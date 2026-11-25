//
//  MenuKey.swift
//  MacJi
//
//  Created: 2026-11-26
//  Raw key codes → the keys every MacJi grid understands: arrows, confirm and cancel.
//  Ported from Octopus: octopus/UI/MenuKit/MenuKey.swift
//

import Carbon.HIToolbox

enum MenuKey: Equatable {
    case up, down, left, right, confirm, cancel

    init?(keyCode: UInt16) {
        switch Int(keyCode) {
        case kVK_UpArrow: self = .up
        case kVK_DownArrow: self = .down
        case kVK_LeftArrow: self = .left
        case kVK_RightArrow: self = .right
        case kVK_Return, kVK_ANSI_KeypadEnter: self = .confirm
        case kVK_Escape: self = .cancel
        default: return nil
        }
    }
}
