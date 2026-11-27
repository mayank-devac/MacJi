//
//  FeedbackDetails.swift
//  MacJi
//
//  Created: 2026-11-27
//  The few anonymous technical details a feedback report may carry: versions and permission
//  state.
//

import Foundation

////////////////////
//// Only what explains most MacJi bugs
/// Versions say which code ran; Accessibility and Secure Input explain most "the panel never
/// opens" reports. Nothing here identifies the user or the Mac: no model, serial, locale,
/// app names, settings or logs.

struct FeedbackDetails: Equatable, Sendable {
    struct Row: Identifiable, Equatable, Sendable {
        let label: String
        let value: String
        var id: String { label }
    }

    let appVersion: String
    let macOSVersion: String
    let accessibilityGranted: Bool
    let secureInputOn: Bool

    var rows: [Row] {
        [
            Row(label: SettingsStrings.appName, value: appVersion),
            Row(label: FeedbackStrings.macOSLabel, value: macOSVersion),
            Row(label: FeedbackStrings.accessibilityLabel,
                value: accessibilityGranted ? FeedbackStrings.granted : FeedbackStrings.notGranted),
            Row(label: FeedbackStrings.secureInputLabel,
                value: secureInputOn ? FeedbackStrings.on : FeedbackStrings.off),
        ]
    }

    /// The rows as plain text lines, as they appear in the email or issue.
    var summary: String {
        rows.map { "\($0.label): \($0.value)" }.joined(separator: "\n")
    }

    static func current(appVersion: String, accessibilityGranted: Bool, secureInputOn: Bool) -> FeedbackDetails {
        FeedbackDetails(appVersion: appVersion,
                        macOSVersion: macOSVersion(ProcessInfo.processInfo.operatingSystemVersion),
                        accessibilityGranted: accessibilityGranted,
                        secureInputOn: secureInputOn)
    }

    /// "15.1", or "15.1.2" when there is a patch version.
    static func macOSVersion(_ version: OperatingSystemVersion) -> String {
        let base = "\(version.majorVersion).\(version.minorVersion)"
        return version.patchVersion > 0 ? "\(base).\(version.patchVersion)" : base
    }
}

//// Add a row only when a real report needed it, and keep it anonymous.
//////////////////
