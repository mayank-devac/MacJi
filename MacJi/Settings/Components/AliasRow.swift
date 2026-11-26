//
//  AliasRow.swift
//  MacJi
//
//  Created: 2026-11-27
//  One alias in the Aliases page: spellings, what they become, its name, a switch and, for
//  your own, edit and delete.
//

import SwiftUI

struct AliasRow: View {
    let alias: TextAlias
    @Binding var isOn: Bool
    /// Only your own aliases can be edited or deleted.
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    ////////////////////
    //// Row
    /// Every spelling, the arrow, every output (the typed one first), then the name. Your own
    /// aliases carry a "Yours" tag, an edit button, and Edit / Delete in the context menu.

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: SettingsMetrics.aliasSpacing) {
                Text(alias.texts.joined(separator: " "))
                    .font(.body.monospaced())
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: SettingsMetrics.aliasTextWidth, alignment: .leading)
                Image(systemName: SymbolNames.convertsTo).foregroundStyle(.secondary)
                Text(alias.replacements.joined(separator: " "))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(1)
                Text(TextAliasNames.name(of: alias))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if alias.isCustom { yoursTag }
            }
        }
        .contextMenu {
            if let onEdit { Button(AliasStrings.edit, action: onEdit) }
            if let onDelete { Button(AliasStrings.delete, role: .destructive, action: onDelete) }
        }
    }

    private var yoursTag: some View {
        HStack(spacing: SettingsMetrics.rowSpacing) {
            Text(AliasStrings.yours)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, SettingsMetrics.tagHorizontalPadding)
                .background(Capsule().fill(Palette.keycapFill))
            if let onEdit {
                Button(action: onEdit) { Image(systemName: SymbolNames.edit) }
                    .buttonStyle(.borderless)
                    .help(AliasStrings.edit)
                    .accessibilityLabel(AliasStrings.edit)
            }
        }
    }

    //////////////////
}
