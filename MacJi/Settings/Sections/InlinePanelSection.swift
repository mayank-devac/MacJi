//
//  InlinePanelSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  The inline panel's on/off toggle and the trigger field with live validation.
//

import SwiftUI

struct InlinePanelSection: View {
    @Binding var isEnabled: Bool
    let trigger: String
    /// Stores a valid trigger and returns nil, or returns why it was rejected.
    let setTrigger: (String) -> InlineTrigger.Problem?

    @State private var draft = ""
    @State private var problem: InlineTrigger.Problem?

    var body: some View {
        Section {
            Toggle(isOn: $isEnabled) {
                Text(SettingsStrings.inlineToggle)
                Text(SettingsStrings.inlineExample(trigger: trigger))
            }
            triggerField
                .disabled(!isEnabled)
            if let problem {
                SettingsHint(text: "\(message(for: problem)) \(SettingsStrings.triggerKeptHint(trigger))",
                             symbol: SymbolNames.error, tint: Palette.error)
            }
        } header: {
            Text(SettingsStrings.inlineHeader)
        } footer: {
            if !isEnabled { Text(SettingsStrings.inlineOffFooter).foregroundStyle(.secondary) }
        }
        .animation(PanelMotion.settingsReveal, value: problem)
        .onAppear { draft = trigger }
    }

    ////////////////////
    //// Trigger field
    /// Every edit is validated at once: a valid draft is saved immediately, an invalid one shows
    /// why and keeps the last valid trigger working. Return on an invalid draft restores it.

    private var triggerField: some View {
        LabeledContent(SettingsStrings.triggerLabel) {
            TextField(SettingsStrings.triggerLabel, text: $draft)
                .textFieldStyle(.roundedBorder)
                .labelsHidden()
                .font(.body.monospaced())
                .multilineTextAlignment(.center)
                .frame(width: SettingsMetrics.triggerFieldWidth)
                .onChange(of: draft) { problem = setTrigger(draft) }
                .onSubmit {
                    guard problem != nil else { return }
                    draft = trigger
                }
        }
    }

    //// The stored trigger only ever holds a valid value.
    //////////////////

    private func message(for problem: InlineTrigger.Problem) -> String {
        switch problem {
        case .empty: SettingsStrings.triggerErrorEmpty
        case .tooLong: SettingsStrings.triggerErrorTooLong(Limits.triggerMaxLength)
        case .whitespace: SettingsStrings.triggerErrorWhitespace
        case .onlyQueryCharacters: SettingsStrings.triggerErrorOnlyLetters
        }
    }
}
