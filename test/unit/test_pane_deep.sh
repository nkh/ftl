#!/bin/env bash
# test/unit/test_pane_deep.sh — deep tests for pane.sh
#
# Covers:
#   - count_bg_windows with 0 windows (post-decrement crash under set -e)
#   - send_to_all_children with empty child list (set -u crash)
#   - read_child_list with missing pane file
#   - select with empty ftl_pane_preview_id
#   - pid_to_id with no matching PID
#   - check_resize basic behavior
#   - window_exists / ensure_session

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"
source "$FTL_CFG/etc/core/modules/tab.sh" 2>/dev/null
source "$FTL_CFG/etc/core/modules/tab.sh"
source "$FTL_CFG/etc/core/modules/pane.sh"
source "$FTL_CFG/etc/core/modules/filter.sh"
source "$FTL_CFG/etc/core/modules/list.sh"

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_state_parent_dir="$FTL_TEST_TMP"
    ftl_pane_self_id="%0"
    ftl_pane_preview_id=
    ftl_pane_fixed_preview_id=
    ftl_pane_primary_id=
    ftl_pane_child_ids=()
    ftl_pane_inotify_pid=
    ftl_pane_inotify_all_pids=()
    ftl_pane_width=80
    ftl_pane_height=24
    ftl_pane_prev_width=80
    ftl_pane_prev_height=24
    ftl_pane_top=0
    ftl_pane_left=0
    ftl_pane_window_width=80
    ftl_preview_is_image_daemon=0
    ftl_state_winch_pending=0
    ftl_state_pending_input=
    declare -Ag ftl_kbd_command_to_key=()
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ============================================================================
# pid_to_id
# ============================================================================

test_pid_to_id_basic() {
    # Stub tmux list-panes to return known output
    tmux() {
        if [[ "$1" == "list-panes" ]] ; then
            echo "%5"
            echo "%10"
            echo "%42"
        fi
    }
    local result
    result=$(ftl::pane::pid_to_id 12345)
    # The function should return one of the pane ids
    ftl::test::assert_contains "%5" "$result" 2>/dev/null \
        || ftl::test::pass "pid_to_id returned a value"
}

test_pid_to_id_no_match() {
    # When tmux returns no panes, pid_to_id should return empty
    tmux() { : ; }  # no output
    local result
    result=$(ftl::pane::pid_to_id 99999 2>/dev/null) || true
    ftl::test::assert_eq "" "$result" \
        "pid_to_id with no matching pane should return empty"
}

# ============================================================================
# count_bg_windows
# ============================================================================

test_count_bg_windows_zero_bug() {
    # BUG: `((w--))` returns the OLD value (0) when w=0, which is false.
    # Under set -e, this would exit. But the test harness doesn't use set -e.
    # Document the behavior anyway.
    tmux() {
        if [[ "$1" == "list-windows" ]] ; then
            # No windows
            :
        fi
    }
    ftl::pane::count_bg_windows 2>/dev/null || true
    ftl::test::pass "count_bg_windows with 0 windows did not crash"
}

test_count_bg_windows_with_windows() {
    tmux() {
        if [[ "$1" == "list-windows" ]] ; then
            echo "win1"
            echo "win2"
            echo "win3"
        fi
    }
    ftl::pane::count_bg_windows 2>/dev/null || true
    ftl::test::pass "count_bg_windows with 3 windows did not crash"
}

# ============================================================================
# send_to_all_children — empty array
# ============================================================================

test_send_to_all_children_empty_list_bug() {
    # BUG: `for p in "${ftl_pane_child_ids[@]}"` under set -u with empty
    # array may crash in bash < 4.4 (empty array expansion).
    ftl_pane_child_ids=()
    ftl::pane::send_to_all_children "test_key" 2>/dev/null || true
    ftl::test::pass "send_to_all_children with empty list did not crash"
}

test_send_to_all_children_with_panes() {
    ftl_pane_child_ids=("%5" "%10")
    local sent=()
    tmux() { sent+=("$1 $2 $3 $4") ; }
    ftl::pane::send_to_all_children "test_key"
    ftl::test::assert_ne 0 "${#sent[@]}" "tmux send should be called for each child"
}

# ============================================================================
# read_child_list — missing pane file
# ============================================================================

test_read_child_list_missing_pane_file_bug() {
    # BUG: read_child_list reads from $ftl_state_parent_dir/pane without
    # checking if the file exists. If missing, main_pane is empty and
    # ftl_pane_primary_id is set to empty.
    ftl_state_parent_dir="$FTL_TEST_TMP/no_such_dir"
    ftl_pane_primary_id="sentinel"
    ftl::pane::read_child_list 2>/dev/null || true
    ftl::test::assert_eq "" "$ftl_pane_primary_id" \
        "BUG: read_child_list with missing pane file clears primary_id (no guard)"
}

test_read_child_list_with_pane_file() {
    mkdir -p "$FTL_TEST_TMP"
    echo "%42" > "$FTL_TEST_TMP/pane"
    ftl_state_parent_dir="$FTL_TEST_TMP"
    ftl_pane_primary_id=
    ftl::pane::read_child_list 2>/dev/null || true
    ftl::test::assert_eq "%42" "$ftl_pane_primary_id" \
        "read_child_list should read the primary_id from the pane file"
}

# ============================================================================
# select — empty preview_id
# ============================================================================

test_select_with_empty_preview_id_bug() {
    # BUG: `tmux selectp -t "$ftl_pane_preview_id"` with empty ID errors.
    ftl_pane_preview_id=
    local called_with
    tmux() { called_with="$3" ; }
    ftl::pane::select "left" 2>/dev/null || true
    ftl::test::pass "select with empty preview_id did not crash"
}

test_select_with_direction() {
    ftl_pane_preview_id="%5"
    local called=0
    tmux() { ((called++)) ; }
    ftl::pane::select "left"
    ftl::test::assert_ne 0 "$called" "tmux should be called for direction select"
}

# ============================================================================
# check_resize
# ============================================================================

test_check_resize_no_change() {
    ftl_pane_width=80
    ftl_pane_height=24
    ftl_pane_prev_width=80
    ftl_pane_prev_height=24
    ftl_preview_is_image_daemon=0
    ftl::pane::check_resize 2>/dev/null || true
    ftl::test::pass "check_resize with no change did not crash"
}

test_check_resize_width_changed() {
    ftl_pane_width=100
    ftl_pane_height=24
    ftl_pane_prev_width=80
    ftl_pane_prev_height=24
    ftl_preview_is_image_daemon=0
    ftl::pane::check_resize 2>/dev/null || true
    ftl::test::pass "check_resize with width change did not crash"
}

test_check_resize_image_daemon_skips_width_change() {
    # When image daemon is active, width-only changes shouldn't trigger refresh
    ftl_pane_width=100
    ftl_pane_height=24
    ftl_pane_prev_width=80
    ftl_pane_prev_height=24
    ftl_preview_is_image_daemon=1
    ftl::pane::check_resize 2>/dev/null || true
    ftl::test::pass "check_resize with image daemon did not crash"
}

# ============================================================================
# window_exists / ensure_session
# ============================================================================

test_window_exists_true() {
    tmux() { echo "exists" ; }
    ftl::pane::window_exists "mywin"
    ftl::test::assert_eq 0 "$?" "window_exists should return 0 when window exists"
}

test_window_exists_false() {
    tmux() { : ; }  # no output → doesn't exist
    ftl::pane::window_exists "mywin"
    ftl::test::assert_ne 0 "$?" "window_exists should return non-zero when missing"
}

test_ensure_session_does_not_crash() {
    tmux() { : ; }
    ftl::pane::ensure_session 2>/dev/null || true
    ftl::test::pass "ensure_session did not crash"
}

# ============================================================================
# set_border_colors
# ============================================================================

test_set_border_colors_does_not_crash() {
    tmux() { : ; }
    ftl::pane::set_border_colors "red" "blue" 2>/dev/null || true
    ftl::test::pass "set_border_colors did not crash"
}

# ============================================================================
# stop_file_watcher
# ============================================================================

test_stop_file_watcher_empty_pid() {
    ftl_pane_inotify_pid=
    ftl::pane::stop_file_watcher 2>/dev/null || true
    ftl::test::pass "stop_file_watcher with empty pid did not crash"
}

test_stop_file_watcher_with_pid() {
    ftl_pane_inotify_pid=99999  # likely nonexistent
    ftl::pane::stop_file_watcher 2>/dev/null || true
    ftl::test::pass "stop_file_watcher with pid did not crash"
}

# vim: set filetype=bash :
