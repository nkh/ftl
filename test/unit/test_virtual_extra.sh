#!/bin/env bash
# test/unit/test_virtual_extra.sh — additional virtual entry tests

source "$FTL_CFG/etc/core/modules/virtual.sh"

ftl::test::setup() {
	ftl_plugin_vfiles=()
	ftl_plugin_vdirs=()
	ftl_plugin_virtual_enabled=0
	ftl_etag_callback=
}

test_enable_sets_flag() {
	ftl::plugin::virtual::enable 1
	ftl::test::assert_eq "1" "$ftl_plugin_virtual_enabled"
}

test_enable_initializes_arrays() {
	ftl::plugin::virtual::enable 1
	ftl::test::assert_eq "0" "${#ftl_plugin_vfiles[@]}"
	ftl::test::assert_eq "0" "${#ftl_plugin_vdirs[@]}"
}

test_reset_clears_flag() {
	ftl::plugin::virtual::enable 1
	ftl::plugin::virtual::reset
	ftl::test::assert_eq "0" "$ftl_plugin_virtual_enabled"
}

test_reset_clears_callback() {
	ftl::plugin::virtual::set_callbacks D F C P H
	ftl::plugin::virtual::reset
	ftl::test::assert_eq "" "$ftl_etag_callback"
}

test_inject_populates_vdirs() {
	ftl::plugin::virtual::enable 1
	ftl::plugin::virtual::get_dirs_callback() { echo "vd1"; }
	ftl::plugin::virtual::get_files_callback() { :; }
	ftl::plugin::virtual::inject_entries
	ftl::test::assert_eq "1" "${#ftl_plugin_vdirs[@]}"
}

test_inject_populates_vfiles() {
	ftl::plugin::virtual::enable 1
	ftl::plugin::virtual::get_dirs_callback() { :; }
	ftl::plugin::virtual::get_files_callback() { echo "vf1"; echo "vf2"; }
	ftl::plugin::virtual::inject_entries
	ftl::test::assert_eq "2" "${#ftl_plugin_vfiles[@]}"
}

test_inject_disabled_noop() {
	ftl_plugin_virtual_enabled=0
	ftl::plugin::virtual::get_dirs_callback() { echo "should_not_appear"; }
	ftl::plugin::virtual::inject_entries
	ftl::test::assert_eq "0" "${#ftl_plugin_vdirs[@]}"
}

test_get_virtual_dirs_empty() {
	ftl_plugin_vdirs=()
	local r=$(ftl::plugin::virtual::get_virtual_dirs)
	ftl::test::assert_eq "" "$r"
}

test_get_virtual_dirs_single() {
	ftl_plugin_vdirs=([mydir]=1)
	local r=$(ftl::plugin::virtual::get_virtual_dirs)
	ftl::test::assert_contains "$r" "mydir"
}

test_get_virtual_dirs_multiple() {
	ftl_plugin_vdirs=([d1]=1 [d2]=1 [d3]=1)
	local r=$(ftl::plugin::virtual::get_virtual_dirs)
	ftl::test::assert_contains "$r" "d1"
	ftl::test::assert_contains "$r" "d2"
	ftl::test::assert_contains "$r" "d3"
}

test_set_callbacks_has_dirs() {
	ftl::plugin::virtual::set_callbacks DIRS FILES CLR PREV KEY
	ftl::test::assert_contains "$ftl_etag_callback" "DIRS"
}

test_set_callbacks_has_files() {
	ftl::plugin::virtual::set_callbacks DIRS FILES CLR PREV KEY
	ftl::test::assert_contains "$ftl_etag_callback" "FILES"
}

test_set_callbacks_has_clear() {
	ftl::plugin::virtual::set_callbacks DIRS FILES CLR PREV KEY
	ftl::test::assert_contains "$ftl_etag_callback" "CLR"
}

test_set_callbacks_has_preview() {
	ftl::plugin::virtual::set_callbacks DIRS FILES CLR PREV KEY
	ftl::test::assert_contains "$ftl_etag_callback" "PREV"
}

test_set_callbacks_has_key() {
	ftl::plugin::virtual::set_callbacks DIRS FILES CLR PREV KEY
	ftl::test::assert_contains "$ftl_etag_callback" "KEY"
}

test_enable_appends_to_callback() {
	ftl_etag_callback="existing"
	ftl::plugin::virtual::enable 1
	ftl::test::assert_contains "$ftl_etag_callback" "existing"
}

test_inject_clears_first() {
	ftl_plugin_vfiles=([old]=1)
	ftl_plugin_vdirs=([olddir]=1)
	ftl_plugin_virtual_enabled=1
	ftl::plugin::virtual::get_dirs_callback() { :; }
	ftl::plugin::virtual::get_files_callback() { :; }
	ftl::plugin::virtual::inject_entries
	ftl::test::assert_eq "0" "${#ftl_plugin_vfiles[@]}" "old vfiles cleared"
	ftl::test::assert_eq "0" "${#ftl_plugin_vdirs[@]}" "old vdirs cleared"
}

test_default_callbacks_are_noops() {
	# Default get_dirs_callback should produce no output
	local r=$(ftl::plugin::virtual::get_dirs_callback)
	ftl::test::assert_eq "" "$r"
}

test_default_clear_filter_is_cat() {
	local r=$(echo "passthrough" | ftl::plugin::virtual::clear_filter)
	ftl::test::assert_eq "passthrough" "$r"
}
