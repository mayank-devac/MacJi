//
//  InlinePanelPlacement.swift
//  MacJi
//
//  Created: 2026-11-26
//  Where the inline panel opens: just under the caret, flipped above when there is no room.
//  Pure geometry so it is unit-tested.
//  Ported from Octopus: octopus/UI/MacJi/MacJiPanel.swift
//

import CoreGraphics

struct InlinePanelPlacement: Equatable {
    /// Panel frame in AppKit screen coordinates, including the shadow margin.
    let frame: CGRect
    /// True when the card sits above the caret (no room below).
    let opensAbove: Bool

    ////////////////////
    //// Place the card
    /// The card opens just under the caret, left-aligned with it, and flips above when there is
    /// no room below. Without a caret it opens at the pointer.
    // Frames include the shadow margin, which may hang off-screen; only the card itself is kept inside.

    static func place(card: CGSize, caret: CGRect?, pointer: CGPoint, visibleFrames: [CGRect]) -> InlinePanelPlacement {
        let anchor = caret ?? CGRect(origin: pointer, size: .zero)
        let margin = MenuShadowMargin.size
        let size = MenuShadowMargin.panelSize(card: card)
        let screen = visibleFrames.first { $0.contains(CGPoint(x: anchor.minX, y: anchor.midY)) }
            ?? visibleFrames.first ?? CGRect(origin: .zero, size: size)
        var origin = CGPoint(x: anchor.minX - margin, y: anchor.minY - PanelMetrics.caretGap - card.height - margin)
        let opensAbove = origin.y + margin < screen.minY
        if opensAbove {
            origin.y = anchor.maxY + PanelMetrics.caretGap - margin
        }
        origin.x = min(max(origin.x, screen.minX - margin), screen.maxX - size.width + margin)
        origin.y = min(max(origin.y, screen.minY - margin), screen.maxY - size.height + margin)
        return InlinePanelPlacement(frame: CGRect(origin: origin, size: size), opensAbove: opensAbove)
    }

    //// The appear animation grows from the card corner nearest the caret.
    //////////////////
}
