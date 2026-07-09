import XCTest
@testable import Lathe

final class MissionControlLayoutTests: XCTestCase {
    private let area = CGRect(x: 0, y: 0, width: 1600, height: 1000)

    func test_empty_returnsEmpty() {
        XCTAssertTrue(MissionControlLayout.tiles(windows: [], in: area).isEmpty)
    }

    func test_stackedWindows_spreadWithoutOverlap() {
        // 모두 같은 자리에 최대화된 4개 창 → 격자로 펼쳐 서로 안 겹침.
        let ws = (1...4).map { (id: $0, frame: CGRect(x: 0, y: 39, width: 1800, height: 1130)) }
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        XCTAssertEqual(tiles.count, 4)
        for i in tiles.indices {
            for j in (i + 1)..<tiles.count {
                let o = tiles[i].rect.intersection(tiles[j].rect)
                XCTAssertTrue(o.isNull || o.width * o.height < 0.01, "tile \(i) overlaps \(j)")
            }
        }
    }

    func test_preservesAspectRatio() {
        let ws = [(id: 1, frame: CGRect(x: 0, y: 0, width: 1600, height: 900)),
                  (id: 2, frame: CGRect(x: 100, y: 100, width: 800, height: 600))]
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        let byID = Dictionary(uniqueKeysWithValues: tiles.map { ($0.windowID, $0.rect) })
        for w in ws {
            let rect = byID[w.id]!
            XCTAssertEqual(w.frame.width / w.frame.height,
                           rect.width / rect.height, accuracy: 0.01)
        }
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

    func test_ordersByReadingOrder() {
        // 아래-오른쪽 창을 먼저 넣어도 첫 타일은 위-왼쪽 창.
        let ws = [(id: 10, frame: CGRect(x: 800, y: 600, width: 300, height: 200)),
                  (id: 20, frame: CGRect(x: 0, y: 0, width: 300, height: 200))]
        let tiles = MissionControlLayout.tiles(windows: ws, in: area)
        XCTAssertEqual(tiles.first?.windowID, 20)
    }

    func test_aspectFit_doesNotUpscaleSmallWindow() {
        // 창이 cell보다 작으면 원래 크기 유지(확대 안 함) — macOS처럼 창 1개면 실제 크기.
        let fit = MissionControlLayout.aspectFit(CGSize(width: 200, height: 400),
                                                 in: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        XCTAssertEqual(fit.width, 200)
        XCTAssertEqual(fit.height, 400)
        XCTAssertEqual(fit.midX, 500)   // 가운데 정렬은 유지
        XCTAssertEqual(fit.midY, 500)
    }

    func test_aspectFit_downscalesLargeWindow() {
        let fit = MissionControlLayout.aspectFit(CGSize(width: 1000, height: 500),
                                                 in: CGRect(x: 0, y: 0, width: 500, height: 500))
        XCTAssertEqual(fit.width, 500)
        XCTAssertEqual(fit.height, 250)
    }

    func test_deterministic() {
        let ws = (1...5).map {
            (id: $0, frame: CGRect(x: CGFloat($0 * 100), y: CGFloat($0 * 60), width: 400, height: 300))
        }
        XCTAssertEqual(MissionControlLayout.tiles(windows: ws, in: area),
                       MissionControlLayout.tiles(windows: ws, in: area))
    }
}
