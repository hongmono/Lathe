# Per-Window Switching Design

- Date: 2026-07-08
- Status: Approved
- Target platform: macOS 14.6+

## Context

Lathe intercepts ⌘+Tab and renders a fan carousel of running `.regular`
apps; releasing ⌘ activates the center app. Until now the switcher
operated only at the app level — there was no way to pick *which window*
of an app to bring forward, and activating an app raised all of its
windows.

macOS itself uses ⌘+` (backtick) to move focus between the windows of the
active app. This feature adopts the same key to add window-level
switching on top of the existing app carousel, without disturbing the
app-switching muscle memory.

## Goals

- Add a window list above the carousel when the focused app has more than
  one user-facing window.
- Cycle windows with ⌘+` (forward) and ⇧⌘+` (backward), whether or not
  the carousel is already open.
- Pressing ⌘+` on its own (carousel closed) enters the frontmost app's
  windows directly.
- On ⌘ release, raise **only** the selected window — sibling windows stay
  where they are.
- Order windows most-recently-used per app, and show a short document/URL
  path next to titles that expose one.
- Keep app-level switching on public API; fence any private API behind
  runtime lookups with public fallbacks.

## Non-goals

- Cross-app window mixing (the window list is always scoped to one app).
- Persisting window order across launches (MRU is in-process only).
- A settings surface for the window list (no new preferences).

## Design

### Key handling

`HotKeyAction` gains `cycleWindow` / `cycleWindowPrevious`, resolved from
the grave key (`0x32`) and the ISO section key (`0x0A`) when ⌘ is down and
`windowCycleEnabled` is set. `windowCycleEnabled` is turned on globally at
startup so ⌘+` works as an entry point even when the overlay is hidden;
`arrowsEnabled` still gates arrow keys to the visible-overlay state. The
event tap now also consumes ⌘+`.

### Window list

`WindowListProvider` reconciles the Accessibility window list
(`kAXWindowsAttribute`) against `CGWindowListCopyWindowInfo`:

1. Filter AX windows to user-facing roles/subroles
   (`WindowVisibilityFilter`).
2. Match each AX window to a CoreGraphics window id — first via the
   private `_AXUIElementGetWindow`, then by title, then by frame (within a
   2pt tolerance).
3. Filter CG windows to layer 0, non-zero alpha, and a minimum size, and
   split them into on-screen and off-screen (minimized) pools.
4. Prefer the AX title, fall back to the CG title, and attach a
   `WindowPathSummary` derived from `kAXDocumentAttribute` / `kAXURLAttribute`.

`WindowOrderTracker` keeps a per-pid MRU list, reconciled against the live
window ids on each load, and `WindowFocusTracker` records the focused
window on `didActivateApplication` so ordering reflects real usage.
`WindowSelectionViewModel` owns the selected index and cycling.

### Rendering

`OverlayRootView` replaces `CarouselView` as the hosted root: it composes
the existing carousel geometry with a `WindowListView` shown above the
carousel via an overlay, only when `hasMultipleWindows` is true.

### Single-window raise

`SingleWindowFocuser` uses SkyLight (`_SLPSSetFrontProcessWithOptions`,
`SLPSPostEventRecordTo`, `GetProcessForPID`) to raise a single window
without app-level activation — the technique AltTab and yabai use.
`AppActivator.activate(_:window:)` calls it first; if the private symbols
are unavailable or the call fails, it falls back to `kAXMainAttribute` +
`kAXRaiseAction` and normal app activation.

## Private API

Two private surfaces are used, both resolved at runtime via `dlsym` with
public fallbacks so the app degrades gracefully if Apple removes them:

- `_AXUIElementGetWindow` — map an AX window to its CG window id.
- SkyLight front-process calls — raise one window.

App switching and the carousel remain entirely on public, documented API.

## Testing

- `HotKeyActionTests` — ⌘+` / ⇧⌘+` resolution, and that it is ignored when
  window cycling is disabled.
- `WindowListProviderTests` — CG filtering, frame matching tolerance, and
  title preference.
- `WindowOrderTrackerTests` — MRU touch, reconcile, and preferred index.
- `WindowPathSummaryTests` — path abbreviation and display-title assembly.
- `WindowSelectionViewModelTests` — load/clear, multi-window gating, and
  wraparound cycling.
