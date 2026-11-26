//
//  InlinePanelController.swift
//  MacJi
//
//  Created: 2026-11-26
//  Type a trigger and a term in any app ("::roc", "##arr"), or the start of an emoticon ("^_"),
//  to open a panel under the caret. Return replaces what was typed with the selection ·
//  Shift-Return copies it · Esc closes · Tab filters · Space or punctuation closes as you type.
//  Ported from Octopus: octopus/UI/MacJi/MacJiController.swift
//

import AppKit

@MainActor
final class InlinePanelController {
    private let monitor = InlineInputMonitor()
    private let model = InlinePanelModel()
    private let recents: GlyphRecents
    private let secureInputNotifier = SecureInputNotifier()
    private let fader = MenuPanelFader()
    private lazy var panel = InlinePanelWindow(rootView: InlinePanelView(model: model) { [weak self] in self?.insert($0) })
    private var configuration = InlinePanelConfiguration()
    private var tracker = TriggerTracker(triggers: [:])
    private var autocomplete = EmoticonAutocomplete(emoticons: [], minimumLength: 0, triggers: [])
    private var aliases = TextAliasConverter(aliases: [])
    private var convertsAliases = false
    /// What the last key opened, as seen inside the tap; the panel shows it a main-queue turn later.
    private var openSearch: InlinePanelModel.Search?
    private var isPresented = false
    private var anchor: (caret: CGRect?, pointer: CGPoint) = (nil, .zero)
    private var workspaceObserver: NSObjectProtocol?
    private var pointerMonitor: Any?
    private var copyClose: Task<Void, Never>?

    init(recents: GlyphRecents) {
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

    func setLibrary(_ library: GlyphLibrary) {
        model.library = library
        rebuildAutocomplete()
    }

    ////////////////////
    //// Settings and permission
    /// The composition root forwards the panel settings from AppSettings, and calls
    /// `retryListening` when Accessibility changes. The tap exists only while a panel, emoticon
    /// autocomplete or text aliases need it; with all of them off nothing watches the keyboard.
    // Frequency ranking applies from the next open.

    func configure(_ configuration: InlinePanelConfiguration) {
        if tracker.triggers != configuration.triggers {
            tracker.triggers = configuration.triggers
            endSession()
        }
        self.configuration = configuration
        rebuildAutocomplete()
        retryListening()
    }

    /// The aliases to convert while typing; empty turns conversion off.
    func setTextAliases(_ enabled: [TextAlias]) {
        aliases = TextAliasConverter(aliases: enabled)
        convertsAliases = !enabled.isEmpty
        retryListening()
    }

    func retryListening() {
        if configuration.watchesTyping || convertsAliases { startListening() } else { stopListening() }
    }

    private func rebuildAutocomplete() {
        autocomplete = EmoticonAutocomplete(emoticons: model.library.emoticons.entries.map(\.glyph.text),
                                            minimumLength: configuration.emoticonAutocompleteLength,
                                            triggers: Array(configuration.triggers.values))
    }

    private func applicationDidActivate(pid: pid_t?) {
        endSession()
        retryListening()
        if configuration.watchesTyping || convertsAliases { secureInputNotifier.check(frontmostPID: pid) }
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

    //// Turning everything off removes the tap entirely; nothing watches the keyboard then.
    //////////////////

    ////////////////////
    //// Key handling (runs inside the event tap)
    /// While a panel is open, its keys are consumed and handled on the next main-queue turn.
    /// A key that completes a text alias is consumed and its replacement typed instead; every
    /// other key passes through and updates the buffer.
    // The buffer is updated synchronously so fast typing never races the panel. Nothing is
    // queued while nothing is being typed for a panel and no panel is showing. Typing in MacJi's
    // own windows (the trigger field, the picker search) never opens a panel; the panel itself
    // is non-activating, so MacJi is only active while one of those windows has focus.

    private func handleKeyDown(_ keyCode: UInt16, _ modifiers: NSEvent.ModifierFlags, _ characters: String) -> Bool {
        guard !NSApp.isActive else {
            tracker.reset()
            openSearch = nil
            return false
        }
        if let search = openSearch,
           let action = InlinePanelKeyAction(keyCode: keyCode, modifiers: modifiers,
                                             hasFilters: search.kind.hasFilters && isPresented),
           action == .close || action == .nextFilter || action == .previousFilter || !model.results.isEmpty {
            handle(action, for: search)
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
        openSearch = currentSearch()
        let search = openSearch
        if search != nil || isPresented {
            DispatchQueue.main.async { [weak self] in self?.refresh(search) }
        }
        return conversion != nil
    }

    /// A trigger and its term win over an autocomplete run.
    private func currentSearch() -> InlinePanelModel.Search? {
        if let query = tracker.query {
            return .init(kind: query.kind, typed: query.trigger + query.term, term: query.term, isAutocomplete: false)
        }
        return autocomplete.run(in: tracker.buffer).map { .init(kind: .emoticons, typed: $0, term: $0, isAutocomplete: true) }
    }

    /// Esc on a suggestion keeps the typed word and silences it until the next word.
    private func handle(_ action: InlinePanelKeyAction, for search: InlinePanelModel.Search) {
        switch action {
        case .move(let key):
            DispatchQueue.main.async { [weak self] in self?.model.moveSelection(key) }
            return
        case .nextFilter, .previousFilter:
            DispatchQueue.main.async { [weak self] in self?.model.cycleFilter(forward: action == .nextFilter) }
            return
        case .close where search.isAutocomplete:
            autocomplete.dismiss(search.typed)
        case .insert, .copy, .close:
            tracker.reset()
        }
        openSearch = nil
        DispatchQueue.main.async { [weak self] in self?.perform(action, replacing: search.typed.count) }
    }

    //// Return with no results passes through, so MacJi never swallows a line break for nothing.
    //////////////////

    private func perform(_ action: InlinePanelKeyAction, replacing length: Int) {
        switch action {
        case .insert:
            guard let glyph = model.chosenGlyph else { hidePanel(); return }
            replace(length, with: glyph)
        case .copy:
            guard let glyph = model.chosenGlyph, model.copy(glyph) else {
                NSSound.beep()
                hidePanel()
                return
            }
            recents.record(glyph.text)
            copyClose = Task { [weak self] in
                guard (try? await Task.sleep(for: .seconds(PanelMotion.copyCloseDelay))) != nil else { return }
                self?.hidePanel()
            }
        case .close, .move, .nextFilter, .previousFilter:
            hidePanel()
        }
    }

    /// Pointer click on a result.
    private func insert(_ glyph: Glyph) {
        guard let search = openSearch else { hidePanel(); return }
        tracker.reset()
        openSearch = nil
        replace(search.typed.count, with: glyph)
    }

    private func replace(_ length: Int, with glyph: Glyph) {
        hidePanel()
        recents.record(glyph.text)
        TextInserter.replace(characterCount: length, with: glyph.text)
    }

    private func endSession() {
        tracker.reset()
        openSearch = nil
        hidePanel()
    }

    ////////////////////
    //// Panel visibility
    /// The caret is looked up once per open; the panel stays put while typing. Typing another
    /// panel's trigger re-sizes the card in place, since filters make it taller.
    // A pending copy-close keeps the "Copied" badge visible until its timer fires.

    private func refresh(_ search: InlinePanelModel.Search?) {
        guard let search else {
            if copyClose == nil { hidePanel() }
            return
        }
        cancelCopyClose()
        let previousKind = model.search?.kind
        if !isPresented { present(search.kind) }
        model.update(search)
        if let previousKind, previousKind != search.kind { place(search.kind) }
    }

    private func present(_ kind: InlinePanelKind) {
        fader.cancel(panel)
        anchor = (CaretLocator.caretRect(), NSEvent.mouseLocation)
        let placement = place(kind)
        model.beginPresentation(growsFrom: placement.opensAbove ? .bottomLeading : .topLeading,
                                useCounts: configuration.ranksFrequentlyUsed ? recents.useCounts : [:])
        panel.orderFrontRegardless()
        isPresented = true
    }

    @discardableResult
    private func place(_ kind: InlinePanelKind) -> InlinePanelPlacement {
        let placement = InlinePanelPlacement.place(card: PanelMetrics.cardSize(withFilters: kind.hasFilters), caret: anchor.caret,
                                                   pointer: anchor.pointer,
                                                   visibleFrames: NSScreen.screens.map(\.visibleFrame))
        panel.setFrame(placement.frame, display: isPresented)
        return placement
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
