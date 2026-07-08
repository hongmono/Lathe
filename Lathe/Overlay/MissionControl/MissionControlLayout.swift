import CoreGraphics
import Foundation

struct MCTileLayout: Equatable {
    let windowID: Int
    let rect: CGRect
}

enum MissionControlLayout {
    /// 각 창의 실제 위치·상대 크기를 유지한 채 화면에 맞게 균일 축소하고, 겹친 창만 밀어내 정리한다.
    /// (Mission Control식 배치 — 격자에 우겨넣지 않는다.)
    /// - windows: (창 ID, 화면-로컬 프레임(top-left 원점)).
    /// - area: 화면-로컬 영역 (top-left 원점).
    /// ponytail: 침투 최소 축 분리를 반복하는 완화(relaxation) 방식. 창이 매우 많아 수렴이 덜 되면
    ///           comfort를 낮추거나 iterations를 늘려 튜닝.
    static func tiles(windows: [(id: Int, frame: CGRect)],
                      in area: CGRect,
                      margin: CGFloat = 24,
                      gap: CGFloat = 12,
                      comfort: CGFloat = 0.85,
                      iterations: Int = 240) -> [MCTileLayout] {
        guard !windows.isEmpty else { return [] }
        let inner = area.insetBy(dx: margin, dy: margin)

        // 1. 전체 배치를 화면 중심 기준으로 균일 축소 → 실제 위치/상대 크기 유지.
        let fit = min(inner.width / area.width, inner.height / area.height)
        let s = max(0.01, fit * comfort)
        let areaCenter = CGPoint(x: area.midX, y: area.midY)
        let innerCenter = CGPoint(x: inner.midX, y: inner.midY)

        var rects: [CGRect] = windows.map { w in
            let cx = innerCenter.x + (w.frame.midX - areaCenter.x) * s
            let cy = innerCenter.y + (w.frame.midY - areaCenter.y) * s
            let size = CGSize(width: w.frame.width * s, height: w.frame.height * s)
            return CGRect(x: cx - size.width / 2, y: cy - size.height / 2,
                          width: size.width, height: size.height)
        }

        // 2. 겹침 해소: 침투가 적은 축으로 서로 밀어낸다. (결정적)
        for _ in 0..<iterations {
            var moved = false
            for i in 0..<rects.count {
                for j in (i + 1)..<rects.count {
                    let a = rects[i].insetBy(dx: -gap / 2, dy: -gap / 2)
                    let b = rects[j].insetBy(dx: -gap / 2, dy: -gap / 2)
                    let o = a.intersection(b)
                    guard !o.isNull, o.width > 0.01, o.height > 0.01 else { continue }
                    if o.width < o.height {
                        let dir: CGFloat = (rects[i].midX >= rects[j].midX) ? 1 : -1
                        let push = (o.width / 2) * dir
                        rects[i].origin.x += push
                        rects[j].origin.x -= push
                    } else {
                        let dir: CGFloat = (rects[i].midY >= rects[j].midY) ? 1 : -1
                        let push = (o.height / 2) * dir
                        rects[i].origin.y += push
                        rects[j].origin.y -= push
                    }
                    moved = true
                }
            }
            for i in 0..<rects.count { rects[i] = clamp(rects[i], into: inner) }
            if !moved { break }
        }

        return zip(windows, rects).map { MCTileLayout(windowID: $0.0.id, rect: $0.1) }
    }

    /// rect를 크기 변경 없이 bounds 안으로 이동한다.
    private static func clamp(_ rect: CGRect, into bounds: CGRect) -> CGRect {
        var r = rect
        if r.maxX > bounds.maxX { r.origin.x = bounds.maxX - r.width }
        if r.minX < bounds.minX { r.origin.x = bounds.minX }
        if r.maxY > bounds.maxY { r.origin.y = bounds.maxY - r.height }
        if r.minY < bounds.minY { r.origin.y = bounds.minY }
        return r
    }
}
