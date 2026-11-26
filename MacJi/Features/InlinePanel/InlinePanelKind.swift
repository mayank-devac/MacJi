//
//  InlinePanelKind.swift
//  MacJi
//
//  Created: 2026-11-27
//  The three inline panels (emoji, symbols, emoticons): which catalog each searches and
//  whether its trigger may be blank.
//

import Foundation

enum InlinePanelKind: CaseIterable, Sendable {
    /// `::rocket` → 🚀
    case emoji
    /// `##arrow` → →
    case symbols
    /// `^_` (autocomplete) or an optional trigger → ^_^
    case emoticons

    var defaultTrigger: String {
        switch self {
        case .emoji: PreferenceDefaults.trigger
        case .symbols: PreferenceDefaults.symbolTrigger
        case .emoticons: PreferenceDefaults.emoticonTrigger
        }
    }

    /// Emoticons open by autocomplete, so their trigger may be blank (none).
    var triggerIsOptional: Bool { self == .emoticons }
}
