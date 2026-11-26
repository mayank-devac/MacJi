#!/usr/bin/env bash
#
#  bump-version.sh
#  MacJi
#
#  Created: 2026-11-26
#  Bumps MARKETING_VERSION and CURRENT_PROJECT_VERSION in Config/Base.xcconfig (the only place
#  they live) and adds a dated heading to CHANGELOG.md. scripts/release.py calls it.
#
####################
#### Usage
### scripts/bump-version.sh <major|minor|patch>
###   Semantic version bump; the build number always goes up by one (Sparkle compares it).
### scripts/bump-version.sh --print
###   Print the current "version build" and change nothing.
# Example: scripts/bump-version.sh patch      0.1.0 (1) → 0.1.1 (2)
# Running it twice bumps twice: it is deliberate, never automatic.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

[[ $# -eq 1 ]] || { print_usage "$0"; exit 1; }
[[ "$1" == "-h" || "$1" == "--help" ]] && { print_usage "$0"; exit 0; }

version=$(awk -F' = ' '/^MARKETING_VERSION/ {print $2}' "$MACJI_XCCONFIG")
build=$(awk -F' = ' '/^CURRENT_PROJECT_VERSION/ {print $2}' "$MACJI_XCCONFIG")
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$build" =~ ^[0-9]+$ ]] \
    || fail "Could not read the version from Config/Base.xcconfig." "Keep the lines 'MARKETING_VERSION = x.y.z' and 'CURRENT_PROJECT_VERSION = n'."

if [[ "$1" == "--print" ]]; then
    echo "$version $build"
    exit 0
fi

IFS=. read -r major minor patch <<<"$version"
case "$1" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
    *) print_usage "$0"; exit 1 ;;
esac
new_version="$major.$minor.$patch"
new_build=$((build + 1))

####################
#### Write
### Only the two version lines change; sed keeps every other line byte for byte.

sed -i '' -E "s/^MARKETING_VERSION = .*/MARKETING_VERSION = $new_version/; s/^CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $new_build/" "$MACJI_XCCONFIG"
step "Config/Base.xcconfig: $version ($build) → $new_version ($new_build)"

changelog="$MACJI_ROOT/CHANGELOG.md"
[[ -f "$changelog" ]] || fail "CHANGELOG.md is missing." "Restore it from git."
heading="## [$new_version] - $(date +%Y-%m-%d)"
if ! grep -qF "## [$new_version]" "$changelog"; then
    awk -v heading="$heading" '
        !done && /^## \[Unreleased\]/ { print; print ""; print heading; done = 1; next }
        { print }
    ' "$changelog" >"$changelog.tmp" && mv "$changelog.tmp" "$changelog"
    step "CHANGELOG.md: added \"$heading\" under Unreleased"
fi

#### Notes written under "Unreleased" now sit under the new heading and feed the appcast.
##################

ok "Version is now $new_version (build $new_build)"
