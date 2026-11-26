//
//  TextAliasesPage.swift
//  MacJi
//
//  Created: 2026-11-26
//  The Aliases page that slides in from Settings: a filter, then each group (arrows, math,
//  symbols, emoji, emoticons) with your own aliases first, a switch per alias and per group,
//  hide or delete per alias, and + to add one. Adding or editing opens the alias editor sheet.
//

import SwiftUI

struct TextAliasesPage: View {
    let builtIn: [TextAlias]
    @Binding var custom: [TextAlias]
    /// IDs of the aliases turned off.
    @Binding var disabled: Set<String>
    /// IDs of the built-in aliases hidden from this page.
    @Binding var hidden: Set<String>
    /// Active panel triggers, which a spelling may not contain.
    let triggers: [String]
    let onBack: () -> Void

    /// Which alias the editor sheet adds or edits.
    private struct EditorTarget: Identifiable {
        let id = UUID()
        let alias: TextAlias?
        let group: TextAlias.Group
    }

    @State private var filter = ""
    @State private var editor: EditorTarget?
    @State private var deleting: TextAlias?

    private var isFiltering: Bool { !filter.trimmingCharacters(in: .whitespaces).isEmpty }
    private var atLimit: Bool { custom.count >= Limits.customAliasesMax }
    private var listed: [TextAlias] { custom + builtIn.filter { !hidden.contains($0.id) } }

    var body: some View {
        VStack(spacing: 0) {
            header
            filterField
            Divider()
            Form {
                ForEach(TextAlias.Group.allCases) { section(for: $0) }
                if isFiltering && !TextAlias.Group.allCases.contains(where: { !aliases(in: $0).isEmpty }) {
                    Text(AliasStrings.noMatches).foregroundStyle(.secondary)
                }
                Section {
                    HStack {
                        Button(AliasStrings.turnAllOn) { disabled.subtract(listed.map(\.id)) }
                            .disabled(listed.allSatisfy { !disabled.contains($0.id) })
                        Spacer()
                        if !hidden.isEmpty {
                            Button(AliasStrings.showHidden(hidden.count)) { hidden.removeAll() }
                        }
                    }
                } footer: {
                    Text(AliasStrings.footer).foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
        .sheet(item: $editor) { target in
            AliasEditorSheet(editing: target.alias, initialGroup: target.group,
                             others: custom.filter { $0.id != target.alias?.id }, triggers: triggers,
                             onSave: save, onDelete: target.alias.map { alias in { delete(alias) } })
        }
        .confirmationDialog(AliasStrings.deleteTitle(deleting.map(TextAliasNames.name(of:)) ?? ""),
                            isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button(AliasStrings.delete, role: .destructive) {
                if let deleting { delete(deleting) }
            }
        } message: {
            Text(AliasStrings.deleteMessage)
        }
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                Label(AliasStrings.back, systemImage: SymbolNames.back)
            }
            .keyboardShortcut(.cancelAction)
            Spacer()
            Text(AliasStrings.title).font(.headline)
            Spacer()
            Button { editor = EditorTarget(alias: nil, group: .symbols) } label: {
                Image(systemName: SymbolNames.add)
            }
            .disabled(atLimit)
            .help(atLimit ? AliasStrings.limitReached : AliasStrings.add)
            .accessibilityLabel(AliasStrings.add)
        }
        .padding(SettingsMetrics.pageHeaderPadding)
    }

    private var filterField: some View {
        TextField(AliasStrings.filterPlaceholder, text: $filter, prompt: Text(AliasStrings.filterPlaceholder))
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal, SettingsMetrics.pageHeaderPadding)
            .padding(.bottom, SettingsMetrics.pageHeaderPadding)
    }

    ////////////////////
    //// One group
    /// Yours first, then the built-in ones not hidden. The header counts what is on and switches the whole
    /// group (mixed when only some are on); the last row adds one of yours to this group.
    // While filtering, groups with no match are hidden, and so are the add rows.

    private func aliases(in group: TextAlias.Group) -> [TextAlias] {
        listed.filter { $0.group == group && TextAliasNames.matches($0, filter: filter) }
    }

    @ViewBuilder
    private func section(for group: TextAlias.Group) -> some View {
        let rows = aliases(in: group)
        if !(isFiltering && rows.isEmpty) {
            Section {
                ForEach(rows) { alias in
                    AliasRow(alias: alias, isOn: isOn(alias),
                             onEdit: alias.isCustom ? { editor = EditorTarget(alias: alias, group: group) } : nil,
                             onRemove: { if alias.isCustom { deleting = alias } else { hidden.insert(alias.id) } })
                }
                if !isFiltering {
                    Button { editor = EditorTarget(alias: nil, group: group) } label: {
                        Label(AliasStrings.addInGroup, systemImage: SymbolNames.add)
                    }
                    .buttonStyle(.borderless)
                    .disabled(atLimit)
                }
            } header: {
                groupHeader(group, rows: rows)
            } footer: {
                if group == .emoticons { Text(AliasStrings.emoticonsFooter).foregroundStyle(.secondary) }
            }
        }
    }

    private func groupHeader(_ group: TextAlias.Group, rows: [TextAlias]) -> some View {
        HStack {
            Text(AliasStrings.title(of: group))
            Spacer()
            if !rows.isEmpty {
                Text(AliasStrings.onCount(rows.filter { !disabled.contains($0.id) }.count, of: rows.count))
                    .foregroundStyle(.secondary)
                Toggle(sources: rows.map(isOn), isOn: \.self) { Text(AliasStrings.title(of: group)) }
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
            }
        }
    }

    //////////////////

    private func isOn(_ alias: TextAlias) -> Binding<Bool> {
        Binding(get: { !disabled.contains(alias.id) },
                set: { isOn in
                    if isOn { disabled.remove(alias.id) } else { disabled.insert(alias.id) }
                })
    }

    private func save(_ alias: TextAlias) {
        if let index = custom.firstIndex(where: { $0.id == alias.id }) {
            custom[index] = alias
        } else {
            custom.append(alias)
        }
    }

    /// Deleting also forgets the alias's off switch.
    private func delete(_ alias: TextAlias) {
        custom.removeAll { $0.id == alias.id }
        disabled.remove(alias.id)
        deleting = nil
    }
}
