# CLAUDE.md

Guidance for Claude Code (and any developer) working in this repository.
**Read `repo_map.md` first** to find where things live.

## Project

MacJi is an open-source macOS menu-bar app for emoji. Its features:

1. **Inline panel** – type the trigger (default `::`) plus a term in any app (`::roc`) and an emoji
   panel opens under the caret. Return replaces `::roc` with the emoji, Shift-Return copies it,
   Esc closes, Space or punctuation closes it as you keep typing.
2. **Emoji picker** – a menu-bar popover (also opened by a global shortcut) with search,
   categories, recents and keyboard navigation, on Emoji / Symbols / Emoticons tabs (⌘1–⌘3,
   `PickerTab`; `pickerShowsSymbols`, `pickerShowsEmoticons`, last tab in `pickerLastTab`).
   Return copies, Option-Return copies and stays open.
3. **Frequent-emoji ranking** – the inline panels list used glyphs first, most used first, when they
   match by prefix (`GlyphSearch.ranked(useCounts:)`, counts in `GlyphRecents`). Setting
   `rankFrequentlyUsedEmoji`, default on. The picker keeps the plain ranking.
4. **Text aliases** – `->` becomes →, `(c)` ©, `:)` 🙂 as the last character is typed
   (`TextAliasCatalog` → `ActiveTextAliases` → `TextAliasConverter`, run from the event tap's key
   path), whether or not a panel is on. Settings › Aliases + Customize… (`convertTextAliases`,
   `disabledTextAliases`, registered default = the emoticons via `TextAliasCatalog.offByDefault`;
   built-ins hidden from the page in `hiddenTextAliases`). Emoticon spellings come from wooorm/emoticon (MIT,
   `LICENSES/emoticon-MIT.txt`), filtered as `docs/convert-symbols.md` explains. Alias IDs are
   stored, so they are permanent; keep `docs/convert-symbols.md` in step with the catalog.
5. **Symbol panel** – `##term` (`symbolPanelEnabled`, `symbolPanelTrigger`) opens the same inline
   panel on `symbols.json` (2,166 Unicode symbols, `scripts/update-symbol-data.py`) with a category
   bar that Tab cycles (`InlinePanelKind.symbols`, shared `CategoryBar`).
6. **Emoticons** – `emoticons.json` (wooorm/emoticon ASCII emoticons + netromdk/kaomojidict kaomoji,
   `scripts/update-emoticon-data.py`). Autocomplete (`EmoticonAutocomplete`, shown as "Suggest as
   you type") opens the panel when the
   typed run is the start of an emoticon (`emoticonAutocompleteLength`, default 2, 0 = Off); an
   optional trigger (`emoticonPanelTrigger`, blank by default) searches by name. `emoticonsEnabled`
   switches both.
7. **Custom aliases** – your own aliases: a name, several spellings, several outputs (first is typed)
   in `customTextAliases` (`CustomTextAliasCodec`, rules in `CustomTextAliasValidator`), edited on
   the Aliases page (`AliasEditorSheet`). Yours win over a built-in spelling. Their outputs show first
   in every panel's and the picker's search, by name or spelling (`AliasGlyphs`,
   `showAliasesInSearch`).
8. **Send Feedback** – Settings › About › Send Feedback… (`FeedbackSheet`): Bug / Feature Idea /
   Other and a message, sent by the user's mail app to `AppLinks.feedbackEmail` or as a prefilled
   GitHub issue form (`FeedbackReport`). MacJi itself sends nothing. Technical details
   (`FeedbackDetails`) are opt-in and anonymous.

## Feedback rules

- **Feedback stays anonymous and opt-in.** `FeedbackDetails` holds versions and permission state
  only; never add a device identifier, model, locale, app names, settings, logs or typed text. A
  new row must be shown in the sheet's preview and listed in `PRIVACY.md`.
- **Issue-form field ids are permanent.** `FeedbackReport.IssueForm` names must match the `id:`s in
  `.github/ISSUE_TEMPLATE/`; `FeedbackReportTests` reads the forms to check.

- macOS **14.6+** for the app, **15+** for the test target. Swift 6 language mode with complete
  strict concurrency. SwiftUI + AppKit. Accessory app (`LSUIElement`), no Dock icon.
- Dependencies (Swift packages, nothing else): `KeyboardShortcuts`, `Sparkle`.
- Derived from **Octopus** (`Upstream/octopus`, GitHub `mayank-devac/octopus-mac`). MacJi owns
  its ported copies; Octopus is reference only and is never compiled.
- The app needs **Accessibility** permission. The App Sandbox is off because the event tap and AX need it off.

## How to behave

Act like a senior developer who owns this repo for years.

- **Understand first.** Read the surrounding code, `repo_map.md` and the related tests before
  editing. Trace the whole call chain before calling something a bug or a fix.
- **Smallest correct change.** Do what was asked and nothing more. No drive-by refactors, new
  modes or speculative abstractions. If scope needs to grow, say so and ask.
- **Root cause over patches.** Fix the cause, not the symptom. Reuse existing helpers instead of
  adding near-duplicates.
- **Clean repo.** No dead code, commented-out code, debug prints or stray files. Scratch files go
  in the scratchpad, not the repo. Focused commits whose message says *why*.
- **Safe by default.** Handle failure paths explicitly (AX calls fail often), no force-unwraps,
  keep UI and AX on the main actor, never weaken permission or signing handling.
- **Test what you change** (see Testing rule).
- **A new feature updates the docs in the same change:** the feature list under Project and any
  rule it adds in this file, the README (Features, Usage, Settings, and Privacy if it stores
  something), `PRIVACY.md` when it stores data, and `repo_map.md`.
- **Be honest and concise.** Report exactly what was and was not verified.
- **Ask before risky actions:** deleting files, rewriting history, pushing, creating GitHub repos or
  releases, generating signing keys, touching the Keychain, changing signing, entitlements, the
  update feed, the bundle ID or licences.
- **No session links.** Never add a Claude Code session link to commits, PRs or comments.
- Read only what you need; pipe long build/test output through `tail`/`grep`.

## Commands

```sh
./build.sh                          # build Debug into .build/DerivedData, quit + relaunch MacJi
CONFIGURATION=Release ./build.sh    # same for Release
scripts/test.sh                     # all tests; fails if zero tests ran
scripts/test.sh InlinePanelTests    # one suite
scripts/test.sh InlinePanelTests/triggerInsideWordIsIgnored   # one test ("()" is added)
scripts/make-screenshots.sh         # regenerate the README images and GIFs after a visible UI change
scripts/check.sh                    # repo hygiene (run before every commit; CI runs it)
```

- Tests use **Swift Testing** (`#expect`), not XCTest. A filter that matches nothing runs **zero
  tests and still "passes"** in `xcodebuild`. `scripts/test.sh` refuses that; when you call
  `xcodebuild` yourself, confirm the test names appear in the output. A Swift Testing filter for one
  test needs the trailing `()`; `test.sh` adds it.
- `Config/Base.xcconfig` holds the version, build number and bundle ID and optionally includes the
  git-ignored `Config/LocalSigning.xcconfig` (copy `LocalSigning.example.xcconfig`).
- There is no linter; `scripts/check.sh` is the hygiene gate.

## Scripts

| Script | What it does |
|---|---|
| `build.sh` | Build Debug (or `CONFIGURATION=Release`), quit the running MacJi, relaunch, print the running `.app` path |
| `scripts/setup.sh` | First-time setup of a fresh clone; reports (never creates) the certificate and Sparkle key |
| `scripts/test.sh [Suite[/test]]` | Run tests, print summary + failures, fail when zero tests ran |
| `scripts/check.sh` | Headers, banned calls, inline UserDefaults keys, repo map ↔ tree, tracked secrets |
| `scripts/new-file.sh <Path.swift> "<job>"` | New Swift file with the standard header; refuses to overwrite |
| `scripts/repo-map.py` | Regenerate the tree in `repo_map.md`, keeping descriptions; flags `TODO: describe` |
| `scripts/bump-version.sh <major\|minor\|patch>` | Bump version + build in `Base.xcconfig`, add a `CHANGELOG.md` heading |
| `scripts/release.py` | Full signed release (see `docs/RELEASING.md`); `--dry-run` publishes nothing |
| `scripts/verify-update.swift` | Check an archive's EdDSA signature, version and appcast entry |
| `scripts/make-icon.sh <1024.png>` | Every AppIcon size + `Contents.json` |
| `scripts/make-screenshots.sh` | README images and typing GIFs from the real views, light + dark, into `assets/screenshots_by_agent/` (needs ffmpeg) |
| `scripts/make-web-assets.sh` | Website copies in `WEB/assets/`: WebP screenshots and icon, emoji data (needs cwebp) |
| `scripts/make-placeholder-icon.swift` | Draw the placeholder 1024 px icon (yellow face on blue tile) |
| `scripts/update-emoji-data.py <gemoji.json>` | Strip a gemoji `emoji.json` to the fields MacJi reads |
| `scripts/update-symbol-data.py` | Build `symbols.json` from Python's Unicode names (curated blocks, keywords such as `rarr`) |
| `scripts/update-emoticon-data.py <index.js> <kaomoji.json>` | Build `emoticons.json` from wooorm/emoticon and netromdk/kaomojidict (parsed as data, never run) |
| `scripts/sync-from-octopus.sh [file]` | Update the Octopus submodule and diff every ported file's origin |
| `scripts/reset-permissions.sh` | Dev only: reset MacJi's Accessibility grant and relaunch (asks first) |
| `scripts/clean.sh` | Remove build output and release artefacts (shows the list, asks first) |

Shared values (bundle ID, scheme, paths, certificate name, repos) live in `scripts/config.sh`
and `scripts/config.py`; never copy them into a script.

## Architecture

`MacJi/App/MacJiApp.swift` is the SwiftUI `App`; its `AppDelegate` is the **only composition root**.
It creates every controller, wires them together with closures and Combine subscriptions on
`AppSettings`, and mirrors start/stop in `applicationDidFinishLaunching` / `applicationWillTerminate`.
Features never import or reference each other.

| Folder | What belongs there |
|---|---|
| `MacJi/App/` | App entry, composition root, launch/reopen policy, the menu-bar status item |
| `MacJi/Features/InlinePanel/` | The `::term` / `##term` / emoticon panel: event tap, trigger tracking, emoticon autocomplete, keys, model, window, placement, view, text insertion, Secure Input, alias conversion |
| `MacJi/Features/EmojiPicker/` | The picker popover: controller, model, tabs, view, keys, anchor for the hidden-icon case |
| `MacJi/Shared/Glyphs/` | Glyph model, generic catalog, ranked search, recents store, clipboard, grid rows, the bundled data files — used by both features |
| `MacJi/Shared/GlyphUI/` | Glyph cell and row, key hints, "Copied" badge — reusable glyph views |
| `MacJi/Shared/TextAliases/` | Alias model, built-in catalog, your aliases' storage and rules, active set, search catalog |
| `MacJi/Shared/MenuKit/` | Panel chrome and keyboard helpers: card background, shadow margin, appear/fade, grid navigation, category bar |
| `MacJi/Shared/Permissions/` | Accessibility status, permission guide, event-tap trust and revocation recovery |
| `MacJi/Shared/AX/` | Checked AX value reads and the caret locator |
| `MacJi/Shared/Logging/` | `os.Logger` categories |
| `MacJi/Settings/` | Settings window, one view per section, `AppSettings`, `SettingsMigrator`, login item |
| `MacJi/Updates/` | Sparkle `UpdateController` |
| `MacJi/Constants/` | `Keys/`, `Strings/`, `Layout/`, `Motion/`, `Theme/`, `Links/` — every literal lives here |
| `MacJi/Resources/` | `Assets.xcassets`, `Info.plist`, `MacJi.entitlements` |
| `MacJiTests/` | Swift Testing suites, mirroring the source folders |
| `Config/` | `Base.xcconfig` (version, build, bundle ID), signing example |
| `scripts/` | Automation (see Scripts) |
| `docs/` | `ARCHITECTURE.md`, `RELEASING.md`, `icon-prompt.md`, `convert-symbols.md` |
| `dist/` | Sparkle feed `appcast.xml` (served from `main`) and the last release's signing identity |
| `Upstream/octopus/` | Octopus submodule, reference only |

## Comment style — the "Mayank `////` style"

```swift
////////////////////
//// Build the display order
/// Keep apps with open windows together at the top.
// Place windowless apps last so they are easy to distinguish.

func displayOrder() -> [String] {
    ["Active apps", "Windowless apps"]
}

//// Preserve this order so the sidebar is easy to scan.
//////////////////
```

- `////////////////////` opens a substantial section, `////` is its title, `///` the main
  explanation, `//` the detail; a `////` closing line and `//////////////////` end the section.
- Use it for long functions and substantial blocks, not as boilerplate around every tiny function.
- No trailing end-of-line comments, no comments that restate the code.
- Shell and Python scripts use the same shape with `#` (`####################`, `####`, `###`, `#`).

## File header rule

Every new file starts with:

```swift
//
//  FileName.swift
//  MacJi
//
//  Created: YYYY-MM-DD
//  One or two lines on this file's single responsibility.
//  Ported from Octopus: octopus/UI/MacJi/FileName.swift      ← only when ported
//
```

`scripts/new-file.sh` writes it for you. `scripts/sync-from-octopus.sh` reads the
`Ported from Octopus:` lines, so keep the path exact (several origins: comma-separated).

## Constants rule

No magic numbers, user-visible strings, colours, durations, URLs or UserDefaults keys inline in
features. They live in `MacJi/Constants/<Kind>/` (`Keys/`, `Strings/`, `Layout/`, `Motion/`,
`Theme/`, `Links/`). Key codes of the keyboard map are named in `MenuKey`/`InlinePanelKeys`.

## Folder rule

One responsibility per file, in the folder that owns that responsibility. Split a file when it
gains a second job. Aim for files under 300 lines. Every component (cell, grid, search field,
key handling, panel chrome, permission row, settings row) takes small inputs and closures, so it
works in any UI and never reaches into a specific controller.

## Settings survive updates

- Defaults are only ever **registered** (`AppSettings.registerDefaults()`), never written at launch,
  so a stored user value always wins. Never call `removePersistentDomain`, or `removeObject` on
  startup, outside an explicit user "Reset" button or a migration.
- **The bundle ID never changes** (`io.github.mayank-devac.macji`). Preferences, the login item and
  the Accessibility grant are all keyed to it. Debug builds use `<id>.debug` so they never touch
  a user install.
- **Preference key names are permanent**, including `KeyboardShortcuts.Name` strings (the package
  stores the shortcut under that name). To rename or reshape a setting, add a migration in
  `Settings/SettingsMigrator.swift`; never just change the key.
- An invalid stored value falls back to its default **at read time**, for that key only. It is
  never deleted, so a value written by a newer MacJi survives a downgrade.

## Glyph, trigger and alias rules

- **No trigger may contain another** (`InlineTrigger.problem(with:for:others:)`), so one keystroke
  never opens two panels. Only the emoticon trigger may be blank. A clashing stored trigger falls
  back at read time, in panel order.
- **The tap runs while anything needs it**: a panel, emoticon autocomplete or aliases
  (`InlinePanelConfiguration.watchesTyping` or converting aliases). With all off it is removed.
- **Glyph text identity is canonical.** Swift compares strings by canonical equivalence, so the data
  scripts drop characters that normalise to another (Ω OHM SIGN) and dedupe on NFC.
- **Synthetic text goes in ≤20 UTF-16-unit chunks** on character boundaries (`TextInserter.chunks`);
  longer key events are truncated by apps.
- **Custom alias IDs start with `custom-`**; entries `CustomTextAliasCodec` can't read are kept and
  written back, never dropped. `CustomAliasKeys` field names are permanent.
- **Recents are one store** (`emojiRecents`, up to 72); each picker tab shows its own 24 by catalog
  lookup, so an older MacJi still reads them.

## Hard-won rules (carried over from Octopus)

- **Event-tap revocation.** A tap that macOS no longer trusts blocks every app's input.
  Every tap registers with `EventTapPermissionWatch`; on confirmed revocation all taps are removed
  and MacJi relaunches (`AccessibilityRevocationRecovery`). `AXIsProcessTrusted()` keeps returning
  true after revocation inside a running app, so trust is probed with a throwaway tap. The probe's
  0.5 s timer is the one deliberate periodic task, and it runs only while a tap is installed.
- **Tap hygiene.** The tap callback does no AX or window work and never blocks; panel work is
  queued to the next main-queue turn. `tapDisabledByTimeout`/`ByUserInput` re-enable only after
  trust is confirmed.
- **Secure Input.** While any app holds Secure Event Input no tap sees keys. Detect it
  (`SecureInput`), tell the user which app holds it and how to release it; never fail silently.
- **AX calls fail often.** Short messaging timeouts (0.1 s), no force-unwrap or `as!` of AX/CF
  values (use `AXValueReader`), keep "missing" distinct from "failed".
- **Caret fallback.** Many apps (Electron, web views, terminals) report no caret bounds; the panel
  then opens at the pointer.
- **Never weaken permission or signing handling** to make something "work".
- **Verification honesty.** A green build or test run proves nothing about typing, caret, panel or
  popover behaviour in real apps. Say what was and wasn't checked live, and check which
  `MacJi.app` is actually running (`build.sh` prints it).
- Before removing or moving a symbol, search all references.
- Octopus also contains this feature. Turn MacJi off in Octopus while testing MacJi, or both open a panel.

## Syncing a fix from Octopus

1. `scripts/sync-from-octopus.sh` (runs `git submodule update --remote Upstream/octopus` and diffs
   every ported file's origin since the pinned commit).
2. Port the change by hand into the MacJi file named in the output, keeping MacJi's constants and naming.
3. Commit the submodule bump together with the port, then refresh the table in `docs/ARCHITECTURE.md`
   (`scripts/sync-from-octopus.sh --table`).

## Release rules

- Follow `docs/RELEASING.md`; `scripts/release.py` does every step and stops on the first failure.
- Include at least one relevant emoji in every release title or announcement, commit message, and pull request title or description. Keep version tags and other machine-readable identifiers emoji-free.
- Releases are signed with the self-signed **`MacJi Release`** certificate, never ad-hoc, and are not
  notarized. Its name and certificate must never change.
- Updates are EdDSA-signed by Sparkle. Never change the EdDSA key and the signing certificate in the same release.
- **Never commit signing material, `.p12` files or the Sparkle private key.** Never print the private key.
- Nothing is pushed, tagged or released without Mayank's OK.

## Repo map rule

Read `repo_map.md` first to find where things live. Update it in the same change whenever a file
or folder is added, moved, renamed or removed (`scripts/repo-map.py` regenerates the tree;
`scripts/check.sh` fails when they disagree).

## Testing rule

Write only necessary tests: real behaviour or past bugs, the least amount that protects them.
Pure logic only (trigger tracking, key mapping, search ranking, settings validation, migrations,
geometry). No tests for trivial getters, SwiftUI layout or what the compiler guarantees.
Tests mirror source folders and are named for the behaviour, not the method. Keep state changes
outside `#expect(...)` (Swift Testing macros capture immutably).
`MacJiTests/Screenshots/` is the one exception: an opt-in image generator, skipped unless
`scripts/make-screenshots.sh` runs it (it shows as "1 skipped" in `scripts/test.sh`).

## Memory rule

At the end of every session run `/postsession` to save memory, decisions, done work and open tasks
to context-eng. During work, save decisions and mistakes with `memory_create` (one claim each,
project scope `/Users/mayank/Desktop/mac/MacJi`).
