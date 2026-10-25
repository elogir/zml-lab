#!/bin/sh
# Packs a (signed) ZML-Lab.app into a disk image for a first install: open it,
# drag ZML-Lab onto Applications. Installed apps update themselves from the
# release's tar.gz after that.
#
#   tool/macos_dmg.sh build/macos/Build/Products/Release/ZML-Lab.app ZML-Lab.dmg
set -eu

app=${1:?usage: tool/macos_dmg.sh path/to/ZML-Lab.app out.dmg}
out=${2:?usage: tool/macos_dmg.sh path/to/ZML-Lab.app out.dmg}

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT
# ditto keeps the bundle as signed (permissions, symlinks, metadata).
ditto "$app" "$staging/$(basename "$app")"
ln -s /Applications "$staging/Applications"
hdiutil create -volname ZML-Lab -srcfolder "$staging" -fs HFS+ \
  -format UDZO -ov "$out" >/dev/null
echo "$out"
