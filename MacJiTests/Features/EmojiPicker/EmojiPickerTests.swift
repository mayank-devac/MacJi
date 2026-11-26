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
    }

    @MainActor
    @Test func searchShowsOneRankedGroupWithTheBestMatchSelected() throws {
        let defaults = try #require(UserDefaults(suiteName: "macji.tests.picker.\(UUID().uuidString)"))
        let model = EmojiPickerModel(recents: GlyphRecents(defaults: defaults))
        model.catalog = catalog
        model.query = "heart"
        #expect(model.groups.map(\.title) == [PickerStrings.searchResults])
        #expect(model.groups.first?.glyphs.map(\.text) == ["❤️", "😍"])
        #expect(model.selectedGlyph?.text == "❤️")
    }
}
