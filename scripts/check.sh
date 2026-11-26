#!/usr/bin/env bash
#
#  check.sh
#  MacJi
#
#  Created: 2026-11-26
#  Fast, read-only repo hygiene gate. Run it before every commit; CI runs it on every push.
#
####################
#### Usage
### scripts/check.sh    run every check, print each problem as file:line, exit 1 if any failed
# Checks: file headers · banned calls · inline UserDefaults keys · repo_map.md ↔ tree ·
# shared config values in sync · no tracked signing material.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { print_usage "$0"; exit 0; }
cd "$MACJI_ROOT"

failures=0
report() {
    local title="$1" found="$2"
    if [[ -z "$found" ]]; then
        ok "$title"
    else
        printf '✗ %s\n' "$title" >&2
        printf '%s\n' "$found" | sed 's/^/  /' | head -20 >&2
        failures=$((failures + 1))
    fi
}

####################
#### Files to check
### Tracked files plus new files git doesn't ignore, so a check sees work before it's committed.

files=()
while IFS= read -r -d '' path; do
    [[ -f "$path" ]] && files+=("$path")
done < <(git ls-files --cached --others --exclude-standard -z)
swift_app=() swift_all=() scripts=()
for path in "${files[@]}"; do
    case "$path" in
        MacJi/*.swift) swift_app+=("$path"); swift_all+=("$path") ;;
        MacJiTests/*.swift) swift_all+=("$path") ;;
    esac
    case "$path" in
        *.swift|*.sh|*.py) scripts+=("$path") ;;
    esac
done

##################

####################
#### 1. Headers
### The header names the file (line 2, or line 3 after a shebang) and has "Created: YYYY-MM-DD".

found=""
for path in "${scripts[@]}"; do
    name=$(basename "$path")
    head -3 "$path" | grep -qxE "(//|#)  $name" || found+="$path: header must name the file ('//  $name' or '#  $name')"$'\n'
    head -12 "$path" | grep -qE "Created: [0-9]{4}-[0-9]{2}-[0-9]{2}" || found+="$path: missing 'Created: YYYY-MM-DD'"$'\n'
done
report "File headers" "${found%$'\n'}"

#### 2. Banned calls
### Comment lines are skipped. Diagnostics go to os.Logger; AX and CF values use AXValueReader.

found=$(grep -nE '(^|[^A-Za-z_.])(print|debugPrint|fatalError)\(|as!|try!|DispatchQueue\.main\.sync' \
    ${swift_all[@]+"${swift_all[@]}"} | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)
report "No print, as!, try!, fatalError or main.sync" "$found"

#### 3. Preference keys
### App code names keys through PreferenceKeys; tests may write literal legacy keys on purpose.

found=$(grep -nE 'forKey: *"|@AppStorage\("|AutosaveName\("|autosaveName = "' \
    ${swift_app[@]+"${swift_app[@]}"} | grep -v '^MacJi/Constants/Keys/' || true)
report "No inline UserDefaults keys outside Constants/Keys" "$found"

##################

####################
#### 4. Repo map

if map_output=$(python3 scripts/repo-map.py --check 2>&1); then
    report "repo_map.md matches the tree" ""
else
    report "repo_map.md matches the tree" "$map_output"
fi

#### 5. Shared values
### config.sh is the source; config.py, Base.xcconfig and Info.plist must agree with it.

python_value() { sed -nE "s/^$1 = \"(.*)\"$/\1/p" scripts/config.py; }
found=""
for key in BUNDLE_ID SIGNING_IDENTITY SPARKLE_KEY_ACCOUNT SOURCE_REPO PLACEHOLDER_PUBLIC_KEY; do
    shell_name="MACJI_$key"
    [[ "$(python_value "$key")" == "${!shell_name}" ]] || found+="scripts/config.py: $key differs from config.sh"$'\n'
done
grep -qE "^MACJI_BUNDLE_ID = $MACJI_BUNDLE_ID\$" "$MACJI_XCCONFIG" || found+="Config/Base.xcconfig: MACJI_BUNDLE_ID differs from config.sh"$'\n'
grep -qF "/$MACJI_SOURCE_REPO/main/dist/appcast.xml" "$MACJI_INFO_PLIST" || found+="MacJi/Resources/Info.plist: SUFeedURL doesn't point at $MACJI_SOURCE_REPO's dist/appcast.xml"$'\n'
report "Shared values agree (config.sh, config.py, Base.xcconfig, Info.plist)" "${found%$'\n'}"

#### 6. Signing material
### Certificates, keys and local signing config never enter git, even by accident.

found=$( {
    git ls-files | grep -iE '\.(p12|p8|pem|key|cer|certsigningrequest|mobileprovision|provisionprofile)$|(^|/)LocalSigning\.xcconfig$|sparkle_private_key|(^|/)\.env'
    git grep -lIE -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' -- . ':!Upstream'
} || true)
report "No tracked signing files or private keys" "$found"

##################

(( failures == 0 )) || fail "$failures check(s) failed" "Fix the problems listed above, then run scripts/check.sh again."
ok "All checks passed"
