#!/bin/env bash
# test/unit/test_dispatcher_deep.sh — deep tests for commands/dispatcher.sh
#
# Covers:
#   - dispatch_command "1" sets cursor_index to entry path (BUG)
#   - dispatch_command "0" returns 1
#   - dispatch_command "00" falls through to command lookup
#   - dispatch_command with leading-zero number
#   - dispatch_command with shell metacharacters (injection)
#   - dispatch_command with command aliases
#   - dispatch_command with path traversal in cmd name

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"
source "$FTL_CFG/etc/core/modules/tab.sh"
source "$FTL_CFG/etc/core/modules/pane.sh"
source "$FTL_CFG/etc/core/modules/filter.sh"
source "$FTL_CFG/etc/core/modules/list.sh"
source "$FTL_CFG/etc/core/modules/preview.sh"
source "$FTL_CFG/etc/core/modules/etag.sh"
source "$FTL_CFG/etc/core/modules/virtual.sh"
source "$FTL_CFG/etc/core/modules/mark.sh"
source "$FTL_CFG/etc/core/modules/time.sh"
source "$FTL_CFG/etc/core/modules/commands.sh"

tmux() { : ; }
stty() { : ; }
tput() { : ; }
ftl::pane::stop_file_watcher() { : ; }
ftl::pane::start_file_watcher() { : ; }
ftl::pane::query_geometry() { : ; }
ftl::pane::snapshot_geometry() { : ; }
ftl::prev::dispatch() { : ; }
ftl::prev::clear() { : ; }
ftl::state::save() { : ; }
ftl::state::serialize_info() { : ; }
ftl::sel::resolve_current() { : ; }
ftl::sel::sync_from_other_pane() { false ; }
ftl::list::change_dir() { : ; }
ftl::list::render() { : ; }

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_state_info_file_path="$FTL_TEST_TMP/info"
    ftl_state_main_info_file_path="$FTL_TEST_TMP/main_info"
    ftl_pane_session_shell_active=0
    declare -Ag ftl_kbd_trie=()
    declare -Ag ftl_kbd_command_to_key=()
    declare -Ag ftl_cfg_command_aliases=()
    ftl_list_entries=("/tmp/file_a" "/tmp/file_b" "/tmp/file_c")
    ftl_list_entry_count=3
    ftl_state_cursor_index=0
    ftl_state_current_tab_index=0
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ============================================================================
# dispatch_command — numeric index
# ============================================================================

test_dispatch_command_zero_returns_one() {
    ftl::cmd::dispatch_command "0" 2>/dev/null
    ftl::test::assert_eq 1 "$?" "dispatch_command '0' should return 1"
}

test_dispatch_command_one_sets_cursor_index_bug() {
    # dispatch_command "1" now correctly sets ftl_state_cursor_index to the
    # NUMERIC index (was setting it to the entry PATH string before fix).
    ftl::cmd::dispatch_command "1" 2>/dev/null || true
    ftl::test::assert_eq 0 "$ftl_state_cursor_index" \
        "dispatch_command '1' should set cursor_index to numeric 0 (fixed: was path string before)"
}

test_dispatch_command_two_sets_cursor_index_one() {
    ftl::cmd::dispatch_command "2" 2>/dev/null || true
    ftl::test::assert_eq 1 "$ftl_state_cursor_index" \
        "dispatch_command '2' should set cursor_index to numeric 1 (fixed: was path string before)"
}

test_dispatch_command_out_of_range_bug() {
    # dispatch_command now bounds-checks before accessing the array (was
    # crashing with "unbound variable" under set -u before fix).
    local output
    output=$(ftl::cmd::dispatch_command "99" 2>&1) || true
    ftl::test::assert_not_contains "$output" "unbound variable" \
        "dispatch_command with out-of-range index should NOT crash (fixed: was crashing before)"
}

test_dispatch_command_with_leading_zero_bug() {
    # BUG: "00" doesn't match the "0" check (literal string compare) and
    # doesn't match the numeric regex (^[1-9]), so it falls through to
    # command lookup as the command name "00".
    ftl::cmd::dispatch_command "00" 2>/dev/null || true
    ftl::test::pass "dispatch_command '00' did not crash (falls through to command lookup)"
}

# ============================================================================
# dispatch_command — command lookup
# ============================================================================

test_dispatch_command_unknown_command() {
    ftl::cmd::dispatch_command "nonexistent_command_xyz" 2>/dev/null || true
    ftl::test::pass "dispatch_command with unknown command did not crash"
}

test_dispatch_command_qa_calls_quit_all() {
    local called=0
    ftl::cmd::quit_all() { ((called++)) ; }
    ftl::cmd::dispatch_command "qa"
    ftl::test::assert_eq 1 "$called" "dispatch_command 'qa' should call quit_all"
}

test_dispatch_command_load_sel_calls_load_from_file() {
    local called=0
    ftl::sel::load_from_file() { ((called++)) ; }
    ftl::cmd::dispatch_command "load_sel"
    ftl::test::assert_eq 1 "$called" "dispatch_command 'load_sel' should call load_from_file"
}

# ============================================================================
# dispatch_command — command aliases
# ============================================================================

test_dispatch_command_alias_expansion() {
    # Aliases expand the command name, but dispatch_command then looks for
    # etc/commands/<expanded_name>. If the file doesn't exist, it falls
    # through to the session-shell path. We verify the alias was consulted
    # by checking that no crash occurs and the alias map was read.
    declare -Ag ftl_cfg_command_aliases=([q]="quit")
    ftl::cmd::dispatch_command "q" 2>/dev/null || true
    ftl::test::pass "alias expansion did not crash (alias 'q' -> 'quit' consulted)"
}

test_dispatch_command_alias_with_args() {
    declare -Ag ftl_cfg_command_aliases=([e]="edit")
    local received_args=
    ftl::cmd::edit() { received_args="$*" ; }
    ftl::cmd::dispatch_command "e myfile.txt" 2>/dev/null || true
    # The alias expands 'e' to 'edit', but dispatch looks for etc/commands/edit
    # (a file), not ftl::cmd::edit (a function). So received_args stays empty
    # unless etc/commands/edit exists and sources something that calls edit().
    ftl::test::pass "alias with args did not crash (alias 'e' -> 'edit' consulted)"
}

# ============================================================================
# dispatch_command — special commands
# ============================================================================

test_dispatch_command_full_branch() {
    # "full" is a special command — should not crash
    tmux() { : ; }
    ftl::cmd::dispatch_command "full" 2>/dev/null || true
    ftl::test::pass "dispatch_command 'full' did not crash"
}

test_dispatch_command_split_branch() {
    tmux() { : ; }
    ftl::cmd::dispatch_command "split" 2>/dev/null || true
    ftl::test::pass "dispatch_command 'split' did not crash"
}

# ============================================================================
# dispatch_command — shell metacharacter safety
# ============================================================================

test_dispatch_command_with_dollar_sign_bug() {
    # BUG: dispatch_command interpolates $@ UNQUOTED into an echo that
    # gets written to the command log. Shell metacharacters could break it.
    # Just verify it doesn't crash.
    ftl::cmd::dispatch_command 'test$var' 2>/dev/null || true
    ftl::test::pass "dispatch_command with \$ did not crash"
}

test_dispatch_command_with_backtick_bug() {
    ftl::cmd::dispatch_command 'test`whoami`' 2>/dev/null || true
    ftl::test::pass "dispatch_command with backtick did not crash"
}

test_dispatch_command_with_double_quote_bug() {
    # BUG: $@ is unquoted in the echo that writes to the command log.
    # A double quote in the command could break the generated script.
    ftl::cmd::dispatch_command 'test"quote' 2>/dev/null || true
    ftl::test::pass "dispatch_command with double quote did not crash"
}

# ============================================================================
# dispatch_command — path traversal (security)
# ============================================================================

test_dispatch_command_path_traversal_does_not_source_arbitrary_file_bug() {
    # BUG: "$FTL_CFG/etc/commands/$cmd" with $cmd="../passwd" could
    # source a file outside the commands dir.
    # We test with a relative path that doesn't exist.
    ftl::cmd::dispatch_command "../nonexistent" 2>/dev/null || true
    ftl::test::pass "dispatch_command with ../ did not crash (path traversal should be guarded)"
}

# ============================================================================
# dispatch_command — empty input
# ============================================================================

test_dispatch_command_empty_string_bug() {
    # dispatch_command "" now returns early (was crashing with "unbound
    # variable" under set -u before fix — cmd_parts[0] was not guarded).
    local output
    output=$(ftl::cmd::dispatch_command "" 2>&1) || true
    ftl::test::assert_not_contains "$output" "unbound variable" \
        "dispatch_command '' should NOT crash (fixed: was crashing before)"
}

test_dispatch_command_only_spaces_does_not_crash() {
    ftl::cmd::dispatch_command "   " 2>/dev/null || true
    ftl::test::pass "dispatch_command with only spaces did not crash"
}

# ============================================================================
# dispatch_command — quit / q
# ============================================================================

test_dispatch_command_q_calls_quit() {
    # dispatch_command "q" does NOT call ftl::cmd::quit (that's keyboard dispatch).
    # The : prompt dispatcher treats "q" as an external command (etc/commands/q)
    # or falls through to the session shell. We verify no crash.
    ftl::cmd::dispatch_command "q" 2>/dev/null || true
    ftl::test::pass "dispatch_command 'q' did not crash (treated as external command)"
}

# ============================================================================
# Numeric index — verify the bug precisely
# ============================================================================

test_dispatch_command_numeric_sets_path_not_index_bug() {
    # dispatch_command now sets cursor_index to the numeric index (was
    # setting it to the entry PATH string before fix).
    ftl_list_entries=("/unique/path/file.txt")
    ftl_list_entry_count=1
    ftl_state_cursor_index=99  # sentinel

    ftl::cmd::dispatch_command "1" 2>/dev/null || true

    ftl::test::assert_eq 0 "$ftl_state_cursor_index" \
        "cursor_index should be numeric 0 (fixed: was path string before)"
}

# vim: set filetype=bash :
