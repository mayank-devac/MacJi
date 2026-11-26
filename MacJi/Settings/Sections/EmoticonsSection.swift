//
//  EmoticonsSection.swift
//  MacJi
//
//  Created: 2026-11-27
//  The Emoticons switch, the autocomplete length stepper (with Off) and the optional emoticon
//  trigger.
//

import SwiftUI

struct EmoticonsSection: View {
    @Binding var isEnabled: Bool
    /// 0 is off, else within `Limits.emoticonAutocompleteLengths`.
    @Binding var autocompleteLength: Int
    let trigger: String
    let setTrigger: (String) -> InlineTrigger.Problem?

    var body: some View {
        Section {
            Toggle(isOn: $isEnabled) {
                Text(SettingsStrings.emoticonsToggle)
                Text(SettingsStrings.emoticonsExample)
            }
            Group {
                autocompleteStepper
                TriggerField(trigger: trigger, setTrigger: setTrigger,
                             placeholder: SettingsStrings.emoticonTriggerPlaceholder)
                SettingsHint(text: SettingsStrings.emoticonTriggerHint)
            }
            .disabled(!isEnabled)
        } header: {
            Text(SettingsStrings.emoticonsHeader)
        }
    }

    ////////////////////
    //// Autocomplete length
    /// − from the shortest length turns autocomplete off; + from off starts at the shortest.

    private var autocompleteStepper: some View {
        let lengths = Limits.emoticonAutocompleteLengths
        return LabeledContent(SettingsStrings.autocompleteLabel) {
            Stepper {
                Text(autocompleteLength == 0 ? SettingsStrings.autocompleteOff
                                             : SettingsStrings.autocompleteAfter(autocompleteLength))
                    .monospacedDigit()
            } onIncrement: {
                autocompleteLength = autocompleteLength == 0 ? lengths.lowerBound : min(autocompleteLength + 1, lengths.upperBound)
            } onDecrement: {
                autocompleteLength = autocompleteLength <= lengths.lowerBound ? 0 : autocompleteLength - 1
            }
        }
    }

    //////////////////
}
