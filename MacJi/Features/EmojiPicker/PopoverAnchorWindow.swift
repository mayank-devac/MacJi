//
//  PopoverAnchorWindow.swift
//  MacJi
//
//  Created: 2026-11-26
//  An invisible, click-through window the picker popover can point at when the menu-bar
//  icon is hidden, so the shortcut still opens the picker next to the caret or pointer.
//

import AppKit

@MainActor
final class PopoverAnchorWindow {
    private let window: NSPanel

    init() {
        window = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .popUpMenu
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        window.isReleasedWhenClosed = false
    }

    /// Orders the anchor in at `rect` (AppKit screen coordinates) and returns the view to point at.
    func show(at rect: CGRect) -> NSView? {
        let size = max(rect.height, PickerMetrics.anchorSize)
        window.setFrame(CGRect(x: rect.minX, y: rect.minY, width: PickerMetrics.anchorSize, height: size), display: false)
        window.orderFrontRegardless()
        return window.contentView
    }

    func hide() {
        window.orderOut(nil)
    }
}
