#!/usr/bin/env python3
"""Boots the joe Linux desktop image and checks that it is a working desktop:
the display manager starts, a user session with GNOME Shell on Wayland comes
up, and the core applications launch. Screenshots are saved under
build/images/vm-desktop/ for a person to look at.
"""

import os
import subprocess
import sys
import time

from harness import VM, Timeout, TOP
from repo import GUEST_HOST

BASE_PORT = 8643
# What a program started from the shell's own launcher would inherit.
SESSION_ENV = (
    "XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 "
    "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus "
    "XDG_CURRENT_DESKTOP=GNOME XDG_SESSION_TYPE=wayland XDG_SESSION_DESKTOP=gnome"
)


def step(text):
    print(f"--- {text}", flush=True)


def wait_for(vm, description, command, timeout=180):
    """Polls a guest command until it succeeds."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        out = vm.run(f"{command} >/dev/null 2>&1; echo status=$?", check=False)
        if out.strip().endswith("status=0"):
            return
        time.sleep(3)
    raise AssertionError(f"timed out waiting for {description}")


def in_session(command):
    """A command run as the logged-in user, inside their graphical session."""
    return f"su joe -c '{SESSION_ENV} {command}'"


def build_image():
    overlay = os.path.join(TOP, "build", "joe", "desktop-overlay")
    os.makedirs(os.path.join(overlay, "etc", "gdm"), exist_ok=True)
    # Log the test user in without asking, so the session can be examined.
    with open(os.path.join(overlay, "etc", "gdm", "custom.conf"), "w") as f:
        f.write("[daemon]\nAutomaticLoginEnable=True\nAutomaticLogin=joe\n")
    base = os.path.join(TOP, "build", "repo")
    key = os.path.join(TOP, "build", "keys", "joe.pub")
    image = os.path.join(TOP, "build", "images", "joe-desktop.img")
    subprocess.run([
        os.path.join(TOP, "image", "mkjoe.sh"), "--test", "--overlay", overlay, "--root-size", "16G",
        "--repo", f"joe,{base},http://{GUEST_HOST}:{BASE_PORT},{key}",
        image, "joe-desktop", "joe-test-desktop",
    ], check=True)
    return image


APPLICATIONS = (
    ("Terminal", "gnome-terminal", "gnome-terminal-server"),
    ("Files", "nautilus", "nautilus"),
    ("Text Editor", "gnome-text-editor", "gnome-text-editor"),
    ("Settings", "gnome-control-center", "gnome-control-center"),
)


def check_desktop(vm, tag):
    """The checks that make up "a working desktop". `tag` names the screenshots."""
    step("the system finishes booting and the display manager is running")
    wait_for(vm, "the system to finish booting", "systemctl is-active graphical.target", 300)
    wait_for(vm, "gdm", "systemctl is-active gdm.service")
    failed = vm.run("systemctl --failed --no-legend --plain", check=False).strip()
    print(f"    failed units: {failed or 'none'}")

    step("a user session with GNOME Shell on Wayland comes up")
    wait_for(vm, "the user's session", "loginctl show-user joe -p State | grep -q active", 240)
    wait_for(vm, "gnome-shell", "pgrep -u joe -x gnome-shell", 240)
    wait_for(vm, "the Wayland socket", "test -S /run/user/1000/wayland-0")
    session = vm.run("loginctl show-session $(loginctl list-sessions --no-legend | awk '$3==\"joe\"{print $1; exit}') -p Type -p Class")
    print("    " + session.strip().replace("\n", "  "))
    assert "Type=wayland" in session, session
    time.sleep(15)
    vm.screenshot(os.path.join(vm.workdir, f"{tag}-1-session.png"))

    step("the core applications start")
    for name, command, process in APPLICATIONS:
        vm.run(in_session(f"{command} >/tmp/{command}.log 2>&1 &"), check=False)
        # The program itself, not the shell that launched it: a command line
        # whose first word is the program.
        running = f"pgrep -u joe -f \"^[^ ]*{process}( |\\$)\""
        try:
            wait_for(vm, name, running, 60)
            time.sleep(15)
            still = vm.run(f"{running} >/dev/null; echo status=$?", check=False).strip()
            assert still.endswith("status=0"), f"{name} exited"
            print(f"    {name}: running")
        except AssertionError as err:
            print(f"    {name}: FAILED ({err})")
            print(vm.run(f"tail -n 15 /tmp/{command}.log", check=False))
            raise
    vm.screenshot(os.path.join(vm.workdir, f"{tag}-2-applications.png"))

    step("the session's services")
    for unit in ("pipewire.service", "wireplumber.service", "xdg-desktop-portal.service"):
        state = vm.run(in_session(f"systemctl --user is-active {unit}"), check=False).strip()
        print(f"    {unit}: {state}")
        assert state == "active", f"{unit} is {state}"
    network = vm.run("nmcli -t -f DEVICE,STATE device | paste -sd' '", check=False).strip()
    print(f"    network: {network}")
    assert ":connected" in network, network


def main():
    image = sys.argv[1] if len(sys.argv) > 1 else build_image()
    with VM(image, "desktop", memory="6G", cpus=8, display=True) as vm:
        vm.start()
        vm.wait_boot(600)
        assert vm.run("cat /sys/kernel/security/joe/enforce").strip() == "0"
        check_desktop(vm, "log")

        step("the same desktop with the security module enforcing from boot")
        vm.run("sed -i '/^options /s/$/ joe=enforce/' /efi/loader/entries/joe-1.conf; sync")
        vm.reboot(600)
        assert vm.run("cat /sys/kernel/security/joe/enforce").strip() == "1"
        check_desktop(vm, "enforce")
        denials = vm.run("dmesg | grep 'joe: denied'", check=False).strip()
        count = len(denials.splitlines()) if denials else 0
        print(f"    denials since boot: {count}")
        if denials:
            print("\n".join("      " + l.split("joe: ", 1)[-1] for l in denials.splitlines()[:25]))
        print(f"screenshots: {vm.workdir}")
    print("desktop scenarios passed")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, Timeout) as err:
        print(f"FAILED: {err}")
        sys.exit(1)
