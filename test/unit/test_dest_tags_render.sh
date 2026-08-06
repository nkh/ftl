#!/bin/env bash
# test/unit/test_dest_tags_render.sh — render-side tests for destination tags
#
# Split from test_dest_tags.sh because the main file's other tests stub
# ftl::list::render to a no-op, and the stub persists across tests
# (functions are global in bash). Running the render tests in a separate
# file gives us a clean render implementation.
#
# Backport coverage for upstream commit 38a073a "ADDED: destination tags".

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

# Source all core modules (dest_tags.sh needs list, util, etc.)
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

# Stubs for tmux / preview / pane (but NOT for ftl::list::render — we test it)
tmux() { : ; }
stty() { : ; }
tput() { : ; }
ftl::pane::stop_file_watcher() { : ; }
ftl::pane::start_file_watcher() { : ; }
ftl::pane::query_geometry() { : ; }
ftl::pane::snapshot_geometry() { : ; }
ftl::prev::dispatch() { : ; }
ftl::prev::clear() { : ; }
ftl::state::save() { : ; }
ftl::sel::resolve_current() { : ; }
ftl::sel::sync_from_other_pane() { false ; }
ftl::list::change_dir() { : ; }

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_state_current_path=
    ftl_state_current_tab_index=0
    ftl_state_cursor_index=0
    ftl_pane_height=24
    ftl_pane_width=80
    ftl_pane_is_child=1   # avoid preview dispatch
    ftl_cfg_dtag_move=1
    ftl_cfg_dtag_l=10
    ftl_list_entry_count=0
    ftl_list_entries=()
    declare -Ag ftl_dest_tags=()
    declare -Ag ftl_dest_dir_dest=()
    ftl_dest_last_dest=
    ftl_kbd_count=
    ftl_state_search_string=
    ftl_list_quick_display_active=0
    ftl_list_flip_index=0
    ftl_list_current_flip_char=" "
    ftl_cfg_row_separator_chars=(' ' ' ')
    ftl_cfg_cursor_color_default="\e[7m"
    ftl_list_header_total_count=
    ftl_list_header_total_size=
    ftl_state_show_size_mode=0
    ftl_state_etag_enabled=0
    declare -Ag ftl_state_cursor_memory=()
    declare -Ag ftl_selection_tags=()

    # Stub helpers that need extensive tab/state we don't have
    _ftl::list::render_header() { : ; }
    _ftl::list::clear_below() { : ; }
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# Test: render includes the destination annotation for tagged entries
test_render_includes_dest_annotation() {
    ftl_list_entry_count=1
    ftl_list_entries=( "/work/file1.txt" )
    ftl_list_entry_colors=( "file1.txt" )
    ftl_list_window_top=0
    ftl_list_window_bottom=0
    ftl_list_window_height=1
    ftl_list_window_center=0
    ftl_state_cursor_index=0
    ftl_state_current_path="/work/file1.txt"
    ftl_dest_tags[/work/file1.txt]="/tmp/docs"

    local output
    output=$(ftl::list::render 2>&1) || true

    ftl::test::assert_contains "$output" "[.../tmp/docs" \
        "render should emit the destination annotation for tagged entries"
}

# Test: render does not emit annotation for untagged entries
test_render_no_annotation_for_untagged() {
    ftl_list_entry_count=1
    ftl_list_entries=( "/work/file2.txt" )
    ftl_list_entry_colors=( "file2.txt" )
    ftl_list_window_top=0
    ftl_list_window_bottom=0
    ftl_list_window_height=1
    ftl_list_window_center=0
    ftl_state_cursor_index=0
    ftl_state_current_path="/work/file2.txt"
    # No ftl_dest_tags entry for /work/file2.txt

    local output
    output=$(ftl::list::render 2>&1) || true

    ftl::test::assert_not_contains "$output" "[..." \
        "render should not emit dest annotation for untagged entries"
}

# Test: render emits annotations for multiple tagged entries
test_render_multiple_tagged_entries() {
    ftl_list_entry_count=3
    ftl_list_entries=( "/work/f1" "/work/f2" "/work/f3" )
    ftl_list_entry_colors=( "f1" "f2" "f3" )
    ftl_list_window_top=0
    ftl_list_window_bottom=2
    ftl_list_window_height=3
    ftl_list_window_center=1
    ftl_state_cursor_index=0
    ftl_state_current_path="/work/f1"
    ftl_dest_tags[/work/f1]="/tmp/docs"
    ftl_dest_tags[/work/f3]="/tmp/tests"

    local output
    output=$(ftl::list::render 2>&1) || true

    ftl::test::assert_contains "$output" "[.../tmp/docs" \
        "render should emit annotation for f1"
    ftl::test::assert_contains "$output" "[.../tmp/tests" \
        "render should emit annotation for f3"
    ftl::test::assert_not_contains "$output" "f2]" \
        "render should not emit a trailing ']' for untagged f2"
}

# Test: render emits annotation with long destination path trimmed
test_render_trims_long_dest_path() {
    ftl_cfg_dtag_l=10
    ftl_list_entry_count=1
    ftl_list_entries=( "/work/long.txt" )
    ftl_list_entry_colors=( "long.txt" )
    ftl_list_window_top=0
    ftl_list_window_bottom=0
    ftl_list_window_height=1
    ftl_list_window_center=0
    ftl_state_cursor_index=0
    ftl_state_current_path="/work/long.txt"
    ftl_dest_tags[/work/long.txt]="/a/very/long/path/that/exceeds/the/limit"

    local output
    output=$(ftl::list::render 2>&1) || true

    # The trimmed path should be the last 10 chars: "/the/limit"
    ftl::test::assert_contains "$output" "/the/limit" \
        "render should trim long destination paths to ftl_cfg_dtag_l chars"
    ftl::test::assert_not_contains "$output" "/a/very/long" \
        "render should not include the beginning of a long destination path"
}

# vim: set filetype=bash :
