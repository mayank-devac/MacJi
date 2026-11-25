//
//  MacJiApp.swift
//  MacJi
//
//  Created: 2026-11-26
//  SwiftUI entry point. All real work starts in AppDelegate, the composition root.
//  Ported from Octopus: octopus/octopusApp.swift
//

import SwiftUI

////////////////////
//// App
/// The SwiftUI Settings scene is left empty because it cannot be opened from code on macOS 14;
/// ⌘, is routed to MacJi's own Settings window instead.

@main
struct MacJiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button(SettingsStrings.menuItem) { appDelegate.showSettings() }
                        .keyboardShortcut(",")
                }
            }
    }
}

//////////////////
