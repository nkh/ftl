# preview.sh — preview pane management
#
# Manages the preview pane: dispatching to the right viewer, clearing,
# and handling the different preview types (vim, image daemon, child ftl).
#
# Public functions:
#   ftl::prev::dispatch           — dispatch preview for current entry (was: preview)
#   ftl::prev::clear              — clear the preview pane (was: tcpreview)
#   ftl::prev::show_in_vim        — show a file in vim (was: vipreview)
#   ftl::prev::show_image         — show an image via ftli/w3m (was: pw3image)
#   ftl::prev::sync_and_dispatch  — sync state and dispatch (was: prev_synch)
#
# Private functions:
#   _ftl::prev::clear_fixed       — clear the fixed preview pane (was: tcpreview2)
#   _ftl::prev::select_self_after_delay — select our pane after a delay (was: select_myp)
#
# Globals:
#   ftl_preview_is_dir_ftl        — child ftl is previewing a dir (was: in_pdir)
#   ftl_preview_is_vim            — vim is previewing (was: in_viprev)
#   ftl_preview_is_image_daemon   — ftli is running (was: in_ftli)
#   ftl_state_preview_pane_visible — whether preview pane is on (was: prev_all)
#   ftl_state_preview_callback    — callback for virtual entries (was: prev_cb)
#   ftl_state_fixed_preview_filename — filename for fixed preview (was: preview_pane2)
#   ftl_preview_media_pid            — background media player PID (was: mplayer)
#   ftl_view_w3mimg_pid           — w3mimgdisplay PID (was: w3iproc)

# Dispatch the preview for the current entry.
# In the main pane, calls the viewer directly. In a child pane, signals
# the main pane to sync state and dispatch.
ftl::prev::dispatch() {
        if (( ftl_pane_is_primary )) ; then
                if (( ftl_state_external_viewer_mode )) ; then
                        ftl::prev::show_external
                        ftl_state_external_viewer_mode=0
                elif (( ftl_state_preview_pane_visible )) ; then
                        ftl::prev::show_internal
                fi
                ftl_state_alt_preview_mode=0
        else
                ftl::state::save
                echo "$ftl_state_session_dir" >"$ftl_state_shared_dir/fs"
                echo "$ftl_pane_self_id" >"$ftl_state_shared_dir/pane"
                tmux send -t "$ftl_pane_primary_id" 'Ä' &>/dev/null
        fi
}

# Placeholder for the internal viewer dispatch (defined in viewers/core).
ftl::prev::show_internal() {
        :  # overridden by sourcing viewers/core
}

# Placeholder for the external viewer dispatch.
ftl::prev::show_external() {
        :  # overridden by sourcing viewers/core
}

# Clear the preview pane (kill the running preview program).
# Args:
#   $1: optional new value for ftl_state_preview_pane_visible
ftl::prev::clear() {
        if [[ -n "$ftl_pane_preview_id" ]] ; then
                tmux killp -t "$ftl_pane_preview_id" &>/dev/null
                ftl_pane_preview_id=
                ftl_preview_is_dir_ftl=
                ftl_preview_is_vim=
                ftl_preview_is_image_daemon=
                sleep 0.01
        fi
        _ftl::prev::clear_fixed
        [[ -n "${1:-}" ]] && ftl_state_preview_pane_visible=$1
}

# Clear the fixed preview pane.
_ftl::prev::clear_fixed() {
        if [[ -n "$ftl_pane_fixed_preview_id" ]] ; then
                tmux killp -t "$ftl_pane_fixed_preview_id" &>/dev/null
                ftl_pane_fixed_preview_id=
                sleep 0.01
        fi
}

# Show a file in vim (read-only). If vim is already running in the preview
# pane, send `:e` to switch files; otherwise spawn a new vim.
# Args:
#   $1: file path
ftl::prev::show_in_vim() {
        # Escape special vim characters in the filename so the `:e` command
        # parses correctly. The previous version only escaped `$` and `#`;
        # it missed `%` (vim's "current file"), `|` (command separator),
        # and `\` (escape char). We escape all of these.
        local escaped="$1"
        escaped="${escaped//\\/\\\\}"   # backslash first (so we don't double-escape)
        escaped="${escaped//\$/\\\$}"   # dollar sign
        escaped="${escaped//\#/\\#}"    # hash (alternate file)
        escaped="${escaped//\%/\\%}"    # percent (current file)
        escaped="${escaped//\|/\\|}"    # pipe (command separator)

        if (( ftl_preview_is_vim )) ; then
                tmux send -t "$ftl_pane_preview_id" \
                        ":e ${ftl_view_vim_tail_commands[$1]}$escaped" C-m
        else
                ftl::pane::split_or_respawn "$ftl_cfg_editor -R ${ftl_view_vim_tail_commands[$1]}${1@Q}"
        fi
        ftl_preview_is_vim=1
}

# Show an image via the ftli daemon (w3mimgdisplay).
# If ftli is already running, send the image path; otherwise spawn ftli.
# Args:
#   $1: image file path
ftl::prev::show_image() {
        if (( ftl_preview_is_image_daemon )) ; then
                tmux send -t "$ftl_pane_preview_id" "$1" C-m "$ftl_cfg_image_zoomed" C-m
        else
                ftl::pane::split_or_respawn \
                        "ftli $ftl_state_parent_dir \"$1\" '$ftl_cfg_image_zoomed' '$ftl_cfg_image_clean_borders' '$ftl_cfg_char_width_px' '$ftl_cfg_char_height_px'"
                ftl_preview_is_image_daemon=1
                _ftl::prev::select_self_after_delay
        fi
}

# Select our pane after a short delay (to let the split settle).
_ftl::prev::select_self_after_delay() {
        sleep 0.05
        tmux selectp -t "$ftl_pane_self_id"
}

# Sync state from the main pane and dispatch the preview.
# Args:
#   $1: "prev" to preview the current file, otherwise cd to the saved dir
ftl::prev::sync_and_dispatch() {
        ftl::sel::sync_from_other_pane
        read -r ftl_state_other_session_dir <"$ftl_state_shared_dir/fs"
        source "$ftl_state_other_session_dir/ftl"

        if (( ftl_pane_is_child )) ; then
                if [[ -n "$ftl_filter_external_name" ]] ; then
                        source "$FTL_CFG/etc/filters/$ftl_filter_external_name" load "$ftl_state_other_session_dir"
                else
                        ftl::filt::reset
                fi
        fi

        if (( ftl_pane_is_child )) ; then
                if [[ -n "$ftl_state_preview_callback" ]] ; then
                        eval "$ftl_state_preview_callback"
                fi
        fi

        if (( ftl_pane_is_child )) ; then
                if [[ -n "$ftl_etag_source_name" ]] ; then
                        source "$FTL_CFG/etc/etags/$ftl_etag_source_name"
                        if [[ -n "$ftl_plugin_virtual_callback" ]] ; then
                                eval "$ftl_plugin_virtual_callback"
                        fi
                        true
                else
                        source "$FTL_CFG/etc/etags/none"
                fi
        fi

        if (( ftl_pane_is_child )) ; then
                ftl::cmd::view_mode "${ftl_tab_view_mode[$ftl_state_current_tab_index]}" 1
        fi

        if [[ $1 == "prev" ]] ; then
                ftl::util::parse_path "$ftl_state_current_path"
                ftl::prev::dispatch
                source "$ftl_state_parent_dir/ftl"
        else
                ftl::list::change_dir "$ftl_state_sync_dir" '' "$ftl_state_sync_index"
        fi
        ftl_state_other_session_dir=
}

# Compute the thumbnail path for a file.
# Args:
#   $1: thumbnail subdirectory (extension)
#   $2: thumbnail format
# Outputs: thumbnail path on stdout
ftl::gen::thumb_path() {
        echo "$ftl_cache_thumb_dir/$1/$(md5sum <<<"$ftl_state_current_path" | cut -d' ' -f1)_$ftl_state_current_basename.$2"
}

# vim: set filetype=bash :
