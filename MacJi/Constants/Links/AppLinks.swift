//
//  AppLinks.swift
//  MacJi
//
//  Created: 2026-11-26
//  External URLs: the project, its issues, the feedback inbox, Octopus, the licence and the System
//  Settings panes MacJi opens.
//  The update feed URL lives in Info.plist (SUFeedURL) because Sparkle reads it from there.
//

import Foundation

////////////////////
//// Links
/// Each is a compile-time constant literal, so the force unwrap can only fail on a typo,
// which the first launch of any build exposes immediately.

enum AppLinks {
    static let repository = URL(string: "https://github.com/mayank-devac/MacJi")!
    static let releases = URL(string: "https://github.com/mayank-devac/MacJi/releases")!
    static let licence = URL(string: "https://github.com/mayank-devac/MacJi/blob/main/LICENSE")!
    static let privacy = URL(string: "https://github.com/mayank-devac/MacJi/blob/main/PRIVACY.md")!
    static let newIssue = URL(string: "https://github.com/mayank-devac/MacJi/issues/new")!
    /// Gmail's compose page, for Send Email when the email reader is a browser.
    static let gmailCompose = URL(string: "https://mail.google.com/mail/")!
    /// Any web page: the apps that open it are the browsers.
    static let webProbe = URL(string: "https://example.com")!
    static let octopus = URL(string: "https://github.com/mayank-devac/octopus-mac")!
    static let accessibilitySettings = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    static let systemSettingsBundleID = "com.apple.systempreferences"
    /// The project's own inbox, for feedback and security reports without a GitHub account.
    static let feedbackEmail = "macji.app@proton.me"
}

//////////////////
