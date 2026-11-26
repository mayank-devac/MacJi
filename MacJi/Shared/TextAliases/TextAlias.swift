//
//  TextAlias.swift
//  MacJi
//
//  Created: 2026-11-26
//  One text alias: what you type (e.g. "->" or ":)"), what MacJi types in its place (→ or 🙂)
//  and any further outputs search shows, its group, where in a word it may fire and, for your
//  own aliases, the name search finds it by.
//

import Foundation

struct TextAlias: Identifiable, Equatable, Sendable {
    /// Raw values are stored with your own aliases; never rename one.
    enum Group: String, CaseIterable, Identifiable, Sendable {
        case arrows, math, symbols, emoticons, emoji
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
    /// Never empty. The first is typed in place of a spelling; search shows them all.
    let replacements: [String]
    let group: Group
    let boundary: Boundary
    /// Your own aliases' search name ("Check mark"); nil for built-in ones, which take their symbol's name.
    let name: String?

    var replacement: String { replacements.first ?? "" }
    var isCustom: Bool { name != nil }

    /// A built-in alias: one output, named after it.
    init(id: String, texts: [String], replacement: String, group: Group, boundary: Boundary) {
        self.init(id: id, texts: texts, replacements: [replacement], group: group, boundary: boundary, name: nil)
    }

    init(id: String, texts: [String], replacements: [String], group: Group, boundary: Boundary, name: String?) {
        self.id = id
        self.texts = texts
        self.replacements = replacements
        self.group = group
        self.boundary = boundary
        self.name = name
    }
}
