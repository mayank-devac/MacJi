# Repo map

Where everything lives. Update it in the same change whenever a file or folder is added, moved,
renamed or removed. `scripts/repo-map.py` regenerates the tree below from disk and keeps the
descriptions; `scripts/check.sh` fails when the tree and the disk disagree.

## Where do I change…?

| I want to change… | File |
|---|---|
| Trigger defaults (`::`, `##`, blank emoticon trigger) or their rules | `MacJi/Constants/Keys/PreferenceKeys.swift` (`PreferenceDefaults`), `MacJi/Features/InlinePanel/InlineTrigger.swift` |
| Emoticon autocomplete rules (deny list, minimum length) | `MacJi/Features/InlinePanel/EmoticonAutocomplete.swift`, `MacJi/Constants/Limits/Limits.swift` |
| Symbol or emoticon categories and their icons | `MacJi/Shared/Glyphs/SymbolCategory.swift`, `MacJi/Shared/Glyphs/EmoticonCategory.swift` (match the data scripts) |
| Rules and limits for your own aliases | `MacJi/Shared/TextAliases/CustomTextAliasValidator.swift`, `MacJi/Constants/Limits/Limits.swift` |
| How your aliases are stored | `MacJi/Shared/TextAliases/CustomTextAliasCodec.swift`, `CustomAliasKeys` in `MacJi/Constants/Keys/PreferenceKeys.swift` (permanent) |
| Copy-close delay, fades, springs, name-reveal delay | `MacJi/Constants/Motion/PanelMotion.swift` |
| Inline panel size, grid columns, caret gap | `MacJi/Constants/Layout/PanelMetrics.swift` |
| Picker size and columns | `MacJi/Constants/Layout/PickerMetrics.swift` |
| Result caps, recents count, trigger length | `MacJi/Constants/Limits/Limits.swift` |
| Revocation probe, recovery and AX timeouts | `MacJi/Constants/Motion/Timing.swift` |
| Settings window width / height limits | `MacJi/Constants/Layout/SettingsMetrics.swift` |
| Colours | `MacJi/Constants/Theme/Palette.swift` |
| Any user-visible text | `MacJi/Constants/Strings/*.swift` |
| Preference keys and their defaults | `MacJi/Constants/Keys/PreferenceKeys.swift` |
| Default picker shortcut | `MacJi/Constants/Keys/ShortcutNames.swift` |
| Renaming or reshaping a stored setting | `MacJi/Settings/SettingsMigrator.swift` (add a migration) |
| Update feed URL / public EdDSA key | `MacJi/Resources/Info.plist`, mirrored by `SOURCE_REPO` in `scripts/config.sh` and `FEED_URL` in `scripts/config.py` |
| Version and build number | `Config/Base.xcconfig` (via `scripts/bump-version.sh`) |
| Bundle ID (never after the first release) | `Config/Base.xcconfig` and `scripts/config.sh` |
| GitHub / Octopus / licence links, feedback email | `MacJi/Constants/Links/AppLinks.swift` |
| App icon | `scripts/make-icon.sh <1024.png>` → `MacJi/Resources/Assets.xcassets/AppIcon.appiconset` |
| Menu-bar icon | `MacJi/Constants/Theme/SymbolNames.swift` (`menuBar`) |
| Text aliases (`->` → `→`, `:)` → 🙂) | `MacJi/Shared/TextAliases/TextAliasCatalog.swift`, documented in `docs/convert-symbols.md` |
| Emoji data | `scripts/update-emoji-data.py` → `MacJi/Shared/Glyphs/Resources/emoji.json` |
| Symbol data (names, keywords like `rarr`) | `scripts/update-symbol-data.py` → `MacJi/Shared/Glyphs/Resources/symbols.json` |
| Emoticon data (ASCII faces, kaomoji) | `scripts/update-emoticon-data.py <index.js> <kaomoji.json>` → `MacJi/Shared/Glyphs/Resources/emoticons.json` |
| Release steps | `docs/RELEASING.md`, `scripts/release.py` |
| README screenshots and GIFs | `scripts/make-screenshots.sh` → `assets/screenshots_by_agent/` (scenes in `MacJiTests/Screenshots/`) |
| Website (GitHub Pages) | `WEB/` (deployed by `.github/workflows/pages.yml`; images via `scripts/make-web-assets.sh`) |
| Shared script values (bundle ID, cert name, repos) | `scripts/config.sh`, `scripts/config.py` |

## Tree

<!-- repo-map:tree:start -->
```text
.github/ — GitHub configuration
  ISSUE_TEMPLATE/ — issue forms
    bug_report.yml — bug report form; the app prefills its version fields
    config.yml — issue chooser; security reports go to the private advisory form
    feature_request.yml — feature request form
  workflows/ — CI
    ci.yml — build, check.sh and test.sh on macos-latest, unsigned
    pages.yml — deploy WEB/ to GitHub Pages on pushes to main that touch it
.gitignore — build output, local signing, secrets, the one-shot prompt
.gitmodules — the Upstream/octopus submodule
CHANGELOG.md — dated release notes; fed into the appcast
CLAUDE.md — rules for agents and developers; read first
CONTRIBUTING.md — how to build, test and send changes
Config/ — build settings
  Base.xcconfig — version, build number, bundle ID, Swift and warning settings (single source)
  LocalSigning.example.xcconfig — copy to LocalSigning.xcconfig for a stable local signing identity
LICENSE — MIT licence for MacJi
LICENSES/ — notices for code and data MacJi includes
  Octopus-MIT.txt — original Octopus MIT notice (required)
  emoticon-MIT.txt — wooorm/emoticon licence (source of the emoticon aliases)
  gemoji-MIT.txt — gemoji emoji data licence
  kaomojidict-MIT.txt — netromdk/kaomojidict licence (source of the kaomoji)
  unicode-LICENSE.txt — Unicode License v3 (symbol names and code points)
MacJi/ — the app target (synchronised folder: new files are picked up automatically)
  App/ — entry point and composition root
    AppDelegate.swift — composition root: creates, wires, starts and stops every controller
    AppLifecycle.swift — when to open Settings on launch and reopen; login-item launch detection
    MacJiApp.swift — SwiftUI App; routes ⌘, to the Settings window
    StatusItemController.swift — menu-bar icon: click opens the picker, right-click menu
  Constants/ — every literal lives here
    Keys/ — stored names
      GlyphResources.swift — bundled glyph data file names (emoji, symbols, emoticons)
      PreferenceKeys.swift — UserDefaults keys and their registered defaults (keys are permanent)
      ShortcutNames.swift — KeyboardShortcuts names and the default picker shortcut
    Layout/ — sizes and spacing
      EmojiUIMetrics.swift — shared emoji views: grid cell, footer keycaps, Copied badge
      GuideMetrics.swift — drag-to-allow Accessibility guide beside System Settings
      PanelMetrics.swift — inline panel card, grid, caret gap, shadow margin
      PickerMetrics.swift — picker popover size, grid, recents limit
      SettingsMetrics.swift — Settings window size and row spacing
    Limits/ — caps
      Limits.swift — trigger and query length, result counts, recents count, caret height
    Links/ — URLs
      AppLinks.swift — GitHub, new issue, feedback email, Octopus, licence, releases and System Settings URLs
    Motion/ — timing
      PanelMotion.swift — springs, fades, copy-close and name-reveal delays
      Timing.swift — non-animation intervals: revocation probe, guide polling, recovery, AX timeout
    Strings/ — user-visible text
      AliasStrings.swift — Aliases page and alias editor, including the editor’s problem messages
      FeedbackStrings.swift — Send Feedback sheet, its privacy notes and the report labels
      MenuBarStrings.swift — status item and its menu
      PanelStrings.swift — inline panel
      PermissionStrings.swift — Accessibility guide and Secure Input messages
      PickerStrings.swift — emoji picker and shared emoji views
      SettingsStrings.swift — Settings window
    Theme/ — colours and symbols
      Palette.swift — colours and SF Symbol names
      SymbolNames.swift — SF Symbol names, including the menu-bar icon
  Features/ — the two user features; they never import each other
    EmojiPicker/ — menu-bar picker popover
      EmojiPickerController.swift — popover lifecycle, keyboard actions, focus hand-back
      EmojiPickerHeaderButton.swift — icon button beside the search field (Settings)
      EmojiPickerKeys.swift — key presses → picker actions, ⌘1–⌘3 for tabs
      EmojiPickerModel.swift — tab, search text, per-tab category, selection, recents grouping
      EmojiPickerView.swift — search field, tabs, category bar, grid and footer
      PickerTab.swift — the picker tabs (Emoji, Symbols, Emoticons): title, placeholder, columns
      PopoverAnchorWindow.swift — invisible anchor so the popover opens without the menu-bar icon
    InlinePanel/ — the `::term` panel
      EmoticonAutocomplete.swift — the typed run that starts an emoticon (“^_”), its rules and Esc dismissal
      InlineInputMonitor.swift — session event tap; reports key-downs, consumes panel keys
      InlinePanelConfiguration.swift — enabled triggers, ranking and autocomplete length forwarded by the composition root
      InlinePanelController.swift — trigger and autocomplete sessions, key handling, insert/copy, panel visibility
      InlinePanelKeys.swift — key presses → panel actions and typed-buffer input
      InlinePanelKind.swift — the three inline panels (emoji, symbols, emoticons) and their default triggers
      InlinePanelModel.swift — open panel and search, ranked results, filter, selection, hover, copy feedback
      InlinePanelPlacement.swift — where the panel opens (under the caret, flips above)
      InlinePanelView.swift — header, filters, grid or emoticon rows, and footer of the panel
      InlinePanelWindow.swift — non-activating floating panel that never takes focus
      InlineTrigger.swift — trigger validation (incl. no trigger containing another) and its reasons
      SecureInputNotifier.swift — notification when a background app blocks MacJi
      TextAliasConverter.swift — the key just typed → what to delete and insert, chained aliases included
      TextInserter.swift — replaces the typed `::term` with the glyph via synthetic keys, chunked for long text
      TriggerTracker.swift — typed-text buffer and the panel + term after the last trigger typed
  Resources/ — bundle resources
    Assets.xcassets/ — asset catalog
      AccentColor.colorset/ — accent colour
        Contents.json — accent colour definition
      AppIcon.appiconset/ — app icon (written by scripts/make-icon.sh)
      Contents.json — asset catalog metadata
    Info.plist — Sparkle feed URL and public EdDSA key (merged with generated keys)
    MacJi.entitlements — hardened-runtime entitlements (none; no sandbox)
  Settings/ — Settings window and stored settings
    AppSettings.swift — typed accessors, registered defaults, change publishers
    Components/ — reusable Settings rows
      AliasRow.swift — one alias row: spellings → outputs, name, edit (yours), delete or hide, switch
      SettingsHint.swift — small explanatory or error line under a control
      SettingsStatusRow.swift — status row with symbol, explanation and optional fix-it button
      TriggerField.swift — trigger text field with live validation and the reason for a rejection
    Feedback/ — Send Feedback: the sheet and the report it builds
      FeedbackDetails.swift — the anonymous technical details: MacJi and macOS versions, Accessibility, Secure Input
      FeedbackReport.swift — kind + message (+ details) as a mailto draft or a prefilled GitHub issue form
      FeedbackSheet.swift — kind, message, Include technical details, What will be sent, Email / GitHub
    LoginItem.swift — SMAppService wrapper with real status and errors
    Pages/ — Settings pages that slide in over the main Form
      AliasEditorSheet.swift — add or edit one of your aliases: name, group, + spellings, + outputs, live validation
      TextAliasesPage.swift — Aliases page: filter, groups with yours first, group switches, + to add, Turn All On, Show Hidden
    Sections/ — one view per Settings section
      AboutSection.swift — version, Send Feedback…, links, Built on Octopus
      AliasesSection.swift — Aliases switch, Customize…, show-in-search switch, and a note when nothing watches the keyboard
      EmojiPickerSection.swift — picker shortcut recorder and reset, Symbols and Emoticons tab switches
      EmoticonsSection.swift — Emoticons switch, "Suggest as you type" − N + stepper (with Off), optional trigger
      InlinePanelsSection.swift — emoji and symbol panel switches and triggers, frequency ranking
      LoginItemSection.swift — Open at login switch, under Accessibility, with approval and error hints
      MenuBarSection.swift — show/hide the menu-bar icon
      PermissionSection.swift — Accessibility and Secure Input status rows
      QuitSection.swift — Quit MacJi button at the bottom of Settings
      UpdatesSection.swift — automatic updates, Check Now and the last check time
    SettingsMigrator.swift — schema version and ordered, idempotent migrations
    SettingsView.swift — the single grouped Form
    SettingsWindowController.swift — the Settings window: size limits, position autosave, activation
  Shared/ — code used by both features
    AX/ — Accessibility API helpers
      AXValueReader.swift — checked reads of AX attributes (no force casts)
      CaretLocator.swift — caret rectangle of the focused text field
    GlyphUI/ — reusable glyph views
      CopiedBadge.swift — "Copied" capsule and its timed modifier
      GlyphCell.swift — one glyph button with selection, hover and press feedback
      GlyphRow.swift — one wide glyph (an emoticon) as a full-width row with its name
      KeyHint.swift — footer keycap with caption
    Glyphs/ — glyph data shared by both features: emoji, symbols, emoticons
      EmoticonCategory.swift — emoticon filters (Happy, Love, Sad, … Flip, Animals)
      Glyph.swift — Glyph and GlyphSection value types
      GlyphCatalog.swift — loads and indexes one data file once, generic over its categories
      GlyphCategory.swift — the GlyphCategory protocol and EmojiCategory
      GlyphClipboard.swift — copies a glyph to the pasteboard
      GlyphGrid.swift — splits items into fixed-column rows for drawing and arrow keys
      GlyphLibrary.swift — the emoji, symbol and emoticon catalogs, loaded together off the main thread
      GlyphRecents.swift — recently used glyphs (persisted, capped) and per-glyph use counts
      GlyphSearch.swift — ranked search used by the panel and the picker
      Resources/ — data files
        emoji.json — gemoji data stripped to the fields MacJi reads
        emoticons.json — ASCII emoticons and kaomoji (written by scripts/update-emoticon-data.py)
        symbols.json — Unicode symbols with search keywords (written by scripts/update-symbol-data.py)
      SymbolCategory.swift — symbol filters (Arrows, Math, Greek, … Technical)
    Logging/ — diagnostics
      Log.swift — os.Logger categories (never print)
    MenuKit/ — panel chrome and keyboard helpers
      CategoryBar.swift — category filter buttons for any glyph catalog, and Tab cycling
      MenuAppearModifier.swift — fade/scale-in on each presentation
      MenuCardBackground.swift — frosted card with hairline and soft shadow
      MenuGridNavigator.swift — arrow-key movement through rows
      MenuKey.swift — key codes → arrow, confirm, cancel
      MenuPanelFader.swift — fade a panel out, cancellable by a reopen
      MenuPressButtonStyle.swift — press shrink with no system bezel
      MenuShadowMargin.swift — transparent margin where the card shadow draws
    Permissions/ — Accessibility and event-tap safety
      AccessibilityGrantReset.swift — clear a stale Accessibility entry on user request
      AccessibilityGuidePlacement.swift — dock the guide panel next to System Settings
      AccessibilityPermissionGuide.swift — open System Settings and show the drag guide
      AccessibilityPermissionGuideView.swift — the drag-to-allow guide panel
      AccessibilityRevocationRecovery.swift — relaunch after revocation to free input
      EventTapPermissionWatch.swift — remove every tap when Accessibility is revoked
      EventTapRevocationProbe.swift — background probe and its failure detector
      EventTapTrust.swift — throwaway-tap check of real trust
      PermissionStatus.swift — observable Accessibility and Secure Input state, updated by notifications
      SecureInput.swift — who holds Secure Event Input and how to release it
    TextAliases/ — text aliases shared by the panel (conversion) and the picker (search)
      ActiveTextAliases.swift — the aliases that convert: built-in + yours − turned off; yours win a spelling
      AliasGlyphs.swift — your aliases as a searchable catalog, merged first into panel and picker results
      CustomTextAliasCodec.swift — your aliases to and from the stored plist array, keeping unreadable entries
      CustomTextAliasValidator.swift — rules for your aliases (name, spellings, outputs) and the editor draft
      TextAlias.swift — one text alias: spellings, outputs, group, word-start rule, your name for it
      TextAliasCatalog.swift — the built-in aliases (arrows, math, symbols, emoticons); IDs are stored
      TextAliasNames.swift — the name an alias shows and is searched by, and the page filter
  Updates/ — software updates
    UpdateController.swift — Sparkle updater: check now, automatic checks, last check
MacJi.xcodeproj/ — Xcode project (synchronised folders, shared scheme)
MacJiTests/ — Swift Testing suites, mirroring MacJi/
  Features/ — feature tests
    EmojiPicker/ — picker tests
      EmojiPickerTests.swift — key mapping, grid rows, recents grouping
    InlinePanel/ — inline panel tests
      InlinePanelTests.swift — trigger tracking, keys, validation, placement, caret, Secure Input
  Screenshots/ — opt-in README image generator (skipped in normal test runs)
    ReadmeScreenshots.swift — renders picker tabs, search, Settings, Aliases page and editor, Send Feedback, and the typing scripts, light and dark
    ScreenshotStage.swift — themes, backdrop, mock window chrome and the offscreen 2x renderer
    TypingRecording.swift — typing scripts (emoji, symbols, emoticons, aliases) recorded into GIF frames with the real panel
  Settings/ — settings tests
    FeedbackReportTests.swift — details only when included, URL encoding, field ids match the issue forms
    SettingsTests.swift — migrations, idempotence, per-key fallback
  Shared/ — shared code tests
    AX/ — AX helper tests
      CaretLocatorTests.swift — rejects field, paragraph and off-screen caret rects
    Glyphs/ — glyph data tests
      GlyphDataTests.swift — catalog search, ranking, recents
    Permissions/ — permission tests
      EventTapRevocationDetectorTests.swift — revocation needs consecutive failures
      SecureInputTests.swift — reads the Secure Input holder from the console session only
    TextAliases/ — custom alias tests
      CustomTextAliasTests.swift — validation, storage that keeps unreadable entries, overriding a built-in
PRIVACY.md — what MacJi reads, stores and sends (almost nothing)
README.md — pitch, install, first launch, permissions, usage, build, Built on Octopus
SECURITY.md — how to report a vulnerability; signing and update model
Upstream/ — reference sources
  octopus/ — Octopus git submodule, reference only, never compiled
WEB/ — product website, served by GitHub Pages (static, no build step)
  404.html — Pages not-found page (absolute /MacJi/ paths)
  assets/ — site-only copies of images and data
    data/ — data the live demo reads
      emoji.json — copy of MacJi/Shared/Glyphs/Resources/emoji.json; refresh it when that changes
      symbols.json — copy of MacJi/Shared/Glyphs/Resources/symbols.json for the ## demo; refresh it when that changes
    icon/ — favicon and app icon from assets/icon (written by scripts/make-web-assets.sh)
    screenshots/ — WebP screenshots plus the link-preview PNG (written by scripts/make-web-assets.sh)
  css/ — stylesheets
    base.css — design tokens (light + dark), page glow, nav, buttons, keycaps, footer, motion, confetti canvas
    demo.css — the hero's note window, inline emoji panel and "try it" chips
    home.css — landing page layout
    pointer.css — iPadOS-style pointer: dot, platter and text beam
    thank-you.css — thank-you and 404 layout
  index.html — landing page with the live ::term demo
  js/ — scripts, no dependencies
    confetti-sprites.js — confetti shapes with their glow, painted once and cached
    confetti.js — click-anywhere confetti on every page, side poppers, the 🎉 party shower and pointer collisions
    demo.js — working copy of the inline panel (trigger rule + GlyphSearch ranking)
    pointer.js — iPadOS-style pointer and button parallax, ported from the Octopus site
    release.js — latest release's .dmg from the GitHub API, Releases-page fallback
    thank-you.js — starts the download, fires the confetti
    theme.js — light/dark theme, scrolled nav and current section
  thank-you.html — after Download: starts the .dmg, confetti, first-launch steps
assets/ — app images
  icon/ — app icon PNGs for the README header
  new_screenshots/ — earlier offscreen renders of the 0.3.0 features, superseded by screenshots_by_agent/
    editor-dark.png — alias editor, dark
    editor-light.png — alias editor, light
    panel-emoticons-dark.png — emoticon panel, dark
    panel-emoticons-light.png — emoticon panel, light
    panel-symbols-dark.png — symbol panel, dark
    panel-symbols-light.png — symbol panel, light
    picker-emoticons-dark.png — picker Emoticons tab, dark
    picker-emoticons-light.png — picker Emoticons tab, light
    picker-symbols-dark.png — picker Symbols tab, dark
    picker-symbols-light.png — picker Symbols tab, light
  picker-buttons/ — picker images with the Settings button; not used by the README or website
    picker-dark.png — picker, dark
    picker-light.png — picker, light
    picker-search-dark.png — picker search, dark
    picker-search-light.png — picker search, light
  screenshots/ — 0.2.0 README images and GIFs, no longer referenced
  screenshots_by_agent/ — README images and GIFs, light and dark (written by scripts/make-screenshots.sh)
build.sh — build, quit the running MacJi, relaunch, print the running path
dist/ — Sparkle update feed, served from main
  README.md — what the feed folder holds
  appcast.xml — Sparkle feed, written by scripts/release.py
  signing-identity.json — certificate hash and EdDSA key of the last release (release.py checks rotation)
docs/ — long-form documentation
  ARCHITECTURE.md — layers, data flow, MacJi file → Octopus file table
  RELEASING.md — one-time certificate/key setup and the release steps
  convert-symbols.md — every text → symbol conversion: built in, left out and why, macOS ways
  icon-prompt.md — image prompt for the 1024 px app icon
  zany-sprouting-origami-of.md — the 0.3.0 implementation plan (symbols, emoticons, custom aliases)
repo_map.md — this file
scripts/ — automation (see CLAUDE.md → Scripts)
  bump-version.sh — bump version/build and add a CHANGELOG heading
  check.sh — repo hygiene gate (CI + before every commit)
  clean.sh — remove build output and release artefacts (asks first)
  config.py — shared values for Python scripts (mirrors config.sh)
  config.sh — shared values: bundle ID, scheme, paths, certificate, repos
  make-icon.sh — every AppIcon size and Contents.json from one 1024 px PNG
  make-placeholder-icon.swift — draws the placeholder icon
  make-screenshots.sh — regenerate README images and GIFs from the real views (needs ffmpeg)
  make-web-assets.sh — refresh WEB/assets: WebP screenshots and icon, emoji data (needs cwebp)
  new-file.sh — new Swift file with the standard header
  release.py — full signed release; --dry-run publishes nothing
  repo-map.py — regenerate the tree in repo_map.md
  reset-permissions.sh — dev only: reset the Accessibility grant (asks first)
  setup.sh — first-time setup of a fresh clone
  sync-from-octopus.sh — diff ported files against their Octopus origins
  test.sh — run tests; fails when zero tests ran
  update-emoji-data.py — strip a gemoji emoji.json to MacJi's fields
  update-emoticon-data.py — build emoticons.json from wooorm/emoticon and kaomojidict
  update-symbol-data.py — build symbols.json from Python’s Unicode names
  verify-update.swift — check an archive's EdDSA signature, version and appcast entry
```
<!-- repo-map:tree:end -->
