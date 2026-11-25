//
//  LoginItem.swift
//  MacJi
//
//  Created: 2026-11-26
//  "Open at login" through SMAppService: reads the real status (the user can change it in
//  System Settings at any time) and reports failures in the UI instead of printing them.
//  Ported from Octopus: octopus/UI/Preferences/PreferencesGeneralView.swift
//

import Combine
import ServiceManagement

@MainActor
final class LoginItem: ObservableObject {
    @Published private(set) var isEnabled = false
    /// Registered, but waiting for the user's approval in System Settings › Login Items.
    @Published private(set) var needsApproval = false
    @Published private(set) var errorMessage: String?

    ////////////////////
    //// Status and changes
    /// The status lives in macOS, not in MacJi's preferences, so it is re-read whenever Settings
    // opens and after every change.

    func refresh() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled || status == .requiresApproval
        needsApproval = status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            errorMessage = SettingsStrings.loginError(error.localizedDescription)
            Log.settings.error("Login item change failed: \(error.localizedDescription, privacy: .public)")
        }
        refresh()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    //// A failed change leaves the toggle showing the real status.
    //////////////////
}
