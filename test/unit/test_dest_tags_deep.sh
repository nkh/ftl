#!/bin/env bash
# test/unit/test_dest_tags_deep.sh — deep tests for dest_tags.sh
#
# Covers edge cases and bugs found in the audit:
#   - dest_tag_apply_last_to_count with ftl_cfg_dtag_move=0 (tags same entry N times)
#   - dest_tag_copy_tagged clears tags even when cp fails
#   - dest_tag_move_tagged clears tags even when mv fails
#   - format_annotation with ftl_cfg_dtag_l=0
#   - format_annotation with empty tag
#   - dest_tag_current with empty REPLY
#   - dest_tag_current with empty current_path
#   - copy_tagged vs move_tagged consistency (render vs change_dir)

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
source "$FTL_CFG/etc/core/modules/commands.sh"

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

# ============================================================================
# dest_tag_apply_last_to_count — dtag_move=0 bug
# ============================================================================

test_apply_last_to_count_dtag_move_zero_tags_same_entry_bug() {
    # BUG: with ftl_cfg_dtag_move=0, the loop tags ftl_state_current_path
    # N times (overwriting), and move_cursor is never called, so only 1
    # entry is tagged regardless of count.
    ftl_cfg_dtag_move=0
    ftl_dest_last_dest="d"
    declare -Ag ftl_dest_dir_dest=([d]="/tmp/docs")
    ftl_state_current_path="/work/file1.txt"
    ftl_kbd_count=3
    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_apply_last_to_count

    ftl::test::assert_eq 1 "${#ftl_dest_tags[@]}" \
        "BUG: with dtag_move=0 and count=3, only 1 entry is tagged (same entry tagged N times)"
}

test_apply_last_to_count_dtag_move_one_tags_multiple() {
    ftl_cfg_dtag_move=1
    ftl_dest_last_dest="d"
    declare -Ag ftl_dest_dir_dest=([d]="/tmp/docs")
    ftl_kbd_count=3
    ftl_list_entry_count=5
    ftl_list_entries=("/work/f1" "/work/f2" "/work/f3" "/work/f4" "/work/f5")
    ftl_state_cursor_index=0
    ftl_state_current_path="/work/f1"
    ftl::list::move_cursor() {
        (( ftl_state_cursor_index++ ))
        (( ftl_state_cursor_index >= ftl_list_entry_count )) \
            && ftl_state_cursor_index=$((ftl_list_entry_count - 1))
        ftl_state_current_path="${ftl_list_entries[$ftl_state_cursor_index]}"
    }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_apply_last_to_count

    ftl::test::assert_eq 3 "${#ftl_dest_tags[@]}" \
        "with dtag_move=1 and count=3, 3 entries should be tagged"
}

test_apply_last_to_count_zero_count() {
    ftl_cfg_dtag_move=1
    ftl_dest_last_dest="d"
    declare -Ag ftl_dest_dir_dest=([d]="/tmp/docs")
    ftl_kbd_count=0
    ftl_state_current_path="/work/file1.txt"
    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_apply_last_to_count

    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" \
        "count=0 should tag no entries"
}

# ============================================================================
# dest_tag_copy_tagged — clears tags even when cp fails
# ============================================================================

test_copy_tagged_clears_tags_even_when_cp_fails_bug() {
    # BUG: ftl_dest_tags=() runs after the loop regardless of cp success.
    # If cp fails (e.g., destination dir doesn't exist), the tags are lost.
    mkdir -p "$FTL_TEST_TMP/src"
    echo "content" > "$FTL_TEST_TMP/src/file1.txt"
    # Destination dir doesn't exist
    ftl_dest_tags=(
        ["$FTL_TEST_TMP/src/file1.txt"]="/nonexistent/destination/dir"
    )
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_copy_tagged 2>/dev/null || true

    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" \
        "BUG: tags are cleared even when cp fails (lost work)"
}

test_copy_tagged_with_existing_destination() {
    mkdir -p "$FTL_TEST_TMP/src" "$FTL_TEST_TMP/dst"
    echo "content" > "$FTL_TEST_TMP/src/file1.txt"
    ftl_dest_tags=(
        ["$FTL_TEST_TMP/src/file1.txt"]="$FTL_TEST_TMP/dst"
    )
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_copy_tagged

    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" "tags cleared after successful copy"
    ftl::test::assert_eq "content" "$(cat "$FTL_TEST_TMP/dst/file1.txt")" \
        "file copied to destination"
}

# ============================================================================
# dest_tag_move_tagged — clears tags even when mv fails
# ============================================================================

test_move_tagged_clears_tags_even_when_mv_fails_bug() {
    mkdir -p "$FTL_TEST_TMP/src"
    echo "content" > "$FTL_TEST_TMP/src/file1.txt"
    ftl_dest_tags=(
        ["$FTL_TEST_TMP/src/file1.txt"]="/nonexistent/destination/dir"
    )
    ftl::list::change_dir() { : ; }

    ftl::cmd::dest_tag_move_tagged 2>/dev/null || true

    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" \
        "BUG: tags are cleared even when mv fails (lost work)"
    # Original file should still exist (mv failed)
    ftl::test::assert_eq "content" "$(cat "$FTL_TEST_TMP/src/file1.txt")" \
        "original file should still exist after failed mv"
}

test_move_tagged_with_existing_destination() {
    mkdir -p "$FTL_TEST_TMP/src" "$FTL_TEST_TMP/dst"
    echo "content" > "$FTL_TEST_TMP/src/file1.txt"
    ftl_dest_tags=(
        ["$FTL_TEST_TMP/src/file1.txt"]="$FTL_TEST_TMP/dst"
    )
    ftl::list::change_dir() { : ; }

    ftl::cmd::dest_tag_move_tagged

    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" "tags cleared after successful move"
    ftl::test::assert_eq "content" "$(cat "$FTL_TEST_TMP/dst/file1.txt")" \
        "file moved to destination"
    [[ ! -e "$FTL_TEST_TMP/src/file1.txt" ]] \
        && ftl::test::pass "original removed after move" \
        || ftl::test::fail "original should be removed after move"
}

# ============================================================================
# format_annotation edge cases
# ============================================================================

test_format_annotation_dtag_l_zero_bug() {
    # BUG: ${tag: -0} returns the WHOLE string (bash treats -0 as 0, and
    # ${var:0} is the whole string). So with dtag_l=0, the annotation is
    # the full tag, not trimmed to 0 chars.
    ftl_dest_tags[/path]="/very/long/path"
    ftl_cfg_dtag_l=0
    local result
    result=$(_ftl::dest::format_annotation "/path")
    ftl::test::assert_eq " [.../very/long/path]" "$result" \
        "BUG: dtag_l=0 returns full tag (should be empty or single char)"
}

test_format_annotation_dtag_l_one() {
    ftl_dest_tags[/path]="/very/long/path"
    ftl_cfg_dtag_l=1
    local result
    result=$(_ftl::dest::format_annotation "/path")
    # With dtag_l=1, should keep only the last char of the tag
    ftl::test::assert_contains "$result" "h" "dtag_l=1 should keep last char"
}

test_format_annotation_empty_tag_returns_empty() {
    # An entry with an empty-string destination (from unknown key) should
    # produce no annotation.
    ftl_dest_tags[/path]=""
    ftl_cfg_dtag_l=15
    local result
    result=$(_ftl::dest::format_annotation "/path")
    ftl::test::assert_eq "" "$result" \
        "empty tag should produce empty annotation"
}

test_format_annotation_unset_entry() {
    unset 'ftl_dest_tags[/unset/path]'
    ftl_cfg_dtag_l=15
    local result
    result=$(_ftl::dest::format_annotation "/unset/path")
    ftl::test::assert_eq "" "$result" \
        "unset entry should produce empty annotation"
}

test_format_annotation_tag_exactly_dtag_l_chars() {
    ftl_dest_tags[/path]="/exactly15char"  # 14 chars
    ftl_cfg_dtag_l=14
    local result
    result=$(_ftl::dest::format_annotation "/path")
    ftl::test::assert_contains "$result" "exactly15char" \
        "tag with exactly dtag_l chars should be fully shown"
}

test_format_annotation_tag_shorter_than_dtag_l_padded() {
    ftl_dest_tags[/path]="/short"
    ftl_cfg_dtag_l=15
    local result
    result=$(_ftl::dest::format_annotation "/path")
    # The inner part between [... and ] should be 15 chars
    local inner="${result#*\[\.\.\.}"
    inner="${inner%\]}"
    ftl::test::assert_eq 15 "${#inner}" \
        "tag shorter than dtag_l should be padded to dtag_l columns"
}

# ============================================================================
# dest_tag_current edge cases
# ============================================================================

test_dest_tag_current_empty_reply() {
    # If read returns empty (EOF / Ctrl-D), the tag should be empty
    declare -Ag ftl_dest_dir_dest=([d]="/tmp/docs")
    ftl_state_current_path="/work/file1.txt"
    read() { REPLY= ; }
    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_current

    ftl::test::assert_eq "" "${ftl_dest_tags[/work/file1.txt]}" \
        "empty REPLY should set empty tag"
    ftl::test::assert_eq "" "$ftl_dest_last_dest" \
        "empty REPLY should set empty last_dest"
}

test_dest_tag_current_empty_current_path() {
    # If ftl_state_current_path is empty, the tag should not be set
    # (avoid bad array subscript)
    declare -Ag ftl_dest_dir_dest=([d]="/tmp/docs")
    ftl_state_current_path=""
    read() { REPLY='d' ; }
    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_current 2>/dev/null || true

    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" \
        "empty current_path should not create a tag"
    ftl::test::assert_eq "d" "$ftl_dest_last_dest" \
        "last_dest should still be updated even with empty current_path"
}

# ============================================================================
# dest_tag_clear_current edge cases
# ============================================================================

test_clear_current_with_empty_current_path() {
    ftl_state_current_path=""
    ftl::list::move_cursor() { : ; }
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_clear_current 2>/dev/null || true

    ftl::test::pass "clear_current with empty current_path did not crash"
}

# ============================================================================
# dest_tag_clear_all
# ============================================================================

test_clear_all_preserves_last_dest() {
    ftl_dest_tags["/a"]="/tmp/x"
    ftl_dest_tags["/b"]="/tmp/y"
    ftl_dest_last_dest="d"
    declare -Ag ftl_dest_dir_dest=([d]="/tmp/docs")
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_clear_all

    ftl::test::assert_eq 0 "${#ftl_dest_tags[@]}" "tags cleared"
    ftl::test::assert_eq "d" "$ftl_dest_last_dest" "last_dest preserved"
    ftl::test::assert_eq "/tmp/docs" "${ftl_dest_dir_dest[d]}" "dir_dest preserved"
}

# ============================================================================
# copy_tagged vs move_tagged consistency
# ============================================================================

test_copy_uses_render_move_uses_change_dir_inconsistency_bug() {
    # BUG: copy_tagged calls ftl::list::render but move_tagged calls
    # ftl::list::change_dir. Inconsistent — copy doesn't refresh the listing
    # so copied files don't appear.
    # Verify by inspecting the function bodies with declare -f.
    local copy_body move_body
    copy_body=$(declare -f ftl::cmd::dest_tag_copy_tagged 2>/dev/null || true)
    move_body=$(declare -f ftl::cmd::dest_tag_move_tagged 2>/dev/null || true)

    ftl::test::assert_contains "$copy_body" "ftl::list::render" \
        "copy_tagged uses render"
    ftl::test::assert_contains "$move_body" "ftl::list::change_dir" \
        "move_tagged uses change_dir"
    ftl::test::pass "BUG documented: copy uses render (no rescan), move uses change_dir (rescan) — inconsistent"
}

# ============================================================================
# Multiple entries copy/move
# ============================================================================

test_copy_tagged_multiple_entries() {
    mkdir -p "$FTL_TEST_TMP/src" "$FTL_TEST_TMP/dst1" "$FTL_TEST_TMP/dst2"
    echo "a" > "$FTL_TEST_TMP/src/f1"
    echo "b" > "$FTL_TEST_TMP/src/f2"
    ftl_dest_tags=(
        ["$FTL_TEST_TMP/src/f1"]="$FTL_TEST_TMP/dst1"
        ["$FTL_TEST_TMP/src/f2"]="$FTL_TEST_TMP/dst2"
    )
    ftl::list::render() { : ; }

    ftl::cmd::dest_tag_copy_tagged

    ftl::test::assert_eq "a" "$(cat "$FTL_TEST_TMP/dst1/f1")" "f1 copied"
    ftl::test::assert_eq "b" "$(cat "$FTL_TEST_TMP/dst2/f2")" "f2 copied"
}

test_move_tagged_multiple_entries() {
    mkdir -p "$FTL_TEST_TMP/src" "$FTL_TEST_TMP/dst"
    echo "a" > "$FTL_TEST_TMP/src/f1"
    echo "b" > "$FTL_TEST_TMP/src/f2"
    ftl_dest_tags=(
        ["$FTL_TEST_TMP/src/f1"]="$FTL_TEST_TMP/dst"
        ["$FTL_TEST_TMP/src/f2"]="$FTL_TEST_TMP/dst"
    )
    ftl::list::change_dir() { : ; }

    ftl::cmd::dest_tag_move_tagged

    ftl::test::assert_eq "a" "$(cat "$FTL_TEST_TMP/dst/f1")" "f1 moved"
    ftl::test::assert_eq "b" "$(cat "$FTL_TEST_TMP/dst/f2")" "f2 moved"
    [[ ! -e "$FTL_TEST_TMP/src/f1" ]] && [[ ! -e "$FTL_TEST_TMP/src/f2" ]] \
        && ftl::test::pass "both originals removed" \
        || ftl::test::fail "originals should be removed after move"
}

# vim: set filetype=bash :
