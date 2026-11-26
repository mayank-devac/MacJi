//
//  GlyphCategory.swift
//  MacJi
//
//  Created: 2026-11-27
//  What a catalog's categories provide, and the emoji categories in gemoji (Unicode) order.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiCatalog.swift
//

import Foundation

/// A catalog's filters. Raw values match the `category` strings in its data file exactly.
protocol GlyphCategory: RawRepresentable, CaseIterable, Identifiable, Hashable, Sendable
    where RawValue == String, AllCases == [Self] {
    /// SF Symbol describing the category in filter bars.
    var symbol: String { get }
    /// Name shown in tooltips and VoiceOver.
    var title: String { get }
}

////////////////////
//// Emoji categories
/// The picker's emoji filters, in gemoji (Unicode) order. The symbol describes the category.

enum EmojiCategory: String, GlyphCategory {
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
    var title: String { rawValue }

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
