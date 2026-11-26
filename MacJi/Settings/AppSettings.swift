//
//  AppSettings.swift
//  MacJi
//
//  Created: 2026-11-26
//  Typed, validated access to every stored setting, published for the Settings window and
//  for the composition root, which forwards changes to the features.
//

import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var inlinePanelEnabled: Bool {
        didSet { store(inlinePanelEnabled, oldValue, PreferenceKeys.inlinePanelEnabled) }
    }
    @Published var symbolPanelEnabled: Bool {
        didSet { store(symbolPanelEnabled, oldValue, PreferenceKeys.symbolPanelEnabled) }
    }
    @Published var emoticonsEnabled: Bool {
        didSet { store(emoticonsEnabled, oldValue, PreferenceKeys.emoticonsEnabled) }
    }
    /// Always valid: change them through `setTrigger(_:for:)`. The emoticon trigger may be blank.
    @Published private(set) var triggers: [InlinePanelKind: String]
    /// 0 is off, else within `Limits.emoticonAutocompleteLengths`.
    @Published var emoticonAutocompleteLength: Int {
        didSet {
            guard emoticonAutocompleteLength != oldValue else { return }
            defaults.set(emoticonAutocompleteLength, forKey: PreferenceKeys.emoticonAutocompleteLength)
        }
    }
    @Published var rankFrequentlyUsedEmoji: Bool {
        didSet { store(rankFrequentlyUsedEmoji, oldValue, PreferenceKeys.rankFrequentlyUsedEmoji) }
    }
    @Published var convertTextAliases: Bool {
        didSet { store(convertTextAliases, oldValue, PreferenceKeys.convertTextAliases) }
    }
    /// IDs from `TextAliasCatalog`; unknown IDs (from a newer MacJi) are kept.
    @Published var disabledTextAliases: Set<String> {
        didSet {
            guard disabledTextAliases != oldValue else { return }
            defaults.set(disabledTextAliases.sorted(), forKey: PreferenceKeys.disabledTextAliases)
        }
    }
    /// Your own aliases, in Settings order. Entries this build can't read are kept on save.
    @Published var customTextAliases: [TextAlias] {
        didSet {
            guard customTextAliases != oldValue else { return }
            defaults.set(CustomTextAliasCodec.encode(customTextAliases, keeping: unreadableCustomAliases),
                         forKey: PreferenceKeys.customTextAliases)
        }
    }
    @Published var showAliasesInSearch: Bool {
        didSet { store(showAliasesInSearch, oldValue, PreferenceKeys.showAliasesInSearch) }
    }
    @Published var pickerShowsSymbols: Bool {
        didSet { store(pickerShowsSymbols, oldValue, PreferenceKeys.pickerShowsSymbols) }
    }
    @Published var pickerShowsEmoticons: Bool {
        didSet { store(pickerShowsEmoticons, oldValue, PreferenceKeys.pickerShowsEmoticons) }
    }
    /// App state rather than a setting; an unknown stored tab reads as Emoji.
    var pickerLastTab: PickerTab {
        get { defaults.string(forKey: PreferenceKeys.pickerLastTab).flatMap(PickerTab.init(rawValue:)) ?? .emoji }
        set { defaults.set(newValue.rawValue, forKey: PreferenceKeys.pickerLastTab) }
    }
    @Published var showMenuBarIcon: Bool {
        didSet { store(showMenuBarIcon, oldValue, PreferenceKeys.showMenuBarIcon) }
    }

    private let defaults: UserDefaults
    private let unreadableCustomAliases: [Any]

    ////////////////////
    //// Reading stored values
    /// A missing value reads its registered default. A stored value of the wrong type or an
    /// invalid trigger falls back to the default for that key only, and is never deleted, so a
    /// value written by a newer MacJi survives running an older one.
    // Triggers are checked in panel order, each against the ones read before it.

    init(defaults: UserDefaults) {
        self.defaults = defaults
        inlinePanelEnabled = Self.bool(defaults, PreferenceKeys.inlinePanelEnabled, PreferenceDefaults.inlinePanelEnabled)
        symbolPanelEnabled = Self.bool(defaults, PreferenceKeys.symbolPanelEnabled, PreferenceDefaults.symbolPanelEnabled)
        emoticonsEnabled = Self.bool(defaults, PreferenceKeys.emoticonsEnabled, PreferenceDefaults.emoticonsEnabled)
        var triggers: [InlinePanelKind: String] = [:]
        for kind in InlinePanelKind.allCases {
            triggers[kind] = InlineTrigger.valid(defaults.object(forKey: Self.triggerKey(kind)) as? String,
                                                 for: kind, others: triggers)
        }
        self.triggers = triggers
        emoticonAutocompleteLength = Self.autocompleteLength(defaults.object(forKey: PreferenceKeys.emoticonAutocompleteLength))
        rankFrequentlyUsedEmoji = Self.bool(defaults, PreferenceKeys.rankFrequentlyUsedEmoji, PreferenceDefaults.rankFrequentlyUsedEmoji)
        convertTextAliases = Self.bool(defaults, PreferenceKeys.convertTextAliases, PreferenceDefaults.convertTextAliases)
        disabledTextAliases = Set(defaults.stringArray(forKey: PreferenceKeys.disabledTextAliases) ?? [])
        (customTextAliases, unreadableCustomAliases) = CustomTextAliasCodec.decode(defaults.object(forKey: PreferenceKeys.customTextAliases))
        showAliasesInSearch = Self.bool(defaults, PreferenceKeys.showAliasesInSearch, PreferenceDefaults.showAliasesInSearch)
        pickerShowsSymbols = Self.bool(defaults, PreferenceKeys.pickerShowsSymbols, PreferenceDefaults.pickerShowsSymbols)
        pickerShowsEmoticons = Self.bool(defaults, PreferenceKeys.pickerShowsEmoticons, PreferenceDefaults.pickerShowsEmoticons)
        showMenuBarIcon = Self.bool(defaults, PreferenceKeys.showMenuBarIcon, PreferenceDefaults.showMenuBarIcon)
    }

    /// Registers (never writes) the defaults. Call once at launch, after `SettingsMigrator`.
    static func registerDefaults(in defaults: UserDefaults) {
        defaults.register(defaults: PreferenceDefaults.registered)
    }

    /// 0 (off) or a length in range; anything else reads as the default.
    nonisolated static func autocompleteLength(_ stored: Any?) -> Int {
        guard let length = stored as? Int, length == 0 || Limits.emoticonAutocompleteLengths.contains(length) else {
            return PreferenceDefaults.emoticonAutocompleteLength
        }
        return length
    }

    private static func bool(_ defaults: UserDefaults, _ key: String, _ fallback: Bool) -> Bool {
        defaults.object(forKey: key) as? Bool ?? fallback
    }

    //// Only a user action or a migration ever writes a setting.
    //////////////////

    func trigger(for kind: InlinePanelKind) -> String {
        triggers[kind] ?? ""
    }

    /// True when no panel, emoticon suggestion or alias needs the keyboard, so the tap is removed.
    var watchesNoTyping: Bool {
        let panels = InlinePanelConfiguration(emojiEnabled: inlinePanelEnabled, symbolsEnabled: symbolPanelEnabled,
                                              emoticonsEnabled: emoticonsEnabled, triggers: triggers,
                                              emoticonAutocompleteLength: emoticonAutocompleteLength,
                                              ranksFrequentlyUsed: rankFrequentlyUsedEmoji)
        return !panels.watchesTyping && !convertTextAliases
    }

    /// Stores `raw` and returns nil when it is a valid trigger for `kind`; otherwise keeps the
    /// current trigger and returns why `raw` was rejected.
    func setTrigger(_ raw: String, for kind: InlinePanelKind) -> InlineTrigger.Problem? {
        if let problem = InlineTrigger.problem(with: raw, for: kind, others: triggers) { return problem }
        guard raw != triggers[kind] else { return nil }
        triggers[kind] = raw
        defaults.set(raw, forKey: Self.triggerKey(kind))
        return nil
    }

    private static func triggerKey(_ kind: InlinePanelKind) -> String {
        switch kind {
        case .emoji: PreferenceKeys.inlinePanelTrigger
        case .symbols: PreferenceKeys.symbolPanelTrigger
        case .emoticons: PreferenceKeys.emoticonPanelTrigger
        }
    }

    /// App state rather than a setting: has the first launch already shown Settings?
    var hasCompletedFirstLaunch: Bool {
        get { defaults.bool(forKey: PreferenceKeys.hasCompletedFirstLaunch) }
        set { defaults.set(newValue, forKey: PreferenceKeys.hasCompletedFirstLaunch) }
    }

    private func store(_ value: Bool, _ oldValue: Bool, _ key: String) {
        guard value != oldValue else { return }
        defaults.set(value, forKey: key)
    }
}
