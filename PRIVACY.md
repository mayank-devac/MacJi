<!--
  PRIVACY.md · MacJi · Created: 2026-11-26
  What MacJi reads, stores and sends.
-->

# Privacy

**Short version:** MacJi doesn't collect anything. No analytics, no crash reports, no account, and no
network requests other than checking for updates.

## What MacJi reads

- **Key presses, only while the inline panel is turned on.** Each key is checked against the
  trigger (`::` by default) in memory. MacJi keeps the last few typed characters so it can tell when
  you've typed the trigger and a word. They're never written to disk, logged or sent anywhere.
  Turning the inline panel off removes the keyboard listener completely.
- **The caret position** of the text field you're typing in, through macOS Accessibility, so the
  panel can open next to it. MacJi doesn't read the text in the field.
- **Which app holds Secure Input**, when one does, so MacJi can tell you why the panel isn't
  opening.

## What MacJi stores

All of it stays on your Mac, in MacJi's preferences
(`~/Library/Preferences/io.github.mayank-devac.macji.plist`):

- your settings (trigger, shortcut, menu-bar icon, open at login, update checks)
- up to 24 recently used emoji
- the Settings window position and Sparkle's last update-check date

## What MacJi sends

- **Update checks.** MacJi downloads its update feed from `raw.githubusercontent.com`, once a day
  unless you turn automatic checks off. If there's an update, the download comes from GitHub
  Releases. GitHub sees your IP address, as with any web request. No other information is attached:
  Sparkle's anonymous system profile is turned off.

That's the only network traffic MacJi makes.

## The clipboard

When you copy an emoji (Shift-Return in the panel, Return in the picker), MacJi puts it on the
clipboard. Inserting an emoji with Return doesn't touch the clipboard: MacJi types the emoji
directly.

## Questions

Open an issue on [GitHub](https://github.com/mayank-devac/MacJi/issues).
