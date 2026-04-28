import SwiftUI

struct CarouselView: View {
    @ObservedObject var viewModel: CarouselViewModel

    private let cardSpacing: CGFloat = 96
    private let scaleStep: CGFloat = 0.15
    private let opacityStep: CGFloat = 0.25
    private let maxVisibleEachSide = 4

    var body: some View {
        let totalWidth = cardSpacing * CGFloat(maxVisibleEachSide * 2 + 1)
        return ZStack {
            ForEach(visibleEntries(), id: \.entry.id) { item in
                CardView(entry: item.entry, isFocused: item.isFocused)
                    .scaleEffect(item.scale)
                    .opacity(item.opacity)
                    .offset(x: item.offsetX)
                    .zIndex(item.zIndex)
            }
        }
        .frame(width: totalWidth, height: 180)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(carouselBackground)
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: viewModel.selectedIndex)
        .animation(.easeInOut(duration: 0.18), value: viewModel.apps.map(\.id))
    }

    private var carouselBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.regularMaterial)
            .shadow(radius: 24, y: 8)
    }

    private struct Item {
        let entry: AppEntry
        let isFocused: Bool
        let scale: CGFloat
        let opacity: Double
        let offsetX: CGFloat
        let zIndex: Double
    }

    private func visibleEntries() -> [Item] {
        let selected = viewModel.selectedIndex
        let limit = CGFloat(maxVisibleEachSide)
        return viewModel.apps.enumerated().compactMap { index, entry -> Item? in
            let d = CGFloat(index - selected)
            let absD = abs(d)
            guard absD <= limit else { return nil }
            return Item(
                entry: entry,
                isFocused: index == selected,
                scale: max(1 - absD * scaleStep, 0.5),
                opacity: Double(max(1 - absD * opacityStep, 0.15)),
                offsetX: d * cardSpacing,
                zIndex: Double(limit - absD)
            )
        }
    }
}
