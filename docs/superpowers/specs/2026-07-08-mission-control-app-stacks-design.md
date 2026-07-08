# Mission Control 앱별 스택 + ⌘+` 창 순환 — 설계 스펙

- **날짜**: 2026-07-08
- **상태**: 승인됨(설계) → 구현 진행
- **전제**: [Mission Control 레이아웃](2026-07-08-mission-control-layout-design.md) 위에 얹는 증분 기능. 현재 Space 스코프 유지.

## 1. 목표

Mission Control 오버레이에서 **같은 앱의 창들을 하나의 스택으로 묶어** 보여준다. ⌘+Tab은 앱(스택) 사이를 이동하고, **⌘+`(⇧ 포함 역방향)로 선택된 앱의 스택 안에서 창을 순환**한다 — 캐러셀의 창 순환 UX와 동일. ⌘을 떼면 선택 스택의 맨 앞 창으로 전환한다.

## 2. 확정된 결정

| 항목 | 결정 |
|---|---|
| 그룹 단위 | **앱별** (정확히는 `(pid, 소속 화면)` 단위 — 한 앱이 두 모니터에 걸치면 화면마다 스택) |
| 스택 모양 | **뒤로 살짝 겹침(offset)** — 맨 앞 썸네일 + 뒤로 최대 2장 살짝 오프셋 |
| 뒤 카드 | 썸네일 안 채우고 가벼운 카드(성능·단순). 창 여러 개임을 시각적으로만 암시 |
| ⌘+Tab | 스택(앱) 사이 이동 |
| ⌘+` / ⌘+⇧+` | 선택 스택 **내부** 창 순환 (맨 앞 카드 교체), 랩어라운드 |
| 창 순서 | **MRU** (`WindowFocusTracker` 재사용) |
| 창 1개 앱 | 단일 타일(스택 안 쌓음) |
| ⌘ 뗌 | 선택 스택의 **맨 앞 창** 활성화 |

## 3. 비목표 (YAGNI)

- 다른 Space/최소화 창 (기존 스코프 유지)
- 뒤 카드에 실제 썸네일 렌더
- 스택 펼치기(hover로 창 전부 펼침) 등 추가 인터랙션
- 마우스 클릭 선택

## 4. 아키텍처 (핵심은 뷰모델 재구성, 나머지 대부분 재사용)

### 4.1 모델 — `MCAppStack` (신규)
```
struct MCAppStack: Identifiable {
    let id: Int              // pid 기반 안정 식별자 (한 화면 내 유니크)
    let appEntry: AppEntry
    let screenIndex: Int
    let windows: [MCWindow]  // MRU 순서 (index 0 = 가장 최근)
    var frontIndex: Int      // 현재 맨 앞(선택) 창
    var frontWindow: MCWindow { windows[frontIndex] }
}
```
`MCWindow`는 기존 그대로(id/pid/appEntry/windowEntry/frame/localFrame/screenIndex).

### 4.2 프로바이더 — `MissionControlWindowProvider`
- `windows(appEntries:) -> [MCWindow]` → **`stacks(appEntries:) -> [MCAppStack]`** 로 변경(또는 추가).
- 앱별 MRU 창 순서는 **`WindowFocusTracker.windows(forProcessIdentifier: pid)`** 로 얻고, 각 `WindowEntry`를 프레임/화면 정보로 보강해 `MCWindow` 생성.
- `(pid, screenIndex)`로 그룹핑 → 각 그룹이 하나의 `MCAppStack` (windows MRU 순, frontIndex=0).
- 프레임/화면 없는 창(오프스크린·최소화)은 제외. 유효 창 0개인 앱은 스택 없음.
- 반환은 대표 창(front) 위치순 정렬은 뷰/레이아웃에서 처리.

### 4.3 뷰모델 — `MissionControlViewModel` (재구성)
```
@Published private(set) var stacks: [MCAppStack]
@Published private(set) var selectedStackIndex: Int
@Published private(set) var thumbnails: [Int: NSImage]   // 창 id → 이미지 (변경 없음)

func set(stacks:, selectedWindowID:)   // 초기 선택: selectedWindowID를 front로 가진 스택
func setThumbnail(_:forWindowID:)       // 변경 없음
func next() / previous()                 // selectedStackIndex 랩어라운드 (앱 이동)
func cycleWindow() / cycleWindowPrevious() // 선택 스택의 frontIndex 랩어라운드 (창 이동)
var currentStack: MCAppStack?
var currentWindow: MCWindow?             // = currentStack?.frontWindow
```

### 4.4 레이아웃 — `MissionControlLayout`
- 변경 최소. 스택 하나당 1개 배치: `tiles(windows: stacks.map { (id: $0.id, frame: $0.frontWindow.localFrame) }, in: area)`.
- 격자·변주·정렬 그대로. id는 이제 스택 id(pid 기반).

### 4.5 뷰 — `MissionControlScreenView`
- 자기 화면 스택만 필터 → 레이아웃 → 스택별 렌더.
- **스택 렌더**: ZStack에 뒤 카드(최대 2장, 오프셋 down-right, 가벼운 material 카드) + 맨 앞 카드(front 창 썸네일 or 폴백 아이콘).
- 선택 스택: 강조 링 + 나머지 dim(기존 로직 재사용, 스택 단위로).
- ⌘+`로 frontIndex 바뀌면 맨 앞 썸네일 교체(부드럽게).
- 등장 애니메이션(스프링 스케일-인), 백드롭, 아이콘→썸네일 크로스페이드 — 기존 재사용.

### 4.6 컨트롤러 — `MissionControlController`
- `WindowFocusTracker` 보유(MRU). (캐러셀과 별도 인스턴스, 워크스페이스 옵저버로 자동 갱신)
- `show`: `provider.stacks(appEntries:)` → 초기 선택 = 최전면 앱 스택, `forward`면 `next()` 한 칸 → 패널 표시 → 모든 창 썸네일 비동기 캡처(기존).
- `next/previous` → viewModel 스택 이동. `cycleWindow/cycleWindowPrevious` → viewModel 스택 내부.
- `currentSelection()` → `OverlaySelection(app: currentStack.appEntry, window: currentStack.frontWindow.windowEntry)`.
- `recordWindowActivation()` → 선택 창을 `WindowFocusTracker.touchSelectedWindow`로 MRU 갱신.

### 4.7 핫키 배선 — `AppDelegate` / `OverlayPresenting`
- `OverlayPresenting`의 MC용 `cycleWindow(){next()}` **오버라이드 제거** → MC가 진짜 `cycleWindow()` 구현.
- `AppDelegate` MC 분기: `hotKeyDidRequestCycleWindow` (visible 시) → `missionControl.next()` **→ `missionControl.cycleWindow()`** 로 변경. `hotKeyDidRequestCycleWindowPrevious` → `cycleWindowPrevious()`. ⌘+Tab(next/previous)은 그대로 스택 이동.

## 5. 데이터 흐름
```
⌘+Tab (MC 모드)
 → controller.show → provider.stacks (앱별 MRU 그룹, 화면별)
 → viewModel.set(stacks, 최전면 앱 front) → forward면 next()
 → 화면별 패널에 스택 격자 배치, 썸네일 async 채움
⌘+Tab 반복 → next()/previous() (앱 스택 이동)
⌘+`  반복  → cycleWindow()/cycleWindowPrevious() (선택 스택 내부 창 이동, 맨 앞 카드 교체)
⌘ release → currentSelection()=선택스택 front → AppActivator.activate(app, window:) + touchSelectedWindow(MRU)
```

## 6. 테스트 (순수 로직)
- `MissionControlViewModelTests` 재작성: 스택 간 next/previous 랩, 스택 내부 cycleWindow 랩, 초기 선택=최전면 앱, currentWindow=front, 빈 목록.
- `MissionControlWindowProviderTests` 보강: `(pid,screen)` 그룹핑, MRU 순서 반영, 창1개 앱=단일 스택.
- 레이아웃 테스트는 사실상 그대로(스택 id로 키만 바뀜).
- 스택 렌더·애니메이션·핫키는 실기기 수동.

## 7. 파일 변경
- 수정: `MissionControlWindowProvider.swift`(+`MCAppStack`), `MissionControlViewModel.swift`, `MissionControlScreenView.swift`, `MissionControlController.swift`, `OverlayPresenting.swift`, `AppDelegate.swift`
- 테스트: `MissionControlViewModelTests.swift`, `MissionControlWindowProviderTests.swift`

## 8. 리스크
- 한 앱이 두 화면에 걸친 경우 `(pid,screen)` 스택 분리로 처리 — 드묾, 수용.
- `WindowFocusTracker`를 MC용으로 하나 더 두면 카레셀과 MRU 상태가 분리됨. v1 허용(각자 옵저버로 갱신). 필요 시 공유로 승격.
