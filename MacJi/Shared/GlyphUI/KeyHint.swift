//
//  KeyHint.swift
//  MacJi
//
//  Created: 2026-11-26
//  One footer shortcut: a small keycap with an optional caption.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerComponents.swift
//

import SwiftUI

struct KeyHint: View {
    let key: String
    var label: String?

    var body: some View {
        HStack(spacing: EmojiUIMetrics.keyLabelSpacing) {
            Text(key)
                .font(.system(size: EmojiUIMetrics.keyFontSize, weight: .medium))
                .padding(.horizontal, EmojiUIMetrics.keyHorizontalPadding)
                .frame(minWidth: EmojiUIMetrics.keyMinWidth, minHeight: EmojiUIMetrics.keyMinHeight)
                .background(RoundedRectangle(cornerRadius: EmojiUIMetrics.keyCornerRadius).fill(Palette.keycapFill))
            if let label {
                Text(label).font(.system(size: EmojiUIMetrics.keyFontSize))
            }
        }
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}
