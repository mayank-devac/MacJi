//
//  SettingsTests.swift
//  MacJiTests
//
//  Created: 2026-11-26
//  Settings survive upgrades: migrations keep values and are idempotent, and a bad stored
//  value falls back for its own key only.
//

import Foundation
import Testing
@testable import MacJi

@MainActor
struct SettingsTests {
    private let domain = "macji.tests.settings.\(UUID().uuidString)"

    private func freshDefaults() throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: domain))
        defaults.removePersistentDomain(forName: domain)
        return defaults
    }

    @Test func migrationFromAnOldSchemaKeepsTheUsersValues() throws {
        let defaults = try freshDefaults()
        defaults.set(";;", forKey: "legacyTrigger")
        defaults.set(false, forKey: PreferenceKeys.showMenuBarIcon)
        let migrations = [SettingsMigration.renameKey("legacyTrigger", to: PreferenceKeys.inlinePanelTrigger)]

        #expect(SettingsMigrator.migrate(defaults, domain: domain, migrations: migrations) == 1)
        AppSettings.registerDefaults(in: defaults)
        let settings = AppSettings(defaults: defaults)

        #expect(settings.trigger == ";;")
        #expect(!settings.showMenuBarIcon)
        #expect(defaults.object(forKey: "legacyTrigger") == nil)
        #expect(defaults.integer(forKey: PreferenceKeys.settingsSchemaVersion) == 1)
    }

    @Test func secondRunChangesNothing() throws {
        let defaults = try freshDefaults()
        defaults.set(";;", forKey: "legacyTrigger")
        let migrations = [SettingsMigration.renameKey("legacyTrigger", to: PreferenceKeys.inlinePanelTrigger)]
        SettingsMigrator.migrate(defaults, domain: domain, migrations: migrations)
        defaults.set("!!", forKey: PreferenceKeys.inlinePanelTrigger)

        #expect(SettingsMigrator.migrate(defaults, domain: domain, migrations: migrations) == 0)
        #expect(defaults.string(forKey: PreferenceKeys.inlinePanelTrigger) == "!!")
        #expect(SettingsMigrator.migrate(defaults, domain: domain, migrations: []) == 0)
    }

    @Test func invalidStoredValueFallsBackForItsOwnKeyOnly() throws {
        let defaults = try freshDefaults()
        defaults.set("ab", forKey: PreferenceKeys.inlinePanelTrigger)
        defaults.set("yes", forKey: PreferenceKeys.inlinePanelEnabled)
        defaults.set(false, forKey: PreferenceKeys.showMenuBarIcon)
        AppSettings.registerDefaults(in: defaults)
        let settings = AppSettings(defaults: defaults)

        #expect(settings.trigger == PreferenceDefaults.trigger)
        #expect(settings.inlinePanelEnabled == PreferenceDefaults.inlinePanelEnabled)
        #expect(!settings.showMenuBarIcon)
        #expect(defaults.string(forKey: PreferenceKeys.inlinePanelTrigger) == "ab")
    }
}
