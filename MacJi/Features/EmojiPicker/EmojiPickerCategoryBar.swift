//
//  EmojiPickerCategoryBar.swift
//  MacJi
//
//  Created: 2026-11-26
//  The row of category filter buttons; the selection pill slides to the chosen category.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerView.swift
//

import SwiftUI

struct EmojiPickerCategoryBar: View {
    @Binding var selection: EmojiCategory?
    @Namespace private var pill
    @State private var hovered: EmojiCategory??
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: PickerMetrics.categorySpacing) {
            button(nil, symbol: SymbolNames.allCategories, title: PickerStrings.allCategories)
            ForEach(EmojiCategory.allCases) { category in
                button(category, symbol: category.symbol, title: category.rawValue)
            }
        }
    }

    ////////////////////
    //// One filter button
    /// The selected filter gets the accent pill (matched geometry makes it slide between buttons);
    /// hovering an unselected filter shows a faint fill so the bar feels clickable.
    // `hovered` is a double optional: `.some(nil)` is the "All" button, `nil` is nothing hovered.

    private func button(_ category: EmojiCategory?, symbol: String, title: String) -> some View {
        let isSelected = selection == category
        let shape = RoundedRectangle(cornerRadius: PickerMetrics.categoryCornerRadius, style: .continuous)
        return Button {
            withAnimation(reduceMotion ? nil : PanelMotion.categorySlide) { selection = category }
        } label: {
            Image(systemName: symbol)
                .frame(maxWidth: .infinity, minHeight: PickerMetrics.categoryHeight)
                .foregroundStyle(isSelected ? Palette.categorySelected : .secondary)
                .background {
                    if isSelected {
                        shape.fill(Palette.categorySelectedFill).matchedGeometryEffect(id: "pill", in: pill)
                    } else if hovered == .some(category) {
                        shape.fill(Palette.hoverFill)
                    }
                }
                .contentShape(shape)
        }
        .buttonStyle(MenuPressButtonStyle())
        .help(PickerStrings.categoryHelp(title))
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { inside in
            if inside {
                hovered = .some(category)
            } else if hovered == .some(category) {
                hovered = nil
            }
        }
    }

    //////////////////
}
