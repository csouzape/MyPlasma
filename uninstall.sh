#!/usr/bin/env bash
#
# MyPlasma uninstaller
#
# Removes any symlink under $XDG_CONFIG_HOME (or $HOME for the legacy
# gtkrc files) that points back into this repo. Only touches symlinks
# this repo created — real files and unrelated symlinks are left alone.
# Backups made by install.sh (~/.myplasma-backup-*) are NOT restored
# automatically; they're just left on disk for you to restore by hand.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
removed=0

unlink_if_ours() {
    local link="$1"
    [ -L "$link" ] || return 0
    case "$(readlink -f "$link")" in
        "$REPO_DIR"/*)
            rm -v "$link"
            removed=1
            ;;
    esac
}

while IFS= read -r -d '' link; do
    unlink_if_ours "$link"
done < <(find "$XDG_CONFIG_HOME" -type l -print0 2>/dev/null)

unlink_if_ours "$HOME/.gtkrc"
unlink_if_ours "$HOME/.gtkrc-2.0"

echo
if [ "$removed" -eq 1 ]; then
    echo "Done. Backups (if any) are still under ~/.myplasma-backup-*"
else
    echo "Nothing to remove — no MyPlasma symlinks found."
fi