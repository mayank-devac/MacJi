//
//  CustomTextAliasTests.swift
//  MacJi
//
//  Created: 2026-11-27
//  Custom alias validation, storage that keeps unreadable entries, and yours overriding a
//  built-in spelling.
//

import Testing
@testable import MacJi

struct CustomTextAliasTests {
    private func mine(_ texts: [String], _ outputs: [String], name: String = "Check mark", id: String = "custom-1") -> TextAlias {
        TextAlias(id: id, texts: texts, replacements: outputs, group: .symbols, boundary: .afterSpace, name: name)
    }

    @Test func spellingsMustBeTypableWithoutFiringInsideWordsOrTriggers() {
        let others = [mine(["(v)"], ["✓"], name: "Tick", id: "custom-2")]
        func problem(_ text: String, in texts: [String]? = nil) -> CustomTextAliasValidator.Problem? {
            let texts = texts ?? [text]
            return CustomTextAliasValidator.spellingProblem(at: texts.count - 1, in: texts, triggers: ["::", "##"], others: others)
        }
        #expect(problem("[x]") == nil)
        #expect(problem("") == nil)
        #expect(problem("x") == .spellingTooShort)
        #expect(problem("brb") == .spellingOnlyLettersOrDigits)
        #expect(problem("[ x]") == .spellingHasSpace)
        #expect(problem("##x") == .spellingHasTrigger("##"))
        #expect(problem("[x]", in: ["[x]", "[x]"]) == .spellingRepeated)
        #expect(problem("(v)") == .spellingTaken("Tick"))
        #expect(problem(String(repeating: "-", count: 17)) == .spellingTooLong)
    }

    @Test func aDraftSavesOnlyWithANameASpellingAndAnOutputAndDropsBlankRows() {
        var draft = CustomTextAliasValidator.Draft(name: "  Check mark ", group: .symbols, texts: ["[x]", ""],
                                                   replacements: ["✓", " ", "✔"], wordStartOnly: true)
        let alias = CustomTextAliasValidator.alias(from: draft, id: "custom-1", triggers: [], others: [])
        #expect(alias == mine(["[x]"], ["✓", "✔"]))
        draft.replacements = [""]
        #expect(CustomTextAliasValidator.problems(in: draft, triggers: [], others: []) == [.noOutput])
        draft.name = ""
        #expect(CustomTextAliasValidator.problems(in: draft, triggers: [], others: []) == [.nameMissing, .noOutput])
    }

    @Test func storageRoundTripsAndKeepsEntriesItCannotRead() {
        let future: [String: Any] = ["id": "custom-9", "name": "Later", "group": "kaomoji", "texts": ["(x)"],
                                     "replacements": ["✗"], "wordStartOnly": true]
        let stored = CustomTextAliasCodec.encode([mine(["[x]"], ["✓", "✔"])], keeping: [future, "junk"])
        let decoded = CustomTextAliasCodec.decode(stored)
        #expect(decoded.aliases == [mine(["[x]"], ["✓", "✔"])])
        #expect(decoded.unreadable.count == 2)
        #expect(CustomTextAliasCodec.decode("not a list").aliases.isEmpty)
    }

    @Test func yoursWinOverABuiltInSpellingAndTypesItsFirstOutput() {
        let custom = [mine(["->", "-->"], ["⟶", "→"], name: "Long arrow")]
        let active = ActiveTextAliases.make(builtIn: TextAliasCatalog.all, custom: custom, disabled: [])
        let converter = TextAliasConverter(aliases: active)
        #expect(converter.conversion(typing: .text(">"), after: "a -") == .init(replacement: "⟶", deleteCount: 1))
        #expect(!active.contains { $0.id == "rightArrow" })
        let withMineOff = ActiveTextAliases.make(builtIn: TextAliasCatalog.all, custom: custom, disabled: ["custom-1"])
        #expect(TextAliasConverter(aliases: withMineOff).conversion(typing: .text(">"), after: "a -")?.replacement == "→")
        #expect(ActiveTextAliases.builtIn(using: "->")?.id == "rightArrow")
    }

    @Test func searchFindsEveryOutputByNameOrSpellingOnceAndFirst() {
        let catalog = AliasGlyphs.catalog(from: [mine(["[x]"], ["✓", "✔"]), mine(["(v)"], ["✓"], name: "Tick", id: "custom-2")])
        #expect(GlyphSearch.ranked("check", in: catalog, limit: 8).map(\.text) == ["✓", "✔"])
        #expect(GlyphSearch.ranked("tick", in: catalog, limit: 8).isEmpty)
        #expect(GlyphSearch.ranked("[x]", in: catalog, limit: 8).map(\.text) == ["✓", "✔"])
        let found = GlyphSearch.ranked("check", in: catalog, limit: 8)
        let emoji = Glyph(text: "✔", description: "check mark", category: "Symbols", aliases: [], tags: [])
        let rocket = Glyph(text: "🚀", description: "rocket", category: "Travel & Places", aliases: [], tags: [])
        #expect(AliasGlyphs.merge(found, before: [emoji, rocket]).map(\.text) == ["✓", "✔", "🚀"])
        #expect(AliasGlyphs.spelling(of: emoji, in: catalog) == "[x]")
        #expect(AliasGlyphs.spelling(of: rocket, in: catalog) == nil)
    }
}
