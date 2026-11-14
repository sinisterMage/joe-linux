#!/usr/bin/env python3
"""End-to-end test of the joe security module on an image built from joe's own
packages.

  Rule 1  a privileged process runs only sealed code
  Rule 2  a privileged process cannot make memory executable
  Rule 3  a privileged process is held to its declared operations

and, throughout, that unprivileged processes are not affected.
"""

import os
import re
import shutil
import subprocess
import sys

from harness import VM, Timeout, TOP, start_virtiofsd, stop_virtiofsd
from repo import Repo, GUEST_HOST, GUEST_URL, serve_directory

BASE_PORT = 8643
PROBE_DECLARED = ["net", "cap:sys_admin", "mount", "write:/var/lib/probe", "exec:/usr/bin/true"]


def step(text):
    print(f"--- {text}", flush=True)


def build_probe():
    """A static probe binary, built on the host with Zig's C compiler."""
    out = os.path.join(TOP, "build", "probe")
    subprocess.run(
        ["zig", "cc", "-target", "x86_64-linux-musl", "-static", "-O2", "-o", out,
         os.path.join(TOP, "tests", "vm", "probe.c")],
        check=True,
    )
    return out


def probe_package(repo, name, binary, allow):
    stage = os.path.join(repo.stage, name, "usr", "bin")
    os.makedirs(stage)
    subprocess.run(["cp", binary, os.path.join(stage, name)], check=True)
    os.chmod(os.path.join(stage, name), 0o755)
    repo.pack_tree(name, "1-r1", os.path.join(repo.stage, name), allow=allow)


def allowed(vm, command):
    """Runs a probe and returns True if the kernel allowed the operation."""
    out = vm.run(command, check=False).strip().splitlines()
    last = out[-1] if out else ""
    assert last == "allowed" or last.startswith("denied"), f"`{command}` printed: {out}"
    return last == "allowed"


def as_nobody(command):
    return f"su -s /bin/sh nobody -c '{command}'"


def main():
    subprocess.run(["zig", "build", "-Doptimize=ReleaseSafe"], cwd=os.path.join(TOP, "dave"), check=True)
    repo = Repo("vm-repo-security")
    probe = build_probe()
    probe_package(repo, "probe-all", probe, ["all"])
    probe_package(repo, "probe-none", probe, ["none"])
    probe_package(repo, "probe-declared", probe, PROBE_DECLARED)
    probe_package(repo, "probe-undeclared", probe, [])
    probe_package(repo, "probe-limited", probe, ["exec:/usr/bin/probe-undeclared"])
    probe_package(repo, "probe-ipc", probe, ["root-ipc"])
    probe_package(repo, "probe-cap", probe, ["cap:sys_admin"])
    probe_package(repo, "probe-device", probe, ["write:/dev/vda"])
    repo.index()

    base = os.path.join(TOP, "build", "repo")
    base_key = os.path.join(TOP, "build", "keys", "joe.pub")
    image = os.path.join(TOP, "build", "images", "joe-security.img")
    subprocess.run([
        os.path.join(TOP, "image", "mkjoe.sh"), "--test",
        "--repo", f"joe,{base},http://{GUEST_HOST}:{BASE_PORT},{base_key}",
        "--repo", f"test,{repo.path},{GUEST_URL},{repo.public_key}",
        image, "joe-base", "probe-all", "probe-none", "probe-declared",
        "probe-undeclared", "probe-limited", "probe-ipc", "probe-cap", "probe-device",
    ], check=True)

    with VM(image, "security") as vm:
        share = os.path.join(TOP, "build", "images", "security-share")
        shutil.rmtree(share, ignore_errors=True)
        os.makedirs(share)
        socket = os.path.join(vm.workdir, "virtiofs.sock")
        daemon = start_virtiofsd(share, socket)
        if daemon:
            vm.extra_args = [
                "-object", "memory-backend-memfd,id=mem,size=2G,share=on", "-numa", "node,memdev=mem",
                "-chardev", f"socket,id=vfs,path={socket}", "-device", "vhost-user-fs-pci,chardev=vfs,tag=host",
            ]
        try:
            vm.start()
            vm.wait_boot()
            scenarios(vm, share if daemon else None)
        finally:
            vm.close()
            stop_virtiofsd(daemon)
    print("security scenarios passed")


def scenarios(vm, share):
    step("the module is active and starts in log mode")
    assert "joe" in vm.run("cat /sys/kernel/security/lsm").split(","), "the joe module is not loaded"
    assert vm.run("cat /sys/kernel/security/joe/enforce").strip() == "0"

    step("the first boot sealed every packaged file")
    assert vm.run("test -e /usr/lib/dave/sealed && echo yes", check=False).strip() == "yes"
    out = vm.run("dave seal", timeout=600)
    m = re.search(r"Sealed (\d+) file\(s\); (\d+) were already sealed", out)
    assert m and m.group(1) == "0" and int(m.group(2)) > 3000, out
    print(f"    {m.group(2)} files sealed")
    assert vm.run("echo x >> /usr/bin/true", check=False) != "" or True
    assert vm.run("echo x >> /usr/bin/true 2>/dev/null; echo status=$?", check=False).strip().endswith("status=1"), \
        "a sealed file could be modified"

    step("log mode reports but does not prevent")
    vm.run("cp /usr/bin/true /root/unsealed && /root/unsealed")
    log = vm.run("dmesg | grep 'joe: would-deny' | grep unsealed | tail -n 3")
    assert "op=exec-unsealed arg=/root/unsealed" in log, log

    step("undeclared code is reported distinctly in log mode")
    assert allowed(vm, "probe-limited exec /usr/bin/probe-undeclared")
    log = vm.run("dmesg | grep 'joe: would-deny' | grep undeclared | tail -n 3")
    assert "op=undeclared arg=/usr/bin/probe-undeclared" in log, log

    step("switching to enforcing is one-way")
    vm.run("echo 1 > /sys/kernel/security/joe/enforce")
    assert vm.run("cat /sys/kernel/security/joe/enforce").strip() == "1"
    vm.run("echo 0 > /sys/kernel/security/joe/enforce 2>/dev/null; true")
    assert vm.run("cat /sys/kernel/security/joe/enforce").strip() == "1"

    step("rule 1: root cannot run unsealed code; ordinary users can")
    assert "status=126" in vm.run("/root/unsealed; echo status=$?", check=False), "unsealed program ran as root"
    # A copy that carries the original's seal attribute is still not sealed:
    # the attribute alone means nothing without fs-verity over the contents.
    vm.run("cp --preserve=xattr /usr/bin/true /root/copied")
    assert "status=126" in vm.run("/root/copied; echo status=$?", check=False), "a copied seal was accepted"
    vm.run("printf '#!/bin/sh\\necho script ran\\n' > /root/script.sh && chmod +x /root/script.sh")
    assert "script ran" not in vm.run("/root/script.sh; true", check=False), "an unsealed script ran as root"
    vm.run("cp /root/unsealed /root/script.sh /tmp/ && chmod 755 /tmp/unsealed /tmp/script.sh")
    assert "status=0" in vm.run(as_nobody("/tmp/unsealed") + "; echo status=$?", check=False)
    assert "script ran" in vm.run(as_nobody("/tmp/script.sh"), check=False)
    denied = vm.run("dmesg | grep 'joe: denied' | tail -n 4")
    print(denied)
    assert "op=exec-unsealed" in denied, denied

    step("undeclared is not none, and only an all caller supplies authority")
    assert not allowed(vm, "probe-limited exec /usr/bin/probe-undeclared")
    assert allowed(vm, "probe-all exec /usr/bin/probe-undeclared net")
    assert not allowed(vm, "probe-all exec /usr/bin/probe-none net")
    denied = vm.run("dmesg | grep 'joe: denied' | grep undeclared | tail -n 3")
    assert "op=undeclared arg=/usr/bin/probe-undeclared" in denied, denied
    vm.run("chmod 4755 /usr/bin/probe-undeclared")
    assert not allowed(vm, as_nobody("probe-all exec /usr/bin/probe-undeclared"))
    vm.run("chmod 755 /usr/bin/probe-undeclared")

    step("AT_EXECVE_CHECK gives the same answer as a real exec")
    assert allowed(vm, "probe-declared exec-check /usr/bin/true")
    assert not allowed(vm, "probe-declared exec-check /usr/bin/false")
    assert not allowed(vm, "probe-all exec-check /root/unsealed")

    step("rule 2: root cannot create executable memory, whatever it declares")
    assert not allowed(vm, "probe-all jit-anon")
    assert not allowed(vm, "probe-all jit-mprotect")
    assert allowed(vm, as_nobody("probe-all jit-anon"))
    assert allowed(vm, as_nobody("probe-all jit-mprotect"))

    step("privileged processes cannot escape or inject code through task mechanisms")
    assert allowed(vm, "probe-all userns")
    assert allowed(vm, "probe-none userns")
    assert not allowed(vm, "probe-all cap-only-userns")
    assert not allowed(vm, "probe-all userns-jit")
    assert allowed(vm, as_nobody("probe-none userns"))
    assert allowed(vm, as_nobody("probe-none userns-jit"))
    assert allowed(vm, "probe-all ptrace-root")
    assert not allowed(vm, "probe-none ptrace-root")
    assert not allowed(vm, "probe-all ptrace-write")
    assert not allowed(vm, "probe-all proc-mem-write")
    assert not allowed(vm, "probe-all process-vm-write")
    assert allowed(vm, as_nobody("probe-all ptrace-write"))
    assert allowed(vm, as_nobody("probe-all proc-mem-write"))
    assert allowed(vm, as_nobody("probe-all process-vm-write"))
    step("root-ipc authorizes root-to-root signals and SysV IPC")
    assert not allowed(vm, "probe-none ipc-signal")
    assert allowed(vm, "probe-ipc ipc-signal")
    assert not allowed(vm, "probe-none ipc-sysv")
    assert allowed(vm, "probe-ipc ipc-sysv")
    assert not allowed(vm, "probe-none ipc-sysv-ctl")
    assert allowed(vm, "probe-ipc ipc-sysv-ctl")
    assert allowed(vm, "probe-none ipc-sysv-info")
    assert allowed(vm, as_nobody("probe-none ipc-signal"))
    assert allowed(vm, as_nobody("probe-none ipc-sysv"))
    assert allowed(vm, as_nobody("probe-none ipc-sysv-ctl"))

    step("rule 3: a program that declares nothing can do nothing privileged")
    vm.run("mkdir -p /var/lib/probe /mnt/probe")
    assert not allowed(vm, "probe-none net")
    assert not allowed(vm, "probe-none cap")
    assert not allowed(vm, "probe-none write /var/lib/probe/file")
    assert not allowed(vm, "probe-none exec /usr/bin/true")
    assert not allowed(vm, "probe-none mount /mnt/probe")
    # Temporary file systems hold no lasting state and are not restricted.
    assert allowed(vm, "probe-none write /run/probe-file")

    step("rule 3: a program is held to exactly what it declares")
    assert allowed(vm, "probe-declared net")
    assert allowed(vm, "probe-declared cap")
    assert allowed(vm, "probe-declared mount /mnt/probe")
    assert not allowed(vm, "probe-cap mount-create")
    assert allowed(vm, "probe-declared mount-create")
    assert not allowed(vm, "probe-all mount-delegate /usr/bin/probe-cap")
    assert allowed(vm, "probe-all mount-delegate /usr/bin/probe-declared")
    assert not allowed(vm, "probe-cap mount-new /mnt/probe")
    assert allowed(vm, "probe-declared mount-new /mnt/probe")
    vm.run("mount -t tmpfs probe /mnt/probe")
    assert not allowed(vm, "probe-cap remount /mnt/probe")
    assert allowed(vm, "probe-declared remount /mnt/probe")
    assert not allowed(vm, "probe-cap mount-setattr /mnt/probe")
    assert allowed(vm, "probe-declared mount-setattr /mnt/probe")
    assert not allowed(vm, "probe-cap umount-only /mnt/probe")
    assert allowed(vm, "probe-declared umount-only /mnt/probe")
    assert allowed(vm, "probe-declared write /var/lib/probe/file")
    assert not allowed(vm, "probe-declared write /var/lib/elsewhere")
    assert not allowed(vm, "probe-declared write /etc/probe-file")
    assert allowed(vm, "probe-declared exec /usr/bin/true")
    assert not allowed(vm, "probe-declared exec /usr/bin/false")
    assert allowed(vm, "probe-all write /etc/probe-file")
    assert allowed(vm, "probe-all exec /usr/bin/false")
    assert not allowed(vm, "probe-none block-write /dev/vda")
    assert allowed(vm, "probe-device block-write /dev/vda")
    # None of this concerns an unprivileged user, whom ordinary permissions confine.
    assert allowed(vm, as_nobody("probe-none net"))
    assert allowed(vm, as_nobody("probe-none exec /usr/bin/true"))

    if share:
        step("writes through virtiofs are persistent writes")
        vm.run("mkdir -p /mnt/probe-share && mount -t virtiofs host /mnt/probe-share")
        path = os.path.join(share, "probe")
        assert not allowed(vm, "probe-none write /mnt/probe-share/probe")
        assert not os.path.exists(path), "a denied virtiofs open created a host file"
        assert allowed(vm, "probe-all write /mnt/probe-share/probe")
        with open(path) as f:
            assert f.read() == "x"
        vm.run("umount /mnt/probe-share")
    else:
        print("    virtiofsd is not installed: the persistent host-share write probe is skipped")

    step("the system keeps working while enforcing")
    assert "Running deployment 1." in vm.run("dave status")
    state = vm.run("systemctl is-system-running", check=False).strip()
    assert state in ("running", "degraded"), state
    print(f"    system state: {state}")

    step("a system booted with joe=enforce comes up and stays usable")
    vm.run("sed -i '/^options /s/$/ joe=enforce/' /efi/loader/entries/joe-1.conf")
    vm.reboot(300)
    assert vm.run("cat /sys/kernel/security/joe/enforce").strip() == "1"
    assert "joe=enforce" in vm.run("cat /proc/cmdline")
    assert "Running deployment 1." in vm.run("dave status")
    assert "status=126" in vm.run("/root/unsealed; echo status=$?", check=False)
    failed = vm.run("systemctl --failed --no-legend --plain", check=False).strip()
    assert failed == "", failed
    denials = vm.run("dmesg | grep -c 'joe: denied'", check=False).strip()
    print(f"    denials since boot: {denials}")
    unexpected = vm.run("dmesg | grep 'joe: denied' | grep -vF 'op=exec-unsealed arg=/root/unsealed'", check=False).strip()
    assert unexpected == "", unexpected


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, Timeout) as err:
        print(f"FAILED: {err}")
        sys.exit(1)
