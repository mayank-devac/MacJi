//
//  PanelMetrics.swift
//  MacJi
//
//  Created: 2026-11-26
//  Sizes and spacing of the inline panel card, its grid and its floating shadow.
//  Ported from Octopus: octopus/UI/MacJi/MacJiView.swift, octopus/Constants/Layout/WindowMenuMetrics.swift
//

import CoreGraphics

enum PanelMetrics {
    // Card
    static let cardSize = CGSize(width: 320, height: 236)
    static let cornerRadius: CGFloat = 12
    static let horizontalPadding: CGFloat = 12
    static let headerHeight: CGFloat = 30
    static let footerHeight: CGFloat = 36
    static let headerSpacing: CGFloat = 6
    static let footerSpacing: CGFloat = 8
    static let keyHintSpacing: CGFloat = 6

    // Grid: fixed columns so arrow keys move through the same rows the grid draws
    static let columnCount = 8
    static let gridSpacing: CGFloat = 2
    static let gridPadding: CGFloat = 8

    // Type
    static let titleFontSize: CGFloat = 11
    static let queryFontSize: CGFloat = 12
    static let countFontSize: CGFloat = 11
    static let footerEmojiSize: CGFloat = 18

    // Placement and shadow: the transparent margin around the card is where its shadow draws
    static let caretGap: CGFloat = 4
    static let shadowInset: CGFloat = 18
    static let shadowRadius: CGFloat = 14
    static let shadowOffsetY: CGFloat = 6
    static let cardStrokeWidth: CGFloat = 0.5
}
