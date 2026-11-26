//
//  SettingsView.swift
//  MacJi
//
//  Created: 2026-11-26
//  The Settings page: a grouped Form with one section per area, and the Aliases page that
//  slides in over it.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var permissions: PermissionStatus
    let loginItem: LoginItem
    let updates: UpdateController
    let onGrantAccess: () -> Void
    let onQuit: () -> Void

    @State private var showsAliases = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    ////////////////////
    //// Sliding between pages
    /// Both pages stay alive side by side, so going back keeps the main page's scroll position.
    // The page off screen is disabled so Tab never lands on a control you cannot see.

    var body: some View {
        ZStack {
            mainPage
                .offset(x: showsAliases ? -SettingsMetrics.width : 0)
                .disabled(showsAliases)
                .accessibilityHidden(showsAliases)
            TextAliasesPage(aliases: TextAliasCatalog.all, disabled: $settings.disabledTextAliases,
                            onBack: { showsAliases = false })
                .offset(x: showsAliases ? 0 : SettingsMetrics.width)
                .disabled(!showsAliases)
                .accessibilityHidden(!showsAliases)
        }
        .clipped()
        .animation(reduceMotion ? nil : PanelMotion.settingsSlide, value: showsAliases)
        .frame(minWidth: SettingsMetrics.width, maxWidth: SettingsMetrics.width)
    }

    //////////////////

    private var mainPage: some View {
        Form {
            PermissionSection(accessibilityGranted: permissions.accessibilityGranted,
                              secureInputHolder: permissions.secureInputHolder,
                              onGrantAccess: onGrantAccess)
            EmojiPickerSection()
            InlinePanelSection(isEnabled: $settings.inlinePanelEnabled, trigger: settings.trigger,
                               setTrigger: settings.setTrigger,
                               ranksFrequentlyUsed: $settings.rankFrequentlyUsedEmoji,
                               convertsTextAliases: $settings.convertTextAliases,
                               onCustomizeAliases: { showsAliases = true })
            MenuBarSection(isShown: $settings.showMenuBarIcon)
            GeneralSection(loginItem: loginItem, updates: updates)
            AboutSection()
            QuitSection(onQuit: onQuit)
        }
        .formStyle(.grouped)
    }
}
