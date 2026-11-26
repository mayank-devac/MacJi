#!/usr/bin/env bash
#
#  setup.sh
#  MacJi
#
#  Created: 2026-11-26
#  First-time setup of a fresh clone. Safe to run again; it never creates certificates or keys,
#  it only reports whether the release ones exist.
#
####################
#### Usage
### scripts/setup.sh    check Xcode, fetch the Octopus submodule, create LocalSigning.xcconfig,
###                     resolve Swift packages, report release signing status
# Example: git clone … && cd MacJi && scripts/setup.sh && ./build.sh
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { print_usage "$0"; exit 0; }
cd "$MACJI_ROOT"

####################
#### Toolchain
### Synchronised folders need Xcode 16; the command-line tools must point at a full Xcode.

xcode-select -p >/dev/null 2>&1 || fail "No developer tools found." "Install Xcode from the App Store, then run: xcode-select --install"
xcode_version=$(xcodebuild -version 2>/dev/null | awk '/^Xcode/ {print $2}')
[[ -n "$xcode_version" ]] || fail "xcodebuild doesn't point at a full Xcode." "Run: sudo xcode-select -s /Applications/Xcode.app"
(( ${xcode_version%%.*} >= 16 )) || fail "Xcode $xcode_version is too old." "Install Xcode 16 or later."
ok "Xcode $xcode_version"

##################

####################
#### Repository

step "Fetching the Octopus reference submodule"
if git submodule update --init Upstream/octopus >/dev/null 2>&1; then
    ok "Upstream/octopus at $(git -C Upstream/octopus rev-parse --short HEAD)"
else
    printf '! Upstream/octopus could not be fetched (offline?). It is reference only; the build does not need it.\n'
fi

if [[ -f Config/LocalSigning.xcconfig ]]; then
    ok "Config/LocalSigning.xcconfig exists"
else
    cp Config/LocalSigning.example.xcconfig Config/LocalSigning.xcconfig
    ok "Created Config/LocalSigning.xcconfig (set CODE_SIGN_IDENTITY there to keep the Accessibility grant across builds)"
fi

step "Resolving Swift packages"
log="$MACJI_ROOT/.build/setup.log"
mkdir -p "$MACJI_ROOT/.build"
xcodebuild -resolvePackageDependencies -project "$MACJI_PROJECT" -scheme "$MACJI_SCHEME" \
    -derivedDataPath "$MACJI_DERIVED_DATA" >"$log" 2>&1 \
    || fail "Swift packages could not be resolved (log: .build/setup.log)." "Check your network, then run scripts/setup.sh again."
ok "Swift packages resolved"

##################

####################
#### Release signing (report only)
### Only needed to publish releases; docs/RELEASING.md creates them. Nothing here reads a secret:
### the Keychain lookups ask only whether the items exist.

if security find-identity -p codesigning 2>/dev/null | grep -qF "\"$MACJI_SIGNING_IDENTITY\""; then
    ok "Certificate \"$MACJI_SIGNING_IDENTITY\" found"
else
    printf '· Certificate "%s" not found (only needed for releases; see docs/RELEASING.md)\n' "$MACJI_SIGNING_IDENTITY"
fi
if security find-generic-password -s "https://sparkle-project.org" -a "$MACJI_SPARKLE_KEY_ACCOUNT" >/dev/null 2>&1; then
    ok "Sparkle EdDSA key found (account $MACJI_SPARKLE_KEY_ACCOUNT)"
else
    printf '· Sparkle EdDSA key not found (only needed for releases; see docs/RELEASING.md)\n'
fi
if grep -qF "$MACJI_PLACEHOLDER_PUBLIC_KEY" MacJi/Resources/Info.plist; then
    printf '· Info.plist still has the placeholder SUPublicEDKey; release.py refuses to run until it is replaced\n'
fi

##################

ok "Setup done. Next: ./build.sh"
