"""Drives a joe Linux disk image in QEMU over its serial console.

The guest is expected to log root in automatically on ttyS0 with the prompt
"joe# ". Everything the guest prints is appended to a log file so a failed
scenario can be read afterwards.
"""

import json
import os
import re
import select
import socket
import shutil
import subprocess
import time

TOP = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OVMF_CODE = "/usr/share/edk2/x64/OVMF_CODE.4m.fd"
OVMF_VARS = "/usr/share/edk2/x64/OVMF_VARS.4m.fd"
PROMPT = b"joe# "
# Printed by the firmware each time it hands over to the boot loader.
BOOT_BANNER = b"BdsDxe: starting "


class Timeout(Exception):
    pass


class CommandFailed(Exception):
    pass


class VM:
    def __init__(self, base_image, name, memory="2G", cpus=4, extra_args=(), display=False):
        self.workdir = os.path.join(TOP, "build", "images", "vm-" + name)
        shutil.rmtree(self.workdir, ignore_errors=True)
        os.makedirs(self.workdir)
        # Each VM works on its own copy; the base image stays pristine.
        self.image = os.path.join(self.workdir, "disk.img")
        subprocess.run(["cp", "--reflink=auto", "--sparse=always", base_image, self.image], check=True)
        self.vars = os.path.join(self.workdir, "OVMF_VARS.fd")
        shutil.copy(OVMF_VARS, self.vars)
        self.log_path = os.path.join(self.workdir, "console.log")
        self.log = open(self.log_path, "wb")
        self.memory = memory
        self.cpus = cpus
        self.extra_args = list(extra_args)
        # With a display, the guest gets a virtio GPU and input devices, and
        # QEMU's control socket is opened so that screenshots can be taken.
        self.display = display
        self.qmp_path = os.path.join(self.workdir, "qmp.sock")
        self.proc = None
        self.buffer = b""

    # -- process control ----------------------------------------------------

    def start(self):
        args = [
            "qemu-system-x86_64",
            "-enable-kvm", "-cpu", "host", "-machine", "q35",
            "-m", self.memory, "-smp", str(self.cpus),
            "-drive", f"if=pflash,format=raw,readonly=on,file={OVMF_CODE}",
            "-drive", f"if=pflash,format=raw,file={self.vars}",
            "-drive", f"file={self.image},format=raw,if=virtio,cache=unsafe",
            "-netdev", "user,id=n0", "-device", "virtio-net-pci,netdev=n0",
            "-display", "none", "-monitor", "none", "-serial", "stdio",
        ] + self.extra_args
        if self.display:
            args += [
                "-device", "virtio-vga", "-device", "virtio-keyboard-pci", "-device", "virtio-tablet-pci",
                "-qmp", f"unix:{self.qmp_path},server=on,wait=off",
            ]
        self.proc = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        os.set_blocking(self.proc.stdout.fileno(), False)
        self.buffer = b""

    def kill(self):
        """Pulls the plug: the guest gets no chance to shut down."""
        if self.proc and self.proc.poll() is None:
            self.proc.kill()
            self.proc.wait()
        self.proc = None

    def close(self):
        self.kill()
        self.log.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    # -- console ------------------------------------------------------------

    def _read(self, timeout):
        ready, _, _ = select.select([self.proc.stdout], [], [], timeout)
        if not ready:
            return False
        data = self.proc.stdout.read()
        if data:
            self.log.write(data)
            self.log.flush()
            self.buffer += data
            return True
        if self.proc.poll() is not None:
            raise Timeout(f"qemu exited with status {self.proc.returncode}")
        return False

    def expect(self, pattern, timeout=120):
        """Waits for `pattern` (bytes regex) and returns the match. Consumes
        everything up to and including it."""
        regex = re.compile(pattern, re.S)
        deadline = time.monotonic() + timeout
        while True:
            m = regex.search(self.buffer)
            if m:
                self.buffer = self.buffer[m.end():]
                return m
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                tail = self.buffer[-2000:].decode(errors="replace")
                raise Timeout(f"timed out after {timeout}s waiting for {pattern!r}; console tail:\n{tail}")
            self._read(min(remaining, 1.0))

    def send(self, text):
        self.proc.stdin.write(text.encode())
        self.proc.stdin.flush()

    # -- guest lifecycle ----------------------------------------------------

    def wait_boot(self, timeout=180):
        """Waits for the firmware to start a boot and root to be logged in."""
        self.expect(re.escape(BOOT_BANNER), timeout)
        self.wait_prompt(timeout)

    def wait_prompt(self, timeout=180):
        self.expect(re.escape(PROMPT), timeout)
        # Keep later kernel messages from interleaving with command output.
        self.run("dmesg -n 1; stty cols 250 rows 50", check=False)

    def run(self, command, timeout=120, check=True):
        """Runs a shell command in the guest and returns its output."""
        self.buffer = b""
        self.send(f"echo __BEGIN__; {command}; echo __RC__$?__\n")
        self.expect(rb"__BEGIN__\r?\n", timeout)
        m = self.expect(rb"(.*?)__RC__(\d+)__\r?\n", timeout)
        output = m.group(1).decode(errors="replace").replace("\r\n", "\n")
        status = int(m.group(2))
        self.expect(re.escape(PROMPT), 30)
        if check and status != 0:
            raise CommandFailed(f"`{command}` exited with {status}:\n{output}")
        return output

    def reboot(self, timeout=180):
        """Clean reboot through systemd; returns once the next boot is up."""
        self.buffer = b""
        self.send("systemctl reboot\n")
        self.wait_boot(timeout)

    def power_cut(self, timeout=180):
        """Kills the VM without warning and boots it again."""
        self.kill()
        self.start()
        self.wait_boot(timeout)

    def screenshot(self, path):
        """Saves what the guest's display shows as a PNG file."""
        sock = socket.socket(socket.AF_UNIX)
        sock.settimeout(30)
        sock.connect(self.qmp_path)
        stream = sock.makefile("rw")

        def command(name, **arguments):
            stream.write(json.dumps({"execute": name, "arguments": arguments}) + "\n")
            stream.flush()
            while True:
                reply = json.loads(stream.readline())
                if "return" in reply or "error" in reply:
                    return reply

        json.loads(stream.readline())  # greeting
        command("qmp_capabilities")
        reply = command("screendump", filename=path, format="png")
        sock.close()
        if "error" in reply:
            raise RuntimeError(f"screenshot failed: {reply['error']}")

    # -- conveniences -------------------------------------------------------

    def current_subvol(self):
        """The root subvolume named on the running kernel's command line."""
        cmdline = self.run("cat /proc/cmdline")
        m = re.search(r"rootflags=subvol=([^, ]+)", cmdline)
        return m.group(1) if m else None
