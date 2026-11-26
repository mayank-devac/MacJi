//
//  InlinePanelView.swift
//  MacJi
//
//  Created: 2026-11-26
//  The inline panel: what was typed, the symbol or emoticon filters, the ranked results (a grid,
//  or one row per emoticon) and a footer with key hints. Resting on a result names it. Keys are
//  handled by the controller; this view only reflects the model.
//  Ported from Octopus: octopus/UI/MacJi/MacJiView.swift
//

import SwiftUI

struct InlinePanelView: View {
    @ObservedObject var model: InlinePanelModel
    let onPick: (Glyph) -> Void
    @State private var showsName = false

    var body: some View {
        let size = PanelMetrics.cardSize(withFilters: model.kind.hasFilters)
        VStack(spacing: 0) {
            header
            if model.kind.hasFilters { filters }
            Divider()
            results
            Divider()
            footer
        }
        .frame(width: size.width, height: size.height)
        .menuCard(cornerRadius: PanelMetrics.cornerRadius)
        .menuAppear(presentationID: model.presentationID, anchor: model.growsFrom)
        .padding(MenuShadowMargin.size)
        .task(id: model.focusedGlyph?.text) { await revealName() }
    }

    ////////////////////
    //// Delayed name
    /// A new focus cancels the running task, restarting the timer, so the name never flickers
    // while arrowing quickly through the grid.

    private func revealName() async {
        showsName = false
        guard model.focusedGlyph != nil, (try? await Task.sleep(for: PanelMotion.nameRevealDelay)) != nil else { return }
        withAnimation(PanelMotion.nameReveal) { showsName = true }
    }

    //////////////////

    private var title: String {
        switch model.kind {
        case .emoji: PanelStrings.emojiTitle
        case .symbols: PanelStrings.symbolsTitle
        case .emoticons: PanelStrings.emoticonsTitle
        }
    }

    private var header: some View {
        HStack(spacing: PanelMetrics.headerSpacing) {
            Text(title)
                .font(.system(size: PanelMetrics.titleFontSize, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(model.search?.typed ?? "")
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

    @ViewBuilder
    private var filters: some View {
        Group {
            switch model.kind {
            case .symbols: CategoryBar(selection: $model.symbolCategory, style: PanelMetrics.categoryBar)
            case .emoticons: CategoryBar(selection: $model.emoticonCategory, style: PanelMetrics.categoryBar)
            case .emoji: EmptyView()
            }
        }
        .font(.system(size: PanelMetrics.titleFontSize))
        .padding(.horizontal, PanelMetrics.horizontalPadding)
        .frame(height: PanelMetrics.filterBarHeight, alignment: .top)
    }

    ////////////////////
    //// Results
    /// Arrow keys move `selection`; the list scrolls it into view. A new term starts at the top.
    // Emoticons are one per row so a long face never squeezes into a cell.

    private var results: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: PanelMetrics.gridSpacing) {
                    ForEach(model.results) { glyph in
                        cell(for: glyph).id(glyph.text)
                    }
                }
                .padding(PanelMetrics.gridPadding)
            }
            .scrollIndicators(.never)
            .id(model.search?.term)
            .onChange(of: model.selection) { _, selection in
                if let selection { proxy.scrollTo(selection) }
            }
        }
        .overlay {
            if model.results.isEmpty && model.search != nil { emptyState }
        }
        .copiedBadge(copyCount: model.copyCount, glyph: model.lastCopied, presentationID: model.presentationID)
    }

    //////////////////

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: PanelMetrics.gridSpacing), count: model.columnCount)
    }

    @ViewBuilder
    private func cell(for glyph: Glyph) -> some View {
        let isSelected = model.selection == glyph.text
        if model.kind == .emoticons {
            GlyphRow(glyph: glyph, isSelected: isSelected, hovered: $model.hovered) { onPick(glyph) }
        } else {
            GlyphCell(glyph: glyph, isSelected: isSelected, hovered: $model.hovered) { onPick(glyph) }
        }
    }

    private var emptyState: some View {
        let term = model.search?.term ?? ""
        let filtered = model.symbolCategory != nil || model.emoticonCategory != nil
        return VStack(spacing: EmojiUIMetrics.emptyStateSpacing) {
            Group {
                switch model.kind {
                case .emoji: Text(PanelStrings.noEmoji(for: term))
                case .symbols: Text(PanelStrings.noSymbols(for: term))
                case .emoticons: Text(PanelStrings.noEmoticons(for: term))
                }
            }
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            Text(filtered ? PanelStrings.noResultsInFilterHint : PanelStrings.noResultsHint)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, PanelMetrics.horizontalPadding)
    }

    ////////////////////
    //// Footer
    /// The focused glyph and its name; one of your alias outputs shows its spelling, a symbol
    /// its code point.

    private var footer: some View {
        HStack(spacing: PanelMetrics.footerSpacing) {
            if showsName, let glyph = model.focusedGlyph {
                if model.kind != .emoticons {
                    Text(glyph.text).font(.system(size: PanelMetrics.footerEmojiSize))
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(glyph.displayName)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let spelling = model.focusedSpelling {
                        Text(AliasStrings.typeHint(spelling))
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    } else if model.kind == .symbols {
                        Text(PanelStrings.codePoints(of: glyph.text))
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity)
            }
            Spacer(minLength: PanelMetrics.footerSpacing)
            HStack(spacing: PanelMetrics.keyHintSpacing) {
                KeyHint(key: KeycapStrings.returnKey, label: PanelStrings.insert)
                KeyHint(key: KeycapStrings.shiftReturn, label: model.kind.hasFilters ? nil : PanelStrings.copy)
                if model.kind.hasFilters { KeyHint(key: KeycapStrings.tab) }
                KeyHint(key: KeycapStrings.escape)
            }
            .fixedSize()
        }
        .padding(.horizontal, PanelMetrics.horizontalPadding)
        .frame(height: PanelMetrics.footerHeight)
    }

    //////////////////
}
