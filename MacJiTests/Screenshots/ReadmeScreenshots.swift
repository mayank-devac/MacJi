//
//  ReadmeScreenshots.swift
//  MacJi
//
//  Created: 2026-11-26
//  Opt-in generator for the README images: MacJi's real picker tabs, Settings, Aliases page and
//  editor, in light and dark, plus the typing GIFs' frames. Skipped unless make-screenshots.sh runs it.
//

import AppKit
import SwiftUI
import Testing
@testable import MacJi

@MainActor
@Suite(.serialized, .enabled(if: ScreenshotOutput.directory != nil, "Run scripts/make-screenshots.sh"))
struct ReadmeScreenshots {
    private static let defaultsSuite = "io.github.mayank-devac.macji.screenshots"
    private static let recentEmoji = ["🚀", "🎉", "❤️", "👍", "😂", "✨", "🔥", "✅", "👀"]

    ////////////////////
    //// Render everything
    /// A throwaway UserDefaults suite holds the settings and recents, so the generator never
    // touches the developer's own MacJi preferences.

    @Test func renderReadmeImages() async throws {
        let output = try #require(ScreenshotOutput.directory)
        let defaults = try #require(UserDefaults(suiteName: Self.defaultsSuite))
        defaults.removePersistentDomain(forName: Self.defaultsSuite)
        defer { defaults.removePersistentDomain(forName: Self.defaultsSuite) }
        AppSettings.registerDefaults(in: defaults)
        let recents = GlyphRecents(defaults: defaults)
        for emoji in Self.recentEmoji.reversed() { recents.record(emoji) }
        let library = await GlyphLibrary.loadBundled()

        for theme in ScreenshotTheme.allCases {
            let name = theme.rawValue
            func file(_ stem: String) -> URL { output.appending(path: "\(stem)-\(name).png") }
            try await renderPicker(theme, library: library, recents: recents, tab: .emoji, query: "", to: file("picker"))
            try await renderPicker(theme, library: library, recents: recents, tab: .emoji, query: "heart", to: file("picker-search"))
            try await renderPicker(theme, library: library, recents: recents, tab: .symbols, query: "", to: file("picker-symbols"))
            try await renderPicker(theme, library: library, recents: recents, tab: .emoticons, query: "", to: file("picker-emoticons"))
            try await renderSettings(theme, defaults: defaults, to: file("settings"))
            try await renderAliasesPage(theme, to: file("aliases-page"))
            try await renderAliasEditor(theme, to: file("alias-editor"))
            for script in Self.typingScripts {
                try await TypingRecorder.record(script, theme: theme, library: library, output: output)
            }
        }
    }

    //////////////////

    ////////////////////
    //// Typing GIFs
    /// One per typing feature: the emoji panel, the symbol panel with its category bar, emoticon
    /// suggestions, and aliases converting as the last character is typed.

    private static var typingScripts: [TypingScript] {
        func emoji(_ term: String) -> InlinePanelModel.Search {
            .init(kind: .emoji, typed: "::" + term, term: term, isAutocomplete: false)
        }
        func symbol(_ term: String) -> InlinePanelModel.Search {
            .init(kind: .symbols, typed: "##" + term, term: term, isAutocomplete: false)
        }
        let suggestion = InlinePanelModel.Search(kind: .emoticons, typed: "^_", term: "^_", isAutocomplete: true)
        return [
            TypingScript(name: "inline-panel", windowTitle: "Launch notes", lineStart: "Tell the team we ship today", steps: [
                .text(":", hold: .milliseconds(130)), .text("::", hold: .milliseconds(130)),
                .search("::r", emoji("r"), hold: .milliseconds(120)), .search("::ro", emoji("ro"), hold: .milliseconds(150)),
                .search("::roc", emoji("roc"), hold: .milliseconds(650)), .move(.right, hold: .milliseconds(250)),
                .still(hold: .milliseconds(1600)), .pick,
            ]),
            TypingScript(name: "symbol-panel", windowTitle: "Launch notes", lineStart: "Next: tests", steps: [
                .text("#", hold: .milliseconds(130)), .text("##", hold: .milliseconds(130)),
                .search("##r", symbol("r"), hold: .milliseconds(120)), .search("##ra", symbol("ra"), hold: .milliseconds(150)),
                .search("##rar", symbol("rar"), hold: .milliseconds(150)), .search("##rarr", symbol("rarr"), hold: .milliseconds(650)),
                .still(hold: .milliseconds(1600)), .pick, .text("→ ship", hold: .milliseconds(300)),
            ]),
            TypingScript(name: "emoticon-panel", windowTitle: "Launch notes", lineStart: "Thanks for the help!", steps: [
                .text("^", hold: .milliseconds(200)), .search("^_", suggestion, hold: .milliseconds(650)),
                .move(.down, hold: .milliseconds(300)), .still(hold: .milliseconds(1600)), .pick,
            ]),
            TypingScript(name: "aliases", windowTitle: "Launch notes", lineStart: "Flow:", steps: [
                .text("build", hold: .milliseconds(250)), .text("build -", hold: .milliseconds(160)),
                .text("build →", hold: .milliseconds(500)), .text("build → ship", hold: .milliseconds(250)),
                .text("build → ship ..", hold: .milliseconds(160)), .text("build → ship …", hold: .milliseconds(500)),
                .text("build → ship … !", hold: .milliseconds(160)), .text("build → ship … ≠", hold: .milliseconds(500)),
                .text("build → ship … ≠ (c", hold: .milliseconds(160)), .text("build → ship … ≠ ©", hold: .milliseconds(500)),
                .still(hold: .milliseconds(1200)),
            ]),
        ]
    }

    //////////////////

    private func renderPicker(_ theme: ScreenshotTheme, library: GlyphLibrary, recents: GlyphRecents, tab: PickerTab,
                              query: String, to url: URL) async throws {
        let model = EmojiPickerModel(recents: recents)
        model.library = library
        model.setVisibleTabs(PickerTab.allCases)
        model.tab = tab
        model.prepareForOpen()
        let window = SnapshotWindow(theme: theme) { PickerScene(model: model, theme: theme) }
        defer { window.close() }
        try await window.settle(.milliseconds(300))
        if query.isEmpty {
            model.moveSelection(.right)
        } else {
            model.query = query
        }
        try await window.settle(.milliseconds(300))
        try window.capture().writePNG(to: url)
    }

    private func renderSettings(_ theme: ScreenshotTheme, defaults: UserDefaults, to url: URL) async throws {
        let settings = AppSettings(defaults: defaults)
        let permissions = PermissionStatus()
        let loginItem = LoginItem()
        let updates = UpdateController()
        try await renderWindow(theme, height: 560, to: url) {
            SettingsView(settings: settings, permissions: permissions, loginItem: loginItem, updates: updates,
                         onGrantAccess: {}, onQuit: {})
        }
    }

    ////////////////////
    //// Aliases page and editor
    /// The page at its top, where one alias of your own leads Arrows, and the editor open on it.

    private static let sampleAlias = TextAlias(id: CustomTextAliasCodec.idPrefix + "sample", texts: ["-->", "==>"],
                                               replacements: ["⟶", "⟹", "➜"], group: .arrows, boundary: .anywhere,
                                               name: "Long arrow")

    private func renderAliasesPage(_ theme: ScreenshotTheme, to url: URL) async throws {
        try await renderWindow(theme, height: 560, to: url) {
            TextAliasesPage(builtIn: TextAliasCatalog.all, custom: .constant([Self.sampleAlias]),
                            disabled: .constant(Set(TextAliasCatalog.offByDefault)), hidden: .constant([]),
                            triggers: ["::", "##"], onBack: {})
        }
    }

    private func renderAliasEditor(_ theme: ScreenshotTheme, to url: URL) async throws {
        // The sheet has a fixed size, so the window grows by its title bar and divider.
        let height = SettingsMetrics.editorHeight + Stage.titleBarHeight + 1
        try await renderWindow(theme, height: height, width: SettingsMetrics.editorWidth, to: url) {
            AliasEditorSheet(editing: Self.sampleAlias, initialGroup: .arrows, others: [], triggers: ["::", "##"],
                             onSave: { _ in }, onDelete: {})
        }
    }

    //////////////////

    private func renderWindow<Content: View>(_ theme: ScreenshotTheme, height: CGFloat, width: CGFloat = SettingsMetrics.width,
                                             to url: URL, @ViewBuilder content: () -> Content) async throws {
        let window = SnapshotWindow(theme: theme) {
            Backdrop(theme: theme) {
                MockWindow(title: SettingsStrings.windowTitle, size: CGSize(width: width, height: height), content: content)
            }
        }
        defer { window.close() }
        try await window.settle(.milliseconds(500))
        try window.capture().writePNG(to: url)
    }
}

////////////////////
//// Scenes
/// Real MacJi views placed in mock macOS chrome. Only the chrome is fake.

/// The picker popover hanging from MacJi's menu-bar icon.
private struct PickerScene: View {
    let model: EmojiPickerModel
    let theme: ScreenshotTheme
    private static let cardInset: CGFloat = 28
    private static let canvasWidth = PickerMetrics.size.width + cardInset * 2
    private static let arrowSize = CGSize(width: 22, height: 10)
    private static let arrowGap: CGFloat = 4

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Stage.windowCorner, style: .continuous)
        let fill = Color(nsColor: theme.materialStandIn)
        let iconCenter = Self.canvasWidth - MockMenuBar.trailing - MockMenuBar.clockWidth - MockMenuBar.spacing
            - MockMenuBar.iconWidth / 2
        Backdrop(theme: theme, insets: EdgeInsets(top: 0, leading: 0, bottom: Stage.margin, trailing: 0)) {
            VStack(alignment: .leading, spacing: 0) {
                MockMenuBar()
                PopoverArrow()
                    .fill(fill)
                    .frame(width: Self.arrowSize.width, height: Self.arrowSize.height)
                    .offset(x: iconCenter - Self.arrowSize.width / 2, y: 0.5)
                    .padding(.top, Self.arrowGap)
                    .zIndex(1)
                EmojiPickerView(model: model, onOpenSettings: {})
                    .background(fill)
                    .clipShape(shape)
                    .overlay(shape.strokeBorder(Stage.hairline, lineWidth: 0.5))
                    .shadow(color: Stage.shadow, radius: Stage.shadowRadius, y: Stage.shadowY)
                    .offset(x: Self.cardInset)
            }
            .frame(width: Self.canvasWidth, alignment: .leading)
        }
    }
}

//// Scene text is sample content for the images, not app copy, so it stays here.
//////////////////
