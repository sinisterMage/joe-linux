#!/usr/bin/env python3
"""Boots the joe Linux desktop image and checks that it is a working desktop:
the display manager starts, a user session with GNOME Shell on Wayland comes
up, every application launches, and the things a person does all day work
(a web page renders, sudo, the manual, spell checking, media codecs, the
trash). Screenshots are saved under build/images/vm-desktop/ for a person to
look at.
"""

import os
import shlex
import subprocess
import sys
import time

import harness
from harness import VM, Timeout, TOP
from repo import GUEST_HOST, GUEST_URL, PORT, serve_directory

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
    # image/desktop.zon: the test user joe, logged in without asking so that
    # the session can be examined.
    base = os.path.join(TOP, "build", "repo")
    key = os.path.join(TOP, "build", "keys", "joe.pub")
    image = harness.build_image("desktop", os.path.join(TOP, "build", "images", "joe-desktop.img"), repos=[
        ("joe", base, f"http://{GUEST_HOST}:{BASE_PORT}", key),
    ])
    return image


APPLICATIONS = (
    ("Terminal", "gnome-terminal", "gnome-terminal-server"),
    ("Files", "nautilus", "nautilus"),
    ("Text Editor", "gnome-text-editor", "gnome-text-editor"),
    ("Settings", "gnome-control-center", "gnome-control-center"),
)


# The rest of what is installed: (name, command, the name it takes on the
# session bus once it is running). The two that take no name are looked for
# as processes instead.
MORE_APPLICATIONS = (
    ("Image Viewer", "loupe", "org.gnome.Loupe"),
    ("Document Viewer", "evince", "process:evince"),
    ("Video Player", "showtime", "org.gnome.Showtime"),
    ("Audio Player", "org.gnome.Decibels", "org.gnome.Decibels"),
    ("Calculator", "gnome-calculator", "process:gnome-calculator"),
    ("Clocks", "gnome-clocks", "org.gnome.clocks"),
    ("Weather", "gapplication launch org.gnome.Weather", "org.gnome.Weather"),
    ("Maps", "gapplication launch org.gnome.Maps", "org.gnome.Maps"),
    ("Characters", "gnome-characters", "org.gnome.Characters"),
    ("Fonts", "gnome-font-viewer", "org.gnome.font-viewer"),
    ("Disks", "gnome-disks", "org.gnome.DiskUtility"),
    ("Disk Usage Analyzer", "baobab", "org.gnome.baobab"),
    ("Archive Manager", "file-roller", "org.gnome.FileRoller"),
    ("System Monitor", "gnome-system-monitor", "org.gnome.SystemMonitor"),
)


def bus(method, name):
    return in_session(
        "gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus "
        f"--method org.freedesktop.DBus.{method} {name}")


def check_applications(vm, tag):
    """Starts each application on its own, sees that it is still there a
    little later, and closes it again."""
    step("every other application starts")
    shots = os.path.join(vm.workdir, f"{tag}-applications")
    os.makedirs(shots, exist_ok=True)
    failed = []
    for name, command, identity in MORE_APPLICATIONS:
        log = f"/tmp/{identity}.log"
        if identity.startswith("process:"):
            pattern = f"\"^[^ ]*{identity.split(':')[1]}( |\\$)\""
            running = f"pgrep -u joe -f {pattern}"
            stop = f"pkill -u joe -f {pattern}"
        else:
            running = bus("NameHasOwner", identity) + " | grep -q true"
            stop = "kill $(" + bus("GetConnectionUnixProcessID", identity) + " | tr -dc '0-9 ' | awk '{print $NF}')"
        vm.run(in_session(f"{command} >{log} 2>&1 &"), check=False)
        try:
            wait_for(vm, name, running, 60)
            time.sleep(8)
            still = vm.run(f"{running} >/dev/null 2>&1; echo status=$?", check=False).strip()
            assert still.endswith("status=0"), f"{name} exited"
            vm.screenshot(os.path.join(shots, f"{identity.split(':')[-1]}.png"))
            print(f"    {name}: running")
        except AssertionError as err:
            print(f"    {name}: FAILED ({err})")
            print(vm.run(f"tail -n 15 {log}", check=False))
            failed.append(name)
        vm.run(f"{stop} 2>/dev/null", check=False)
        time.sleep(2)
    assert not failed, "did not start: " + ", ".join(failed)


def check_everyday(vm, tag):
    """What a person expects to just work, beyond windows opening."""
    step("Firefox renders a page served by the host")
    vm.run(in_session(f"firefox --headless --screenshot /tmp/page.png {GUEST_URL}/ >/tmp/firefox-headless.log 2>&1"),
           timeout=180, check=False)
    kind = vm.run("file -b /tmp/page.png; stat -c %s /tmp/page.png", check=False)
    print("    " + " ".join(kind.split()))
    assert "PNG image data" in kind and int(kind.split()[-1]) > 10000, \
        kind + vm.run("tail -n 15 /tmp/firefox-headless.log", check=False)
    vm.run(in_session(f"firefox {GUEST_URL}/ >/tmp/firefox.log 2>&1 &"), check=False)
    wait_for(vm, "Firefox", "pgrep -u joe -x firefox", 60)
    time.sleep(25)
    assert vm.run("pgrep -u joe -x firefox >/dev/null; echo status=$?", check=False).strip().endswith("status=0"), \
        "Firefox exited\n" + vm.run("tail -n 15 /tmp/firefox.log", check=False)
    vm.screenshot(os.path.join(vm.workdir, f"{tag}-3-firefox.png"))
    vm.run("pkill -u joe -x firefox", check=False)
    for kind in ("x-scheme-handler/https", "text/html"):
        default = vm.run(in_session(f"gio mime {kind}"), check=False).splitlines()[0]
        assert "firefox.desktop" in default, default

    step("an administrator can become root, and the manual is there")
    assert vm.run("su joe -c 'echo joe | sudo -S id -u' 2>/dev/null", check=False).strip() == "0", "sudo did not work"
    assert "list directory contents" in vm.run("su joe -c 'man ls' 2>/dev/null | head -n 8", check=False)
    for tool in ("git", "vim", "nano", "ssh -V", "rsync", "gpg", "wget", "htop", "strace -V"):
        program = tool.split()[0]
        flag = tool.split()[1] if " " in tool else "--version"
        out = vm.run(f"su joe -c '{program} {flag}' >/dev/null 2>&1; echo status=$?", check=False).strip()
        assert out.endswith("status=0"), f"{program} does not run"
    listing = vm.run("su joe -c 'cd /tmp && echo hi > z.txt && zip -q z.zip z.txt && unzip -l z.zip'", check=False)
    assert "z.txt" in listing, listing

    step("text: fonts and spell checking")
    for family, expected in (("sans-serif", "Noto Sans"), ("emoji", "Noto Color Emoji"),
                             ("sans-serif:lang=ja", "Noto Sans CJK JP"), ("Arial", "Liberation Sans")):
        got = vm.run(f"fc-match -f '%{{family}}' '{family}'", check=False).strip()
        assert expected in got, f"{family} is {got}, not {expected}"
    misspelt = vm.run("echo helo world | enchant-2 -d en_US -l", check=False).split()
    assert misspelt == ["helo"], misspelt

    step("media: the common formats have decoders")
    for element in ("avdec_h264", "avdec_aac", "vp9dec", "mpg123audiodec", "opusdec", "gtk4paintablesink"):
        out = vm.run(in_session(f"gst-inspect-1.0 --exists {element}") + "; echo status=$?", check=False).strip()
        assert out.endswith("status=0"), f"GStreamer has no {element}"

    step("files: the trash and other GVfs locations")
    vm.run(in_session("touch /home/joe/discard && gio trash /home/joe/discard"), check=False)
    assert "discard" in vm.run(in_session("gio list trash:///"), check=False)
    for kind, application in (("application/pdf", "org.gnome.Evince.desktop"), ("image/png", "org.gnome.Loupe.desktop"),
                              ("video/mp4", "org.gnome.Showtime.desktop"), ("audio/mpeg", "org.gnome.Decibels.desktop")):
        default = vm.run(in_session(f"gio mime {kind}"), check=False).splitlines()[0]
        assert application in default, default


def check_optional_servers(vm):
    step("optional servers remain off until the administrator starts them")
    state = vm.run("systemctl is-enabled rsyncd.socket", check=False).strip()
    assert state == "disabled", f"rsync daemon socket is {state}"
    assert vm.run("systemctl is-active rsyncd.socket", check=False).strip() == "inactive"
    probe = ('import errno,socket; s=socket.socket(); s.settimeout(5); '
             'assert s.connect_ex(("127.0.0.1",873)) == errno.ECONNREFUSED; s.close()')
    vm.run("su joe -c " + shlex.quote("python3 -c " + shlex.quote(probe)))
    try:
        vm.run("systemctl start rsyncd.socket")
        probe = ('import socket; s=socket.create_connection(("127.0.0.1",873),timeout=5); '
                 'assert s.makefile("rb").readline(128).startswith(b"@RSYNCD:"); s.close()')
        vm.run("su joe -c " + shlex.quote("python3 -c " + shlex.quote(probe)))
    finally:
        vm.run("systemctl stop rsyncd.socket")


def check_desktop(vm, tag):
    """The checks that make up "a working desktop". `tag` names the screenshots."""
    step("the system finishes booting and the display manager is running")
    wait_for(vm, "the system to finish booting", "systemctl is-active graphical.target", 300)
    wait_for(vm, "gdm", "systemctl is-active gdm.service")
    check_optional_servers(vm)
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


def serve_page():
    """A web page on the host for the guest's browser to fetch."""
    site = os.path.join(TOP, "build", "images", "desktop-site")
    os.makedirs(site, exist_ok=True)
    with open(os.path.join(site, "index.html"), "w") as f:
        f.write("<!doctype html><meta charset='utf-8'><title>joe Linux</title><body style='font: 48px sans-serif; background: #268bd2; "
                "color: white'><h1>joe Linux</h1><p>This page was served by the build machine. \u2714 \u65e5\u672c\u8a9e "
                "\U0001F600</p>")
    return serve_directory(site, PORT)


def main():
    image = sys.argv[1] if len(sys.argv) > 1 else build_image()
    site = serve_page()
    try:
        run(image)
    finally:
        site.terminate()
        site.wait()
    print("desktop scenarios passed")


def run(image):
    with VM(image, "desktop", memory="6G", cpus=8, display=True) as vm:
        vm.start()
        vm.wait_boot(600)
        assert vm.run("cat /sys/kernel/security/joe/enforce").strip() == "0"
        check_desktop(vm, "log")
        check_applications(vm, "log")
        check_everyday(vm, "log")

        step("the same desktop with the security module enforcing from boot")
        vm.run("sed -i '/^options /s/$/ joe=enforce/' /efi/loader/entries/joe-1.conf; sync")
        vm.reboot(600)
        assert vm.run("cat /sys/kernel/security/joe/enforce").strip() == "1"
        check_desktop(vm, "enforce")
        check_applications(vm, "enforce")
        denials = vm.run("dmesg | grep 'joe: denied'", check=False).strip()
        count = len(denials.splitlines()) if denials else 0
        print(f"    denials since boot: {count}")
        if denials:
            print("\n".join("      " + l.split("joe: ", 1)[-1] for l in denials.splitlines()[:25]))
        print(f"screenshots: {vm.workdir}")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, Timeout) as err:
        print(f"FAILED: {err}")
        sys.exit(1)
