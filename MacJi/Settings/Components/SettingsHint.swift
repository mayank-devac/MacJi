//
//  SettingsHint.swift
//  MacJi
//
//  Created: 2026-11-26
//  One small explanatory or error line under a Settings control, with an optional symbol.
//

import SwiftUI

struct SettingsHint: View {
    let text: String
    var symbol: String?
    var tint: Color = .secondary

    var body: some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            if let symbol { Image(systemName: symbol).foregroundStyle(tint) }
        }
        .labelStyle(.titleAndIcon)
        .font(.caption)
        .foregroundStyle(tint == .secondary ? .secondary : tint)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
