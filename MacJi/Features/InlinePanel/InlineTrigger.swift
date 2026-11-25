//
//  InlineTrigger.swift
//  MacJi
//
//  Created: 2026-11-26
//  The rules for a valid trigger, with a reason for each rejection so Settings can explain it.
//  Ported from Octopus: octopus/UI/MacJi/MacJiSettings.swift
//

enum InlineTrigger {
    enum Problem: Equatable {
        case empty
        case tooLong
        case whitespace
        /// Made only of letters, digits or `_-+`: it would fire inside ordinary words.
        case onlyQueryCharacters
    }

    ////////////////////
    //// Validation
    /// A trigger is 1–4 characters, contains no whitespace and at least one character that
    /// can't appear in a search term, so typing normal words never opens the panel.

    static func problem(with raw: String) -> Problem? {
        if raw.isEmpty { return .empty }
        if raw.count > Limits.triggerMaxLength { return .tooLong }
        if raw.contains(where: { $0.isWhitespace || $0.isNewline }) { return .whitespace }
        if raw.allSatisfy(TriggerTracker.isQueryCharacter) { return .onlyQueryCharacters }
        return nil
    }

    /// The stored trigger, or the default when it is missing or invalid.
    static func valid(_ raw: String?) -> String {
        guard let raw, problem(with: raw) == nil else { return PreferenceDefaults.trigger }
        return raw
    }

    //// Invalid stored values fall back at read time; they are never deleted.
    //////////////////
}
