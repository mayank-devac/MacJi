//
//  MenuPressButtonStyle.swift
//  MacJi
//
//  Created: 2026-11-26
//  Button style for grid cells and chips: shrink while pressed, no system bezel.
//  Ported from Octopus: octopus/UI/MenuKit/MenuPressButtonStyle.swift
//

import SwiftUI

struct MenuPressButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = PanelMotion.pressedScale

    func makeBody(configuration: Configuration) -> some View {
        Content(configuration: configuration, pressedScale: pressedScale)
    }

    private struct Content: View {
        let configuration: ButtonStyle.Configuration
        let pressedScale: CGFloat
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed && !reduceMotion ? pressedScale : 1)
                .animation(PanelMotion.press, value: configuration.isPressed)
        }
    }
}
