#!/usr/bin/env swift
//
//  make-placeholder-icon.swift
//  MacJi
//
//  Created: 2026-11-26
//  Draws the placeholder 1024 px app icon: a yellow smiling face on a blue rounded tile,
//  laid out on Apple's macOS icon grid. Used until the real icon from docs/icon-prompt.md exists.
//
//  Usage:   swift scripts/make-placeholder-icon.swift <output.png>
//  Example: swift scripts/make-placeholder-icon.swift .build/icon-1024.png
//

import AppKit

////////////////////
//// macOS icon grid
/// The tile is 824 × 824 centred in the 1024 canvas, leaving room for the drop shadow.
// Corner radius follows Apple's template (about 22.4 % of the tile).

let canvas: CGFloat = 1024
let tile: CGFloat = 824
let cornerRadius: CGFloat = 185
let tileRect = CGRect(x: (canvas - tile) / 2, y: (canvas - tile) / 2 + 10, width: tile, height: tile)

//////////////////

guard CommandLine.arguments.count == 2, CommandLine.arguments[1] != "-h", CommandLine.arguments[1] != "--help" else {
    print("Usage: swift scripts/make-placeholder-icon.swift <output.png>")
    exit(CommandLine.arguments.count == 2 ? 0 : 1)
}

let image = NSImage(size: NSSize(width: canvas, height: canvas), flipped: false) { _ in
    let tilePath = NSBezierPath(roundedRect: tileRect, xRadius: cornerRadius, yRadius: cornerRadius)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = 28
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.set()
    NSColor(red: 0.10, green: 0.42, blue: 0.95, alpha: 1).setFill()
    tilePath.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(starting: NSColor(red: 0.36, green: 0.68, blue: 1.0, alpha: 1),
               ending: NSColor(red: 0.05, green: 0.30, blue: 0.85, alpha: 1))?.draw(in: tilePath, angle: -90)

    ////////////////////
    //// Smiling face
    /// A glossy yellow disc with two eyes and a smile, centred on the tile.

    let face = tileRect.insetBy(dx: 150, dy: 150)
    let facePath = NSBezierPath(ovalIn: face)
    NSGradient(starting: NSColor(red: 1.0, green: 0.92, blue: 0.35, alpha: 1),
               ending: NSColor(red: 0.98, green: 0.70, blue: 0.08, alpha: 1))?.draw(in: facePath, angle: -90)

    NSColor(red: 0.35, green: 0.22, blue: 0.02, alpha: 1).setFill()
    for dx in [-95.0, 95.0] {
        NSBezierPath(ovalIn: CGRect(x: face.midX + dx - 34, y: face.midY + 40, width: 68, height: 96)).fill()
    }
    let smile = NSBezierPath()
    smile.lineWidth = 38
    smile.lineCapStyle = .round
    smile.appendArc(withCenter: CGPoint(x: face.midX, y: face.midY + 10), radius: 170, startAngle: 205, endAngle: 335)
    NSColor(red: 0.35, green: 0.22, blue: 0.02, alpha: 1).setStroke()
    smile.stroke()

    let gloss = NSBezierPath(ovalIn: CGRect(x: face.minX + 90, y: face.maxY - 190, width: face.width - 180, height: 150))
    NSColor.white.withAlphaComponent(0.35).setFill()
    gloss.fill()

    //// Glossy highlight last so it sits over the eyes' top edge.
    //////////////////
    return true
}

guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("✗ Could not render the icon.\n".utf8))
    exit(1)
}
do {
    try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    print("✓ Wrote \(CommandLine.arguments[1])")
} catch {
    FileHandle.standardError.write(Data("✗ Could not write \(CommandLine.arguments[1]): \(error.localizedDescription)\n".utf8))
    exit(1)
}
