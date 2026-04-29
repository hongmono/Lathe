import SwiftUI

struct CarouselView: View {
    @ObservedObject var viewModel: CarouselViewModel
    @ObservedObject var settings: SettingsStore = .shared

    private let maxVisibleEachSide = 5
    private let heightRatio: CGFloat = 1.36
    private let pivotRatio: CGFloat = 2.9

    var body: some View {
        let cardWidth = CGFloat(settings.cardSize)
        let cardHeight = cardWidth * heightRatio
        let pivotDistance = cardWidth * pivotRatio
        let angularStep = settings.angularStep
        let frameSide = (pivotDistance + cardHeight) * 2
        let anchor = UnitPoint(x: 0.5, y: 0.5 + pivotDistance / cardHeight)

        return ZStack {
            ForEach(visibleEntries(angularStep: angularStep), id: \.entry.id) { item in
                CardView(entry: item.entry, isFocused: item.isFocused)
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(item.scale)
                    .rotationEffect(.degrees(item.angleDegrees), anchor: settings.layoutStyle == .fan ? anchor : .center)
                    .offset(x: item.offsetX, y: item.offsetY)
                    .opacity(item.opacity)
                    .zIndex(item.zIndex)
            }
        }
        .frame(width: frameSide, height: frameSide)
        .animation(.spring(response: 0.32, dampingFraction: 0.74), value: viewModel.selectedIndex)
        .animation(.easeInOut(duration: 0.18), value: viewModel.apps.map(\.id))
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: settings.layoutStyle)
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

    private func visibleEntries(angularStep: Double) -> [Item] {
        CarouselLayout.items(
            appCount: viewModel.apps.count,
            selectedIndex: viewModel.selectedIndex,
            style: settings.layoutStyle,
            angularStep: angularStep,
            maxVisibleEachSide: maxVisibleEachSide
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
}
