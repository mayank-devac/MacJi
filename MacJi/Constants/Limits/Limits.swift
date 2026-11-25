//
//  Limits.swift
//  MacJi
//
//  Created: 2026-11-26
//  Caps on typed text, results and stored lists.
//  Ported from Octopus: octopus/UI/MacJi/MacJiTriggerTracker.swift, octopus/UI/MacJi/MacJiSearch.swift, octopus/UI/MacJi/MacJiSettings.swift, octopus/UI/EmojiPicker/EmojiPickerSettings.swift
//

import CoreGraphics

enum Limits {
    /// Long triggers are hard to type and gain nothing.
    static let triggerMaxLength = 4
    /// Longest search term the inline panel follows after the trigger.
    static let queryMaxLength = 32
    /// Inline panel results; keeps a one-letter term fast to draw.
    static let inlineResults = 64
    /// Picker search results (browsing shows every emoji).
    static let pickerResults = 180
    static let recents = 24
    /// Tallest AX rect still treated as one line of text; taller means a field or paragraph.
    static let maxCaretHeight: CGFloat = 64
}
