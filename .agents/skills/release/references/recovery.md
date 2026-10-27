# Recovering a half-done or failed release

Finish a release; never redo it. A pushed tag is permanent. Once it is on origin, never move, delete or re-push it, even when nothing was published: someone may have fetched it, and a later rerun would build a different commit.

## Half-done states

- **Committed, not pushed.** Push master (step 6).
- **Release commit made, not tagged.** Find the commit with
  `git log -1 -G'^version:' -- pubspec.yaml` and tag it:
  `git tag -a vX.Y.Z -m vX.Y.Z <commit>`.
  If commits came after it and belong in the release, leave it untagged. Make a new release commit with the next patch instead.
- **Tag local only.** Check `git ls-remote --tags origin vX.Y.Z` first. Then push master if it's ahead, then push the tag.
- **Tag pushed, no workflow run.** Check that the tag matches `v<major>.<minor>.<patch>` and that `.github/workflows/release.yml` exists at the tagged commit. A tag pushed together with many others can miss its trigger. If no run ever appears, fix forward with the next patch rather than re-pushing the tag.
- **Run succeeded, release missing or short of assets.** The Publish step failed or was cancelled. Rerun it: `gh run rerun <id> --failed`.

## Failed runs

`gh run view <id> --log-failed` shows the failing step.

| Step | Likely cause | Fix |
|---|---|---|
| Read the version from the tag | The tag isn't `vX.Y.Z`, or pubspec's `X.Y.Z` differs from the tag | Next patch, with pubspec bumped |
| Fetch the perf benchmarker library | The pinned `libzmlbench-<sha12>.dylib` isn't on the `zmlbench` pre-release, or its checksum differs | If you have the pinned build, `tool/publish_zmlbench.sh` and rerun. Otherwise next patch, with a new pin |
| `flutter pub get --enforce-lockfile` | `pubspec.lock` is stale or a hash changed | Run `flutter pub get`, commit, next patch |
| Build | A compile error the analyzer missed, Flutter (`flutter-version` in the workflow) differing from local, or the `macos-26` runner image changing | Reproduce with `flutter build macos --release` locally, fix, next patch. For a flaky runner, rerun |
| Code-sign | `ZML_LAB_CODESIGN_P12` or `_PASSWORD` is missing or wrong, or the certificate expired (it is valid until 2036) | Fix the secret ([signing.md](signing.md)), then rerun |
| Package and sign | `ZML_LAB_UPDATE_KEY` is missing, or doesn't match `updatePublicKey` | Fix the secret, then rerun. Never change `updatePublicKey` to match a new key: installed apps would reject the release |
| Publish | The release already exists, or a GitHub hiccup | Check `gh release view vX.Y.Z`, then rerun |

**Rerun or fix forward.** Rerun the same run (`gh run rerun <id> --failed`) when nothing in the repo has to change: a secret, a flaky runner, or uploading a pin that already exists. A rerun builds the tagged commit with the workflow as it was at that commit. Anything that needs a commit is a new patch release: go back to step 2 and leave the failed tag as it is.

## The release published, but apps won't install it

The updater checks the archive's Ed25519 signature, then the code-signing requirement: `codesign` must accept `updateCodeRequirement` (bundle id `ai.zml.lab` plus the certificate's hash). To check a published release:

```sh
gh release download vX.Y.Z --pattern 'zml-lab-macos.tar.gz*' --dir /tmp/zl
tar -xzf /tmp/zl/zml-lab-macos.tar.gz -C /tmp/zl
codesign --verify -R='=identifier "ai.zml.lab" and certificate leaf = H"26030c55cf8570725dff36177ae3f74c4874816a"' /tmp/zl/ZML-Lab.app
```

The hash comes from `updateCodeRequirement` in `lib/features/updates/domain/update_release.dart`. For the signature check, see [signing.md](signing.md). A release that fails either check can't be fixed in place. Publish the next patch, built correctly.
