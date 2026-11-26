//
//  TriggerTracker.swift
//  MacJi
//
//  Created: 2026-11-26
//  Remembers the last few characters typed in the focused app and reports the search term
//  after the last trigger, e.g. "rock" for "::rock". A pure value type so the rules are unit-tested.
//  Ported from Octopus: octopus/UI/MacJi/MacJiTriggerTracker.swift
//

import Foundation

/// What a key press means for the typed-text buffer.
enum TypedKey: Equatable {
    case text(String)
    case deleteBackward
    /// Caret moved or text changed in a way the buffer cannot follow.
    case reset
}

struct TriggerTracker {
    /// The open search: which panel, the trigger that opened it and the term typed after it.
    struct Query: Equatable {
        let kind: InlinePanelKind
        let trigger: String
        let term: String
    }

    /// One trigger per panel; a blank or missing one never opens its panel.
    var triggers: [InlinePanelKind: String] { didSet { buffer = "" } }
    private(set) var buffer = ""

    init(triggers: [InlinePanelKind: String]) {
        self.triggers = triggers
    }

    static func isQueryCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || "_-+".contains(character)
    }

    mutating func apply(_ key: TypedKey) {
        switch key {
        case .text(let text):
            buffer += text
            let longest = triggers.values.map(\.count).max() ?? 0
            let limit = longest + Limits.queryMaxLength + 1
            if buffer.count > limit { buffer = String(buffer.suffix(limit)) }
        case .deleteBackward:
            if !buffer.isEmpty { buffer.removeLast() }
        case .reset:
            buffer = ""
        }
    }

    mutating func reset() {
        buffer = ""
    }

    ////////////////////
    //// Current search term
    /// The text after the trigger typed last, while it is non-empty and made only of query
    /// characters. Space or punctuation ends the term, closing the panel.
    // The trigger must not follow a letter or digit, so "std::string" and "a##b" never open it.
    // Triggers never contain one another (InlineTrigger), so the last one found is unambiguous.

    var query: Query? {
        let found = triggers.compactMap { kind, trigger -> (kind: InlinePanelKind, trigger: String, range: Range<String.Index>)? in
            guard !trigger.isEmpty, let range = buffer.range(of: trigger, options: .backwards) else { return nil }
            return (kind, trigger, range)
        }
        guard let last = found.max(by: { $0.range.lowerBound < $1.range.lowerBound }) else { return nil }
        if let before = buffer[..<last.range.lowerBound].last, before.isLetter || before.isNumber { return nil }
        let term = buffer[last.range.upperBound...]
        guard !term.isEmpty, term.count <= Limits.queryMaxLength, term.allSatisfy(Self.isQueryCharacter) else { return nil }
        return Query(kind: last.kind, trigger: last.trigger, term: String(term))
    }

    /// Characters to delete when replacing "trigger + term" with a glyph.
    var replacementLength: Int {
        query.map { $0.trigger.count + $0.term.count } ?? 0
    }

    //// The panel is shown exactly while `query` is non-nil.
    //////////////////
}
