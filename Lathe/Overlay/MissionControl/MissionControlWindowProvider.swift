import AppKit
import CoreGraphics
import Foundation

struct MCWindow: Identifiable, Equatable {
    let id: Int          // cgWindowID
    let pid: pid_t
    let appEntry: AppEntry
    let windowEntry: WindowEntry
    let frame: CGRect       // 전역 좌표 (kCGWindowBounds, top-left 원점)
    let localFrame: CGRect  // 소속 화면 기준 로컬 좌표 (top-left 원점) — 배치용
    let screenIndex: Int

    static func == (lhs: MCWindow, rhs: MCWindow) -> Bool { lhs.id == rhs.id }
}

struct MissionControlWindowProvider {
    let windowLister: WindowListing

    init(windowLister: WindowListing = WindowListProvider()) {
        self.windowLister = windowLister
    }

    /// 창 프레임과 겹치는 면적이 가장 큰 화면 인덱스. 화면이 없으면 nil.
    static func screenIndex(forFrame frame: CGRect, screenFrames: [CGRect]) -> Int? {
        guard !screenFrames.isEmpty else { return nil }
        var best: (index: Int, area: CGFloat)?
        for (index, screen) in screenFrames.enumerated() {
            let overlap = screen.intersection(frame)
            let area = overlap.isNull ? 0 : overlap.width * overlap.height
            if best == nil || area > best!.area { best = (index, area) }
        }
        return best?.index
    }

    /// 현재 Space·on-screen·비최소화 창을 열거해 MCWindow 목록으로.
    /// appEntries: 현재 실행 앱 목록(pid→AppEntry). 여기 없는 pid의 창은 제외.
    func windows(appEntries: [AppEntry]) -> [MCWindow] {
        let byPID = Dictionary(uniqueKeysWithValues: appEntries.map { ($0.id, $0) })
        let screenFrames = NSScreen.screens.map { CoordinateSpace.globalTopLeft(from: $0.frame) }

        return byPID.keys.sorted().flatMap { pid -> [MCWindow] in
            guard let app = byPID[pid] else { return [] }
            return windowLister.windows(forProcessIdentifier: pid).compactMap { entry -> MCWindow? in
                guard !entry.isMinimized else { return nil }
                guard let frame = WindowListProvider.frame(forWindowID: entry.id) else { return nil }
                guard let screenIndex = Self.screenIndex(forFrame: frame, screenFrames: screenFrames) else { return nil }
                let screen = screenFrames[screenIndex]
                let localFrame = CGRect(x: frame.minX - screen.minX,
                                        y: frame.minY - screen.minY,
                                        width: frame.width,
                                        height: frame.height)
                return MCWindow(id: entry.id, pid: pid, appEntry: app,
                                windowEntry: entry, frame: frame, localFrame: localFrame,
                                screenIndex: screenIndex)
            }
        }
    }
}

/// CG 전역 좌표(top-left, y↓)와 AppKit(bottom-left, y↑) 사이를 변환한다.
enum CoordinateSpace {
    /// NSScreen.frame(AppKit, bottom-left) → 전역 top-left 좌표계 사각형.
    static func globalTopLeft(from screenFrame: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return screenFrame }
        let primaryMaxY = primary.frame.maxY
        return CGRect(x: screenFrame.minX,
                      y: primaryMaxY - screenFrame.maxY,
                      width: screenFrame.width,
                      height: screenFrame.height)
    }
}
