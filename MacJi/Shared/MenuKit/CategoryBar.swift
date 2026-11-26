//
//  CategoryBar.swift
//  MacJi
//
//  Created: 2026-11-26
//  A row of category filter buttons for any glyph catalog; the selection pill slides to the
//  chosen category. Used by the picker and the inline symbol and emoticon panels.
//  Ported from Octopus: octopus/UI/EmojiPicker/EmojiPickerView.swift
//

import SwiftUI

/// Sizes differ between the picker and the smaller inline panel.
struct CategoryBarStyle: Sendable {
    let height: CGFloat
    let cornerRadius: CGFloat
    let spacing: CGFloat
}

struct CategoryBar<Category: GlyphCategory>: View {
    @Binding var selection: Category?
    let style: CategoryBarStyle
    @Namespace private var pill
    @State private var hovered: Category??
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: style.spacing) {
            button(nil, symbol: SymbolNames.allCategories, title: GlyphStrings.allCategories)
            ForEach(Category.allCases) { category in
                button(category, symbol: category.symbol, title: category.title)
            }
        }
    }

    ////////////////////
    //// One filter button
    /// The selected filter gets the accent pill (matched geometry makes it slide between buttons);
    /// hovering an unselected filter shows a faint fill so the bar feels clickable.
    // `hovered` is a double optional: `.some(nil)` is the "All" button, `nil` is nothing hovered.

    private func button(_ category: Category?, symbol: String, title: String) -> some View {
        let isSelected = selection == category
        let shape = RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
        return Button {
            withAnimation(reduceMotion ? nil : PanelMotion.categorySlide) { selection = category }
        } label: {
            Image(systemName: symbol)
                .frame(maxWidth: .infinity, minHeight: style.height)
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
        .help(GlyphStrings.categoryHelp(title))
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

////////////////////
//// Cycling with Tab
/// Tab moves to the next filter and Shift-Tab to the previous, wrapping through "All" (nil).

extension GlyphCategory {
    static func cycle(_ current: Self?, forward: Bool) -> Self? {
        let filters: [Self?] = [nil] + allCases
        let index = filters.firstIndex(of: current) ?? 0
        return filters[(index + (forward ? 1 : filters.count - 1)) % filters.count]
    }
}

//////////////////
