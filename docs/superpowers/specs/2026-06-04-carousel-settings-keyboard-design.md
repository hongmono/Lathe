# Carousel Settings and Keyboard Navigation Design

- Date: 2026-06-04
- Status: Approved
- Target platform: macOS 14.6+

## Context

Lathe already exposes carousel layout settings and renders the switcher through a
SwiftUI overlay hosted in an AppKit panel. The current fan layout uses a fixed
fan angle derived from carousel spacing, and keyboard navigation after the
overlay is visible is limited to Cmd+Tab and Shift+Cmd+Tab.

## Goals

- Make the settings detail surface visibly brighter than the surrounding
  preferences background while preserving system-adaptive materials.
- Add a fan r-value preference that appears only when the fan carousel layout is
  selected.
- Use the fan r-value in both the live carousel and the settings preview.
- Let Left and Right arrow keys move the selection while the carousel is already
  visible.

## Non-Goals

- Do not make arrow keys open the carousel from an inactive state.
- Do not replace the existing Cmd+Tab activation and release behavior.
- Do not redesign the whole preferences window.

## Design

`SettingsView` will keep its manual sidebar-detail layout. The detail panel will
continue using `settingsGlassSurface`, but that modifier will add a subtle
system-adaptive light overlay for non-interactive surfaces so the detail panel
reads brighter than the root material.

`SettingsStore` will add persisted `fanRDegrees` and `fanSpacing` values with
defaults matching the current visual behavior. The r-value preference key remains
compatible with the previous local `fanRadius` key, but legacy point-sized
values outside the degree range are ignored and reset to the default.
`resetCarouselDefaults()` will reset these values alongside card size, angular
spacing, and app-name visibility.

`CarouselView` will pass the stored r degree value into its fan layout math and
use `fanSpacing` as the fan rotation anchor distance. The layout model remains
focused on per-item angle, offset, scale, opacity, and z-index. For the fan
layout, fan r is the only angle control; the general spacing setting is not
applied so the two settings do not compete. At `0°`, the fan cards are
flat/horizontal, and fan spacing controls the spread once r is above zero.

`SettingsCarouselDetailView` will show a `Fan r` slider only for
`LayoutStyle.fan`, show a `Fan spacing` slider in points for the same layout,
and hide the general spacing slider for fan. The preview receives both fan
values.

`HotKeyMonitor` will recognize Left and Right arrow keyDown events. If Command
is held, behavior remains unchanged for Tab/Escape. If Command is not held,
arrow keys are forwarded to the delegate only when arrow handling is enabled.
`AppDelegate` will enable that handling while the overlay is visible and disable
it after activation, cancellation, or hide.

## Testing

- Add store tests for fan r default, persistence, legacy value normalization,
  fan spacing default/persistence, and reset behavior.
- Add carousel layout tests that `0°` is horizontal, larger r values increase
  rotation, and fan ignores general spacing to avoid competing angle controls.
- Add hotkey handling unit tests through a small pure key-action resolver so
  arrow behavior can be tested without installing a CGEventTap.
- Run the focused tests first, then the full Xcode test suite.
