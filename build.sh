#!/usr/bin/env bash
#
#  build.sh
#  MacJi
#
#  Created: 2026-11-26
#  Builds MacJi, quits the running copy built from this checkout, relaunches the new build
#  and prints which MacJi.app is running.
#
####################
#### Usage
### ./build.sh                          Debug build (bundle ID ...macji.debug)
### CONFIGURATION=Release ./build.sh    Release build
### ./build.sh --no-launch              build only
# Example: CONFIGURATION=Release ./build.sh
# Output goes to .build/DerivedData. Only the app at that exact path is quit, never another MacJi.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/scripts/config.sh"

launch=true
case "${1:-}" in
    -h|--help) print_usage "$0"; exit 0 ;;
    --no-launch) launch=false ;;
    "") ;;
    *) print_usage "$0"; exit 1 ;;
esac

configuration="${CONFIGURATION:-Debug}"
app="$MACJI_DERIVED_DATA/Build/Products/$configuration/$MACJI_APP_NAME.app"

step "Building $MACJI_APP_NAME ($configuration)"
log="$MACJI_ROOT/.build/build.log"
mkdir -p "$MACJI_ROOT/.build"
if ! xcodebuild -project "$MACJI_PROJECT" -scheme "$MACJI_SCHEME" -configuration "$configuration" \
        -destination "$MACJI_DESTINATION" -derivedDataPath "$MACJI_DERIVED_DATA" build >"$log" 2>&1; then
    grep -E "error:" "$log" | sed "s|$MACJI_ROOT/||" | sort -u | head -20 >&2
    fail "Build failed (full log: .build/build.log)" "Fix the errors above, then run ./build.sh again."
fi
[[ -d "$app" ]] || fail "Build succeeded but $app is missing." "Check the scheme's product name."
ok "Built ${app#$MACJI_ROOT/}"
$launch || exit 0

quit_app "$app"
open -n "$app"
sleep 1
running=$(pgrep -f "$app/Contents/MacOS/$MACJI_APP_NAME" | head -1 || true)
[[ -n "$running" ]] || fail "MacJi did not start." "Run: open \"$app\" and check Console.app for MacJi."
ok "Running (pid $running): $app"
