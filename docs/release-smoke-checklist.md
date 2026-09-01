# Release smoke checklist

Run this checklist on the signed release candidate. Unit tests do not exercise TCC, global event taps,
ScreenCaptureKit, window activation, or real multi-display geometry.

## Installation and permissions

- [ ] Install the candidate over the previous release and confirm Accessibility permission remains valid.
- [ ] Revoke Accessibility permission, launch Lathe, grant it again, and confirm `Command-Tab` works without relaunching.
- [ ] Deny Screen Recording permission and confirm Mission Control remains usable with icon and title fallbacks.
- [ ] Grant Screen Recording permission, relaunch Lathe, and confirm window thumbnails appear.

## Switcher input

- [ ] Open each layout with `Command-Tab`, navigate forward and backward, and release Command to commit.
- [ ] Press `Command-Escape` and `Command-.` while the switcher is open and confirm neither changes the active app.
- [ ] Press `Command-H` on a visible app in the carousel and confirm it becomes hidden and visibly marked.
- [ ] Press `Command-H` again on that app and confirm it becomes visible without switching to it.
- [ ] Press `Command-Q` on a normal app and confirm it receives a normal quit request and disappears from the switcher.
- [ ] Press `Command-Q` on an app with unsaved work and confirm its save prompt is preserved; do not force quit it.
- [ ] Make Finder visible in Lathe, press `Command-Q`, and confirm Finder is not terminated.
- [ ] After `Command-H` or `Command-Q`, navigate to another item before releasing Command and confirm that item activates.

## Apps and windows

- [ ] Switch to an app with visible and minimized windows; confirm visible windows are raised without restoring all minimized windows.
- [ ] Switch to an app whose every window is minimized; confirm only the most recent window is restored.
- [ ] Cycle forward and backward through multiple windows with `Command-\`` and `Shift-Command-\``.
- [ ] Confirm selecting one window does not pull all sibling windows forward.
- [ ] Launch and terminate apps while the carousel is open and confirm selection stays on the same app when possible.

## Displays and Spaces

- [ ] Open the carousel on each connected display and confirm it is centered on the display containing the pointer.
- [ ] Open Mission Control with multiple displays and confirm every window belongs to the correct display.
- [ ] Repeat with a vertically rotated display and confirm thumbnails are not enlarged beyond their source size.
- [ ] Change Spaces and confirm current-Space apps remain ahead of other running apps in carousel order.

## Settings and update path

- [ ] Toggle language, appearance, layout, carousel geometry, names, and opening animation; confirm each persists after relaunch.
- [ ] Enable Reduce Motion in macOS and confirm the opening spread animation is skipped.
- [ ] Open settings with `Command-,` while the switcher is visible and confirm the selection is not committed.
- [ ] Run Check for Updates and confirm the result window appears in front.
