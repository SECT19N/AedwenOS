#!/usr/bin/env bash
# Applies the installer's "Extras" choice inside the target system (called by
# shellprocess-postinstall with the ticked ids, e.g. "python,zed,print"):
#   local groups that were NOT ticked are removed (they are on the ISO image)
#   online groups that WERE ticked are installed from the repositories
# Optional software must never fail an install: every problem is reported and
# skipped, and the script always exits 0. Online groups that could not be
# installed (no network, mirror down) are listed in /var/lib/aedwen/pending-extras
# for `aedwen-extras pending`.
#
# This is a script, not inline in the Calamares config, because shellprocess
# expands $name in its commands as its own variables and fails the install.
CATALOGUE=${AEDWEN_EXTRAS_CATALOGUE:-/usr/share/aedwen/extras}
PENDING=${AEDWEN_EXTRAS_PENDING:-/var/lib/aedwen/pending-extras}
chosen=",${1},"

[[ -r $CATALOGUE ]] || { echo "extras: no catalogue at $CATALOGUE, nothing to do" >&2; exit 0; }

online_pkgs=()
online_ids=()
while IFS='|' read -r id kind pkgs; do
    case "$id" in ''|'#'*) continue ;; esac
    ticked=0
    [[ $chosen == *",$id,"* ]] && ticked=1
    case "$kind" in
    local)
        (( ticked )) && continue
        for p in $pkgs; do
            if pacman -Qq "$p" > /dev/null 2>&1; then
                # a package that something else needs stays: not an error
                pacman -Rns --noconfirm "$p" > /dev/null 2>&1 || echo "extras: kept $p (still needed)" >&2
            fi
        done
        ;;
    online)
        (( ticked )) || continue
        online_pkgs+=($pkgs)
        online_ids+=("$id")
        ;;
    *) echo "extras: unknown kind '$kind' for $id" >&2 ;;
    esac
done < "$CATALOGUE"

# units enabled for removed packages (bluetooth.service, cups.socket)
find "${AEDWEN_EXTRAS_ROOT:-}/etc/systemd/system" -xtype l -delete 2> /dev/null

if (( ${#online_pkgs[@]} )); then
    # -Syu, not -Sy: refreshing the databases without upgrading is a partial
    # upgrade, which Arch does not support. The kernel and bootloader pacman
    # hooks are already in place, so an upgrade regenerates what it needs.
    if pacman -Syu --needed --noconfirm "${online_pkgs[@]}" ; then
        echo "extras: installed ${online_ids[*]}"
    else
        echo "extras: could not install ${online_ids[*]} (offline?); run: aedwen-extras pending" >&2
        mkdir -p "$(dirname "$PENDING")"
        printf '%s\n' "${online_ids[@]}" >> "$PENDING"
    fi
fi
exit 0
