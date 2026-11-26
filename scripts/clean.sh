#!/usr/bin/env bash
#
#  clean.sh
#  MacJi
#
#  Created: 2026-11-26
#  Removes build output and release artefacts for this checkout. Lists everything first and
#  deletes only after you confirm.
#
####################
#### Usage
### scripts/clean.sh    list .build/, stray build folders and Xcode's DerivedData for this project, then ask
# Example: scripts/clean.sh && ./build.sh
# Xcode DerivedData folders are matched by their recorded project path, never by name alone,
# so another MacJi checkout's build is never removed.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { print_usage "$0"; exit 0; }

####################
#### Collect targets

targets=()
for path in "$MACJI_ROOT/.build" "$MACJI_ROOT/build" "$MACJI_ROOT/release-output" "$MACJI_ROOT/scripts/__pycache__"; do
    [[ -e "$path" ]] && targets+=("$path")
done
xcode_derived="$HOME/Library/Developer/Xcode/DerivedData"
for folder in "$xcode_derived/$MACJI_APP_NAME"-*; do
    [[ -f "$folder/info.plist" ]] || continue
    workspace=$(/usr/libexec/PlistBuddy -c "Print :WorkspacePath" "$folder/info.plist" 2>/dev/null || true)
    [[ "$workspace" == "$MACJI_PROJECT" ]] && targets+=("$folder")
done

##################

if [[ ${#targets[@]} -eq 0 ]]; then
    ok "Nothing to clean"
    exit 0
fi
echo "This will delete:"
for path in "${targets[@]}"; do
    printf '  %6s  %s\n' "$(du -sh "$path" 2>/dev/null | cut -f1)" "${path/#$HOME/~}"
done
confirm "Delete these?" || { echo "Nothing deleted."; exit 0; }

####################
#### Delete
### Each target is re-checked to sit inside this checkout or Xcode's DerivedData before removal.

for path in "${targets[@]}"; do
    case "$path" in
        "$MACJI_ROOT"/?*|"$xcode_derived"/"$MACJI_APP_NAME"-?*) rm -rf "$path" ;;
        *) fail "Refusing to delete $path." "This is a bug in clean.sh; please report it." ;;
    esac
done

##################

ok "Removed ${#targets[@]} item(s)"
