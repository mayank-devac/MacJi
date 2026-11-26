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
        /// Contains, or is part of, another panel's trigger, so typing one would open both.
        case overlaps(InlinePanelKind, trigger: String)
    }

    ////////////////////
    //// Validation
    /// A trigger is 1–4 characters, contains no whitespace and at least one character that
    /// can't appear in a search term, so typing normal words never opens the panel.
    /// No two triggers may contain one another. The emoticon trigger may be blank: no trigger.

    static func problem(with raw: String, for kind: InlinePanelKind = .emoji,
                        others: [InlinePanelKind: String] = [:]) -> Problem? {
        if raw.isEmpty { return kind.triggerIsOptional ? nil : .empty }
        if raw.count > Limits.triggerMaxLength { return .tooLong }
        if raw.contains(where: { $0.isWhitespace || $0.isNewline }) { return .whitespace }
        if raw.allSatisfy(TriggerTracker.isQueryCharacter) { return .onlyQueryCharacters }
        let overlapping = InlinePanelKind.allCases.first { other in
            guard other != kind, let trigger = others[other], !trigger.isEmpty else { return false }
            return trigger.contains(raw) || raw.contains(trigger)
        }
        return overlapping.map { .overlaps($0, trigger: others[$0] ?? "") }
    }

    /// The stored trigger, else the default, else blank when even the default overlaps another.
    static func valid(_ raw: String?, for kind: InlinePanelKind = .emoji,
                      others: [InlinePanelKind: String] = [:]) -> String {
        if let raw, problem(with: raw, for: kind, others: others) == nil { return raw }
        return problem(with: kind.defaultTrigger, for: kind, others: others) == nil ? kind.defaultTrigger : ""
    }

    //// Invalid stored values fall back at read time; they are never deleted.
    //////////////////
}
