//
//  Glyph.swift
//  MacJi
//
//  Created: 2026-11-26
//  One pickable glyph (an emoji, a symbol or an emoticon) and a titled section of glyphs.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiCatalog.swift
//

import Foundation

/// One record, decoded straight from a bundled data file. Every file uses gemoji's field names.
struct Glyph: Decodable, Hashable, Identifiable, Sendable {
    /// What MacJi inserts or copies: "🚀", "→" or "¯\_(ツ)_/¯".
    let text: String
    let description: String
    let category: String
    let aliases: [String]
    let tags: [String]

    var id: String { text }

    /// Name as shown in footers and tooltips ("Grinning Face").
    var displayName: String { description.capitalized }

    private enum CodingKeys: String, CodingKey {
        case text = "emoji", description, category, aliases, tags
    }
}

/// A titled block of glyphs: a category, "Recently Used" or search results.
struct GlyphSection: Identifiable, Sendable {
    let title: String
    let glyphs: [Glyph]

    var id: String { title }
}
