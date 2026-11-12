#!/usr/bin/env python3
"""End-to-end test of dave's deployments in a real VM: upgrade, late edits,
rollback, live install, power loss, and unattended recovery from a broken
upgrade.

    deployments.py            on the scaffold (host kernel, borrowed userspace)
    deployments.py --joe      on an image built entirely from joe's own packages
"""

import os
import re
import subprocess
import sys
import time

from harness import VM, Timeout, TOP, BOOT_BANNER
from repo import Repo, GUEST_HOST, GUEST_URL, script, serve_directory


def step(text):
    print(f"--- {text}", flush=True)


def entries(vm):
    return vm.run("ls /efi/loader/entries/").split()


def deployments(vm):
    return sorted(int(d) for d in vm.run("ls /run/dave/top/joe/deploy/").split() if d.isdigit())


def expect_running(vm, deployment):
    got = vm.current_subvol()
    assert got == f"joe/deploy/{deployment}", f"expected deployment {deployment}, running {got}"
    assert f"Running deployment {deployment}." in vm.run("dave status")


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
    expect_running(vm, deployment)
    wait_blessed(vm, deployment)
    assert vm.run("systemctl is-active dave-boot-check.service", check=False).strip() == "active"
    assert "An upgrade is ready" not in vm.run("dave status")


def publish_v1(repo):
    repo.package("hello", "1.0-r1", {"usr/bin/hello": script("echo hello v1")})
    repo.package("release-marker", "1-r1", {"usr/lib/release-marker": "1\n"})
    repo.index()


BASE_PORT = 8643


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
        image = os.path.join(TOP, "build", "images", "joe.img")
        subprocess.run([
            os.path.join(TOP, "image", "mkjoe.sh"), "--test",
            "--repo", f"joe,{base},http://{GUEST_HOST}:{BASE_PORT},{base_key}",
            "--repo", f"test,{repo.path},{GUEST_URL},{repo.public_key}",
            image, "joe-base", "hello", "release-marker",
        ], check=True)
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
    repo.package("release-marker", "2-r1", {"usr/lib/release-marker": "2\n"})
    repo.index()
    out = vm.run("dave upgrade", timeout=300)
    assert "upgrade  hello  1.0-r1 -> 2.0-r1" in out, out
    assert "The running system has not been changed." in out, out
    assert vm.run("hello").strip() == "hello v1"
    assert deployments(vm) == [1], deployments(vm)
    assert entries(vm) == ["joe-1.conf"], entries(vm)
    assert "An upgrade is ready" in vm.run("dave status")

    step("upgrade: applied at shutdown, including changes made after it was prepared")
    vm.run("echo made-after-upgrade > /etc/late-edit")
    reboot_into_upgrade(vm, 2)
    expect_running(vm, 2)
    assert vm.run("hello").strip() == "hello v2"
    assert vm.run("cat /usr/lib/release-marker").strip() == "2"
    assert vm.run("cat /etc/late-edit").strip() == "made-after-upgrade"
    assert "Everything is up to date." in vm.run("dave upgrade", timeout=300)

    step("rollback: returns to the previous system and stays there")
    assert "Deployment 1 will start on the next boot" in vm.run("dave rollback")
    vm.reboot()
    expect_running(vm, 1)
    assert vm.run("hello").strip() == "hello v1"
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

    step("an upgrade killed while it is being prepared leaves the system as it was")
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
    assert vm.run("ls -A /run/dave/top/joe/deploy/ | grep -c scratch", check=False).strip() == "0"

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
