#!/bin/env bash
# test/unit/test_util.sh — tests for the util module
#
# Tests ftl::util::parse_path, ftl::util::resolve_full_path,
# ftl::util::format_size_human, and ftl::util::dedup_file.

# Source the module under test
source "$FTL_CFG/etc/core/modules/util.sh"

# Test: parse_path decomposes a full path correctly
test_parse_path_full() {
    ftl::util::parse_path "/home/user/file.txt"
    ftl::test::assert_eq "/home/user/file.txt" "$ftl_state_current_path" "path"
    ftl::test::assert_eq "/home/user" "$ftl_state_current_dir" "dir"
    ftl::test::assert_eq "file.txt" "$ftl_state_current_basename" "basename"
    ftl::test::assert_eq "file" "$ftl_state_current_stem" "stem"
    ftl::test::assert_eq "txt" "$ftl_state_current_extension" "extension"
}

# Test: parse_path handles paths without extension
test_parse_path_no_extension() {
    ftl::util::parse_path "/home/user/Makefile"
    ftl::test::assert_eq "Makefile" "$ftl_state_current_basename" "basename"
    ftl::test::assert_eq "Makefile" "$ftl_state_current_stem" "stem"
    ftl::test::assert_eq "" "$ftl_state_current_extension" "extension should be empty"
}

# Test: parse_path handles relative paths
test_parse_path_relative() {
    ftl::util::parse_path "src/main.sh"
    # The dir should be resolved relative to PWD
    ftl::test::assert_eq "main.sh" "$ftl_state_current_basename" "basename"
    ftl::test::assert_eq "sh" "$ftl_state_current_extension" "extension"
}

# Test: parse_path handles root path
test_parse_path_root() {
    ftl::util::parse_path "/"
    ftl::test::assert_eq "/" "$ftl_state_current_path" "path"
}

# Test: clear_path_vars resets all
test_clear_path_vars() {
    ftl::util::parse_path "/some/path/file.txt"
    ftl::util::clear_path_vars
    ftl::test::assert_eq "" "$ftl_state_current_path" "path should be empty"
    ftl::test::assert_eq "" "$ftl_state_current_dir" "dir should be empty"
    ftl::test::assert_eq "" "$ftl_state_current_basename" "basename should be empty"
}

# Test: resolve_full_path handles ./
test_resolve_full_path_dot() {
    local result
    result=$(cd /tmp && ftl::util::resolve_full_path "./foo/bar")
    ftl::test::assert_eq "/tmp/foo/bar" "$result" "should expand ./ relative to PWD"
}

# Test: resolve_full_path handles trailing slash
test_resolve_full_path_trailing_slash() {
    local result
    result=$(ftl::util::resolve_full_path "/home/user/")
    ftl::test::assert_eq "/home/user" "$result" "should strip trailing slash"
}

# Test: resolve_full_path handles absolute paths
test_resolve_full_path_absolute() {
    local result
    result=$(ftl::util::resolve_full_path "/usr/local/bin")
    ftl::test::assert_eq "/usr/local/bin" "$result" "absolute path unchanged"
}

# Test: format_size_human formats bytes
test_format_size_bytes() {
    local result
    result=$(ftl::util::format_size_human 512)
    ftl::test::assert_contains "$result" "512" "512 bytes"
}

# Test: format_size_human formats kilobytes
test_format_size_kilobytes() {
    local result
    result=$(ftl::util::format_size_human 2048)
    ftl::test::assert_contains "$result" "2" "2048 bytes should show as ~2K"
    ftl::test::assert_contains "$result" "K" "should have K suffix"
}

# Test: format_size_human formats megabytes
test_format_size_megabytes() {
    local result
    result=$(ftl::util::format_size_human 1048576)
    ftl::test::assert_contains "$result" "M" "should have M suffix"
}

# Test: dedup_file removes duplicate lines
test_dedup_file() {
    command -v sponge >/dev/null 2>&1 || { ftl::test::skip "sponge not installed"; return; }
    local tmpfile
    tmpfile=$(mktemp)
    printf "line1\nline2\nline1\nline3\nline2\n" > "$tmpfile"
    ftl::util::dedup_file "$tmpfile"
    local result
    result=$(cat "$tmpfile")
    ftl::test::assert_eq "line1
line2
line3" "$result" "should preserve order, remove dups"
    rm "$tmpfile"
}

# Test: dedup_file on empty file is a no-op
test_dedup_file_empty() {
    local tmpfile
    tmpfile=$(mktemp)
    : > "$tmpfile"
    ftl::util::dedup_file "$tmpfile"
    ftl::test::assert_eq "" "$(cat "$tmpfile")" "empty file stays empty"
    rm "$tmpfile"
}
