//
//  EmojiDataTests.swift
//  MacJiTests
//
//  Created: 2026-11-26
//  Catalog browsing and filtering, ranked search (with use counts) and the recents list.
//  Ported from Octopus: octopusTests/EmojiPickerTests.swift, octopusTests/MacJiTests.swift
//

import Testing
@testable import MacJi

struct EmojiDataTests {
    private let catalog = EmojiCatalog(emojis: [
        Emoji(emoji: "😍", description: "smiling face with heart-eyes", category: "Smileys & Emotion",
              aliases: ["heart_eyes"], tags: ["love", "crush"]),
        Emoji(emoji: "🐶", description: "dog face", category: "Animals & Nature", aliases: ["dog"], tags: ["pet"]),
        Emoji(emoji: "❤️", description: "red heart", category: "Smileys & Emotion", aliases: ["heart"], tags: ["love"]),
        Emoji(emoji: "🆕", description: "future", category: "Unknown Category", aliases: [], tags: []),
    ])

    @Test func emptyQueryGroupsEverythingByCategoryOrder() {
        let sections = catalog.sections()
        #expect(sections.map(\.title) == [EmojiCategory.smileys.rawValue, EmojiCategory.animals.rawValue])
        #expect(sections[0].emojis.map(\.emoji) == ["😍", "❤️"])
    }

    @Test func searchMatchesNameAliasAndTagsWithEveryTerm() {
        #expect(catalog.sections(matching: "PET").flatMap(\.emojis).map(\.emoji) == ["🐶"])
        #expect(catalog.sections(matching: "love heart").flatMap(\.emojis).map(\.emoji) == ["😍", "❤️"])
        #expect(catalog.sections(matching: "love dog").isEmpty)
    }

    @Test func categoryFilterKeepsOnlyThatSection() {
        #expect(catalog.sections(in: .animals).map(\.title) == [EmojiCategory.animals.rawValue])
    }

    @Test func exactAliasThenAliasPrefixThenWordPrefixThenSubstring() {
        let ranked = EmojiCatalog(emojis: [
            Emoji(emoji: "🎸", description: "guitar", category: "Objects", aliases: ["guitar"], tags: ["rock"]),
            Emoji(emoji: "🐊", description: "crocodile", category: "Animals & Nature", aliases: ["crocodile"], tags: []),
            Emoji(emoji: "🚀", description: "rocket", category: "Travel & Places", aliases: ["rocket"], tags: []),
            Emoji(emoji: "🪨", description: "rock", category: "Travel & Places", aliases: ["roc"], tags: []),
        ])
        #expect(EmojiSearch.ranked("roc", in: ranked, limit: 10).map(\.emoji) == ["🪨", "🚀", "🎸", "🐊"])
        #expect(EmojiSearch.ranked("roc", in: ranked, limit: 2).count == 2)
        #expect(EmojiSearch.ranked("roc", in: ranked, category: .objects, limit: 10).map(\.emoji) == ["🎸"])
    }

    @Test func frequentlyUsedPrefixMatchesComeFirstMostUsedFirst() {
        let ranked = EmojiCatalog(emojis: [
            Emoji(emoji: "🎸", description: "guitar", category: "Objects", aliases: ["guitar"], tags: ["rock"]),
            Emoji(emoji: "🐊", description: "crocodile", category: "Animals & Nature", aliases: ["crocodile"], tags: []),
            Emoji(emoji: "🚀", description: "rocket", category: "Travel & Places", aliases: ["rocket"], tags: []),
            Emoji(emoji: "🪨", description: "rock", category: "Travel & Places", aliases: ["roc"], tags: []),
        ])
        let useCounts = ["🎸": 2, "🚀": 5, "🐊": 9]
        #expect(EmojiSearch.ranked("roc", in: ranked, useCounts: useCounts, limit: 10).map(\.emoji) == ["🚀", "🎸", "🪨", "🐊"])
    }

    @Test func recentsMoveToFrontWithoutDuplicatesAndStayCapped() {
        #expect(EmojiRecents.adding("🐶", to: ["😍", "🐶", "❤️"], limit: 2) == ["🐶", "😍"])
        #expect(catalog.emojis(for: ["🆕", "❤️"]).map(\.emoji) == ["❤️"])
    }
}
