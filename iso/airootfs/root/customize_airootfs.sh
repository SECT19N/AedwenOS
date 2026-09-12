#!/usr/bin/env bash
# Standard archiso hook: mkarchiso runs this via arch-chroot while building the
# live root, then deletes it. Bakes a fully populated, trusted keyring into the
# squashfs so `pacman -S` works on the live medium without a runtime
# `pacman-key --init` (which fails on the read-only-backed live root -- see
# aedwen-install for the equivalent step run against the installed system).
set -e -u
pacman-key --init
# Keyring names are the file stems under /usr/share/pacman/keyrings/ --
# chaotic-keyring ships "chaotic.gpg", not "chaotic-aur.gpg".
pacman-key --populate archlinux chaotic

# mkarchiso installs packages with the *host's* pacman. CachyOS patches its
# pacman to record the source repo as an %INSTALLED_DB% field in
# /var/lib/pacman/local/*/desc; vanilla Arch pacman (what the ISO ships) does
# not know that key and warns "unknown key '%INSTALLED_DB%' in local database"
# once per package. Strip the field so the local db is plain Arch format.
# No-op when building on a host whose pacman does not write it.
sed -i '/^%INSTALLED_DB%$/,/^$/d' /var/lib/pacman/local/*/desc
