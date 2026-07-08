import XCTest
@testable import Lathe

final class MissionControlLayoutTests: XCTestCase {
    private let area = CGRect(x: 0, y: 0, width: 1000, height: 800)

    func test_empty_returnsEmpty() {
        XCTAssertTrue(MissionControlLayout.tiles(windows: [], in: area).isEmpty)
    }

    func test_single_fitsInsideArea() {
        let tiles = MissionControlLayout.tiles(
            windows: [(id: 1, frame: CGRect(x: 0, y: 0, width: 800, height: 600))], in: area)
        XCTAssertEqual(tiles.count, 1)
        XCTAssertTrue(area.contains(tiles[0].rect))
    }

    func test_four_noOverlap() {
        let ws = (1...4).map { (id: $0, frame: CGRect(x: 0, y: 0, width: 400, height: 300)) }
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        XCTAssertEqual(tiles.count, 4)
        for i in tiles.indices {
            for j in (i + 1)..<tiles.count {
                let overlap = tiles[i].rect.intersection(tiles[j].rect)
                XCTAssertTrue(overlap.isNull || overlap.area < 0.01, "tile \(i) overlaps \(j)")
            }
        }
    }

    func test_deterministic() {
        let ws = (1...5).map { (id: $0, frame: CGRect(x: CGFloat($0 * 50), y: 0, width: 300, height: 200)) }
        XCTAssertEqual(MissionControlLayout.tiles(windows: ws, in: area),
                       MissionControlLayout.tiles(windows: ws, in: area))
    }

    func test_ordersByTopLeftReadingOrder() {
        // 오른쪽-아래 창을 먼저 넣어도 정렬 결과는 (y,x) 오름차순.
        let ws = [
            (id: 10, frame: CGRect(x: 500, y: 400, width: 200, height: 200)), // 아래-오른쪽
            (id: 20, frame: CGRect(x: 0, y: 0, width: 200, height: 200)),     // 위-왼쪽
        ]
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        XCTAssertEqual(tiles.first?.windowID, 20)
    }
}

private extension CGRect {
    var area: CGFloat { width * height }
}
