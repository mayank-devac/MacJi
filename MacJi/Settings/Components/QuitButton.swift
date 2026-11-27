//
//  QuitButton.swift
//  MacJi
//
//  Created: 2026-11-26
//  The Quit MacJi icon button.
//

import SwiftUI

struct QuitButton: View {
    let onQuit: () -> Void

    var body: some View {
        Button(action: onQuit) {
            Image(systemName: SymbolNames.quit)
        }
        .buttonStyle(.link)
        .help(MenuBarStrings.quit)
        .accessibilityLabel(MenuBarStrings.quit)
    }
}
