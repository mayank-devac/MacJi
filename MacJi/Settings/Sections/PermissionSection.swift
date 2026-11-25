//
//  PermissionSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  Accessibility status with a Grant Access button, and a Secure Input warning when an app
//  is blocking keyboard access. Both update live from PermissionStatus.
//

import SwiftUI

struct PermissionSection: View {
    let accessibilityGranted: Bool
    let secureInputHolder: SecureInputHolder?
    let onGrantAccess: () -> Void

    var body: some View {
        Section {
            if accessibilityGranted {
                SettingsStatusRow(symbol: SymbolNames.granted, tint: Palette.granted,
                                  title: SettingsStrings.accessibilityTitle, detail: SettingsStrings.accessibilityGranted)
            } else {
                SettingsStatusRow(symbol: SymbolNames.attention, tint: Palette.attention,
                                  title: SettingsStrings.accessibilityTitle, detail: SettingsStrings.accessibilityMissing,
                                  actionTitle: SettingsStrings.grantAccess, action: onGrantAccess)
            }
            if let holder = secureInputHolder {
                SettingsStatusRow(symbol: SymbolNames.lock, tint: Palette.attention, title: SettingsStrings.secureInputTitle,
                                  detail: "\(PermissionStrings.blocking(holder.name)) \(holder.turnOffSteps)")
            }
        }
        .animation(PanelMotion.settingsReveal, value: accessibilityGranted)
        .animation(PanelMotion.settingsReveal, value: secureInputHolder)
    }
}
