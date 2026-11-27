//
//  FeedbackStrings.swift
//  MacJi
//
//  Created: 2026-11-27
//  User-visible text of the Send Feedback sheet and the reports it builds.
//

import Foundation

enum FeedbackStrings {
    ////////////////////
    //// The sheet

    static let button = String(localized: "Send Feedback…")
    static let title = String(localized: "Send Feedback")
    static let cancel = String(localized: "Cancel")
    static let done = String(localized: "Done")
    static let copyMessage = String(localized: "Copy Message")
    static let copied = String(localized: "Copied")
    static let unknownApp = String(localized: "another app")
    static let kindLabel = String(localized: "Kind")
    static let messageHeader = String(localized: "What would you like to share?")
    static let includeDetails = String(localized: "Include technical details")
    static let sendEmail = String(localized: "Send Email…")
    static let openGitHub = String(localized: "Open on GitHub…")

    static func kindTitle(_ kind: FeedbackKind) -> String {
        switch kind {
        case .bug: String(localized: "Bug")
        case .feature: String(localized: "Feature Idea")
        case .other: String(localized: "Other")
        }
    }

    static func placeholder(_ kind: FeedbackKind) -> String {
        switch kind {
        case .bug: String(localized: "Tell me what happened, what you expected, and which app you were typing in.")
        case .feature: String(localized: "Describe the idea and how it would help.")
        case .other: String(localized: "Questions, thanks, anything else.")
        }
    }

    static func characterCount(_ count: Int, of limit: Int) -> String {
        String(localized: "\(count) of \(limit) characters")
    }

    static func openFailed(_ address: String) -> String {
        String(localized: "No app opened the link. Copy the message and write to \(address) instead.")
    }

    static func opened(in app: String) -> String {
        String(localized: "Opened in \(app). If your message isn't there, copy it and paste it in. Your text stays here until you press Done.")
    }

    //////////////////

    ////////////////////
    //// What will be sent

    static let previewHeader = String(localized: "What will be sent")
    static let previewMessage = String(localized: "The kind and your message.")
    static let bullet = "•"
    static let anonymousNote = String(localized: "MacJi adds no name, device identifier, logs, keystrokes, settings or clipboard content. Nothing leaves your Mac until you send it yourself.")
    static func emailNote(_ address: String) -> String {
        String(localized: "Email opens a draft to \(address) in your mail app. No account needed; only the developer sees your message and your email address.")
    }
    static let gitHubNote = String(localized: "GitHub opens a public issue form, filled in. It needs a free GitHub account and shows your username.")

    //////////////////

    ////////////////////
    //// The report

    static func subject(_ kind: FeedbackKind) -> String {
        switch kind {
        case .bug: String(localized: "MacJi bug report")
        case .feature: String(localized: "MacJi feature idea")
        case .other: String(localized: "MacJi feedback")
        }
    }

    static let macOSLabel = "macOS"
    static let accessibilityLabel = String(localized: "Accessibility")
    static let secureInputLabel = String(localized: "Secure Input")
    static let granted = String(localized: "Granted")
    static let notGranted = String(localized: "Not granted")
    static let on = String(localized: "On")
    static let off = String(localized: "Off")

    //////////////////
}
