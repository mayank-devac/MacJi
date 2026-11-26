//
//  EmojiRecents.swift
//  MacJi
//
//  Created: 2026-11-26
//  Recently used emoji, newest first, and how often each was used; shared by the inline panel
//  and the picker.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerSettings.swift, octopus/UI/EmojiPicker/EmojiPickerModel.swift
//

import Foundation

@MainActor
final class EmojiRecents {
    private let defaults: UserDefaults
    private let limit: Int

    init(defaults: UserDefaults, limit: Int = Limits.recents) {
        self.defaults = defaults
        self.limit = limit
    }

    /// Stored characters, newest first. A missing or wrongly typed value reads as empty.
    var characters: [String] {
        defaults.stringArray(forKey: PreferenceKeys.emojiRecents) ?? []
    }

    /// How often each emoji was inserted or copied. A wrongly typed entry is skipped on its own.
    var useCounts: [String: Int] {
        defaults.dictionary(forKey: PreferenceKeys.emojiUseCounts)?.compactMapValues { $0 as? Int } ?? [:]
    }

    func record(_ emoji: String) {
        defaults.set(Self.adding(emoji, to: characters, limit: limit), forKey: PreferenceKeys.emojiRecents)
        var counts = useCounts
        counts[emoji, default: 0] += 1
        defaults.set(counts, forKey: PreferenceKeys.emojiUseCounts)
    }

    /// Moves `emoji` to the front, removing an older copy and trimming to `limit`.
    nonisolated static func adding(_ emoji: String, to recents: [String], limit: Int) -> [String] {
        Array(([emoji] + recents.filter { $0 != emoji }).prefix(limit))
    }
}
