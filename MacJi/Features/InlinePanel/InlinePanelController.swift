//
//  InlinePanelController.swift
//  MacJi
//
//  Created: 2026-11-26
//  Type the trigger (default "::") and a term in any app, e.g. "::roc", to open an emoji
//  panel under the caret. Return replaces "::roc" with the selection · Shift-Return copies
//  it · Esc closes · Space or punctuation closes as you keep typing.
//  Ported from Octopus: octopus/UI/MacJi/MacJiController.swift
//

import AppKit

@MainActor
final class InlinePanelController {
    private let monitor = InlineInputMonitor()
    private let model = InlinePanelModel()
    private let recents: EmojiRecents
    private let secureInputNotifier = SecureInputNotifier()
    private let fader = MenuPanelFader()
    private lazy var panel = InlinePanelWindow(rootView: InlinePanelView(model: model) { [weak self] in self?.insert($0) })
    private var tracker = TriggerTracker(trigger: PreferenceDefaults.trigger)
    private var isEnabled = false
    private var ranksFrequentlyUsed = PreferenceDefaults.rankFrequentlyUsedEmoji
    private var aliases = TextAliasConverter(aliases: [])
    private var isPresented = false
    private var workspaceObserver: NSObjectProtocol?
    private var pointerMonitor: Any?
    private var copyClose: Task<Void, Never>?

    init(recents: EmojiRecents) {
        self.recents = recents
    }

    func start() {
        monitor.onKeyDown = { [weak self] in self?.handleKeyDown($0, $1, $2) ?? false }
        monitor.onInterrupted = { [weak self] in self?.endSession() }
        // Switching apps moves the caret; it is also a cheap moment to retry the tap after
        // Accessibility was granted, and to report a background app whose Secure Input hides
        // every key from the tap.
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            let pid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
            MainActor.assumeIsolated { self?.applicationDidActivate(pid: pid) }
        }
    }

    func stop() {
        if let workspaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver) }
        workspaceObserver = nil
        stopListening()
    }

    func setCatalog(_ catalog: EmojiCatalog) {
        model.catalog = catalog
    }

    ////////////////////
    //// Settings and permission
    /// The composition root forwards the panel settings from AppSettings, and calls
    /// `retryListening` when Accessibility changes. The tap exists only while both allow it.
    // Frequency ranking applies from the next open; text aliases ride on the same tap.

    func configure(enabled: Bool, trigger: String, ranksFrequentlyUsed: Bool) {
        if tracker.trigger != trigger {
            tracker.trigger = trigger
            endSession()
        }
        isEnabled = enabled
        self.ranksFrequentlyUsed = ranksFrequentlyUsed
        retryListening()
    }

    /// The aliases to convert while typing; empty turns conversion off.
    func setTextAliases(_ enabled: [TextAlias]) {
        aliases = TextAliasConverter(aliases: enabled)
    }

    func retryListening() {
        if isEnabled { startListening() } else { stopListening() }
    }

    private func applicationDidActivate(pid: pid_t?) {
        endSession()
        retryListening()
        if isEnabled { secureInputNotifier.check(frontmostPID: pid) }
    }

    private func startListening() {
        guard !monitor.isRunning, monitor.start() else { return }
        // Any click can move the caret, so the typed buffer no longer matches the text.
        // Global monitors never see clicks in MacJi's own panel.
        pointerMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.endSession() }
        }
    }

    private func stopListening() {
        monitor.stop()
        if let pointerMonitor { NSEvent.removeMonitor(pointerMonitor) }
        pointerMonitor = nil
        endSession()
    }

    //// Turning the panel off removes the tap entirely; nothing watches the keyboard then.
    //////////////////

    ////////////////////
    //// Key handling (runs inside the event tap)
    /// While a term is open, panel keys are consumed and handled on the next main-queue turn.
    /// A key that completes a text alias is consumed and its replacement typed instead; every
    /// other key passes through and updates the buffer.
    // The buffer is updated synchronously so fast typing never races the panel. Nothing is
    // queued while no trigger is being typed and no panel is showing. Typing in MacJi's own
    // windows (the trigger field, the picker search) never opens the panel; the panel itself is
    // non-activating, so MacJi is only active while one of those windows has focus.

    private func handleKeyDown(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags, _ characters: String) -> Bool {
        guard !NSApp.isActive else {
            tracker.reset()
            return false
        }
        if tracker.query != nil, let action = InlinePanelKeyAction(keyCode: keyCode, modifiers: modifiers),
           action == .close || !model.results.isEmpty {
            if case .move(let key) = action {
                DispatchQueue.main.async { [weak self] in self?.model.moveSelection(key) }
            } else {
                let length = tracker.replacementLength
                tracker.reset()
                DispatchQueue.main.async { [weak self] in self?.perform(action, replacing: length) }
            }
            return true
        }
        let key = TypedKey(keyCode: keyCode, modifiers: modifiers, characters: characters)
        let conversion = aliases.conversion(typing: key, after: tracker.buffer)
        if let conversion {
            for _ in 0..<conversion.deleteCount { tracker.apply(.deleteBackward) }
            tracker.apply(.text(conversion.replacement))
            DispatchQueue.main.async {
                TextInserter.replace(characterCount: conversion.deleteCount, with: conversion.replacement)
            }
        } else {
            tracker.apply(key)
        }
        let query = tracker.query
        if query != nil || isPresented {
            DispatchQueue.main.async { [weak self] in self?.refresh(query) }
        }
        return conversion != nil
    }

    //// Return with no results passes through, so MacJi never swallows a line break for nothing.
    //////////////////

    private func perform(_ action: InlinePanelKeyAction, replacing length: Int) {
        switch action {
        case .insert:
            guard let emoji = model.chosenEmoji else { hidePanel(); return }
            replace(length, with: emoji)
        case .copy:
            guard let emoji = model.chosenEmoji, model.copy(emoji) else {
                NSSound.beep()
                hidePanel()
                return
            }
            recents.record(emoji.emoji)
            copyClose = Task { [weak self] in
                guard (try? await Task.sleep(for: .seconds(PanelMotion.copyCloseDelay))) != nil else { return }
                self?.hidePanel()
            }
        case .close, .move:
            hidePanel()
        }
    }

    /// Pointer click on a result.
    private func insert(_ emoji: Emoji) {
        let length = tracker.replacementLength
        guard length > 0 else { hidePanel(); return }
        tracker.reset()
        replace(length, with: emoji)
    }

    private func replace(_ length: Int, with emoji: Emoji) {
        hidePanel()
        recents.record(emoji.emoji)
        TextInserter.replace(characterCount: length, with: emoji.emoji)
    }

    private func endSession() {
        tracker.reset()
        hidePanel()
    }

    ////////////////////
    //// Panel visibility
    /// The caret is looked up once per open; the panel stays put while typing.
    // A pending copy-close keeps the "Copied" badge visible until its timer fires.

    private func refresh(_ query: String?) {
        guard let query else {
            if copyClose == nil { hidePanel() }
            return
        }
        cancelCopyClose()
        if !isPresented { present() }
        model.update(query: query, trigger: tracker.trigger)
    }

    private func present() {
        fader.cancel(panel)
        let placement = InlinePanelPlacement.place(card: PanelMetrics.cardSize, caret: CaretLocator.caretRect(),
                                                   pointer: NSEvent.mouseLocation,
                                                   visibleFrames: NSScreen.screens.map(\.visibleFrame))
        model.beginPresentation(growsFrom: placement.opensAbove ? .bottomLeading : .topLeading,
                                useCounts: ranksFrequentlyUsed ? recents.useCounts : [:])
        panel.setFrame(placement.frame, display: false)
        panel.orderFrontRegardless()
        isPresented = true
    }

    private func hidePanel() {
        cancelCopyClose()
        guard isPresented else { return }
        isPresented = false
        fader.fadeOut(panel) { [weak self] in self?.model.reset() }
    }

    private func cancelCopyClose() {
        copyClose?.cancel()
        copyClose = nil
    }

    //// A reopen during the fade cancels it and re-places the panel at the new caret.
    //////////////////
}
