//
//  MenuCardBackground.swift
//  MacJi
//
//  Created: 2026-11-26
//  Frosted card background with a hairline and a soft shadow, for floating panels.
//  Ported from Octopus: octopus/UI/MenuKit/MenuCardBackground.swift
//

import AppKit
import SwiftUI

////////////////////
//// Frosted card
/// The card draws its own blur, hairline and shadow so the whole card can scale and fade
/// during the appear animation. The panel behind it stays transparent.
// The shadow is a blurred shape: SwiftUI shadows ignore NSView-backed content.

extension View {
    func menuCard(cornerRadius: CGFloat) -> some View {
        modifier(MenuCardBackground(cornerRadius: cornerRadius))
    }
}

private struct MenuCardBackground: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background { MenuVisualEffect(cornerRadius: cornerRadius) }
            .clipShape(shape)
            .overlay { shape.strokeBorder(Palette.cardStroke, lineWidth: PanelMetrics.cardStrokeWidth) }
            .background {
                shape.fill(Palette.cardShadow)
                    .blur(radius: PanelMetrics.shadowRadius)
                    .offset(y: PanelMetrics.shadowOffsetY)
                    .allowsHitTesting(false)
            }
    }
}

//// Panels hosting a card set hasShadow = false and a clear background.
//////////////////

/// Masks the native backdrop itself: layer rounding alone can leave square material corners.
private struct MenuVisualEffect: NSViewRepresentable {
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        view.maskImage = Self.mask(radius: cornerRadius)
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}

    private static func mask(radius: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: radius * 2 + 1, height: radius * 2 + 1), flipped: false) { rect in
            NSColor.white.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}
