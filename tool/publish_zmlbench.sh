#!/bin/sh
# Makes native/libzmlbench.dylib available to the release workflow, which
# can't build it: uploads it to this repo's `zmlbench` pre-release as
# libzmlbench-<sha>.dylib and pins that sha in native/libzmlbench.dylib.sha256.
# Commit the .sha256 file afterwards. Pre-releases are invisible to the
# updater, which only reads the latest full release.
set -eu
cd "$(dirname "$0")/.."

lib=native/libzmlbench.dylib
sha=$(shasum -a 256 "$lib" | cut -d' ' -f1)
asset="libzmlbench-$(echo "$sha" | cut -c1-12).dylib"

if ! gh release view zmlbench >/dev/null 2>&1; then
  gh release create zmlbench --prerelease --title 'zmlbench (build input)' \
    --notes 'The perf benchmarker library release builds bundle. Not an app release.'
fi
tmp=$(mktemp -d)
cp "$lib" "$tmp/$asset"
gh release upload zmlbench "$tmp/$asset" --clobber
rm -rf "$tmp"

echo "$sha" > native/libzmlbench.dylib.sha256
echo "Uploaded $asset. Commit native/libzmlbench.dylib.sha256."
