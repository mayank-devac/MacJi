//
//  SettingsWindowController.swift
//  MacJi
//
//  Created: 2026-11-26
//  The Settings window: created once, fixed width and resizable height, remembers its
//  position, and comes to the front even though MacJi has no Dock icon.
//

import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {
    private let makeContent: () -> AnyView
    private var window: NSWindow?

    init(content: @escaping () -> some View) {
        makeContent = { AnyView(content()) }
    }

    ////////////////////
    //// Show
    /// An accessory app must activate itself, or the window opens behind the frontmost app.
    /// The window opens on the current Space instead of jumping to the one it was last on.

    func show() {
        let window = self.window ?? makeWindow()
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    //////////////////

    private func makeWindow() -> NSWindow {
        let host = NSHostingController(rootView: makeContent())
        host.sizingOptions = []
        let window = NSWindow(contentViewController: host)
        window.title = SettingsStrings.windowTitle
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.collectionBehavior = [.moveToActiveSpace]
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: SettingsMetrics.width, height: SettingsMetrics.minHeight)
        window.contentMaxSize = NSSize(width: SettingsMetrics.width, height: SettingsMetrics.maxHeight)
        window.setContentSize(NSSize(width: SettingsMetrics.width, height: SettingsMetrics.initialHeight))
        if !window.setFrameUsingName(PreferenceKeys.settingsWindowAutosave) { window.center() }
        window.setFrameAutosaveName(PreferenceKeys.settingsWindowAutosave)
        self.window = window
        return window
    }
}
