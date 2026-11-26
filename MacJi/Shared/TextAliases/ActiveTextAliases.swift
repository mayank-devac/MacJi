//
//  ActiveTextAliases.swift
//  MacJi
//
//  Created: 2026-11-27
//  The aliases that convert: built-in and your own, minus the ones turned off; yours win over
//  a built-in with the same spelling.
//

import Foundation

enum ActiveTextAliases {
    ////////////////////
    //// What converts
    /// Yours first, then the built-in ones, without those turned off. A built-in spelling one of
    /// yours also uses is dropped from the built-in alias, so yours always wins; a built-in left
    // with no spelling is dropped. Turning yours off brings the built-in spelling back.

    static func make(builtIn: [TextAlias], custom: [TextAlias], disabled: Set<String>) -> [TextAlias] {
        let mine = custom.filter { !disabled.contains($0.id) }
        let taken = Set(mine.flatMap(\.texts))
        let builtIns = builtIn.filter { !disabled.contains($0.id) }.compactMap { alias -> TextAlias? in
            let texts = alias.texts.filter { !taken.contains($0) }
            guard !texts.isEmpty else { return nil }
            return TextAlias(id: alias.id, texts: texts, replacements: alias.replacements, group: alias.group,
                             boundary: alias.boundary, name: alias.name)
        }
        return mine + builtIns
    }

    /// The built-in alias a spelling would replace, for the editor's hint.
    static func builtIn(using text: String, in builtIn: [TextAlias] = TextAliasCatalog.all) -> TextAlias? {
        builtIn.first { $0.texts.contains(text) }
    }

    //////////////////
}
