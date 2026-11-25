//
//  CaretLocatorTests.swift
//  MacJiTests
//
//  Created: 2026-11-26
//  Rejecting AX rects that are fields, paragraphs or off every screen.
//  Ported from Octopus: octopusTests/MacJiTests.swift
//

import CoreGraphics
import Testing
@testable import MacJi

struct CaretLocatorTests {
    @Test func caretRejectsFieldSizedOrOffscreenRects() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 800)]
        let line = CaretLocator.plausibleCaret(CGRect(x: 100, y: 100, width: 0, height: 16), primaryMaxY: 800, screens: screens)
        #expect(line == CGRect(x: 100, y: 684, width: 0, height: 16))
        #expect(CaretLocator.plausibleCaret(CGRect(x: 100, y: 100, width: 600, height: 400), primaryMaxY: 800, screens: screens) == nil)
        #expect(CaretLocator.plausibleCaret(CGRect(x: -5000, y: 100, width: 0, height: 16), primaryMaxY: 800, screens: screens) == nil)
    }
}
