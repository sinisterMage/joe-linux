# joe Linux

An independent Linux distribution whose goal is to be as boring as possible for
the person using it. Two things about it are new; everything else is ordinary
(glibc, systemd, a usr-merged file system, and in time GNOME).

1. **Transactional upgrades on a system that is not immutable.** An upgrade is
   applied to a btrfs snapshot and takes effect on reboot. If the new system
   does not boot, the machine returns to the previous one by itself. The
   running root stays an ordinary writable file system.
2. **dave**, a package manager written in Zig with a PubGrub solver, designed
   around that update model from the start.

The idea of snapshot-based upgrades without immutability comes from
[Arch-silverblue](https://github.com/sinisterMage/Arch-silverblue).

## Status

A first milestone: joe Linux 0.1 is a console system of 68 packages built from
source that boots in a virtual machine, and whose upgrade, rollback and
recovery behaviour is exercised end to end by `make test-joe`. It is not ready
to install on a real computer; see [Not done yet](#not-done-yet).

## How it behaves

```
dave install tree     Installs now. The system as it was is kept as a
                      bootable deployment first, so there is a way back.

dave upgrade          Works out and downloads the upgrade and proves it applies
                      cleanly to a copy of the system. Changes nothing you can
                      see. The upgrade is applied when the machine shuts down.

dave rollback         The previous system starts on the next boot, and on every
                      boot after it.

dave status           What is running, what will start next, what is pending.
```

When a request cannot be satisfied, dave says why:

```
dave: this cannot be done.

Because editor 1.0-r1 depends on libui >=2 and editor has no version other than 1.0-r1, editor requires libui >=2.
And because no version of libui matches >=2, editor cannot be installed.
So, because you asked for editor, what you asked for cannot be installed.
```

## How it works

**Deployments.** The root file system is a btrfs subvolume `joe/deploy/<id>`.
`/home` and `/var` are separate subvolumes shared by every deployment; `/etc`
belongs to the deployment, so configuration rolls back with the system. dave's
database lives under `/usr/lib/dave/db`, inside the deployment, so each
snapshot carries the database that describes exactly its own contents.

**Upgrades lose nothing.** `dave upgrade` only records a plan. At shutdown,
`dave-finalize.service` snapshots the root *as it is at that moment* and
applies the plan to the snapshot. Anything changed between `dave upgrade` and
the reboot is therefore in the new system; there is no merge step. The boot
entry for the new deployment is written last, so a power cut at any earlier
point boots the old system with the upgrade still pending.

**The boot loader keeps the health record.** Each deployment has one
systemd-boot entry. Entries are ordered by a priority that is bumped whenever a
deployment is chosen, so activating an upgrade and rolling back are the same
operation, and a rollback is persistent. A new deployment starts with three
boot attempts. `dave-boot-check.service` runs before systemd marks the boot
good; if the check fails the machine reboots, and when the attempts run out
systemd-boot returns to whatever was chosen before. A root that cannot be
mounted at all takes the same path through the kernel's panic timeout.

**Packages** are zstd-compressed tar files beginning with a manifest that is
authoritative for all file metadata. Repositories are signed with Ed25519; the
signed index carries the SHA-256 of every package. Packages have no install
scripts: a package may declare a trigger (rebuild the linker cache when
libraries change), and that is all.

The details are in the source, which is commented for readers:
[dave/src/deploy.zig](dave/src/deploy.zig), [dave/src/boot.zig](dave/src/boot.zig),
[dave/src/txn.zig](dave/src/txn.zig), [dave/src/solver/pubgrub.zig](dave/src/solver/pubgrub.zig).

## Building and testing

Requirements on the build machine: Zig 0.17.1, a C toolchain, QEMU with KVM,
OVMF firmware, btrfs-progs 6.12 or newer, bubblewrap, and a build directory on
btrfs. Nothing needs root.

```
make test                  unit tests and command-line tests, in seconds
make test-boot-contract    what the design assumes about systemd-boot, in a VM
make test-deployments      upgrade, rollback, power loss and recovery, in a VM
```

Those two VM tests use a *scaffold*: a throwaway image made from the build
machine's kernel and a stock Arch userspace, so the deployment mechanics can be
exercised without building a distribution first. Nothing from it ships.

```
make bootstrap             cross toolchain and temporary tools
make packages              every recipe in packages/, into build/repo
make image                 a bootable image, build/images/joe.img
make run                   boot it in QEMU on this terminal (leave with Ctrl-A X)
make test-joe              the same deployment tests on that image
```

The image made by `make image` logs root in on the serial console without a
password. That is for demonstration only: there is no installer yet that could
set one.

The bootstrap follows Linux From Scratch (systemd, development branch) with the
same package versions. Recipes are described in [packages/README.md](packages/README.md).

## Layout

| Path | What it is |
|------|------------|
| `dave/` | The package manager and deployment tool |
| `packages/` | One recipe per package, and the build order |
| `bootstrap/` | Scripts that build the first toolchain and then every package |
| `system/` | dave's systemd units |
| `image/` | Disk image assembly |
| `tests/` | Command-line tests and VM scenarios |

## Not done yet

- **GNOME** and everything a desktop needs; the base is a console system.
- **Real hardware.** The kernel boots without an initramfs, which is enough for
  virtual machines and simple disks but not for encrypted or multi-device roots.
  There is no installer; images are assembled on the build machine.
- **Split packages.** A package is everything its upstream installs, so the
  base image carries the compiler because programs need its run-time libraries.
- **Builds are not isolated from each other.** Every recipe builds in one
  shared build root, in a fixed order, as Linux From Scratch does. A fresh,
  minimal build root per package, chosen by the solver, comes later.
- **System accounts** are a static `/etc/passwd`, not `sysusers.d`.
- **Building dave inside joe.** dave is a static binary cross-built by Zig on
  the build machine, because joe does not package Zig yet.
- **The security model**: only signed, ahead-of-time compiled code may run as
  root, enforced by a kernel security module, with each privileged program
  limited to operations it declares. The package format reserves the fields it
  needs; nothing enforces it yet.
- HTTPS repositories, virtual packages (`provides`), and changing the kernel on
  a running system (use `dave upgrade`).
