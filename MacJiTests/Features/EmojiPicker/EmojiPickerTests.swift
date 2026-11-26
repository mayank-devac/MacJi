//
//  EmojiPickerTests.swift
//  MacJiTests
//
//  Created: 2026-11-26
//  Picker grid rows, key mapping and the ranked search group.
//  Ported from Octopus: octopusTests/EmojiPickerTests.swift
//

import Foundation
import Testing
@testable import MacJi

struct EmojiPickerTests {
    private let catalog = EmojiCatalog(glyphs: [
        Glyph(text: "😍", description: "smiling face with heart-eyes", category: "Smileys & Emotion",
              aliases: ["heart_eyes"], tags: ["love"]),
        Glyph(text: "❤️", description: "red heart", category: "Smileys & Emotion", aliases: ["heart"], tags: ["love"]),
        Glyph(text: "🐶", description: "dog face", category: "Animals & Nature", aliases: ["dog"], tags: ["pet"]),
    ])

    @Test func gridRowsMatchColumnsAndNeverMixGroups() {
        let groups = catalog.sections()
        #expect(EmojiPickerModel.grid(for: groups, columns: 1).map { $0.map(\.text) } == [["😍"], ["❤️"], ["🐶"]])
        #expect(EmojiPickerModel.grid(for: groups, columns: 9).map(\.count) == [2, 1])
    }

    @Test func keysMapToPickerActionsAndLeaveTypingToSearch() {
        #expect(EmojiPickerKeyAction(keyCode: 125, modifiers: []) == .move(.down))
        #expect(EmojiPickerKeyAction(keyCode: 123, modifiers: .option) == nil)
        #expect(EmojiPickerKeyAction(keyCode: 36, modifiers: []) == .copy(keepOpen: false))
        #expect(EmojiPickerKeyAction(keyCode: 36, modifiers: .option) == .copy(keepOpen: true))
        #expect(EmojiPickerKeyAction(keyCode: 48, modifiers: .shift) == .previousCategory)
        #expect(EmojiPickerKeyAction(keyCode: 53, modifiers: []) == .cancel)
        #expect(EmojiPickerKeyAction(keyCode: 0, modifiers: []) == nil)
        #expect(EmojiPickerKeyAction(keyCode: 19, modifiers: .command) == .selectTab(1))
        #expect(EmojiPickerKeyAction(keyCode: 19, modifiers: []) == nil)
    }

    @MainActor
    @Test func eachTabShowsOnlyItsOwnRecentsAndHiddenTabsFallBack() throws {
        let defaults = try #require(UserDefaults(suiteName: "macji.tests.picker.\(UUID().uuidString)"))
        let recents = GlyphRecents(defaults: defaults)
        recents.record("❤️")
        recents.record("→")
        let symbols = SymbolCatalog(glyphs: [
            Glyph(text: "→", description: "rightwards arrow", category: SymbolCategory.arrows.rawValue, aliases: ["rarr"], tags: []),
        ])
        let model = EmojiPickerModel(recents: recents)
        model.library = GlyphLibrary(emoji: catalog, symbols: symbols, emoticons: .empty)
        model.setVisibleTabs([.emoji, .symbols])
        model.prepareForOpen()
        #expect(model.groups.first?.glyphs.map(\.text) == ["❤️"])
        model.selectTab(at: 1)
        #expect(model.tab == .symbols)
        #expect(model.groups.first?.glyphs.map(\.text) == ["→"])
        model.selectTab(at: 2)
        #expect(model.tab == .symbols)
        model.setVisibleTabs([.emoji])
        #expect(model.tab == .emoji)
    }

    @MainActor
    @Test func searchShowsOneRankedGroupWithTheBestMatchSelected() throws {
        let defaults = try #require(UserDefaults(suiteName: "macji.tests.picker.\(UUID().uuidString)"))
        let model = EmojiPickerModel(recents: GlyphRecents(defaults: defaults))
        model.library = GlyphLibrary(emoji: catalog, symbols: .empty, emoticons: .empty)
        model.query = "heart"
        #expect(model.groups.map(\.title) == [PickerStrings.searchResults])
        #expect(model.groups.first?.glyphs.map(\.text) == ["❤️", "😍"])
        #expect(model.selectedGlyph?.text == "❤️")
        model.aliases = AliasGlyphs.catalog(from: [
            TextAlias(id: "custom-1", texts: ["<3<3"], replacements: ["💕", "❤️"], group: .emoji, boundary: .afterSpace, name: "Heart pair"),
        ])
        #expect(model.groups.map(\.title) == [PickerStrings.yourAliases, PickerStrings.searchResults])
        #expect(model.groups.map { $0.glyphs.map(\.text) } == [["💕", "❤️"], ["😍"]])
    }
}
