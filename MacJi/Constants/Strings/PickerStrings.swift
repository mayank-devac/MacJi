//
//  PickerStrings.swift
//  MacJi
//
//  Created: 2026-11-26
//  User-visible text of the emoji picker popover.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerView.swift, octopus/UI/EmojiPicker/EmojiPickerModel.swift
//

import Foundation

enum PickerStrings {
    static let searchPlaceholder = String(localized: "Search emoji")
    static let searchSymbolsPlaceholder = String(localized: "Search symbols")
    static let searchEmoticonsPlaceholder = String(localized: "Search emoticons")
    static let clearSearch = String(localized: "Clear search")
    static let recentlyUsed = String(localized: "Recently Used")
    static let searchResults = String(localized: "Best Matches")
    static let noResults = String(localized: "Nothing found")
    static let noResultsHint = String(localized: "Try another word, or press esc to clear")
    static let copy = String(localized: "Copy")
    static let filter = String(localized: "Filter")
    static let keyHelp = String(localized: "Return copies and closes · Option-Return copies and stays open · Tab / Shift-Tab change category · ⌘1–⌘3 change tab · Esc clears the search, then closes")
    static let tabsLabel = String(localized: "Show")
    static let tabsHelp = String(localized: "Emoji, symbols or emoticons (⌘1, ⌘2, ⌘3)")

    static func alias(_ alias: String) -> String {
        ":\(alias):"
    }
}

/// Text of the shared glyph views used by both the panel and the picker.
enum GlyphStrings {
    static let allCategories = String(localized: "All")

    static func categoryHelp(_ title: String) -> String {
        String(localized: "\(title) (Tab / Shift-Tab)")
    }

    static func copied(_ emoji: String) -> String {
        String(localized: "Copied \(emoji)")
    }
}
