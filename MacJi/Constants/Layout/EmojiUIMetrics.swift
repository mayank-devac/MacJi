//
//  EmojiUIMetrics.swift
//  MacJi
//
//  Created: 2026-11-26
//  Sizes of the shared emoji views: the grid cell, footer keycaps and the "Copied" badge.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerComponents.swift
//

import CoreGraphics

enum EmojiUIMetrics {
    // Emoji cell
    static let cellEmojiSize: CGFloat = 24
    static let cellSize: CGFloat = 34
    static let cellCornerRadius: CGFloat = 6
    static let cellHoverScale: CGFloat = 1.15

    // Glyph row (emoticons): one wide glyph per row
    static let rowHeight: CGFloat = 26
    static let rowFontSize: CGFloat = 15
    static let rowSpacing: CGFloat = 8
    static let rowHorizontalPadding: CGFloat = 8

    // Key hint
    static let keyFontSize: CGFloat = 10
    static let keyHorizontalPadding: CGFloat = 4
    static let keyMinWidth: CGFloat = 18
    static let keyMinHeight: CGFloat = 16
    static let keyCornerRadius: CGFloat = 4
    static let keyLabelSpacing: CGFloat = 3

    // Copied badge
    static let badgeFontSize: CGFloat = 12
    static let badgeSpacing: CGFloat = 6
    static let badgeHorizontalPadding: CGFloat = 12
    static let badgeVerticalPadding: CGFloat = 6
    static let badgeShadowRadius: CGFloat = 6
    static let badgeShadowY: CGFloat = 2
    static let badgeBottomPadding: CGFloat = 10

    // Empty state
    static let emptyStateSpacing: CGFloat = 4
}
