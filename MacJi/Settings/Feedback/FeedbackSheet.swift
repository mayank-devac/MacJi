//
//  FeedbackSheet.swift
//  MacJi
//
//  Created: 2026-11-27
//  The Send Feedback sheet: kind, message, optional technical details, a preview of what is
//  sent.
//

import AppKit
import SwiftUI

struct FeedbackSheet: View {
    @Binding var kind: FeedbackKind
    @Binding var message: String
    @Binding var includesDetails: Bool
    let details: FeedbackDetails
    let emailAddress: String
    let newIssue: URL
    /// Called when the user closes the sheet with Done after sending, so the draft can be cleared.
    let onSent: () -> Void

    ////////////////////
    //// After Send Email or Open on GitHub
    /// An app taking the link proves nothing about the draft: a browser set as the mail app can
    /// open an empty page. So the sheet never clears or closes itself; it says where the link
    /// went and offers the message to copy.

    enum Outcome: Equatable {
        case none
        case opened(in: String)
        case failed
    }

    //////////////////

    @Environment(\.dismiss) private var dismiss
    @State private var outcome = Outcome.none
    @State private var copied = false

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
            copied = false
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
                ForEach([FeedbackStrings.anonymousNote, FeedbackStrings.emailNote(emailAddress),
                         FeedbackStrings.gitHubNote], id: \.self) { note in
                    HStack(alignment: .firstTextBaseline, spacing: SettingsMetrics.feedbackBulletSpacing) {
                        Text(FeedbackStrings.bullet)
                        Text(note).fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                switch outcome {
                case .none:
                    EmptyView()
                case .opened(let app):
                    SettingsHint(text: FeedbackStrings.opened(in: app), symbol: SymbolNames.granted)
                case .failed:
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
            if outcome == .none {
                Button(FeedbackStrings.cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            } else {
                Button(FeedbackStrings.done) {
                    onSent()
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button(copied ? FeedbackStrings.copied : FeedbackStrings.copyMessage) { copyMessage() }
                    .disabled(!report.hasMessage)
            }
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

    ////////////////////
    //// Open the draft
    /// Name the app that took the link, so a browser set as the mail app is no surprise, and keep
    /// the text either way.
    // NSWorkspace answers synchronously on the main actor. SwiftUI's openURL calls its completion
    // on a LaunchServices queue, which trips Swift 6's main-actor check and crashes the app.

    private func open(_ url: URL?) {
        guard let url, NSWorkspace.shared.open(url) else {
            outcome = .failed
            return
        }
        let app = NSWorkspace.shared.urlForApplication(toOpen: url)
            .map { FileManager.default.displayName(atPath: $0.path) }
        outcome = .opened(in: app ?? FeedbackStrings.unknownApp)
    }

    //// The message with any technical details, exactly as the draft carries it.
    private func copyMessage() {
        NSPasteboard.general.clearContents()
        copied = NSPasteboard.general.setString(report.body, forType: .string)
    }

    //////////////////
}
