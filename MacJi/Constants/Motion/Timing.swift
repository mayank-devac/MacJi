//
//  Timing.swift
//  MacJi
//
//  Created: 2026-11-26
//  Non-animation intervals: permission probes, guide polling and recovery deadlines.
//  Ported from Octopus: octopus/UI/Permissions/EventTapRevocationProbe.swift, octopus/UI/Permissions/AccessibilityPermissionGuide.swift, octopus/UI/Permissions/AccessibilityRevocationRecovery.swift
//

import Foundation

enum Timing {
    // Event-tap revocation probe: a probe costs about a millisecond and runs only while a tap is installed.
    static let revocationProbeInterval: TimeInterval = 0.5
    static let revocationRetryDelay: TimeInterval = 0.1

    // Recovery after revocation
    static let recoveryMainThreadDeadline: TimeInterval = 1
    static let recoveryTerminationGrace: TimeInterval = 10

    // Permission guide beside System Settings; runs only while the guide is open.
    static let guidePollInterval: TimeInterval = 0.25
    static let guideLaunchGrace: TimeInterval = 5

    /// macOS updates `AXIsProcessTrusted()` a moment after it posts the change notification.
    static let permissionRecheckDelay: TimeInterval = 0.5

    /// A click on the menu-bar icon closes the transient popover on mouse-down; a toggle arriving
    /// this soon after is that same click and must not reopen it.
    static let popoverReopenGuard: TimeInterval = 0.3

    /// AX messaging timeout for caret lookups; unresponsive apps must not stall typing.
    static let axMessagingTimeout: Float = 0.1
}
