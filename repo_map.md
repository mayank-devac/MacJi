# Repo map

Where everything lives. Update it in the same change whenever a file or folder is added, moved,
renamed or removed. `scripts/repo-map.py` regenerates the tree below from disk and keeps the
descriptions; `scripts/check.sh` fails when the tree and the disk disagree.

## Where do I change…?

| I want to change… | File |
|---|---|
| Trigger default (`::`) or its rules | `MacJi/Constants/Keys/PreferenceKeys.swift` (`PreferenceDefaults.trigger`), `MacJi/Features/InlinePanel/InlineTrigger.swift` |
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
| GitHub / Octopus / licence links | `MacJi/Constants/Links/AppLinks.swift` |
| App icon | `scripts/make-icon.sh <1024.png>` → `MacJi/Resources/Assets.xcassets/AppIcon.appiconset` |
| Menu-bar icon | `MacJi/Constants/Theme/SymbolNames.swift` (`menuBar`) |
| Emoji data | `scripts/update-emoji-data.py` → `MacJi/Shared/EmojiData/Resources/emoji.json` |
| Release steps | `docs/RELEASING.md`, `scripts/release.py` |
| README screenshots and GIFs | `scripts/make-screenshots.sh` → `assets/screenshots/` (scenes in `MacJiTests/Screenshots/`) |
| Website (GitHub Pages) | `WEB/` (deployed by `.github/workflows/pages.yml`; images via `scripts/make-web-assets.sh`) |
| Shared script values (bundle ID, cert name, repos) | `scripts/config.sh`, `scripts/config.py` |

## Tree

<!-- repo-map:tree:start -->
```text
.github/ — GitHub configuration
  ISSUE_TEMPLATE/ — issue forms
    bug_report.md — bug report template
    feature_request.md — feature request template
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
  gemoji-MIT.txt — gemoji emoji data licence
MacJi/ — the app target (synchronised folder: new files are picked up automatically)
  App/ — entry point and composition root
    AppDelegate.swift — composition root: creates, wires, starts and stops every controller
    AppLifecycle.swift — when to open Settings on launch and reopen; login-item launch detection
    MacJiApp.swift — SwiftUI App; routes ⌘, to the Settings window
    StatusItemController.swift — menu-bar icon: click opens the picker, right-click menu
  Constants/ — every literal lives here
    Keys/ — stored names
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
      AppLinks.swift — GitHub, Octopus, licence, releases and System Settings URLs
    Motion/ — timing
      PanelMotion.swift — springs, fades, copy-close and name-reveal delays
      Timing.swift — non-animation intervals: revocation probe, guide polling, recovery, AX timeout
    Strings/ — user-visible text
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
      EmojiPickerCategoryBar.swift — category filter buttons
      EmojiPickerController.swift — popover lifecycle, keyboard actions, focus hand-back
      EmojiPickerKeys.swift — key presses → picker actions
      EmojiPickerModel.swift — search text, category, selection, recents grouping
      EmojiPickerView.swift — search field, grid and footer
      PopoverAnchorWindow.swift — invisible anchor so the popover opens without the menu-bar icon
    InlinePanel/ — the `::term` panel
      InlineInputMonitor.swift — session event tap; reports key-downs, consumes panel keys
      InlinePanelController.swift — trigger session, key handling, insert/copy, panel visibility
      InlinePanelKeys.swift — key presses → panel actions and typed-buffer input
      InlinePanelModel.swift — typed term, ranked results, selection, hover, copy feedback
      InlinePanelPlacement.swift — where the panel opens (under the caret, flips above)
      InlinePanelView.swift — header, grid and footer of the panel
      InlinePanelWindow.swift — non-activating floating panel that never takes focus
      InlineTrigger.swift — trigger validation and its error messages
      SecureInputNotifier.swift — notification when a background app blocks MacJi
      TextInserter.swift — replaces the typed `::term` with the emoji via synthetic keys
      TriggerTracker.swift — typed-text buffer and the term after the trigger
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
      SettingsHint.swift — small explanatory or error line under a control
      SettingsStatusRow.swift — status row with symbol, explanation and optional fix-it button
    LoginItem.swift — SMAppService wrapper with real status and errors
    Sections/ — one view per Settings section
      AboutSection.swift — version, links, Built on Octopus
      EmojiPickerSection.swift — picker shortcut recorder and reset
      GeneralSection.swift — open at login, automatic updates, Check Now
      InlinePanelSection.swift — enable toggle and trigger field with validation
      MenuBarSection.swift — show/hide the menu-bar icon
      PermissionSection.swift — Accessibility and Secure Input status rows
    SettingsMigrator.swift — schema version and ordered, idempotent migrations
    SettingsView.swift — the single grouped Form
    SettingsWindowController.swift — the Settings window: size limits, position autosave, activation
  Shared/ — code used by both features
    AX/ — Accessibility API helpers
      AXValueReader.swift — checked reads of AX attributes (no force casts)
      CaretLocator.swift — caret rectangle of the focused text field
    EmojiData/ — emoji data shared by both features
      Emoji.swift — Emoji, EmojiCategory and EmojiSection value types
      EmojiCatalog.swift — loads and indexes emoji.json once
      EmojiClipboard.swift — copies an emoji to the pasteboard
      EmojiGrid.swift — splits items into fixed-column rows for drawing and arrow keys
      EmojiRecents.swift — recently used emoji, persisted and capped
      EmojiSearch.swift — ranked search used by the panel and the picker
      Resources/ — data files
        emoji.json — gemoji data stripped to the fields MacJi reads
    EmojiUI/ — reusable emoji views
      CopiedBadge.swift — "Copied" capsule and its timed modifier
      EmojiCell.swift — one emoji button with selection, hover and press feedback
      KeyHint.swift — footer keycap with caption
    Logging/ — diagnostics
      Log.swift — os.Logger categories (never print)
    MenuKit/ — panel chrome and keyboard helpers
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
    ReadmeScreenshots.swift — renders picker, search, Settings and the inline-panel GIF frames, light and dark
    ScreenshotStage.swift — themes, backdrop, mock window chrome and the offscreen 2x renderer
  Settings/ — settings tests
    SettingsTests.swift — migrations, idempotence, per-key fallback
  Shared/ — shared code tests
    AX/ — AX helper tests
      CaretLocatorTests.swift — rejects field, paragraph and off-screen caret rects
    EmojiData/ — emoji data tests
      EmojiDataTests.swift — catalog search, ranking, recents
    Permissions/ — permission tests
      EventTapRevocationDetectorTests.swift — revocation needs consecutive failures
      SecureInputTests.swift — reads the Secure Input holder from the console session only
PRIVACY.md — what MacJi reads, stores and sends (almost nothing)
README.md — pitch, install, first launch, permissions, usage, build, Built on Octopus
SECURITY.md — how to report a vulnerability; signing and update model
Upstream/ — reference sources
  octopus/ — Octopus git submodule, reference only, never compiled
WEB/ — product website, served by GitHub Pages (static, no build step)
  404.html — Pages not-found page (absolute /MacJi/ paths)
  assets/ — site-only copies of images and data
    data/ — data the live demo reads
      emoji.json — copy of MacJi/Shared/EmojiData/Resources/emoji.json; refresh it when that changes
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
    confetti.js — click-anywhere confetti on every page, side poppers and the 🎉 party shower
    demo.js — working copy of the inline panel (trigger rule + EmojiSearch ranking)
    pointer.js — iPadOS-style pointer and button parallax, ported from the Octopus site
    release.js — latest release's .dmg from the GitHub API, Releases-page fallback
    thank-you.js — starts the download, fires the confetti
    theme.js — light/dark theme, scrolled nav and current section
  thank-you.html — after Download: starts the .dmg, confetti, first-launch steps
assets/ — images used by the README
  icon/ — app icon PNGs for the README header
  screenshots/ — README images and GIFs, light and dark (written by scripts/make-screenshots.sh)
build.sh — build, quit the running MacJi, relaunch, print the running path
dist/ — Sparkle update feed, served from main
  README.md — what the feed folder holds
  appcast.xml — Sparkle feed, written by scripts/release.py
  signing-identity.json — certificate hash and EdDSA key of the last release (release.py checks rotation)
docs/ — long-form documentation
  ARCHITECTURE.md — layers, data flow, MacJi file → Octopus file table
  RELEASING.md — one-time certificate/key setup and the release steps
  icon-prompt.md — image prompt for the 1024 px app icon
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
  verify-update.swift — check an archive's EdDSA signature, version and appcast entry
```
<!-- repo-map:tree:end -->
