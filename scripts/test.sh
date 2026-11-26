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
# Example: scripts/test.sh GlyphDataTests
# Full log: .build/test.log, results in .build/test.xcresult. Tests need macOS 15 or later.
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
results="$MACJI_ROOT/.build/test.xcresult"
mkdir -p "$MACJI_ROOT/.build"
rm -rf "$results"
step "Testing ${filter:-every suite}"
status=0
xcodebuild -project "$MACJI_PROJECT" -scheme "$MACJI_SCHEME" -destination "$MACJI_DESTINATION" \
    -derivedDataPath "$MACJI_DERIVED_DATA" -resultBundlePath "$results" ${only[@]+"${only[@]}"} \
    ${signing[@]+"${signing[@]}"} test >"$log" 2>&1 || status=$?

####################
#### Report
### The result bundle is the source of truth. The log's "Test case" lines can't be counted:
### xcodebuild sometimes writes its own summary into the middle of one, which hid a test.
# First line: passed failed skipped suites. Then one "<Suite>/<test>()" per failed test. A build
# that never ran tests has no bundle and reads as all zeros. Build errors and failed expectations
# are printed once each, paths relative to the repo.

report=$( { [[ -d "$results" ]] && xcrun xcresulttool get test-results tests --path "$results" 2>/dev/null; } \
    | python3 -I -c '
import json, sys
try:
    nodes = json.load(sys.stdin)["testNodes"]
except (ValueError, KeyError):
    nodes = []
cases = []
def walk(node, suite):
    if node.get("nodeType") == "Test Suite":
        suite = node.get("name")
    if node.get("nodeType") == "Test Case":
        cases.append((suite, node.get("name"), node.get("result")))
    for child in node.get("children", []):
        walk(child, suite)
for node in nodes:
    walk(node, None)
count = lambda result: sum(case[2] == result for case in cases)
print(count("Passed"), count("Failed"), count("Skipped"), len({c[0] for c in cases if c[2] in ("Passed", "Failed")}))
print("\n".join(f"{suite}/{name}" for suite, name, result in cases if result == "Failed"))
' || true)
read -r passed failed skipped suites <<<"$(head -1 <<<"$report")"

if (( failed > 0 )); then
    tail -n +2 <<<"$report" | sed '/^$/d; s/^/  ✗ /' >&2
    print_errors "$log"
    fail "$failed of $((passed + failed)) tests failed (full log: .build/test.log)" "Fix the failures above, then run scripts/test.sh again."
fi
if (( status != 0 )); then
    print_errors "$log"
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
