<h1 align="center">Lathe</h1>

<p align="center">
  <strong>직접 빌드하는 안전한 macOS ⌘+Tab 대체 앱.</strong>
</p>

<p align="center">
  <a href="#왜">왜</a> •
  <a href="#설치">설치</a> •
  <a href="#소스에서-빌드">빌드</a> •
  <a href="#사용법">사용법</a> •
  <a href="#환경설정">환경설정</a> •
  <a href="#권한">권한</a> •
  <a href="#기술-스택">기술</a> •
  <a href="#라이선스">라이선스</a>
</p>

<p align="right">
  <a href="README.md">English</a> · 한국어
</p>

---

Lathe는 시스템 ⌘+Tab을 가로채 실행 중인 앱들을 부채꼴 캐러셀로 보여준다.
가운데 카드가 항상 포커스 — ⌘ 누른 채 Tab 누르면 카드들이 회전하고,
⌘ 떼면 가운데 카드의 앱이 활성화된다.

<p align="center">
  <img src="docs/images/carousel.png" alt="Lathe 캐러셀" width="640">
</p>

## 왜

⌘+Tab을 아이콘 한 줄짜리보다 더 보기 좋게 만들고 싶었고, 키 입력을 가로채는
앱의 소스 코드를 직접 읽을 수 있어야 했다. Lathe는 그 결과물 — 오후 한나절이면
다 읽을 수 있을 만큼 작고, 본인 인증서로 직접 서명하고, Accessibility 외엔
어떤 권한도 요구하지 않는다.

## 설치

미리 빌드된 바이너리는 없다 — 의도적이다. 본인이 직접 컴파일하고 서명하는 게
이 프로젝트의 핵심이니까.

1. 빌드 의존성 설치:

   ```bash
   brew install xcodegen
   ```

2. 클론 후 빌드:

   ```bash
   git clone https://github.com/hongmono/Lathe.git
   cd Lathe
   ./dev run
   ```

3. 첫 실행 시 권한 안내 윈도우가 뜬다. 시스템 설정에서 Accessibility 권한을
   부여한 뒤 `./dev run` 으로 다시 실행 — event tap은 권한 부여 후 새 프로세스에서만
   동작한다.

DMG도, 공증(notarization)도, `xattr` 우회도 없다. 빌드 산출물은
DerivedData 안에 있고 본인 로컬 인증서로 서명된다.

## 소스에서 빌드

### 툴체인

| 도구       | 버전                                    |
|------------|-----------------------------------------|
| macOS      | 14.6 (Sonoma) 이상                      |
| Xcode      | 15+ (Xcode 26에서 검증)                 |
| Swift      | 6.0                                     |
| `xcodegen` | latest (`brew install xcodegen`)        |

### 코드 서명

Lathe는 login keychain에 저장된 **자체 서명(self-signed) Code Signing 인증서**
`Lathe Local Dev` 로 서명된다. 중요한 이유 — macOS의 TCC(Accessibility 권한을
관장하는 시스템)는 앱을 **서명 인증서 ID 기준**으로 추적한다. 안정적인 인증서를
쓰면 코드가 바뀌어도 cdhash 변경에 영향받지 않고 **부여된 권한이 매번 재빌드해도
유지된다**.

인증서 만들기:

1. **Keychain Access** 열기 → 메뉴 **Certificate Assistant → Create a
   Certificate…**
2. 입력:
   - Name: `Lathe Local Dev`
   - Identity Type: `Self Signed Root`
   - Certificate Type: `Code Signing`
3. **"Let me override defaults"** 체크 후 wizard 진행, **Validity Period**
   를 `3650` (10년)으로 지정해서 만료 신경 안 쓰게.
4. 마침.
5. codesigning 용도로 키 권한 부여:

   ```bash
   security set-key-partition-list \
     -S apple-tool:,apple:,codesign: -s \
     -D "Lathe Local Dev" -t private \
     ~/Library/Keychains/login.keychain-db
   ```

   프롬프트에 macOS 로그인 비밀번호 입력.

다른 인증서(본인 Developer ID, 팀 인증서 등)를 쓰고 싶으면 `Project.yml`
과 `dev` 수정:

```yaml
# Project.yml
settings:
  base:
    CODE_SIGN_IDENTITY: "Your Identity Name"
    DEVELOPMENT_TEAM: "YOUR_TEAM_ID"   # self-signed면 ""
```

```bash
# dev
SIGN_ARGS=(
  CODE_SIGN_STYLE=Manual
  CODE_SIGN_IDENTITY="Your Identity Name"
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"
)
```

### `./dev` 헬퍼

bash 한 줄로 다 해결:

```bash
./dev run     # 빌드 + (재)실행 — 실행 중인 Lathe는 종료 후 재시작
./dev build   # 빌드만
./dev test    # 단위 테스트 실행
./dev stop    # 실행 중인 앱 종료
./dev clean   # Lathe.xcodeproj와 빌드 산출물 정리
```

`./dev run` 은 `Project.yml` 또는 `*.swift` 소스가 마지막 빌드 이후 변경됐으면
`Lathe.xcodeproj` 를 자동으로 재생성한다.

### Xcode로 작업

```bash
xcodegen generate
open Lathe.xcodeproj
```

`Lathe` target → Signing & Capabilities → Team: 본인 인증서 선택. ⌘R
로 실행.

## 사용법

| 입력                  | 동작                                            |
|-----------------------|-------------------------------------------------|
| ⌘+Tab                 | 캐러셀 표시, 직전 앱이 가운데로                  |
| ⌘ 유지 + Tab          | 다음 앱으로 회전                                 |
| ⌘ 유지 + ⇧Tab         | 이전 앱으로 회전                                 |
| ⌘ 떼기                | 가운데(포커스) 앱 활성화                          |
| ⌘ 유지 + Esc          | 활성화 없이 닫기                                  |

시스템 ⌘+Tab과 동일한 동작 모델 — 머슬 메모리 그대로 쓸 수 있다. 차이는
포커스가 캐러셀 가운데에 고정되고 카드들이 그 주위로 회전한다는 것뿐.

## 환경설정

메뉴바 점선 원 아이콘 → **Preferences…** (또는 메뉴 열린 상태에서 ⌘,)

<p align="center">
  <img src="docs/images/preferences.png" alt="Lathe 환경설정 윈도우" width="480">
</p>

| 섹션       | 항목                  | 동작                                          |
|------------|-----------------------|-----------------------------------------------|
| Appearance | Theme                 | 시스템 매칭 / Light / Dark                    |
| Carousel   | Card size             | 카드 너비. 높이·pivot은 비율 자동 적용        |
| Carousel   | Spacing               | 카드 사이 펼침 각도(도)                       |
| General    | Launch Lathe at login | `SMAppService` 로 Login Item 등록             |

캐러셀 슬라이더는 **실시간 반영** — 환경설정 윈도우 켜놓고 ⌘+Tab 으로 즉시 확인.

## 권한

Lathe는 ⌘+Tab을 글로벌하게 가로채는 `CGEventTap` 설치를 위해 **Accessibility**
권한이 필요하다. 그 외 어떤 권한도 요청하지 않는다 — Input Monitoring 없음,
Full Disk Access 없음, Screen Recording 없음. event tap은 ⌘ + Tab/⇧Tab/Esc
의 keyDown 이벤트로만 한정되고 그 외 모든 입력은 변형 없이 통과한다.

권한 회수: 시스템 설정 → 개인 정보 보호 및 보안 → 손쉬운 사용 → Lathe 토글 끄기
(또는 항목 삭제).

서명 인증서가 안정적이라 재빌드해도 TCC 등록은 유지된다. 인증서를 바꾸거나
순환시키면 한 번 더 권한 다이얼로그가 뜨고, 옛 기록은 다음 명령으로 정리:

```bash
tccutil reset Accessibility com.hongmono.Lathe
```

## 기술 스택

- **SwiftUI + AppKit 하이브리드.** 캐러셀은 SwiftUI 뷰를 `NSPanel` 오버레이에
  호스팅. 메뉴바 항목, hot key tap, workspace 옵저버는 AppKit.
- **부채꼴 레이아웃.** 각 카드를 frame 밖에 놓인 pivot 기준으로
  `rotationEffect(_:anchor:)` 회전. 가운데 카드는 angle 0, 양옆은
  `±n × angularStep` 으로 펼침. 수동 삼각함수 계산 없음, `GeometryReader`
  복잡도 없음.
- **Event tap.** `CGEventTap` 두 개를 `cgSessionEventTap` /
  `headInsertEventTap` 위에 설치 — 하나는 `flagsChanged` (⌘ press/release
  추적), 하나는 `keyDown` (Tab / ⇧Tab / Esc 가로채고 소비).
- **앱 목록.** `NSWorkspace.runningApplications` 를 `.regular` activation
  policy로 필터, `didActivateApplication` 알림으로 갱신되는 인-프로세스 MRU
  큐로 정렬.
- **설정 store.** `UserDefaults` 백업 `ObservableObject`. `CarouselView` 가
  observe 해서 geometry 변경이 즉시 반영됨.
- **비공개 API 사용 안 함.** 사용된 API 모두 macOS 14 시점 공개 문서화된 것.

### 프로젝트 구조

```
Lathe/
├── App/            LatheApp.swift, AppDelegate.swift
├── HotKey/         HotKeyMonitor.swift          (CGEventTap)
├── AppList/        AppEntry.swift, AppListProvider.swift
├── Overlay/        OverlayPanel + Controller, CarouselView/Model, CardView
├── Activation/     AppActivator.swift           (pid → activate)
├── Permissions/    AccessibilityChecker, PermissionPromptWindow
├── MenuBar/        MenuBarController.swift
├── Settings/       SettingsStore, SettingsView, SettingsWindowController,
│                   Appearance, LoginItem
└── Resources/      Info.plist, Assets.xcassets
LatheTests/         CarouselViewModelTests.swift
docs/
├── superpowers/    specs/  plans/                (디자인 history)
└── images/         README 스크린샷
```

### Spec & plan

원본 디자인 spec 과 구현 plan 도 같이 커밋:

- [디자인 spec](docs/superpowers/specs/2026-04-28-lathe-design.md)
- [구현 plan](docs/superpowers/plans/2026-04-28-lathe-v1.md)

## 의도적 제외 (현재 v1)

- 파일 드래그 → AirDrop / 휴지통
- 같은 앱 윈도우 사이클 (⌘+\`)
- 숫자 키 / 첫글자 점프
- 트랙패드 스와이프 회전
- 마우스 hover / 클릭 선택
- 자동 업데이트

v1에선 의도적으로 뺀 것들 — 필요하면 코드 베이스가 작아서 한나절이면 추가 가능.

## 라이선스

[MIT](LICENSE) — fork·수정·재배포 자유. attribution 만 유지해주면
됨.
