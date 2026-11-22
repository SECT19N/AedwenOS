# AedwenOS

AedwenOS is an Arch-based Linux distribution with a **Material 3 Expressive**
desktop on KDE Plasma 6 (Wayland): a custom top bar, dock, Quick Settings and
launcher, its own widget style, window decorations, icons, cursors, sounds,
boot splash and installer, all drawn from one colour palette that follows the
accent colour you pick. The root filesystem is Btrfs with snapshots you can boot
from the Limine menu.

This repository contains everything needed to build its installation medium (a
live ISO) from source and to install the system to disk.

> **Project status: experimental / pre-alpha.**
> The ISO is not yet confirmed to boot on all hardware. Both installers (the
> graphical Calamares one and the command-line `aedwen-install`) work in testing,
> but expect rough edges. See [Project status and roadmap](#status-and-roadmap).

---

## Highlights

- **Material 3 Expressive desktop** on KDE Plasma 6 (Wayland): top bar, dock,
  Quick Settings, launcher, notification centre, plus a widget style
  (`aedwen-qstyle`) and window decoration (`aedwen-decoration`) in the same
  language, in light, dark and baseline (stock Material 3) variants.
- **One accent, everywhere.** The Appearance settings and the Welcome app pick
  a seed colour; the Plasma colour scheme, cursors, icons, GTK/libadwaita apps,
  Konsole, Kate and the wallpaper follow it. A High contrast option and a
  keyboard focus ring are built in.
- **Own icon theme and font:** `Aedwen-Icons` and IBM Plex Sans.
- **Two installers:** Calamares with custom pages (including an Extras step for
  optional software packs) or the scripted `aedwen-install`.
- **Btrfs, snapshots and Limine:** `snapper` snapshots with bootable rollback.
- **Plain Arch underneath:** `pacman`, `paru` and the AUR work as usual.

## Quick start

AedwenOS is built on an x86-64 Arch or Arch-based host (other systems use a
container or VM, see [Building](docs/building.md)). The build host also needs
the chaotic-aur keyring and mirrorlist (see the same page).

```sh
sudo pacman -S archiso
git clone https://github.com/SECT19N/AedwenOS.git && cd AedwenOS
scripts/build-localrepo.sh      # once: AUR-only and AedwenOS packages (as your user)
./build.sh                      # ISO ends up in out/   (--fast for quicker dev builds)
./test-vm.sh                    # boot the newest ISO in QEMU
```

Boot the ISO and run **Install AedwenOS** (Calamares), or `sudo aedwen-install
/dev/sdX` from a terminal. Details: [Installing](docs/installing.md).

## System at a glance

| Layer           | Choice                                                                                  |
| --------------- | --------------------------------------------------------------------------------------- |
| Base            | Arch Linux (`pacstrap`), kernel `linux-zen`                                             |
| Boot            | [Limine](https://wiki.archlinux.org/title/Limine) on the installed system; UEFI only     |
| Initramfs       | dracut on the installed system (the live ISO uses mkinitcpio, as archiso requires)       |
| Filesystem      | Btrfs with subvolumes and zstd; `snapper` + `snap-pac` snapshots                         |
| Desktop         | KDE Plasma on Wayland, SDDM, the AedwenOS shell widgets (`org.aedwen.*`)                 |
| Packages        | `pacman` and `paru`, chaotic-aur enabled                                                |
| Installers      | Calamares (graphical) or `aedwen-install` (command line)                                 |

## Documentation

- [Building the ISO](docs/building.md) and [testing it](docs/testing.md)
- [Installing](docs/installing.md) and [updating](docs/maintenance.md)
- [Design notes, limitations and repository layout](docs/design-notes.md)
- [Contributing](CONTRIBUTING.md), [Code of Conduct](CODE_OF_CONDUCT.md), [Security](SECURITY.md)

## Status and roadmap

Working: the ISO build (locally and in CI), the desktop shell, widget style,
window decoration, icon theme, Welcome app and Appearance settings (including
High contrast), both installers, snapshots with Limine rollback, and `firewalld`.

Planned:

- Confirm a clean UEFI boot on common VMs and hardware; test Calamares on more
  hardware and verify `aedwen-install` output boots reliably.
- Window snap layouts, multi-display top bar behaviour and top-bar window
  controls for full-screen apps.
- Package the shell and theme and host a pacman repository, so installed systems
  receive theme and shell updates (today they come only with a new ISO).
- `aedwen-update` (mirror refresh, keyring-first upgrade, reboot hint).
- Accent-following Plymouth and Limine themes at run time.
- Disk encryption (LUKS) and legacy BIOS support; Secure Boot.
- Branding (`os-release`, a real logo), a GitHub Pages site, a "keep existing
  /home" option in `aedwen-install`, and optionally extra kernels.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please follow the
[Code of Conduct](CODE_OF_CONDUCT.md), and report security problems privately as
described in [SECURITY.md](SECURITY.md).

## License

- Code (scripts, installer, QML, configuration, packaging) is licensed under
  **GPL-3.0-or-later**: see [LICENSE](LICENSE).
- Artwork (wallpapers, icons, logos and theme images) is licensed under
  **CC BY-SA 4.0**: see [LICENSE-ARTWORK](LICENSE-ARTWORK).
- Third-party components, such as the bundled fonts, Calamares and the Arch and
  KDE packages on the ISO, keep their own licenses.
- The name "AedwenOS" and the logo are not covered by these licenses. Forks
  should use a different name and logo.

