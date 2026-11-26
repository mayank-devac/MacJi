//
//  InlinePanelModel.swift
//  MacJi
//
//  Created: 2026-11-26
//  State for the inline panel: which panel is open and what was typed, ranked results, the
//  category filter, keyboard selection, hover, copy feedback and the current presentation.
//  Ported from Octopus: octopus/UI/MacJi/MacJiModel.swift
//

import SwiftUI

@MainActor
final class InlinePanelModel: ObservableObject {
    /// What opened the panel: a trigger and its term, or an emoticon autocomplete run.
    struct Search: Equatable {
        let kind: InlinePanelKind
        /// Shown in the header and deleted on insert: "::roc", "##arr" or "^_".
        let typed: String
        let term: String
        let isAutocomplete: Bool
    }

    @Published private(set) var search: Search?
    @Published private(set) var results: [Glyph] = []
    @Published var symbolCategory: SymbolCategory? { didSet { if symbolCategory != oldValue { refreshResults() } } }
    @Published var emoticonCategory: EmoticonCategory? { didSet { if emoticonCategory != oldValue { refreshResults() } } }
    /// The selected glyph's text; the first result after each new term.
    @Published var selection: String?
    @Published var hovered: Glyph?
    @Published private(set) var lastCopied: Glyph?
    /// Bumped on every copy so copying the same glyph twice re-shows the badge.
    @Published private(set) var copyCount = 0
    /// Bumped on each open so the view replays its appear animation and drops stale feedback.
    @Published private(set) var presentationID = 0
    /// The card corner nearest the caret; the appear animation grows out of it.
    @Published private(set) var growsFrom = UnitPoint.topLeading

    var library = GlyphLibrary.empty
    /// Set on each open; empty while frequency ranking is off.
    private var useCounts: [String: Int] = [:]

    var kind: InlinePanelKind { search?.kind ?? .emoji }

    /// Emoticons are wide, so they list one per row.
    var columnCount: Int { kind == .emoticons ? 1 : PanelMetrics.columnCount }

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
    // Switching panels mid-session (typing another trigger) clears the filter.

    func beginPresentation(growsFrom anchor: UnitPoint, useCounts: [String: Int]) {
        reset()
        growsFrom = anchor
        self.useCounts = useCounts
        presentationID += 1
    }

    func update(_ search: Search) {
        guard search != self.search else { return }
        if search.kind != self.search?.kind {
            symbolCategory = nil
            emoticonCategory = nil
        }
        self.search = search
        refreshResults()
    }

    func reset() {
        search = nil
        symbolCategory = nil
        emoticonCategory = nil
        results = []
        selection = nil
        hovered = nil
        lastCopied = nil
    }

    //// The hosting view stays alive between presentations, so state must be reset explicitly.
    //////////////////

    func cycleFilter(forward: Bool) {
        switch kind {
        case .emoji: break
        case .symbols: symbolCategory = SymbolCategory.cycle(symbolCategory, forward: forward)
        case .emoticons: emoticonCategory = EmoticonCategory.cycle(emoticonCategory, forward: forward)
        }
    }

    func moveSelection(_ key: MenuKey) {
        let rows = GlyphGrid.rows(of: results.map(\.text), columns: columnCount)
        selection = MenuGridNavigator.move(selection, key, in: rows)
    }

    /// Returns false when the clipboard refused the text.
    func copy(_ glyph: Glyph) -> Bool {
        guard GlyphClipboard.copy(glyph) else { return false }
        lastCopied = glyph
        copyCount += 1
        return true
    }

    ////////////////////
    //// Results
    /// Each panel searches its own catalog; the symbol and emoticon panels honour their filter.
    /// Autocomplete lists the emoticons that start with what was typed, used ones first.

    private func refreshResults() {
        guard let search else {
            results = []
            return
        }
        let limit = Limits.inlineResults
        switch search.kind {
        case .emoji:
            results = GlyphSearch.ranked(search.term, in: library.emoji, useCounts: useCounts, limit: limit)
        case .symbols:
            results = GlyphSearch.ranked(search.term, in: library.symbols, category: symbolCategory,
                                         useCounts: useCounts, limit: limit)
        case .emoticons where search.isAutocomplete:
            results = GlyphSearch.starting(with: search.term, in: library.emoticons, category: emoticonCategory,
                                           useCounts: useCounts, limit: limit)
        case .emoticons:
            results = GlyphSearch.ranked(search.term, in: library.emoticons, category: emoticonCategory,
                                         useCounts: useCounts, limit: limit)
        }
        selection = results.first?.text
        hovered = nil
    }

    //////////////////
}
