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
    static let title = String(localized: "MacJi")
    static let insert = String(localized: "Insert")
    static let copy = String(localized: "Copy")
    static let noResultsHint = String(localized: "Keep typing, or press esc")

    static func noResults(for query: String) -> String {
        String(localized: "No emoji for “\(query)”")
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
