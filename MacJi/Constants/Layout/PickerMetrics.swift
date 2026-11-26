//
//  PickerMetrics.swift
//  MacJi
//
//  Created: 2026-11-26
//  Sizes and spacing of the emoji picker popover.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerView.swift
//

import CoreGraphics

enum PickerMetrics {
    // Popover
    static let size = CGSize(width: 360, height: 440)
    // Tab bar: added to the height only while Symbols or Emoticons is on
    static let tabBarHeight: CGFloat = 30
    static let tabBarBottomPadding: CGFloat = 8
    static let outerPadding: CGFloat = 10

    // Header button beside the search field
    static let headerSpacing: CGFloat = 6
    static let headerButtonWidth: CGFloat = 28

    // Search field
    static let searchHeight: CGFloat = 30
    static let searchCornerRadius: CGFloat = 8
    static let searchHorizontalPadding: CGFloat = 9
    static let searchFontSize: CGFloat = 13
    static let searchIconSpacing: CGFloat = 6

    // Category bar
    static let categoryBar = CategoryBarStyle(height: 26, cornerRadius: 6, spacing: 2)
    static let categoryBarHorizontalPadding: CGFloat = 8
    static let categoryBarBottomPadding: CGFloat = 6

    // Grid: fixed columns so arrow keys move through the same rows the grid draws
    static let columnCount = 9
    static let gridSpacing: CGFloat = 2
    static let gridHorizontalPadding: CGFloat = 8
    static let gridBottomPadding: CGFloat = 8
    static let sectionTitleFontSize: CGFloat = 11
    static let sectionTitleLeading: CGFloat = 4
    static let sectionTitleTop: CGFloat = 8
    static let sectionTitleBottom: CGFloat = 2

    // Footer
    static let footerHeight: CGFloat = 46
    static let footerEmojiSize: CGFloat = 24
    static let footerSpacing: CGFloat = 8
    static let footerHorizontalPadding: CGFloat = 12
    static let keyHintSpacing: CGFloat = 6

    // Hidden menu-bar icon: the popover points at this small rect around the caret or pointer
    static let anchorSize: CGFloat = 2
}
