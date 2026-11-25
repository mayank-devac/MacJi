//
//  InlinePanelWindow.swift
//  MacJi
//
//  Created: 2026-11-26
//  The floating, non-activating panel that hosts the inline panel view. It never becomes
//  key, so typing keeps going to the app underneath.
//  Ported from Octopus: octopus/UI/MacJi/MacJiPanel.swift
//

import AppKit
import SwiftUI

final class InlinePanelWindow: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    convenience init(rootView: some View) {
        self.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        contentView = NSHostingView(rootView: rootView)
    }
}
