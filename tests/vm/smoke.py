#!/usr/bin/env python3
"""Boots an image and checks the basic contract every other scenario relies on:
it reaches a root shell with no initramfs, the root is the expected writable
btrfs subvolume, and the shared subvolumes and the ESP are mounted."""

import sys

from harness import VM


def main():
    image = sys.argv[1]
    with VM(image, "smoke") as vm:
        vm.start()
        vm.wait_boot()

        subvol = vm.current_subvol()
        assert subvol == "joe/deploy/1", f"unexpected root subvolume: {subvol}"

        cmdline = vm.run("cat /proc/cmdline")
        assert "initrd=" not in cmdline, "booted with an initramfs"

        root = vm.run("findmnt -rno FSTYPE,OPTIONS /")
        assert root.startswith("btrfs"), root
        assert "rw" in root.split()[1].split(","), f"root is not writable: {root}"
        assert "subvol=/joe/deploy/1" in root, root

        for mountpoint, expected in (("/var", "subvol=/var"), ("/home", "subvol=/home"), ("/efi", "vfat")):
            info = vm.run(f"findmnt -rno FSTYPE,OPTIONS {mountpoint}")
            assert expected in info, f"{mountpoint}: {info}"

        # The mutable-root promise: an ordinary write to / just works.
        vm.run("echo hello > /usr/local/smoke && cat /usr/local/smoke && rm /usr/local/smoke")

        state = vm.run("systemctl is-system-running --wait", timeout=180, check=False).strip()
        failed = vm.run("systemctl --failed --no-legend --plain", check=False).strip()
        print(f"system state: {state}")
        if failed:
            print(f"failed units:\n{failed}")
        print(vm.run("bootctl status 2>/dev/null | sed -n '1,25p'", check=False))
        print("smoke test passed")


if __name__ == "__main__":
    main()
