#!/usr/bin/env python3
#
#  repo-map.py
#  MacJi
#
#  Created: 2026-11-26
#  Regenerates the tree in repo_map.md from the files git knows about, keeping every hand-written
#  one-line description. New entries are marked "TODO: describe".
#
####################
#### Usage
### scripts/repo-map.py           rewrite the tree between the repo-map markers
### scripts/repo-map.py --check   change nothing; exit 1 when the tree is stale or has a TODO
# Example: scripts/new-file.sh MacJi/Shared/EmojiUI/Thing.swift "…" && scripts/repo-map.py
# Lists tracked files plus new files git doesn't ignore. Generated folders are listed, not expanded.
##################

import argparse
import difflib
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import config  # noqa: E402

MAP = config.ROOT / "repo_map.md"
START = "<!-- repo-map:tree:start -->"
END = "<!-- repo-map:tree:end -->"
TODO = "TODO: describe"
INDENT = "  "

####################
#### Folders listed without their contents
### Their files are generated or belong to another repository, so one line describes them all.

COLLAPSED = {
    "MacJi.xcodeproj",
    "Upstream/octopus",
    "MacJi/Resources/Assets.xcassets/AppIcon.appiconset",
    "assets/icon",
    "assets/screenshots",
}

##################


def repository_paths():
    output = subprocess.run(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
        cwd=config.ROOT, check=True, capture_output=True, text=True,
    ).stdout
    paths = set()
    for path in filter(None, output.split("\0")):
        if not (config.ROOT / path).exists() and not (config.ROOT / path).is_symlink():
            continue
        parts = path.split("/")
        for depth in range(1, len(parts) + 1):
            prefix = "/".join(parts[:depth])
            if prefix in COLLAPSED:
                paths.add(prefix + "/")
                break
        else:
            paths.add(path)
    return paths


####################
#### Tree model
### Each path becomes a chain of folders ending in a file; a collapsed folder ends in "/".
# Entries sort by name, files and folders together, which keeps LICENSE next to LICENSES/.

def build_tree(paths):
    root = {}
    for path in paths:
        node = root
        parts = path.rstrip("/").split("/")
        for index, part in enumerate(parts):
            is_last = index == len(parts) - 1
            is_folder = not is_last or path.endswith("/")
            node = node.setdefault((part, is_folder), {})
    return root


def render(node, descriptions, todos, prefix="", depth=0):
    lines = []
    for (name, is_folder) in sorted(node, key=lambda key: key[0]):
        path = f"{prefix}{name}"
        label = f"{name}/" if is_folder else name
        description = descriptions.get(path) or TODO
        if description == TODO:
            todos.append(path)
        lines.append(f"{INDENT * depth}{label} — {description}")
        lines += render(node[(name, is_folder)], descriptions, todos, f"{path}/", depth + 1)
    return lines

##################


def read_descriptions(block):
    descriptions, stack = {}, []
    for line in block:
        match = re.match(r"^( *)(\S.*?)(?: — (.*))?$", line)
        if not match or line.startswith("```"):
            continue
        depth = len(match.group(1)) // len(INDENT)
        name = match.group(2).rstrip("/")
        stack[depth:] = [name]
        descriptions["/".join(stack)] = match.group(3)
    return descriptions


def main():
    parser = argparse.ArgumentParser(description="Regenerate the tree in repo_map.md.")
    parser.add_argument("--check", action="store_true", help="change nothing; exit 1 when stale")
    args = parser.parse_args()

    text = MAP.read_text()
    if START not in text or END not in text:
        sys.exit(f"✗ repo_map.md is missing the {START} / {END} markers.\n  fix: restore them from git.")
    head, rest = text.split(START, 1)
    old_block, tail = rest.split(END, 1)
    old_lines = old_block.strip("\n").splitlines()

    todos = []
    tree = render(build_tree(repository_paths()), read_descriptions(old_lines), todos)
    new_lines = ["```text", *tree, "```"]

    if args.check:
        if old_lines != new_lines:
            diff = difflib.unified_diff(old_lines, new_lines, "repo_map.md", "disk", n=0, lineterm="")
            print("\n".join(line for line in diff if not line.startswith("@@")))
            sys.exit("✗ repo_map.md doesn't match the tree.\n  fix: run scripts/repo-map.py and describe new entries.")
        if todos:
            sys.exit("✗ repo_map.md has entries without a description:\n  " + "\n  ".join(todos)
                     + "\n  fix: replace each 'TODO: describe' with one line.")
        print("✓ repo_map.md matches the tree")
        return

    if old_lines == new_lines:
        print("✓ repo_map.md is already up to date")
        return
    MAP.write_text(head + START + "\n" + "\n".join(new_lines) + "\n" + END + tail)
    added = len(set(new_lines) - set(old_lines))
    removed = len(set(old_lines) - set(new_lines))
    print(f"✓ repo_map.md updated: {added} lines added, {removed} removed")
    for path in todos:
        print(f"  TODO: describe {path}")


if __name__ == "__main__":
    main()
