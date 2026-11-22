# Testing the ISO

Booting the image in a virtual machine or from a USB drive. Back to the [README](../README.md).

When booted, the live environment logs in automatically to KDE Plasma as the
user `aedwen` (no password). The desktop contains an **Install AedwenOS** icon
that launches Calamares, and the `aedwen-install` command is available in a
terminal for the command-line installation path. A terminal also has
`fastfetch`, `ncdu`, `python3`, and `node`
available to sanity-check the developer tooling, and `octopi` is on the
application menu alongside the KDE app suite.

### QEMU

`test-vm.sh` boots the newest ISO from `out/`.

```sh
./test-vm.sh          # UEFI boot (requires the OVMF firmware, package edk2-ovmf)
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
- Optical drive: attach the ISO from `out/` (see [Build output](building.md#build-output) for the filename pattern)

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
[Design notes and limitations](design-notes.md)).
