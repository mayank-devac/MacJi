//
//  EmojiRecents.swift
//  MacJi
//
//  Created: 2026-11-26
//  Recently used emoji, newest first, shared by the inline panel and the picker.
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

    func record(_ emoji: String) {
        defaults.set(Self.adding(emoji, to: characters, limit: limit), forKey: PreferenceKeys.emojiRecents)
    }

    /// Moves `emoji` to the front, removing an older copy and trimming to `limit`.
    nonisolated static func adding(_ emoji: String, to recents: [String], limit: Int) -> [String] {
        Array(([emoji] + recents.filter { $0 != emoji }).prefix(limit))
    }
}
