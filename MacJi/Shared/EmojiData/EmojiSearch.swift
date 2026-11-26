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
    /// With `useCounts`, used emoji whose name or alias starts with the term come first, most used first.
    // One pass fills a bucket per rank in catalog order, so ties keep Unicode order without a sort.

    static func ranked(_ query: String, in catalog: EmojiCatalog, category: EmojiCategory? = nil,
                       useCounts: [String: Int] = [:], limit: Int) -> [Emoji] {
        let queryTerms = terms(in: query)
        guard !queryTerms.isEmpty else { return [] }
        var buckets = Array(repeating: [Emoji](), count: Rank.allCases.count)
        var used: [(emoji: Emoji, count: Int, rank: Int)] = []
        for entry in catalog.entries where (category == nil || entry.category == category) && matches(entry, queryTerms) {
            let weakest = queryTerms.map { rank(entry, $0).rawValue }.max() ?? Rank.substring.rawValue
            if weakest < Rank.substring.rawValue, let count = useCounts[entry.emoji.emoji], count > 0 {
                used.append((entry.emoji, count, weakest))
            } else {
                buckets[weakest].append(entry.emoji)
            }
        }
        return Array((mostUsedFirst(used) + buckets.joined()).prefix(limit))
    }

    //// Capped so a one-letter term stays fast to draw.
    //////////////////

    /// Equal counts keep the better match first, then catalog order.
    private static func mostUsedFirst(_ used: [(emoji: Emoji, count: Int, rank: Int)]) -> [Emoji] {
        used.enumerated().sorted { a, b in
            if a.element.count != b.element.count { return a.element.count > b.element.count }
            if a.element.rank != b.element.rank { return a.element.rank < b.element.rank }
            return a.offset < b.offset
        }.map(\.element.emoji)
    }

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
