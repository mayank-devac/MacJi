//
//  AppLifecycle.swift
//  MacJi
//
//  Created: 2026-11-26
//  Launch facts and the policy for when MacJi opens Settings by itself.
//

import AppKit
import Carbon

enum AppLifecycle {
    /// Hosted unit tests launch the app; it must then do nothing visible.
    static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil || environment["XCTestBundlePath"] != nil
    }

    ////////////////////
    //// Login-item launch
    /// macOS marks the launch Apple Event of a login item with `keyAELaunchedAsLogInItem`.
    // Read it in applicationWillFinishLaunching, while that event is still the current one.
    // Best effort: if macOS stops sending the marker, MacJi only opens Settings a little more often.

    @MainActor
    static func launchedAsLoginItem() -> Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent, event.eventID == kAEOpenApplication else { return false }
        return event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }

    //////////////////

    ////////////////////
    //// Open Settings at launch?
    /// Always on the first launch. Otherwise, when the user opened MacJi themselves, only if
    /// something needs them: the menu-bar icon is hidden (Settings is the only way back in) or
    /// Accessibility is missing. A login-item launch stays quiet.
    // Reopening a running MacJi (Finder, Spotlight, Launchpad) always opens Settings; see AppDelegate.

    static func shouldOpenSettingsAtLaunch(isFirstLaunch: Bool, menuBarIconShown: Bool,
                                           accessibilityGranted: Bool, launchedAsLoginItem: Bool) -> Bool {
        if isFirstLaunch { return true }
        guard !launchedAsLoginItem else { return false }
        return !menuBarIconShown || !accessibilityGranted
    }

    //////////////////
}
