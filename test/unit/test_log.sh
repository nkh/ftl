#!/bin/env bash
# test/unit/test_log.sh — tests for the log module
#
# Tests ftl::log::init, ftl::log::set_level, ftl::log::debug,
# ftl::log::info, ftl::log::trace, and ftl::log::wrap.

# Source the module under test
source "$FTL_CFG/etc/core/modules/log.sh"

# Set up before each test
ftl::test::setup() {
    # Mock tmux as a no-op so log helpers don't fail
    tmux() { : ; }
    # Build an isolated temp session dir for log output
    FTL_TEST_TMP=$(mktemp -d)
    FTL_STATE_DIR="$FTL_TEST_TMP"
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_state_parent_dir="$FTL_TEST_TMP"
    # Reset log module defaults
    ftl_log_level=0
    ftl_log_file=
    ftl_cfg_debug_log_file=
    ftl_pane_is_child=0
    ftl_pane_self_id="%0"
    FTL_DEBUG=0
    FTL_TRACE=0
}

# Tear down after each test
ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# Test: init sets level 0 by default
test_init_default_level() {
    FTL_DEBUG=0
    FTL_TRACE=0
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_cfg_debug_log_file=
    ftl::log::init
    ftl::test::assert_eq "0" "$ftl_log_level" "default level is 0"
}

# Test: init sets level 1 when FTL_DEBUG=1
test_init_debug_level() {
    FTL_DEBUG=1
    FTL_TRACE=0
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_cfg_debug_log_file=
    ftl::log::init
    ftl::test::assert_eq "1" "$ftl_log_level" "FTL_DEBUG=1 -> level 1"
}

# Test: init sets level 2 when FTL_TRACE=1 (overrides FTL_DEBUG)
test_init_trace_level() {
    FTL_DEBUG=1
    FTL_TRACE=1
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_cfg_debug_log_file=
    ftl::log::init
    ftl::test::assert_eq "2" "$ftl_log_level" "FTL_TRACE=1 -> level 2"
}

# Test: init sets log_file to session_dir/debug.log when session_dir is set
test_init_log_file_path() {
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_cfg_debug_log_file=
    FTL_DEBUG=0
    ftl::log::init
    ftl::test::assert_eq "$FTL_TEST_TMP/debug.log" "$ftl_log_file" \
        "log file should be in session dir"
}

# Test: init respects ftl_cfg_debug_log_file override
test_init_log_file_override() {
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_cfg_debug_log_file="$FTL_TEST_TMP/custom.log"
    ftl::log::init
    ftl::test::assert_eq "$FTL_TEST_TMP/custom.log" "$ftl_log_file" \
        "custom log file should be used"
}

# Test: init writes startup banner when level > 0
test_init_writes_banner() {
    FTL_DEBUG=1
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_cfg_debug_log_file=
    ftl::log::init
    ftl::test::assert_contains "$(cat "$ftl_log_file")" "ftl debug log started" \
        "banner should be written"
}

# Test: set_level updates the level
test_set_level() {
    ftl_log_file="$FTL_TEST_TMP/test.log"
    ftl::log::set_level 2
    ftl::test::assert_eq "2" "$ftl_log_level" "level should be 2"
    ftl::log::set_level 0
    ftl::test::assert_eq "0" "$ftl_log_level" "level should be 0"
}

# Test: info writes to the log file regardless of level
test_info_writes_to_log() {
    ftl_log_file="$FTL_TEST_TMP/info.log"
    ftl_log_level=0
    ftl::log::info "an info message"
    ftl::test::assert_contains "$(cat "$ftl_log_file")" "INFO: an info message" \
        "info should be logged"
}

# Test: debug only writes when level >= 1
test_debug_respects_level() {
    ftl_log_file="$FTL_TEST_TMP/debug.log"
    : >"$ftl_log_file"

    ftl_log_level=0
    ftl::log::debug "should not appear"
    ftl::test::assert_eq "" "$(cat "$ftl_log_file")" "level 0 should not log"

    ftl_log_level=1
    ftl::log::debug "should appear"
    ftl::test::assert_contains "$(cat "$ftl_log_file")" "DEBUG: should appear" \
        "level 1 should log debug"
}

# Test: trace only writes when level >= 2
test_trace_respects_level() {
    ftl_log_file="$FTL_TEST_TMP/trace.log"
    : >"$ftl_log_file"

    ftl_log_level=1
    ftl::log::trace "should not appear"
    ftl::test::assert_eq "" "$(cat "$ftl_log_file")" "level 1 should not log trace"

    ftl_log_level=2
    ftl::log::trace "should appear"
    ftl::test::assert_match "TRACE:.*should appear" "$(cat "$ftl_log_file")" \
        "level 2 should log trace"
}

# Test: trace includes caller info
test_trace_includes_caller() {
    ftl_log_file="$FTL_TEST_TMP/trace_caller.log"
    ftl_log_level=2
    ftl::log::trace "hello"
    local content
    content=$(cat "$ftl_log_file")
    ftl::test::assert_match "TRACE:" "$content" "should have TRACE prefix"
    # caller info is in brackets, e.g. "[1 test_log.sh]"
    ftl::test::assert_match '\[[0-9]+ ' "$content" "should contain caller info"
}

# Test: wrap captures stderr to the log file
test_wrap_captures_stderr() {
    ftl_pane_is_child=1  # use show_error_full (no read blocking)
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_log_file="$FTL_TEST_TMP/debug.log"
    ftl_log_level=0

    ftl::log::wrap sh -c 'echo "oops on stderr" >&2'

    # show_error_full appends to errors.log
    local errors
    errors=$(cat "$FTL_TEST_TMP/errors.log" 2>/dev/null || true)
    ftl::test::assert_contains "$errors" "oops on stderr" \
        "stderr should be captured to errors.log"
}

# Test: wrap with no stderr output does not create errors.log
test_wrap_no_stderr() {
    ftl_pane_is_child=1
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_log_file="$FTL_TEST_TMP/debug.log"
    ftl_log_level=0
    rm -f "$FTL_TEST_TMP/errors.log"

    ftl::log::wrap true

    ftl::test::assert_eq "" "$(cat "$FTL_TEST_TMP/errors.log" 2>/dev/null || true)" \
        "no stderr -> no errors.log"
}
