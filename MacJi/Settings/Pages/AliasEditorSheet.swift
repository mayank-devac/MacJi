//
//  AliasEditorSheet.swift
//  MacJi
//
//  Created: 2026-11-27
//  The sheet that adds or edits one of your aliases: name, group, spellings and outputs with +
//  and −, word-start rule, live validation.
//

import AppKit
import SwiftUI

struct AliasEditorSheet: View {
    /// nil when adding a new alias.
    let editing: TextAlias?
    let initialGroup: TextAlias.Group
    /// Your other aliases, so a spelling can't be shared.
    let others: [TextAlias]
    /// Active panel triggers; a spelling may not contain one.
    let triggers: [String]
    let onSave: (TextAlias) -> Void
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    /// A row with a stable identity, so removing one never shifts another's text field.
    private struct Row: Identifiable {
        let id = UUID()
        var text = ""
    }

    @State private var newID = CustomTextAliasCodec.newID()
    @State private var name = ""
    @State private var group = TextAlias.Group.symbols
    @State private var spellings = [Row()]
    @State private var outputs = [Row()]
    @State private var wordStartOnly = true
    @State private var confirmsDelete = false

    private var draft: CustomTextAliasValidator.Draft {
        .init(name: name, group: group, texts: spellings.map(\.text), replacements: outputs.map(\.text),
              wordStartOnly: wordStartOnly)
    }

    private var saved: TextAlias? {
        CustomTextAliasValidator.alias(from: draft, id: editing?.id ?? newID, triggers: triggers, others: others)
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(editing == nil ? AliasStrings.newTitle : AliasStrings.editTitle)
                .font(.headline)
                .padding(.top, SettingsMetrics.pageHeaderPadding)
            Form {
                nameSection
                spellingsSection
                outputsSection
                ruleSection
            }
            .formStyle(.grouped)
            Divider()
            buttons
        }
        .frame(width: SettingsMetrics.editorWidth, height: SettingsMetrics.editorHeight)
        .onAppear(perform: load)
        .confirmationDialog(AliasStrings.deleteTitle(name), isPresented: $confirmsDelete) {
            Button(AliasStrings.delete, role: .destructive) {
                onDelete?()
                dismiss()
            }
        } message: {
            Text(AliasStrings.deleteMessage)
        }
    }

    private func load() {
        guard let editing else {
            group = initialGroup
            return
        }
        let draft = CustomTextAliasValidator.draft(from: editing)
        name = draft.name
        group = draft.group
        spellings = draft.texts.map { Row(text: $0) }
        outputs = draft.replacements.map { Row(text: $0) }
        wordStartOnly = draft.wordStartOnly
    }

    ////////////////////
    //// Name and group
    /// The name is what every panel's search finds; the footer shows how, with the triggers in use.

    private var nameSection: some View {
        Section {
            TextField(AliasStrings.nameLabel, text: $name, prompt: Text(AliasStrings.namePlaceholder))
            if let problem = CustomTextAliasValidator.nameProblem(name), problem != .nameMissing {
                error(problem)
            }
            Picker(AliasStrings.groupLabel, selection: $group) {
                ForEach(TextAlias.Group.allCases) { Text(AliasStrings.title(of: $0)).tag($0) }
            }
        } footer: {
            Text(AliasStrings.searchHint(searchExamples)).foregroundStyle(.secondary)
        }
    }

    private var searchExamples: String {
        let word = name.split(separator: " ").first.map { $0.lowercased() } ?? AliasStrings.namePlaceholder.lowercased()
        return triggers.filter { !$0.isEmpty }.map { $0 + word }.joined(separator: "  ")
    }

    //////////////////

    ////////////////////
    //// Spellings and outputs
    /// + adds a row (up to the limit), − removes one (never the last). Blank rows are ignored.
    /// The first output is typed; "Type this one" moves another to the top.

    private var spellingsSection: some View {
        Section {
            ForEach($spellings) { $row in
                let index = spellings.firstIndex { $0.id == row.id } ?? 0
                HStack {
                    TextField(AliasStrings.spellingsHeader, text: $row.text, prompt: Text(AliasStrings.spellingPlaceholder))
                        .labelsHidden()
                        .font(.body.monospaced())
                    removeButton(disabled: spellings.count == 1) { spellings.removeAll { $0.id == row.id } }
                }
                spellingHint(at: index)
            }
            addButton(AliasStrings.addSpelling, disabled: spellings.count >= Limits.aliasMaxSpellings) { spellings.append(Row()) }
        } header: {
            Text(AliasStrings.spellingsHeader)
        }
    }

    @ViewBuilder
    private func spellingHint(at index: Int) -> some View {
        let texts = spellings.map(\.text)
        if let problem = CustomTextAliasValidator.spellingProblem(at: index, in: texts, triggers: triggers, others: others) {
            error(problem)
        } else if let builtIn = ActiveTextAliases.builtIn(using: texts[index]) {
            SettingsHint(text: AliasStrings.replacesBuiltIn(builtIn.replacement, name: TextAliasNames.name(of: builtIn)))
        }
    }

    private var outputsSection: some View {
        Section {
            ForEach($outputs) { $row in
                let index = outputs.firstIndex { $0.id == row.id } ?? 0
                HStack {
                    TextField(AliasStrings.outputsHeader, text: $row.text, prompt: Text(AliasStrings.outputPlaceholder))
                        .labelsHidden()
                    if index == 0 {
                        Text(AliasStrings.typedBadge).font(.caption).foregroundStyle(.secondary)
                    } else {
                        Button { outputs.move(fromOffsets: [index], toOffset: 0) } label: {
                            Image(systemName: SymbolNames.makeFirst)
                        }
                        .buttonStyle(.borderless)
                        .help(AliasStrings.useWhenTyping)
                        .accessibilityLabel(AliasStrings.useWhenTyping)
                    }
                    removeButton(disabled: outputs.count == 1) { outputs.removeAll { $0.id == row.id } }
                }
                if let problem = CustomTextAliasValidator.outputProblem(at: index, in: outputs.map(\.text)) { error(problem) }
            }
            HStack {
                addButton(AliasStrings.addOutput, disabled: outputs.count >= Limits.aliasMaxOutputs) { outputs.append(Row()) }
                Spacer()
                Button(AliasStrings.characterViewer) { NSApp.orderFrontCharacterPalette(nil) }
            }
        } header: {
            Text(AliasStrings.outputsHeader)
        } footer: {
            Text(AliasStrings.outputsFooter).foregroundStyle(.secondary)
        }
    }

    //////////////////

    private var ruleSection: some View {
        Section {
            Toggle(isOn: $wordStartOnly) {
                Text(AliasStrings.wordStartOnly)
                Text(AliasStrings.wordStartOnlyHint)
            }
            if let saved {
                SettingsHint(text: AliasStrings.preview(typed: saved.texts[0], becomes: saved.replacement))
            }
        }
    }

    private var buttons: some View {
        HStack {
            if onDelete != nil {
                Button(AliasStrings.delete, role: .destructive) { confirmsDelete = true }
            }
            Spacer()
            Button(AliasStrings.cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button(AliasStrings.save) {
                guard let saved else { return }
                onSave(saved)
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(saved == nil)
        }
        .padding(SettingsMetrics.pageHeaderPadding)
    }

    private func addButton(_ title: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: SymbolNames.add) }
            .buttonStyle(.borderless)
            .disabled(disabled)
    }

    private func removeButton(disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: SymbolNames.remove) }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .disabled(disabled)
            .help(AliasStrings.removeRow)
            .accessibilityLabel(AliasStrings.removeRow)
    }

    private func error(_ problem: CustomTextAliasValidator.Problem) -> some View {
        SettingsHint(text: AliasStrings.message(for: problem), symbol: SymbolNames.error, tint: Palette.error)
    }
}
