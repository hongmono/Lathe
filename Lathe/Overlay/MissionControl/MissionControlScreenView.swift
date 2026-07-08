import SwiftUI

struct MissionControlScreenView: View {
    @ObservedObject var viewModel: MissionControlViewModel
    let screenIndex: Int
    let areaSize: CGSize

    // 오버레이가 뜰 때마다 뷰가 새로 생성되므로 false로 시작 → onAppear에서 등장 애니메이션.
    @State private var appeared = false

    var body: some View {
        let mine = viewModel.stacks.filter { $0.screenIndex == screenIndex }
        let tiles = MissionControlLayout.tiles(
            windows: mine.map { (id: $0.id, frame: $0.frontWindow.localFrame) },
            in: CGRect(origin: .zero, size: areaSize)
        )
        let byID = Dictionary(uniqueKeysWithValues: mine.map { ($0.id, $0) })

        ZStack(alignment: .topLeading) {
            // 실제 창이 비치지 않도록 프로스티드 백드롭으로 화면을 덮는다. (Mission Control 느낌)
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.18))
                .ignoresSafeArea()

            ForEach(Array(tiles.enumerated()), id: \.element.windowID) { index, tile in
                if let stack = byID[tile.windowID] {
                    stackView(stack: stack, isSelected: stack.id == viewModel.currentStack?.id)
                        .frame(width: tile.rect.width, height: tile.rect.height)
                        .scaleEffect(appeared ? 1 : 0.88)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(response: 0.42, dampingFraction: 0.74)
                            .delay(Double(index) * 0.045), value: appeared)
                        .offset(x: tile.rect.minX, y: tile.rect.minY)
                }
            }
        }
        .frame(width: areaSize.width, height: areaSize.height, alignment: .topLeading)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: viewModel.selectedStackIndex)
        .animation(.spring(response: 0.34, dampingFraction: 0.72), value: viewModel.currentStack?.frontIndex)
        .animation(.easeInOut(duration: 0.15), value: viewModel.stacks.map(\.id))
        .onAppear { appeared = true }
    }

    /// 앱 스택: 스택의 각 창을 실제 카드로 그리고 frontIndex 기준 상대 깊이로 배치한다.
    /// ⌘+`로 frontIndex가 바뀌면 각 카드가 offset/scale을 애니메이션하며 **실제로 자리를 옮긴다**.
    @ViewBuilder
    private func stackView(stack: MCAppStack, isSelected: Bool) -> some View {
        let count = stack.windows.count
        let maxDepth = 2   // 앞 + 뒤 2장까지 노출
        ZStack {
            ForEach(stack.windows) { window in
                let idx = stack.windows.firstIndex { $0.id == window.id } ?? 0
                let depth = (idx - stack.frontIndex + count) % count   // 0 = 맨 앞
                let d = CGFloat(min(depth, maxDepth))
                card(window: window, isFront: depth == 0, isSelected: isSelected)
                    .scaleEffect(1 - d * 0.03)
                    .offset(x: d * 16, y: d * 16)
                    .opacity(depth <= maxDepth ? (depth == 0 ? 1 : (isSelected ? 0.9 : 0.5)) : 0)
                    .zIndex(Double(count - depth))
            }
        }
    }

    @ViewBuilder
    private func card(window: MCWindow, isFront: Bool, isSelected: Bool) -> some View {
        ZStack {
            // 폴백(아이콘+제목)을 항상 깔고, 썸네일이 도착하면 그 위로 1초에 걸쳐 서서히 나타난다.
            fallbackTile(window: window)

            if let image = viewModel.thumbnails[window.id] {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 1.0), value: viewModel.thumbnails[window.id] != nil)
        .overlay {
            // 선택 안 된 스택은 살짝 어둡게(dim). 흐림(blur) 아님.
            Color.black.opacity(isSelected ? 0 : 0.3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay {
            // 강조 링은 선택된 스택의 맨 앞 카드에만.
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.accentColor, lineWidth: (isSelected && isFront) ? 3 : 0)
        }
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }

    @ViewBuilder
    private func fallbackTile(window: MCWindow) -> some View {
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
        .background(.ultraThinMaterial)
    }
}
