import XCTest
@testable import Lathe

final class MissionControlLayoutTests: XCTestCase {
    private let area = CGRect(x: 0, y: 0, width: 1600, height: 1000)

    func test_empty_returnsEmpty() {
        XCTAssertTrue(MissionControlLayout.tiles(windows: [], in: area).isEmpty)
    }

    func test_preservesAspectRatio() {
        let ws = [(id: 1, frame: CGRect(x: 100, y: 80, width: 800, height: 600)),
                  (id: 2, frame: CGRect(x: 1000, y: 500, width: 400, height: 300))]
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        for (w, t) in zip(ws, tiles) {
            XCTAssertEqual(w.frame.width / w.frame.height,
                           t.rect.width / t.rect.height, accuracy: 0.01)
        }
    }

    func test_preservesRelativeSize() {
        // 창1 면적이 창2의 4배 → 타일도 4배 (균일 축소).
        let ws = [(id: 1, frame: CGRect(x: 0, y: 0, width: 800, height: 600)),
                  (id: 2, frame: CGRect(x: 900, y: 700, width: 400, height: 300))]
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        let a0 = tiles[0].rect.width * tiles[0].rect.height
        let a1 = tiles[1].rect.width * tiles[1].rect.height
        XCTAssertEqual(a0 / a1, 4.0, accuracy: 0.05)
    }

    func test_allWithinArea() {
        let ws = (1...6).map {
            (id: $0, frame: CGRect(x: CGFloat($0 * 120), y: CGFloat($0 * 80), width: 500, height: 360))
        }
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        for t in tiles {
            XCTAssertTrue(area.insetBy(dx: -0.5, dy: -0.5).contains(t.rect))
        }
    }

    func test_separatesOverlappingWindows() {
        // 거의 완전히 겹친 두 창 → 결과는 서로 안 겹침.
        let ws = [(id: 1, frame: CGRect(x: 400, y: 300, width: 500, height: 400)),
                  (id: 2, frame: CGRect(x: 430, y: 330, width: 500, height: 400))]
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        let o = tiles[0].rect.intersection(tiles[1].rect)
        let overlapArea = o.isNull ? 0 : o.width * o.height
        XCTAssertLessThan(overlapArea, 1.0)
    }

    func test_preservesRelativePosition() {
        // 왼쪽 창은 오른쪽 창보다 왼쪽에 유지.
        let ws = [(id: 1, frame: CGRect(x: 50, y: 400, width: 300, height: 220)),
                  (id: 2, frame: CGRect(x: 1200, y: 400, width: 300, height: 220))]
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        XCTAssertLessThan(tiles[0].rect.midX, tiles[1].rect.midX)
    }

    func test_deterministic() {
        let ws = (1...5).map {
            (id: $0, frame: CGRect(x: CGFloat($0 * 100), y: CGFloat($0 * 60), width: 400, height: 300))
        }
        XCTAssertEqual(MissionControlLayout.tiles(windows: ws, in: area),
                       MissionControlLayout.tiles(windows: ws, in: area))
    }
}
