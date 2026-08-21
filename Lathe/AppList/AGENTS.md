# AppList Guide

## OVERVIEW

- Build the switchable app and window snapshots consumed by overlays.
- `AppListProvider` owns running-app state and space-aware app MRU.
- `WindowListProvider` reconciles Accessibility windows with CoreGraphics IDs.
- `WindowFocusTracker` owns ephemeral, per-process window MRU.
- Treat AX as metadata and intent, CG as the source of stable window IDs.
- Missing AX permission is a supported runtime path, not an exceptional result.

## STRUCTURE

- `AppEntry.swift`, app identity plus carousel exclusion and space priority transforms.
- `AppListProvider.swift`, NSWorkspace observation, snapshot rebuild, app ordering.
- `CurrentSpaceWindowProvider.swift`, layer-zero visible process detection.
- `SpaceScopedAppOrder.swift`, global and remembered space-local app MRU.
- `WindowListProvider.swift`, AX/CG discovery, matching, titles, frames.
- `WindowVisibilityFilter.swift`, CG and AX eligibility rules.
- `WindowFocusTracker.swift`, activation-driven focused-window recording.
- `WindowOrderTracker.swift`, per-PID window ordering and selection index.
- `WindowPathSummary.swift`, compact AX document and URL labels.

## WHERE TO LOOK

- App ordering or Space changes: `AppListProvider` and `SpaceScopedAppOrder`.
- Window eligibility or missing cards: `WindowVisibilityFilter` before matcher changes.
- Wrong AX-to-CG pairing: `WindowListProvider.matchUniqueToCGWindow`.
- Minimized windows: match off-screen layer-zero CG windows first.
- Focused default window: `WindowFocusTracker` plus `WindowOrderTracker`.
- Display labels: `WindowEntry` and `WindowPathSummary`.

## CONVENTIONS

- Keep app and window MRU in memory only.
- Scope window order by PID. Never let one app's IDs affect another's order.
- Reconcile order with live IDs before reading it. Preserve existing MRU, append unknown live IDs.
- On app activation, move its PID to the front, then rebuild the snapshot.
- Maintain global order even when current Space data is empty.
- Space memories include detected PIDs and activation-inferred PIDs. Match exact sets first, then only memories with overlap of at least two.
- Base CG candidates must be layer zero, nontransparent, and at least 100 square points.
- The on-screen pool additionally requires `kCGWindowIsOnscreen`, width >= 200, and height >= 80.
- AX candidates must be `AXWindow` with no subrole, or an allowed standard, dialog, or document subrole.
- Consume each CG candidate once while matching AX windows.
- Match AX to CG in this order: runtime direct ID, exact title, then frame.
- Frame matching compares AX and CG global top-left coordinates with a 2-point tolerance on origin and size.
- Prefer AX title, fall back to CG title. Drop entries with neither usable title nor path.
- When AX window enumeration fails, return titled on-screen CG windows with no path and `isMinimized == false`.
- `_AXUIElementGetWindow` is optional. Keep title and frame matching as its fallback.
- Read AX document before AX URL for path summaries. Keep summaries short and home-relative where possible.

## ANTI-PATTERNS

- Don't replace reconciliation with title-only matching. Duplicate and empty titles exist.
- Don't admit floating layers, transparent windows, tiny CG artifacts, or unsupported AX roles.
- Don't turn AX enumeration failure into a crash; preserve the titled on-screen CG fallback.
- Don't use the on-screen pool as the first match for minimized AX windows.
- Don't change CG frame coordinates to a display-local or bottom-left system.
- Don't tighten the 2-point tolerance without evidence from AX and CG rounding behavior.
- Don't persist stale app or window IDs across termination or live-list reconciliation.
- Don't reorder all apps globally when updating a remembered Space order.
