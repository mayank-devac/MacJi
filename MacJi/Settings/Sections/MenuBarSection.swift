//
//  MenuBarSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  Show or hide the menu-bar icon, with the way back in when it is hidden.
//

import SwiftUI

struct MenuBarSection: View {
    @Binding var isShown: Bool

    var body: some View {
        Section {
            Toggle(SettingsStrings.showMenuBarIcon, isOn: $isShown)
            if !isShown {
                SettingsHint(text: SettingsStrings.hiddenIconHint, symbol: SymbolNames.attention, tint: Palette.attention)
            }
        } header: {
            Text(SettingsStrings.menuBarHeader)
        } footer: {
            if isShown { Text(SettingsStrings.menuBarFooter).foregroundStyle(.secondary) }
        }
        .animation(PanelMotion.settingsReveal, value: isShown)
    }
}
