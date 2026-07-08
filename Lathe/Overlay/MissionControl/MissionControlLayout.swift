import CoreGraphics
import Foundation

struct MCTileLayout: Equatable {
    let windowID: Int
    let rect: CGRect
}

enum MissionControlLayout {
    /// 창들을 화면에 겹치지 않게 펼친다. 실제 창들이 서로 크게 겹쳐 있어도(예: 모두 최대화)
    /// 각자 보이도록 near-square 격자로 배치하고, 원래 위치 순서(위→아래, 왼→오)를 보존한다.
    /// (Mission Control이 겹친 창들을 펼치는 방식과 동일한 결과.)
    /// - windows: (창 ID, 화면-로컬 프레임). 프레임은 종횡비와 정렬 순서에 쓴다.
    static func tiles(windows: [(id: Int, frame: CGRect)],
                      in area: CGRect,
                      gap: CGFloat = 28) -> [MCTileLayout] {
        let n = windows.count
        guard n > 0 else { return [] }

        // 원래 위치 순서 보존: (y, x) 오름차순 = 좌상단부터 읽기 순서.
        let sorted = windows.sorted {
            if abs($0.frame.midY - $1.frame.midY) > 1 { return $0.frame.midY < $1.frame.midY }
            return $0.frame.midX < $1.frame.midX
        }

        let cols = Int(ceil(Double(n).squareRoot()))
        let rows = Int(ceil(Double(n) / Double(cols)))
        let cellW = (area.width - gap * CGFloat(cols + 1)) / CGFloat(cols)
        let cellH = (area.height - gap * CGFloat(rows + 1)) / CGFloat(rows)

        return sorted.enumerated().map { index, window in
            let row = index / cols
            let col = index % cols
            // 마지막 행이 덜 찼으면 가운데 정렬.
            let itemsInRow = (row == rows - 1) ? (n - row * cols) : cols
            let rowWidth = CGFloat(itemsInRow) * cellW + CGFloat(itemsInRow - 1) * gap
            let rowStartX = area.minX + (area.width - rowWidth) / 2
            let cellX = rowStartX + CGFloat(col) * (cellW + gap)
            let cellY = area.minY + gap + CGFloat(row) * (cellH + gap)
            let cell = CGRect(x: cellX, y: cellY, width: cellW, height: cellH)

            // 셀보다 살짝 작게 맞춘 뒤, 창별로 고정된 미세 크기·위치 변주를 준다.
            // → 정사각 격자(4개, 9개 등)도 기계적으로 딱 맞지 않고 유기적으로 보이게.
            let fit = aspectFit(window.frame.size, in: cell.insetBy(dx: cell.width * 0.05, dy: cell.height * 0.05))
            let scaleJitter = 1.0 - 0.10 * hash01(window.id)            // 0.90 ~ 1.00
            let w = fit.width * scaleJitter
            let h = fit.height * scaleJitter
            let jx = (hash01(window.id &+ 101) - 0.5) * cell.width * 0.10
            let jy = (hash01(window.id &+ 211) - 0.5) * cell.height * 0.10
            let rect = CGRect(x: cell.midX - w / 2 + jx, y: cell.midY - h / 2 + jy, width: w, height: h)
            return MCTileLayout(windowID: window.id, rect: rect)
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

    /// 창 ID로부터 0~1 사이의 결정적 유사난수. 변주를 창마다 고정시킨다.
    static func hash01(_ n: Int) -> Double {
        var x = UInt32(truncatingIfNeeded: n &* 0x9E3779B9)
        x ^= x >> 16; x = x &* 0x7FEB352D; x ^= x >> 15; x = x &* 0x846CA68B; x ^= x >> 16
        return Double(x) / Double(UInt32.max)
    }
}
