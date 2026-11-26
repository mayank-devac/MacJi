//
//  EmojiPickerKeys.swift
//  MacJi
//
//  Created: 2026-11-26
//  Maps key presses in the picker popover to picker actions. Anything not listed (letters,
//  Delete, Command shortcuts) goes to the search field, so typing searches straight away.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerKeys.swift
//

import AppKit
import Carbon.HIToolbox

enum EmojiPickerKeyAction: Equatable {
    case move(MenuKey)
    case nextCategory, previousCategory
    /// Copy the selection; `keepOpen` is Option-Return.
    case copy(keepOpen: Bool)
    /// Clears the search first, then closes on a second press.
    case cancel
    /// ⌘1, ⌘2, ⌘3: the nth visible tab (0-based).
    case selectTab(Int)

    private static let tabKeys = [kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3]

    init?(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        let modifiers = modifiers.intersection([.command, .option, .control, .shift])
        if modifiers == .command, let index = Self.tabKeys.firstIndex(of: Int(keyCode)) {
            self = .selectTab(index)
            return
        }
        if Int(keyCode) == kVK_Tab {
            guard modifiers.isSubset(of: .shift) else { return nil }
            self = modifiers.contains(.shift) ? .previousCategory : .nextCategory
            return
        }
        guard let key = MenuKey(keyCode: keyCode) else { return nil }
        switch key {
        // Modified arrows (e.g. Option-Left) keep editing the search text.
        case .up, .down, .left, .right:
            guard modifiers.isEmpty else { return nil }
            self = .move(key)
        case .confirm:
            guard modifiers.isSubset(of: .option) else { return nil }
            self = .copy(keepOpen: modifiers.contains(.option))
        case .cancel:
            self = .cancel
        }
    }
}
