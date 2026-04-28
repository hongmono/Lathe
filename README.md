<h1 align="center">Lathe</h1>

<p align="center">
  <strong>A safer, self-built ⌘+Tab replacement for macOS.</strong>
</p>

<p align="center">
  <a href="#why">Why</a> •
  <a href="#install">Install</a> •
  <a href="#build-from-source">Build</a> •
  <a href="#use">Use</a> •
  <a href="#preferences">Preferences</a> •
  <a href="#permissions">Permissions</a> •
  <a href="#tech">Tech</a> •
  <a href="#license">License</a>
</p>

<p align="right">
  English · <a href="README.ko.md">한국어</a>
</p>

---

Lathe takes over the system ⌘+Tab and shows a fan-shaped carousel of
your running apps. The card at the top is always the focused app — hold
⌘ and tap Tab to rotate the deck, release ⌘ to switch.

<p align="center">
  <img src="docs/images/carousel.png" alt="Lathe carousel" width="640">
</p>

## Why

I wanted ⌘+Tab to look more interesting than a row of icons, and I
wanted to be able to read the source of whatever was intercepting my
keystrokes. Lathe is the result — small enough to audit in an
afternoon, signed by your own identity, no third-party permissions
to worry about.

## Install

Two paths:

- **Build it yourself** (recommended — that's the point of this
  project; see [Build from source](#build-from-source))
- **Download a signed build** from
  [Releases](https://github.com/hongmono/Lathe/releases) — same
  binary the maintainer runs, signed with the `Lathe Local Dev`
  self-signed identity. After unzipping:

  ```bash
  xattr -d com.apple.quarantine Lathe.app
  open Lathe.app
  ```

  This is the kind of `xattr` workaround we wanted to avoid in
  closed-source apps. Here you can read the source first; if you
  don't trust the binary, build it yourself.

### Build it yourself

1. Install the build dependency:

   ```bash
   brew install xcodegen
   ```

2. Clone, generate the Xcode project, and open it:

   ```bash
   git clone https://github.com/hongmono/Lathe.git
   cd Lathe
   xcodegen generate
   open Lathe.xcodeproj
   ```

3. In Xcode, select the `Lathe` target → Signing & Capabilities → Team:
   your signing identity (see [Code signing](#code-signing) below).
   Run with ⌘R.

4. The first launch will show a permission window. Grant Accessibility
   in System Settings, then quit and run again — event taps need a
   fresh process to attach.

That's it. There is no DMG, no notarization, no `xattr` workaround. The
whole binary lives in your DerivedData and is signed with your local
identity.

## Build from source

### Toolchain

| Tool       | Version                                    |
|------------|--------------------------------------------|
| macOS      | 14.6 (Sonoma) or later                     |
| Xcode      | 15+ (project tested on Xcode 26)           |
| Swift      | 6.0                                        |
| `xcodegen` | latest (`brew install xcodegen`)           |

### Code signing

Lathe is signed with a **self-signed Code Signing certificate** named
`Lathe Local Dev`, stored in your login keychain. This matters because
macOS's TCC (the privacy database that grants Accessibility) tracks
apps by signing identity — using a stable identity means **granted
permissions persist across rebuilds** instead of being revoked every
time the cdhash changes.

To create the certificate:

1. Open **Keychain Access** → menu **Certificate Assistant → Create a
   Certificate…**
2. Set:
   - Name: `Lathe Local Dev`
   - Identity Type: `Self Signed Root`
   - Certificate Type: `Code Signing`
3. Check **"Let me override defaults"**, click Next through the wizard,
   and bump **Validity Period** to `3650` (10 years) so it doesn't
   expire on you.
4. Finish.
5. Authorize the new key for codesigning:

   ```bash
   security set-key-partition-list \
     -S apple-tool:,apple:,codesign: -s \
     -D "Lathe Local Dev" -t private \
     ~/Library/Keychains/login.keychain-db
   ```

   When prompted, enter your macOS login password.

If you'd rather use a different identity (your own Developer ID, a
team certificate, etc.), edit `Project.yml` and `dev`:

```yaml
# Project.yml
settings:
  base:
    CODE_SIGN_IDENTITY: "Your Identity Name"
    DEVELOPMENT_TEAM: "YOUR_TEAM_ID"   # or "" for self-signed
```

```bash
# dev
SIGN_ARGS=(
  CODE_SIGN_STYLE=Manual
  CODE_SIGN_IDENTITY="Your Identity Name"
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"
)
```

### Day-to-day

Anytime `Project.yml` or a Swift source changes, regenerate the Xcode
project:

```bash
xcodegen generate
```

Then build/run from Xcode (⌘R), or from the command line:

```bash
xcodebuild -project Lathe.xcodeproj -scheme Lathe -configuration Debug build
xcodebuild -project Lathe.xcodeproj -scheme Lathe test
```

## Use

| Input                | Effect                                              |
|----------------------|-----------------------------------------------------|
| ⌘+Tab                | Open carousel, focus the previous app               |
| ⌘ held + Tab         | Rotate forward                                      |
| ⌘ held + ⇧Tab        | Rotate backward                                     |
| ⌘ released           | Activate the focused (center) app                   |
| ⌘ held + Esc         | Dismiss without switching                           |
| ⌘ held + ,           | Open Preferences (also dismisses the carousel)      |

Behavior matches the system ⌘+Tab so the muscle memory still works —
the only difference is that the focus is fixed at the top of the
carousel and the cards rotate around it.

## Preferences

Open from the menu bar's dotted-circle icon → **Preferences…**, or
hit ⌘+, while the carousel is open (see [Use](#use)).

<p align="center">
  <img src="docs/images/preferences.png" alt="Lathe preferences window" width="480">
</p>

| Section    | Setting                  | What it does                                 |
|------------|--------------------------|----------------------------------------------|
| Appearance | Theme                    | System / Light / Dark                        |
| Carousel   | Card size                | Card width; height & pivot scale with it     |
| Carousel   | Spacing                  | Angle (degrees) between adjacent cards       |
| General    | Launch Lathe at login    | Register as a Login Item via `SMAppService`  |

The carousel sliders update **live** — leave the Preferences window
open, hit ⌘+Tab, and tweak.

## Permissions

Lathe needs **Accessibility** permission to install the
`CGEventTap` that intercepts ⌘+Tab globally. There is no other
permission requested — no Input Monitoring, no Full Disk Access, no
Screen Recording. The event tap is scoped to keyDown for ⌘ + Tab/⇧Tab
/Esc only; everything else passes through unmodified.

If you ever want to revoke: System Settings → Privacy & Security →
Accessibility → toggle Lathe off (or remove it entirely).

The TCC entry survives rebuilds because the app is signed with a
stable identity. If you change the signing identity (or rotate the
certificate), you'll be prompted once more and can clear the old
record with:

```bash
tccutil reset Accessibility com.hongmono.Lathe
```

## Tech

- **SwiftUI + AppKit hybrid.** The carousel is a SwiftUI view hosted
  inside an `NSPanel` overlay; the menu bar item, hot key tap, and
  workspace observers are AppKit.
- **Fan layout.** Each card is rotated around an off-frame pivot via
  `rotationEffect(_:anchor:)`. The center card has angle 0; neighbors
  spread out by `±n × angularStep`. No manual trig, no `GeometryReader`
  gymnastics.
- **Event tap.** Two `CGEventTap` instances on `cgSessionEventTap` /
  `headInsertEventTap` — one for `flagsChanged` (track ⌘ press/release),
  one for `keyDown` (intercept Tab / ⇧Tab / Esc and consume them).
- **App list.** `NSWorkspace.runningApplications` filtered to
  `.regular` activation policy, ordered by an in-process MRU queue
  fed by `didActivateApplication` notifications.
- **Settings store.** `ObservableObject` backed by `UserDefaults`,
  observed by `CarouselView` so geometry changes apply live.
- **No private API.** Everything used here is publicly documented and
  available since macOS 14.

### Project layout

```
Lathe/
├── App/            LatheApp.swift, AppDelegate.swift
├── HotKey/         HotKeyMonitor.swift          (CGEventTap)
├── AppList/        AppEntry.swift, AppListProvider.swift
├── Overlay/        OverlayPanel + Controller, CarouselView/Model, CardView
├── Activation/     AppActivator.swift           (pid → activate)
├── Permissions/    AccessibilityChecker, PermissionPromptWindow
├── MenuBar/        MenuBarController.swift
├── Settings/       SettingsStore, SettingsView, SettingsWindowController,
│                   Appearance, LoginItem
└── Resources/      Info.plist, Assets.xcassets
LatheTests/         CarouselViewModelTests.swift
docs/
├── superpowers/    specs/  plans/                (design history)
└── images/         README screenshots
```

### Spec & plan

The original design spec and implementation plan are checked in:

- [Design spec](docs/superpowers/specs/2026-04-28-lathe-design.md)
- [Implementation plan](docs/superpowers/plans/2026-04-28-lathe-v1.md)

## Out of scope (intentional, for now)

- File drag → AirDrop / Trash
- Same-app window cycling (⌘+\`)
- Number-key or first-letter jump
- Trackpad swipe to rotate
- Mouse hover / click to select
- Auto-update

These are all deliberate omissions for v1 — if you want them, the
codebase is small enough to add them in an afternoon.

## Releases

A GitHub Actions workflow at [`.github/workflows/release.yml`](.github/workflows/release.yml)
builds a signed Release archive on every `v*` tag push (or via manual
`workflow_dispatch`) and attaches the zipped `.app` to a GitHub Release.

### One-time secret setup

The workflow uses your local self-signed `Lathe Local Dev` identity, so
the runner needs to import it.

1. Export the cert + private key from your login keychain to a `.p12`:

   ```bash
   security export -k login.keychain -t identities -f pkcs12 \
     -P "<choose-an-export-password>" -o /tmp/lathe-cert.p12
   # Pick the "Lathe Local Dev" identity in the dialog that follows.
   ```

2. Encode it as base64 (for GitHub secrets):

   ```bash
   base64 -i /tmp/lathe-cert.p12 | pbcopy
   ```

3. On GitHub: **Settings → Secrets and variables → Actions → New repository secret**.
   Add three secrets:

   | Name                    | Value                                           |
   |-------------------------|-------------------------------------------------|
   | `SIGNING_CERT_P12`      | Paste the base64 from step 2                    |
   | `SIGNING_CERT_PASSWORD` | The export password from step 1                 |
   | `KEYCHAIN_PASSWORD`     | Any random string — used for the runner-side keychain |

4. Wipe the local copy: `rm /tmp/lathe-cert.p12`

### Cutting a release

```bash
git tag v0.1.0
git push origin v0.1.0
```

The workflow runs, builds, signs, zips, and publishes a release with
auto-generated notes. You can also trigger it manually from the
**Actions** tab → **Release** workflow → **Run workflow** (specify
the tag).

### Caveat

The artifact is signed with a self-signed identity, so anyone else
downloading it will hit Gatekeeper's "unidentified developer" wall and
need to run `xattr -d com.apple.quarantine Lathe.app` once before
opening. For a publicly trusted distribution you'd need a paid Apple
Developer ID + notarization step in this workflow.

## License

[MIT](LICENSE) — fork, modify, ship it however you want. Attribution
keeps the door open for others to find the source.
