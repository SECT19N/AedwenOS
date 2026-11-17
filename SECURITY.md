# Security policy

AedwenOS is **experimental, pre-alpha software**. Only the latest commit on
`master` and the most recent ISO built from it are supported; older ISOs do
not get fixes. Please don't use it for anything you can't afford to rebuild.

## Reporting a vulnerability

Please **do not open a public issue** for a security problem.

Report it privately through GitHub: open the repository's **Security** tab and
choose **Report a vulnerability**. If that option isn't available, contact the
maintainer, [@SECT19N](https://github.com/SECT19N), through the contact
options on their GitHub profile and ask for a private channel before sending
details.

Please include:

- What is affected (the ISO, `aedwen-install`, the Calamares configuration, a
  shell widget, a package under `packages/`, the build or release workflow).
- The ISO version (the file name) or commit, and how you installed or booted it.
- Steps to reproduce, and what an attacker could do with it.

You can expect an acknowledgement within about a week. This is a volunteer
project, so fixes may take longer, but we will keep you informed and credit you
in the fix if you wish.

## What counts

In scope:

- Flaws in the installers (`aedwen-install`, the Calamares configuration and
  its post-install steps) that leave an installed system less safe than
  documented: wrong permissions, leftover live-session credentials, a shared
  pacman keyring, and similar.
- Privilege escalation or code execution through files this repository ships
  (the helper scripts in `/usr/local/bin`, systemd units, the shell widgets, the
  packages under `packages/`).
- Problems in the build and release pipeline, such as a way to tamper with a
  published ISO or leak the repository's secrets.

Known limitations, not vulnerabilities:

- The **live session** has an `aedwen` user with passwordless `sudo` and
  automatic login. That is by design for a live medium; the installers remove
  it from installed systems.
- **Secure Boot** and **disk encryption** (LUKS) are not supported yet. See the
  design notes in the [README](README.md#design-notes-and-limitations).
- Vulnerabilities in upstream software (Arch Linux, KDE Plasma, Calamares,
  Limine and the like) belong with those projects. Tell us if AedwenOS
  configures one in a way that makes it worse.
