//
//  InlinePanelTests.swift
//  MacJiTests
//
//  Created: 2026-11-26
//  Trigger tracking, key mapping, text aliases, trigger validation and panel placement.
//  Ported from Octopus: octopusTests/MacJiTests.swift
//

import AppKit
import Testing
@testable import MacJi

struct InlinePanelTests {
    private func tracker(typing text: String, trigger: String = "::") -> TriggerTracker {
        var tracker = TriggerTracker(trigger: trigger)
        text.forEach { tracker.apply(.text(String($0))) }
        return tracker
    }

    @Test func queryFollowsTriggerAndEndsAtSpace() {
        #expect(tracker(typing: "hi ::roc").query == "roc")
        #expect(tracker(typing: "hi ::roc").replacementLength == 5)
        #expect(tracker(typing: "::").query == nil)
        #expect(tracker(typing: "::roc ").query == nil)
        #expect(tracker(typing: ";;dog", trigger: ";;").query == "dog")
    }

    @Test func triggerInsideWordIsIgnored() {
        #expect(tracker(typing: "std::string").query == nil)
    }

    @Test func deleteAndResetEditTheBuffer() {
        var typed = tracker(typing: "::rocx")
        typed.apply(.deleteBackward)
        #expect(typed.query == "roc")
        typed.apply(.reset)
        typed.apply(.text("a"))
        #expect(typed.query == nil)
    }

    @Test func keysMapToPanelActionsAndBufferInput() {
        #expect(InlinePanelKeyAction(keyCode: 36, modifiers: []) == .insert)
        #expect(InlinePanelKeyAction(keyCode: 36, modifiers: .shift) == .copy)
        #expect(InlinePanelKeyAction(keyCode: 53, modifiers: []) == .close)
        #expect(InlinePanelKeyAction(keyCode: 0, modifiers: []) == nil)
        #expect(TypedKey(keyCode: 0, modifiers: .command, characters: "a") == .reset)
        #expect(TypedKey(keyCode: 51, modifiers: [], characters: "\u{8}") == .deleteBackward)
        #expect(TypedKey(keyCode: 41, modifiers: .shift, characters: ":") == .text(":"))
    }

    @Test func typedAliasBecomesItsReplacement() {
        let all = TextAliasConverter(aliases: TextAliasCatalog.all)
        #expect(all.conversion(typing: .text(">"), after: "a -") == .init(replacement: "→", deleteCount: 1))
        #expect(all.conversion(typing: .text("m"), after: "(t") == nil)
        #expect(all.conversion(typing: .text(")"), after: "(tm") == .init(replacement: "™", deleteCount: 3))
        #expect(all.conversion(typing: .text(">"), after: "a ") == nil)
        #expect(all.conversion(typing: .deleteBackward, after: "-") == nil)
        #expect(TextAliasConverter(aliases: []).conversion(typing: .text(">"), after: "-") == nil)
    }

    @Test func longerAliasMatchesAfterShorterOneConverted() {
        let all = TextAliasConverter(aliases: TextAliasCatalog.all)
        #expect(all.conversion(typing: .text(">"), after: "a ←") == .init(replacement: "↔", deleteCount: 1))
        #expect(all.conversion(typing: .text(">"), after: "≤") == .init(replacement: "⇔", deleteCount: 1))
        let withoutLeftArrow = TextAliasConverter(aliases: TextAliasCatalog.all.filter { $0.id != "leftArrow" })
        #expect(withoutLeftArrow.conversion(typing: .text(">"), after: "<-") == .init(replacement: "↔", deleteCount: 2))
    }

    @Test func emoticonsConvertOnlyAtWordStart() {
        let all = TextAliasConverter(aliases: TextAliasCatalog.all)
        #expect(all.conversion(typing: .text(")"), after: "hi :") == .init(replacement: "🙂", deleteCount: 1))
        #expect(all.conversion(typing: .text(")"), after: ":") == .init(replacement: "🙂", deleteCount: 1))
        #expect(all.conversion(typing: .text(")"), after: "note:") == nil)
        #expect(all.conversion(typing: .text("D"), after: "::") == nil)
    }

    @Test func emoticonWithAPrefixBeatsTheShorterOneInside() {
        let all = TextAliasConverter(aliases: TextAliasCatalog.all)
        #expect(all.conversion(typing: .text("("), after: "so >:") == .init(replacement: "😠", deleteCount: 2))
        #expect(all.conversion(typing: .text(")"), after: "O:-") == .init(replacement: "😇", deleteCount: 3))
        #expect(all.conversion(typing: .text("="), after: "≤") == .init(replacement: "⇐", deleteCount: 1))
    }

    @Test func aliasIDsAndSpellingsAreUnique() {
        let spellings = TextAliasCatalog.all.flatMap(\.texts)
        #expect(Set(TextAliasCatalog.all.map(\.id)).count == TextAliasCatalog.all.count)
        #expect(Set(spellings).count == spellings.count)
    }

    @Test func invalidTriggersAreRejectedWithAReasonAndFallBack() {
        #expect(InlineTrigger.problem(with: ";;") == nil)
        #expect(InlineTrigger.problem(with: "") == .empty)
        #expect(InlineTrigger.problem(with: ":::::") == .tooLong)
        #expect(InlineTrigger.problem(with: ": :") == .whitespace)
        #expect(InlineTrigger.problem(with: "em") == .onlyQueryCharacters)
        #expect(InlineTrigger.valid("em") == "::")
        #expect(InlineTrigger.valid(nil) == "::")
    }

    @Test func panelFlipsAboveCaretNearScreenBottom() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let card = PanelMetrics.cardSize
        let below = InlinePanelPlacement.place(card: card, caret: CGRect(x: 100, y: 600, width: 1, height: 16),
                                               pointer: .zero, visibleFrames: [screen])
        #expect(!below.opensAbove)
        #expect(below.frame.maxY - MenuShadowMargin.size <= 600)
        let above = InlinePanelPlacement.place(card: card, caret: CGRect(x: 100, y: 20, width: 1, height: 16),
                                               pointer: .zero, visibleFrames: [screen])
        #expect(above.opensAbove)
        #expect(above.frame.minY + MenuShadowMargin.size >= 36)
    }
}
