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

/// One grid cell. The group is part of the identity because a recent emoji also appears in
/// its own category.
struct EmojiSlot: Hashable {
    let group: String
    let emoji: String
}

@MainActor
final class EmojiPickerModel: ObservableObject {
    @Published var query = "" { didSet { refreshGroups(selectFirst: true) } }
    /// `nil` shows all categories.
    @Published var category: EmojiCategory? { didSet { refreshGroups(selectFirst: true) } }
    @Published var hovered: Emoji?
    @Published var selection: EmojiSlot?
    @Published private(set) var groups: [EmojiSection] = []
    @Published private(set) var lastCopied: Emoji?
    /// Bumped on every copy so copying the same emoji twice still re-shows the "Copied" badge.
    @Published private(set) var copyCount = 0
    /// Bumped on each open so the view refocuses the search field and drops stale feedback.
    @Published private(set) var openCount = 0

    private let recents: EmojiRecents
    var catalog = EmojiCatalog.empty { didSet { refreshGroups(selectFirst: false) } }

    init(recents: EmojiRecents) {
        self.recents = recents
    }

    var isSearching: Bool { !query.allSatisfy(\.isWhitespace) }

    var selectedEmoji: Emoji? {
        guard let selection else { return nil }
        return groups.first { $0.title == selection.group }?.emojis.first { $0.emoji == selection.emoji }
    }

    /// The pointer wins over the keyboard so the footer names what is under it.
    var focusedEmoji: Emoji? { hovered ?? selectedEmoji }

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
        let filters: [EmojiCategory?] = [nil] + EmojiCategory.allCases
        let index = filters.firstIndex(of: category) ?? 0
        category = filters[(index + (forward ? 1 : filters.count - 1)) % filters.count]
    }

    /// Returns false when there is nothing to copy or the clipboard refused it.
    func copySelection() -> Bool {
        guard let emoji = selectedEmoji ?? groups.first?.emojis.first else { return false }
        return pick(emoji)
    }

    //// Selection follows search: typing selects the first match for Return.
    //////////////////

    /// Copies the emoji to the clipboard and records it as recently used.
    @discardableResult
    func pick(_ emoji: Emoji) -> Bool {
        guard EmojiClipboard.copy(emoji) else { return false }
        lastCopied = emoji
        copyCount += 1
        recents.record(emoji.emoji)
        refreshGroups(selectFirst: false)
        return true
    }

    /// Splits each group into rows of `columns`; groups never share a row.
    nonisolated static func grid(for groups: [EmojiSection], columns: Int = PickerMetrics.columnCount) -> [[EmojiSlot]] {
        groups.flatMap { group in
            EmojiGrid.rows(of: group.emojis.map { EmojiSlot(group: group.title, emoji: $0.emoji) }, columns: columns)
        }
    }

    ////////////////////
    //// Groups
    /// Browsing shows "Recently Used" (all categories only, like the system picker) and then the
    /// categories in Unicode order. Searching shows one ranked "Best Matches" group, shared with
    // the inline panel's ranking, so the likeliest emoji is always first and selected.

    private func refreshGroups(selectFirst: Bool) {
        if isSearching {
            let matches = EmojiSearch.ranked(query, in: catalog, category: category, limit: Limits.pickerResults)
            groups = matches.isEmpty ? [] : [EmojiSection(title: PickerStrings.searchResults, emojis: matches)]
        } else {
            let recentEmojis = category == nil ? catalog.emojis(for: recents.characters) : []
            let recentGroup = recentEmojis.isEmpty ? [] : [EmojiSection(title: PickerStrings.recentlyUsed, emojis: recentEmojis)]
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
