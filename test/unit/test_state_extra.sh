#!/bin/env bash
# test/unit/test_state_extra.sh — additional state tests

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/state.sh"

ftl::test::setup() {
	ftl_state_session_dir=$(mktemp -d)
	ftl_state_parent_dir="$ftl_state_session_dir"
	ftl_state_shared_dir="$ftl_state_session_dir/prev"
	mkdir -p "$ftl_state_shared_dir"
	ftl_state_current_path="/tmp/test"
	ftl_selection_current=("/tmp/test")
	ftl_selection_tags=()
	ftl_selection_total_bytes=0
	ftl_selection_revision=0
	ftl_state_child_env=()
}

ftl::test::teardown() {
	rm -rf "$ftl_state_session_dir"
}

test_save_creates_tags_file() {
	ftl::sel::set "/tmp/save_test" 2>/dev/null
	ftl::state::save
	ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/tags" && echo 1)"
}

test_save_creates_state_file() {
	ftl_list_entry_count=1
	ftl_list_entries=("/tmp/state_file_test")
	ftl_state_cursor_index=0
	ftl::state::save
	ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/ftl" && echo 1)"
}

test_save_writes_stagsi() {
	ftl_selection_revision=99
	ftl::state::save
	ftl::test::assert_eq "99" "$(cat "$ftl_state_shared_dir/stagsi")"
}

test_save_writes_fs_pointer() {
	ftl::state::save
	ftl::test::assert_contains "$(cat "$ftl_state_shared_dir/fs")" "$ftl_state_session_dir"
}

test_save_selection_creates_file() {
	ftl::sel::set "/tmp/sel1" 2>/dev/null
	ftl::state::save_selection
	ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/tags" && echo 1)"
}

test_load_selection_sources_file() {
	echo 'declare -Ag ftl_selection_tags=(["/tmp/loaded"]=▪ )' > "$ftl_state_session_dir/tags"
	ftl::state::load_selection "$ftl_state_session_dir"
	ftl::test::assert_eq "▪" "${ftl_selection_tags[/tmp/loaded]}"
}

test_serialize_info_writes_pid() {
	ftl::state::serialize_info "$ftl_state_session_dir/info"
	ftl::test::assert_contains "$(cat "$ftl_state_session_dir/info")" "FTL_PID"
}

test_serialize_info_writes_cwd() {
	ftl::state::serialize_info "$ftl_state_session_dir/info"
	ftl::test::assert_contains "$(cat "$ftl_state_session_dir/info")" "FTL_SESSION_DIR"
}

test_serialize_info_creates_file() {
	ftl::state::serialize_info "$ftl_state_session_dir/info"
	ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/info" && echo 1)"
}

test_render_child_env_has_pfs() {
	ftl_state_parent_dir="/tmp/parent_test"
	ftl_state_session_dir="/tmp/session_test"
	ftl_state_child_env=()
	local r=$(ftl::state::render_child_env)
	ftl::test::assert_contains "$r" "ftl_pfs=/tmp/parent_test"
}

test_render_child_env_has_fs() {
	ftl_state_parent_dir="/tmp/parent_test"
	ftl_state_session_dir="/tmp/session_test"
	ftl_state_child_env=()
	local r=$(ftl::state::render_child_env)
	ftl::test::assert_contains "$r" "ftl_fs=/tmp/session_test"
}

test_render_child_env_custom_prefix() {
	ftl_state_child_env=([test_key]="test_val")
	local r=$(ftl::state::render_child_env "-x")
	ftl::test::assert_contains "$r" "-x test_key=test_val"
}

test_cleanup_removes_dir() {
	local d=$(mktemp -d)
	ftl_state_session_dir="$d"
	ftl::state::cleanup
	ftl::test::assert_eq "1" "$(test ! -d "$d" && echo 1)"
}

test_cleanup_on_nonexistent() {
	ftl_state_session_dir="/tmp/nonexistent_cleanup_123"
	ftl::state::cleanup
	ftl::test::pass "cleanup nonexistent doesn't crash"
}

test_emit_selection_no_fd3() {
	# Without fd 3 open, should not crash
	ftl_state_quit_cancelled=0
	ftl_selection_current=("/tmp/a" "/tmp/b")
	ftl::state::emit_selection_fd3 2>/dev/null
	ftl::test::pass "emit_selection_fd3 didn't crash"
}

test_emit_selection_cancelled() {
	ftl_state_quit_cancelled=1
	ftl_selection_current=("/tmp/a")
	ftl::state::emit_selection_fd3 2>/dev/null
	ftl::test::pass "cancelled emit didn't crash"
}

test_save_empty_directory() {
	ftl_list_entry_count=0
	ftl_list_entries=()
	ftl::state::save
	local content=$(cat "$ftl_state_session_dir/ftl" 2>/dev/null)
	ftl::test::assert_eq "0" "${#content}" "empty dir → empty state file"
}

test_child_env_accumulates() {
	ftl_state_child_env=([key1]="val1")
	ftl_state_parent_dir="/p"
	ftl_state_session_dir="/s"
	ftl::state::render_child_env >/dev/null
	ftl::test::assert_eq "val1" "${ftl_state_child_env[key1]}" "existing env preserved"
}
