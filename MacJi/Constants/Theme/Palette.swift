//
//  Palette.swift
//  MacJi
//
//  Created: 2026-11-26
//  Colours for the panel, picker, shared emoji views and Settings.
//  Ported from Octopus: octopus/Constants/Theme/MenuPalette.swift
//

import SwiftUI

////////////////////
//// Colours
/// System and accent colours adapt to Light, Dark and Increase Contrast automatically.

enum Palette {
    // Emoji cells
    static let selectionFill = Color.accentColor.opacity(0.3)
    static let hoverFill = Color.primary.opacity(0.1)

    // Cards and badges
    static let cardStroke = Color.primary.opacity(0.1)
    static let cardShadow = Color.black.opacity(0.28)
    static let badgeStroke = Color.primary.opacity(0.1)
    static let badgeShadow = Color.black.opacity(0.15)
    static let copiedCheck = Color.green
    static let keycapFill = Color.primary.opacity(0.08)

    // Picker
    static let searchFill = Color.primary.opacity(0.06)
    static let searchStroke = Color.primary.opacity(0.08)
    static let searchFocusStroke = Color.accentColor.opacity(0.6)
    static let categorySelectedFill = Color.accentColor.opacity(0.15)
    static let categorySelected = Color.accentColor

    // Permission guide
    static let guideChipFill = Color.accentColor.opacity(0.12)
    static let guideChipStroke = Color.accentColor.opacity(0.7)
    static let guideCardStroke = Color.white.opacity(0.12)
    static let guideIconBackground = Color(nsColor: .windowBackgroundColor).opacity(0.6)

    // Settings status
    static let granted = Color.green
    static let attention = Color.orange
    static let error = Color.red
}

//// Status colours always come with an icon and text, never colour alone.
//////////////////
