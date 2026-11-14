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

- a **console system** of about 65 packages, with sudo, an editor, the
  manual and ssh, whose upgrade, rollback and recovery behaviour is exercised
  end to end by `make test-joe`;
- a **GNOME desktop** of about 325 packages: GDM, GNOME Shell on Wayland,
  Firefox, Files, Terminal, Text Editor, Settings and the usual small
  applications (documents, images, video, music, archives, disks, maps,
  weather, clocks, calculator), with fonts for most scripts, spell checking
  and the common media codecs. `make test-desktop` starts every one of them,
  with the security module both logging and enforcing.

The desktop can be lived in as a virtual machine that keeps its disk: the
first boot asks who you are, and upgrades come from the build machine. See
[Living in it](#living-in-it). It can also be installed, from a live medium
whose installer erases a whole disk; see [Installing](#installing). Real
computers are a work in progress; see [Not done yet](#not-done-yet).

## How it behaves

```
dave install tree     Installs now. The system as it was is kept as a
                      bootable deployment first, so there is a way back.

dave upgrade          Works out and downloads the upgrade and proves it applies
                      cleanly to a copy of the system. Changes nothing you can
                      see. The upgrade is applied when the machine shuts down.

dave rollback         The previous system starts on the next boot, and on every
                      boot after it. Says so if someone has been given an
                      account since that system was made: accounts live in
                      /etc, which belongs to each system.

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
point boots the old system with the upgrade still pending. A newer
systemd-boot in the upgraded system replaces the one on the EFI system
partition at the same moment, and only ever a newer one, because every
deployment is started by the same loader.

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
signed index carries the SHA-256 of every package. They are fetched over HTTPS
(checked against the system's certificate store), HTTP, or from a local
directory; the signature is what is trusted either way. Packages have no install
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
   compiler cannot work under these rules, so none can run as root. A debugger
   cannot write another process's executable pages either: ptrace, process-vm
   and `/proc/PID/mem` writes are covered as well as `mmap` and `mprotect`.
3. *Declared operations.* A recipe states what its privileged programs do:
   which capabilities, whether the network, where they write, what they run.

   ```zon
   .operations = .{
       .{ .programs = .{"usr/bin/mount"}, .allow = .{ "mount", "cap:sys_admin" } },
   },
   ```

   The declaration is part of what is signed, and the module refuses the rest.
   `root-ipc` covers signals and SysV IPC between root processes. `none` is an
   explicit empty declaration. A program no declaration covers is `undeclared`:
   an `all` caller gives it `all`, and otherwise it is reported and refused when
   enforcing. Global root stays confined when it creates a user namespace. A
   process whose only global privilege is its capability set cannot create one,
   because replacing that set would discard its confinement.

The module logs by default and enforces when booted with `joe=enforce`. One
consequence worth knowing: a root shell does not read `/etc/profile` or
`~/.bashrc`, because files you can edit are not sealed.

The details are in the source, which is commented for readers:
[packages/linux/joe-lsm/joe.c](packages/linux/joe-lsm/joe.c), [dave/src/seal.zig](dave/src/seal.zig),
[dave/src/deploy.zig](dave/src/deploy.zig), [dave/src/boot.zig](dave/src/boot.zig),
[dave/src/txn.zig](dave/src/txn.zig), [dave/src/solver/pubgrub.zig](dave/src/solver/pubgrub.zig).

## Building and testing

GitHub Actions runs dave's existing unit tests on pull requests and pushes to
`main`, using Zig 0.17.1 on Ubuntu. To run the same checks locally:
`cd dave && zig build test --summary all` (requires `zstd`). Tests that need
btrfs or fs-verity skip when those features are unavailable. This workflow
does not run the command-line or VM suites below.

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
make audit-security        package seal and declaration audit
```

```
make desktop-image         a GNOME image, build/images/joe-desktop.img
make run-desktop           boot it in a QEMU window (user joe, password joe)
make test-desktop          session, every application, a web page; logging and enforcing
```

Building the desktop packages takes several hours the first time; LLVM, Rust,
Firefox, Node.js and SpiderMonkey are the long ones.

These are test images: root is logged in on the serial console without a
password, and the desktop image has a ready-made user, because that is how
the tests look inside. The release image below has neither.

## Installing

```
make iso                   build/images/joe-live.iso, the installation medium
make test-live             boot it as a CD and as a USB stick, in a VM
make test-install          install from it onto an empty disk, then boot that
```

The medium is a hybrid ISO for UEFI computers (Secure Boot off): write it to a
USB stick or attach it to a virtual machine as a CD. It starts a GNOME session
from a compressed image of the desktop, with a layer in memory for changes, and
opens the installer. The installer asks which disk to use and erases all of
it: a new GPT with an EFI system partition and a btrfs root laid out exactly
as an image's. The packages are installed from the medium itself, by one dave
transaction, and sealed as they are installed. The installed system boots
without an initramfs, like every joe system, and its first boot runs GNOME's
initial setup.

The installer (`installer/`) is a Qt Quick front end; all of its work is done by
`dave install-system`, which can be run by hand on the medium:

```
dave install-system --list                 the disks, and why any cannot be used
dave install-system --disk /dev/nvme0n1    erase it and install
```

Images and media are described by specifications in `image/*.zon` and built by
`dave image build`; each Makefile target above names one. The build machine
publishes the medium with the repository (see infra/build-machine).

## Releases

A release is named **J*X*-*Y*-*Z***, with a stage such as `-alpha1` before it
is final:

| Part | Is | In J1-7.3.1-0.2.0-alpha1 |
|------|----|--------------------------|
| J | joe, the distribution | J |
| *X* | the system revision | 1 |
| *Y* | the kernel's version | 7.3.1 |
| *Z* | dave's version | 0.2.0 |

`packages/joe-release` writes the name into `os-release` and the build machine
names the installation medium after it. Its package version is the revision
and stage alone (`1alpha1`), which dave orders before the final `1`.

## Living in it

```
make release-image         the desktop as a person gets it, build/images/joe-release.img
make test-release          its first boot: disk growth, first-run setup, sound, shared folder
make vm                    a virtual machine with a 64G disk of its own, in build/vm
make run-vm                boot it; what you do in it is still there next time
make serve-repo            offer build/repo to that machine
```

The release image has no accounts and root has no password. On the first boot
GDM starts GNOME's initial setup, which asks for a language, keyboard layout
and time zone and creates your account. That account is an administrator (a
member of `wheel`), so `sudo` works. The root file system grows to fill the
disk it finds itself on.

`make run-vm` uses the host's GPU for the guest's 3D when QEMU can (virgl),
gives the guest a sound card, and takes options through `VM_ARGS`: `--share
DIR` shares a host directory (`mount -t virtiofs host /mnt` in the guest),
`--sound virtio`, `--no-gl`, `--memory`, `--cpus`. Delete `build/vm` to start
again from the image.

To change the system you are running, as its developer:

```
edit packages/NAME, bump .release in its package.zon
bootstrap/build-packages.sh NAME      on the build machine
make serve-repo                       leave it running

sudo dave upgrade                     in the virtual machine
reboot
```

`dave install NAME` in the machine takes a package from the same place.

The bootstrap follows Linux From Scratch, and the desktop Beyond Linux From
Scratch (systemd, development branches), with the same package versions. Recipes are described in [packages/README.md](packages/README.md).

## Layout

| Path | What it is |
|------|------------|
| `dave/` | The package manager and deployment tool |
| `packages/` | One recipe per package, and the build order |
| `bootstrap/` | Scripts that build the first toolchain and then every package |
| `system/` | dave's systemd units |
| `image/` | Image and live medium specifications, and the scaffold's scripts |
| `installer/` | The graphical installer |
| `tests/` | Command-line tests and VM scenarios |

## Not done yet

- **Declarations for real packages.** The mechanism of rule 3 is tested, but
  real package programs still need studied declarations instead of generated
  `undeclared` policies or stale `all` defaults. `dave repo audit build/repo`
  lists the remaining undeclared programs and invalid or missing seals.
- **The rest of the trust chain.** Kernel modules are checked by the module
  but not by the kernel's own signature enforcement; there is no kernel
  lockdown and no Secure Boot, so root can still replace the kernel or its
  command line. There is no way yet to sign software built on the machine.
  Interpreters other than bash and Python (awk, sed, perl) do not ask before
  running a script.
- **Real hardware.** Firmware, processor microcode, Wi-Fi (through
  NetworkManager and wpa_supplicant) and the Intel, AMD and NVIDIA graphics
  drivers are there, but have been tried on few machines; there are no Vulkan
  drivers or hardware video decoding yet. The kernel boots without an
  initramfs, which is enough for internal disks but not for encrypted or
  multi-device roots. The installer erases a whole disk: no encryption, no
  installing beside another system. There is no Secure Boot.
- **Desktop gaps.** No printing, Bluetooth or mobile broadband; Settings is
  built without those three panels. No graphical front end to dave. Only the
  English (US) locale is built, so that is the one language the first-run
  setup offers. No HEIF or AVIF images, no hardware video decoding, and no
  office suite or mail client.
- **Split packages.** A package is everything its upstream installs, so the
  base image carries the compiler because programs need its run-time libraries.
- **Builds are not isolated from each other.** Every recipe builds in one
  shared build root. A fresh, minimal build root per package, chosen by the
  solver, comes later. Seven packages fetch Rust crates from the network while
  building, Rust itself starts from its upstream's prebuilt compiler, and the
  TypeScript compiler (needed to build one application) is its upstream's
  already-compiled release.
- **Building dave inside joe.** dave is a static binary cross-built by Zig on
  the build machine, because joe does not package Zig yet.
- Virtual packages (`provides`), and changing the kernel on a running system
  (use `dave upgrade`).

## Licence

joe Linux's own code is under the [MIT License](LICENSE). The security module
is GPL-2.0-only, as part of the kernel, and the patches to bash, Python and
GNOME Settings are under those projects' licences. The recipes follow Linux
From Scratch and Beyond LFS. [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)
has the details, including what to know before distributing an image built
from these recipes.
