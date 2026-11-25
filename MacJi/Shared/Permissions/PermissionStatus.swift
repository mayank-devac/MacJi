//
//  PermissionStatus.swift
//  MacJi
//
//  Created: 2026-11-26
//  Observable state of what MacJi may see: the Accessibility grant and the app holding
//  Secure Input. Updated by system notifications, never by a polling timer.
//

import AppKit
import ApplicationServices

@MainActor
final class PermissionStatus: ObservableObject {
    @Published private(set) var accessibilityGranted = AXIsProcessTrusted()
    @Published private(set) var secureInputHolder: SecureInputHolder?

    private var observers: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    ////////////////////
    //// Observe instead of polling
    /// macOS posts "com.apple.accessibility.api" whenever any app's Accessibility grant changes;
    /// the trust value catches up a moment later, so it is re-read after a short delay.
    /// App switches and MacJi becoming active are cheap extra moments to re-read both values
    // (the user usually comes back from System Settings by clicking MacJi's window).

    func start() {
        guard observers.isEmpty else { return }
        observe(DistributedNotificationCenter.default(), Notification.Name("com.apple.accessibility.api")) { status in
            status.refresh()
            Task { @MainActor [weak status] in
                try? await Task.sleep(for: .seconds(Timing.permissionRecheckDelay))
                status?.refresh()
            }
        }
        observe(NSWorkspace.shared.notificationCenter, NSWorkspace.didActivateApplicationNotification) { $0.refresh() }
        observe(NotificationCenter.default, NSApplication.didBecomeActiveNotification) { $0.refresh() }
        refresh()
    }

    func stop() {
        observers.forEach { $0.center.removeObserver($0.token) }
        observers = []
    }

    //// Revocation inside a running app is caught by EventTapPermissionWatch, not here:
    //// AXIsProcessTrusted() keeps returning true after the grant is removed.
    //////////////////

    func refresh() {
        let granted = AXIsProcessTrusted()
        if granted != accessibilityGranted { accessibilityGranted = granted }
        let holder = SecureInput.holder()
        if holder != secureInputHolder { secureInputHolder = holder }
    }

    private func observe(_ center: NotificationCenter, _ name: Notification.Name,
                         _ handler: @escaping @MainActor (PermissionStatus) -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                handler(self)
            }
        }
        observers.append((center, token))
    }
}
