# joe Linux

An independent Linux distribution whose goal is to be as boring as possible for
the person using it. Three things about it are new; everything else is ordinary
(glibc, systemd, a usr-merged file system, GNOME).

1. **Transactional upgrades on a system that is not immutable.** An upgrade is
   applied to a btrfs snapshot and takes effect on reboot. If the new system
   does not boot, the machine returns to the previous one by itself. The
   running root stays an ordinary writable file system.
2. **dave**, a package manager written in Zig with a PubGrub solver, designed
   around that update model from the start.
3. **A security model for root.** A privileged process runs only code that the
   distribution has signed, cannot generate code at run time, and is held to
   the operations its program declares. One kernel security module enforces it.

The idea of snapshot-based upgrades without immutability comes from
[Arch-silverblue](https://github.com/sinisterMage/Arch-silverblue).

## Status

joe Linux builds from source into two systems that boot in a virtual machine:

- a **console system** of about 70 packages, whose upgrade, rollback and
  recovery behaviour is exercised end to end by `make test-joe`;
- a **GNOME desktop** of about 320 packages: GDM, GNOME Shell on Wayland,
  Terminal, Files, Text Editor and Settings, checked by `make test-desktop`
  with the security module both logging and enforcing.

It is not ready to install on a real computer; see [Not done yet](#not-done-yet).

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

**Seals.** Every packaged file that is not configuration is *sealed* when it
is installed: fs-verity makes its contents immutable and gives the kernel a
digest of them, and an extended attribute carries a signature over that digest
together with the operations the package declares for the file. The public
half of the signing key is compiled into the kernel. A sealed file can be
replaced or deleted, never modified.

**What the security module does.** It concerns privileged processes only: any
user id of 0, or any capability, in the initial user namespace. Ordinary users
are not affected.

1. *Sealed code only.* The program, every library it maps, every kernel module
   it loads and every script it runs must be sealed. bash and Python ask the
   module before reading a script file; commands typed at a prompt and `-c`
   strings are not files and are allowed.
2. *No code made at run time.* No anonymous executable memory, no writable
   executable mappings, no making modified memory executable. A just-in-time
   compiler cannot work under these rules, so none can run as root.
3. *Declared operations.* A recipe states what its privileged programs do:
   which capabilities, whether the network, where they write, what they run.

   ```zon
   .operations = .{
       .{ .programs = .{"usr/bin/mount"}, .allow = .{ "mount", "cap:sys_admin" } },
   },
   ```

   The declaration is part of what is signed, and the module refuses the rest.

The module logs by default and enforces when booted with `joe=enforce`. One
consequence worth knowing: a root shell does not read `/etc/profile` or
`~/.bashrc`, because files you can edit are not sealed.

The details are in the source, which is commented for readers:
[packages/linux/joe-lsm/joe.c](packages/linux/joe-lsm/joe.c), [dave/src/seal.zig](dave/src/seal.zig),
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
make test-security         the security module's three rules
```

```
make desktop-image         a GNOME image, build/images/joe-desktop.img
make run-desktop           boot it in a QEMU window (user joe, password joe)
make test-desktop          session and applications, logging and enforcing
```

Building the desktop packages takes several hours the first time; LLVM, Rust
and SpiderMonkey are the long ones.

These are demonstration images: root is logged in on the serial console
without a password, and the desktop image has a ready-made user. There is no
installer yet that could set accounts up properly.

The bootstrap follows Linux From Scratch, and the desktop Beyond Linux From
Scratch (systemd, development branches), with the same package versions. Recipes are described in [packages/README.md](packages/README.md).

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

- **Declarations for real packages.** The mechanism of rule 3 is tested, but
  almost every package is still sealed as declaring `all`, because its
  programs have not been studied. `grep -L operations packages/*/package.zon`
  lists them. Until that list is short, rule 3 constrains little in practice.
- **The rest of the trust chain.** Kernel modules are checked by the module
  but not by the kernel's own signature enforcement; there is no kernel
  lockdown and no Secure Boot, so root can still replace the kernel or its
  command line. There is no way yet to sign software built on the machine.
  Interpreters other than bash and Python (awk, sed, perl) do not ask before
  running a script.
- **Real hardware.** The kernel boots without an initramfs, which is enough for
  virtual machines and simple disks but not for encrypted or multi-device roots.
  Wireless is off. There is no installer; images are assembled on the build
  machine.
- **Desktop gaps.** No web browser, printing, Bluetooth or mobile broadband;
  Settings is built without those three panels. No first-run setup, so no way
  to create your own user. No graphical front end to dave.
- **Split packages.** A package is everything its upstream installs, so the
  base image carries the compiler because programs need its run-time libraries.
- **Builds are not isolated from each other.** Every recipe builds in one
  shared build root. A fresh, minimal build root per package, chosen by the
  solver, comes later. Five packages fetch Rust crates from the network while
  building, and Rust itself starts from its upstream's prebuilt compiler.
- **Building dave inside joe.** dave is a static binary cross-built by Zig on
  the build machine, because joe does not package Zig yet.
- HTTPS repositories, virtual packages (`provides`), and changing the kernel on
  a running system (use `dave upgrade`).
