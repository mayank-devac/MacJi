//
//  MenuAppearModifier.swift
//  MacJi
//
//  Created: 2026-11-26
//  Appear animation for floating cards: fade in and grow out of the anchor point.
//  Ported from Octopus: octopus/UI/MenuKit/MenuAppearModifier.swift
//

import SwiftUI

////////////////////
//// Appear animation
/// The hosting view stays alive while its panel is hidden, so `onAppear` runs only once.
/// A new `presentationID` replays the animation for each presentation; refreshes keep the same
// ID and never replay it. `anchor` is the point the card grows from (the caret side).

struct MenuAppearModifier: ViewModifier {
    let presentationID: Int
    let anchor: UnitPoint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .scaleEffect(isShown || reduceMotion ? 1 : PanelMotion.appearScale, anchor: anchor)
            .onAppear(perform: replay)
            .onChange(of: presentationID) { replay() }
    }

    private func replay() {
        var reset = Transaction()
        reset.disablesAnimations = true
        withTransaction(reset) { isShown = false }
        // Animate on the next turn so the reset frame is committed first.
        DispatchQueue.main.async {
            withAnimation(reduceMotion ? PanelMotion.appearReduced : PanelMotion.appear) { isShown = true }
        }
    }
}

extension View {
    func menuAppear(presentationID: Int, anchor: UnitPoint) -> some View {
        modifier(MenuAppearModifier(presentationID: presentationID, anchor: anchor))
    }
}

//////////////////
