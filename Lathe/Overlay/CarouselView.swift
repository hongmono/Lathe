import SwiftUI

struct CarouselView: View {
    @ObservedObject var viewModel: CarouselViewModel
    @ObservedObject var settings: SettingsStore = .shared

    private let heightRatio: CGFloat = 1.36
    private let pivotRatio: CGFloat = 2.9

    var body: some View {
        let cardWidth = CGFloat(settings.cardSize)
        let cardHeight = cardWidth * heightRatio
        let angularStep = settings.angularStep
        let maxVisibleEachSide = CarouselGeometry.maxVisibleEachSide(for: settings.layoutStyle)
        let pivotDistance = cardWidth * pivotRatio
        let frameSide = (pivotDistance + cardHeight) * 2

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
                    .opacity(item.opacity)
                    .zIndex(item.zIndex)
            }
        }
        .frame(width: frameSide, height: frameSide)
        .animation(.spring(response: 0.32, dampingFraction: 0.74), value: viewModel.selectedIndex)
        .animation(.easeInOut(duration: 0.18), value: viewModel.apps.map(\.id))
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: settings.layoutStyle)
        .animation(.easeInOut(duration: 0.14), value: settings.showAppNamesInCarousel)
        .animation(.easeInOut(duration: 0.14), value: settings.fanRadius)
        .animation(.easeInOut(duration: 0.14), value: settings.fanSpacing)
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
            appCount: viewModel.apps.count,
            selectedIndex: viewModel.selectedIndex,
            style: settings.layoutStyle,
            angularStep: angularStep,
            fanRadius: settings.fanRadius,
            fanSpacing: settings.fanSpacing,
            maxVisibleEachSide: maxVisibleEachSide,
            currentSpaceIndices: currentSpaceIndices
        ).map { layoutItem in
            let entry = viewModel.apps[layoutItem.index]
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

    private var currentSpaceIndices: Set<Int> {
        Set(viewModel.apps.indices.filter { viewModel.apps[$0].isCurrentSpace })
    }
}
