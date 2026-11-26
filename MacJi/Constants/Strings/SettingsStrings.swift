//
//  SettingsStrings.swift
//  MacJi
//
//  Created: 2026-11-26
//  User-visible text of the Settings window, one block per section.
//

import Foundation

enum SettingsStrings {
    static let windowTitle = String(localized: "MacJi Settings")
    static let menuItem = String(localized: "Settings…")

    ////////////////////
    //// Permissions

    static let accessibilityTitle = String(localized: "Accessibility access")
    static let accessibilityGranted = String(localized: "Granted. The inline panel can see the trigger and insert emoji.")
    static let accessibilityMissing = String(localized: "Needed for the inline panel: MacJi watches for the trigger and types the emoji for you. Keystrokes are never stored or sent.")
    static let grantAccess = String(localized: "Grant Access…")
    static let secureInputTitle = String(localized: "Secure Input is on")

    //////////////////

    ////////////////////
    //// Emoji Picker

    static let pickerHeader = String(localized: "Emoji Picker")
    static let shortcutLabel = String(localized: "Open picker:")
    static let resetShortcut = String(localized: "Reset to Default")
    static let pickerFooter = String(localized: "Opens the picker from any app. Return copies the emoji, Option-Return copies and keeps the picker open.")

    //////////////////

    ////////////////////
    //// Inline Panel

    static let inlineHeader = String(localized: "Inline Panel")
    static let inlineToggle = String(localized: "Open emoji panel while typing")
    static let triggerLabel = String(localized: "Trigger")
    static let rankFrequentlyUsed = String(localized: "Rank frequently used emoji higher")
    static let aliasesToggle = String(localized: "Aliases")
    static let aliasesExample = String(localized: "-> becomes →, (c) becomes ©, :) becomes 🙂")
    static let customizeAliases = String(localized: "Customize…")
    static let triggerErrorEmpty = String(localized: "Type at least one character.")
    static let triggerErrorWhitespace = String(localized: "Spaces aren't allowed.")
    static let triggerErrorOnlyLetters = String(localized: "Include a symbol such as : or ; so the trigger never fires inside words.")
    static let inlineOffFooter = String(localized: "Turned off: MacJi stops watching the keyboard entirely.")

    static func triggerErrorTooLong(_ limit: Int) -> String {
        String(localized: "Use \(limit) characters or fewer.")
    }

    static func triggerKeptHint(_ trigger: String) -> String {
        String(localized: "Still using \(trigger)")
    }

    static func inlineExample(trigger: String) -> String {
        String(localized: "Type \(trigger)rocket in any app, then Return inserts 🚀. Shift-Return copies, esc closes.")
    }

    //////////////////

    ////////////////////
    //// Aliases page

    static let aliasesBack = String(localized: "Inline Panel")
    static let aliasesTitle = String(localized: "Aliases")
    static let aliasesArrows = String(localized: "Arrows")
    static let aliasesMath = String(localized: "Math")
    static let aliasesSymbols = String(localized: "Symbols")
    static let aliasesEmoticons = String(localized: "Emoticons")
    static let aliasesEmoticonsFooter = String(localized: "Symbols in brackets and emoticons convert only at the start of a word, so \"note:)\" and the trigger stay as typed.")
    static let aliasesFooter = String(localized: "An alias converts as you type its last character, in every app. Turn off any you type in code, such as -> or !=.")
    static let turnAllOn = String(localized: "Turn All On")

    //////////////////

    ////////////////////
    //// Menu Bar

    static let menuBarHeader = String(localized: "Menu Bar")
    static let showMenuBarIcon = String(localized: "Show MacJi in the menu bar")
    static let hiddenIconHint = String(localized: "Hidden: open MacJi again from Applications or Spotlight to get back here. The picker shortcut still works.")
    static let menuBarFooter = String(localized: "Click the icon for the picker; right-click for Settings and updates.")

    //////////////////

    ////////////////////
    //// General

    static let generalHeader = String(localized: "General")
    static let openAtLogin = String(localized: "Open at login")
    static let loginNeedsApproval = String(localized: "Waiting for your approval in System Settings › General › Login Items.")
    static let openLoginItems = String(localized: "Open Login Items…")
    static let automaticUpdates = String(localized: "Check for updates automatically")
    static let checkNow = String(localized: "Check Now")
    static let neverChecked = String(localized: "Not checked yet")

    static func loginError(_ detail: String) -> String {
        String(localized: "Couldn't change the login item: \(detail)")
    }

    static func lastChecked(_ relative: String) -> String {
        String(localized: "Last checked \(relative)")
    }

    //////////////////

    ////////////////////
    //// About

    static let aboutHeader = String(localized: "About")
    static let tagline = String(localized: "Emoji anywhere you type.")
    static let github = String(localized: "GitHub")
    static let builtOnOctopus = String(localized: "Built on Octopus")
    static let licence = String(localized: "MIT Licence")
    static let privacy = String(localized: "Privacy")

    static func version(_ version: String, build: String) -> String {
        String(localized: "Version \(version) (\(build))")
    }

    //////////////////
}
