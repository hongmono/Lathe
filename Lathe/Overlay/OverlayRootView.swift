import SwiftUI

struct OverlayRootView: View {
    @ObservedObject var carouselViewModel: CarouselViewModel
    @ObservedObject var windowSelectionViewModel: WindowSelectionViewModel
    @ObservedObject var settings: SettingsStore = .shared

    private let heightRatio: CGFloat = 1.36
    private let pivotRatio: CGFloat = 2.9
    private let appToWindowGap: CGFloat = 40

    var body: some View {
        let cardWidth = CGFloat(settings.cardSize)
        let cardHeight = cardWidth * heightRatio
        let angularStep = settings.angularStep
        let maxVisibleEachSide = CarouselGeometry.maxVisibleEachSide(for: settings.layoutStyle)
        let pivotDistance = cardWidth * pivotRatio
        let frameSide = (pivotDistance + cardHeight) * 2
        let windowListTopOffset = frameSide / 2 + cardHeight / 2 + appToWindowGap

        return ZStack {
            ForEach(visibleEntries(angularStep: angularStep, maxVisibleEachSide: maxVisibleEachSide), id: \.entry.id) { item in
                CardView(
                    entry: item.entry,
                    isFocused: item.isFocused,
                    showsName: settings.showAppNamesInCarousel
                )
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(item.scale)
                    .rotationEffect(.degrees(item.angleDegrees), anchor: .center)
                    .offset(x: item.offsetX, y: item.offsetY)
                    .opacity(item.entry.id == carouselViewModel.hoveredAppID ? 1.0 : item.opacity)
                    .zIndex(item.zIndex)
                // 클릭 선택은 패널 레벨(FirstMouseHostingView + 컨트롤러 히트테스트)에서 처리.
            }
        }
        .frame(width: frameSide, height: frameSide)
        .animation(.spring(response: 0.32, dampingFraction: 0.74), value: carouselViewModel.selectedIndex)
        .animation(.easeInOut(duration: 0.18), value: carouselViewModel.apps.map(\.id))
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: settings.layoutStyle)
        .animation(.easeInOut(duration: 0.14), value: settings.showAppNamesInCarousel)
        .animation(.easeInOut(duration: 0.14), value: settings.fanRadius)
        .animation(.easeInOut(duration: 0.14), value: settings.fanSpacing)
        .animation(.easeOut(duration: 0.13), value: carouselViewModel.hoveredAppID)   // hover dim 페이드
        .overlay(alignment: .top) {
            if windowSelectionViewModel.hasMultipleWindows {
                WindowListView(
                    windows: windowSelectionViewModel.windows,
                    selectedIndex: windowSelectionViewModel.selectedIndex
                )
                .offset(y: windowListTopOffset)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                .animation(.spring(response: 0.26, dampingFraction: 0.82), value: windowSelectionViewModel.selectedIndex)
                .animation(.easeInOut(duration: 0.16), value: windowSelectionViewModel.windows.map(\.id))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: windowSelectionViewModel.hasMultipleWindows)
    }

    private struct Item {
        let entry: AppEntry
        let isFocused: Bool
        let angleDegrees: Double
        let offsetX: Double
        let offsetY: Double
        let scale: Double
        let opacity: Double
        let zIndex: Double
    }

    private func visibleEntries(angularStep: Double, maxVisibleEachSide: Int) -> [Item] {
        CarouselLayout.items(
            appCount: carouselViewModel.apps.count,
            selectedIndex: carouselViewModel.selectedIndex,
            style: settings.layoutStyle,
            angularStep: angularStep,
            fanRadius: settings.fanRadius,
            fanSpacing: settings.fanSpacing,
            maxVisibleEachSide: maxVisibleEachSide
        ).map { layoutItem in
            let entry = carouselViewModel.apps[layoutItem.index]
            return Item(
                entry: entry,
                isFocused: layoutItem.relativeIndex == 0,
                angleDegrees: layoutItem.angleDegrees,
                offsetX: layoutItem.offsetX,
                offsetY: layoutItem.offsetY,
                scale: layoutItem.scale,
                opacity: layoutItem.opacity,
                zIndex: layoutItem.zIndex
            )
        }
    }
}
