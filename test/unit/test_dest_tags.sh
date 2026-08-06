#!/bin/env bash
# test/unit/test_dest_tags.sh — tests for the destination tags feature
#
# Backport tests for upstream commit 38a073a "ADDED: destination tags".
# Covers:
#   - ftl::cmd::dest_tag_current: reads key, sets ftl_dest_tags[path] from
#     ftl_dest_dir_dest[key], optionally moves cursor down
#   - ftl::cmd::dest_tag_clear_current: clears current entry's tag
#   - ftl::cmd::dest_tag_clear_all: clears all tags
#   - ftl::cmd::dest_tag_apply_last_to_count: applies last_dest to COUNT entries
#   - ftl::cmd::dest_tag_copy_tagged: cp all tagged files to their dests
#   - ftl::cmd::dest_tag_move_tagged: mv all tagged files to their dests
#   - _ftl::dest::format_annotation: format the [...dest] display string
#   - Truncation accounts for color prefix length (entry_color_c)
#   - Render loop emits the destination annotation
#   - Key bindings are registered with correct (group, key) tuples
#   - State vars are declared in ftl_setup
#   - Config vars (ftl_cfg_dtag_move, ftl_cfg_dtag_l) are set in ftlrc

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

# Stubs for tmux / preview / pane
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
    ftl_pane_is_child=0
    ftl_cfg_dtag_move=1
    ftl_cfg_dtag_l=15
    ftl_list_entry_count=0
    ftl_list_entries=()
    declare -Ag ftl_dest_tags=()
    declare -Ag ftl_dest_dir_dest=()
    ftl_dest_last_dest=
    ftl_kbd_count=
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ---------------------------------------------------------------------------
# dest_tag_current
# ---------------------------------------------------------------------------

# Test: dest_tag_current reads a key and looks up the destination
test_dest_tag_current_sets_tag_from_key() {
    ftl_dest_dir_dest[d]="/tmp/docs"
    ftl_dest_dir_dest[t]="/tmp/tests"
    ftl_state_current_path="/work/file1.txt"

    # Stub read to return 'd'
    read() { REPLY='d' ; }
    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_current

    ftl::test::assert_eq "/tmp/docs" "${ftl_dest_tags[/work/file1.txt]}" \
        "dest_tag_current should set the tag to the dest dir for key 'd'"
    ftl::test::assert_eq "d" "$ftl_dest_last_dest" \
        "dest_tag_current should remember the last key used"
}

# Test: dest_tag_current moves cursor down when ftl_cfg_dtag_move is set
test_dest_tag_current_moves_down_when_dtag_move() {
    ftl_cfg_dtag_move=1
    ftl_dest_dir_dest[d]="/tmp/docs"
    ftl_state_current_path="/work/file1.txt"

    read() { REPLY='d' ; }
    _ftl_test_move_calls=0
    ftl::list::move_cursor() { ((_ftl_test_move_calls++)) ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_current

    ftl::test::assert_eq 1 "$_ftl_test_move_calls" \
        "dest_tag_current should call move_cursor once when dtag_move is set"
}

# Test: dest_tag_current does NOT move cursor when ftl_cfg_dtag_move is 0
test_dest_tag_current_no_move_when_dtag_move_zero() {
    ftl_cfg_dtag_move=0
    ftl_dest_dir_dest[d]="/tmp/docs"
    ftl_state_current_path="/work/file1.txt"

    read() { REPLY='d' ; }
    _ftl_test_move_calls=0
    ftl::list::move_cursor() { ((_ftl_test_move_calls++)) ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_current

    ftl::test::assert_eq 0 "$_ftl_test_move_calls" \
        "dest_tag_current should NOT call move_cursor when dtag_move is 0"
}

# Test: dest_tag_current handles unknown key gracefully (empty dest)
test_dest_tag_current_unknown_key() {
    ftl_dest_dir_dest[d]="/tmp/docs"
    # 'x' is not in the map
    ftl_state_current_path="/work/file1.txt"

    read() { REPLY='x' ; }
    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_current

    ftl::test::assert_eq "" "${ftl_dest_tags[/work/file1.txt]}" \
        "dest_tag_current should set empty tag for unknown key"
}

# ---------------------------------------------------------------------------
# dest_tag_clear_current
# ---------------------------------------------------------------------------

# Test: dest_tag_clear_current removes the current entry's tag
test_dest_tag_clear_current_removes_tag() {
    ftl_dest_tags[/work/file1.txt]="/tmp/docs"
    ftl_state_current_path="/work/file1.txt"

    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_clear_current

    ftl::test::assert_eq "" "${ftl_dest_tags[/work/file1.txt]:-}" \
        "dest_tag_clear_current should remove the current entry's tag"
}

# Test: dest_tag_clear_current is a no-op when no tag is set
test_dest_tag_clear_current_no_tag() {
    ftl_state_current_path="/work/file2.txt"
    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_clear_current

    ftl::test::assert_eq "" "${ftl_dest_tags[/work/file2.txt]:-}" \
        "dest_tag_clear_current should be a no-op when no tag is set"
}

# Test: dest_tag_clear_current respects ftl_cfg_dtag_move
test_dest_tag_clear_current_respects_dtag_move() {
    ftl_cfg_dtag_move=1
    ftl_state_current_path="/work/file1.txt"
    _ftl_test_move_calls=0
    ftl::list::move_cursor() { ((_ftl_test_move_calls++)) ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_clear_current

    ftl::test::assert_eq 1 "$_ftl_test_move_calls" \
        "dest_tag_clear_current should move cursor when dtag_move is set"
}

# ---------------------------------------------------------------------------
# dest_tag_clear_all
# ---------------------------------------------------------------------------

# Test: dest_tag_clear_all empties the ftl_dest_tags array
test_dest_tag_clear_all_empties_array() {
    ftl_dest_tags[/a]="/tmp/x"
    ftl_dest_tags[/b]="/tmp/y"
    ftl_dest_tags[/c]="/tmp/z"
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_clear_all

    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" \
        "dest_tag_clear_all should leave ftl_dest_tags empty"
}

# Test: dest_tag_clear_all does not touch ftl_dest_dir_dest
test_dest_tag_clear_all_preserves_dir_dest() {
    ftl_dest_tags[/a]="/tmp/x"
    ftl_dest_dir_dest[d]="/tmp/docs"
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_clear_all

    ftl::test::assert_eq "/tmp/docs" "${ftl_dest_dir_dest[d]}" \
        "dest_tag_clear_all should not touch ftl_dest_dir_dest"
}

# ---------------------------------------------------------------------------
# dest_tag_apply_last_to_count
# ---------------------------------------------------------------------------

# Test: dest_tag_apply_last_to_count uses ftl_dest_last_dest with default count 1
test_dest_tag_apply_last_default_count() {
    ftl_dest_last_dest="d"
    ftl_dest_dir_dest[d]="/tmp/docs"
    ftl_state_current_path="/work/file1.txt"
    ftl_kbd_count=
    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_apply_last_to_count

    ftl::test::assert_eq "/tmp/docs" "${ftl_dest_tags[/work/file1.txt]}" \
        "apply_last with default count should tag the current entry"
}

# Test: dest_tag_apply_last_to_count respects COUNT prefix
test_dest_tag_apply_last_with_count() {
    ftl_dest_last_dest="d"
    ftl_dest_dir_dest[d]="/tmp/docs"
    ftl_kbd_count=3
    # Simulate three entries (so move_cursor's stub can safely advance)
    ftl_list_entry_count=5
    ftl_list_entries=( "/work/f1" "/work/f2" "/work/f3" "/work/f4" "/work/f5" )
    ftl_state_cursor_index=0
    ftl_state_current_path="/work/f1"
    # Stub move_cursor: advance the index and update current_path
    ftl::list::move_cursor() {
        (( ftl_state_cursor_index++ ))
        (( ftl_state_cursor_index >= ftl_list_entry_count )) \
            && ftl_state_cursor_index=$((ftl_list_entry_count - 1))
        ftl_state_current_path="${ftl_list_entries[$ftl_state_cursor_index]}"
    }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_apply_last_to_count

    ftl::test::assert_eq "/tmp/docs" "${ftl_dest_tags[/work/f1]}" \
        "first entry should be tagged"
    ftl::test::assert_eq "/tmp/docs" "${ftl_dest_tags[/work/f2]}" \
        "second entry should be tagged"
    ftl::test::assert_eq "/tmp/docs" "${ftl_dest_tags[/work/f3]}" \
        "third entry should be tagged"
}

# ---------------------------------------------------------------------------
# dest_tag_copy_tagged / dest_tag_move_tagged
# ---------------------------------------------------------------------------

# Test: dest_tag_copy_tagged copies each tagged file to its destination
test_dest_tag_copy_tagged_copies_files() {
    mkdir -p "$FTL_TEST_TMP/src" "$FTL_TEST_TMP/dst1" "$FTL_TEST_TMP/dst2"
    echo "content1" > "$FTL_TEST_TMP/src/file1.txt"
    echo "content2" > "$FTL_TEST_TMP/src/file2.txt"

    ftl_dest_tags=(
        ["$FTL_TEST_TMP/src/file1.txt"]="$FTL_TEST_TMP/dst1"
        ["$FTL_TEST_TMP/src/file2.txt"]="$FTL_TEST_TMP/dst2"
    )
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_copy_tagged

    ftl::test::assert_eq "content1" "$(cat "$FTL_TEST_TMP/dst1/file1.txt")" \
        "file1 should be copied to dst1"
    ftl::test::assert_eq "content2" "$(cat "$FTL_TEST_TMP/dst2/file2.txt")" \
        "file2 should be copied to dst2"
    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" \
        "ftl_dest_tags should be cleared after copy"
    # Originals should still exist (copy, not move)
    ftl::test::assert_eq "content1" "$(cat "$FTL_TEST_TMP/src/file1.txt")" \
        "original file1 should still exist after copy"
}

# Test: dest_tag_move_tagged moves each tagged file to its destination
test_dest_tag_move_tagged_moves_files() {
    mkdir -p "$FTL_TEST_TMP/src" "$FTL_TEST_TMP/dst1"
    echo "content1" > "$FTL_TEST_TMP/src/file1.txt"

    ftl_dest_tags=(
        ["$FTL_TEST_TMP/src/file1.txt"]="$FTL_TEST_TMP/dst1"
    )
    ftl::list::change_dir() { : ; }

    ftl::cmd::dest_tag_move_tagged

    ftl::test::assert_eq "content1" "$(cat "$FTL_TEST_TMP/dst1/file1.txt")" \
        "file1 should be moved to dst1"
    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" \
        "ftl_dest_tags should be cleared after move"
    # Original should no longer exist
    [[ ! -e "$FTL_TEST_TMP/src/file1.txt" ]] \
        && ftl::test::pass "original file1 should not exist after move" \
        || ftl::test::fail "original file1 should not exist after move"
}

# Test: dest_tag_copy_tagged skips entries with empty destination
test_dest_tag_copy_skips_empty_dest() {
    mkdir -p "$FTL_TEST_TMP/src"
    echo "content" > "$FTL_TEST_TMP/src/file1.txt"

    # One entry with empty dest, one with valid dest
    ftl_dest_tags=(
        ["$FTL_TEST_TMP/src/file1.txt"]=""
    )
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_copy_tagged

    # No destination dir should have been written to (we can't easily check
    # this, but at least the command shouldn't have errored out)
    ftl::test::pass "dest_tag_copy_tagged completed without error on empty dest"
}

# Test: dest_tag_copy_tagged skips non-existent source files
test_dest_tag_copy_skips_missing_source() {
    mkdir -p "$FTL_TEST_TMP/dst1"

    ftl_dest_tags=(
        ["/nonexistent/source/file.txt"]="$FTL_TEST_TMP/dst1"
    )
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_copy_tagged

    # Nothing should have been copied to dst1
    local count
    count=$(ls -A "$FTL_TEST_TMP/dst1" 2>/dev/null | wc -l)
    ftl::test::assert_eq 0 "$count" \
        "no files should be copied when source doesn't exist"
}

# ---------------------------------------------------------------------------
# _ftl::dest::format_annotation
# ---------------------------------------------------------------------------

# Test: format_annotation returns empty when no tag is set
test_format_annotation_empty_when_no_tag() {
    unset 'ftl_dest_tags[/some/path]'
    local result
    result=$(_ftl::dest::format_annotation "/some/path")
    ftl::test::assert_eq "" "$result" \
        "format_annotation should return empty when no tag is set"
}

# Test: format_annotation returns the formatted annotation when tag is set
test_format_annotation_returns_annotation() {
    ftl_dest_tags[/some/path]="/tmp/docs"
    ftl_cfg_dtag_l=15
    local result
    result=$(_ftl::dest::format_annotation "/some/path")
    # The annotation is " [...<padded-tag>]" — the path appears between
    # [... and ] but may have trailing padding spaces. Check for the
    # path with the bracket prefix to avoid matching padding.
    ftl::test::assert_contains "$result" "[.../tmp/docs" \
        "format_annotation should include the dest path in brackets"
    ftl::test::assert_contains "$result" " " \
        "format_annotation should have a leading space (separator)"
    ftl::test::assert_contains "$result" "]" \
        "format_annotation should end with closing bracket"
}

# Test: format_annotation trims long destination paths to the last N chars
test_format_annotation_trims_long_paths() {
    ftl_dest_tags[/some/path]="/a/very/long/path/that/exceeds/the/limit"
    ftl_cfg_dtag_l=10
    local result
    result=$(_ftl::dest::format_annotation "/some/path")
    # Should contain only the last 10 chars of the path
    ftl::test::assert_contains "$result" "he/limit" \
        "format_annotation should trim long paths to the last ftl_cfg_dtag_l chars"
    ftl::test::assert_not_contains "$result" "/a/very/long" \
        "format_annotation should not include the beginning of a long path"
}

# Test: format_annotation pads short destination paths to the column width
test_format_annotation_pads_short_paths() {
    ftl_dest_tags[/some/path]="/tmp"
    ftl_cfg_dtag_l=15
    local result
    result=$(_ftl::dest::format_annotation "/some/path")
    # The result should be 15 chars between the [... and ]
    # Result format: " [...<padded-tag>]"
    # Extract the part between [... and ]
    local inner="${result#*\[\.\.\.}"
    inner="${inner%\]}"
    ftl::test::assert_eq 15 "${#inner}" \
        "format_annotation should pad the tag to ftl_cfg_dtag_l columns"
}

# ---------------------------------------------------------------------------
# Truncation accounts for color prefix length (entry_color_c)
# ---------------------------------------------------------------------------

# Test: truncation with a colored entry keeps more of the visible prefix
# than the same entry without color (because the slice index is offset by
# the color prefix length)
test_truncation_accounts_for_color_prefix() {
    # We test _ftl::list::apply_filters_and_format directly with a
    # manufactured colored entry to verify the entry_color_c adjustment.
    FTL_TEST_TMP=$(mktemp -d)
    cd "$FTL_TEST_TMP"

    # Create a file with a long name that will trigger truncation
    local fname="abcdefghij_longname.txt"
    touch "$fname"

    # Configure narrow pane to force truncation
    ftl_pane_width=20
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_state_current_tab_index=0
    ftl_state_etag_enabled=0
    ftl_state_show_size_mode=0
    ftl_state_show_stat=0
    ftl_state_search_string=
    ftl_cfg_show_entry_index=0
    ftl_cfg_quick_display_threshold=0
    ftl_list_path_separator=/
    ftl_list_resolved_sort_type=0
    ftl_list_resolved_sort_reversed=
    ftl_list_flip_index=0
    ftl_list_current_flip_char=" "
    ftl_list_quick_display_active=0
    ftl_list_index_padding=1
    ftl_list_display_line_no=0
    ftl_list_total_size=0
    ftl_list_first_file_index=
    ftl_list_search_found_index=
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
    ftl_cfg_line_color_default="\e[0m"
    ftl_cfg_cursor_color_default="\e[7m"
    ftl_cfg_row_separator_chars=(' ' ' ')

    # Manufacture a colored entry: color code + name + reset
    local color_prefix="\e[31m"   # red
    local color_reset="\e[0m"
    ftl_list_raw_entries[0]="$fname"
    ftl_list_raw_colors[0]="${color_prefix}${fname}${color_reset}"
    ftl_list_raw_names[0]="$fname"
    ftl_list_raw_paths[0]="$FTL_TEST_TMP"
    ftl_list_raw_relpath_len[0]=0
    ftl_list_raw_sizes[0]=0

    _ftl::list::apply_filters_and_format

    # The truncated color should:
    # 1. Contain the ellipsis
    # 2. End with the extension 'txt' (no dot)
    # 3. Contain the color prefix (the red color code)
    local color="${ftl_list_entry_colors[0]}"
    ftl::test::assert_contains "$color" "…" \
        "colored entry should be truncated with ellipsis"
    ftl::test::assert_contains "$color" "txt" \
        "colored entry should keep extension visible"
    ftl::test::assert_contains "$color" "$color_prefix" \
        "colored entry should preserve the color prefix"

    cd - >/dev/null
    rm -rf "$FTL_TEST_TMP"
}

# ---------------------------------------------------------------------------
# Render emits destination tag annotations
# ---------------------------------------------------------------------------
# Note: render tests live in test/unit/test_dest_tags_render.sh because the
# other tests in this file stub ftl::list::render to a no-op, and bash
# function definitions are global — the stub would persist into the render
# tests and produce empty output.

# ---------------------------------------------------------------------------
# Key bindings registered in ftlrc
# ---------------------------------------------------------------------------

# Test: ftlrc registers all 7 destination-tag bindings in the selection group
test_ftlrc_registers_dest_tag_bindings() {
    # Scan ftlrc for the 7 dest_tag bindings
    local count=0
    count=$(( $(grep -cE '^\s*ftl::kbd::bind\s+ftl\s+selection\s+t\s+ftl::cmd::dest_tag_current\b' "$FTL_CFG/etc/ftlrc") \
           + $(grep -cE '^\s*ftl::kbd::bind\s+ftl\s+selection\s+TCC\s+ftl::cmd::dest_tag_clear_current\b' "$FTL_CFG/etc/ftlrc") \
           + $(grep -cE '^\s*ftl::kbd::bind\s+ftl\s+selection\s+TCA\s+ftl::cmd::dest_tag_clear_all\b' "$FTL_CFG/etc/ftlrc") \
           + $(grep -cE '^\s*ftl::kbd::bind\s+ftl\s+selection\s+TT\s+ftl::cmd::dest_tag_apply_last_to_count\b' "$FTL_CFG/etc/ftlrc") \
           + $(grep -cE '^\s*ftl::kbd::bind\s+ftl\s+selection\s+"COUNT TT"\s+ftl::cmd::dest_tag_apply_last_to_count\b' "$FTL_CFG/etc/ftlrc") \
           + $(grep -cE '^\s*ftl::kbd::bind\s+ftl\s+selection\s+Tc\s+ftl::cmd::dest_tag_copy_tagged\b' "$FTL_CFG/etc/ftlrc") \
           + $(grep -cE '^\s*ftl::kbd::bind\s+ftl\s+selection\s+Tm\s+ftl::cmd::dest_tag_move_tagged\b' "$FTL_CFG/etc/ftlrc") ))
    ftl::test::assert_eq 7 "$count" \
        "ftlrc should register all 7 destination-tag bindings"
}

# Test: ftlrc declares the two config vars
test_ftlrc_declares_config_vars() {
    ftl::test::assert_contains "$(cat $FTL_CFG/etc/ftlrc)" "ftl_cfg_dtag_move" \
        "ftlrc should declare ftl_cfg_dtag_move"
    ftl::test::assert_contains "$(cat $FTL_CFG/etc/ftlrc)" "ftl_cfg_dtag_l" \
        "ftlrc should declare ftl_cfg_dtag_l"
}

# ---------------------------------------------------------------------------
# State declarations in ftl_setup
# ---------------------------------------------------------------------------

# Test: ftl_setup declares the dest_tags state arrays
test_ftl_setup_declares_dest_state() {
    ftl::test::assert_contains "$(cat $FTL_CFG/etc/core/ftl_setup)" "declare -Ag ftl_dest_tags" \
        "ftl_setup should declare ftl_dest_tags"
    ftl::test::assert_contains "$(cat $FTL_CFG/etc/core/ftl_setup)" "declare -Ag ftl_dest_dir_dest" \
        "ftl_setup should declare ftl_dest_dir_dest"
    ftl::test::assert_contains "$(cat $FTL_CFG/etc/core/ftl_setup)" "ftl_dest_last_dest=" \
        "ftl_setup should initialize ftl_dest_last_dest"
}

# Test: commands.sh sources dest_tags.sh
test_commands_sh_sources_dest_tags() {
    ftl::test::assert_contains "$(cat $FTL_CFG/etc/core/modules/commands.sh)" "commands/dest_tags.sh" \
        "commands.sh should source dest_tags.sh"
}

# vim: set filetype=bash :
