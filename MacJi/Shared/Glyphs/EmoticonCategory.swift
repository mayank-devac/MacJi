//
//  EmoticonCategory.swift
//  MacJi
//
//  Created: 2026-11-27
//  The emoticon catalog's filters, in emoticons.json order.
//

import Foundation

/// Raw values match the `category` strings scripts/update-emoticon-data.py writes.
enum EmoticonCategory: String, GlyphCategory {
    case happy = "Happy"
    case love = "Love"
    case sad = "Sad"
    case angry = "Angry"
    case surprised = "Surprised"
    case shrug = "Shrug"
    case flip = "Flip"
    case greeting = "Greeting"
    case animals = "Animals"
    case other = "Other"

    var id: String { rawValue }
    var title: String { rawValue }

    var symbol: String {
        switch self {
        case .happy: "face.smiling"
        case .love: "heart"
        case .sad: "cloud.rain"
        case .angry: "flame"
        case .surprised: "exclamationmark.bubble"
        case .shrug: "questionmark"
        case .flip: "table"
        case .greeting: "hand.wave"
        case .animals: "pawprint"
        case .other: "ellipsis.circle"
        }
    }
}
