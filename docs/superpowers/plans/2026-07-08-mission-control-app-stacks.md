# Mission Control 앱 스택 Implementation Plan

**Goal:** MC에서 같은 앱 창을 스택으로 묶고 ⌘+`로 스택 내부 창을 순환한다.

**Tech:** Swift/SwiftUI/AppKit, XCTest. 스펙: `docs/superpowers/specs/2026-07-08-mission-control-app-stacks-design.md`.

**Global Constraints:** XcodeGen(`xcodegen generate` 후 `xcodebuild -scheme Lathe -destination 'platform=macOS' test`). 네이티브 SwiftUI. 기존 캐러셀·MC 재사용 최대화.

---

## Task 1: MCAppStack + provider stacks() (그룹핑/MRU)

**Files:** `Lathe/Overlay/MissionControl/MissionControlWindowProvider.swift`, `LatheTests/MissionControlWindowProviderTests.swift`

**Produces:** `struct MCAppStack: Identifiable { id, appEntry, screenIndex, windows:[MCWindow], frontIndex; frontWindow }`; provider가 창들을 `(pid, screenIndex)`로 그룹핑하는 순수 헬퍼 `static func group(_ windows: [MCWindow]) -> [MCAppStack]` (MRU 순서는 입력 순서 유지).

- [ ] TDD: `group` 순수 함수 테스트 — 같은 pid+screen 묶음, 다른 화면 분리, 입력(=MRU) 순서 유지, frontIndex=0, id 유니크.
- [ ] 구현 `group` + `stacks(appEntries:)` (기존 `windows(appEntries:)`가 만든 MCWindow를 MRU 정렬 후 group). MRU는 `WindowFocusTracker` 주입.
- [ ] 빌드+테스트, 커밋.

## Task 2: MissionControlViewModel 재구성

**Files:** `Lathe/Overlay/MissionControl/MissionControlViewModel.swift`, `LatheTests/MissionControlViewModelTests.swift`

**Produces:** `stacks`, `selectedStackIndex`, `set(stacks:selectedWindowID:)`, `next/previous`(스택), `cycleWindow/cycleWindowPrevious`(frontIndex), `currentStack`, `currentWindow`, `thumbnails` 유지.

- [ ] TDD 재작성: 스택 next/previous 랩, cycleWindow 랩(frontIndex), 초기선택=selectedWindowID 포함 스택, currentWindow=front, 빈 목록.
- [ ] 구현. 빌드+테스트, 커밋.

## Task 3: 컨트롤러 배선

**Files:** `Lathe/Overlay/MissionControl/MissionControlController.swift`

- [ ] `WindowFocusTracker` 보유. `show`가 `provider.stacks` 사용, 초기선택=최전면 앱 창, forward면 next(). 썸네일 캡처는 모든 스택의 모든 창 id.
- [ ] `cycleWindow/cycleWindowPrevious` → viewModel 스택 내부. `currentSelection()` = 선택스택 front. `recordWindowActivation()` = `touchSelectedWindow`.
- [ ] 빌드, 커밋.

## Task 4: 스택 렌더 (뷰)

**Files:** `Lathe/Overlay/MissionControl/MissionControlScreenView.swift`

- [ ] 자기 화면 스택 필터 → 레이아웃(스택 id/front localFrame) → 스택별 렌더: 뒤 카드 최대 2장 오프셋(가벼운 material) + 앞 카드(front 썸네일/폴백). 선택 스택 강조 링+나머지 dim. front 바뀌면 썸네일 교체 애니. 등장 애니·백드롭·크로스페이드 재사용.
- [ ] 빌드, 커밋.

## Task 5: 핫키 재매핑

**Files:** `Lathe/Overlay/OverlayPresenting.swift`, `Lathe/App/AppDelegate.swift`

- [ ] `OverlayPresenting`의 MC `cycleWindow(){next()}` 오버라이드 제거(MC가 직접 구현하므로).
- [ ] AppDelegate MC 분기: `hotKeyDidRequestCycleWindow` visible 시 `missionControl.cycleWindow()`(기존 `.next()`에서), previous도 대응.
- [ ] 빌드, 커밋.

## Task 6: 전체 검증

- [ ] `xcodebuild ... test` 전체 통과.
- [ ] 실기기 수동: ⌘+Tab=앱 이동, ⌘+`=스택 내부 창 순환(앞 카드 교체), ⌘ 뗌=front 창 전환, 창1개 앱=단일 타일, 캐러셀 회귀 없음.
