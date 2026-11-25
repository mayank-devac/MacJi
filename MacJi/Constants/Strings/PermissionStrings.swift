//
//  PermissionStrings.swift
//  MacJi
//
//  Created: 2026-11-26
//  User-visible text about Accessibility access and Secure Input.
//  Ported from Octopus: octopus/UI/Permissions/AccessibilityPermissionGuideView.swift, octopus/UI/MacJi/MacJiSecureInput.swift, octopus/UI/MacJi/MacJiSecureInputNotifier.swift
//

import Foundation

enum PermissionStrings {
    ////////////////////
    //// Drag-to-allow guide beside System Settings

    static let guideSubtitle = String(localized: "Then switch it on to allow access.")
    static let close = String(localized: "Close")
    static let resetPrompt = String(localized: "Already in the list but not working?")
    static let reset = String(localized: "Reset")
    static let resetting = String(localized: "Resetting…")
    static let resetFailed = String(localized: "Reset failed. Remove it with the − button.")

    static func guideTitle(_ appName: String) -> String {
        String(localized: "Drag \(appName) into the Accessibility list")
    }

    static func resetDone(_ appName: String) -> String {
        String(localized: "Reset done. Drag \(appName) in again.")
    }

    //////////////////

    ////////////////////
    //// Secure Input
    /// Worded for the app that holds it, because only that app can release it.

    static let pausedTitle = String(localized: "MacJi is paused")
    static let anotherApp = String(localized: "Another app")

    static func blocking(_ holder: String) -> String {
        String(localized: "\(holder) is blocking keyboard access.")
    }

    static let terminalSteps = String(localized: "To fix it, open Terminal and choose Terminal › Secure Keyboard Entry in the menu bar so it's unchecked. Still stuck? Quit Terminal (⌘Q).")

    static func otherAppSteps(_ holder: String) -> String {
        String(localized: "To fix it, close any password field in \(holder). Still stuck? Quit \(holder) (⌘Q).")
    }

    //// Terminal is singled out because its Secure Keyboard Entry stays on until unchecked.
    //////////////////
}
