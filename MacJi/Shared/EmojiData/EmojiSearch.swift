//
//  EmojiSearch.swift
//  MacJi
//
//  Created: 2026-11-26
//  Ranked emoji search shared by the inline panel and the picker: the likeliest emoji comes
//  first, so "roc" puts 🚀 rocket before 🎸 (tagged "rock").
//  Ported from Octopus: octopus/UI/MacJi/MacJiSearch.swift, octopus/UI/EmojiPicker/EmojiCatalog.swift
//

import Foundation

enum EmojiSearch {
    /// How well an entry matches one term; lower is better.
    private enum Rank: Int, CaseIterable {
        case exactAlias, aliasPrefix, wordPrefix, substring
    }

    ////////////////////
    //// Ranked results
    /// 0 exact alias · 1 alias prefix · 2 word prefix in name or tags · 3 anywhere.
    /// With several terms an entry ranks by its weakest term. Every term must match somewhere.
    // One pass fills a bucket per rank in catalog order, so ties keep Unicode order without a sort.

    static func ranked(_ query: String, in catalog: EmojiCatalog, category: EmojiCategory? = nil, limit: Int) -> [Emoji] {
        let terms = terms(in: query)
        guard !terms.isEmpty else { return [] }
        var buckets = Array(repeating: [Emoji](), count: Rank.allCases.count)
        for entry in catalog.entries where (category == nil || entry.category == category) && matches(entry, terms) {
            let rank = terms.map { rank(entry, $0).rawValue }.max() ?? Rank.substring.rawValue
            buckets[rank].append(entry.emoji)
        }
        return Array(buckets.joined().prefix(limit))
    }

    //// Capped so a one-letter term stays fast to draw.
    //////////////////

    static func terms(in query: String) -> [String] {
        query.lowercased().split(whereSeparator: \.isWhitespace).map(String.init)
    }

    static func matches(_ entry: EmojiCatalog.Entry, _ terms: [String]) -> Bool {
        terms.allSatisfy(entry.keywords.contains)
    }

    private static func rank(_ entry: EmojiCatalog.Entry, _ term: String) -> Rank {
        if entry.aliases.contains(term) { return .exactAlias }
        if entry.aliases.contains(where: { $0.hasPrefix(term) }) { return .aliasPrefix }
        return entry.words.contains(where: { $0.hasPrefix(term) }) ? .wordPrefix : .substring
    }
}
