//
//  GlyphLibrary.swift
//  MacJi
//
//  Created: 2026-11-27
//  The three bundled catalogs (emoji, symbols, emoticons), loaded together off the main thread.
//

import Foundation

typealias SymbolCatalog = GlyphCatalog<SymbolCategory>
typealias EmoticonCatalog = GlyphCatalog<EmoticonCategory>

struct GlyphLibrary: Sendable {
    let emoji: EmojiCatalog
    let symbols: SymbolCatalog
    let emoticons: EmoticonCatalog

    static let empty = GlyphLibrary(emoji: .empty, symbols: .empty, emoticons: .empty)

    /// Each file decodes on its own background task; a missing one leaves just that catalog empty.
    static func loadBundled() async -> GlyphLibrary {
        async let emoji = EmojiCatalog.loadBundled(GlyphResources.emoji)
        async let symbols = SymbolCatalog.loadBundled(GlyphResources.symbols)
        async let emoticons = EmoticonCatalog.loadBundled(GlyphResources.emoticons)
        return await GlyphLibrary(emoji: emoji, symbols: symbols, emoticons: emoticons)
    }
}
