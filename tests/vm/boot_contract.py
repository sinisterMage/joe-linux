#!/usr/bin/env python3
"""Checks, with hand-written boot entries and shell prototypes, every boot
loader behaviour the deployment design depends on. dave is not involved: this
is the contract dave's implementation is then written against.

  1. Among entries sharing a sort-key, the highest `version` boots.
  2. Raising an older deployment's `version` is a persistent rollback.
  3. A counted entry (`+3`) is blessed only after a health check that is
     ordered before boot-complete.target has passed.
  4. A deployment whose health check fails is retried, then abandoned in
     favour of the previously chosen one, with nobody at the keyboard.
  5. So is a deployment whose root cannot be mounted at all.
  6. A service's stop job can snapshot the root and write a boot entry during
     shutdown, capturing changes made right up to the reboot.
  7. A power cut before that stop job leaves the old deployment booting.
"""

import base64
import re
import sys
import time

from harness import VM, Timeout

BOOT_CHECK = """#!/bin/sh
sub=$(sed -n 's/.*rootflags=subvol=\\([^ ,]*\\).*/\\1/p' /proc/cmdline)
if [ -e /etc/joe-fail-health ]; then
    echo "JOE-HEALTH subvol=$sub result=fail" > /dev/ttyS0
    exit 1
fi
echo "JOE-HEALTH subvol=$sub result=ok" > /dev/ttyS0
"""

BOOT_CHECK_UNIT = """[Unit]
Description=joe boot health check (prototype)
After=multi-user.target
Before=boot-complete.target
FailureAction=reboot

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/joe-boot-check
"""

FINALIZE = """#!/bin/sh
[ -e /var/lib/joe-staged ] || exit 0
n=$(cat /var/lib/joe-staged)
set -e
mkdir -p /run/top
mountpoint -q /run/top || mount -o subvolid=5 "$(findmnt -rno SOURCE / | sed 's/\\[.*//')" /run/top
btrfs subvolume snapshot / /run/top/joe/deploy/$n >/dev/null
cp /var/lib/joe-staged.entry /efi/loader/entries/.joe-$n.tmp
sync /efi/loader/entries/.joe-$n.tmp
mv /efi/loader/entries/.joe-$n.tmp "/efi/loader/entries/joe-$n+3.conf"
rm -f /var/lib/joe-staged /var/lib/joe-staged.entry
sync
echo "JOE-FINALIZE deployment=$n" > /dev/ttyS0
"""

FINALIZE_UNIT = """[Unit]
Description=joe finalize staged upgrade (prototype)
DefaultDependencies=no
RequiresMountsFor=/efi /var
After=local-fs.target systemd-journal-flush.service
Before=basic.target final.target
Conflicts=final.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/true
ExecStop=/usr/local/bin/joe-finalize
TimeoutStopSec=5min
"""


class Contract:
    def __init__(self, vm):
        self.vm = vm
        self.kernel = None
        self.options = None

    def write(self, path, content, mode=None):
        blob = base64.b64encode(content.encode()).decode()
        self.vm.run(f"echo {blob} | base64 -d > {path}")
        if mode:
            self.vm.run(f"chmod {mode} {path}")

    def learn_entry(self):
        text = self.vm.run("cat /efi/loader/entries/joe-1.conf")
        self.kernel = re.search(r"^linux (.+)$", text, re.M).group(1).strip()
        self.options = re.search(r"^options (.+)$", text, re.M).group(1).strip()

    def entry_text(self, deployment, priority):
        options = re.sub(r"subvol=joe/deploy/\d+", f"subvol=joe/deploy/{deployment}", self.options)
        return (
            f"title joe Linux (deployment {deployment})\n"
            f"sort-key joe\nversion {priority}\nlinux {self.kernel}\noptions {options}\n"
        )

    def write_entry(self, deployment, priority, tries=None):
        self.vm.run(f"rm -f /efi/loader/entries/joe-{deployment}.conf /efi/loader/entries/joe-{deployment}+*.conf")
        suffix = f"+{tries}" if tries is not None else ""
        self.write(f"/efi/loader/entries/joe-{deployment}{suffix}.conf", self.entry_text(deployment, priority))

    def mount_top(self):
        self.vm.run(
            "mkdir -p /run/top; mountpoint -q /run/top || "
            "mount -o subvolid=5 \"$(findmnt -rno SOURCE / | sed 's/\\[.*//')\" /run/top"
        )

    def snapshot(self, deployment):
        self.mount_top()
        self.vm.run(f"btrfs subvolume snapshot / /run/top/joe/deploy/{deployment}")

    def entries(self):
        return self.vm.run("ls /efi/loader/entries/").split()

    def expect_subvol(self, deployment):
        got = self.vm.current_subvol()
        assert got == f"joe/deploy/{deployment}", f"expected deployment {deployment}, booted {got}"


def step(text):
    print(f"--- {text}", flush=True)


def main():
    image = sys.argv[1]
    with VM(image, "boot-contract") as vm:
        c = Contract(vm)
        vm.start()
        vm.wait_boot()
        c.learn_entry()
        c.expect_subvol(1)

        step("1. highest version boots")
        c.snapshot(2)
        c.write_entry(2, priority=2)
        vm.reboot()
        c.expect_subvol(2)

        step("2. raising an older deployment's version is a persistent rollback")
        c.write_entry(1, priority=3)
        vm.reboot()
        c.expect_subvol(1)
        vm.reboot()
        c.expect_subvol(1)

        # Install the prototypes into deployment 1 so later snapshots inherit them.
        c.write("/usr/local/bin/joe-boot-check", BOOT_CHECK, "755")
        c.write("/etc/systemd/system/joe-boot-check.service", BOOT_CHECK_UNIT)
        vm.run("mkdir -p /etc/systemd/system/boot-complete.target.requires && "
               "ln -sf ../joe-boot-check.service /etc/systemd/system/boot-complete.target.requires/")
        c.write("/usr/local/bin/joe-finalize", FINALIZE, "755")
        c.write("/etc/systemd/system/joe-finalize.service", FINALIZE_UNIT)
        vm.run("mkdir -p /etc/systemd/system/multi-user.target.wants && "
               "ln -sf ../joe-finalize.service /etc/systemd/system/multi-user.target.wants/")

        step("3. a counted entry is blessed only after the health check passes")
        c.snapshot(3)
        c.write_entry(3, priority=4, tries=3)
        vm.buffer = b""
        vm.send("systemctl reboot\n")
        m = vm.expect(rb"JOE-HEALTH subvol=(\S+) result=(\w+)\r?\n", 240)
        assert m.group(1) == b"joe/deploy/3" and m.group(2) == b"ok", m.group(0)
        vm.wait_prompt()
        c.expect_subvol(3)
        for _ in range(30):
            if vm.run("systemctl is-active systemd-bless-boot.service", check=False).strip() == "active":
                break
            time.sleep(1)
        print(vm.run("systemctl show -p ActiveEnterTimestampMonotonic joe-boot-check.service systemd-bless-boot.service"))
        entries = c.entries()
        assert "joe-3.conf" in entries, f"entry was not blessed: {entries}"
        order = vm.run("systemctl show -p After systemd-bless-boot.service")
        assert "boot-complete.target" in order, order
        # No check runs on an ordinary (uncounted) boot.
        vm.reboot()
        c.expect_subvol(3)
        assert vm.run("systemctl is-active boot-complete.target", check=False).strip() != "active"

        step("4. a failing health check falls back unattended")
        c.snapshot(4)
        vm.run("touch /run/top/joe/deploy/4/etc/joe-fail-health")
        c.write_entry(4, priority=5, tries=3)
        vm.buffer = b""
        vm.send("systemctl reboot\n")
        for attempt in range(3):
            m = vm.expect(rb"JOE-HEALTH subvol=(\S+) result=(\w+)\r?\n", 240)
            assert m.group(1) == b"joe/deploy/4" and m.group(2) == b"fail", m.group(0)
            print(f"    attempt {attempt + 1} failed its health check")
        vm.wait_boot(300)
        c.expect_subvol(3)
        entries = c.entries()
        assert "joe-4+0-3.conf" in entries, f"deployment 4 not marked bad: {entries}"

        step("5. an unmountable root falls back unattended")
        c.write_entry(5, priority=6, tries=3)
        vm.buffer = b""
        vm.send("systemctl reboot\n")
        for attempt in range(3):
            vm.expect(rb"Kernel panic - not syncing: VFS: Unable to mount root fs", 240)
            print(f"    attempt {attempt + 1} panicked")
        vm.wait_boot(300)
        c.expect_subvol(3)
        entries = c.entries()
        assert "joe-5+0-3.conf" in entries, f"deployment 5 not marked bad: {entries}"

        step("6. a stop job snapshots and writes the entry during shutdown")
        c.write("/var/lib/joe-staged.entry", c.entry_text(6, 7))
        vm.run("echo 6 > /var/lib/joe-staged")
        vm.run("echo edited-after-staging > /etc/joe-late-edit")
        assert not any(e.startswith("joe-6") for e in c.entries()), "entry exists before finalize"
        vm.buffer = b""
        vm.send("systemctl reboot\n")
        vm.expect(rb"JOE-FINALIZE deployment=6\r?\n", 240)
        m = vm.expect(rb"JOE-HEALTH subvol=(\S+) result=(\w+)\r?\n", 240)
        assert m.group(1) == b"joe/deploy/6" and m.group(2) == b"ok", m.group(0)
        vm.wait_prompt()
        c.expect_subvol(6)
        assert vm.run("cat /etc/joe-late-edit").strip() == "edited-after-staging"

        step("7. a power cut before the stop job changes nothing")
        c.write("/var/lib/joe-staged.entry", c.entry_text(7, 8))
        vm.run("echo 7 > /var/lib/joe-staged; sync")
        vm.power_cut()
        c.expect_subvol(6)
        assert vm.run("cat /var/lib/joe-staged").strip() == "7", "staged marker lost"
        assert not any(e.startswith("joe-7") for e in c.entries()), "entry appeared without finalize"

        print("boot contract holds")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, Timeout) as err:
        print(f"FAILED: {err}")
        sys.exit(1)
