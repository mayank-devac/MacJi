//
//  TextInserter.swift
//  MacJi
//
//  Created: 2026-11-26
//  Replaces the typed "::term" in the focused app: Delete once per typed character, then the
//  emoji as a Unicode key event. The clipboard is left alone.
//  Ported from Octopus: octopus/UI/MacJi/MacJiTextInserter.swift
//

import AppKit
import Carbon.HIToolbox

enum TextInserter {
    /// "MacJi" in ASCII; stored in each synthetic event's source user data so the tap ignores them.
    static let syntheticMarker: Int64 = 0x4D_61_63_4A_69

    static func replace(characterCount: Int, with text: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<characterCount {
            post(keyCode: CGKeyCode(kVK_Delete), text: nil, source: source)
        }
        for chunk in chunks(of: text) {
            post(keyCode: 0, text: chunk, source: source)
        }
    }

    ////////////////////
    //// Splitting long text
    /// A key event carries at most `Limits.syntheticKeyUTF16Units` UTF-16 units; apps drop the
    /// rest, which cut long kaomoji short. Chunks end on character boundaries, so a flag or a ZWJ
    // family is never split; a single character longer than the limit goes alone.

    static func chunks(of text: String, maxUnits: Int = Limits.syntheticKeyUTF16Units) -> [String] {
        var chunks: [String] = []
        var current = ""
        for character in text {
            if !current.isEmpty, current.utf16.count + character.utf16.count > maxUnits {
                chunks.append(current)
                current = ""
            }
            current.append(character)
        }
        if !current.isEmpty { chunks.append(current) }
        return chunks
    }

    //////////////////

    ////////////////////
    //// One synthetic key press
    /// Flags are cleared so a still-held Shift never turns Delete into a forward delete.
    // `text` replaces whatever the key code would type.

    private static func post(keyCode: CGKeyCode, text: String?, source: CGEventSource?) {
        for keyDown in [true, false] {
            guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) else { continue }
            event.flags = []
            event.setIntegerValueField(.eventSourceUserData, value: syntheticMarker)
            if let text {
                let units = Array(text.utf16)
                event.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
            }
            event.post(tap: .cghidEventTap)
        }
    }

    //// Delivered in order through the HID stream, ahead of later typing.
    //////////////////
}
