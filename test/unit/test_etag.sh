#!/bin/env bash
# test/unit/test_etag.sh — tests for the etag module
#
# Tests the default no-op implementations of ftl::etag::scan_directory
# and ftl::etag::get_entry_tag.

# Source the module under test
source "$FTL_CFG/etc/core/modules/etag.sh"

ftl::test::setup() {
    # Reset etag globals
    ftl_state_etag_enabled=0
    ftl_etag_source_name=
    ftl_etag_callback=
    ftl_etag_entry_tag=
    ftl_etag_entry_tag_len=0
}

# Test: scan_directory is callable and produces no output
test_scan_directory_no_output() {
    local out
    out=$(ftl::etag::scan_directory)
    ftl::test::assert_eq "" "$out" "default scan_directory should output nothing"
}

# Test: scan_directory returns success
test_scan_directory_returns_zero() {
    if ftl::etag::scan_directory ; then
        ftl::test::pass "scan_directory returns 0"
    else
        ftl::test::fail "scan_directory should return 0"
    fi
}

# Test: get_entry_tag sets the tag variable to empty
test_get_entry_tag_empty() {
    local tag="initial"
    local len="initial"
    ftl::etag::get_entry_tag "/some/path" tag len
    ftl::test::assert_eq "" "$tag" "default tag should be empty"
}

# Test: get_entry_tag sets the length variable to 0
test_get_entry_tag_zero_length() {
    local tag="initial"
    local len="initial"
    ftl::etag::get_entry_tag "/some/path" tag len
    ftl::test::assert_eq "0" "$len" "default tag length should be 0"
}

# Test: get_entry_tag does not depend on the entry path
test_get_entry_tag_path_independent() {
    local tag1 len1 tag2 len2
    ftl::etag::get_entry_tag "/path/one" tag1 len1
    ftl::etag::get_entry_tag "/path/two" tag2 len2
    ftl::test::assert_eq "$tag1" "$tag2" "tags should match (both empty)"
    ftl::test::assert_eq "$len1" "$len2" "lengths should match (both 0)"
}

# Test: get_entry_tag overwrites a non-empty tag value
test_get_entry_tag_overwrites() {
    local tag="non-empty"
    local len="42"
    ftl::etag::get_entry_tag "/path" tag len
    ftl::test::assert_eq "" "$tag" "non-empty tag should be reset to empty"
    ftl::test::assert_eq "0" "$len" "non-zero length should be reset to 0"
}

# Test: get_entry_tag returns success
test_get_entry_tag_returns_zero() {
    local tag len
    if ftl::etag::get_entry_tag "/path" tag len ; then
        ftl::test::pass "get_entry_tag returns 0"
    else
        ftl::test::fail "get_entry_tag should return 0"
    fi
}

# Test: scan_directory handles being called multiple times
test_scan_directory_idempotent() {
    ftl::etag::scan_directory
    ftl::etag::scan_directory
    ftl::etag::scan_directory
    ftl::test::pass "multiple scan_directory calls succeed"
}
