//
//  TriggerField.swift
//  MacJi
//
//  Created: 2026-11-27
//  A trigger text field with live validation: a valid draft is saved at once, an invalid one
//  explains why and keeps the last valid trigger.
//

import SwiftUI

struct TriggerField: View {
    let trigger: String
    /// Stores a valid trigger and returns nil, or returns why it was rejected.
    let setTrigger: (String) -> InlineTrigger.Problem?
    var placeholder = SettingsStrings.triggerLabel

    @State private var draft = ""
    @State private var problem: InlineTrigger.Problem?

    ////////////////////
    //// Field and its error
    /// Every edit is validated at once: a valid draft is saved immediately, an invalid one shows
    /// why and keeps the last valid trigger working. Return on an invalid draft restores it.

    var body: some View {
        LabeledContent(SettingsStrings.triggerLabel) {
            TextField(placeholder, text: $draft)
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
        .onAppear { draft = trigger }
        if let problem {
            SettingsHint(text: "\(Self.message(for: problem)) \(SettingsStrings.triggerKeptHint(trigger))",
                         symbol: SymbolNames.error, tint: Palette.error)
        }
    }

    //// The stored trigger only ever holds a valid value.
    //////////////////

    static func message(for problem: InlineTrigger.Problem) -> String {
        switch problem {
        case .empty: SettingsStrings.triggerErrorEmpty
        case .tooLong: SettingsStrings.triggerErrorTooLong(Limits.triggerMaxLength)
        case .whitespace: SettingsStrings.triggerErrorWhitespace
        case .onlyQueryCharacters: SettingsStrings.triggerErrorOnlyLetters
        case .overlaps(let kind, let trigger): SettingsStrings.triggerErrorOverlaps(name(of: kind), trigger: trigger)
        }
    }

    private static func name(of kind: InlinePanelKind) -> String {
        switch kind {
        case .emoji: SettingsStrings.emojiPanelName
        case .symbols: SettingsStrings.symbolPanelName
        case .emoticons: SettingsStrings.emoticonPanelName
        }
    }
}
