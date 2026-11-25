//
//  EmojiPickerController.swift
//  MacJi
//
//  Created: 2026-11-26
//  Owns the picker popover: opening it from the menu-bar icon or anywhere on screen, its
//  keyboard actions, and handing focus back to the previous app after a copy.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerController.swift
//

import AppKit
import SwiftUI

@MainActor
final class EmojiPickerController: NSObject, NSPopoverDelegate {
    private let popover = NSPopover()
    private let model: EmojiPickerModel
    private let anchorWindow = PopoverAnchorWindow()
    private var keyMonitor: Any?
    /// The app that was frontmost before opening, so Return can hand focus back for ⌘V.
    private var previousApp: NSRunningApplication?
    private var closedAt = Date.distantPast

    init(recents: EmojiRecents) {
        model = EmojiPickerModel(recents: recents)
        super.init()
    }

    var isShown: Bool { popover.isShown }

    func start() {
        popover.behavior = .transient
        popover.delegate = self
        let host = NSHostingController(rootView: EmojiPickerView(model: model))
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host
        // Only keys sent to the popover's window are handled; the Settings window is untouched.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let handled = MainActor.assumeIsolated { self?.handle(event) ?? false }
            return handled ? nil : event
        }
    }

    func stop() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        popover.performClose(nil)
    }

    func setCatalog(_ catalog: EmojiCatalog) {
        model.catalog = catalog
    }

    ////////////////////
    //// Open and close
    /// From the menu-bar icon the popover hangs under the icon; with the icon hidden it points at
    /// a screen rect (the caret, else the pointer) through an invisible anchor window.
    // A transient popover closes on the mouse-down of a click on its own icon, and the icon's
    // action then fires on mouse-up; the short reopen guard turns that click into a plain close.

    func toggle(relativeTo view: NSView) {
        if popover.isShown { close(); return }
        guard Date().timeIntervalSince(closedAt) > Timing.popoverReopenGuard else { return }
        show(relativeTo: view)
    }

    func toggle(at screenRect: CGRect) {
        if popover.isShown { close(); return }
        guard let anchor = anchorWindow.show(at: screenRect) else { return }
        show(relativeTo: anchor)
    }

    func close() {
        popover.performClose(nil)
    }

    private func show(relativeTo view: NSView) {
        let frontmost = NSWorkspace.shared.frontmostApplication
        previousApp = frontmost == NSRunningApplication.current ? nil : frontmost
        model.prepareForOpen()
        // An accessory app must activate for the search field to receive typing.
        NSApp.activate()
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func popoverDidClose(_ notification: Notification) {
        closedAt = Date()
        anchorWindow.hide()
    }

    //// Pointer clicks outside still close the transient popover normally.
    //////////////////

    ////////////////////
    //// Keyboard actions
    /// Return copies and closes, handing focus back so ⌘V pastes immediately.
    /// Esc clears the search first and closes on a second press.

    private func handle(_ event: NSEvent) -> Bool {
        guard popover.isShown, event.window === popover.contentViewController?.view.window,
              let action = EmojiPickerKeyAction(keyCode: event.keyCode, modifiers: event.modifierFlags) else { return false }
        perform(action)
        return true
    }

    private func perform(_ action: EmojiPickerKeyAction) {
        switch action {
        case .move(let key):
            model.moveSelection(key)
        case .nextCategory:
            model.cycleCategory(forward: true)
        case .previousCategory:
            model.cycleCategory(forward: false)
        case .copy(let keepOpen):
            guard model.copySelection() else { NSSound.beep(); return }
            if !keepOpen { closeRestoringFocus() }
        case .cancel:
            if model.query.isEmpty {
                closeRestoringFocus()
            } else {
                model.query = ""
            }
        }
    }

    private func closeRestoringFocus() {
        close()
        previousApp?.activate()
        previousApp = nil
    }

    //////////////////
}
