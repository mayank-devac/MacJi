<!--
  CONTRIBUTING.md · MacJi · Created: 2026-11-26
  How to set up, build, test and send a change.
-->

# Contributing to MacJi

Thanks for helping. MacJi is small on purpose: two features, two dependencies, no network access
other than update checks. Changes that keep it that way are the easiest to accept.

## Before you start

- **Bugs:** open an issue with the bug template. Say which app you were typing in. Many problems
  only happen in particular apps: Electron apps, terminals and web views often don't report a caret.
- **Features:** open an issue first so we can agree on the idea before you spend time on code.
- **Security problems:** don't open a public issue. Follow [SECURITY.md](SECURITY.md).

## Set up

```sh
git clone https://github.com/mayank-devac/MacJi.git
cd MacJi
scripts/setup.sh
```

`setup.sh` checks Xcode, fetches the Swift packages and creates `Config/LocalSigning.xcconfig`. To
keep the Accessibility grant across rebuilds, set a signing identity there (any certificate in your
Keychain will do). Otherwise every build is signed ad-hoc and macOS asks for access again.

If you also run Octopus, turn its MacJi feature off while you test, or both apps open a panel.

## The everyday loop

```sh
./build.sh                      # build Debug, quit the running build, launch the new one
scripts/test.sh                 # every test; fails if no tests ran
scripts/test.sh EmojiDataTests  # one suite
scripts/check.sh                # hygiene gate: run it before every commit (CI runs it too)
scripts/new-file.sh MacJi/Shared/EmojiUI/Thing.swift "What this file does"
```

Every script supports `--help`. The full list is in [CLAUDE.md](CLAUDE.md#scripts).

## How the code is organised

Read [`repo_map.md`](repo_map.md) to find where things live and [`CLAUDE.md`](CLAUDE.md) for the
rules. In short:

- **One composition root.** `MacJi/App/AppDelegate.swift` creates and wires every controller.
  Features never import each other.
- **No literals in features.** Sizes, durations, strings, colours, URLs and preference keys live in
  `MacJi/Constants/`.
- **One job per file**, in the folder that owns that job. Aim for files under 300 lines.
- **Settings survive updates.** Never rename a preference key; add a migration in
  `Settings/SettingsMigrator.swift` instead.
- **Accessibility calls fail often.** Use short timeouts, no force-unwraps or `as!`, and keep
  "missing" distinct from "failed".
- **Comments** use the `////` style described in `CLAUDE.md`, and every new file starts with the
  standard header (`scripts/new-file.sh` writes it).

When you add, move or remove a file, run `scripts/repo-map.py` and write a one-line description for
any entry it marks `TODO: describe`.

## Tests

Tests use Swift Testing (`#expect`) and need macOS 15. Write the fewest tests that protect real
behaviour or a past bug, in pure logic: trigger tracking, key mapping, search ranking, settings
validation, migrations and geometry. Don't test SwiftUI layout or simple getters.

A green test run says nothing about typing in real apps. In your pull request, list the apps you
tried the change in (for example TextEdit, Safari, Notes, an Electron app, Terminal).

## Pull requests

- Keep each pull request to one change, and say **why** in the commit message.
- `scripts/check.sh` and `scripts/test.sh` must pass; CI runs both.
- Update `repo_map.md`, `docs/` and `CHANGELOG.md` (under **Unreleased**) in the same pull request.
- Changed something visible? Run `scripts/make-screenshots.sh`, then `scripts/make-web-assets.sh`,
  and commit the refreshed README and website images.
- No new dependencies, analytics, network calls or permissions without discussing it in an issue
  first.

By contributing, you agree that your contribution is licensed under the [MIT Licence](LICENSE).
