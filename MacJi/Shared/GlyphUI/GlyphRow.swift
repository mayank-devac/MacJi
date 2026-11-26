//
//  GlyphRow.swift
//  MacJi
//
//  Created: 2026-11-27
//  One wide glyph (an emoticon) as a full-width row: the text, its name, selection, hover and
//  press feedback.
//

import SwiftUI

struct GlyphRow: View {
    let glyph: Glyph
    let isSelected: Bool
    @Binding var hovered: Glyph?
    let onPick: () -> Void

    private var isHovered: Bool { hovered == glyph }

    private var highlight: Color {
        if isSelected { return Palette.selectionFill }
        return isHovered ? Palette.hoverFill : .clear
    }

    ////////////////////
    //// Row
    /// The face keeps its natural width and truncates in the middle when it can't fit; the name
    /// sits on the right. The highlight follows the keyboard instantly, like a native menu.

    var body: some View {
        Button(action: onPick) {
            HStack(spacing: EmojiUIMetrics.rowSpacing) {
                Text(glyph.text)
                    .font(.system(size: EmojiUIMetrics.rowFontSize))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: EmojiUIMetrics.rowSpacing)
                Text(glyph.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, EmojiUIMetrics.rowHorizontalPadding)
            .frame(maxWidth: .infinity, minHeight: EmojiUIMetrics.rowHeight)
            .background(RoundedRectangle(cornerRadius: EmojiUIMetrics.cellCornerRadius, style: .continuous).fill(highlight))
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuPressButtonStyle())
        .help(glyph.displayName)
        .accessibilityLabel(glyph.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { inside in
            if inside {
                hovered = glyph
            } else if isHovered {
                hovered = nil
            }
        }
    }

    //// Leaving one row only clears hover if no other row has claimed it already.
    //////////////////
}
