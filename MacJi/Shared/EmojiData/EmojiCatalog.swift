//
//  EmojiCatalog.swift
//  MacJi
//
//  Created: 2026-11-26
//  Loads the bundled emoji data once and indexes it for search and lookup.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiCatalog.swift
//

import Foundation

struct EmojiCatalog: Sendable {
    ////////////////////
    //// Index entry
    /// Everything search needs is lowercased and split once, at load time, so a keystroke
    /// only compares strings that already exist.

    struct Entry: Sendable {
        let emoji: Emoji
        let category: EmojiCategory
        /// Name, aliases and tags joined: every search term must appear somewhere in here.
        let keywords: String
        let aliases: [String]
        /// Words of the name and tags, for word-prefix ranking.
        let words: [Substring]
    }

    //////////////////

    let entries: [Entry]
    private let byCharacter: [String: Emoji]

    static let empty = EmojiCatalog(emojis: [])

    /// Records with an unknown category (a newer gemoji release) are skipped.
    init(emojis: [Emoji]) {
        entries = emojis.compactMap { emoji in
            guard let category = EmojiCategory(rawValue: emoji.category) else { return nil }
            let aliases = emoji.aliases.map { $0.lowercased() }
            let keywords = ([emoji.description] + aliases + emoji.tags).joined(separator: " ").lowercased()
            let words = ([emoji.description] + emoji.tags).joined(separator: " ").lowercased()
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            return Entry(emoji: emoji, category: category, keywords: keywords, aliases: aliases, words: words)
        }
        byCharacter = Dictionary(entries.map { ($0.emoji.emoji, $0.emoji) }, uniquingKeysWith: { first, _ in first })
    }

    ////////////////////
    //// Loading
    /// Decoding ~200 KB of JSON takes tens of milliseconds, so it runs off the main thread once
    /// at launch; features show an empty grid for that moment instead of blocking the first keys.

    static func loadBundled() async -> EmojiCatalog {
        await Task.detached(priority: .userInitiated) { load(from: .main) }.value
    }

    static func load(from bundle: Bundle) -> EmojiCatalog {
        guard let url = bundle.url(forResource: "emoji", withExtension: "json") else {
            Log.emojiData.error("emoji.json is missing from the bundle")
            return .empty
        }
        do {
            let emojis = try JSONDecoder().decode([Emoji].self, from: Data(contentsOf: url))
            return EmojiCatalog(emojis: emojis)
        } catch {
            Log.emojiData.error("emoji.json could not be read: \(error.localizedDescription, privacy: .public)")
            return .empty
        }
    }

    //// An unreadable resource yields an empty catalog (and a log line), never a crash.
    //////////////////

    ////////////////////
    //// Browse and lookup
    /// An empty query returns every section, so the picker can browse the full set.
    // Results keep catalog order and are grouped into non-empty category sections.

    func sections(matching query: String = "", in filter: EmojiCategory? = nil) -> [EmojiSection] {
        let terms = EmojiSearch.terms(in: query)
        let matched = entries.filter { ($0.category == filter || filter == nil) && EmojiSearch.matches($0, terms) }
        return EmojiCategory.allCases.compactMap { category in
            let emojis = matched.filter { $0.category == category }.map(\.emoji)
            return emojis.isEmpty ? nil : EmojiSection(title: category.rawValue, emojis: emojis)
        }
    }

    /// Resolves stored characters (e.g. recents), dropping ones no longer in the catalog.
    func emojis(for characters: [String]) -> [Emoji] {
        characters.compactMap { byCharacter[$0] }
    }

    //////////////////
}
