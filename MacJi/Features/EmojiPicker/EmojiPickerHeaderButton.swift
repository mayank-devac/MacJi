//
//  EmojiPickerHeaderButton.swift
//  MacJi
//
//  Created: 2026-11-26
//  A small icon button beside the picker's search field, with a hover fill and tooltip.
//

import SwiftUI

struct EmojiPickerHeaderButton: View {
    let symbol: String
    let title: String
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: PickerMetrics.searchCornerRadius, style: .continuous)
        Button(action: action) {
            Image(systemName: symbol)
                .frame(width: PickerMetrics.headerButtonWidth, height: PickerMetrics.searchHeight)
                .foregroundStyle(.secondary)
                .background {
                    if hovered { shape.fill(Palette.hoverFill) }
                }
                .contentShape(shape)
        }
        .buttonStyle(MenuPressButtonStyle())
        .help(title)
        .accessibilityLabel(title)
        .onHover { hovered = $0 }
    }
}
