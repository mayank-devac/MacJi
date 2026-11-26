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
    @Published private(set) var results: [Glyph] = []
    /// The selected emoji character; the first result after each new term.
    @Published var selection: String?
    @Published var hovered: Glyph?
    @Published private(set) var lastCopied: Glyph?
    /// Bumped on every copy so copying the same emoji twice re-shows the badge.
    @Published private(set) var copyCount = 0
    /// Bumped on each open so the view replays its appear animation and drops stale feedback.
    @Published private(set) var presentationID = 0
    /// The card corner nearest the caret; the appear animation grows out of it.
    @Published private(set) var growsFrom = UnitPoint.topLeading

    var catalog = EmojiCatalog.empty
    /// Set on each open; empty while frequency ranking is off.
    private var useCounts: [String: Int] = [:]

    var selectedGlyph: Glyph? {
        results.first { $0.text == selection }
    }

    /// The pointer wins over the keyboard so the shown name matches what is under it.
    var focusedGlyph: Glyph? {
        hovered ?? selectedGlyph
    }

    /// What Return and Shift-Return act on: the selection, else the first result.
    var chosenGlyph: Glyph? {
        selectedGlyph ?? results.first
    }

    ////////////////////
    //// Session lifecycle
    /// A presentation starts empty; `update` fills it. `reset` runs once the panel has faded out.

    func beginPresentation(growsFrom anchor: UnitPoint, useCounts: [String: Int]) {
        reset()
        growsFrom = anchor
        self.useCounts = useCounts
        presentationID += 1
    }

    func update(query: String, trigger: String) {
        self.trigger = trigger
        guard query != self.query else { return }
        self.query = query
        results = GlyphSearch.ranked(query, in: catalog, useCounts: useCounts, limit: Limits.inlineResults)
        selection = results.first?.text
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
        let rows = GlyphGrid.rows(of: results.map(\.text), columns: PanelMetrics.columnCount)
        selection = MenuGridNavigator.move(selection, key, in: rows)
    }

    /// Returns false when the clipboard refused the text.
    func copy(_ emoji: Glyph) -> Bool {
        guard GlyphClipboard.copy(emoji) else { return false }
        lastCopied = emoji
        copyCount += 1
        return true
    }
}
