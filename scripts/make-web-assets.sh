#!/usr/bin/env bash
#
#  make-web-assets.sh
#  MacJi
#
#  Created: 2026-11-26
#  Refreshes the website's copies in WEB/assets: screenshots and icon as WebP, the PNGs that
#  browsers and link previews need, and the emoji data the live demo reads.
#
####################
#### Usage
### scripts/make-web-assets.sh    rewrite WEB/assets from assets/ and the app's emoji.json
# Example: scripts/make-screenshots.sh && scripts/make-web-assets.sh && git diff --stat WEB
# Needs cwebp (brew install webp).
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { print_usage "$0"; exit 0; }
command -v cwebp >/dev/null || fail "cwebp is not installed." "Run: brew install webp"

web="$MACJI_ROOT/WEB/assets"
shots="$MACJI_ROOT/assets/screenshots"
icons="$MACJI_ROOT/assets/icon"

####################
#### WebP copies
### Quality 90 with sharp YUV keeps the screenshots' small text crisp at about a tenth of the size.

to_webp() {
    [[ -f "$1" ]] || fail "${1#"$MACJI_ROOT"/} is missing." "Run scripts/make-screenshots.sh first."
    cwebp -quiet -q 90 -alpha_q 100 -m 6 -sharp_yuv "$1" -o "$2" || fail "cwebp could not convert ${1#"$MACJI_ROOT"/}."
}

mkdir -p "$web/screenshots" "$web/icon" "$web/data"
for name in picker picker-search settings; do
    for theme in light dark; do
        to_webp "$shots/$name-$theme.png" "$web/screenshots/$name-$theme.webp"
    done
done
to_webp "$shots/inline-panel-light.png" "$web/screenshots/inline-panel-light.webp"
to_webp "$icons/icon_128x128@2x.png" "$web/icon/icon-256.webp"

##################

####################
#### Plain copies
### Link previews read the PNG screenshot; favicons and home-screen icons stay PNG.

cp "$shots/inline-panel-light.png" "$web/screenshots/inline-panel-light.png"
cp "$icons/icon_32x32@2x.png" "$web/icon/favicon-64.png"
cp "$icons/icon_128x128@2x.png" "$web/icon/icon-256.png"
cp "$MACJI_ROOT/MacJi/Shared/Glyphs/Resources/emoji.json" "$web/data/emoji.json"

##################

du -h "$web"/screenshots/*.webp "$web"/icon/*.webp | sed "s|$MACJI_ROOT/||"
ok "Website assets written to WEB/assets/"
