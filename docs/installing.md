# Installing AedwenOS

The two installers, and moving from another distribution. Back to the [README](../README.md).

Two installers are provided.

**Calamares (graphical).** Launched from the **Install AedwenOS** desktop icon.
Guided, partition-aware, and the intended path for most installations. It uses
AedwenOS's own pages (welcome, location, keyboard, disk, users, **Extras**,
summary) and is still being tested on more hardware; see the roadmap.

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

Calamares also has an **Extras** page: optional software, one switch per item,
none selected by default. Developer tools come per language (Python,
JavaScript/TypeScript, build tools), editors per editor (Zed, Neovim, Helix,
Code - OSS), and the KDE apps one by one. Items that are part of the image are
removed again after the copy if left off; the rest (marked "download" on the
page) are fetched at the end of the install, which needs a network. If the
install is offline they are skipped and listed, and `aedwen-extras pending`
installs them later; `aedwen-extras list` and `aedwen-extras install <id>` do the
same for anything else. The groups are in `iso/airootfs/usr/share/aedwen/extras`.
`aedwen-install` installs the full image set and none of the downloadable items.

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
