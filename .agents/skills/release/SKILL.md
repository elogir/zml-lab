---
name: release
description: Publish a ZML-Lab release. Takes the repo from wherever it stands to a published GitHub release (signed DMG plus the self-update archive and its signature): works out the version itself, bumps pubspec.yaml, runs the checks, tags, pushes after the user confirms and watches the release workflow. It finishes a half-done release rather than redoing it. Use when the user runs /release or asks to release, ship, tag or publish ZML-Lab.
---

# Release ZML-Lab

A release is an annotated `vX.Y.Z` tag on master. Pushing it runs `.github/workflows/release.yml`, which builds, code-signs and publishes three files: `ZML-Lab.dmg`, `zml-lab-macos.tar.gz` and `zml-lab-macos.tar.gz.sig`. Installed apps update themselves to the latest release.

Rules for every step:
- Release from `master` only. Never force-push.
- Never move, delete or re-create a pushed tag. Fix forward with the next patch.
- Commits follow the repo's style: a subject line, a blank line, then prose wrapped at 72 columns.
- Commits carry no `Co-Authored-By` or "Generated with Claude Code" lines.
- Nothing committed names a private repository or says where the benchmarker is built. Write "built elsewhere" instead.
- The repo is public, so nothing committed reveals the maintainer's machine: no local paths, host names, or where keys, certificates or checkouts live. That holds for skill files, comments and commit messages too.

## 1. Where things stand

Run `scripts/status.sh`. It fetches origin's tags and changes nothing else. It reports:
- the branch, uncommitted files and how far the branch is ahead of or behind origin;
- the latest `v*` tag on origin and whether HEAD is tagged;
- pubspec's version and the next version;
- for the release in progress: the tag locally and on origin, its `release.yml` run, and the GitHub release's assets;
- the benchmarker library.

Resume at the first row that matches:

| State | Next |
|---|---|
| Not on master, or behind origin/master | Stop and ask |
| HEAD's tag is on origin and its release has all three assets | Done: give step 7's report |
| HEAD's tag is on origin and its run is queued or in progress | Step 7 |
| HEAD's tag is on origin, and its run failed or there's no release | [references/recovery.md](references/recovery.md) |
| HEAD is tagged but the tag is only local | Step 6 |
| A release commit exists but isn't tagged yet | Tag it (end of step 5), then step 6 |
| No commits since the latest tag | Nothing to release: say so and stop |
| Otherwise | Steps 2 to 7 |

## 2. The benchmarker library

`native/libzmlbench.dylib` is the perf benchmarker, a C library loaded over FFI.
- It is built elsewhere and copied in by hand. Never build it here.
- It is gitignored.
- Release CI ignores the local file. It downloads the build pinned in `native/libzmlbench.dylib.sha256` from the repo's `zmlbench` pre-release, as asset `libzmlbench-<first 12 hex of the sha>.dylib`, and checks it against the pin.
- That pre-release and its `zmlbench` tag are a build input, not an app release, and the updater never sees them. Leave the tag alone.

`status.sh` compares the local file, the pin and the pre-release:
- **Same as the pin, and the asset is present:** current. CI will ship it.
- **Local file missing:** CI still ships the pin. Locally, the bench_lib tests skip and a local build has no Perf tab.
- **Local file differs from the pin:** someone copied in another build. Ask the user whether it's the one to ship.
- **Asset missing from the pre-release:** CI's fetch step will fail. If the local file has the pinned sha, publish it (below). Otherwise ask the user for that build.

Nothing here shows whether the benchmarker's source has changed. If the user says it has, ask them for the new build's path; never guess one. To ship a new build:
1. Copy it to `native/libzmlbench.dylib`. Check that `lipo -archs` lists `arm64`.
2. Ask the user before running `tool/publish_zmlbench.sh`, because it uploads to GitHub. It adds the asset to the `zmlbench` pre-release and rewrites the `.sha256` pin.
3. Commit the `.sha256` file, saying what changed in the library.
4. Run step 3 in full, including the release build. A new native asset needs a full `flutter test` or `flutter run`, never a hot reload.

## 3. Checks

- `flutter analyze` and `flutter test` must pass. Report what skipped: the bench_lib tests skip without the library, and the run-format contract skips without `uv`.
- Also run `flutter build macos --release` when `status.sh` lists changes to native assets or dependencies since the last tag (`pubspec.yaml`, `pubspec.lock`, `hook/`, `native/`, `macos/`).
- If a check fails, fix it or stop. Never release over a failing check.

## 4. Commit what's left

1. Read `git log -5` for the style.
2. Group the uncommitted changes into commits.
3. Show each message to the user before committing.

Run `status.sh` again afterwards:
- it must report 0 files naming private repos;
- review every added line it lists with a home path, and keep only the app's own documented locations.

## 5. Version

Decide the version; don't ask the user for it. If HEAD is already tagged, keep that tag and go to step 6.

- **Patch** (`X.Y.Z+1`) by default, counting from the latest `v*` tag on origin.
- **Minor** (`X.(Y+1).0`) only when the commits since that tag clearly call for it: a changed file format, a removed feature, or a migration users will notice.
- **Major** only if the user asks.
- Tell the user, in one line, which you picked and why.

Make the release commit:
1. Set `version: X.Y.Z+N` in `pubspec.yaml`, using the build number `N` that `status.sh` prints. It is pubspec's previous build number + 1. The first time pubspec is used this way (its version doesn't match the latest tag), `N` is the count of `v*` tags + 1.
2. Change nothing else in that commit.
3. Subject: `ZML-Lab X.Y.Z`. Body: `pubspec version X.Y.Z+N, built by the vX.Y.Z tag.`
4. Show the message first, as in step 4.

Tag that commit: `git tag -a vX.Y.Z -m vX.Y.Z`.

`release.yml` fails if the tag doesn't match pubspec's `X.Y.Z`. The bundle takes its version and build number from pubspec. `--dart-define=ZML_LAB_VERSION` comes from the tag; the updater reads it. Local builds don't have it, so they never update themselves.

## 6. Push

Confirm with the user first: "Push master and vX.Y.Z? Installed apps will update to it." Then push master before the tag:

```sh
git push origin master
git push origin vX.Y.Z
```

If a push fails or is cut off, check the remote before retrying:

```sh
git ls-remote origin refs/heads/master refs/tags/vX.Y.Z
```

## 7. Watch

```sh
gh run list --workflow release.yml --branch vX.Y.Z --limit 1   # the run's id
gh run watch <id> --exit-status
```

The run takes about 10 minutes, so run the watch in the background.

**On success**, run `gh release view vX.Y.Z` and report:
- the release URL;
- each asset with its size: `ZML-Lab.dmg`, `zml-lab-macos.tar.gz` and `zml-lab-macos.tar.gz.sig`;
- the benchmarker build it ships (the pin's first 12 hex).

**On failure**, run `gh run view <id> --log-failed`. Report the failing step and its log lines, then the likely cause: signing secrets, the code-signing requirement, the runner, or the pinned library missing. Then follow [references/recovery.md](references/recovery.md). The keys and certificate are described in [references/signing.md](references/signing.md).
