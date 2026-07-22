#!/bin/env bash
# test/unit/test_debug.sh — tests for the debug module
#
# Tests ftl::debug::stacktrace, ftl::debug::log_caller, and
# ftl::debug::format_size (numfmt wrapper).

# Source dependencies (debug.format_size uses ftl::log::error)
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/debug.sh"

# Helper that calls stacktrace so we get predictable caller info
_stacktrace_helper() {
    ftl::debug::stacktrace
}

# Set up before each test
ftl::test::setup() {
    tmux() { : ; }
    FTL_TEST_TMP=$(mktemp -d)
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_log_level=0
    ftl_log_file=
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# Test: stacktrace produces non-empty output
test_stacktrace_not_empty() {
    local out
    out=$(_stacktrace_helper)
    ftl::test::assert_ne "" "$out" "stacktrace should produce output"
}

# Test: stacktrace output mentions the calling function
test_stacktrace_mentions_caller() {
    local out
    out=$(_stacktrace_helper)
    # The output is like "[1] file:line func(): source-line"
    ftl::test::assert_contains "$out" "_stacktrace_helper" \
        "stacktrace should mention the caller function"
}

# Test: stacktrace output is numbered
test_stacktrace_numbered() {
    local out
    out=$(_stacktrace_helper)
    ftl::test::assert_match '\[1\]' "$out" "first frame should be [1]"
}

# Test: stacktrace output includes file:line prefix
test_stacktrace_includes_file_line() {
    local out
    out=$(_stacktrace_helper)
    # Should reference this test file
    ftl::test::assert_contains "$out" "test_debug.sh" \
        "stacktrace should reference this test file"
}

# Test: log_caller writes to stderr
test_log_caller_writes() {
    local out
    out=$(ftl::debug::log_caller "hello" 2>&1)
    ftl::test::assert_contains "$out" "hello" "log_caller should write the message"
    ftl::test::assert_contains "$out" "BASH_SOURCE" "log_caller should log BASH_SOURCE"
    ftl::test::assert_contains "$out" "BASH_LINENO" "log_caller should log BASH_LINENO"
    ftl::test::assert_contains "$out" "FUNCNAME" "log_caller should log FUNCNAME"
}

# Test: log_caller prefix includes caller info
test_log_caller_prefix() {
    local out
    out=$(ftl::debug::log_caller "msg" 2>&1)
    # The prefix is "[<line> <func> <file>]"
    ftl::test::assert_match '^\[' "$out" "log_caller should start with ["
}

# Test: format_size wraps numfmt successfully
test_format_size_ok() {
    local out
    out=$(ftl::debug::format_size --to=iec -- 1024)
    ftl::test::assert_eq "1.0K" "$out" "1024 bytes -> 1.0K"
}

# Test: format_size handles larger values
test_format_size_large() {
    local out
    out=$(ftl::debug::format_size --to=iec -- 1048576)
    ftl::test::assert_eq "1.0M" "$out" "1048576 bytes -> 1.0M"
}

# Test: format_size logs error on bad args
test_format_size_error() {
    # Pass an invalid option so numfmt fails
    ftl::debug::format_size --bogus-option 2>/dev/null || true
    ftl::test::assert_contains "$(cat "$FTL_TEST_TMP/numfmt_errors.log" 2>/dev/null)" \
        "--bogus-option" "error should be logged to numfmt_errors.log"
}

# Test: format_size error log includes a stacktrace section
test_format_size_error_has_stacktrace() {
    ftl::debug::format_size --bogus-option 2>/dev/null || true
    local log
    log=$(cat "$FTL_TEST_TMP/numfmt_errors.log" 2>/dev/null)
    ftl::test::assert_contains "$log" "------------------" \
        "error log should have a separator before stacktrace"
}
