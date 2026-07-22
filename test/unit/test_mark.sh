#!/bin/env bash
# test/unit/test_mark.sh — tests for the mark module
#
# Tests _ftl::mark::save_to_history: skipping child panes, skipping empty
# paths, and appending to both the session history file and the shared
# history file.

# Source the module under test
source "$FTL_CFG/etc/core/modules/mark.sh"

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    FTL_STATE_DIR="$FTL_TEST_TMP/state"
    ftl_state_session_dir="$FTL_TEST_TMP/session"
    mkdir -p "$ftl_state_session_dir" "$FTL_STATE_DIR/shared"
    ftl_state_current_path=
    ftl_pane_is_child=0
    # Clean any pre-existing history files
    rm -f "$ftl_state_session_dir/history" "$FTL_STATE_DIR/shared/history"
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# Test: skips writing when pane is a child
test_skip_when_child() {
    ftl_pane_is_child=1
    ftl_state_current_path="/some/path"
    _ftl::mark::save_to_history
    ftl::test::assert_eq "" "$(cat "$ftl_state_session_dir/history" 2>/dev/null)" \
        "session history should be empty for child pane"
    ftl::test::assert_eq "" "$(cat "$FTL_STATE_DIR/shared/history" 2>/dev/null)" \
        "shared history should be empty for child pane"
}

# Test: skips writing when current path is empty
test_skip_when_empty_path() {
    ftl_pane_is_child=0
    ftl_state_current_path=
    _ftl::mark::save_to_history
    ftl::test::assert_eq "" "$(cat "$ftl_state_session_dir/history" 2>/dev/null)" \
        "session history should be empty for empty path"
    ftl::test::assert_eq "" "$(cat "$FTL_STATE_DIR/shared/history" 2>/dev/null)" \
        "shared history should be empty for empty path"
}

# Test: appends the current path to the session history file
test_appends_to_session_history() {
    ftl_pane_is_child=0
    ftl_state_current_path="/home/user/project"
    _ftl::mark::save_to_history
    ftl::test::assert_eq "/home/user/project" "$(cat "$ftl_state_session_dir/history")" \
        "session history should contain the path"
}

# Test: appends the current path to the shared history file
test_appends_to_shared_history() {
    ftl_pane_is_child=0
    ftl_state_current_path="/var/log"
    _ftl::mark::save_to_history
    ftl::test::assert_eq "/var/log" "$(cat "$FTL_STATE_DIR/shared/history")" \
        "shared history should contain the path"
}

# Test: appends to both files in a single call
test_appends_to_both_files() {
    ftl_pane_is_child=0
    ftl_state_current_path="/usr/local/bin"
    _ftl::mark::save_to_history
    local session shared
    session=$(cat "$ftl_state_session_dir/history")
    shared=$(cat "$FTL_STATE_DIR/shared/history")
    ftl::test::assert_eq "$session" "$shared" \
        "both history files should contain the same content"
    ftl::test::assert_eq "/usr/local/bin" "$session" "content should be the path"
}

# Test: multiple calls accumulate (append mode)
test_multiple_calls_accumulate() {
    ftl_pane_is_child=0
    ftl_state_current_path="/path/one"
    _ftl::mark::save_to_history
    ftl_state_current_path="/path/two"
    _ftl::mark::save_to_history
    ftl_state_current_path="/path/three"
    _ftl::mark::save_to_history
    local session
    session=$(cat "$ftl_state_session_dir/history")
    ftl::test::assert_contains "$session" "/path/one" "should contain path one"
    ftl::test::assert_contains "$session" "/path/two" "should contain path two"
    ftl::test::assert_contains "$session" "/path/three" "should contain path three"
    # Should have 3 lines
    local count
    count=$(printf "%s\n" "$session" | wc -l)
    ftl::test::assert_eq "3" "$count" "should have 3 history entries"
}

# Test: shared history accumulates across multiple calls
test_shared_history_accumulates() {
    ftl_pane_is_child=0
    ftl_state_current_path="/a"
    _ftl::mark::save_to_history
    ftl_state_current_path="/b"
    _ftl::mark::save_to_history
    local shared
    shared=$(cat "$FTL_STATE_DIR/shared/history")
    local count
    count=$(printf "%s\n" "$shared" | wc -l)
    ftl::test::assert_eq "2" "$count" "shared history should have 2 entries"
}

# Test: returns 0 in all cases (even when skipping)
test_returns_zero() {
    ftl_pane_is_child=1
    ftl_state_current_path="/anything"
    if _ftl::mark::save_to_history ; then
        ftl::test::pass "returns 0 when skipping (child pane)"
    else
        ftl::test::fail "should return 0 even when skipping"
    fi
}

# Test: child pane skip takes precedence over empty path
test_child_skip_precedence() {
    ftl_pane_is_child=1
    ftl_state_current_path=
    _ftl::mark::save_to_history
    ftl::test::assert_eq "" "$(cat "$ftl_state_session_dir/history" 2>/dev/null)" \
        "child pane should skip regardless of path"
}
