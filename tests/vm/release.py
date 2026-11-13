#!/usr/bin/env python3
"""Boots a desktop that nobody has set up yet, the way `make vm` and `make
run-vm` do, and checks what living in that machine depends on: the root file
system grows to fill a disk larger than the image, the first boot offers to
create an account instead of a login prompt nobody could pass, a sound card
appears, and a host directory can be shared.

The image differs from the release image in one way: root is logged in on the
serial console, which is how this test looks inside.
"""

import os
import shutil
import subprocess
import sys
import time

from harness import VM, Timeout, TOP
from repo import GUEST_HOST
from desktop import step, wait_for

BASE_PORT = 8643
DISK = "40G"
MEMORY = "6G"


def build_image():
    base = os.path.join(TOP, "build", "repo")
    key = os.path.join(TOP, "build", "keys", "joe.pub")
    image = os.path.join(TOP, "build", "images", "joe-firstboot.img")
    subprocess.run([
        os.path.join(TOP, "image", "mkjoe.sh"), "--test", "--root-size", "16G",
        "--repo", f"joe,{base},http://{GUEST_HOST}:{BASE_PORT},{key}",
        image, "joe-desktop",
    ], check=True)
    return image


def new_machine(image):
    """The disk `image/run.sh --persist` makes for a new machine."""
    machine = os.path.join(TOP, "build", "images", "release-machine")
    shutil.rmtree(machine, ignore_errors=True)
    subprocess.run([
        os.path.join(TOP, "image", "run.sh"), "--persist", machine, "--create", "--disk-size", DISK, image,
    ], check=True)
    disk = os.path.join(machine, "disk.img")
    assert os.path.getsize(disk) == 40 << 30, os.path.getsize(disk)
    return disk


def start_virtiofsd(share, socket):
    """The same daemon, with the same identity mapping, as `run.sh --share`."""
    binary = shutil.which("virtiofsd") or "/usr/lib/virtiofsd"
    if not os.access(binary, os.X_OK):
        return None
    daemon = subprocess.Popen([
        binary, "--socket-path", socket, "--shared-dir", share,
        "--translate-uid", "squash-guest:0:0:4294967295", "--translate-gid", "squash-guest:0:0:4294967295",
        "--translate-uid", "squash-host:0:1000:4294967295", "--translate-gid", "squash-host:0:1000:4294967295",
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(50):
        if os.path.exists(socket):
            return daemon
        time.sleep(0.1)
    raise AssertionError("virtiofsd did not start")


def root_size(vm):
    return int(vm.run("df -B1 --output=size / | tail -n 1").strip())


def main():
    image = sys.argv[1] if len(sys.argv) > 1 else build_image()
    disk = new_machine(image)
    share = os.path.join(TOP, "build", "images", "release-share")
    shutil.rmtree(share, ignore_errors=True)
    os.makedirs(share)
    with open(os.path.join(share, "from-host"), "w") as f:
        f.write("written on the host\n")
    socket = os.path.join(TOP, "build", "images", "vm-release", "virtiofs.sock")

    devices = [
        # A sound card with nowhere to play: only the guest's side is examined.
        "-audiodev", "none,id=snd0", "-device", "intel-hda", "-device", "hda-duplex,audiodev=snd0",
        # vhost-user devices need the guest's memory shared with the daemon.
        "-object", f"memory-backend-memfd,id=mem,size={MEMORY},share=on", "-numa", "node,memdev=mem",
        "-chardev", f"socket,id=vfs,path={socket}", "-device", "vhost-user-fs-pci,chardev=vfs,tag=host",
    ]
    daemon = None
    with VM(disk, "release", memory=MEMORY, cpus=8, display=True, extra_args=devices) as vm:
        try:
            daemon = start_virtiofsd(share, socket)
            if daemon is None:
                print("    virtiofsd is not installed: the shared folder is not tested")
                vm.extra_args = devices[:6]
            vm.start()
            vm.wait_boot(600)
            scenarios(vm, share, daemon is not None)
        finally:
            if daemon:
                daemon.terminate()
                daemon.wait()
        print(f"screenshots: {vm.workdir}")
    print("release scenarios passed")


def scenarios(vm, share, shared):
    step("the root file system grew to fill the disk on the first boot")
    for unit in ("systemd-repart.service", "systemd-growfs-root.service"):
        state = vm.run(f"systemctl is-active {unit}", check=False).strip()
        assert state == "active", f"{unit} is {state}"
    size = root_size(vm)
    print(f"    / is {size / (1 << 30):.1f} GiB on a {DISK} disk")
    assert size > 38 << 30, size
    # The partition table's backup was moved to the new end of the disk.
    table = vm.run("sfdisk --verify /dev/vda 2>&1", check=False)
    assert "No errors detected" in table, table

    step("nobody has an account, and root has no password")
    people = vm.run("awk -F: '$3 >= 1000 && $3 <= 60000 { print $1 }' /etc/passwd").split()
    assert people == [], people
    assert vm.run("grep -c '^root:!' /etc/shadow").strip() == "1"

    step("a sound card with playback and capture")
    cards = vm.run("cat /proc/asound/cards")
    pcm = vm.run("cat /proc/asound/pcm", check=False)
    print("    " + " ".join(cards.split()))
    assert "HDA" in cards and "playback" in pcm and "capture" in pcm, cards + pcm

    if shared:
        step("a directory of the host, shared")
        vm.run("mount -t virtiofs host /mnt")
        assert vm.run("cat /mnt/from-host").strip() == "written on the host"
        # Everything there appears to belong to the first account, and what the
        # guest writes belongs on the host to whoever started the machine.
        assert vm.run("stat -c %u /mnt/from-host").strip() == "1000"
        vm.run("echo written in the guest > /mnt/from-guest && umount /mnt")
        path = os.path.join(share, "from-guest")
        assert open(path).read().strip() == "written in the guest"
        assert os.stat(path).st_uid == os.getuid()

    step("the display manager starts the first-run setup")
    wait_for(vm, "the system to finish booting", "systemctl is-active graphical.target", 300)
    wait_for(vm, "gdm", "systemctl is-active gdm.service")
    wait_for(vm, "gnome-initial-setup", "pgrep -u gnome-initial-setup -f /usr/libexec/gnome-initial-setup", 240)
    time.sleep(20)
    vm.screenshot(os.path.join(vm.workdir, "1-initial-setup.png"))
    failed = vm.run("systemctl --failed --no-legend --plain", check=False).strip()
    print(f"    failed units: {failed or 'none'}")

    step("a second boot changes nothing")
    vm.reboot(600)
    assert root_size(vm) == size
    for unit in ("systemd-repart.service", "systemd-growfs-root.service"):
        state = vm.run(f"systemctl is-failed {unit}", check=False).strip()
        assert state != "failed", f"{unit} failed on the second boot"
    wait_for(vm, "gnome-initial-setup", "pgrep -u gnome-initial-setup -f /usr/libexec/gnome-initial-setup", 240)


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, Timeout) as err:
        print(f"FAILED: {err}")
        sys.exit(1)
