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

    static func presentationOrder(for index: Int, selectedIndex: Int, itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        let visibleCount = visibleRowCount(itemCount)
        let clampedSelectedIndex = min(max(selectedIndex, 0), itemCount - 1)
        let maximumStart = max(itemCount - visibleCount, 0)
        let visibleStart = min(max(clampedSelectedIndex - visibleCount / 2, 0), maximumStart)
        return min(max(index - visibleStart, 0), visibleCount - 1)
    }
}

private enum WindowListPresentationMotion {
    static let wholeInitialOffsetY: CGFloat = -12
    static let wholeInitialScale: CGFloat = 0.97
    static let wholeResponse = 0.32
    static let staggeredInitialOffsetY: CGFloat = -10
    static let staggeredResponse = 0.30
    static let dampingFraction = 1.0
    static let backgroundLeadTime = 0.04
    static let staggerDelay = 0.025
    static let expandResponse = 0.34
}

struct WindowListView: View {
    let items: [WindowSelectionItem]
    let selectedIndex: Int
    let presentationStyle: WindowListAnimationStyle
    let presentationSpeed: Double

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Namespace private var highlightNamespace
    @State private var areRowsPresented = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: WindowListLayout.rowSpacing) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        row(for: item, isSelected: index == selectedIndex)
                            .id(index)
                            .offset(y: rowOffsetY(for: index))
                            .opacity(rowOpacity(for: index))
                            .zIndex(rowZIndex(for: index))
                            .animation(rowPresentationAnimation(for: index), value: areRowsPresented)
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
                withAnimation(selectionAnimation) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(selectedIndex, anchor: .center)
                DispatchQueue.main.async {
                    areRowsPresented = true
                }
            }
        }
        .background {
            containerShape
                .fill(.ultraThinMaterial)
        }
        .overlay {
            containerShape
                .stroke(.white.opacity(0.16), lineWidth: 0.8)
        }
        .mask { containerShape }
        .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 10)
        .scaleEffect(wholeListScale, anchor: .top)
        .offset(y: wholeListOffsetY)
        .opacity(areRowsPresented ? 1 : 0)
        .animation(containerPresentationAnimation, value: areRowsPresented)
        .animation(selectionAnimation, value: selectedIndex)
    }

    private var selectionAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .spring(response: 0.26, dampingFraction: 1.0)
    }

    private var containerShape: WindowListContainerShape {
        WindowListContainerShape(
            expansionProgress: containerExpansionProgress,
            collapsedHeight: WindowListLayout.rowHeight + WindowListLayout.verticalPadding * 2,
            cornerRadius: WindowListLayout.cornerRadius
        )
    }

    private var containerExpansionProgress: CGFloat {
        guard presentationStyle == .expand, !accessibilityReduceMotion else { return 1 }
        return areRowsPresented ? 1 : 0
    }

    private var wholeListScale: CGFloat {
        guard presentationStyle == .whole, !accessibilityReduceMotion else { return 1 }
        return areRowsPresented ? 1 : WindowListPresentationMotion.wholeInitialScale
    }

    private var wholeListOffsetY: CGFloat {
        guard presentationStyle == .whole, !accessibilityReduceMotion else { return 0 }
        return areRowsPresented ? 0 : WindowListPresentationMotion.wholeInitialOffsetY
    }

    private func rowOffsetY(for index: Int) -> CGFloat {
        guard !accessibilityReduceMotion, !areRowsPresented else { return 0 }
        switch presentationStyle {
        case .whole:
            return 0
        case .staggered:
            return WindowListPresentationMotion.staggeredInitialOffsetY
        case .expand:
            return -CGFloat(presentationOrder(for: index)) * rowStride
        }
    }

    private func rowOpacity(for index: Int) -> Double {
        guard !areRowsPresented else { return 1 }
        switch presentationStyle {
        case .whole:
            return 1
        case .staggered:
            return 0
        case .expand:
            return presentationOrder(for: index) == 0 ? 1 : 0
        }
    }

    private func rowZIndex(for index: Int) -> Double {
        guard presentationStyle == .expand else { return 0 }
        return Double(WindowListLayout.maxVisibleRows - presentationOrder(for: index))
    }

    private var rowStride: CGFloat {
        WindowListLayout.rowHeight + WindowListLayout.rowSpacing
    }

    private func presentationOrder(for index: Int) -> Int {
        WindowListLayout.presentationOrder(
            for: index,
            selectedIndex: selectedIndex,
            itemCount: items.count
        )
    }

    private var containerPresentationAnimation: Animation {
        guard !accessibilityReduceMotion else {
            return .easeOut(duration: 0.12).speed(resolvedPresentationSpeed)
        }
        switch presentationStyle {
        case .whole:
            return .spring(
                response: WindowListPresentationMotion.wholeResponse,
                dampingFraction: WindowListPresentationMotion.dampingFraction
            )
            .speed(resolvedPresentationSpeed)
        case .staggered:
            return .easeOut(duration: 0.12).speed(resolvedPresentationSpeed)
        case .expand:
            return .spring(
                response: WindowListPresentationMotion.expandResponse,
                dampingFraction: WindowListPresentationMotion.dampingFraction
            )
            .speed(resolvedPresentationSpeed)
        }
    }

    private func rowPresentationAnimation(for index: Int) -> Animation? {
        guard !accessibilityReduceMotion else {
            return .easeOut(duration: 0.12).speed(resolvedPresentationSpeed)
        }
        switch presentationStyle {
        case .whole:
            return nil
        case .staggered:
            let delay = WindowListPresentationMotion.backgroundLeadTime
                + Double(presentationOrder(for: index)) * WindowListPresentationMotion.staggerDelay
            return .spring(
                response: WindowListPresentationMotion.staggeredResponse,
                dampingFraction: WindowListPresentationMotion.dampingFraction
            )
            .delay(delay)
            .speed(resolvedPresentationSpeed)
        case .expand:
            let delay = Double(presentationOrder(for: index)) * WindowListPresentationMotion.staggerDelay
            return .spring(
                response: WindowListPresentationMotion.expandResponse,
                dampingFraction: WindowListPresentationMotion.dampingFraction
            )
            .delay(delay)
            .speed(resolvedPresentationSpeed)
        }
    }

    private var resolvedPresentationSpeed: Double {
        SettingsStore.clampedWindowListAnimationSpeed(presentationSpeed)
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

private struct WindowListContainerShape: Shape {
    var expansionProgress: CGFloat
    let collapsedHeight: CGFloat
    let cornerRadius: CGFloat

    var animatableData: CGFloat {
        get { expansionProgress }
        set { expansionProgress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let progress = min(max(expansionProgress, 0), 1)
        let height = collapsedHeight + (rect.height - collapsedHeight) * progress
        return Path(
            roundedRect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height),
            cornerRadius: cornerRadius
        )
    }
}
