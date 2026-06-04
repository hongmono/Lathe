# Carousel Settings and Keyboard Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a configurable fan r degree value, make the settings detail surface brighter, and support Left/Right arrow selection while the carousel is visible.

**Architecture:** Persist the new fan r degree value and fan spacing in `SettingsStore`, feed them into the SwiftUI carousel fan math, and expose them through the carousel settings pane. In fan mode, hide the general spacing slider so `r` is the single angle control, while fan spacing controls the rotation-anchor distance. Add a small pure key-action resolver around `HotKeyMonitor` so arrow key behavior can be tested without event-tap setup.

**Tech Stack:** Swift 6, SwiftUI, AppKit, CoreGraphics, XCTest, Xcode project.

---

## File Structure

- Modify `Lathe/Settings/SettingsStore.swift`: persisted `fanRDegrees` and `fanSpacing` settings, legacy point-value normalization, and reset defaults.
- Modify `Lathe/Settings/Detail/SettingsCarouselDetailView.swift`: fan-r degree slider, fan-spacing slider, and preview propagation.
- Modify `Lathe/Settings/SettingsView.swift`: brighter detail glass surface styling.
- Modify `Lathe/Overlay/CarouselView.swift`: use stored fan r degrees for fan rotation and fan spacing for anchor distance.
- Modify `Lathe/HotKey/HotKeyMonitor.swift`: arrow key action resolution and delegate callbacks.
- Modify `Lathe/App/AppDelegate.swift`: enable arrow selection only while overlay is visible.
- Modify localization files under `Lathe/Resources/*/Localizable.strings`.
- Modify tests under `LatheTests/`.

## Task 1: Persist Fan R Degrees

- [ ] Add failing tests in `LatheTests/SettingsStoreDisplayOptionsTests.swift`:

```swift
@MainActor
func test_fanRDegreesDefaultsToConfiguredDefault() {
    let store = SettingsStore(userDefaults: makeDefaults())
    XCTAssertEqual(store.fanRDegrees, SettingsStore.defaultFanRDegrees)
}

@MainActor
func test_fanRDegreesPersists() {
    let defaults = makeDefaults()
    let store = SettingsStore(userDefaults: defaults)
    store.fanRDegrees = 18
    let reloaded = SettingsStore(userDefaults: defaults)
    XCTAssertEqual(reloaded.fanRDegrees, 18)
}

@MainActor
func test_resetCarouselDefaultsRestoresFanRDegrees() {
    let store = SettingsStore(userDefaults: makeDefaults())
    store.fanRDegrees = 18
    store.resetCarouselDefaults()
    XCTAssertEqual(store.fanRDegrees, SettingsStore.defaultFanRDegrees)
}
```

- [ ] Run `xcodebuild test -project Lathe.xcodeproj -scheme Lathe -only-testing:LatheTests/SettingsStoreDisplayOptionsTests`.
- [ ] Implement `fanRDegrees` in `SettingsStore`.
- [ ] Implement `fanSpacing` in `SettingsStore`.
- [ ] Re-run the focused test command.

## Task 2: Apply Fan R Degrees in UI

- [ ] Add failing tests for user-facing strings in `LatheTests/LocalizationTests.swift`.
- [ ] Add `settings.carousel.fanRadius` and `settings.carousel.fanSpacing` to English and Korean localization files.
- [ ] Update `SettingsCarouselDetailView` so the r and fan-spacing sliders appear only for `.fan`, the general spacing slider is hidden for `.fan`, displays degrees/points, passes both values to preview, and resets with defaults.
- [ ] Update `CarouselView` so fan rotation uses `settings.fanRDegrees` and anchor distance uses `settings.fanSpacing`.
- [ ] Run `xcodebuild test -project Lathe.xcodeproj -scheme Lathe -only-testing:LatheTests/LocalizationTests -only-testing:LatheTests/SettingsStoreDisplayOptionsTests`.

## Task 3: Arrow Selection

- [ ] Add a pure `HotKeyAction` resolver test file:

```swift
XCTAssertEqual(HotKeyAction.resolve(keyCode: 0x7C, commandDown: false, shiftDown: false, arrowsEnabled: true), .next)
XCTAssertEqual(HotKeyAction.resolve(keyCode: 0x7B, commandDown: false, shiftDown: false, arrowsEnabled: true), .previous)
XCTAssertNil(HotKeyAction.resolve(keyCode: 0x7C, commandDown: false, shiftDown: false, arrowsEnabled: false))
XCTAssertEqual(HotKeyAction.resolve(keyCode: 0x30, commandDown: true, shiftDown: false, arrowsEnabled: false), .next)
```

- [ ] Run the new hotkey test and verify it fails.
- [ ] Add `HotKeyAction`, delegate arrow callbacks, and an `arrowsEnabled` flag to `HotKeyMonitor`.
- [ ] Update `AppDelegate` to enable arrows on overlay show and disable them when the overlay is no longer visible.
- [ ] Re-run the hotkey tests.

## Task 4: Visual Detail Surface

- [ ] Add a layout/style constant test asserting the detail surface overlay opacity is greater than zero.
- [ ] Add `SettingsViewLayout.detailSurfaceOverlayOpacity`.
- [ ] Use that opacity in `SettingsGlassSurfaceModifier` for non-interactive surfaces.
- [ ] Re-run `LatheTests/SettingsViewLayoutTests`.

## Task 5: Full Verification

- [ ] Run `xcodebuild test -project Lathe.xcodeproj -scheme Lathe`.
- [ ] Run `xcodebuild -project Lathe.xcodeproj -scheme Lathe -configuration Debug build`.
- [ ] Review `git diff --stat` and `git diff`.
