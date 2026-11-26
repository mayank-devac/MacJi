//
//  QuitSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  The Quit MacJi button at the bottom of Settings.
//

import SwiftUI

struct QuitSection: View {
    let onQuit: () -> Void

    var body: some View {
        Section {
            Button(MenuBarStrings.quit, action: onQuit)
                .frame(maxWidth: .infinity)
        }
    }
}
