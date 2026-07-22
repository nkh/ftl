#!/bin/env bash
# test/unit/test_state.sh — tests for the state module
#
# Tests ftl::state::save, ftl::state::load, ftl::state::save_selection,
# ftl::state::load_selection, ftl::state::serialize_info,
# ftl::state::render_child_env, ftl::state::emit_selection_fd3,
# and ftl::state::cleanup.

# Source the module under test
source "$FTL_CFG/etc/core/modules/state.sh"

# Set up before each test
ftl::test::setup() {
    tmux() { : ; }
    FTL_TEST_TMP=$(mktemp -d)
    # Mock the session dir layout used by the module
    ftl_state_session_dir="$FTL_TEST_TMP/session"
    ftl_state_shared_dir="$FTL_TEST_TMP/session/prev"
    ftl_state_parent_dir="$FTL_TEST_TMP/parent"
    mkdir -p "$ftl_state_session_dir" "$ftl_state_shared_dir" "$ftl_state_parent_dir"
    # Reset state globals the module reads/writes
    declare -Ag ftl_selection_tags=()
    ftl_selection_revision=0
    declare -ag ftl_selection_current=()
    declare -Ag ftl_state_cursor_memory=()
    ftl_state_current_path=
    ftl_state_current_tab_index=0
    ftl_state_cursor_index=0
    ftl_list_entry_count=0
    declare -ag ftl_list_entries=()
    declare -Ag ftl_state_child_env=()
    ftl_state_info_file_path=
    ftl_state_quit_cancelled=0
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# Test: save writes the tags file with declare -gA form
test_save_writes_tags() {
    ftl_selection_tags["/tmp/foo"]=1
    ftl::state::save
    [[ -f "$ftl_state_session_dir/tags" ]] \
        && ftl::test::pass "tags file exists" \
        || ftl::test::fail "tags file should exist"
    ftl::test::assert_contains "$(cat "$ftl_state_session_dir/tags")" "ftl_selection_tags" \
        "tags file should contain ftl_selection_tags declaration"
}

# Test: save with no entries writes an empty ftl state file
test_save_empty_writes_empty_ftl() {
    ftl_list_entry_count=0
    ftl::state::save
    ftl::test::assert_eq "" "$(cat "$ftl_state_session_dir/ftl")" \
        "ftl file should be empty when no entries"
}

# Test: save also writes the shared-dir pointer files
test_save_writes_shared_pointers() {
    ftl::state::save
    ftl::test::assert_eq "$ftl_state_session_dir" "$(cat "$ftl_state_shared_dir/fs")" \
        "shared fs pointer should point at session dir"
    ftl::test::assert_eq "0" "$(cat "$ftl_state_shared_dir/stagsi")" \
        "shared stagsi should be the selection revision"
}

# Test: load sources a state file
test_load_sources_file() {
    cat >"$ftl_state_session_dir/state" <<EOF
loaded_var=hello_world
EOF
    ftl::state::load "$ftl_state_session_dir/state"
    ftl::test::assert_eq "hello_world" "$loaded_var" "load should source the file"
}

# Test: load on missing file is a no-op
test_load_missing_file() {
    ftl::state::load "$ftl_state_session_dir/does_not_exist"
    ftl::test::pass "load on missing file did not error"
}

# Test: save_selection writes a sourceable tags file
test_save_selection_roundtrip() {
    ftl_selection_tags["/tmp/a"]=1
    ftl_selection_tags["/tmp/b"]=2
    ftl::state::save_selection "$ftl_state_session_dir/sel"
    # Reset and reload
    ftl_selection_tags=()
    ftl::state::load_selection "$ftl_state_session_dir/sel"
    ftl::test::assert_eq "1" "${ftl_selection_tags[/tmp/a]}" "tag a restored"
    ftl::test::assert_eq "2" "${ftl_selection_tags[/tmp/b]}" "tag b restored"
}

# Test: save_selection default path is session_dir/tags
test_save_selection_default_path() {
    ftl_selection_tags["/tmp/x"]=1
    ftl::state::save_selection
    [[ -f "$ftl_state_session_dir/tags" ]] \
        && ftl::test::pass "default tags path created" \
        || ftl::test::fail "default tags path missing"
}

# Test: serialize_info writes FTL_PID, FTL_SESSION_DIR, FTL_CWD
test_serialize_info_contents() {
    local target="$ftl_state_session_dir/info"
    ftl_state_current_path="/some/path"
    ftl::state::serialize_info "$target"
    local content
    content=$(cat "$target")
    ftl::test::assert_match "FTL_PID=$$" "$content" "should contain FTL_PID"
    ftl::test::assert_match "FTL_SESSION_DIR=$ftl_state_session_dir" "$content" \
        "should contain FTL_SESSION_DIR"
    ftl::test::assert_contains "$content" "FTL_CWD=" "should contain FTL_CWD"
    ftl::test::assert_contains "$content" "ftl_state_current_path" \
        "should contain ftl_state_current_path"
}

# Test: serialize_info creates a temp file when no path given
test_serialize_info_temp_file() {
    # Pass empty string so $1 is bound under set -u but treated as no-arg
    ftl::state::serialize_info ""
    [[ -f "$ftl_state_info_file_path" ]] \
        && ftl::test::pass "temp info file created" \
        || ftl::test::fail "temp info file missing"
    ftl::test::assert_contains "$ftl_state_info_file_path" "$ftl_state_session_dir" \
        "temp file should be in session dir"
}

# Test: render_child_env outputs -e key=value pairs
test_render_child_env_format() {
    ftl_state_child_env+=([FOO]=bar [BAZ]=qux)
    ftl_state_parent_dir="$FTL_TEST_TMP/parent"
    local out
    out=$(ftl::state::render_child_env)
    ftl::test::assert_contains "$out" "-e FOO=bar" "should have -e FOO=bar"
    ftl::test::assert_contains "$out" "-e BAZ=qux" "should have -e BAZ=qux"
    # render_child_env also injects ftl_pfs and ftl_fs
    ftl::test::assert_contains "$out" "ftl_pfs=" "should have ftl_pfs"
    ftl::test::assert_contains "$out" "ftl_fs=" "should have ftl_fs"
}

# Test: render_child_env accepts a custom flag prefix
test_render_child_env_custom_prefix() {
    ftl_state_child_env+=( [K1]=v1 )
    local out
    out=$(ftl::state::render_child_env "--env")
    ftl::test::assert_contains "$out" "--env K1=v1" "should use custom prefix"
}

# Test: emit_selection_fd3 writes selection to fd 3
test_emit_selection_fd3() {
    ftl_state_quit_cancelled=0
    ftl_selection_current=( "/tmp/a" "/tmp/b" )
    local out
    out=$(ftl::state::emit_selection_fd3 3>&1)
    ftl::test::assert_eq "/tmp/a
/tmp/b" "$out" "selection should be written to fd 3"
}

# Test: emit_selection_fd3 writes empty line when cancelled
test_emit_selection_fd3_cancelled() {
    ftl_state_quit_cancelled=1
    ftl_selection_current=( "/tmp/a" )
    local out
    out=$(ftl::state::emit_selection_fd3 3>&1)
    ftl::test::assert_eq "" "$out" "cancelled selection should be empty"
}

# Test: cleanup removes the session directory
test_cleanup_removes_session_dir() {
    local dir="$ftl_state_session_dir"
    touch "$dir/marker"
    ftl::state::cleanup
    [[ -d "$dir" ]] \
        && ftl::test::fail "session dir should be removed" \
        || ftl::test::pass "session dir removed"
}
