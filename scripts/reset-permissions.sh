#!/usr/bin/env bash
#
#  reset-permissions.sh
#  MacJi
#
#  Created: 2026-11-26
#  Dev only: clears MacJi's Accessibility grant and relaunches it, to test the first-run
#  permission flow. Asks before changing anything.
#
####################
#### Usage
### scripts/reset-permissions.sh             the Debug build (bundle ID …macji.debug)
### scripts/reset-permissions.sh --release   the installed release in /Applications
# Example: ./build.sh && scripts/reset-permissions.sh
# Only the chosen bundle ID is reset; other apps' grants are untouched.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

case "${1:-}" in
    -h|--help) print_usage "$0"; exit 0 ;;
    --release) bundle_id="$MACJI_BUNDLE_ID"; app="/Applications/$MACJI_APP_NAME.app" ;;
    "") bundle_id="$MACJI_DEBUG_BUNDLE_ID"; app="$MACJI_DERIVED_DATA/Build/Products/Debug/$MACJI_APP_NAME.app" ;;
    *) print_usage "$0"; exit 1 ;;
esac

printf 'This will quit %s, reset the Accessibility grant for %s and relaunch it.\n' "${app#$MACJI_ROOT/}" "$bundle_id"
confirm "Continue?" || { echo "Nothing changed."; exit 0; }

quit_app "$app"
tccutil reset Accessibility "$bundle_id" >/dev/null || fail "tccutil could not reset $bundle_id." "Remove MacJi by hand in System Settings › Privacy & Security › Accessibility."
ok "Accessibility grant reset for $bundle_id"

if [[ -d "$app" ]]; then
    open -n "$app"
    ok "Relaunched ${app#$MACJI_ROOT/}"
else
    printf '· %s is not built; run ./build.sh to launch it\n' "${app#$MACJI_ROOT/}"
fi
