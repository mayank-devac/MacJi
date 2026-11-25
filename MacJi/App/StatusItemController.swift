//
//  StatusItemController.swift
//  MacJi
//
//  Created: 2026-11-26
//  The menu-bar icon: a click opens the picker, a right-click (or Control-click) opens a menu
//  with Settings, Check for Updates and Quit.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerController.swift
//

import AppKit

@MainActor
final class StatusItemController: NSObject {
    var onOpenPicker: (NSView) -> Void = { _ in }
    var onOpenSettings: () -> Void = {}
    var onCheckForUpdates: () -> Void = {}
    /// The icon was shown or hidden, including by the user ⌘-dragging it out of the menu bar.
    var onVisibilityChanged: (Bool) -> Void = { _ in }

    private var item: NSStatusItem?
    private var visibilityObservation: NSKeyValueObservation?
    private lazy var menu = makeMenu()

    /// The icon's button while it is shown; the picker hangs under it.
    var visibleButton: NSStatusBarButton? {
        item?.isVisible == true ? item?.button : nil
    }

    ////////////////////
    //// Install
    /// A template SF Symbol follows the menu bar's light/dark appearance. The item may be removed by
    /// ⌘-dragging it out; that turns the setting off (watched through KVO) and Settings explains
    // how to get back. Our stored setting wins over AppKit's own remembered visibility.

    func start(visible: Bool) {
        guard item == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = PreferenceKeys.statusItemAutosave
        item.behavior = .removalAllowed
        if let button = item.button {
            let image = NSImage(systemSymbolName: SymbolNames.menuBar, accessibilityDescription: MenuBarStrings.iconDescription)
            image?.isTemplate = true
            button.image = image
            button.toolTip = MenuBarStrings.iconHelp
            button.target = self
            button.action = #selector(buttonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        item.isVisible = visible
        self.item = item
        visibilityObservation = item.observe(\.isVisible, options: [.new]) { [weak self] _, change in
            let visible = change.newValue ?? true
            Task { @MainActor in self?.onVisibilityChanged(visible) }
        }
    }

    //// The observer is added after applying the setting, so AppKit's restore can't flip it.
    //////////////////

    func setVisible(_ visible: Bool) {
        guard let item, item.isVisible != visible else { return }
        item.isVisible = visible
    }

    func stop() {
        visibilityObservation = nil
        if let item { NSStatusBar.system.removeStatusItem(item) }
        item = nil
    }

    ////////////////////
    //// Clicks
    /// Assigning the menu only for the duration of the click keeps left-click free for the picker
    // while the right-click menu still opens in the native position under the icon.

    @objc private func buttonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            showMenu()
        } else {
            onOpenPicker(sender)
        }
    }

    private func showMenu() {
        guard let item, let button = item.button else { return }
        item.menu = menu
        button.performClick(nil)
        item.menu = nil
    }

    //////////////////

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(menuItem(MenuBarStrings.openPicker, #selector(openPickerFromMenu)))
        menu.addItem(.separator())
        menu.addItem(menuItem(MenuBarStrings.settings, #selector(openSettings), key: ","))
        menu.addItem(menuItem(MenuBarStrings.checkForUpdates, #selector(checkForUpdates)))
        menu.addItem(.separator())
        menu.addItem(menuItem(MenuBarStrings.quit, #selector(quit), key: "q"))
        return menu
    }

    private func menuItem(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func openPickerFromMenu() {
        guard let button = visibleButton else { return }
        onOpenPicker(button)
    }

    @objc private func openSettings() { onOpenSettings() }
    @objc private func checkForUpdates() { onCheckForUpdates() }
    @objc private func quit() { NSApp.terminate(nil) }
}
