#!/bin/env bash
# test/unit/test_inline_rename.sh — tests for the inline_rename module
#
# Tests ftl::plugin::inline_rename::enter, ::exit, ::dispatch, and the
# private helpers (_ftl::plugin::inline_rename::*).
#
# Strategy: source the module under test, set up minimal state, call the
# dispatch function with a fake ftl_kbd_current_key, and assert on the
# resulting module state. Heavy I/O functions (ftl::list::render,
# ftl::list::change_dir, ftl::cmd::prompt, ftl::cmd::cursor_up, etc.)
# are stubbed to no-op or to mutate state predictably.

FTL_CFG="/home/z/my-project/ftl-work/config/ftl"
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
source "$FTL_CFG/etc/bindings/inline_rename"

# Stub heavy I/O functions. These are redefined AFTER sourcing the module
# so the stubs win over the originals.
ftl::list::render() {
        # Sync cursor_index from cursor_memory, mirroring the real render (list.sh:355-360)
        if [[ -n "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]:-}" ]] ; then
                ftl_state_cursor_index="${ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]}"
        fi
        (( ftl_list_entry_count )) && (( ftl_state_cursor_index > ftl_list_entry_count - 1 )) \
                && ftl_state_cursor_index=$(( ftl_list_entry_count - 1 ))
        (( ftl_state_cursor_index < 0 )) && ftl_state_cursor_index=0
}
ftl::list::change_dir() {
        # Update current_path/basename from cursor index, like the real one
        if (( ftl_list_entry_count )) ; then
                local idx=${ftl_state_cursor_index:-0}
                (( idx >= ftl_list_entry_count )) && idx=$(( ftl_list_entry_count - 1 ))
                (( idx < 0 )) && idx=0
                ftl_state_current_path="${ftl_list_entries[$idx]}"
                ftl_state_current_basename="${ftl_state_current_path##*/}"
        fi
}
ftl::pane::stop_file_watcher() { : ; }
ftl::pane::start_file_watcher() { : ; }
ftl::pane::query_geometry() { : ; }
ftl::pane::snapshot_geometry() { : ; }
ftl::pane::pid_to_id() { echo "%0" ; }
ftl::prev::dispatch() { : ; }
ftl::prev::clear() { : ; }
tmux() { : ; }
stty() { : ; }
tput() { : ; }

# Stub prompt: sets REPLY from $FTL_TEST_FAKE_REPLY
FTL_TEST_FAKE_REPLY=
ftl::cmd::prompt() {
        REPLY="$FTL_TEST_FAKE_REPLY"
}

# Stub cursor_up/down to just move the index (the real one calls render)
ftl::cmd::cursor_up() {
        if (( ftl_list_entry_count )) ; then
                (( ftl_state_cursor_index > 0 )) && (( ftl_state_cursor_index-- ))
                ftl_state_current_path="${ftl_list_entries[$ftl_state_cursor_index]}"
                ftl_state_current_basename="${ftl_state_current_path##*/}"
        fi
}
ftl::cmd::cursor_down() {
        if (( ftl_list_entry_count )) ; then
                (( ftl_state_cursor_index < ftl_list_entry_count - 1 )) && (( ftl_state_cursor_index++ ))
                ftl_state_current_path="${ftl_list_entries[$ftl_state_cursor_index]}"
                ftl_state_current_basename="${ftl_state_current_path##*/}"
        fi
}

ftl::test::setup() {
        ftl_state_session_dir=$(mktemp -d)
        mkdir -p "$ftl_state_session_dir/prev"
        ftl_state_current_tab_index=0
        ftl_state_cursor_index=0
        ftl_state_current_path=
        ftl_state_current_dir=
        ftl_state_current_basename=
        ftl_state_current_extension=
        ftl_list_entries=()
        ftl_list_entry_count=0
        ftl_list_window_top=0
        ftl_list_window_bottom=0
        declare -Ag ftl_selection_tags=()
        ftl_selection_tags=()
        ftl_selection_current=()
        ftl_kbd_current_key=
        ftl_kbd_submode_handler=
        ftl_cfg_move_step_size=4
        ftl_cfg_inline_rename_sequence_format='%03d'
        ftl_cfg_inline_rename_regexp_default='s/OLD/NEW/'
        ftl_cfg_inline_rename_no_confirm_delete=0
        ftl_cfg_delete_command='rm -f'
        ftl_cfg_image_extensions=(jpg jpeg png gif tiff tif bmp webp heic)
        ftl_cfg_glyph_inline_rename='[R]'
        ftl_cfg_glyph_inline_rename_edit='[R*]'
        declare -Ag ftl_state_cursor_memory=()
        declare -Ag ftl_plugin_vfiles=()
        declare -Ag ftl_plugin_vdirs=()
        declare -Ag ftl_kbd_trie=()
        declare -Ag ftl_kbd_command_to_key=()
        declare -Ag ftl_kbd_bindings_display=()
        ftl_selection_revision=0
        ftl_selection_total_bytes=0
        ftl_selection_other_revision=0
        ftl_selection_class_cursor=0
        declare -Ag ftl_selection_class_index=()
        ftl_inline_rename_active=0
        ftl_inline_rename_original_path=
        ftl_inline_rename_original_name=
        ftl_inline_rename_draft=
        ftl_inline_rename_draft_cursor=0
        ftl_inline_rename_is_label=0
        ftl_inline_rename_history=()
        ftl_inline_rename_bulk_targets=()
        ftl_state_inline_rename_error=
        FTL_TEST_FAKE_REPLY=
}

ftl::test::teardown() {
        rm -rf "$ftl_state_session_dir" 2>/dev/null
}

# Helper: simulate a keypress in the current sub-mode
press() {
        ftl_kbd_current_key="$1"
        # Suppress render_draft output (terminal escape sequences) during tests
        ftl::plugin::inline_rename::dispatch >/dev/null 2>&1
}

# Helper: set up a fake listing of regular files in a temp dir.
# Args: filenames (relative to the temp dir)
setup_listing() {
        local f
        for f in "$@" ; do
                touch "$ftl_state_session_dir/$f"
                ftl_list_entries+=( "$ftl_state_session_dir/$f" )
        done
        ftl_list_entry_count=${#ftl_list_entries[@]}
        ftl_state_cursor_index=0
        ftl_state_current_path="${ftl_list_entries[0]}"
        ftl_state_current_dir="$ftl_state_session_dir"
        ftl_state_current_basename="${ftl_state_current_path##*/}"
        # Set extension if applicable
        if [[ "$ftl_state_current_basename" == *.* ]] ; then
                ftl_state_current_extension="${ftl_state_current_basename##*.}"
        else
                ftl_state_current_extension=
        fi
}

#==== Phase 1: enter / exit / dispatch routing ====

test_enter_sets_submode_handler() {
        ftl::plugin::inline_rename::enter
        ftl::test::assert_eq "ftl::plugin::inline_rename::dispatch" \
                "$ftl_kbd_submode_handler" "submode handler set on enter"
}

test_enter_sets_active_flag() {
        ftl::plugin::inline_rename::enter
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "active=1 (outer) after enter"
}

test_exit_clears_submode_handler() {
        ftl::plugin::inline_rename::enter
        ftl::plugin::inline_rename::exit
        ftl::test::assert_eq "" "$ftl_kbd_submode_handler" "submode handler cleared on exit"
}

test_exit_clears_active_flag() {
        ftl::plugin::inline_rename::enter
        ftl::plugin::inline_rename::exit
        ftl::test::assert_eq "0" "$ftl_inline_rename_active" "active=0 after exit"
}

test_exit_clears_state() {
        ftl::plugin::inline_rename::enter
        ftl_inline_rename_draft="abc"
        ftl_inline_rename_original_path="/tmp/x"
        ftl::plugin::inline_rename::exit
        ftl::test::assert_eq "" "$ftl_inline_rename_draft" "draft cleared"
        ftl::test::assert_eq "" "$ftl_inline_rename_original_path" "original_path cleared"
}

test_enter_refuses_in_virtual_list() {
        declare -gA ftl_plugin_vfiles=( [vfile1]=1 )
        ftl::plugin::inline_rename::enter
        ftl::test::assert_eq "" "$ftl_kbd_submode_handler" "no submode in virtual list"
        ftl::test::assert_eq "0" "$ftl_inline_rename_active" "not active in virtual list"
}

test_dispatch_timeout_ignored() {
        ftl::plugin::inline_rename::enter
        ftl_kbd_current_key="ERROR_142"
        ftl::plugin::inline_rename::dispatch
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "ERROR_ key leaves state unchanged"
}

test_binding_registered() {
        # Re-bind here since setup() clears the trie
        source "$FTL_CFG/etc/bindings/inline_rename"
        ftl::test::assert_eq "ftl::plugin::inline_rename::enter" \
                "${ftl_kbd_trie[LEADERri]:-}" "LEADER r i bound to enter"
}

#==== Phase 1: outer navigation ====

test_outer_up_moves_cursor() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl_state_cursor_index=2
        ftl::plugin::inline_rename::enter
        press UP
        ftl::test::assert_eq "1" "$ftl_state_cursor_index" "UP decrements cursor"
}

test_outer_k_moves_cursor() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl_state_cursor_index=2
        ftl::plugin::inline_rename::enter
        press k
        ftl::test::assert_eq "1" "$ftl_state_cursor_index" "k decrements cursor"
}

test_outer_down_moves_cursor() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl_state_cursor_index=0
        ftl::plugin::inline_rename::enter
        press DOWN
        ftl::test::assert_eq "1" "$ftl_state_cursor_index" "DOWN increments cursor"
}

test_outer_j_moves_cursor() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl_state_cursor_index=0
        ftl::plugin::inline_rename::enter
        press j
        ftl::test::assert_eq "1" "$ftl_state_cursor_index" "j increments cursor"
}

test_outer_home_jumps_to_first() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl_state_cursor_index=2
        ftl::plugin::inline_rename::enter
        press HOME
        ftl::test::assert_eq "0" "$ftl_state_cursor_index" "HOME jumps to 0"
}

test_outer_g_jumps_to_first() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl_state_cursor_index=2
        ftl::plugin::inline_rename::enter
        press g
        ftl::test::assert_eq "0" "$ftl_state_cursor_index" "g jumps to 0"
}

test_outer_end_jumps_to_last() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl_state_cursor_index=0
        ftl::plugin::inline_rename::enter
        press END
        ftl::test::assert_eq "2" "$ftl_state_cursor_index" "END jumps to last"
}

test_outer_G_jumps_to_last() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl_state_cursor_index=0
        ftl::plugin::inline_rename::enter
        press G
        ftl::test::assert_eq "2" "$ftl_state_cursor_index" "G jumps to last"
}

test_outer_space_toggles_selection() {
        setup_listing "a.txt" "b.txt"
        ftl::plugin::inline_rename::enter
        press SPACE
        ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "SPACE tags 1 entry"
}

test_outer_t_toggles_selection() {
        setup_listing "a.txt" "b.txt"
        ftl::plugin::inline_rename::enter
        press t
        ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "t tags 1 entry"
}

test_outer_tab_toggles_and_advances() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl::plugin::inline_rename::enter
        press TAB
        ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "TAB tagged entry 0"
        ftl::test::assert_eq "1" "$ftl_state_cursor_index" "TAB advanced cursor to 1"
}

test_outer_escape_exits() {
        setup_listing "a.txt"
        ftl::plugin::inline_rename::enter
        press ESCAPE
        ftl::test::assert_eq "0" "$ftl_inline_rename_active" "ESCAPE exits mode"
        ftl::test::assert_eq "" "$ftl_kbd_submode_handler" "ESCAPE clears submode"
}

test_outer_q_exits() {
        setup_listing "a.txt"
        ftl::plugin::inline_rename::enter
        press q
        ftl::test::assert_eq "0" "$ftl_inline_rename_active" "q exits mode"
}

test_outer_unknown_key_ignored() {
        setup_listing "a.txt"
        ftl::plugin::inline_rename::enter
        # F1 is not in the outer-mode keymap, so it should be ignored
        press F1
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "unknown key keeps mode active"
}

test_outer_enter_begins_edit() {
        setup_listing "oldname.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        ftl::test::assert_eq "2" "$ftl_inline_rename_active" "ENTER enters inner mode"
        ftl::test::assert_eq "oldname.txt" "$ftl_inline_rename_draft" "draft pre-filled with basename"
}

test_outer_letter_begins_edit_with_letter() {
        setup_listing "oldname.txt"
        ftl::plugin::inline_rename::enter
        press a
        ftl::test::assert_eq "2" "$ftl_inline_rename_active" "letter enters inner mode"
        ftl::test::assert_eq "a" "$ftl_inline_rename_draft" "draft starts with the letter"
}

#==== Phase 2: inner mode editing ====

test_inner_letter_appends() {
        setup_listing "old.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press x
        ftl::test::assert_eq "old.txtx" "$ftl_inline_rename_draft" "letter appended"
}

test_inner_backspace_removes() {
        setup_listing "old.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press BACKSPACE
        ftl::test::assert_eq "old.tx" "$ftl_inline_rename_draft" "backspace removed last char"
}

test_inner_ctl_u_clears() {
        setup_listing "old.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-U
        ftl::test::assert_eq "" "$ftl_inline_rename_draft" "CTL-U cleared draft"
        ftl::test::assert_eq "0" "$ftl_inline_rename_draft_cursor" "cursor at 0"
}

test_inner_ctl_w_deletes_word() {
        setup_listing "x.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-U
        # Type "foo bar baz"
        for c in f o o ' ' b a r ' ' b a z ; do press "$c" ; done
        press CTL-W
        # ${draft% *} removes the shortest suffix matching " *", which is " baz"
        ftl::test::assert_eq "foo bar" "$ftl_inline_rename_draft" "CTL-W removed last word"
}

test_inner_ctl_a_moves_to_start() {
        setup_listing "abc.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-A
        ftl::test::assert_eq "0" "$ftl_inline_rename_draft_cursor" "CTL-A moves cursor to 0"
}

test_inner_ctl_e_moves_to_end() {
        setup_listing "abc.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-A  # move to start
        press CTL-E  # move to end
        ftl::test::assert_eq "${#ftl_inline_rename_draft}" "$ftl_inline_rename_draft_cursor" "CTL-E moves cursor to end"
}

test_inner_home_moves_to_start() {
        setup_listing "abc.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press HOME
        ftl::test::assert_eq "0" "$ftl_inline_rename_draft_cursor" "HOME moves cursor to 0"
}

test_inner_end_moves_to_end() {
        setup_listing "abc.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press HOME
        press END
        ftl::test::assert_eq "${#ftl_inline_rename_draft}" "$ftl_inline_rename_draft_cursor" "END moves cursor to end"
}

test_inner_escape_aborts() {
        setup_listing "old.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press x
        press ESCAPE
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "ESCAPE returns to outer mode"
        ftl::test::assert_eq "" "$ftl_inline_rename_draft" "draft cleared on abort"
}

test_inner_return_empty_draft_aborts() {
        setup_listing "old.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-U  # clear draft
        press RETURN
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "RETURN on empty draft aborts"
        [[ -e "$ftl_state_session_dir/old.txt" ]] \
                && ftl::test::pass "original file intact" \
                || ftl::test::fail "original file missing"
}

test_inner_return_same_name_aborts() {
        setup_listing "old.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press RETURN
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "RETURN on unchanged name aborts"
}

test_inner_return_commits() {
        setup_listing "old.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-U
        for c in n e w ; do press "$c" ; done
        press RETURN
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "RETURN commits and returns to outer"
        [[ -e "$ftl_state_session_dir/new" ]] \
                && ftl::test::pass "file renamed" \
                || ftl::test::fail "file not renamed"
        [[ ! -e "$ftl_state_session_dir/old.txt" ]] \
                && ftl::test::pass "old name gone" \
                || ftl::test::fail "old name still exists"
}

test_inner_return_target_exists_refuses() {
        setup_listing "old.txt" "new"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-U
        for c in n e w ; do press "$c" ; done
        press RETURN
        ftl::test::assert_eq "2" "$ftl_inline_rename_active" "stays in inner mode on conflict"
        [[ -e "$ftl_state_session_dir/old.txt" ]] \
                && ftl::test::pass "original intact on conflict" \
                || ftl::test::fail "original lost on conflict"
}

test_inner_non_printable_ignored() {
        setup_listing "old.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press F1
        ftl::test::assert_eq "old.txt" "$ftl_inline_rename_draft" "F1 ignored in inner mode"
}

test_inner_insert_in_middle() {
        # Type "abc", move to start, type "X" → should be "Xabc"
        setup_listing "abc.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-A
        press X
        ftl::test::assert_eq "Xabc.txt" "$ftl_inline_rename_draft" "X inserted at start"
        ftl::test::assert_eq "1" "$ftl_inline_rename_draft_cursor" "cursor advanced past X"
}

#==== Phase 3: TAB flow (commit + advance) ====

test_inner_tab_commits_and_advances() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl::plugin::inline_rename::enter
        # Edit first entry to "aaa"
        press ENTER
        press CTL-U
        for c in a a a ; do press "$c" ; done
        press TAB
        # After TAB: file a.txt renamed to aaa, cursor on b.txt, in inner mode
        # begin_edit("") pre-fills with the new entry's basename
        ftl::test::assert_eq "2" "$ftl_inline_rename_active" "TAB moves to inner mode on next entry"
        ftl::test::assert_eq "1" "$ftl_state_cursor_index" "cursor advanced to next entry"
        ftl::test::assert_eq "b.txt" "$ftl_inline_rename_draft" "draft pre-filled with next entry's basename"
        [[ -e "$ftl_state_session_dir/aaa" ]] \
                && ftl::test::pass "first file renamed by TAB" \
                || ftl::test::fail "first file not renamed by TAB"
}

test_inner_tab_on_last_entry_commits_only() {
        setup_listing "a.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-U
        for c in z z z ; do press "$c" ; done
        press TAB
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "TAB on last entry returns to outer"
        [[ -e "$ftl_state_session_dir/zzz" ]] \
                && ftl::test::pass "last entry renamed" \
                || ftl::test::fail "last entry not renamed"
}

#==== Phase 4: sequential rename ====

test_snapshot_targets_uses_selection() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl::sel::set "$ftl_state_session_dir/a.txt"
        ftl::sel::set "$ftl_state_session_dir/c.txt"
        _ftl::plugin::inline_rename::snapshot_targets
        ftl::test::assert_eq "2" "${#ftl_inline_rename_bulk_targets[@]}" "snapshot from selection"
}

test_snapshot_targets_uses_list_when_no_sel() {
        setup_listing "a.txt" "b.txt" "c.txt"
        _ftl::plugin::inline_rename::snapshot_targets
        ftl::test::assert_eq "3" "${#ftl_inline_rename_bulk_targets[@]}" "snapshot from list"
}

test_sequential_rename() {
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl::plugin::inline_rename::enter
        FTL_TEST_FAKE_REPLY="img"
        press r
        [[ -e "$ftl_state_session_dir/img001.txt" ]] \
                && ftl::test::pass "img001.txt created" \
                || ftl::test::fail "img001.txt missing"
        [[ -e "$ftl_state_session_dir/img002.txt" ]] \
                && ftl::test::pass "img002.txt created" \
                || ftl::test::fail "img002.txt missing"
        [[ -e "$ftl_state_session_dir/img003.txt" ]] \
                && ftl::test::pass "img003.txt created" \
                || ftl::test::fail "img003.txt missing"
}

test_sequential_preserves_extension() {
        setup_listing "foo.txt" "bar.jpg"
        ftl::plugin::inline_rename::enter
        FTL_TEST_FAKE_REPLY="x"
        press r
        [[ -e "$ftl_state_session_dir/x001.txt" ]] \
                && ftl::test::pass "x001.txt preserves .txt" \
                || ftl::test::fail "x001.txt missing"
        [[ -e "$ftl_state_session_dir/x002.jpg" ]] \
                && ftl::test::pass "x002.jpg preserves .jpg" \
                || ftl::test::fail "x002.jpg missing"
}

test_sequential_skips_existing_target() {
        setup_listing "a.txt" "b.txt"
        # Pre-create a conflict for index 1
        touch "$ftl_state_session_dir/img001.txt"
        ftl::plugin::inline_rename::enter
        FTL_TEST_FAKE_REPLY="img"
        press r
        # a.txt should NOT have been renamed to img001.txt (it existed)
        [[ -e "$ftl_state_session_dir/a.txt" ]] \
                && ftl::test::pass "a.txt skipped (target existed)" \
                || ftl::test::fail "a.txt was overwritten"
        [[ -e "$ftl_state_session_dir/img002.txt" ]] \
                && ftl::test::pass "b.txt renamed to img002.txt" \
                || ftl::test::fail "img002.txt missing"
}

test_sequential_empty_base_aborts() {
        setup_listing "a.txt"
        ftl::plugin::inline_rename::enter
        FTL_TEST_FAKE_REPLY=
        press r
        [[ -e "$ftl_state_session_dir/a.txt" ]] \
                && ftl::test::pass "empty base leaves file unchanged" \
                || ftl::test::fail "empty base renamed the file"
}

#==== Phase 5: regexp rename ====

test_regexp_rename() {
        setup_listing "a.txt" "b.txt"
        ftl::plugin::inline_rename::enter
        FTL_TEST_FAKE_REPLY='s/\.txt$/.md/'
        press R
        [[ -e "$ftl_state_session_dir/a.md" ]] \
                && ftl::test::pass "a.txt -> a.md" \
                || ftl::test::fail "a.md missing"
        [[ -e "$ftl_state_session_dir/b.md" ]] \
                && ftl::test::pass "b.txt -> b.md" \
                || ftl::test::fail "b.md missing"
}

test_regexp_rename_no_change_skips() {
        setup_listing "a.txt"
        ftl::plugin::inline_rename::enter
        # Pattern that doesn't match → file unchanged
        FTL_TEST_FAKE_REPLY='s/XYZ/PQR/'
        press R
        [[ -e "$ftl_state_session_dir/a.txt" ]] \
                && ftl::test::pass "non-matching pattern leaves file" \
                || ftl::test::fail "non-matching pattern renamed the file"
}

test_regexp_default_pattern_aborts() {
        setup_listing "a.txt"
        ftl::plugin::inline_rename::enter
        # User accepted the default 's/OLD/NEW/' verbatim → should abort
        FTL_TEST_FAKE_REPLY='s/OLD/NEW/'
        press R
        [[ -e "$ftl_state_session_dir/a.txt" ]] \
                && ftl::test::pass "default pattern aborts" \
                || ftl::test::fail "default pattern renamed the file"
}

#==== Phase 6: delete ====

test_delete_one_with_confirm_y() {
        setup_listing "a.txt" "b.txt"
        ftl::plugin::inline_rename::enter
        FTL_TEST_FAKE_REPLY="y"
        press x
        [[ ! -e "$ftl_state_session_dir/a.txt" ]] \
                && ftl::test::pass "a.txt deleted (confirm y)" \
                || ftl::test::fail "a.txt still exists"
}

test_delete_one_with_confirm_n() {
        setup_listing "a.txt" "b.txt"
        ftl::plugin::inline_rename::enter
        FTL_TEST_FAKE_REPLY="n"
        press x
        [[ -e "$ftl_state_session_dir/a.txt" ]] \
                && ftl::test::pass "a.txt kept (confirm n)" \
                || ftl::test::fail "a.txt was deleted despite n"
}

test_delete_one_no_confirm_when_opt_in() {
        setup_listing "a.txt" "b.txt"
        ftl_cfg_inline_rename_no_confirm_delete=1
        ftl::plugin::inline_rename::enter
        press d
        [[ ! -e "$ftl_state_session_dir/a.txt" ]] \
                && ftl::test::pass "a.txt deleted without confirm" \
                || ftl::test::fail "a.txt still exists with no_confirm=1"
}

test_delete_one_with_confirm_when_opt_out() {
        # Default: ftl_cfg_inline_rename_no_confirm_delete=0 → 'd' should prompt
        setup_listing "a.txt" "b.txt"
        ftl::plugin::inline_rename::enter
        FTL_TEST_FAKE_REPLY="n"  # answer no
        press d
        [[ -e "$ftl_state_session_dir/a.txt" ]] \
                && ftl::test::pass "a.txt kept (d with no_confirm=0 prompts)" \
                || ftl::test::fail "a.txt was deleted despite n"
}

#==== Phase 7: image labeling ====

test_begin_label_no_op_if_not_image() {
        setup_listing "readme.txt"
        ftl::plugin::inline_rename::enter
        press l
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "l on non-image stays in outer mode"
}

test_begin_label_no_op_if_no_exiftool() {
        setup_listing "photo.jpg"
        # Override exiftool to be missing by hiding it from PATH
        local saved_path="$PATH"
        PATH="/nonexistent"
        ftl::plugin::inline_rename::enter
        press l
        ftl::test::assert_eq "1" "$ftl_inline_rename_active" "l without exiftool stays in outer mode"
        PATH="$saved_path"
}

test_begin_label_enters_inner_for_image() {
        setup_listing "photo.jpg"
        # We can't actually run exiftool in the test env reliably, so stub it
        exiftool() {
                case "$1" in
                        -s3) echo "" ;;  # empty existing label
                        *) : ;;
                esac
        }
        export -f exiftool
        ftl::plugin::inline_rename::enter
        press l
        ftl::test::assert_eq "2" "$ftl_inline_rename_active" "l on image enters inner mode"
        ftl::test::assert_eq "1" "$ftl_inline_rename_is_label" "is_label flag set"
        unset -f exiftool
}

#==== Phase 8: render_draft ====

test_render_draft_emits_to_stdout() {
        setup_listing "old.txt"
        ftl_list_window_top=0
        ftl_state_cursor_index=0
        ftl::plugin::inline_rename::enter >/dev/null 2>&1
        press ENTER
        # Capture stdout from render_draft directly
        local out
        out=$(_ftl::plugin::inline_rename::render_draft 2>/dev/null)
        # Should contain the draft text and the [RENAME] marker
        ftl::test::assert_contains "$out" "old.txt" "render_draft emits the draft"
        ftl::test::assert_contains "$out" "[RENAME]" "render_draft emits [RENAME] marker"
}

test_render_draft_shows_error() {
        setup_listing "old.txt"
        ftl_state_session_dir=
        ftl::plugin::inline_rename::enter >/dev/null 2>&1
        press ENTER
        ftl_state_inline_rename_error="test error"
        local out
        out=$(_ftl::plugin::inline_rename::render_draft 2>/dev/null)
        ftl::test::assert_contains "$out" "test error" "render_draft shows error message"
}

#==== History tracking ====

test_history_records_rename() {
        setup_listing "old.txt"
        ftl::plugin::inline_rename::enter
        press ENTER
        press CTL-U
        for c in n e w ; do press "$c" ; done
        press RETURN
        ftl::test::assert_eq "1" "${#ftl_inline_rename_history[@]}" "history has 1 entry"
        ftl::test::assert_contains "${ftl_inline_rename_history[0]}" "old.txt" "history records old path"
        ftl::test::assert_contains "${ftl_inline_rename_history[0]}" "new" "history records new path"
}

# vim: set filetype=bash :
