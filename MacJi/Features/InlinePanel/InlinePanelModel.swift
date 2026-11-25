//
//  InlinePanelModel.swift
//  MacJi
//
//  Created: 2026-11-26
//  State for the inline panel: the typed term, ranked results, keyboard selection, hover,
//  copy feedback and the current presentation.
//  Ported from Octopus: octopus/UI/MacJi/MacJiModel.swift
//

import SwiftUI

@MainActor
final class InlinePanelModel: ObservableObject {
    @Published private(set) var trigger = PreferenceDefaults.trigger
    @Published private(set) var query = ""
    @Published private(set) var results: [Emoji] = []
    /// The selected emoji character; the first result after each new term.
    @Published var selection: String?
    @Published var hovered: Emoji?
    @Published private(set) var lastCopied: Emoji?
    /// Bumped on every copy so copying the same emoji twice re-shows the badge.
    @Published private(set) var copyCount = 0
    /// Bumped on each open so the view replays its appear animation and drops stale feedback.
    @Published private(set) var presentationID = 0
    /// The card corner nearest the caret; the appear animation grows out of it.
    @Published private(set) var growsFrom = UnitPoint.topLeading

    var catalog = EmojiCatalog.empty

    var selectedEmoji: Emoji? {
        results.first { $0.emoji == selection }
    }

    /// The pointer wins over the keyboard so the shown name matches what is under it.
    var focusedEmoji: Emoji? {
        hovered ?? selectedEmoji
    }

    /// What Return and Shift-Return act on: the selection, else the first result.
    var chosenEmoji: Emoji? {
        selectedEmoji ?? results.first
    }

    ////////////////////
    //// Session lifecycle
    /// A presentation starts empty; `update` fills it. `reset` runs once the panel has faded out.

    func beginPresentation(growsFrom anchor: UnitPoint) {
        reset()
        growsFrom = anchor
        presentationID += 1
    }

    func update(query: String, trigger: String) {
        self.trigger = trigger
        guard query != self.query else { return }
        self.query = query
        results = EmojiSearch.ranked(query, in: catalog, limit: Limits.inlineResults)
        selection = results.first?.emoji
        hovered = nil
    }

    func reset() {
        query = ""
        results = []
        selection = nil
        hovered = nil
        lastCopied = nil
    }

    //// The hosting view stays alive between presentations, so state must be reset explicitly.
    //////////////////

    func moveSelection(_ key: MenuKey) {
        let rows = EmojiGrid.rows(of: results.map(\.emoji), columns: PanelMetrics.columnCount)
        selection = MenuGridNavigator.move(selection, key, in: rows)
    }

    /// Returns false when the clipboard refused the text.
    func copy(_ emoji: Emoji) -> Bool {
        guard EmojiClipboard.copy(emoji) else { return false }
        lastCopied = emoji
        copyCount += 1
        return true
    }
}
