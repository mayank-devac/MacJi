//
//  AppSettings.swift
//  MacJi
//
//  Created: 2026-11-26
//  Typed, validated access to every stored setting, published for the Settings window and
//  for the composition root, which forwards changes to the features.
//

import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var inlinePanelEnabled: Bool {
        didSet { store(inlinePanelEnabled, oldValue, PreferenceKeys.inlinePanelEnabled) }
    }
    /// Always valid: change it through `setTrigger(_:)`.
    @Published private(set) var trigger: String
    @Published var showMenuBarIcon: Bool {
        didSet { store(showMenuBarIcon, oldValue, PreferenceKeys.showMenuBarIcon) }
    }

    private let defaults: UserDefaults

    ////////////////////
    //// Reading stored values
    /// A missing value reads its registered default. A stored value of the wrong type or an
    /// invalid trigger falls back to the default for that key only, and is never deleted, so a
    // value written by a newer MacJi survives running an older one.

    init(defaults: UserDefaults) {
        self.defaults = defaults
        inlinePanelEnabled = defaults.object(forKey: PreferenceKeys.inlinePanelEnabled) as? Bool ?? PreferenceDefaults.inlinePanelEnabled
        trigger = InlineTrigger.valid(defaults.object(forKey: PreferenceKeys.inlinePanelTrigger) as? String)
        showMenuBarIcon = defaults.object(forKey: PreferenceKeys.showMenuBarIcon) as? Bool ?? PreferenceDefaults.showMenuBarIcon
    }

    /// Registers (never writes) the defaults. Call once at launch, after `SettingsMigrator`.
    static func registerDefaults(in defaults: UserDefaults) {
        defaults.register(defaults: PreferenceDefaults.registered)
    }

    //// Only a user action or a migration ever writes a setting.
    //////////////////

    /// Stores `raw` and returns nil when it is a valid trigger; otherwise keeps the current
    /// trigger and returns why `raw` was rejected.
    func setTrigger(_ raw: String) -> InlineTrigger.Problem? {
        if let problem = InlineTrigger.problem(with: raw) { return problem }
        guard raw != trigger else { return nil }
        trigger = raw
        defaults.set(raw, forKey: PreferenceKeys.inlinePanelTrigger)
        return nil
    }

    /// App state rather than a setting: has the first launch already shown Settings?
    var hasCompletedFirstLaunch: Bool {
        get { defaults.bool(forKey: PreferenceKeys.hasCompletedFirstLaunch) }
        set { defaults.set(newValue, forKey: PreferenceKeys.hasCompletedFirstLaunch) }
    }

    private func store(_ value: Bool, _ oldValue: Bool, _ key: String) {
        guard value != oldValue else { return }
        defaults.set(value, forKey: key)
    }
}
