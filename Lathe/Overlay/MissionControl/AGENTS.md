# MISSION CONTROL

## OVERVIEW

Mission Control presents current Space windows as app stacks across every display.
One `OverlayPanel` fills each `NSScreen`, indexed by current `NSScreen.screens` order.
A stack is one app on one screen. Its front window is the activation target.
Keyboard selection moves between stacks. Command plus backtick rotates within the selected stack.
A click selects its stack and commits immediately. Hover only changes visual emphasis.
Tiles must remain usable when Screen Recording is unavailable or captures fail.

## STRUCTURE

`MissionControlController.swift` owns panels, visibility, input wiring, and thumbnail requests.
`MissionControlViewModel.swift` owns observable stacks, selection, hover, and thumbnail state.
`MissionControlWindowProvider.swift` converts CG window records and assigns each window to a display.
`MissionControlLayout.swift` is the shared, deterministic tile and hit testing geometry.
`MissionControlScreenView.swift` renders one screen from that screen's local tile set.
`WindowThumbnailProvider.swift` handles permission checks and concurrent ScreenCaptureKit capture.

## WHERE TO LOOK

Change panel creation or pointer routing in `MissionControlController`.
Change tab order, front card choice, or commit behavior in `MissionControlViewModel`.
Change screen ownership or global to local coordinate conversion in `MissionControlWindowProvider`.
Change tile placement in `MissionControlLayout`, then keep controller hit testing on `tiles()`.
Change card depth, dimming, fallback content, or thumbnail transition in `MissionControlScreenView`.
Change capture limits, permissions, or per window capture concurrency in `WindowThumbnailProvider`.

## CONVENTIONS

Use CG global top left coordinates for window bounds. Convert screen frames through `CoordinateSpace.globalTopLeft`.
Use local top left coordinates for layout, screen views, and panel click points.
Assign a spanning window to the screen with the greatest overlap. Preserve the first screen on exact ties.
Group by process and screen. Keep each stack's windows in app MRU order, with index zero as front.
Order stacks by screen index, then first appearance within that screen. This defines keyboard traversal.
Keep `MissionControlLayout.tiles()` deterministic. Its ID based variation must not change between renders.
Render and hit test from the same tile calculation. Never duplicate geometry rules.
Keep the selected stack distinct from the hovered stack. Only the selected front card receives the accent ring.
Keep deeper cards behind the front card with explicit depth based z ordering.
Request Screen Recording access at most once per controller lifetime. No permission means fallback tiles, not an empty overlay.
Capture thumbnails after panels appear. Capture failures omit only those images and retain icon and title fallbacks.
Merge captured thumbnails as a batch on the main actor. Don't let capture completion replace stacks or selection.

## ANTI-PATTERNS

Don't mix AppKit bottom left screen frames with CG top left window frames.
Don't assign all windows to the primary display or lay out global frames inside a local panel.
Don't make click hit testing approximate the rendered cards.
Don't reorder stacks from asynchronous thumbnail completion.
Don't let hover commit, move keyboard selection, or alter the selected app stack.
Don't require window titles when Screen Recording permission is absent.
Don't block overlay presentation on ScreenCaptureKit, capture every window serially, or discard fallback cards.
