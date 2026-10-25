#!/bin/sh
# Signs a built ZML-Lab.app with the release code-signing certificate, so
# macOS knows every release as the same app: Documents access and the other
# privacy grants survive updates, where an ad-hoc signature (a hash of that
# one build) made each update a new app. The certificate is self-signed, so
# Gatekeeper still calls the developer unidentified; that's about the first
# install, not the identity.
#
#   tool/macos_sign.sh build/macos/Build/Products/Release/ZML-Lab.app
#
# The certificate (.p12, base64) and its password come from the environment,
# ZML_LAB_CODESIGN_P12 and ZML_LAB_CODESIGN_PASSWORD: GitHub secrets in CI,
# path/to/certificate.{p12,password} locally:
#
#   ZML_LAB_CODESIGN_P12=$(base64 -i path/to/certificate.p12) \
#   ZML_LAB_CODESIGN_PASSWORD=... \
#   tool/macos_sign.sh path/to/ZML-Lab.app
#
# It goes into a throwaway keychain, deleted when done.
set -eu

app=${1:?usage: tool/macos_sign.sh path/to/ZML-Lab.app}
: "${ZML_LAB_CODESIGN_P12:?set ZML_LAB_CODESIGN_P12 (the .p12, base64)}"
: "${ZML_LAB_CODESIGN_PASSWORD:?set ZML_LAB_CODESIGN_PASSWORD}"
identity='ZML-Lab Code Signing'
entitlements="$(dirname "$0")/../macos/Runner/Release.entitlements"

work=$(mktemp -d)
keychain="$work/codesign.keychain-db"
keychain_password=$(openssl rand -hex 16)
searched=$(security list-keychains -d user | tr -d '"')
cleanup() {
  # shellcheck disable=SC2086 # one path per word
  security list-keychains -d user -s $searched
  security delete-keychain "$keychain" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
printf '%s' "$ZML_LAB_CODESIGN_P12" | base64 --decode > "$work/codesign.p12"
security import "$work/codesign.p12" -k "$keychain" \
  -P "$ZML_LAB_CODESIGN_PASSWORD" -T /usr/bin/codesign >/dev/null
rm "$work/codesign.p12"
# Lets codesign use the key without a prompt.
security set-key-partition-list -S apple-tool:,apple:,codesign: -s \
  -k "$keychain_password" "$keychain" >/dev/null
# codesign finds the key through the keychain search list.
# shellcheck disable=SC2086
security list-keychains -d user -s "$keychain" $searched

sign() {
  codesign --force --timestamp=none --keychain "$keychain" \
    --sign "$identity" "$@"
}

# Nested code first (frameworks, loose dylibs), then the app itself with its
# entitlements, which seals them in.
find "$app/Contents/Frameworks" -maxdepth 1 \
  \( -name '*.framework' -o -name '*.dylib' \) -print |
  while read -r nested; do sign "$nested"; done
sign --entitlements "$entitlements" "$app"

codesign --verify --deep --strict "$app"
codesign --display --requirements - "$app" 2>&1 | grep designated
