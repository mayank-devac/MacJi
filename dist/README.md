# MacJi update feed

This folder holds MacJi's Sparkle feed (`appcast.xml`) and the signing identity of the last release
(`signing-identity.json`).

- The app reads `https://raw.githubusercontent.com/mayank-devac/MacJi/main/dist/appcast.xml`.
- Every update archive is attached to a GitHub Release of this repository and signed with
  MacJi's EdDSA key; the app refuses any archive whose signature does not match.
- `appcast.xml` is written by `scripts/release.py`. Don't edit it by hand.
