#!/usr/bin/env bash
#
#  test.sh
#  MacJi
#
#  Created: 2026-11-26
#  Runs the Swift Testing suites, prints only the summary and failures, and fails when zero
#  tests ran (xcodebuild passes a filter that matches nothing).
#
####################
#### Usage
### scripts/test.sh                                   every test
### scripts/test.sh InlinePanelTests                  one suite
### scripts/test.sh InlinePanelTests/triggerInsideWordIsIgnored   one test ("()" is added)
### scripts/test.sh --unsigned [filter]               build without code signing (CI)
# Example: scripts/test.sh EmojiDataTests
# Full log: .build/test.log. Tests need macOS 15 or later.
##################

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

signing=()
filter=""
for arg in "$@"; do
    case "$arg" in
        -h|--help) print_usage "$0"; exit 0 ;;
        --unsigned) signing=(CODE_SIGNING_ALLOWED=NO) ;;
        -*) print_usage "$0"; exit 1 ;;
        *) [[ -z "$filter" ]] || { print_usage "$0"; exit 1; }; filter="$arg" ;;
    esac
done

####################
#### Build the filter
### Swift Testing names a test function with its parentheses; without them xcodebuild matches
### nothing and still reports success, so they are added here.

only=()
if [[ -n "$filter" ]]; then
    [[ "$filter" == */* && "$filter" != *")" ]] && filter="$filter()"
    only=("-only-testing:${MACJI_SCHEME}Tests/$filter")
fi

##################

log="$MACJI_ROOT/.build/test.log"
mkdir -p "$MACJI_ROOT/.build"
step "Testing ${filter:-every suite}"
status=0
xcodebuild -project "$MACJI_PROJECT" -scheme "$MACJI_SCHEME" -destination "$MACJI_DESTINATION" \
    -derivedDataPath "$MACJI_DERIVED_DATA" ${only[@]+"${only[@]}"} ${signing[@]+"${signing[@]}"} test >"$log" 2>&1 || status=$?

####################
#### Report
### One "Test case '<Suite>/<test>()' passed|failed|skipped" line per test is the source of truth.
# Build errors and failed expectations are printed once each, paths relative to the repo.

passed=$(grep -cE "^Test case '.*' passed" "$log" || true)
failed=$(grep -cE "^Test case '.*' failed" "$log" || true)
skipped=$(grep -cE "^Test case '.*' skipped" "$log" || true)
suites=$( { grep -E "^Test case '.*' (passed|failed)" "$log" || true; } | { grep -oE "^Test case '[^/']+/" || true; } \
    | sort -u | wc -l | tr -d ' ')

if (( failed > 0 )); then
    grep -E "^Test case '.*' failed" "$log" | sed -E "s/^Test case '([^']*)'.*/  ✗ \1/" >&2
    { grep -E "error: " "$log" || true; } | sed "s|$MACJI_ROOT/||" | sort -u | head -20 >&2
    fail "$failed of $((passed + failed)) tests failed (full log: .build/test.log)" "Fix the failures above, then run scripts/test.sh again."
fi
if (( status != 0 )); then
    { grep -E "error: " "$log" || true; } | sed "s|$MACJI_ROOT/||" | sort -u | head -20 >&2
    fail "xcodebuild failed before any test failed (full log: .build/test.log)" "Fix the build errors above."
fi
if (( passed == 0 )); then
    fail "No tests ran for '${filter:-all}'." "Check the suite and test names: scripts/test.sh <Suite>[/<test>]."
fi

#### Skipped tests are opt-in tools (for example the screenshot generator), not failures.
##################

summary="$passed tests passed in $suites suites"
(( skipped > 0 )) && summary+=", $skipped skipped"
ok "$summary"
