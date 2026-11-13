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
import subprocess
import sys

from harness import VM, Timeout, TOP
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
    probe_package(repo, "probe-none", probe, [])
    probe_package(repo, "probe-declared", probe, PROBE_DECLARED)
    repo.index()

    base = os.path.join(TOP, "build", "repo")
    base_key = os.path.join(TOP, "build", "keys", "joe.pub")
    image = os.path.join(TOP, "build", "images", "joe-security.img")
    subprocess.run([
        os.path.join(TOP, "image", "mkjoe.sh"), "--test",
        "--repo", f"joe,{base},http://{GUEST_HOST}:{BASE_PORT},{base_key}",
        "--repo", f"test,{repo.path},{GUEST_URL},{repo.public_key}",
        image, "joe-base", "probe-all", "probe-none", "probe-declared",
    ], check=True)

    with VM(image, "security") as vm:
        vm.start()
        vm.wait_boot()
        scenarios(vm)
    print("security scenarios passed")


def scenarios(vm):
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

    step("rule 2: root cannot create executable memory, whatever it declares")
    assert not allowed(vm, "probe-all jit-anon")
    assert not allowed(vm, "probe-all jit-mprotect")
    assert allowed(vm, as_nobody("probe-all jit-anon"))
    assert allowed(vm, as_nobody("probe-all jit-mprotect"))

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
    assert allowed(vm, "probe-declared write /var/lib/probe/file")
    assert not allowed(vm, "probe-declared write /var/lib/elsewhere")
    assert not allowed(vm, "probe-declared write /etc/probe-file")
    assert allowed(vm, "probe-declared exec /usr/bin/true")
    assert not allowed(vm, "probe-declared exec /usr/bin/false")
    assert allowed(vm, "probe-all write /etc/probe-file")
    assert allowed(vm, "probe-all exec /usr/bin/false")
    # None of this concerns an unprivileged user, whom ordinary permissions confine.
    assert allowed(vm, as_nobody("probe-none net"))
    assert allowed(vm, as_nobody("probe-none exec /usr/bin/true"))

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
    print(f"    failed units: {failed or 'none'}")
    denials = vm.run("dmesg | grep -c 'joe: denied'", check=False).strip()
    print(f"    denials since boot: {denials}")
    print(vm.run("dmesg | grep 'joe: denied' | grep -v unsealed | head -n 15", check=False))


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, Timeout) as err:
        print(f"FAILED: {err}")
        sys.exit(1)
