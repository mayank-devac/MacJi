//
//  EmojiPickerModel.swift
//  MacJi
//
//  Created: 2026-11-26
//  State for the emoji picker: search text, category filter, keyboard selection, hover and
//  copy feedback, and the groups the grid draws (recents, categories or ranked matches).
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
    /// `nil` shows all categories.
    @Published var category: EmojiCategory? { didSet { refreshGroups(selectFirst: true) } }
    @Published var hovered: Glyph?
    @Published var selection: PickerSlot?
    @Published private(set) var groups: [GlyphSection] = []
    @Published private(set) var lastCopied: Glyph?
    /// Bumped on every copy so copying the same emoji twice still re-shows the "Copied" badge.
    @Published private(set) var copyCount = 0
    /// Bumped on each open so the view refocuses the search field and drops stale feedback.
    @Published private(set) var openCount = 0

    private let recents: GlyphRecents
    var catalog = EmojiCatalog.empty { didSet { refreshGroups(selectFirst: false) } }

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

    /// Starts each open fresh: empty search, all categories, nothing selected, recents re-read.
    func prepareForOpen() {
        query = ""
        category = nil
        refreshGroups(selectFirst: true)
        hovered = nil
        lastCopied = nil
        openCount += 1
    }

    ////////////////////
    //// Keyboard actions
    /// Arrows move through the drawn rows, Tab cycles the category filters and Return copies
    // the selection, falling back to the first emoji shown.

    func moveSelection(_ key: MenuKey) {
        selection = MenuGridNavigator.move(selection, key, in: Self.grid(for: groups))
    }

    func cycleCategory(forward: Bool) {
        category = EmojiCategory.cycle(category, forward: forward)
    }

    /// Returns false when there is nothing to copy or the clipboard refused it.
    func copySelection() -> Bool {
        guard let emoji = selectedGlyph ?? groups.first?.glyphs.first else { return false }
        return pick(emoji)
    }

    //// Selection follows search: typing selects the first match for Return.
    //////////////////

    /// Copies the emoji to the clipboard and records it as recently used.
    @discardableResult
    func pick(_ emoji: Glyph) -> Bool {
        guard GlyphClipboard.copy(emoji) else { return false }
        lastCopied = emoji
        copyCount += 1
        recents.record(emoji.text)
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
    /// categories in Unicode order. Searching shows one ranked "Best Matches" group, shared with
    // the inline panel's ranking, so the likeliest emoji is always first and selected.

    private func refreshGroups(selectFirst: Bool) {
        if isSearching {
            let matches = GlyphSearch.ranked(query, in: catalog, category: category, limit: Limits.pickerResults)
            groups = matches.isEmpty ? [] : [GlyphSection(title: PickerStrings.searchResults, glyphs: matches)]
        } else {
            let recentEmojis = category == nil ? catalog.glyphs(for: recents.characters) : []
            let recentGroup = recentEmojis.isEmpty ? [] : [GlyphSection(title: PickerStrings.recentlyUsed, glyphs: recentEmojis)]
            groups = recentGroup + catalog.sections(in: category)
        }
        let slots = Self.grid(for: groups).joined()
        if selectFirst {
            selection = isSearching ? slots.first : nil
        } else if let selection, !slots.contains(selection) {
            self.selection = nil
        }
    }

    //// Browsing starts with nothing selected so the first arrow key picks the first row.
    //////////////////
}
