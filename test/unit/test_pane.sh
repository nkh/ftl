#!/bin/env bash
# test/unit/test_pane.sh — tests for the pane module
#
# Tests ftl::pane::pid_to_id, ftl::pane::query_geometry,
# ftl::pane::snapshot_geometry, ftl::pane::check_resize,
# ftl::pane::set_border_colors, ftl::pane::window_exists,
# ftl::pane::count_bg_windows, and ftl::pane::ensure_session.
# tmux is mocked per-test.

# Source the module under test
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/pane.sh"

ftl::test::setup() {
    ftl_pane_self_id="%0"
    ftl_pane_width=80
    ftl_pane_height=24
    ftl_pane_prev_width=80
    ftl_pane_prev_height=24
    ftl_pane_top=0
    ftl_pane_left=0
    ftl_pane_window_width=80
    ftl_pane_preview_id=
    ftl_preview_is_image_daemon=0
    ftl_state_winch_pending=0
    ftl_state_pending_input=
    declare -Ag ftl_kbd_command_to_key=()
}

# Helper: mock tmux with the harness-style case dispatch
_mock_tmux_basic() {
    tmux() {
        case "$1" in
            display) echo "%0" ;;
            lsp)     echo "" ;;
            *)       : ;;
        esac
    }
}

# Test: pid_to_id returns the pane id for a matching pane_pid
test_pid_to_id_match() {
    tmux() {
        case "$1" in
            lsp) echo "%0 4242" ; echo "%1 5555" ;;
        esac
    }
    local out
    out=$(ftl::pane::pid_to_id 5555)
    ftl::test::assert_eq "%1" "$out" "should find pane %1 for pid 5555"
}

# Test: pid_to_id returns nothing when no match
test_pid_to_id_no_match() {
    tmux() {
        case "$1" in
            lsp) echo "%0 4242" ; echo "%1 5555" ;;
        esac
    }
    local out
    out=$(ftl::pane::pid_to_id 9999)
    ftl::test::assert_eq "" "$out" "should output nothing when pid not found"
}

# Test: query_geometry populates the geometry globals
test_query_geometry() {
    tmux() {
        if [[ "$1" == "display" ]] ; then
            echo "0 200 50 100 5"
        fi
    }
    ftl::pane::query_geometry
    ftl::test::assert_eq "0" "$ftl_pane_top" "top should be 0"
    ftl::test::assert_eq "200" "$ftl_pane_window_width" "window_width should be 200"
    ftl::test::assert_eq "50" "$ftl_pane_height" "height should be 50"
    ftl::test::assert_eq "100" "$ftl_pane_width" "width should be 100"
    ftl::test::assert_eq "5" "$ftl_pane_left" "left should be 5"
}

# Test: snapshot_geometry saves prev_width and prev_height
test_snapshot_geometry() {
    tmux() {
        if [[ "$1" == "display" ]] ; then
            echo "0 200 50 100 5"
        fi
    }
    ftl_pane_prev_width=0
    ftl_pane_prev_height=0
    ftl::pane::snapshot_geometry
    ftl::test::assert_eq "100" "$ftl_pane_prev_width" "prev_width should match width"
    ftl::test::assert_eq "50" "$ftl_pane_prev_height" "prev_height should match height"
}

# Test: check_resize does not flag when geometry unchanged
test_check_resize_no_change() {
    tmux() {
        if [[ "$1" == "display" ]] ; then
            echo "0 200 50 100 5"
        fi
    }
    ftl_pane_prev_width=100
    ftl_pane_prev_height=50
    ftl_state_winch_pending=1
    ftl_state_pending_input=
    ftl::pane::check_resize
    ftl::test::assert_eq "" "$ftl_state_pending_input" \
        "no resize -> no pending input"
}

# Test: check_resize flags when width changes and winch is pending
test_check_resize_width_change() {
    tmux() {
        if [[ "$1" == "display" ]] ; then
            echo "0 200 50 80 5"
        fi
    }
    ftl_pane_prev_width=100
    ftl_pane_prev_height=50
    ftl_state_winch_pending=1
    ftl_kbd_command_to_key[ftl::cmd::refresh_pane]="R"
    ftl_state_pending_input=""
    ftl::pane::check_resize
    ftl::test::assert_contains "$ftl_state_pending_input" "R" \
        "pending input should include refresh key"
}

# Test: check_resize flags when height changes
test_check_resize_height_change() {
    tmux() {
        if [[ "$1" == "display" ]] ; then
            echo "0 200 60 100 5"
        fi
    }
    ftl_pane_prev_width=100
    ftl_pane_prev_height=50
    ftl_state_winch_pending=1
    ftl_kbd_command_to_key[ftl::cmd::refresh_pane]="R"
    ftl_state_pending_input=""
    ftl::pane::check_resize
    ftl::test::assert_contains "$ftl_state_pending_input" "R" \
        "height change should also trigger refresh"
}

# Test: set_border_colors calls tmux set with the right color numbers
test_set_border_colors() {
    local calls=()
    tmux() {
        calls+=("$*")
    }
    ftl::pane::set_border_colors 4 9
    # First call should reference pane-border-style with color4
    ftl::test::assert_contains "${calls[*]}" "pane-border-style" \
        "should set pane-border-style"
    ftl::test::assert_contains "${calls[*]}" "color4" \
        "should reference color4 for border"
    ftl::test::assert_contains "${calls[*]}" "pane-active-border-style" \
        "should set pane-active-border-style"
    ftl::test::assert_contains "${calls[*]}" "color9" \
        "should reference color9 for active border"
}

# Test: window_exists returns 0 when window name is in the list
test_window_exists_yes() {
    tmux() {
        if [[ "$1" == "list-windows" ]] ; then
            echo "main"
            echo "logs"
            echo "shell"
        fi
    }
    if ftl::pane::window_exists "logs" ; then
        ftl::test::pass "logs window exists"
    else
        ftl::test::fail "logs window should exist"
    fi
}

# Test: window_exists returns 1 when window name is missing
test_window_exists_no() {
    tmux() {
        if [[ "$1" == "list-windows" ]] ; then
            echo "main"
            echo "shell"
        fi
    }
    if ftl::pane::window_exists "missing" ; then
        ftl::test::fail "missing window should not exist"
    else
        ftl::test::pass "missing window correctly reported absent"
    fi
}

# Test: count_bg_windows returns 0 when only one window exists
test_count_bg_windows_zero() {
    tmux() {
        if [[ "$1" == "lsw" ]] ; then
            echo "only_one_window"
        fi
    }
    local out
    out=$(ftl::pane::count_bg_windows)
    ftl::test::assert_eq "" "$out" "single window -> no bg windows output"
}

# Test: count_bg_windows returns N-1 when multiple windows exist
test_count_bg_windows_multiple() {
    tmux() {
        if [[ "$1" == "lsw" ]] ; then
            echo "w1"
            echo "w2"
            echo "w3"
        fi
    }
    local out
    out=$(ftl::pane::count_bg_windows)
    ftl::test::assert_eq "2" "$out" "3 windows -> 2 bg windows"
}

# Test: ensure_session creates session when has-session fails
test_ensure_session_creates() {
    local created=
    tmux() {
        case "$1" in
            has-session) return 1 ;;  # session does not exist
            new) created="yes" ;;
        esac
    }
    ftl::pane::ensure_session "test_suffix"
    ftl::test::assert_eq "yes" "$created" \
        "should call tmux new when session doesn't exist"
}

# Test: ensure_session does not create when has-session succeeds
test_ensure_session_exists() {
    local created=
    tmux() {
        case "$1" in
            has-session) return 0 ;;  # session exists
            new) created="yes" ;;
        esac
    }
    ftl::pane::ensure_session "test_suffix"
    ftl::test::assert_eq "" "$created" \
        "should not call tmux new when session already exists"
}
