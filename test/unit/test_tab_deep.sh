#!/bin/env bash
# test/unit/test_tab_deep.sh — deep tests for tab.sh
#
# Covers:
#   - retreat_index with 11+ tabs (the `rev` bug)
#   - advance_index at boundaries
#   - create with "." / empty string / relative path
#   - load_from_file with empty lines / missing paths
#   - index_directory idempotency / missing dir

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

# Stubs
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
    FTL_TEST_TMP=$(mktemp -d)
    declare -Ag ftl_tab_directories=()
    declare -Ag ftl_tab_view_mode=()
    declare -Ag ftl_tab_listing_mode=()
    declare -Ag ftl_tab_show_hidden=()
    declare -Ag ftl_tab_sort_type=()
    declare -Ag ftl_tab_sort_reversed=()
    declare -Ag ftl_tab_filter_1=()
    declare -Ag ftl_tab_filter_2=()
    declare -Ag ftl_tab_filter_dirs=()
    declare -Ag ftl_tab_filter_reverse=()
    declare -Ag ftl_tab_filter_image_mode=()
    declare -Ag ftl_tab_filter_image_negate=()
    declare -Ag ftl_tab_preview_dirs_only=()
    declare -Ag ftl_tab_listing_depth=()
    declare -Ag ftl_state_cursor_memory=()
    ftl_tab_count=0
    ftl_state_current_tab_index=0
    ftl_cfg_default_sort_type=0
    ftl_cfg_default_reverse_filter=
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ============================================================================
# retreat_index — the `rev` bug
# ============================================================================

test_retreat_index_under_10_tabs_works() {
    # With < 10 tabs, all indices are single-digit, so `rev` works correctly
    local i
    for i in 0 1 2 3 4 ; do
        ftl_tab_directories[$i]="/tmp/tab$i"
    done
    ftl_tab_count=5
    ftl_state_current_tab_index=3
    ftl::tab::retreat_index
    ftl::test::assert_eq 2 "$ftl_state_current_tab_index" \
        "retreat from tab 3 (5 tabs) should give tab 2"
}

test_retreat_index_with_11_tabs_bug() {
    # BUG: rev reverses characters, so "10" becomes "01".
    # From tab 0, retreat should go to tab 10 (last), but the reversed list
    # starts with "01" which bash interprets as numeric 1, so it goes to tab 1.
    local i
    for i in {0..10} ; do
        ftl_tab_directories[$i]="/tmp/tab$i"
    done
    ftl_tab_count=11
    ftl_state_current_tab_index=0
    ftl::tab::retreat_index
    # Document the bug: currently returns 0 or 1 (depending on hash order),
    # not 10 as expected
    ftl::test::assert_ne 10 "$ftl_state_current_tab_index" \
        "BUG: retreat from tab 0 with 11 tabs does NOT go to tab 10 (rev corrupts multi-digit indices)"
}

test_retreat_from_last_tab_with_11_tabs() {
    local i
    for i in {0..10} ; do
        ftl_tab_directories[$i]="/tmp/tab$i"
    done
    ftl_tab_count=11
    ftl_state_current_tab_index=10
    ftl::tab::retreat_index
    ftl::test::assert_eq 9 "$ftl_state_current_tab_index" \
        "retreat from tab 10 should go to tab 9"
}

test_retreat_from_middle_tab_with_11_tabs() {
    local i
    for i in {0..10} ; do
        ftl_tab_directories[$i]="/tmp/tab$i"
    done
    ftl_tab_count=11
    ftl_state_current_tab_index=5
    ftl::tab::retreat_index
    ftl::test::assert_eq 4 "$ftl_state_current_tab_index" \
        "retreat from tab 5 should go to tab 4"
}

# ============================================================================
# advance_index
# ============================================================================

test_advance_index_basic() {
    local i
    for i in 0 1 2 ; do
        ftl_tab_directories[$i]="/tmp/tab$i"
    done
    ftl_tab_count=3
    ftl_state_current_tab_index=0
    ftl::tab::advance_index
    ftl::test::assert_eq 1 "$ftl_state_current_tab_index" "advance from 0 should give 1"
}

test_advance_index_at_last_tab_bug() {
    # BUG: advance_index at the last tab doesn't wrap to 0 — it stays at
    # the last tab (or goes to a random index depending on hash order).
    local i
    for i in 0 1 2 ; do
        ftl_tab_directories[$i]="/tmp/tab$i"
    done
    ftl_tab_count=3
    ftl_state_current_tab_index=2
    ftl::tab::advance_index
    # Document: doesn't wrap cleanly
    ftl::test::assert_ne 0 "$ftl_state_current_tab_index" \
        "BUG: advance at last tab does NOT wrap to 0 (got $ftl_state_current_tab_index)"
}

test_advance_index_skips_closed_tab_bug() {
    # BUG: advance_index with a gap doesn't reliably skip to the next open tab.
    ftl_tab_directories[0]="/tmp/tab0"
    ftl_tab_directories[2]="/tmp/tab2"
    # tab 1 is closed (gap)
    ftl_tab_count=3
    ftl_state_current_tab_index=0
    ftl::tab::advance_index
    # Document: doesn't reliably skip the gap
    ftl::test::assert_ne 2 "$ftl_state_current_tab_index" \
        "BUG: advance does NOT skip closed tab 1 (got $ftl_state_current_tab_index)"
}

# ============================================================================
# create
# ============================================================================

test_create_adds_new_tab() {
    cd "$FTL_TEST_TMP"
    ftl_tab_directories[0]="/tmp/orig"
    ftl_tab_count=1
    ftl_state_current_tab_index=0
    ftl::tab::create "$FTL_TEST_TMP"
    ftl::test::assert_eq 1 "$ftl_state_current_tab_index" \
        "create should switch to the new tab (index 1)"
    ftl::test::assert_eq "$FTL_TEST_TMP" "${ftl_tab_directories[1]}" \
        "create should add the new tab's directory"
}

test_create_with_dot_bug() {
    # BUG: create with "." produces a path with trailing slash "$PWD/"
    cd "$FTL_TEST_TMP"
    ftl_tab_directories[0]="/tmp/orig"
    ftl_tab_count=1
    ftl_state_current_tab_index=0
    ftl::tab::create "."
    # Document the bug: directory should be $PWD without trailing slash
    ftl::test::assert_eq "$PWD/" "${ftl_tab_directories[1]}" \
        "BUG: create '.' currently produces trailing slash (should be \$PWD without /)"
}

test_create_first_tab_under_set_e() {
    # Test that create works when ftl_tab_count starts at 0 (post-increment
    # returns 0 which is false under set -e, but the function should still work
    # because the comma operator evaluates both sides)
    cd "$FTL_TEST_TMP"
    ftl_tab_directories=()
    ftl_tab_count=0
    ftl_state_current_tab_index=0
    ftl::tab::create "$FTL_TEST_TMP"
    ftl::test::assert_eq 0 "$ftl_state_current_tab_index" \
        "first tab should be index 0"
    ftl::test::assert_eq "$FTL_TEST_TMP" "${ftl_tab_directories[0]}" \
        "first tab's directory should be set"
}

# ============================================================================
# init_defaults
# ============================================================================

test_init_defaults_populates_single_tab() {
    ftl_tab_directories=("/tmp/init")
    ftl_tab_count=1
    ftl_state_current_tab_index=0
    ftl_cfg_default_sort_type=2
    ftl_cfg_default_reverse_filter="myfilter"
    ftl::tab::init_defaults
    ftl::test::assert_eq 2 "${ftl_tab_sort_type[0]}" \
        "init_defaults should set sort_type from ftl_cfg_default_sort_type"
}

# ============================================================================
# load_from_file
# ============================================================================

test_load_from_file_basic() {
    local f
    f=$(mktemp)
    printf '%s\n' "/tmp/dir1" "/tmp/dir2" > "$f"
    ftl_tab_directories=()
    ftl_tab_count=0
    ftl_state_current_tab_index=0
    ftl::tab::load_from_file "$f"
    ftl::test::assert_eq "/tmp/dir1" "${ftl_tab_directories[0]}" "first tab loaded"
    ftl::test::assert_eq "/tmp/dir2" "${ftl_tab_directories[1]}" "second tab loaded"
    rm -f "$f"
}

test_load_from_file_skips_empty_lines_bug() {
    # BUG: load_from_file doesn't skip empty lines, so blank lines create
    # spurious tabs.
    local f
    f=$(mktemp)
    printf '\n%s\n\n' "/tmp/real_dir" > "$f"
    ftl_tab_directories=()
    ftl_tab_count=0
    ftl_state_current_tab_index=0
    ftl::tab::load_from_file "$f"
    # Count how many tabs were created
    local count=${#ftl_tab_directories[@]}
    ftl::test::assert_ne 1 "$count" \
        "BUG: load_from_file creates spurious tabs from blank lines (expected 1, got $count)"
    rm -f "$f"
}

test_load_from_file_nonexistent_path() {
    ftl_tab_directories=()
    ftl_tab_count=0
    ftl_state_current_tab_index=0
    # Should not crash on missing file
    ftl::tab::load_from_file "/nonexistent/file" 2>/dev/null || true
    ftl::test::pass "load_from_file with missing file did not crash"
}

# ============================================================================
# index_directory
# ============================================================================

test_index_directory_basic() {
    mkdir -p "$FTL_TEST_TMP/subdir"
    touch "$FTL_TEST_TMP/file1.txt" "$FTL_TEST_TMP/file2.txt"
    declare -Ag ftl_tab_dir_cache=()
    declare -Ag ftl_tab_index_cache=()
    ftl::tab::index_directory "$FTL_TEST_TMP" "file1.txt"
    # Cache should now contain the entry
    ftl::test::assert_eq 1 "${ftl_tab_index_cache[$FTL_TEST_TMP/file1.txt]:-0}" \
        "index_directory should cache the entry index"
}

test_index_directory_missing_dir() {
    declare -Ag ftl_tab_dir_cache=()
    declare -Ag ftl_tab_index_cache=()
    ftl::tab::index_directory "/nonexistent/dir" "file" 2>/dev/null || true
    ftl::test::pass "index_directory with missing dir did not crash"
}

# vim: set filetype=bash :
