#!/bin/env bash
# test/unit/test_project_marks.sh — tests for the project_marks binding plugin
#
# Backport tests for upstream commit 5301ef3 "ADDED: project marks".
# Covers:
#   - get_project_marks: searches parent and child .ftl_project_marks files
#   - pmark: appends current entry to local mark file, deduplicates, reverses
#   - pmarks_fzf / pmarks_subdir_fzf: fzf navigation (mocked)
#   - pmarks_edit: opens the local mark file for editing
#   - Key bindings are registered with correct (group, subgroup, key) tuples

# Source dependencies required by the plugin
source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"

# Stubs for plugin dependencies that touch tmux / fzf / the listing engine.
ftl::list::render() { : ; }
_ftl::cmd::process_search_results() { : ; }
ftl::cmd::edit_current() {
    _ftl_test_last_edit_target="$1"
}

# Source the plugin under test
source "$FTL_CFG/bindings/project_marks"

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    cd "$FTL_TEST_TMP"
    ftl_state_current_path=
    _ftl_test_last_edit_target=
    # Plugin references ftl_cfg_fzf_popup_opts in fzf-tmux invocations
    ftl_cfg_fzf_popup_opts=
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# Test: get_project_marks walks upward and downward and concatenates mark files
test_get_project_marks_walks_upward_and_downward() {
    # Build tree: $FTL_TEST_TMP/a/.ftl_project_marks (parent)
    #             $FTL_TEST_TMP/a/b/.ftl_project_marks (here)
    #             $FTL_TEST_TMP/a/b/c/.ftl_project_marks (child)
    mkdir -p "$FTL_TEST_TMP/a/b/c"
    echo "/parent/mark" > "$FTL_TEST_TMP/a/.ftl_project_marks"
    echo "/here/mark"   > "$FTL_TEST_TMP/a/b/.ftl_project_marks"
    echo "/child/mark"  > "$FTL_TEST_TMP/a/b/c/.ftl_project_marks"

    cd "$FTL_TEST_TMP/a/b"
    local result_file result
    result_file="$(ftl::plugin::project_marks::get_project_marks)"
    result="$(cat "$result_file")"
    rm -f "$result_file"
    ftl::test::assert_contains "$result" "/parent/mark" "should include parent mark"
    ftl::test::assert_contains "$result" "/here/mark"   "should include current mark"
    ftl::test::assert_contains "$result" "/child/mark"  "should include child mark"
}

# Test: subdir_only mode skips the upward walk
test_get_project_marks_subdir_only() {
    mkdir -p "$FTL_TEST_TMP/a/b/c"
    echo "/parent/mark" > "$FTL_TEST_TMP/a/.ftl_project_marks"
    echo "/child/mark"  > "$FTL_TEST_TMP/a/b/c/.ftl_project_marks"

    cd "$FTL_TEST_TMP/a/b"
    local result_file result
    result_file="$(ftl::plugin::project_marks::get_project_marks 1)"
    result="$(cat "$result_file")"
    rm -f "$result_file"
    ftl::test::assert_contains    "$result" "/child/mark"  "should include child mark in subdir mode"
    ftl::test::assert_not_contains "$result" "/parent/mark" "should NOT include parent mark in subdir mode"
}

# Test: pmark adds current entry to local .ftl_project_marks, deduped and reversed
test_pmark_appends_dedupes_and_reverses() {
    cd "$FTL_TEST_TMP"
    # Pre-existing marks
    printf '%s\n' "/old/first" "/old/second" > .ftl_project_marks
    ftl_state_current_path="/new/third"

    ftl::plugin::project_marks::pmark

    local lines=()
    while IFS= read -r l ; do lines+=("$l") ; done < .ftl_project_marks
    # Pipeline: cat existing (first, second) | echo new (third) | awk dedup | tac (reverse)
    # Result: third, second, first
    ftl::test::assert_eq "/new/third"  "${lines[0]}" "new mark should be at top after tac"
    ftl::test::assert_eq "/old/second" "${lines[1]}" "old second should follow (tac reversed)"
    ftl::test::assert_eq "/old/first"  "${lines[2]}" "old first should be last (tac reversed)"
    ftl::test::assert_eq 3 "${#lines[@]}" "should have 3 unique marks"
}

# Test: pmark deduplicates an already-present entry (moves it to top)
test_pmark_dedupes_existing() {
    cd "$FTL_TEST_TMP"
    printf '%s\n' "/keep/first" "/dup/path" > .ftl_project_marks
    ftl_state_current_path="/dup/path"

    ftl::plugin::project_marks::pmark

    local lines=()
    while IFS= read -r l ; do lines+=("$l") ; done < .ftl_project_marks
    ftl::test::assert_eq 2 "${#lines[@]}"            "should still have 2 marks (no duplicate)"
    ftl::test::assert_eq "/dup/path" "${lines[0]}"   "duplicate should be moved to top"
    ftl::test::assert_eq "/keep/first" "${lines[1]}" "other mark preserved"
}

# Test: pmark creates the file if it doesn't exist
test_pmark_creates_file() {
    cd "$FTL_TEST_TMP"
    ftl_state_current_path="/brand/new"
    ftl::plugin::project_marks::pmark
    ftl::test::assert_eq "/brand/new" "$(cat .ftl_project_marks)" "file should be created with the new mark"
}

# Test: pmarks_edit calls edit_current with the local mark file and re-renders
test_pmarks_edit_opens_mark_file() {
    cd "$FTL_TEST_TMP"
    touch .ftl_project_marks
    ftl::plugin::project_marks::pmarks_edit
    ftl::test::assert_eq ".ftl_project_marks" "$_ftl_test_last_edit_target" \
        "pmarks_edit should pass the local mark file to edit_current"
}

# Test: pmarks_edit is a no-op when no local mark file exists
test_pmarks_edit_no_file() {
    cd "$FTL_TEST_TMP"
    ftl::plugin::project_marks::pmarks_edit
    ftl::test::assert_eq "" "$_ftl_test_last_edit_target" \
        "pmarks_edit should not invoke edit_current when no mark file exists"
}

# Test: pmarks_fzf strips $PWD/ prefix before passing to fzf
# (we replace process_search_results with a recorder)
test_pmarks_fzf_strips_pwd_prefix() {
    mkdir -p "$FTL_TEST_TMP/sub"
    # Marks include an absolute path that starts with $PWD
    printf '%s\n' "$FTL_TEST_TMP/sub/file_a" "$FTL_TEST_TMP/file_b" > .ftl_project_marks

    cd "$FTL_TEST_TMP"
    # Override the recorder to capture the fzf input.
    # The plugin uses the 3-arg form: `_ftl::cmd::process_search_results f fzf <results>`
    _ftl_test_captured_fzf_input=
    _ftl::cmd::process_search_results() {
        if [[ "$1" == "f" ]] ; then
            _ftl_test_captured_fzf_input="$3"
        else
            _ftl_test_captured_fzf_input="$2"
        fi
    }
    # stub fzf-tmux to just pass through stdin (so we can see what was sent)
    fzf-tmux() { cat ; }
    lscolors() { cat ; }

    ftl::plugin::project_marks::pmarks_fzf

    # The stripped names should appear in what was sent to fzf
    ftl::test::assert_contains "$_ftl_test_captured_fzf_input" "sub/file_a" "PWD prefix should be stripped"
    ftl::test::assert_contains "$_ftl_test_captured_fzf_input" "file_b"     "bare name preserved"
    ftl::test::assert_not_contains "$_ftl_test_captured_fzf_input" "$FTL_TEST_TMP/" "absolute prefix must not leak"
}

# Test: the plugin registers 4 key bindings in the (marks, project) group
test_plugin_registers_bindings() {
    # The ftl::kbd::bind calls happen at source time. We need to capture them.
    # Re-source the plugin with a stub bind function.
    ftl::kbd::bind() {
        _ftl_test_bindings+=("$1|$2|$3|$4")
    }
    _ftl_test_bindings=()
    source "$FTL_CFG/bindings/project_marks"
    unset -f ftl::kbd::bind

    local count=0
    local found_mpp=0 found_mpe=0 found_gpp=0 found_gps=0
    for b in "${_ftl_test_bindings[@]}" ; do
        # format: group|subgroup|key|func
        local g="${b%%|*}"; local rest="${b#*|}"
        local sg="${rest%%|*}"; rest="${rest#*|}"
        local key="${rest%%|*}"; local fn="${rest#*|}"
        [[ "$g" == "marks" && "$sg" == "project" ]] && (( count++ ))
        [[ "$key" == "Mpp" ]] && found_mpp=1
        [[ "$key" == "Mpe" ]] && found_mpe=1
        [[ "$key" == "gpp" ]] && found_gpp=1
        [[ "$key" == "gps" ]] && found_gps=1
    done

    ftl::test::assert_eq 4 "$count"      "should register 4 bindings in marks/project"
    ftl::test::assert_eq 1 "$found_mpp"  "Mpp binding registered"
    ftl::test::assert_eq 1 "$found_mpe"  "Mpe binding registered"
    ftl::test::assert_eq 1 "$found_gpp"  "gpp binding registered"
    ftl::test::assert_eq 1 "$found_gps"  "gps binding registered"
}

# Test: 'gp' is intentionally left unbound so 'gpp' / 'gps' can be 3-key chords
test_gp_prefix_is_free_for_chord_use() {
    # Scan ftlrc for any 'gp' leaf binding (we expect only 'gP' now)
    local matches
    matches=$(grep -E '^\s*ftl::kbd::bind\s+ftl\s+pane\s+gp\b' "$FTL_CFG/etc/ftlrc" || true)
    ftl::test::assert_eq "" "$matches" "ftlrc should not bind 'gp' (would shadow gpp/gps chords)"
    # And 'gP' should be present
    local gP_present
    gP_present=$(grep -cE '^\s*ftl::kbd::bind\s+ftl\s+pane\s+gP\b' "$FTL_CFG/etc/ftlrc" || true)
    ftl::test::assert_eq 1 "$gP_present" "ftlrc should bind 'gP' for goto_next_pane"
}
