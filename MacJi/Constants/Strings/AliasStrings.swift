//
//  AliasStrings.swift
//  MacJi
//
//  Created: 2026-11-27
//  User-visible text of the Aliases page and the alias editor.
//

import Foundation

enum AliasStrings {
    ////////////////////
    //// Aliases page

    static let back = String(localized: "Settings")
    static let title = String(localized: "Aliases")
    static let add = String(localized: "New Alias…")
    static let addInGroup = String(localized: "Add Alias…")
    static let filterPlaceholder = String(localized: "Filter by spelling, symbol or name")
    static let arrows = String(localized: "Arrows")
    static let math = String(localized: "Math")
    static let symbols = String(localized: "Symbols")
    static let emoticons = String(localized: "Emoticons")
    static let emoji = String(localized: "Emoji")
    static let yours = String(localized: "Yours")
    static let edit = String(localized: "Edit…")
    static let delete = String(localized: "Delete…")
    static let emoticonsFooter = String(localized: "Symbols in brackets and emoticons convert only at the start of a word, so \"note:)\" and the trigger stay as typed.")
    static let footer = String(localized: "An alias converts as you type its last character, in every app. Turn off any you type in code, such as -> or !=. Your own aliases also show in every panel's search, by name.")
    static let turnAllOn = String(localized: "Turn All On")
    static let noMatches = String(localized: "No aliases match.")

    static func onCount(_ on: Int, of total: Int) -> String {
        String(localized: "\(on) of \(total) on")
    }

    static func example(_ example: String, yours count: Int) -> String {
        String(localized: "\(example) · \(count) of your own")
    }

    static func deleteTitle(_ name: String) -> String {
        String(localized: "Delete “\(name)”?")
    }

    static let deleteMessage = String(localized: "This alias is removed for good. This can't be undone.")
    static let limitReached = String(localized: "You have the most aliases MacJi keeps. Delete one to add another.")

    //////////////////

    ////////////////////
    //// Editor

    static let newTitle = String(localized: "New Alias")
    static let editTitle = String(localized: "Edit Alias")
    static let nameLabel = String(localized: "Name")
    static let namePlaceholder = String(localized: "Check mark")
    static let groupLabel = String(localized: "Group")
    static let spellingsHeader = String(localized: "You type")
    static let spellingPlaceholder = String(localized: "[x]")
    static let addSpelling = String(localized: "Add Spelling")
    static let outputsHeader = String(localized: "Becomes")
    static let outputPlaceholder = String(localized: "✓")
    static let addOutput = String(localized: "Add Output")
    static let characterViewer = String(localized: "Emoji & Symbols…")
    static let typedBadge = String(localized: "Typed")
    static let useWhenTyping = String(localized: "Type this one")
    static let removeRow = String(localized: "Remove")
    static let wordStartOnly = String(localized: "Only at the start of a word")
    static let wordStartOnlyHint = String(localized: "Recommended: \"note[x]\" and code stay as typed.")
    static let outputsFooter = String(localized: "Typing a spelling gives the first output. Search shows them all.")
    static let save = String(localized: "Save")
    static let cancel = String(localized: "Cancel")

    static func typeHint(_ spelling: String) -> String {
        String(localized: "Type \(spelling)")
    }

    static func searchHint(_ examples: String) -> String {
        String(localized: "Find it by name in any panel: \(examples)")
    }

    static func preview(typed: String, becomes: String) -> String {
        String(localized: "Typing \(typed) gives \(becomes)")
    }

    static func replacesBuiltIn(_ symbol: String, name: String) -> String {
        String(localized: "Replaces the built-in \(symbol) (\(name)) while this alias is on.")
    }

    //////////////////

    ////////////////////
    //// Editor problems

    static let nameMissing = String(localized: "Give it a name to search by.")
    static let spellingTooShort = String(localized: "Use at least 2 characters.")
    static let spellingHasSpace = String(localized: "Spaces aren't allowed.")
    static let spellingOnlyLettersOrDigits = String(localized: "Include a symbol such as [ ( : or -, so it never fires inside a word.")
    static let spellingRepeated = String(localized: "Already in this list.")
    static let outputHasNewline = String(localized: "Use a single line.")
    static let outputRepeated = String(localized: "Already in this list.")

    static func nameTooLong(_ limit: Int) -> String {
        String(localized: "Use \(limit) characters or fewer.")
    }

    static func spellingTooLong(_ limit: Int) -> String {
        String(localized: "Use \(limit) characters or fewer.")
    }

    static func outputTooLong(_ limit: Int) -> String {
        String(localized: "Use \(limit) characters or fewer.")
    }

    static func spellingHasTrigger(_ trigger: String) -> String {
        String(localized: "Contains the trigger \(trigger), which opens a panel instead.")
    }

    static func spellingTaken(_ name: String) -> String {
        String(localized: "Your alias “\(name)” already uses it.")
    }

    static func message(for problem: CustomTextAliasValidator.Problem) -> String {
        switch problem {
        case .nameMissing, .noSpelling, .noOutput: nameMissing
        case .nameTooLong: nameTooLong(Limits.aliasNameMaxLength)
        case .spellingTooShort: spellingTooShort
        case .spellingTooLong: spellingTooLong(Limits.aliasSpellingLengths.upperBound)
        case .spellingHasSpace: spellingHasSpace
        case .spellingOnlyLettersOrDigits: spellingOnlyLettersOrDigits
        case .spellingHasTrigger(let trigger): spellingHasTrigger(trigger)
        case .spellingRepeated: spellingRepeated
        case .spellingTaken(let name): spellingTaken(name)
        case .outputTooLong: outputTooLong(Limits.aliasOutputMaxLength)
        case .outputHasNewline: outputHasNewline
        case .outputRepeated: outputRepeated
        }
    }

    static func title(of group: TextAlias.Group) -> String {
        switch group {
        case .arrows: arrows
        case .math: math
        case .symbols: symbols
        case .emoticons: emoticons
        case .emoji: emoji
        }
    }

    //////////////////
}
