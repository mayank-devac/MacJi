<!--
  SECURITY.md · MacJi · Created: 2026-11-26
  How to report a vulnerability, and how MacJi's signing and updates work.
-->

# Security

MacJi has Accessibility access, so it can see key presses and type text into other apps. We take
reports about it seriously.

## Reporting a vulnerability

Please **don't open a public issue.** Report it privately, in either of these ways:

- **GitHub:** open the repository's **Security** tab and choose **Report a vulnerability**.
- **Email**, if you don't have a GitHub account: write to
  [macji.app@proton.me](mailto:macji.app@proton.me) with "Security" in the subject.

Include the MacJi version, your macOS version and the steps to reproduce.

You'll get a reply within a week. Once a fix is released, the report is credited in the release
notes unless you'd rather stay anonymous.

Only the latest release gets security fixes.

## What's in scope

- Anything that makes MacJi store, log or send keystrokes, or read text it shouldn't.
- A way to make MacJi install an update that wasn't signed with its EdDSA key.
- A way for another process to drive MacJi's text insertion.
- An event tap that keeps blocking input after Accessibility access is removed.

## How releases are signed

- The app is signed with a self-signed certificate named **MacJi Release**, with the hardened
  runtime. It isn't notarized; the README explains the first launch.
- Updates are signed with an **EdDSA (ed25519)** key. MacJi refuses any update whose signature
  doesn't match the public key in its `Info.plist`.
- The update feed and archives are served over HTTPS from GitHub.
- Each release publishes SHA-256 sums in `SHA256SUMS.txt`.

To check a copy you downloaded:

```sh
shasum -a 256 MacJi-*.dmg                                   # compare with SHA256SUMS.txt
codesign -dv --verbose=2 /Applications/MacJi.app 2>&1 | grep Authority   # Authority=MacJi Release
```

## Why library validation is turned off

Releases include the `com.apple.security.cs.disable-library-validation` entitlement. Without a paid
Apple Developer account the certificate has no Team ID. With library validation on, macOS refuses to
load the Sparkle framework that ships inside MacJi, and the app crashes at launch. MacJi loads no
plug-ins and no code from outside its own bundle.
