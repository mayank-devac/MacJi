//
//  MenuPanelFader.swift
//  MacJi
//
//  Created: 2026-11-26
//  Fades a floating panel out, then orders it out; a reopen during the fade cancels it.
//  Ported from Octopus: octopus/UI/MenuKit/MenuPanelFader.swift
//

import AppKit

////////////////////
//// Fade out
/// A new presentation during the fade cancels it, so a quick reopen never loses the panel.
// The panel ignores clicks while it fades. Reduce Motion skips the fade.

@MainActor
final class MenuPanelFader {
    private var generation = 0
    private(set) var isFading = false

    func fadeOut(_ panel: NSPanel, completion: @escaping @MainActor () -> Void) {
        generation += 1
        let current = generation
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            finish(panel, completion: completion)
            return
        }
        isFading = true
        panel.ignoresMouseEvents = true
        NSAnimationContext.runAnimationGroup { context in
            context.duration = PanelMotion.fadeOutDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, self.generation == current else { return }
                self.finish(panel, completion: completion)
            }
        }
    }

    /// Call before showing the panel again.
    func cancel(_ panel: NSPanel) {
        generation += 1
        isFading = false
        panel.alphaValue = 1
        panel.ignoresMouseEvents = false
    }

    private func finish(_ panel: NSPanel, completion: @MainActor () -> Void) {
        isFading = false
        panel.orderOut(nil)
        panel.alphaValue = 1
        panel.ignoresMouseEvents = false
        completion()
    }
}

//// The completion runs only for the fade that is still current.
//////////////////
