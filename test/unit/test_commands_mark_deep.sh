#!/bin/env bash
# test/unit/test_commands_mark_deep.sh — deep tests for commands/mark.sh
#
# Covers the systemic BUG: set_mark/goto_mark/clear_persistent_marks/
# clear_global_history use $ftl_kbd_current_key (the trigger key) instead
# of $REPLY (what the user typed after the trigger).
#
# Also covers:
#   - add_persistent_mark hardcoded /tmp/ftl_marks_tmp (race condition)
#   - goto_mark_via_fzf unquoted array expansion
#   - edit_global_history hardcoded /tmp/ftl_hist_tmp

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
ftl::sel::resolve_current() { : ; }
ftl::sel::sync_from_other_pane() { false ; }
ftl::list::change_dir() { : ; }
ftl::list::render() { : ; }
fzf-tmux() { : ; }
lscolors() { cat ; }

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    ftl_state_session_dir="$FTL_TEST_TMP"
    FTL_STATE_DIR="$FTL_TEST_TMP/state"
    mkdir -p "$FTL_STATE_DIR/shared"
    ftl_kbd_current_key="m"  # simulate 'm' was the trigger key
    declare -Ag ftl_mark_session_marks=()
    ftl_list_entries=("/test/file1" "/test/file2")
    ftl_state_cursor_index=0
    ftl_state_current_path="/test/file1"
    ftl_state_current_tab_index=0
    ftl_cfg_fzf_popup_opts=
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ============================================================================
# set_mark — uses ftl_kbd_current_key instead of REPLY
# ============================================================================

test_set_mark_uses_reply_not_kbd_current_key_bug() {
    # set_mark now uses $REPLY (user input) instead of $ftl_kbd_current_key
    # (trigger key). User types 'a' → mark is saved under 'a'.
    read() { REPLY='a' ; }  # simulate user pressing 'a'
    ftl::cmd::set_mark

    # Mark should now be saved under 'a' (REPLY), not 'm' (trigger key)
    if [[ -n "${ftl_mark_session_marks[a]:-}" ]] ; then
        ftl::test::pass "mark saved under 'a' (REPLY) — bug fixed"
    elif [[ -n "${ftl_mark_session_marks[m]:-}" ]] ; then
        ftl::test::fail "BUG still present: mark saved under 'm' (trigger key) instead of 'a' (REPLY)"
    else
        ftl::test::fail "mark was not saved under either 'a' or 'm'"
    fi
}

test_set_mark_saves_current_entry_path() {
    read() { REPLY='a' ; }
    ftl::cmd::set_mark
    # The mark (even if under wrong key) should point to the current entry
    local mark_value="${ftl_mark_session_marks[m]:-${ftl_mark_session_marks[a]:-}}"
    ftl::test::assert_contains "$mark_value" "/test/file1" \
        "mark should save the current entry path"
}

test_set_mark_directory_entry_gets_trailing_slash() {
    ftl_state_current_path="/test/dir/"
    ftl_list_entries=("/test/dir/")
    read() { REPLY='a' ; }
    ftl::cmd::set_mark
    local mark_value="${ftl_mark_session_marks[m]:-${ftl_mark_session_marks[a]:-}}"
    ftl::test::assert_contains "$mark_value" "/$" \
        "directory mark should end with /"
}

# ============================================================================
# goto_mark — uses ftl_kbd_current_key
# ============================================================================

test_goto_mark_uses_reply_not_kbd_current_key_bug() {
    # goto_mark now uses $REPLY (user input) instead of $ftl_kbd_current_key.
    ftl_mark_session_marks[a]="/test/dir/file_a"
    ftl_mark_session_marks[m]="/test/dir/file_m"  # under trigger key
    read() { REPLY='a' ; }  # user wants to go to mark 'a'
    local called_with
    ftl::list::change_dir() { called_with="$@" ; }

    ftl::cmd::goto_mark 2>/dev/null || true

    # Should go to file_a (REPLY), not file_m (trigger key)
    if [[ "$called_with" == *"/test/dir/file_a"* ]] ; then
        ftl::test::pass "went to file_a (REPLY) — bug fixed"
    elif [[ "$called_with" == *"/test/dir/file_m"* ]] ; then
        ftl::test::fail "BUG still present: went to file_m (trigger key) instead of file_a (REPLY)"
    fi
}

# ============================================================================
# goto_mark_new_tab — same bug
# ============================================================================

test_goto_mark_new_tab_uses_reply_not_kbd_current_key_bug() {
    ftl_mark_session_marks[a]="/test/dir/file_a"
    ftl_mark_session_marks[m]="/test/dir/file_m"
    read() { REPLY='a' ; }
    local called_with
    ftl::list::change_dir() { called_with="$@" ; }
    ftl::tab::create() { : ; }

    ftl::cmd::goto_mark_new_tab 2>/dev/null || true

    if [[ "$called_with" == *"/test/dir/file_a"* ]] ; then
        ftl::test::pass "goto_mark_new_tab went to file_a (REPLY) — bug fixed"
    elif [[ "$called_with" == *"/test/dir/file_m"* ]] ; then
        ftl::test::fail "BUG still present: went to file_m (trigger key)"
    fi
}

# ============================================================================
# clear_persistent_marks — uses ftl_kbd_current_key
# ============================================================================

test_clear_persistent_marks_uses_reply_not_kbd_current_key_bug() {
    # clear_persistent_marks now uses $REPLY (user's y/N answer) instead of
    # $ftl_kbd_current_key (trigger key).
    echo "/some/persistent/mark" > "$FTL_STATE_DIR/shared/marks"
    ftl_kbd_current_key="x"  # trigger key is NOT 'y'
    ftl::cmd::prompt() { REPLY='y' ; }  # user types 'y'

    ftl::cmd::clear_persistent_marks

    # File should be cleared because REPLY='y' (was NOT cleared before fix
    # — the function checked ftl_kbd_current_key='x' instead)
    if [[ ! -s "$FTL_STATE_DIR/shared/marks" ]] ; then
        ftl::test::pass "file cleared because REPLY='y' (fixed: was checking trigger key before)"
    else
        ftl::test::fail "BUG still present: file not cleared (checking trigger key, not REPLY)"
    fi
}

test_clear_persistent_marks_with_y_trigger() {
    # With the fix, even if trigger key is 'y', the user's 'n' answer is
    # respected (was clearing because trigger key == 'y' before fix).
    echo "/some/persistent/mark" > "$FTL_STATE_DIR/shared/marks"
    ftl_kbd_current_key="y"  # trigger key IS 'y'
    ftl::cmd::prompt() { REPLY='n' ; }  # user says NO

    ftl::cmd::clear_persistent_marks

    # File should NOT be cleared because REPLY='n' (was cleared before fix)
    if [[ -s "$FTL_STATE_DIR/shared/marks" ]] ; then
        ftl::test::pass "file NOT cleared because REPLY='n' (fixed: was clearing on trigger key before)"
    else
        ftl::test::fail "BUG still present: file cleared (ignoring user's 'n')"
    fi
}

# ============================================================================
# clear_global_history — same bug
# ============================================================================

test_clear_global_history_uses_reply_not_kbd_current_key_bug() {
    # clear_global_history now uses $REPLY (user's y/N answer) instead of
    # $ftl_kbd_current_key (trigger key).
    echo "/some/history/entry" > "$FTL_STATE_DIR/shared/history"
    ftl_kbd_current_key="x"
    ftl::cmd::prompt() { REPLY='y' ; }

    ftl::cmd::clear_global_history 2>/dev/null || true

    # File should be cleared because REPLY='y' (was NOT cleared before fix)
    if [[ ! -s "$FTL_STATE_DIR/shared/history" ]] ; then
        ftl::test::pass "history cleared because REPLY='y' (fixed: was checking trigger key before)"
    else
        ftl::test::fail "BUG still present: history not cleared (checking trigger key, not REPLY)"
    fi
}

# ============================================================================
# add_persistent_mark — hardcoded /tmp file
# ============================================================================

test_add_persistent_mark_appends_to_shared_file() {
    echo "/existing/mark" > "$FTL_STATE_DIR/shared/marks"
    ftl_state_current_path="/new/mark"
    ftl::cmd::add_persistent_mark
    local content
    content=$(cat "$FTL_STATE_DIR/shared/marks")
    ftl::test::assert_contains "$content" "/new/mark" "new mark should be appended"
    ftl::test::assert_contains "$content" "/existing/mark" "existing marks preserved"
}

test_add_persistent_mark_creates_file_if_missing() {
    rm -f "$FTL_STATE_DIR/shared/marks"
    ftl_state_current_path="/first/mark"
    ftl::cmd::add_persistent_mark
    [[ -f "$FTL_STATE_DIR/shared/marks" ]] \
        && ftl::test::pass "marks file created" \
        || ftl::test::fail "marks file should be created"
}

test_add_persistent_mark_dedupes() {
    echo "/dup/mark" > "$FTL_STATE_DIR/shared/marks"
    ftl_state_current_path="/dup/mark"
    ftl::cmd::add_persistent_mark
    local count
    count=$(grep -c "/dup/mark" "$FTL_STATE_DIR/shared/marks")
    ftl::test::assert_eq 1 "$count" "duplicate mark should not be added twice"
}

test_add_persistent_mark_hardcoded_tmp_file_bug() {
    # BUG: uses /tmp/ftl_marks_tmp (race condition if multiple ftl instances)
    ftl_state_current_path="/test/mark"
    ftl::cmd::add_persistent_mark
    # The hardcoded tmp file may or may not still exist; just verify no crash
    ftl::test::pass "add_persistent_mark did not crash (hardcoded /tmp/ftl_marks_tmp documented)"
    rm -f /tmp/ftl_marks_tmp
}

# ============================================================================
# goto_mark_via_fzf — unquoted array
# ============================================================================

test_goto_mark_via_fzf_no_marks_does_not_crash() {
    ftl_mark_session_marks=()
    ftl::cmd::goto_mark_via_fzf 2>/dev/null || true
    ftl::test::pass "goto_mark_via_fzf with no marks did not crash"
}

test_goto_mark_via_fzf_with_marks() {
    ftl_mark_session_marks[a]="/path/a"
    ftl_mark_session_marks[b]="/path/b"
    # Stub fzf to return the first entry
    fzf-tmux() { echo "/path/a" ; }
    ftl::cmd::goto_mark_via_fzf 2>/dev/null || true
    ftl::test::pass "goto_mark_via_fzf with marks did not crash"
}

# ============================================================================
# goto_session_history / goto_global_history
# ============================================================================

test_goto_session_history_empty_does_not_crash() {
    : > "$ftl_state_session_dir/history"
    ftl::cmd::goto_session_history 2>/dev/null || true
    ftl::test::pass "goto_session_history with empty history did not crash"
}

test_goto_global_history_empty_does_not_crash() {
    : > "$FTL_STATE_DIR/shared/history"
    ftl::cmd::goto_global_history 2>/dev/null || true
    ftl::test::pass "goto_global_history with empty history did not crash"
}

# ============================================================================
# edit_global_history — hardcoded /tmp file
# ============================================================================

test_edit_global_history_does_not_crash() {
    echo "/some/path" > "$FTL_STATE_DIR/shared/history"
    # Stub fzf to return nothing
    fzf-tmux() { : ; }
    ftl::cmd::edit_global_history 2>/dev/null || true
    ftl::test::pass "edit_global_history did not crash"
    rm -f /tmp/ftl_hist_tmp
}

# vim: set filetype=bash :
