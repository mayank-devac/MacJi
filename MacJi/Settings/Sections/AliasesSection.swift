//
//  AliasesSection.swift
//  MacJi
//
//  Created: 2026-11-27
//  The Aliases switch and Customize…, and a note when nothing watches the keyboard.
//

import SwiftUI

struct AliasesSection: View {
    @Binding var convertsTextAliases: Bool
    /// How many of your own aliases there are, shown under the switch.
    let customCount: Int
    /// Shows the note that nothing watches the keyboard.
    let everythingTypedIsOff: Bool
    let onCustomize: () -> Void

    var body: some View {
        Section {
            LabeledContent {
                HStack {
                    Button(SettingsStrings.customizeAliases, action: onCustomize)
                    Toggle(SettingsStrings.aliasesToggle, isOn: $convertsTextAliases)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            } label: {
                Text(SettingsStrings.aliasesToggle)
                Text(customCount == 0 ? SettingsStrings.aliasesExample
                                      : AliasStrings.example(SettingsStrings.aliasesExample, yours: customCount))
            }
        } header: {
            Text(SettingsStrings.aliasesHeader)
        } footer: {
            if everythingTypedIsOff { Text(SettingsStrings.allTypingOffFooter).foregroundStyle(.secondary) }
        }
    }
}
