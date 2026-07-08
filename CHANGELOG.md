# Changelog

## Unreleased

- 미션 컨트롤 레이아웃을 추가했습니다. 설정 → 레이아웃에서 '미션 컨트롤'을 고르면, ⌘+Tab 이 현재 Space 의 모든 창을 각자 속한 모니터 위에 겹치지 않게 펼쳐 보여줍니다. ⌘ 을 누른 채 Tab 을 눌러 창을 하나씩 넘기고, 선택한 창만 선명하게·나머지는 살짝 흐리게 표시하며, ⌘ 을 떼면 그 창으로 전환합니다.
- 창 미리보기에는 화면 기록 권한을 사용합니다. 권한이 없으면 각 창을 앱 아이콘과 제목 타일로 대신 표시합니다.

## 1.2.0

- ⌘+` 로 현재 앱의 창 사이를 전환하는 기능을 추가했습니다. 캐러셀이 떠 있으면 가운데 앱의 창 목록에서, 캐러셀이 닫혀 있으면 최전면 앱에서 바로 창을 순환합니다. (⇧ 를 함께 누르면 역방향)
- 창이 둘 이상인 앱은 캐러셀 위에 창 목록을 표시하고, 최근 사용(MRU) 순으로 정렬합니다. 문서·URL 창은 제목 옆에 축약된 경로를 함께 보여줍니다.
- 창을 선택하면 형제 창을 함께 끌어올리지 않고 선택한 창 하나만 전면화합니다.

## 1.1.2

- 앱을 전환할 때 최소화해 둔 창이 전부 복원되던 문제를 고쳤습니다. 이제 보이는 창이 하나도 없을 때만 가장 최근 창 하나를 복원합니다.
- 접근성 권한을 켜면 앱을 다시 시작하지 않아도 ⌘Tab이 바로 동작합니다. 권한을 허용한 뒤 Lathe로 돌아오거나 '상태 새로고침'을 누르면 자동으로 적용됩니다.

## 1.1.1

- 사용하지 않는 내부 코드를 정리했습니다. (기능 변화 없음)

## 1.1.0

- 설정창을 새로 만들어 사이드바 펼치기·접기가 부드럽게 동작합니다.
- 사이드바 토글 버튼을 사이드바 영역 오른쪽에 두고, ⌘B 단축키로도 접고 펼 수 있습니다.
- 설정창 사이드바가 macOS 기본 사이드바처럼 표시됩니다.

## 1.0.13

- Bring the app to the front when checking for updates so the result dialog (including "you're up to date") is actually visible instead of opening behind other windows.

## 1.0.12

- Restore the sidebar toggle button and add a Command-B shortcut to show or hide the settings sidebar.

## 1.0.11

- Let the settings detail content span the full window width instead of being capped at a fixed maximum.

## 1.0.10

- Build the release with the macOS 26 SDK so the distributed app shows the correct translucent settings sidebar (the previous release was built with an older SDK and rendered it flat).

## 1.0.9

- Fix the settings window sidebar so it shows the standard translucent material without the content area turning transparent.

## 1.0.8

- Restore the translucent (vibrant) sidebar material in the settings window so it reads as floating, matching the native macOS look.

## 1.0.7

- Redesign the settings window with a unified sidebar so the window controls sit on the sidebar, matching the native macOS look.
- Keep the sidebar always visible and show the selected section name in the title bar.
- Rebuild the Hidden Apps list to match System Settings, with a short description above the table.

## 1.0.6

- Replace the carousel-card icon direction with a distinct keyboard-switcher mark built around Command-Tab.
- Refresh the menu bar template icon to match the new keycap-and-switch silhouette.

## 1.0.5

- Replace the app icon with a simpler, higher-contrast carousel mark that stays readable at small sizes.
- Refresh the menu bar template icon with a cleaner three-card silhouette.

## 1.0.4

- Remove the Space carousel layout option and restore the layout picker to Fan, Strip, and Stack only.
- Remove the visual current-Space metadata path added for the experimental layout while keeping the existing current-Space app ordering behavior.

## 1.0.3

- Soften the Space carousel layout into one continuous fan-like deck instead of a separated two-row layout.
- De-emphasize other-Space apps with depth, scale, and opacity while keeping current-Space apps in front.

## 1.0.2

- Add a Space carousel layout option that separates current Space apps from other running apps.
- Preserve the existing fan layout fallback when current Space metadata is unavailable for visible apps.
- Add localized Space layout labels and focused regression coverage for the new layout.

## 1.0.1

- Keep apps like KakaoTalk in the current Space switcher order even when macOS does not expose their windows through the normal window list.
- Bring selected apps forward more reliably by unhiding them, activating all windows, and raising accessible windows when switching.
- Harden release signing configuration so CI discovers the Developer ID identity and injects Sparkle keys from GitHub secrets.

## 1.0.0

- Mark Lathe as the first stable release.
- Include signed and notarized distribution.
- Include Sparkle automatic updates and signed appcast delivery.

## 0.3.0

- Add Sparkle automatic updates.
- Add a Check for Updates menu item and update controls in About settings.
- Publish a signed Sparkle appcast with each GitHub Release.

## 0.2.11

- Add Developer ID release signing for maintainer builds.
- Add notarized DMG packaging in the release workflow.
- Publish releases from the `release` branch instead of tag pushes.
- Add file-based release versioning with `VERSION`.
- Add changelog-based release notes for GitHub Releases and future Sparkle updates.
