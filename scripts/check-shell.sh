#!/usr/bin/env bash
# Load every AedwenOS shell widget (org.aedwen.*) against the Plasma
# installed on this machine and fail on QML errors.
#
# The widgets use some KDE-internal QML APIs (kicker, volume, brightness,
# power profiles, ...) that can change between Plasma releases; AedwenOS is
# rolling, so run this after a Plasma update and before building an ISO.
# Quick-settings tiles that fail to load are reported by name.
#
# Nothing is installed: widgets are loaded from the repo through
# XDG_DATA_DIRS / QML_IMPORT_PATH, offscreen, with a throwaway config and
# data dir, so your own desktop and settings are untouched.
#
# Usage: scripts/check-shell.sh            (needs plasmawindowed: plasma-sdk
#                                           or plasma-workspace's own copy)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
air=$root/iso/airootfs
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

command -v plasmawindowed >/dev/null || { echo "plasmawindowed not found" >&2; exit 2; }

export QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1
export XDG_DATA_DIRS=$air/usr/share:/usr/local/share:/usr/share
export QML_IMPORT_PATH=$air/usr/lib/qt6/qml
export XDG_CONFIG_HOME=$tmp/config XDG_DATA_HOME=$tmp/data
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
cp "$air/etc/xdg/kdeglobals" "$XDG_CONFIG_HOME/"

fail=0
for dir in "$air"/usr/share/plasma/plasmoids/org.aedwen.*; do
    id=$(basename "$dir")
    log=$tmp/$id.log
    timeout 8 plasmawindowed "$id" >"$log" 2>&1
    # QML errors carry the file:line of the offending .qml; tile failures are
    # logged by the quick-settings popup itself.
    errors=$(grep -E "(\.qml:[0-9]+|aedwen quicksettings: tile .* failed)" "$log" \
             | grep -vE "Injection of parameters into signal handlers is deprecated" | sort -u)
    if [[ -n $errors ]]; then
        echo "FAIL $id"
        sed 's/^/    /' <<<"$errors"
        fail=1
    else
        echo "ok   $id"
    fi
done
exit $fail
