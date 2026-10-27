# Release signing

Two separate signatures. CI makes both from repository secrets. The private originals are kept outside the repository: ask the user for them, and never write where they are into a committed file.

## The update signature (Ed25519)

- **What:** `tool/update_signing.dart sign <version> <archive>` signs the archive's SHA-256, the version and the asset name. The release workflow writes the result to `zml-lab-macos.tar.gz.sig`.
- **Private key:** the `ZML_LAB_UPDATE_KEY` secret, one base64 line.
- **Public half:** `updatePublicKey` in `lib/features/updates/domain/update_release.dart`. The sign command refuses a key that doesn't match it.
- **Losing the key:** installed apps reject every later release, and each install has to be updated by hand.
- **Checking a published `.sig`:** Ed25519 is deterministic. With the key in `ZML_LAB_UPDATE_KEY`, re-signing the downloaded archive with the same version must reproduce the published `.sig` byte for byte:

  ```sh
  dart run tool/update_signing.dart sign X.Y.Z zml-lab-macos.tar.gz
  ```

## The code signature (macOS)

- **What:** `tool/macos_sign.sh` signs the app with the self-signed "ZML-Lab Code Signing" certificate. macOS then treats every release as the same app and keeps its permissions across updates.
- **Secrets:** `ZML_LAB_CODESIGN_P12` (the `.p12`, base64) and `ZML_LAB_CODESIGN_PASSWORD`.
- **Designated requirement:** bundle id `ai.zml.lab` and the certificate's leaf hash. This is `updateCodeRequirement`, and from 0.1.5 the updater refuses an update that doesn't satisfy it.
- **Changing the certificate or the bundle id** changes the app's identity, so macOS asks for every permission again. It also needs a transition release first: one whose `updateCodeRequirement` accepts the new identity, published before any build signed with it.

## Setting a secret

`gh secret set <NAME>` reads the value from stdin. The `.p12` goes in base64 (`base64 -i <p12> | gh secret set ZML_LAB_CODESIGN_P12`). Setting a secret changes the repository's configuration, so the user either does it or OKs it first.
