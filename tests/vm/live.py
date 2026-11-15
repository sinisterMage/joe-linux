#!/usr/bin/env python3
"""Boots the installation medium (image/live.zon, built with --test) the two
ways a computer does: as a CD and as a USB stick, each with an empty disk
beside it. Checks that the live system comes up from the compressed image
with a writable layer in memory over it, that the live session (where the
installer runs) starts by itself, that the repository on the medium is
complete and verifies, and that the security module, which can only log on a
system where nothing is sealed, says so once per file rather than flooding
the kernel log.

    tests/vm/live.py [ISO]     without ISO, builds build/images/joe-live-test.iso
"""

import os
import re
import sys
import time

from harness import VM, Timeout, TOP, build_image, blank_disk, as_cd, as_usb_stick
from repo import GUEST_HOST
from desktop import step, wait_for

BASE_PORT = 8643
ISO = os.path.join(TOP, "build", "images", "joe-live-test.iso")


def build_iso():
    base = os.path.join(TOP, "build", "repo")
    key = os.path.join(TOP, "build", "keys", "joe.pub")
    return build_image("live", ISO, repos=[("joe", base, f"http://{GUEST_HOST}:{BASE_PORT}", key)])


def check_live(vm, medium_device):
    step("the root is the image with a writable layer over it")
    assert vm.run("findmnt -no FSTYPE /").strip() == "overlay"
    assert vm.run("findmnt -no FSTYPE /run/live/lower").strip() == "squashfs"
    source = vm.run("findmnt -no SOURCE /run/live/medium").strip()
    if not source.startswith(medium_device):
        # systemd attaches a CD that has a partition table (as a hybrid ISO
        # does) to a loop device, so that its partitions appear; the medium
        # is then the first of those, the same ISO 9660 file system.
        loop = vm.run(f"lsblk -no PKNAME {source}").strip()
        backing = vm.run(f"losetup -nO BACK-FILE /dev/{loop}", check=False).strip()
        assert backing.endswith(os.path.basename(medium_device)), \
            f"medium mounted from {source} ({backing}), expected {medium_device}"
    vm.run("echo changed > /usr/share/live-write-test && grep -q changed /usr/share/live-write-test")
    cmdline = vm.run("cat /proc/cmdline")
    assert "root=" not in cmdline and "joe=log" in cmdline, cmdline
    assert vm.run("cat /sys/kernel/security/joe/enforce").strip() == "0"

    step("the release is named after its kernel and dave: J<revision>-<kernel>-<dave>[-<stage>]")
    name = vm.run(". /usr/lib/os-release; echo $VERSION").strip()
    kernel = vm.run("uname -r").strip().removesuffix("-joe")
    dave = vm.run("dave version").strip().split()[-1]
    assert re.fullmatch(rf"J\d+-{re.escape(kernel)}-{re.escape(dave)}(-[a-z]+\d+)?", name), \
        f"the release is called {name}, but runs kernel {kernel} and dave {dave}"
    print(f"    {name}")

    step("the system came up without failed units")
    failed = vm.run("systemctl --failed --no-legend --plain", check=False).strip()
    assert not failed, f"failed units:\n{failed}"
    for unit in ("dave-seal", "systemd-repart", "systemd-growfs-root"):
        state = vm.run(f"systemctl is-enabled {unit}.service", check=False).strip()
        assert state == "masked", f"{unit} is {state} on the live system"

    step("the live session starts by itself")
    wait_for(vm, "liveuser's GNOME Shell", "pgrep -u liveuser -x gnome-shell", 300)
    wait_for(vm, "the Wayland socket", "test -S /run/user/1000/wayland-0")
    assert vm.run("id -nG liveuser").split().count("wheel") == 1
    wait_for(vm, "the installer, opened by the session", "pgrep -u liveuser -x joe-installer", 120)
    time.sleep(15)
    vm.screenshot(os.path.join(vm.workdir, "session.png"))

    step("the medium carries what the installer installs")
    install = vm.run("cat /run/live/medium/joe/install.zon")
    assert "joe-desktop" in install, install
    listing = vm.run("ls /run/live/medium/joe/repos/joe/ | grep -c '\\.dave$'").strip()
    assert int(listing) > 300, f"only {listing} packages on the medium"
    # The medium's repository verifies against the key the live system
    # trusts, and has every package the installation needs.
    vm.run("mkdir -p /tmp/check/etc/dave/keys && cp /etc/dave/keys/* /tmp/check/etc/dave/keys/ && "
           "printf '.{ .repos = .{ .{ .name = \"joe\", .url = \"/run/live/medium/joe/repos/joe\" } } }' > /tmp/check/etc/dave/repos.zon")
    plan = vm.run("dave --root /tmp/check --cache /tmp/check-cache --dry-run install joe-desktop", timeout=300)
    assert "install  joe-desktop" in plan, plan

    step("Wi-Fi, as far as a virtual machine can show it")
    # Simulated radios: the kernel's wireless stack and the signed regulatory
    # database, then NetworkManager taking the device over through
    # wpa_supplicant (which D-Bus starts for it).
    vm.run("modprobe mac80211_hwsim radios=1")
    wait_for(vm, "a Wi-Fi device in NetworkManager", "nmcli -t -f TYPE device | grep -qx wifi", 60)
    wait_for(vm, "wpa_supplicant", "pgrep -x wpa_supplicant", 60)
    # The database itself is read when a country is set; what must be there
    # before then is the file and the keys it is checked against.
    assert "Loaded X.509 cert 'sforshee" in vm.run("dmesg | grep -i 'x.509 cert'", check=False), "no regulatory keys"
    vm.run("test -s /usr/lib/firmware/regulatory.db && test -s /usr/lib/firmware/regulatory.db.p7s")
    state = vm.run("nmcli -t -f TYPE,STATE device | grep '^wifi:'").strip()
    assert "unavailable" not in state and "unmanaged" not in state, state
    print(f"    {state}")

    step("the security module reports each unsealed file once")
    reports = int(vm.run("dmesg | grep -c 'joe: would-deny'", check=False).strip() or "0")
    lost = vm.run("dmesg | head -n 1").strip()
    print(f"    {reports} reports; the kernel log starts with: {lost[:60]}")
    assert "Linux version" in lost, "the kernel log lost its beginning"
    assert vm.run("dmesg | grep -c 'joe: denied'", check=False).strip() == "0"


def main():
    iso = sys.argv[1] if len(sys.argv) > 1 else build_iso()
    disk = blank_disk(os.path.join(TOP, "build", "images", "blank-40g.img"))
    for name, attach, device in (("cd", as_cd, "/dev/sr0"), ("usb", as_usb_stick, "/dev/sd")):
        print(f"=== the medium as a {name.upper()}")
        with VM(disk, f"live-{name}", memory="6G", cpus=8, extra_args=attach(iso), display=True) as vm:
            vm.start()
            vm.wait_boot(600)
            check_live(vm, device)
            print(f"screenshots: {vm.workdir}")
    print("live medium scenarios passed")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, Timeout) as err:
        print(f"FAILED: {err}")
        sys.exit(1)
