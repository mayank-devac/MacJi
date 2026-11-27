//
//  AboutSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  App icon, version and build, Send Feedback, and links to GitHub, Octopus, the licence and
//  privacy notes.
//

import SwiftUI

struct AboutSection: View {
    let accessibilityGranted: Bool
    let secureInputOn: Bool

    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"

    /// The draft lives here, so closing the sheet by accident keeps what was typed.
    @State private var showsFeedback = false
    @State private var feedbackKind = FeedbackKind.bug
    @State private var feedbackMessage = ""
    @State private var includesDetails = false

    var body: some View {
        Section {
            HStack(spacing: SettingsMetrics.aboutSpacing) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: SettingsMetrics.aboutIconSize, height: SettingsMetrics.aboutIconSize)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: SettingsMetrics.rowSpacing) {
                    Text(SettingsStrings.appName).font(.headline)
                    Text(SettingsStrings.version(version, build: build))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Text(SettingsStrings.tagline).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(FeedbackStrings.button) { showsFeedback = true }
            }
            HStack(spacing: SettingsMetrics.linkSpacing) {
                Link(SettingsStrings.github, destination: AppLinks.repository)
                Link(SettingsStrings.builtOnOctopus, destination: AppLinks.octopus)
                Link(SettingsStrings.licence, destination: AppLinks.licence)
                Link(SettingsStrings.privacy, destination: AppLinks.privacy)
            }
            .font(.callout)
        } header: {
            Text(SettingsStrings.aboutHeader)
        }
        .sheet(isPresented: $showsFeedback) {
            FeedbackSheet(kind: $feedbackKind, message: $feedbackMessage, includesDetails: $includesDetails,
                          details: .current(appVersion: "\(version) (\(build))",
                                            accessibilityGranted: accessibilityGranted,
                                            secureInputOn: secureInputOn),
                          emailAddress: AppLinks.feedbackEmail,
                          newIssue: AppLinks.newIssue,
                          onSent: { feedbackMessage = "" })
        }
    }
}
