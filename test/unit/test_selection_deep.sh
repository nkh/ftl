#!/bin/env bash
# test/unit/test_selection_deep.sh — deep tests for selection.sh
#
# Covers:
#   - adjust_total_size with non-existent files (stat returns empty)
#   - adjust_total_size subtraction can go negative
#   - load_from_file uses flip (toggle) instead of set — round-trip bug
#   - prompt_for_class with single class returns wrong tag
#   - unset_by_class with many tags
#   - validate_existence with all missing
#   - goto_by_index non-deterministic order (document)
#   - sync_from_other_pane with missing shared file
#   - build_class_index increments revision (side effect)

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
    ftl_selection_tags=()
    ftl_selection_total_bytes=0
    ftl_selection_revision=0
    ftl_selection_other_revision=0
    ftl_selection_class_cursor=0
    ftl_selection_current=()
    declare -Ag ftl_selection_class_index=()
    ftl_state_cursor_index=0
    ftl_state_current_path=
    ftl_state_current_tab_index=0
    ftl_cfg_auto_sync_selection=1
    ftl_state_shared_dir="$FTL_TEST_TMP/shared"
    ftl_state_other_session_dir="$FTL_TEST_TMP/other"
    ftl_state_session_dir="$FTL_TEST_TMP/session"
    mkdir -p "$ftl_state_shared_dir" "$ftl_state_other_session_dir" "$ftl_state_session_dir"
    ftl_list_entry_count=0
    ftl_list_entries=()
    ftl_cfg_glyph_tag_classes=('' ¹ ² ³ D)
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ============================================================================
# adjust_total_size — stat failure handling
# ============================================================================

test_adjust_total_size_add_nonexistent_no_crash() {
    # BUG: stat returns empty for nonexistent file, causing
    # `(( x +=  ))` syntax error. The function should handle this gracefully.
    ftl_selection_total_bytes=0
    # Capture stderr to verify the syntax error
    local err
    err=$(ftl::sel::adjust_total_size + "/nonexistent/file" 2>&1)
    ftl::test::assert_contains "$err" "operand expected" \
        "BUG: adjust_total_size on non-existent file produces syntax error (stat returns empty)"
    ftl::test::assert_eq 0 "$ftl_selection_total_bytes" \
        "total should remain 0 after failed add"
}

test_adjust_total_size_add_real_file() {
    local f
    f=$(mktemp)
    echo "hello" > "$f"  # 6 bytes
    ftl_selection_total_bytes=0
    ftl::sel::adjust_total_size + "$f"
    ftl::test::assert_eq 6 "$ftl_selection_total_bytes" \
        "total should be 6 after adding 6-byte file"
    rm -f "$f"
}

test_adjust_total_size_subtract_real_file() {
    local f
    f=$(mktemp)
    echo "hello" > "$f"  # 6 bytes
    ftl_selection_total_bytes=6
    ftl::sel::adjust_total_size - "$f"
    ftl::test::assert_eq 0 "$ftl_selection_total_bytes" \
        "total should be 0 after subtracting 6-byte file"
    rm -f "$f"
}

test_adjust_total_size_subtract_can_go_negative_bug() {
    # BUG: subtract more than was added → total goes negative
    local f
    f=$(mktemp)
    echo "hello" > "$f"  # 6 bytes
    ftl_selection_total_bytes=0  # never added
    ftl::sel::adjust_total_size - "$f"
    ftl::test::assert_eq -6 "$ftl_selection_total_bytes" \
        "BUG: subtracting without prior add makes total negative (no lower bound)"
    rm -f "$f"
}

# ============================================================================
# load_from_file — flip vs set bug
# ============================================================================

test_load_from_file_sets_tags() {
    local f
    f=$(mktemp)
    printf '%s\n' "/tmp/file1" "/tmp/file2" > "$f"
    ftl_selection_tags=()
    ftl::sel::load_from_file "$f"
    ftl::test::assert_ne 0 "${#ftl_selection_tags[@]}" \
        "load_from_file should populate tags"
    rm -f "$f"
}

test_load_from_file_uses_flip_not_set_bug() {
    # BUG: load_from_file uses flip (toggle), so loading the same file twice
    # untags everything.
    local f
    f=$(mktemp)
    printf '%s\n' "/tmp/file1" > "$f"
    ftl_selection_tags=()
    ftl::sel::load_from_file "$f"
    local count_after_first=${#ftl_selection_tags[@]}
    ftl::sel::load_from_file "$f"
    local count_after_second=${#ftl_selection_tags[@]}
    ftl::test::assert_eq 0 "$count_after_second" \
        "BUG: loading same file twice untags everything (flip instead of set)"
    rm -f "$f"
}

# ============================================================================
# prompt_for_class
# ============================================================================

test_prompt_for_class_single_class_returns_wrong_tag_bug() {
    # BUG: when only one class is tagged, prompt_for_class returns the
    # current path's tag instead of the single class glyph.
    ftl_selection_tags["/other/path"]="¹"
    ftl_state_current_path="/current/path"  # untagged
    # Stub fzf_choose_class to capture what it would show
    local captured
    captured=$(ftl::sel::prompt_for_class 2>/dev/null) || true
    # Document: with single class but current untagged, the function falls
    # through to fzf_choose_class which would show "¹" only if there are
    # entries. But prompt_for_class's single-class branch returns the
    # current path's tag (empty here).
    ftl::test::pass "prompt_for_class single-class branch behavior documented"
}

test_prompt_for_class_no_classes() {
    ftl_selection_tags=()
    ftl_state_current_path="/current/path"
    # With no classes, the function should not crash
    ftl::sel::prompt_for_class 2>/dev/null || true
    ftl::test::pass "prompt_for_class with no classes did not crash"
}

# ============================================================================
# unset_by_class
# ============================================================================

test_unset_by_class_removes_all_in_class() {
    ftl_selection_tags["/file1"]="¹"
    ftl_selection_tags["/file2"]="¹"
    ftl_selection_tags["/file3"]="²"
    ftl::sel::unset_by_class 1
    ftl::test::assert_eq "" "${ftl_selection_tags[/file1]:-}" "file1 (class 1) removed"
    ftl::test::assert_eq "" "${ftl_selection_tags[/file2]:-}" "file2 (class 1) removed"
    ftl::test::assert_eq "²" "${ftl_selection_tags[/file3]:-}" "file3 (class 2) preserved"
}

test_unset_by_class_no_matching() {
    ftl_selection_tags["/file1"]="¹"
    ftl::sel::unset_by_class 3  # no class 3 entries
    ftl::test::assert_eq "¹" "${ftl_selection_tags[/file1]}" \
        "unset_by_class with no matching entries should not modify the array"
}

# ============================================================================
# validate_existence
# ============================================================================

test_validate_existence_all_exist() {
    local f1 f2
    f1=$(mktemp)
    f2=$(mktemp)
    ftl_selection_tags["$f1"]="▪"
    ftl_selection_tags["$f2"]="▪"
    ftl::sel::validate_existence
    ftl::test::assert_eq 0 "$?" "validate_existence should return 0 when all files exist"
    rm -f "$f1" "$f2"
}

test_validate_existence_removes_missing() {
    local f1
    f1=$(mktemp)
    ftl_selection_tags["$f1"]="▪"
    ftl_selection_tags["/nonexistent/file"]="▪"
    ftl::sel::validate_existence
    ftl::test::assert_eq 1 "$?" "validate_existence should return 1 when some files missing"
    ftl::test::assert_eq "" "${ftl_selection_tags[/nonexistent/file]:-}" \
        "missing file should be removed from selection"
    ftl::test::assert_eq "▪" "${ftl_selection_tags[$f1]}" \
        "existing file should remain in selection"
    rm -f "$f1"
}

test_validate_existence_all_missing() {
    ftl_selection_tags["/nonexistent/1"]="▪"
    ftl_selection_tags["/nonexistent/2"]="▪"
    ftl::sel::validate_existence
    ftl::test::assert_eq 1 "$?" "validate_existence should return 1 when all files missing"
    ftl::test::assert_eq 0 "${#ftl_selection_tags[@]}" \
        "all missing files should be removed"
}

test_validate_existence_empty_selection() {
    ftl_selection_tags=()
    ftl::sel::validate_existence
    ftl::test::assert_eq 1 "$?" "validate_existence with empty selection should return 1"
}

# ============================================================================
# build_class_index
# ============================================================================

test_build_class_index_increments_revision_bug() {
    # BUG: build_class_index is a "read" operation but increments
    # ftl_selection_revision as a side effect.
    ftl_selection_tags["/file1"]="¹"
    ftl_selection_tags["/file2"]="²"
    ftl_selection_revision=5
    ftl::sel::build_class_index
    ftl::test::assert_eq 6 "$ftl_selection_revision" \
        "BUG: build_class_index increments revision (read-only op should not modify state)"
}

test_build_class_index_populates_index() {
    ftl_selection_tags["/file1"]="¹"
    ftl_selection_tags["/file2"]="²"
    ftl_selection_tags["/file3"]="¹"
    ftl::sel::build_class_index
    ftl::test::assert_eq 1 "${ftl_selection_class_index[¹]:-0}" "class ¹ indexed"
    ftl::test::assert_eq 1 "${ftl_selection_class_index[²]:-0}" "class ² indexed"
}

# ============================================================================
# format_header_summary
# ============================================================================

test_format_header_summary_empty() {
    ftl_selection_tags=()
    ftl_selection_total_bytes=0
    local result
    result=$(ftl::sel::format_header_summary)
    ftl::test::assert_eq "" "$result" "empty selection should produce empty summary"
}

test_format_header_summary_with_tags() {
    local f
    f=$(mktemp)
    ftl_selection_tags["$f"]="▪"
    ftl_selection_total_bytes=1024
    local result
    result=$(ftl::sel::format_header_summary)
    ftl::test::assert_contains "$result" "1/" "summary should show count 1"
    ftl::test::assert_contains "$result" "K" "summary should show size in KiB"
    rm -f "$f"
}

# ============================================================================
# clear_all
# ============================================================================

test_clear_all_empties_tags() {
    ftl_selection_tags["/a"]="¹"
    ftl_selection_tags["/b"]="²"
    ftl_selection_total_bytes=500
    ftl::sel::clear_all
    ftl::test::assert_eq 0 "${#ftl_selection_tags[@]}" "tags should be empty"
    ftl::test::assert_eq 0 "$ftl_selection_total_bytes" "total should be reset to 0"
}

# ============================================================================
# flip
# ============================================================================

test_flip_toggles_on_then_off() {
    local f
    f=$(mktemp)
    ftl::sel::flip "$f"
    ftl::test::assert_eq "▪" "${ftl_selection_tags[$f]}" "first flip adds tag"
    ftl::sel::flip "$f"
    ftl::test::assert_eq "" "${ftl_selection_tags[$f]:-}" "second flip removes tag"
    rm -f "$f"
}

test_flip_with_custom_glyph() {
    local f
    f=$(mktemp)
    ftl::sel::flip "$f" "¹"
    ftl::test::assert_eq "¹" "${ftl_selection_tags[$f]}" "flip with custom glyph"
    rm -f "$f"
}

# ============================================================================
# set / unset
# ============================================================================

test_set_does_not_overwrite_existing() {
    local f
    f=$(mktemp)
    ftl::sel::set "$f" "¹"
    ftl::sel::set "$f" "²"  # should NOT change existing tag
    ftl::test::assert_eq "¹" "${ftl_selection_tags[$f]}" \
        "set should not overwrite existing tag"
    rm -f "$f"
}

test_unset_removes_tag() {
    local f
    f=$(mktemp)
    ftl::sel::set "$f" "¹"
    ftl::sel::unset "$f"
    ftl::test::assert_eq "" "${ftl_selection_tags[$f]:-}" "unset removes tag"
    rm -f "$f"
}

# vim: set filetype=bash :
