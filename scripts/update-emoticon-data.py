#!/usr/bin/env python3
#
#  update-emoticon-data.py
#  MacJi
#
#  Created: 2026-11-27
#  Builds emoticons.json from wooorm/emoticon's ASCII emoticons, netromdk/kaomojidict's kaomoji and
#  a short list of classic faces, in emoji.json's shape.
#
####################
#### Usage
### scripts/update-emoticon-data.py <wooorm-emoticon-index.js> <kaomojidict-kaomoji.json>
###   Sources: https://github.com/wooorm/emoticon/blob/main/index.js (MIT, LICENSES/emoticon-MIT.txt)
###            https://github.com/netromdk/kaomojidict/blob/main/kaomoji.json (MIT, LICENSES/kaomojidict-MIT.txt)
# Example: scripts/update-emoticon-data.py ~/Downloads/index.js ~/Downloads/kaomoji.json
# index.js is read as data (its array literal is parsed, never run). Kaomoji tagged with a brand or
# with violence, and frame templates holding "TEXT", are left out.
##################

import ast
import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "MacJi/Shared/Glyphs/Resources/emoticons.json"

####################
#### Categories
### Raw values must match EmoticonCategory in MacJi/Shared/Glyphs/GlyphCategory.swift.
### A kaomoji takes the first category whose tag it carries, in this order.

CATEGORY_TAGS = [
    ("Flip", {"flip", "tableflip", "noflip", "table"}),
    ("Shrug", {"shrug", "shrugging", "whatever", "dunno"}),
    ("Animals", {"cat", "kitty", "neko", "bear"}),
    ("Angry", {"angry", "mad", "rage", "grr", "furious", "annoyed"}),
    ("Sad", {"sad", "cry", "crying", "sob", "tears", "depressed", "despair"}),
    ("Love", {"love", "luv", "hug", "cuddle", "kiss", "heart", "crush"}),
    ("Surprised", {"surprised", "shock", "shocked", "omg", "wtf", "confused", "gasp", "huh", "what"}),
    ("Greeting", {"hello", "hi", "hey", "wave", "bye", "goodbye"}),
    ("Happy", {"happy", "joy", "smile", "yay", "woohoo", "haha", "lol", "laugh", "giggle", "cute"}),
]
OTHER = "Other"

#### wooorm/emoticon entries by their gemoji name.
WOOORM_CATEGORY = {
    "angry": "Angry", "rage": "Angry", "imp": "Angry", "smiling_imp": "Other",
    "blush": "Happy", "innocent": "Happy", "joy": "Happy", "laughing": "Happy", "smile": "Happy",
    "smiley": "Happy", "sweat_smile": "Happy", "wink": "Happy", "sunglasses": "Happy",
    "stuck_out_tongue": "Happy", "stuck_out_tongue_closed_eyes": "Happy",
    "stuck_out_tongue_winking_eye": "Happy",
    "heart": "Love", "kissing": "Love",
    "broken_heart": "Sad", "cry": "Sad", "frowning": "Sad", "sob": "Sad", "sweat": "Sad",
    "confused": "Surprised", "open_mouth": "Surprised",
}

##################

####################
#### What is left out of kaomojidict
### Faces that mock a company or product, threaten, or are frame templates ("TEXT").

DENIED_TAGS = {
    "microsoft", "microslop", "facebook", "fb", "meta", "ig", "insta", "instagram", "openai",
    "anthropic", "misanthropic", "claude", "claudeai", "claudecode", "clanker", "violence",
    "knife", "heathen",
}

##################

####################
#### Classic faces
### Well-known kaomoji and ASCII faces the two sources lack; the ASCII ones are what
### autocomplete can match as you type ("(^" → (^_^), "o_" → o_O).

CLASSICS = [
    ("¯\\_(ツ)_/¯", "shrug", "Shrug", ["whatever", "dunno"]),
    ("( ͡° ͜ʖ ͡°)", "lenny face", "Other", ["lenny", "smirk"]),
    ("(ノಠ益ಠ)ノ彡┻━┻", "table flip rage", "Flip", ["tableflip", "angry"]),
    ("┬─┬ノ( º _ ºノ)", "put the table back", "Flip", ["unflip", "calm"]),
    ("ʕ•ᴥ•ʔ", "bear", "Animals", ["cute"]),
    ("(ᵔᴥᵔ)", "happy bear", "Animals", ["cute"]),
    ("༼ つ ◕_◕ ༽つ", "give hug", "Love", ["hug", "gimme"]),
    ("(☞ﾟヮﾟ)☞", "finger guns", "Happy", ["you", "point"]),
    ("ᕦ(ò_óˇ)ᕤ", "flexing", "Happy", ["strong", "muscle"]),
    ("(¬‿¬)", "smirk", "Other", ["sly"]),
    ("ლ(ಠ益ಠლ)", "why", "Angry", ["frustrated"]),
    ("(^_^)", "happy", "Happy", ["smile", "joy"]),
    ("(^_^;)", "nervous smile", "Happy", ["sweat", "awkward"]),
    ("^_^", "happy", "Happy", ["smile"]),
    ("^_~", "wink", "Happy", ["playful"]),
    ("(>_<)", "frustrated", "Angry", ["ugh", "argh"]),
    ("o_O", "confused", "Surprised", ["what", "huh"]),
    ("O_o", "confused", "Surprised", ["what", "huh"]),
    ("(o_O)", "confused", "Surprised", ["what", "huh"]),
    ("(T_T)", "crying", "Sad", ["cry", "tears"]),
    ("T_T", "crying", "Sad", ["cry", "tears"]),
    ("(-_-)", "unimpressed", "Other", ["meh", "bored"]),
    ("(-_-)zzz", "sleeping", "Other", ["sleep", "tired"]),
    ("\\(^o^)/", "cheering", "Happy", ["yay", "hooray"]),
    ("\\o/", "cheering", "Happy", ["yay", "hooray"]),
    ("(*^_^*)", "blushing", "Happy", ["shy", "blush"]),
    ("(^_-)", "wink", "Happy", ["playful"]),
    ("(^.^)", "cute smile", "Happy", ["smile"]),
    ("<(^_^)>", "dancing", "Happy", ["dance"]),
    ("m(_ _)m", "bowing", "Other", ["sorry", "thanks", "bow"]),
    ("(._.)", "sad", "Sad", ["down"]),
    ("(;_;)", "crying", "Sad", ["cry", "tears"]),
    ("(=^.^=)", "cat", "Animals", ["kitty", "cute"]),
    ("(o^^)o", "punching", "Angry", ["fight"]),
    ("(?_?)", "confused", "Surprised", ["huh", "what"]),
]

##################


def wooorm_records(index_js: Path) -> list[dict]:
    ### The exported array is a JavaScript literal; quoting its bare keys makes it a Python literal.
    source = index_js.read_text(encoding="utf-8")
    match = re.search(r"export const emoticon = (\[.*\])\s*$", source, re.S)
    if not match:
        raise ValueError("no `export const emoticon = [...]` array")
    literal = re.sub(r"^(\s*)(description|emoji|emoticons|name|tags):", r"\1'\2':", match.group(1), flags=re.M)
    entries = ast.literal_eval(literal)
    return [
        {"emoji": text, "description": entry["description"],
         "category": WOOORM_CATEGORY.get(entry["name"], OTHER),
         "aliases": [entry["name"]], "tags": entry["tags"]}
        for entry in entries for text in entry["emoticons"]
    ]


def kaomoji_records(kaomoji_json: Path) -> list[dict]:
    faces = json.loads(kaomoji_json.read_text(encoding="utf-8"))["kaomoji"]
    records = []
    for face, locales in faces.items():
        tags = locales.get("*", []) + locales.get("en", [])
        if "TEXT" in face or DENIED_TAGS.intersection(tags):
            continue
        category, tag = next(((name, next(t for t in tags if t in wanted)) for name, wanted in CATEGORY_TAGS
                              if wanted.intersection(tags)), (OTHER, tags[0] if tags else "kaomoji"))
        records.append({"emoji": face, "description": tag, "category": category, "aliases": [], "tags": tags})
    return records


def classic_records() -> list[dict]:
    return [{"emoji": face, "description": name, "category": category, "aliases": [], "tags": tags}
            for face, name, category, tags in CLASSICS]


def main() -> int:
    if len(sys.argv) != 3 or sys.argv[1] in ("-h", "--help"):
        print("Usage: scripts/update-emoticon-data.py <wooorm-emoticon-index.js> <kaomojidict-kaomoji.json>")
        return 0 if len(sys.argv) == 2 else 1
    sources = [Path(argument) for argument in sys.argv[1:]]
    for source in sources:
        if not source.is_file():
            print(f"✗ No such file: {source}\n  fix: pass wooorm/emoticon's index.js and kaomojidict's kaomoji.json",
                  file=sys.stderr)
            return 1
    try:
        records = classic_records() + wooorm_records(sources[0]) + kaomoji_records(sources[1])
    except (ValueError, SyntaxError, KeyError, TypeError, json.JSONDecodeError) as error:
        print(f"✗ Unexpected source format: {error}\n  fix: check the upstream files still have the same shape",
              file=sys.stderr)
        return 1
    ### First spelling wins; Swift compares strings canonically, so dedupe on the NFC form.
    unique = list({unicodedata.normalize("NFC", record["emoji"]): record for record in reversed(records)}.values())[::-1]
    OUTPUT.write_text(json.dumps(unique, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"✓ Wrote {len(unique)} emoticons to {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
