#!/usr/bin/env python3
"""Installs joe Linux from the installation medium onto an empty disk and
checks the system that makes:

- the installer is offered the empty disk and never the medium;
- the installation reports its progress as it goes, and finishes;
- the firmware is told where the new system's boot loader is;
- the installed system starts from the disk alone, as a deployment, with its
  files already sealed, the repository the medium was built for, no
  accounts, and GNOME's initial setup waiting for the person;
- dave works on it as on any other joe system: a change makes a rollback
  point, and rolling back returns to it.

The installation goes through the graphical installer (joe-installer
--autotest, in the live session, with screenshots of each page) when the
medium has it, and through `dave install-system` directly otherwise.

    tests/vm/install.py [ISO]    without ISO, builds build/images/joe-live-test.iso
"""

import json
import os
import sys
import time

from harness import VM, Timeout, TOP, blank_disk, as_cd
from repo import GUEST_HOST, serve_directory
from desktop import step, wait_for
from live import build_iso

BASE_PORT = 8643
LIVE_ENV = (
    "XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 "
    "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus "
    "XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_TYPE=wayland QT_FORCE_STDERR_LOGGING=1"
)
# A package outside the desktop, to change the installed system with.
EXTRA = "ninja"


def install_headless(vm):
    step("installing with dave install-system")
    out = vm.run("dave install-system --disk /dev/vda --json 2>/tmp/install.log; echo status=$?",
                 timeout=2400, check=False)
    events = [json.loads(line) for line in out.splitlines() if line.startswith("{")]
    if not out.strip().endswith("status=0"):
        print(vm.run("tail -n 40 /tmp/install.log", check=False))
        raise AssertionError(f"the installation failed: {events[-1] if events else out[-500:]}")
    assert events and events[-1]["event"] == "done", events[-3:]
    fractions = [e["fraction"] for e in events if "fraction" in e]
    assert fractions == sorted(fractions), "progress went backwards"
    assert any(e["event"] == "progress" for e in events), "no per-package progress"
    print(f"    {len(events)} events, last: {events[-1]['message']}")


def install_graphical(vm):
    step("installing with the installer, as a person would")
    wait_for(vm, "the live session", "pgrep -u liveuser -x gnome-shell", 300)
    # The session opened the installer by itself; the test drives its own.
    wait_for(vm, "the installer the session opened", "pgrep -u liveuser -x joe-installer", 120)
    time.sleep(10)
    vm.screenshot(os.path.join(vm.workdir, "installer-0-opened.png"))
    vm.run("pkill -x joe-installer; sleep 2", check=False)
    vm.run(f"su liveuser -c '{LIVE_ENV} joe-installer --autotest /dev/vda > /tmp/installer.log 2>&1 &'")
    seen = set()
    deadline = time.monotonic() + 2400
    while time.monotonic() < deadline:
        log = vm.run("grep -o 'autotest: .*' /tmp/installer.log", check=False)
        for line in log.splitlines():
            if line.startswith("autotest: page ") and line not in seen:
                seen.add(line)
                page = line.split()[2].rstrip(":")
                print(f"    {line}")
                vm.screenshot(os.path.join(vm.workdir, f"installer-{len(seen)}-{page}.png"))
        if "autotest: page done" in seen:
            return
        if any(s.startswith("autotest: page failed") or "cannot be used" in s for s in seen):
            break
        if vm.run("pgrep -x joe-installer >/dev/null; echo status=$?", check=False).strip().endswith("status=1"):
            break  # it exited without reaching the last page
        time.sleep(5)
    print(vm.run("tail -n 40 /tmp/installer.log", check=False))
    raise AssertionError(f"the installer did not finish: {sorted(seen)}")


def check_installed(vm):
    step("the installed system starts from the disk as deployment 1")
    cmdline = vm.run("cat /proc/cmdline")
    assert "rootflags=subvol=joe/deploy/1" in cmdline and "console=ttyS0,115200" in cmdline, cmdline
    assert "joe=log" not in cmdline, "the medium's command line was copied"
    assert vm.run("findmnt -no FSTYPE /").strip() == "btrfs"
    assert vm.run("findmnt -no FSTYPE /efi").strip() == "vfat"
    assert "Running deployment 1." in vm.run("dave status")
    assert vm.run("sfdisk --dump /dev/vda | grep -c '^/dev/vda'").strip() == "2"
    vm.run("sfdisk --verify /dev/vda")
    size = int(vm.run("df -B1 --output=size / | tail -n 1").strip())
    assert size > 37 << 30, f"the root is {size} bytes on a 40G disk"

    step("its files were sealed as they were installed")
    assert vm.run("test -e /usr/lib/dave/sealed && echo yes", check=False).strip() == "yes"
    assert "no" in vm.run("systemctl show -p ConditionResult dave-seal.service")
    seal = vm.run("getfattr --absolute-names --only-values -n security.joe /usr/bin/bash 2>/dev/null | head -c 4")
    assert seal.strip() == "JOE1", seal

    step("it takes packages from the repository the medium was made for")
    assert f"http://{GUEST_HOST}:{BASE_PORT}" in vm.run("cat /etc/dave/repos.zon")
    assert vm.run("ls /var/cache/dave 2>/dev/null | wc -l").strip() in ("0", "")

    step("nobody has an account yet, and the first-run setup is waiting")
    assert vm.run("awk -F: '$3 >= 1000 && $3 < 60000' /etc/passwd").strip() == ""
    wait_for(vm, "gnome-initial-setup", "pgrep -f gnome-initial-setup", 300)
    time.sleep(20)
    vm.screenshot(os.path.join(vm.workdir, "first-boot.png"))
    failed = vm.run("systemctl --failed --no-legend --plain", check=False).strip()
    assert not failed, f"failed units:\n{failed}"


def check_dave(vm):
    step("a change makes a rollback point, and rolling back returns to it")
    vm.run(f"dave install {EXTRA}", timeout=600)
    assert vm.run(f"command -v {EXTRA}", check=False).strip()
    vm.run("dave rollback")
    vm.reboot(600)
    assert "Running deployment 2." in vm.run("dave status")
    assert not vm.run(f"command -v {EXTRA}", check=False).strip(), f"{EXTRA} survived the rollback"


def main():
    iso = sys.argv[1] if len(sys.argv) > 1 else build_iso()
    disk = blank_disk(os.path.join(TOP, "build", "images", "install-target.img"))
    server = serve_directory(os.path.join(TOP, "build", "repo"), BASE_PORT)
    try:
        with VM(disk, "install", memory="6G", cpus=8, extra_args=as_cd(iso), display=True) as vm:
            vm.start()
            vm.wait_boot(600)

            step("the installer is offered the empty disk, and not the medium")
            listing = json.loads(vm.run("dave install-system --list --json"))
            disks = {d["device"]: d for d in listing["disks"]}
            assert disks.get("/dev/vda", {}).get("usable"), listing
            assert "/dev/sr0" not in disks, listing

            if vm.run("command -v joe-installer", check=False).strip():
                install_graphical(vm)
            else:
                install_headless(vm)

            step("the firmware was told about the new system")
            loaders = vm.run("bootctl status --no-pager 2>/dev/null | sed -n '/Listed in EFI Variables/,/^$/p'", check=False)
            assert "Linux Boot Manager" in loaders, loaders

            # The medium is taken out; the disk alone must start.
            vm.kill()
            vm.extra_args = []
            vm.start()
            vm.wait_boot(600)
            check_installed(vm)
            check_dave(vm)
            print(f"screenshots: {vm.workdir}")
    finally:
        server.terminate()
        server.wait()
    print("installation scenarios passed")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, Timeout) as err:
        print(f"FAILED: {err}")
        sys.exit(1)
