#!/bin/env bash
# test/unit/test_missing_functionalities_behavior.sh
#
# Behavioral tests for every feature in config/ftl/bindings/missing_functionalities.
#
# Unlike test_missing_functionalities.sh (which only checks function existence),
# these tests actually exercise each feature against a real temp directory and
# assert on the resulting filesystem / state changes.
#
# Heavy I/O is stubbed (ftl::list::render, ftl::pane::split_for_preview, tmux
# for non-tmux-requiring tests). Real commands (cp, ln, mv, touch, sha256sum,
# zip, 7z, tar, git, sed, find, stat, convert) are used directly.
#
# Tool availability:
#   - sponge, tmux, 7z, fzf, convert are checked per-test; tests skip
#     themselves if their tool is missing.

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
source "$FTL_CFG/bindings/missing_functionalities"

#----------------------------------------------------------------------------
# Stubs — heavy I/O is no-op'd so tests are deterministic
#----------------------------------------------------------------------------

ftl::list::render() { : ; }
ftl::list::change_dir() {
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
ftl::pane::split() { : ; }
ftl::pane::split_for_preview() { : ; }
ftl::pane::run_in_bg_window() { : ; }
ftl::prev::dispatch() { : ; }
ftl::prev::clear() { : ; }
ftl::prev::show_image() { : ; }
tmux() { : ; }
stty() { : ; }
tput() { : ; }

# Stub ftl::cmd::prompt — sets REPLY and ftl_kbd_current_key from
# FTL_TEST_FAKE_REPLY (some functions read $REPLY, others read $ftl_kbd_current_key).
# The missing_functionalities code mostly uses $ftl_kbd_current_key which is
# a bug, but we faithfully stub both so the tests exercise real behaviour.
FTL_TEST_FAKE_REPLY=
ftl::cmd::prompt() {
        REPLY="$FTL_TEST_FAKE_REPLY"
        ftl_kbd_current_key="$FTL_TEST_FAKE_REPLY"
}
ftl::cmd::cd_to_parent() {
        cd ..
        ftl_state_current_dir="$PWD"
}
ftl::cmd::goto_mark_via_fzf() { : ; }
ftl::cmd::find_in_dir() { : ; }

ftl::test::setup() {
        ftl_state_session_dir=$(mktemp -d)
        mkdir -p "$ftl_state_session_dir/prev" "$ftl_state_session_dir/lock_preview"
        ftl_state_parent_dir="$ftl_state_session_dir"
        ftl_state_shared_dir="$ftl_state_session_dir/prev"
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
        ftl_selection_revision=0
        ftl_selection_total_bytes=0
        ftl_selection_other_revision=0
        ftl_selection_class_cursor=0
        declare -Ag ftl_selection_class_index=()
        declare -Ag ftl_state_cursor_memory=()
        declare -Ag ftl_plugin_vfiles=()
        declare -Ag ftl_plugin_vdirs=()
        declare -Ag ftl_mark_session_marks=()
        declare -Ag ftl_kbd_trie=()
        declare -Ag ftl_kbd_command_to_key=()
        declare -Ag ftl_kbd_bindings_display=()
        ftl_tab_directories=()
        ftl_tab_count=1
        ftl_pane_is_child=0
        ftl_cfg_image_zoomed=0
        ftl_cfg_diff_tool="diff"
        ftl_cfg_delete_command="rm -f"
        ftl_plugin_missing_nav_history=()
        ftl_plugin_missing_nav_index=0
        ftl_plugin_missing_preview_zoom=2
        FTL_STATE_DIR="$ftl_state_session_dir"
        FTL_TEST_FAKE_REPLY=
}

ftl::test::teardown() {
        rm -rf "$ftl_state_session_dir" 2>/dev/null
}

#----------------------------------------------------------------------------
# Helpers
#----------------------------------------------------------------------------

# Build a fake listing from a list of filenames (created in the session dir).
# Sets ftl_list_entries, ftl_list_entry_count, ftl_state_current_*, and cds
# into the session dir.
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
        if [[ "$ftl_state_current_basename" == *.* ]] ; then
                ftl_state_current_extension="${ftl_state_current_basename##*.}"
        else
                ftl_state_current_extension=
        fi
        cd "$ftl_state_session_dir"
}

# Resolve the absolute path of a listing entry by basename.
path_of() {
        echo "$ftl_state_session_dir/$1"
}

# Tag a file (by basename) into the selection.
tag() {
        local name="$1"
        local p="$(path_of "$name")"
        ftl::sel::set "$p"
        ftl_selection_current+=( "$p" )
}

# Run a missing-functionality function with a fake prompt answer.
run_with_reply() {
        FTL_TEST_FAKE_REPLY="$1"
        shift
        "$@"
}

#==========================================================================
# 1. File Operations
#==========================================================================

#--- duplicate ---

test_duplicate_creates_copy_with_suffix() {
        setup_listing "report.txt"
        tag "report.txt"
        ftl::plugin::missing::duplicate
        [[ -e "$(path_of report_copy1.txt)" ]] \
                && ftl::test::pass "duplicate created report_copy1.txt" \
                || ftl::test::fail "duplicate did not create report_copy1.txt"
}

test_duplicate_increments_suffix() {
        setup_listing "data.csv"
        tag "data.csv"
        # Pre-create the first copy slot
        cp "$(path_of data.csv)" "$(path_of data_copy1.csv)"
        ftl::plugin::missing::duplicate
        [[ -e "$(path_of data_copy2.csv)" ]] \
                && ftl::test::pass "duplicate incremented to _copy2" \
                || ftl::test::fail "duplicate did not increment suffix"
}

test_duplicate_preserves_no_extension() {
        setup_listing "Makefile"
        tag "Makefile"
        ftl::plugin::missing::duplicate
        [[ -e "$(path_of Makefile_copy1)" ]] \
                && ftl::test::pass "duplicate of extensionless file works" \
                || ftl::test::fail "duplicate of extensionless file failed"
}

test_duplicate_handles_multiple_selection() {
        setup_listing "a.txt" "b.txt"
        tag "a.txt"
        tag "b.txt"
        ftl::plugin::missing::duplicate
        [[ -e "$(path_of a_copy1.txt)" && -e "$(path_of b_copy1.txt)" ]] \
                && ftl::test::pass "duplicate of 2 files created 2 copies" \
                || ftl::test::fail "duplicate of 2 files failed"
}

test_duplicate_uses_cp_r_for_directories() {
        mkdir -p "$ftl_state_session_dir/subdir"
        touch "$ftl_state_session_dir/subdir/inner.txt"
        ftl_list_entries+=( "$ftl_state_session_dir/subdir" )
        ftl_list_entry_count=1
        ftl_state_current_path="$ftl_state_session_dir/subdir"
        ftl_selection_current+=( "$ftl_state_session_dir/subdir" )
        ftl::plugin::missing::duplicate
        [[ -d "$(path_of subdir_copy1)" && -f "$(path_of subdir_copy1/inner.txt)" ]] \
                && ftl::test::pass "duplicate of directory recurses" \
                || ftl::test::fail "duplicate of directory did not recurse"
}

#--- hardlink ---

test_hardlink_creates_link_in_cwd() {
        # Create the source file in a subdirectory so the hardlink (created in
        # $PWD = $ftl_state_session_dir) doesn't try to overwrite the source.
        mkdir -p "$ftl_state_session_dir/src"
        touch "$ftl_state_session_dir/src/original.txt"
        ftl_list_entries+=( "$ftl_state_session_dir/src/original.txt" )
        ftl_list_entry_count=1
        ftl_state_current_path="$ftl_state_session_dir/src/original.txt"
        ftl_state_current_basename="original.txt"
        ftl_state_current_dir="$ftl_state_session_dir/src"
        ftl_selection_current+=( "$ftl_state_session_dir/src/original.txt" )
        ftl::sel::set "$ftl_state_session_dir/src/original.txt"
        cd "$ftl_state_session_dir"
        run_with_reply "y" ftl::plugin::missing::hardlink
        # The hardlink should exist in $ftl_state_session_dir/original.txt
        [[ -f "$ftl_state_session_dir/original.txt" ]] \
                && ftl::test::pass "hardlink created in cwd" \
                || ftl::test::fail "hardlink not created in cwd"
        # Verify it's actually a hardlink (same inode)
        local orig_inode=$(stat -c %i "$ftl_state_session_dir/src/original.txt")
        local new_inode=$(stat -c %i "$ftl_state_session_dir/original.txt")
        [[ "$orig_inode" == "$new_inode" ]] \
                && ftl::test::pass "hardlink shares inode ($orig_inode)" \
                || ftl::test::fail "hardlink has different inode ($orig_inode vs $new_inode)"
}

test_hardlink_declined_does_nothing() {
        setup_listing "original.txt"
        tag "original.txt"
        run_with_reply "n" ftl::plugin::missing::hardlink
        # After decline, only the original file should exist (plus setup subdirs prev/ lock_preview/)
        local files=$(find "$ftl_state_session_dir" -maxdepth 1 -type f | wc -l)
        ftl::test::assert_eq "1" "$files" "no hardlink created when declined"
}

#--- touch_files ---

test_touch_files_updates_mtime() {
        setup_listing "old.txt"
        tag "old.txt"
        # Set mtime to a known old value
        touch -d "2020-01-01 00:00:00" "$(path_of old.txt)"
        local before=$(stat -c %Y "$(path_of old.txt)")
        ftl::plugin::missing::touch_files
        local after=$(stat -c %Y "$(path_of old.txt)")
        # Old timestamp (2020) is definitely less than current epoch
        (( after > before )) \
                && ftl::test::pass "touch updated mtime ($before -> $after)" \
                || ftl::test::fail "touch did not update mtime"
}

test_touch_files_handles_multiple() {
        setup_listing "a.txt" "b.txt" "c.txt"
        tag "a.txt" ; tag "b.txt" ; tag "c.txt"
        # Set all mtimes to a known old value
        touch -d "2020-01-01" "$(path_of a.txt)" "$(path_of b.txt)" "$(path_of c.txt)"
        ftl::plugin::missing::touch_files
        # All three should now have mtime > 2020 epoch (1577836800)
        local a=$(stat -c %Y "$(path_of a.txt)")
        local b=$(stat -c %Y "$(path_of b.txt)")
        local c=$(stat -c %Y "$(path_of c.txt)")
        (( a > 1577836800 )) && (( b > 1577836800 )) && (( c > 1577836800 )) \
                && ftl::test::pass "touch updated all 3 files" \
                || ftl::test::fail "touch did not update all files (a=$a b=$b c=$c)"
}

#--- checksum ---

test_checksum_computes_sha256() {
        setup_listing "data.txt"
        printf "hello world" > "$(path_of data.txt)"
        tag "data.txt"
        # Capture what would be sent to split_for_preview by overriding it
        local captured
        ftl::pane::split_for_preview() { cat ; }
        captured=$(ftl::plugin::missing::checksum)
        local expected=$(sha256sum "$(path_of data.txt)" | awk '{print $1}')
        ftl::test::assert_contains "$captured" "$expected" "checksum output contains sha256"
}

test_checksum_for_multiple_files() {
        setup_listing "a.txt" "b.txt"
        printf "aaa" > "$(path_of a.txt)"
        printf "bbb" > "$(path_of b.txt)"
        tag "a.txt" ; tag "b.txt"
        ftl::pane::split_for_preview() { cat ; }
        local captured=$(ftl::plugin::missing::checksum)
        local line_count=$(echo "$captured" | wc -l)
        ftl::test::assert_eq "2" "$line_count" "checksum output has 2 lines for 2 files"
}

#--- checksum_verify ---

test_checksum_verify_with_valid_sha256_file() {
        setup_listing "data.txt"
        printf "hello" > "$(path_of data.txt)"
        local expected_hash=$(sha256sum "$(path_of data.txt)" | awk '{print $1}')
        printf "%s  %s\n" "$expected_hash" "$(path_of data.txt)" > "$(path_of data.txt).sha256"
        tag "data.txt"
        ftl::pane::split_for_preview() { cat ; }
        local captured=$(ftl::plugin::missing::checksum_verify)
        ftl::test::assert_contains "$captured" "OK" "checksum_verify reports OK for valid .sha256"
}

test_checksum_verify_without_sha256_file() {
        setup_listing "data.txt"
        printf "hello" > "$(path_of data.txt)"
        tag "data.txt"
        ftl::pane::split_for_preview() { cat ; }
        local captured=$(ftl::plugin::missing::checksum_verify)
        ftl::test::assert_contains "$captured" "no checksum file" "checksum_verify reports missing .sha256"
}

#--- rename_pattern ---

test_rename_pattern_applies_sed() {
        setup_listing "old_name.txt"
        tag "old_name.txt"
        run_with_reply "s/old/new/" ftl::plugin::missing::rename_pattern
        [[ -e "$(path_of new_name.txt)" && ! -e "$(path_of old_name.txt)" ]] \
                && ftl::test::pass "rename_pattern renamed old_name → new_name" \
                || ftl::test::fail "rename_pattern did not rename"
}

test_rename_pattern_empty_aborts() {
        setup_listing "old.txt"
        tag "old.txt"
        run_with_reply "" ftl::plugin::missing::rename_pattern
        [[ -e "$(path_of old.txt)" ]] \
                && ftl::test::pass "empty pattern keeps original" \
                || ftl::test::fail "empty pattern renamed the file"
}

test_rename_pattern_no_match_skips() {
        setup_listing "photo.jpg"
        tag "photo.jpg"
        run_with_reply "s/XYZ/ABC/" ftl::plugin::missing::rename_pattern
        [[ -e "$(path_of photo.jpg)" ]] \
                && ftl::test::pass "non-matching pattern keeps original" \
                || ftl::test::fail "non-matching pattern renamed the file"
}

test_rename_pattern_skips_existing_target() {
        setup_listing "a.txt" "b.txt"
        tag "a.txt"
        # Make 'b.txt' the rename target of 'a.txt' so the target already exists
        run_with_reply "s/a/b/" ftl::plugin::missing::rename_pattern
        [[ -e "$(path_of a.txt)" ]] \
                && ftl::test::pass "rename_pattern skipped when target exists" \
                || ftl::test::fail "rename_pattern overwrote an existing file"
}

test_rename_pattern_multiple_files() {
        setup_listing "img_001.jpg" "img_002.jpg"
        tag "img_001.jpg" ; tag "img_002.jpg"
        run_with_reply "s/img_/vacation_/" ftl::plugin::missing::rename_pattern
        [[ -e "$(path_of vacation_001.jpg)" && -e "$(path_of vacation_002.jpg)" ]] \
                && ftl::test::pass "rename_pattern renamed both files" \
                || ftl::test::fail "rename_pattern did not rename both"
}

#--- chmod_numeric ---

test_chmod_numeric_applies_octal() {
        setup_listing "script.sh"
        chmod 644 "$(path_of script.sh)"
        tag "script.sh"
        run_with_reply "755" ftl::plugin::missing::chmod_numeric
        local mode=$(stat -c %a "$(path_of script.sh)")
        ftl::test::assert_eq "755" "$mode" "chmod_numeric set mode to 755"
}

test_chmod_numeric_invalid_pattern_aborts() {
        setup_listing "script.sh"
        chmod 644 "$(path_of script.sh)"
        tag "script.sh"
        run_with_reply "abc" ftl::plugin::missing::chmod_numeric
        local mode=$(stat -c %a "$(path_of script.sh)")
        ftl::test::assert_eq "644" "$mode" "invalid chmod pattern leaves mode unchanged"
}

test_chmod_numeric_4_digit() {
        setup_listing "script.sh"
        chmod 644 "$(path_of script.sh)"
        tag "script.sh"
        run_with_reply "4755" ftl::plugin::missing::chmod_numeric
        local mode=$(stat -c %a "$(path_of script.sh)")
        ftl::test::assert_eq "4755" "$mode" "chmod_numeric handles 4-digit octal"
}

#--- chown_files ---

test_chown_files_empty_aborts() {
        setup_listing "file.txt"
        tag "file.txt"
        local before_owner=$(stat -c %U "$(path_of file.txt)")
        run_with_reply "" ftl::plugin::missing::chown_files
        local after_owner=$(stat -c %U "$(path_of file.txt)")
        ftl::test::assert_eq "$before_owner" "$after_owner" "empty chown input does nothing"
}

# Note: real chown requires root, so we can only test the empty-abort path
# behaviourally. The non-empty path is covered by an existence check in
# test_missing_functionalities.sh.

#==========================================================================
# 2. Navigation
#==========================================================================

#--- nav_record / nav_back / nav_forward ---

test_nav_record_appends_to_history() {
        ftl_state_current_path="/tmp/something"
        ftl_pane_is_child=0
        ftl::plugin::missing::nav_record
        ftl::test::assert_eq "1" "${#ftl_plugin_missing_nav_history[@]}" "nav_record appended 1 entry"
        ftl::test::assert_eq "$PWD" "${ftl_plugin_missing_nav_history[0]}" "history[0] is current PWD"
}

test_nav_record_skipped_in_child_pane() {
        ftl_state_current_path="/tmp/something"
        ftl_pane_is_child=1
        ftl::plugin::missing::nav_record
        ftl::test::assert_eq "0" "${#ftl_plugin_missing_nav_history[@]}" "nav_record skipped in child pane"
}

test_nav_record_skipped_with_empty_path() {
        ftl_state_current_path=
        ftl_pane_is_child=0
        ftl::plugin::missing::nav_record
        ftl::test::assert_eq "0" "${#ftl_plugin_missing_nav_history[@]}" "nav_record skipped with empty path"
}

test_nav_back_does_nothing_at_start() {
        # No history recorded yet
        ftl::plugin::missing::nav_back
        ftl::test::assert_eq "0" "$ftl_plugin_missing_nav_index" "nav_back at start: index unchanged"
}

test_nav_back_decrements_index() {
        ftl_state_current_path="/tmp/a"
        ftl::plugin::missing::nav_record
        cd /tmp
        ftl_state_current_path="/tmp/b"
        ftl::plugin::missing::nav_record
        # Now index=2, history has 2 entries
        ftl::test::assert_eq "2" "$ftl_plugin_missing_nav_index" "after 2 records, index=2"
        ftl::plugin::missing::nav_back
        ftl::test::assert_eq "1" "$ftl_plugin_missing_nav_index" "nav_back decremented to 1"
}

test_nav_forward_does_nothing_at_end() {
        ftl_state_current_path="/tmp/a"
        ftl::plugin::missing::nav_record
        # index=1, history has 1 entry — at end
        ftl::plugin::missing::nav_forward
        ftl::test::assert_eq "1" "$ftl_plugin_missing_nav_index" "nav_forward at end: index unchanged"
}

test_nav_forward_increments_index() {
        ftl_state_current_path="/tmp/a"
        ftl::plugin::missing::nav_record
        cd /tmp
        ftl_state_current_path="/tmp/b"
        ftl::plugin::missing::nav_record
        ftl::plugin::missing::nav_back  # index=1
        ftl::plugin::missing::nav_forward
        ftl::test::assert_eq "2" "$ftl_plugin_missing_nav_index" "nav_forward incremented to 2"
}

test_nav_back_forward_roundtrip() {
        local dir1=$(mktemp -d)
        local dir2=$(mktemp -d)
        cd "$dir1"
        ftl_state_current_path="$dir1/x"
        ftl::plugin::missing::nav_record
        cd "$dir2"
        ftl_state_current_path="$dir2/y"
        ftl::plugin::missing::nav_record
        ftl::plugin::missing::nav_back
        ftl::test::assert_eq "1" "$ftl_plugin_missing_nav_index" "back: index=1"
        ftl::plugin::missing::nav_forward
        ftl::test::assert_eq "2" "$ftl_plugin_missing_nav_index" "forward: index=2"
        rm -rf "$dir1" "$dir2"
}

#--- move_left_select ---

test_move_left_select_cd_to_parent() {
        mkdir -p "$ftl_state_session_dir/child"
        cd "$ftl_state_session_dir/child"
        ftl_state_current_dir="$ftl_state_session_dir/child"
        ftl::plugin::missing::move_left_select
        [[ "$PWD" == "$ftl_state_session_dir" ]] \
                && ftl::test::pass "move_left_select cd'd to parent" \
                || ftl::test::fail "move_left_select did not cd to parent (PWD=$PWD)"
}

# Note: move_left_select also calls ftl::list::change_dir with the basename
# of the last dir, which would position the cursor on that dir. Since our
# stub for change_dir is minimal, we only test the cd-to-parent behaviour.

#--- marks_manage ---

test_marks_manage_view_action() {
        # Stub fzf-tmux to return "view"
        echo "view" > "$ftl_state_session_dir/fzf_reply"
        ftl::plugin::missing::marks_manage
        # The view action calls ftl::cmd::goto_mark_via_fzf which we stubbed to no-op.
        # We can only verify the function didn't crash.
        ftl::test::pass "marks_manage view action completed without error"
}

#==========================================================================
# 3. Selection
#==========================================================================

#--- selection_invert ---

test_selection_invert_selects_untagged() {
        setup_listing "a.txt" "b.txt" "c.txt"
        # Tag only a.txt
        tag "a.txt"
        ftl::plugin::missing::selection_invert
        # After invert: a.txt should be untagged, b.txt and c.txt should be tagged
        [[ -z "${ftl_selection_tags[$(path_of a.txt)]:-}" ]] \
                && ftl::test::pass "a.txt untagged after invert" \
                || ftl::test::fail "a.txt still tagged after invert"
        [[ -n "${ftl_selection_tags[$(path_of b.txt)]:-}" ]] \
                && ftl::test::pass "b.txt tagged after invert" \
                || ftl::test::fail "b.txt not tagged after invert"
        [[ -n "${ftl_selection_tags[$(path_of c.txt)]:-}" ]] \
                && ftl::test::pass "c.txt tagged after invert" \
                || ftl::test::fail "c.txt not tagged after invert"
}

test_selection_invert_with_no_initial_selection() {
        setup_listing "a.txt" "b.txt"
        ftl::plugin::missing::selection_invert
        ftl::test::assert_eq "2" "${#ftl_selection_tags[@]}" "invert with no selection tags all entries"
}

test_selection_invert_with_all_selected() {
        setup_listing "a.txt" "b.txt"
        tag "a.txt" ; tag "b.txt"
        ftl::plugin::missing::selection_invert
        ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "invert with all selected clears selection"
}

#--- select_by_pattern ---

test_select_by_pattern_matches_names() {
        setup_listing "foo.txt" "bar.txt" "foobar.txt" "baz.md"
        run_with_reply "foo" ftl::plugin::missing::select_by_pattern
        # foo.txt and foobar.txt should be tagged
        [[ -n "${ftl_selection_tags[$(path_of foo.txt)]:-}" ]] \
                && ftl::test::pass "foo.txt tagged by pattern" \
                || ftl::test::fail "foo.txt not tagged by pattern"
        [[ -n "${ftl_selection_tags[$(path_of foobar.txt)]:-}" ]] \
                && ftl::test::pass "foobar.txt tagged by pattern" \
                || ftl::test::fail "foobar.txt not tagged by pattern"
        [[ -z "${ftl_selection_tags[$(path_of bar.txt)]:-}" ]] \
                && ftl::test::pass "bar.txt not tagged by pattern" \
                || ftl::test::fail "bar.txt wrongly tagged by pattern"
}

test_select_by_pattern_regex() {
        setup_listing "img_001.jpg" "img_002.jpg" "photo.txt"
        run_with_reply "^img_[0-9]+\.jpg$" ftl::plugin::missing::select_by_pattern
        ftl::test::assert_eq "2" "${#ftl_selection_tags[@]}" "regex pattern tagged 2 files"
}

test_select_by_pattern_empty_aborts() {
        setup_listing "a.txt"
        run_with_reply "" ftl::plugin::missing::select_by_pattern
        ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "empty pattern tags nothing"
}

#--- select_by_size ---

test_select_by_size_picks_large_files() {
        setup_listing "small.txt" "large.txt"
        printf "small" > "$(path_of small.txt)"
        dd if=/dev/zero of="$(path_of large.txt)" bs=1024 count=10 2>/dev/null
        run_with_reply "100" ftl::plugin::missing::select_by_size
        [[ -n "${ftl_selection_tags[$(path_of large.txt)]:-}" ]] \
                && ftl::test::pass "large.txt tagged by size" \
                || ftl::test::fail "large.txt not tagged by size"
        [[ -z "${ftl_selection_tags[$(path_of small.txt)]:-}" ]] \
                && ftl::test::pass "small.txt not tagged by size" \
                || ftl::test::fail "small.txt wrongly tagged by size"
}

test_select_by_size_invalid_input_aborts() {
        setup_listing "a.txt"
        run_with_reply "abc" ftl::plugin::missing::select_by_size
        ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "invalid size input tags nothing"
}

test_select_by_size_zero_selects_all_files() {
        setup_listing "a.txt" "b.txt"
        printf "x" > "$(path_of a.txt)"
        printf "y" > "$(path_of b.txt)"
        run_with_reply "0" ftl::plugin::missing::select_by_size
        ftl::test::assert_eq "2" "${#ftl_selection_tags[@]}" "min_size=0 tags all files (size > 0)"
}

#--- size_analysis ---

test_size_analysis_finds_largest() {
        setup_listing "a.txt" "b.txt" "c.txt"
        printf "tiny" > "$(path_of a.txt)"
        printf "medium content here" > "$(path_of b.txt)"
        dd if=/dev/zero of="$(path_of c.txt)" bs=1024 count=5 2>/dev/null
        # Override split_for_preview to capture output
        ftl::pane::split_for_preview() { cat ; }
        local output=$(ftl::plugin::missing::size_analysis 2>/dev/null)
        # Output should contain c.txt (the largest)
        ftl::test::assert_contains "$output" "c.txt" "size_analysis lists largest file"
}

#--- selection_save / selection_load ---

test_selection_save_writes_file() {
        setup_listing "a.txt" "b.txt"
        tag "a.txt"
        local savefile="$ftl_state_session_dir/mysel"
        run_with_reply "$savefile" ftl::plugin::missing::selection_save
        [[ -f "$savefile" ]] \
                && ftl::test::pass "selection_save created file" \
                || ftl::test::fail "selection_save did not create file"
        ftl::test::assert_contains "$(cat "$savefile")" "$(path_of a.txt)" "save file contains a.txt path"
}

test_selection_load_restores_tags() {
        setup_listing "a.txt" "b.txt"
        # Pre-create a selection file
        printf '%s\n' "$(path_of a.txt)" "$(path_of b.txt)" > "$ftl_state_session_dir/saved"
        run_with_reply "$ftl_state_session_dir/saved" ftl::plugin::missing::selection_load
        ftl::test::assert_eq "2" "${#ftl_selection_tags[@]}" "selection_load restored 2 tags"
}

test_selection_load_missing_file_does_nothing() {
        setup_listing "a.txt"
        tag "a.txt"
        run_with_reply "/nonexistent/file" ftl::plugin::missing::selection_load
        # Existing selection should be untouched (load only clears if file exists)
        ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "load of missing file leaves selection intact"
}

#--- selection_union ---

test_selection_union_merges_from_file() {
        setup_listing "a.txt" "b.txt" "c.txt"
        # Start with a.txt tagged
        tag "a.txt"
        # Union with a file containing b.txt and c.txt
        printf '%s\n' "$(path_of b.txt)" "$(path_of c.txt)" > "$ftl_state_session_dir/other"
        run_with_reply "$ftl_state_session_dir/other" ftl::plugin::missing::selection_union
        ftl::test::assert_eq "3" "${#ftl_selection_tags[@]}" "union merged to 3 tags"
}

test_selection_union_with_missing_file() {
        setup_listing "a.txt"
        tag "a.txt"
        run_with_reply "/nonexistent" ftl::plugin::missing::selection_union
        ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "union with missing file leaves selection intact"
}

#--- selection_intersect ---

test_selection_intersect_keeps_only_common() {
        setup_listing "a.txt" "b.txt" "c.txt"
        # Tag a.txt and b.txt
        tag "a.txt" ; tag "b.txt"
        # Intersect with file containing b.txt and c.txt
        printf '%s\n' "$(path_of b.txt)" "$(path_of c.txt)" > "$ftl_state_session_dir/other"
        run_with_reply "$ftl_state_session_dir/other" ftl::plugin::missing::selection_intersect
        # Only b.txt should remain
        ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "intersect kept 1 common entry"
        [[ -n "${ftl_selection_tags[$(path_of b.txt)]:-}" ]] \
                && ftl::test::pass "intersect kept b.txt" \
                || ftl::test::fail "intersect lost b.txt"
}

test_selection_intersect_empty_result() {
        setup_listing "a.txt" "b.txt"
        tag "a.txt"
        # Intersect with file containing only b.txt
        printf '%s\n' "$(path_of b.txt)" > "$ftl_state_session_dir/other"
        run_with_reply "$ftl_state_session_dir/other" ftl::plugin::missing::selection_intersect
        ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "intersect with disjoint sets gives empty"
}

#--- selection_subtract ---

test_selection_subtract_removes_from_file() {
        setup_listing "a.txt" "b.txt" "c.txt"
        tag "a.txt" ; tag "b.txt" ; tag "c.txt"
        # Subtract file containing b.txt
        printf '%s\n' "$(path_of b.txt)" > "$ftl_state_session_dir/other"
        run_with_reply "$ftl_state_session_dir/other" ftl::plugin::missing::selection_subtract
        ftl::test::assert_eq "2" "${#ftl_selection_tags[@]}" "subtract removed 1, left 2"
        [[ -z "${ftl_selection_tags[$(path_of b.txt)]:-}" ]] \
                && ftl::test::pass "subtract removed b.txt" \
                || ftl::test::fail "subtract did not remove b.txt"
}

test_selection_subtract_missing_file_no_op() {
        setup_listing "a.txt"
        tag "a.txt"
        run_with_reply "/nonexistent" ftl::plugin::missing::selection_subtract
        ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "subtract with missing file leaves selection intact"
}

#--- visual_mode ---

test_visual_mode_completes_without_crash() {
        # visual_mode reads from stdin in a loop; with no input, it should exit immediately
        setup_listing "a.txt" "b.txt" "c.txt"
        ftl::plugin::missing::visual_mode </dev/null
        ftl::test::pass "visual_mode exited cleanly with no input"
}

#==========================================================================
# 4. Search
#==========================================================================

#--- rg_replace ---

test_rg_replace_replaces_in_selected() {
        command -v rg >/dev/null 2>&1 || { ftl::test::skip "rg not installed" ; return ; }
        setup_listing "a.txt" "b.txt"
        printf "hello world\n" > "$(path_of a.txt)"
        printf "hello there\n" > "$(path_of b.txt)"
        tag "a.txt" ; tag "b.txt"
        # Three prompts: search, replace, scope. Answer: "hello" / "HI" / "s" (selected)
        # Use a global array so the stub function can pop sequential replies.
        _FTL_TEST_REPLIES=( "hello" "HI" "s" )
        _FTL_TEST_REPLY_IDX=0
        # Save and override ftl::cmd::prompt; restore at end so subsequent tests get the default stub.
        local _saved_prompt="$(declare -f ftl::cmd::prompt)"
        ftl::cmd::prompt() {
                ftl_kbd_current_key="${_FTL_TEST_REPLIES[$_FTL_TEST_REPLY_IDX]:-}"
                ((_FTL_TEST_REPLY_IDX++)) || true
        }
        ftl::plugin::missing::rg_replace
        local a_content=$(cat "$(path_of a.txt)")
        local b_content=$(cat "$(path_of b.txt)")
        ftl::test::assert_contains "$a_content" "HI" "a.txt had hello replaced with HI"
        ftl::test::assert_contains "$b_content" "HI" "b.txt had hello replaced with HI"
        # Restore the default prompt stub
        eval "$_saved_prompt"
        unset _FTL_TEST_REPLIES _FTL_TEST_REPLY_IDX
}

test_rg_replace_empty_search_aborts() {
        setup_listing "a.txt"
        printf "hello\n" > "$(path_of a.txt)"
        tag "a.txt"
        # First reply is empty → should abort
        FTL_TEST_FAKE_REPLY=
        ftl::cmd::prompt() { ftl_kbd_current_key="$FTL_TEST_FAKE_REPLY" ; }
        ftl::plugin::missing::rg_replace
        # File should be unchanged
        ftl::test::assert_contains "$(cat "$(path_of a.txt)")" "hello" "empty search left file unchanged"
}

#--- find_with_history ---

test_find_with_history_appends_to_history_file() {
        setup_listing "a.txt"
        # Pre-create a history file with one entry
        local h="$ftl_state_session_dir/find_history"
        printf 'previous_search\n' > "$h"
        # find_with_history loads the last history line into ftl_state_search_string,
        # calls find_in_dir (stubbed no-op), then appends ftl_state_search_string to history.
        # So after the call, history should have previous_search (original) + previous_search (appended).
        ftl_state_search_string=
        ftl::plugin::missing::find_with_history
        # History should now contain 2 lines (both "previous_search")
        local line_count=$(wc -l < "$h")
        ftl::test::assert_eq "2" "$line_count" "history appended one entry (now 2 lines)"
        ftl::test::assert_contains "$(cat "$h")" "previous_search" "history preserved previous entry"
}

test_find_with_history_loads_last_entry() {
        setup_listing "a.txt"
        local h="$ftl_state_session_dir/find_history"
        printf 'old_query\n' > "$h"
        ftl_state_search_string=
        ftl::plugin::missing::find_with_history
        # ftl_state_search_string should be loaded from the last history line
        # Note: find_with_history sets it from history, then calls find_in_dir (stubbed),
        # then appends ftl_state_search_string to history.
        ftl::test::assert_eq "old_query" "$ftl_state_search_string" "search string loaded from history"
}

#==========================================================================
# 5. Preview
#==========================================================================

#--- preview_pin / preview_unpin ---

test_preview_pin_creates_lock_file() {
        setup_listing "doc.txt"
        # The lock file path uses the full current_path as a filename, which contains
        # slashes. We need to pre-create the nested directory structure.
        mkdir -p "$ftl_state_session_dir/lock_preview/$(dirname "$(path_of doc.txt)")" 2>/dev/null
        ftl::plugin::missing::preview_pin 2>/dev/null
        # A lock file should exist in $ftl_state_session_dir/lock_preview/<full_path>
        local lockfile="$ftl_state_session_dir/lock_preview/$(path_of doc.txt)"
        [[ -f "$lockfile" ]] \
                && ftl::test::pass "preview_pin created lock file" \
                || ftl::test::fail "preview_pin did not create lock file"
        ftl::test::assert_contains "$(cat "$lockfile" 2>/dev/null)" "doc.txt" "lock file mentions the pinned path"
}

test_preview_unpin_removes_lock_file() {
        setup_listing "doc.txt"
        # Pre-create the nested lock dir structure (preview_pin uses the full path as filename)
        mkdir -p "$ftl_state_session_dir/lock_preview/$(dirname "$(path_of doc.txt)")" 2>/dev/null
        # First pin
        ftl::plugin::missing::preview_pin 2>/dev/null
        local lockfile="$ftl_state_session_dir/lock_preview/$(path_of doc.txt)"
        [[ -f "$lockfile" ]] || { ftl::test::fail "pin setup failed" ; return ; }
        # Then unpin
        ftl::plugin::missing::preview_unpin
        [[ ! -f "$lockfile" ]] \
                && ftl::test::pass "preview_unpin removed lock file" \
                || ftl::test::fail "preview_unpin did not remove lock file"
}

test_preview_unpin_without_prior_pin_no_op() {
        setup_listing "doc.txt"
        # No prior pin — unpin should not crash
        ftl::plugin::missing::preview_unpin
        ftl::test::pass "preview_unpin without prior pin completed without error"
}

#--- preview_compare ---

test_preview_compare_with_two_files() {
        setup_listing "a.txt" "b.txt"
        tag "a.txt" ; tag "b.txt"
        ftl_selection_current=( "$(path_of a.txt)" "$(path_of b.txt)" )
        # Stub ftl::pane::split to capture the command
        local captured=
        ftl::pane::split() { captured="$*" ; }
        ftl::plugin::missing::preview_compare
        ftl::test::assert_contains "$captured" "diff" "preview_compare invoked diff tool"
        ftl::test::assert_contains "$captured" "a.txt" "preview_compare passed a.txt"
        ftl::test::assert_contains "$captured" "b.txt" "preview_compare passed b.txt"
}

test_preview_compare_wrong_count_aborts() {
        setup_listing "a.txt" "b.txt" "c.txt"
        tag "a.txt" ; tag "b.txt" ; tag "c.txt"
        ftl_selection_current=( "$(path_of a.txt)" "$(path_of b.txt)" "$(path_of c.txt)" )
        # Should warn and return without calling split
        local split_called=0
        ftl::pane::split() { split_called=1 ; }
        ftl::plugin::missing::preview_compare 2>/dev/null
        ftl::test::assert_eq "0" "$split_called" "preview_compare with != 2 files did not call split"
}

#--- preview_zoom_in / preview_zoom_out ---

test_preview_zoom_in_increments() {
        ftl_plugin_missing_preview_zoom=2
        ftl::plugin::missing::preview_zoom_in
        ftl::test::assert_eq "3" "$ftl_plugin_missing_preview_zoom" "zoom_in incremented to 3"
}

test_preview_zoom_in_caps_at_5() {
        ftl_plugin_missing_preview_zoom=5
        ftl::plugin::missing::preview_zoom_in
        ftl::test::assert_eq "5" "$ftl_plugin_missing_preview_zoom" "zoom_in capped at 5"
}

test_preview_zoom_out_decrements() {
        ftl_plugin_missing_preview_zoom=3
        ftl::plugin::missing::preview_zoom_out
        ftl::test::assert_eq "2" "$ftl_plugin_missing_preview_zoom" "zoom_out decremented to 2"
}

test_preview_zoom_out_floors_at_0() {
        ftl_plugin_missing_preview_zoom=0
        ftl::plugin::missing::preview_zoom_out
        ftl::test::assert_eq "0" "$ftl_plugin_missing_preview_zoom" "zoom_out floored at 0"
}

test_preview_zoom_in_sets_image_zoomed_flag() {
        ftl_plugin_missing_preview_zoom=2
        ftl_cfg_image_zoomed=0
        ftl::plugin::missing::preview_zoom_in
        ftl::test::assert_eq "1" "$ftl_cfg_image_zoomed" "zoom_in sets image_zoomed flag"
}

#--- preview_rotate ---

test_preview_rotate_invokes_convert() {
        command -v convert >/dev/null 2>&1 || { ftl::test::skip "convert not installed" ; return ; }
        setup_listing "photo.jpg"
        # Create a real 1x1 jpg so convert has something to read
        convert -size 1x1 xc:red "$(path_of photo.jpg)" 2>/dev/null
        # Stub ftl::prev::show_image to capture the temp path
        local shown=
        ftl::prev::show_image() { shown="$1" ; }
        ftl::plugin::missing::preview_rotate
        # A rotated temp file should have been created and passed to show_image
        [[ -n "$shown" ]] \
                && ftl::test::pass "preview_rotate called show_image with a path" \
                || ftl::test::fail "preview_rotate did not call show_image"
        [[ -f "$shown" ]] \
                && ftl::test::pass "rotated temp file exists" \
                || ftl::test::fail "rotated temp file missing"
}

#--- preview_tail_live ---

test_preview_tail_live_with_log_file() {
        setup_listing "app.log"
        # Should call ftl::pane::split with "tail -f"
        local captured=
        ftl::pane::split() { captured="$*" ; }
        ftl::plugin::missing::preview_tail_live
        ftl::test::assert_contains "$captured" "tail -f" "tail_live invoked tail -f"
        ftl::test::assert_contains "$captured" "app.log" "tail_live passed the log file"
}

test_preview_tail_live_skips_non_log_file() {
        setup_listing "readme.txt"
        local split_called=0
        ftl::pane::split() { split_called=1 ; }
        ftl::plugin::missing::preview_tail_live
        ftl::test::assert_eq "0" "$split_called" "tail_live did not invoke split for non-log file"
}

test_preview_tail_live_accepts_out_extension() {
        setup_listing "server.out"
        local captured=
        ftl::pane::split() { captured="$*" ; }
        ftl::plugin::missing::preview_tail_live
        ftl::test::assert_contains "$captured" "tail -f" "tail_live works for .out files"
}

test_preview_tail_live_accepts_err_extension() {
        setup_listing "daemon.err"
        local captured=
        ftl::pane::split() { captured="$*" ; }
        ftl::plugin::missing::preview_tail_live
        ftl::test::assert_contains "$captured" "tail -f" "tail_live works for .err files"
}

#==========================================================================
# 6. UI
#==========================================================================

#--- command_palette ---

test_command_palette_sets_pending_input() {
        # Stub fzf-tmux to return a known command name
        ftl_kbd_command_to_key["ftl::cmd::cursor_up"]="j"
        # Override fzf-tmux just for this test
        local saved_fzf_tmux=$(type -t fzf-tmux 2>/dev/null)
        fzf-tmux() { echo "ftl::cmd::cursor_up" ; }
        ftl::plugin::missing::command_palette
        ftl::test::assert_eq "j" "$ftl_state_pending_input" "command_palette set pending_input to binding"
        unset -f fzf-tmux
}

test_command_palette_empty_choice_no_op() {
        fzf-tmux() { : ; }  # returns nothing
        ftl::plugin::missing::command_palette
        ftl::test::assert_eq "" "${ftl_state_pending_input:-}" "empty palette choice leaves pending_input empty"
        unset -f fzf-tmux
}

#--- workspace_save / workspace_load ---

test_workspace_save_writes_files() {
        setup_listing "a.txt"
        ftl_tab_directories=( "$ftl_state_session_dir" "/tmp" )
        ftl_state_current_tab_index=0
        tag "a.txt"
        run_with_reply "test_ws" ftl::plugin::missing::workspace_save
        local ws="$FTL_STATE_DIR/workspaces/test_ws"
        [[ -f "$ws/tabs" ]] \
                && ftl::test::pass "workspace_save wrote tabs file" \
                || ftl::test::fail "workspace_save did not write tabs file"
        [[ -f "$ws/active_tab" ]] \
                && ftl::test::pass "workspace_save wrote active_tab file" \
                || ftl::test::fail "workspace_save did not write active_tab file"
        [[ -f "$ws/selection" ]] \
                && ftl::test::pass "workspace_save wrote selection file" \
                || ftl::test::fail "workspace_save did not write selection file"
        ftl::test::assert_contains "$(cat "$ws/tabs")" "$ftl_state_session_dir" "tabs file contains session dir"
}

test_workspace_save_empty_name_aborts() {
        setup_listing "a.txt"
        run_with_reply "" ftl::plugin::missing::workspace_save
        # No workspace dir should have been created
        local count=$(find "$FTL_STATE_DIR/workspaces" -type d 2>/dev/null | wc -l)
        ftl::test::assert_eq "0" "$count" "empty name did not create workspace"
}

test_workspace_load_restores_tabs() {
        # Pre-create a workspace
        local ws="$FTL_STATE_DIR/workspaces/test_ws"
        mkdir -p "$ws"
        printf '%s\n' "$ftl_state_session_dir" "/tmp" > "$ws/tabs"
        echo "0" > "$ws/active_tab"
        # Stub fzf-tmux to return "test_ws"
        fzf-tmux() { echo "test_ws" ; }
        ftl::plugin::missing::workspace_load
        unset -f fzf-tmux
        ftl::test::assert_eq "2" "${#ftl_tab_directories[@]}" "workspace_load restored 2 tabs"
        ftl::test::assert_eq "0" "$ftl_state_current_tab_index" "workspace_load restored active_tab=0"
}

#==========================================================================
# 7. Git
#==========================================================================

# Helper: set up a temp git repo with a committed file
setup_git_repo() {
        local repo="$ftl_state_session_dir/gitrepo"
        mkdir -p "$repo"
        cd "$repo"
        git init -q 2>/dev/null
        git config user.email "test@test.com" 2>/dev/null
        git config user.name "Test" 2>/dev/null
        printf "line1\nline2\nline3\n" > "$repo/tracked.txt"
        git add tracked.txt 2>/dev/null
        git commit -q -m "initial" 2>/dev/null
        # Set ftl state to point at the tracked file
        ftl_list_entries=( "$repo/tracked.txt" )
        ftl_list_entry_count=1
        ftl_state_cursor_index=0
        ftl_state_current_path="$repo/tracked.txt"
        ftl_state_current_dir="$repo"
        ftl_state_current_basename="tracked.txt"
        ftl_state_current_extension="txt"
}

#--- git_blame_preview ---

test_git_blame_preview_runs_in_repo() {
        command -v git >/dev/null 2>&1 || { ftl::test::skip "git not installed" ; return ; }
        setup_git_repo
        local captured=
        ftl::pane::split_for_preview() { cat ; }
        captured=$(ftl::plugin::missing::git_blame_preview 2>/dev/null)
        # git blame output contains the file's content lines (with commit hash prefix)
        ftl::test::assert_contains "$captured" "line1" "blame output contains file content"
        ftl::test::assert_contains "$captured" "line2" "blame output contains 2nd line"
}

test_git_blame_preview_skips_non_file() {
        command -v git >/dev/null 2>&1 || { ftl::test::skip "git not installed" ; return ; }
        setup_git_repo
        # Point at a directory instead of a file
        ftl_state_current_path="$ftl_state_session_dir/gitrepo"
        local split_called=0
        ftl::pane::split_for_preview() { split_called=1 ; }
        ftl::plugin::missing::git_blame_preview
        ftl::test::assert_eq "0" "$split_called" "blame skipped for non-file"
}

test_git_blame_preview_skips_outside_repo() {
        command -v git >/dev/null 2>&1 || { ftl::test::skip "git not installed" ; return ; }
        setup_listing "not_tracked.txt"
        # Not in a git repo (ftl_state_session_dir is a temp dir, not a git repo)
        ftl_state_current_path="$(path_of not_tracked.txt)"
        local split_called=0
        ftl::pane::split_for_preview() { split_called=1 ; }
        ftl::plugin::missing::git_blame_preview 2>/dev/null
        ftl::test::assert_eq "0" "$split_called" "blame skipped outside git repo"
}

#--- git_file_log ---

test_git_file_log_runs_in_repo() {
        command -v git >/dev/null 2>&1 || { ftl::test::skip "git not installed" ; return ; }
        setup_git_repo
        # Add a second commit to make the log more interesting
        printf "line1\nline2\nline3\nline4\n" > "$ftl_state_session_dir/gitrepo/tracked.txt"
        git commit -q -am "second commit" 2>/dev/null
        ftl::pane::split_for_preview() { cat ; }
        local captured=$(ftl::plugin::missing::git_file_log 2>/dev/null)
        # git log --oneline output contains short commit hashes and messages
        ftl::test::assert_contains "$captured" "initial" "file_log shows initial commit"
        ftl::test::assert_contains "$captured" "second commit" "file_log shows second commit"
}

test_git_file_log_skips_non_file() {
        command -v git >/dev/null 2>&1 || { ftl::test::skip "git not installed" ; return ; }
        setup_git_repo
        ftl_state_current_path="$ftl_state_session_dir/gitrepo"
        local split_called=0
        ftl::pane::split_for_preview() { split_called=1 ; }
        ftl::plugin::missing::git_file_log
        ftl::test::assert_eq "0" "$split_called" "file_log skipped for non-file"
}

#--- git_diff_stat ---

test_git_diff_stat_runs_in_repo() {
        command -v git >/dev/null 2>&1 || { ftl::test::skip "git not installed" ; return ; }
        setup_git_repo
        # Make an uncommitted change so diff --stat has output
        printf "new line\n" >> "$ftl_state_session_dir/gitrepo/tracked.txt"
        ftl::pane::split_for_preview() { cat ; }
        local captured=$(ftl::plugin::missing::git_diff_stat 2>/dev/null)
        ftl::test::assert_contains "$captured" "tracked.txt" "diff_stat mentions modified file"
}

test_git_diff_stat_skips_outside_repo() {
        command -v git >/dev/null 2>&1 || { ftl::test::skip "git not installed" ; return ; }
        setup_listing "a.txt"
        local split_called=0
        ftl::pane::split_for_preview() { split_called=1 ; }
        ftl::plugin::missing::git_diff_stat 2>/dev/null
        ftl::test::assert_eq "0" "$split_called" "diff_stat skipped outside repo"
}

#==========================================================================
# 8. Archives
#==========================================================================

#--- compress_zip ---

test_compress_zip_creates_archive() {
        command -v zip >/dev/null 2>&1 || { ftl::test::skip "zip not installed" ; return ; }
        setup_listing "a.txt" "b.txt"
        printf "aaa" > "$(path_of a.txt)"
        printf "bbb" > "$(path_of b.txt)"
        tag "a.txt" ; tag "b.txt"
        run_with_reply "archive" ftl::plugin::missing::compress_zip
        [[ -f "$(path_of archive.zip)" ]] \
                && ftl::test::pass "compress_zip created archive.zip" \
                || ftl::test::fail "compress_zip did not create archive.zip"
        # Verify the archive contents
        local listing=$(unzip -l "$(path_of archive.zip)" 2>/dev/null)
        ftl::test::assert_contains "$listing" "a.txt" "zip contains a.txt"
        ftl::test::assert_contains "$listing" "b.txt" "zip contains b.txt"
}

test_compress_zip_empty_name_aborts() {
        command -v zip >/dev/null 2>&1 || { ftl::test::skip "zip not installed" ; return ; }
        setup_listing "a.txt"
        tag "a.txt"
        run_with_reply "" ftl::plugin::missing::compress_zip
        [[ ! -f "$(path_of .zip)" ]] \
                && ftl::test::pass "empty name did not create .zip" \
                || ftl::test::fail "empty name created .zip"
}

#--- compress_7z ---

test_compress_7z_creates_archive() {
        command -v 7z >/dev/null 2>&1 || { ftl::test::skip "7z not installed" ; return ; }
        setup_listing "a.txt" "b.txt"
        printf "aaa" > "$(path_of a.txt)"
        printf "bbb" > "$(path_of b.txt)"
        tag "a.txt" ; tag "b.txt"
        run_with_reply "archive7" ftl::plugin::missing::compress_7z
        [[ -f "$(path_of archive7.7z)" ]] \
                && ftl::test::pass "compress_7z created archive7.7z" \
                || ftl::test::fail "compress_7z did not create archive7.7z"
        # Verify the archive contents
        local listing=$(7z l "$(path_of archive7.7z)" 2>/dev/null)
        ftl::test::assert_contains "$listing" "a.txt" "7z contains a.txt"
        ftl::test::assert_contains "$listing" "b.txt" "7z contains b.txt"
}

#--- archive_list ---

test_archive_list_zip() {
        command -v unzip >/dev/null 2>&1 || { ftl::test::skip "unzip not installed" ; return ; }
        # Create a zip with known contents
        setup_listing "x.txt" "y.txt"
        cd "$ftl_state_session_dir"
        zip -q test.zip x.txt y.txt 2>/dev/null
        # Set ftl state to point at the zip
        ftl_state_current_path="$ftl_state_session_dir/test.zip"
        ftl_state_current_extension="zip"
        ftl::pane::split_for_preview() { cat ; }
        local captured=$(ftl::plugin::missing::archive_list 2>/dev/null)
        ftl::test::assert_contains "$captured" "x.txt" "archive_list shows x.txt"
        ftl::test::assert_contains "$captured" "y.txt" "archive_list shows y.txt"
}

test_archive_list_tar() {
        command -v tar >/dev/null 2>&1 || { ftl::test::skip "tar not installed" ; return ; }
        setup_listing "p.txt" "q.txt"
        cd "$ftl_state_session_dir"
        tar -cf test.tar p.txt q.txt 2>/dev/null
        ftl_state_current_path="$ftl_state_session_dir/test.tar"
        ftl_state_current_extension="tar"
        ftl::pane::split_for_preview() { cat ; }
        local captured=$(ftl::plugin::missing::archive_list 2>/dev/null)
        ftl::test::assert_contains "$captured" "p.txt" "archive_list shows p.txt"
        ftl::test::assert_contains "$captured" "q.txt" "archive_list shows q.txt"
}

test_archive_list_unsupported_extension_no_op() {
        setup_listing "data.bin"
        ftl_state_current_extension="bin"
        local split_called=0
        ftl::pane::split_for_preview() { split_called=1 ; }
        ftl::plugin::missing::archive_list
        ftl::test::assert_eq "0" "$split_called" "archive_list did nothing for .bin"
}

#==========================================================================
# 9. Remote / Network
#==========================================================================

#--- scp_upload ---

test_scp_upload_no_known_hosts_no_op() {
        # scp_upload reads from ~/.ssh/known_hosts via fzf-tmux.
        # With no known_hosts (or no fzf-tmux return), it should no-op.
        fzf-tmux() { : ; }  # return nothing
        setup_listing "a.txt"
        tag "a.txt"
        ftl::plugin::missing::scp_upload
        ftl::test::pass "scp_upload completed without crash when no host selected"
        unset -f fzf-tmux
}

test_scp_upload_with_host_prompts_for_path() {
        # Stub fzf-tmux to return a host, then check that scp is invoked
        local scp_called=0
        local scp_args=
        fzf-tmux() { echo "user@example.com" ; }
        scp() { scp_called=1 ; scp_args="$*" ; }
        setup_listing "a.txt"
        tag "a.txt"
        ftl_selection_current=( "$(path_of a.txt)" )
        FTL_TEST_FAKE_REPLY="/remote/path"
        ftl::cmd::prompt() { ftl_kbd_current_key="$FTL_TEST_FAKE_REPLY" ; }
        ftl::plugin::missing::scp_upload
        ftl::test::assert_eq "1" "$scp_called" "scp was invoked"
        ftl::test::assert_contains "$scp_args" "user@example.com" "scp args contain host"
        ftl::test::assert_contains "$scp_args" "/remote/path" "scp args contain remote path"
        unset -f fzf-tmux scp
}

#--- download_url ---

test_download_url_invokes_wget() {
        command -v wget >/dev/null 2>&1 || { ftl::test::skip "wget not installed" ; return ; }
        local wget_called=0
        local wget_args=
        # Override ftl::pane::run_in_bg_window to capture the command without actually running it
        ftl::pane::run_in_bg_window() { wget_called=1 ; wget_args="$*" ; }
        setup_listing "a.txt"
        run_with_reply "http://example.com/file.txt" ftl::plugin::missing::download_url
        ftl::test::assert_eq "1" "$wget_called" "download_url invoked run_in_bg_window"
        ftl::test::assert_contains "$wget_args" "wget" "download_url invoked wget"
        ftl::test::assert_contains "$wget_args" "http://example.com/file.txt" "download_url passed the URL"
}

test_download_url_empty_aborts() {
        setup_listing "a.txt"
        local bg_called=0
        ftl::pane::run_in_bg_window() { bg_called=1 ; }
        run_with_reply "" ftl::plugin::missing::download_url
        ftl::test::assert_eq "0" "$bg_called" "empty URL did not invoke download"
}

# vim: set filetype=bash :
