//
//  AboutSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  App icon, version and build, and links to GitHub, Octopus, the licence and privacy notes.
//

import SwiftUI

struct AboutSection: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    private let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "–"

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
    }
}
