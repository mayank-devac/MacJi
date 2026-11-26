//
//  EmojiPickerSection.swift
//  MacJi
//
//  Created: 2026-11-26
//  The global picker shortcut: a recorder plus Reset to Default.
//  Replaces Octopus's custom recorder (octopus/UI/KeyboardShortcuts/KeyboardShortcutRecorder.swift)
//  with the package's own, because one shortcut needs no second event tap.
//

import KeyboardShortcuts
import SwiftUI

struct EmojiPickerSection: View {
    @Binding var showsSymbols: Bool
    @Binding var showsEmoticons: Bool
    @State private var isDefault = Self.shortcutIsDefault
    /// Bumped by Reset so the recorder redraws with the restored shortcut.
    @State private var recorderID = 0

    var body: some View {
        Section {
            LabeledContent(SettingsStrings.shortcutLabel) {
                HStack {
                    KeyboardShortcuts.Recorder(for: .showEmojiPicker) { _ in isDefault = Self.shortcutIsDefault }
                        .id(recorderID)
                    Button(SettingsStrings.resetShortcut) {
                        KeyboardShortcuts.reset(.showEmojiPicker)
                        isDefault = Self.shortcutIsDefault
                        recorderID += 1
                    }
                    .disabled(isDefault)
                }
            }
            Toggle(SettingsStrings.pickerSymbolsTab, isOn: $showsSymbols)
            Toggle(SettingsStrings.pickerEmoticonsTab, isOn: $showsEmoticons)
        } header: {
            Text(SettingsStrings.pickerHeader)
        } footer: {
            Text(SettingsStrings.pickerFooter).foregroundStyle(.secondary)
        }
    }

    private static var shortcutIsDefault: Bool {
        KeyboardShortcuts.getShortcut(for: .showEmojiPicker) == KeyboardShortcuts.Name.showEmojiPicker.defaultShortcut
    }
}
