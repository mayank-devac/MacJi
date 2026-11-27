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
    /// Recently used glyphs kept, shared by emoji, symbols and emoticons.
    static let recents = 72
    /// Recently used glyphs one picker tab shows.
    static let recentsShown = 24
    /// Longest typed run emoticon autocomplete follows.
    static let emoticonRunMaxLength = 16
    /// Lengths the Settings `− +` stepper offers for emoticon autocomplete (below the lowest is Off).
    static let emoticonAutocompleteLengths = 2...6
    /// Your own aliases: name, spelling and output lengths, and how many of each.
    static let aliasNameMaxLength = 40
    static let aliasSpellingLengths = 2...16
    static let aliasOutputMaxLength = 64
    static let aliasMaxSpellings = 8
    static let aliasMaxOutputs = 8
    static let customAliasesMax = 200
    /// Your alias outputs listed first in a panel or the picker's search.
    static let aliasResults = 8
    /// UTF-16 units one synthetic key event can carry; CGEvent drops anything longer.
    static let syntheticKeyUTF16Units = 20
    /// Longest Send Feedback message; keeps the mailto and issue URLs short enough to open.
    static let feedbackMaxLength = 2000
    /// Tallest AX rect still treated as one line of text; taller means a field or paragraph.
    static let maxCaretHeight: CGFloat = 64
}
