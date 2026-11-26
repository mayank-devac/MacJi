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
    /// Bool: the symbol panel listens for its trigger.
    static let symbolPanelEnabled = "symbolPanelEnabled"
    /// String: the characters that open the symbol panel, validated by `InlineTrigger`.
    static let symbolPanelTrigger = "symbolPanelTrigger"
    /// Bool: emoticon autocomplete and the emoticon trigger work.
    static let emoticonsEnabled = "emoticonsEnabled"
    /// Int: typed characters before emoticon suggestions open; 0 is off.
    static let emoticonAutocompleteLength = "emoticonAutocompleteLength"
    /// String: the characters that open the emoticon panel by name; blank is none.
    static let emoticonPanelTrigger = "emoticonPanelTrigger"
    /// Bool: the inline panels list the user's most-used matching glyphs first.
    static let rankFrequentlyUsedEmoji = "rankFrequentlyUsedEmoji"
    /// Bool: typed text aliases ("->", ":)") are replaced with their symbol or emoji.
    static let convertTextAliases = "convertTextAliases"
    /// [String]: IDs of the text aliases the user turned off; aliases added later start on.
    static let disabledTextAliases = "disabledTextAliases"
    /// [[String: Any]]: the user's own aliases (fields in `CustomAliasKeys`), in Settings order.
    static let customTextAliases = "customTextAliases"
    /// Bool: the picker shows a Symbols tab.
    static let pickerShowsSymbols = "pickerShowsSymbols"
    /// Bool: the picker shows an Emoticons tab.
    static let pickerShowsEmoticons = "pickerShowsEmoticons"
    /// String: the picker tab used last (`PickerTab` raw value), reopened next time.
    static let pickerLastTab = "pickerLastTab"
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

/// Fields of each dictionary in `customTextAliases`; permanent like the keys above.
enum CustomAliasKeys {
    static let id = "id"
    static let name = "name"
    static let group = "group"
    static let texts = "texts"
    static let replacements = "replacements"
    static let wordStartOnly = "wordStartOnly"
}

//// Keys are plain strings on purpose: they are what is written to disk.
//////////////////

////////////////////
//// Registered defaults
/// Registered (never written) at launch, so a stored user value always wins.

enum PreferenceDefaults {
    static let inlinePanelEnabled = true
    static let trigger = "::"
    static let symbolTrigger = "##"
    /// Blank: emoticons open by autocomplete until the user sets a trigger.
    static let emoticonTrigger = ""
    static let showMenuBarIcon = true
    static let rankFrequentlyUsedEmoji = true
    static let convertTextAliases = true
    static let symbolPanelEnabled = true
    static let emoticonsEnabled = true
    static let emoticonAutocompleteLength = 2
    static let pickerShowsSymbols = true
    static let pickerShowsEmoticons = true

    static var registered: [String: Any] {
        [
            PreferenceKeys.inlinePanelEnabled: inlinePanelEnabled,
            PreferenceKeys.inlinePanelTrigger: trigger,
            PreferenceKeys.symbolPanelEnabled: symbolPanelEnabled,
            PreferenceKeys.symbolPanelTrigger: symbolTrigger,
            PreferenceKeys.emoticonsEnabled: emoticonsEnabled,
            PreferenceKeys.emoticonAutocompleteLength: emoticonAutocompleteLength,
            PreferenceKeys.emoticonPanelTrigger: emoticonTrigger,
            PreferenceKeys.pickerShowsSymbols: pickerShowsSymbols,
            PreferenceKeys.pickerShowsEmoticons: pickerShowsEmoticons,
            PreferenceKeys.rankFrequentlyUsedEmoji: rankFrequentlyUsedEmoji,
            PreferenceKeys.convertTextAliases: convertTextAliases,
            PreferenceKeys.showMenuBarIcon: showMenuBarIcon,
        ]
    }
}

//// Recents, use counts, disabled aliases and the last picker tab (Emoji) need no registration.
//////////////////
