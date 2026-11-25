//
//  Log.swift
//  MacJi
//
//  Created: 2026-11-26
//  os.Logger categories for developer diagnostics. Never use print.
//

import Foundation
import os

////////////////////
//// Diagnostics
/// View with Console.app or `log stream --predicate 'subsystem BEGINSWITH "io.github.mayank-devac.macji"'`.
// Never log typed characters, search terms or anything else the user types.

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "io.github.mayank-devac.macji"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let emojiData = Logger(subsystem: subsystem, category: "emoji-data")
    static let inlinePanel = Logger(subsystem: subsystem, category: "inline-panel")
    static let picker = Logger(subsystem: subsystem, category: "picker")
    static let permissions = Logger(subsystem: subsystem, category: "permissions")
    static let settings = Logger(subsystem: subsystem, category: "settings")
    static let updates = Logger(subsystem: subsystem, category: "updates")
}

//// Logger is Sendable, so these statics are safe from any thread.
//////////////////
