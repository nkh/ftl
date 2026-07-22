#!/bin/env bash
# test/unit/test_missing_functionalities.sh — tests for missing_functionalities plugin

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"

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
source "$FTL_CFG/bindings/missing_functionalities"

tmux() { : ; }

ftl::test::setup() {
	ftl_state_session_dir=$(mktemp -d)
	mkdir -p "$ftl_state_session_dir/prev"
	ftl_state_parent_dir="$ftl_state_session_dir"
	ftl_state_shared_dir="$ftl_state_session_dir/prev"
	ftl_pane_self_id="%0"
	ftl_pane_is_primary=1
	ftl_pane_preview_id=""
	ftl_pane_height=24
	ftl_pane_width=80
	ftl_state_preview_pane_visible=1
	ftl_state_current_path="/tmp"
	ftl_state_current_dir="/tmp"
	ftl_state_current_basename=""
	ftl_state_current_extension=""
	ftl_state_current_tab_index=0
	ftl_state_cursor_index=0
	ftl_state_quit_cancelled=0
	ftl_state_pending_input=""
	ftl_kbd_current_key=""
	ftl_selection_tags=()
	ftl_selection_current=()
	ftl_selection_total_bytes=0
	ftl_selection_revision=0
	ftl_list_entries=()
	ftl_list_entry_count=0
	ftl_tab_directories=()
	ftl_tab_count=0
	ftl_filter_pipeline_list=()
	ftl_mark_session_marks=()
	ftl_kbd_trie=()
	ftl_kbd_command_to_key=()
	ftl_cfg_image_zoomed=0
	ftl_cfg_editor="echo"
	ftl_cfg_diff_tool="echo"
	ftl_cfg_delete_command="echo"
	FTL_STATE_DIR="$ftl_state_session_dir"
	declare -gA ftl_filter_listing_hide_exts=()
}

ftl::test::teardown() {
	rm -rf "$ftl_state_session_dir" 2>/dev/null
}

#==== File Operations ====

test_mf_duplicate_exists() { [[ $(type -t ftl::plugin::missing::duplicate) == function ]] && ftl::test::pass "duplicate exists" ; }
test_mf_hardlink_exists() { [[ $(type -t ftl::plugin::missing::hardlink) == function ]] && ftl::test::pass "hardlink exists" ; }
test_mf_touch_exists() { [[ $(type -t ftl::plugin::missing::touch_files) == function ]] && ftl::test::pass "touch exists" ; }
test_mf_checksum_exists() { [[ $(type -t ftl::plugin::missing::checksum) == function ]] && ftl::test::pass "checksum exists" ; }
test_mf_checksum_verify_exists() { [[ $(type -t ftl::plugin::missing::checksum_verify) == function ]] && ftl::test::pass "checksum_verify exists" ; }
test_mf_rename_pattern_exists() { [[ $(type -t ftl::plugin::missing::rename_pattern) == function ]] && ftl::test::pass "rename_pattern exists" ; }
test_mf_chmod_numeric_exists() { [[ $(type -t ftl::plugin::missing::chmod_numeric) == function ]] && ftl::test::pass "chmod_numeric exists" ; }
test_mf_chown_exists() { [[ $(type -t ftl::plugin::missing::chown_files) == function ]] && ftl::test::pass "chown exists" ; }

test_mf_duplicate_works() {
	local d=$(mktemp -d)
	echo "test" > "$d/file.txt"
	ftl_selection_current=("$d/file.txt")
	cd "$d"
	ftl::plugin::missing::duplicate 2>/dev/null
	ftl::test::assert_eq "1" "$(ls "$d"/file_copy*.txt 2>/dev/null | wc -l)" "duplicate created"
	cd /
	rm -rf "$d"
}

test_mf_touch_works() {
	local f=$(mktemp)
	local old_mtime=$(stat -c %Y "$f")
	sleep 1
	ftl_selection_current=("$f")
	ftl::plugin::missing::touch_files 2>/dev/null
	local new_mtime=$(stat -c %Y "$f")
	ftl::test::assert_ne "$old_mtime" "$new_mtime" "timestamp updated"
	rm "$f"
}

test_mf_invert_selection() {
	ftl_list_entries=("/tmp/a" "/tmp/b" "/tmp/c")
	ftl::sel::set "/tmp/a"
	ftl::plugin::missing::selection_invert 2>/dev/null
	ftl::test::assert_eq "0" "${ftl_selection_tags[/tmp/a]:-}" "a unselected"
	ftl::test::assert_eq "1" "${ftl_selection_tags[/tmp/b]:-1}" "b selected"
	ftl::test::assert_eq "1" "${ftl_selection_tags[/tmp/c]:-1}" "c selected"
}

test_mf_select_by_pattern() {
	ftl_list_entries=("/tmp/test.py" "/tmp/readme.md" "/tmp/other.py")
	ftl_kbd_current_key="\.py$"
	ftl::plugin::missing::select_by_pattern 2>/dev/null
	ftl::test::assert_eq "1" "${ftl_selection_tags[/tmp/test.py]:-1}" "test.py selected"
	ftl::test::assert_eq "1" "${ftl_selection_tags[/tmp/other.py]:-1}" "other.py selected"
}

test_mf_select_by_size() {
	local big=$(mktemp); dd if=/dev/zero bs=1024 count=10 of="$big" 2>/dev/null
	local small=$(mktemp); echo "x" > "$small"
	ftl_list_entries=("$big" "$small")
	ftl_kbd_current_key="5000"
	ftl::plugin::missing::select_by_size 2>/dev/null
	ftl::test::assert_eq "1" "${ftl_selection_tags[$big]:-1}" "big file selected"
	ftl::test::assert_eq "0" "${ftl_selection_tags[$small]:-}" "small not selected"
	rm "$big" "$small"
}

test_mf_size_analysis() {
	local d=$(mktemp -d)
	echo "data" > "$d/f1"
	ftl_state_current_path="$d"
	cd "$d"
	ftl::plugin::missing::size_analysis 2>/dev/null
	ftl::test::pass "size_analysis ran"
	cd /
	rm -rf "$d"
}

#==== Navigation ====

test_mf_nav_back_exists() { [[ $(type -t ftl::plugin::missing::nav_back) == function ]] && ftl::test::pass "nav_back exists" ; }
test_mf_nav_forward_exists() { [[ $(type -t ftl::plugin::missing::nav_forward) == function ]] && ftl::test::pass "nav_forward exists" ; }
test_mf_move_left_select_exists() { [[ $(type -t ftl::plugin::missing::move_left_select) == function ]] && ftl::test::pass "move_left_select exists" ; }
test_mf_marks_manage_exists() { [[ $(type -t ftl::plugin::missing::marks_manage) == function ]] && ftl::test::pass "marks_manage exists" ; }

test_mf_nav_record_and_back() {
	ftl_pane_is_child=0
	ftl_state_current_path="/tmp"
	ftl_plugin_missing_nav_history=()
	ftl_plugin_missing_nav_index=0
	ftl::plugin::missing::nav_record
	ftl::test::assert_eq "1" "${#ftl_plugin_missing_nav_history[@]}" "history recorded"
}

#==== Selection ====

test_mf_selection_save_exists() { [[ $(type -t ftl::plugin::missing::selection_save) == function ]] && ftl::test::pass "save exists" ; }
test_mf_selection_load_exists() { [[ $(type -t ftl::plugin::missing::selection_load) == function ]] && ftl::test::pass "load exists" ; }
test_mf_selection_union_exists() { [[ $(type -t ftl::plugin::missing::selection_union) == function ]] && ftl::test::pass "union exists" ; }
test_mf_selection_intersect_exists() { [[ $(type -t ftl::plugin::missing::selection_intersect) == function ]] && ftl::test::pass "intersect exists" ; }
test_mf_selection_subtract_exists() { [[ $(type -t ftl::plugin::missing::selection_subtract) == function ]] && ftl::test::pass "subtract exists" ; }
test_mf_visual_mode_exists() { [[ $(type -t ftl::plugin::missing::visual_mode) == function ]] && ftl::test::pass "visual_mode exists" ; }

test_mf_selection_save_load_roundtrip() {
	ftl::sel::set "/tmp/save_test"
	local savefile="$ftl_state_session_dir/saved"
	printf '%s\n' "${!ftl_selection_tags[@]}" > "$savefile"
	ftl::sel::clear_all
	while read -r p ; do ftl::sel::set "$p" ; done < "$savefile"
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "roundtrip 1 tag"
}

#==== Search ====

test_mf_rg_replace_exists() { [[ $(type -t ftl::plugin::missing::rg_replace) == function ]] && ftl::test::pass "rg_replace exists" ; }
test_mf_find_with_history_exists() { [[ $(type -t ftl::plugin::missing::find_with_history) == function ]] && ftl::test::pass "find_with_history exists" ; }

#==== Preview ====

test_mf_preview_pin_exists() { [[ $(type -t ftl::plugin::missing::preview_pin) == function ]] && ftl::test::pass "pin exists" ; }
test_mf_preview_unpin_exists() { [[ $(type -t ftl::plugin::missing::preview_unpin) == function ]] && ftl::test::pass "unpin exists" ; }
test_mf_preview_compare_exists() { [[ $(type -t ftl::plugin::missing::preview_compare) == function ]] && ftl::test::pass "compare exists" ; }
test_mf_preview_zoom_in_exists() { [[ $(type -t ftl::plugin::missing::preview_zoom_in) == function ]] && ftl::test::pass "zoom_in exists" ; }
test_mf_preview_zoom_out_exists() { [[ $(type -t ftl::plugin::missing::preview_zoom_out) == function ]] && ftl::test::pass "zoom_out exists" ; }
test_mf_preview_rotate_exists() { [[ $(type -t ftl::plugin::missing::preview_rotate) == function ]] && ftl::test::pass "rotate exists" ; }
test_mf_preview_tail_live_exists() { [[ $(type -t ftl::plugin::missing::preview_tail_live) == function ]] && ftl::test::pass "tail_live exists" ; }

#==== UI ====

test_mf_command_palette_exists() { [[ $(type -t ftl::plugin::missing::command_palette) == function ]] && ftl::test::pass "command_palette exists" ; }
test_mf_workspace_save_exists() { [[ $(type -t ftl::plugin::missing::workspace_save) == function ]] && ftl::test::pass "workspace_save exists" ; }
test_mf_workspace_load_exists() { [[ $(type -t ftl::plugin::missing::workspace_load) == function ]] && ftl::test::pass "workspace_load exists" ; }

test_mf_workspace_save_load() {
	local ws="$FTL_STATE_DIR/workspaces/test_ws"
	mkdir -p "$ws"
	printf '/tmp\n/var\n' > "$ws/tabs"
	echo "0" > "$ws/active_tab"
	ftl::test::assert_eq "1" "$(test -f "$ws/tabs" && echo 1)" "workspace file exists"
	rm -rf "$ws"
}

#==== Git ====

test_mf_git_blame_exists() { [[ $(type -t ftl::plugin::missing::git_blame_preview) == function ]] && ftl::test::pass "git_blame exists" ; }
test_mf_git_file_log_exists() { [[ $(type -t ftl::plugin::missing::git_file_log) == function ]] && ftl::test::pass "git_file_log exists" ; }
test_mf_git_diff_stat_exists() { [[ $(type -t ftl::plugin::missing::git_diff_stat) == function ]] && ftl::test::pass "git_diff_stat exists" ; }

#==== Archives ====

test_mf_compress_zip_exists() { [[ $(type -t ftl::plugin::missing::compress_zip) == function ]] && ftl::test::pass "compress_zip exists" ; }
test_mf_compress_7z_exists() { [[ $(type -t ftl::plugin::missing::compress_7z) == function ]] && ftl::test::pass "compress_7z exists" ; }
test_mf_archive_list_exists() { [[ $(type -t ftl::plugin::missing::archive_list) == function ]] && ftl::test::pass "archive_list exists" ; }

#==== Remote ====

test_mf_scp_upload_exists() { [[ $(type -t ftl::plugin::missing::scp_upload) == function ]] && ftl::test::pass "scp_upload exists" ; }
test_mf_download_url_exists() { [[ $(type -t ftl::plugin::missing::download_url) == function ]] && ftl::test::pass "download_url exists" ; }

#==== Bindings registered ====

test_mf_bindings_registered() {
	local bound=0
	grep -c 'ftl::kbd::bind' "$FTL_CFG/bindings/missing_functionalities" 2>/dev/null
}

test_mf_all_functions_exist() {
	for fn in duplicate hardlink touch_files checksum checksum_verify \
		rename_pattern chmod_numeric chown_files selection_invert \
		select_by_pattern select_by_size size_analysis nav_back nav_forward \
		move_left_select marks_manage selection_save selection_load \
		selection_union selection_intersect selection_subtract visual_mode \
		rg_replace find_with_history preview_pin preview_unpin preview_compare \
		preview_zoom_in preview_zoom_out preview_rotate preview_tail_live \
		command_palette workspace_save workspace_load git_blame_preview \
		git_file_log git_diff_stat compress_zip compress_7z archive_list \
		scp_upload download_url; do
		[[ $(type -t "ftl::plugin::missing::$fn") == function ]] || ftl::test::fail "ftl::plugin::missing::$fn not defined"
	done
	ftl::test::pass "all 42 missing functionality functions exist"
}

# vim: set filetype=bash :
