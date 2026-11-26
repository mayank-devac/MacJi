//
//  SymbolCategory.swift
//  MacJi
//
//  Created: 2026-11-27
//  The symbol catalog's filters, in symbols.json order.
//

import Foundation

/// Raw values match the `category` strings scripts/update-symbol-data.py writes.
enum SymbolCategory: String, GlyphCategory {
    case arrows = "Arrows"
    case math = "Math"
    case greek = "Greek"
    case currency = "Currency"
    case punctuation = "Punctuation"
    case letterlike = "Letterlike"
    case numbers = "Numbers"
    case shapes = "Shapes"
    case signs = "Signs"
    case technical = "Technical"

    var id: String { rawValue }
    var title: String { rawValue }

    var symbol: String {
        switch self {
        case .arrows: "arrow.right"
        case .math: "plus.forwardslash.minus"
        case .greek: "character"
        case .currency: "dollarsign"
        case .punctuation: "quote.opening"
        case .letterlike: "c.circle"
        case .numbers: "number"
        case .shapes: "square.on.circle"
        case .signs: "star"
        case .technical: "command"
        }
    }
}
