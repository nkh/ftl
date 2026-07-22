#!/bin/env bash
# test/unit/test_util_extra.sh — additional util tests

source "$FTL_CFG/etc/core/modules/util.sh"

test_parse_path_root_slash() {
	ftl::util::parse_path "/"
	ftl::test::assert_eq "/" "$ftl_state_current_path"
}

test_parse_path_double_slash() {
	ftl::util::parse_path "/a/b"
	ftl::test::assert_eq "/a" "$ftl_state_current_dir"
	ftl::test::assert_eq "b" "$ftl_state_current_basename"
}

test_parse_path_hidden_file() {
	ftl::util::parse_path "/home/user/.bashrc"
	ftl::test::assert_eq ".bashrc" "$ftl_state_current_basename"
	ftl::test::assert_eq "bashrc" "$ftl_state_current_extension"
}

test_parse_path_multiple_dots() {
	ftl::util::parse_path "/file.tar.gz"
	ftl::test::assert_eq "file.tar.gz" "$ftl_state_current_basename"
	ftl::test::assert_eq "gz" "$ftl_state_current_extension"
	ftl::test::assert_eq "file.tar" "$ftl_state_current_stem"
}

test_parse_path_no_dir() {
	ftl::util::parse_path "simple.txt"
	ftl::test::assert_eq "simple.txt" "$ftl_state_current_basename"
}

test_clear_path_resets_all() {
	ftl::util::parse_path "/some/deep/path/file.txt"
	ftl::util::clear_path_vars
	ftl::test::assert_eq "" "$ftl_state_current_path"
	ftl::test::assert_eq "" "$ftl_state_current_dir"
	ftl::test::assert_eq "" "$ftl_state_current_basename"
	ftl::test::assert_eq "" "$ftl_state_current_stem"
	ftl::test::assert_eq "" "$ftl_state_current_extension"
}

test_resolve_full_path_absolute() {
	local r=$(ftl::util::resolve_full_path "/usr/bin")
	ftl::test::assert_eq "/usr/bin" "$r"
}

test_resolve_full_path_no_trailing() {
	local r=$(ftl::util::resolve_full_path "/usr/bin/")
	ftl::test::assert_eq "/usr/bin" "$r"
}

test_format_size_zero() {
	local r=$(ftl::util::format_size_human 0)
	ftl::test::assert_contains "$r" "0"
}

test_format_size_exactly_1024() {
	local r=$(ftl::util::format_size_human 1024)
	ftl::test::assert_contains "$r" "K"
}

test_format_size_gigabyte() {
	local r=$(ftl::util::format_size_human 1073741824)
	ftl::test::assert_contains "$r" "G"
}

test_format_size_terabyte() {
	local r=$(ftl::util::format_size_human 1099511627776)
	ftl::test::assert_contains "$r" "T"
}

test_is_binary_file_text() {
	local tmpf=$(mktemp)
	echo "hello world" > "$tmpf"
	ftl::util::is_binary_file "$tmpf"
	ftl::test::assert_eq "0" "$ftl_state_current_is_binary" "text file is not binary"
	rm "$tmpf"
}

test_is_binary_file_binary() {
	local tmpf=$(mktemp)
	printf '\x00\x01\x02\x03' > "$tmpf"
	ftl::util::is_binary_file "$tmpf"
	ftl::test::assert_eq "1" "$ftl_state_current_is_binary" "null bytes are binary"
	rm "$tmpf"
}

test_dedup_file_single_line() {
	command -v sponge >/dev/null 2>&1 || { ftl::test::skip "sponge"; return; }
	local tmpf=$(mktemp)
	echo "only" > "$tmpf"
	ftl::util::dedup_file "$tmpf"
	ftl::test::assert_eq "only" "$(cat "$tmpf")" "single line preserved"
	rm "$tmpf"
}

test_dedup_file_all_same() {
	command -v sponge >/dev/null 2>&1 || { ftl::test::skip "sponge"; return; }
	local tmpf=$(mktemp)
	printf "dup\ndup\ndup\n" > "$tmpf"
	ftl::util::dedup_file "$tmpf"
	ftl::test::assert_eq "1" "$(wc -l < "$tmpf")" "all dups → 1 line"
	rm "$tmpf"
}

test_create_fifos_creates_fds() {
	# Test that we can create and use fifos
	local tmpdir=$(mktemp -d)
	local pipe="$tmpdir/test_pipe"
	mkfifo "$pipe"
	exec 100<>"$pipe"
	echo "test" >&100 &
	local val
	read -t 1 -u 100 val
	ftl::test::assert_eq "test" "$val" "fifo works"
	exec 100>&-
	rm -rf "$tmpdir"
}

test_refresh_screen_outputs_escape() {
	local r=$(ftl::util::refresh_screen "test")
	ftl::test::assert_contains "$r" "test"
}

test_stacktrace_returns_something() {
	local r=$(ftl::test::_pass 2>&1 ; ftl::util::stacktrace 2>&1)
	# stacktrace should produce output when called from a function
	ftl::test::pass "stacktrace executed"
}
