#!/bin/env bash
# test/unit/test_selection.sh — tests for the selection module
#
# Tests ftl::sel::flip, ftl::sel::set, ftl::sel::unset, ftl::sel::clear_all,
# ftl::sel::validate_existence, and ftl::sel::adjust_total_size.

# Source dependencies
source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"

# Set up before each test
ftl::test::setup() {
    ftl_selection_tags=()
    ftl_selection_total_bytes=0
    ftl_selection_revision=0
}

# Test: flip adds a tag
test_flip_add() {
    ftl::sel::flip "/tmp/test_file"
    ftl::test::assert_eq "▪" "${ftl_selection_tags[/tmp/test_file]}" "should have default glyph"
}

# Test: flip removes a tag
test_flip_remove() {
    ftl::sel::flip "/tmp/test_file"
    ftl::sel::flip "/tmp/test_file"
    ftl::test::assert_eq "" "${ftl_selection_tags[/tmp/test_file]:-}" "should be removed"
}

# Test: flip with custom glyph
test_flip_custom_glyph() {
    ftl::sel::flip "/tmp/test_file" "¹"
    ftl::test::assert_eq "¹" "${ftl_selection_tags[/tmp/test_file]}" "should have custom glyph"
}

# Test: set adds a tag if not already set
test_set_new() {
    ftl::sel::set "/tmp/test_file"
    ftl::test::assert_eq "▪" "${ftl_selection_tags[/tmp/test_file]}" "should be set"
}

# Test: set does not change existing tag
test_set_existing() {
    ftl::sel::set "/tmp/test_file" "¹"
    ftl::sel::set "/tmp/test_file" "²"
    ftl::test::assert_eq "¹" "${ftl_selection_tags[/tmp/test_file]}" "should not change existing"
}

# Test: unset removes a tag
test_unset() {
    ftl::sel::set "/tmp/test_file"
    ftl::sel::unset "/tmp/test_file"
    ftl::test::assert_eq "" "${ftl_selection_tags[/tmp/test_file]:-}" "should be removed"
}

# Test: unset on non-existent tag is a no-op
test_unset_nonexistent() {
    ftl::sel::unset "/tmp/nonexistent"
    ftl::test::pass "unset on non-existent should not error"
}

# Test: clear_all removes all tags
test_clear_all() {
    ftl::sel::set "/tmp/file1"
    ftl::sel::set "/tmp/file2"
    ftl::sel::set "/tmp/file3"
    ftl::sel::clear_all
    ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "should have 0 tags"
}

# Test: clear_all resets total bytes
test_clear_all_resets_size() {
    # Create a temp file to get its size
    local tmpfile
    tmpfile=$(mktemp)
    echo "test content" > "$tmpfile"
    
    ftl::sel::set "$tmpfile"
    local size_before=$ftl_selection_total_bytes
    ftl::test::assert_ne "0" "$size_before" "should have non-zero size"
    
    ftl::sel::clear_all
    ftl::test::assert_eq "0" "$ftl_selection_total_bytes" "should be 0 after clear"
    
    rm "$tmpfile"
}

# Test: validate_existence removes non-existent files
test_validate_existence() {
    local tmpfile
    tmpfile=$(mktemp)
    
    ftl::sel::set "$tmpfile"
    ftl::sel::set "/tmp/nonexistent_file_12345"
    
    ftl::sel::validate_existence
    
    ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "should have 1 tag (existent only)"
    ftl::test::assert_eq "1" "${ftl_selection_tags[$tmpfile]:+1}" "existent file should remain"
    
    rm "$tmpfile"
}

# Test: revision counter increments on each operation
test_revision_increments() {
    local rev_before=$ftl_selection_revision
    ftl::sel::set "/tmp/test1"
    ftl::test::assert_eq "$((rev_before + 1))" "$ftl_selection_revision" "should increment on set"
    
    ftl::sel::flip "/tmp/test1"
    ftl::test::assert_eq "$((rev_before + 2))" "$ftl_selection_revision" "should increment on flip"
    
    ftl::sel::clear_all
    ftl::test::assert_eq "$((rev_before + 3))" "$ftl_selection_revision" "should increment on clear"
}

# Test: resolve_current uses tags if any
test_resolve_current_with_tags() {
    ftl::sel::set "/tmp/file1"
    ftl::sel::set "/tmp/file2"
    
    # Mock ftl_list_entry_count to 0 so it doesn't interfere
    ftl_list_entry_count=0
    
    ftl::sel::resolve_current
    
    ftl::test::assert_eq "2" "${#ftl_selection_current[@]}" "should have 2 entries"
    ftl::test::assert_contains "${ftl_selection_current[*]}" "/tmp/file1" "should contain file1"
    ftl::test::assert_contains "${ftl_selection_current[*]}" "/tmp/file2" "should contain file2"
}

# Test: resolve_current falls back to current entry if no tags
test_resolve_current_no_tags() {
    ftl_list_entry_count=1
    ftl_list_entries=("/tmp/somefile")
    ftl_state_cursor_index=0
    
    ftl::sel::resolve_current
    
    ftl::test::assert_eq "1" "${#ftl_selection_current[@]}" "should have 1 entry"
    ftl::test::assert_eq "/tmp/somefile" "${ftl_selection_current[0]}" "should be current file"
}

# Test: format_header_summary returns empty when no tags
test_header_summary_empty() {
    local result
    result=$(ftl::sel::format_header_summary)
    ftl::test::assert_eq "" "$result" "should be empty with no tags"
}

# Test: format_header_summary returns count/size when tags exist
test_header_summary_with_tags() {
    local tmpfile
    tmpfile=$(mktemp)
    echo "test" > "$tmpfile"
    
    ftl::sel::set "$tmpfile"
    
    local result
    result=$(ftl::sel::format_header_summary)
    ftl::test::assert_contains "$result" "1/" "should show count 1"
    
    rm "$tmpfile"
}
