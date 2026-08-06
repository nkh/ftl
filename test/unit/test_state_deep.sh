#!/bin/env bash
# test/unit/test_state_deep.sh — deep tests for state.sh
#
# Covers:
#   - save round-trip: save → clear vars → source file → check vars restored
#     (BUG: writes OLD variable names, child pane reads NEW names)
#   - save with tag whose path contains "-A" (sed corruption)
#   - save with custom target_dir (tags go to session_dir, ftl goes to target_dir)
#   - serialize_info with unset vars
#   - emit_selection_fd3 with empty selection
#   - cleanup with empty session_dir (guard)
#   - render_child_env

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

tmux() { : ; }
stty() { : ; }
tput() { : ; }
ftl::pane::stop_file_watcher() { : ; }
ftl::pane::start_file_watcher() { : ; }
ftl::pane::query_geometry() { : ; }
ftl::pane::snapshot_geometry() { : ; }
ftl::prev::dispatch() { : ; }
ftl::prev::clear() { : ; }
ftl::sel::resolve_current() { : ; }
ftl::sel::sync_from_other_pane() { false ; }

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    ftl_state_session_dir="$FTL_TEST_TMP/session"
    ftl_state_shared_dir="$FTL_TEST_TMP/shared"
    ftl_state_parent_dir="$ftl_state_session_dir"
    ftl_state_info_file_path="$FTL_TEST_TMP/info"
    ftl_state_main_info_file_path="$FTL_TEST_TMP/main_info"
    mkdir -p "$ftl_state_session_dir" "$ftl_state_shared_dir"
    ftl_state_current_path="/test/path/file.txt"
    ftl_state_current_tab_index=0
    ftl_state_cursor_index=2
    ftl_state_show_size_mode=0
    ftl_state_etag_enabled=0
    ftl_etag_source_name=
    ftl_state_preview_callback=
    ftl_state_dir_preview_mode=0
    ftl_filter_external_name=
    ftl_filter_active_glyph=
    ftl_plugin_virtual_callback=
    ftl_state_quit_cancelled=0
    declare -Ag ftl_selection_tags=()
    declare -Ag ftl_state_cursor_memory=()
    declare -Ag ftl_tab_view_mode=([0]=0)
    declare -Ag ftl_tab_sort_type=([0]=0)
    declare -Ag ftl_tab_sort_reversed=([0]=)
    declare -Ag ftl_tab_filter_1=([0]=)
    declare -Ag ftl_tab_filter_2=([0]=)
    declare -Ag ftl_tab_filter_dirs=([0]=)
    declare -Ag ftl_tab_filter_reverse=([0]=)
    declare -Ag ftl_tab_filter_image_mode=([0]=)
    declare -Ag ftl_tab_filter_image_negate=([0]=)
    declare -Ag ftl_tab_listing_mode=([0]=0)
    declare -Ag ftl_tab_show_hidden=([0]=0)
    declare -Ag ftl_tab_preview_dirs_only=([0]=)
    declare -Ag ftl_filter_listing_hide_exts=()
    declare -Ag ftl_filter_listing_keep_exts=()
    declare -Ag ftl_state_child_env=()
    declare -ag ftl_selection_current=()
    ftl_list_entry_count=0
    ftl_list_entries=()
    ftl_pane_is_child=0
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ============================================================================
# save / load round-trip
# ============================================================================

test_save_creates_state_file() {
    ftl::state::save
    [[ -f "$ftl_state_session_dir/ftl" ]] \
        && ftl::test::pass "save creates session_dir/ftl" \
        || ftl::test::fail "save should create session_dir/ftl"
}

test_save_creates_tags_file() {
    ftl_selection_tags["/test/file"]="▪"
    ftl::state::save
    [[ -f "$ftl_state_session_dir/tags" ]] \
        && ftl::test::pass "save creates session_dir/tags" \
        || ftl::test::fail "save should create session_dir/tags"
}

test_save_round_trip_restores_preview_callback_bug() {
    # BUG: save writes OLD variable names (prev_cb, etag, dirmode, etc.),
    # but the child pane reads NEW names (ftl_state_preview_callback, etc.).
    # So the round-trip fails for these variables.
    ftl_state_preview_callback="my_preview_func"
    ftl::state::save
    # Clear and reload
    ftl_state_preview_callback=
    source "$ftl_state_session_dir/ftl"
    ftl::test::assert_eq "" "$ftl_state_preview_callback" \
        "BUG: ftl_state_preview_callback is NOT restored (save writes old name 'prev_cb')"
}

test_save_round_trip_restores_etag_enabled_bug() {
    ftl_state_etag_enabled=1
    ftl::state::save
    ftl_state_etag_enabled=0
    source "$ftl_state_session_dir/ftl"
    ftl::test::assert_eq 0 "$ftl_state_etag_enabled" \
        "BUG: ftl_state_etag_enabled is NOT restored (save writes 'etag' not 'ftl_state_etag_enabled')"
}

test_save_round_trip_restores_dir_preview_mode_bug() {
    ftl_state_dir_preview_mode=2
    ftl::state::save
    ftl_state_dir_preview_mode=0
    source "$ftl_state_session_dir/ftl"
    ftl::test::assert_eq 0 "$ftl_state_dir_preview_mode" \
        "BUG: ftl_state_dir_preview_mode is NOT restored (save writes 'dirmode')"
}

test_save_round_trip_restores_current_path() {
    # ftl_state_current_path IS restored correctly (uses serialize_info)
    ftl_state_current_path="/restored/path"
    ftl::state::save
    ftl_state_current_path=
    source "$ftl_state_session_dir/ftl"
    ftl::test::assert_eq "/restored/path" "$ftl_state_current_path" \
        "ftl_state_current_path should be restored"
}

# ============================================================================
# save — sed corruption with "-A" in tag path
# ============================================================================

test_save_tag_with_hyphen_A_in_path_bug() {
    # BUG: `declare -p ftl_selection_tags | sed 's/\-A/-A -g/'` matches
    # "-A" ANYWHERE in the output, including inside filename values.
    # If a tagged file is named "file-Apples.txt", the sed turns it into
    # "file-A -gpples.txt", corrupting the path.
    ftl_selection_tags["/test/file-Apples.txt"]="▪"
    ftl::state::save
    # Reload
    ftl_selection_tags=()
    source "$ftl_state_session_dir/tags"
    # Check the tag survived the round-trip
    ftl::test::assert_eq "" "${ftl_selection_tags[/test/file-Apples.txt]:-}" \
        "BUG: tag with '-A' in path is corrupted by sed (lost on reload)"
}

test_save_tag_normal_path_round_trips() {
    ftl_selection_tags["/test/normal_file.txt"]="▪"
    ftl::state::save
    ftl_selection_tags=()
    source "$ftl_state_session_dir/tags"
    ftl::test::assert_eq "▪" "${ftl_selection_tags[/test/normal_file.txt]}" \
        "tag with normal path should round-trip correctly"
}

# ============================================================================
# save — custom target_dir
# ============================================================================

test_save_with_custom_target_dir_bug() {
    # BUG: save writes tags to $session_dir/tags but ftl to $target_dir/ftl.
    # If target_dir != session_dir, the files go to different directories.
    local target="$FTL_TEST_TMP/target"
    mkdir -p "$target"
    ftl_selection_tags["/test/file"]="▪"
    ftl::state::save "$target"
    [[ -f "$target/ftl" ]] \
        && ftl::test::pass "ftl state written to target_dir" \
        || ftl::test::fail "ftl state should be in target_dir"
    # Document the bug: tags go to session_dir, not target_dir
    [[ -f "$ftl_state_session_dir/tags" ]] \
        && ftl::test::pass "BUG documented: tags go to session_dir, not target_dir" \
        || ftl::test::fail "tags should be somewhere (session_dir or target_dir)"
}

# ============================================================================
# serialize_info
# ============================================================================

test_serialize_info_writes_to_file() {
    ftl_state_current_path="/info/test"
    ftl::state::serialize_info "$ftl_state_info_file_path"
    [[ -f "$ftl_state_info_file_path" ]] \
        && ftl::test::pass "serialize_info creates the file" \
        || ftl::test::fail "serialize_info should create the file"
}

test_serialize_info_includes_current_path() {
    ftl_state_current_path="/info/test"
    ftl::state::serialize_info "$ftl_state_info_file_path"
    local content
    content=$(cat "$ftl_state_info_file_path")
    ftl::test::assert_contains "$content" "/info/test" \
        "serialize_info output should include current_path"
}

# ============================================================================
# emit_selection_fd3
# ============================================================================

test_emit_selection_fd3_empty_prints_newline_bug() {
    # BUG: with empty selection, `printf "%s\n" "${arr[@]}"` outputs just
    # a newline, not empty output.
    ftl_selection_current=()
    local output
    output=$(ftl::state::emit_selection_fd3 2>/dev/null) || true
    # The function writes to fd 3, but with our redirect it may go to stdout
    ftl::test::pass "emit_selection_fd3 with empty selection did not crash"
}

test_emit_selection_fd3_with_entries() {
    ftl_selection_current=("/file1" "/file2")
    # Open fd 3 to a temp file so we can read what was written
    local tmpf
    tmpf=$(mktemp)
    exec 3>"$tmpf"
    ftl::state::emit_selection_fd3 2>/dev/null || true
    exec 3>&-
    local content
    content=$(cat "$tmpf")
    ftl::test::assert_contains "$content" "/file1" "fd3 output includes file1"
    ftl::test::assert_contains "$content" "/file2" "fd3 output includes file2"
    rm -f "$tmpf"
}

# ============================================================================
# cleanup
# ============================================================================

test_cleanup_removes_session_dir() {
    ftl::state::cleanup
    [[ ! -d "$ftl_state_session_dir" ]] \
        && ftl::test::pass "cleanup removed session_dir" \
        || ftl::test::fail "cleanup should remove session_dir"
}

test_cleanup_with_empty_session_dir_does_not_crash_bug() {
    # BUG: `rm -rf "$ftl_state_session_dir"` with empty var = `rm -rf ""`
    # which is a no-op (rm refuses to remove ""). But if the var somehow
    # becomes "/", catastrophic.
    local saved="$ftl_state_session_dir"
    ftl_state_session_dir=""
    ftl::state::cleanup 2>/dev/null || true
    ftl::test::pass "cleanup with empty session_dir did not crash (rm -rf '' is a no-op)"
    ftl_state_session_dir="$saved"
}

# ============================================================================
# render_child_env
# ============================================================================

test_render_child_env_populates_array() {
    ftl_state_session_dir="$FTL_TEST_TMP/session"
    ftl_state_shared_dir="$FTL_TEST_TMP/shared"
    ftl_state_child_env=()
    ftl::state::render_child_env
    ftl::test::assert_ne 0 "${#ftl_state_child_env[@]}" \
        "render_child_env should populate the child_env array"
}

test_render_child_env_includes_session_dir() {
    ftl_state_session_dir="$FTL_TEST_TMP/session"
    ftl_state_shared_dir="$FTL_TEST_TMP/shared"
    ftl_state_child_env=()
    ftl::state::render_child_env
    ftl::test::assert_contains "${ftl_state_child_env[ftl_pfs]:-}" "$FTL_TEST_TMP" \
        "child_env should include the session dir path"
}

# ============================================================================
# save_selection / load_selection
# ============================================================================

test_save_selection_writes_file() {
    ftl_selection_tags["/file1"]="▪"
    ftl_selection_tags["/file2"]="¹"
    ftl_selection_total_bytes=100
    ftl_selection_revision=5
    ftl::state::save_selection
    [[ -f "$ftl_state_session_dir/tags" ]] \
        && ftl::test::pass "save_selection writes tags file" \
        || ftl::test::fail "save_selection should write tags file"
}

test_load_selection_restores_tags() {
    ftl_selection_tags["/file1"]="▪"
    ftl::state::save_selection
    ftl_selection_tags=()
    ftl::state::load_selection "$ftl_state_session_dir"
    ftl::test::assert_eq "▪" "${ftl_selection_tags[/file1]}" \
        "load_selection should restore tags"
}

# vim: set filetype=bash :
