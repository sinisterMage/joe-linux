# The joe Linux installer

A Qt Quick front end to `dave install-system`, which does all of the work.
It runs in the live session of the installation medium (image/live.zon),
opened automatically by the joe-live package.

- `dave install-system --list --json` (as the live user) lists the disks and
  says which can be used and why not.
- `dave install-system --disk PATH --json` (as root, through pkexec, inside
  systemd-inhibit) erases the disk and installs what the medium's
  joe/install.zon names, one JSON object per line on standard output:
  `{"event":"step"|"progress"|"done"|"error","message":...,"fraction":...}`.

The installer asks only which disk to use. Language, keyboard, time zone and
the account are asked by GNOME's initial setup on the installed system's
first boot.

`joe-installer --autotest DISK` goes through the same pages unattended and
exits 0 when the installation succeeded; tests/vm/install.py uses it.

Built by packages/joe-installer, whose build copies this directory into the
recipe (bootstrap/build-packages.sh).
