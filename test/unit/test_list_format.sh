#!/bin/env bash
# test/unit/test_list_format.sh — tests for _ftl::list::apply_filters_and_format
#
# Tests that the entry formatting pipeline produces correct output for
# various file types, sizes, etags, and filter conditions.

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

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

ftl::test::setup() {
        ftl_state_session_dir=$(mktemp -d)
        ftl_state_current_tab_index=0
        ftl_state_cursor_index=0
        ftl_state_current_path=
        ftl_state_current_dir=
        ftl_state_current_basename=
        ftl_state_current_extension=
        ftl_state_search_string=
        ftl_state_etag_enabled=0
        ftl_state_show_size_mode=0
        ftl_state_show_stat=0
        ftl_state_montage_glyph=
        ftl_pane_height=24
        ftl_pane_width=80
        ftl_pane_preview_id=
        ftl_pane_is_child=0
        ftl_list_path_separator=/
        ftl_list_resolved_sort_type=0
        ftl_list_resolved_sort_reversed=
        ftl_list_flip_index=0
        ftl_list_current_flip_char=" "
        ftl_list_quick_display_active=0
        ftl_cfg_quick_display_threshold=0
        ftl_cfg_show_entry_index=0
        ftl_cfg_row_separator_chars=(' ' ' ')
        ftl_cfg_line_color_default="\e[0m"
        ftl_cfg_cursor_color_default="\e[7m"
        ftl_filter_active_glyph=
        ftl_filter_external_name=
        declare -ag ftl_list_raw_entries=()
        declare -ag ftl_list_raw_colors=()
        declare -ag ftl_list_raw_names=()
        declare -ag ftl_list_raw_paths=()
        declare -ag ftl_list_raw_sizes=()
        declare -ag ftl_list_raw_relpath_len=()
        declare -Ag ftl_filter_listing_hide_exts=()
        declare -Ag ftl_filter_listing_keep_exts=()
        declare -Ag ftl_filter_listing_keep_exts_per_tab=()
        declare -Ag ftl_tab_view_mode=([0]=0)
        declare -Ag ftl_tab_listing_mode=([0]=0)
        declare -Ag ftl_tab_preview_dirs_only=([0]=)
        declare -Ag ftl_selection_tags=()
        declare -Ag ftl_state_cursor_memory=()
        ftl_tab_count=1
}

ftl::test::teardown() {
        rm -rf "$ftl_state_session_dir" 2>/dev/null
}

# Helper: set up raw entries from a temp directory
# Args: filenames (relative to temp dir)
setup_raw_entries() {
        local testdir
        testdir=$(mktemp -d)
        ftl_state_session_dir="$testdir"
        cd "$testdir"

        local f
        local idx=0
        for f in "$@" ; do
                touch "$testdir/$f"
                # Raw entries: indexed array, index → name
                ftl_list_raw_entries[$idx]="$f"
                ftl_list_raw_colors[$idx]="$f"
                ftl_list_raw_names[$idx]="$f"
                ftl_list_raw_paths[$idx]="$testdir"
                ftl_list_raw_relpath_len[$idx]=0
                ftl_list_raw_sizes[$idx]=100
                ((idx++))
        done
}

# Test: basic formatting — entries are populated
test_format_basic_entries() {
        setup_raw_entries "file1.txt" "file2.py" "dir1"
        _ftl::list::apply_filters_and_format

        ftl::test::assert_eq "3" "$ftl_list_entry_count" "should have 3 entries"
        ftl::test::assert_eq "$ftl_state_session_dir/file1.txt" "${ftl_list_entries[0]}" "entry 0 path"
        ftl::test::assert_eq "$ftl_state_session_dir/file2.py" "${ftl_list_entries[1]}" "entry 1 path"
        ftl::test::assert_eq "$ftl_state_session_dir/dir1" "${ftl_list_entries[2]}" "entry 2 path"
}

# Test: total size is accumulated
test_format_total_size() {
        setup_raw_entries "a.txt" "b.txt" "c.txt"
        _ftl::list::apply_filters_and_format

        ftl::test::assert_eq "300" "$ftl_list_total_size" "total size should be 300 (3×100)"
}

# Test: first file index is tracked
test_format_first_file_index() {
        mkdir -p "$(dirname "$ftl_state_session_dir")/d1" 2>/dev/null; setup_raw_entries "dir1" "dir2" "file1.txt"
        _ftl::list::apply_filters_and_format

        ftl::test::assert_eq "0" "$ftl_list_first_file_index" "first file at index 0 (all are files in test)"
}

# Test: search string matching
test_format_search_match() {
        setup_raw_entries "apple.txt" "banana.txt" "cherry.txt"
        ftl_state_search_string="ban"
        _ftl::list::apply_filters_and_format

        ftl::test::assert_eq "1" "$ftl_list_search_found_index" "search should find 'banana' at index 1"
}

# Test: extension hide filter
test_format_hide_extension() {
        setup_raw_entries "a.txt" "b.py" "c.txt"
        e="txt"; ftl_filter_listing_hide_exts[${e@Q}]=1
        _ftl::list::apply_filters_and_format

        ftl::test::assert_eq "1" "$ftl_list_entry_count" "should have 1 entry (b.py only)"
        ftl::test::assert_contains "${ftl_list_entries[0]}" "b.py" "remaining entry should be b.py"
}

# Test: extension keep filter
test_format_keep_extension() {
        setup_raw_entries "a.txt" "b.py" "c.txt"
        local e="py"
        ftl_filter_listing_keep_exts[${e@Q}]=1
        _ftl::list::apply_filters_and_format

        ftl::test::assert_eq "1" "$ftl_list_entry_count" "should have 1 entry (b.py only)"
        [[ ${#ftl_list_entries[@]} -gt 0 ]] \
                && ftl::test::assert_contains "${ftl_list_entries[0]}" "b.py" "kept entry should be b.py" \
                || ftl::test::fail "no entries after keep filter"
}

# Test: entry colors are populated
test_format_entry_colors() {
        setup_raw_entries "a.txt" "b.txt"
        _ftl::list::apply_filters_and_format

        ftl::test::assert_eq "2" "${#ftl_list_entry_colors[@]}" "should have 2 color entries"
        [[ -n "${ftl_list_entry_colors[0]}" ]] \
                && ftl::test::pass "entry 0 has color" \
                || ftl::test::fail "entry 0 has no color"
}

# Test: index padding is computed
test_format_index_padding() {
        setup_raw_entries a b c d e f g h i j
        _ftl::list::apply_filters_and_format

        # 10 entries → padding = 2 (length of "10")
        ftl::test::assert_eq "2" "$ftl_list_index_padding" "padding for 10 entries should be 2"
}

# Test: empty directory
test_format_empty_directory() {
        setup_raw_entries
        _ftl::list::apply_filters_and_format

        ftl::test::assert_eq "0" "$ftl_list_entry_count" "empty dir should have 0 entries"
}

# Test: entry colors contain the filename
test_format_color_contains_name() {
        setup_raw_entries "myfile.txt"
        _ftl::list::apply_filters_and_format

        ftl::test::assert_contains "${ftl_list_entry_colors[0]}" "myfile.txt" \
                "color string should contain the filename"
}

# vim: set filetype=bash :
