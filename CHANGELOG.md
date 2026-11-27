# Changelog

All notable changes to MacJi. Versions follow [Semantic Versioning](https://semver.org).
Write notes under **Unreleased**; `scripts/bump-version.sh` moves them under a dated heading and
`scripts/release.py` publishes that section as the update's release notes.

## [Unreleased]

Feedback from inside the app 💬

### Added
- 💬 Send Feedback: Settings › About › Send Feedback… sends a bug, a feature idea or anything else
  by email (no account needed) or as a filled-in GitHub issue. Tick **Include technical details**
  to add only the MacJi and macOS versions and the Accessibility and Secure Input state; the form
  shows exactly what will be sent.
- 🌐 A feedback page on the website does the same without the app, and replaces the website's
  "Report an issue" link.
- 🙂 On that page a face made of dots wears the mood you pick, watches you type and winks when your
  draft opens.

### Changed
- 👋 Quit MacJi in Settings is now a power icon in the About section.
- 📝 Bug reports and feature requests on GitHub are now short forms that ask for what's needed.
- 🔒 Security problems can also be reported privately by email, without a GitHub account.

## [0.3.0] - 2026-11-27

Symbols, emoticons and your own aliases 🔣

### Added
- 🔣 Symbol panel: type `##` and a word (`##arrow`, `##euro`, `##cmd`) for more than 2,000
  Unicode symbols. Tab and Shift-Tab switch between categories.
- 😄 Emoticons: start typing one (`^_`, `o_`) and MacJi suggests the rest, from more than 450
  ASCII emoticons and kaomoji. Settings sets how many characters it waits for, or turns it off,
  and you can add a trigger to search emoticons by name.
- ✍️ Aliases: `->` becomes →, `!=` ≠, `(c)` © as you type, in any app. Turn single aliases off,
  hide the ones you never want to see, and add your own with several spellings and outputs.
  Emoticon aliases such as `:)` → 🙂 start off; turn on the ones you want.
- 🔎 Your aliases show first when you search any panel or the picker, by name.
- 🧭 Emoji, Symbols and Emoticons tabs in the picker (⌘1–⌘3), each with its own recents.
- 🌠 The panels list the glyphs you use most first.

### Changed
- ⚙️ Open at login sits right under Accessibility in Settings; the rest of General is now Updates.
- 🧹 With every typing feature off, MacJi stops watching the keyboard entirely.

## [0.2.0] - 2026-11-26

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
