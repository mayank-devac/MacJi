//
//  TextAliasConverter.swift
//  MacJi
//
//  Created: 2026-11-26
//  Decides, for the key just typed, whether it completes an enabled text alias: which typed
//  characters to delete and what to insert. A pure value type so the rules are unit-tested.
//

import Foundation

struct TextAliasConverter {
    struct Conversion: Equatable {
        let replacement: String
        /// Characters already in the app, just before the caret, that the replacement replaces.
        let deleteCount: Int
    }

    /// One spelling as it stands in the app when its last character is typed.
    private struct Pattern {
        let form: String
        let replacement: String
        let boundary: TextAlias.Boundary
    }

    /// Longest first, so the most specific alias wins.
    private let patterns: [Pattern]

    ////////////////////
    //// Building the patterns
    /// Shorter aliases convert while a longer one is typed, so each spelling is matched in the
    /// form it has in the app by its last key: with "<-" on, "<->" is "←" + ">" by then.
    // The literal spelling is kept too, for text the buffer saw without converting (a paste).

    init(aliases: [TextAlias]) {
        let spellings = aliases.flatMap { alias in alias.texts.map { (text: $0, alias: alias) } }
            .sorted { $0.text.count < $1.text.count }
        var built: [Pattern] = []
        for (text, alias) in spellings where !text.isEmpty {
            let typedSoFar = TextAliasConverter(sortedPatterns: built).typing(String(text.dropLast()))
            for form in Set([text, typedSoFar + String(text.suffix(1))]) {
                built.append(Pattern(form: form, replacement: alias.replacement, boundary: alias.boundary))
            }
        }
        patterns = built.sorted { $0.form.count > $1.form.count }
    }

    private init(sortedPatterns: [Pattern]) {
        patterns = sortedPatterns.sorted { $0.form.count > $1.form.count }
    }

    /// What the app holds after `text` is typed key by key into an empty field.
    private func typing(_ text: String) -> String {
        text.reduce(into: "") { field, character in
            if let conversion = conversion(typing: String(character), after: field) {
                field = String(field.dropLast(conversion.deleteCount)) + conversion.replacement
            } else {
                field.append(character)
            }
        }
    }

    //// Built once per settings change; matching a key is a few suffix checks.
    //////////////////

    ////////////////////
    //// Matching the key just typed
    /// The completing key is kept from the app; only the characters typed before it are deleted.
    // `buffer` is the text before the caret as TriggerTracker knows it, already converted.

    func conversion(typing key: TypedKey, after buffer: String) -> Conversion? {
        guard case .text(let typed) = key else { return nil }
        return conversion(typing: typed, after: buffer)
    }

    private func conversion(typing typed: String, after buffer: String) -> Conversion? {
        let text = buffer + typed
        for pattern in patterns where pattern.form.count >= typed.count && text.hasSuffix(pattern.form) {
            guard pattern.boundary.allows(text.dropLast(pattern.form.count).last) else { continue }
            return Conversion(replacement: pattern.replacement, deleteCount: pattern.form.count - typed.count)
        }
        return nil
    }

    //////////////////
}
