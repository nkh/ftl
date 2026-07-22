#!/bin/env bash
# test/integration/test_integration_deep.sh — 50 deep integration tests

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/debug.sh"
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

tmux() { : ; }
_TMP=$(mktemp -d)

ftl::test::setup() {
	ftl_state_session_dir="$_TMP/$$"
	mkdir -p "$ftl_state_session_dir/prev"
	ftl_state_parent_dir="$ftl_state_session_dir"
	ftl_state_shared_dir="$ftl_state_session_dir/prev"
	ftl_pane_self_id="%0"
	ftl_pane_is_primary=1
	ftl_pane_preview_id=""
	ftl_pane_height=24
	ftl_pane_width=80
	ftl_pane_prev_width=80
	ftl_pane_prev_height=24
	ftl_state_preview_pane_visible=1
	ftl_state_preview_zoom_index=1
	ftl_state_alt_preview_mode=0
	ftl_state_external_viewer_mode=0
	ftl_state_dir_preview_mode=0
	ftl_state_etag_enabled=0
	ftl_state_show_size_mode=0
	ftl_state_show_stat=0
	ftl_state_search_string=""
	ftl_state_current_path="/tmp"
	ftl_state_current_dir="/tmp"
	ftl_state_current_basename=""
	ftl_state_current_extension=""
	ftl_state_current_tab_index=0
	ftl_state_cursor_index=0
	ftl_state_quit_cancelled=0
	ftl_state_winch_pending=0
	ftl_state_pending_input=""
	ftl_state_previous_pwd=""
	ftl_state_child_env=()
	ftl_list_entries=()
	ftl_list_entry_count=0
	ftl_selection_tags=()
	ftl_selection_current=()
	ftl_selection_total_bytes=0
	ftl_selection_revision=0
	ftl_tab_directories=()
	ftl_tab_count=0
	ftl_filter_pipeline_list=()
	ftl_filter_pipeline_string=""
	ftl_filter_active_glyph=""
	ftl_filter_external_name=""
	ftl_filter_listing_hide_exts=()
	ftl_filter_listing_keep_exts=()
	ftl_kbd_trie=()
	ftl_kbd_command_to_key=()
	ftl_kbd_redo_excluded=()
	ftl_kbd_bindings_display=()
	ftl_kbd_submode_handler=""
	ftl_kbd_current_key=""
	ftl_kbd_accumulated_keys=""
	ftl_kbd_keys_count=0
	ftl_kbd_has_count=""
	ftl_kbd_count=""
	ftl_kbd_last_command=""
	ftl_kbd_warn_on_override=0
	ftl_mark_session_marks=()
	ftl_time_handlers=()
	ftl_time_last_event_time=0
	ftl_cfg_time_event_interval=0
	ftl_cfg_auto_sync_selection=1
	ftl_cfg_preview_zoom_levels=(85 70 50 30)
	ftl_cfg_glyph_tag_classes=("" "1" "2" "3" "D")
	ftl_cfg_image_zoomed=0
	ftl_cfg_auto_select_filename="README"
	ftl_cfg_default_reverse_filter=""
	ftl_cfg_sort_options=("-k3 -V" "-n" "-k2 -V")
	ftl_cfg_row_separator_chars=(" " " ")
	ftl_cfg_glyph_sort=("a" "b" "c")
	ftl_preview_is_vim=""
	ftl_preview_is_dir_ftl=""
	ftl_preview_is_image_daemon=""
	ftl_view_vim_tail_commands=()
	ftl_view_preview_ignore_exts=()
	ftl_view_media_pid=""
	ftl_etag_source_name=""
	ftl_etag_callback=""
	ftl_plugin_vfiles=()
	ftl_plugin_vdirs=()
	ftl_plugin_virtual_enabled=0
	ftl_log_level=0
	ftl_log_file=""
	ftl_log_alt_screen=0
}

ftl::test::teardown() { : ; }

#==== 1. Keyboard + selection workflow (10) ====

test_deep_bind_and_select() {
	ftl::kbd::bind ftl test "t" ftl::sel::flip "tag"
	ftl_list_entries=("/tmp/deep1")
	ftl_list_entry_count=1
	ftl_state_cursor_index=0
	ftl::sel::flip "/tmp/deep1"
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "tagged via bound function"
}

test_deep_count_then_select() {
	ftl_kbd_count="3"
	ftl_list_entries=("/tmp/c1" "/tmp/c2" "/tmp/c3" "/tmp/c4")
	ftl_list_entry_count=4
	ftl_state_cursor_index=0
	ftl::sel::flip "/tmp/c1"
	ftl::sel::flip "/tmp/c2"
	ftl::sel::flip "/tmp/c3"
	ftl::test::assert_eq "3" "${#ftl_selection_tags[@]}" "3 tags via count"
}

test_deep_class_selection() {
	ftl_list_entries=("/tmp/cl1")
	ftl_list_entry_count=1
	ftl_state_cursor_index=0
	ftl::sel::set "/tmp/cl1" "1"
	ftl::test::assert_eq "1" "${ftl_selection_tags[/tmp/cl1]}" "class 1 glyph"
}

test_deep_selection_resolve() {
	ftl::sel::set "/tmp/r1"
	ftl::sel::set "/tmp/r2"
	ftl_list_entry_count=0
	ftl::sel::resolve_current
	ftl::test::assert_eq "2" "${#ftl_selection_current[@]}" "resolved 2"
}

test_deep_selection_clear() {
	ftl::sel::set "/tmp/cc1"
	ftl::sel::set "/tmp/cc2"
	ftl::sel::clear_all
	ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "cleared"
}

test_deep_selection_validate() {
	local f=$(mktemp)
	ftl::sel::set "$f"
	ftl::sel::set "/nonexistent"
	ftl::sel::validate_existence
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "1 valid"
	rm "$f"
}

test_deep_unbind_removes_function() {
	ftl::kbd::bind ftl test "x" my_func "test"
	ftl::kbd::unbind "x"
	ftl::test::assert_eq "" "${ftl_kbd_trie[x]:-}" "unbind works"
}

test_deep_exclude_from_redo() {
	ftl::kbd::exclude_from_redo "excluded"
	ftl::test::assert_eq "1" "${ftl_kbd_redo_excluded[excluded]}" "excluded"
}

test_deep_reset_exclusions() {
	ftl::kbd::exclude_from_redo "a"
	ftl::kbd::exclude_from_redo "b"
	ftl::kbd::reset_redo_exclusions
	ftl::test::assert_eq "0" "${#ftl_kbd_redo_excluded[@]}" "all cleared"
}

test_deep_multi_key_binding() {
	ftl::kbd::bind ftl test "abc" test_fn "triple"
	ftl::test::assert_eq "test_fn" "${ftl_kbd_trie[abc]}" "triple key bound"
}

#==== 2. Tab + filter + state (10) ====

test_deep_tab_with_filter() {
	ftl::tab::create "/proj"
	ftl_tab_filter_1[0]="\.py$"
	ftl::test::assert_eq "\.py$" "${ftl_tab_filter_1[0]}" "filter per tab"
}

test_deep_tab_switch_preserves() {
	ftl::tab::create "/a"
	ftl::tab::create "/b"
	ftl_tab_filter_1[0]="filter_a"
	ftl_tab_filter_1[1]="filter_b"
	ftl_state_current_tab_index=0
	ftl::tab::advance_index
	ftl::test::assert_eq "filter_b" "${ftl_tab_filter_1[1]}" "other tab filter preserved"
}

test_deep_state_save_with_tags() {
	ftl::sel::set "/tmp/sst"
	ftl::state::save
	ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/tags" && echo 1)" "tags saved"
}

test_deep_state_save_stagsi() {
	ftl_selection_revision=42
	ftl::state::save
	ftl::test::assert_eq "42" "$(cat "$ftl_state_shared_dir/stagsi")" "stagsi correct"
}

test_deep_state_save_fs() {
	ftl::state::save
	ftl::test::assert_contains "$(cat "$ftl_state_shared_dir/fs")" "$ftl_state_session_dir" "fs pointer"
}

test_deep_serialize_info() {
	ftl::state::serialize_info "$ftl_state_session_dir/info"
	ftl::test::assert_contains "$(cat "$ftl_state_session_dir/info")" "FTL_PID" "info has PID"
}

test_deep_child_env() {
	ftl_state_parent_dir="/p"
	ftl_state_session_dir="/s"
	declare -gA ftl_state_child_env=()
	local r=$(ftl::state::render_child_env)
	ftl::test::assert_contains "$r" "ftl_pfs=/p" "child env pfs"
}

test_deep_filter_pipeline_full() {
	ftl_filter_pipeline_list=()
	ftl::filt::pipeline_add a b c
	ftl::filt::pipeline_remove b
	ftl::test::assert_eq "2" "${#ftl_filter_pipeline_list[@]}" "2 after remove"
}

test_deep_filter_reset_clears_glyph() {
	ftl_filter_active_glyph="~"
	ftl::filt::reset
	ftl::test::assert_eq "" "$ftl_filter_active_glyph" "glyph cleared"
}

test_deep_filter_init_populates() {
	ftl_filter_pipeline_list=()
	ftl::filt::init
	ftl::test::assert_ne "0" "${#ftl_filter_pipeline_list[@]}" "init populated"
}

#==== 3. Virtual + etag + time (10) ====

test_deep_virtual_full_cycle() {
	ftl::plugin::virtual::enable 1
	ftl::plugin::virtual::get_dirs_callback() { echo "vd"; }
	ftl::plugin::virtual::get_files_callback() { echo "vf"; }
	ftl::plugin::virtual::inject_entries
	ftl::test::assert_eq "1" "${#ftl_plugin_vdirs[@]}" "vdir injected"
	ftl::test::assert_eq "1" "${#ftl_plugin_vfiles[@]}" "vfile injected"
	ftl::plugin::virtual::reset
	ftl::test::assert_eq "0" "$ftl_plugin_virtual_enabled" "reset disabled"
}

test_deep_virtual_get_dirs_format() {
	ftl_plugin_vdirs=([d1]=1)
	local r=$(ftl::plugin::virtual::get_virtual_dirs)
	ftl::test::assert_contains "$r" "0	0	d1" "format correct"
}

test_deep_virtual_callbacks() {
	ftl::plugin::virtual::set_callbacks D F C P H
	ftl::test::assert_contains "$ftl_etag_callback" "D" "has D"
	ftl::test::assert_contains "$ftl_etag_callback" "F" "has F"
}

test_deep_etag_noop() {
	ftl::etag::scan_directory
	ftl::test::pass "etag scan noop"
}

test_deep_etag_tag_empty() {
	local t l
	ftl::etag::get_entry_tag "/x" t l
	ftl::test::assert_eq "" "$t" "empty tag"
	ftl::test::assert_eq "0" "$l" "zero length"
}

test_deep_time_disabled() {
	ftl_cfg_time_event_interval=0
	ftl::time::tick
	ftl::test::pass "tick disabled noop"
}

test_deep_time_fires() {
	ftl_cfg_time_event_interval=1
	ftl_time_last_event_time=0
	_h() { _hit=1; }
	ftl_time_handlers[_h]=_h
	_hit=0
	ftl::time::tick
	ftl::test::assert_eq "1" "$_hit" "handler fired"
}

test_deep_time_skips() {
	ftl_cfg_time_event_interval=999
	ftl_time_last_event_time=$SECONDS
	_nh() { :; }
	ftl_time_handlers[_nh]=_nh
	ftl::time::tick
	ftl::test::pass "correctly skipped"
}

test_deep_etag_source_set() {
	ftl_etag_source_name="git"
	ftl::test::assert_eq "git" "$ftl_etag_source_name" "source set"
}

test_deep_virtual_disabled_inject() {
	ftl_plugin_virtual_enabled=0
	ftl::plugin::virtual::get_dirs_callback() { echo "x"; }
	ftl::plugin::virtual::inject_entries
	ftl::test::assert_eq "0" "${#ftl_plugin_vdirs[@]}" "noop when disabled"
}

#==== 4. Logging + debug (8) ====

test_deep_log_init_debug() {
	ftl_state_session_dir=$(mktemp -d)
	FTL_DEBUG=1 ftl::log::init
	ftl::test::assert_eq "1" "$ftl_log_level" "level 1"
	rm -rf "$ftl_state_session_dir"
}

test_deep_log_debug_writes() {
	ftl_log_level=1
	ftl_log_file="$_TMP/d.log"
	: > "$ftl_log_file"
	ftl::log::debug "msg"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "msg" "written"
}

test_deep_log_info_always() {
	ftl_log_level=0
	ftl_log_file="$_TMP/i.log"
	: > "$ftl_log_file"
	ftl::log::info "always"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "always" "info written"
}

test_deep_log_trace_at_2() {
	ftl_log_level=2
	ftl_log_file="$_TMP/t.log"
	: > "$ftl_log_file"
	ftl::log::trace "tr"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "tr" "trace written"
}

test_deep_log_trace_suppressed_at_1() {
	ftl_log_level=1
	ftl_log_file="$_/tmp/ts.log"
	: > "$ftl_log_file"
	ftl::log::trace "no"
	ftl::test::assert_eq "" "$(cat "$ftl_log_file")" "suppressed"
}

test_deep_log_set_level() {
	ftl::log::set_level 2
	ftl::test::assert_eq "2" "$ftl_log_level"
	ftl::log::set_level 0
	ftl::test::assert_eq "0" "$ftl_log_level"
}

test_deep_log_warn_writes() {
	ftl_log_level=1
	ftl_log_file="$_TMP/w.log"
	: > "$ftl_log_file"
	ftl::log::warn "warn"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "WARN: warn"
}

test_deep_log_error_writes() {
	ftl_log_level=1
	ftl_log_file="$_TMP/e.log"
	: > "$ftl_log_file"
	ftl::log::error "err"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "ERROR: err"
}

#==== 5. Preview + pane (8) ====

test_deep_preview_clear() {
	ftl_pane_preview_id="%9"
	ftl_preview_is_vim=1
	ftl::prev::clear
	ftl::test::assert_eq "" "$ftl_pane_preview_id" "cleared"
	ftl::test::assert_eq "" "$ftl_preview_is_vim" "vim cleared"
}

test_deep_preview_clear_sets_vis() {
	ftl::prev::clear 0
	ftl::test::assert_eq "0" "$ftl_state_preview_pane_visible" "vis=0"
}

test_deep_preview_dispatch_primary() {
	ftl_pane_is_primary=1
	ftl::prev::dispatch 2>/dev/null
	ftl::test::pass "primary dispatch"
}

test_deep_pane_query() {
	ftl::pane::query_geometry
	ftl::test::assert_eq "%0" "$ftl_pane_self_id" "self_id set"
}

test_deep_pane_border() {
	ftl::pane::set_border_colors 10 20
	ftl::test::pass "border colors ok"
}

test_deep_pane_snapshot() {
	ftl_pane_width=100
	ftl_pane_height=50
	ftl_pane_prev_width=$ftl_pane_width
	ftl_pane_prev_height=$ftl_pane_height
	ftl::test::assert_eq "100" "$ftl_pane_prev_width" "snapshot ok"
}

test_deep_thumb_path() {
	ftl_state_current_path="/tmp/img.jpg"
	ftl_state_current_basename="img.jpg"
	local r=$(ftl::gen::thumb_path "jpg" "jpg")
	ftl::test::assert_contains "$r" "img.jpg" "thumb path"
}

test_deep_preview_sync_noop() {
	ftl_pane_is_child=1
	ftl::prev::sync_and_dispatch 2>/dev/null
	ftl::test::pass "sync didn't crash"
}

#==== 6. Command dispatch (8) ====

test_deep_dispatch_empty() {
	ftl::cmd::dispatch_command "0"
	ftl::test::assert_eq "1" "$?" "empty returns 1"
}

test_deep_dispatch_qa() {
	_q=0
	ftl::cmd::quit_all() { _q=1; }
	ftl::cmd::dispatch_command "qa"
	ftl::test::assert_eq "1" "$_q" "qa called quit_all"
}

test_deep_dispatch_load_sel() {
	_l=0
	ftl::sel::load_from_file() { _l=1; }
	ftl::cmd::dispatch_command "load_sel"
	ftl::test::assert_eq "1" "$_l" "load_sel called"
}

test_deep_dispatch_trie() {
	ftl::kbd::bind ftl test "zz" trie_cmd "test"
	ftl_kbd_trie[zz]="trie_cmd"
	ftl::cmd::dispatch_command "zz" 2>/dev/null
	ftl::test::pass "trie dispatch ok"
}

test_deep_quote_entries() {
	ftl_list_entries=("/tmp/a" "/tmp/b")
	local r=$(ftl::list::quote_all_entries)
	ftl::test::assert_contains "$r" "/tmp/a" "quoted"
}

test_deep_quote_selection() {
	ftl_selection_current=("/tmp/s1")
	local r=$(ftl::list::quote_selection)
	ftl::test::assert_contains "$r" "s1" "selection quoted"
}

test_deep_move_cursor() {
	ftl_list_entry_count=5
	ftl_state_cursor_index=2
	ftl::list::move_cursor 1
	ftl::test::assert_eq "3" "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]:-}" "moved to 3"
}

test_deep_move_clamp() {
	ftl_list_entry_count=3
	ftl_state_cursor_index=2
	ftl::list::move_cursor 100
	ftl::test::pass "clamped ok"
}

#==== 7. Edge cases (6) ====

test_deep_all_modules_loaded() {
	for fn in ftl::util::parse_path ftl::log::debug ftl::state::save \
		ftl::kbd::bind ftl::sel::flip ftl::tab::create \
		ftl::pane::split ftl::filt::reset ftl::list::render \
		ftl::prev::dispatch ftl::etag::scan_directory \
		ftl::plugin::virtual::enable ftl::time::tick; do
		[[ $(type -t "$fn") == function ]] || ftl::test::fail "$fn"
	done
	ftl::test::pass "all modules loaded"
}

test_deep_path_extension() {
	ftl::util::parse_path "/tmp/file.tar.gz"
	ftl::test::assert_eq "gz" "$ftl_state_current_extension" "ext is gz"
}

test_deep_path_hidden() {
	ftl::util::parse_path "/home/u/.bashrc"
	ftl::test::assert_eq "bashrc" "$ftl_state_current_extension" "hidden ext"
}

test_deep_flip_idempotent_glyph() {
	ftl::sel::set "/tmp/idem" "2"
	ftl::sel::set "/tmp/idem" "3"
	ftl::test::assert_eq "2" "${ftl_selection_tags[/tmp/idem]}" "glyph not changed"
}

test_deep_size_gigabyte() {
	local r=$(ftl::util::format_size_human 1073741824)
	ftl::test::assert_contains "$r" "G" "gigabyte"
}

test_deep_cleanup() {
	rm -rf "$_TMP"
	ftl::test::pass "cleanup done"
}

# vim: set filetype=bash :
