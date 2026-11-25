//
//  EventTapRevocationDetectorTests.swift
//  MacJiTests
//
//  Created: 2026-11-26
//  Revocation needs consecutive failed probes and is confirmed exactly once.
//  Ported from Octopus: octopusTests/EventTapRevocationDetectorTests.swift
//

import Testing
@testable import MacJi

struct EventTapRevocationDetectorTests {
    /// Feeds probe results in order and returns what `record` answered for each.
    private func confirmations(_ probes: [Bool], into detector: inout EventTapRevocationDetector) -> [Bool] {
        probes.map { detector.record(trusted: $0) }
    }

    @Test func oneFailedProbeIsNotRevocation() {
        var detector = EventTapRevocationDetector()
        #expect(confirmations([false, true, false], into: &detector) == [false, false, false])
        #expect(!detector.isRevoked)
    }

    @Test func confirmsRevocationExactlyOnceAfterConsecutiveFailures() {
        var detector = EventTapRevocationDetector()
        #expect(confirmations([false, false, false, true], into: &detector) == [false, true, false, false])
        #expect(detector.isRevoked)
    }

    @Test func resetClearsPendingFailuresButNotRevocation() {
        var detector = EventTapRevocationDetector()
        _ = confirmations([false], into: &detector)
        detector.reset()
        #expect(confirmations([false], into: &detector) == [false])

        _ = confirmations([false], into: &detector)
        detector.reset()
        #expect(detector.isRevoked)
    }
}
