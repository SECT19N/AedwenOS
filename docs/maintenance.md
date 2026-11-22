# Updating and maintenance

Keeping an installed system up to date. Back to the [README](../README.md).

An installed system is a standard rolling-release Arch system and is kept up to
date in place — there is no reinstall or reformat cycle.

```sh
sudo pacman -Syu      # official repositories + chaotic-aur
paru -Syu             # the above, plus AUR packages
```

`paru -Syu` is only needed for packages you installed from the AUR yourself.
The AedwenOS-specific packages (`aedwen-tools`, `aedwen-qstyle`,
`aedwen-decoration`, `ttf-roboto-flex`) and the shell and theme files come with
the ISO and are not updated by `pacman` yet (a hosted package repository is on
the roadmap). A wrapper script
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
