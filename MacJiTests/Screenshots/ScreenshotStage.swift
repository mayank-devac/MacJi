//
//  ScreenshotStage.swift
//  MacJi
//
//  Created: 2026-11-26
//  The stage for README images: light and dark themes, an opaque backdrop, mock window and
//  menu-bar chrome, and an offscreen window that renders any SwiftUI view to a PNG.
//

import AppKit
import SwiftUI
@testable import MacJi

/// Where the generator writes; set only by scripts/make-screenshots.sh, so normal runs skip it.
enum ScreenshotOutput {
    static var directory: URL? {
        ProcessInfo.processInfo.environment["MACJI_SCREENSHOTS_DIR"].map { URL(filePath: $0, directoryHint: .isDirectory) }
    }
}

////////////////////
//// Themes
/// Every image is rendered once per theme so the README can serve the one matching GitHub's.
/// The backdrop is opaque so dark text never sits on a dark page, or light text on a light one.

enum ScreenshotTheme: String, CaseIterable {
    case light, dark

    var appearance: NSAppearance? {
        NSAppearance(named: self == .light ? .aqua : .darkAqua)
    }

    var backdrop: [Color] {
        switch self {
        case .light: [Color(red: 0.93, green: 0.95, blue: 0.98), Color(red: 0.84, green: 0.88, blue: 0.94)]
        case .dark: [Color(red: 0.14, green: 0.16, blue: 0.20), Color(red: 0.07, green: 0.08, blue: 0.11)]
        }
    }

    /// What the popover material looks like on screen; cacheDisplay can't capture the live blur.
    var materialStandIn: NSColor {
        self == .light ? NSColor(white: 0.985, alpha: 1) : NSColor(white: 0.17, alpha: 1)
    }
}

enum Stage {
    static let margin: CGFloat = 44
    static let canvasCorner: CGFloat = 18
    static let windowCorner: CGFloat = 12
    static let titleBarHeight: CGFloat = 30
    static let trafficLights = [Color(red: 1, green: 0.37, blue: 0.34), Color(red: 1, green: 0.74, blue: 0.18),
                                Color(red: 0.16, green: 0.78, blue: 0.25)]
    static let trafficLightSize: CGFloat = 12
    static let hairline = Color.primary.opacity(0.12)
    static let shadow = Color.black.opacity(0.28)
    static let shadowRadius: CGFloat = 26
    static let shadowY: CGFloat = 14
    static let scale: CGFloat = 2
}

//// Colours here describe the stage, not MacJi, so they stay out of Constants/.
//////////////////

/// Gradient canvas with rounded corners; the corners stay transparent so they take the page colour.
/// `insets` defaults to the stage margin on every side; the picker scene keeps its menu bar flush.
struct Backdrop<Content: View>: View {
    let theme: ScreenshotTheme
    var insets = EdgeInsets(top: Stage.margin, leading: Stage.margin, bottom: Stage.margin, trailing: Stage.margin)
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(insets)
            .background(LinearGradient(colors: theme.backdrop, startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(RoundedRectangle(cornerRadius: Stage.canvasCorner, style: .continuous))
    }
}

/// A macOS document window: traffic lights, a centred title, and the content below.
struct MockWindow<Content: View>: View {
    let title: String
    let size: CGSize
    @ViewBuilder let content: Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Stage.windowCorner, style: .continuous)
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 8) {
                    ForEach(Stage.trafficLights.indices, id: \.self) { index in
                        Circle().fill(Stage.trafficLights[index]).frame(width: Stage.trafficLightSize, height: Stage.trafficLightSize)
                    }
                    Spacer()
                }
                .padding(.leading, 14)
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
            }
            .frame(height: Stage.titleBarHeight)
            .background(Color(nsColor: .windowBackgroundColor))
            Divider()
            content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: size.width, height: size.height)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(shape)
        .overlay(shape.strokeBorder(Stage.hairline, lineWidth: 0.5))
        .shadow(color: Stage.shadow, radius: Stage.shadowRadius, y: Stage.shadowY)
    }
}

/// The right end of the menu bar: MacJi's highlighted icon and a clock.
struct MockMenuBar: View {
    static let height: CGFloat = 26
    static let iconWidth: CGFloat = 26
    static let clockWidth: CGFloat = 118
    static let trailing: CGFloat = 14
    static let spacing: CGFloat = 10

    var body: some View {
        HStack(spacing: Self.spacing) {
            Spacer()
            Image(systemName: SymbolNames.menuBar)
                .font(.system(size: 14, weight: .medium))
                .frame(width: Self.iconWidth, height: 20)
                .background(Color.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            Text("Thu 26 Nov  9:41")
                .font(.system(size: 13, weight: .medium))
                .frame(width: Self.clockWidth, alignment: .trailing)
        }
        .padding(.trailing, Self.trailing)
        .frame(height: Self.height)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.72))
    }
}

/// Small upward triangle that joins a popover to the menu-bar icon.
struct PopoverArrow: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

////////////////////
//// Offscreen rendering
/// The view lives in a real, nearly transparent window so SwiftUI runs `onAppear`, tasks and
/// animations exactly as in the app; `cacheDisplay` then draws it.
// The window must be on screen and unoccluded or SwiftUI pauses its animations, so it is ordered
// front at 1% opacity and ignores the mouse for the few seconds it exists.

@MainActor
final class SnapshotWindow {
    private let window: NSWindow
    private let host: NSView
    private let materialStandIn: NSColor

    init<Content: View>(theme: ScreenshotTheme, @ViewBuilder content: () -> Content) {
        let hosting = NSHostingView(rootView: content())
        hosting.frame = CGRect(origin: .zero, size: hosting.fittingSize)
        host = hosting
        materialStandIn = theme.materialStandIn
        window = RetinaWindow(contentRect: hosting.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.appearance = theme.appearance
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = true
        window.alphaValue = 0.01
        window.contentView = hosting
        window.orderFrontRegardless()
    }

    func settle(_ duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }

    func capture() throws -> NSBitmapImageRep {
        fillMaterials(in: host)
        host.layoutSubtreeIfNeeded()
        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { throw SnapshotError.render }
        host.cacheDisplay(in: host.bounds, to: rep)
        guard let srgb = rep.converting(to: .sRGB, renderingIntent: .default) else { throw SnapshotError.render }
        return srgb
    }

    func close() {
        window.orderOut(nil)
        window.close()
    }

    /// Behind-window blur is composited by the window server, outside the view tree, so each
    /// material gets an opaque stand-in of its on-screen colour, clipped to the material's mask.
    private func fillMaterials(in view: NSView) {
        if let effect = view as? NSVisualEffectView, !effect.subviews.contains(where: { $0 is MaterialStandIn }) {
            let standIn = MaterialStandIn(color: materialStandIn, radius: effect.maskImage?.capInsets.top ?? 0)
            standIn.frame = effect.bounds
            standIn.autoresizingMask = [.width, .height]
            effect.addSubview(standIn)
        }
        view.subviews.forEach(fillMaterials)
    }
}

/// Renders at 2x on any display, so the images stay sharp on non-Retina screens too.
// AppKit controls (switches, buttons) draw in their inactive-window style: macOS 14+ never
// lets a background process take focus, which is also what keeps the generator unobtrusive.
private final class RetinaWindow: NSWindow {
    override var backingScaleFactor: CGFloat { Stage.scale }
}

private final class MaterialStandIn: NSView {
    private let color: NSColor
    private let radius: CGFloat

    init(color: NSColor, radius: CGFloat) {
        self.color = color
        self.radius = radius
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func draw(_ dirtyRect: NSRect) {
        color.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: radius, yRadius: radius).fill()
    }
}

enum SnapshotError: Error {
    case render, encode
}

extension NSBitmapImageRep {
    func writePNG(to url: URL) throws {
        guard let data = representation(using: .png, properties: [:]) else { throw SnapshotError.encode }
        try data.write(to: url)
    }
}

//// The PNGs are tagged sRGB so browsers and ffmpeg show the same colours.
//////////////////

////////////////////
//// GIF frames
/// Frames are written as numbered PNGs plus an ffmpeg concat list with each frame's duration;
/// scripts/make-screenshots.sh turns the list into a palette-optimised GIF.

@MainActor
final class FrameRecorder {
    private let directory: URL
    private var list = ""
    private var count = 0

    init(directory: URL) throws {
        self.directory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func add(_ frame: NSBitmapImageRep, duration: Duration) throws {
        let file = String(format: "frame-%03d.png", count)
        try frame.writePNG(to: directory.appending(path: file))
        let seconds = Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18
        list += "file '\(file)'\nduration \(String(format: "%.3f", seconds))\n"
        count += 1
    }

    /// ffmpeg's concat demuxer ignores the last duration unless the last file is listed again.
    func finish() throws {
        let lastFile = String(format: "frame-%03d.png", count - 1)
        try (list + "file '\(lastFile)'\n").write(to: directory.appending(path: "frames.txt"), atomically: true, encoding: .utf8)
    }
}

//////////////////
