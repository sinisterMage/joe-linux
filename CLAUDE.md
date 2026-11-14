# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

joe Linux is an independent distribution built from source. Three parts are original and live here; everything else is deliberately ordinary (glibc, systemd, usr-merge, GNOME), so prefer the conventional option when unsure.

1. **dave** (`dave/`): a package manager and deployment tool in Zig, with a PubGrub solver.
2. **Transactional upgrades on a writable root**: btrfs snapshots plus systemd-boot boot counting.
3. **The joe security module** (`packages/linux/joe-lsm/joe.c`): an LSM that restricts privileged processes to signed ("sealed") code and declared operations.

README.md explains the design; `packages/README.md` is the recipe-writing reference. Read the latter before touching anything in `packages/`.

## Hard constraints

- **Nothing runs as root on the host, and sudo is not available.** Root-owned trees are made with `unshare --map-root-user`, build chroots with `bwrap`, disk images with `mkfs.btrfs --rootdir` and mtools (never mounted), and anything that truly needs root runs inside QEMU/KVM. Do not introduce steps that need sudo or docker.
- **Zig 0.17.1.** It uses `pub fn main(init: std.process.Init)` and the `std.Io` interface; older idioms do not compile. Check the std source (`zig env` gives the lib dir) rather than relying on memory. Known traps: a directory opened without `.iterate = true` is path-only and ioctls on it fail with EBADF; `Io.Dir.readFileAlloc` returns 0 bytes for some procfs files; std has zstd decompression only, which is why writing packages pipes through the `zstd` program.
- `build/` must be on btrfs (reflink copies, subvolumes). All generated state lives there and is git-ignored.
- The VM harness and `image/run.sh` hardcode Arch's OVMF paths (`/usr/share/edk2/x64/OVMF_*.4m.fd`).
- **joe boots without an initramfs**, so the kernel mounts the root itself and, until udev has processed the partition, btrfs reports the root's device as `/dev/root`. Anything that needs the root's block device early in boot (systemd-repart, systemd-growfs) must run after udev; `packages/joe-base/build.sh` ships the drop-ins that arrange this.

## Commands

```
make dave                  build dave/zig-out/bin/dave (ReleaseSafe, static, no libc)
make test                  Zig unit tests + tests/cli.sh; takes seconds, no VM
make test-boot-contract    systemd-boot assumptions, in a VM on the scaffold image
make test-deployments      upgrade/rollback/power-loss scenarios on the scaffold image
make bootstrap             LFS cross toolchain and temporary tools (stage1 + stage2)
make packages              build every recipe into build/repo
make image / make run      build/images/joe.img; boot it on this terminal (Ctrl-A X to leave)
make test-joe              deployment scenarios on an image built from joe's own packages
make test-security         the security module's three rules, in a VM
make desktop-image / run-desktop / test-desktop     the GNOME image
make release-image / test-release                   the desktop without test accounts; its first boot, in a VM
make vm / run-vm / serve-repo                       a VM that keeps its disk (build/vm), and build/repo served to it
```

A subset of unit tests (the filter matches test names and file paths such as `solver.version`):

```
cd dave && zig test src/main.zig -target x86_64-linux-none --test-filter "version"
```

`tests/cli.sh` can be run on its own; `DAVE=/path/to/dave` overrides the binary. It works in `build/cli-test`. Its network tests serve the repository from `127.0.0.1` over HTTP and HTTPS (a throwaway CA laid over `/etc/ssl` with `bwrap`), so it needs `openssl` and `python3` as well.

Build specific packages (in dependency order, into the shared build root):

```
bootstrap/build-packages.sh NAME...
```

This is resumable by file name: a package whose `NAME-VERSION-rRELEASE-x86_64.dave` already exists in `build/repo` is skipped. After changing a recipe, bump `.release` in its `package.zon` (or delete the file) or nothing is rebuilt. A failed build's full log is `build/work/NAME/build.log`.

Other tools: `bootstrap/order.py [NAME...]` prints the build order and reports missing recipes and cycles; `bootstrap/enter.sh [--net] CMD` runs a command inside the build root; `packages/.build/book.py [--blfs] PAGE` prints an LFS/BLFS page's commands for writing a recipe.

VM tests are plain Python scripts (`python3 tests/vm/deployments.py [--joe]`, `security.py`, `desktop.py`, `release.py`). Each runs all of its scenarios in sequence on one VM; there is no per-scenario selector. `deployments.py` and `security.py` rebuild dave and their image on every run; `desktop.py` and `release.py` build their image unless given an image path as their argument. Everything the guest prints goes to `build/images/vm-<name>/console.log`, which is where to look after a failure. They serve repositories to the guest on host ports 8642 and 8643.

## Two tiers of test image

- The **scaffold** (`image/mkscaffold*.sh`) is the host's kernel plus a stock Arch userspace with dave added. It exists so deployment mechanics can be tested in minutes without building the distribution. Nothing from it ships, and it has no security module.
- The **joe image** (`image/mkjoe.sh`) is one `dave install` transaction of `joe-base` (or `joe-desktop`) into an empty directory, then `image/mkimage.sh`. It needs `make bootstrap` and `make packages` first, which take an hour or more (the desktop set several hours).

- The **release image** (`make release-image`) is `joe-desktop` alone: no test console, no ready-made user, root locked. GDM starts gnome-initial-setup because no account exists. `tests/vm/release.py` boots the same package set plus `joe-test-console`, because the harness has no other way in.

`--test` images add `joe-test-console`: root is logged in on ttyS0 with the prompt `joe# `, which `tests/vm/harness.py` depends on.

## Architecture

### dave (`dave/src/`)

One static binary serves as package manager, build tool, repository tool and boot-time service. `main.zig` parses arguments and dispatches; each module opens with a `//!` comment stating its design, and those comments are the documentation.

The flow of a change: `etc/dave/world` is the only statement of intent (the Alpine model). `resolve.zig` solves world against the signed repository indexes (`repo.zig`) with `solver/pubgrub.zig`, and the transaction is the difference from what is installed (`db.zig`). `solver/report.zig` turns a failed solve into the prose explanation users see. `txn.zig` applies a transaction to a root directory; it has no undo log and relies on being pointed at a snapshot that can be thrown away.

`install` and `remove` apply live after taking a bootable snapshot. Only `upgrade` is deferred: `deploy.zig` stages a plan, and `dave finalize` at shutdown snapshots the root as it then is, applies the plan to the snapshot, and writes the boot entry last. `boot.zig` keeps no state of its own: priority and health are encoded in systemd-boot entry file names (`joe-<id>+3.conf`), and those assumptions are pinned by `tests/vm/boot_contract.py`.

Invariants that span files:

- The package database is at `usr/lib/dave/db` *inside* the root so every snapshot carries its own. `/etc` belongs to the deployment; `/var` and `/home` are shared subvolumes. That is why nothing under `/var` may be packaged and why system users need fixed ids.
- The manifest (`manifest.zig`) is authoritative for all file metadata; the archive (`archive.zig`) carries regular-file contents only.
- There are no install scripts. Post-install work is a declarative trigger file under `usr/lib/dave/triggers/` (`triggers.zig`).
- `dave build` (`builder.zig`) runs `packages/.build/driver.sh` inside the build root. The driver sources the recipe's `build.sh`, then strips binaries and removes `.la` files, docs and `var`/`run`/`tmp` for every package.

### Seals and the security module

`dave/src/seal.zig` (userspace) and `packages/linux/joe-lsm/joe.c` (kernel) must agree byte for byte on the seal format: fs-verity digest plus a `security.joe` xattr holding the declared operations and a signature over both. Change one and you must change the other, then run `make test-security`.

- The module is not a kernel fork. `packages/linux/joe-lsm/install.sh` copies it into the unpacked kernel tree and splices it in with anchored `sed` edits that fail loudly when a kernel update moves an anchor.
- `joe_keys.h` is generated by `bootstrap/build-packages.sh` from `build/keys/joe-code.pub`. The kernel therefore trusts only packages sealed with this build directory's key; a new key means rebuilding `linux`.
- bash and Python carry patches (`packages/bash/joe-sealed-scripts.patch`, `packages/python/joe-sealed-code.patch`) that ask the module, via an ioctl on the open script, before running it.
- Operations are declared per program in `package.zon` (`.operations`); the vocabulary is validated in `seal.zig`. A program no declaration covers is sealed `undeclared`; `dave repo audit build/repo` (or `make audit-security`) finds those and invalid seals.
- Images are assembled unprivileged and so cannot be sealed at build time; `dave-seal.service` does it on first boot.
- The module only logs unless the kernel is booted with `joe=enforce`.

### Packages and build order

`packages/NAME/` holds `package.zon` and `build.sh` (sourced, so nothing at top level). The base system builds in the hand-written order of `packages/ORDER`, because those packages replace the bootstrap's temporary tools one by one. Every other recipe is ordered by `bootstrap/order.py` from `depends` and `build_depends`, which must therefore be complete. All recipes build in one shared build root, `build/bootstrap/root`, which dave itself manages; each package is installed into it after being built unless marked build-only.

Recipes follow Linux From Scratch and Beyond LFS (systemd, development branch). Take versions, URLs and flags from the book page, not from memory.

### Files that exist in more than one place

- dave's systemd units are in `system/`. They are installed by both `packages/dave/build.sh` (real images) and `image/add-dave.sh` (scaffold); adding or renaming a unit means editing both. Units are enabled by shipping symlinks.
- `packages/dave/files/` is populated by `build-packages.sh` with the freshly built binary and `system/*`. dave is cross-built on the host because joe does not package Zig. A dave change reaches an image only after the `dave` package is rebuilt, which needs a `.release` bump in `packages/dave/package.zon`.
