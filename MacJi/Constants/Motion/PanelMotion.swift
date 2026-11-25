//
//  PanelMotion.swift
//  MacJi
//
//  Created: 2026-11-26
//  Animation curves and delays for the inline panel, the picker and the shared emoji views.
//  Ported from Octopus: octopus/Constants/Motion/MenuMotion.swift, octopus/UI/MacJi/MacJiController.swift
//

import SwiftUI

////////////////////
//// Curves and delays
/// A lightly under-damped spring gives a small settle on appear without bouncing.
// Reduce Motion is honoured by the views that use these values.

enum PanelMotion {
    // Appear
    static let appear = Animation.spring(response: 0.34, dampingFraction: 0.68)
    static let appearReduced = Animation.easeOut(duration: 0.12)
    static let appearScale: CGFloat = 0.92

    // Press and hover
    static let press = Animation.easeOut(duration: 0.1)
    static let pressedScale: CGFloat = 0.9
    static let hoverGrow = Animation.easeOut(duration: 0.12)
    static let categorySlide = Animation.spring(response: 0.28, dampingFraction: 0.82)

    // Dismiss
    static let fadeOutDuration: TimeInterval = 0.12
    /// How long the "Copied" badge shows before the inline panel closes itself.
    static let copyCloseDelay: TimeInterval = 0.9

    // Feedback
    /// How long the pointer or selection must rest before the inline panel names the emoji.
    static let nameRevealDelay = Duration.milliseconds(550)
    static let nameReveal = Animation.easeOut(duration: 0.15)
    static let badgeIn = Animation.easeOut(duration: 0.15)
    static let badgeOut = Animation.easeIn(duration: 0.2)
    static let badgeVisible = Duration.milliseconds(1200)
    static let settingsReveal = Animation.easeOut(duration: 0.18)
}

//// Badge visibility outlasts the copy-close delay, so the badge is still showing as the panel fades.
//////////////////
