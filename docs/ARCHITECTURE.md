<!--
  ARCHITECTURE.md · MacJi · Created: 2026-11-26
  Layers, data flow, the safety rules behind them, and where each file came from in Octopus.
-->

# Architecture

MacJi is an accessory app (`LSUIElement`, no Dock icon) written in Swift 6 with complete strict
concurrency. UI and Accessibility code runs on the main actor. Its only dependencies are
[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) and
[Sparkle](https://sparkle-project.org).

## Layers

```text
                       ┌──────────────────────────────┐
                       │ App/AppDelegate              │  the only composition root
                       │ creates · wires · start/stop │
                       └──────┬───────────────┬───────┘
          closures + AppSettings publishers   │
         ┌────────────────────┘               └───────────────────┐
┌────────▼─────────────┐   ┌────────────────────┐   ┌─────────────▼──────────┐
│ Features/InlinePanel │   │ Settings/  Updates/│   │ Features/EmojiPicker   │
│ ::  ##  emoticons    │   │ window · migrator  │   │ the popover            │
└────────┬─────────────┘   └─────────┬──────────┘   └─────────────┬──────────┘
         │      never import each other (features know only Shared)│
┌────────▼─────────────────────────────────────────────────────────▼──────────┐
│ Shared/  Glyphs · GlyphUI · TextAliases · MenuKit · Permissions · AX · Log  │
├─────────────────────────────────────────────────────────────────────────────┤
│ Constants/  Keys · Strings · Layout · Motion · Theme · Links · Limits       │
└─────────────────────────────────────────────────────────────────────────────┘
```

- **`App/`** owns launch and reopen policy (`AppLifecycle`), the menu-bar icon
  (`StatusItemController`) and `AppDelegate`, which builds every controller and connects them.
- **`Features/`** hold the two user features. Each exposes `start()`, `stop()`, `setLibrary(_:)`,
  `setAliasCatalog(_:)` and a few closures or methods; neither knows the other exists.
- **`Shared/`** holds what both features use: one generic glyph catalog (emoji, symbols, emoticons,
  your alias outputs), one ranked search, one recents store, the glyph cell and row, the category
  bar, the text-alias model, the panel chrome, the permission machinery and the AX helpers.
- **`Constants/`** holds every literal: preference keys, strings, sizes, durations, colours, URLs and
  limits. Change a number there, not in a feature.

## Launch

1. `applicationWillFinishLaunching` runs `SettingsMigrator.migrate`, then
   `AppSettings.registerDefaults`. Defaults are registered, never written, so a stored user value
   always wins and a downgrade never loses data.
2. `applicationDidFinishLaunching` starts the features and the status item, wires the `AppSettings`
   publishers, loads the three glyph files (`GlyphLibrary`) off the main thread and opens Settings when `AppLifecycle`
   decides to (first launch, icon hidden, or Accessibility missing, but never at login).
3. Opening MacJi again (Finder, Spotlight) always shows Settings. That's the way back in when the
   icon is hidden.

## Inline panel

```text
key-down in any app
  → InlineInputMonitor (session event tap; tiny callback, no AX or window work)
  → InlinePanelController.handleKeyDown
       TextAliasConverter  completes an alias ("->" → "→") on its last key
       TriggerTracker      keeps the last few characters, finds the last trigger + term (::, ##, …)
       EmoticonAutocomplete  else: is the typed run the start of an emoticon? (one set lookup)
       InlinePanelKeys     maps arrows / Return / Shift-Return / Esc / Tab while a panel is open
  → next main-queue turn
       InlinePanelModel   kind's catalog + your alias outputs, filter, selection, copy feedback
       CaretLocator       caret rect once per open (falls back to the pointer)
       InlinePanelPlacement + InlinePanelWindow   non-activating panel under the caret
  → Return: TextInserter deletes what was typed and types the glyph in ≤20-unit chunks
```

- The tap exists only while something needs it (a panel, emoticon autocomplete or aliases) **and**
  Accessibility is granted. Turning all of them off removes it, so nothing watches the keyboard.
- One tap serves all three panels. No trigger may contain another, so the last trigger typed names
  the panel unambiguously; a trigger beats an autocomplete run.
- Keys pass through unless a term is open and the key is a panel key. Return with no results
  passes through, so a line break is never swallowed.
- MacJi's own synthetic keys are tagged and ignored by the tap.

## Emoji picker

`StatusItemController` (click) and the KeyboardShortcuts hot key both call into
`EmojiPickerController`. With the icon visible the popover hangs under it; with the icon hidden it
points at the caret (or the pointer) through `PopoverAnchorWindow`. Emoji, Symbols and Emoticons
tabs (⌘1–⌘3) each search their own catalog with your alias outputs first. Return copies, closes
the popover and hands focus back to the previous app so ⌘V pastes at once. Option-Return copies and
stays open. The hot key uses Carbon's hot-key API and needs no permission.

## Permissions and event-tap safety

These rules come from bugs Octopus shipped and fixed:

- **Revocation.** A tap that macOS no longer trusts blocks every app's input.
  `AXIsProcessTrusted()` keeps answering `true` after revocation inside a running process, so trust
  is checked with a throwaway tap (`EventTapTrust`). While a tap is installed,
  `EventTapRevocationProbe` checks every 0.5 s (the app's only periodic work). Several failures in a
  row (`EventTapRevocationDetector`) make `EventTapPermissionWatch` remove every tap, and
  `AccessibilityRevocationRecovery` relaunches MacJi.
- **Tap re-enable.** `tapDisabledByTimeout` / `ByUserInput` re-enable the tap only after trust is
  confirmed.
- **Secure Input.** While any app holds Secure Event Input, no tap sees keys. `SecureInput` finds
  the app holding it; Settings and a notification say which app it is and how to release it.
- **AX calls fail often.** `CaretLocator` sets a 0.1 s messaging timeout, and `AXValueReader` does
  checked reads (no force casts) that keep "missing" distinct from "failed".
- **Status without polling.** `PermissionStatus` updates from system notifications and app
  activation, never on a timer.

## Settings

`AppSettings` gives each setting a typed property backed by `UserDefaults`, publishes changes, and
falls back to the default at read time when a stored value is invalid, without deleting it.
`SettingsMigrator` runs ordered, idempotent migrations keyed by `settingsSchemaVersion`. It reads only
the persistent domain, so registered defaults can't make a key look already set. Preference key names
and `KeyboardShortcuts.Name` strings are permanent.

## Updates and releases

`UpdateController` wraps Sparkle's standard updater: Check Now, the automatic-check toggle and the
last check date. The feed is `dist/appcast.xml` in this repository; archives are attached to
GitHub Releases of this repository. Releases are signed with the self-signed `MacJi Release`
certificate and EdDSA-signed for Sparkle. See [RELEASING.md](RELEASING.md).

## Glyph data

Three files in `Shared/Glyphs/Resources`, all in gemoji's shape so one decoder reads them:

| File | Script | Source |
|---|---|---|
| `emoji.json` | `scripts/update-emoji-data.py` | gemoji (MIT) |
| `symbols.json` | `scripts/update-symbol-data.py` | Python's `unicodedata` over curated blocks (Unicode License v3) |
| `emoticons.json` | `scripts/update-emoticon-data.py` | wooorm/emoticon and netromdk/kaomojidict (MIT) |

`GlyphLibrary.loadBundled()` decodes them in parallel, off the main thread, into
`GlyphCatalog<Category>`s that precompute lowercase keywords, so `GlyphSearch` allocates nothing per
keystroke. Results are capped (`Limits`).

## Text aliases

`TextAliasCatalog` (built in) and your own aliases (`customTextAliases`, read by
`CustomTextAliasCodec`) meet in `ActiveTextAliases`, where yours win a shared spelling. The composition
root hands the result to the panel's `TextAliasConverter`, and your enabled aliases, turned into an
`AliasCatalog` by `AliasGlyphs`, to both features' search. The editor's rules live in
`CustomTextAliasValidator`.

## Ported from Octopus

MacJi began as a feature of [Octopus](https://github.com/mayank-devac/octopus-mac). Octopus is a git
submodule at `Upstream/octopus`, for reference only and never compiled. MacJi owns its copies, so an
Octopus change can never break the MacJi build. Every ported file names its origin in its header
(`Ported from Octopus:`). `scripts/sync-from-octopus.sh` shows which origins changed since the pinned
commit; `scripts/sync-from-octopus.sh --table` regenerates the table below.

<!-- octopus-table:start -->
| MacJi file | Octopus origin (pinned at `e0d6570`) |
|---|---|
| `MacJi/App/AppDelegate.swift` | [octopus/octopusApp.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/octopusApp.swift) |
| `MacJi/App/MacJiApp.swift` | [octopus/octopusApp.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/octopusApp.swift) |
| `MacJi/App/StatusItemController.swift` | [octopus/UI/EmojiPicker/EmojiPickerController.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerController.swift) |
| `MacJi/Constants/Keys/PreferenceKeys.swift` | [octopus/UI/MacJi/MacJiSettings.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiSettings.swift)<br>[octopus/UI/EmojiPicker/EmojiPickerSettings.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerSettings.swift) |
| `MacJi/Constants/Keys/ShortcutNames.swift` | [octopus/UI/EmojiPicker/EmojiPickerController.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerController.swift) |
| `MacJi/Constants/Layout/EmojiUIMetrics.swift` | [octopus/UI/EmojiPicker/EmojiPickerComponents.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerComponents.swift) |
| `MacJi/Constants/Layout/GuideMetrics.swift` | [octopus/UI/Permissions/AccessibilityPermissionGuideView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityPermissionGuideView.swift)<br>[octopus/UI/Permissions/AccessibilityGuidePlacement.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityGuidePlacement.swift) |
| `MacJi/Constants/Layout/PanelMetrics.swift` | [octopus/UI/MacJi/MacJiView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiView.swift)<br>[octopus/Constants/Layout/WindowMenuMetrics.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/Constants/Layout/WindowMenuMetrics.swift) |
| `MacJi/Constants/Layout/PickerMetrics.swift` | [octopus/UI/EmojiPicker/EmojiPickerView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerView.swift) |
| `MacJi/Constants/Limits/Limits.swift` | [octopus/UI/MacJi/MacJiTriggerTracker.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiTriggerTracker.swift)<br>[octopus/UI/MacJi/MacJiSearch.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiSearch.swift)<br>[octopus/UI/MacJi/MacJiSettings.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiSettings.swift)<br>[octopus/UI/EmojiPicker/EmojiPickerSettings.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerSettings.swift) |
| `MacJi/Constants/Motion/PanelMotion.swift` | [octopus/Constants/Motion/MenuMotion.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/Constants/Motion/MenuMotion.swift)<br>[octopus/UI/MacJi/MacJiController.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiController.swift) |
| `MacJi/Constants/Motion/Timing.swift` | [octopus/UI/Permissions/EventTapRevocationProbe.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/EventTapRevocationProbe.swift)<br>[octopus/UI/Permissions/AccessibilityPermissionGuide.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityPermissionGuide.swift)<br>[octopus/UI/Permissions/AccessibilityRevocationRecovery.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityRevocationRecovery.swift) |
| `MacJi/Constants/Strings/PanelStrings.swift` | [octopus/UI/MacJi/MacJiView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiView.swift) |
| `MacJi/Constants/Strings/PermissionStrings.swift` | [octopus/UI/Permissions/AccessibilityPermissionGuideView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityPermissionGuideView.swift)<br>[octopus/UI/MacJi/MacJiSecureInput.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiSecureInput.swift)<br>[octopus/UI/MacJi/MacJiSecureInputNotifier.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiSecureInputNotifier.swift) |
| `MacJi/Constants/Strings/PickerStrings.swift` | [octopus/UI/EmojiPicker/EmojiPickerView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerView.swift)<br>[octopus/UI/EmojiPicker/EmojiPickerModel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerModel.swift) |
| `MacJi/Constants/Theme/Palette.swift` | [octopus/Constants/Theme/MenuPalette.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/Constants/Theme/MenuPalette.swift) |
| `MacJi/Features/EmojiPicker/EmojiPickerCategoryBar.swift` | [octopus/UI/EmojiPicker/EmojiPickerView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerView.swift) |
| `MacJi/Features/EmojiPicker/EmojiPickerController.swift` | [octopus/UI/EmojiPicker/EmojiPickerController.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerController.swift) |
| `MacJi/Features/EmojiPicker/EmojiPickerKeys.swift` | [octopus/UI/EmojiPicker/EmojiPickerKeys.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerKeys.swift) |
| `MacJi/Features/EmojiPicker/EmojiPickerModel.swift` | [octopus/UI/EmojiPicker/EmojiPickerModel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerModel.swift) |
| `MacJi/Features/EmojiPicker/EmojiPickerView.swift` | [octopus/UI/EmojiPicker/EmojiPickerView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerView.swift) |
| `MacJi/Features/InlinePanel/InlineInputMonitor.swift` | [octopus/UI/MacJi/MacJiInputMonitor.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiInputMonitor.swift) |
| `MacJi/Features/InlinePanel/InlinePanelController.swift` | [octopus/UI/MacJi/MacJiController.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiController.swift) |
| `MacJi/Features/InlinePanel/InlinePanelKeys.swift` | [octopus/UI/MacJi/MacJiKeys.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiKeys.swift) |
| `MacJi/Features/InlinePanel/InlinePanelModel.swift` | [octopus/UI/MacJi/MacJiModel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiModel.swift) |
| `MacJi/Features/InlinePanel/InlinePanelPlacement.swift` | [octopus/UI/MacJi/MacJiPanel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiPanel.swift) |
| `MacJi/Features/InlinePanel/InlinePanelView.swift` | [octopus/UI/MacJi/MacJiView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiView.swift) |
| `MacJi/Features/InlinePanel/InlinePanelWindow.swift` | [octopus/UI/MacJi/MacJiPanel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiPanel.swift) |
| `MacJi/Features/InlinePanel/InlineTrigger.swift` | [octopus/UI/MacJi/MacJiSettings.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiSettings.swift) |
| `MacJi/Features/InlinePanel/SecureInputNotifier.swift` | [octopus/UI/MacJi/MacJiSecureInputNotifier.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiSecureInputNotifier.swift) |
| `MacJi/Features/InlinePanel/TextInserter.swift` | [octopus/UI/MacJi/MacJiTextInserter.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiTextInserter.swift) |
| `MacJi/Features/InlinePanel/TriggerTracker.swift` | [octopus/UI/MacJi/MacJiTriggerTracker.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiTriggerTracker.swift) |
| `MacJi/Settings/LoginItem.swift` | [octopus/UI/Preferences/PreferencesGeneralView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Preferences/PreferencesGeneralView.swift) |
| `MacJi/Shared/AX/AXValueReader.swift` | [octopus/UI/MacJi/MacJiCaretLocator.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiCaretLocator.swift) |
| `MacJi/Shared/AX/CaretLocator.swift` | [octopus/UI/MacJi/MacJiCaretLocator.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiCaretLocator.swift) |
| `MacJi/Shared/GlyphUI/CopiedBadge.swift` | [octopus/UI/EmojiPicker/EmojiPickerComponents.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerComponents.swift)<br>[octopus/UI/EmojiPicker/EmojiPickerView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerView.swift)<br>[octopus/UI/MacJi/MacJiView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiView.swift) |
| `MacJi/Shared/GlyphUI/GlyphCell.swift` | [octopus/UI/EmojiPicker/EmojiPickerComponents.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerComponents.swift) |
| `MacJi/Shared/GlyphUI/KeyHint.swift` | [octopus/UI/EmojiPicker/EmojiPickerComponents.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerComponents.swift) |
| `MacJi/Shared/Glyphs/Glyph.swift` | [octopus/UI/EmojiPicker/EmojiCatalog.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiCatalog.swift) |
| `MacJi/Shared/Glyphs/GlyphCatalog.swift` | [octopus/UI/EmojiPicker/EmojiCatalog.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiCatalog.swift) |
| `MacJi/Shared/Glyphs/GlyphCategory.swift` | [octopus/UI/EmojiPicker/EmojiCatalog.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiCatalog.swift) |
| `MacJi/Shared/Glyphs/GlyphClipboard.swift` | [octopus/UI/MacJi/MacJiModel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiModel.swift)<br>[octopus/UI/EmojiPicker/EmojiPickerModel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerModel.swift) |
| `MacJi/Shared/Glyphs/GlyphGrid.swift` | [octopus/UI/MacJi/MacJiModel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiModel.swift)<br>[octopus/UI/EmojiPicker/EmojiPickerModel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerModel.swift) |
| `MacJi/Shared/Glyphs/GlyphRecents.swift` | [octopus/UI/EmojiPicker/EmojiPickerSettings.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerSettings.swift)<br>[octopus/UI/EmojiPicker/EmojiPickerModel.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiPickerModel.swift) |
| `MacJi/Shared/Glyphs/GlyphSearch.swift` | [octopus/UI/MacJi/MacJiSearch.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiSearch.swift)<br>[octopus/UI/EmojiPicker/EmojiCatalog.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/EmojiPicker/EmojiCatalog.swift) |
| `MacJi/Shared/MenuKit/MenuAppearModifier.swift` | [octopus/UI/MenuKit/MenuAppearModifier.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MenuKit/MenuAppearModifier.swift) |
| `MacJi/Shared/MenuKit/MenuCardBackground.swift` | [octopus/UI/MenuKit/MenuCardBackground.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MenuKit/MenuCardBackground.swift) |
| `MacJi/Shared/MenuKit/MenuGridNavigator.swift` | [octopus/UI/MenuKit/MenuGridNavigator.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MenuKit/MenuGridNavigator.swift) |
| `MacJi/Shared/MenuKit/MenuKey.swift` | [octopus/UI/MenuKit/MenuKey.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MenuKit/MenuKey.swift) |
| `MacJi/Shared/MenuKit/MenuPanelFader.swift` | [octopus/UI/MenuKit/MenuPanelFader.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MenuKit/MenuPanelFader.swift) |
| `MacJi/Shared/MenuKit/MenuPressButtonStyle.swift` | [octopus/UI/MenuKit/MenuPressButtonStyle.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MenuKit/MenuPressButtonStyle.swift) |
| `MacJi/Shared/MenuKit/MenuShadowMargin.swift` | [octopus/UI/MenuKit/MenuShadowMargin.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MenuKit/MenuShadowMargin.swift) |
| `MacJi/Shared/Permissions/AccessibilityGrantReset.swift` | [octopus/UI/Permissions/AccessibilityGrantReset.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityGrantReset.swift) |
| `MacJi/Shared/Permissions/AccessibilityGuidePlacement.swift` | [octopus/UI/Permissions/AccessibilityGuidePlacement.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityGuidePlacement.swift) |
| `MacJi/Shared/Permissions/AccessibilityPermissionGuide.swift` | [octopus/UI/Permissions/AccessibilityPermissionGuide.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityPermissionGuide.swift) |
| `MacJi/Shared/Permissions/AccessibilityPermissionGuideView.swift` | [octopus/UI/Permissions/AccessibilityPermissionGuideView.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityPermissionGuideView.swift) |
| `MacJi/Shared/Permissions/AccessibilityRevocationRecovery.swift` | [octopus/UI/Permissions/AccessibilityRevocationRecovery.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/AccessibilityRevocationRecovery.swift) |
| `MacJi/Shared/Permissions/EventTapPermissionWatch.swift` | [octopus/UI/Permissions/EventTapPermissionWatch.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/EventTapPermissionWatch.swift) |
| `MacJi/Shared/Permissions/EventTapRevocationProbe.swift` | [octopus/UI/Permissions/EventTapRevocationProbe.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/EventTapRevocationProbe.swift) |
| `MacJi/Shared/Permissions/EventTapTrust.swift` | [octopus/UI/Permissions/EventTapTrust.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/Permissions/EventTapTrust.swift) |
| `MacJi/Shared/Permissions/SecureInput.swift` | [octopus/UI/MacJi/MacJiSecureInput.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/UI/MacJi/MacJiSecureInput.swift) |
| `MacJi/Updates/UpdateController.swift` | [octopus/Updates/SparkleConnector.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopus/Updates/SparkleConnector.swift) |
| `MacJiTests/Features/EmojiPicker/EmojiPickerTests.swift` | [octopusTests/EmojiPickerTests.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopusTests/EmojiPickerTests.swift) |
| `MacJiTests/Features/InlinePanel/InlinePanelTests.swift` | [octopusTests/MacJiTests.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopusTests/MacJiTests.swift) |
| `MacJiTests/Shared/AX/CaretLocatorTests.swift` | [octopusTests/MacJiTests.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopusTests/MacJiTests.swift) |
| `MacJiTests/Shared/Glyphs/GlyphDataTests.swift` | [octopusTests/EmojiPickerTests.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopusTests/EmojiPickerTests.swift)<br>[octopusTests/MacJiTests.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopusTests/MacJiTests.swift) |
| `MacJiTests/Shared/Permissions/EventTapRevocationDetectorTests.swift` | [octopusTests/EventTapRevocationDetectorTests.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopusTests/EventTapRevocationDetectorTests.swift) |
| `MacJiTests/Shared/Permissions/SecureInputTests.swift` | [octopusTests/MacJiTests.swift](https://github.com/mayank-devac/octopus-mac/blob/e0d657082288ff25c63494401f3597fbe35aeb5e/octopusTests/MacJiTests.swift) |
<!-- octopus-table:end -->
