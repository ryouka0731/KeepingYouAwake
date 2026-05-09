# Sparkle auto-update — one-time setup

`#54` ships the workflow infrastructure for Sparkle auto-updates. Once
the items below are completed, every new `v*-amphetamine.*` tag will
auto-publish a signed `appcast.xml`, and existing installs will see the
update inside KYA's "Check for Updates…" menu.

## 1. Generate the EdDSA key pair

Sparkle 2.x uses Ed25519 signatures. On a Mac with Sparkle's tools
available (e.g. via Homebrew or by extracting Sparkle's release
tarball):

```bash
# Download Sparkle's tools — pin to the same version as the workflow.
SPARKLE_VERSION=2.6.4
curl -L "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" \
  -o sparkle.tar.xz
tar -xf sparkle.tar.xz

# Generate the key pair. This stores the private key in the keychain
# and prints the public key to stdout.
./bin/generate_keys
# → Public key: <BASE64_PUBLIC_KEY>
```

To export the private key for use as a CI secret:

```bash
./bin/generate_keys -p   # prints the base64-encoded private key
```

> ⚠️ The private key has signing power over every fork user's
> auto-update. Treat it like a release-signing secret: don't commit it,
> don't paste it into chat, and rotate it if you ever suspect leakage.

## 2. Add the public key to `Info.plist`

Open `KeepingYouAwake/Info.plist` and add:

```xml
<key>SUPublicEDKey</key>
<string>BASE64_PUBLIC_KEY_FROM_STEP_1</string>
```

Commit and push. Sparkle inside the running app reads this on launch
and refuses to install any update whose signature can't be verified
against this public key.

## 3. Add the private key as a repo secret

```bash
gh secret set SPARKLE_ED_PRIVATE_KEY \
  --repo ryouka0731/KeepingYouAwake-Amphetamine \
  --body "$(./bin/generate_keys -p)"
```

The `appcast.yml` workflow reads this through `secrets.SPARKLE_ED_PRIVATE_KEY`
and forwards it to `sign_update`.

## 4. Enable GitHub Pages on `gh-pages`

The workflow's first run creates an orphan `gh-pages` branch with an
`index.html` and the generated `appcast.xml`. Once the branch exists:

1. Go to `Settings → Pages` in the repo.
2. Set **Source** to `Deploy from a branch`, **Branch** to `gh-pages`,
   **Folder** to `/ (root)`.
3. Save. Within ~1 minute the appcast is live at
   `https://ryouka0731.github.io/KeepingYouAwake-Amphetamine/appcast.xml`,
   matching the URL hard-coded in `KYAAppUpdater.m`.

## 5. Trigger the first run

Either push a new tag, or manually run the workflow:

```bash
gh workflow run appcast.yml --repo ryouka0731/KeepingYouAwake-Amphetamine
```

Verify the resulting `appcast.xml` has `sparkle:edSignature="..."` on
each `<enclosure>` — that's the proof that signing is wired up.

## Verifying inside the app

In a development build (or a downloaded fresh release):

1. **KeepingYouAwake** menu → **Check for Updates…**
2. If the appcast advertises a newer build than the running one,
   Sparkle prompts to install. Confirm — Sparkle will fetch the
   signed dmg, verify `sparkle:edSignature` against the
   `SUPublicEDKey` baked into the running bundle, and replace
   `KeepingYouAwake.app` in place.

## Rotating or revoking the key

Re-run step 1 to generate new keys, update `SUPublicEDKey` in
`Info.plist`, push a new release with the new public key, and
update the `SPARKLE_ED_PRIVATE_KEY` secret. Old installs (still
holding the old public key) won't accept the new signed updates
until their owners manually download a recent release — there is
no in-band rotation mechanism in Sparkle.
