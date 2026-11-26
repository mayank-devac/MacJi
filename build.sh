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
### ./build.sh --no-launch --unsigned   build without code signing (CI)
# Example: CONFIGURATION=Release ./build.sh
# Output goes to .build/DerivedData. Only the app at that exact path is quit, never another MacJi.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/scripts/config.sh"

launch=true
signing=()
for arg in "$@"; do
    case "$arg" in
        -h|--help) print_usage "$0"; exit 0 ;;
        --no-launch) launch=false ;;
        --unsigned) signing=(CODE_SIGNING_ALLOWED=NO) ;;
        *) print_usage "$0"; exit 1 ;;
    esac
done

configuration="${CONFIGURATION:-Debug}"
app="$MACJI_DERIVED_DATA/Build/Products/$configuration/$MACJI_APP_NAME.app"

step "Building $MACJI_APP_NAME ($configuration)"
log="$MACJI_ROOT/.build/build.log"
mkdir -p "$MACJI_ROOT/.build"
if ! xcodebuild -project "$MACJI_PROJECT" -scheme "$MACJI_SCHEME" -configuration "$configuration" \
        -destination "$MACJI_DESTINATION" -derivedDataPath "$MACJI_DERIVED_DATA" ${signing[@]+"${signing[@]}"} build >"$log" 2>&1; then
    print_errors "$log"
    fail "Build failed (full log: .build/build.log)" "Fix the errors above, then run ./build.sh again."
fi
[[ -d "$app" ]] || fail "Build succeeded but $app is missing." "Check the scheme's product name."
ok "Built ${app#$MACJI_ROOT/}"
$launch || exit 0

quit_app "$app"

####################
#### Keep the Accessibility grant matching this build
### macOS stores the app's designated requirement with the grant. When a build's requirement differs
### (ad-hoc signing, a new certificate), the old entry still shows "on" in System Settings but no
### longer matches, and switching it on again changes nothing. Resetting that one entry lets the
### new build be allowed with a single switch instead of removing and re-adding it by hand.
# An ad-hoc requirement pins each build's own hash, so it changes every build: only warn for that.

bundle_id="$MACJI_BUNDLE_ID"
[[ "$configuration" == "Debug" ]] && bundle_id="$MACJI_DEBUG_BUNDLE_ID"
requirement=$(codesign -d -r- "$app" 2>/dev/null | sed -n 's/^designated => //p' || true)
record="$MACJI_ROOT/.build/designated-requirement-$configuration.txt"
previous=$(cat "$record" 2>/dev/null || true)
if [[ -z "$requirement" || "$requirement" == cdhash* ]]; then
    printf '· Signed ad-hoc: macOS forgets the Accessibility grant after every build\n'
    printf '  fix: set CODE_SIGN_IDENTITY in Config/LocalSigning.xcconfig\n'
elif [[ -n "$previous" && "$previous" != "$requirement" ]]; then
    printf '· The signature changed since the last build, so the saved Accessibility grant for %s no longer matches.\n' "$bundle_id"
    if confirm "Reset that grant so this build can be allowed with one switch?"; then
        tccutil reset Accessibility "$bundle_id" >/dev/null && ok "Accessibility grant reset for $bundle_id" \
            || printf '· tccutil failed; remove MacJi in System Settings › Privacy & Security › Accessibility\n'
    else
        printf '· Kept it; remove and re-add MacJi in Accessibility, or run scripts/reset-permissions.sh\n'
    fi
fi
printf '%s\n' "$requirement" >"$record"

#### A stable signing identity keeps the requirement, and so the grant, across every rebuild.
##################

open -n "$app"
running=""
for _ in $(seq 1 30); do
    running=$(pgrep -f "$app/Contents/MacOS/$MACJI_APP_NAME" | head -1 || true)
    [[ -n "$running" ]] && break
    sleep 0.1
done
[[ -n "$running" ]] || fail "MacJi did not start." "Run: open \"$app\" and check Console.app for MacJi."
ok "Running (pid $running): $app"
