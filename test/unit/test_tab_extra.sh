#!/bin/env bash
# test/unit/test_tab_extra.sh — additional tab tests

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/tab.sh"

ftl::test::setup() {
	ftl_tab_directories=()
	ftl_tab_count=0
	ftl_state_current_tab_index=0
	ftl_cfg_default_reverse_filter=
}

test_create_absolute_path() {
	ftl::tab::create "/usr/local"
	ftl::test::assert_eq "/usr/local" "${ftl_tab_directories[0]}"
}

test_create_relative_path() {
	ftl::tab::create "relative/dir"
	ftl::test::assert_contains "${ftl_tab_directories[0]}" "relative/dir"
}

test_create_increments_count() {
	ftl::tab::create "/a"
	ftl::tab::create "/b"
	ftl::test::assert_eq "2" "$ftl_tab_count"
}

test_create_sets_current_index() {
	ftl::tab::create "/first"
	ftl::test::assert_eq "0" "$ftl_state_current_tab_index"
	ftl::tab::create "/second"
	ftl::test::assert_eq "1" "$ftl_state_current_tab_index"
}

test_init_defaults_sets_depth() {
	ftl_state_current_tab_index=5
	ftl::tab::init_defaults
	ftl::test::assert_eq "1" "${ftl_tab_listing_depth[5]}"
}

test_init_defaults_sets_filters() {
	ftl_state_current_tab_index=3
	ftl::tab::init_defaults
	ftl::test::assert_eq "." "${ftl_tab_filter_1[3]}"
	ftl::test::assert_eq "." "${ftl_tab_filter_2[3]}"
	ftl::test::assert_eq "." "${ftl_tab_filter_dirs[3]}"
}

test_init_defaults_sets_modes() {
	ftl_state_current_tab_index=7
	ftl::tab::init_defaults
	ftl::test::assert_eq "0" "${ftl_tab_view_mode[7]}"
	ftl::test::assert_eq "0" "${ftl_tab_listing_mode[7]}"
}

test_advance_to_next() {
	ftl::tab::create "/a"
	ftl::tab::create "/b"
	ftl_state_current_tab_index=0
	ftl::tab::advance_index
	ftl::test::assert_eq "1" "$ftl_state_current_tab_index"
}

test_advance_wraps_around() {
	ftl::tab::create "/a"
	ftl::tab::create "/b"
	ftl_state_current_tab_index=1
	ftl::tab::advance_index
	ftl::test::assert_eq "0" "$ftl_state_current_tab_index"
}

test_retreat_to_prev() {
	ftl::tab::create "/a"
	ftl::tab::create "/b"
	ftl_state_current_tab_index=1
	ftl::tab::retreat_index
	ftl::test::assert_eq "0" "$ftl_state_current_tab_index"
}

test_retreat_wraps_around() {
	ftl::tab::create "/a"
	ftl::tab::create "/b"
	ftl_state_current_tab_index=0
	ftl::tab::retreat_index
	ftl::test::assert_eq "1" "$ftl_state_current_tab_index"
}

test_advance_single_tab() {
	ftl::tab::create "/only"
	ftl_state_current_tab_index=0
	ftl::tab::advance_index
	ftl::test::assert_eq "0" "$ftl_state_current_tab_index" "single tab stays at 0"
}

test_create_dot_uses_pwd() {
	ftl::tab::create "."
	ftl::test::assert_contains "${ftl_tab_directories[0]}" "/"
}

test_init_defaults_reverse_filter() {
	ftl_state_current_tab_index=0
	ftl_cfg_default_reverse_filter="\.swp$"
	ftl::tab::init_defaults
	ftl::test::assert_eq '\.swp$' "${ftl_tab_filter_reverse[0]}"
}

test_create_five_tabs() {
	for d in /a /b /c /d /e; do ftl::tab::create "$d"; done
	ftl::test::assert_eq "5" "${#ftl_tab_directories[@]}"
	ftl::test::assert_eq "4" "$ftl_state_current_tab_index"
}
