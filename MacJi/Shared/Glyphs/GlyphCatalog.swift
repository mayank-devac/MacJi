//
//  GlyphCatalog.swift
//  MacJi
//
//  Created: 2026-11-26
//  Loads one bundled glyph data file once and indexes it for search and lookup.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiCatalog.swift
//

import Foundation

typealias EmojiCatalog = GlyphCatalog<EmojiCategory>

struct GlyphCatalog<Category: GlyphCategory>: Sendable {
    ////////////////////
    //// Index entry
    /// Everything search needs is lowercased and split once, at load time, so a keystroke
    /// only compares strings that already exist.

    struct Entry: Sendable {
        let glyph: Glyph
        let category: Category
        /// Name, aliases and tags joined: every search term must appear somewhere in here.
        let keywords: String
        let aliases: [String]
        /// Words of the name and tags, for word-prefix ranking.
        let words: [Substring]
    }

    //////////////////

    let entries: [Entry]
    private let byText: [String: Glyph]

    static var empty: GlyphCatalog { GlyphCatalog(glyphs: []) }

    /// Records with an unknown category (a newer data release) are skipped.
    init(glyphs: [Glyph]) {
        entries = glyphs.compactMap { glyph in
            guard let category = Category(rawValue: glyph.category) else { return nil }
            let aliases = glyph.aliases.map { $0.lowercased() }
            let keywords = ([glyph.description] + aliases + glyph.tags).joined(separator: " ").lowercased()
            let words = ([glyph.description] + glyph.tags).joined(separator: " ").lowercased()
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            return Entry(glyph: glyph, category: category, keywords: keywords, aliases: aliases, words: words)
        }
        byText = Dictionary(entries.map { ($0.glyph.text, $0.glyph) }, uniquingKeysWith: { first, _ in first })
    }

    ////////////////////
    //// Loading
    /// Decoding a data file takes tens of milliseconds, so it runs off the main thread once
    /// at launch; features show an empty grid for that moment instead of blocking the first keys.

    static func loadBundled(_ resource: String) async -> GlyphCatalog {
        await Task.detached(priority: .userInitiated) { load(resource, from: .main) }.value
    }

    static func load(_ resource: String, from bundle: Bundle) -> GlyphCatalog {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            Log.emojiData.error("\(resource, privacy: .public).json is missing from the bundle")
            return .empty
        }
        do {
            let glyphs = try JSONDecoder().decode([Glyph].self, from: Data(contentsOf: url))
            return GlyphCatalog(glyphs: glyphs)
        } catch {
            Log.emojiData.error("\(resource, privacy: .public).json could not be read: \(error.localizedDescription, privacy: .public)")
            return .empty
        }
    }

    //// An unreadable resource yields an empty catalog (and a log line), never a crash.
    //////////////////

    ////////////////////
    //// Browse and lookup
    /// An empty query returns every section, so the picker can browse the full set.
    // Results keep catalog order and are grouped into non-empty category sections.

    func sections(matching query: String = "", in filter: Category? = nil) -> [GlyphSection] {
        let terms = GlyphSearch.terms(in: query)
        let matched = entries.filter { ($0.category == filter || filter == nil) && GlyphSearch.matches($0, terms) }
        return Category.allCases.compactMap { category in
            let glyphs = matched.filter { $0.category == category }.map(\.glyph)
            return glyphs.isEmpty ? nil : GlyphSection(title: category.title, glyphs: glyphs)
        }
    }

    /// Resolves stored texts (e.g. recents), dropping ones no longer in the catalog.
    func glyphs(for texts: [String]) -> [Glyph] {
        texts.compactMap { byText[$0] }
    }

    //////////////////
}
