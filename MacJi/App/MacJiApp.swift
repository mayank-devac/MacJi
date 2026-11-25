//
//  MacJiApp.swift
//  MacJi
//
//  Created: 2026-11-26
//  SwiftUI entry point. All real work starts in AppDelegate, the composition root.
//

import SwiftUI

@main
struct MacJiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
