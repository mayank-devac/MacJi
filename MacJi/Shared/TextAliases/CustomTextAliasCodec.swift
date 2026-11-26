//
//  CustomTextAliasCodec.swift
//  MacJi
//
//  Created: 2026-11-27
//  Your own text aliases to and from the plist array stored in UserDefaults; unreadable
//  entries are kept, not dropped.
//

import Foundation

enum CustomTextAliasCodec {
    /// IDs of your own aliases start with this, so they never clash with a built-in ID.
    static let idPrefix = "custom-"

    static func newID() -> String {
        idPrefix + UUID().uuidString
    }

    ////////////////////
    //// Reading
    /// Each alias is a dictionary in a plist array. An entry that can't be read (a wrong type,
    /// an empty field, or a group from a newer MacJi) is skipped but returned as `unreadable`,
    // so saving writes it back untouched and a value written by a newer MacJi survives.

    static func decode(_ stored: Any?) -> (aliases: [TextAlias], unreadable: [Any]) {
        guard let entries = stored as? [Any] else { return ([], []) }
        var aliases: [TextAlias] = []
        var unreadable: [Any] = []
        for entry in entries {
            if let alias = alias(from: entry) { aliases.append(alias) } else { unreadable.append(entry) }
        }
        return (aliases, unreadable)
    }

    private static func alias(from entry: Any) -> TextAlias? {
        guard let fields = entry as? [String: Any],
              let id = fields[CustomAliasKeys.id] as? String, id.hasPrefix(idPrefix),
              let name = fields[CustomAliasKeys.name] as? String, !name.isEmpty,
              let groupName = fields[CustomAliasKeys.group] as? String, let group = TextAlias.Group(rawValue: groupName),
              let texts = fields[CustomAliasKeys.texts] as? [String], !texts.isEmpty,
              let replacements = fields[CustomAliasKeys.replacements] as? [String], !replacements.isEmpty,
              let wordStartOnly = fields[CustomAliasKeys.wordStartOnly] as? Bool else { return nil }
        return TextAlias(id: id, texts: texts, replacements: replacements, group: group,
                         boundary: wordStartOnly ? .afterSpace : .anywhere, name: name)
    }

    //// Missing or wrongly typed storage reads as no aliases; nothing is deleted.
    //////////////////

    static func encode(_ aliases: [TextAlias], keeping unreadable: [Any]) -> [Any] {
        aliases.map { alias -> Any in
            [
                CustomAliasKeys.id: alias.id,
                CustomAliasKeys.name: alias.name ?? "",
                CustomAliasKeys.group: alias.group.rawValue,
                CustomAliasKeys.texts: alias.texts,
                CustomAliasKeys.replacements: alias.replacements,
                CustomAliasKeys.wordStartOnly: alias.boundary == .afterSpace,
            ] as [String: Any]
        } + unreadable
    }
}
