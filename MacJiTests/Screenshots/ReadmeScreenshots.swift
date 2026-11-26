//
//  ReadmeScreenshots.swift
//  MacJi
//
//  Created: 2026-11-26
//  Opt-in generator for the README images: MacJi's real picker, inline panel and Settings views,
//  in light and dark, plus the inline-panel GIF frames. Skipped unless make-screenshots.sh runs it.
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
        let recents = EmojiRecents(defaults: defaults)
        for emoji in Self.recentEmoji.reversed() { recents.record(emoji) }
        let catalog = await EmojiCatalog.loadBundled()

        for theme in ScreenshotTheme.allCases {
            let name = theme.rawValue
            try await renderPicker(theme, catalog: catalog, recents: recents, query: "", to: output.appending(path: "picker-\(name).png"))
            try await renderPicker(theme, catalog: catalog, recents: recents, query: "heart",
                                   to: output.appending(path: "picker-search-\(name).png"))
            try await renderSettings(theme, defaults: defaults, to: output.appending(path: "settings-\(name).png"))
            try await recordInlinePanel(theme, catalog: catalog, output: output)
        }
    }

    //////////////////

    private func renderPicker(_ theme: ScreenshotTheme, catalog: EmojiCatalog, recents: EmojiRecents, query: String,
                              to url: URL) async throws {
        let model = EmojiPickerModel(recents: recents)
        model.catalog = catalog
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
        let window = SnapshotWindow(theme: theme) {
            Backdrop(theme: theme) {
                MockWindow(title: SettingsStrings.windowTitle, size: CGSize(width: SettingsMetrics.width, height: 560)) {
                    SettingsView(settings: settings, permissions: permissions, loginItem: loginItem, updates: updates,
                                 onGrantAccess: {})
                }
            }
        }
        defer { window.close() }
        try await window.settle(.milliseconds(500))
        try window.capture().writePNG(to: url)
    }

    ////////////////////
    //// The inline-panel GIF
    /// Types "::roc" after a sentence, lets the panel grow in with its real animation, presses →
    /// to move from 🪨 to 🚀, waits for its name, then presses Return: "::roc" becomes the emoji.
    // Each frame's duration is its screen time in the GIF; the last frame of each state holds it.

    private func recordInlinePanel(_ theme: ScreenshotTheme, catalog: EmojiCatalog, output: URL) async throws {
        let panel = InlinePanelModel()
        panel.catalog = catalog
        let editor = EditorState()
        let frames = try FrameRecorder(directory: output.appending(path: "inline-panel-\(theme.rawValue)-frames"))
        let window = SnapshotWindow(theme: theme) { EditorScene(state: editor, panel: panel, theme: theme) }
        defer { window.close() }
        try await window.settle(.milliseconds(400))

        func shot(_ duration: Duration, after wait: Duration = .milliseconds(60)) async throws -> NSBitmapImageRep {
            try await window.settle(wait)
            let frame = try window.capture()
            try frames.add(frame, duration: duration)
            return frame
        }

        for visible in [true, false, true] {
            editor.caretVisible = visible
            _ = try await shot(.milliseconds(420))
        }
        for typed in [":", "::"] {
            editor.typed = typed
            _ = try await shot(.milliseconds(130))
        }

        editor.typed = "::r"
        panel.beginPresentation(growsFrom: .topLeading)
        panel.update(query: "r", trigger: "::")
        editor.panelShown = true
        for _ in 0..<6 { _ = try await shot(.milliseconds(40), after: .milliseconds(35)) }
        _ = try await shot(.milliseconds(120))
        for query in ["ro", "roc"] {
            editor.typed = "::" + query
            panel.update(query: query, trigger: "::")
            _ = try await shot(.milliseconds(query == "roc" ? 650 : 150))
        }
        panel.moveSelection(.right)
        _ = try await shot(.milliseconds(250))
        let named = try await shot(.milliseconds(1600), after: PanelMotion.nameRevealDelay + .milliseconds(250))
        try named.writePNG(to: output.appending(path: "inline-panel-\(theme.rawValue).png"))

        let chosen = try #require(panel.chosenEmoji)
        editor.typed = chosen.emoji
        editor.panelOpacity = 0.35
        _ = try await shot(.milliseconds(50), after: .milliseconds(20))
        editor.panelShown = false
        for visible in [true, false, true, false, true] {
            editor.caretVisible = visible
            _ = try await shot(.milliseconds(visible ? 600 : 420))
        }
        try frames.finish()
    }

    //////////////////
}

////////////////////
//// Scenes
/// Real MacJi views placed in mock macOS chrome. Only the chrome is fake.

@MainActor
private final class EditorState: ObservableObject {
    @Published var typed = ""
    @Published var caretVisible = true
    @Published var panelShown = false
    @Published var panelOpacity = 1.0
}

/// A document window with a sentence being typed and the inline panel under its caret.
private struct EditorScene: View {
    @ObservedObject var state: EditorState
    let panel: InlinePanelModel
    let theme: ScreenshotTheme
    private static let windowSize = CGSize(width: 700, height: 470)
    private static let caretHeight: CGFloat = 19

    var body: some View {
        Backdrop(theme: theme) {
            MockWindow(title: "Launch notes", size: Self.windowSize) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Launch checklist").font(.system(size: 22, weight: .bold))
                    Text("✅  Tests pass on CI")
                    Text("✅  Release notes written")
                    HStack(spacing: 1) {
                        Text("Tell the team we ship today\u{00A0}" + state.typed)
                        caret
                    }
                }
                .font(.system(size: 15))
                .padding(28)
            }
        }
    }

    /// The panel hangs off the caret as InlinePanelPlacement places it: card top-left just under
    /// the caret. Offscreen capture skips blur filters, so the card's blurred shadow would draw as
    /// a hard band; the card is clipped to its own frame and given an equivalent soft shadow.
    private var caret: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: 2, height: Self.caretHeight)
            .opacity(state.caretVisible ? 1 : 0)
            .overlay(alignment: .topLeading) {
                if state.panelShown {
                    InlinePanelView(model: panel, onPick: { _ in })
                        .fixedSize()
                        .padding(-MenuShadowMargin.size)
                        .clipShape(RoundedRectangle(cornerRadius: PanelMetrics.cornerRadius, style: .continuous))
                        .shadow(color: Palette.cardShadow, radius: PanelMetrics.shadowRadius / 2, y: PanelMetrics.shadowOffsetY)
                        .opacity(state.panelOpacity)
                        .offset(y: Self.caretHeight + PanelMetrics.caretGap)
                }
            }
    }
}

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
        let iconCenter = Self.canvasWidth - MockMenuBar.trailing - MockMenuBar.clockWidth - 10 - MockMenuBar.iconWidth / 2
        let cardX = Self.cardInset
        VStack(alignment: .leading, spacing: 0) {
            MockMenuBar()
            PopoverArrow()
                .fill(theme.popoverFill)
                .frame(width: Self.arrowSize.width, height: Self.arrowSize.height)
                .offset(x: iconCenter - Self.arrowSize.width / 2, y: 0.5)
                .padding(.top, Self.arrowGap)
                .zIndex(1)
            EmojiPickerView(model: model)
                .background(theme.popoverFill)
                .clipShape(shape)
                .overlay(shape.strokeBorder(Stage.hairline, lineWidth: 0.5))
                .shadow(color: Stage.shadow, radius: Stage.shadowRadius, y: Stage.shadowY)
                .offset(x: cardX)
                .padding(.bottom, Stage.margin)
        }
        .frame(width: Self.canvasWidth, alignment: .leading)
        .background(LinearGradient(colors: theme.backdrop, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: Stage.canvasCorner, style: .continuous))
    }
}

//// Scene text is sample content for the images, not app copy, so it stays here.
//////////////////
