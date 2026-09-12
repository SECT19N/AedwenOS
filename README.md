# AedwenOS

AedwenOS is an Arch-based Linux distribution. This repository contains
everything needed to build its installation medium (a live ISO) from source and
to install the system to disk.

> **Project status: experimental / pre-alpha.**
> The ISO is not yet confirmed to boot on all hardware, and the graphical
> installer is a work in progress. The command-line installer is functional.
> See [Project status and roadmap](#project-status-and-roadmap).

---

## Table of contents

- [What is in this repository](#what-is-in-this-repository)
- [System composition](#system-composition)
- [How the build works](#how-the-build-works)
- [Requirements](#requirements)
- [Building the ISO](#building-the-iso)
  - [Arch and Arch-based Linux](#arch-and-arch-based-linux)
  - [Other Linux distributions (container build)](#other-linux-distributions-container-build)
  - [Windows (WSL2 or a virtual machine)](#windows-wsl2-or-a-virtual-machine)
  - [macOS (virtual machine)](#macos-virtual-machine)
  - [Build output](#build-output)
- [Testing the ISO](#testing-the-iso)
  - [QEMU](#qemu)
  - [VirtualBox or VMware](#virtualbox-or-vmware)
  - [Writing the ISO to a USB drive](#writing-the-iso-to-a-usb-drive)
- [Installing AedwenOS](#installing-aedwenos)
  - [How the two installers stay consistent](#how-the-two-installers-stay-consistent)
- [Updating and maintenance](#updating-and-maintenance)
- [Migrating from another distribution](#migrating-from-another-distribution)
- [Repository layout](#repository-layout)
- [Design notes and limitations](#design-notes-and-limitations)
- [Project status and roadmap](#project-status-and-roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## What is in this repository

| Path            | Purpose                                                                                                                                                |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `iso/`          | The [archiso](https://gitlab.archlinux.org/archlinux/archiso) profile: the package list and configuration that `mkarchiso` compiles into the live ISO. |
| `iso/airootfs/` | Files copied verbatim onto the live filesystem (system configuration, the installer script, the Calamares configuration, branding).                    |
| `scripts/build-localrepo.sh` | Builds packages no longer (or never) published in the official repos or chaotic-aur from the AUR, and stages them in `iso/localrepo/` (the `[aedwen-local]` repo `mkarchiso` pulls from). Must be run before `build.sh` at least once. |
| `build.sh`      | Convenience wrapper around `mkarchiso`.                                                                                                                |
| `test-vm.sh`    | Boots the most recently built ISO in QEMU.                                                                                                             |

The distribution's identity — kernel, filesystem, bootloader, desktop — is
defined entirely by the files under `iso/`.

## System composition

| Layer           | Choice                                                                                                                                    |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Base            | Arch Linux, installed with `pacstrap`                                                                                                     |
| Kernel          | `linux-zen` (Arch official repository)                                                                                                    |
| Initramfs       | [dracut](https://wiki.archlinux.org/title/Dracut) on the installed system (the live ISO uses mkinitcpio, which archiso requires)          |
| Bootloader      | [Limine](https://wiki.archlinux.org/title/Limine), installed on the target system                                                         |
| Root filesystem | Btrfs (subvolume layout, zstd compression)                                                                                                |
| Desktop         | KDE Plasma on Wayland, with the SDDM display manager                                                                                      |
| Shell           | fish for the user account; bash (from `base`) for root and as fallback                                                                    |
| Package tools   | `pacman`, plus `paru` for the AUR (chaotic-aur repository enabled), and `octopi` (Qt GUI front end) |
| Editors         | `zed` (from `zed-bin`, the `[aedwen-local]` repo), `kate`/`kwrite`, `vim`, `nano`                                                          |
| Developer tooling | Python, Node.js/npm, Kotlin, OpenJDK 25 (LTS, `jdk25-openjdk`) as the default JDK, `fastfetch`, `ncdu`                                   |
| Snapshots       | `snapper` (timeline + `snap-pac` pre/post-transaction pairs), with bootable rollback entries in the Limine menu via `limine-snapper-sync` |
| Firewall        | `firewalld`, enabled with SSH allowed in the default zone                                                                                 |
| Installer       | Calamares (graphical, in development) or `aedwen-install` (command-line)                                                                  |

The installed system is an ordinary rolling-release Arch system. Software is
managed with `pacman` and `paru` in the usual way, with no restrictions imposed
by the distribution. The [chaotic-aur](https://aur.chaotic.cx/) repository is
enabled by default so that `paru` and common AUR packages are available as
prebuilt binaries; removing its section from `/etc/pacman.conf` makes `paru`
build from source instead.

## How the build works

A Linux distribution at this stage consists of two independent pieces:

1. **The live/installation medium.** `mkarchiso` (from the `archiso` package)
   reads the profile in `iso/`, installs the listed packages into a temporary
   root filesystem, overlays the files from `iso/airootfs/`, and packs the
   result into a bootable ISO image. Booting that ISO provides a running KDE
   Plasma environment used to test the system and to run the installer.

2. **The installer.** Once booted, either Calamares or the `aedwen-install`
   script partitions a disk, installs the base system and the `linux-zen`
   kernel with `pacstrap`, and configures the Limine bootloader. This is the
   step that produces a permanent AedwenOS installation.

Because the build relies on `mkarchiso` and `pacman`, **the ISO must be built on
an x86-64 Arch or Arch-based system.** On other operating systems this is
achieved with a container or a virtual machine, as described below.

## Requirements

**To build the ISO:**

- An x86-64 host running Arch Linux or an Arch-based distribution
  (Arch, CachyOS, EndeavourOS, Manjaro, and similar), either directly or inside
  a container/VM.
- The `archiso` package.
- Approximately 10 GB of free disk space and 15–25 minutes, depending on
  network speed and hardware.
- Root privileges (`mkarchiso` creates loop devices and mount namespaces).

Most packages AedwenOS installs — including `linux-zen` — come from the
official Arch repositories. A few are pulled from the **chaotic-aur**
repository instead (`paru`, `zen-browser-bin`, `octopi`, `limine-snapper-sync`);
the build host must therefore have the chaotic-aur keyring and mirrorlist
installed (see `iso/pacman.conf` for the one-time setup commands).

A further handful are no longer published anywhere prebuilt — either dropped
from the official repos (`calamares`, `ckbcomp`) or never packaged there in
the first place (`zed-bin`). These are built from
the AUR by `scripts/build-localrepo.sh` into `iso/localrepo/`, which
`mkarchiso` reads as the `[aedwen-local]` repo. **Run this script at least
once before `build.sh`** (see [Building the ISO](#building-the-iso)); rerun it
with `--force` to pick up newer AUR versions. `build.sh` checks for the staged
packages and the chaotic-aur host setup before starting and stops with a
clear message if anything is missing.

On an installed system these three packages have no repository behind them
(`[aedwen-local]` exists only at build time), so plain `pacman -Syu` will
never update them. `paru -Syu` — or Octopi's AUR mode, which uses paru — treats
them as AUR packages and updates them normally.

**To test the ISO:** a virtual machine (QEMU, VirtualBox, VMware, Hyper-V) or a
spare USB drive and a computer that can boot from it.

## Building the ISO

### Arch and Arch-based Linux

```sh
# 1. Install the build tools (and, optionally, tools for testing).
sudo pacman -S --needed archiso git qemu-desktop edk2-ovmf

# 2. Obtain the source.
git clone <repository-url> AedwenOS
cd AedwenOS

# 3. Build the AUR-only packages into the local repo (see Requirements above).
# Run as your normal user, NOT with sudo. Takes a while the first time
# (zed-bin is a large download); safe to skip on
# later builds unless you want to pick up newer AUR versions (--force).
./scripts/build-localrepo.sh

# 4. Build. build.sh re-runs itself with sudo, so invoke it as a normal user.
./build.sh

# Or, for a quick dev/test build (lower squashfs compression, much faster):
./build.sh --fast
```

The finished image is written to `out/` (see [Build output](#build-output)).

### Other Linux distributions (container build)

Distributions such as Debian, Ubuntu, and Fedora cannot run `mkarchiso`
directly. The supported approach is to build inside an official Arch Linux
container. The example below uses Podman; Docker works identically (replace
`podman` with `docker`).

```sh
git clone <repository-url> AedwenOS
cd AedwenOS

sudo podman run --rm --privileged \
  --volume "$PWD":/build \
  --workdir /build \
  docker.io/archlinux:latest \
  bash -c '
    pacman -Sy --noconfirm --needed archiso base-devel git sudo &&
    useradd -m builder && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers &&
    su builder -c "./scripts/build-localrepo.sh" &&
    ./build.sh
  '
```

Notes:

- `--privileged` is mandatory. `mkarchiso` needs loop devices and the ability
  to create mount namespaces, which an unprivileged container cannot provide.
- `scripts/build-localrepo.sh` needs `makepkg` (from `base-devel`), which only
  exists on Arch — hence running it inside the container, as an unprivileged
  user (`makepkg` refuses to run as root), skip it if `iso/localrepo/` is
  already populated from a prior run.
- The finished ISO (and the populated `iso/localrepo/`) are written back to
  the cloned repository on the host, because the repository is bind-mounted
  into the container.

### Windows (WSL2 or a virtual machine)

There is no native Windows build. Two options are supported.

**Option A — Windows Subsystem for Linux 2 (recommended):**

1. Install WSL2 and restart when prompted:

   ```powershell
   wsl --install
   ```

2. Install an Arch Linux distribution for WSL. Either:

   - Run `wsl --install archlinux` (available on current Windows 11 builds), or
   - Install the community [ArchWSL](https://github.com/yuk7/ArchWSL)
     distribution.

3. Open the Arch WSL shell and build:

   ```sh
   sudo pacman -Syu --noconfirm --needed archiso git base-devel
   git clone <repository-url> AedwenOS
   cd AedwenOS
   ./scripts/build-localrepo.sh
   ./build.sh
   ```

4. If `mkarchiso` fails during mount or loop-device operations, enable systemd
   in WSL by adding the following to `/etc/wsl.conf`:

   ```ini
   [boot]
   systemd=true
   ```

   then run `wsl --shutdown` in PowerShell and reopen the shell. As an
   alternative, run the
   [container build](#other-linux-distributions-container-build) using Docker
   Desktop configured with the WSL2 backend.

5. Copy the finished ISO from WSL to Windows, for example:

   ```sh
   cp out/aedwenos-*.iso /mnt/c/Users/Public/
   ```

**Option B — a virtual machine:** install Arch Linux in a VM (Hyper-V,
VirtualBox, or VMware), then follow the
[Arch and Arch-based Linux](#arch-and-arch-based-linux) instructions inside it
and transfer the resulting ISO out through a shared folder.

### macOS (virtual machine)

`mkarchiso` cannot run on macOS. Install Arch Linux in a virtual machine
(UTM, Parallels, VMware Fusion, or VirtualBox), build inside it following the
[Arch and Arch-based Linux](#arch-and-arch-based-linux) instructions, and copy
the ISO out through a shared folder.

### Build output

On success, `out/` contains:

```
out/aedwenos-<YYYY.MM.DD>-g<commit>[-dirty]-x86_64.iso
```

The version string ties the image to the exact source it was built from:
the date, the short git commit hash of `HEAD` at build time, and a `-dirty`
suffix if the working tree had uncommitted changes. This also means rebuilding
multiple times in one day (e.g. after each commit) never overwrites a
previous image in `out/` — each build gets a distinct filename. Package
downloads are already reused between builds via the host's normal pacman
cache (`/var/cache/pacman/pkg`); `--fast` (see above) additionally trades
squashfs compression ratio for build speed. The image is a hybrid ISO: it can
be booted as an optical disc image by a virtual machine, or written raw to a
USB drive.

## Testing the ISO

When booted, the live environment logs in automatically to KDE Plasma as the
user `aedwen` (no password). The desktop contains an **Install AedwenOS** icon
that launches Calamares, and the `aedwen-install` command is available in a
terminal for the command-line installation path. A terminal also has
`fastfetch`, `ncdu`, `python3`, `node`, `kotlin`, and `java` (OpenJDK 25)
available to sanity-check the developer tooling, and `octopi`/`zed` are on the
application menu alongside the KDE app suite.

### QEMU

`test-vm.sh` boots the newest ISO from `out/`.

```sh
./test-vm.sh          # UEFI boot (requires the OVMF firmware, package edk2-ovmf)
./test-vm.sh --bios   # legacy BIOS boot
./test-vm.sh --ssh    # also forward host port 2222 to the guest's SSH port
```

To test an installation, attach a second, empty virtual disk and use it as the
target — for example `sudo aedwen-install /dev/vdb` in a terminal, or the
Calamares desktop icon.

**Getting text out of the VM.** The live session runs Plasma on Wayland, where
SPICE clipboard sharing does not work, so the practical route is SSH: run
commands from a host terminal and copy their output there. In the live
session, give the `aedwen` user a password (sshd refuses empty ones) and start
sshd:

```sh
passwd                       # any password, live session only
sudo systemctl start sshd
```

Then from the host (with `./test-vm.sh --ssh`):

```sh
ssh -p 2222 aedwen@localhost                        # interactive shell
ssh -p 2222 aedwen@localhost 'sudo pacman -Syu' 2>&1 | tee live.log
```

As on the official Arch ISO, the live medium ships without repository
databases (`mkarchiso` strips them, since they would be stale within days), so
run `sudo pacman -Sy` once before any `pacman -S` in the live session.

The same works for a USB boot on real hardware: run `ip addr` in the live
session and `ssh aedwen@<that address>` from another machine on the LAN. For
a one-off without SSH, `some-command 2>&1 | curl -F "file=@-" https://0x0.st`
prints a paste URL.

### VirtualBox or VMware

Create a new virtual machine with these settings:

- Operating system type: **Arch Linux (64-bit)**
- Memory: 4 GB or more
- Processors: 2 or more
- A blank virtual hard disk of at least 20 GB (needed only to test installation)
- Firmware: **EFI/UEFI enabled**
- Optical drive: attach the ISO from `out/` (see [Build output](#build-output) for the filename pattern)

Enable 3D acceleration for a responsive Plasma session. In VirtualBox, set the
graphics controller to **VMSVGA**.

### Writing the ISO to a USB drive

The ISO is a raw disk image and must be written block-for-block, not copied as
a file onto an existing filesystem.

> **Warning:** this permanently erases all data on the target USB drive.
> Double-check the device name before running any command.

- **Linux.** Identify the device with `lsblk`, then:

  ```sh
  sudo dd if=out/aedwenos-*.iso of=/dev/sdX bs=4M conv=fsync status=progress
  ```

  Replace `/dev/sdX` with the USB drive (for example `/dev/sdb`), not a
  partition.

- **Windows.** Use [Rufus](https://rufus.ie) (choose **DD Image** mode if it
  offers a choice between ISO and DD) or
  [balenaEtcher](https://etcher.balena.io).

- **macOS.** Use [balenaEtcher](https://etcher.balena.io), or `dd`:

  ```sh
  diskutil list                       # find the disk identifier, e.g. disk4
  diskutil unmountDisk /dev/disk4
  sudo dd if=aedwenos-*.iso of=/dev/rdisk4 bs=4m
  ```

After writing, boot the target computer from the USB drive. Secure Boot must be
disabled in the firmware settings (see
[Design notes and limitations](#design-notes-and-limitations)).

## Installing AedwenOS

Two installers are provided.

**Calamares (graphical).** Launched from the **Install AedwenOS** desktop icon.
Guided, partition-aware, and the intended path for most installations. Its
configuration currently under active development; see the roadmap.

**`aedwen-install` (command-line).** A scripted installer for advanced or
unattended use. Run from a terminal in the live environment:

```sh
sudo aedwen-install /dev/sdX
```

It creates a GPT layout with a 1 GiB FAT32 EFI system partition and a Btrfs root
with subvolumes (`@`, `@home`, `@log`, `@pkg`, `@snapshots`), installs the base
system and `linux-zen`, and configures Limine. It prompts before erasing the
target disk.

### How the two installers stay consistent

`iso/packages.x86_64` is the single source of truth for the installed package
set. Calamares clones the live filesystem to disk and then removes the packages
marked `LIVE ONLY` in that file (via `iso/airootfs/etc/calamares/modules/packages.conf`).
`aedwen-install` installs the same non-`LIVE ONLY` set directly with `pacstrap`.
Changing the package list in one place therefore updates both installers.

## Updating and maintenance

An installed system is a standard rolling-release Arch system and is kept up to
date in place — there is no reinstall or reformat cycle.

```sh
sudo pacman -Syu      # official repositories + chaotic-aur
paru -Syu             # the above, plus AUR packages
```

Prefer `paru -Syu`: the packages that come from `[aedwen-local]` at build time
(`zed-bin` among them) have no repository on the installed system and are only
updated through paru, which treats them as AUR packages. A wrapper script
(`aedwen-update`: mirror refresh, keyring-first upgrade, reboot hint) is
planned — see the roadmap.

The bootloader keeps itself current automatically:

- **Kernel updates** overwrite `/boot/vmlinuz-linux-zen`, and a pacman hook
  (`/etc/pacman.d/hooks/90-dracut-install.hook`) regenerates
  `/boot/initramfs-linux-zen.img` with dracut. Both filenames are fixed, so the
  Limine entry needs no action.
- **Limine package updates** trigger the pacman hook installed at
  `/etc/pacman.d/hooks/95-limine-deploy.hook`, which re-copies the Limine EFI
  binary to the EFI system partition.

**Snapshots and rollback.** `snap-pac` takes an automatic pre/post Btrfs
snapshot pair around every `pacman`/`paru` transaction, and `snapper`'s
timeline timers additionally take hourly/daily/weekly/monthly snapshots on
their own schedule (`snapper list` to see them, `snapper list-configs` for the
config name). `limine-snapper-sync` keeps a "Snapshots" entry in the Limine
boot menu in sync automatically, so a broken update can be booted into and
rolled back without any extra tooling.

**Firewall.** `firewalld` is enabled with SSH allowed in the default
(`public`) zone; no other services are pre-opened, and `sshd` itself is not
enabled by default. Adjust with `firewall-cmd`.

## Migrating from another distribution

An in-place upgrade from another distribution is not supported — installation
replaces the target system. To preserve user data across the switch, keep
`/home` on a separate partition (or Btrfs subvolume) and, during installation,
mount it without formatting:

- **Calamares:** in the manual partitioning screen, assign the existing
  partition to `/home` and leave _Format_ unchecked.
- **`aedwen-install`:** not yet supported by the script; back up `/home`
  separately and restore it after installation.

Note that user _configuration_ carried over from a different desktop or distro
may need cleanup; migrating documents and data is reliable, migrating dotfiles
wholesale is not.

## Repository layout

```
AedwenOS/
├── build.sh                      Build wrapper (calls mkarchiso)
├── test-vm.sh                    Boot the built ISO in QEMU
├── scripts/
│   └── build-localrepo.sh        Builds AUR-only packages into iso/localrepo/
├── iso/
│   ├── profiledef.sh             ISO metadata, boot modes, file permissions
│   ├── packages.x86_64           Package set (source of truth for the install)
│   ├── pacman.conf               Repositories used during the build
│   ├── localrepo/                [aedwen-local] repo, built by scripts/build-localrepo.sh (git-ignored)
│   ├── syslinux/                 Live-medium boot menu (BIOS)
│   ├── efiboot/                  Live-medium boot menu (UEFI, systemd-boot)
│   └── airootfs/                 Overlay applied to the live filesystem
│       ├── root/customize_airootfs.sh  Runs once during the build (bakes in the pacman keyring)
│       ├── etc/                  System configuration, autologin, first-boot setup
│       ├── etc/calamares/        Calamares sequence, modules, branding
│       │   └── modules/packages.conf   LIVE ONLY packages removed after install
│       └── usr/local/bin/
│           ├── aedwen-install        Command-line installer
│           ├── aedwen-dracut.sh      Initramfs regeneration helper (pacman hooks)
│           └── aedwen-live-setup     First-boot live-user setup
└── out/                          Build output (created by build.sh, git-ignored)
```

## Design notes and limitations

- **Btrfs is the root filesystem.** It is mature, widely deployed, readable
  directly by Limine, and supports the subvolume/snapshot layout the installers
  create. bcachefs was considered but is deferred: it left the mainline kernel
  in Linux 6.18 and would require the out-of-tree `bcachefs-dkms` module, whose
  build can fail on a kernel update and leave the system unbootable. It may be
  revisited once it re-stabilises.

- **The kernel and initramfs are stored on the FAT32 EFI system partition**
  mounted at `/boot`. Limine therefore only ever reads FAT. The root filesystem
  is passed to the kernel by UUID on the kernel command line
  (`root=UUID=…`, plus `rootflags=subvol=@` for Btrfs).

- **The installed system uses dracut; the live ISO uses mkinitcpio.** archiso
  builds the live initramfs with mkinitcpio and its scripts require it, so the
  ISO keeps mkinitcpio. That initramfs is thrown away on install: the `packages`
  module removes mkinitcpio, and both installers register dracut pacman hooks
  and generate pkgbase-named images (`initramfs-linux-zen.img`) via the shared
  `aedwen-dracut.sh` helper. dracut is built non-host-only for portability.

- **The live ISO itself does not use Limine.** archiso has no Limine boot mode,
  so the ISO boots through syslinux (BIOS) and systemd-boot (UEFI). Limine is
  used only on installed systems. Adding Limine to the ISO would require
  post-processing the image, as the CachyOS `iso-profiles` project does.

- **Calamares installs by cloning, not by re-downloading.** The `unpackfs`
  module copies the live filesystem to disk and the `packages` module prunes
  the live-only packages. This keeps installation fast and possible offline, at
  the cost of coupling the ISO contents to the installed system. A future
  move to package selection at install time (graphics drivers, optional
  components) would add a `packagechooser` module on top of this; a full
  download-based installer (`netinstall`) is only needed for multiple editions
  from one ISO.

- **Secure Boot is not supported.** It must be disabled in firmware before
  booting the ISO or an installed system.

- **The live medium ships a pre-populated pacman keyring.**
  `iso/airootfs/root/customize_airootfs.sh` is the standard archiso hook
  (auto-run via `arch-chroot` during `mkarchiso`, then deleted) that runs
  `pacman-key --init` and `--populate` while building the image. Without it,
  `pacman -S` on the live medium fails with keyring/signature errors, because
  the live root's `/etc/pacman.d/gnupg` would otherwise never get initialized
  at all — this profile intentionally omits the stock `pacman-init.service`
  in favor of doing it once at build time. The baked-in keyring is only for
  the live session: `pacman-key --init` creates a random per-machine master
  key, so both installers (`aedwen-install`, and Calamares via
  `shellprocess-postinstall.conf`) wipe the cloned `/etc/pacman.d/gnupg` and
  regenerate it on the target, then re-import the static distro keys from the
  `archlinux-keyring` / `chaotic-keyring` packages.

## Project status and roadmap

Functional:

- ISO builds from the profile in `iso/`.
- `aedwen-install` performs a complete Btrfs installation with Limine.
- Snapshots (`snapper` timeline + `snap-pac`) with Limine boot-menu rollback,
  and `firewalld` with SSH pre-allowed, on both install paths.
- `pacman` works on the live medium (keyring pre-populated at build time), and
  the installed system gets its own per-machine keyring from either installer.
- Baseline tooling ships preinstalled (Zed, Octopi, OpenJDK 25, Python,
  Node.js, Kotlin, fastfetch, ncdu).

Planned:

- `aedwen-update`: a thin update wrapper (mirror refresh, keyring-first
  upgrade via paru, reboot-needed hint), later fronted by a toolbox GUI.
- Curate the Plasma defaults (theme, panel layout, wallpaper, fonts).

- Confirm a clean UEFI and BIOS boot to KDE Plasma across common virtual
  machines and hardware.
- Verify `aedwen-install` output boots reliably.
- Finish and test the Calamares configuration.
- Branding: `os-release`, Plasma theming, wallpaper, and a real product logo.
- Add a `packagechooser` screen for graphics drivers and optional components.
- Add a "keep existing /home" option to `aedwen-install`.
- Optionally offer additional kernels (for example `linux-xanmod`).
- Investigate shipping Limine on the ISO itself.
- Revisit bcachefs support once it stabilises.
- Continuous integration to build the ISO automatically.

## Contributing

Issues and pull requests are welcome. Useful contributions at this stage
include test reports from real hardware and virtual machines, fixes to the
Calamares configuration, and branding assets. Please describe the host system
and boot mode (UEFI or BIOS) in any bug report.

## License

Not yet specified. Until a license file is added, no permissions are granted
beyond viewing the source. A license will be chosen before the first release.
