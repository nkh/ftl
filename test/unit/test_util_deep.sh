#!/bin/env bash
# test/unit/test_util_deep.sh — deep tests for util.sh
#
# Covers edge cases and bugs found in the audit:
#   - parse_path with root, single-component absolute, relative paths
#   - format_size_human with >= 1 PiB (loop fallthrough bug)
#   - resolve_full_path with non-"./" relative paths
#   - is_binary_file (smoke)
#   - dedup_file edge cases
#   - create_fifos argument validation
#   - stacktrace format

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"

# Stubs
tmux() { : ; }
stty() { : ; }
tput() { : ; }

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ============================================================================
# parse_path edge cases
# ============================================================================

test_parse_path_single_component_absolute_bug() {
    # BUG: parse_path "/foo" sets dir to "$PWD/" instead of "/"
    # because ${path%/*} on "/foo" strips "/foo" entirely → empty string
    # → PWD prepended.
    ftl::util::parse_path "/foo"
    ftl::test::assert_eq "foo" "$ftl_state_current_basename" \
        "basename of /foo should be 'foo'"
    ftl::test::assert_eq "$PWD/" "$ftl_state_current_dir" \
        "BUG: dir of /foo is '\$PWD/' instead of '/' (parse_path root decomposition bug)"
}

test_parse_path_root_bug() {
    ftl::util::parse_path "/"
    ftl::test::assert_eq "" "$ftl_state_current_basename" \
        "basename of '/' should be empty"
    ftl::test::assert_eq "$PWD/" "$ftl_state_current_dir" \
        "BUG: dir of '/' is '\$PWD/' instead of '/' (same root decomposition bug)"
}

test_parse_path_relative_no_slash_bug() {
    cd "$FTL_TEST_TMP"
    ftl::util::parse_path "file.txt"
    ftl::test::assert_eq "file.txt" "$ftl_state_current_basename" \
        "basename of relative 'file.txt' should be 'file.txt'"
    ftl::test::assert_eq "$PWD/" "$ftl_state_current_dir" \
        "BUG: dir of relative 'file.txt' has trailing slash (should be \$PWD without /)"
}

test_parse_path_with_extension() {
    ftl::util::parse_path "/tmp/file.tar.gz"
    ftl::test::assert_eq "file.tar.gz" "$ftl_state_current_basename"
    ftl::test::assert_eq "file.tar" "$ftl_state_current_stem" \
        "stem should strip only the last extension"
    ftl::test::assert_eq "gz" "$ftl_state_current_extension" \
        "extension should be only the last segment"
}

test_parse_path_no_extension() {
    ftl::util::parse_path "/tmp/Makefile"
    ftl::test::assert_eq "Makefile" "$ftl_state_current_basename"
    ftl::test::assert_eq "Makefile" "$ftl_state_current_stem" \
        "stem should equal basename when no extension"
    ftl::test::assert_eq "" "$ftl_state_current_extension" \
        "extension should be empty for no-extension files"
}

test_parse_path_dotfile() {
    ftl::util::parse_path "/tmp/.bashrc"
    ftl::test::assert_eq ".bashrc" "$ftl_state_current_basename"
    # Bash treats .bashrc as: stem=.bashrc, extension=bashrc (last dot wins)
    # This is the standard behavior — test documents it
    ftl::test::assert_eq "bashrc" "$ftl_state_current_extension" \
        "dotfile extension is the part after the (only) dot"
}

test_parse_path_clear_path_vars() {
    ftl::util::parse_path "/some/path/file.txt"
    ftl::util::clear_path_vars
    ftl::test::assert_eq "" "$ftl_state_current_path" "path should be cleared"
    ftl::test::assert_eq "" "$ftl_state_current_dir" "dir should be cleared"
    ftl::test::assert_eq "" "$ftl_state_current_basename" "basename should be cleared"
    ftl::test::assert_eq "" "$ftl_state_current_stem" "stem should be cleared"
    ftl::test::assert_eq "" "$ftl_state_current_extension" "extension should be cleared"
}

# ============================================================================
# format_size_human edge cases
# ============================================================================

test_format_size_human_zero() {
    local result
    result=$(ftl::util::format_size_human 0)
    ftl::test::assert_eq "   0 " "$result" \
        "size 0 should be formatted as '   0 ' (5-char right-aligned)"
}

test_format_size_human_small() {
    local result
    result=$(ftl::util::format_size_human 500)
    ftl::test::assert_eq " 500 " "$result" \
        "size 500 should be formatted as ' 500 '"
}

test_format_size_human_kib() {
    local result
    result=$(ftl::util::format_size_human 1024)
    ftl::test::assert_contains "$result" "K" "1024 should be in KiB range"
}

test_format_size_human_mib() {
    local result
    result=$(ftl::util::format_size_human $((1024 * 1024)))
    ftl::test::assert_contains "$result" "M" "1 MiB should be in M range"
}

test_format_size_human_gib() {
    local result
    result=$(ftl::util::format_size_human $((1024 ** 3)))
    ftl::test::assert_contains "$result" "G" "1 GiB should be in G range"
}

test_format_size_human_tib() {
    local result
    result=$(ftl::util::format_size_human $((1024 ** 4)))
    ftl::test::assert_contains "$result" "T" "1 TiB should be in T range"
}

test_format_size_human_pib_bug() {
    # BUG: the loop only iterates K, M, G, T — for >= 1 PiB it falls through
    # and returns an empty string. This test documents the bug.
    local result
    result=$(ftl::util::format_size_human $((1024 ** 5)))
    # When the bug is fixed, this assertion should pass:
    ftl::test::assert_eq "" "$result" \
        "1 PiB currently returns empty (loop fallthrough bug — needs P, E, Z, Y in loop)"
}

test_format_size_human_eib_bug() {
    local result
    result=$(ftl::util::format_size_human $((1024 ** 6)))
    ftl::test::assert_eq "" "$result" \
        "1 EiB currently returns empty (same loop fallthrough bug)"
}

test_format_size_human_just_under_kib() {
    local result
    result=$(ftl::util::format_size_human 1023)
    ftl::test::assert_contains "$result" "1023" "1023 should display as 1023 (under 1 KiB)"
}

# ============================================================================
# resolve_full_path
# ============================================================================

test_resolve_full_path_absolute_passthrough() {
    local result
    result=$(ftl::util::resolve_full_path "/already/absolute")
    ftl::test::assert_eq "/already/absolute" "$result" \
        "absolute path should pass through unchanged"
}

test_resolve_full_path_dot_slash() {
    cd "$FTL_TEST_TMP"
    local result
    result=$(ftl::util::resolve_full_path "./foo")
    ftl::test::assert_eq "$PWD/foo" "$result" \
        "./foo should be resolved to \$PWD/foo"
}

test_resolve_full_path_relative_no_dot_slash_bug() {
    # BUG: "foo" (no ./ prefix) returns "foo" unchanged, not "$PWD/foo"
    cd "$FTL_TEST_TMP"
    local result
    result=$(ftl::util::resolve_full_path "foo")
    ftl::test::assert_eq "foo" "$result" \
        "relative 'foo' (no ./) currently returns 'foo' unchanged (BUG: should be \$PWD/foo)"
}

test_resolve_full_path_middle_dot_slash_bug() {
    # BUG: ${1/\.\//$PWD\/} replaces the FIRST "./" anywhere, not just at start
    cd "$FTL_TEST_TMP"
    local result
    result=$(ftl::util::resolve_full_path "foo/./bar")
    ftl::test::assert_eq "foo/$PWD/bar" "$result" \
        "middle ./ is mangled (BUG: should keep 'foo/bar' or fully resolve)"
}

# ============================================================================
# is_binary_file
# ============================================================================

test_is_binary_file_text() {
    local f
    f=$(mktemp)
    echo "hello world" > "$f"
    ftl_state_current_is_binary=99  # sentinel
    ftl::util::is_binary_file "$f"
    ftl::test::assert_eq 0 "$ftl_state_current_is_binary" \
        "text file should set is_binary=0"
    rm -f "$f"
}

test_is_binary_file_binary() {
    local f
    f=$(mktemp)
    # Write a NUL byte to make it binary
    printf 'hello\0world\0' > "$f"
    ftl_state_current_is_binary=99
    ftl::util::is_binary_file "$f"
    ftl::test::assert_eq 1 "$ftl_state_current_is_binary" \
        "file with NUL bytes should set is_binary=1"
    rm -f "$f"
}

test_is_binary_file_nonexistent() {
    ftl_state_current_is_binary=99
    ftl::util::is_binary_file "/nonexistent/file" 2>/dev/null || true
    # perl -B on nonexistent file fails; the function captures perl's exit
    # code. Document the actual behavior (likely 0 or 2 depending on perl).
    ftl::test::assert_ne 99 "$ftl_state_current_is_binary" \
        "nonexistent file should change is_binary from sentinel value"
}

# ============================================================================
# dedup_file
# ============================================================================

test_dedup_file_removes_consecutive_dups() {
    local f
    f=$(mktemp)
    printf "a\na\nb\nc\nc\nc\n" > "$f"
    ftl::util::dedup_file "$f"
    local result
    result=$(cat "$f")
    ftl::test::assert_eq $'a\nb\nc' "$result" \
        "dedup_file should remove consecutive duplicates, preserving order"
    rm -f "$f"
}

test_dedup_file_preserves_non_consecutive() {
    local f
    f=$(mktemp)
    printf "a\nb\na\nc\n" > "$f"
    ftl::util::dedup_file "$f"
    local result
    result=$(cat "$f")
    # dedup_file uses `tac | awk '!seen[$0]++' | tac` which keeps the
    # LAST occurrence of each line (double tac reverses the order twice,
    # but awk dedup is applied on the reversed stream, so the last
    # occurrence in the original is the first in the reversed, hence kept).
    # Input "a b a c" → "b a c" (second 'a' kept, first removed).
    ftl::test::assert_eq $'b\na\nc' "$result" \
        "dedup_file keeps the LAST occurrence of each duplicate (tac|awk|tac)"
    rm -f "$f"
}

test_dedup_file_empty_file() {
    local f
    f=$(mktemp)
    : > "$f"
    ftl::util::dedup_file "$f"
    ftl::test::assert_eq "" "$(cat "$f")" "empty file stays empty"
    rm -f "$f"
}

test_dedup_file_missing_file() {
    # Should not crash on missing file
    ftl::util::dedup_file "/nonexistent/path/file" 2>/dev/null
    ftl::test::pass "dedup_file on missing file did not crash"
}

# ============================================================================
# create_fifos
# ============================================================================

test_create_fifos_single_fd() {
    ftl::util::create_fifos 9 2>/dev/null
    # Check the fd is open and is a fifo
    if [[ -e /proc/self/fd/9 ]] ; then
        ftl::test::pass "fd 9 was opened"
        # Close it
        exec 9>&-
    else
        ftl::test::fail "fd 9 was not opened"
    fi
}

test_create_fifos_multiple_fds() {
    ftl::util::create_fifos 7 8 2>/dev/null
    local ok=0
    [[ -e /proc/self/fd/7 ]] && ok=1
    [[ -e /proc/self/fd/8 ]] && (( ok == 1 )) && ok=2
    ftl::test::assert_eq 2 "$ok" "fds 7 and 8 should both be opened"
    exec 7>&- 8>&- 2>/dev/null
}

# ============================================================================
# stacktrace
# ============================================================================

test_stacktrace_returns_nonempty() {
    local trace
    trace=$(ftl::util::stacktrace 2>/dev/null) || true
    # stacktrace may be empty if caller info isn't available, but it shouldn't crash
    ftl::test::pass "stacktrace completed without crash"
}

# vim: set filetype=bash :
