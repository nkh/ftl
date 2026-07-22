#!/bin/env bash
# test/unit/test_tab.sh — tests for the tab module
#
# Tests ftl::tab::init_defaults, ftl::tab::create, ftl::tab::advance_index,
# ftl::tab::retreat_index.

# Source dependencies
source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/tab.sh"

ftl::test::setup() {
    ftl_tab_directories=()
    ftl_tab_count=0
    ftl_state_current_tab_index=0
    # Minimal config defaults needed by init_defaults
    ftl_cfg_default_reverse_filter=
}

# Test: init_defaults sets up tab state
test_init_defaults() {
    ftl_state_current_tab_index=0
    ftl::tab::init_defaults
    ftl::test::assert_eq "1" "${ftl_tab_listing_depth[0]}" "depth should be 1"
    ftl::test::assert_eq "0" "${ftl_tab_view_mode[0]}" "view mode should be 0"
    ftl::test::assert_eq "0" "${ftl_tab_listing_mode[0]}" "listing mode should be 0"
    ftl::test::assert_eq "." "${ftl_tab_filter_1[0]}" "filter_1 should be '.'"
}

# Test: create adds a new tab
test_create() {
    ftl::tab::create "/tmp"
    ftl::test::assert_eq "1" "${#ftl_tab_directories[@]}" "should have 1 tab"
    ftl::test::assert_eq "/tmp" "${ftl_tab_directories[0]}" "dir should be /tmp"
    ftl::test::assert_eq "1" "$ftl_tab_count" "count should be 1"
    ftl::test::assert_eq "0" "$ftl_state_current_tab_index" "current should be 0"
}

# Test: create with "." uses current directory
test_create_dot() {
    ftl::tab::create "."
    ftl::test::assert_contains "${ftl_tab_directories[0]}" "/" "should contain trailing slash for current dir"
}

# Test: create multiple tabs increments index
test_create_multiple() {
    ftl::tab::create "/tmp"
    ftl::tab::create "/var"
    ftl::tab::create "/usr"
    ftl::test::assert_eq "3" "${#ftl_tab_directories[@]}" "should have 3 tabs"
    ftl::test::assert_eq "2" "$ftl_state_current_tab_index" "current should be 2"
}

# Test: advance_index moves to next tab
test_advance_index() {
    ftl::tab::create "/tmp"
    ftl::tab::create "/var"
    ftl_state_current_tab_index=0
    ftl::tab::advance_index
    ftl::test::assert_eq "1" "$ftl_state_current_tab_index" "should be at tab 1"
}

# Test: advance_index wraps around
test_advance_index_wrap() {
    ftl::tab::create "/tmp"
    ftl::tab::create "/var"
    ftl_state_current_tab_index=1
    ftl::tab::advance_index
    ftl::test::assert_eq "0" "$ftl_state_current_tab_index" "should wrap to tab 0"
}

# Test: retreat_index moves to previous tab
test_retreat_index() {
    ftl::tab::create "/tmp"
    ftl::tab::create "/var"
    ftl_state_current_tab_index=1
    ftl::tab::retreat_index
    ftl::test::assert_eq "0" "$ftl_state_current_tab_index" "should be at tab 0"
}

# Test: retreat_index wraps around
test_retreat_index_wrap() {
    ftl::tab::create "/tmp"
    ftl::tab::create "/var"
    ftl_state_current_tab_index=0
    ftl::tab::retreat_index
    ftl::test::assert_eq "1" "$ftl_state_current_tab_index" "should wrap to tab 1"
}
