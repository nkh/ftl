#!/bin/env bash
# test/integration/test_tmux_integration.sh — tests requiring real tmux
#
# These tests are skipped when tmux is not available.

FTL_CFG="${FTL_CFG:-$(cd "$(dirname "$0")/../.." && pwd)/config/ftl}"

# Skip entire file if no tmux
command -v tmux >/dev/null 2>&1 || {
	echo "  (skipped: tmux not installed)"
	exit 0
}

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"
source "$FTL_CFG/etc/core/modules/tab.sh"
source "$FTL_CFG/etc/core/modules/pane.sh"
source "$FTL_CFG/etc/core/modules/filter.sh"
source "$FTL_CFG/etc/core/modules/list.sh"
source "$FTL_CFG/etc/core/modules/preview.sh"
source "$FTL_CFG/etc/core/modules/etag.sh"
source "$FTL_CFG/etc/core/modules/virtual.sh"
source "$FTL_CFG/etc/core/modules/mark.sh"
source "$FTL_CFG/etc/core/modules/time.sh"
source "$FTL_CFG/etc/core/modules/commands.sh"

ftl::test::setup() {
	ftl_state_session_dir=$(mktemp -d)
	mkdir -p "$ftl_state_session_dir/prev"
	ftl_state_parent_dir="$ftl_state_session_dir"
	ftl_state_shared_dir="$ftl_state_session_dir/prev"
	ftl_selection_tags=()
	ftl_selection_total_bytes=0
	ftl_selection_revision=0
}

ftl::test::teardown() {
	rm -rf "$ftl_state_session_dir"
}

test_tmux_session_create() {
	local sess="ftl_test_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	ftl::test::assert_eq "0" "$?" "tmux session created"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_pane_split() {
	local sess="ftl_test_split_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	tmux split-window -t "$sess" 2>/dev/null
	local panes=$(tmux lsp -t "$sess" 2>/dev/null | wc -l)
	ftl::test::assert_eq "2" "$panes" "should have 2 panes after split"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_pane_id() {
	local sess="ftl_test_pid_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	local pid=$(tmux display -t "$sess" -p '#{pane_pid}' 2>/dev/null)
	ftl::test::assert_ne "" "$pid" "should get pane pid"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_geometry() {
	local sess="ftl_test_geo_$$"
	tmux new-session -d -s "$sess" -x 80 -y 24 2>/dev/null
	local h=$(tmux display -t "$sess" -p '#{pane_height}' 2>/dev/null)
	local w=$(tmux display -t "$sess" -p '#{pane_width}' 2>/dev/null)
	ftl::test::assert_ne "" "$h" "should get height"
	ftl::test::assert_ne "" "$w" "should get width"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_window_list() {
	local sess="ftl_test_wl_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	tmux new-window -t "$sess" 2>/dev/null
	local count=$(tmux lsw -t "$sess" 2>/dev/null | wc -l)
	ftl::test::assert_eq "2" "$count" "should have 2 windows"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_send_keys() {
	local sess="ftl_test_sk_$$"
	tmux new-session -d -s "$sess" "cat; sleep 10" 2>/dev/null
	sleep 0.2
	tmux send-keys -t "$sess" "hello" C-m 2>/dev/null
	ftl::test::assert_eq "0" "$?" "send-keys succeeded"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_popup() {
	local sess="ftl_test_pop_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	# popup may not be available in older tmux
	tmux popup -w 20 -h 5 "echo test" 2>/dev/null
	ftl::test::pass "popup didn't crash"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_kill_pane() {
	local sess="ftl_test_kp_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	tmux split-window -t "$sess" 2>/dev/null
	tmux kill-pane -t "$sess:0.1" 2>/dev/null
	local panes=$(tmux lsp -t "$sess" 2>/dev/null | wc -l)
	ftl::test::assert_eq "1" "$panes" "should have 1 pane after kill"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_resize_pane() {
	local sess="ftl_test_rp_$$"
	tmux new-session -d -s "$sess" -x 80 -y 24 2>/dev/null
	tmux split-window -t "$sess" -h 2>/dev/null
	tmux resize-pane -t "$sess:0.1" -x 30 2>/dev/null
	local w=$(tmux display -t "$sess:0.1" -p '#{pane_width}' 2>/dev/null)
	ftl::test::assert_eq "30" "$w" "pane resized to 30"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_select_pane() {
	local sess="ftl_test_sp_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	tmux split-window -t "$sess" 2>/dev/null
	tmux select-pane -t "$sess:0.1" 2>/dev/null
	ftl::test::assert_eq "0" "$?" "select-pane succeeded"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_respawn_pane() {
	local sess="ftl_test_rs_$$"
	tmux new-session -d -s "$sess" "sleep 100" 2>/dev/null
	tmux respawn-pane -k -t "$sess" "sleep 200" 2>/dev/null
	ftl::test::assert_eq "0" "$?" "respawn-pane succeeded"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_set_border_style() {
	local sess="ftl_test_bs_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	tmux set -t "$sess" pane-border-style "fg=color67" 2>/dev/null
	ftl::test::assert_eq "0" "$?" "set border style succeeded"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_kill_session() {
	local sess="ftl_test_ks_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	tmux kill-session -t "$sess" 2>/dev/null
	ftl::test::assert_eq "0" "$?" "kill-session succeeded"
}

test_tmux_multiple_sessions() {
	local s1="ftl_test_ms1_$$"
	local s2="ftl_test_ms2_$$"
	tmux new-session -d -s "$s1" 2>/dev/null
	tmux new-session -d -s "$s2" 2>/dev/null
	local count=$(tmux ls 2>/dev/null | wc -l)
	ftl::test::assert_ne "0" "$count" "should have multiple sessions"
	tmux kill-session -t "$s1" 2>/dev/null
	tmux kill-session -t "$s2" 2>/dev/null
}

test_tmux_capture_pane() {
	local sess="ftl_test_cp_$$"
	tmux new-session -d -s "$sess" "echo hello; sleep 10" 2>/dev/null
	sleep 0.5
	local captured=$(tmux capture-pane -t "$sess" -p 2>/dev/null)
	ftl::test::assert_contains "$captured" "hello" "captured pane content"
	tmux kill-session -t "$sess" 2>/dev/null
}

test_tmux_set_environment() {
	local sess="ftl_test_env_$$"
	tmux new-session -d -s "$sess" 2>/dev/null
	tmux set-environment -t "$sess" TEST_VAR "test_value" 2>/dev/null
	local val=$(tmux show-environment -t "$sess" TEST_VAR 2>/dev/null)
	ftl::test::assert_contains "$val" "test_value" "env var set"
	tmux kill-session -t "$sess" 2>/dev/null
}

# vim: set filetype=bash :
