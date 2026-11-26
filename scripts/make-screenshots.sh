#!/usr/bin/env bash
#
#  make-screenshots.sh
#  MacJi
#
#  Created: 2026-11-26
#  Regenerates every README image from MacJi's real views: picker tabs, search, Settings, the
#  Aliases page and editor, and the typing GIFs, each in light and dark, written to
#  assets/screenshots_by_agent/.
#
####################
#### Usage
### scripts/make-screenshots.sh    render, encode the GIFs, replace assets/screenshots_by_agent/*
# Example: scripts/make-screenshots.sh && git diff --stat assets/screenshots_by_agent
# Needs ffmpeg for the GIFs (brew install ffmpeg). Run it after any visible UI change.
# A nearly transparent window flashes nothing on screen but needs a logged-in session.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { print_usage "$0"; exit 0; }
command -v ffmpeg >/dev/null || fail "ffmpeg is not installed." "Run: brew install ffmpeg"

render="$MACJI_ROOT/.build/screenshots"
assets="$MACJI_ROOT/assets/screenshots_by_agent"
gif_width=880

####################
#### Render
### ReadmeScreenshots is skipped unless MACJI_SCREENSHOTS_DIR is set; xcodebuild forwards
### TEST_RUNNER_-prefixed variables to the test process without the prefix.

rm -rf "$render"
mkdir -p "$render" "$assets"
TEST_RUNNER_MACJI_SCREENSHOTS_DIR="$render" "$MACJI_ROOT/scripts/test.sh" ReadmeScreenshots \
    || fail "Rendering failed." "Read .build/test.log; the generator is MacJiTests/Screenshots/ReadmeScreenshots.swift."

##################

####################
#### Encode the GIFs
### Every *-frames folder becomes one GIF, with one palette built from all its frames; Sierra
### dithering keeps emoji gradients smooth.
# Frame durations come from frames.txt, so the GIF keeps the recorded timing (variable frame rate).

shopt -s nullglob
recordings=("$render"/*-frames)
(( ${#recordings[@]} > 0 )) || fail "No GIF frames were rendered." "Check .build/test.log."
for frames in "${recordings[@]}"; do
    gif="$(basename "$frames" -frames).gif"
    [[ -f "$frames/frames.txt" ]] || fail "No frame list for $gif." "Check .build/test.log."
    step "Encoding $gif"
    ffmpeg -v error -y -f concat -safe 0 -i "$frames/frames.txt" -fps_mode vfr \
        -vf "scale=$gif_width:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=full[p];[b][p]paletteuse=dither=sierra2_4a" \
        -loop 0 "$render/$gif" \
        || fail "ffmpeg could not encode $gif." "Run the ffmpeg command by hand to see why."
done

##################

cp "$render"/*.png "$render"/*.gif "$assets/"
for file in "$assets"/*; do
    printf '  %6s  %s\n' "$(du -h "$file" | cut -f1)" "${file#$MACJI_ROOT/}"
done
ok "README images written to assets/screenshots_by_agent/"
