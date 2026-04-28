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
                    .rotationEffect(.degrees(item.angleDegrees), anchor: anchor)
                    .opacity(item.opacity)
                    .zIndex(item.zIndex)
            }
        }
        .frame(width: frameSide, height: frameSide)
        .animation(.spring(response: 0.32, dampingFraction: 0.74), value: viewModel.selectedIndex)
        .animation(.easeInOut(duration: 0.18), value: viewModel.apps.map(\.id))
    }

    private struct Item {
        let entry: AppEntry
        let isFocused: Bool
        let angleDegrees: Double
        let opacity: Double
        let zIndex: Double
    }

    private func visibleEntries(angularStep: Double) -> [Item] {
        let selected = viewModel.selectedIndex
        let limit = maxVisibleEachSide
        return viewModel.apps.enumerated().compactMap { index, entry -> Item? in
            let d = index - selected
            let absD = abs(d)
            guard absD <= limit else { return nil }
            return Item(
                entry: entry,
                isFocused: d == 0,
                angleDegrees: Double(d) * angularStep,
                opacity: max(1.0 - Double(absD) * 0.13, 0.35),
                zIndex: Double(limit - absD)
            )
        }
    }
}
