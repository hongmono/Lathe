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

/// 같은 앱(한 화면)의 창들을 묶은 스택. 맨 앞(frontIndex) 창이 대표.
struct MCAppStack: Identifiable {
    let id: Int              // pid*1000+screen — (pid, screen)당 유니크
    let appEntry: AppEntry
    let screenIndex: Int
    let windows: [MCWindow]  // MRU 순 (index 0 = 가장 최근)
    var frontIndex: Int

    var frontWindow: MCWindow { windows[frontIndex] }
}

struct MissionControlWindowProvider {

    /// 창 목록을 (pid, 화면)별로 묶어 스택 배열로. 입력 순서(=MRU)를 스택 안에서 보존하고,
    /// 스택 배열 순서는 화면(screenIndex) 우선 → 같은 화면 안에선 첫 등장 순서. frontIndex는 0(가장 최근).
    /// (한 화면의 스택을 다 순회한 뒤 다음 화면으로 넘어가도록 탭 순서를 일관되게 만든다.)
    static func group(_ windows: [MCWindow]) -> [MCAppStack] {
        var order: [Int] = []
        var windowsByStack: [Int: [MCWindow]] = [:]
        var appByStack: [Int: AppEntry] = [:]
        var screenByStack: [Int: Int] = [:]
        for window in windows {
            let stackID = Int(window.pid) * 1000 + window.screenIndex
            if windowsByStack[stackID] == nil {
                order.append(stackID)
                appByStack[stackID] = window.appEntry
                screenByStack[stackID] = window.screenIndex
            }
            windowsByStack[stackID, default: []].append(window)
        }
        return order.map { stackID in
            MCAppStack(id: stackID,
                       appEntry: appByStack[stackID]!,
                       screenIndex: screenByStack[stackID]!,
                       windows: windowsByStack[stackID]!,
                       frontIndex: 0)
        }.sorted { $0.screenIndex < $1.screenIndex }   // Swift sort는 stable → 화면 내 등장 순서 유지
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

    /// 현재 Space·온스크린 유저 창을 CGWindowList **한 번**으로 열거해 MCWindow 목록으로.
    /// AX 왕복·창별 frame 조회 없이 (pid, id, bounds, title)을 한 방에 얻는다. (미션 컨트롤 전용 빠른 경로)
    /// appEntries: 현재 실행 앱 목록(pid→AppEntry). 여기 없는 pid의 창은 제외.
    func windows(appEntries: [AppEntry]) -> [MCWindow] {
        let appsByPID = Dictionary(uniqueKeysWithValues: appEntries.map { ($0.id, $0) })
        let screenFrames = NSScreen.screens.map { CoordinateSpace.globalTopLeft(from: $0.frame) }
        guard let raw = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return [] }
        return Self.mcWindows(fromWindowList: raw, appsByPID: appsByPID, screenFrames: screenFrames,
                              requireTitle: WindowThumbnailProvider.hasPermission())
    }

    /// CGWindowList raw dict → MCWindow 변환(순수). 알 수 없는 pid·유저 창 아님·화면 밖 창은 제외.
    /// 온스크린 창만 오므로 비최소화가 보장된다. CGWindowList는 z-order(앞→뒤)라 결과도 그 순서.
    /// requireTitle: 제목 없는 창(그림자·래퍼 같은 보조 레이어)을 제외할지. 화면 기록 권한이 있을 때만 켠다
    ///   — 권한이 없으면 CGWindowName이 전부 비어 이 필터가 유저 창까지 지워버리기 때문.
    static func mcWindows(fromWindowList raw: [[String: Any]],
                          appsByPID: [pid_t: AppEntry],
                          screenFrames: [CGRect],
                          requireTitle: Bool) -> [MCWindow] {
        raw.compactMap { info -> MCWindow? in
            guard let ownerPID = (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value else { return nil }
            let pid = pid_t(ownerPID)
            guard let app = appsByPID[pid] else { return nil }
            guard WindowVisibilityFilter.passesOnScreenCGWindow(info) else { return nil }
            let title = (info[kCGWindowName as String] as? String) ?? ""
            if requireTitle, title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
            guard let id = (info[kCGWindowNumber as String] as? NSNumber)?.intValue,
                  let frame = cgFrame(from: info),
                  let screenIndex = screenIndex(forFrame: frame, screenFrames: screenFrames) else { return nil }
            let entry = WindowEntry(id: id, title: title, pathSummary: nil, isMinimized: false)
            let screen = screenFrames[screenIndex]
            let localFrame = CGRect(x: frame.minX - screen.minX, y: frame.minY - screen.minY,
                                    width: frame.width, height: frame.height)
            return MCWindow(id: id, pid: pid, appEntry: app, windowEntry: entry,
                            frame: frame, localFrame: localFrame, screenIndex: screenIndex)
        }
    }

    private static func cgFrame(from info: [String: Any]) -> CGRect? {
        guard let bounds = info[kCGWindowBounds as String] as? [String: Any],
              let x = (bounds["X"] as? NSNumber)?.doubleValue,
              let y = (bounds["Y"] as? NSNumber)?.doubleValue,
              let w = (bounds["Width"] as? NSNumber)?.doubleValue,
              let h = (bounds["Height"] as? NSNumber)?.doubleValue else { return nil }
        return CGRect(x: x, y: y, width: w, height: h)
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
