//
//  MenuShadowMargin.swift
//  MacJi
//
//  Created: 2026-11-26
//  The transparent margin around a floating card, where the card's soft shadow draws.
//  Ported from Octopus: octopus/UI/MenuKit/MenuShadowMargin.swift
//

import CoreGraphics

////////////////////
//// Shadow margin
/// Views pad the card with `size`; controllers size their panel with `panelSize(card:)`.
// Octopus's sidebar-facing variants are dropped: MacJi's cards float free on every side.

enum MenuShadowMargin {
    static let size = PanelMetrics.shadowInset

    static func panelSize(card: CGSize) -> CGSize {
        CGSize(width: card.width + size * 2, height: card.height + size * 2)
    }
}

//////////////////
