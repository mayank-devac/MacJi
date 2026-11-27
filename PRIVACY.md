<!--
  PRIVACY.md · MacJi · Created: 2026-11-26
  What MacJi reads, stores and sends.
-->

# Privacy

**Short version:** MacJi doesn't collect anything. No analytics, no crash reports, no account, and no
network requests other than checking for updates.

## What MacJi reads

- **Key presses, only while a typing feature is turned on** (the emoji or symbol panel, emoticon
  suggestions, or aliases). Each key is checked in memory against the triggers (`::` and `##` by
  default), the start of an emoticon and your aliases. MacJi keeps the last few typed characters so
  it can tell when you've typed a trigger and a word. They're never written to disk, logged or sent
  anywhere. Turning all of those features off removes the keyboard listener completely.
- **The caret position** of the text field you're typing in, through macOS Accessibility, so the
  panel can open next to it. MacJi doesn't read the text in the field.
- **Which app holds Secure Input**, when one does, so MacJi can tell you why the panel isn't
  opening.

## What MacJi stores

All of it stays on your Mac, in MacJi's preferences
(`~/Library/Preferences/io.github.mayank-devac.macji.plist`):

- your settings (triggers, shortcut, ranking, emoticon suggestions, picker tabs and the last one
  you used, aliases you turned off or hid, menu-bar icon, open at login, update checks)
- the aliases you added yourself: their names, spellings and outputs
- up to 72 recently used emoji, symbols and emoticons, and how many times you inserted or copied
  each one
- the Settings window position and Sparkle's last update-check date

## What MacJi sends

- **Update checks.** MacJi downloads its update feed from `raw.githubusercontent.com`, once a day
  unless you turn automatic checks off. If there's an update, the download comes from GitHub
  Releases. GitHub sees your IP address, as with any web request. No other information is attached:
  Sparkle's anonymous system profile is turned off.

That's the only network traffic MacJi makes.

## Feedback

**Settings › About › Send Feedback…** doesn't send anything itself. It hands your message to
another app, which sends it only when you do:

- **Send Email…** opens a draft in your mail app, addressed to `macji.app@proton.me`. The developer
  sees your message and the address you send it from, as with any email.
- **Open on GitHub…** opens a filled-in issue form in your browser. Issues are public and show your
  GitHub username.

Either way the report holds the kind you picked and your message. Only if you tick **Include
technical details** does it also hold the MacJi version and build, the macOS version, and whether
Accessibility is granted and Secure Input is on. The form lists these before you send. MacJi never
adds your name, a device identifier, logs, keystrokes, settings or clipboard content. Your draft is
kept in memory while Settings is open and never written to disk.

## The clipboard

When you copy an emoji, symbol or emoticon (Shift-Return in a panel, Return in the picker), MacJi
puts it on the clipboard. Inserting with Return doesn't touch the clipboard: MacJi types it
directly. So does an alias conversion.

## Questions

Open an issue on [GitHub](https://github.com/mayank-devac/MacJi/issues), or write to
[macji.app@proton.me](mailto:macji.app@proton.me).
