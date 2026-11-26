//
//  GlyphDataTests.swift
//  MacJiTests
//
//  Created: 2026-11-26
//  Catalog browsing and filtering, ranked search (with use counts) and the recents list.
//  Ported from Octopus: octopusTests/EmojiPickerTests.swift, octopusTests/MacJiTests.swift
//

import Testing
@testable import MacJi

struct GlyphDataTests {
    private let catalog = EmojiCatalog(glyphs: [
        Glyph(text: "😍", description: "smiling face with heart-eyes", category: "Smileys & Emotion",
              aliases: ["heart_eyes"], tags: ["love", "crush"]),
        Glyph(text: "🐶", description: "dog face", category: "Animals & Nature", aliases: ["dog"], tags: ["pet"]),
        Glyph(text: "❤️", description: "red heart", category: "Smileys & Emotion", aliases: ["heart"], tags: ["love"]),
        Glyph(text: "🆕", description: "future", category: "Unknown Category", aliases: [], tags: []),
    ])

    @Test func emptyQueryGroupsEverythingByCategoryOrder() {
        let sections = catalog.sections()
        #expect(sections.map(\.title) == [EmojiCategory.smileys.rawValue, EmojiCategory.animals.rawValue])
        #expect(sections[0].glyphs.map(\.text) == ["😍", "❤️"])
    }

    @Test func searchMatchesNameAliasAndTagsWithEveryTerm() {
        #expect(catalog.sections(matching: "PET").flatMap(\.glyphs).map(\.text) == ["🐶"])
        #expect(catalog.sections(matching: "love heart").flatMap(\.glyphs).map(\.text) == ["😍", "❤️"])
        #expect(catalog.sections(matching: "love dog").isEmpty)
    }

    @Test func categoryFilterKeepsOnlyThatSection() {
        #expect(catalog.sections(in: .animals).map(\.title) == [EmojiCategory.animals.rawValue])
    }

    @Test func exactAliasThenAliasPrefixThenWordPrefixThenSubstring() {
        let ranked = EmojiCatalog(glyphs: [
            Glyph(text: "🎸", description: "guitar", category: "Objects", aliases: ["guitar"], tags: ["rock"]),
            Glyph(text: "🐊", description: "crocodile", category: "Animals & Nature", aliases: ["crocodile"], tags: []),
            Glyph(text: "🚀", description: "rocket", category: "Travel & Places", aliases: ["rocket"], tags: []),
            Glyph(text: "🪨", description: "rock", category: "Travel & Places", aliases: ["roc"], tags: []),
        ])
        #expect(GlyphSearch.ranked("roc", in: ranked, limit: 10).map(\.text) == ["🪨", "🚀", "🎸", "🐊"])
        #expect(GlyphSearch.ranked("roc", in: ranked, limit: 2).count == 2)
        #expect(GlyphSearch.ranked("roc", in: ranked, category: .objects, limit: 10).map(\.text) == ["🎸"])
    }

    @Test func frequentlyUsedPrefixMatchesComeFirstMostUsedFirst() {
        let ranked = EmojiCatalog(glyphs: [
            Glyph(text: "🎸", description: "guitar", category: "Objects", aliases: ["guitar"], tags: ["rock"]),
            Glyph(text: "🐊", description: "crocodile", category: "Animals & Nature", aliases: ["crocodile"], tags: []),
            Glyph(text: "🚀", description: "rocket", category: "Travel & Places", aliases: ["rocket"], tags: []),
            Glyph(text: "🪨", description: "rock", category: "Travel & Places", aliases: ["roc"], tags: []),
        ])
        let useCounts = ["🎸": 2, "🚀": 5, "🐊": 9]
        #expect(GlyphSearch.ranked("roc", in: ranked, useCounts: useCounts, limit: 10).map(\.text) == ["🚀", "🎸", "🪨", "🐊"])
    }

    @Test func recentsMoveToFrontWithoutDuplicatesAndStayCapped() {
        #expect(GlyphRecents.adding("🐶", to: ["😍", "🐶", "❤️"], limit: 2) == ["🐶", "😍"])
        #expect(catalog.glyphs(for: ["🆕", "❤️"]).map(\.text) == ["❤️"])
    }
}
