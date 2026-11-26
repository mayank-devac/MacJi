//
//  LoginItemSection.swift
//  MacJi
//
//  Created: 2026-11-27
//  The Open at login switch, right under Accessibility, with its approval and error hints.
//

import SwiftUI

struct LoginItemSection: View {
    @ObservedObject var loginItem: LoginItem

    var body: some View {
        Section {
            Toggle(SettingsStrings.openAtLogin, isOn: Binding(get: { loginItem.isEnabled }, set: { loginItem.setEnabled($0) }))
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
        }
        .animation(PanelMotion.settingsReveal, value: loginItem.errorMessage)
    }
}
