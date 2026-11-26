//
//  AliasGlyphs.swift
//  MacJi
//
//  Created: 2026-11-27
//  Your aliases as a searchable glyph catalog: every output, found by the alias name, its
//  spellings and group.
//

import Foundation

typealias AliasCatalog = GlyphCatalog<TextAlias.Group>

/// Lets alias outputs share the catalog, ranking and recents every panel already uses.
extension TextAlias.Group: GlyphCategory {
    var title: String { AliasStrings.title(of: self) }

    var symbol: String {
        switch self {
        case .arrows: "arrow.right"
        case .math: "plus.forwardslash.minus"
        case .symbols: "c.circle"
        case .emoticons: "face.smiling"
        case .emoji: "heart"
        }
    }
}

enum AliasGlyphs {
    ////////////////////
    //// Building the catalog
    /// Each output becomes a glyph named after its alias, tagged with the spellings, so "check"
    /// finds ✓ ✔ ☑ and, in the picker, "[x]" does too. Only the typed (first) output carries the
    /// spellings as its aliases, which is what the "Type [x]" hint reads.
    // An output two aliases share appears once, for the first alias.

    static func catalog(from aliases: [TextAlias]) -> AliasCatalog {
        var seen = Set<String>()
        var glyphs: [Glyph] = []
        for alias in aliases {
            for output in alias.replacements where seen.insert(output).inserted {
                glyphs.append(Glyph(text: output, description: TextAliasNames.name(of: alias), category: alias.group.rawValue,
                                    aliases: output == alias.replacement ? alias.texts : [], tags: alias.texts))
            }
        }
        return AliasCatalog(glyphs: glyphs)
    }

    //////////////////

    /// Alias matches first, then the panel's own results without the ones already listed.
    static func merge(_ aliases: [Glyph], before results: [Glyph]) -> [Glyph] {
        let listed = Set(aliases.map(\.text))
        return aliases + results.filter { !listed.contains($0.text) }
    }

    /// The first spelling that types `glyph`, for the "Type [x]" hint; nil when no spelling types it.
    static func spelling(of glyph: Glyph, in catalog: AliasCatalog) -> String? {
        catalog.entries.first { $0.glyph.text == glyph.text }?.glyph.aliases.first
    }
}
