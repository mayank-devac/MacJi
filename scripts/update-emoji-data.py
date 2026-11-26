#!/usr/bin/env python3
#
#  update-emoji-data.py
#  MacJi
#
#  Created: 2026-11-26
#  Strips a gemoji emoji.json to the five fields MacJi reads and writes it compactly into the app.
#
####################
#### Usage
### scripts/update-emoji-data.py <path-to-gemoji-db-emoji.json>
###   Source: https://github.com/github/gemoji/blob/master/db/emoji.json (MIT, LICENSES/gemoji-MIT.txt)
# Example: scripts/update-emoji-data.py ~/Downloads/emoji.json
# Records with a category MacJi does not know are kept; the app skips them until EmojiCategory learns them.
##################

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "MacJi/Shared/Glyphs/Resources/emoji.json"
FIELDS = ("emoji", "description", "category", "aliases", "tags")


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__ or "", end="")
        print("Usage: scripts/update-emoji-data.py <gemoji emoji.json>")
        return 0 if len(sys.argv) == 2 else 1
    source = Path(sys.argv[1])
    if not source.is_file():
        print(f"✗ No such file: {source}\n  fix: pass gemoji's db/emoji.json", file=sys.stderr)
        return 1
    try:
        records = json.loads(source.read_text(encoding="utf-8"))
        stripped = [{field: record[field] for field in FIELDS} for record in records]
    except (json.JSONDecodeError, KeyError, TypeError) as error:
        print(f"✗ Not a gemoji emoji.json: {error}\n  fix: use db/emoji.json from github/gemoji", file=sys.stderr)
        return 1
    OUTPUT.write_text(json.dumps(stripped, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    print(f"✓ Wrote {len(stripped)} emoji to {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size // 1024} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
