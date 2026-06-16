# Changelog

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
