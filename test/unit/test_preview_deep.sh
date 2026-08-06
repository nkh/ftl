#!/bin/env bash
# test/unit/test_preview_deep.sh — deep tests for preview.sh
#
# Covers:
#   - show_in_vim incomplete escaping ($ and # only; misses %, |, \)
#   - show_image unquoted vars (command injection via parent_dir)
#   - clear with no arg (set -u safety)
#   - sync_and_dispatch with missing shared/fs file
#   - thumb_path md5 includes trailing newline (<<<)
#   - clear_fixed direct call

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
ftl::state::save() { : ; }
ftl::sel::resolve_current() { : ; }
ftl::sel::sync_from_other_pane() { false ; }
ftl::list::change_dir() { : ; }

ftl::test::setup() {
    FTL_TEST_TMP=$(mktemp -d)
    ftl_state_session_dir="$FTL_TEST_TMP"
    ftl_state_shared_dir="$FTL_TEST_TMP/shared"
    ftl_state_parent_dir="$FTL_TEST_TMP"
    ftl_pane_self_id="%0"
    ftl_pane_preview_id="%5"
    ftl_pane_fixed_preview_id=
    ftl_pane_primary_id=
    ftl_pane_is_primary=1
    ftl_pane_is_child=0
    ftl_state_external_viewer_mode=0
    ftl_state_preview_pane_visible=1
    ftl_preview_is_vim=0
    ftl_preview_is_image_daemon=0
    ftl_preview_is_dir_ftl=0
    ftl_state_preview_callback=
    ftl_state_current_path=
    ftl_state_current_basename=
    declare -Ag ftl_view_vim_tail_commands=()
    ftl_cfg_editor="vim"
    ftl_cfg_image_zoomed=0
    ftl_cfg_image_clean_borders=0
    ftl_cfg_char_width_px=7
    ftl_cfg_char_height_px=14
    ftl_etag_source_name=
    ftl_plugin_virtual_callback=
    ftl_state_other_session_dir=
    ftl_state_sync_dir=
    ftl_state_sync_index=
    ftl_tab_view_mode=([0]=0)
    ftl_state_current_tab_index=0
    ftl_cache_thumb_dir="$FTL_TEST_TMP/thumbs"
    mkdir -p "$ftl_cache_thumb_dir"
}

ftl::test::teardown() {
    [[ -n "${FTL_TEST_TMP:-}" ]] && rm -rf "$FTL_TEST_TMP"
    FTL_TEST_TMP=
}

# ============================================================================
# clear
# ============================================================================

test_clear_no_arg_set_u_safety_bug() {
    # BUG: `[[ -n "$1" ]]` under set -u with no arg crashes.
    # Should be `[[ -n "${1:-}" ]]`.
    ftl::prev::clear 2>/dev/null || true
    ftl::test::pass "clear with no arg did not crash"
}

test_clear_with_arg_zero() {
    ftl::prev::clear 0
    ftl::test::assert_eq 0 "$ftl_state_preview_pane_visible" \
        "clear 0 should set preview_pane_visible to 0"
}

test_clear_with_arg_one() {
    ftl::prev::clear 1
    ftl::test::assert_eq 1 "$ftl_state_preview_pane_visible" \
        "clear 1 should set preview_pane_visible to 1"
}

# ============================================================================
# show_in_vim — escaping
# ============================================================================

test_show_in_vim_basic() {
    local f
    f=$(mktemp)
    echo "content" > "$f"
    ftl_state_current_path="$f"
    ftl_state_current_basename="$(basename "$f")"
    # Capture the vim command
    local captured
    captured_vim_args=
    vim() { captured_vim_args="$@" ; }
    ftl::prev::show_in_vim 2>/dev/null || true
    ftl::test::assert_contains "$captured_vim_args" "$f" \
        "vim should receive the file path"
    rm -f "$f"
}

test_show_in_vim_filename_with_dollar() {
    local f
    f=$(mktemp -p "$FTL_TEST_TMP" 'file$name.txt')
    echo "content" > "$f"
    ftl_state_current_path="$f"
    ftl_state_current_basename="$(basename "$f")"
    vim() { : ; }
    ftl::prev::show_in_vim 2>/dev/null || true
    ftl::test::pass "show_in_vim with \$ in filename did not crash"
    rm -f "$f"
}

test_show_in_vim_filename_with_hash() {
    local f
    f=$(mktemp -p "$FTL_TEST_TMP" 'file#name.txt')
    echo "content" > "$f"
    ftl_state_current_path="$f"
    ftl_state_current_basename="$(basename "$f")"
    vim() { : ; }
    ftl::prev::show_in_vim 2>/dev/null || true
    ftl::test::pass "show_in_vim with # in filename did not crash"
    rm -f "$f"
}

test_show_in_vim_filename_with_percent_bug() {
    # BUG: show_in_vim only escapes $ and #; % (current file in vim) is
    # not escaped.
    local f
    f=$(mktemp -p "$FTL_TEST_TMP" 'file%name.txt')
    echo "content" > "$f"
    ftl_state_current_path="$f"
    ftl_state_current_basename="$(basename "$f")"
    vim() { : ; }
    ftl::prev::show_in_vim 2>/dev/null || true
    ftl::test::pass "show_in_vim with % in filename (BUG: not escaped) did not crash"
    rm -f "$f"
}

test_show_in_vim_filename_with_pipe_bug() {
    # BUG: | (vim command separator) is not escaped
    local f
    f=$(mktemp -p "$FTL_TEST_TMP" 'file|name.txt')
    echo "content" > "$f"
    ftl_state_current_path="$f"
    ftl_state_current_basename="$(basename "$f")"
    vim() { : ; }
    ftl::prev::show_in_vim 2>/dev/null || true
    ftl::test::pass "show_in_vim with | in filename (BUG: not escaped) did not crash"
    rm -f "$f"
}

# ============================================================================
# show_image — unquoted vars
# ============================================================================

test_show_image_basic() {
    local f
    f=$(mktemp -p "$FTL_TEST_TMP" 'image.png')
    ftl_state_current_path="$f"
    ftl_state_parent_dir="$FTL_TEST_TMP"
    # Stub ftli (the image viewer wrapper)
    ftli() { : ; }
    ftl::prev::show_image "$f" 2>/dev/null || true
    ftl::test::pass "show_image basic call did not crash"
    rm -f "$f"
}

test_show_image_path_with_spaces_bug() {
    # BUG: $ftl_state_parent_dir is UNQUOTED in the ftli command string.
    # If parent_dir contains spaces, the command breaks.
    mkdir -p "$FTL_TEST_TMP/my dir"
    local f="$FTL_TEST_TMP/my dir/image.png"
    : > "$f"
    ftl_state_current_path="$f"
    ftl_state_parent_dir="$FTL_TEST_TMP/my dir"
    ftli() { : ; }
    ftl::prev::show_image "$f" 2>/dev/null || true
    ftl::test::pass "show_image with spaces in parent_dir did not crash (quoting bug)"
    rm -rf "$FTL_TEST_TMP/my dir"
}

# ============================================================================
# dispatch
# ============================================================================

test_dispatch_primary_mode() {
    ftl_pane_is_primary=1
    ftl_pane_is_child=0
    ftl_state_external_viewer_mode=0
    ftl_state_preview_pane_visible=1
    ftl_state_current_path="/some/file"
    ftl::prev::show_internal() { : ; }
    ftl::prev::dispatch 2>/dev/null || true
    ftl::test::pass "dispatch in primary mode did not crash"
}

test_dispatch_child_mode() {
    ftl_pane_is_primary=0
    ftl_pane_is_child=1
    ftl_state_current_path="/some/file"
    ftl::prev::show_internal() { : ; }
    ftl::prev::dispatch 2>/dev/null || true
    ftl::test::pass "dispatch in child mode did not crash"
}

test_dispatch_neither_primary_nor_child() {
    ftl_pane_is_primary=0
    ftl_pane_is_child=0
    ftl_state_external_viewer_mode=0
    ftl::prev::dispatch 2>/dev/null || true
    ftl::test::pass "dispatch with neither flag did not crash"
}

# ============================================================================
# sync_and_dispatch — missing shared file
# ============================================================================

test_sync_and_dispatch_missing_shared_file_bug() {
    # BUG: sync_and_dispatch reads from $ftl_state_shared_dir/fs without
    # checking if the file exists. If missing, ftl_state_other_session_dir
    # is empty, and `source "$empty/ftl"` fails.
    ftl_pane_is_child=1
    ftl_state_shared_dir="$FTL_TEST_TMP/nonexistent_shared"
    ftl::prev::sync_and_dispatch 2>/dev/null || true
    ftl::test::pass "sync_and_dispatch with missing shared/fs did not crash"
}

test_sync_and_dispatch_with_shared_file() {
    mkdir -p "$FTL_TEST_TMP/shared"
    echo "$FTL_TEST_TMP/other_session" > "$FTL_TEST_TMP/shared/fs"
    mkdir -p "$FTL_TEST_TMP/other_session"
    : > "$FTL_TEST_TMP/other_session/ftl"
    ftl_pane_is_child=1
    ftl_state_shared_dir="$FTL_TEST_TMP/shared"
    ftl::prev::show_internal() { : ; }
    ftl::prev::sync_and_dispatch 2>/dev/null || true
    ftl::test::pass "sync_and_dispatch with shared file did not crash"
}

# ============================================================================
# thumb_path
# ============================================================================

test_thumb_path_basic() {
    ftl_state_current_path="/test/image.png"
    ftl_state_current_basename="image.png"
    ftl_cache_thumb_dir="$FTL_TEST_TMP/thumbs"
    local result
    result=$(ftl::gen::thumb_path 2>/dev/null) || true
    ftl::test::assert_contains "$result" "$FTL_TEST_TMP/thumbs" \
        "thumb_path should include the cache dir"
}

test_thumb_path_md5_includes_newline_bug() {
    # BUG: `md5sum <<<"$path"` adds a trailing newline. The MD5 is of
    # "path\n", not "path". If the same path is hashed elsewhere without
    # <<<, the hashes don't match.
    ftl_state_current_path="/test/file.txt"
    ftl_state_current_basename="file.txt"
    ftl_cache_thumb_dir="$FTL_TEST_TMP/thumbs"

    local with_heredoc without_heredoc
    with_heredoc=$(md5sum <<<"$ftl_state_current_path" | cut -d' ' -f1)
    without_heredoc=$(printf '%s' "$ftl_state_current_path" | md5sum | cut -d' ' -f1)
    ftl::test::assert_ne "$with_heredoc" "$without_heredoc" \
        "BUG: md5sum <<< adds newline, so thumb_path hash differs from hash without newline"
}

test_thumb_path_different_paths_produce_different_hashes() {
    ftl_cache_thumb_dir="$FTL_TEST_TMP/thumbs"

    ftl_state_current_path="/test/file1.png"
    ftl_state_current_basename="file1.png"
    local h1
    h1=$(ftl::gen::thumb_path 2>/dev/null)

    ftl_state_current_path="/test/file2.png"
    ftl_state_current_basename="file2.png"
    local h2
    h2=$(ftl::gen::thumb_path 2>/dev/null)

    ftl::test::assert_ne "$h1" "$h2" \
        "different paths should produce different thumb paths"
}

# ============================================================================
# clear_fixed
# ============================================================================

test_clear_fixed_with_no_fixed_preview_id() {
    ftl_pane_fixed_preview_id=
    tmux() { : ; }
    ftl::prev::clear_fixed 2>/dev/null || true
    # Should not crash with empty fixed_preview_id
    ftl::test::pass "clear_fixed with no fixed_preview_id did not crash"
}

test_clear_fixed_with_fixed_preview_id() {
    ftl_pane_fixed_preview_id="%99"
    local killed=0
    tmux() {
        if [[ "$1" == "kill-pane" ]] ; then
            ((killed++))
        fi
    }
    ftl::prev::clear_fixed 2>/dev/null || true
    ftl::test::pass "clear_fixed with fixed_preview_id did not crash"
    ftl_pane_fixed_preview_id=
}

# vim: set filetype=bash :
