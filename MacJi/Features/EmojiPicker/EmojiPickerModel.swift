//
//  EmojiPickerModel.swift
//  MacJi
//
//  Created: 2026-11-26
//  State for the picker: the tab (emoji, symbols, emoticons), search text, the tab's category
//  filter, keyboard selection, hover and copy feedback, and the groups the grid draws.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerModel.swift
//

import AppKit

/// One grid cell. The group is part of the identity because a recent glyph also appears in
/// its own category.
struct PickerSlot: Hashable {
    let group: String
    let text: String
}

@MainActor
final class EmojiPickerModel: ObservableObject {
    @Published var query = "" { didSet { refreshGroups(selectFirst: true) } }
    @Published var tab = PickerTab.emoji {
        didSet {
            guard tab != oldValue else { return }
            refreshGroups(selectFirst: true)
            onTabChanged(tab)
        }
    }
    /// `nil` shows all categories. Each tab keeps its own filter.
    @Published var emojiCategory: EmojiCategory? { didSet { refreshGroups(selectFirst: true) } }
    @Published var symbolCategory: SymbolCategory? { didSet { refreshGroups(selectFirst: true) } }
    @Published var emoticonCategory: EmoticonCategory? { didSet { refreshGroups(selectFirst: true) } }
    @Published var hovered: Glyph?
    @Published var selection: PickerSlot?
    @Published private(set) var groups: [GlyphSection] = []
    @Published private(set) var lastCopied: Glyph?
    /// Bumped on every copy so copying the same glyph twice still re-shows the "Copied" badge.
    @Published private(set) var copyCount = 0
    /// Bumped on each open so the view refocuses the search field and drops stale feedback.
    @Published private(set) var openCount = 0
    /// Tabs turned on in Settings; the tab bar hides when only Emoji is left.
    @Published private(set) var visibleTabs: [PickerTab] = [.emoji]

    /// Reported so the composition root can remember the last tab.
    var onTabChanged: (PickerTab) -> Void = { _ in }
    private let recents: GlyphRecents
    var library = GlyphLibrary.empty { didSet { refreshGroups(selectFirst: false) } }
    /// Your aliases' outputs, listed first in search results; empty while that is off.
    var aliases = AliasCatalog.empty { didSet { refreshGroups(selectFirst: false) } }

    init(recents: GlyphRecents) {
        self.recents = recents
    }

    var isSearching: Bool { !query.allSatisfy(\.isWhitespace) }

    var selectedGlyph: Glyph? {
        guard let selection else { return nil }
        return groups.first { $0.title == selection.group }?.glyphs.first { $0.text == selection.text }
    }

    /// The pointer wins over the keyboard so the footer names what is under it.
    var focusedGlyph: Glyph? { hovered ?? selectedGlyph }

    /// "Type [x]" when the focused glyph is one of your alias outputs.
    var focusedSpelling: String? {
        focusedGlyph.flatMap { AliasGlyphs.spelling(of: $0, in: aliases) }
    }

    /// A hidden tab falls back to Emoji.
    func setVisibleTabs(_ tabs: [PickerTab]) {
        visibleTabs = tabs
        if !tabs.contains(tab) { tab = .emoji }
    }

    /// Starts each open fresh: empty search, all categories, nothing selected, recents re-read.
    func prepareForOpen() {
        query = ""
        emojiCategory = nil
        symbolCategory = nil
        emoticonCategory = nil
        refreshGroups(selectFirst: true)
        hovered = nil
        lastCopied = nil
        openCount += 1
    }

    ////////////////////
    //// Keyboard actions
    /// Arrows move through the drawn rows, Tab cycles the tab's category filters, ⌘1–3 pick a
    // tab and Return copies the selection, falling back to the first glyph shown.

    func moveSelection(_ key: MenuKey) {
        selection = MenuGridNavigator.move(selection, key, in: Self.grid(for: groups, columns: tab.columnCount))
    }

    func cycleCategory(forward: Bool) {
        switch tab {
        case .emoji: emojiCategory = EmojiCategory.cycle(emojiCategory, forward: forward)
        case .symbols: symbolCategory = SymbolCategory.cycle(symbolCategory, forward: forward)
        case .emoticons: emoticonCategory = EmoticonCategory.cycle(emoticonCategory, forward: forward)
        }
    }

    /// The nth visible tab (0-based); out of range is ignored.
    func selectTab(at index: Int) {
        guard visibleTabs.indices.contains(index) else { return }
        tab = visibleTabs[index]
    }

    /// Returns false when there is nothing to copy or the clipboard refused it.
    func copySelection() -> Bool {
        guard let glyph = selectedGlyph ?? groups.first?.glyphs.first else { return false }
        return pick(glyph)
    }

    //// Selection follows search: typing selects the first match for Return.
    //////////////////

    /// Copies the glyph to the clipboard and records it as recently used.
    @discardableResult
    func pick(_ glyph: Glyph) -> Bool {
        guard GlyphClipboard.copy(glyph) else { return false }
        lastCopied = glyph
        copyCount += 1
        recents.record(glyph.text)
        refreshGroups(selectFirst: false)
        return true
    }

    /// Splits each group into rows of `columns`; groups never share a row.
    nonisolated static func grid(for groups: [GlyphSection], columns: Int = PickerMetrics.columnCount) -> [[PickerSlot]] {
        groups.flatMap { group in
            GlyphGrid.rows(of: group.glyphs.map { PickerSlot(group: group.title, text: $0.text) }, columns: columns)
        }
    }

    ////////////////////
    //// Groups
    /// Browsing shows "Recently Used" (all categories only, like the system picker) and then the
    /// tab's categories. Searching shows one ranked "Best Matches" group, shared with the inline
    // panel's ranking, so the likeliest glyph is always first and selected; your matching alias
    // outputs come before it in every tab. Recents are shared across tabs; each tab shows its own.

    private func refreshGroups(selectFirst: Bool) {
        switch tab {
        case .emoji: groups = groups(in: library.emoji, category: emojiCategory)
        case .symbols: groups = groups(in: library.symbols, category: symbolCategory)
        case .emoticons: groups = groups(in: library.emoticons, category: emoticonCategory)
        }
        let slots = Self.grid(for: groups, columns: tab.columnCount).joined()
        if selectFirst {
            selection = isSearching ? slots.first : nil
        } else if let selection, !slots.contains(selection) {
            self.selection = nil
        }
    }

    private func groups<Category>(in catalog: GlyphCatalog<Category>, category: Category?) -> [GlyphSection] {
        if isSearching {
            let mine = category == nil ? GlyphSearch.ranked(query, in: aliases, limit: Limits.aliasResults) : []
            let listed = Set(mine.map(\.text))
            let matches = GlyphSearch.ranked(query, in: catalog, category: category, limit: Limits.pickerResults)
                .filter { !listed.contains($0.text) }
            return [GlyphSection(title: PickerStrings.yourAliases, glyphs: mine),
                    GlyphSection(title: PickerStrings.searchResults, glyphs: matches)].filter { !$0.glyphs.isEmpty }
        }
        let recentGlyphs = category == nil ? Array(catalog.glyphs(for: recents.characters).prefix(Limits.recentsShown)) : []
        let recentGroup = recentGlyphs.isEmpty ? [] : [GlyphSection(title: PickerStrings.recentlyUsed, glyphs: recentGlyphs)]
        return recentGroup + catalog.sections(in: category)
    }

    //// Browsing starts with nothing selected so the first arrow key picks the first row.
    //////////////////
}
