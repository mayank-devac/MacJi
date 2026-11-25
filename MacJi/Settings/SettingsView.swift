//
//  SettingsView.swift
//  MacJi
//
//  Created: 2026-11-26
//  The single Settings page: a grouped Form with one section per area.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: PermissionStatus
    let loginItem: LoginItem
    let updates: UpdateController
    let onGrantAccess: () -> Void

    var body: some View {
        Form {
            PermissionSection(accessibilityGranted: permissions.accessibilityGranted,
                              secureInputHolder: permissions.secureInputHolder,
                              onGrantAccess: onGrantAccess)
            EmojiPickerSection()
            InlinePanelSection(isEnabled: $settings.inlinePanelEnabled, trigger: settings.trigger,
                               setTrigger: settings.setTrigger)
            MenuBarSection(isShown: $settings.showMenuBarIcon)
            GeneralSection(loginItem: loginItem, updates: updates)
            AboutSection()
        }
        .formStyle(.grouped)
        .frame(minWidth: SettingsMetrics.width, maxWidth: SettingsMetrics.width)
    }
}
