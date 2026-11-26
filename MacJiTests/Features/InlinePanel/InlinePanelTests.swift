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
    private func tracker(typing text: String,
                         triggers: [InlinePanelKind: String] = [.emoji: "::", .symbols: "##"]) -> TriggerTracker {
        var tracker = TriggerTracker(triggers: triggers)
        text.forEach { tracker.apply(.text(String($0))) }
        return tracker
    }

    @Test func queryFollowsTriggerAndEndsAtSpace() {
        #expect(tracker(typing: "hi ::roc").query == .init(kind: .emoji, trigger: "::", term: "roc"))
        #expect(tracker(typing: "hi ::roc").replacementLength == 5)
        #expect(tracker(typing: "::").query == nil)
        #expect(tracker(typing: "::roc ").query == nil)
        #expect(tracker(typing: ";;dog", triggers: [.emoji: ";;"]).query?.term == "dog")
    }

    @Test func triggerInsideWordIsIgnored() {
        #expect(tracker(typing: "std::string").query == nil)
        #expect(tracker(typing: "a##b").query == nil)
    }

    @Test func lastTriggerTypedPicksThePanel() {
        #expect(tracker(typing: "::a ##arr").query == .init(kind: .symbols, trigger: "##", term: "arr"))
        #expect(tracker(typing: "##b ::roc").query?.kind == .emoji)
        #expect(tracker(typing: "## Heading").query == nil)
        #expect(tracker(typing: ";;shrug", triggers: [.emoji: "::", .emoticons: ""]).query == nil)
    }

    @Test func deleteAndResetEditTheBuffer() {
        var typed = tracker(typing: "::rocx")
        typed.apply(.deleteBackward)
        #expect(typed.query?.term == "roc")
        typed.apply(.reset)
        typed.apply(.text("a"))
        #expect(typed.query == nil)
    }

    @Test func longTextIsSplitIntoWholeCharacterChunks() {
        let shrug = "¯\\_(ツ)_/¯ (╯°□°)╯︵ ┻━┻"
        let chunks = TextInserter.chunks(of: shrug, maxUnits: 20)
        #expect(chunks.joined() == shrug)
        #expect(chunks.allSatisfy { $0.utf16.count <= 20 })
        let family = "👨‍👩‍👧‍👦"
        #expect(TextInserter.chunks(of: "a" + family, maxUnits: 4) == ["a", family])
        #expect(TextInserter.chunks(of: "", maxUnits: 20).isEmpty)
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

    @Test func tabFiltersOnlyInPanelsWithFilters() {
        #expect(InlinePanelKeyAction(keyCode: 48, modifiers: [], hasFilters: true) == .nextFilter)
        #expect(InlinePanelKeyAction(keyCode: 48, modifiers: .shift, hasFilters: true) == .previousFilter)
        #expect(InlinePanelKeyAction(keyCode: 48, modifiers: [], hasFilters: false) == nil)
        #expect(InlinePanelKeyAction(keyCode: 48, modifiers: .command, hasFilters: true) == nil)
        #expect(SymbolCategory.cycle(.technical, forward: true) == nil)
        #expect(SymbolCategory.cycle(nil, forward: false) == .technical)
    }

    ////////////////////
    //// Emoticon autocomplete
    /// The run after the last space opens suggestions once it is long enough, holds a symbol and
    // starts an emoticon. Esc silences it until the next word.

    private func autocomplete(_ length: Int = 2, triggers: [String] = ["::", "##"]) -> EmoticonAutocomplete {
        EmoticonAutocomplete(emoticons: ["^_^", "^_~", "owo", ":-)", "--_--", "8)", "XD", "((>_<))", "</3?", ">=)", "\\(^o^)/"],
                             minimumLength: length,
                             triggers: triggers)
    }

    @Test func suggestsWhenTheTypedRunStartsAnEmoticon() {
        var suggest = autocomplete()
        #expect(suggest.run(in: "nice ^_") == "^_")
        #expect(suggest.run(in: "nice ^") == nil)
        #expect(suggest.run(in: "nice ^_ ") == nil)
        #expect(suggest.run(in: "^_^x") == nil)
        #expect(suggest.run(in: "8)") == nil)
        var longer = autocomplete(3)
        #expect(longer.run(in: "^_") == nil)
        var off = autocomplete(0)
        #expect(off.run(in: "^_") == nil)
    }

    @Test func wordsCodeAndTriggersNeverSuggest() {
        var suggest = autocomplete(triggers: [":-"])
        #expect(suggest.run(in: "ow") == nil)
        #expect(suggest.run(in: "xd") == nil)
        #expect(suggest.run(in: "--") == nil)
        #expect(suggest.run(in: ":-") == nil)
        #expect(suggest.run(in: "f((") == nil)
        #expect(suggest.run(in: "if ((") == nil)
        #expect(suggest.run(in: "a </") == nil)
        #expect(suggest.run(in: "b >=") == nil)
        #expect(suggest.run(in: "\\(") == nil)
    }

    @Test func escSilencesTheRunUntilTheNextWord() {
        var suggest = autocomplete()
        suggest.dismiss("^_")
        #expect(suggest.run(in: "^_") == nil)
        #expect(suggest.run(in: "^_^") == nil)
        #expect(suggest.run(in: "^_^ ") == nil)
        #expect(suggest.run(in: "^_^ ^_") == "^_")
    }

    @Test func completionsContinueThePrefixUsedFirst() {
        let emoticons = EmoticonCatalog(glyphs: ["^_^", "^_~", "(^_^)"].map {
            Glyph(text: $0, description: "face", category: EmoticonCategory.happy.rawValue, aliases: [], tags: [])
        })
        #expect(GlyphSearch.starting(with: "^_", in: emoticons, limit: 9).map(\.text) == ["^_^", "^_~"])
        #expect(GlyphSearch.starting(with: "^_", in: emoticons, useCounts: ["^_~": 3], limit: 9).map(\.text) == ["^_~", "^_^"])
        #expect(GlyphSearch.starting(with: "^_^", in: emoticons, limit: 9).isEmpty)
    }

    //////////////////

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

    @Test func triggersMayNotContainEachOtherAndOnlyEmoticonsMayBeBlank() {
        let others: [InlinePanelKind: String] = [.emoji: "::", .symbols: "##", .emoticons: ""]
        #expect(InlineTrigger.problem(with: ":", for: .symbols, others: others) == .overlaps(.emoji, trigger: "::"))
        #expect(InlineTrigger.problem(with: "##x", for: .emoticons, others: others) == .overlaps(.symbols, trigger: "##"))
        #expect(InlineTrigger.problem(with: ";;", for: .emoticons, others: others) == nil)
        #expect(InlineTrigger.problem(with: "", for: .emoticons, others: others) == nil)
        #expect(InlineTrigger.problem(with: "", for: .symbols, others: others) == .empty)
        #expect(InlineTrigger.valid("::", for: .symbols, others: others) == "##")
        #expect(InlineTrigger.valid(nil, for: .symbols, others: [.emoji: "##"]) == "")
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
