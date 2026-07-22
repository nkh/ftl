#!/bin/env bash
# test/unit/test_preview.sh — tests for the preview module
#
# Tests ftl::prev::clear, ftl::prev::show_in_vim, ftl::prev::show_image,
# ftl::prev::dispatch, and ftl::prev::sync_and_dispatch. tmux is mocked.

# Source dependencies (preview calls into state, pane, util)
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/pane.sh"
source "$FTL_CFG/etc/core/modules/preview.sh"

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    ftl_pane_self_id="%0"
    ftl_pane_primary_id="%0"
    ftl_pane_is_primary=1
    ftl_pane_is_child=0
    ftl_pane_preview_id=
    ftl_pane_fixed_preview_id=
    ftl_preview_is_dir_ftl=
    ftl_preview_is_vim=
    ftl_preview_is_image_daemon=
    ftl_state_preview_pane_visible=0
    ftl_state_external_viewer_mode=0
    ftl_state_alt_preview_mode=0
    ftl_state_session_dir="$FTL_TEST_TMP/session"
    ftl_state_shared_dir="$FTL_TEST_TMP/session/prev"
    ftl_state_parent_dir="$FTL_TEST_TMP/parent"
    mkdir -p "$ftl_state_session_dir" "$ftl_state_shared_dir" "$ftl_state_parent_dir"
    ftl_cfg_editor="vim"
    declare -Ag ftl_view_vim_tail_commands=()
    ftl_cfg_image_zoomed=""
    ftl_cfg_image_clean_borders=""
    ftl_cfg_char_width_px=10
    ftl_cfg_char_height_px=20
    # Override the show_internal/show_external to no-ops (already no-ops by default)
    tmux() { : ; }
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# Test: clear with a preview id kills the pane and resets state
test_clear_with_preview_id() {
    ftl_pane_preview_id="%9"
    ftl_preview_is_vim=1
    ftl_preview_is_image_daemon=1
    ftl_preview_is_dir_ftl=1
    local killed=
    tmux() { killed="yes" ; }
    ftl::prev::clear ""
    ftl::test::assert_eq "" "$ftl_pane_preview_id" "preview id should be cleared"
    ftl::test::assert_eq "" "$ftl_preview_is_vim" "vim flag should be cleared"
    ftl::test::assert_eq "" "$ftl_preview_is_image_daemon" "image daemon flag should be cleared"
    ftl::test::assert_eq "" "$ftl_preview_is_dir_ftl" "dir ftl flag should be cleared"
    ftl::test::assert_eq "yes" "$killed" "tmux killp should have been called"
}

# Test: clear with no preview id is a no-op for tmux
test_clear_no_preview_id() {
    ftl_pane_preview_id=
    local killed=
    tmux() { killed="yes" ; }
    ftl::prev::clear ""
    ftl::test::assert_eq "" "$killed" "tmux should not be called when no preview id"
}

# Test: clear with arg sets preview_pane_visible
test_clear_sets_visible_flag() {
    ftl_pane_preview_id=
    ftl_state_preview_pane_visible=1
    ftl::prev::clear 0
    ftl::test::assert_eq "0" "$ftl_state_preview_pane_visible" \
        "should set preview_pane_visible to 0"
}

# Test: clear also clears the fixed preview pane
test_clear_clears_fixed() {
    ftl_pane_preview_id=
    ftl_pane_fixed_preview_id="%7"
    local killed_target=
    tmux() { killed_target="$3" ; }  # capture the -t value (3rd arg)
    ftl::prev::clear ""
    ftl::test::assert_eq "%7" "$killed_target" "should kill fixed preview %7"
    ftl::test::assert_eq "" "$ftl_pane_fixed_preview_id" "fixed id should be cleared"
}

# Test: show_in_vim sends :e to existing vim preview
test_show_in_vim_existing() {
    ftl_preview_is_vim=1
    ftl_pane_preview_id="%5"
    ftl_view_vim_tail_commands["/tmp/file.txt"]=""
    local sent=
    tmux() {
        if [[ "$1" == "send" ]] ; then
            sent="$*"
        fi
    }
    ftl::prev::show_in_vim "/tmp/file.txt"
    ftl::test::assert_contains "$sent" ":e" "should send :e command"
    ftl::test::assert_contains "$sent" "/tmp/file.txt" "should include the file path"
    ftl::test::assert_contains "$sent" "%5" "should target the preview pane"
}

# Test: show_in_vim spawns new vim when not already running
test_show_in_vim_spawn() {
    ftl_preview_is_vim=0
    ftl_pane_preview_id=
    ftl_view_vim_tail_commands["/tmp/file.txt"]=""
    local split_called=
    # Override split_or_respawn to capture the call
    ftl::pane::split_or_respawn() { split_called="$1" ; }
    ftl::prev::show_in_vim "/tmp/file.txt"
    ftl::test::assert_contains "$split_called" "vim" "should spawn vim"
    ftl::test::assert_contains "$split_called" "/tmp/file.txt" "should include the file"
    ftl::test::assert_eq "1" "$ftl_preview_is_vim" "should set vim flag after spawn"
}

# Test: show_image sends to existing daemon
test_show_image_existing() {
    ftl_preview_is_image_daemon=1
    ftl_pane_preview_id="%3"
    local sent=
    tmux() {
        if [[ "$1" == "send" ]] ; then
            sent="$*"
        fi
    }
    ftl::prev::show_image "/tmp/pic.png"
    ftl::test::assert_contains "$sent" "/tmp/pic.png" "should send image path"
    ftl::test::assert_contains "$sent" "%3" "should target preview pane"
}

# Test: show_image spawns new daemon when not running
test_show_image_spawn() {
    ftl_preview_is_image_daemon=0
    ftl_pane_preview_id=
    local split_called=
    ftl::pane::split_or_respawn() { split_called="$1" ; }
    ftl::prev::show_image "/tmp/pic.png"
    ftl::test::assert_contains "$split_called" "ftli" "should spawn ftli"
    ftl::test::assert_contains "$split_called" "/tmp/pic.png" "should include image path"
    ftl::test::assert_eq "1" "$ftl_preview_is_image_daemon" "should set daemon flag after spawn"
}

# Test: dispatch in primary mode with preview visible calls show_internal
test_dispatch_primary_internal() {
    ftl_pane_is_primary=1
    ftl_state_preview_pane_visible=1
    ftl_state_external_viewer_mode=0
    local internal_called=
    ftl::prev::show_internal() { internal_called=1 ; }
    ftl::prev::dispatch
    ftl::test::assert_eq "1" "$internal_called" "show_internal should be called"
    ftl::test::assert_eq "0" "$ftl_state_alt_preview_mode" \
        "alt preview mode should be reset"
}

# Test: dispatch in primary mode with external viewer calls show_external
test_dispatch_primary_external() {
    ftl_pane_is_primary=1
    ftl_state_preview_pane_visible=0
    ftl_state_external_viewer_mode=1
    local external_called=
    ftl::prev::show_external() { external_called=1 ; }
    ftl::prev::dispatch
    ftl::test::assert_eq "1" "$external_called" "show_external should be called"
    ftl::test::assert_eq "0" "$ftl_state_external_viewer_mode" \
        "external viewer mode should be reset"
}

# Test: dispatch in child mode writes to shared dir and signals parent
test_dispatch_child_mode() {
    ftl_pane_is_primary=0
    ftl_pane_is_child=1
    ftl_pane_self_id="%5"
    ftl_pane_primary_id="%1"
    ftl_state_session_dir="$FTL_TEST_TMP/child_session"
    ftl_state_shared_dir="$FTL_TEST_TMP/shared"
    mkdir -p "$ftl_state_session_dir" "$ftl_state_shared_dir"
    # state::save writes tags; ensure ftl_list_entry_count=0 to short-circuit
    ftl_list_entry_count=0
    declare -Ag ftl_selection_tags=()
    ftl_selection_revision=0
    local sent=
    tmux() {
        if [[ "$1" == "send" ]] ; then
            sent="$*"
        fi
    }
    ftl::prev::dispatch
    ftl::test::assert_eq "$ftl_state_session_dir" "$(cat "$ftl_state_shared_dir/fs")" \
        "should write session dir to shared fs"
    ftl::test::assert_eq "%5" "$(cat "$ftl_state_shared_dir/pane")" \
        "should write self id to shared pane"
    ftl::test::assert_contains "$sent" "%1" "should signal primary pane"
}

# Test: sync_and_dispatch reads the other session's fs pointer
test_sync_and_dispatch_reads_fs() {
    # Set up a "other" session dir with a minimal ftl file
    local other="$FTL_TEST_TMP/other_session"
    mkdir -p "$other"
    cat >"$other/ftl" <<EOF
loaded_var=synced_value
ftl_state_current_path=
sdir=
sindex=
EOF
    echo "$other" >"$ftl_state_shared_dir/fs"

    # Mock sync_from_other_pane (which is in selection.sh)
    ftl::sel::sync_from_other_pane() { : ; }
    # Mock list::change_dir (called in non-"prev" branch)
    ftl::list::change_dir() { : ; }

    ftl::prev::sync_and_dispatch "other"
    ftl::test::assert_eq "synced_value" "$loaded_var" \
        "should source the other session's ftl file"
}
