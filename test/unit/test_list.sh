#!/bin/env bash
# test/unit/test_list.sh — tests for the list module
#
# Tests ftl::list::move_cursor, ftl::list::quote_all_entries,
# ftl::list::quote_all_files, ftl::list::quote_all_dirs,
# ftl::list::quote_selection, ftl::list::compute_preview_width,
# and ftl::list::get_mime_type (caching behavior).

# Source dependencies
source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/pane.sh"
source "$FTL_CFG/etc/core/modules/list.sh"

ftl::test::setup() {
    tmux() { : ; }
    FTL_TEST_TMP=$(mktemp -d)
    # Reset list globals used by the functions under test
    declare -ag ftl_list_entries=()
    ftl_list_entry_count=0
    ftl_state_cursor_index=0
    ftl_state_current_tab_index=0
    declare -Ag ftl_state_cursor_memory=()
    declare -ag ftl_selection_current=()
    declare -Ag ftl_list_mime_cache=()
    ftl_state_current_path=
    ftl_state_current_mime_type=
    ftl_pane_self_id="%0"
    ftl_pane_preview_id=
    ftl_pane_width=80
    ftl_pane_preview_width=0
    ftl_pane_resize_target=0
    ftl_state_preview_zoom_index=0
    declare -ag ftl_cfg_preview_zoom_levels=( 50 )
    PWD_BAK="$PWD"
    cd "$FTL_TEST_TMP"
}

ftl::test::teardown() {
    [[ -n "${PWD_BAK:-}" ]] && cd "$PWD_BAK"
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# Test: move_cursor updates cursor_memory to a clamped value
test_move_cursor_basic() {
    ftl_list_entry_count=5
    ftl_state_cursor_index=2
    ftl::list::move_cursor 1
    ftl::test::assert_eq "3" "${ftl_state_cursor_memory[0_$PWD]}" \
        "cursor_memory should be 3 after +1 from 2"
}

# Test: move_cursor at lower boundary still updates memory (post-38a073a)
# Upstream 38a073a removed the `((nf != file)) &&` guard so move_cursor
# always updates memory and re-parses the path. This is required so that
# destination-tag commands can read ftl_state_current_path after a move
# and see the new entry's path, not the pre-move entry's path.
test_move_cursor_clamp_low() {
    ftl_list_entry_count=5
    ftl_state_cursor_index=0
    ftl::list::move_cursor -3
    ftl::test::assert_eq "0" "${ftl_state_cursor_memory[0_$PWD]:-}" \
        "cursor_memory should be 0 (clamped, always updated post-38a073a)"
}

# Test: move_cursor at upper boundary still updates memory (post-38a073a)
test_move_cursor_clamp_high() {
    ftl_list_entry_count=5
    ftl_state_cursor_index=4
    ftl::list::move_cursor 10
    ftl::test::assert_eq "4" "${ftl_state_cursor_memory[0_$PWD]:-}" \
        "cursor_memory should be 4 (clamped, always updated post-38a073a)"
}

# Test: move_cursor always returns zero (post-38a073a)
# The old behavior returned non-zero when no movement occurred. The new
# behavior always returns the result of parse_path/clear_path_vars (0),
# matching upstream move().
test_move_cursor_returns_zero_at_boundary() {
    ftl_list_entry_count=3
    ftl_state_cursor_index=0
    if ftl::list::move_cursor -1 ; then
        ftl::test::pass "move at lower boundary returns zero (post-38a073a)"
    else
        ftl::test::fail "move at lower boundary should return zero (post-38a073a)"
    fi
}

# Test: move_cursor returns zero when movement happens
test_move_cursor_returns_zero_on_move() {
    ftl_list_entry_count=3
    ftl_state_cursor_index=1
    if ftl::list::move_cursor 1 ; then
        ftl::test::pass "move in middle returns zero"
    else
        ftl::test::fail "move in middle should return zero"
    fi
}

# Test: move_cursor updates ftl_state_current_path to the new entry's path
# This is the core rationale for the 38a073a change — destination-tag
# commands read ftl_state_current_path immediately after move_cursor.
test_move_cursor_updates_current_path() {
    ftl_list_entry_count=3
    ftl_list_entries=( "/tmp/file_a.txt" "/tmp/file_b.txt" "/tmp/file_c.txt" )
    ftl_state_cursor_index=0
    ftl_state_current_path=
    ftl::list::move_cursor 1
    ftl::test::assert_eq "/tmp/file_b.txt" "$ftl_state_current_path" \
        "move_cursor should update ftl_state_current_path to the new entry"
}

# Test: move_cursor clears path vars when the listing is empty
test_move_cursor_clears_path_when_empty() {
    ftl_list_entry_count=0
    ftl_list_entries=()
    ftl_state_cursor_index=0
    ftl_state_current_path="/some/stale/path"
    ftl::list::move_cursor 1
    ftl::test::assert_eq "" "$ftl_state_current_path" \
        "move_cursor should clear ftl_state_current_path when listing is empty"
}

# Test: quote_all_entries quotes entries one per line
test_quote_all_entries() {
    ftl_list_entries=( "/tmp/a b.txt" "/tmp/cd" )
    local out
    out=$(ftl::list::quote_all_entries)
    ftl::test::assert_contains "$out" "/tmp/a\\ b.txt" \
        "spaces should be backslash-escaped"
    ftl::test::assert_contains "$out" "/tmp/cd" \
        "plain paths should pass through"
}

# Test: quote_all_entries returns one line per entry
test_quote_all_entries_count() {
    ftl_list_entries=( "a" "b" "c" )
    local out
    out=$(ftl::list::quote_all_entries)
    local count
    count=$(printf "%s\n" "$out" | wc -l)
    ftl::test::assert_eq "3" "$count" "should have 3 lines"
}

# Test: quote_all_dirs returns only directory entries
test_quote_all_dirs() {
    mkdir -p "$FTL_TEST_TMP/subdir"
    touch "$FTL_TEST_TMP/afile.txt"
    ftl_list_entries=( "$FTL_TEST_TMP/subdir" "$FTL_TEST_TMP/afile.txt" )
    local out
    out=$(ftl::list::quote_all_dirs)
    ftl::test::assert_contains "$out" "subdir" "should include the subdir"
    ftl::test::assert_eq "0" "$(printf "%s\n" "$out" | grep -c afile.txt)" \
        "should not include the file (count check)"
    # afile.txt should NOT be in output
    if printf "%s\n" "$out" | grep -q afile.txt ; then
        ftl::test::fail "afile.txt should not be in dirs output"
    else
        ftl::test::pass "afile.txt correctly excluded from dirs"
    fi
}

# Test: quote_all_files returns only file entries
test_quote_all_files() {
    mkdir -p "$FTL_TEST_TMP/subdir"
    touch "$FTL_TEST_TMP/afile.txt"
    ftl_list_entries=( "$FTL_TEST_TMP/subdir" "$FTL_TEST_TMP/afile.txt" )
    local out
    out=$(ftl::list::quote_all_files)
    ftl::test::assert_contains "$out" "afile.txt" "should include the file"
    if printf "%s\n" "$out" | grep -q subdir ; then
        ftl::test::fail "subdir should not be in files output"
    else
        ftl::test::pass "subdir correctly excluded from files"
    fi
}

# Test: quote_selection quotes the current selection
test_quote_selection() {
    ftl_selection_current=( "/tmp/x y" "/tmp/z" )
    local out
    out=$(ftl::list::quote_selection)
    ftl::test::assert_contains "$out" "/tmp/x\\ y" \
        "spaces in selection should be escaped"
    ftl::test::assert_contains "$out" "/tmp/z" "should include plain path"
}

# Test: compute_preview_width sets resize target when preview pane is open
test_compute_preview_width_with_preview() {
    ftl_pane_self_id="%0"
    ftl_pane_preview_id="%9"
    ftl_pane_width=100
    ftl_cfg_preview_zoom_levels=( 50 )
    tmux() {
        # The geometry query uses -t $ftl_pane_self_id with 5 tokens
        # The preview-width query uses -t $ftl_pane_preview_id with 1 token
        if [[ "$*" == *"$ftl_pane_preview_id"* ]] ; then
            echo 100
        else
            echo "0 200 50 100 0"
        fi
    }
    ftl::list::compute_preview_width
    ftl::test::assert_eq "100" "$ftl_pane_resize_target" \
        "resize target should be (100+100)*50/100 = 100"
}

# Test: compute_preview_width returns 0 when no preview pane
test_compute_preview_width_no_preview() {
    ftl_pane_self_id="%0"
    ftl_pane_width=100
    ftl_pane_preview_id=
    ftl_cfg_preview_zoom_levels=( 50 )
    tmux() { echo "0 200 50 100 0" ; }
    ftl::list::compute_preview_width
    ftl::test::assert_eq "0" "$ftl_pane_preview_width" \
        "preview_width should be 0 with no preview pane"
    ftl::test::assert_eq "50" "$ftl_pane_resize_target" \
        "resize_target should be (100+0)*50/100 = 50"
}

# Test: get_mime_type uses cache when present
test_get_mime_type_cached() {
    ftl_state_current_path="/some/file.txt"
    ftl_list_mime_cache["/some/file.txt"]="text/plain"
    ftl::list::get_mime_type
    ftl::test::assert_eq "text/plain" "$ftl_state_current_mime_type" \
        "should return cached mime type"
}

# Test: get_mime_type does not invoke detector when cache hits
test_get_mime_type_no_detector_on_hit() {
    ftl_state_current_path="/cached/path"
    ftl_list_mime_cache["/cached/path"]="image/png"
    # If detector is called, this would fail because it doesn't exist
    ftl_cfg_mime_detector="/nonexistent/binary"
    ftl::list::get_mime_type
    ftl::test::assert_eq "image/png" "$ftl_state_current_mime_type" \
        "should use cache without invoking detector"
}

# Test: get_mime_type invokes detector and caches result on miss
test_get_mime_type_invokes_detector() {
    # Create a detector script that returns "basename:text/plain"
    local detector="$FTL_TEST_TMP/detector"
    cat >"$detector" <<'EOF'
#!/bin/bash
# Echo each input path as "basename:text/plain"
for p in "$@" ; do
    echo "$(basename "$p"):text/plain"
done
EOF
    chmod +x "$detector"

    # Touch a file so basename matches
    touch "$FTL_TEST_TMP/file.txt"
    ftl_state_current_path="$FTL_TEST_TMP/file.txt"
    ftl_list_entries=( "$FTL_TEST_TMP/file.txt" )
    ftl_state_cursor_index=0
    ftl_list_mime_cache=()
    ftl_cfg_mime_detector="$detector"

    ftl::list::get_mime_type
    ftl::test::assert_eq "text/plain" "$ftl_state_current_mime_type" \
        "should populate mime type from detector"

    # Subsequent call should hit the cache (detector not called again).
    # Replace detector with one that would corrupt the result if called.
    cat >"$detector" <<'EOF'
#!/bin/bash
echo "$(basename "$1"):application/x-should-not-be-used"
EOF
    chmod +x "$detector"
    ftl_state_current_mime_type=
    ftl::list::get_mime_type
    ftl::test::assert_eq "text/plain" "$ftl_state_current_mime_type" \
        "should use cache on second call (detector output ignored)"
}
