//
//  FeedbackReportTests.swift
//  MacJiTests
//
//  Created: 2026-11-27
//  Feedback reports carry only what the user chose, survive URL encoding, and match the issue
//  forms and the website's feedback page.
//

import Foundation
import Testing
@testable import MacJi

struct FeedbackReportTests {
    private let details = FeedbackDetails(appVersion: "0.4.0 (5)", macOSVersion: "15.1",
                                          accessibilityGranted: true, secureInputOn: false)
    private let message = "Typed a + b & c = d?\n#2 🚀"

    private func query(_ url: URL?) throws -> [String: String] {
        let components = try #require(url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) })
        return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
    }

    @Test func emailKeepsTheMessageExactlyAndEncodesPlus() throws {
        let url = FeedbackReport(kind: .bug, message: "  \(message)\n", details: nil).emailURL(to: "x@example.com")

        let items = try query(url)
        #expect(url?.scheme == "mailto")
        #expect(url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.path } == "x@example.com")
        #expect(items["body"] == message)
        #expect(items["subject"] == FeedbackStrings.subject(.bug))
        #expect(url?.query?.contains("+") == false)
    }

    @Test func gmailDraftCarriesAddressSubjectAndExactMessage() throws {
        let report = FeedbackReport(kind: .feature, message: message, details: details)
        let url = report.gmailURL(to: "x@example.com", compose: AppLinks.gmailCompose)

        let items = try query(url)
        #expect(url?.host() == AppLinks.gmailCompose.host())
        #expect(items[FeedbackReport.GmailCompose.view] == FeedbackReport.GmailCompose.compose)
        #expect(items[FeedbackReport.GmailCompose.to] == "x@example.com")
        #expect(items[FeedbackReport.GmailCompose.subject] == FeedbackStrings.subject(.feature))
        #expect(items[FeedbackReport.GmailCompose.body] == report.body)
        #expect(url?.query?.contains("+") == false)
    }

    ////////////////////
    //// Mail app or Gmail
    /// A browser set as the email reader shows no draft for a mailto link, so Gmail opens instead.

    @Test func browserOrMissingEmailReaderOpensGmail() {
        let chrome = URL(filePath: "/Applications/Google Chrome.app")
        let mail = URL(filePath: "/System/Applications/Mail.app")
        let browsers = [URL(filePath: "/Applications/Safari.app"), chrome]

        #expect(FeedbackMailRoute.choose(mailReader: chrome, webBrowsers: browsers) == .gmail)
        #expect(FeedbackMailRoute.choose(mailReader: nil, webBrowsers: browsers) == .gmail)
        #expect(FeedbackMailRoute.choose(mailReader: mail, webBrowsers: browsers) == .mailApp)
    }

    //////////////////

    @Test func technicalDetailsAreSentOnlyWhenIncluded() throws {
        let without = FeedbackReport(kind: .bug, message: message, details: nil)
        let with = FeedbackReport(kind: .bug, message: message, details: details)

        #expect(without.body == message)
        #expect(!without.body.contains("15.1"))
        let bare = try query(without.issueURL(newIssue: AppLinks.newIssue))
        #expect(bare[FeedbackReport.IssueForm.version] == nil)
        #expect(bare[FeedbackReport.IssueForm.macOS] == nil)

        #expect(with.body.hasSuffix(details.summary))
        let full = try query(with.issueURL(newIssue: AppLinks.newIssue))
        #expect(full[FeedbackReport.IssueForm.whatHappened] == message)
        #expect(full[FeedbackReport.IssueForm.version] == "0.4.0 (5)")
        #expect(full[FeedbackReport.IssueForm.macOS] == "15.1")
    }

    ////////////////////
    //// The app and the forms agree
    /// GitHub silently ignores a query name with no matching field id, so a renamed id in a form
    /// would stop the prefill without any error. This reads the forms from the checkout.

    private let checkout = URL(filePath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    @Test func prefilledFieldsExistInTheIssueForms() throws {
        let forms = checkout.appending(path: ".github/ISSUE_TEMPLATE")
        let bug = try String(contentsOf: forms.appending(path: FeedbackReport.IssueForm.bugTemplate), encoding: .utf8)
        let feature = try String(contentsOf: forms.appending(path: FeedbackReport.IssueForm.featureTemplate), encoding: .utf8)

        for id in [FeedbackReport.IssueForm.whatHappened, FeedbackReport.IssueForm.version, FeedbackReport.IssueForm.macOS] {
            #expect(bug.contains("id: \(id)\n"), "bug_report.yml has no field \(id)")
        }
        #expect(feature.contains("id: \(FeedbackReport.IssueForm.problem)\n"))
    }

    //// The website's feedback page prefills the same forms, so it must use the same names.
    @Test func websitePrefillsTheSameFields() throws {
        let script = try String(contentsOf: checkout.appending(path: "WEB/js/feedback.js"), encoding: .utf8)

        for name in [FeedbackReport.IssueForm.bugTemplate, FeedbackReport.IssueForm.featureTemplate,
                     FeedbackReport.IssueForm.whatHappened, FeedbackReport.IssueForm.problem] {
            #expect(script.contains("\"\(name)\""), "WEB/js/feedback.js doesn't use \(name)")
        }
    }

    //////////////////
}
