//
//  EmojiCell.swift
//  MacJi
//
//  Created: 2026-11-26
//  One emoji button, shared by the panel and the picker: keyboard selection highlight,
//  a slight grow on hover, a press shrink, and a tooltip naming the emoji.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerComponents.swift
//

import SwiftUI

struct EmojiCell: View {
    let emoji: Emoji
    let isSelected: Bool
    @Binding var hovered: Emoji?
    let onPick: () -> Void

    private var isHovered: Bool { hovered == emoji }

    private var highlight: Color {
        if isSelected { return Palette.selectionFill }
        return isHovered ? Palette.hoverFill : .clear
    }

    ////////////////////
    //// Cell
    /// The highlight follows the keyboard instantly (like a native menu); only the hover grow animates.
    // The native tooltip appears once the pointer rests; VoiceOver reads the emoji's name.

    var body: some View {
        Button(action: onPick) {
            Text(emoji.emoji)
                .font(.system(size: EmojiUIMetrics.cellEmojiSize))
                .frame(width: EmojiUIMetrics.cellSize, height: EmojiUIMetrics.cellSize)
                .background(RoundedRectangle(cornerRadius: EmojiUIMetrics.cellCornerRadius, style: .continuous).fill(highlight))
                .scaleEffect(isHovered ? EmojiUIMetrics.cellHoverScale : 1)
                .animation(PanelMotion.hoverGrow, value: isHovered)
                .contentShape(Rectangle())
        }
        .buttonStyle(MenuPressButtonStyle())
        .help(emoji.displayName)
        .accessibilityLabel(emoji.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { inside in
            if inside {
                hovered = emoji
            } else if isHovered {
                hovered = nil
            }
        }
    }

    //// Leaving one cell only clears hover if no other cell has claimed it already.
    //////////////////
}
