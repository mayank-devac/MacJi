//
//  SettingsMigrator.swift
//  MacJi
//
//  Created: 2026-11-26
//  Upgrades stored settings from older MacJi versions: a stored schema version and ordered,
//  idempotent migrations that run once at launch, before anything reads a setting.
//

import Foundation

/// One step that brings stored settings to the next schema version.
struct SettingsMigration: Sendable {
    let summary: String
    let apply: @Sendable (SettingsMigrationContext) -> Void

    ////////////////////
    //// Rename a key
    /// Copies the old value to the new key (unless the user already stored a value there),
    /// and only then removes the old key. Running it twice changes nothing.

    static func renameKey(_ old: String, to new: String) -> SettingsMigration {
        SettingsMigration(summary: "Rename \(old) to \(new)") { context in
            guard let value = context.storedValue(forKey: old) else { return }
            if context.storedValue(forKey: new) == nil { context.defaults.set(value, forKey: new) }
            context.defaults.removeObject(forKey: old)
        }
    }

    //////////////////
}

////////////////////
//// What a migration can see
/// Registered defaults are process-wide and show through `object(forKey:)` on every
/// UserDefaults, so migrations read the persistent domain: only what the user really stored.

struct SettingsMigrationContext {
    let defaults: UserDefaults
    let domain: String

    func storedValue(forKey key: String) -> Any? {
        defaults.persistentDomain(forName: domain)?[key]
    }
}

//////////////////

enum SettingsMigrator {
    ////////////////////
    //// Migrations
    /// Append only. Migration n (counting from 1) brings the schema to version n.
    /// Never edit, reorder or remove one that has shipped; add a new one instead.
    // Version 0 is the first release's layout (the keys in PreferenceKeys), so the list starts empty.

    static let migrations: [SettingsMigration] = []

    //// Example: `.renameKey("inlinePanelTrigger", to: "panelTrigger")` plus updating PreferenceKeys.
    //////////////////

    ////////////////////
    //// Run pending migrations
    /// Applies every migration after the stored version, in order, then records the new version.
    /// Nothing is written when there is nothing to do, and a version written by a newer MacJi
    // (higher than this build knows) is left untouched.

    @discardableResult
    static func migrate(_ defaults: UserDefaults, domain: String = Bundle.main.bundleIdentifier ?? "",
                        migrations: [SettingsMigration] = migrations) -> Int {
        let stored = defaults.integer(forKey: PreferenceKeys.settingsSchemaVersion)
        guard stored < migrations.count else { return 0 }
        let context = SettingsMigrationContext(defaults: defaults, domain: domain)
        for migration in migrations[stored...] {
            Log.settings.notice("Migrating settings: \(migration.summary, privacy: .public)")
            migration.apply(context)
        }
        defaults.set(migrations.count, forKey: PreferenceKeys.settingsSchemaVersion)
        return migrations.count - stored
    }

    //// Returns how many migrations ran.
    //////////////////
}
