//
//  GeneralSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  Open at login, automatic update checks and Check Now with the last check time.
//

import SwiftUI

struct GeneralSection: View {
    @ObservedObject var loginItem: LoginItem
    @ObservedObject var updates: UpdateController

    var body: some View {
        Section {
            Toggle(SettingsStrings.openAtLogin, isOn: Binding(get: { loginItem.isEnabled }, set: loginItem.setEnabled))
            if loginItem.needsApproval {
                HStack {
                    SettingsHint(text: SettingsStrings.loginNeedsApproval, symbol: SymbolNames.attention, tint: Palette.attention)
                    Spacer()
                    Button(SettingsStrings.openLoginItems, action: loginItem.openSystemSettings)
                }
            }
            if let error = loginItem.errorMessage {
                SettingsHint(text: error, symbol: SymbolNames.error, tint: Palette.error)
            }
            Toggle(SettingsStrings.automaticUpdates,
                   isOn: Binding(get: { updates.automaticallyChecks }, set: updates.setAutomaticallyChecks))
            LabeledContent {
                Button(SettingsStrings.checkNow, action: updates.checkForUpdates)
                    .disabled(!updates.canCheckForUpdates)
            } label: {
                Text(lastCheckedText).foregroundStyle(.secondary)
            }
        } header: {
            Text(SettingsStrings.generalHeader)
        }
        .animation(PanelMotion.settingsReveal, value: loginItem.errorMessage)
    }

    private var lastCheckedText: String {
        guard let date = updates.lastCheckDate else { return SettingsStrings.neverChecked }
        return SettingsStrings.lastChecked(date.formatted(.relative(presentation: .named)))
    }
}
