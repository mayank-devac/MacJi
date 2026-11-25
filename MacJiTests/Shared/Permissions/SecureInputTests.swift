//
//  SecureInputTests.swift
//  MacJiTests
//
//  Created: 2026-11-26
//  Reading the Secure Input holder from the console session only.
//  Ported from Octopus: octopusTests/MacJiTests.swift
//

import Foundation
import Testing
@testable import MacJi

struct SecureInputTests {
    @Test func holderComesFromTheConsoleSessionOnly() {
        let other: [String: Any] = [SecureInput.onConsoleKey: false, SecureInput.pidKey: NSNumber(value: 42)]
        let console: [String: Any] = [SecureInput.onConsoleKey: true, SecureInput.pidKey: NSNumber(value: 8705)]
        #expect(SecureInput.holderPID(inConsoleUsers: [other, console]) == 8705)
        #expect(SecureInput.holderPID(inConsoleUsers: [[SecureInput.onConsoleKey: true, SecureInput.pidKey: NSNumber(value: 0)]]) == nil)
        #expect(SecureInput.holderPID(inConsoleUsers: [other]) == nil)
    }
}
