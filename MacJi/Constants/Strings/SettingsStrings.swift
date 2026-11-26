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
    static let pickerSymbolsTab = String(localized: "Symbols tab")
    static let pickerEmoticonsTab = String(localized: "Emoticons tab")
    static let shortcutLabel = String(localized: "Open picker:")
    static let resetShortcut = String(localized: "Reset to Default")
    static let pickerFooter = String(localized: "Opens the picker from any app. Return copies the emoji, Option-Return copies and keeps the picker open.")

    //////////////////

    ////////////////////
    //// Inline Panels and triggers

    static let inlineHeader = String(localized: "Inline Panels")
    static let inlineToggle = String(localized: "Emoji panel")
    static let symbolToggle = String(localized: "Symbol panel")
    static let triggerLabel = String(localized: "Trigger")
    static let rankFrequentlyUsed = String(localized: "Rank frequently used first")
    static let allTypingOffFooter = String(localized: "Panels, emoticons and aliases are all off: MacJi doesn't watch the keyboard at all.")

    static func symbolExample(trigger: String) -> String {
        String(localized: "Type \(trigger)arrow for → ← ↔, \(trigger)euro for €. Tab changes the category.")
    }

    static let triggerErrorEmpty = String(localized: "Type at least one character.")
    static let triggerErrorWhitespace = String(localized: "Spaces aren't allowed.")
    static let triggerErrorOnlyLetters = String(localized: "Include a symbol such as : or ; so the trigger never fires inside words.")

    static func triggerErrorTooLong(_ limit: Int) -> String {
        String(localized: "Use \(limit) characters or fewer.")
    }

    static func triggerErrorOverlaps(_ panel: String, trigger: String) -> String {
        String(localized: "The \(panel) already uses \(trigger); pick characters that don't contain it.")
    }

    static let emojiPanelName = String(localized: "emoji panel")
    static let symbolPanelName = String(localized: "symbol panel")
    static let emoticonPanelName = String(localized: "emoticon panel")

    static func triggerKeptHint(_ trigger: String) -> String {
        String(localized: "Still using \(trigger)")
    }

    static func inlineExample(trigger: String) -> String {
        String(localized: "Type \(trigger)rocket in any app, then Return inserts 🚀. Shift-Return copies, esc closes.")
    }

    //////////////////

    ////////////////////
    //// Emoticons

    static let emoticonsHeader = String(localized: "Emoticons")
    static let emoticonsToggle = String(localized: "Emoticons")
    static let emoticonsExample = String(localized: "Suggests ^_^ and (^_^;) as you type ^_, and o_O as you type o_.")
    static let autocompleteLabel = String(localized: "Suggest as you type")
    static let autocompleteOff = String(localized: "Off")
    static let emoticonTriggerPlaceholder = String(localized: "None")
    static let emoticonTriggerHint = String(localized: "Optional. Set one, such as ;;, to search emoticons by name: ;;shrug.")

    static func autocompleteAfter(_ count: Int) -> String {
        String(localized: "After \(count) characters")
    }

    //////////////////

    ////////////////////
    //// Aliases section

    static let aliasesHeader = String(localized: "Aliases")
    static let aliasesToggle = String(localized: "Convert as you type")
    static let aliasesExample = String(localized: "Replace text spellings with symbols or emoji while typing")
    static let customizeAliases = String(localized: "Customize…")
    static let aliasesInSearch = String(localized: "Show your aliases in search")
    static let aliasesInSearchExample = String(localized: "Find their outputs by name in every panel and the picker: ::check gives ✓ ✔ ☑.")

    //////////////////

    ////////////////////
    //// Menu Bar

    static let menuBarHeader = String(localized: "Menu Bar")
    static let showMenuBarIcon = String(localized: "Show MacJi in the menu bar")
    static let hiddenIconHint = String(localized: "Hidden: open MacJi again from Applications or Spotlight to get back here. The picker shortcut still works.")
    static let menuBarFooter = String(localized: "Click the icon for the picker; right-click for Settings and updates.")

    //////////////////

    ////////////////////
    //// Open at login and updates

    static let updatesHeader = String(localized: "Updates")
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
    static let appName = "MacJi"
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
