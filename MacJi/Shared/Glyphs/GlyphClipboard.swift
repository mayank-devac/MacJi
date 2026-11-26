//
//  GlyphClipboard.swift
//  MacJi
//
//  Created: 2026-11-26
//  Copies a glyph to the pasteboard; the one copy path for the panel and the picker.
//  Ported from Octopus: octopus/UI/MacJi/MacJiModel.swift, octopus/UI/EmojiPicker/EmojiPickerModel.swift
//

import AppKit

enum GlyphClipboard {
    /// Returns false when the pasteboard refused the text.
    @MainActor
    static func copy(_ glyph: Glyph, to pasteboard: NSPasteboard = .general) -> Bool {
        pasteboard.clearContents()
        return pasteboard.setString(glyph.text, forType: .string)
    }
}
