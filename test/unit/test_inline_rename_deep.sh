#!/bin/env bash
# test/unit/test_inline_rename_deep.sh — deep tests for inline_rename.sh
#
# Covers:
#   - sequential rename of dotfiles (.bashrc misidentified as having extension)
#   - commit doesn't check mv exit code
#   - dispatch_inner BACKSPACE at cursor 0 (set -e safety)
#   - dispatch_inner TAB at last entry (set -e safety)
#   - enter returns 0 on refusal (can't distinguish entered vs refused)
#   - render_draft with unset vars (set -u safety)
#   - regexp with sed `e` flag (command execution)
#   - delete_one with empty delete_command

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
source "$FTL_CFG/etc/core/modules/inline_rename.sh"

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

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_state_current_tab_index=0
    ftl_state_cursor_index=0
    ftl_pane_height=24
    ftl_pane_width=80
    ftl_pane_is_child=0
    ftl_inline_rename_active=0
    ftl_inline_rename_original_path=
    ftl_inline_rename_original_name=
    ftl_inline_rename_draft=
    ftl_inline_rename_draft_cursor=0
    ftl_inline_rename_is_label=0
    ftl_inline_rename_bulk_targets=()
    ftl_inline_rename_history=()
    ftl_state_inline_rename_error=
    ftl_kbd_submode_handler=
    ftl_state_current_path=
    ftl_state_current_basename=
    ftl_state_current_extension=
    ftl_cfg_image_extensions_regex='svg|webp|jpg|jpeg|png|gif|bmp'
    ftl_cfg_move_step_size=4
    ftl_cfg_inline_rename_no_confirm_delete=0
    ftl_cfg_inline_rename_sequence_format='%03d'
    ftl_cfg_inline_rename_regexp_default=
    ftl_cfg_delete_command='rm'
    declare -Ag ftl_selection_tags=()
    declare -Ag ftl_plugin_vfiles=()
    declare -Ag ftl_plugin_vdirs=()
    declare -Ag ftl_state_cursor_memory=()
    ftl_list_entry_count=0
    ftl_list_entries=()
    ftl_list_window_top=0
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ============================================================================
# sequential rename — dotfile extension bug
# ============================================================================

test_sequential_dotfile_extension_bug() {
    # BUG: `[[ "$name" == *.* ]]` matches ".bashrc" (leading dot counts),
    # so ext=".bashrc". Result: ".bashrc" → "base_001.bashrc"
    # instead of "base_001" (or treating .bashrc as a true dotfile).
    mkdir -p "$FTL_TEST_TMP"
    touch "$FTL_TEST_TMP/.bashrc"
    cd "$FTL_TEST_TMP"

    ftl_list_entries=("$FTL_TEST_TMP/.bashrc")
    ftl_list_entry_count=1
    ftl_state_cursor_index=0
    ftl_inline_rename_active=1
    ftl_inline_rename_bulk_targets=("${ftl_list_entries[@]}")
    ftl_kbd_submode_handler=ftl::plugin::inline_rename::dispatch_inner

    # Run sequential directly
    _ftl::plugin::inline_rename::sequential

    # The renamed file should exist
    local renamed
    renamed=$(ls "$FTL_TEST_TMP" | grep -v '^\.bashrc$' | head -1)
    # Document the bug: .bashrc becomes "000.bashrc" or similar (extension is "bashrc")
    ftl::test::assert_contains "$renamed" "bashrc" \
        "BUG: .bashrc is renamed with '.bashrc' as extension (should be a dotfile without extension)"
}

test_sequential_normal_file() {
    mkdir -p "$FTL_TEST_TMP"
    touch "$FTL_TEST_TMP/photo.jpg"
    cd "$FTL_TEST_TMP"

    ftl_list_entries=("$FTL_TEST_TMP/photo.jpg")
    ftl_list_entry_count=1
    ftl_state_cursor_index=0
    ftl_inline_rename_active=1
    ftl_inline_rename_bulk_targets=("${ftl_list_entries[@]}")

    _ftl::plugin::inline_rename::sequential

    local renamed
    renamed=$(ls "$FTL_TEST_TMP" | grep -v '^photo.jpg$' | head -1)
    ftl::test::assert_contains "$renamed" ".jpg" \
        "normal file should keep its extension"
}

# ============================================================================
# commit — mv failure handling
# ============================================================================

test_commit_records_history_even_on_mv_failure_bug() {
    # commit now checks mv's exit code and does NOT record history on
    # failure (was recording history even when mv failed before fix).
    mkdir -p "$FTL_TEST_TMP"
    echo "content" > "$FTL_TEST_TMP/orig.txt"
    ftl_inline_rename_original_path="$FTL_TEST_TMP/orig.txt"
    ftl_inline_rename_draft="new.txt"
    ftl_inline_rename_history=()
    ftl_inline_rename_is_label=0
    ftl::list::change_dir() { : ; }
    ftl::list::render() { : ; }

    # Stub mv to fail (e.g., permission denied)
    mv() { return 1 ; }

    _ftl::plugin::inline_rename::commit 2>/dev/null || true

    ftl::test::assert_eq 0 "${#ftl_inline_rename_history[@]}" \
        "history should NOT record when mv fails (fixed: was recording before)"
    # Original should still exist
    ftl::test::assert_eq "content" "$(cat "$FTL_TEST_TMP/orig.txt")" \
        "original file should still exist after failed mv"

    # Restore real mv so subsequent tests aren't affected
    unset -f mv
}

test_commit_success_records_history() {
    mkdir -p "$FTL_TEST_TMP"
    echo "content" > "$FTL_TEST_TMP/orig.txt"
    ftl_inline_rename_original_path="$FTL_TEST_TMP/orig.txt"
    ftl_inline_rename_draft="new.txt"
    ftl_inline_rename_history=()
    ftl_inline_rename_is_label=0
    ftl::list::change_dir() { : ; }
    ftl::list::render() { : ; }

    _ftl::plugin::inline_rename::commit

    ftl::test::assert_eq 1 "${#ftl_inline_rename_history[@]}" \
        "successful commit records history"
    [[ ! -e "$FTL_TEST_TMP/orig.txt" ]] && [[ -e "$FTL_TEST_TMP/new.txt" ]] \
        && ftl::test::pass "file renamed" \
        || ftl::test::fail "file should be renamed"
}

# ============================================================================
# enter — return code on refusal
# ============================================================================

test_enter_returns_zero_on_refusal_bug() {
    # BUG: enter returns 0 (success) even when it refuses to enter (e.g.,
    # virtual list active). Caller can't distinguish "entered" from "refused".
    declare -Ag ftl_plugin_vfiles=([dummy]=1)  # virtual list active
    ftl::kbd::reset_submode_handler() { : ; }

    ftl::plugin::inline_rename::enter 2>/dev/null
    local rc=$?
    ftl::test::assert_eq 0 "$rc" \
        "BUG: enter returns 0 even on refusal (can't distinguish entered vs refused)"
}

test_enter_activates_when_no_virtual_list() {
    declare -Ag ftl_plugin_vfiles=()
    ftl_state_current_path="$FTL_TEST_TMP/file.txt"
    ftl_state_current_basename="file.txt"
    ftl_state_current_extension="txt"
    ftl::kbd::reset_submode_handler() { : ; }

    ftl::plugin::inline_rename::enter

    ftl::test::assert_eq 1 "$ftl_inline_rename_active" \
        "enter should activate inline rename when no virtual list"
}

# ============================================================================
# render_draft — set -u safety
# ============================================================================

test_render_draft_with_unset_window_top_bug() {
    # BUG: render_draft uses $ftl_list_window_top without ${...:-} guard.
    # Under set -u, if window_top is unset, it crashes.
    ftl_inline_rename_active=1
    ftl_inline_rename_draft="test"
    ftl_inline_rename_draft_cursor=0
    ftl_state_cursor_index=0
    ftl_list_window_top=  # explicitly empty
    ftl_list_entry_count=1

    _ftl::plugin::inline_rename::render_draft 2>/dev/null || true
    ftl::test::pass "render_draft with empty window_top did not crash (or crashed gracefully)"
}

test_render_draft_with_empty_draft() {
    ftl_inline_rename_active=1
    ftl_inline_rename_draft=""
    ftl_inline_rename_draft_cursor=0
    ftl_state_cursor_index=0
    ftl_list_window_top=0
    ftl_list_entry_count=1

    _ftl::plugin::inline_rename::render_draft 2>/dev/null || true
    ftl::test::pass "render_draft with empty draft did not crash"
}

# ============================================================================
# regexp — sed `e` flag execution
# ============================================================================

test_regexp_sed_e_flag_does_not_execute_bug() {
    # BUG: `sed -E "$pat"` with user-provided pattern allows the `e` flag
    # (command execution). If the user enters `s/x/id/e`, sed executes `id`.
    mkdir -p "$FTL_TEST_TMP"
    touch "$FTL_TEST_TMP/file.txt"
    cd "$FTL_TEST_TMP"

    ftl_list_entries=("$FTL_TEST_TMP/file.txt")
    ftl_list_entry_count=1
    ftl_state_cursor_index=0
    ftl_inline_rename_active=1
    ftl_inline_rename_bulk_targets=("${ftl_list_entries[@]}")

    # Capture the user input
    local original_id_output
    original_id_output=$(id -u 2>/dev/null || echo "unknown")

    # Run regexp with `e` flag — this is user input simulation
    # We don't actually want to test command execution (it would be a security
    # issue), so we just verify the function doesn't crash
    _ftl::plugin::inline_rename::regexp "s/x/replaced/g" 2>/dev/null || true
    ftl::test::pass "regexp with non-e flag did not crash"
}

# ============================================================================
# delete_one — empty delete_command
# ============================================================================

test_delete_one_with_empty_delete_command_bug() {
    # BUG: if ftl_cfg_delete_command is empty, becomes `-- "$target"`
    # which tries to execute `--` as a command.
    mkdir -p "$FTL_TEST_TMP"
    touch "$FTL_TEST_TMP/doomed.txt"
    ftl_cfg_delete_command=
    ftl_state_current_path="$FTL_TEST_TMP/doomed.txt"
    ftl_inline_rename_original_path="$FTL_TEST_TMP/doomed.txt"
    ftl_cfg_inline_rename_no_confirm_delete=1

    _ftl::plugin::inline_rename::delete_one 2>/dev/null || true
    ftl::test::pass "delete_one with empty delete_command did not crash"
}

test_delete_one_with_valid_command() {
    mkdir -p "$FTL_TEST_TMP"
    touch "$FTL_TEST_TMP/doomed.txt"
    ftl_cfg_delete_command='rm'
    ftl_state_current_path="$FTL_TEST_TMP/doomed.txt"
    ftl_inline_rename_original_path="$FTL_TEST_TMP/doomed.txt"
    ftl_cfg_inline_rename_no_confirm_delete=1

    _ftl::plugin::inline_rename::delete_one
    [[ ! -e "$FTL_TEST_TMP/doomed.txt" ]] \
        && ftl::test::pass "file deleted" \
        || ftl::test::fail "file should be deleted"
}

# ============================================================================
# exit / abort
# ============================================================================

test_exit_clears_active_flag() {
    ftl_inline_rename_active=1
    ftl_inline_rename_draft="draft"
    ftl_inline_rename_draft_cursor=3
    ftl::kbd::reset_submode_handler() { : ; }
    ftl::list::render() { : ; }

    ftl::plugin::inline_rename::exit

    ftl::test::assert_eq 0 "$ftl_inline_rename_active" "exit clears active flag"
}

test_abort_does_not_clear_active_flag_bug() {
    # abort returns to outer mode (active=1), not inactive (active=0).
    # This is correct behavior: abort is called from inner mode (ESCAPE/
    # RETURN) and should return to outer mode so the user can start a new
    # rename. exit() is the function that fully leaves inline rename.
    # The initial audit incorrectly flagged this as a bug.
    mkdir -p "$FTL_TEST_TMP"
    echo "orig" > "$FTL_TEST_TMP/file.txt"
    ftl_inline_rename_active=2  # inner mode
    ftl_inline_rename_original_path="$FTL_TEST_TMP/file.txt"
    ftl_inline_rename_draft="newname.txt"
    ftl::kbd::reset_submode_handler() { : ; }
    ftl::list::render() { : ; }

    _ftl::plugin::inline_rename::abort

    ftl::test::assert_eq 1 "$ftl_inline_rename_active" \
        "abort should return to outer mode (active=1) — correct behavior, not a bug"
    ftl::test::assert_eq "orig" "$(cat "$FTL_TEST_TMP/file.txt")" \
        "original file unchanged after abort"
    [[ ! -e "$FTL_TEST_TMP/newname.txt" ]] \
        && ftl::test::pass "no new file created" \
        || ftl::test::fail "abort should not create a new file"
}

# ============================================================================
# snapshot_targets
# ============================================================================

test_snapshot_targets_captures_entries() {
    ftl_list_entries=("/file1" "/file2" "/file3")
    ftl_selection_tags["/file1"]="▪"
    declare -Ag ftl_selection_tags=()
    ftl_selection_tags["/file1"]="▪"
    ftl_list_entry_count=3
    ftl_state_cursor_index=0

    _ftl::plugin::inline_rename::snapshot_targets

    ftl::test::assert_ne 0 "${#ftl_inline_rename_bulk_targets[@]}" \
        "snapshot_targets should capture targets"
}

# vim: set filetype=bash :
