//
//  PickerTab.swift
//  MacJi
//
//  Created: 2026-11-27
//  The picker's tabs (Emoji, Symbols, Emoticons) and what each one searches and shows.
//

import Foundation

/// Raw values are stored as the last tab used; never rename one.
enum PickerTab: String, CaseIterable, Identifiable, Sendable {
    case emoji, symbols, emoticons

    var id: Self { self }

    var title: String {
        switch self {
        case .emoji: PanelStrings.emojiTitle
        case .symbols: PanelStrings.symbolsTitle
        case .emoticons: PanelStrings.emoticonsTitle
        }
    }

    var searchPlaceholder: String {
        switch self {
        case .emoji: PickerStrings.searchPlaceholder
        case .symbols: PickerStrings.searchSymbolsPlaceholder
        case .emoticons: PickerStrings.searchEmoticonsPlaceholder
        }
    }

    /// Emoticons are wide, so they list one per row.
    var columnCount: Int { self == .emoticons ? 1 : PickerMetrics.columnCount }
}
