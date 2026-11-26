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
        // @Published emits before the value is stored, so build from the emitted values only.
        Publishers.CombineLatest4(settings.$inlinePanelEnabled, settings.$symbolPanelEnabled,
                                  settings.$emoticonsEnabled, settings.$triggers)
            .combineLatest(settings.$emoticonAutocompleteLength, settings.$rankFrequentlyUsedEmoji)
            .map { panels, autocompleteLength, ranks in
                InlinePanelConfiguration(emojiEnabled: panels.0, symbolsEnabled: panels.1, emoticonsEnabled: panels.2,
                                         triggers: panels.3, emoticonAutocompleteLength: autocompleteLength,
                                         ranksFrequentlyUsed: ranks)
            }
            .removeDuplicates()
            .sink { [weak self] configuration in self?.inlinePanel.configure(configuration) }
            .store(in: &subscriptions)
        settings.$convertTextAliases.combineLatest(settings.$disabledTextAliases, settings.$customTextAliases)
            .sink { [weak self] on, disabled, custom in
                let active = ActiveTextAliases.make(builtIn: TextAliasCatalog.all, custom: custom, disabled: disabled)
                self?.inlinePanel.setTextAliases(on ? active : [])
            }
            .store(in: &subscriptions)
        settings.$pickerShowsSymbols.combineLatest(settings.$pickerShowsEmoticons)
            .sink { [weak self] symbols, emoticons in
                guard let self else { return }
                let tabs = PickerTab.allCases.filter { $0 == .emoji || ($0 == .symbols && symbols) || ($0 == .emoticons && emoticons) }
                picker.configureTabs(tabs, selected: settings.pickerLastTab) { [weak self] in self?.settings.pickerLastTab = $0 }
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
            self?.inlinePanel.setLibrary(library)
            self?.picker.setLibrary(library)
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
