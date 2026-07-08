import CoreGraphics
import Foundation

struct MCTileLayout: Equatable {
    let windowID: Int
    let rect: CGRect
}

enum MissionControlLayout {
    /// 화면 로컬(top-left 원점) 좌표계에서 창을 겹치지 않게 격자 배치한다.
    /// - windows: (창 ID, 전역 프레임). 프레임은 종횡비와 정렬 순서 판정에만 쓴다.
    /// ponytail: 단순 near-square 격자 패킹. 창이 많아 셀이 과도하게 작아지면 셀 세분화로 업그레이드.
    static func tiles(windows: [(id: Int, frame: CGRect)],
                      in area: CGRect,
                      gap: CGFloat = 16,
                      minTile: CGFloat = 40) -> [MCTileLayout] {
        let n = windows.count
        guard n > 0 else { return [] }

        // 원본 위치 순서 보존: (y, x) 오름차순 = 좌상단부터 읽기 순서.
        let sorted = windows.sorted {
            if $0.frame.midY != $1.frame.midY { return $0.frame.midY < $1.frame.midY }
            return $0.frame.midX < $1.frame.midX
        }

        let cols = Int(ceil(Double(n).squareRoot()))
        let rows = Int(ceil(Double(n) / Double(cols)))

        let cellW = (area.width - gap * CGFloat(cols + 1)) / CGFloat(cols)
        let cellH = (area.height - gap * CGFloat(rows + 1)) / CGFloat(rows)

        return sorted.enumerated().map { index, window in
            let row = index / cols
            let col = index % cols
            let cellX = area.minX + gap + CGFloat(col) * (cellW + gap)
            let cellY = area.minY + gap + CGFloat(row) * (cellH + gap)
            let cell = CGRect(x: cellX, y: cellY, width: max(cellW, minTile), height: max(cellH, minTile))
            return MCTileLayout(windowID: window.id, rect: aspectFit(window.frame.size, in: cell))
        }
    }

    /// 원본 종횡비를 유지한 채 cell 안에 중앙 정렬로 맞춘다.
    static func aspectFit(_ size: CGSize, in cell: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return cell }
        let scale = min(cell.width / size.width, cell.height / size.height)
        let w = size.width * scale
        let h = size.height * scale
        return CGRect(x: cell.midX - w / 2, y: cell.midY - h / 2, width: w, height: h)
    }
}
