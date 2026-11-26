//
//  TypingRecording.swift
//  MacJi
//
//  Created: 2026-11-27
//  Scripted typing GIFs for the README: a document window, the real inline panel under its
//  caret, and a recorder that plays typing, panel and pick steps into frames.
//

import AppKit
import SwiftUI
@testable import MacJi

////////////////////
//// A typing script
/// Each step sets what the line shows after its fixed start and, while a panel is open, what
/// it searches. `pick` replaces the search's typed text with the chosen glyph, as Return does.

enum TypingStep {
    /// The text after the line's start, with no panel open.
    case text(String, hold: Duration)
    /// The text and the panel's search; the first one opens the panel with its real animation.
    case search(String, InlinePanelModel.Search, hold: Duration)
    case move(MenuKey, hold: Duration)
    /// Waits for the focused glyph's name, holds, and writes this frame as the still PNG.
    case still(hold: Duration)
    case pick
}

struct TypingScript {
    /// File stem: "<name>-<theme>.png", "<name>-<theme>-frames/".
    let name: String
    let windowTitle: String
    let lineStart: String
    let steps: [TypingStep]
}

//////////////////

////////////////////
//// Recording
/// The caret blinks, the script plays, the caret blinks again. Each frame's duration is its
/// screen time in the GIF; the last frame of each state holds it.

@MainActor
enum TypingRecorder {
    static func record(_ script: TypingScript, theme: ScreenshotTheme, library: GlyphLibrary, output: URL) async throws {
        let panel = InlinePanelModel()
        panel.library = library
        let editor = EditorState(lineStart: script.lineStart)
        let frames = try FrameRecorder(directory: output.appending(path: "\(script.name)-\(theme.rawValue)-frames"))
        let window = SnapshotWindow(theme: theme) {
            EditorScene(state: editor, panel: panel, theme: theme, title: script.windowTitle)
        }
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
        for step in script.steps {
            switch step {
            case .text(let text, let hold):
                editor.typed = text
                _ = try await shot(hold)
            case .search(let text, let search, let hold):
                editor.typed = text
                if editor.panelShown {
                    panel.update(search)
                } else {
                    panel.beginPresentation(growsFrom: .topLeading, useCounts: [:])
                    panel.update(search)
                    editor.panelShown = true
                    for _ in 0..<6 { _ = try await shot(.milliseconds(40), after: .milliseconds(35)) }
                }
                _ = try await shot(hold)
            case .move(let key, let hold):
                panel.moveSelection(key)
                _ = try await shot(hold)
            case .still(let hold):
                let named = try await shot(hold, after: PanelMotion.nameRevealDelay + .milliseconds(250))
                try named.writePNG(to: output.appending(path: "\(script.name)-\(theme.rawValue).png"))
            case .pick:
                guard let search = panel.search, let chosen = panel.chosenGlyph else { throw SnapshotError.render }
                editor.typed = String(editor.typed.dropLast(search.typed.count)) + chosen.text
                editor.panelOpacity = 0.35
                _ = try await shot(.milliseconds(50), after: .milliseconds(20))
                editor.panelShown = false
                editor.panelOpacity = 1
            }
        }
        for visible in [true, false, true, false, true] {
            editor.caretVisible = visible
            _ = try await shot(.milliseconds(visible ? 600 : 420))
        }
        try frames.finish()
    }
}

//////////////////

////////////////////
//// The document
/// A document window with a line being typed and the inline panel under its caret. Only the
/// chrome and the sample text are fake.

@MainActor
private final class EditorState: ObservableObject {
    let lineStart: String
    @Published var typed = ""
    @Published var caretVisible = true
    @Published var panelShown = false
    @Published var panelOpacity = 1.0

    init(lineStart: String) {
        self.lineStart = lineStart
    }
}

private struct EditorScene: View {
    @ObservedObject var state: EditorState
    let panel: InlinePanelModel
    let theme: ScreenshotTheme
    let title: String
    private static let windowSize = CGSize(width: 700, height: 470)
    private static let caretHeight: CGFloat = 19

    /// Spaces are non-breaking so a trailing one still shows before the caret.
    var body: some View {
        Backdrop(theme: theme) {
            MockWindow(title: title, size: Self.windowSize) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Launch checklist").font(.system(size: 22, weight: .bold))
                    Text("✅  Tests pass on CI")
                    Text("✅  Release notes written")
                    HStack(spacing: 1) {
                        Text((state.lineStart + " " + state.typed).replacingOccurrences(of: " ", with: "\u{00A0}"))
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

//// Scene text is sample content for the images, not app copy, so it stays here.
//////////////////
