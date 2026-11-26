//
//  CustomTextAliasValidator.swift
//  MacJi
//
//  Created: 2026-11-27
//  The rules for your own aliases (name, spellings, outputs), with a reason for each rejection
//  so the editor can explain it.
//

import Foundation

enum CustomTextAliasValidator {
    /// What the editor holds: rows may be blank while you type; blank rows are dropped on save.
    struct Draft: Equatable {
        var name = ""
        var group = TextAlias.Group.symbols
        var texts = [""]
        var replacements = [""]
        var wordStartOnly = true
    }

    enum Problem: Equatable {
        case nameMissing, nameTooLong
        case spellingTooShort, spellingTooLong, spellingHasSpace, spellingOnlyLettersOrDigits
        /// Typing it would open that panel trigger instead.
        case spellingHasTrigger(String)
        case spellingRepeated
        /// Another of your aliases already uses it; the associated value is that alias's name.
        case spellingTaken(String)
        case outputTooLong, outputHasNewline, outputRepeated
        case noSpelling, noOutput
    }

    ////////////////////
    //// Field rules
    /// A spelling is 2–16 characters with no whitespace and at least one character that isn't a
    /// letter or digit (the trigger rule), so it never fires inside a word. It may not contain
    /// an active trigger and no two of your aliases may share one. A built-in with the same
    // spelling is fine: yours wins (see ActiveTextAliases) and the editor says so.

    static func nameProblem(_ name: String) -> Problem? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .nameMissing }
        return trimmed.count > Limits.aliasNameMaxLength ? .nameTooLong : nil
    }

    /// Blank rows have no problem; they are dropped on save.
    static func spellingProblem(at index: Int, in texts: [String], triggers: [String], others: [TextAlias]) -> Problem? {
        let text = texts[index]
        if text.isEmpty { return nil }
        if text.count < Limits.aliasSpellingLengths.lowerBound { return .spellingTooShort }
        if text.count > Limits.aliasSpellingLengths.upperBound { return .spellingTooLong }
        if text.contains(where: { $0.isWhitespace || $0.isNewline }) { return .spellingHasSpace }
        if text.allSatisfy({ $0.isLetter || $0.isNumber }) { return .spellingOnlyLettersOrDigits }
        if let trigger = triggers.first(where: { !$0.isEmpty && text.contains($0) }) { return .spellingHasTrigger(trigger) }
        if texts[..<index].contains(text) { return .spellingRepeated }
        if let other = others.first(where: { $0.texts.contains(text) }) { return .spellingTaken(other.name ?? "") }
        return nil
    }

    static func outputProblem(at index: Int, in replacements: [String]) -> Problem? {
        let text = replacements[index]
        if text.allSatisfy(\.isWhitespace) { return nil }
        if text.contains(where: \.isNewline) { return .outputHasNewline }
        if text.count > Limits.aliasOutputMaxLength { return .outputTooLong }
        return replacements[..<index].contains(text) ? .outputRepeated : nil
    }

    //////////////////

    ////////////////////
    //// Saving
    /// A draft saves when every field is valid and at least one spelling and one output remain.
    // `others` are your other aliases (not the one being edited).

    static func problems(in draft: Draft, triggers: [String], others: [TextAlias]) -> [Problem] {
        var problems = [nameProblem(draft.name)].compactMap { $0 }
        problems += draft.texts.indices.compactMap { spellingProblem(at: $0, in: draft.texts, triggers: triggers, others: others) }
        problems += draft.replacements.indices.compactMap { outputProblem(at: $0, in: draft.replacements) }
        if spellings(of: draft).isEmpty { problems.append(.noSpelling) }
        if outputs(of: draft).isEmpty { problems.append(.noOutput) }
        return problems
    }

    static func alias(from draft: Draft, id: String, triggers: [String], others: [TextAlias]) -> TextAlias? {
        guard problems(in: draft, triggers: triggers, others: others).isEmpty else { return nil }
        return TextAlias(id: id, texts: spellings(of: draft), replacements: outputs(of: draft), group: draft.group,
                         boundary: draft.wordStartOnly ? .afterSpace : .anywhere,
                         name: draft.name.trimmingCharacters(in: .whitespaces))
    }

    static func draft(from alias: TextAlias) -> Draft {
        Draft(name: alias.name ?? "", group: alias.group, texts: alias.texts, replacements: alias.replacements,
              wordStartOnly: alias.boundary == .afterSpace)
    }

    private static func spellings(of draft: Draft) -> [String] {
        draft.texts.filter { !$0.isEmpty }
    }

    private static func outputs(of draft: Draft) -> [String] {
        draft.replacements.filter { !$0.allSatisfy(\.isWhitespace) }
    }

    //////////////////
}
