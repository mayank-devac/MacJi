//
//  FeedbackMailRoute.swift
//  MacJi
//
//  Created: 2026-11-27
//  Where Send Email opens the draft: the mail app, or Gmail when the email reader is a browser.
//

import AppKit

////////////////////
//// Mail app or Gmail
/// A mailto link only becomes a draft in a real mail app. When the email reader is a browser,
/// or there is none, the browser shows nothing useful, so Send Email opens Gmail's compose page,
/// filled in, instead. An app counts as a browser when it also opens web pages; no list of
/// browser names to keep up to date.

enum FeedbackMailRoute: Equatable {
    case mailApp
    case gmail

    static func choose(mailReader: URL?, webBrowsers: [URL]) -> FeedbackMailRoute {
        guard let mailReader else { return .gmail }
        let reader = mailReader.standardizedFileURL
        return webBrowsers.contains { $0.standardizedFileURL == reader } ? .gmail : .mailApp
    }

    @MainActor
    static func current(for mailto: URL, workspace: NSWorkspace = .shared) -> FeedbackMailRoute {
        choose(mailReader: workspace.urlForApplication(toOpen: mailto),
               webBrowsers: workspace.urlsForApplications(toOpen: AppLinks.webProbe))
    }
}

//// Apple Mail, Outlook or Spark set as the email reader always get the plain mailto link.
//////////////////
