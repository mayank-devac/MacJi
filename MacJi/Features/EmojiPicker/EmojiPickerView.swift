//
//  EmojiPickerView.swift
//  MacJi
//
//  Created: 2026-11-26
//  The picker popover: search field, category filters, a sectioned emoji grid and a footer
//  naming the selected or hovered emoji. Keyboard handling lives in the controller; this view
//  only reflects `model.selection`.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerView.swift
//

import SwiftUI

struct EmojiPickerView: View {
    @ObservedObject var model: EmojiPickerModel
    @FocusState private var searchFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: PickerMetrics.gridSpacing),
                                count: PickerMetrics.columnCount)

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(PickerMetrics.outerPadding)
            EmojiPickerCategoryBar(selection: $model.category)
                .padding(.horizontal, PickerMetrics.categoryBarHorizontalPadding)
                .padding(.bottom, PickerMetrics.categoryBarBottomPadding)
            Divider()
            grid
            Divider()
            footer
        }
        .frame(width: PickerMetrics.size.width, height: PickerMetrics.size.height)
        .onAppear { searchFocused = true }
        .onChange(of: model.openCount) { searchFocused = true }
    }

    ////////////////////
    //// Search field
    /// Focused on every open so typing searches at once; the clear button appears only with text.

    private var searchField: some View {
        let shape = RoundedRectangle(cornerRadius: PickerMetrics.searchCornerRadius, style: .continuous)
        return HStack(spacing: PickerMetrics.searchIconSpacing) {
            Image(systemName: SymbolNames.search)
                .foregroundStyle(.secondary)
            TextField(PickerStrings.searchPlaceholder, text: $model.query)
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
            .id(model.category)
            .onChange(of: model.selection) { _, slot in
                if let slot { proxy.scrollTo(slot) }
            }
        }
        .overlay {
            if model.groups.isEmpty { emptyState }
        }
        .copiedBadge(copyCount: model.copyCount, emoji: model.lastCopied, presentationID: model.openCount)
    }

    //////////////////

    private func section(_ group: EmojiSection) -> some View {
        Section {
            ForEach(group.emojis) { emoji in
                let slot = EmojiSlot(group: group.title, emoji: emoji.emoji)
                EmojiCell(emoji: emoji, isSelected: model.selection == slot, hovered: $model.hovered) {
                    model.selection = slot
                    model.pick(emoji)
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
    /// Names the hovered or selected emoji with its first alias; short keycaps keep it on one line
    // and the tooltip spells out every key.

    private var footer: some View {
        HStack(spacing: PickerMetrics.footerSpacing) {
            if let emoji = model.focusedEmoji {
                Text(emoji.emoji).font(.system(size: PickerMetrics.footerEmojiSize))
                VStack(alignment: .leading, spacing: 1) {
                    Text(emoji.displayName)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let alias = emoji.aliases.first {
                        Text(PickerStrings.alias(alias))
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

    //////////////////
}
