# Lathe — Design Spec

- Date: 2026-04-28
- Status: Approved (brainstorm)
- Target platform: macOS 14.6 (Sonoma) or later

## Context

`yuzeguitarist/Orbit`은 macOS용 radial app switcher인데, 미서명·source-available·Accessibility + Input Monitoring 권한 조합 때문에 신뢰하기 어렵다. 같은 컨셉(커서 근처 카드형 앱 스위처)을 본인이 직접 만들어 안전하게 사용하는 것이 목표.

Lathe는 ⌘+Tab을 가로채 시스템 스위처 대신 **캐러셀형 오버레이**를 띄운다. 커서 추적 대신 화면 중앙(또는 화면별 정해진 위치)에 가로 띠로 카드를 배치하고, **가운데 카드 = 현재 포커스**라는 고정된 시각 모델을 쓴다. ⌘ 누른 채 Tab으로 카드를 회전시키고, ⌘ 떼면 가운데 앱이 활성화된다.

## Goals (v1)

- 시스템 ⌘+Tab을 가로채 Lathe 오버레이로 대체
- 실행 중인 일반(`.regular`) 앱을 최근 활성화 순으로 캐러셀 표시
- ⌘ 유지 + Tab/⇧Tab으로 회전, ⌘ release로 가운데 앱 활성화, ESC로 취소
- 풀스크린/멀티 스페이스에서도 오버레이 표시
- 메뉴바 아이콘에서 종료/권한 안내 접근
- 본인 Apple ID 로컬 서명으로 빌드 가능 (유료 dev 계정 불필요)

## Non-goals (v1, 의도적 제외)

- 파일 드래그 → AirDrop / 휴지통 (원본 Orbit의 핵심 차별점이지만 v1에서 제외)
- 앱 카드 더블클릭 종료 / 가운데 블랙홀로 드래그 종료
- 같은 앱 윈도우 사이클 (⌘+`)
- 환경설정 UI — 카드 크기, 회전 속도, 트리거 키 등은 코드 상수로 고정
- 시작 시 자동 실행(LaunchAgent)
- 다국어
- 자동 업데이트

이 항목들은 **v1 끝난 뒤** 별도 spec으로 다룬다.

## Functional Requirements

### Trigger

- ⌘ press → "armed" 상태 진입 (오버레이는 아직 표시 안 함)
- armed 상태에서 Tab keyDown → 오버레이 표시, `selectedIndex = 1` (가장 최근 비활성 앱). 인덱스 정의: `apps[0]` = 현재 frontmost, `apps[1]` = 그 직전, ... 시스템 ⌘+Tab과 동일.
- armed 상태에서 ⇧Tab keyDown(첫 입력)으로 오버레이 진입 시 `selectedIndex = apps.count - 1`
- ⌘ 떼는 즉시 armed 해제. 오버레이가 떠 있었으면 가운데 앱 활성화.
- 오버레이가 떠 있는 동안:
  - Tab → `selectedIndex += 1` (wrap-around)
  - ⇧Tab → `selectedIndex -= 1` (wrap-around)
  - ESC → 오버레이 dismiss, 활성화 안 함
- Tab/⇧Tab/ESC keyDown 이벤트는 **소비**(시스템 ⌘+Tab 차단)
- ⌘ keyUp 이벤트 자체는 소비하지 않음 — 다른 앱이 ⌘ 조합을 정상적으로 받을 수 있어야 함

### Carousel

- 가운데 카드: scale 1.0, opacity 1.0, highlight ring + 앱 이름 라벨
- 양옆 카드: 인덱스 거리(`d = |i - selectedIndex|`)에 따라
  - `offsetX = (i - selectedIndex) * spacing`
  - `scale = max(1 - d * 0.15, 0.5)`
  - `opacity = max(1 - d * 0.25, 0.2)`
- `selectedIndex` 변경 시 `withAnimation(.spring(response: 0.25, dampingFraction: 0.7))` 자동 보간으로 카드들이 슬라이드
- wrap-around: 좌우 끝에서 반대편으로 이어지는 시각적 끊김은 v1에서 허용 (인덱스만 wrap, 시각적 무한 스크롤은 v2)

### App list

- `NSWorkspace.shared.runningApplications` 중 `activationPolicy == .regular` 만 포함
- 정렬: 최근 활성화 순. Lathe 자체는 `LSUIElement=YES` 로 `activationPolicy == .accessory` 이므로 `.regular` 필터에 의해 자동 제외됨
- 표시 항목: `runningApp.icon`, `runningApp.localizedName`
- 오버레이가 떠 있는 동안 앱 종료/실행 이벤트 발생 시 리스트 즉시 갱신, `selectedIndex` 클램프

### Overlay window

- borderless `NSPanel`
- `level = .floating`
- `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`
- 화면 중앙 가로 띠 (현재 활성 스크린 기준)
- `ignoresMouseEvents = true` (v1에선 마우스 인터랙션 없음 — 키보드 전용. hover/클릭 동작은 v2)
- ⌘ 떼는 순간 fade-out (0.15s)

### Menu bar

- `NSStatusItem` with template icon
- 메뉴 항목:
  - "Lathe is running"
  - "Permissions…" → Accessibility 권한 상태 표시 / System Settings 딥링크
  - "Quit Lathe"

### Permissions

- 첫 실행 시 Accessibility 권한 확인 (`AXIsProcessTrustedWithOptions`)
- 미부여 시 안내 윈도우 + "Open System Settings" 버튼 (`x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`)
- 권한 부여 후 재실행 안내 (event tap은 권한 없으면 attach 자체가 실패)

## Architecture

```
┌─────────────────────────────────────────────────┐
│  AppDelegate (LSUIElement = YES)                │
│   ├─ MenuBarController                          │
│   │    └─ NSStatusItem + NSMenu                 │
│   ├─ HotKeyMonitor                              │
│   │    └─ CGEventTap (cgSessionEventTap,        │
│   │                   headInsertEventTap)       │
│   ├─ AppListProvider                            │
│   │    └─ NSWorkspace KVO + 캐시               │
│   ├─ OverlayController                          │
│   │    └─ OverlayPanel (NSPanel)                │
│   │         └─ CarouselView (SwiftUI)           │
│   └─ AppActivator                               │
└─────────────────────────────────────────────────┘
```

### Module: `HotKeyMonitor`

책임: 글로벌 키 이벤트를 가로채 상위 컨트롤러에 의도(intent)로 전달.

인터페이스:
```swift
protocol HotKeyMonitorDelegate: AnyObject {
    func hotKeyDidArm()             // ⌘ down
    func hotKeyDidDisarm()          // ⌘ up
    func hotKeyDidRequestNext()     // ⌘+Tab
    func hotKeyDidRequestPrevious() // ⌘+⇧Tab
    func hotKeyDidCancel()          // ⌘+ESC
}

final class HotKeyMonitor {
    weak var delegate: HotKeyMonitorDelegate?
    func start() throws  // throws if Accessibility not granted
    func stop()
}
```

구현:
- `CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, ...)` 두 번:
  1. `flagsChanged` 마스크 — ⌘ down/up 트래킹
  2. `keyDown` 마스크 — ⌘ + (Tab|⇧Tab|ESC) 가로채고 `nil` 리턴해 시스템 차단
- `RunLoop` 소스로 등록
- 권한 없으면 `tapCreate` 가 nil 리턴 → throw

### Module: `AppListProvider`

책임: 표시 가능한 앱 목록을 최근 활성화 순으로 제공.

인터페이스:
```swift
protocol AppListProviding {
    var apps: [AppEntry] { get }    // ordered, 자기 자신 제외
    var didChange: () -> Void { get set }
}

struct AppEntry: Identifiable, Equatable {
    let id: pid_t
    let bundleIdentifier: String?
    let name: String
    let icon: NSImage
}
```

구현:
- `NSWorkspace.shared.runningApplications` 초기 스냅샷
- KVO observe `NSWorkspace.shared` `runningApplications` (앱 launch/terminate)
- `NSWorkspace.didActivateApplicationNotification` 으로 활성화 순서 갱신
- 정렬은 내부 `[pid_t]` MRU 큐 유지

### Module: `OverlayController` + `CarouselView`

책임: 오버레이 윈도우 표시/숨김, SwiftUI 캐러셀 호스팅.

`OverlayController`:
```swift
final class OverlayController {
    func show(apps: [AppEntry], initialIndex: Int)
    func updateApps(_ apps: [AppEntry])
    func setSelectedIndex(_ i: Int)  // animated
    func currentSelection() -> AppEntry?
    func hide(animated: Bool)
}
```

- `NSPanel` lazy 생성, 재사용
- `NSHostingView<CarouselView>` 로 SwiftUI 마운트
- `CarouselViewModel: ObservableObject` 가 상태(`apps`, `selectedIndex`) 보관, controller 가 외부에서 변경

`CarouselView` (SwiftUI):
- `HStack` 대신 `ZStack` + 각 카드에 `offset` 적용 (z-order 제어)
- 가운데 카드부터 z-index 높게
- 카드: 80×80 아이콘 + 12pt 이름 라벨, 라운드된 사각형 배경

### Module: `AppActivator`

```swift
enum AppActivator {
    static func activate(_ entry: AppEntry)
}
```

`NSRunningApplication(processIdentifier: entry.id)?.activate(options: .activateIgnoringOtherApps)`.

### Module: `MenuBarController`

`NSStatusItem` + `NSMenu`. 단순.

### Coordinator: `AppDelegate`

`HotKeyMonitorDelegate` 채택, intent → `OverlayController` 호출로 변환:

| Intent | Action |
|---|---|
| `hotKeyDidArm` | nothing (오버레이 아직 안 뜸) |
| `hotKeyDidRequestNext` | 오버레이 안 떠 있으면 show(initialIndex:1), 떠 있으면 selectedIndex+1 |
| `hotKeyDidRequestPrevious` | show(initialIndex: count-1) or selectedIndex-1 |
| `hotKeyDidCancel` | hide(animated: true), 활성화 안 함 |
| `hotKeyDidDisarm` | 떠 있으면 currentSelection 활성화 후 hide |

## Data Flow (Happy Path)

```
User: ⌘ down
  → CGEventTap(flagsChanged) → HotKeyMonitor → delegate.hotKeyDidArm
  → AppDelegate: ignore (no overlay yet)

User: Tab down (⌘ still held)
  → CGEventTap(keyDown) → HotKeyMonitor → delegate.hotKeyDidRequestNext
                                       → return nil (consume)
  → AppDelegate: OverlayController.show(apps: provider.apps, initialIndex: 1)
  → CarouselView animates in

User: Tab down (again)
  → delegate.hotKeyDidRequestNext
  → AppDelegate: OverlayController.setSelectedIndex(2)
  → CarouselViewModel.selectedIndex = 2 → spring animation

User: ⌘ up
  → CGEventTap(flagsChanged) → HotKeyMonitor → delegate.hotKeyDidDisarm
  → AppDelegate: AppActivator.activate(controller.currentSelection)
  → OverlayController.hide(animated: true)
```

## Edge Cases

| Case | Handling |
|---|---|
| Accessibility 권한 없음 | `HotKeyMonitor.start()` throws → 안내 윈도우 표시, 메뉴바 아이콘 빨간 점 |
| 실행 중 일반 앱이 0개 (Lathe 자기 자신만) | `requestNext` 무시 (오버레이 안 띄움) |
| 실행 중 일반 앱이 1개 | 오버레이 띄우되 캐러셀에 한 장만 |
| 오버레이 떠 있는 동안 앱 종료 → selectedIndex 가 범위 밖 | clamp to `count - 1` |
| 오버레이 떠 있는 동안 새 앱 launch | 캐러셀 끝에 추가, selectedIndex 유지 |
| 풀스크린 앱 위 | `.fullScreenAuxiliary` + `.canJoinAllSpaces` 로 표시 |
| 멀티 모니터 | 현재 마우스 커서가 있는 스크린의 중앙에 띄움 |
| ⌘+Tab 길게 눌러서 키 리피트 | 키 리피트 keyDown 이벤트도 next 로 처리 (시스템 ⌘+Tab과 동일) |
| ⌘ 안 누른 채 Tab | 가로채지 않음 (mask 에서 ⌘ flag 확인) |
| 다른 modifier 조합 (⌥+Tab 등) | 가로채지 않음 |
| event tap 이 시스템에 의해 disable 됨 (`tapDisabledByTimeout`) | 재활성화 (`CGEvent.tapEnable(tap:enable:true)`) |

## Testing Strategy

### Unit
- `CarouselViewModel`: `next()`, `previous()` wrap-around, clamp on app removal
- `AppListProvider`: MRU 정렬, 자기 자신 제외, KVO 시뮬레이션 (mock `NSWorkspace`)

### Integration / Manual QA
- 실제 ⌘+Tab 동작 검증은 수동 — 시스템 스위처가 안 뜨고 Lathe 가 뜨는지
- 풀스크린, 멀티 모니터, Spaces 전환 시나리오
- 권한 토글 후 재시작 흐름

### SwiftUI Preview
- `CarouselView` 다양한 카운트 (0, 1, 3, 8, 20) + `selectedIndex` 스냅샷

테스트 타깃은 `LatheTests`(SPM)로 분리. SwiftUI 뷰는 단위 테스트 안 함.

## Project Structure

```
Lathe/
├── Lathe.xcodeproj/
├── Lathe/
│   ├── App/
│   │   ├── LatheApp.swift          (@main, AppDelegate)
│   │   └── Info.plist              (LSUIElement=YES)
│   ├── HotKey/
│   │   └── HotKeyMonitor.swift
│   ├── AppList/
│   │   ├── AppEntry.swift
│   │   └── AppListProvider.swift
│   ├── Overlay/
│   │   ├── OverlayController.swift
│   │   ├── OverlayPanel.swift
│   │   ├── CarouselView.swift
│   │   ├── CarouselViewModel.swift
│   │   └── CardView.swift
│   ├── MenuBar/
│   │   └── MenuBarController.swift
│   ├── Activation/
│   │   └── AppActivator.swift
│   ├── Permissions/
│   │   ├── AccessibilityChecker.swift
│   │   └── PermissionPromptView.swift
│   └── Resources/
│       └── Assets.xcassets
├── LatheTests/
│   ├── CarouselViewModelTests.swift
│   └── AppListProviderTests.swift
└── docs/superpowers/specs/
    └── 2026-04-28-lathe-design.md
```

## Build & Distribution

- Xcode 프로젝트, deployment target macOS 14.6
- 코드 서명: 본인 Apple ID로 자동 서명 (Personal Team) — 유료 계정 불필요, 본인 Mac에서 실행 가능
- `Info.plist`:
  - `LSUIElement` = `YES` (Dock 아이콘 없음)
  - `NSAppleEventsUsageDescription` 불필요 (NSWorkspace는 권한 안 받음)
  - Accessibility 권한은 사용자가 System Settings 에서 직접 부여 (Info.plist 항목 없음)
- 배포: 본인 사용 목적이므로 DMG 패키징 / 공증 / 업데이트 불필요. Xcode 에서 직접 Run.

## Open Questions (Resolved)

- ⌘+Tab 가로채기 가능? → 가능 (`cgSessionEventTap` + `headInsertEventTap`, Accessibility 권한)
- 캐러셀 시각 모델? → 가운데 = 포커스, 양옆은 scale/opacity 감쇠
- 회전 입력? → ⌘ 유지 + Tab/⇧Tab, ⌘ 떼면 확정 (시스템 ⌘+Tab 멘탈 모델)
- 앱 이름? → Lathe

## Future (out of scope for v1)

- 파일 드래그 → AirDrop / 휴지통
- 같은 앱 윈도우 사이클
- 환경설정 UI (카드 크기, 회전 속도, 트리거 변경)
- 무한 스크롤 시각화
- 시작 시 자동 실행
- 트랙패드 스와이프로 회전
