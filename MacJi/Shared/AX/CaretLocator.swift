//
//  CaretLocator.swift
//  MacJi
//
//  Created: 2026-11-26
//  Finds the text caret of the focused app through AX, so panels open next to it.
//  Many apps (Electron, some web views, terminals) report no text bounds; callers fall back
//  to the pointer.
//  Ported from Octopus: octopus/UI/MacJi/MacJiCaretLocator.swift
//

import AppKit

enum CaretLocator {
    /// Caret rectangle in AppKit screen coordinates, or nil when unavailable.
    @MainActor
    static func caretRect() -> CGRect? {
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, Timing.axMessagingTimeout)
        guard let focused = AXValueReader.element(kAXFocusedUIElementAttribute, of: system) else { return nil }
        AXUIElementSetMessagingTimeout(focused, Timing.axMessagingTimeout)
        guard let selection = AXValueReader.range(kAXSelectedTextRangeAttribute, of: focused),
              let primary = NSScreen.screens.first else { return nil }

        ////////////////////
        //// Bounds at the caret
        /// The character just before the caret is measured first: apps report it far more
        /// reliably than a collapsed range, which some answer with the whole line, field or a
        /// stale rect. Its trailing edge is the caret.
        // AX uses top-left global coordinates, flipped here against the primary screen.

        let screens = NSScreen.screens.map(\.frame)
        if selection.length == 0, selection.location > 0,
           let previous = AXValueReader.bounds(of: CFRange(location: selection.location - 1, length: 1), in: focused),
           let caret = plausibleCaret(CGRect(x: previous.maxX, y: previous.minY, width: 0, height: previous.height),
                                      primaryMaxY: primary.frame.maxY, screens: screens) {
            return caret
        }
        guard let collapsed = AXValueReader.bounds(of: selection, in: focused) else { return nil }
        return plausibleCaret(collapsed, primaryMaxY: primary.frame.maxY, screens: screens)

        //// Anything taller than a text line or off every screen is not a caret.
        //////////////////
    }

    /// Flips an AX rect to AppKit coordinates and keeps it only when it looks like a caret.
    static func plausibleCaret(_ axRect: CGRect, primaryMaxY: CGFloat, screens: [CGRect]) -> CGRect? {
        guard axRect.height > 0, axRect.height <= Limits.maxCaretHeight else { return nil }
        let rect = CGRect(x: axRect.minX, y: primaryMaxY - axRect.maxY, width: axRect.width, height: axRect.height)
        let probe = CGPoint(x: rect.minX, y: rect.midY)
        return screens.contains { $0.contains(probe) } ? rect : nil
    }
}
