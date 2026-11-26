//
//  CopiedBadge.swift
//  MacJi
//
//  Created: 2026-11-26
//  The "Copied 😀" capsule and the modifier that shows it briefly after each copy.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerComponents.swift, octopus/UI/EmojiPicker/EmojiPickerView.swift, octopus/UI/MacJi/MacJiView.swift
//

import SwiftUI

struct CopiedBadge: View {
    let glyph: Glyph?

    var body: some View {
        HStack(spacing: EmojiUIMetrics.badgeSpacing) {
            Image(systemName: SymbolNames.copied).foregroundStyle(Palette.copiedCheck)
            Text(GlyphStrings.copied(glyph?.text ?? ""))
        }
        .font(.system(size: EmojiUIMetrics.badgeFontSize, weight: .medium))
        .padding(.horizontal, EmojiUIMetrics.badgeHorizontalPadding)
        .padding(.vertical, EmojiUIMetrics.badgeVerticalPadding)
        .background(Capsule().fill(.regularMaterial))
        .overlay(Capsule().strokeBorder(Palette.badgeStroke))
        .shadow(color: Palette.badgeShadow, radius: EmojiUIMetrics.badgeShadowRadius, y: EmojiUIMetrics.badgeShadowY)
        .padding(.bottom, EmojiUIMetrics.badgeBottomPadding)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .accessibilityElement(children: .combine)
    }
}

////////////////////
//// Timed badge
/// Each new `copyCount` shows the badge and restarts its timer, so copying twice in a row
/// never hides the second badge early. A new `presentationID` hides any badge left from before.

private struct CopiedBadgeModifier: ViewModifier {
    let copyCount: Int
    let glyph: Glyph?
    let presentationID: Int
    @State private var isShown = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isShown { CopiedBadge(glyph: glyph) }
            }
            .task(id: copyCount) { await flash() }
            .onChange(of: presentationID) { isShown = false }
    }

    private func flash() async {
        guard copyCount > 0 else { return }
        withAnimation(PanelMotion.badgeIn) { isShown = true }
        guard (try? await Task.sleep(for: PanelMotion.badgeVisible)) != nil else { return }
        withAnimation(PanelMotion.badgeOut) { isShown = false }
    }
}

extension View {
    func copiedBadge(copyCount: Int, glyph: Glyph?, presentationID: Int) -> some View {
        modifier(CopiedBadgeModifier(copyCount: copyCount, glyph: glyph, presentationID: presentationID))
    }
}

//// A cancelled sleep (newer copy) leaves the badge up for the newer task to manage.
//////////////////
