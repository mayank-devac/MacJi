//
//  GlyphResources.swift
//  MacJi
//
//  Created: 2026-11-27
//  Names of the bundled glyph data files, without the .json extension.
//

import Foundation

enum GlyphResources {
    /// gemoji's emoji, stripped by scripts/update-emoji-data.py.
    static let emoji = "emoji"
    /// Unicode symbols, written by scripts/update-symbol-data.py.
    static let symbols = "symbols"
    /// ASCII emoticons and kaomoji, written by scripts/update-emoticon-data.py.
    static let emoticons = "emoticons"
}
