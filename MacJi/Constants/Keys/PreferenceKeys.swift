//
//  PreferenceKeys.swift
//  MacJi
//
//  Created: 2026-11-26
//  Every UserDefaults key MacJi stores, and the defaults registered for them at launch.
//  Ported from Octopus: octopus/UI/MacJi/MacJiSettings.swift, octopus/UI/EmojiPicker/EmojiPickerSettings.swift
//

import Foundation

////////////////////
//// Stored keys
/// Key names are permanent once a release has shipped: renaming one silently drops every
/// user's saved value. Reshape or rename through a migration in `SettingsMigrator`.
// Sparkle stores its own `SU*` keys and KeyboardShortcuts stores `KeyboardShortcuts_<name>`.

enum PreferenceKeys {
    /// Bool: the inline panel listens for the trigger.
    static let inlinePanelEnabled = "inlinePanelEnabled"
    /// String: the characters that open the inline panel, validated by `InlineTrigger`.
    static let inlinePanelTrigger = "inlinePanelTrigger"
    /// Bool: the inline panel lists the user's most-used matching emoji first.
    static let rankFrequentlyUsedEmoji = "rankFrequentlyUsedEmoji"
    /// Bool: typed text aliases ("->", ":)") are replaced with their symbol or emoji.
    static let convertTextAliases = "convertTextAliases"
    /// [String]: IDs of the text aliases the user turned off; aliases added later start on.
    static let disabledTextAliases = "disabledTextAliases"
    /// Bool: the emoji icon is shown in the menu bar.
    static let showMenuBarIcon = "showMenuBarIcon"
    /// [String]: recently used emoji characters, newest first.
    static let emojiRecents = "emojiRecents"
    /// [String: Int]: how often each emoji character was inserted or copied.
    static let emojiUseCounts = "emojiUseCounts"
    /// Int: how many `SettingsMigrator` migrations have run.
    static let settingsSchemaVersion = "settingsSchemaVersion"
    /// Bool: set after the first launch has shown Settings once.
    static let hasCompletedFirstLaunch = "hasCompletedFirstLaunch"
    /// AppKit autosave name for the Settings window frame.
    static let settingsWindowAutosave = "SettingsWindow"
    /// AppKit autosave name for the status item's position.
    static let statusItemAutosave = "MacJiStatusItem"
}

//// Keys are plain strings on purpose: they are what is written to disk.
//////////////////

////////////////////
//// Registered defaults
/// Registered (never written) at launch, so a stored user value always wins.

enum PreferenceDefaults {
    static let inlinePanelEnabled = true
    static let trigger = "::"
    static let showMenuBarIcon = true
    static let rankFrequentlyUsedEmoji = true
    static let convertTextAliases = true

    static var registered: [String: Any] {
        [
            PreferenceKeys.inlinePanelEnabled: inlinePanelEnabled,
            PreferenceKeys.inlinePanelTrigger: trigger,
            PreferenceKeys.rankFrequentlyUsedEmoji: rankFrequentlyUsedEmoji,
            PreferenceKeys.convertTextAliases: convertTextAliases,
            PreferenceKeys.showMenuBarIcon: showMenuBarIcon,
        ]
    }
}

//// Recents, use counts and disabled aliases default to empty and need no registration.
//////////////////
