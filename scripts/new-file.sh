#!/usr/bin/env bash
#
#  new-file.sh
#  MacJi
#
#  Created: 2026-11-26
#  Creates a Swift file with the standard MacJi header. The Xcode project uses synchronised
#  folders, so a file under MacJi/ or MacJiTests/ joins its target with no project edit.
#
####################
#### Usage
### scripts/new-file.sh <MacJi/Folder/Name.swift> "<what this file does>"
### scripts/new-file.sh <MacJiTests/Folder/NameTests.swift> "<behaviour it protects>"
# Example: scripts/new-file.sh MacJi/Shared/EmojiUI/SkinTonePicker.swift "Skin-tone variants for one emoji."
# Refuses to overwrite an existing file. Then run scripts/repo-map.py and describe the new entry.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { print_usage "$0"; exit 0; }
[[ $# -eq 2 && -n "$2" ]] || { print_usage "$0"; exit 1; }

path="${1#./}"
responsibility="$2"
name=$(basename "$path")
[[ "$name" == *.swift ]] || fail "$name is not a .swift file." "Pass a path ending in .swift."
case "$path" in
    MacJi/*) imports="import Foundation" ;;
    MacJiTests/*) imports=$'import Testing\n@testable import MacJi' ;;
    *) fail "$path is outside MacJi/ and MacJiTests/." "App code goes under MacJi/, tests under MacJiTests/ (see repo_map.md)." ;;
esac
target="$MACJI_ROOT/$path"
[[ -e "$target" ]] && fail "$path already exists." "Pick another name; this script never overwrites."

####################
#### Write the header
### The responsibility wraps at about 96 columns, each line prefixed like the rest of the header.

mkdir -p "$(dirname "$target")"
{
    printf '//\n//  %s\n//  %s\n//\n//  Created: %s\n' "$name" "$MACJI_APP_NAME" "$(date +%Y-%m-%d)"
    printf '%s\n' "$responsibility" | fold -s -w 92 | sed -E 's/[[:space:]]+$//; s/^/\/\/  /'
    printf '//\n\n%s\n' "$imports"
} >"$target"

##################

ok "Created $path"
printf '  next: scripts/repo-map.py, then describe %s in repo_map.md\n' "$name"
