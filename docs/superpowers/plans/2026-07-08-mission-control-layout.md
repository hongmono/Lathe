# Mission Control 레이아웃 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ⌘+Tab 오버레이에, 현재 Space의 모든 창을 각 모니터 위에 실제 썸네일로 겹침 없이 펼치고 ⌘+Tab으로 하나씩 넘기는 "Mission Control" 레이아웃 모드를 기존 캐러셀과 병존시켜 추가한다.

**Architecture:** 창 단위 별도 엔진(`MissionControl*`)을 신설하고, 하위 유틸(창 열거 `WindowListProvider`, 활성화 `AppActivator`, 패널 설정 `OverlayPanel`)은 재사용한다. `AppDelegate`는 신설 `OverlayPresenting` 프로토콜로 `SettingsStore.layoutMode`에 따라 캐러셀/MC 컨트롤러를 분기한다.

**Tech Stack:** Swift, SwiftUI, AppKit(NSPanel), ScreenCaptureKit(`SCScreenshotManager`), CoreGraphics(`CGWindowListCopyWindowInfo`), XCTest.

## Global Constraints

- macOS deployment target **14.6** — ScreenCaptureKit `SCScreenshotManager` 사용 가능.
- 신규 UI는 **네이티브 SwiftUI 컴포넌트 우선**(`Picker`/`Toggle` 기본) — 커스텀 UI 지양.
- 사용자 노출 문자열은 **L10n(en/ko) 모두** 추가. 릴리스 노트/CHANGELOG는 **한국어**.
- 순수 로직(레이아웃/필터/뷰모델)은 기존 패턴대로 **AppKit 비의존 순수 함수 + XCTest**.
- 빌드/테스트: `xcodebuild -scheme Lathe -destination 'platform=macOS' build` / `test`.
- 기존 캐러셀(fan/strip/stack) 동작은 **변경 없이 유지**.

---

## Task 1: LayoutMode enum + SettingsStore.layoutMode

**Files:**
- Create: `Lathe/Settings/LayoutMode.swift`
- Modify: `Lathe/Settings/SettingsStore.swift` (Key struct, @Published, init)
- Test: `LatheTests/SettingsStoreLayoutModeTests.swift`

**Interfaces:**
- Produces: `enum LayoutMode: String, CaseIterable, Identifiable { case carousel, missionControl }`, `SettingsStore.layoutMode: LayoutMode` (UserDefaults 영속, 기본 `.carousel`).

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import Lathe

final class SettingsStoreLayoutModeTests: XCTestCase {
    func test_defaultsToCarousel() {
        let defaults = UserDefaults(suiteName: "layoutmode.default")!
        defaults.removePersistentDomain(forName: "layoutmode.default")
        let store = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(store.layoutMode, .carousel)
    }

    func test_persistsLayoutMode() {
        let defaults = UserDefaults(suiteName: "layoutmode.persist")!
        defaults.removePersistentDomain(forName: "layoutmode.persist")
        let store = SettingsStore(userDefaults: defaults)
        store.layoutMode = .missionControl
        let reloaded = SettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.layoutMode, .missionControl)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' test -only-testing:LatheTests/SettingsStoreLayoutModeTests`
Expected: FAIL (컴파일 에러: `layoutMode` 없음)

> 참고: `SettingsStore` init이 `userDefaults:` 파라미터를 받는지 확인. 기존 `layoutStyle` 초기화(line ~92)가 `userDefaults.string(forKey:)`를 쓰므로 동일 이니셜라이저 사용.

- [ ] **Step 3: Write minimal implementation**

`Lathe/Settings/LayoutMode.swift`:
```swift
import Foundation

enum LayoutMode: String, CaseIterable, Identifiable {
    case carousel
    case missionControl

    var id: String { rawValue }

    func label(language displayLanguage: AppLanguage) -> String {
        switch self {
        case .carousel: L10n.string("layout.mode.carousel", language: displayLanguage)
        case .missionControl: L10n.string("layout.mode.missionControl", language: displayLanguage)
        }
    }
}
```

`SettingsStore.swift` — `Key`에 추가:
```swift
static let layoutMode = "layoutMode"
```
`@Published` 프로퍼티 추가 (layoutStyle 바로 아래):
```swift
@Published var layoutMode: LayoutMode {
    didSet { defaults.set(layoutMode.rawValue, forKey: Key.layoutMode) }
}
```
init에서 (layoutStyle 초기화 옆):
```swift
self.layoutMode = LayoutMode(rawValue: userDefaults.string(forKey: Key.layoutMode) ?? "") ?? .carousel
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' test -only-testing:LatheTests/SettingsStoreLayoutModeTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Lathe/Settings/LayoutMode.swift Lathe/Settings/SettingsStore.swift LatheTests/SettingsStoreLayoutModeTests.swift
git commit -m "feat: add LayoutMode setting (carousel/missionControl)"
```

---

## Task 2: MissionControlLayout (순수 배치 함수)

**Files:**
- Create: `Lathe/Overlay/MissionControl/MissionControlLayout.swift`
- Test: `LatheTests/MissionControlLayoutTests.swift`

**Interfaces:**
- Produces:
  - `struct MCTileLayout: Equatable { let windowID: Int; let rect: CGRect }`
  - `enum MissionControlLayout { static func tiles(windows: [(id: Int, frame: CGRect)], in area: CGRect, gap: CGFloat = 16, minTile: CGFloat = 40) -> [MCTileLayout] }`
  - 배치: near-square 격자(`cols = ceil(sqrt(n))`), 원본 프레임 중심 (y,x) 오름차순 정렬, 각 셀에 원본 종횡비 aspect-fit 중앙 배치. `area`는 top-left 원점 로컬 좌표.

- [ ] **Step 1: Write the failing test**

```swift
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
            for j in (i+1)..<tiles.count {
                XCTAssertTrue(tiles[i].rect.intersection(tiles[j].rect).isNull
                    || tiles[i].rect.intersection(tiles[j].rect).area < 0.01,
                    "tile \(i) overlaps \(j)")
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

private extension CGRect { var area: CGFloat { width * height } }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' test -only-testing:LatheTests/MissionControlLayoutTests`
Expected: FAIL (컴파일 에러: `MissionControlLayout` 없음)

- [ ] **Step 3: Write minimal implementation**

```swift
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' test -only-testing:LatheTests/MissionControlLayoutTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Lathe/Overlay/MissionControl/MissionControlLayout.swift LatheTests/MissionControlLayoutTests.swift
git commit -m "feat: add MissionControlLayout grid packing"
```

---

## Task 3: MCWindow 모델 + MissionControlWindowProvider

**Files:**
- Create: `Lathe/Overlay/MissionControl/MissionControlWindowProvider.swift`
- Test: `LatheTests/MissionControlWindowProviderTests.swift`

**Interfaces:**
- Produces:
  - `struct MCWindow: Identifiable, Equatable { let id: Int; let pid: pid_t; let appEntry: AppEntry; let windowEntry: WindowEntry; let frame: CGRect; let screenIndex: Int }` (id = cgWindowID)
  - `enum MissionControlWindowProvider { static func screenIndex(forFrame:screenFrames:) -> Int?; func windows(appEntries:) -> [MCWindow] }`
- Consumes: `WindowListProvider` 정적(창/프레임), `AppEntry`, `WindowEntry`, `NSScreen`.

- [ ] **Step 1: Write the failing test** (순수 매핑 함수만 테스트)

```swift
import XCTest
@testable import Lathe

final class MissionControlWindowProviderTests: XCTestCase {
    func test_screenIndex_picksMaxOverlap() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 800),
                       CGRect(x: 1000, y: 0, width: 1000, height: 800)]
        // 대부분 두 번째 화면에 걸친 창.
        let frame = CGRect(x: 900, y: 100, width: 400, height: 300)
        XCTAssertEqual(MissionControlWindowProvider.screenIndex(forFrame: frame, screenFrames: screens), 1)
    }

    func test_screenIndex_noScreens_returnsNil() {
        XCTAssertNil(MissionControlWindowProvider.screenIndex(forFrame: .zero, screenFrames: []))
    }

    func test_screenIndex_fullyOnFirst() {
        let screens = [CGRect(x: 0, y: 0, width: 1000, height: 800),
                       CGRect(x: 1000, y: 0, width: 1000, height: 800)]
        let frame = CGRect(x: 100, y: 100, width: 200, height: 200)
        XCTAssertEqual(MissionControlWindowProvider.screenIndex(forFrame: frame, screenFrames: screens), 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' test -only-testing:LatheTests/MissionControlWindowProviderTests`
Expected: FAIL (컴파일 에러)

- [ ] **Step 3: Write minimal implementation**

```swift
import AppKit
import CoreGraphics
import Foundation

struct MCWindow: Identifiable, Equatable {
    let id: Int          // cgWindowID
    let pid: pid_t
    let appEntry: AppEntry
    let windowEntry: WindowEntry
    let frame: CGRect    // 전역 좌표 (kCGWindowBounds)
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

        return byPID.keys.flatMap { pid -> [MCWindow] in
            guard let app = byPID[pid] else { return [] }
            return windowLister.windows(forProcessIdentifier: pid).compactMap { entry -> MCWindow? in
                guard !entry.isMinimized else { return nil }
                guard let frame = WindowListProvider.frame(forWindowID: entry.id) else { return nil }
                guard let screenIndex = Self.screenIndex(forFrame: frame, screenFrames: screenFrames) else { return nil }
                return MCWindow(id: entry.id, pid: pid, appEntry: app,
                                windowEntry: entry, frame: frame, screenIndex: screenIndex)
            }
        }
    }
}

/// CG 전역 좌표(top-left, y↓)와 AppKit(bottom-left, y↑)을 맞춘다.
enum CoordinateSpace {
    /// NSScreen.frame(bottom-left) → 전역 top-left 좌표계 사각형.
    static func globalTopLeft(from screenFrame: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return screenFrame }
        let maxY = primary.frame.maxY
        return CGRect(x: screenFrame.minX,
                      y: maxY - screenFrame.maxY,
                      width: screenFrame.width,
                      height: screenFrame.height)
    }
}
```

> 이 태스크는 `WindowListProvider.frame(forWindowID:)` 정적 헬퍼가 필요하다. 기존 private `cgFrame(forWindowID:)`를 `static func frame(forWindowID:) -> CGRect?`로 노출(래핑)한다. WindowListProvider.swift 하단에 추가:
> ```swift
> static func frame(forWindowID windowID: Int) -> CGRect? { cgFrame(forWindowID: windowID) }
> ```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' test -only-testing:LatheTests/MissionControlWindowProviderTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Lathe/Overlay/MissionControl/MissionControlWindowProvider.swift Lathe/AppList/WindowListProvider.swift LatheTests/MissionControlWindowProviderTests.swift
git commit -m "feat: add MissionControlWindowProvider + MCWindow"
```

---

## Task 4: MissionControlViewModel

**Files:**
- Create: `Lathe/Overlay/MissionControl/MissionControlViewModel.swift`
- Test: `LatheTests/MissionControlViewModelTests.swift`

**Interfaces:**
- Produces: `@MainActor final class MissionControlViewModel: ObservableObject` with
  `@Published private(set) var windows: [MCWindow]`, `@Published private(set) var selectedIndex: Int`,
  `@Published private(set) var thumbnails: [Int: NSImage]`,
  `func set(windows:selectedWindowID:)`, `func setThumbnail(_:forWindowID:)`, `func next()`, `func previous()`,
  `var currentWindow: MCWindow?`.
- Consumes: `MCWindow` (Task 3).

**Test용 헬퍼:** 아래 테스트는 `MCWindow`를 만들기 위해 `AppEntry`/`WindowEntry` 더미가 필요하다. 테스트 파일 내 팩토리 사용.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import Lathe

@MainActor
final class MissionControlViewModelTests: XCTestCase {
    private func window(_ id: Int) -> MCWindow {
        let app = AppEntry(id: pid_t(id), bundleIdentifier: "x.\(id)", name: "App\(id)", icon: NSImage())
        let entry = WindowEntry(id: id, title: "W\(id)", pathSummary: nil, isMinimized: false)
        return MCWindow(id: id, pid: pid_t(id), appEntry: app, windowEntry: entry,
                        frame: .zero, screenIndex: 0)
    }

    func test_next_wraps() {
        let vm = MissionControlViewModel()
        vm.set(windows: [window(1), window(2), window(3)], selectedWindowID: 1)
        XCTAssertEqual(vm.currentWindow?.id, 1)
        vm.next(); XCTAssertEqual(vm.currentWindow?.id, 2)
        vm.next(); vm.next(); XCTAssertEqual(vm.currentWindow?.id, 1)
    }

    func test_previous_wraps() {
        let vm = MissionControlViewModel()
        vm.set(windows: [window(1), window(2)], selectedWindowID: 1)
        vm.previous(); XCTAssertEqual(vm.currentWindow?.id, 2)
    }

    func test_initialSelection_matchesGivenID() {
        let vm = MissionControlViewModel()
        vm.set(windows: [window(1), window(2), window(3)], selectedWindowID: 3)
        XCTAssertEqual(vm.currentWindow?.id, 3)
    }

    func test_empty_currentWindowNil() {
        let vm = MissionControlViewModel()
        vm.set(windows: [], selectedWindowID: nil)
        XCTAssertNil(vm.currentWindow)
    }

    func test_setThumbnail_keepsSelection() {
        let vm = MissionControlViewModel()
        vm.set(windows: [window(1), window(2)], selectedWindowID: 2)
        vm.setThumbnail(NSImage(), forWindowID: 1)
        XCTAssertEqual(vm.currentWindow?.id, 2)
        XCTAssertNotNil(vm.thumbnails[1])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' test -only-testing:LatheTests/MissionControlViewModelTests`
Expected: FAIL (컴파일 에러)

- [ ] **Step 3: Write minimal implementation**

```swift
import AppKit
import Combine

@MainActor
final class MissionControlViewModel: ObservableObject {
    @Published private(set) var windows: [MCWindow] = []
    @Published private(set) var selectedIndex: Int = 0
    @Published private(set) var thumbnails: [Int: NSImage] = [:]

    func set(windows: [MCWindow], selectedWindowID: Int?) {
        self.windows = windows
        self.thumbnails = [:]
        if let selectedWindowID, let idx = windows.firstIndex(where: { $0.id == selectedWindowID }) {
            selectedIndex = idx
        } else {
            selectedIndex = 0
        }
    }

    func setThumbnail(_ image: NSImage, forWindowID id: Int) {
        thumbnails[id] = image
    }

    func next() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % windows.count
    }

    func previous() {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
    }

    var currentWindow: MCWindow? {
        guard windows.indices.contains(selectedIndex) else { return nil }
        return windows[selectedIndex]
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' test -only-testing:LatheTests/MissionControlViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Lathe/Overlay/MissionControl/MissionControlViewModel.swift LatheTests/MissionControlViewModelTests.swift
git commit -m "feat: add MissionControlViewModel"
```

---

## Task 5: WindowThumbnailProvider (ScreenCaptureKit)

**Files:**
- Create: `Lathe/Overlay/MissionControl/WindowThumbnailProvider.swift`

**Interfaces:**
- Produces: `struct WindowThumbnailProvider { static func hasPermission() -> Bool; static func requestPermission(); func capture(windowIDs: [Int]) async -> [Int: NSImage] }`
- Consumes: ScreenCaptureKit.
- **검증: 실기기 수동** (SCK/권한은 단위 테스트 불가). TDD 테스트 없음 — 대신 빌드 통과 + Task 10 end-to-end.

- [ ] **Step 1: Implement**

```swift
import AppKit
import CoreGraphics
import ScreenCaptureKit

struct WindowThumbnailProvider {
    /// 화면 녹화 권한 여부(비차단).
    static func hasPermission() -> Bool { CGPreflightScreenCaptureAccess() }

    /// 권한 요청(최초 1회 시스템 프롬프트). 결과와 무관하게 오버레이는 폴백 동작.
    @discardableResult
    static func requestPermission() -> Bool { CGRequestScreenCaptureAccess() }

    /// 주어진 cgWindowID들의 현재 화면 이미지를 1회 캡처. 권한 없거나 실패한 창은 결과에서 빠진다.
    func capture(windowIDs: [Int]) async -> [Int: NSImage] {
        guard Self.hasPermission() else { return [:] }
        guard let content = try? await SCShareableContent.excludingDesktopWindows(false,
                                                                                  onScreenWindowsOnly: true) else {
            return [:]
        }
        let wanted = Set(windowIDs.map { UInt32($0) })
        let targets = content.windows.filter { wanted.contains($0.windowID) }

        var result: [Int: NSImage] = [:]
        for window in targets {
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let config = SCStreamConfiguration()
            config.width = Int(window.frame.width)
            config.height = Int(window.frame.height)
            config.showsCursor = false
            guard let cgImage = try? await SCScreenshotManager.captureImage(contentFilter: filter,
                                                                            configuration: config) else {
                continue
            }
            result[Int(window.windowID)] = NSImage(cgImage: cgImage,
                                                    size: NSSize(width: cgImage.width, height: cgImage.height))
        }
        return result
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED (ScreenCaptureKit 링크 확인. 실패 시 프로젝트에 프레임워크 추가 — Task 10과 합류.)

- [ ] **Step 3: Commit**

```bash
git add Lathe/Overlay/MissionControl/WindowThumbnailProvider.swift
git commit -m "feat: add WindowThumbnailProvider via ScreenCaptureKit"
```

---

## Task 6: MissionControlScreenView (SwiftUI 타일 렌더)

**Files:**
- Create: `Lathe/Overlay/MissionControl/MissionControlScreenView.swift`

**Interfaces:**
- Produces: `struct MissionControlScreenView: View` — 한 화면(screenIndex)의 타일을 절대 좌표로 배치. 선택 창 선명+강조 링, 나머지 흐림.
- Consumes: `MissionControlViewModel`, `MissionControlLayout`, `MCTileLayout`, `MCWindow`.
- **검증: 실기기 수동.**

- [ ] **Step 1: Implement**

```swift
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
                        .resizable().frame(width: 64, height: 64)
                    Text(window.windowEntry.displayTitle)
                        .font(.caption).lineLimit(1)
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
```

- [ ] **Step 2: Build**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Lathe/Overlay/MissionControl/MissionControlScreenView.swift
git commit -m "feat: add MissionControlScreenView tile rendering"
```

---

## Task 7: MissionControlController (모니터별 다중 패널)

**Files:**
- Create: `Lathe/Overlay/MissionControl/MissionControlController.swift`

**Interfaces:**
- Produces: `@MainActor final class MissionControlController` — NSScreen마다 패널 1개. 메서드: `show(appEntries:forward:)`, `next()`, `previous()`, `currentSelection() -> OverlaySelection?`, `recordWindowActivation()`, `hide(animated:)`, `isVisible`.
- Consumes: `OverlayPanel`, `MissionControlViewModel`, `MissionControlScreenView`, `MissionControlWindowProvider`, `WindowThumbnailProvider`, `AppEntry`, `OverlaySelection`.
- **검증: 실기기 수동.**

- [ ] **Step 1: Implement**

```swift
import AppKit
import SwiftUI

@MainActor
final class MissionControlController {
    private var panels: [OverlayPanel] = []
    private let viewModel = MissionControlViewModel()
    private let provider = MissionControlWindowProvider()
    private let thumbnails = WindowThumbnailProvider()
    private(set) var isVisible = false

    /// 현재 Space 창을 열거해 각 모니터 패널에 펼친다. forward=true면 활성창 다음을 선택.
    func show(appEntries: [AppEntry], forward: Bool) {
        let windows = provider.windows(appEntries: appEntries)
        guard !windows.isEmpty else { return }

        let activeWindowID = frontmostWindowID(in: windows)
        viewModel.set(windows: windows, selectedWindowID: activeWindowID)
        if forward { viewModel.next() } else { viewModel.previous() }

        rebuildPanels()
        for panel in panels {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            panels.forEach { $0.animator().alphaValue = 1 }
        }
        isVisible = true

        // 썸네일 비동기 캡처 → 완료되는 대로 채움.
        let ids = windows.map(\.id)
        Task { [weak self] in
            let images = await self?.thumbnails.capture(windowIDs: ids) ?? [:]
            for (id, image) in images { self?.viewModel.setThumbnail(image, forWindowID: id) }
        }
    }

    func next() { viewModel.next() }
    func previous() { viewModel.previous() }

    func currentSelection() -> OverlaySelection? {
        guard let window = viewModel.currentWindow else { return nil }
        return OverlaySelection(app: window.appEntry, window: window.windowEntry)
    }

    func recordWindowActivation() { /* MC는 창 단위 MRU 기록 없음. no-op. */ }

    func hide(animated: Bool) {
        guard isVisible else { return }
        isVisible = false
        let toClose = panels
        if animated {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.15
                toClose.forEach { $0.animator().alphaValue = 0 }
            }, completionHandler: {
                MainActor.assumeIsolated { toClose.forEach { $0.orderOut(nil) } }
            })
        } else {
            toClose.forEach { $0.alphaValue = 0; $0.orderOut(nil) }
        }
        panels = []
    }

    /// 화면 수만큼 패널을 만들어 각 화면을 꽉 채운다.
    private func rebuildPanels() {
        panels.forEach { $0.orderOut(nil) }
        panels = NSScreen.screens.enumerated().map { index, screen in
            let panel = OverlayPanel()
            panel.setFrame(screen.frame, display: true)
            let root = MissionControlScreenView(viewModel: viewModel,
                                                screenIndex: index,
                                                areaSize: screen.frame.size)
            let host = NSHostingView(rootView: root)
            host.frame = NSRect(origin: .zero, size: screen.frame.size)
            host.autoresizingMask = [.width, .height]
            let container = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
            container.addSubview(host)
            panel.contentView = container
            return panel
        }
    }

    private func frontmostWindowID(in windows: [MCWindow]) -> Int? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return windows.first?.id }
        return windows.first(where: { $0.pid == pid })?.id ?? windows.first?.id
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Lathe/Overlay/MissionControl/MissionControlController.swift
git commit -m "feat: add MissionControlController with per-screen panels"
```

---

## Task 8: OverlayPresenting 프로토콜 + AppDelegate 디스패치

**Files:**
- Create: `Lathe/Overlay/OverlayPresenting.swift`
- Modify: `Lathe/Overlay/OverlayController.swift` (프로토콜 준수 — 이미 메서드 존재)
- Modify: `Lathe/App/AppDelegate.swift` (분기 배선)

**Interfaces:**
- Produces: `@MainActor protocol OverlayPresenting: AnyObject { var isVisible: Bool { get }; func next(); func previous(); func cycleWindow(); func cycleWindowPrevious(); func currentSelection() -> OverlaySelection?; func recordWindowActivation(); func hide(animated: Bool) }`
- **검증: 실기기 수동 + 빌드.**

- [ ] **Step 1: Implement protocol**

`Lathe/Overlay/OverlayPresenting.swift`:
```swift
import Foundation

@MainActor
protocol OverlayPresenting: AnyObject {
    var isVisible: Bool { get }
    func next()
    func previous()
    func cycleWindow()
    func cycleWindowPrevious()
    func currentSelection() -> OverlaySelection?
    func recordWindowActivation()
    func hide(animated: Bool)
}

extension OverlayController: OverlayPresenting {}

extension MissionControlController: OverlayPresenting {
    // MC는 앱 내 창 순환 개념이 없다. ⌘+` 순환은 전체 창 이동과 동일 취급.
    func cycleWindow() { next() }
    func cycleWindowPrevious() { previous() }
}
```

- [ ] **Step 2: Wire AppDelegate**

`AppDelegate` 필드 추가 및 분기. `overlay` 직접 참조를 `activePresenter`로 대체:
```swift
private var overlay: OverlayController!
private var missionControl: MissionControlController!

private var activePresenter: OverlayPresenting {
    SettingsStore.shared.layoutMode == .missionControl ? missionControl : overlay
}
```
`applicationDidFinishLaunching`에서 `missionControl = MissionControlController()` 생성.

델리게이트 메서드 재작성:
```swift
func hotKeyDidDisarm() {
    let presenter = activePresenter
    guard presenter.isVisible else { return }
    if let selection = presenter.currentSelection() {
        presenter.recordWindowActivation()
        AppActivator.activate(selection.app, window: selection.window)
    }
    hideOverlay(animated: true)
}

func hotKeyDidRequestNext() {
    if activePresenter.isVisible { activePresenter.next() }
    else { presentOverlay(forward: true) }
}

func hotKeyDidRequestPrevious() {
    if activePresenter.isVisible { activePresenter.previous() }
    else { presentOverlay(forward: false) }
}

func hotKeyDidRequestCycleWindow() {
    if activePresenter.isVisible { activePresenter.cycleWindow() }
    else { presentOverlay(forward: true) }
}

func hotKeyDidRequestCycleWindowPrevious() {
    if activePresenter.isVisible { activePresenter.cycleWindowPrevious() }
    else { presentOverlay(forward: false) }
}

func hotKeyDidCancel() { hideOverlay(animated: true) }

/// 모드에 맞는 오버레이를 첫 표시한다.
private func presentOverlay(forward: Bool) {
    appList.refresh()
    let apps = appList.apps
    guard !apps.isEmpty else { return }

    if SettingsStore.shared.layoutMode == .missionControl {
        missionControl.show(appEntries: apps, forward: forward)
    } else {
        // 기존 캐러셀 동작 보존.
        if forward {
            let initial = apps.count > 1 ? 1 : 0
            overlay.show(apps: apps, initialIndex: initial)
        } else {
            overlay.show(apps: apps, initialIndex: apps.count - 1)
        }
    }
    updateHotKeyModes()
}

private func hideOverlay(animated: Bool) {
    hotKey.arrowsEnabled = false
    activePresenter.hide(animated: animated)
}

private func updateHotKeyModes() {
    hotKey.arrowsEnabled = activePresenter.isVisible
}
```
기존 `beginWindowSwitch`는 `presentOverlay(forward:)`로 대체되어 삭제. `appList.didChange`의 `overlay.updateApps`는 캐러셀 전용이므로 `if SettingsStore.shared.layoutMode == .carousel && overlay.isVisible` 가드로 유지.

> 캐러셀의 기존 세부 동작(`cmd+`가 앱을 골라 창 순환) 회귀 방지: 위 재작성은 캐러셀 경로에서 `presentOverlay` 후 `cycleWindow`를 부르지 않음 → 기존 `beginWindowSwitch`의 "창 한 칸 이동"이 사라진다. 이를 보존하려면 caروسel 경로에서도 첫 표시 시 `overlay.cycleWindow()` 호출을 `hotKeyDidRequestCycleWindow`의 else 브랜치에 유지. 구현 시 기존 동작과 diff 비교하여 캐러셀 회귀 없는지 확인.

- [ ] **Step 3: Build + 회귀 확인**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED. 캐러셀 모드(기본)에서 ⌘+Tab 기존 동작 유지 수동 확인.

- [ ] **Step 4: Commit**

```bash
git add Lathe/Overlay/OverlayPresenting.swift Lathe/Overlay/OverlayController.swift Lathe/App/AppDelegate.swift
git commit -m "feat: dispatch overlay by layoutMode via OverlayPresenting"
```

---

## Task 9: 설정 UI — 모드 Picker + 권한 배너 + L10n

**Files:**
- Modify: `Lathe/Settings/SettingsView.swift` (또는 캐러셀 상세 `SettingsCarouselDetailView.swift`)
- Modify: L10n 문자열 리소스 (en/ko)

**Interfaces:**
- Consumes: `SettingsStore.layoutMode`, `LayoutMode`, `WindowThumbnailProvider.hasPermission()/requestPermission()`.
- **검증: 빌드 + 수동.** (레이아웃 계산 테스트가 있으면 기존 `SettingsViewLayoutTests` 확장.)

- [ ] **Step 1: 문자열 추가**

L10n 파일(en/ko)에 키 추가:
```
"layout.mode.title" = "레이아웃" / "Layout";
"layout.mode.carousel" = "캐러셀" / "Carousel";
"layout.mode.missionControl" = "미션 컨트롤" / "Mission Control";
"layout.mode.screenRecording.needed" = "미션 컨트롤은 창 미리보기를 위해 화면 기록 권한이 필요합니다. 권한이 없으면 앱 아이콘으로 표시됩니다." / "Mission Control needs Screen Recording permission for window previews. Without it, windows show as app icons.";
"layout.mode.screenRecording.open" = "권한 열기" / "Open Permission";
```
(기존 L10n 등록 방식 — `Localizable.strings` 또는 코드 딕셔너리 — 을 그대로 따른다.)

- [ ] **Step 2: 모드 Picker + 배너 추가**

설정 뷰 최상단(레이아웃 섹션)에 네이티브 `Picker` 추가:
```swift
Picker(L10n.string("layout.mode.title", language: settings.appLanguage), selection: $settings.layoutMode) {
    ForEach(LayoutMode.allCases) { mode in
        Text(mode.label(language: settings.appLanguage)).tag(mode)
    }
}
.pickerStyle(.segmented)

if settings.layoutMode == .missionControl && !WindowThumbnailProvider.hasPermission() {
    HStack {
        Text(L10n.string("layout.mode.screenRecording.needed", language: settings.appLanguage))
            .font(.footnote).foregroundStyle(.secondary)
        Spacer()
        Button(L10n.string("layout.mode.screenRecording.open", language: settings.appLanguage)) {
            WindowThumbnailProvider.requestPermission()
        }
    }
}
```
fan/strip/stack 및 fan radius/spacing 컨트롤은 `if settings.layoutMode == .carousel` 로 감싸 숨김.

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' build`
Expected: BUILD SUCCEEDED. 기존 설정 테스트: `xcodebuild ... test -only-testing:LatheTests/SettingsViewLayoutTests`

- [ ] **Step 4: Commit**

```bash
git add Lathe/Settings/ Lathe/Resources/
git commit -m "feat: layout mode picker + screen recording banner in settings"
```

---

## Task 10: 프레임워크 링크 · Info.plist · end-to-end 수동 검증

**Files:**
- Modify: `Lathe.xcodeproj/project.pbxproj` (ScreenCaptureKit 링크 — Task 5에서 이미 됐으면 skip)
- Modify: `Lathe/Resources/Info.plist` (필요 시 `NSScreenCaptureUsageDescription`)
- Modify: `CHANGELOG.md` (한국어 항목)

- [ ] **Step 1: 프레임워크/plist 확인**

전체 빌드: `xcodebuild -scheme Lathe -destination 'platform=macOS' build`
ScreenCaptureKit 미링크로 실패 시 프로젝트 General → Frameworks에 `ScreenCaptureKit.framework` 추가. 권한 프롬프트 문구가 필요하면 Info.plist에 `NSScreenCaptureUsageDescription` 추가(한/영).

- [ ] **Step 2: 전체 테스트**

Run: `xcodebuild -scheme Lathe -destination 'platform=macOS' test`
Expected: 전체 PASS (신규 3개 스위트 포함, 기존 회귀 없음).

- [ ] **Step 3: 실기기 end-to-end (수동)**

1. 설정에서 레이아웃 = 미션 컨트롤 선택. 화면 기록 권한 부여.
2. 여러 앱/창을 여러 모니터에 배치.
3. ⌘+Tab → 각 모니터에 창 썸네일이 겹침 없이 뜨는지, 선택 창만 선명·나머지 흐림, ⌘+Tab 반복 시 커서 이동, ⌘ 떼면 선택 창으로 포커스 전환 확인.
4. 권한 거부 상태 → 아이콘 타일 폴백 확인.
5. 레이아웃 = 캐러셀로 되돌려 기존 ⌘+Tab 회귀 없는지 확인.

- [ ] **Step 4: CHANGELOG + Commit**

`CHANGELOG.md`에 한국어 항목 추가(예: "미션 컨트롤 레이아웃 추가 — 모든 창을 모니터별로 펼쳐 ⌘+Tab으로 전환").
```bash
git add CHANGELOG.md Lathe.xcodeproj/project.pbxproj Lathe/Resources/Info.plist
git commit -m "docs: changelog + link ScreenCaptureKit for mission control"
```

---

## Self-Review 결과

- **Spec 커버리지**: 실제 썸네일(T5), 모니터별 배치(T7 rebuildPanels), 겹침 정리(T2), 현재 Space 보이는 창만(T3 필터), 설정 택1+⌘+Tab 공유(T1/T8), SCK(T5), 정적 캡처(T7 Task 1회), 권한 폴백(T5/T6/T9) — 전부 태스크 존재.
- **Placeholder 스캔**: 코드 스텝에 실제 코드 포함, TBD 없음. (T9 문자열은 기존 L10n 등록 방식 확인 필요 — 구현 시 파일 형태 맞춤.)
- **타입 일관성**: `MCWindow`(id/pid/appEntry/windowEntry/frame/screenIndex), `MissionControlViewModel.set(windows:selectedWindowID:)`, `OverlayPresenting` 시그니처 T7/T8 일치. `OverlaySelection(app:window:)`는 기존 타입 재사용.
- **알려진 리스크**: (1) `WindowListProvider.frame(forWindowID:)` 노출 필요(T3에 명시). (2) 좌표계 변환 `CoordinateSpace.globalTopLeft` — 다중 모니터 y축 뒤집기 실기기 검증 필수. (3) 캐러셀 `cmd+` 회귀(T8 노트). (4) L10n 등록 방식은 구현 시 기존 파일 형태에 맞춤.
