//
//  TextAliasesPage.swift
//  MacJi
//
//  Created: 2026-11-26
//  The Aliases page that slides in from the Inline Panel section: one switch per text alias,
//  grouped as arrows, math, symbols and emoticons.
//

import SwiftUI

struct TextAliasesPage: View {
    let aliases: [TextAlias]
    /// IDs of the aliases turned off.
    @Binding var disabled: Set<String>
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Form {
                ForEach(TextAlias.Group.allCases.filter { group in aliases.contains { $0.group == group } }) { group in
                    Section {
                        ForEach(aliases.filter { $0.group == group }) { row(for: $0) }
                    } header: {
                        Text(title(of: group))
                    } footer: {
                        if group == .emoticons {
                            Text(SettingsStrings.aliasesEmoticonsFooter).foregroundStyle(.secondary)
                        }
                    }
                }
                Section {
                    Button(SettingsStrings.turnAllOn) { disabled.subtract(aliases.map(\.id)) }
                        .disabled(aliases.allSatisfy { !disabled.contains($0.id) })
                } footer: {
                    Text(SettingsStrings.aliasesFooter).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Label(SettingsStrings.aliasesBack, systemImage: SymbolNames.back)
            }
            .keyboardShortcut(.cancelAction)
            Spacer()
            Text(SettingsStrings.aliasesTitle).font(.headline)
            Spacer()
        }
        .padding(SettingsMetrics.pageHeaderPadding)
    }

    ////////////////////
    //// One alias row
    /// Every spelling, the arrow, then what it becomes; the switch stores the ID when off.

    private func row(for alias: TextAlias) -> some View {
        Toggle(isOn: Binding(get: { !disabled.contains(alias.id) },
                             set: { isOn in
                                 if isOn { disabled.remove(alias.id) } else { disabled.insert(alias.id) }
                             })) {
            HStack(spacing: SettingsMetrics.aliasSpacing) {
                Text(alias.texts.joined(separator: " "))
                    .font(.body.monospaced())
                    .frame(width: SettingsMetrics.aliasTextWidth, alignment: .leading)
                Image(systemName: SymbolNames.convertsTo).foregroundStyle(.secondary)
                Text(alias.replacement)
            }
        }
    }

    //////////////////

    private func title(of group: TextAlias.Group) -> String {
        switch group {
        case .arrows: SettingsStrings.aliasesArrows
        case .math: SettingsStrings.aliasesMath
        case .symbols: SettingsStrings.aliasesSymbols
        case .emoticons: SettingsStrings.aliasesEmoticons
        case .emoji: SettingsStrings.aliasesEmoji
        }
    }
}
