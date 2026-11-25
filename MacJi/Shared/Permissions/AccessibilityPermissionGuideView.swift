//
//  AccessibilityPermissionGuideView.swift
//  MacJi
//
//  Created: 2026-11-26
//  Compact drag-to-allow panel shown next to System Settings → Accessibility.
//  Ported from Octopus: octopus/UI/Permissions/AccessibilityPermissionGuideView.swift
//

import AppKit
import SwiftUI

struct AccessibilityPermissionGuideView: View {
    var onClose: () -> Void

    private enum ResetState { case idle, running, done, failed }

    private let appURL = Bundle.main.bundleURL
    private let appName = Bundle.main.bundleURL.deletingPathExtension().lastPathComponent
    @State private var resetState = ResetState.idle

    var body: some View {
        VStack(alignment: .leading, spacing: GuideMetrics.spacing) {
            dragChip

            HStack(alignment: .top, spacing: GuideMetrics.chipPadding) {
                Image(systemName: SymbolNames.dragHint)
                    .font(.system(size: GuideMetrics.hintIconSize, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(PermissionStrings.guideTitle(appName))
                        .font(.system(size: GuideMetrics.titleSize, weight: .semibold))
                    Text(PermissionStrings.guideSubtitle)
                        .font(.system(size: GuideMetrics.detailSize))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Image(systemName: SymbolNames.close)
                        .font(.system(size: GuideMetrics.closeIconSize))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(PermissionStrings.close)
            }
            .padding(.leading, GuideMetrics.textLeading)

            resetRow
                .padding(.leading, GuideMetrics.textLeading)
        }
        .padding(GuideMetrics.padding)
        .frame(width: GuideMetrics.width, alignment: .top)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: GuideMetrics.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: GuideMetrics.cornerRadius, style: .continuous).strokeBorder(Palette.guideCardStroke))
    }

    ////////////////////
    //// Drag chip
    /// The whole chip is the drag handle, so it reads as one obvious target.
    // Dropping the .app bundle's file URL mirrors a Finder drag, which the Accessibility list accepts.

    private var dragChip: some View {
        let chip = RoundedRectangle(cornerRadius: GuideMetrics.chipCornerRadius, style: .continuous)
        return HStack(spacing: GuideMetrics.chipSpacing) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: GuideMetrics.iconSize, height: GuideMetrics.iconSize)
                .padding(GuideMetrics.iconPadding)
                .background(Palette.guideIconBackground, in: RoundedRectangle(cornerRadius: GuideMetrics.iconCornerRadius, style: .continuous))
            Text(appName)
                .font(.system(size: GuideMetrics.appNameSize, weight: .semibold))
            Spacer(minLength: 0)
            Image(systemName: SymbolNames.dragHandle)
                .foregroundStyle(.secondary)
        }
        .padding(GuideMetrics.chipPadding)
        .padding(.trailing, GuideMetrics.chipTrailing)
        .background(Palette.guideChipFill, in: chip)
        .overlay(chip.strokeBorder(Palette.guideChipStroke,
                                   style: StrokeStyle(lineWidth: GuideMetrics.chipStrokeWidth, dash: GuideMetrics.chipDash)))
        .contentShape(chip)
        .onDrag { NSItemProvider(object: appURL as NSURL) }
        .help(PermissionStrings.guideTitle(appName))
    }

    //// Keep the chip visually dominant over the instructions below it.
    //////////////////

    ////////////////////
    //// Reset row
    /// Lets the user clear an old entry that shows as "on" but no longer works.
    // Every state is one short line so the panel keeps the height it was created with.
    // The button is replaced while the reset runs, so it cannot be started twice.

    private var resetRow: some View {
        Group {
            switch resetState {
            case .idle:
                HStack(spacing: 4) {
                    Text(PermissionStrings.resetPrompt)
                        .foregroundStyle(.secondary)
                    Button(PermissionStrings.reset, action: startReset)
                        .buttonStyle(.link)
                }
            case .running:
                Text(PermissionStrings.resetting).foregroundStyle(.secondary)
            case .done:
                Text(PermissionStrings.resetDone(appName)).foregroundStyle(.secondary)
            case .failed:
                Text(PermissionStrings.resetFailed).foregroundStyle(.secondary)
            }
        }
        .font(.system(size: GuideMetrics.detailSize))
        .lineLimit(1)
    }

    private func startReset() {
        resetState = .running
        Task {
            resetState = await AccessibilityGrantReset.reset() ? .done : .failed
        }
    }

    //// The reset only runs from this button, never automatically.
    //////////////////
}
