# The joe Linux installer

A Qt Quick front end to `dave install-system`, which does all of the work.
It runs in the live session of the installation medium (image/live.zon),
opened automatically by the joe-live package.

- `dave install-system --list --json` (as the live user) lists the disks:
  whether each can be erased (`usable`, `reason`), its partitions with where
  they lie (`partitions`: `start`, `size`, `kind`), and whether joe fits in
  its free space beside what is there (`beside`: `possible`, `reason`,
  `start`, `size`, `systems`).
- `dave install-system --disk PATH [--beside] [--enforce] --json` (as root,
  through pkexec, inside systemd-inhibit) erases the disk, or with `--beside`
  adds joe's partitions to its free space, and installs what the medium's
  joe/install.zon names, one JSON object per line on standard output:
  `{"event":"step"|"progress"|"done"|"error","message":...,"fraction":...}`.

The installer asks only which disk to use, and on a disk joe can share,
whether to go beside what is there (the default) or erase it. The
confirmation page also offers "Enforce the security module", off unless
ticked: with it the installed system boots with `joe=enforce` (`--enforce`). Language,
keyboard, time zone and the account are asked by GNOME's initial setup on
the installed system's first boot.

`joe-installer --autotest DISK [--beside] [--enforce]` goes through the same pages
unattended and exits 0 when the installation succeeded; tests/vm/install.tomlx
uses it.

Built by packages/joe-installer, whose build copies this directory into the
recipe (bootstrap/build-packages.sh).
