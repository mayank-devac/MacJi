# App icon prompt

Created: 2026-11-26

MacJi ships a simple placeholder icon (`scripts/make-placeholder-icon.swift`: a yellow face on a
blue rounded tile). Generate the real icon in an image tool with the prompt below, then install it.

## Prompt

> App icon: a 3D 2000s skeuomorphic smiling face, glossy yellow plastic finish, deep specular
> highlights, raised beveled edges, set on a rounded square vibrant blue glass tile with a subtle
> inner glow, classic early iOS and Frutiger Aero aesthetic, soft drop shadow, centered,
> front-facing, studio lighting, high detail, macOS app icon, transparent background outside the
> tile, no text.

## Requirements

- **1024 × 1024 PNG** with a transparent background outside the tile.
- Follow Apple's macOS icon grid: the tile is about **824 × 824**, centred, with the rest of the
  canvas left for the drop shadow. Don't fill the whole canvas, or MacJi will look bigger than
  every other icon in the Dock and Finder.
- No text, and it should still be readable at 16 px (the face should read as a face).

## Install

```sh
scripts/make-icon.sh ~/Downloads/macji-icon-1024.png
./build.sh
```

`make-icon.sh` writes the 16–1024 px sizes and `Contents.json` into
`MacJi/Resources/Assets.xcassets/AppIcon.appiconset`. To go back to the placeholder:
`scripts/make-icon.sh --placeholder`.

The **menu-bar icon** is separate: a monochrome template SF Symbol (`SymbolNames.menuBar`) so it
follows the menu bar's light and dark appearance. Don't use the colour app icon there.
