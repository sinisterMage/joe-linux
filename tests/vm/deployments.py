#!/usr/bin/env python3
"""End-to-end test of dave's deployments in a real VM: upgrade, late edits,
boot loader update, rollback, live install, nested subvolumes, power loss,
unattended recovery from a broken upgrade, and what users without root see.

    deployments.py            on the scaffold (host kernel, borrowed userspace)
    deployments.py --joe      on an image built entirely from joe's own packages
"""

import os
import re
import subprocess
import sys
import time

from harness import VM, Timeout, TOP, BOOT_BANNER, build_image
from repo import Repo, GUEST_HOST, GUEST_URL, script, serve_directory


def step(text):
    print(f"--- {text}", flush=True)


def entries(vm):
    return vm.run("ls /efi/loader/entries/").split()


def deployments(vm):
    return sorted(int(d) for d in vm.run("ls /run/dave/top/joe/deploy/").split() if d.isdigit())


def scratch_left(vm):
    return vm.run("ls -A /run/dave/top/joe/deploy/ | grep -c scratch", check=False).strip()


def nested_in(vm, deployment):
    """The subvolumes nested in a deployment, as btrfs lists them."""
    return vm.run(f"btrfs subvolume list -o /run/dave/top/joe/deploy/{deployment}").strip()


def as_user(vm, command, check=True):
    """Runs a command as a user without any privileges. joe's util-linux has
    neither setpriv nor runuser, and su from root asks for no password, but
    Arch's nobody has expired: the account is the test's own. It is a system
    account, made in deployment 1 before any other exists, so every
    deployment has it and rollback has no person to warn about."""
    vm.run("id dave-user >/dev/null 2>&1 || useradd --system --no-create-home --home-dir / --shell /bin/sh dave-user")
    return vm.run(f"su dave-user -c 'cd / && {command}'", check=check)


def wait_published(vm):
    """Waits for dave-status.service, which publishes the state at boot."""
    for _ in range(60):
        if vm.run("systemctl is-active dave-status.service", check=False).strip() == "active":
            return
        time.sleep(1)
    raise AssertionError("dave-status.service never ran: " + vm.run("systemctl status dave-status.service --no-pager", check=False))


def expect_running(vm, deployment):
    got = vm.current_subvol()
    assert got == f"joe/deploy/{deployment}", f"expected deployment {deployment}, running {got}"
    status = vm.run("dave status")
    assert f"Running deployment {deployment}." in status, status
    # Root's dave has just published what it showed; a user sees the same.
    seen = as_user(vm, "dave status")
    assert seen == status, f"a user sees:\n{seen}\nroot sees:\n{status}"


def digest(vm, path):
    return vm.run(f"sha256sum < {path}").split()[0]


def wait_blessed(vm, deployment):
    for _ in range(60):
        if f"joe-{deployment}.conf" in entries(vm):
            return
        time.sleep(1)
    raise AssertionError(f"deployment {deployment} was never marked good: {entries(vm)}")


def reboot_into_upgrade(vm, deployment):
    """Reboots into a prepared upgrade and checks that it was applied during
    shutdown, passed its boot check and was marked good. State is read back
    with commands rather than matched on the console, where kernel messages
    can land in the middle of a line."""
    vm.reboot(300)
    assert vm.current_subvol() == f"joe/deploy/{deployment}", vm.current_subvol()
    wait_blessed(vm, deployment)
    # Published at boot, after the boot was marked good, so a user sees what
    # root does before root has run dave at all.
    wait_published(vm)
    published = as_user(vm, "dave status")
    expect_running(vm, deployment)
    assert published == vm.run("dave status"), published
    assert vm.run("systemctl is-active dave-boot-check.service", check=False).strip() == "active"
    assert "An upgrade is ready" not in vm.run("dave status")


def publish_v1(repo):
    repo.package("hello", "1.0-r1", {"usr/bin/hello": script("echo hello v1")})
    repo.package("release-marker", "1-r1", {"usr/lib/release-marker": "1\n"})
    repo.index()


BASE_PORT = 8643
# systemd-boot as the system ships it, and its two copies on the ESP.
LOADER = "/usr/lib/systemd/boot/efi/systemd-bootx64.efi"
LOADER_COPIES = ("/efi/EFI/systemd/systemd-bootx64.efi", "/efi/EFI/BOOT/BOOTX64.EFI")


def main():
    joe = "--joe" in sys.argv[1:]
    subprocess.run(["zig", "build", "-Doptimize=ReleaseSafe"], cwd=os.path.join(TOP, "dave"), check=True)
    repo = Repo()
    publish_v1(repo)
    base_server = None
    if joe:
        # The base system comes from joe's own repository; the test packages
        # from a second one, as a third-party repository would be.
        base = os.path.join(TOP, "build", "repo")
        base_key = os.path.join(TOP, "build", "keys", "joe.pub")
        image = build_image("console", os.path.join(TOP, "build", "images", "joe.img"), repos=[
            ("joe", base, f"http://{GUEST_HOST}:{BASE_PORT}", base_key),
            ("test", repo.path, GUEST_URL, repo.public_key),
        ], extra=["hello", "release-marker"])
        base_server = serve_directory(base, BASE_PORT)
    else:
        image = os.path.join(TOP, "build", "images", "scaffold-dave.img")
        subprocess.run([
            os.path.join(TOP, "image", "mkscaffold-dave.sh"), repo.path, repo.public_key, GUEST_URL, image,
            "hello", "release-marker",
        ], check=True)
    repo.serve()
    try:
        with VM(image, "deployments-joe" if joe else "deployments") as vm:
            vm.start()
            vm.wait_boot()
            if joe:
                print(vm.run("cat /etc/os-release; uname -r"))
            scenarios(vm, repo)
    finally:
        repo.stop()
        if base_server:
            base_server.terminate()
            base_server.wait()
    print("deployment scenarios passed")


def scenarios(vm, repo):
    step("baseline: the image boots with dave managing deployment 1")
    expect_running(vm, 1)
    assert vm.run("hello").strip() == "hello v1"
    assert "hello 1.0-r1" in vm.run("dave list")

    step("upgrade: prepared without touching the running system")
    repo.package("hello", "2.0-r1", {"usr/bin/hello": script("echo hello v2")})
    repo.package("release-marker", "2-r1", {
        "usr/lib/release-marker": "2\n",
        # A directory systemd-tmpfiles makes a subvolume of where it can, as it
        # does systemd's own /var/lib/machines, and a trigger that runs it when
        # the upgrade is applied (the scaffold has no joe systemd to do that).
        "usr/lib/tmpfiles.d/dave-test.conf": "v /var/lib/dave-test 0755 - - -\n",
        "usr/lib/dave/triggers/90-dave-test.zon":
            '.{ .paths = .{"usr/lib/tmpfiles.d/"}, .exec = .{ "/usr/bin/systemd-tmpfiles", "--create", "/usr/lib/tmpfiles.d/dave-test.conf" } }\n',
    })
    repo.index()
    out = vm.run("dave upgrade", timeout=300)
    assert re.search(r"^\s+hello\s+1\.0-r1 -> 2\.0-r1", out, re.M), out
    assert "The running system has not been changed." in out, out
    assert vm.run("hello").strip() == "hello v1"
    assert deployments(vm) == [1], deployments(vm)
    # The rehearsal ran the trigger in a scratch snapshot, which is gone.
    assert scratch_left(vm) == "0", vm.run("ls -A /run/dave/top/joe/deploy/")
    assert entries(vm) == ["joe-1.conf"], entries(vm)
    assert "An upgrade is ready" in vm.run("dave status")

    step("upgrade: applied at shutdown, including changes made after it was prepared")
    vm.run("echo made-after-upgrade > /etc/late-edit")
    # Make the boot loader on the ESP an older release than the one the system
    # ships, as it would be after an upgrade of systemd: the version it states
    # about itself is rewritten in place. It is replaced before it ever runs.
    for copy in LOADER_COPIES:
        vm.run(f"LC_ALL=C sed -i 's/\\(#### LoaderInfo: systemd-boot \\)[0-9][0-9][0-9]/\\1100/' {copy}")
        assert digest(vm, copy) != digest(vm, LOADER)
    vm.run("sync")
    reboot_into_upgrade(vm, 2)
    expect_running(vm, 2)
    assert vm.run("hello").strip() == "hello v2"
    assert vm.run("cat /usr/lib/release-marker").strip() == "2"
    assert vm.run("cat /etc/late-edit").strip() == "made-after-upgrade"
    assert "Everything is up to date." in vm.run("dave upgrade", timeout=300)

    step("upgrade: the trigger's subvolume is in the shared /var, not hidden in the deployment")
    assert nested_in(vm, 2) == "", nested_in(vm, 2)
    assert vm.run("test -d /var/lib/dave-test; echo $?").strip() == "0"

    step("upgrade: the newer boot loader reached the ESP, and has just booted this system")
    for copy in LOADER_COPIES:
        assert digest(vm, copy) == digest(vm, LOADER), f"{copy} was not updated"

    step("rollback: returns to the previous system and stays there")
    # Someone given an account since the upgrade does not exist in the system
    # being returned to: /etc belongs to the deployment.
    vm.run("useradd -u 1234 late")
    out = vm.run("dave rollback")
    assert "Deployment 1 will start on the next boot" in out, out
    assert "deployment 1 was made before these accounts were created: late." in out, out
    vm.reboot()
    expect_running(vm, 1)
    assert vm.run("hello").strip() == "hello v1"
    assert vm.run("id late >/dev/null 2>&1; echo $?").strip() == "1"
    vm.reboot()
    expect_running(vm, 1)

    step("install: takes effect immediately and leaves a way back")
    repo.package("moo", "1.0-r1", {"usr/bin/moo": script("echo moo")})
    repo.index()
    out = vm.run("dave install moo", timeout=300)
    assert "Saved the current system as deployment 3." in out, out
    assert vm.run("moo").strip() == "moo"
    expect_running(vm, 1)
    assert "Deployment 3 will start on the next boot" in vm.run("dave rollback")
    vm.reboot()
    expect_running(vm, 3)
    assert vm.run("command -v moo", check=False).strip() == ""
    assert vm.run("hello").strip() == "hello v1"

    step("nested subvolumes: hidden ones are cleared, others refused by name")
    # Where dave 0.2.1's upgrades left subvolumes: in the deployment's own
    # /var, under the shared one, out of reach of the running system.
    vm.run("mkdir -p /run/dave/top/joe/deploy/3/var/lib && btrfs subvolume create /run/dave/top/joe/deploy/3/var/lib/left-behind")
    vm.run("mkdir -p /opt && btrfs subvolume create /opt/nested")
    out = vm.run("dave upgrade 2>&1", timeout=300, check=False)
    assert "nested btrfs subvolumes (/opt/nested)" in out, out
    assert vm.run("test -e /run/dave/top/joe/deploy/3/var/lib/left-behind; echo $?").strip() == "1"
    vm.run("btrfs subvolume delete /opt/nested")
    out = vm.run("dave upgrade", timeout=300)
    assert "will be applied when the system shuts down" in out, out
    assert nested_in(vm, 3) == "", nested_in(vm, 3)

    step("users without root: status, deployments, search and upgrade --check, but not the top level")
    assert as_user(vm, "dave deployments") == vm.run("dave deployments")
    assert re.search(r"^hello\s+2\.0-r1\b", as_user(vm, "dave search hello"), re.M)
    out = as_user(vm, "dave upgrade --check")
    assert re.search(r"^\s+hello\s+1\.0-r1 -> 2\.0-r1", out, re.M), out
    assert "An upgrade is already prepared" in out, out
    # Refused before anything is touched, saying how to do it.
    out = as_user(vm, "dave install moo 2>&1", check=False)
    assert "installing packages needs root; run it with sudo: sudo dave install moo" in out, out
    assert as_user(vm, "ls /run/dave/top >/dev/null 2>&1; echo $?").strip() != "0"
    assert vm.run("stat -c %a /run/dave/top").strip() == "700"
    assert "nosuid" in vm.run("findmnt -no OPTIONS /run/dave/top")

    step("an upgrade killed while it is being prepared leaves the system as it was")
    # A rehearsal's leftover from dave 0.2.1, holding a subvolume of its own.
    vm.run("btrfs subvolume create /run/dave/top/joe/deploy/.scratch-old && "
           "btrfs subvolume create /run/dave/top/joe/deploy/.scratch-old/inner")
    before = (deployments(vm), entries(vm))
    out = vm.run("dave upgrade >/dev/null 2>&1 & pid=$!; sleep 0.05; kill -9 $pid; wait $pid; echo status=$?", check=False)
    print(f"    {out.strip().splitlines()[-1]} (137 means the kill landed mid-run)")
    expect_running(vm, 3)
    assert vm.run("hello").strip() == "hello v1"
    assert entries(vm) == before[1], entries(vm)
    # Whatever the kill left behind (a scratch snapshot, a half-written state
    # file), the lock is free and housekeeping restores a clean slate.
    vm.run("dave deployments gc")
    assert deployments(vm) == before[0], deployments(vm)
    assert scratch_left(vm) == "0", vm.run("ls -A /run/dave/top/joe/deploy/")

    step("power loss between preparing an upgrade and shutting down")
    out = vm.run("dave upgrade", timeout=300)
    assert "will be applied when the system shuts down" in out, out
    vm.run("sync")
    vm.power_cut()
    expect_running(vm, 3)
    assert vm.run("hello").strip() == "hello v1"
    assert "An upgrade is ready" in vm.run("dave status")
    reboot_into_upgrade(vm, 4)
    expect_running(vm, 4)
    assert vm.run("hello").strip() == "hello v2"

    step("a broken upgrade is abandoned with nobody at the keyboard")
    repo.package("release-marker", "3-r1", {
        "usr/lib/release-marker": "3\n",
        "etc/dave/boot-check.d/always-fail": script("echo this release is broken; exit 1"),
    })
    repo.index()
    vm.run("dave upgrade", timeout=300)
    # Three attempts at deployment 5, then the boot loader gives up on it: four
    # boots in all before a system stays up. Each begins with the firmware's
    # banner, which nothing can interleave with.
    vm.buffer = b""
    vm.send("systemctl reboot\n")
    for attempt in range(3):
        vm.expect(re.escape(BOOT_BANNER), 300)
        print(f"    attempt {attempt + 1} at the broken deployment")
    vm.wait_boot(300)
    expect_running(vm, 4)
    assert vm.run("cat /usr/lib/release-marker").strip() == "2"
    # The entry name records that all three attempts were used and failed.
    assert "joe-5+0-3.conf" in entries(vm), entries(vm)
    journal = vm.run("journalctl -b -1 -u dave-boot-check.service --no-pager -o cat 2>/dev/null | tail -n 5", check=False)
    assert "boot check failed" in journal, journal
    status = vm.run("dave status")
    print(status)
    assert "failed" in status, status

    step("garbage collection removes the failed and the oldest deployments")
    vm.run("dave deployments gc")
    left = deployments(vm)
    assert 5 not in left and 4 in left, left
    assert not any(e.startswith("joe-5") for e in entries(vm)), entries(vm)
    print(vm.run("dave deployments"))


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, Timeout) as err:
        print(f"FAILED: {err}")
        sys.exit(1)
