#!/usr/bin/env bash
#
# MyPlasma installer
#
# Symlinks everything under config/ into the right place under $HOME,
# so a fresh box ends up with this exact KDE Plasma setup. No copies:
# edit a file in ~/.config, it edits the file in this repo (they're the
# same inode), so `git status` in this repo always shows what changed.
#
# This script only deals with dotfiles. Installing the actual packages
# (dolphin, kate, plasma-desktop, gtk themes, etc.) is dsxtool's job,
# not this repo's.
#
# Supported: Arch Linux.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$REPO_DIR/config"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.myplasma-backup-$(date +%Y%m%d-%H%M%S)"
backed_up=0

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ]; then
        rm -f "$dst"
    elif [ -e "$dst" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "${dst#"$HOME"/}")"
        mv "$dst" "$BACKUP_DIR/${dst#"$HOME"/}"
        backed_up=1
    fi

    ln -s "$src" "$dst"
    echo "linked  ${dst#"$HOME"/}"
}


while IFS= read -r -d '' f; do
    rel="${f#"$CONFIG_DIR"/plasma/}"
    link "$f" "$XDG_CONFIG_HOME/$rel"
done < <(find "$CONFIG_DIR/plasma" \( -type f -o -type l \) -print0 2>/dev/null)

while IFS= read -r -d '' f; do
    rel="${f#"$CONFIG_DIR"/applications/}"
    rel="${rel#*/}"
    link "$f" "$XDG_CONFIG_HOME/$rel"
done < <(find "$CONFIG_DIR/applications" -mindepth 2 \( -type f -o -type l \) -print0 2>/dev/null)


for v in 3 4; do
    [ -d "$CONFIG_DIR/gtk/gtk-$v.0" ] || continue
    while IFS= read -r -d '' f; do
        rel="${f#"$CONFIG_DIR"/gtk/}"
        link "$f" "$XDG_CONFIG_HOME/$rel"
    done < <(find "$CONFIG_DIR/gtk/gtk-$v.0" \( -type f -o -type l \) -print0)
done


[ -f "$CONFIG_DIR/gtk/gtkrc" ]    && link "$CONFIG_DIR/gtk/gtkrc"    "$HOME/.gtkrc"
[ -f "$CONFIG_DIR/gtk/gtkrc-2.0" ] && link "$CONFIG_DIR/gtk/gtkrc-2.0" "$HOME/.gtkrc-2.0"

echo
if [ "$backed_up" -eq 1 ]; then
    echo "Done. Existing files that were overwritten got backed up to:"
    echo "  $BACKUP_DIR"
else
    echo "Done."
fi