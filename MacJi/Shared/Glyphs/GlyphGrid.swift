//
//  GlyphGrid.swift
//  MacJi
//
//  Created: 2026-11-26
//  Splits items into fixed-column rows, so arrow keys move through the rows the grid draws.
//  Ported from Octopus: octopus/UI/MacJi/MacJiModel.swift, octopus/UI/EmojiPicker/EmojiPickerModel.swift
//

enum GlyphGrid {
    static func rows<Item>(of items: [Item], columns: Int) -> [[Item]] {
        guard columns > 0 else { return [] }
        return stride(from: 0, to: items.count, by: columns).map { Array(items[$0..<min($0 + columns, items.count)]) }
    }
}
