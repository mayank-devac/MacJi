//
//  AliasRow.swift
//  MacJi
//
//  Created: 2026-11-27
//  One alias in the Aliases page: spellings, what they become, its name, then edit (yours
//  only), delete or hide, and its switch.
//

import SwiftUI

struct AliasRow: View {
    let alias: TextAlias
    @Binding var isOn: Bool
    /// Only your own aliases can be edited.
    var onEdit: (() -> Void)?
    /// Deletes one of yours, or hides a built-in one.
    let onRemove: () -> Void

    ////////////////////
    //// Row
    /// Every spelling, the arrow, every output (the typed one first), then the name. The
    /// buttons sit right before the switch: edit and delete for yours, hide for a built-in one.
    // The context menu repeats them for keyboard and VoiceOver users.

    var body: some View {
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
            Spacer(minLength: 0)
            if let onEdit { iconButton(SymbolNames.edit, help: AliasStrings.edit, action: onEdit) }
            removeButton
            Toggle(TextAliasNames.name(of: alias), isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .contextMenu {
            if let onEdit { Button(AliasStrings.edit, action: onEdit) }
            if alias.isCustom {
                Button(AliasStrings.delete, role: .destructive, action: onRemove)
            } else {
                Button(AliasStrings.hide, action: onRemove)
            }
        }
    }

    private var yoursTag: some View {
        Text(AliasStrings.yours)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, SettingsMetrics.tagHorizontalPadding)
            .background(Capsule().fill(Palette.keycapFill))
    }

    @ViewBuilder
    private var removeButton: some View {
        if alias.isCustom {
            iconButton(SymbolNames.delete, help: AliasStrings.delete, action: onRemove)
        } else {
            iconButton(SymbolNames.hide, help: AliasStrings.hideHelp, label: AliasStrings.hide, action: onRemove)
        }
    }

    private func iconButton(_ symbol: String, help: String, label: String? = nil,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: symbol) }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(help)
            .accessibilityLabel(label ?? help)
    }

    //////////////////
}
