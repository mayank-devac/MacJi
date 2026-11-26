//
//  EmojiPickerView.swift
//  MacJi
//
//  Created: 2026-11-26
//  The picker popover: search field with a Settings button, category filters, a sectioned
//  emoji grid and a footer naming the selected or hovered emoji. Keyboard handling lives in
//  the controller; this view only reflects `model.selection`.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerView.swift
//

import SwiftUI

struct EmojiPickerView: View {
    @ObservedObject var model: EmojiPickerModel
    let onOpenSettings: () -> Void
    @FocusState private var searchFocused: Bool

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: PickerMetrics.gridSpacing), count: model.tab.columnCount)
    }

    private var showsTabs: Bool { model.visibleTabs.count > 1 }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(PickerMetrics.outerPadding)
            if showsTabs { tabBar }
            categoryBar
                .padding(.horizontal, PickerMetrics.categoryBarHorizontalPadding)
                .padding(.bottom, PickerMetrics.categoryBarBottomPadding)
            Divider()
            grid
            Divider()
            footer
        }
        .frame(width: PickerMetrics.size.width,
               height: PickerMetrics.size.height + (showsTabs ? PickerMetrics.tabBarHeight : 0))
        .onAppear { searchFocused = true }
        .onChange(of: model.openCount) { searchFocused = true }
    }

    private var header: some View {
        HStack(spacing: PickerMetrics.headerSpacing) {
            searchField
            EmojiPickerHeaderButton(symbol: SymbolNames.settings, title: MenuBarStrings.settings,
                                    action: onOpenSettings)
        }
    }

    ////////////////////
    //// Tabs and filters
    /// The segmented tabs appear only when Symbols or Emoticons is on; ⌘1–3 pick them too.
    // Each tab has its own category bar and keeps its own filter.

    private var tabBar: some View {
        Picker(PickerStrings.tabsLabel, selection: $model.tab) {
            ForEach(model.visibleTabs) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .help(PickerStrings.tabsHelp)
        .padding(.horizontal, PickerMetrics.outerPadding)
        .padding(.bottom, PickerMetrics.tabBarBottomPadding)
    }

    @ViewBuilder
    private var categoryBar: some View {
        switch model.tab {
        case .emoji: CategoryBar(selection: $model.emojiCategory, style: PickerMetrics.categoryBar)
        case .symbols: CategoryBar(selection: $model.symbolCategory, style: PickerMetrics.categoryBar)
        case .emoticons: CategoryBar(selection: $model.emoticonCategory, style: PickerMetrics.categoryBar)
        }
    }

    //////////////////

    ////////////////////
    //// Search field
    /// Focused on every open so typing searches at once; the clear button appears only with text.

    private var searchField: some View {
        let shape = RoundedRectangle(cornerRadius: PickerMetrics.searchCornerRadius, style: .continuous)
        return HStack(spacing: PickerMetrics.searchIconSpacing) {
            Image(systemName: SymbolNames.search)
                .foregroundStyle(.secondary)
            TextField(model.tab.searchPlaceholder, text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: PickerMetrics.searchFontSize))
                .focused($searchFocused)
            if !model.query.isEmpty {
                Button { model.query = "" } label: {
                    Image(systemName: SymbolNames.clear)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(PickerStrings.clearSearch)
                .accessibilityLabel(PickerStrings.clearSearch)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, PickerMetrics.searchHorizontalPadding)
        .frame(height: PickerMetrics.searchHeight)
        .background(shape.fill(Palette.searchFill))
        .overlay(shape.strokeBorder(searchFocused ? Palette.searchFocusStroke : Palette.searchStroke))
        .animation(PanelMotion.nameReveal, value: model.query.isEmpty)
    }

    //////////////////

    ////////////////////
    //// Grid
    /// A new category starts at the top; arrow keys scroll the selection into view.
    // Indicators are hidden: a legacy (always-visible) scroller would cover the last column.

    private var grid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: PickerMetrics.gridSpacing) {
                    ForEach(model.groups) { group in
                        section(group)
                    }
                }
                .padding(.horizontal, PickerMetrics.gridHorizontalPadding)
                .padding(.bottom, PickerMetrics.gridBottomPadding)
            }
            .scrollIndicators(.never)
            .id(PickerGridID(tab: model.tab, filter: filterID))
            .onChange(of: model.selection) { _, slot in
                if let slot { proxy.scrollTo(slot) }
            }
        }
        .overlay {
            if model.groups.isEmpty { emptyState }
        }
        .copiedBadge(copyCount: model.copyCount, glyph: model.lastCopied, presentationID: model.openCount)
    }

    //////////////////

    private func section(_ group: GlyphSection) -> some View {
        Section {
            ForEach(group.glyphs) { glyph in
                let slot = PickerSlot(group: group.title, text: glyph.text)
                cell(for: glyph, isSelected: model.selection == slot) {
                    model.selection = slot
                    model.pick(glyph)
                }
                .id(slot)
            }
        } header: {
            // Unpinned and transparent so it sits on the popover material, not a grey bar.
            Text(group.title)
                .font(.system(size: PickerMetrics.sectionTitleFontSize, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, PickerMetrics.sectionTitleLeading)
                .padding(.top, PickerMetrics.sectionTitleTop)
                .padding(.bottom, PickerMetrics.sectionTitleBottom)
                .accessibilityAddTraits(.isHeader)
        }
    }

    /// Emoticons are wide, so they list one per row.
    @ViewBuilder
    private func cell(for glyph: Glyph, isSelected: Bool, onPick: @escaping () -> Void) -> some View {
        if model.tab == .emoticons {
            GlyphRow(glyph: glyph, isSelected: isSelected, hovered: $model.hovered, onPick: onPick)
        } else {
            GlyphCell(glyph: glyph, isSelected: isSelected, hovered: $model.hovered, onPick: onPick)
        }
    }

    /// A new tab or filter starts the grid at the top.
    private var filterID: String? {
        switch model.tab {
        case .emoji: model.emojiCategory?.rawValue
        case .symbols: model.symbolCategory?.rawValue
        case .emoticons: model.emoticonCategory?.rawValue
        }
    }

    private var emptyState: some View {
        VStack(spacing: EmojiUIMetrics.emptyStateSpacing) {
            Text(PickerStrings.noResults).foregroundStyle(.secondary)
            Text(PickerStrings.noResultsHint)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    ////////////////////
    //// Footer
    /// Names the hovered or selected glyph with its emoji alias or a symbol's code point; short
    // keycaps keep it on one line and the tooltip spells out every key.

    private var footer: some View {
        HStack(spacing: PickerMetrics.footerSpacing) {
            if let glyph = model.focusedGlyph {
                if model.tab != .emoticons {
                    Text(glyph.text).font(.system(size: PickerMetrics.footerEmojiSize))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(glyph.displayName)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let detail = footerDetail(for: glyph) {
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }
            Spacer(minLength: PickerMetrics.footerSpacing)
            HStack(spacing: PickerMetrics.keyHintSpacing) {
                KeyHint(key: KeycapStrings.returnKey, label: PickerStrings.copy)
                KeyHint(key: KeycapStrings.tab, label: PickerStrings.filter)
                KeyHint(key: KeycapStrings.escape)
            }
            .fixedSize()
            .help(PickerStrings.keyHelp)
        }
        .font(.callout)
        .padding(.horizontal, PickerMetrics.footerHorizontalPadding)
        .frame(height: PickerMetrics.footerHeight)
    }

    private func footerDetail(for glyph: Glyph) -> String? {
        if let spelling = model.focusedSpelling { return AliasStrings.typeHint(spelling) }
        return switch model.tab {
        case .emoji: glyph.aliases.first.map(PickerStrings.alias)
        case .symbols: PanelStrings.codePoints(of: glyph.text)
        case .emoticons: glyph.text
        }
    }

    //////////////////
}

/// Identity of the grid's scroll position: a new tab or filter scrolls back to the top.
private struct PickerGridID: Hashable {
    let tab: PickerTab
    let filter: String?
}
