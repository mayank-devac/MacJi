#!/usr/bin/env python3
#
#  update-symbol-data.py
#  MacJi
#
#  Created: 2026-11-27
#  Builds symbols.json from Unicode character names: arrows, math, Greek, currency, punctuation,
#  letterlike, numbers, shapes, signs and Mac keys, in emoji.json's shape.
#
####################
#### Usage
### scripts/update-symbol-data.py
###   Source: Python's unicodedata (Unicode Character Database, LICENSES/unicode-LICENSE.txt)
# Characters gemoji shows as emoji by default are left out, so a symbol never duplicates an emoji.
# Text-style characters that gemoji also lists with U+FE0F (→ ↔ © ™) stay, as plain text.
# Rerun after a Python upgrade to pick up a newer Unicode version; the order is stable.
##################

import json
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "MacJi/Shared/Glyphs/Resources"
OUTPUT = RESOURCES / "symbols.json"
EMOJI = RESOURCES / "emoji.json"

####################
#### Categories and the code points they take
### Raw values must match SymbolCategory in MacJi/Shared/Glyphs/GlyphCategory.swift.
### A code point listed twice keeps its first category; MOVED overrides that.
# Mixed blocks (Misc Symbols and Arrows) put every "ARROW" name under Arrows.

LATIN1 = {
    "Math": [0x00AC, 0x00B0, 0x00B1, 0x00D7, 0x00F7],
    "Currency": [0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x0E3F],
    "Punctuation": [0x00A1, 0x00A7, 0x00AB, 0x00B6, 0x00B7, 0x00BB, 0x00BF],
    "Letterlike": [0x00A9, 0x00AE],
    "Numbers": [0x00B9, 0x00B2, 0x00B3, 0x00BC, 0x00BD, 0x00BE],
}

BLOCKS = [
    ("Arrows", 0x2190, 0x21FF), ("Arrows", 0x27F0, 0x27FF), ("Arrows", 0x2900, 0x297F),
    ("Math", 0x2200, 0x22FF), ("Math", 0x27C0, 0x27EF),
    ("Greek", 0x0391, 0x03A9), ("Greek", 0x03B1, 0x03C9), ("Greek", 0x03D1, 0x03D6),
    ("Currency", 0x20A0, 0x20C0),
    ("Punctuation", 0x2010, 0x2027), ("Punctuation", 0x2030, 0x205E),
    ("Letterlike", 0x2100, 0x214F),
    ("Numbers", 0x2070, 0x209C), ("Numbers", 0x2150, 0x218B), ("Numbers", 0x2460, 0x24FF),
    ("Numbers", 0x2776, 0x2793),
    ("Shapes", 0x25A0, 0x25FF), ("Shapes", 0x2B00, 0x2BFF), ("Shapes", 0x2580, 0x259F),
    ("Shapes", 0x2500, 0x257F),
    ("Signs", 0x2600, 0x26FF), ("Signs", 0x2700, 0x27BF),
    ("Technical", 0x2300, 0x23FF), ("Technical", 0x2423, 0x2423),
]

MOVED = {0x21E7: "Technical", 0x21EA: "Technical", 0x21E4: "Technical", 0x21E5: "Technical"}

#### Names that start with these are left out: APL operators fill Misc Technical but nobody types them.
SKIPPED_NAMES = ("APL FUNCTIONAL SYMBOL",)

#### The Apple logo has no Unicode name (private use), so it is added by hand.
APPLE_LOGO = {"emoji": "", "description": "apple logo", "category": "Technical",
              "aliases": ["apple", "mac"], "tags": []}

##################

####################
#### Search keywords
### Short names people already type: HTML entity names, LaTeX names and plain words.
# Unicode names are searched too, so "rightwards" already finds →; these add "rarr", "cmd" and friends.

KEYWORDS = {
    "→": ["rarr", "right", "to"], "←": ["larr", "left"], "↑": ["uarr", "up"], "↓": ["darr", "down"],
    "↔": ["harr"], "↕": ["varr"], "⇒": ["rarr2", "implies"], "⇐": ["larr2"], "⇔": ["harr2", "iff"],
    "↦": ["mapsto"], "⟶": ["longrightarrow"], "⟵": ["longleftarrow"], "⟹": ["longimplies"],
    "↗": ["nearr"], "↘": ["searr"], "↖": ["nwarr"], "↙": ["swarr"], "↻": ["reload", "refresh", "redo"],
    "↺": ["undo"], "⇄": ["swap"],
    "≠": ["ne", "neq"], "≤": ["le", "leq"], "≥": ["ge", "geq"], "±": ["pm", "plusminus"], "∓": ["mp"],
    "×": ["times", "multiply"], "÷": ["div", "divide"], "≈": ["approx"], "≡": ["equiv"],
    "∞": ["infin", "infinity", "inf"], "√": ["sqrt", "radic", "root"], "∑": ["sum"], "∏": ["prod"],
    "∫": ["int", "integral"], "∂": ["part", "partial"], "∆": ["delta"], "∇": ["nabla"],
    "∈": ["isin", "in"], "∉": ["notin"], "∅": ["empty", "emptyset"], "∩": ["cap"], "∪": ["cup"],
    "⊂": ["sub", "subset"], "⊃": ["sup", "superset"], "⊆": ["sube", "subseteq"], "⊇": ["supe"],
    "∀": ["forall"], "∃": ["exist", "exists"], "¬": ["not"], "∧": ["and", "wedge"], "∨": ["or", "vee"],
    "⊕": ["oplus", "xor"], "⊗": ["otimes"], "∝": ["prop"], "∠": ["ang"], "⊥": ["perp"],
    "∴": ["there4", "therefore"], "∵": ["because"], "°": ["deg", "degree"], "⋅": ["sdot", "cdot"],
    "∘": ["compose"], "∛": ["cbrt"], "∼": ["sim"], "≅": ["cong"], "≪": ["ll"], "≫": ["gg"],
    "€": ["euro", "eur"], "£": ["pound", "gbp"], "¥": ["yen", "jpy"], "₹": ["rupee", "inr"],
    "₩": ["won", "krw"], "₽": ["ruble", "rub"], "₿": ["bitcoin", "btc"], "¢": ["cent"],
    "₺": ["lira"], "₱": ["peso"], "₴": ["hryvnia"], "₦": ["naira"], "₫": ["dong"],
    "—": ["mdash", "emdash", "dash"], "–": ["ndash", "endash", "dash"], "…": ["hellip", "ellipsis", "dots"],
    "•": ["bull", "bullet"], "‘": ["lsquo", "quote"], "’": ["rsquo", "apostrophe", "quote"],
    "“": ["ldquo", "quote"], "”": ["rdquo", "quote"], "«": ["laquo", "guillemet"], "»": ["raquo", "guillemet"],
    "‹": ["lsaquo"], "›": ["rsaquo"], "§": ["sect"], "¶": ["para", "pilcrow"], "†": ["dagger"],
    "‡": ["ddagger"], "¡": ["iexcl"], "¿": ["iquest"], "‽": ["interrobang"], "·": ["middot"],
    "©": ["copy"], "®": ["reg"], "™": ["trade", "tm"], "℃": ["celsius"], "℉": ["fahrenheit"],
    "№": ["numero", "no"], "℗": ["phonogram"], "℠": ["servicemark", "sm"],
    "½": ["frac12", "half"], "¼": ["frac14", "quarter"], "¾": ["frac34"], "⅓": ["frac13", "third"],
    "⅔": ["frac23"], "¹": ["sup1"], "²": ["sup2", "squared"], "³": ["sup3", "cubed"],
    "✓": ["check", "tick", "done"], "✔": ["check", "tick"], "✗": ["cross", "x"], "✘": ["cross", "x"],
    "★": ["star"], "☆": ["star"],
    "⌘": ["cmd", "command"], "⌥": ["opt", "option", "alt"], "⇧": ["shift"], "⌃": ["ctrl", "control"],
    "⎋": ["esc", "escape"], "⏎": ["return", "enter"], "⌫": ["delete", "backspace"],
    "⌦": ["del", "forwarddelete"], "⇥": ["tab"], "⇤": ["backtab"], "⇪": ["caps", "capslock"],
    "⏻": ["power"], "␣": ["space"], "⌀": ["diameter"],
}

##################


def emoji_presentation(emoji_path: Path) -> set[str]:
    ### Single code points gemoji lists without U+FE0F render as emoji by default.
    records = json.loads(emoji_path.read_text(encoding="utf-8"))
    return {record["emoji"] for record in records if len(record["emoji"]) == 1}


def category_of(code: int, default: str) -> str:
    if code in MOVED:
        return MOVED[code]
    if default == "Shapes" and 0x2B00 <= code <= 0x2BFF and "ARROW" in unicodedata.name(chr(code), ""):
        return "Arrows"
    return default


def symbol_record(code: int, category: str) -> dict | None:
    character = chr(code)
    name = unicodedata.name(character, "")
    ### Ω OHM SIGN normalises to Greek Ω; Swift compares strings canonically, so keep only one of them.
    if unicodedata.normalize("NFC", character) != character:
        return None
    if not name or unicodedata.category(character)[0] in "MCZ" or name.startswith(SKIPPED_NAMES):
        return None
    return {"emoji": character, "description": name.lower(), "category": category,
            "aliases": KEYWORDS.get(character, []), "tags": []}


def main() -> int:
    if len(sys.argv) > 1:
        print("Usage: scripts/update-symbol-data.py   (no arguments; reads Python's unicodedata)")
        return 0 if sys.argv[1] in ("-h", "--help") else 1
    if not EMOJI.is_file():
        print(f"✗ Missing {EMOJI.relative_to(ROOT)}\n  fix: run scripts/update-emoji-data.py first", file=sys.stderr)
        return 1
    excluded = emoji_presentation(EMOJI)
    ranges = [(category, code) for category, codes in LATIN1.items() for code in codes]
    ranges += [(category, code) for category, first, last in BLOCKS for code in range(first, last + 1)]
    seen: set[int] = set()
    records = []
    for category, code in ranges:
        if code in seen or chr(code) in excluded:
            continue
        seen.add(code)
        record = symbol_record(code, category_of(code, category))
        if record:
            records.append(record)
    records.append(APPLE_LOGO)
    order = ["Arrows", "Math", "Greek", "Currency", "Punctuation", "Letterlike", "Numbers", "Shapes", "Signs", "Technical"]
    records.sort(key=lambda record: order.index(record["category"]))
    OUTPUT.write_text(json.dumps(records, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"✓ Wrote {len(records)} symbols (Unicode {unicodedata.unidata_version}) to "
          f"{OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
