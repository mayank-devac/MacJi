//
//  InlinePanelConfiguration.swift
//  MacJi
//
//  Created: 2026-11-27
//  The inline panel settings the composition root forwards: enabled triggers, ranking and
//  emoticon autocomplete.
//

import Foundation

struct InlinePanelConfiguration: Equatable {
    /// Triggers of the panels that are on; a panel that is off, or a blank trigger, is left out.
    var triggers: [InlinePanelKind: String] = [:]
    var ranksFrequentlyUsed = PreferenceDefaults.rankFrequentlyUsedEmoji
    /// Characters before emoticon suggestions open; 0 is off (also when emoticons are off).
    var emoticonAutocompleteLength = 0

    /// Anything that needs the event tap besides text aliases.
    var watchesTyping: Bool { !triggers.isEmpty || emoticonAutocompleteLength > 0 }

    init() {}

    /// Drops the triggers of panels that are off; emoticons off also turns autocomplete off.
    init(emojiEnabled: Bool, symbolsEnabled: Bool, emoticonsEnabled: Bool, triggers: [InlinePanelKind: String],
         emoticonAutocompleteLength: Int, ranksFrequentlyUsed: Bool) {
        let enabled: [InlinePanelKind: Bool] = [.emoji: emojiEnabled, .symbols: symbolsEnabled, .emoticons: emoticonsEnabled]
        self.triggers = triggers.filter { kind, trigger in !trigger.isEmpty && enabled[kind] == true }
        self.emoticonAutocompleteLength = emoticonsEnabled ? emoticonAutocompleteLength : 0
        self.ranksFrequentlyUsed = ranksFrequentlyUsed
    }
}
