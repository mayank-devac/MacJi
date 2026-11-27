//
//  FeedbackSheet.swift
//  MacJi
//
//  Created: 2026-11-27
//  The Send Feedback sheet: kind, message, optional technical details, a preview of what is
//  sent.
//

import SwiftUI

struct FeedbackSheet: View {
    @Binding var kind: FeedbackKind
    @Binding var message: String
    @Binding var includesDetails: Bool
    let details: FeedbackDetails
    let emailAddress: String
    let newIssue: URL
    /// Called once a mail draft or issue form opened, so the draft can be cleared.
    let onSent: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var openFailed = false

    private var report: FeedbackReport {
        FeedbackReport(kind: kind, message: message, details: includesDetails ? details : nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(FeedbackStrings.title)
                .font(.headline)
                .padding(.top, SettingsMetrics.pageHeaderPadding)
            Form {
                messageSection
                previewSection
            }
            .formStyle(.grouped)
            Divider()
            buttons
        }
        .frame(width: SettingsMetrics.feedbackWidth, height: SettingsMetrics.feedbackHeight)
        .onChange(of: message) { _, new in
            if new.count > Limits.feedbackMaxLength { message = String(new.prefix(Limits.feedbackMaxLength)) }
        }
    }

    private var messageSection: some View {
        Section {
            Picker(FeedbackStrings.kindLabel, selection: $kind) {
                ForEach(FeedbackKind.allCases) { Text(FeedbackStrings.kindTitle($0)).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            TextEditor(text: $message)
                .font(.body)
                .frame(height: SettingsMetrics.feedbackEditorHeight)
                .overlay(alignment: .topLeading) {
                    if message.isEmpty {
                        Text(FeedbackStrings.placeholder(kind))
                            .foregroundStyle(.tertiary)
                            .padding(.leading, SettingsMetrics.feedbackPlaceholderInset)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel(FeedbackStrings.messageHeader)
            Text(FeedbackStrings.characterCount(message.count, of: Limits.feedbackMaxLength))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        } header: {
            Text(FeedbackStrings.messageHeader)
        }
    }

    ////////////////////
    //// What will be sent
    /// Shows exactly what the email or issue will contain before anything opens, and how each
    /// route treats the sender, so nobody sends more than they meant to.
    // The technical details are listed under their checkbox only while it is ticked.

    private var previewSection: some View {
        Section {
            Text(FeedbackStrings.previewMessage)
            VStack(alignment: .leading, spacing: SettingsMetrics.rowSpacing) {
                Toggle(FeedbackStrings.includeDetails, isOn: $includesDetails)
                    .toggleStyle(.checkbox)
                if includesDetails {
                    Grid(alignment: .leading, horizontalSpacing: SettingsMetrics.aliasSpacing,
                         verticalSpacing: SettingsMetrics.rowSpacing) {
                        ForEach(details.rows) { row in
                            GridRow {
                                Text(row.label).foregroundStyle(.secondary)
                                Text(row.value)
                            }
                        }
                    }
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                }
            }
            VStack(alignment: .leading, spacing: SettingsMetrics.rowSpacing) {
                SettingsHint(text: FeedbackStrings.anonymousNote)
                SettingsHint(text: FeedbackStrings.emailNote(emailAddress))
                SettingsHint(text: FeedbackStrings.gitHubNote)
                if openFailed {
                    SettingsHint(text: FeedbackStrings.openFailed(emailAddress),
                                 symbol: SymbolNames.attention, tint: Palette.attention)
                }
            }
            .textSelection(.enabled)
        } header: {
            Text(FeedbackStrings.previewHeader)
        }
    }

    //////////////////

    private var buttons: some View {
        HStack {
            Button(FeedbackStrings.cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Spacer()
            Group {
                Button(FeedbackStrings.openGitHub) { open(report.issueURL(newIssue: newIssue)) }
                Button(FeedbackStrings.sendEmail) { open(report.emailURL(to: emailAddress)) }
                    .keyboardShortcut(.defaultAction)
            }
            .disabled(!report.hasMessage)
        }
        .padding(SettingsMetrics.pageHeaderPadding)
    }

    //// Keep the sheet and the text when nothing opened the link, and say where to write instead.
    private func open(_ url: URL?) {
        guard let url else {
            openFailed = true
            return
        }
        openURL(url) { accepted in
            openFailed = !accepted
            guard accepted else { return }
            onSent()
            dismiss()
        }
    }
}
