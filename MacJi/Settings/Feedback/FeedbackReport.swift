//
//  FeedbackReport.swift
//  MacJi
//
//  Created: 2026-11-27
//  What a user writes in Send Feedback, as an email draft, a Gmail draft or a prefilled GitHub
//  issue.
//

import Foundation

enum FeedbackKind: String, CaseIterable, Identifiable, Sendable {
    case bug, feature, other

    var id: Self { self }
}

struct FeedbackReport: Equatable, Sendable {
    let kind: FeedbackKind
    let message: String
    /// nil unless the user ticked Include technical details.
    let details: FeedbackDetails?

    ////////////////////
    //// GitHub issue forms
    /// Template file names and field ids in .github/ISSUE_TEMPLATE. GitHub fills a field whose id
    /// matches a query name, so these must never drift from the forms (FeedbackReportTests).

    enum IssueForm {
        static let bugTemplate = "bug_report.yml"
        static let featureTemplate = "feature_request.yml"
        static let whatHappened = "what-happened"
        static let version = "version"
        static let macOS = "macos"
        static let problem = "problem"
    }

    //////////////////

    ////////////////////
    //// Gmail compose
    /// Query names of mail.google.com/mail/?view=cm, which opens a filled-in draft.

    enum GmailCompose {
        static let view = "view"
        static let compose = "cm"
        static let fullScreen = "fs"
        static let on = "1"
        static let to = "to"
        static let subject = "su"
        static let body = "body"
    }

    //////////////////

    var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasMessage: Bool { !trimmedMessage.isEmpty }

    var subject: String { FeedbackStrings.subject(kind) }

    /// The message, then the technical details under a rule when the user included them.
    var body: String {
        guard let details else { return trimmedMessage }
        return "\(trimmedMessage)\n\n---\n\(details.summary)"
    }

    func emailURL(to address: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = address
        return Self.url(components, query: [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ])
    }

    func gmailURL(to address: String, compose: URL) -> URL? {
        guard let components = URLComponents(url: compose, resolvingAgainstBaseURL: false) else { return nil }
        return Self.url(components, query: [
            URLQueryItem(name: GmailCompose.view, value: GmailCompose.compose),
            URLQueryItem(name: GmailCompose.fullScreen, value: GmailCompose.on),
            URLQueryItem(name: GmailCompose.to, value: address),
            URLQueryItem(name: GmailCompose.subject, value: subject),
            URLQueryItem(name: GmailCompose.body, value: body),
        ])
    }

    ////////////////////
    //// Prefilled GitHub issue
    /// A bug fills the bug form's message and version fields; its Accessibility and Secure Input
    /// dropdowns ask the same questions on the form. A feature idea fills the feature form.
    // Other opens a blank issue, which config.yml keeps enabled.

    func issueURL(newIssue: URL) -> URL? {
        guard let components = URLComponents(url: newIssue, resolvingAgainstBaseURL: false) else { return nil }
        return Self.url(components, query: issueQuery)
    }

    var issueQuery: [URLQueryItem] {
        switch kind {
        case .bug:
            var items = [URLQueryItem(name: "template", value: IssueForm.bugTemplate),
                         URLQueryItem(name: IssueForm.whatHappened, value: trimmedMessage)]
            if let details {
                items += [URLQueryItem(name: IssueForm.version, value: details.appVersion),
                          URLQueryItem(name: IssueForm.macOS, value: details.macOSVersion)]
            }
            return items
        case .feature:
            return [URLQueryItem(name: "template", value: IssueForm.featureTemplate),
                    URLQueryItem(name: IssueForm.problem, value: body)]
        case .other:
            return [URLQueryItem(name: "body", value: body)]
        }
    }

    //// URLComponents leaves "+" as is, and GitHub reads a bare "+" in a query as a space.
    private static func url(_ components: URLComponents, query: [URLQueryItem]) -> URL? {
        var components = components
        components.queryItems = query
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.url
    }

    //////////////////
}
