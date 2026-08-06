# state.sh — state management and serialization
#
# Manages per-session state: the session directory, serialized state files,
# and the info file used for external command integration.
#
# Public functions:
#   ftl::state::init                — initialize per-session state dirs
#   ftl::state::save                — serialize state to $ftl_state_session_dir/state
#   ftl::state::load                — source a state file
#   ftl::state::save_selection      — serialize the selection (tags) array
#   ftl::state::load_selection      — source a selection file
#   ftl::state::serialize_info      — write info file for external commands
#   ftl::state::render_child_env    — render -e args for child processes
#   ftl::state::emit_selection_fd3  — write selection to fd 3 (for ftll/cdf)
#   ftl::state::cleanup             — remove the session directory
#
# Globals:
#   ftl_state_session_dir      — this pane's private dir (was: fs)
#   ftl_state_parent_dir       — parent pane's session dir (was: pfs)
#   ftl_state_other_session_dir — the pane we're syncing with (was: ofs)
#   ftl_state_shared_dir       — shared sync dir = $pfs/prev (was: fsp)
#   ftl_state_previous_pwd     — previous PWD (was: PPWD)
#   ftl_state_child_env        — assoc array of env vars for children (was: ftl_env)

# Initialize per-session state directories.
# Creates $ftl_state_session_dir and subdirectories.
ftl::state::init() {
        ftl_state_session_dir="$FTL_STATE_DIR/$$"
        ftl_state_shared_dir="$ftl_state_session_dir/prev"
        mkdir -p "$ftl_state_session_dir"/{prev,lock_preview,mnt,tmp}
        mkdir -p "$FTL_STATE_DIR/cache/thumbs"
}

# Serialize current state to $ftl_state_session_dir/state.
# This file is sourced by the preview pane to sync state.
# Args:
#   $1: optional target directory (defaults to $ftl_state_session_dir)
ftl::state::save() {
        local target_dir="${1:-$ftl_state_session_dir}"

        # Serialize the selection (tags) array.
        # Use `declare -Ag` (via sed) so the array can be sourced back into
        # any scope. The previous sed `s/\-A/-A -g/` was a broad match that
        # corrupted filenames containing "-A" (e.g. "file-Apples.txt").
        # We now use a more precise sed that only matches the `declare -A`
        # at the start of the line (anchored with ^), not anywhere in the
        # output where a tag value might contain "-A".
        declare -p ftl_selection_tags \
                | sed 's/^declare -A /declare -Ag /' >"$ftl_state_session_dir/tags"
        echo "$ftl_selection_revision" >"$ftl_state_shared_dir/stagsi"
        echo "$ftl_state_session_dir" >"$ftl_state_shared_dir/fs"

        if (( ! ftl_list_entry_count )) ; then
                : >"$target_dir/ftl"
                return
        fi

        # Write state using the namespaced variable names that the child
        # pane (ftl::prev::sync_and_dispatch) reads back. The previous
        # implementation wrote short legacy names (sdir, prev_cb, etag_s,
        # vmode[tab], etc.) which the child never read — so parent→child
        # state sync was completely broken.
        local t="$ftl_state_current_tab_index"
        {
                echo "ftl_state_sync_dir=\"${ftl_list_entries[$ftl_state_cursor_index]}\""
                echo "ftl_state_sync_index=${ftl_state_cursor_memory[${t}_$ftl_list_entries[$ftl_state_cursor_index]]:-0}"
                echo "ftl_state_current_path=\"$ftl_state_current_path\""
                echo "ftl_filter_active_glyph=\"$ftl_filter_active_glyph\""
                echo "ftl_state_show_size_mode=$ftl_state_show_size_mode"
                echo "ftl_state_preview_callback=\"$ftl_state_preview_callback\""
                echo "ftl_state_etag_enabled=$ftl_state_etag_enabled"
                echo "ftl_etag_source_name=\"$ftl_etag_source_name\""
                echo "ftl_plugin_virtual_callback=\"$ftl_plugin_virtual_callback\""
                echo "ftl_state_dir_preview_mode=\"$ftl_state_dir_preview_mode\""
                echo "ftl_filter_external_name=\"$ftl_filter_external_name\""
                echo "ftl_tab_view_mode[$t]=\"${ftl_tab_view_mode[$t]:-0}\""
                echo "ftl_tab_sort_type[$t]=${ftl_tab_sort_type[$t]:-0}"
                echo "ftl_tab_filter_1[$t]=\"${ftl_tab_filter_1[$t]:-}\""
                echo "ftl_tab_filter_2[$t]=\"${ftl_tab_filter_2[$t]:-}\""
                echo "ftl_tab_listing_mode[$t]=\"${ftl_tab_listing_mode[$t]:-0}\""
                echo "ftl_tab_show_hidden[$t]=\"${ftl_tab_show_hidden[$t]:-0}\""
                echo "ftl_tab_filter_reverse[$t]=\"${ftl_tab_filter_reverse[$t]:-}\""
                echo "ftl_tab_filter_image_negate[$t]=\"${ftl_tab_filter_image_negate[$t]:-}\""
        } >"$target_dir/ftl"

        declare -p ftl_filter_listing_hide_exts ftl_filter_listing_keep_exts >>"$target_dir/ftl"
}

# Load (source) a state file.
# Args:
#   $1: state file path (defaults to $ftl_state_session_dir/state)
ftl::state::load() {
        local file="${1:-$ftl_state_session_dir/state}"
        [[ -f "$file" ]] && source "$file"
}

# Serialize the selection (tags) array to a file.
# Args:
#   $1: target file (defaults to $ftl_state_session_dir/tags)
ftl::state::save_selection() {
        local file="${1:-$ftl_state_session_dir/tags}"
        declare -p ftl_selection_tags | sed 's/^declare -A /declare -Ag /' >"$file"
}

# Load (source) a selection file.
# Args:
#   $1: file containing `declare -p ftl_selection_tags` output
ftl::state::load_selection() {
        local file="$1"
        [[ -f "$file" ]] && source "$file"
}

# Write the info file used by external commands (finfo, fsh, etc.).
# Contains FTL_PID, FTL_SESSION_DIR, FTL_CWD, n, selection.
# Args:
#   $1: optional target file (defaults to a mktemp in $ftl_state_session_dir)
ftl::state::serialize_info() {
        if [[ -n "$1" ]] ; then
                ftl_state_info_file_path="$1"
        else
                ftl_state_info_file_path="$(mktemp -p "$ftl_state_session_dir" ftl_info_XXXXXXX)"
        fi

        export ftl_state_info_file_path
        ftl_state_child_env+=([ftl_info_file]=$ftl_state_info_file_path)

        {
                echo "FTL_PID=$$"
                echo "FTL_SESSION_DIR=$ftl_state_session_dir"
                echo "FTL_CWD=${PWD@Q}"
                declare -p ftl_state_current_path 2>/dev/null || echo "ftl_state_current_path="
                declare -p ftl_selection_current 2>/dev/null || echo "declare -a ftl_selection_current=()"
        } >"$ftl_state_info_file_path"
}

# Render the child environment as -e key=value arguments for tmux split-window.
# Args:
#   $1: optional flag prefix (defaults to "-e")
# Outputs: "-e key1=val1 -e key2=val2 ..." on stdout
ftl::state::render_child_env() {
        ftl_state_child_env+=(
                [ftl_pfs]=$ftl_state_parent_dir
                [ftl_fs]=$ftl_state_session_dir
        )
        local key
        for key in "${!ftl_state_child_env[@]}" ; do
                echo -n "${1:--e} $key=${ftl_state_child_env[$key]} "
        done
}

# Write the selection to fd 3 (used by ftll/cdf to return selection).
ftl::state::emit_selection_fd3() {
        if true 2>&- >&3 ; then
                if (( ! ftl_state_quit_cancelled )) ; then
                        printf "%s\n" "${ftl_selection_current[@]}" >&3
                else
                        echo >&3
                fi
        fi
}

# Remove the session directory (called on quit).
ftl::state::cleanup() {
        rm -rf "$ftl_state_session_dir"
}

# vim: set filetype=bash :
