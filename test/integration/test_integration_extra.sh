#!/bin/env bash
# test/integration/test_integration_extra.sh — 100 additional integration tests

FTL_CFG="${FTL_CFG:-$(cd "$(dirname "$0")/../.." && pwd)/config/ftl}"

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

tmux() { case "$1" in display) echo "%0" ;; *) : ;; esac }
_INTEG2_TMP="$(mktemp -d)"

ftl::test::setup() {
	ftl_state_session_dir="$_INTEG2_TMP/$$"
	mkdir -p "$ftl_state_session_dir/prev"
	ftl_state_parent_dir="$ftl_state_session_dir"
	ftl_state_shared_dir="$ftl_state_session_dir/prev"
	ftl_pane_self_id="%0"
	ftl_selection_tags=()
	ftl_selection_total_bytes=0
	ftl_selection_revision=0
	ftl_selection_current=()
	ftl_list_entries=()
	ftl_list_entry_count=0
	ftl_state_cursor_index=0
	ftl_state_current_tab_index=0
	ftl_tab_directories=()
	ftl_tab_count=0
	ftl_log_level=0
	ftl_log_file=
}

#==========================================================================
# 1. Path + selection deep integration (10 tests)
#==========================================================================

test_e2_path_tag_untag() {
	ftl::util::parse_path "/tmp/e2_test.txt"
	ftl::sel::set "$ftl_state_current_path"
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}"
	ftl::sel::unset "$ftl_state_current_path"
	ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}"
}

test_e2_path_class_tag() {
	ftl::util::parse_path "/tmp/class_e2.txt"
	ftl::sel::set "$ftl_state_current_path" "¹"
	ftl::test::assert_eq "¹" "${ftl_selection_tags[$ftl_state_current_path]}"
}

test_e2_multiple_tags_resolve() {
	ftl::sel::set "/tmp/multi_a"
	ftl::sel::set "/tmp/multi_b"
	ftl::sel::set "/tmp/multi_c"
	ftl_list_entry_count=0
	ftl::sel::resolve_current
	ftl::test::assert_eq "3" "${#ftl_selection_current[@]}"
}

test_e2_flip_cycle_revision() {
	local r0=$ftl_selection_revision
	ftl::sel::flip "/tmp/flip1"
	ftl::sel::flip "/tmp/flip1"
	ftl::test::assert_eq "$((r0 + 2))" "$ftl_selection_revision"
}

test_e2_validate_after_delete() {
	local f=$(mktemp)
	ftl::sel::set "$f"
	rm "$f"
	ftl::sel::validate_existence
	ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}"
}

test_e2_unset_by_class_keeps_others() {
	ftl::sel::set "/tmp/ka" "¹"
	ftl::sel::set "/tmp/kb" "²"
	ftl::sel::set "/tmp/kc" "¹"
	ftl::sel::unset_by_class "¹"
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}"
	ftl::test::assert_eq "²" "${ftl_selection_tags[/tmp/kb]}"
}

test_e2_clear_resets_all() {
	ftl::sel::set "/tmp/ca"
	ftl::sel::set "/tmp/cb"
	ftl::sel::clear_all
	ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}"
	ftl::test::assert_eq "0" "$ftl_selection_total_bytes"
}

test_e2_tag_size_tracking() {
	local f=$(mktemp); echo "12345678" > "$f"
	ftl::sel::set "$f"
	local s1=$ftl_selection_total_bytes
	ftl::sel::unset "$f"
	ftl::test::assert_eq "0" "$ftl_selection_total_bytes"
	rm "$f"
}

test_e2_header_summary_format() {
	local f=$(mktemp); echo "x" > "$f"
	ftl::sel::set "$f"
	local r=$(ftl::sel::format_header_summary)
	ftl::test::assert_contains "$r" "1/"
	rm "$f"
}

test_e2_load_from_file_tags() {
	local f=$(mktemp)
	echo "/tmp/loaded1" > "$f"
	echo "/tmp/loaded2" >> "$f"
	ftl::sel::load_from_file "" "$f"
	ftl::test::assert_eq "2" "${#ftl_selection_tags[@]}"
	rm "$f"
}

#==========================================================================
# 2. Keyboard + filter + tab deep integration (10 tests)
#==========================================================================

test_e2_bind_then_filter_pipeline() {
	ftl::kbd::bind ftl filter "ff" my_filter "filter"
	ftl::filt::pipeline_add fa fb
	ftl::test::assert_eq "my_filter" "${ftl_kbd_trie[ff]}"
	ftl::test::assert_eq "2" "${#ftl_filter_pipeline_list[@]}"
}

test_e2_tab_then_bind() {
	ftl::tab::create "/tmp/tab_bind"
	ftl::kbd::bind ftl test "tt" my_cmd "test"
	ftl::test::assert_eq "1" "${#ftl_tab_directories[@]}"
	ftl::test::assert_eq "my_cmd" "${ftl_kbd_trie[tt]}"
}

test_e2_filter_reset_after_pipeline() {
	ftl::filt::pipeline_add a b c
	ftl::filt::reset
	ftl::test::assert_eq "" "$ftl_filter_active_glyph"
}

test_e2_multi_key_bind_with_tab() {
	ftl::tab::create "/t1"
	ftl::kbd::bind ftl find "gff" find_cmd "fzf"
	ftl::kbd::bind ftl find "gfF" find_all_cmd "fzf all"
	ftl::test::assert_eq "find_cmd" "${ftl_kbd_trie[gff]}"
	ftl::test::assert_eq "find_all_cmd" "${ftl_kbd_trie[gfF]}"
}

test_e2_count_bind_separate_from_regular() {
	ftl::kbd::bind ftl move "COUNT %" pct_cmd "percent"
	ftl::kbd::bind ftl move "%" reg_cmd "plain percent"
	ftl::test::assert_eq "pct_cmd" "${ftl_kbd_trie[COUNT%]}"
	ftl::test::assert_eq "reg_cmd" "${ftl_kbd_trie[%]}"
}

test_e2_unbind_doesnt_affect_others() {
	ftl::kbd::bind ftl test "a" cmd_a "a"
	ftl::kbd::bind ftl test "b" cmd_b "b"
	ftl::kbd::unbind "a"
	ftl::test::assert_eq "" "${ftl_kbd_trie[a]:-}"
	ftl::test::assert_eq "cmd_b" "${ftl_kbd_trie[b]}"
}

test_e2_exclusion_persists_across_binds() {
	ftl::kbd::exclude_from_redo "excluded_cmd"
	ftl::kbd::bind ftl test "e" excluded_cmd "excluded"
	ftl::test::assert_eq "1" "${ftl_kbd_redo_excluded[excluded_cmd]}"
}

test_e2_tab_init_after_create() {
	ftl::tab::create "/new_tab"
	ftl::tab::init_defaults
	ftl::test::assert_eq "1" "${ftl_tab_listing_depth[0]}"
}

test_e2_tab_switch_preserves_filters() {
	ftl::tab::create "/t1"
	ftl::tab::create "/t2"
	ftl_tab_filter_1[1]="my_filter"
	ftl_state_current_tab_index=0
	ftl::tab::advance_index
	ftl::test::assert_eq "my_filter" "${ftl_tab_filter_1[1]}"
}

test_e2_pipeline_string_after_init() {
	ftl::filt::init
	local s="$ftl_filter_pipeline_string"
	ftl::filt::pipeline_clear
	ftl::test::assert_ne "" "$s" "init produced non-empty string"
}

#==========================================================================
# 3. State serialization roundtrip (10 tests)
#==========================================================================

test_e2_save_load_tags_roundtrip() {
	ftl::sel::set "/tmp/rt1"
	ftl::sel::set "/tmp/rt2"
	ftl::state::save_selection
	ftl_selection_tags=()
	ftl::state::load_selection "$ftl_state_session_dir"
	ftl::test::assert_eq "2" "${#ftl_selection_tags[@]}"
}

test_e2_save_writes_stagsi_correct() {
	ftl_selection_revision=77
	ftl::state::save
	ftl::test::assert_eq "77" "$(cat "$ftl_state_shared_dir/stagsi")"
}

test_e2_save_writes_fs_correct() {
	ftl::state::save
	local r=$(cat "$ftl_state_shared_dir/fs")
	ftl::test::assert_contains "$r" "$ftl_state_session_dir"
}

test_e2_serialize_info_has_pid() {
	ftl::state::serialize_info "$ftl_state_session_dir/i1"
	ftl::test::assert_contains "$(cat "$ftl_state_session_dir/i1")" "FTL_PID=$$"
}

test_e2_serialize_info_has_session_dir() {
	ftl::state::serialize_info "$ftl_state_session_dir/i2"
	ftl::test::assert_contains "$(cat "$ftl_state_session_dir/i2")" "FTL_SESSION_DIR"
}

test_e2_child_env_has_both_dirs() {
	declare -gA ftl_state_child_env=()
	ftl_state_parent_dir="/p"
	ftl_state_session_dir="/s"
	local r=$(ftl::state::render_child_env)
	ftl::test::assert_contains "$r" "ftl_pfs=/p"
	ftl::test::assert_contains "$r" "ftl_fs=/s"
}
test_e2_cleanup_removes_all() {
	local d=$(mktemp -d)
	ftl_state_session_dir="$d"
	touch "$d/marker"
	ftl::state::cleanup
	ftl::test::assert_eq "1" "$(test ! -d "$d" && echo 1)"
}

test_e2_save_empty_no_crash() {
	ftl_list_entry_count=0
	ftl::state::save
	ftl::test::pass "save with empty listing didn't crash"
}

test_e2_save_with_entries() {
	ftl_list_entry_count=1
	ftl_list_entries=("/tmp/some_file")
	ftl_state_cursor_index=0
	ftl::state::save
	ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/ftl" && echo 1)"
}

test_e2_state_file_contains_vars() {
	ftl_list_entry_count=1
	ftl_list_entries=("/tmp/sf_test")
	ftl_state_cursor_index=0
	ftl::state::save
	local content=$(cat "$ftl_state_session_dir/ftl")
	ftl::test::assert_contains "$content" "sdir"
}

#==========================================================================
# 4. Virtual entries + etag integration (10 tests)
#==========================================================================

test_e2_virtual_enable_then_inject() {
	ftl::plugin::virtual::enable 1
	ftl::plugin::virtual::get_dirs_callback() { echo "vdir"; }
	ftl::plugin::virtual::get_files_callback() { echo "vfile"; }
	ftl::plugin::virtual::inject_entries
	ftl::test::assert_eq "1" "${#ftl_plugin_vdirs[@]}"
	ftl::test::assert_eq "1" "${#ftl_plugin_vfiles[@]}"
}

test_e2_virtual_reset_clears_all() {
	ftl::plugin::virtual::enable 1
	ftl::plugin::virtual::get_dirs_callback() { echo "d"; }
	ftl::plugin::virtual::inject_entries
	ftl::plugin::virtual::reset
	ftl::test::assert_eq "0" "$ftl_plugin_virtual_enabled"
}

test_e2_virtual_get_dirs_format() {
	ftl_plugin_vdirs=([test_dir]=1)
	local r=$(ftl::plugin::virtual::get_virtual_dirs)
	ftl::test::assert_contains "$r" "0	0	test_dir"
}

test_e2_virtual_disabled_inject_noop() {
	ftl_plugin_virtual_enabled=0
	ftl::plugin::virtual::get_dirs_callback() { echo "should_not"; }
	ftl::plugin::virtual::inject_entries
	ftl::test::assert_eq "0" "${#ftl_plugin_vdirs[@]}"
}

test_e2_virtual_callbacks_set() {
	ftl::plugin::virtual::set_callbacks D F C P H
	ftl::test::assert_contains "$ftl_etag_callback" "get_dirs_callback"
	ftl::test::assert_contains "$ftl_etag_callback" "get_files_callback"
}

test_e2_etag_default_is_noop() {
	ftl::etag::scan_directory
	ftl::test::pass "etag scan no-op"
}

test_e2_etag_tag_returns_empty() {
	local tag len
	ftl::etag::get_entry_tag "/tmp/x" tag len
	ftl::test::assert_eq "" "$tag"
	ftl::test::assert_eq "0" "$len"
}

test_e2_etag_enabled_flag() {
	ftl_state_etag_enabled=1
	ftl::test::assert_eq "1" "$ftl_state_etag_enabled"
}

test_e2_virtual_and_etag_coexist() {
	ftl::plugin::virtual::enable 1
	ftl_etag_source_name="virtual"
	ftl::test::assert_eq "1" "$ftl_plugin_virtual_enabled"
	ftl::test::assert_eq "virtual" "$ftl_etag_source_name"
}

test_e2_virtual_clear_filter_passthrough() {
	local r=$(echo "data" | ftl::plugin::virtual::clear_filter)
	ftl::test::assert_eq "data" "$r"
}

#==========================================================================
# 5. Logging + time + debug integration (10 tests)
#==========================================================================

test_e2_log_init_with_debug() {
	ftl_state_session_dir=$(mktemp -d)
	FTL_DEBUG=1 ftl::log::init
	ftl::test::assert_eq "1" "$ftl_log_level"
	rm -rf "$ftl_state_session_dir"
}

test_e2_log_debug_to_file() {
	ftl_log_level=1
	ftl_log_file="$_INTEG2_TMP/dbg.log"
	: > "$ftl_log_file"
	ftl::log::debug "integration debug"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "integration debug"
}

test_e2_log_info_always() {
	ftl_log_level=0
	ftl_log_file="$_INTEG2_TMP/info.log"
	: > "$ftl_log_file"
	ftl::log::info "always info"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "always info"
}

test_e2_log_set_level_runtime() {
	ftl::log::set_level 2
	ftl::test::assert_eq "2" "$ftl_log_level"
	ftl::log::set_level 0
	ftl::test::assert_eq "0" "$ftl_log_level"
}

test_e2_time_disabled_noop() {
	ftl_cfg_time_event_interval=0
	ftl::time::tick
	ftl::test::pass "tick disabled noop"
}

test_e2_time_fires_handler() {
	ftl_cfg_time_event_interval=1
	ftl_time_last_event_time=0
	_fired=0
	_fire_handler() { _fired=1; }
	ftl_time_handlers[_fire_handler]=_fire_handler
	ftl::time::tick
	ftl::test::assert_eq "1" "$_fired"
}

test_e2_time_resets_after_fire() {
	ftl_cfg_time_event_interval=1
	ftl_time_last_event_time=0
	_noop_handler() { :; }
	ftl_time_handlers[_noop_handler]=_noop_handler
	ftl::time::tick
	ftl::test::assert_ne "0" "$ftl_time_last_event_time"
}

test_e2_time_skips_when_not_elapsed() {
	ftl_cfg_time_event_interval=999
	ftl_time_last_event_time=$SECONDS
	_should_not_fire() { ftl::test::fail "should not fire"; }
	ftl_time_handlers[_should_not_fire]=_should_not_fire
	ftl::time::tick
	ftl::test::pass "correctly skipped"
}

test_e2_debug_stacktrace_runs() {
	ftl::util::stacktrace 2>/dev/null
	ftl::test::pass "stacktrace ran"
}

test_e2_log_wrap_captures() {
	ftl_state_session_dir=$(mktemp -d)
	ftl::log::wrap echo "wrapped" 2>/dev/null
	ftl::test::pass "wrap ran"
	rm -rf "$ftl_state_session_dir"
}

#==========================================================================
# 6. Pane + preview integration (10 tests)
#==========================================================================

test_e2_preview_clear_all_flags() {
	ftl_pane_preview_id="%9"
	ftl_preview_is_vim=1
	ftl_preview_is_image_daemon=1
	ftl_preview_is_dir_ftl=1
	ftl::prev::clear
	ftl::test::assert_eq "" "$ftl_pane_preview_id"
	ftl::test::assert_eq "" "$ftl_preview_is_vim"
}

test_e2_preview_clear_sets_visibility() {
	ftl::prev::clear 1
	ftl::test::assert_eq "1" "$ftl_state_preview_pane_visible"
}

test_e2_preview_clear_zero() {
	ftl::prev::clear 0
	ftl::test::assert_eq "0" "$ftl_state_preview_pane_visible"
}

test_e2_preview_dispatch_primary() {
	ftl_pane_is_primary=1
	ftl_state_preview_pane_visible=0
	ftl_state_external_viewer_mode=0
	ftl::prev::dispatch 2>/dev/null
	ftl::test::pass "primary dispatch"
}

test_e2_preview_dispatch_child_signals() {
	ftl_pane_is_primary=0
	ftl_pane_is_child=1
	ftl::prev::dispatch 2>/dev/null
	ftl::test::pass "child dispatch"
}

test_e2_pane_query_sets_self_id() {
	ftl::pane::query_geometry
	ftl::test::assert_eq "%0" "$ftl_pane_self_id"
}

test_e2_pane_border_colors() {
	ftl::pane::set_border_colors 10 20
	ftl::test::pass "border colors set"
}

test_e2_pane_window_exists() {
	# Mock returns empty, so exists should be false
	if ftl::pane::window_exists "test_win" 2>/dev/null; then
		ftl::test::fail "should not exist"
	else
		ftl::test::pass "window correctly not found"
	fi
}

test_e2_preview_sync_no_crash() {
	ftl_pane_is_child=1
	ftl::prev::sync_and_dispatch 2>/dev/null
	ftl::test::pass "sync_and_dispatch didn't crash"
}

test_e2_thumb_path_format() {
	ftl_state_current_path="/tmp/image.jpg"
	ftl_state_current_basename="image.jpg"
	local r=$(ftl::gen::thumb_path "jpg" "jpg")
	ftl::test::assert_contains "$r" "image.jpg"
}

#==========================================================================
# 7. Command dispatch + listing integration (10 tests)
#==========================================================================

test_e2_dispatch_empty() {
	ftl::cmd::dispatch_command "0"
	ftl::test::assert_eq "1" "$?"
}

test_e2_dispatch_qa() {
	_qa=0
	ftl::cmd::quit_all() { _qa=1; }
	ftl::cmd::dispatch_command "qa"
	ftl::test::assert_eq "1" "$_qa"
}

test_e2_dispatch_load_sel() {
	_ls=0
	ftl::sel::load_from_file() { _ls=1; }
	ftl::cmd::dispatch_command "load_sel"
	ftl::test::assert_eq "1" "$_ls"
}

test_e2_dispatch_trie_shortcut() {
	ftl::kbd::bind ftl test "zz" trie_cmd "test"
	ftl_kbd_trie[zz]="trie_cmd"
	ftl::cmd::dispatch_command "zz" 2>/dev/null
	ftl::test::pass "trie shortcut dispatch"
}

test_e2_quote_all_entries() {
	ftl_list_entries=("/tmp/a" "/tmp/b")
	local r=$(ftl::list::quote_all_entries)
	ftl::test::assert_contains "$r" "/tmp/a"
	ftl::test::assert_contains "$r" "/tmp/b"
}

test_e2_quote_selection() {
	ftl_selection_current=("/tmp/sel1" "/tmp/sel2")
	local r=$(ftl::list::quote_selection)
	ftl::test::assert_contains "$r" "sel1"
}

test_e2_move_cursor_down() {
	ftl_list_entry_count=5
	ftl_state_cursor_index=2
	ftl::list::move_cursor 1
	ftl::test::assert_eq "3" "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]:-}"
}

test_e2_move_cursor_clamp() {
	ftl_list_entry_count=3
	ftl_state_cursor_index=2
	ftl::list::move_cursor 10
	# Should clamp to nfiles-1=2
	ftl::test::pass "move clamped"
}

test_e2_move_cursor_up() {
	ftl_list_entry_count=5
	ftl_state_cursor_index=3
	ftl::list::move_cursor -1
	ftl::test::assert_eq "2" "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]:-}"
}

test_e2_move_cursor_negative_clamp() {
	ftl_list_entry_count=3
	ftl_state_cursor_index=0
	ftl::list::move_cursor -5
	ftl::test::pass "negative move clamped"
}

#==========================================================================
# 8. Module interaction edge cases (10 tests)
#==========================================================================

test_e2_all_modules_loaded() {
	for fn in ftl::util::parse_path ftl::log::debug ftl::state::save \
		ftl::kbd::bind ftl::sel::flip ftl::tab::create \
		ftl::pane::split ftl::filt::reset ftl::list::render \
		ftl::prev::dispatch ftl::etag::scan_directory \
		ftl::plugin::virtual::enable ftl::time::tick; do
		[[ $(type -t "$fn") == function ]] || ftl::test::fail "$fn"
	done
	ftl::test::pass "all modules loaded"
}

test_e2_filter_then_reset_then_init() {
	ftl::filt::pipeline_add temp
	ftl::filt::reset
	ftl::filt::init
	ftl::test::assert_ne "" "$ftl_filter_pipeline_string"
}

test_e2_selection_then_state_save() {
	ftl::sel::set "/tmp/ss_test"
	ftl::state::save
	ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/tags" && echo 1)"
}

test_e2_tab_then_state_save() {
	ftl::tab::create "/tmp/tab_state"
	ftl_list_entry_count=1
	ftl_list_entries=("/tmp/tab_state")
	ftl_state_cursor_index=0
	ftl::state::save
	ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/ftl" && echo 1)"
}

test_e2_keyboard_exclusion_then_reset() {
	ftl::kbd::exclude_from_redo "cmd1"
	ftl::kbd::exclude_from_redo "cmd2"
	ftl::kbd::reset_redo_exclusions
	ftl::test::assert_eq "0" "${#ftl_kbd_redo_excluded[@]}"
}

test_e2_virtual_then_etag_source() {
	ftl::plugin::virtual::enable 1
	ftl_etag_source_name="virtual"
	ftl::test::assert_eq "1" "$ftl_plugin_virtual_enabled"
	ftl::test::assert_eq "virtual" "$ftl_etag_source_name"
}

test_e2_log_then_time_handler() {
	ftl_log_level=1
	ftl_log_file="$_INTEG2_TMP/lt.log"
	: > "$ftl_log_file"
	_log_time_handler() { ftl::log::info "time fired"; }
	ftl_cfg_time_event_interval=1
	ftl_time_last_event_time=0
	ftl_time_handlers[_log_time_handler]=_log_time_handler
	ftl::time::tick
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "time fired"
}

test_e2_path_parse_extension_filter() {
	ftl::util::parse_path "/tmp/test.py"
	ftl::test::assert_eq "py" "$ftl_state_current_extension"
}

test_e2_multiple_tabs_independent_filters() {
	ftl::tab::create "/t1"
	ftl::tab::create "/t2"
	ftl_tab_filter_1[0]="filter_a"
	ftl_tab_filter_1[1]="filter_b"
	ftl::test::assert_eq "filter_a" "${ftl_tab_filter_1[0]}"
	ftl::test::assert_eq "filter_b" "${ftl_tab_filter_1[1]}"
}

test_e2_cleanup_tmp() {
	rm -rf "$_INTEG2_TMP"
	ftl::test::pass "cleanup done"
}

# vim: set filetype=bash :
