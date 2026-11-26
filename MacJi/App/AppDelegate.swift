//
//  AppDelegate.swift
//  MacJi
//
//  Created: 2026-11-26
//  Composition root: creates every controller, wires them together with closures and
//  AppSettings publishers, and mirrors start/stop. Features never reference each other.
//  Ported from Octopus: octopus/octopusApp.swift
//

import AppKit
import Combine
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    ////////////////////
    //// Parts
    /// Anything that reads settings is lazy, so it is first built after the migrations and
    // default registration in applicationWillFinishLaunching.

    private lazy var settings = AppSettings(defaults: .standard)
    private lazy var recents = GlyphRecents(defaults: .standard)
    private lazy var inlinePanel = InlinePanelController(recents: recents)
    private lazy var picker = EmojiPickerController(recents: recents)
    private let permissions = PermissionStatus()
    private let loginItem = LoginItem()
    private let updates = UpdateController()
    private let statusItem = StatusItemController()
    private lazy var settingsWindow = SettingsWindowController { [unowned self] in
        SettingsView(settings: settings, permissions: permissions, loginItem: loginItem, updates: updates,
                     onGrantAccess: { AccessibilityPermissionGuide.shared.open() },
                     onQuit: { NSApp.terminate(nil) })
    }
    private var subscriptions: Set<AnyCancellable> = []
    private var launchedAsLoginItem = false

    //////////////////

    func applicationWillFinishLaunching(_ notification: Notification) {
        launchedAsLoginItem = AppLifecycle.launchedAsLoginItem()
        SettingsMigrator.migrate(.standard)
        AppSettings.registerDefaults(in: .standard)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !AppLifecycle.isRunningTests else { return }
        startFeatures()
        wireSettings()
        loadCatalog()
        openSettingsIfNeeded()
    }

    /// Opening MacJi again (Finder, Spotlight, Launchpad, Dock) always shows Settings: it is the
    /// only way back in when the menu-bar icon is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard !AppLifecycle.isRunningTests else { return }
        inlinePanel.stop()
        picker.stop()
        statusItem.stop()
        permissions.stop()
        AccessibilityPermissionGuide.shared.close()
    }

    func showSettings() {
        permissions.refresh()
        loginItem.refresh()
        settingsWindow.show()
    }

    ////////////////////
    //// Start and wire
    /// The status item and the shortcut both open the picker; with the icon hidden the shortcut
    /// opens it at the caret (or the pointer). Settings changes reach the features only through
    // the AppSettings publishers below: one observation path, no defaults listeners in features.

    private func startFeatures() {
        inlinePanel.start()
        picker.onOpenSettings = { [weak self] in self?.showSettings() }
        picker.start()
        statusItem.onOpenPicker = { [weak self] anchor in self?.picker.toggle(relativeTo: anchor) }
        statusItem.onOpenSettings = { [weak self] in self?.showSettings() }
        statusItem.onCheckForUpdates = { [weak self] in self?.updates.checkForUpdates() }
        statusItem.onVisibilityChanged = { [weak self] visible in self?.settings.showMenuBarIcon = visible }
        statusItem.start(visible: settings.showMenuBarIcon)
        KeyboardShortcuts.onKeyDown(for: .showEmojiPicker) { [weak self] in self?.togglePickerFromShortcut() }
        permissions.start()
        updates.start()
    }

    private func wireSettings() {
        settings.$inlinePanelEnabled.combineLatest(settings.$trigger, settings.$rankFrequentlyUsedEmoji)
            .sink { [weak self] enabled, trigger, ranks in
                self?.inlinePanel.configure(enabled: enabled, trigger: trigger, ranksFrequentlyUsed: ranks)
            }
            .store(in: &subscriptions)
        settings.$convertTextAliases.combineLatest(settings.$disabledTextAliases)
            .sink { [weak self] on, disabled in
                self?.inlinePanel.setTextAliases(on ? TextAliasCatalog.all.filter { !disabled.contains($0.id) } : [])
            }
            .store(in: &subscriptions)
        settings.$showMenuBarIcon.removeDuplicates()
            .sink { [weak self] shown in self?.statusItem.setVisible(shown) }
            .store(in: &subscriptions)
        permissions.$accessibilityGranted.removeDuplicates().dropFirst()
            .sink { [weak self] _ in self?.inlinePanel.retryListening() }
            .store(in: &subscriptions)
    }

    private func togglePickerFromShortcut() {
        if let button = statusItem.visibleButton {
            picker.toggle(relativeTo: button)
        } else if picker.isShown {
            picker.close()
        } else {
            picker.toggle(at: CaretLocator.caretRect() ?? CGRect(origin: NSEvent.mouseLocation, size: .zero))
        }
    }

    //////////////////

    private func loadCatalog() {
        Task { [weak self] in
            let library = await GlyphLibrary.loadBundled()
            self?.inlinePanel.setCatalog(library.emoji)
            self?.picker.setCatalog(library.emoji)
        }
    }

    private func openSettingsIfNeeded() {
        let isFirstLaunch = !settings.hasCompletedFirstLaunch
        if AppLifecycle.shouldOpenSettingsAtLaunch(isFirstLaunch: isFirstLaunch, menuBarIconShown: settings.showMenuBarIcon,
                                                   accessibilityGranted: permissions.accessibilityGranted,
                                                   launchedAsLoginItem: launchedAsLoginItem) {
            showSettings()
        }
        if isFirstLaunch { settings.hasCompletedFirstLaunch = true }
    }
}
