# Design notes and layout

Why the system is built the way it is, and where things live. Back to the [README](../README.md).

## Design notes and limitations

- **Disk encryption is not supported yet.** The bootloader entry and the
  initramfs can't unlock a LUKS root, so the installer hides the "Encrypt
  system" option in its automated modes. Calamares' manual-partitioning dialog
  still offers encryption when creating a partition (that part can't be turned
  off from configuration); don't use it until LUKS support lands.

- **The desktop shell is built from QML widgets on a shared framework.** The
  top bar and dock are AedwenOS Plasma widgets (`org.aedwen.*`): launcher,
  workspace dots, app name next to KDE's global menu, clock and calendar,
  search, quick settings, notification centre and dock. They are all built on
  the `org.aedwen.ui` QML module, which reads its colours live from the
  active KDE colour scheme, and they get their data from KDE's own models
  (task manager, menu, KRunner, notifications), so they work with any
  installed app rather than a fixed list. Quick-settings tiles are separate
  files loaded by name, so a tile whose KDE API changes hides itself instead
  of breaking the panel. A few of those APIs are KDE-internal, so after a
  Plasma update run `scripts/check-shell.sh` before building. Apps use
  `aedwen-qstyle` (Breeze with Material 3 Expressive progress bars and context
  menus) and `aedwen-decoration` (rounded title bars), recoloured from the
  active scheme.

- **One accent drives everything.** The Appearance settings and the Welcome app
  write the seed to `kdeglobals` and apply the matching colour scheme; a
  systemd user path unit then runs `aedwen-cursors`, `aedwen-icons` and
  `aedwen-apps`, which rebuild the cursors, icons, Konsole/Kate themes and
  wallpaper for that accent on the user's machine, using the same generators
  that make the ISO's violet defaults. The boot splash and Limine only change
  when the system is (re)installed or updated, not live.

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
  so the ISO boots through systemd-boot. Limine is
  used only on installed systems. Adding Limine to the ISO would require
  post-processing the image, as the CachyOS `iso-profiles` project does.

- **Calamares installs by cloning, not by re-downloading.** The `unpackfs`
  module copies the live filesystem to disk and the `packages` module prunes
  the live-only packages. This keeps installation fast and possible offline, at
  the cost of coupling the ISO contents to the installed system. Optional
  software is handled the same way: the Extras page keeps every pack on the
  image and removes the unselected ones after the copy, so the install stays
  offline. A full download-based installer (`netinstall`) is only needed for
  multiple editions from one ISO.

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

## Repository layout

```
AedwenOS/
├── build.sh                      Build wrapper (calls mkarchiso)
├── test-vm.sh                    Boot the built ISO in QEMU
├── CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md
├── .github/                      Release workflow, issue forms, pull request template
├── packages/                     PKGBUILDs: aedwen-tools, aedwen-qstyle, aedwen-decoration,
│                                 ttf-roboto-flex, calamares
├── scripts/
│   ├── build-localrepo.sh        Builds the packages above and AUR-only ones into iso/localrepo/
│   ├── generate-*.py             Theme generators (colours, GTK, cursors, icons, Konsole
│   │                             and Kate, wallpaper, Plymouth, Calamares, Plasma theme)
│   ├── palette_lib.py            The shared palette (seeds, contrast levels, GENERATOR_VERSION)
│   ├── check-theme.py            Re-runs the generators and WCAG check (also run in CI)
│   ├── check-contrast.py         WCAG contrast of every palette pair
│   └── check-shell.sh            Loads every shell widget against the installed Plasma
├── iso/
│   ├── profiledef.sh             ISO metadata, boot modes, file permissions
│   ├── packages.x86_64           Package set (source of truth for the install)
│   ├── pacman.conf               Repositories used during the build
│   ├── localrepo/                [aedwen-local] repo, built by scripts/build-localrepo.sh (git-ignored)
│   ├── efiboot/                  Live-medium boot menu (UEFI, systemd-boot)
│   └── airootfs/                 Overlay applied to the live filesystem
│       ├── root/customize_airootfs.sh  Runs once during the build (bakes in the pacman keyring)
│       ├── etc/                  System configuration, autologin, first-boot setup
│       ├── etc/calamares/        Calamares sequence, modules, branding
│       │   └── modules/packages.conf   LIVE ONLY packages removed after install
│       ├── usr/lib/qt6/qml/org/aedwen/  Shell QML modules: ui (design tokens and
│       │                             components), shell (shared actions)
│       ├── usr/share/plasma/plasmoids/org.aedwen.*  Top bar and dock widgets
│       ├── usr/share/plasma/desktoptheme/aedwen/    Plasma theme (generated); aedwen-hc is the High contrast one
│       ├── usr/share/plasma/look-and-feel/          AedwenOS (dark) and AedwenOS Light
│       └── usr/local/bin/
│           ├── aedwen-install        Command-line installer
│           ├── aedwen-cursors / -icons / -apps   Rebuild the accent-coloured cursors, icons,
│           │                         Konsole/Kate themes and wallpaper
│           ├── aedwen-dracut.sh      Initramfs regeneration helper (pacman hooks)
│           └── aedwen-live-setup     First-boot live-user setup
└── out/                          Build output (created by build.sh, git-ignored)
```
