---
name: codesign-build
description: Use when building a local code-signed Lathe.app to run/test on this machine — build, codesign, sign, 코드사이닝, 로컬 빌드, 서명 빌드. NOT for distribution (that's /release → notarized CI). Signs with the SAME Developer ID as the installed app so Screen Recording (TCC) permission carries over instead of re-prompting.
---

# Local code-signed build

Build an optimized `Lathe.app` that **runs on this machine** and **keeps its Screen Recording permission** (dev/test). Distribution is a different path — use `/release` (notarized Developer ID via CI); never notarize locally.

## The one command

```bash
cd /Users/hongmono/Development/Lathe
xcodegen generate                          # .xcodeproj is gitignored/generated — always regenerate first
xcodebuild -project Lathe.xcodeproj -scheme Lathe -configuration Release \
  -derivedDataPath build/dd \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application: Jungwook Hong (THG2GV26Z9)" \
  DEVELOPMENT_TEAM=THG2GV26Z9 \
  PROVISIONING_PROFILE_SPECIFIER="" \
  build
# → build/dd/Build/Products/Release/Lathe.app
open build/dd/Build/Products/Release/Lathe.app
```

## Sign with Developer ID (Jungwook Hong), NOT Apple Development — this is the mistake to avoid

Screen Recording permission is TCC, keyed to the app's **code-signing designated requirement (DR)**. The installed app (from `/release`) is signed **`Developer ID Application: Jungwook Hong (THG2GV26Z9)`**, whose DR is **team-based**:

```
identifier "com.hongmono.Lathe" and anchor apple generic
  and certificate 1[field.…6.2.6] and certificate leaf[field.…6.1.13]
  and certificate leaf[subject.OU] = THG2GV26Z9
```

Sign the local build with the **same Developer ID** and its signature *satisfies that DR* → macOS treats it as the same app → **no permission re-prompt**.

Sign with **`Apple Development: hojw1019@gmail.com`** instead and the DR pins to that cert's exact **CN** (`certificate leaf[subject.CN] = "Apple Development: …"`), a *different* identity → TCC re-prompts for Screen Recording every time. That is the "코드사이닝 잘못" symptom. Both certs belong to the same Apple ID, but only Developer ID matches the installed app.

Verify carry-over (what TCC actually checks — satisfaction, not string-equality of DRs):

```bash
APP=build/dd/Build/Products/Release/Lathe.app
REQ=$(codesign -d -r- /Applications/Lathe.app 2>&1 | sed -n 's/^designated => //p')
codesign --verify -R="$REQ" "$APP" && echo "OK: same TCC identity as installed app"
```

## Why each override

- **`CODE_SIGN_IDENTITY="Developer ID Application: Jungwook Hong (THG2GV26Z9)"`** — full name, not just `"Developer ID Application"`: this machine has **two** Developer ID certs (`CRABs (KR)` and `Jungwook Hong`), so the bare name is ambiguous and may pick the wrong team. The project's Debug default `"Lathe Local Dev"` is a self-signed cert that **doesn't exist here** → always override.
- **`DEVELOPMENT_TEAM=THG2GV26Z9`** — the team ID, from the cert's **OU** field. For `Apple Development: … (SDNAF92M8C)` the parenthetical `SDNAF92M8C` is a **per-cert id, NOT the team** — using it as the team is wrong. Confirm any time: `security find-certificate -c "<cert CN>" -p | openssl x509 -noout -subject` → read `OU=`.
- **`PROVISIONING_PROFILE_SPECIFIER=""`** — no App Sandbox / special entitlements ⇒ no profile needed; empty avoids a "no profile found" failure under Manual signing.
- **Let `xcodebuild` sign; never post-hoc `codesign --deep`.** Xcode signs nested code inside-out during the build: Sparkle's `Downloader.xpc`, `Installer.xpc`, `Updater.app`, `Autoupdate`, then the framework, then the app. Re-signing just `Lathe.app` afterward breaks those nested signatures.

## Verify signature (after building)

```bash
APP=build/dd/Build/Products/Release/Lathe.app
codesign -dvvv "$APP" 2>&1 | grep -E "Authority=Developer|TeamIdentifier|flags|Runtime"
codesign --verify --deep --strict --verbose=2 "$APP"   # want: "valid on disk" + "satisfies its Designated Requirement"
spctl -a -vvv -t exec "$APP"                            # says "rejected" — NORMAL (not notarized); still runs on this machine
```

Good: `Authority=Developer ID Application: Jungwook Hong (THG2GV26Z9)`, `TeamIdentifier=THG2GV26Z9`, `flags=0x10000(runtime)`; deep-verify lists every Sparkle XPC/`Updater.app`/`Autoupdate` as `--validated`. **`spctl … rejected` is expected** for a local non-notarized build — do not "fix" it by notarizing; distribution goes through `/release`.

## Common mistakes

| Mistake | Consequence |
|---------|-------------|
| Sign with `Apple Development` (or any non-Developer-ID) cert | DR differs from installed app → Screen Recording permission re-prompts every launch. |
| `CODE_SIGN_IDENTITY="Developer ID Application"` (bare) | Ambiguous — two Developer ID certs here; may sign with `CRABs (KR)` / wrong team. |
| `DEVELOPMENT_TEAM=SDNAF92M8C` (a cert's parenthetical) | Wrong team; team is the cert **OU** = `THG2GV26Z9`. |
| No identity override at all | Falls back to `"Lathe Local Dev"` which doesn't exist here → signing fails. |
| `codesign --deep` the `.app` yourself | Breaks Sparkle's nested XPC/app signatures. Let xcodebuild do it. |
| Treating `spctl rejected` as failure | Expected for a local build; it still runs here. |
| Forgetting `xcodegen generate` | Stale project missing new/renamed files. |
