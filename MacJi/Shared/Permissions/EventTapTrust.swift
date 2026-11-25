//
//  EventTapTrust.swift
//  MacJi
//
//  Created: 2026-11-26
//  Asks macOS whether MacJi may still filter input, using a throwaway event tap.
//  Ported from Octopus: octopus/UI/Permissions/EventTapTrust.swift
//

import ApplicationServices

////////////////////
//// Real trust check
/// `AXIsProcessTrusted()` keeps answering `true` inside a running app after the user removes
/// it from the Accessibility list, so it cannot be the only check.
/// Creating a throwaway active tap is checked by the window server on every call:
/// it returns nil as soon as the grant is gone.
// The probe is disabled and invalidated at once and is never added to a run loop.

enum EventTapTrust {
    static func isGranted() -> Bool {
        guard AXIsProcessTrusted() else { return false }
        let mask = CGEventMask(1) << CGEventType.keyDown.rawValue
        guard let probe = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .tailAppendEventTap,
            options: .defaultTap, eventsOfInterest: mask,
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) }, userInfo: nil) else { return false }
        CGEvent.tapEnable(tap: probe, enable: false)
        CFMachPortInvalidate(probe)
        return true
    }
}

//// Safe to call from any thread: it touches no MacJi state.
//////////////////
