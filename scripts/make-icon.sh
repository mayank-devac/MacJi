#!/usr/bin/env bash
#
#  make-icon.sh
#  MacJi
#
#  Created: 2026-11-26
#  Writes every macOS AppIcon size and a matching Contents.json from one 1024 × 1024 PNG.
#
####################
#### Usage
### scripts/make-icon.sh <path-to-1024.png>
###   Replaces the images in MacJi/Resources/Assets.xcassets/AppIcon.appiconset.
### scripts/make-icon.sh --placeholder
###   Draws the placeholder icon first (scripts/make-placeholder-icon.swift), then writes the sizes.
# Example: scripts/make-icon.sh ~/Downloads/macji-icon-1024.png
# The PNG should follow Apple's macOS grid: an ~824 px tile centred in 1024 with room for its shadow.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

[[ $# -eq 1 ]] || { print_usage "$0"; exit 1; }
[[ "$1" == "-h" || "$1" == "--help" ]] && { print_usage "$0"; exit 0; }

source_png="$1"
if [[ "$1" == "--placeholder" ]]; then
    mkdir -p "$MACJI_ROOT/.build"
    source_png="$MACJI_ROOT/.build/placeholder-icon-1024.png"
    step "Drawing placeholder icon"
    swift "$MACJI_ROOT/scripts/make-placeholder-icon.swift" "$source_png" >/dev/null
fi

[[ -f "$source_png" ]] || fail "No such file: $source_png" "Pass the path to a 1024 × 1024 PNG."
width=$(sips -g pixelWidth "$source_png" | awk '/pixelWidth/ {print $2}')
height=$(sips -g pixelHeight "$source_png" | awk '/pixelHeight/ {print $2}')
[[ "$width" == "1024" && "$height" == "1024" ]] || fail "Icon is ${width}×${height}, not 1024×1024." "Export the image at 1024 × 1024."

####################
#### Sizes
### macOS needs 16, 32, 128, 256 and 512 pt at 1x and 2x (64 and 1024 px appear as 2x files).

mkdir -p "$MACJI_APPICON_DIR"
images=()
for points in 16 32 128 256 512; do
    for scale in 1 2; do
        pixels=$((points * scale))
        name="icon_${points}x${points}@${scale}x.png"
        sips -z "$pixels" "$pixels" "$source_png" --out "$MACJI_APPICON_DIR/$name" >/dev/null
        images+=("    { \"filename\" : \"$name\", \"idiom\" : \"mac\", \"scale\" : \"${scale}x\", \"size\" : \"${points}x${points}\" }")
    done
done
step "Wrote 10 sizes (16–1024 px)"

#### The 64 px image is icon_32x32@2x; the 1024 px image is icon_512x512@2x.
##################

joined=$(printf '%s,\n' "${images[@]}")
cat > "$MACJI_APPICON_DIR/Contents.json" <<JSON
{
  "images" : [
${joined%,}
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
ok "AppIcon updated in ${MACJI_APPICON_DIR#$MACJI_ROOT/}"
