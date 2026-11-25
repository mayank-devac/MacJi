//
//  InlineInputMonitor.swift
//  MacJi
//
//  Created: 2026-11-26
//  Session event tap that sees every key typed in other apps. It reports key-downs to the
//  controller, which may consume them while the panel is open; the matching key-up is
//  consumed too so apps never see half a press.
//  Ported from Octopus: octopus/UI/MacJi/MacJiInputMonitor.swift
//

import AppKit

@MainActor
final class InlineInputMonitor {
    /// Return true to keep the key from the app.
    var onKeyDown: (_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags, _ characters: String) -> Bool = { _, _, _ in false }
    /// The tap was disabled by macOS; any typed-text state is now stale.
    var onInterrupted: () -> Void = {}

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var consumedKeyUps: Set<UInt16> = []

    var isRunning: Bool { tap != nil }

    ////////////////////
    //// Install and remove the tap
    /// The tap only exists while the inline panel is on and Accessibility is granted, and it
    /// registers with EventTapPermissionWatch so a revoked grant can never leave it blocking keys.

    func start() -> Bool {
        if tap != nil { return true }
        guard AXIsProcessTrusted() else { return false }
        let mask = (CGEventMask(1) << CGEventType.keyDown.rawValue) | (CGEventMask(1) << CGEventType.keyUp.rawValue)
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                let consume = MainActor.assumeIsolated {
                    Unmanaged<InlineInputMonitor>.fromOpaque(context).takeUnretainedValue().shouldConsume(type, event: event)
                }
                return consume ? nil : Unmanaged.passUnretained(event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            Log.inlinePanel.error("Event tap could not be created")
            return false
        }
        guard let source = CFMachPortCreateRunLoopSource(nil, tap, 0) else {
            CFMachPortInvalidate(tap)
            return false
        }
        self.tap = tap
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        EventTapPermissionWatch.shared.tapInstalled(by: self) { [weak self] in self?.stop() }
        return true
    }

    func stop() {
        consumedKeyUps = []
        EventTapPermissionWatch.shared.tapRemoved(by: self)
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        tap = nil
        source = nil
    }

    //////////////////

    ////////////////////
    //// Tap callback
    /// MacJi's own synthetic keys (the emoji insert) pass untouched. No AX reads or window
    /// work run here; the controller queues panel work for the next main-queue turn.
    // Characters come from the event itself, so the active keyboard layout is respected.

    /// True keeps the event from the app.
    private func shouldConsume(_ type: CGEventType, event: CGEvent) -> Bool {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            consumedKeyUps = []
            onInterrupted()
            // An untrusted tap blocks keys system-wide, so re-enable only once trust is confirmed.
            EventTapPermissionWatch.shared.tapDisabled { [weak self] in
                if let tap = self?.tap { CGEvent.tapEnable(tap: tap, enable: true) }
            }
            return false
        }
        guard event.getIntegerValueField(.eventSourceUserData) != TextInserter.syntheticMarker else { return false }
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        if type == .keyUp { return consumedKeyUps.remove(keyCode) != nil }
        guard type == .keyDown else { return false }
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(event.flags.rawValue))
        guard onKeyDown(keyCode, modifiers, Self.characters(of: event)) else { return false }
        consumedKeyUps.insert(keyCode)
        return true
    }

    private static func characters(of event: CGEvent) -> String {
        var length = 0
        var buffer = [UniChar](repeating: 0, count: 8)
        event.keyboardGetUnicodeString(maxStringLength: buffer.count, actualStringLength: &length, unicodeString: &buffer)
        return String(utf16CodeUnits: buffer, count: min(length, buffer.count))
    }

    //// Unhandled keys always pass through, so a slow handler never eats typing.
    //////////////////
}
