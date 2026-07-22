#!/bin/env bash
# test/harness.sh — test framework for ftl
#
# Provides a minimal test harness for unit-testing ftl's Bash modules.
# Tests are functions named test_* in files under test/unit/.
#
# Usage:
#   ./test/harness.sh                     # run all unit tests
#   ./test/harness.sh test/unit/test_keyboard.sh  # run one test file
#   ./test/harness.sh -v                  # verbose mode
#
# Test functions use:
#   ftl::test::assert_eq <expected> <actual> [msg]
#   ftl::test::assert_ne <expected> <actual> [msg]
#   ftl::test::assert_contains <haystack> <needle> [msg]
#   ftl::test::assert_match <regex> <string> [msg]
#   ftl::test::fail [msg]
#   ftl::test::pass [msg]

set -u

FTL_TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
FTL_ROOT_DIR="$(cd "$FTL_TEST_DIR/.." && pwd)"
FTL_CFG="${FTL_CFG:-$HOME/.config/ftl}"

# Colors
if [[ -t 1 ]]; then
    FTL_TEST_RED='\e[31m'
    FTL_TEST_GREEN='\e[32m'
    FTL_TEST_YELLOW='\e[33m'
    FTL_TEST_RESET='\e[0m'
else
    FTL_TEST_RED=''
    FTL_TEST_GREEN=''
    FTL_TEST_YELLOW=''
    FTL_TEST_RESET=''
fi

# Counters
FTL_TEST_PASSES=0
FTL_TEST_FAILS=0
FTL_TEST_SKIPS=0
FTL_TEST_VERBOSE=0

# Assert two values are equal.
# Args:
#   $1: expected
#   $2: actual
#   $3: optional message
ftl::test::assert_eq() {
    local expected="$1" actual="$2" msg="${3:-}"
    if [[ "$expected" == "$actual" ]] ; then
        ftl::test::_pass "${msg:+$msg: }expected='$expected'"
    else
        ftl::test::_fail "${msg:+$msg: }expected='$expected', got='$actual'"
    fi
}

# Assert two values are not equal.
ftl::test::assert_ne() {
    local expected="$1" actual="$2" msg="${3:-}"
    if [[ "$expected" != "$actual" ]] ; then
        ftl::test::_pass "${msg:+$msg: }'$actual' != '$expected'"
    else
        ftl::test::_fail "${msg:+$msg: }expected non-equal, but both='$expected'"
    fi
}

# Assert a string contains a substring.
ftl::test::assert_contains() {
    local haystack="$1" needle="$2" msg="${3:-}"
    if [[ "$haystack" == *"$needle"* ]] ; then
        ftl::test::_pass "${msg:+$msg: }'$haystack' contains '$needle'"
    else
        ftl::test::_fail "${msg:+$msg: }'$haystack' does not contain '$needle'"
    fi
}

# Assert a string matches a regex.
ftl::test::assert_match() {
    local regex="$1" string="$2" msg="${3:-}"
    if [[ "$string" =~ $regex ]] ; then
        ftl::test::_pass "${msg:+$msg: }'$string' matches /$regex/"
    else
        ftl::test::_fail "${msg:+$msg: }'$string' does not match /$regex/"
    fi
}

# Explicitly fail.
ftl::test::fail() {
    ftl::test::_fail "${1:-explicit failure}"
}

# Explicitly pass.
ftl::test::pass() {
    ftl::test::_pass "${1:-explicit pass}"
}

# Skip the current test.
ftl::test::skip() {
    ((FTL_TEST_SKIPS++))
    if (( FTL_TEST_VERBOSE )) ; then
        echo -e "  ${FTL_TEST_YELLOW}SKIP${FTL_TEST_RESET}: ${1:-skipped}"
    fi
    return 0
}

# Internal: record a pass.
ftl::test::_pass() {
    ((FTL_TEST_PASSES++))
    if (( FTL_TEST_VERBOSE )) ; then
        echo -e "  ${FTL_TEST_GREEN}PASS${FTL_TEST_RESET}: $1"
    fi
}

# Internal: record a failure.
ftl::test::_fail() {
    ((FTL_TEST_FAILS++))
    echo -e "  ${FTL_TEST_RED}FAIL${FTL_TEST_RESET}: $1"
}

# Set up mocks before each test.
ftl::test::setup() {
    # Mock tmux if not running in tmux
    if [[ -z "${TMUX:-}" ]] ; then
        tmux() {
            case "$1" in
                display) echo "%0" ;;
                lsp)     echo "" ;;
                *)       : ;;
            esac
        }
        export -f tmux
    fi
    
    # Mock terminal commands
    stty() { : ; }
    tput() { : ; }
    export -f stty tput
}

# Tear down after each test.
ftl::test::teardown() {
    :
}

# Run a single test function.
ftl::test::run_one() {
    local test_name="$1"
    ftl::test::setup
    "$test_name" 2>&1
    ftl::test::teardown
}

# Run all tests in a file.
ftl::test::run_file() {
    local test_file="$1"
    local basename
    basename=$(basename "$test_file")

    echo "Running $basename..."

    # Run the test file in a subshell so that test_* functions and setup
    # overrides from this file do not leak into subsequent files. The
    # subshell writes its pass/fail/skip deltas to a temp file which the
    # parent reads back to accumulate into the global counters.
    # _ftl_counts_file is global+exported so the EXIT trap (which may fire
    # after locals are torn down) can still see it.
    _ftl_counts_file=$(mktemp)
    export _ftl_counts_file

    (
        # Reset counters so we only count this file's results
        FTL_TEST_PASSES=0
        FTL_TEST_FAILS=0
        FTL_TEST_SKIPS=0

        # Ensure counts are written even if a test kills the subshell
        # (e.g. via an unbound variable under set -u).
        trap 'printf "%s %s %s\n" "$FTL_TEST_PASSES" "$FTL_TEST_FAILS" "$FTL_TEST_SKIPS" >"$_ftl_counts_file"' EXIT

        # Source the test file (defines test_* functions)
        source "$test_file"

        # Find and run all test functions
        local test_funcs
        test_funcs=$(declare -F | awk '/^declare -f test_/ {print $3}')

        if [[ -z "$test_funcs" ]] ; then
            echo "  (no test functions found)"
        else
            local tf
            for tf in $test_funcs ; do
                ftl::test::run_one "$tf"
            done
        fi
    )

    local p f s
    { read -r p f s; } <"$_ftl_counts_file"
    rm -f "$_ftl_counts_file"
    (( FTL_TEST_PASSES += ${p:-0} ))
    (( FTL_TEST_FAILS += ${f:-0} ))
    (( FTL_TEST_SKIPS += ${s:-0} ))
}

# Main entry point.
ftl::test::main() {
    local test_files=()
    
    # Parse args
    while [[ $# -gt 0 ]] ; do
        case "$1" in
            -v|--verbose)
                FTL_TEST_VERBOSE=1
                shift
                ;;
            *)
                test_files+=("$1")
                shift
                ;;
        esac
    done
    
    # If no files specified, run all unit + integration tests
    if [[ ${#test_files[@]} -eq 0 ]] ; then
        while IFS= read -r f ; do
            test_files+=("$f")
        done < <(find "$FTL_TEST_DIR/unit" "$FTL_TEST_DIR/integration" -name 'test_*.sh' -type f 2>/dev/null | sort)
    fi
    
    echo "=== ftl test suite ==="
    echo ""
    
    local tf
    for tf in "${test_files[@]}" ; do
        if [[ -f "$tf" ]] ; then
            ftl::test::run_file "$tf"
        else
            echo "File not found: $tf"
        fi
    done
    
    echo ""
    echo "=== Results ==="
    echo -e "  ${FTL_TEST_GREEN}Passed${FTL_TEST_RESET}: $FTL_TEST_PASSES"
    echo -e "  ${FTL_TEST_RED}Failed${FTL_TEST_RESET}: $FTL_TEST_FAILS"
    echo -e "  ${FTL_TEST_YELLOW}Skipped${FTL_TEST_RESET}: $FTL_TEST_SKIPS"
    
    if (( FTL_TEST_FAILS > 0 )) ; then
        return 1
    fi
}

# Run main (unless --source-only was passed, in which case just define functions)
if [[ "${1:-}" != "--source-only" ]] ; then
        ftl::test::main "$@"
fi
