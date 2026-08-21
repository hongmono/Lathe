# PROJECT KNOWLEDGE BASE

**Generated:** 2026-08-21T01:58:23Z
**Commit:** 25619ea
**Branch:** main

## OVERVIEW

Lathe is a Swift 6 macOS 14.6+ menu-bar app that replaces `Command-Tab` with carousel and Mission Control-style switchers. SwiftUI renders content; AppKit, Accessibility, CoreGraphics, ScreenCaptureKit, SkyLight fallbacks, and Sparkle provide system integration.

## STRUCTURE

```text
Lathe/
├── Project.yml                    # XcodeGen source of truth
├── Lathe/
│   ├── App/                       # @main entry and runtime composition
│   ├── AppList/                   # App/window discovery and MRU ordering
│   ├── Overlay/
│   │   └── MissionControl/        # Multi-screen window overview mode
│   ├── Activation/                # App/window focus and private-API fallback
│   ├── HotKey/                    # Global CGEventTap input
│   ├── Settings/                  # UserDefaults state and preferences UI
│   ├── Localization/              # Runtime language selection
│   ├── Update/                    # Sparkle bridge
│   └── Resources/                 # Info.plist, assets, en/ko strings
├── LatheTests/                    # Flat hosted XCTest target
└── docs/superpowers/              # Historical specs and plans
```

`Lathe.xcodeproj` is generated and ignored. The current source tree, not historical layout diagrams, is authoritative.

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Trace startup or end-to-end switching | `Lathe/App/LatheApp.swift`, `AppDelegate.swift` | `AppDelegate` owns the runtime graph |
| Change key handling | `Lathe/HotKey/HotKeyMonitor.swift` | Resolver is pure; event taps dispatch on main |
| Change app/window discovery | `Lathe/AppList/` | Read its nested guidance first |
| Change carousel behavior | `Lathe/Overlay/OverlayController.swift`, `CarouselViewModel.swift`, `CarouselLayout.swift` | Controller commits through `OverlayPresenting` |
| Change Mission Control mode | `Lathe/Overlay/MissionControl/` | Read its nested guidance first |
| Change activation/focus | `Lathe/Activation/` | Preserve public fallbacks around private symbols |
| Add a preference | `Lathe/Settings/SettingsStore.swift`, `Settings/Detail/` | Persist through `UserDefaults`; update reset/migration paths |
| Add user-facing copy | `Lathe/Resources/en.lproj/Localizable.strings`, `ko.lproj/Localizable.strings` | Keep both catalogs synchronized |
| Change targets, sources, resources, signing | `Project.yml` | Regenerate; never hand-edit the project file |
| Add tests | `LatheTests/` | Flat `*Tests.swift` files, hosted by `Lathe.app` |
| Change release behavior | `.github/workflows/release.yml`, `VERSION`, `CHANGELOG.md` | Release workflow does not run tests |

## CODE MAP

Textual occurrence counts supplement LSP outlines; Swift workspace reference queries were unavailable.

| Symbol | Type | Location | Refs | Role |
|--------|------|----------|-----:|------|
| `LatheApp` | `App` | `Lathe/App/LatheApp.swift` | 1 | Sole `@main`; menu-bar scene |
| `AppDelegate` | class | `Lathe/App/AppDelegate.swift` | 3 | Composition root and input coordinator |
| `SettingsStore` | class | `Lathe/Settings/SettingsStore.swift` | 73 | Shared persisted runtime configuration |
| `AppListProvider` | class | `Lathe/AppList/AppListProvider.swift` | 3 | Running-app snapshot and Space ordering |
| `HotKeyMonitor` | class | `Lathe/HotKey/HotKeyMonitor.swift` | 5 | Global input boundary |
| `OverlayPresenting` | protocol | `Lathe/Overlay/OverlayPresenting.swift` | 4 | Shared selection lifecycle for both modes |
| `OverlayController` | class | `Lathe/Overlay/OverlayController.swift` | 4 | Carousel orchestration |
| `MissionControlController` | class | `Lathe/Overlay/MissionControl/MissionControlController.swift` | 4 | Multi-screen overview orchestration |
| `WindowListProvider` | struct | `Lathe/AppList/WindowListProvider.swift` | 12 | AX/CG window reconciliation |
| `WindowFocusTracker` | class | `Lathe/AppList/WindowFocusTracker.swift` | 7 | Per-app in-process window MRU |
| `AppActivator` | enum namespace | `Lathe/Activation/AppActivator.swift` | 4 | Terminal app/window side effect |

Runtime path: `LatheApp` -> `AppDelegate` -> `HotKeyMonitor` -> `AppListProvider` -> `OverlayController` or `MissionControlController` -> `AppActivator`.

## CONVENTIONS

- Treat `Project.yml` as canonical. Run `xcodegen generate` after Swift source or manifest changes.
- Keep the application as one feature-organized target; there is no SwiftPM `Sources/` or internal package module layer.
- Put UI/controller state on `@MainActor`. Event-tap callbacks remain nonisolated and hop to the main queue.
- Isolate platform calls behind small protocols/providers; keep deterministic transforms as value types or static functions for direct XCTest coverage.
- Tests use `final class ...Tests: XCTestCase`, `test_<behavior>()`, and `@testable import Lathe`. Add `@MainActor` when touching actor-isolated state.
- Use isolated `UserDefaults` suites in settings tests. Do not let tests depend on the developer's defaults or TCC state.
- Preserve English and Korean localization parity.

## ANTI-PATTERNS (THIS PROJECT)

- Do not edit or commit `Lathe.xcodeproj`; it is generated and gitignored.
- Do not replace runtime-resolved private APIs without retaining the documented public Accessibility fallback.
- Do not persist per-window MRU order or mix windows across applications.
- Do not let arrow keys open an inactive carousel or alter `Command-Tab` release-to-commit behavior.
- Do not post-sign local builds with `codesign --deep`; Xcode must sign Sparkle's nested code inside-out.
- Do not use an Apple Development identity for a TCC-preserving local build; sign with the same Developer ID identity as the installed app.
- Do not notarize local builds; distribution belongs to the release-branch CI workflow.

## UNIQUE STYLES

- SwiftUI owns views and the menu-bar scene; AppKit owns lifecycle, panels, and the settings window.
- Selection confirmation converges at `AppDelegate.commitActiveSelection()` for keyboard release and pointer commits.
- Private `_AXUIElementGetWindow` and SkyLight calls are optional runtime accelerators, not correctness requirements.
- The focused card remains at the top; window lists remain scoped to the focused app.
- Mission Control thumbnails may be absent without Screen Recording permission; the mode must still function.

## COMMANDS

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project Lathe.xcodeproj -scheme Lathe -configuration Debug build
xcodebuild -project Lathe.xcodeproj -scheme Lathe test
```

For a local signed Release build that preserves TCC identity, regenerate first, pass the installed app's Developer ID identity and team to `xcodebuild`, and leave nested Sparkle signing to Xcode.

## NOTES

- `Project.yml` declares Swift 6 with `SWIFT_STRICT_CONCURRENCY: minimal`.
- `Info.plist` is tracked, but release CI overwrites its version fields from `VERSION`.
- The release workflow triggers on `release`, signs/notarizes a DMG, publishes Sparkle metadata, and optionally updates Homebrew; it performs no XCTest step.
- Permission-dependent UI and system integration require manual exercise in addition to unit tests.
