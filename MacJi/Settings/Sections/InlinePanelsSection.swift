//
//  InlinePanelsSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  The emoji and symbol panels' switches and triggers, and the frequency-ranking switch that
//  applies to every inline panel.
//

import SwiftUI

struct InlinePanelsSection: View {
    @Binding var emojiEnabled: Bool
    @Binding var symbolsEnabled: Bool
    let trigger: (InlinePanelKind) -> String
    /// Stores a valid trigger and returns nil, or returns why it was rejected.
    let setTrigger: (String, InlinePanelKind) -> InlineTrigger.Problem?
    @Binding var ranksFrequentlyUsed: Bool
    /// Ranking also orders emoticon suggestions, so it stays on while those are.
    let emoticonsEnabled: Bool

    var body: some View {
        Section {
            Toggle(isOn: $emojiEnabled) {
                Text(SettingsStrings.inlineToggle)
                Text(SettingsStrings.inlineExample(trigger: trigger(.emoji)))
            }
            TriggerField(trigger: trigger(.emoji), setTrigger: { setTrigger($0, .emoji) })
                .disabled(!emojiEnabled)
            Toggle(isOn: $symbolsEnabled) {
                Text(SettingsStrings.symbolToggle)
                Text(SettingsStrings.symbolExample(trigger: trigger(.symbols)))
            }
            TriggerField(trigger: trigger(.symbols), setTrigger: { setTrigger($0, .symbols) })
                .disabled(!symbolsEnabled)
            Toggle(SettingsStrings.rankFrequentlyUsed, isOn: $ranksFrequentlyUsed)
                .disabled(!emojiEnabled && !symbolsEnabled && !emoticonsEnabled)
        } header: {
            Text(SettingsStrings.inlineHeader)
        }
        .animation(PanelMotion.settingsReveal, value: emojiEnabled)
    }
}
