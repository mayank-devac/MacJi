//
//  EventTapPermissionWatch.swift
//  MacJi
//
//  Created: 2026-11-26
//  Removes every installed event tap when Accessibility is revoked, then relaunches MacJi.
//  Ported from Octopus: octopus/UI/Permissions/EventTapPermissionWatch.swift
//

import AppKit

////////////////////
//// Remove input filters when Accessibility is revoked
/// An active event tap sits in front of every app's keyboard input. If MacJi loses
/// Accessibility while one is installed, macOS keeps routing input to a tap it no longer
/// trusts, so keys never reach any app.
// Tap owners register while their tap is installed. One app-wide probe runs only while at least
// one tap is registered. On confirmed revocation every tap is removed, then MacJi relaunches.

@MainActor
final class EventTapPermissionWatch {
    static let shared = EventTapPermissionWatch()

    private var removals: [ObjectIdentifier: () -> Void] = [:]
    private let probe = EventTapRevocationProbe(
        isTrusted: { EventTapTrust.isGranted() },
        onRevoked: {
            Log.permissions.notice("Accessibility was revoked; removing event taps and relaunching")
            // Queue the tap removal first so it runs before the quit that relaunch requests.
            DispatchQueue.main.async { MainActor.assumeIsolated { EventTapPermissionWatch.shared.removeAllTaps() } }
            AccessibilityRevocationRecovery.relaunch()
        })

    private init() {}

    /// `remove` must uninstall the owner's tap; it may call `tapRemoved(by:)` itself.
    func tapInstalled(by owner: AnyObject, remove: @escaping () -> Void) {
        removals[ObjectIdentifier(owner)] = remove
        probe.setRunning(true)
    }

    func tapRemoved(by owner: AnyObject) {
        guard removals.removeValue(forKey: ObjectIdentifier(owner)) != nil, removals.isEmpty else { return }
        probe.setRunning(false)
    }

    /// Call when macOS disabled a tap. Leave it disabled (a disabled tap blocks nothing) and let
    /// `reenable` run only once trust is confirmed; otherwise recovery takes over.
    func tapDisabled(reenable: @escaping @MainActor @Sendable () -> Void) {
        probe.confirmTrust(ifTrusted: reenable)
    }

    private func removeAllTaps() {
        let pending = removals
        removals = [:]
        pending.values.forEach { $0() }
    }
}

//// The probe costs nothing while no tap is installed.
//////////////////
