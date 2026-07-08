import SwiftUI

struct MissionControlScreenView: View {
    @ObservedObject var viewModel: MissionControlViewModel
    let screenIndex: Int
    let areaSize: CGSize

    var body: some View {
        let mine = viewModel.windows.filter { $0.screenIndex == screenIndex }
        let tiles = MissionControlLayout.tiles(
            windows: mine.map { (id: $0.id, frame: $0.frame) },
            in: CGRect(origin: .zero, size: areaSize)
        )
        let byID = Dictionary(uniqueKeysWithValues: mine.map { ($0.id, $0) })

        ZStack(alignment: .topLeading) {
            // 실제 창이 비치지 않도록 프로스티드 백드롭으로 화면을 덮는다. (Mission Control 느낌)
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.18))
                .ignoresSafeArea()

            ForEach(tiles, id: \.windowID) { tile in
                if let window = byID[tile.windowID] {
                    tileView(window: window, isSelected: window.id == viewModel.currentWindow?.id)
                        .frame(width: tile.rect.width, height: tile.rect.height)
                        .offset(x: tile.rect.minX, y: tile.rect.minY)
                }
            }
        }
        .frame(width: areaSize.width, height: areaSize.height, alignment: .topLeading)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: viewModel.selectedIndex)
        .animation(.easeInOut(duration: 0.15), value: viewModel.windows.map(\.id))
    }

    @ViewBuilder
    private func tileView(window: MCWindow, isSelected: Bool) -> some View {
        ZStack {
            if let image = viewModel.thumbnails[window.id] {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                // 폴백: 아이콘 + 제목
                VStack(spacing: 8) {
                    Image(nsImage: window.appEntry.icon)
                        .resizable()
                        .frame(width: 64, height: 64)
                    Text(window.windowEntry.displayTitle)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.accentColor, lineWidth: isSelected ? 3 : 0)
        }
        .opacity(isSelected ? 1.0 : 0.55)
        .blur(radius: isSelected ? 0 : 2)
        .shadow(color: .black.opacity(isSelected ? 0.35 : 0.15), radius: isSelected ? 12 : 4, y: 2)
    }
}
