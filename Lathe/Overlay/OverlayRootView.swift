import SwiftUI

struct OverlayRootView: View {
    @ObservedObject var carouselViewModel: CarouselViewModel
    let windowSelectionViewModel: WindowSelectionViewModel
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
        let layoutItems = CarouselLayout.items(
            appCount: carouselViewModel.apps.count,
            selectedIndex: carouselViewModel.selectedIndex,
            selectionPosition: carouselViewModel.selectionPosition,
            style: settings.layoutStyle,
            angularStep: angularStep,
            fanRadius: settings.fanRadius,
            fanSpacing: settings.fanSpacing,
            maxVisibleEachSide: maxVisibleEachSide
        )
        let transitionTravel = CGFloat(CarouselTransitionGeometry.directionalTravel(
            items: layoutItems,
            cardWidth: Double(cardWidth)
        ))

        return ZStack {
            ForEach(visibleEntries(layoutItems)) { item in
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
                    .transition(cardTransition(travel: transitionTravel))
                // 클릭 선택은 패널 레벨(FirstMouseHostingView + 컨트롤러 히트테스트)에서 처리.
            }
        }
        .frame(width: frameSide, height: frameSide)
        .animation(selectionAnimation, value: carouselViewModel.selectionPosition)
        .animation(.easeInOut(duration: 0.18), value: carouselViewModel.apps.map(\.id))
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: settings.layoutStyle)
        .animation(.easeInOut(duration: 0.14), value: settings.showAppNamesInCarousel)
        .animation(.easeInOut(duration: 0.14), value: settings.fanRadius)
        .animation(.easeInOut(duration: 0.14), value: settings.fanSpacing)
        .animation(.easeOut(duration: 0.13), value: carouselViewModel.hoveredAppID)   // hover dim 페이드
        .overlay(alignment: .top) {
            WindowSelectionOverlay(
                viewModel: windowSelectionViewModel,
                topOffset: windowListTopOffset
            )
        }
    }

    private struct Item: Identifiable {
        struct ID: Hashable {
            let appID: Int32
            let virtualIndex: Int
        }

        let id: ID
        let entry: AppEntry
        let isFocused: Bool
        let angleDegrees: Double
        let offsetX: Double
        let offsetY: Double
        let scale: Double
        let opacity: Double
        let zIndex: Double
    }

    private var selectionAnimation: Animation? {
        carouselViewModel.apps.count > 2
            ? .spring(response: 0.32, dampingFraction: 0.86)
            : nil
    }

    private func cardTransition(travel: CGFloat) -> AnyTransition {
        let spec = CarouselTransitionGeometry.spec(
            direction: carouselViewModel.selectionDirection,
            travel: Double(travel)
        )
        guard spec.isDirectional else { return .opacity }
        return .asymmetric(
            insertion: .offset(x: CGFloat(spec.insertionOffset)).combined(with: .opacity),
            removal: .offset(x: CGFloat(spec.removalOffset)).combined(with: .opacity)
        )
    }

    private func visibleEntries(_ layoutItems: [CarouselLayout.Item]) -> [Item] {
        layoutItems.map { layoutItem in
            let entry = carouselViewModel.apps[layoutItem.index]
            return Item(
                id: Item.ID(appID: entry.id, virtualIndex: layoutItem.virtualIndex),
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

private struct WindowSelectionOverlay: View {
    @ObservedObject var viewModel: WindowSelectionViewModel
    let topOffset: CGFloat

    var body: some View {
        if viewModel.hasMultipleWindows {
            WindowListView(
                windows: viewModel.windows,
                selectedIndex: viewModel.selectedIndex
            )
            .offset(y: topOffset)
            .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            .animation(.easeInOut(duration: 0.16), value: viewModel.windows.map(\.id))
        }
    }
}
