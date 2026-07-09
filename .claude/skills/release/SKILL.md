---
name: release
description: Use when publishing a new Lathe version — release, deploy, ship, cut a build, 배포, 릴리스, 새 버전 내보내기. Bumps version + changelog and triggers the notarized CI build via the release branch.
---

# Release Lathe

## Overview

Lathe ships through a **`release`-branch CI pipeline** (`.github/workflows/release.yml`) that builds, signs, **notarizes**, and publishes a GitHub release (`v<version>`) + Sparkle `appcast.xml`. You bump the version and changelog on `main`, then push to `release`.

## Steps

1. **Commit pending work to `main` first** — source changes as their own commit, separate from the release commit. Confirm `git status` is clean of unrelated files (don't sweep up `default.profraw`, `.mcp.json`, etc.).

2. **Bump `VERSION`** (semver): bug/perf fixes → **patch** (1.3.1 → 1.3.2), new user-facing feature → **minor**.

3. **Add a `## <version>` section to `CHANGELOG.md`** — **Korean**, user-facing (describe what changed *for the user*, not the implementation). Newest section on top, directly under `# Changelog`. **CI aborts if this section is missing or empty.**

4. **Commit** VERSION + CHANGELOG together: `release: <version> (<short summary>)`.

5. **Push both branches** (release branch push is what triggers CI):
   ```bash
   git push origin main
   git push origin main:release
   ```

6. **Verify CI** (build + **notarize**, ~3 min — don't claim done until it's green):
   ```bash
   gh run list --branch release --limit 1        # find the run-id
   gh run watch <run-id> --exit-status           # wait for success
   gh release view v<version> --json assets --jq '.assets[].name'
   ```
   Expect `Lathe-v<version>.dmg` + `appcast.xml`. The installed app then auto-updates via Sparkle.

## Notes

- `.xcodeproj` is **gitignored and generated** by XcodeGen — CI runs `xcodegen generate`. Never commit it.
- Signing (`Developer ID Application: Jungwook Hong (THG2GV26Z9)`), CI details, and dev-build TCC-permission caveats live in project memory `lathe-build-release-workflow`.
- Changelog tone/format: match existing entries — see project memory `changelog-in-korean`.

## Common Mistakes

| Mistake | Consequence |
|---------|-------------|
| Push `main` but forget `main:release` | Nothing builds — CI only fires on the `release` branch. |
| Skip/empty `## <version>` in CHANGELOG | CI aborts before building. |
| Commit the generated `.xcodeproj` | Stale project file; CI regenerates it anyway. |
| Claim "released" without checking `gh run` | Notarization can still fail after push. Verify green + assets. |
