# Mission Control 레이아웃 — 설계 스펙

- **날짜**: 2026-07-08
- **상태**: 승인 대기 (구현 계획 착수 전)
- **범위**: ⌘+Tab 오버레이에 기존 캐러셀과 나란히 도는 "Mission Control식" 레이아웃 모드를 추가한다.

## 1. 목표

⌘+Tab을 눌렀을 때, 현재 Space의 모든 창을 **각자 소속된 모니터 위에** 실제 창 썸네일로 펼쳐 보여준다. ⌘+Tab을 반복해 창을 하나씩 넘기고, **선택된 창만 선명하게**, 나머지는 **살짝 흐리게** 표시한다. ⌘을 떼면 선택된 창으로 포커스가 전환된다.

macOS의 Mission Control과 유사한 화면 배치를, ⌘+Tab 전환기 UX 안에서 구현한다.

## 2. 확정된 결정 사항

브레인스토밍에서 사용자가 확정한 내용:

| 항목 | 결정 |
|---|---|
| 창 표현 | **실제 창 썸네일** (아이콘 타일 아님) |
| 모니터별 배치 | 각 창은 **자기가 속한 물리 모니터** 위에 표시 |
| 한 모니터 내 배치 | **겹침 정리(Mission Control식)** — 창끼리 안 겹치게 축소·정돈 |
| 창 범위 | **현재 Space의 보이는 창만** (다른 Space·최소화 창 제외) |
| 트리거 | **설정에서 Carousel / MissionControl 택1**, ⌘+Tab이 선택된 모드를 띄움 |
| 캡처 기술 | **ScreenCaptureKit** (`SCScreenshotManager`), deployment target 14.6 |
| 썸네일 갱신 | **정적** — 오버레이가 뜰 때 1회 캡처, 라이브 갱신 없음 |
| 권한 거부 시 | 해당 창을 **아이콘+제목 타일로 폴백**, 나머지 동작은 동일 |

## 3. 비목표 (YAGNI)

- 라이브(실시간 갱신) 썸네일
- 다른 Space / 최소화된 창의 표시
- 창을 드래그·닫기 등 조작하는 인터랙션 (선택→전환만)
- 마우스로 창을 클릭해 고르는 기능 — v1은 ⌘+Tab 키 순환만. (추후 확장 여지로만 남김)
- 기존 fan/strip/stack 캐러셀 제거 — 그대로 유지하고 병존

## 4. 아키텍처

기존 캐러셀은 **앱 단위 + 화면 중앙 패널 1개**다. Mission Control은 **창 단위 + 모니터마다 패널**이라, 데이터 모델·뷰·컨트롤러를 별도 엔진으로 둔다. 하위 유틸(창 열거, 활성화, 권한 확인, 패널 설정)은 최대한 재사용한다.

### 4.1 구성요소

#### `MissionControlWindowProvider` (신규)
- **역할**: 현재 Space의 on-screen·layer 0·비최소화 창을 열거해 flat list로 반환.
- **출력 항목** (`MCWindow` 값 타입):
  - `cgWindowID: Int`
  - `pid: pid_t`
  - `appEntry: AppEntry` — 활성화 재사용용
  - `windowEntry: WindowEntry` — 활성화 재사용용
  - `title: String`
  - `icon: NSImage?` — 폴백 타일용
  - `frame: CGRect` — 전역(글로벌) 좌표, `kCGWindowBounds`
  - `screen: NSScreen` — `frame`이 속한 화면 (겹침 면적 최대 기준으로 판정)
- **의존**: 기존 `WindowListProvider`(창/프레임 열거), `WindowVisibilityFilter`(최소 크기·layer·on-screen 필터), `AppListProvider`(아이콘/앱 엔트리).
- **테스트 가능성**: 순수 계산 부분(창→화면 매핑, 필터링)은 CGWindow dict 입력으로 단위 테스트.

#### `WindowThumbnailProvider` (신규)
- **역할**: `cgWindowID` → 썸네일 `NSImage`. ScreenCaptureKit `SCScreenshotManager.captureImage(contentFilter:configuration:)` 사용.
- **캡처**: 오버레이 표시 시점에 대상 창들을 1회 캡처(정적). 결과는 이번 표시 동안만 캐시.
- **권한**: 화면 녹화 권한 필요. `SCShareableContent` 조회 실패/권한 미부여 시 해당 창은 `nil` 반환 → 뷰가 아이콘 타일로 폴백.
- **의존**: `ScreenCaptureKit`.
- **주의**: SCK API는 async. 컨트롤러가 오버레이를 먼저(빈 프레임 또는 아이콘 타일 상태로) 띄우고, 캡처가 완료되는 대로 뷰모델을 갱신해 썸네일을 채운다. (⌘ 유지 시간이 짧아도 첫 프레임은 즉시 뜨도록.)

#### `MissionControlLayout` (신규, 순수 함수)
- **역할**: 화면별 창 목록 → 겹치지 않게 정돈된 프레임 목록. `CarouselLayout`처럼 UIKit/AppKit 비의존 순수 함수로 두고 단위 테스트.
- **입력**: 한 화면의 `[MCWindow]`(원래 프레임 포함) + 화면 가용 영역(`NSScreen.visibleFrame` 상당) + 여백/최소 타일 크기 상수.
- **출력**: 창별 `MCTileLayout { windowID, rect(화면 로컬 좌표), scale }`.
- **알고리즘 (v1)**: 창 개수 n에 대해 화면 영역을 격자(near-square: `cols = ceil(sqrt(n))`, `rows = ceil(n/cols)`)로 나누고, 각 셀에 창을 배치하되 **원래 창의 상대 위치 순서를 보존**하도록 원본 프레임 중심의 (y, x) 순으로 정렬해 셀에 채운다. 각 타일은 원본 종횡비를 유지한 채 셀 안에 aspect-fit. 셀 간 여백 상수.
  - `// ponytail: 격자 패킹. 실제 Mission Control의 물리시뮬 배치는 과함 — 창 수가 많아 겹침이 심하면 셀 세분화로 업그레이드.`
- **결정성**: 입력이 같으면 출력 동일 (렌더 애니메이션 안정 + 테스트 가능).

#### `MissionControlViewModel` (신규, `CarouselViewModel` 형태 미러)
- `@Published private(set) var windows: [MCWindow]`
- `@Published private(set) var selectedIndex: Int` — **전 모니터를 관통하는 단일 선택 커서**
- `@Published private(set) var thumbnails: [Int: NSImage]` — cgWindowID → 이미지 (async 캡처가 채움)
- `func next() / previous()` — selectedIndex를 전체 창 순서로 순환 (기존 `CarouselViewModel.clamp` 재사용)
- `var currentWindow: MCWindow?`
- **선택 순서**: 화면(왼→오, 위→아래) → 화면 내 정돈 순서로 flat 정렬. 초기 selectedIndex = 현재 활성 창(없으면 0).

#### `MissionControlController` (신규, `OverlayController`와 병존)
- **역할**: `NSScreen.screens`마다 borderless 논-액티베이팅 패널 1개 생성(=`OverlayPanel` 설정 재사용), 각 패널이 자기 화면의 타일을 SwiftUI로 렌더.
- **표시**: `show()` 시 각 화면 패널을 해당 화면 `frame`에 꽉 채워 배치 → 뷰가 `MissionControlLayout` 결과대로 타일 배치.
- **인터페이스** (기존 `OverlayController`와 동일 시그니처로 맞춰 디스패처가 공용 프로토콜로 다루게):
  - `show(initialActiveWindowID:)`, `next()`, `previous()`, `hide(animated:)`, `currentSelection() -> OverlaySelection?`, `isVisible`
- **렌더**: 각 패널 루트 뷰 `MissionControlScreenView`가 자기 화면 창 타일을 그림.
  - 선택된 창: `opacity 1.0` + 강조 링(accent 테두리).
  - 나머지 창: `opacity ≈ 0.55` + 약한 `blur(radius: 2)` (미세 흐림). 상수는 조정 가능.
  - 썸네일 없으면 아이콘+제목 타일.
- **의존**: `OverlayPanel`, `MissionControlViewModel`, `MissionControlLayout`.

#### 활성화 (재사용)
- ⌘ 뗄 때 `currentSelection()`이 선택 창의 `OverlaySelection(app:window:)` 반환 → 기존 `AppActivator.activate(app, window:)` 그대로 호출. 특정 창 포커스는 기존 `raiseWindow` / `SingleWindowFocuser` 경로가 처리.

### 4.2 설정 & 핫키 디스패치

#### `LayoutMode` (신규 enum) + `SettingsStore`
- 신규 `enum LayoutMode: String { case carousel, missionControl }`.
- `SettingsStore`에 `@Published var layoutMode: LayoutMode` 추가 (기존 `layoutStyle`과 동일 패턴으로 UserDefaults 영속).
- 기존 `layoutStyle`(fan/strip/stack)은 **carousel 모드일 때만** 의미. Mission Control 모드에선 무시.

#### `AppDelegate` 디스패처
- 현재 `overlay: OverlayController` 단일 필드 → **공용 프로토콜**(`OverlayPresenting`)로 추상화하고, `layoutMode`에 따라 `OverlayController` 또는 `MissionControlController` 인스턴스를 고른다.
  - `hotKeyDidRequestNext/Previous`, `hotKeyDidDisarm`(활성화), `hotKeyDidCancel`, `hideOverlay` 모두 프로토콜 메서드로 호출 → 분기 최소화.
- `// ponytail: 프로토콜 하나로 두 컨트롤러 공통 호출. mission control은 창 순환(cycleWindow) 개념이 없으므로 해당 델리게이트는 no-op.`
- Mission Control 모드에서 `hotKeyDidRequestCycleWindow`(⌘+`의 앱 내 창 순환 등)는 v1에선 no-op 또는 next와 동일 취급 — 계획 단계에서 확정.

#### 설정 UI (`SettingsView` / 캐러셀 상세)
- 최상단에 **레이아웃 모드 선택**(Carousel / Mission Control) `Picker` 추가. 기존 Prefer-native SwiftUI 원칙 유지 (`Picker`/`Toggle` 기본 컴포넌트).
- Mission Control 선택 시:
  - fan/strip/stack 및 fan radius/spacing 컨트롤 숨김(비관련).
  - **화면 녹화 권한 상태 배너** 표시. 미부여 시 "권한 열기" 버튼(시스템 설정 딥링크) + "권한 없으면 아이콘 타일로 표시됨" 안내.
- 신규 문자열은 L10n(en/ko) 추가. 릴리스 노트/CHANGELOG는 한국어로 작성.

### 4.3 권한 처리

- **확인**: `CGPreflightScreenCaptureAccess()` 또는 SCK 조회 결과로 화면 녹화 권한 상태 판정.
- **요청**: 최초 Mission Control 표시 시 권한 없으면 `CGRequestScreenCaptureAccess()`로 유도(비차단). 실패해도 오버레이는 아이콘 타일로 정상 동작.
- **기존 접근성 권한**과 별개 항목이므로 Permissions 설정 창에도 화면 녹화 항목을 노출 고려(계획 단계).

## 5. 데이터 흐름

```
⌘+Tab (layoutMode == missionControl)
  → MissionControlController.show(initialActiveWindowID:)
      → MissionControlWindowProvider.enumerate()      # 현재 Space·on-screen 창 + 프레임 + 화면
      → 화면별 그룹핑 → MissionControlLayout.tiles()   # 겹침 정리 배치 (순수함수)
      → 각 NSScreen 패널 생성·표시, 아이콘 타일로 즉시 첫 프레임
      → WindowThumbnailProvider (async) 캡처 완료 → viewModel.thumbnails 갱신 → 썸네일로 교체
⌘+Tab 반복 → viewModel.next()/previous() → 선택 커서 이동 (선명/흐림 갱신)
⌘ release → currentSelection() → AppActivator.activate(app, window:) → hide()
```

## 6. 테스트 전략

기존 패턴(`CarouselLayoutTests`, `WindowListProviderTests` 등 순수 로직 XCTest)을 따른다.

- `MissionControlLayoutTests`: 창 n개 → 겹치지 않는 타일, 종횡비 유지, 결정성, 상대 위치 순서 보존, n=0/1 경계.
- `MissionControlWindowProviderTests`: CGWindow dict 입력 → 현재 Space·on-screen 필터, 창→화면 매핑(겹침 면적 최대), 최소화/소형 창 제외.
- `MissionControlViewModelTests`: next/previous 순환, 초기 선택=활성 창, 빈 목록 처리, 썸네일 갱신 후 선택 유지.
- 권한/SCK 캡처·다중 패널 배치는 실기기 수동 확인 (자동화 제외).

## 7. 파일 변경 목록 (예상)

**신규**
- `Lathe/Overlay/MissionControl/MissionControlWindowProvider.swift`
- `Lathe/Overlay/MissionControl/WindowThumbnailProvider.swift`
- `Lathe/Overlay/MissionControl/MissionControlLayout.swift`
- `Lathe/Overlay/MissionControl/MissionControlViewModel.swift`
- `Lathe/Overlay/MissionControl/MissionControlController.swift`
- `Lathe/Overlay/MissionControl/MissionControlScreenView.swift`
- `Lathe/Settings/LayoutMode.swift`
- `LatheTests/MissionControlLayoutTests.swift`
- `LatheTests/MissionControlWindowProviderTests.swift`
- `LatheTests/MissionControlViewModelTests.swift`

**수정**
- `Lathe/App/AppDelegate.swift` — `OverlayPresenting` 프로토콜 도입 + layoutMode 분기
- `Lathe/Overlay/OverlayController.swift` — `OverlayPresenting` 준수(시그니처 정렬)
- `Lathe/Settings/SettingsStore.swift` — `layoutMode` 추가
- `Lathe/Settings/SettingsView.swift`(+캐러셀 상세) — 모드 Picker, 권한 배너, 조건부 숨김
- `Lathe/Resources/*.lproj` / L10n — 신규 문자열(en/ko)
- `Lathe/Resources/Info.plist` — 필요 시 화면 녹화 사용 설명(`NSScreenCaptureUsageDescription` 해당 시)
- 프로젝트 파일 — `ScreenCaptureKit` 링크

## 8. 미해결/계획 단계 확정 사항

- ⌘+` (앱 내 창 순환) 진입점이 Mission Control 모드에서 어떻게 동작할지 (no-op vs next).
- 흐림 강도/강조 스타일 상수 최종값 — 실기기에서 튜닝.
- `NSScreenCaptureUsageDescription` 필요 여부 (SCK 권한 프롬프트 문구) — 구현 중 확인.
- 창이 매우 많을 때 격자 패킹의 셀 세분화 업그레이드 트리거 — v1은 단순 격자로 출발.
