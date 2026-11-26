#!/usr/bin/env bash
#
#  config.sh
#  MacJi
#
#  Created: 2026-11-26
#  Shared values for every MacJi script. Source it; never copy these values into a script.
#  Python scripts read the same values from scripts/config.py.
#

####################
#### Project identity
### The bundle ID and certificate name are permanent after the first release:
### the Accessibility grant and login item stay valid only while both stay the same.

MACJI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACJI_APP_NAME="MacJi"
MACJI_SCHEME="MacJi"
MACJI_PROJECT="$MACJI_ROOT/MacJi.xcodeproj"
MACJI_BUNDLE_ID="io.github.mayank-devac.macji"
MACJI_DEBUG_BUNDLE_ID="$MACJI_BUNDLE_ID.debug"
MACJI_SIGNING_IDENTITY="MacJi Release"
MACJI_SPARKLE_KEY_ACCOUNT="macji"
MACJI_PLACEHOLDER_PUBLIC_KEY="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

#### Keep in sync with Config/Base.xcconfig (MACJI_BUNDLE_ID) and scripts/config.py.
##################

####################
#### Paths and repositories

MACJI_DERIVED_DATA="${DERIVED_DATA:-$MACJI_ROOT/.build/DerivedData}"
MACJI_DESTINATION="platform=macOS,arch=$(uname -m)"
MACJI_RELEASE_DIR="$MACJI_ROOT/.build/release"
MACJI_XCCONFIG="$MACJI_ROOT/Config/Base.xcconfig"
MACJI_INFO_PLIST="$MACJI_ROOT/MacJi/Resources/Info.plist"
MACJI_APPICON_DIR="$MACJI_ROOT/MacJi/Resources/Assets.xcassets/AppIcon.appiconset"
MACJI_SOURCE_REPO="mayank-devac/MacJi"
MACJI_DIST_REPO="mayank-devac/macji-dist"
MACJI_OCTOPUS_PATH="$MACJI_ROOT/Upstream/octopus"
MACJI_OCTOPUS_REPO="mayank-devac/octopus-mac"

##################

####################
#### Output helpers
### One line per step, a short success line, and a fix hint on failure.

step() { printf '› %s\n' "$*"; }
ok() { printf '✓ %s\n' "$*"; }
fail() {
    printf '✗ %s\n' "$1" >&2
    [[ $# -gt 1 ]] && printf '  fix: %s\n' "$2" >&2
    exit 1
}
confirm() {
    local answer
    read -r -p "$1 [y/N] " answer
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}
# Prints each distinct "error:" line of an xcodebuild log, paths relative to the repo, or the
# log's last lines when a failure has no such line (a crash, a signing or toolchain problem).
print_errors() {
    local errors
    errors=$({ grep -E "error[: ]" "$1" || true; } | sed "s|$MACJI_ROOT/||" | sort -u | head -20)
    if [[ -n "$errors" ]]; then printf '%s\n' "$errors" >&2; else tail -25 "$1" >&2; fi
}
# Prints a script's header comment (everything after the shebang up to the first code line).
print_usage() {
    awk 'NR > 1 && /^#/ { sub(/^#+ ?/, ""); print; next } NR > 1 { exit }' "$1"
}

#### Scripts that delete, reset or publish must call confirm first.
##################

####################
#### Quit one MacJi.app
### Matches the executable path inside the given bundle, so an installed MacJi (or Octopus)
### is never touched when quitting a dev build. SIGTERM lets AppKit run applicationWillTerminate,
### which removes the event tap.
# A refused or slow quit fails the script instead of leaving two copies running.

quit_app() {
    local executable="$1/Contents/MacOS/$MACJI_APP_NAME" pids
    pids=$(pgrep -f "$executable" || true)
    [[ -z "$pids" ]] && return 0
    step "Quitting ${1#$MACJI_ROOT/}"
    kill -TERM $pids
    for _ in $(seq 1 50); do
        pgrep -f "$executable" >/dev/null || return 0
        sleep 0.2
    done
    fail "MacJi did not quit." "Quit it from its menu-bar menu, then run the script again."
}

##################
