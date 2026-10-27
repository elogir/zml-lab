#!/bin/sh
# Where a ZML-Lab release stands: everything /release decides from. Read-only
# apart from fetching origin's tags.
#
#   .agents/skills/release/scripts/status.sh
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1

say() { printf '%-28s %s\n' "$1" "$2"; }
semver='^v[0-9]+\.[0-9]+\.[0-9]+$'
have_gh=$(command -v gh >/dev/null && gh auth status >/dev/null 2>&1 && echo yes)

git fetch --quiet --tags origin || echo "warning: git fetch failed, origin may be stale"

echo "== repository"
say "branch:" "$(git rev-parse --abbrev-ref HEAD)"
say "uncommitted files:" "$(git status --porcelain | wc -l | tr -d ' ')"
if git rev-parse --verify --quiet origin/master >/dev/null; then
  # shellcheck disable=SC2046 # two numbers
  set -- $(git rev-list --left-right --count origin/master...HEAD)
  say "vs origin/master:" "behind $1, ahead $2"
fi
private=$(git grep -il --untracked "mono""repo" -- . ':!*.lock' | wc -l | tr -d ' ')
say "files naming private repos:" "$private (must be 0)"

echo "== version"
remote_tags=$(git ls-remote --tags --refs origin 'v*' | sed 's#.*refs/tags/##' | grep -E "$semver")
tag_count=$(printf '%s' "$remote_tags" | grep -c . || true)
latest_num=$(printf '%s\n' "$remote_tags" | sed 's/^v//' | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
latest=${latest_num:+v$latest_num}
say "latest tag on origin:" "${latest:-none} ($tag_count v* tags)"
head_tag=$(git tag --points-at HEAD | grep -E "$semver" | head -1)
say "HEAD tagged:" "${head_tag:-no}"
pub=$(sed -n 's/^version: *//p' pubspec.yaml)
pub_name=${pub%%+*}
pub_build=${pub#*+}
[ "$pub_build" = "$pub" ] && pub_build=0
say "pubspec version:" "$pub"

# A release commit not tagged yet: pubspec's version moved past the latest tag.
pending=
if [ -z "$head_tag" ] && [ -n "$latest" ] && [ "v$pub_name" != "$latest" ] &&
  git diff "$latest" HEAD -- pubspec.yaml | grep -q '^+version:'; then
  pending=v$pub_name
  say "release commit, untagged:" "$pending at $(git log -1 --format='%h %s' -G'^version:' "$latest"..HEAD -- pubspec.yaml)"
fi

if [ -n "$latest" ]; then
  if [ -z "$head_tag$pending" ]; then
    IFS=. read -r x y z <<EOF
$latest_num
EOF
    # pubspec's build number + 1; the first time, the release count + 1.
    if [ "$pub_name" = "$latest_num" ]; then build=$((pub_build + 1)); else build=$((tag_count + 1)); fi
    say "next patch / minor:" "v$x.$y.$((z + 1)) / v$x.$((y + 1)).0, build number $build"
  fi
  echo "commits since $latest:"
  git log --format='  %h %s' "$latest"..HEAD
  changed=$(git diff --name-only "$latest" HEAD -- pubspec.lock hook native macos | tr '\n' ' ')
  # pubspec.yaml counts unless only its version moved.
  if git diff "$latest" HEAD -- pubspec.yaml | grep -E '^[-+][^-+]' | grep -qv '^[-+]version:'; then
    changed="pubspec.yaml $changed"
  fi
  say "native/deps changed:" "${changed:-none}"
  # The repo is public: a home path in a new line may expose this machine.
  homes=$(git diff "$latest" -- . ':!*.lock' |
    grep -E '^\+[^+].*(/Users/[^m]|/Users/m[^e]|~/[A-Za-z.]|\$HOME)')
  say "added lines with home paths:" "$(printf '%s' "$homes" | grep -c . || true) (review each)"
  [ -n "$homes" ] && printf '%s\n' "$homes" | cut -c1-160
fi

target=${head_tag:-${pending:-$latest}}
if [ -n "$target" ]; then
  echo "== $target"
  local_commit=$(git rev-parse -q --verify "refs/tags/$target^{commit}" | cut -c1-9)
  remote_commit=$(git ls-remote --tags origin "refs/tags/$target^{}" | cut -c1-9)
  say "tag local:" "${local_commit:-no}"
  say "tag on origin:" "${remote_commit:-no}"
  if [ -n "$have_gh" ]; then
    run=$(gh run list --workflow release.yml --branch "$target" --limit 1 \
      --json databaseId,status,conclusion,url --jq '.[] | "\(.status) \(.conclusion) \(.url)"')
    say "release.yml run:" "${run:-none}"
    say "GitHub release assets:" "$(gh release view "$target" --json assets \
      --jq '[.assets[].name] | join(" ")' 2>/dev/null || echo none)"
  fi
fi

echo "== benchmarker library"
pin=$(cat native/libzmlbench.dylib.sha256 2>/dev/null)
say "pinned sha256:" "${pin:-none}"
if [ -f native/libzmlbench.dylib ]; then
  sha=$(shasum -a 256 native/libzmlbench.dylib | cut -d' ' -f1)
  [ "$sha" = "$pin" ] && same="same as the pin" || same="DIFFERS from the pin ($sha)"
  say "native/libzmlbench.dylib:" "$same, $(lipo -archs native/libzmlbench.dylib)"
else
  say "native/libzmlbench.dylib:" "missing"
fi
if [ -n "$have_gh" ] && [ -n "$pin" ]; then
  asset="libzmlbench-$(echo "$pin" | cut -c1-12).dylib"
  if gh release view zmlbench --json assets --jq '.assets[].name' | grep -qx "$asset"; then
    say "zmlbench pre-release:" "has $asset"
  else
    say "zmlbench pre-release:" "MISSING $asset (CI's fetch will fail)"
  fi
fi
[ -n "$have_gh" ] || echo "warning: gh missing or not signed in: no workflow, release or library checks"
