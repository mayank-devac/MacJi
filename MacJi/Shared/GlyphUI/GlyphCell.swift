//
//  GlyphCell.swift
//  MacJi
//
//  Created: 2026-11-26
//  One glyph button, shared by the panel and the picker: keyboard selection highlight,
//  a slight grow on hover, a press shrink, and a tooltip naming the glyph.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerComponents.swift
//

import SwiftUI

struct GlyphCell: View {
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
    //// Cell
    /// The highlight follows the keyboard instantly (like a native menu); only the hover grow animates.
    // The native tooltip appears once the pointer rests; VoiceOver reads the glyph's name.

    var body: some View {
        Button(action: onPick) {
            Text(glyph.text)
                .font(.system(size: EmojiUIMetrics.cellEmojiSize))
                .frame(width: EmojiUIMetrics.cellSize, height: EmojiUIMetrics.cellSize)
                .background(RoundedRectangle(cornerRadius: EmojiUIMetrics.cellCornerRadius, style: .continuous).fill(highlight))
                .scaleEffect(isHovered ? EmojiUIMetrics.cellHoverScale : 1)
                .animation(PanelMotion.hoverGrow, value: isHovered)
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

    //// Leaving one cell only clears hover if no other cell has claimed it already.
    //////////////////
}
