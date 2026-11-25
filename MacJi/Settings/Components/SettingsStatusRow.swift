//
//  SettingsStatusRow.swift
//  MacJi
//
//  Created: 2026-11-26
//  A status row: coloured symbol, title, explanation and an optional fix-it button.
//  Used for the Accessibility and Secure Input rows; works in any Form.
//

import SwiftUI

struct SettingsStatusRow: View {
    let symbol: String
    let tint: Color
    let title: String
    let detail: String
    var actionTitle: String?
    var action: () -> Void = {}

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: SettingsMetrics.aboutSpacing) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .font(.system(size: SettingsMetrics.statusIconSize))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: SettingsMetrics.rowSpacing) {
                Text(title)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if let actionTitle {
                // Prominent, but not the default action: Return in another field must not trigger it.
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
