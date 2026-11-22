# Building the ISO

How to build the AedwenOS live ISO from source. Back to the [README](../README.md).

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

Some packages are no longer published anywhere prebuilt (`calamares` and
`ckbcomp` were dropped from the official repos) or are AedwenOS's own
(`aedwen-tools`, `aedwen-qstyle`, `aedwen-decoration`, from
`packages/`). These are built by `scripts/build-localrepo.sh` into
`iso/localrepo/`, which `mkarchiso` reads as the `[aedwen-local]` repo. **Run this script at least
once before `build.sh`** (see [Building the ISO](#build-steps)); rerun it
with `--force` to pick up newer AUR versions. `build.sh` checks for the staged
packages and the chaotic-aur host setup before starting and stops with a
clear message if anything is missing.

On an installed system these packages have no repository behind them
(`[aedwen-local]` exists only at build time), so plain `pacman -Syu` never
updates them. `calamares` and `ckbcomp` are live-only and removed on install.
The `aedwen-*` packages are AedwenOS's own and are not in
the AUR either, so an installed system only gets new versions of them by
installing a newer ISO build; a hosted package repository is on the roadmap.

**To test the ISO:** a virtual machine (QEMU, VirtualBox, VMware, Hyper-V) or a
spare USB drive and a computer that can boot from it.

## Build steps

### Arch and Arch-based Linux

```sh
# 1. Install the build tools (and, optionally, tools for testing).
sudo pacman -S --needed archiso git qemu-desktop edk2-ovmf

# 2. Obtain the source.
git clone <repository-url> AedwenOS
cd AedwenOS

# 3. Build the AUR-only packages into the local repo (see Requirements above).
# Run as your normal user, NOT with sudo. Takes a while the first time; safe
# to skip on later builds unless you want to pick up newer AUR versions
# (--force).
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
