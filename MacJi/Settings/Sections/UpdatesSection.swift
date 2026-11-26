//
//  UpdatesSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  Automatic update checks and Check Now with the last check time.
//

import SwiftUI

struct UpdatesSection: View {
    @ObservedObject var updates: UpdateController

    var body: some View {
        Section {
            Toggle(SettingsStrings.automaticUpdates,
                   isOn: Binding(get: { updates.automaticallyChecks }, set: { updates.setAutomaticallyChecks($0) }))
            LabeledContent {
                Button(SettingsStrings.checkNow, action: updates.checkForUpdates)
                    .disabled(!updates.canCheckForUpdates)
            } label: {
                Text(lastCheckedText).foregroundStyle(.secondary)
            }
        } header: {
            Text(SettingsStrings.updatesHeader)
        }
    }

    private var lastCheckedText: String {
        guard let date = updates.lastCheckDate else { return SettingsStrings.neverChecked }
        return SettingsStrings.lastChecked(date.formatted(.relative(presentation: .named)))
    }
}
