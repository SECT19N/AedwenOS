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
