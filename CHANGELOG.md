# Changelog

All notable changes to MacJi. Versions follow [Semantic Versioning](https://semver.org).
Write notes under **Unreleased**; `scripts/bump-version.sh` moves them under a dated heading and
`scripts/release.py` publishes that section as the update's release notes.

## [Unreleased]

### Added
- ⚙️ Settings button in the emoji picker, beside the search field.
- 👋 Quit MacJi button at the bottom of Settings.

## [0.1.1] - 2026-11-26

The first release of MacJi 🎉 Emoji anywhere on your Mac, straight from the keyboard.

### Added
- ⌨️ Inline panel: type `::` and a term in any app (`::rocket`) and pick an emoji under the caret.
  Return inserts it 🚀, Shift-Return copies it, Esc closes the panel.
- 😀 Emoji picker in the menu bar with search, categories, recents and keyboard navigation.
  Return copies, Option-Return copies and keeps the picker open.
- ⚡️ Global shortcut for the picker (default ⌃⌥⌘Space); it opens at the caret when the icon is hidden.
- ⚙️ Settings: Accessibility status, shortcut, trigger, menu-bar icon, open at login, automatic updates.
- 🔄 Automatic updates, signed with EdDSA so only genuine MacJi updates install.

### First launch
- 🔐 MacJi isn't notarized: open it once from System Settings → Privacy & Security → Open Anyway,
  then turn on Accessibility for MacJi when it asks.
- 💻 Needs macOS 14.6 or later.
