# MacJi 0.3.0 — Symbols, Emoticons, Custom Aliases

## Context

MacJi today has one inline panel (`::term` → emoji), the menu-bar picker (emoji only) and 43
built-in text aliases (`->` → →) that the user can only switch on/off. The user wants:

1. **Custom aliases**: their own arrows, emoji, math, symbols, emoticons. Each alias has a **name**,
   **several spellings** (+ button) and **several outputs** (+ button). Typing converts to the
   first output, and searching the name in **every panel** shows all outputs. The Aliases page gets a redesign.
2. **Emoticons** (`^_^`, `o_O`, ¯\_(ツ)_/¯) from real datasets, with three settings: a
   **switch**, **autocomplete** that opens the emoticon panel once N typed characters match the
   start of an emoticon (on, `− 2 +`, can go to Off), and an optional **trigger** (blank = off,
   e.g. `;;`).
3. **Symbols** (arrows, math, Greek, currency, …) with **their own trigger, `##` by default**,
   with filters and search in the inline panel and the picker.
4. Same standards as the emoji features, every feature can be switched on/off, docs updated,
   reviews run, each phase committed on its own, staged as **0.3.0** (no tag, push or release).

Decisions taken with the user: "many spellings, many results"; symbol trigger `##`; emoticons
get autocomplete (on, 2 characters) plus an optional trigger that is blank by default; bump to
0.3.0 + CHANGELOG.

---

## UX / UI design

### Three inline panels, one engine

| Panel | Default trigger | Example | Layout | Filters |
|---|---|---|---|---|
| Emoji (exists) | `::` | `::roc` → 🚀 | 8-column grid | none (unchanged) |
| Symbols (new) | `##` | `##arr` → → ← ↔ … | grid | Tab / ⇧Tab cycles a slim category bar |
| Emoticons (new) | none (user may set e.g. `;;`) | autocomplete `^_` → ^_^ ^_~ ; trigger `;;shrug` → ¯\_(ツ)_/¯ | one per row: face + name | Tab / ⇧Tab cycles a slim category bar |

**Emoticon autocomplete** (default on, after 2 characters):
- The *run* is what you typed since the last whitespace (or since a click/reset). It opens the
  Emoticons panel when the run is ≥ N characters, contains at least one non-letter/digit (so
  `ow` in "own" never matches `owo`), and is the literal start of at least one emoticon,
  case-sensitive (`:-` → `:-)` `:-(` `:-P` …; `^_` → `^_^` `^_~`).
- It never opens on a run that starts with an active trigger (the trigger panel wins), or on
  code-like starts kept in a deny list (`--` `//` `./` `~/` `==` `**` `__` `<!` `${`). Those
  emoticons stay searchable.
- It opens only with results (no empty state). Typing on filters it, and Space, a mismatch or a
  click closes it. **Esc dismisses it for the rest of that word.**
- Keys are the same as the other panels: Return replaces the run with the selected face, ⇧Return
  copies, arrows move, Tab filters.
- Aliases still win: `:-)` converts to 🙂 on `)` (when that alias is on), and the panel closes
  because the run changed. Choosing `:-)` from the panel inserts the literal text, since
  synthetic keys are ignored by the tap.
- The tap decides synchronously with a precomputed set of every 2–16 character emoticon prefix,
  an O(1) lookup with no blocking. The panel itself is drawn on the next main-queue turn, as today.

- Header title names the panel ("Emoji", "Symbols", "Emoticons"), then the typed `trigger+term`, then the count.
- Keys are the same in all three: Return inserts, ⇧Return copies, Esc closes, arrows move, Space or
  punctuation closes. Tab is consumed only while a Symbols/Emoticons panel is showing. The emoji panel keeps Tab passing through.
- **Your aliases** that match the term are shown first in every panel (deduped against the panel's own results), so `::check` / `##check` / `;;check` all show ✓ ✔ ☑.
- The footer names the focused item. Symbols add their code point (`U+2192`), and anything with an alias shows `Type ->`.
- Card height grows by the category-bar height for Symbols and Emoticons. Placement already takes the card size.

```
┌ Symbols  ##arr                     12 ┐
│ [All][→][±][α][€][“][™][½][■][⌘]       │   ⇥ cycles filters
│ →  ←  ↔  ⇒  ⇐  ⇔  ↑  ↓                │
│ ↗  ↘  ⟶  ⟵                              │
│ → Rightwards Arrow · U+2192   ↩ ⇧↩ ⇥ esc│
└──────────────────────────────────────────┘
┌ Emoticons  ;;shr                      2 ┐
│ [All][☺][♥][☹][💢][🤷][🔄][👋][🐾]        │
│ ¯\_(ツ)_/¯                       Shrug   │
│ ¯\_(⊙_⊙)_/¯              Confused shrug  │
│                         ↩ Insert  ⇧↩ Copy│
└──────────────────────────────────────────┘
```

### Picker (menu-bar popover): tabs

```
[ 🔍 Search symbols…                 ] [⚙]
[   Emoji   |   Symbols   |  Emoticons   ]     ⌘1 ⌘2 ⌘3 switch tabs
[All][→][±][α][€][“][™][½][■][⌘]                Tab cycles filters (as today)
 Your Aliases   ✓ ✔ ☑                       ← search results only
 Recently Used  → ≠ ⌘
 Arrows         → ← ↑ ↓ …
footer: → Rightwards Arrow  U+2192 · Type ->     ↩ Copy  ⇥ Filter  esc
```
- Tab order and the search field are as today. The placeholder follows the tab. The last tab used is remembered.
- A tab that's switched off in Settings is hidden. With only Emoji left, the segmented control disappears (looks exactly like today).
- Recently Used shows each tab's own recents.

### Settings: every feature can be switched off

```
Accessibility …
Emoji Picker     Shortcut [⌃⌥⌘Space] · Symbols tab [on] · Emoticons tab [on]
Inline Panels    Emoji panel     [on]  Trigger [ :: ]   "Type ::rocket…"
                 Symbol panel    [on]  Trigger [ ## ]   "Type ##arrow…"
                 Rank frequently used first [on]
Emoticons        Emoticons                [on]   "Suggests ^_^ as you type ^_"
                 Autocomplete after   [−] 2 characters [+]    (− from 2 → Off; max 6)
                 Trigger              [      ]  "None. Set one, e.g. ;;, to search by name"
Aliases          Convert while typing [on]   "-> becomes →"
                 Show in search results [on]
                 Customize…   (3 of yours)
Menu Bar / General / About / Quit
```
- Aliases are **decoupled** from the emoji panel: the event tap runs while *any* of emoji panel,
  symbol panel, emoticons (autocomplete or trigger) or alias conversion is on, and it's removed
  when all are off (same revocation safety).
- The Emoticons switch off disables autocomplete and the trigger together. The two rows below it
  dim, like today's dependent rows. A blank trigger is valid and means "no trigger".
- Trigger validation is per field and live, as today. New rule: **no trigger may contain another**
  ("Already used by the Symbol panel (##)"). The stored value always stays valid.

### Aliases page (redesign)

```
‹ Settings              Aliases                    [ + ]
[ 🔍 Filter aliases                                    ]
ARROWS                                   6 of 6 on [◐]
  ->            →   Rightwards Arrow              [on]
  [x] (v)       ✓ ✔ ☑   Check mark  ✎ yours       [on]
  + Add Arrow Alias…
MATH …   SYMBOLS …   EMOTICONS → EMOJI …   EMOJI (yours only) …
                     [Turn All On]
```
- Groups: Arrows, Math, Symbols, Emoticons, **Emoji** (new, custom only). Your aliases sit at the
  top of their group with a "yours" tag. Hover shows ✎, and double-click or the context menu gives Edit / Duplicate / Delete.
- The filter field matches spelling, output or name. Each group header has a count and a group switch (on / off / mixed).
- Built-in names come from the output's Unicode or emoji name, so there are no new string tables.

### Alias editor (sheet)

```
New Alias
Name       [ Check mark                 ]   Search: ::check  ##check  ;;check
Group      [ Symbols ▾ ]
You type   [ [x]          ] (−)
           [ (v)          ] (−)
           (+) Add spelling
Becomes    ◉ [ ✓ ] (−)   ← used when typing
           ○ [ ✔ ] (−)
           ○ [ ☑ ] (−)
           (+) Add output        [Emoji & Symbols…]
[✓] Only at the start of a word
Preview:  typing "[x]" gives ✓
[Delete]                               [Cancel] [Save]
```
- "Emoji & Symbols…" opens the system Character Viewer into the focused output field.
- Validation is inline under each row, and Save is disabled while anything is invalid:
  - **Name**: 1–40 chars, required.
  - **Spelling**: 2–16 chars, no whitespace, not only letters/digits (so it can't fire inside a word, same rule as the trigger), must not contain an active trigger, and unique among your aliases.
  - **Output**: 1–64 chars, no newlines, max 8 spellings and 8 outputs, max 200 aliases.
- If a spelling matches a built-in, your alias wins and a hint says "Replaces built-in → (Rightwards arrow)".
- Escape cancels. Delete asks for confirmation, and deleting also removes the alias's ID from `disabledTextAliases`.

### Corners covered (behaviour)
- Last trigger typed wins (`::a##b` opens Symbols). A trigger after a letter or digit never opens (`std::`, `a##b` C token-paste, `x;;`).
- `## Heading` and `;; comment` (with a space) never open. A Markdown `##word` opens, and Esc closes it.
- Long replacements: `TextInserter` posts in ≤20-UTF-16-unit chunks split on grapheme boundaries (CGEvent truncates longer strings). This fixes kaomoji and long custom outputs.
- Alias chains keep working with custom aliases, built through the same `TextAliasConverter` init.
- Recents are shared and keyed by text (`emojiRecents` key unchanged), and the limit is raised to 72. Each picker tab and panel shows only its own (catalog lookup drops the rest). An older MacJi shows only the emoji, so downgrading is safe.
- Use counts are shared: symbols, emoticons and alias outputs get frequency ranking too.
- `customTextAliases` is stored as a plist array of dictionaries. An element that can't be read (bad type, or a newer MacJi's group) is skipped at read time but **kept and written back unchanged**, following the per-key fallback and no-deletion rule.
- Picker and panels need no Accessibility for search. Secure Input, revocation and tap hygiene are unchanged.

---

## Data

| Data | Source | Script → file | Licence |
|---|---|---|---|
| Symbols (~1.5k) | Python `unicodedata` names over curated blocks (Arrows, Math operators + supplemental, Greek, Currency, General punctuation, Letterlike, Number forms + super/subscripts + enclosed digits, Geometric shapes/stars, Misc technical incl. ⌘⌥⇧⌃⎋⏎⌫⇥). Excludes anything in `emoji.json`, controls and combining marks. A curated keyword table adds LaTeX/HTML names (`alpha`, `rarr`, `inf`, `deg`, `cmd`) | `scripts/update-symbol-data.py` → `symbols.json` | `LICENSES/unicode-LICENSE.txt` (Unicode License v3) |
| ASCII emoticons (~200) | [wooorm/emoticon](https://github.com/wooorm/emoticon) `index.js` (MIT, already credited): 29 named entries with description, tags and every ASCII spelling (`:-)` `>:(` `T-T`). This is what autocomplete mostly matches | `scripts/update-emoticon-data.py <index.js> <kaomoji.json>` → `emoticons.json`. It parses the data literal and runs no JavaScript | `LICENSES/emoticon-MIT.txt` (exists) |
| Kaomoji (~100) | [netromdk/kaomojidict](https://github.com/netromdk/kaomojidict) `kaomoji.json` v10 (MIT, 111 entries, English tags). The script drops brand/company-mocking entries (deny list), maps tags to categories (Happy, Love, Sad, Angry, Surprised, Shrug, Flip, Greeting, Animals, Other) and names each face | same script, same file | `LICENSES/kaomojidict-MIT.txt` |

Each output is written in `emoji.json`'s shape (`emoji`, `description`, `category`, `aliases`, `tags`), so one decoder reads all three.
Considered and not used: wavebeem/kaomoji (MIT, categories only, no names or tags), kaomoji-chart (GPL), node-kaomoji (unclear licence).

---

## Architecture

- **Shared glyph layer** (phase 0, a mechanical rename with no behaviour change): `Emoji`→`Glyph`,
  `EmojiSection`→`GlyphSection`, `EmojiCatalog`→`GlyphCatalog<Category: GlyphCategory>`,
  `EmojiSearch`→`GlyphSearch` (ranking untouched), `EmojiCell`→`GlyphCell` (+ wide `GlyphRow`),
  `EmojiGrid`→`GlyphGrid` (wide glyphs take a row each, so `MenuGridNavigator` works unchanged),
  `EmojiClipboard`→`GlyphClipboard`, `EmojiRecents`→`GlyphRecents` (keys unchanged). Folders:
  `Shared/EmojiData`→`Shared/Glyphs`, `Shared/EmojiUI`→`Shared/GlyphUI`. Fix the path in
  `scripts/update-emoji-data.py` and `scripts/make-web-assets.sh`. `EmojiCategory` stays, and
  `SymbolCategory` and `EmoticonCategory` are added. `GlyphLibrary.loadBundled()` loads the three catalogs off the main thread.
- **Shared aliases**: move `TextAlias`, `TextAliasCatalog` to `Shared/TextAliases/`, because the picker needs them for search
  (`TextAliasConverter` stays in InlinePanel). Add `TextAlias.name`, `replacements: [String]`
  (first one is typed), `isCustom`, and `.emoji` group. New `CustomTextAliasStore` (plist read/write,
  lenient), `CustomTextAliasValidator` (pure, returns `Problem`s like `InlineTrigger`), `AliasGlyphs`
  (enabled aliases → searchable `Glyph`s, names from catalogs or Unicode).
- **Multi-trigger tracker**: `TriggerTracker(triggers: [PanelKind: String])`. `query` returns
  `(kind, term)` for the last trigger in the buffer, and the buffer limit uses the longest trigger.
  `InlineTrigger.problem(with:others:)` adds `.overlaps(PanelKind)`. The emoticon trigger
  may be blank (= none), and blank triggers take no part in the overlap check.
- **Emoticon autocomplete**: new pure `EmoticonAutocomplete` (InlinePanel). It takes the buffer,
  minimum length, active triggers and the prefix set, and returns the run or nil. It also gets a
  "dismissed run" so Esc holds until the next whitespace. The controller asks it only when no
  trigger query is open, and `replacementLength` becomes the run length.
- **Inline panel**: `InlinePanelModel` gains `kind`, `category` and its catalogs. It searches the
  kind's catalog plus alias glyphs. `InlinePanelKeys` adds Tab/⇧Tab (`.nextFilter`/`.previousFilter`)
  for filterable kinds. `InlinePanelController.configure` takes one `InlinePanelConfiguration`
  (per-kind enabled and trigger, ranking, aliases), and `startListening` runs when anything needs the tap.
- **Category bar**: move `EmojiPickerCategoryBar` to `Shared/MenuKit/CategoryBar.swift`, generic over `GlyphCategory`, so both features use it without importing each other.
- **Picker**: `EmojiPickerModel` gains `tab: PickerTab`, per-tab catalog and category, and alias glyphs.
  `EmojiPickerKeys` adds ⌘1–3. `EmojiPickerView` adds `PickerTabBar`.
- **Settings**: new keys in `PreferenceKeys` (`symbolPanelEnabled`, `symbolPanelTrigger`,
  `emoticonsEnabled`, `emoticonAutocompleteLength` (Int, 0 = Off, default 2, range 2–6, out of
  range falls back to 2 at read time), `emoticonPanelTrigger` (default ""), `showAliasesInSearch`, `customTextAliases`,
  `pickerShowsSymbols`, `pickerShowsEmoticons`, `pickerLastTab`), all registered and never written at launch.
  No migration is needed (only new keys). New sections `InlinePanelsSection` (replaces
  `InlinePanelSection`), `EmoticonsSection` (switch, `− N +` stepper with Off, trigger field) and
  `AliasesSection`. `TextAliasesPage` is rebuilt, and `AliasEditorSheet` + `AliasRow` go in `Settings/Components`.
- **Composition root** (`AppDelegate.wireSettings`): one publisher chain builds the panel
  configuration, the converter list (built-in + custom − disabled) and alias glyphs, then forwards them to both features.
- Every literal goes in `Constants/` (new `Strings/AliasStrings.swift`, metrics in `PanelMetrics`/`PickerMetrics`/`SettingsMetrics`, `Limits` for the caps). Headers via `scripts/new-file.sh`, files under 300 lines.

---

## Phases → one commit each (branch `macji-build`, emoji in every message, Co-Authored-By trailer)

0. ♻️ Generalise emoji data into the shared glyph layer (rename only; tests green; repo_map regenerated)
1. 🔣 Symbol and emoticon data: two scripts, `symbols.json`, `emoticons.json`, licences, catalog tests
2. ⌨️ Multi-trigger tracker + chunked `TextInserter` + trigger overlap validation (tests)
3. 🔣 Symbol and emoticon inline panels: kinds, wide rows, Tab filters, shared `CategoryBar`, Settings "Inline Panels" section
3b. (^_^) Emoticon autocomplete + Emoticons section (switch, stepper, optional trigger)
4. 🧭 Picker tabs: Emoji / Symbols / Emoticons, ⌘1–3, per-tab recents, tab toggles
5. ✍️ Custom aliases: model, lenient store, validator, converter integration (tests)
6. 🎛️ Aliases page redesign + alias editor sheet with + spellings / + outputs, Aliases section
7. 🔎 Aliases in search across all panels + "Show in search results" toggle
8. 📚 Docs: README (Features, Usage, Settings, Privacy), CLAUDE.md (feature list, trigger rule,
   data sources), PRIVACY.md (custom aliases stored locally), repo_map.md, convert-symbols.md
   (custom aliases), ARCHITECTURE.md, screenshots via `scripts/make-screenshots.sh` (if ffmpeg is present)
9. 🧹 Review fixes, from parallel review agents: `/code-review high`, `/simplify`, and a strict
   "thermo-nuclear" code-quality agent. `/thermo-nuclear-code-quality-review` and `/postsession`
   aren't installed here, so the strict agent stands in for the first, and context-eng `memory_create` for the second.
   Then `/improve` (read-only audit) with its report saved in the scratchpad, and memory saved.
10. 🚀 `scripts/bump-version.sh minor` → 0.3.0 + CHANGELOG notes. No tag, push or release.

## Tests (pure logic only, Swift Testing)
- Tracker: three triggers, last wins, after-letter ignored, per-kind term, buffer limit.
- Trigger validation: overlap rule both ways, blank emoticon trigger valid, read-time fallback.
- Emoticon autocomplete: threshold N and Off, needs a non-letter/digit (`ow` ≠ `owo`), literal
  case-sensitive prefix, trigger runs and deny-listed starts ignored, Esc dismissal lasts until
  whitespace, an alias conversion ends the run.
- Stepper value: out-of-range stored value falls back to 2.
- `TextInserter` chunking: splits ≤20 UTF-16 units without breaking a grapheme (¯\_(ツ)_/¯, flags, ZWJ).
- Symbol and emoticon catalogs: every category in the JSON is known, nothing duplicates `emoji.json`, and `##arrow` ranks → first.
- Custom alias validator: each `Problem`. Store round-trip, with an unreadable element preserved on write.
- Converter: custom overrides built-in, first output typed, chains still work.
- Alias glyphs: name search, dedupe against catalog results, disabled ones excluded.
- Keys: Tab / ⇧Tab only for filterable kinds, ⌘1–3 in the picker. Picker tab hiding and per-tab recents.

## Verification
- `scripts/test.sh` (names present, zero-test guard), `scripts/check.sh`, and `./build.sh` (prints the running `.app`) at every phase.
- Live check in TextEdit with computer-use, Octopus's MacJi turned off: `##arr`↩, autocomplete `^_`↩ and `:-` → Esc → keep typing, a set `;;shrug`↩, `::check` showing custom outputs, a custom `[x]`→✓ conversion, Tab filters, picker tabs, every toggle off actually stops its feature, and a long kaomoji arriving intact.
- The final report says exactly what was checked live and what wasn't (e.g. Electron apps, Secure Input).
