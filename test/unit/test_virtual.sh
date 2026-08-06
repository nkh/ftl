#!/bin/env bash
# test/unit/test_virtual.sh — tests for the virtual plugin module
#
# Tests ftl::plugin::virtual::set_callbacks, ::enable, ::reset,
# ::inject_entries, and ::get_virtual_dirs.

# Source the module under test
source "$FTL_CFG/etc/core/modules/virtual.sh"

ftl::test::setup() {
    # Reset to known state
    ftl::plugin::virtual::reset
    ftl_plugin_vfiles=()
    ftl_plugin_vdirs=()
    ftl_plugin_virtual_enabled=0
    ftl_plugin_virtual_callback=
}

# Test: set_callbacks redefines get_dirs_callback
test_set_callbacks_dirs() {
    ftl::plugin::virtual::set_callbacks \
        "echo my_dir_1; echo my_dir_2" \
        "echo my_file" \
        "cat" \
        ":" \
        ":"
    local out
    out=$(ftl::plugin::virtual::get_dirs_callback)
    ftl::test::assert_contains "$out" "my_dir_1" "dirs callback should echo my_dir_1"
    ftl::test::assert_contains "$out" "my_dir_2" "dirs callback should echo my_dir_2"
}

# Test: set_callbacks redefines get_files_callback
test_set_callbacks_files() {
    ftl::plugin::virtual::set_callbacks \
        ":" \
        "echo file_a; echo file_b" \
        "cat" \
        ":" \
        ":"
    local out
    out=$(ftl::plugin::virtual::get_files_callback)
    ftl::test::assert_contains "$out" "file_a" "files callback should echo file_a"
    ftl::test::assert_contains "$out" "file_b" "files callback should echo file_b"
}

# Test: set_callbacks populates ftl_plugin_virtual_callback string
test_set_callbacks_populates_etag_callback() {
    ftl::plugin::virtual::set_callbacks "D" "F" "C" "P" "H"
    ftl::test::assert_contains "$ftl_plugin_virtual_callback" "get_dirs_callback" \
        "ftl_plugin_virtual_callback should contain get_dirs_callback"
    ftl::test::assert_contains "$ftl_plugin_virtual_callback" "get_files_callback" \
        "ftl_plugin_virtual_callback should contain get_files_callback"
}

# Test: enable turns on the virtual entries flag
test_enable_sets_flag() {
    ftl::plugin::virtual::enable 1
    ftl::test::assert_eq "1" "$ftl_plugin_virtual_enabled" \
        "enable 1 should set ftl_plugin_virtual_enabled=1"
}

# Test: enable with 0 leaves it disabled
test_enable_zero() {
    ftl::plugin::virtual::enable 1
    ftl::plugin::virtual::enable 0
    ftl::test::assert_eq "0" "$ftl_plugin_virtual_enabled" \
        "enable 0 should set ftl_plugin_virtual_enabled=0"
}

# Test: reset clears callbacks and disables
test_reset_disables() {
    ftl::plugin::virtual::set_callbacks "echo D" "echo F" "cat" ":" ":"
    ftl::plugin::virtual::enable 1
    ftl::plugin::virtual::reset
    ftl::test::assert_eq "0" "$ftl_plugin_virtual_enabled" \
        "reset should disable virtual entries"
    ftl::test::assert_eq "" "$ftl_plugin_virtual_callback" \
        "reset should clear ftl_plugin_virtual_callback"
}

# Test: reset restores default no-op callbacks
test_reset_default_callbacks() {
    # Override callbacks
    ftl::plugin::virtual::set_callbacks "echo NOT_DEFAULT" "echo X" "cat" ":" ":"
    ftl::plugin::virtual::reset
    # Default get_dirs_callback should be a no-op (no output)
    local out
    out=$(ftl::plugin::virtual::get_dirs_callback)
    ftl::test::assert_eq "" "$out" "reset should restore default no-op callbacks"
}

# Test: inject_entries populates vfiles and vdirs when enabled
test_inject_entries_when_enabled() {
    ftl::plugin::virtual::set_callbacks \
        "echo vdir1; echo vdir2" \
        "echo vfile1" \
        "cat" ":" ":"
    ftl::plugin::virtual::enable 1
    ftl::plugin::virtual::inject_entries
    ftl::test::assert_eq "1" "${ftl_plugin_vdirs[vdir1]:-}" "vdir1 should be in vdirs"
    ftl::test::assert_eq "1" "${ftl_plugin_vdirs[vdir2]:-}" "vdir2 should be in vdirs"
    ftl::test::assert_eq "1" "${ftl_plugin_vfiles[vfile1]:-}" "vfile1 should be in vfiles"
}

# Test: inject_entries is a no-op when disabled
test_inject_entries_when_disabled() {
    ftl::plugin::virtual::set_callbacks \
        "echo should_not_appear" \
        "echo neither" \
        "cat" ":" ":"
    ftl::plugin::virtual::enable 0
    ftl::plugin::virtual::inject_entries
    ftl::test::assert_eq "0" "${#ftl_plugin_vdirs[@]}" "vdirs should be empty when disabled"
    ftl::test::assert_eq "0" "${#ftl_plugin_vfiles[@]}" "vfiles should be empty when disabled"
}

# Test: get_virtual_dirs emits find-format lines for each vdir
test_get_virtual_dirs_emits() {
    ftl_plugin_vdirs=( ["vdir_a"]=1 ["vdir_b"]=1 )
    local out
    out=$(ftl::plugin::virtual::get_virtual_dirs)
    ftl::test::assert_contains "$out" "vdir_a" "should emit vdir_a"
    ftl::test::assert_contains "$out" "vdir_b" "should emit vdir_b"
    # Each line should have the find-format prefix "0\t0\t"
    # Use a literal tab in the regex (ERE doesn't support \t)
    ftl::test::assert_match "0"$'\t'"0"$'\t' "$out" "should have 0<TAB>0<TAB> prefix"
}

# Test: get_virtual_dirs emits nothing when vdirs is empty
test_get_virtual_dirs_empty() {
    ftl_plugin_vdirs=()
    local out
    out=$(ftl::plugin::virtual::get_virtual_dirs)
    ftl::test::assert_eq "" "$out" "should output nothing when vdirs is empty"
}
