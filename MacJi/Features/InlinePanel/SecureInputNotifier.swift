//
//  SecureInputNotifier.swift
//  MacJi
//
//  Created: 2026-11-26
//  Posts a notification when a background app holds Secure Input and so silently blocks
//  the inline panel. Checked on app switches; each holder is reported once.
//  Ported from Octopus: octopus/UI/MacJi/MacJiSecureInputNotifier.swift
//

import AppKit
import UserNotifications

@MainActor
final class SecureInputNotifier {
    private static let notificationID = "macji.secureInput"
    private var notifiedPID: pid_t?

    ////////////////////
    //// Check after an app switch
    /// The frontmost app holding Secure Input is normal (a password field in use), so only a
    /// holder in the background is reported.

    func check(frontmostPID: pid_t?) {
        guard let holder = SecureInput.holder() else {
            notifiedPID = nil
            return
        }
        guard holder.pid != frontmostPID, holder.pid != notifiedPID else { return }
        notifiedPID = holder.pid
        post(for: holder)
    }

    //// Clearing the holder re-arms the notification for the next time it happens.
    //////////////////

    private func post(for holder: SecureInputHolder) {
        let content = UNMutableNotificationContent()
        content.title = PermissionStrings.pausedTitle
        content.body = "\(PermissionStrings.blocking(holder.name)) \(holder.turnOffSteps)"
        let request = UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: nil)
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                guard try await center.requestAuthorization(options: [.alert]) else { return }
                try await center.add(request)
            } catch {
                Log.inlinePanel.error("Secure Input notification failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
