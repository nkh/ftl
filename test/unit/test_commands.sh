#!/bin/env bash
# test/unit/test_commands.sh — tests for selected command-module functions
#
# Tests ftl::cmd::dispatch_command (empty, numeric, "qa", "load_sel",
# trie shortcuts, command_to_key shortcuts, and user-command lookup)
# and ftl::list::quote_selection.

# Source dependencies (order matters: log -> state -> selection -> list -> commands)
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"
source "$FTL_CFG/etc/core/modules/list.sh"
source "$FTL_CFG/etc/core/modules/commands.sh"

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    tmux() { : ; }
    # Common globals used by dispatch_command
    ftl_state_session_dir="$FTL_TEST_TMP/session"
    mkdir -p "$ftl_state_session_dir"
    ftl_state_pending_input=
    ftl_state_cursor_index=0
    declare -ag ftl_list_entries=()
    ftl_list_entry_count=0
    declare -Ag ftl_kbd_trie=()
    declare -Ag ftl_kbd_command_to_key=()
    ftl_state_info_file_path=
    ftl_pane_session_shell_active=0
    declare -Ag ftl_cfg_command_aliases=()
    declare -ag ftl_selection_current=()
    # Override heavy functions called by dispatch_command paths
    ftl::list::change_dir() { CHANGE_DIR_CALLED=1 ; }
    ftl::list::render() { RENDER_CALLED=1 ; }
    ftl::cmd::quit_all() { QUIT_ALL_CALLED=1 ; }
    ftl::sel::load_from_file() { LOAD_SEL_CALLED=1 ; }
    ftl::state::serialize_info() { SERIALIZE_INFO_CALLED=1 ; }
    # Reset call trackers
    CHANGE_DIR_CALLED=
    RENDER_CALLED=
    QUIT_ALL_CALLED=
    LOAD_SEL_CALLED=
    SERIALIZE_INFO_CALLED=
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# Test: empty command (literally "0") returns 1
test_dispatch_empty_returns_1() {
    if ftl::cmd::dispatch_command 0 ; then
        ftl::test::fail "empty command should return 1"
    else
        ftl::test::pass "empty command returns 1"
    fi
    ftl::test::assert_eq "" "$CHANGE_DIR_CALLED" "should not call change_dir"
    ftl::test::assert_eq "" "$RENDER_CALLED" "should not call render"
}

# Test: numeric command for a file calls render
test_dispatch_numeric_file_calls_render() {
    local tmpfile
    tmpfile=$(mktemp)
    ftl_list_entries=( "$tmpfile" )
    ftl::cmd::dispatch_command 1
    ftl::test::assert_eq "1" "$RENDER_CALLED" "render should be called for file"
    ftl::test::assert_eq "" "$CHANGE_DIR_CALLED" "change_dir should not be called for file"
    ftl::test::assert_eq "$tmpfile" "$ftl_state_cursor_index" \
        "cursor_index should be set to the file path"
    rm -f "$tmpfile"
}

# Test: numeric command for a directory calls change_dir
test_dispatch_numeric_dir_calls_change_dir() {
    local tmpdir
    tmpdir=$(mktemp -d)
    ftl_list_entries=( "$tmpdir" )
    ftl::cmd::dispatch_command 1
    ftl::test::assert_eq "1" "$CHANGE_DIR_CALLED" "change_dir should be called for dir"
    ftl::test::assert_eq "" "$RENDER_CALLED" "render should not be called for dir"
    ftl::test::assert_eq "$tmpdir" "$ftl_state_cursor_index" \
        "cursor_index should be set to the dir path"
    rmdir "$tmpdir" 2>/dev/null || rm -rf "$tmpdir"
}

# Test: numeric command returns 1 (consumes the input)
test_dispatch_numeric_returns_1() {
    local tmpfile
    tmpfile=$(mktemp)
    ftl_list_entries=( "$tmpfile" )
    if ftl::cmd::dispatch_command 1 ; then
        ftl::test::fail "numeric command should return 1"
    else
        ftl::test::pass "numeric command returns 1"
    fi
    rm -f "$tmpfile"
}

# Test: "qa" built-in calls ftl::cmd::quit_all
test_dispatch_qa_calls_quit_all() {
    ftl::cmd::dispatch_command "qa"
    ftl::test::assert_eq "1" "$QUIT_ALL_CALLED" "quit_all should be called for qa"
}

# Test: "load_sel" built-in calls ftl::sel::load_from_file
test_dispatch_load_sel_calls_load_from_file() {
    ftl::cmd::dispatch_command "load_sel"
    ftl::test::assert_eq "1" "$LOAD_SEL_CALLED" "load_from_file should be called for load_sel"
}

# Test: trie shortcut sets pending_input and returns
test_dispatch_trie_shortcut() {
    ftl_kbd_trie["x"]="my_command_fn"
    ftl::cmd::dispatch_command "x"
    ftl::test::assert_eq "my_command_fn" "$ftl_state_pending_input" \
        "pending_input should be set from trie"
    ftl::test::assert_eq "" "$SERIALIZE_INFO_CALLED" \
        "trie shortcut should not call serialize_info"
}

# Test: command_to_key shortcut sets pending_input
test_dispatch_command_to_key_shortcut() {
    ftl_kbd_command_to_key["my_cmd"]="key_seq"
    ftl::cmd::dispatch_command "my_cmd"
    ftl::test::assert_eq "key_seq" "$ftl_state_pending_input" \
        "pending_input should be set from command_to_key"
}

# Test: user command file is sourced when it exists and is not executable
test_dispatch_user_command_sourced() {
    # Create a non-executable user command file
    local user_cmd="$FTL_CFG/etc/commands/01_test_user_cmd_xyz"
    cat >"$user_cmd" <<'EOF'
USER_CMD_SOURCED=1
EOF
    chmod 644 "$user_cmd"
    ftl::cmd::dispatch_command "01_test_user_cmd_xyz"
    ftl::test::assert_eq "1" "${USER_CMD_SOURCED:-0}" \
        "user command should be sourced"
    ftl::test::assert_eq "1" "$SERIALIZE_INFO_CALLED" \
        "serialize_info should be called before user command"
    rm -f "$user_cmd"
}

# Test: quote_selection from this module's listing helpers
test_quote_selection() {
    ftl_selection_current=( "/tmp/file 1.txt" "/tmp/file2" )
    local out
    out=$(ftl::list::quote_selection)
    ftl::test::assert_contains "$out" "file\\ 1.txt" \
        "should escape spaces in selection"
    ftl::test::assert_contains "$out" "file2" "should include plain path"
}
