//
//  InlinePanelView.swift
//  MacJi
//
//  Created: 2026-11-26
//  The inline panel: the typed term, a grid of ranked results and a footer with key hints.
//  Resting on an emoji (pointer or keyboard) names it. Keys are handled by the controller;
//  this view only reflects the model.
//  Ported from Octopus: octopus/UI/MacJi/MacJiView.swift
//

import SwiftUI

struct InlinePanelView: View {
    @ObservedObject var model: InlinePanelModel
    let onPick: (Emoji) -> Void
    @State private var showsName = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: PanelMetrics.gridSpacing),
                                count: PanelMetrics.columnCount)

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            grid
            Divider()
            footer
        }
        .frame(width: PanelMetrics.cardSize.width, height: PanelMetrics.cardSize.height)
        .menuCard(cornerRadius: PanelMetrics.cornerRadius)
        .menuAppear(presentationID: model.presentationID, anchor: model.growsFrom)
        .padding(MenuShadowMargin.size)
        .task(id: model.focusedEmoji?.emoji) { await revealName() }
    }

    ////////////////////
    //// Delayed name
    /// A new focus cancels the running task, restarting the timer, so the name never flickers
    // while arrowing quickly through the grid.

    private func revealName() async {
        showsName = false
        guard model.focusedEmoji != nil, (try? await Task.sleep(for: PanelMotion.nameRevealDelay)) != nil else { return }
        withAnimation(PanelMotion.nameReveal) { showsName = true }
    }

    //////////////////

    private var header: some View {
        HStack(spacing: PanelMetrics.headerSpacing) {
            Text(PanelStrings.title)
                .font(.system(size: PanelMetrics.titleFontSize, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(model.trigger + model.query)
                .font(.system(size: PanelMetrics.queryFontSize, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.head)
            Spacer(minLength: PanelMetrics.headerSpacing)
            if !model.results.isEmpty {
                Text(model.results.count, format: .number)
                    .font(.system(size: PanelMetrics.countFontSize).monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel(PanelStrings.resultCount(model.results.count))
            }
        }
        .padding(.horizontal, PanelMetrics.horizontalPadding)
        .frame(height: PanelMetrics.headerHeight)
    }

    ////////////////////
    //// Grid
    /// Arrow keys move `selection`; the grid scrolls it into view. A new term starts at the top.

    private var grid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: PanelMetrics.gridSpacing) {
                    ForEach(model.results) { emoji in
                        EmojiCell(emoji: emoji, isSelected: model.selection == emoji.emoji, hovered: $model.hovered) {
                            onPick(emoji)
                        }
                        .id(emoji.emoji)
                    }
                }
                .padding(PanelMetrics.gridPadding)
            }
            .scrollIndicators(.never)
            .id(model.query)
            .onChange(of: model.selection) { _, selection in
                if let selection { proxy.scrollTo(selection) }
            }
        }
        .overlay {
            if model.results.isEmpty && !model.query.isEmpty { emptyState }
        }
        .copiedBadge(copyCount: model.copyCount, emoji: model.lastCopied, presentationID: model.presentationID)
    }

    //////////////////

    private var emptyState: some View {
        VStack(spacing: EmojiUIMetrics.emptyStateSpacing) {
            Text(PanelStrings.noResults(for: model.query))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(PanelStrings.noResultsHint)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, PanelMetrics.horizontalPadding)
    }

    private var footer: some View {
        HStack(spacing: PanelMetrics.footerSpacing) {
            if showsName, let emoji = model.focusedEmoji {
                Text(emoji.emoji).font(.system(size: PanelMetrics.footerEmojiSize))
                Text(emoji.displayName)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .transition(.opacity)
            }
            Spacer(minLength: PanelMetrics.footerSpacing)
            HStack(spacing: PanelMetrics.keyHintSpacing) {
                KeyHint(key: KeycapStrings.returnKey, label: PanelStrings.insert)
                KeyHint(key: KeycapStrings.shiftReturn, label: PanelStrings.copy)
                KeyHint(key: KeycapStrings.escape)
            }
            .fixedSize()
        }
        .padding(.horizontal, PanelMetrics.horizontalPadding)
        .frame(height: PanelMetrics.footerHeight)
    }
}
