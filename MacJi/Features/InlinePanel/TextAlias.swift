//
//  TextAlias.swift
//  MacJi
//
//  Created: 2026-11-26
//  One text alias: what you type (e.g. "->" or ":)") and what MacJi types in its place
//  (→ or 🙂), its Settings group and where in a word it may fire.
//

import Foundation

struct TextAlias: Identifiable, Sendable {
    enum Group: CaseIterable, Identifiable, Sendable {
        case arrows, math, symbols, emoticons
        var id: Self { self }
    }

    /// Where the alias may start.
    enum Boundary: Sendable {
        case anywhere
        /// Only at the start of the typed text or after whitespace, so "note:)" or "::D" never fire.
        case afterSpace

        func allows(_ before: Character?) -> Bool {
            switch self {
            case .anywhere: true
            case .afterSpace: before.map(\.isWhitespace) ?? true
            }
        }
    }

    /// Stored in `disabledTextAliases` when turned off; permanent once released.
    let id: String
    /// Spellings that all become `replacement`, e.g. ":)" and ":-)".
    let texts: [String]
    let replacement: String
    let group: Group
    let boundary: Boundary
}
