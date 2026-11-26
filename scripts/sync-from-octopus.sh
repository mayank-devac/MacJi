#!/usr/bin/env bash
#
#  sync-from-octopus.sh
#  MacJi
#
#  Created: 2026-11-26
#  Shows which Octopus originals of MacJi's ported files changed since the pinned submodule
#  commit, with their diffs. Never edits a MacJi file: porting a fix is done by hand.
#
####################
#### Usage
### scripts/sync-from-octopus.sh                  move Upstream/octopus to Octopus's latest commit, list
###                                               changed origins and print their diffs
### scripts/sync-from-octopus.sh <MacJi file>     the same for one ported file
### scripts/sync-from-octopus.sh --no-fetch [f]   compare with the submodule's current checkout (offline)
### scripts/sync-from-octopus.sh --table          rewrite the MacJi → Octopus table in docs/ARCHITECTURE.md
# Example: scripts/sync-from-octopus.sh MacJi/Features/InlinePanel/TriggerTracker.swift
# Origins come from each file's "Ported from Octopus:" header line (comma-separated paths).
# After porting: commit the submodule bump with the port, then run --table.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
cd "$MACJI_ROOT"

fetch=true table=false only=""
for arg in "$@"; do
    case "$arg" in
        -h|--help) print_usage "$0"; exit 0 ;;
        --no-fetch) fetch=false ;;
        --table) table=true ;;
        -*) print_usage "$0"; exit 1 ;;
        *) only="${arg#./}" ;;
    esac
done
[[ -z "$only" || -f "$only" ]] || fail "$only doesn't exist." "Pass a path like MacJi/Features/InlinePanel/TriggerTracker.swift."

submodule="Upstream/octopus"
pinned=$(git ls-files -s "$submodule" | awk '{print $2}')
[[ -n "$pinned" ]] || fail "$submodule is not a submodule here." "Restore .gitmodules and the submodule from git."

####################
#### Ported files and their origins
### One "<MacJi file>\t<origin>" line per origin.

ported_origins() {
    { grep -rl --include='*.swift' "Ported from Octopus:" MacJi MacJiTests || true; } | sort | while read -r file; do
        [[ -z "$only" || "$file" == "$only" ]] || continue
        sed -nE 's/^\/\/  Ported from Octopus: (.*)$/\1/p' "$file" | tr ',' '\n' \
            | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' | while read -r origin; do
                [[ -n "$origin" ]] && printf '%s\t%s\n' "$file" "$origin"
            done
    done
}

##################

####################
#### --table: regenerate the table in docs/ARCHITECTURE.md
### Links point at the pinned commit, so they keep showing the code MacJi was ported from.

if $table; then
    doc="docs/ARCHITECTURE.md"
    rows=$(mktemp)
    trap 'rm -f "$rows"' EXIT
    {
        printf '| MacJi file | Octopus origin (pinned at `%s`) |\n|---|---|\n' "${pinned:0:7}"
        ported_origins | awk -F'\t' -v base="https://github.com/$MACJI_OCTOPUS_REPO/blob/$pinned" '
            $1 != file { if (file) print row " |"; file = $1; row = "| `" $1 "` | "; sep = "" }
            { row = row sep "[" $2 "](" base "/" $2 ")"; sep = "<br>" }
            END { if (file) print row " |" }'
    } >"$rows"
    awk -v rows="$rows" '
        /<!-- octopus-table:start -->/ { print; while ((getline line < rows) > 0) print line; skip = 1; next }
        /<!-- octopus-table:end -->/ { skip = 0 }
        !skip { print }' "$doc" >"$doc.tmp" && mv "$doc.tmp" "$doc"
    ok "$doc: table regenerated ($(($(wc -l <"$rows") - 2)) files, pinned ${pinned:0:7})"
    exit 0
fi

##################

[[ -e "$submodule/.git" ]] || fail "$submodule is not checked out." "Run: git submodule update --init $submodule"
if $fetch; then
    step "Updating $submodule to Octopus's latest commit"
    git submodule update --remote "$submodule" >/dev/null 2>&1 || fail "Could not fetch Octopus." "Check your network, or use --no-fetch."
fi
current=$(git -C "$submodule" rev-parse HEAD)
step "Comparing pinned ${pinned:0:7} with ${current:0:7}"

####################
#### Compare every origin
### Changed origins print their diff; missing ones point at a wrong header or a moved file.

changed=0 unchanged=0 missing=0
while IFS=$'\t' read -r file origin; do
    if ! git -C "$submodule" cat-file -e "$pinned:$origin" 2>/dev/null; then
        printf '? %s: %s is not in the pinned commit (check the header path)\n' "$file" "$origin"
        missing=$((missing + 1))
    elif ! git -C "$submodule" cat-file -e "$current:$origin" 2>/dev/null; then
        printf '? %s: %s was moved or removed in Octopus\n' "$file" "$origin"
        missing=$((missing + 1))
    elif git -C "$submodule" diff --quiet "$pinned" "$current" -- "$origin"; then
        unchanged=$((unchanged + 1))
    else
        printf '\n● %s ← %s\n' "$file" "$origin"
        git -C "$submodule" --no-pager diff --stat=100 "$pinned" "$current" -- "$origin" | tail -1
        git -C "$submodule" --no-pager diff "$pinned" "$current" -- "$origin"
        changed=$((changed + 1))
    fi
done < <(ported_origins)

##################

(( changed + unchanged + missing > 0 )) || fail "No 'Ported from Octopus:' headers found${only:+ in $only}." "Check the file's header."
ok "$changed changed, $unchanged unchanged, $missing missing"
(( changed == 0 )) || printf '  next: port the changes by hand, commit them with the %s bump, then run --table\n' "$submodule"
