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
    static let expandResponse = 0.30
    static let expandRowResponse = 0.28
    static let expandRowLeadTime = 0.03
    static let expandRowStaggerDelay = 0.035
    static let expandInitialRowOffsetY: CGFloat = -22
    static let expandAdditionalRowOffsetY: CGFloat = -4
    static let expandMaximumRowOffsetY: CGFloat = -30
}

enum WindowListPresentationGeometry {
    static func initialRowOffsetY(
        for style: WindowListAnimationStyle,
        presentationOrder: Int
    ) -> CGFloat {
        switch style {
        case .whole:
            return 0
        case .staggered:
            return WindowListPresentationMotion.staggeredInitialOffsetY
        case .expand:
            guard presentationOrder > 0 else { return 0 }
            let additionalOffset = CGFloat(min(presentationOrder - 1, 2))
                * WindowListPresentationMotion.expandAdditionalRowOffsetY
            return max(
                WindowListPresentationMotion.expandInitialRowOffsetY + additionalOffset,
                WindowListPresentationMotion.expandMaximumRowOffsetY
            )
        }
    }

    static func initialRowOpacity(for style: WindowListAnimationStyle) -> Double {
        style == .staggered ? 0 : 1
    }

    static func rowZIndex(for style: WindowListAnimationStyle, presentationOrder: Int) -> Double {
        guard style == .expand else { return 0 }
        return Double(WindowListLayout.maxVisibleRows - presentationOrder)
    }
}

struct WindowListView: View {
    let items: [WindowSelectionItem]
    let selectedIndex: Int
    let presentationStyle: WindowListAnimationStyle
    let presentationSpeed: Double
    let presentationDelay: Double

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
                            .opacity(rowOpacity)
                            .modifier(
                                WindowListExpandRowClipModifier(
                                    isEnabled: presentationStyle == .expand && !accessibilityReduceMotion
                                )
                            )
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
            }
            .task {
                await Task.yield()
                if resolvedPresentationDelay > 0 {
                    try? await Task.sleep(for: .seconds(resolvedPresentationDelay))
                }
                guard !Task.isCancelled else { return }
                areRowsPresented = true
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
        return WindowListPresentationGeometry.initialRowOffsetY(
            for: presentationStyle,
            presentationOrder: presentationOrder(for: index)
        )
    }

    private var rowOpacity: Double {
        guard !areRowsPresented else { return 1 }
        return WindowListPresentationGeometry.initialRowOpacity(for: presentationStyle)
    }

    private func rowZIndex(for index: Int) -> Double {
        WindowListPresentationGeometry.rowZIndex(
            for: presentationStyle,
            presentationOrder: presentationOrder(for: index)
        )
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
            let order = presentationOrder(for: index)
            guard order > 0 else { return nil }
            let delay = WindowListPresentationMotion.expandRowLeadTime
                + Double(order - 1) * WindowListPresentationMotion.expandRowStaggerDelay
            return .spring(
                response: WindowListPresentationMotion.expandRowResponse,
                dampingFraction: WindowListPresentationMotion.dampingFraction
            )
            .delay(delay)
            .speed(resolvedPresentationSpeed)
        }
    }

    private var resolvedPresentationSpeed: Double {
        SettingsStore.clampedWindowListAnimationSpeed(presentationSpeed)
    }

    private var resolvedPresentationDelay: Double {
        SettingsStore.clampedWindowListAnimationDelay(presentationDelay)
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
            ZStack {
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
            // Keep the moving highlight animated without cross-fading row text
            // when its selection-dependent font weight and color change.
            .animation(selectionAnimation, value: selectedIndex)
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

private struct WindowListExpandRowClipModifier: ViewModifier {
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.clipped()
        } else {
            content
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
