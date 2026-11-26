# MacJi update feed

This repository holds only the Sparkle feed (`appcast.xml`) for
[MacJi](https://github.com/mayank-devac/macji), an open-source emoji app for macOS.

- The app reads `https://raw.githubusercontent.com/mayank-devac/macji-dist/main/appcast.xml`.
- Every update archive is attached to a GitHub Release of the source repository and signed with
  MacJi's EdDSA key; the app refuses any archive whose signature does not match.
- `appcast.xml` is written by `scripts/release.py` in the source repository. Don't edit it by hand.
