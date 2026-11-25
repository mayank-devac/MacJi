//
//  TriggerTracker.swift
//  MacJi
//
//  Created: 2026-11-26
//  Remembers the last few characters typed in the focused app and reports the search term
//  after the trigger, e.g. "rock" for "::rock". A pure value type so the rules are unit-tested.
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
    var trigger: String { didSet { buffer = "" } }
    private(set) var buffer = ""

    init(trigger: String) {
        self.trigger = trigger
    }

    static func isQueryCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || "_-+".contains(character)
    }

    mutating func apply(_ key: TypedKey) {
        switch key {
        case .text(let text):
            buffer += text
            let limit = trigger.count + Limits.queryMaxLength + 1
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
    /// The text after the last trigger, while it is non-empty and made only of query characters.
    /// Space or punctuation ends the term, closing the panel.
    // The trigger must not follow a letter or digit, so "std::string" never opens it.

    var query: String? {
        guard let range = buffer.range(of: trigger, options: .backwards) else { return nil }
        if let before = buffer[..<range.lowerBound].last, before.isLetter || before.isNumber { return nil }
        let term = buffer[range.upperBound...]
        guard !term.isEmpty, term.count <= Limits.queryMaxLength, term.allSatisfy(Self.isQueryCharacter) else { return nil }
        return String(term)
    }

    /// Characters to delete when replacing "trigger + term" with an emoji.
    var replacementLength: Int {
        query.map { trigger.count + $0.count } ?? 0
    }

    //// The panel is shown exactly while `query` is non-nil.
    //////////////////
}
