//
//  Emoji.swift
//  MacJi
//
//  Created: 2026-11-26
//  The emoji record, its category and a titled section of emoji.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiCatalog.swift
//

import Foundation

/// One emoji record, decoded straight from `emoji.json` (gemoji's fields).
struct Emoji: Decodable, Hashable, Identifiable, Sendable {
    let emoji: String
    let description: String
    let category: String
    let aliases: [String]
    let tags: [String]

    var id: String { emoji }

    /// Name as shown in footers and tooltips ("Grinning Face").
    var displayName: String { description.capitalized }
}

////////////////////
//// Categories
/// The picker's filters, in gemoji (Unicode) order.
/// Raw values must match gemoji's `category` strings exactly; the symbol describes the category.

enum EmojiCategory: String, CaseIterable, Identifiable, Sendable {
    case smileys = "Smileys & Emotion"
    case people = "People & Body"
    case animals = "Animals & Nature"
    case food = "Food & Drink"
    case travel = "Travel & Places"
    case activities = "Activities"
    case objects = "Objects"
    case symbols = "Symbols"
    case flags = "Flags"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .smileys: "face.smiling"
        case .people: "person"
        case .animals: "pawprint"
        case .food: "fork.knife"
        case .travel: "car"
        case .activities: "soccerball"
        case .objects: "lightbulb"
        case .symbols: "heart"
        case .flags: "flag"
        }
    }
}

//// A newer gemoji category is skipped by the catalog until a case is added here.
//////////////////

/// A titled block of emoji: a category, "Recently Used" or search results.
struct EmojiSection: Identifiable, Sendable {
    let title: String
    let emojis: [Emoji]

    var id: String { title }
}
