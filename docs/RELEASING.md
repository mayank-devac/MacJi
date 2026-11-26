# Releasing MacJi

Created: 2026-11-26

MacJi ships **without a paid Apple Developer account**: there's no Developer ID and no notarization.
Releases are signed with a stable **self-signed certificate** and updates are verified by **Sparkle's
EdDSA signature**. `scripts/release.py` does every step and stops on the first failure. It never
pushes, tags or publishes; it prints those commands for you to run.

## Why a self-signed certificate, not ad-hoc

Ad-hoc signing (`-`) pins the app's identity to each build's hash. After every update macOS sees a
new app: the Accessibility toggle still shows "on" but does nothing, and the user has to grant it
again. Octopus hit exactly this. A self-signed certificate puts the certificate's leaf hash in the
app's designated requirement, so every build signed with it is the same app to macOS.

**The certificate's name and the certificate itself must never change.** The Accessibility grant and
the login item stay valid only while they're the same, and so does the bundle ID
`io.github.mayank-devac.macji`.

## One-time setup (Mayank)

### 1. Create the `MacJi Release` certificate

1. Open **Keychain Access → Certificate Assistant → Create a Certificate…**
2. Name: `MacJi Release`. Identity Type: **Self Signed Root**. Certificate Type: **Code Signing**.
3. Check it's there: `security find-identity -p codesigning | grep "MacJi Release"`
   (it shows as not trusted; that's expected and fine for signing).
4. **Back it up**: export it as a `.p12` with a strong password and store it outside the
   repository, next to your other secrets. Losing it forces every user to grant Accessibility again.

### 2. Create the Sparkle EdDSA key

```sh
./build.sh --no-launch      # resolves packages, which downloads Sparkle's tools
"$(ls -d .build/DerivedData/SourcePackages/artifacts/sparkle/*/bin | head -1)/generate_keys" --account macji
```

- `generate_keys` stores the private key in your login Keychain and prints the **public** key.
- Put the public key into `MacJi/Resources/Info.plist` as `SUPublicEDKey`, replacing the
  `AAAA…=` placeholder. `release.py` refuses to run while the placeholder is there.
- Back up the private key: `generate_keys --account macji -x macji-private-key` writes it to a file.
  Keep that file outside the repository and delete the local copy. **Never commit or print it.**

### 3. Create the feed repository

Create the public repository `mayank-devac/macji-dist` with `dist/README.md` and `dist/appcast.xml`
from this repository. The app's feed URL (`SUFeedURL` in Info.plist) is
`https://raw.githubusercontent.com/mayank-devac/macji-dist/main/appcast.xml`. Update archives
themselves go on GitHub Releases of `mayank-devac/MacJi`.

## Every release

1. Write the notes under `## [Unreleased]` in `CHANGELOG.md` and commit everything.
2. Dry run first (changes no tracked file):
   ```sh
   scripts/release.py patch --dry-run
   ```
3. Real run (bumps the version via `scripts/bump-version.sh`, updates `dist/appcast.xml`):
   ```sh
   scripts/release.py patch      # or minor / major
   ```
   It checks the certificate and key, archives unsigned, signs every nested component and then the
   app with `MacJi Release` (hardened runtime), verifies the signatures (no Team ID, designated
   requirement pinned to the certificate), builds the zip and DMG, signs the zip with EdDSA, writes
   the appcast with the release notes and runs `scripts/verify-update.swift`.
4. Install the DMG from `.build/release/<version>/` on a Mac (ideally another one): first launch,
   Accessibility, `::` in TextEdit, the picker, Check for Updates.
5. Run the commands `release.py` printed: commit, tag, push, `gh release create …`, then publish
   `appcast.xml` to `macji-dist`. The feed goes live with that last push.

## How updates stay trusted

- Sparkle verifies every archive against `SUPublicEDKey` before installing it. EdDSA is what makes
  updates safe without notarization.
- Sparkle also checks that the new app's code signature satisfies the installed app's designated
  requirement. With a self-signed certificate that requirement pins the certificate's leaf hash, so
  a build signed with the same `MacJi Release` certificate is accepted.
- Sparkle's docs describe key rotation for Developer ID apps: a release may change **either** the
  EdDSA key **or** the code-signing certificate, never both. The same rule applies here. `release.py`
  records both in `dist/signing-identity.json`, refuses a release where both changed, and needs
  `--allow-key-rotation` when one did.
- Not yet verified end to end: a real update from one `MacJi Release` build to the next. Do it once
  with the first two releases (install 0.1.0, publish 0.1.1, use Check for Updates).

## Entitlements

`MacJi/Resources/MacJi.entitlements` holds one entitlement, `com.apple.security.cs.disable-library-validation`.
With the hardened runtime on, macOS loads only libraries signed by Apple or by the app's own Team ID.
A self-signed app has no Team ID, so without this entitlement dyld refuses Sparkle.framework at
launch ("different Team IDs"). This was reproduced on 2026-11-26. The App Sandbox is off because the
event tap and the Accessibility API need it off.

## First launch for users

Unnotarized apps are blocked on first launch. The README's "First launch" section explains
System Settings → Privacy & Security → **Open Anyway** and the `xattr` alternative. Publish the
SHA-256 sums (`SHA256SUMS.txt`) with every release.

## Never

- Never commit the certificate, a `.p12`, the Sparkle private key or `Config/LocalSigning.xcconfig`.
- Never change the bundle ID, the certificate and the EdDSA key casually; never two of them at once.
- Never publish without testing the packaged DMG.
