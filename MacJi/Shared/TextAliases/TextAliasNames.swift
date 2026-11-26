//
//  TextAliasNames.swift
//  MacJi
//
//  Created: 2026-11-27
//  The name an alias is shown and searched by: yours as you named it, a built-in one after its
//  symbol's Unicode name.
//

import Foundation

enum TextAliasNames {
    /// "Check mark" for yours; "Rightwards Arrow" for the built-in `->`.
    static func name(of alias: TextAlias) -> String {
        if let name = alias.name { return name }
        return alias.replacement.unicodeScalars.first?.properties.name?.capitalized ?? alias.id
    }

    /// Spellings, outputs and name, lowercased, for the Aliases page filter.
    static func matches(_ alias: TextAlias, filter: String) -> Bool {
        let filter = filter.trimmingCharacters(in: .whitespaces).lowercased()
        guard !filter.isEmpty else { return true }
        return ([name(of: alias)] + alias.texts + alias.replacements).contains { $0.lowercased().contains(filter) }
    }
}
