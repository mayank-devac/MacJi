# Convert symbols

Every text-to-symbol conversion worth knowing on a Mac: the ones MacJi's **Aliases** convert,
the ones left out on purpose, and how to type each symbol without MacJi.

The source of truth for the built-in list is `MacJi/Shared/TextAliases/TextAliasCatalog.swift`.
Keep this file in step with it.

## How MacJi aliases work

- An alias converts the moment you type its **last character**: type `-` then `>` and the `-`
  becomes `→` (the `>` never reaches the app).
- It works in every app the inline panels work in, whether or not a panel is on. It never runs
  in MacJi's own windows or while Secure Input is on (password fields).
- **Convert aliases while typing** in Settings › Aliases turns them all on or off (default **on**,
  all aliases). **Customize…** slides to a page with a filter, one switch per alias and one per
  group. Turned-off aliases are stored by ID, so aliases added in a later version start on.
- Longer aliases build on shorter ones: `<->` is typed as `<-` (already `←`) then `>`, giving `↔`.
  This works whether or not `<-` is on.
- Bracket symbols and emoticons convert only **at the start of a word** (after a space, a
  line start, or a click). `note:)`, `f(c)` and the `::` trigger (`::D…`) stay as typed.
- To keep an alias as typed, turn it off in **Customize…**. Delete after a conversion removes the symbol.

## Your own aliases

On the Aliases page, **+** or a group's **Add Alias…** opens the editor:

| Field | Rule |
|---|---|
| Name | 1–40 characters. What search finds: `::check`, `##check` and the picker list the outputs first. |
| You type | One or more spellings (up to 8), each 2–16 characters, no spaces, with at least one character that isn't a letter or digit, and no panel trigger inside. Two of your aliases can't share one. |
| Becomes | One or more outputs (up to 8), each up to 64 characters on one line. The first is typed; the rest only appear in search. |
| Only at the start of a word | On by default, like the bracket and emoticon aliases below. |

- A spelling of yours that a built-in alias also uses replaces the built-in one while yours is on;
  turn yours off and the built-in one is back. The editor says when that happens.
- Your aliases are stored in MacJi's preferences (`customTextAliases`), so they survive updates.
  An entry a newer MacJi wrote that this version can't read is kept as it is.
- **Show your aliases in search** (Settings › Aliases, default on) controls whether they appear in
  the panels' and the picker's search.

## Built into MacJi

### Arrows

| Type | Becomes | Name | Unicode |
|---|---|---|---|
| `->` | → | Rightwards arrow | U+2192 |
| `<-` | ← | Leftwards arrow | U+2190 |
| `<->` | ↔ | Left right arrow | U+2194 |
| `=>` | ⇒ | Rightwards double arrow | U+21D2 |
| `<==` | ⇐ | Leftwards double arrow | U+21D0 |
| `<=>` | ⇔ | Left right double arrow | U+21D4 |

### Math

| Type | Becomes | Name | Unicode |
|---|---|---|---|
| `!=` | ≠ | Not equal to | U+2260 |
| `<=` | ≤ | Less-than or equal to | U+2264 |
| `>=` | ≥ | Greater-than or equal to | U+2265 |
| `+-` | ± | Plus-minus | U+00B1 |
| `~=` | ≈ | Almost equal to | U+2248 |

### Symbols

| Type | Becomes | Name | Unicode | Word start only |
|---|---|---|---|---|
| `...` | … | Horizontal ellipsis | U+2026 | |
| `(c)` `(C)` | © | Copyright | U+00A9 | ✓ |
| `(r)` `(R)` | ® | Registered | U+00AE | ✓ |
| `(tm)` `(TM)` | ™ | Trade mark | U+2122 | ✓ |

### Emoticons → emoji (word start only)

The spellings come from [wooorm/emoticon](https://github.com/wooorm/emoticon) (MIT, notice in
`LICENSES/emoticon-MIT.txt`), filtered to the ones that can't fire in ordinary text or code. The
emoji for `:)`, `:(`, `:D` and `:*` follow Apple and Slack (🙂 🙁 😃 😘) rather than that list.

| Type | Becomes |
|---|---|
| `:)` `:-)` `:]` `:-]` `=)` `=-)` | 🙂 |
| `:D` `:-D` `=D` `=-D` | 😃 |
| `^_^` `:")` `:-")` `=")` | 😊 |
| `:')` `:'-)` `:'D` `:,)` `:,D` | 😂 |
| `X-D` `X-)` | 😆 |
| `':)` `':D` `,:)` `,:D` | 😅 |
| `;)` `;-)` `;]` `;-]` `;D` `;-D` | 😉 |
| `O:)` `O:-)` `O:]` `O:D` | 😇 |
| `]:)` `]:-)` `]:D` `]:-D` | 😈 |
| `B-)` `B-]` | 😎 |
| `:*` `:-*` | 😘 |
| `:P` `:-P` `=P` `=-P` | 😛 |
| `;P` `;-P` | 😜 |
| `X-P` | 😝 |
| `:\|` `:-\|` | 😐 |
| `-_-` | 😑 |
| `:$` `:-$` `:-S` | 😒 |
| `:-/` `:-\` | 😕 |
| `:O` `:-O` `=O` `=-O` | 😮 |
| `:(` `:-(` `:[` `:-[` `=(` `=-(` | 🙁 |
| `':(` `,:(` | 😓 |
| `:'(` `:'-(` `:'[` `:,(` `='(` | 😢 |
| `:',(` `:,'(` | 😭 |
| `>:(` `>:-(` `>:[` `>:-[` | 😠 |
| `:@` `:-@` | 😡 |
| `]:(` `]:-(` | 👿 |
| `<3` | ❤️ |
| `</3` `<\3` | 💔 |

## Possible, but not built in

These are common conversions that MacJi leaves out because they would fire in ordinary text or
code. Each could become an opt-in alias later.

| Type | Becomes | Name | Why it's left out |
|---|---|---|---|
| `--` | — | Em dash | Breaks command-line flags (`--help`) and `i--` |
| `---` | — | Em dash | Breaks Markdown rules and YAML front matter |
| `-->` | ⟶ | Long rightwards arrow | Breaks HTML comments (`<!-- -->`) |
| `<--` | ⟵ | Long leftwards arrow | Same as above |
| `==>` | ⟹ | Long rightwards double arrow | Rare; conflicts with `=>` |
| `<==>` | ⟺ | Long left right double arrow | Rare |
| `\|->` | ↦ | Maps to | Rare |
| `^^` | ↑ | Upwards arrow | No common spelling |
| `vv` | ↓ | Downwards arrow | Fires inside words |
| `<<` | « | Left guillemet | Breaks C++ streams and shell heredocs |
| `>>` | » | Right guillemet | Breaks shell redirects and quotes in email |
| `1/2` | ½ | Vulgar fraction one half | Breaks dates (`1/2/2026`) |
| `1/4` | ¼ | One quarter | Same |
| `3/4` | ¾ | Three quarters | Same |
| `1/3` `2/3` | ⅓ ⅔ | One third, two thirds | Same |
| `^2` `^3` | ² ³ | Superscript two, three | Breaks maths and regex text |
| `^o` | ° | Degree | No common spelling |
| `x` between numbers | × | Multiplication | Needs context (`1920x1080`) |
| `/` between numbers | ÷ | Division | Breaks paths and dates |
| `==` | ≡ | Identical to | Breaks code |
| `=/=` | ≠ | Not equal (alternative) | `!=` already covers it |
| `~~` | ≈ | Almost equal (alternative) | Breaks Markdown strikethrough |
| `inf` | ∞ | Infinity | Fires inside words (`info`) |
| `(e)` | € | Euro | Not a standard spelling |
| `(p)` | ℗ | Sound recording copyright | Breaks lists such as `(p)` |
| `c/o` | ℅ | Care of | Rare |
| `No.` | № | Numero sign | Breaks sentences ending in "No." |
| `:p` `:o` `xD` `o:)` | 😛 😮 😆 😇 | Lowercase emoticons | Fire mid-word (`:open`, `xDebug`) |
| `:/` `=/` | 😕 | Confused | Break vim commands (`:/pattern`) |
| `:-` | 😶 | No mouth | Starts every emoticon with a nose; breaks vim ranges (`:-1`) |
| `:S` `:Z` | 😒 | Unamused | Fire on capitalised words (`:Some`) |
| `8)` `B)` `X)` | 😎 😆 | Cool, laughing | Break numbered and lettered lists |
| `:3` `:0` `T-T` | 👨 😮 😢 | Digit and letter emoticons | Break times (`:30`) and words |
| `=*` `=[` `=\|` `>=(` | 😘 🙁 😐 😠 | `=` emoticons | Break code (`x =*p`, `a =[1]`, `a >=(b)`) |
| `o/` | 👋 | Waving | Fires inside words |
| `\alpha` … | α β γ π … | Greek letters (LaTeX names) | Would need a whole name table |

## Typing symbols without MacJi

macOS has three built-in ways. None of them works in every app the way MacJi's aliases do.

### Option-key shortcuts (U.S. keyboard layout)

| Symbol | Keys | Symbol | Keys |
|---|---|---|---|
| – en dash | ⌥ - | — em dash | ⌥ ⇧ - |
| … ellipsis | ⌥ ; | • bullet | ⌥ 8 |
| © copyright | ⌥ G | ® registered | ⌥ R |
| ™ trade mark | ⌥ 2 | ° degree | ⌥ ⇧ 8 |
| ≠ not equal | ⌥ = | ± plus-minus | ⌥ ⇧ = |
| ≤ less or equal | ⌥ , | ≥ greater or equal | ⌥ . |
| ≈ almost equal | ⌥ X | ÷ division | ⌥ / |
| ∞ infinity | ⌥ 5 | √ square root | ⌥ V |
| ∑ sum | ⌥ W | ∆ increment | ⌥ J |
| π pi | ⌥ P | Ω omega | ⌥ Z |
| µ micro | ⌥ M | ¬ not | ⌥ L |
| « left guillemet | ⌥ \ | » right guillemet | ⌥ ⇧ \ |
| “ ” double quotes | ⌥ [ / ⌥ ⇧ [ | ‘ ’ single quotes | ⌥ ] / ⌥ ⇧ ] |
| € euro | ⌥ ⇧ 2 | £ pound | ⌥ 3 |
| ¥ yen | ⌥ Y | ¢ cent | ⌥ 4 |
| § section | ⌥ 6 | ¶ pilcrow | ⌥ 7 |
| † dagger | ⌥ T | ‡ double dagger | ⌥ ⇧ 7 |
| · middle dot | ⌥ ⇧ 9 |  Apple logo | ⌥ ⇧ K |

Arrows (→ ← ↔ ⇒) have no Option-key shortcut on the U.S. layout. That's the main gap MacJi's
aliases fill.

### Text Replacements

System Settings › Keyboard › Text Replacements… lets you add any `type → replace with` pair. It
runs only in apps built on the system text system (Notes, Mail, TextEdit, Messages), not in
Electron apps, terminals or most code editors. It also replaces only after a space or
punctuation, not on the last character.

### Character Viewer

Control-Command-Space, or Globe/fn-E, opens the Character Viewer. It has every Unicode symbol
under Arrows, Math Symbols, Punctuation, Currency Symbols, Letterlike Symbols and Emoji. Use its
search to find a symbol by name.
