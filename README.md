# Lathe

A safer, self-built ⌘+Tab replacement for macOS. Carousel UI where the
center card is always the focused app; ⌘+Tab/⇧Tab rotates, ⌘ release confirms.

## Why

`yuzeguitarist/Orbit` is a closed-source unsigned macOS menu bar app that
demands Accessibility + Input Monitoring. That permission combo on an
unsigned, partially-published binary is a non-starter. Lathe is a from-scratch
clone in spirit, built and signed by you, that you can audit line by line.

## Build

Requires Xcode 15+ and `xcodegen`:

```bash
brew install xcodegen
xcodegen generate
open Lathe.xcodeproj
```

In Xcode:

1. Select the `Lathe` target → Signing & Capabilities → Team: your personal Apple ID.
2. Run (⌘R).
3. Grant Accessibility permission when prompted (System Settings → Privacy & Security → Accessibility → enable Lathe).
4. Quit and relaunch Lathe after granting (event taps need a fresh process).

## Use

- ⌘+Tab → carousel appears, center card is the previous app
- ⌘ held + Tab → rotate forward
- ⌘ held + ⇧Tab → rotate backward
- ⌘ release → activate the center app
- ⌘ held + Esc → cancel without switching

## Status

v1: keyboard-only carousel switcher.

Out of scope (intentional): file drag → AirDrop / Trash, same-app window cycling,
preferences UI, auto-launch, auto-update.

## Manual QA

After first launch + permission grant + relaunch:

- [ ] Menu bar icon appears (dotted circle).
- [ ] ⌘+Tab opens Lathe carousel (NOT system switcher).
- [ ] Holding ⌘ + Tab rotates carousel right.
- [ ] ⌘ + ⇧Tab rotates left.
- [ ] Releasing ⌘ activates center app.
- [ ] ⌘ + Esc dismisses without switching.
- [ ] Carousel shows on top of full-screen apps.
- [ ] Carousel appears on the screen with the cursor (multi-monitor).
- [ ] "Quit Lathe" from menu bar terminates cleanly.

## License

Personal use. No license granted for redistribution.
