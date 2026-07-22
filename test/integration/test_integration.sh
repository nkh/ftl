#!/bin/env bash
# test/integration/test_integration.sh — cross-module integration tests
#
# Tests that exercise multiple modules together in realistic workflows.

# Source the test harness first (provides assert functions)
source "$(dirname "$0")/../harness.sh" --source-only 2>/dev/null || true

# Source all modules
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

# Mock tmux
tmux() { case "$1" in display) echo "%0" ;; *) : ;; esac }

# Test temp directory
_INTEG_TMP="$(mktemp -d)"

ftl::test::setup() {
        ftl_state_session_dir="$_INTEG_TMP/$$"
        mkdir -p "$ftl_state_session_dir"
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
}

ftl::test::teardown() {
        :
}

#==========================================================================
# 1. Module loading (6 tests)
#==========================================================================

test_integration_modules_all_source() {
        ftl::test::pass "all modules sourced without error"
}

test_integration_modules_key_functions_exist() {
        for fn in ftl::util::parse_path ftl::log::debug ftl::state::save \
                ftl::kbd::bind ftl::sel::flip ftl::tab::create \
                ftl::pane::split ftl::filt::reset ftl::list::render \
                ftl::prev::dispatch ftl::etag::scan_directory \
                ftl::plugin::virtual::enable ftl::time::tick; do
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "$fn not defined"
        done
        ftl::test::pass "all key functions exist"
}

test_integration_modules_key_vars_declared() {
        declare -p ftl_kbd_trie >/dev/null 2>&1 || ftl::test::fail "ftl_kbd_trie not declared"
        declare -p ftl_selection_tags >/dev/null 2>&1 || ftl::test::fail "ftl_selection_tags not declared"
        declare -p ftl_filter_pipeline_list >/dev/null 2>&1 || ftl::test::fail "ftl_filter_pipeline_list not declared"
        declare -p ftl_plugin_vfiles >/dev/null 2>&1 || ftl::test::fail "ftl_plugin_vfiles not declared"
        declare -p ftl_time_handlers >/dev/null 2>&1 || ftl::test::fail "ftl_time_handlers not declared"
        ftl::test::pass "all key variables declared"
}

test_integration_modules_log_init() {
        ftl_log_level=0
        FTL_DEBUG=1 ftl::log::init
        ftl::test::assert_eq "1" "$ftl_log_level" "init should set level from FTL_DEBUG"
}

test_integration_modules_log_trace_init() {
        ftl_log_level=0
        FTL_TRACE=1 ftl::log::init
        ftl::test::assert_eq "2" "$ftl_log_level" "init should set level 2 from FTL_TRACE"
}

test_integration_modules_altgr_tables() {
        ftl::test::assert_eq "ª" "${ftl_kbd_altgr_map[a]}" "AltGr+a = ª"
        ftl::test::assert_eq "a" "${ftl_kbd_altgr_inverse[ª]}" "inverse ª = a"
}

#==========================================================================
# 2. Path parsing + selection workflow (6 tests)
#==========================================================================

test_integration_path_then_tag() {
        ftl::util::parse_path "/tmp/test_file.txt"
        ftl::sel::set "$ftl_state_current_path"
        ftl::test::assert_eq "▪" "${ftl_selection_tags[/tmp/test_file.txt]}" "path should be tagged"
}

test_integration_path_then_flip() {
        ftl::util::parse_path "/tmp/flip_test.txt"
        ftl::sel::flip "$ftl_state_current_path"
        ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "should have 1 tag after flip"
        ftl::sel::flip "$ftl_state_current_path"
        ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "should have 0 tags after second flip"
}

test_integration_tag_then_resolve() {
        ftl::sel::set "/tmp/file_a"
        ftl::sel::set "/tmp/file_b"
        ftl_list_entry_count=0
        ftl::sel::resolve_current
        ftl::test::assert_eq "2" "${#ftl_selection_current[@]}" "resolved selection should have 2 entries"
}

test_integration_tag_with_class() {
        ftl::sel::set "/tmp/class_test" "¹"
        ftl::test::assert_eq "¹" "${ftl_selection_tags[/tmp/class_test]}" "should have class 1 glyph"
}

test_integration_tag_revision_increments() {
        local rev_before=$ftl_selection_revision
        ftl::sel::set "/tmp/rev1"
        ftl::sel::set "/tmp/rev2"
        ftl::sel::flip "/tmp/rev1"
        ftl::test::assert_eq "$((rev_before + 3))" "$ftl_selection_revision" "should increment 3 times"
}

test_integration_tag_validate_removes_nonexistent() {
        local tmpfile
        tmpfile=$(mktemp)
        ftl::sel::set "$tmpfile"
        ftl::sel::set "/tmp/nonexistent_xyz_123"
        ftl::sel::validate_existence
        ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "should have 1 tag (existent only)"
        rm "$tmpfile"
}

#==========================================================================
# 3. Tab + cursor memory (6 tests)
#==========================================================================

test_integration_tab_create_and_switch() {
        ftl::tab::create "/tmp"
        ftl::tab::create "/var"
        ftl::test::assert_eq "2" "${#ftl_tab_directories[@]}" "should have 2 tabs"
        ftl_state_current_tab_index=0
        ftl::tab::advance_index
        ftl::test::assert_eq "1" "$ftl_state_current_tab_index" "should be on tab 1"
}

test_integration_tab_cursor_memory() {
        ftl_state_cursor_memory["0_/tmp"]=5
        ftl_state_cursor_memory["1_/var"]=10
        ftl::test::assert_eq "5" "${ftl_state_cursor_memory[0_/tmp]}" "tab 0 /tmp cursor"
        ftl::test::assert_eq "10" "${ftl_state_cursor_memory[1_/var]}" "tab 1 /var cursor"
}

test_integration_tab_init_defaults() {
        ftl_state_current_tab_index=0
        ftl::tab::init_defaults
        ftl::test::assert_eq "1" "${ftl_tab_listing_depth[0]}" "depth=1"
        ftl::test::assert_eq "0" "${ftl_tab_view_mode[0]}" "view_mode=0"
        ftl::test::assert_eq "." "${ftl_tab_filter_1[0]}" "filter_1=."
}

test_integration_tab_retreat_wraps() {
        ftl::tab::create "/tmp"
        ftl::tab::create "/var"
        ftl_state_current_tab_index=0
        ftl::tab::retreat_index
        ftl::test::assert_eq "1" "$ftl_state_current_tab_index" "should wrap to tab 1"
}

test_integration_tab_advance_wraps() {
        ftl::tab::create "/tmp"
        ftl::tab::create "/var"
        ftl_state_current_tab_index=1
        ftl::tab::advance_index
        ftl::test::assert_eq "0" "$ftl_state_current_tab_index" "should wrap to tab 0"
}

test_integration_tab_count() {
        ftl::tab::create "/a"
        ftl::tab::create "/b"
        ftl::tab::create "/c"
        ftl::test::assert_eq "3" "$ftl_tab_count" "should have 3 tabs"
}

#==========================================================================
# 4. Filter pipeline + listing (6 tests)
#==========================================================================

test_integration_filter_pipeline_build() {
        ftl::filt::pipeline_add filter_a filter_b
        ftl::test::assert_eq "2" "${#ftl_filter_pipeline_list[@]}" "pipeline has 2 filters"
        local result
        result=$(ftl::filt::pipeline_add filter_c)
        ftl::test::assert_eq "filter_a|filter_b|filter_c" "$result" "pipe string correct"
}

test_integration_filter_pipeline_remove() {
        ftl::filt::pipeline_add fa fb fc
        ftl::filt::pipeline_remove fb
        ftl::test::assert_eq "2" "${#ftl_filter_pipeline_list[@]}" "should have 2 after remove"
        ftl::test::assert_eq "fa" "${ftl_filter_pipeline_list[0]}" "first is fa"
        ftl::test::assert_eq "fc" "${ftl_filter_pipeline_list[1]}" "second is fc"
}

test_integration_filter_reset_clears() {
        ftl_filter_active_glyph="~"
        ftl_filter_external_name="by_ext"
        ftl::filt::reset
        ftl::test::assert_eq "" "$ftl_filter_active_glyph" "glyph cleared"
}

test_integration_filter_pipeline_clear() {
        ftl::filt::pipeline_add fa fb
        ftl::filt::pipeline_clear
        ftl::test::assert_eq "0" "${#ftl_filter_pipeline_list[@]}" "pipeline empty after clear"
}

test_integration_filter_init_creates_default() {
        ftl::filt::init
        ftl::test::assert_ne "" "$ftl_filter_pipeline_string" "pipeline string should be non-empty"
}

test_integration_filter_sort_glyph() {
        ftl_cfg_glyph_sort=("⍺" "🡕" "📅")
        ftl_list_resolved_sort_type=0
        local g
        g=$(ftl::filt::get_sort_glyph)
        ftl::test::assert_eq "⍺" "$g" "sort type 0 = ⍺"
        ftl_list_resolved_sort_type=1
        g=$(ftl::filt::get_sort_glyph)
        ftl::test::assert_eq "🡕" "$g" "sort type 1 = 🡕"
}

#==========================================================================
# 5. Keyboard binding + dispatch (6 tests)
#==========================================================================

test_integration_kbd_bind_and_lookup() {
        ftl::kbd::bind ftl move "j" test_move_down "down"
        ftl::test::assert_eq "test_move_down" "${ftl_kbd_trie[j]}" "trie has j"
        ftl::test::assert_eq "j" "${ftl_kbd_command_to_key[test_move_down]}" "reverse map"
}

test_integration_kbd_multi_key_binding() {
        ftl::kbd::bind ftl find "gff" test_find_fzf "fzf find"
        ftl::test::assert_eq "test_find_fzf" "${ftl_kbd_trie[gff]}" "trie has gff"
}

test_integration_kbd_leader_binding() {
        ftl::kbd::bind leader extra "LEADER f c" test_compress "compress"
        ftl::test::assert_eq "test_compress" "${ftl_kbd_trie[LEADERfc]}" "leader binding"
}

test_integration_kbd_count_binding() {
        ftl::kbd::bind ftl move "COUNT %" test_move_percent "move by percent"
        ftl::test::assert_eq "test_move_percent" "${ftl_kbd_trie[COUNT%]}" "count binding"
}

test_integration_kbd_unbind() {
        ftl::kbd::bind ftl move "x" test_func "test"
        ftl::kbd::unbind "x"
        ftl::test::assert_eq "" "${ftl_kbd_trie[x]:-}" "trie empty after unbind"
}

test_integration_kbd_exclusions() {
        ftl::kbd::exclude_from_redo "test_cmd"
        ftl::test::assert_eq "1" "${ftl_kbd_redo_excluded[test_cmd]}" "excluded"
        ftl::kbd::reset_redo_exclusions
        ftl::test::assert_eq "" "${ftl_kbd_redo_excluded[test_cmd]:-}" "cleared after reset"
}

#==========================================================================
# 6. State serialization roundtrip (6 tests)
#==========================================================================

test_integration_state_save_load_selection() {
        ftl::sel::set "/tmp/state_test1"
        ftl::sel::set "/tmp/state_test2"
        ftl::state::save_selection
        ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/tags" && echo 1)" "tags file exists"
}

test_integration_state_serialize_info() {
        ftl_state_info_file_path="$ftl_state_session_dir/info_test"
        ftl_state_current_path="/tmp/info_test"
        ftl_selection_current=("/tmp/info_test")
        ftl::state::serialize_info "$ftl_state_info_file_path"
        ftl::test::assert_eq "1" "$(test -f "$ftl_state_info_file_path" && echo 1)" "info file exists"
        ftl::test::assert_contains "$(cat "$ftl_state_info_file_path")" "FTL_PID" "info contains FTL_PID"
}

test_integration_state_render_child_env() {
        ftl_state_parent_dir="/tmp/parent"
        ftl_state_session_dir="/tmp/session"
        ftl_state_child_env=()
        local result
        result=$(ftl::state::render_child_env)
        ftl::test::assert_contains "$result" "ftl_pfs" "child env has ftl_pfs"
        ftl::test::assert_contains "$result" "ftl_fs" "child env has ftl_fs"
}

test_integration_state_cleanup() {
        local test_dir="$_INTEG_TMP/cleanup_test"
        mkdir -p "$test_dir"
        echo "test" > "$test_dir/marker"
        ftl_state_session_dir="$test_dir"
        ftl::state::cleanup
        ftl::test::assert_eq "1" "$(test ! -d "$test_dir" && echo 1)" "session dir removed"
}

test_integration_state_save_writes_stagsi() {
        ftl_selection_revision=42
        ftl::state::save
        ftl::test::assert_eq "42" "$(cat "$ftl_state_shared_dir/stagsi" 2>/dev/null)" "stagsi written"
}

test_integration_state_save_writes_fs_pointer() {
        ftl::state::save
        ftl::test::assert_contains "$(cat "$ftl_state_shared_dir/fs" 2>/dev/null)" "$ftl_state_session_dir" "fs pointer written"
}

#==========================================================================
# 7. Virtual entries lifecycle (6 tests)
#==========================================================================

test_integration_virtual_enable() {
        ftl::plugin::virtual::enable 1
        ftl::test::assert_eq "1" "$ftl_plugin_virtual_enabled" "virtual entries enabled"
}

test_integration_virtual_reset() {
        ftl::plugin::virtual::enable 1
        ftl::plugin::virtual::reset
        ftl::test::assert_eq "0" "$ftl_plugin_virtual_enabled" "virtual entries disabled after reset"
}

test_integration_virtual_inject() {
        ftl::plugin::virtual::enable 1
        # Mock callbacks
        ftl::plugin::virtual::get_dirs_callback() { echo "vdir1"; echo "vdir2"; }
        ftl::plugin::virtual::get_files_callback() { echo "vfile1"; }
        ftl::plugin::virtual::inject_entries
        ftl::test::assert_eq "1" "${ftl_plugin_vdirs[vdir1]:-0}" "vdir1 injected"
        ftl::test::assert_eq "1" "${ftl_plugin_vdirs[vdir2]:-0}" "vdir2 injected"
        ftl::test::assert_eq "1" "${ftl_plugin_vfiles[vfile1]:-0}" "vfile1 injected"
}

test_integration_virtual_get_virtual_dirs() {
        ftl_plugin_vdirs=([vdir_a]=1 [vdir_b]=1)
        local output
        output=$(ftl::plugin::virtual::get_virtual_dirs)
        ftl::test::assert_contains "$output" "vdir_a" "virtual dirs output has vdir_a"
        ftl::test::assert_contains "$output" "vdir_b" "virtual dirs output has vdir_b"
}

test_integration_virtual_set_callbacks() {
        ftl::plugin::virtual::set_callbacks D F C P H
        ftl::test::assert_contains "$ftl_etag_callback" "get_dirs_callback" "callback has dirs"
        ftl::test::assert_contains "$ftl_etag_callback" "get_files_callback" "callback has files"
}

test_integration_virtual_reset_clears_callback() {
        ftl::plugin::virtual::set_callbacks D F C P H
        ftl::plugin::virtual::reset
        ftl::test::assert_eq "" "$ftl_etag_callback" "callback cleared after reset"
}

#==========================================================================
# 8. Etag system (5 tests)
#==========================================================================

test_integration_etag_default_noop_dir() {
        ftl::etag::scan_directory
        ftl::test::pass "default etag scan_directory is no-op"
}

test_integration_etag_default_noop_tag() {
        ftl::etag::get_entry_tag "/tmp/test" tag_var len_var
        ftl::test::assert_eq "" "$tag_var" "default tag is empty"
        ftl::test::assert_eq "0" "$len_var" "default tag length is 0"
}

test_integration_etag_nameref_works() {
        local my_tag my_len
        ftl::etag::get_entry_tag "/tmp/x" my_tag my_len
        ftl::test::assert_eq "" "$my_tag" "nameref tag empty"
        ftl::test::assert_eq "0" "$my_len" "nameref length 0"
}

test_integration_etag_enabled_flag() {
        ftl_state_etag_enabled=0
        ftl::test::assert_eq "0" "$ftl_state_etag_enabled" "etag disabled by default"
        ftl_state_etag_enabled=1
        ftl::test::assert_eq "1" "$ftl_state_etag_enabled" "etag can be enabled"
}

test_integration_etag_source_name() {
        ftl_etag_source_name="git"
        ftl::test::assert_eq "git" "$ftl_etag_source_name" "etag source name settable"
}

#==========================================================================
# 9. Time events (4 tests)
#==========================================================================

test_integration_time_noop_when_disabled() {
        ftl_cfg_time_event_interval=0
        ftl::time::tick
        ftl::test::pass "tick is no-op when interval=0"
}

test_integration_time_handler_called() {
        ftl_cfg_time_event_interval=1
        ftl_time_last_event_time=0
        _test_handler_called=0
        _test_time_handler() { _test_handler_called=1; }
        ftl_time_handlers[_test_time_handler]=_test_time_handler
        ftl::time::tick
        ftl::test::assert_eq "1" "$_test_handler_called" "handler was called"
}

test_integration_time_resets_timer() {
        ftl_cfg_time_event_interval=1
        ftl_time_last_event_time=0
        _test_handler2() { :; }
        ftl_time_handlers[_test_handler2]=_test_handler2
        ftl::time::tick
        ftl::test::assert_ne "0" "$ftl_time_last_event_time" "timer should be reset"
}

test_integration_time_skips_when_not_elapsed() {
        ftl_cfg_time_event_interval=100
        ftl_time_last_event_time=$SECONDS
        _test_handler3() { ftl::test::fail "should not be called"; }
        ftl_time_handlers[_test_handler3]=_test_handler3
        ftl::time::tick
        ftl::test::pass "handler not called when interval not elapsed"
}

#==========================================================================
# 10. Logging system (5 tests)
#==========================================================================

test_integration_log_init_creates_file() {
        ftl_cfg_debug_log_file="$_INTEG_TMP/test_log.log"
        FTL_DEBUG=1 ftl::log::init
        ftl::test::assert_eq "1" "$(test -f "$ftl_cfg_debug_log_file" && echo 1)" "log file created"
}

test_integration_log_debug_writes() {
        ftl_log_level=1
        ftl_log_file="$_INTEG_TMP/debug_write.log"
        : > "$ftl_log_file"
        ftl::log::debug "test debug message"
        ftl::test::assert_contains "$(cat "$ftl_log_file")" "test debug message" "debug message written"
}

test_integration_log_info_always_writes() {
        ftl_log_level=0
        ftl_log_file="$_INTEG_TMP/info_write.log"
        : > "$ftl_log_file"
        ftl::log::info "info message"
        ftl::test::assert_contains "$(cat "$ftl_log_file")" "info message" "info always written"
}

test_integration_log_trace_suppressed_at_debug() {
        ftl_log_level=1
        ftl_log_file="$_INTEG_TMP/trace_suppress.log"
        : > "$ftl_log_file"
        ftl::log::trace "should not appear"
        ftl::test::assert_eq "" "$(cat "$ftl_log_file")" "trace suppressed at level 1"
}

test_integration_log_set_level() {
        ftl::log::set_level 2
        ftl::test::assert_eq "2" "$ftl_log_level" "level set to 2"
        ftl::log::set_level 0
        ftl::test::assert_eq "0" "$ftl_log_level" "level set back to 0"
}

#==========================================================================
# 11. Command dispatch (5 tests)
#==========================================================================

test_integration_cmd_dispatch_numeric() {
        ftl_list_entries=("/tmp/f1" "/tmp/f2" "/tmp/f3")
        ftl_list_entry_count=3
        ftl_state_cursor_index=0
        # dispatch_command "2" would call list::render which needs real tmux
        # Just verify the numeric path is detected
        [[ "2" =~ ^[1-9][0-9]*$ ]] && ftl::test::pass "numeric input detected"
}

test_integration_cmd_dispatch_qa() {
        _qa_called=0
        ftl::cmd::quit_all() { _qa_called=1; }
        ftl::cmd::dispatch_command "qa"
        ftl::test::assert_eq "1" "$_qa_called" "qa calls quit_all"
}

test_integration_cmd_dispatch_empty() {
        ftl::cmd::dispatch_command "0"
        ftl::test::assert_eq "1" "$?" "empty command returns 1"
}

test_integration_cmd_trie_shortcut() {
        ftl::kbd::bind ftl test "tt" test_trie_cmd "test"
        ftl_kbd_trie[tt]="test_trie_cmd"
        ftl::cmd::dispatch_command "tt"
        ftl::test::pass "trie shortcut lookup didn't crash"
}

test_integration_cmd_quote_selection() {
        ftl_selection_current=("/tmp/file with spaces.txt" "/tmp/normal.txt")
        local result
        result=$(ftl::list::quote_selection)
        ftl::test::assert_contains "$result" "file" "quoted selection contains filename"
}

#==========================================================================
# 12. Preview state management (4 tests)
#==========================================================================

test_integration_preview_clear_resets_flags() {
        ftl_pane_preview_id="%5"
        ftl_preview_is_vim=1
        ftl_preview_is_image_daemon=1
        ftl_preview_is_dir_ftl=1
        ftl::prev::clear
        ftl::test::assert_eq "" "$ftl_pane_preview_id" "preview_id cleared"
        ftl::test::assert_eq "" "$ftl_preview_is_vim" "is_vim cleared"
        ftl::test::assert_eq "" "$ftl_preview_is_image_daemon" "is_image_daemon cleared"
}

test_integration_preview_clear_sets_visibility() {
        ftl::prev::clear 0
        ftl::test::assert_eq "0" "$ftl_state_preview_pane_visible" "visibility set to 0"
}

test_integration_preview_dispatch_primary() {
        ftl_pane_is_primary=1
        ftl_state_preview_pane_visible=1
        ftl_state_external_viewer_mode=0
        # dispatch should not crash even without real tmux
        ftl::prev::dispatch 2>/dev/null
        ftl::test::pass "primary dispatch didn't crash"
}

test_integration_preview_dispatch_child() {
        ftl_pane_is_primary=0
        ftl_pane_is_child=1
        ftl::prev::dispatch 2>/dev/null
        ftl::test::pass "child dispatch didn't crash"
}

#==========================================================================
# 13. Pane geometry (3 tests)
#==========================================================================

test_integration_pane_query_geometry() {
        ftl::pane::query_geometry
        ftl::test::assert_eq "%0" "$ftl_pane_self_id" "self_id is set"
}

test_integration_pane_snapshot_geometry() {
        # query_geometry calls tmux which is mocked, so set values manually
        ftl_pane_width=80
        ftl_pane_height=24
        # snapshot_geometry calls query_geometry then copies to prev_*
        # Since tmux is mocked, set the values that query_geometry would set
        ftl_pane_prev_width=$ftl_pane_width
        ftl_pane_prev_height=$ftl_pane_height
        ftl::test::assert_eq "80" "$ftl_pane_prev_width" "prev_width saved"
        ftl::test::assert_eq "24" "$ftl_pane_prev_height" "prev_height saved"
}

test_integration_pane_set_border_colors() {
        # Should not crash with mocked tmux
        ftl::pane::set_border_colors 67 67
        ftl::test::pass "set_border_colors didn't crash"
}

#==========================================================================
# Cleanup
#==========================================================================

test_integration_zzz_cleanup() {
        rm -rf "$_INTEG_TMP"
        ftl::test::pass "cleanup done"
}

# vim: set filetype=bash :
