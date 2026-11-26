//
//  InlinePanelKeys.swift
//  MacJi
//
//  Created: 2026-11-26
//  Maps raw key presses from the event tap to typed-buffer input and, while the panel is
//  open, to panel actions that are kept from the app.
//  Ported from Octopus: octopus/UI/MacJi/MacJiKeys.swift
//

import AppKit
import Carbon.HIToolbox

/// Panel actions; these keys are consumed instead of reaching the app.
enum InlinePanelKeyAction: Equatable {
    case move(MenuKey)
    /// Return: replace "::term" with the selected emoji.
    case insert
    /// Shift-Return: copy the selected emoji and leave the text as typed.
    case copy
    /// Esc: close and leave the text as typed.
    case close
    /// Tab / Shift-Tab: next or previous category, in the panels that have filters.
    case nextFilter, previousFilter

    init?(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, hasFilters: Bool = false) {
        let modifiers = modifiers.intersection([.command, .option, .control, .shift])
        if Int(keyCode) == kVK_Tab {
            guard hasFilters, modifiers.isSubset(of: .shift) else { return nil }
            self = modifiers.contains(.shift) ? .previousFilter : .nextFilter
            return
        }
        guard let key = MenuKey(keyCode: keyCode) else { return nil }
        switch key {
        case .up, .down, .left, .right:
            guard modifiers.isEmpty else { return nil }
            self = .move(key)
        case .confirm:
            if modifiers.isEmpty { self = .insert }
            else if modifiers == .shift { self = .copy }
            else { return nil }
        case .cancel:
            self = .close
        }
    }
}

extension TypedKey {
    /// Command/Control shortcuts, navigation keys and Option-Delete can move the caret or edit
    /// text out of view, so they reset the buffer.
    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, characters: String) {
        let modifiers = modifiers.intersection([.command, .option, .control])
        if !modifiers.isDisjoint(with: [.command, .control]) {
            self = .reset
        } else if Int(keyCode) == kVK_Delete {
            self = modifiers.isEmpty ? .deleteBackward : .reset
        } else if !characters.isEmpty,
                  !characters.unicodeScalars.contains(where: { $0.properties.generalCategory == .control }) {
            self = .text(characters)
        } else {
            self = .reset
        }
    }
}
