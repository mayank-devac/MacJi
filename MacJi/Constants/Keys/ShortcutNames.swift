//
//  ShortcutNames.swift
//  MacJi
//
//  Created: 2026-11-26
//  Global keyboard shortcut names and their defaults.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerController.swift
//

import KeyboardShortcuts

////////////////////
//// Picker shortcut
/// The name string is permanent: KeyboardShortcuts stores the recorded shortcut under it.
/// Default ⌃⌥⌘Space is the system emoji viewer's ⌃⌘Space plus Option, so it is easy to remember
// and is not one of macOS's own symbolic hotkeys (⌃Space, ⌃⌥Space, ⌘Space, ⇧⌘Space are).

extension KeyboardShortcuts.Name {
    static let showEmojiPicker = Self("showEmojiPicker", default: .init(.space, modifiers: [.control, .option, .command]))
}

//// Settings → Emoji Picker → Reset restores this default.
//////////////////
