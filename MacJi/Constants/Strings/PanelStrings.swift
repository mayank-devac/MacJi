//
//  PanelStrings.swift
//  MacJi
//
//  Created: 2026-11-26
//  User-visible text of the inline panel.
//  Ported from Octopus: octopus/UI/MacJi/MacJiView.swift
//

import Foundation

enum PanelStrings {
    static let emojiTitle = String(localized: "Emoji")
    static let symbolsTitle = String(localized: "Symbols")
    static let emoticonsTitle = String(localized: "Emoticons")
    static let insert = String(localized: "Insert")
    static let copy = String(localized: "Copy")
    static let noResultsHint = String(localized: "Keep typing, or press esc")
    static let noResultsInFilterHint = String(localized: "Press tab for another category, or esc")

    static func noEmoji(for query: String) -> String {
        String(localized: "No emoji for “\(query)”")
    }

    static func noSymbols(for query: String) -> String {
        String(localized: "No symbols for “\(query)”")
    }

    static func noEmoticons(for query: String) -> String {
        String(localized: "No emoticons for “\(query)”")
    }

    /// "U+2192" for one scalar, "U+00AF U+005C …" for longer text.
    static func codePoints(of text: String) -> String {
        text.unicodeScalars.map { String(format: "U+%04X", $0.value) }.joined(separator: " ")
    }

    static func resultCount(_ count: Int) -> String {
        String(localized: "\(count) results")
    }
}

////////////////////
//// Keycaps
/// Symbols shown on the footer keycaps; the same glyphs macOS uses in menus.

enum KeycapStrings {
    static let returnKey = "↩"
    static let shiftReturn = "⇧↩"
    static let optionReturn = "⌥↩"
    static let tab = "⇥"
    static let escape = "esc"
}

//////////////////
