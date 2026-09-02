import SwiftUI

enum WindowListLayout {
    static let maxVisibleRows = 6
    static let rowHeight: CGFloat = 38
    static let rowSpacing: CGFloat = 2
    static let verticalPadding: CGFloat = 8
    static let horizontalPadding: CGFloat = 8
    static let width: CGFloat = 380
    static let cornerRadius: CGFloat = 16

    static func visibleRowCount(_ count: Int) -> Int {
        min(max(count, 1), maxVisibleRows)
    }

    static func contentHeight(for count: Int) -> CGFloat {
        let rows = visibleRowCount(count)
        let rowsHeight = rowHeight * CGFloat(rows) + rowSpacing * CGFloat(max(0, rows - 1))
        return rowsHeight + verticalPadding * 2
    }
}

struct WindowListView: View {
    let items: [WindowSelectionItem]
    let selectedIndex: Int

    @Namespace private var highlightNamespace

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: WindowListLayout.rowSpacing) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        row(for: item, isSelected: index == selectedIndex)
                            .id(index)
                    }
                }
                .padding(.horizontal, WindowListLayout.horizontalPadding)
                .padding(.vertical, WindowListLayout.verticalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(
                width: WindowListLayout.width,
                height: WindowListLayout.contentHeight(for: items.count)
            )
            .onChange(of: selectedIndex) { _, newIndex in
                proxy.scrollTo(newIndex, anchor: .center)
            }
            .onAppear {
                proxy.scrollTo(selectedIndex, anchor: .center)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WindowListLayout.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: WindowListLayout.cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 10)
    }

    @ViewBuilder
    private func row(for item: WindowSelectionItem, isSelected: Bool) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage(for: item))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(displayTitle(for: item))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if case .browserTab(let tab) = item {
                    Text(L10n.format("browserTabs.window", tab.windowOrdinal))
                        .font(.system(size: 10.5))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(height: WindowListLayout.rowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.accentColor.opacity(0.22))
                    .overlay {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.accentColor.opacity(0.35), lineWidth: 0.8)
                    }
                    .matchedGeometryEffect(id: "selection", in: highlightNamespace)
            }
        }
        .contentShape(Rectangle())
    }

    private func systemImage(for item: WindowSelectionItem) -> String {
        switch item {
        case .window(let window):
            return window.isMinimized ? "macwindow.badge.minus" : "macwindow"
        case .browserTab:
            return "rectangle.on.rectangle"
        }
    }

    private func displayTitle(for item: WindowSelectionItem) -> String {
        switch item {
        case .window(let window):
            return window.displayTitle
        case .browserTab(let tab):
            return tab.title
        }
    }
}
