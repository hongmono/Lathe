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

5. **Push both branches** (release branch push is what triggers CI). **This is where "released" ends** — the push is the deploy; CI builds/notarizes on its own:
   ```bash
   git push origin main
   git push origin main:release
   ```
   **Don't watch/block on CI.** Report the release as done once the push succeeds.

6. **(Optional) Check CI later** — only if the user asks, or to confirm it went green. Don't `gh run watch`; a quick status glance is enough:
   ```bash
   gh run list --branch release --limit 1
   gh release view v<version> --json assets --jq '.assets[].name'   # Lathe-v<version>.dmg + appcast.xml
   ```
   The installed app auto-updates via Sparkle once the release publishes.

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
| `gh run watch` blocking on CI after push | Wasted wait — push is the deploy; CI runs on its own. Report done at push. |
