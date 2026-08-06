# commands/dest_tags.sh — Destination tag commands
#
# Backport of upstream commit 38a073a "ADDED: destination tags".
#
# Destination tags are a per-entry annotation that records a target
# directory the entry should be copied or moved to. The user picks a
# destination by pressing a single shortcut key; the mapping from
# shortcut key to directory path is stored in the user-configurable
# associative array ftl_dest_dir_dest (typically populated in ftlrc).
#
# Once entries are tagged, the user can either:
#   - copy all tagged entries to their recorded destinations (Tc), or
#   - move all tagged entries to their recorded destinations (Tm).
#
# The display layer (ftl::list::render) shows a [...dest] annotation
# next to each tagged entry so the user can see at a glance which
# entries are tagged and where they will go.
#
# State:
#   ftl_dest_tags        — assoc array: full_path → destination_directory
#   ftl_dest_dir_dest    — assoc array (user config): shortcut_key → directory
#   ftl_dest_last_dest   — last shortcut key used (for "apply last to COUNT")
#
# Config:
#   ftl_cfg_dtag_move    — if non-zero, move cursor down after tagging (default 1)
#   ftl_cfg_dtag_l       — display width for the destination annotation (default 15)
#
# Bindings (registered in etc/ftlrc):
#   t              — ftl::cmd::dest_tag_current
#   TCC            — ftl::cmd::dest_tag_clear_current
#   TCA            — ftl::cmd::dest_tag_clear_all
#   TT             — ftl::cmd::dest_tag_apply_last_to_count
#   COUNT TT       — ftl::cmd::dest_tag_apply_last_to_count (with COUNT)
#   Tc             — ftl::cmd::dest_tag_copy_tagged
#   Tm             — ftl::cmd::dest_tag_move_tagged
#
# vim: set filetype=bash :

# Tag the current entry with a destination directory.
# Reads a single keystroke from stdin; the keystroke is looked up in
# ftl_dest_dir_dest to find the destination directory path. If
# ftl_cfg_dtag_move is non-zero, the cursor advances to the next entry
# after tagging (so the user can rapidly tag a sequence of entries).
ftl::cmd::dest_tag_current() {
        # Read a single keystroke (no echo). Use $REPLY (like upstream
        # `read -sn1 ; last_dest=$REPLY`) so test stubs that override
        # `read()` and set REPLY work without parsing the variable-name
        # argument.
        read -rn1
        ftl_dest_last_dest="$REPLY"
        [[ -n "$ftl_state_current_path" ]] \
                && ftl_dest_tags["$ftl_state_current_path"]="${ftl_dest_dir_dest[$REPLY]:-}"
        (( ftl_cfg_dtag_move )) && ftl::list::move_cursor 1
        ftl::list::render
}

# Clear the destination tag on the current entry.
ftl::cmd::dest_tag_clear_current() {
        [[ -n "$ftl_state_current_path" ]] && unset 'ftl_dest_tags[$ftl_state_current_path]'
        (( ftl_cfg_dtag_move )) && ftl::list::move_cursor 1
        ftl::list::render
}

# Clear all destination tags.
ftl::cmd::dest_tag_clear_all() {
        ftl_dest_tags=()
        ftl::list::render
}

# Apply the last-used destination shortcut to COUNT entries (default 1).
# Useful for rapidly tagging a run of entries with the same destination
# without re-pressing the shortcut key each time.
ftl::cmd::dest_tag_apply_last_to_count() {
        local count="${ftl_kbd_count:-1}"
        local i
        for (( i = 0 ; i < count ; i++ )) ; do
                ftl_dest_tags["$ftl_state_current_path"]="${ftl_dest_dir_dest[$ftl_dest_last_dest]:-}"
                (( ftl_cfg_dtag_move )) && ftl::list::move_cursor 1
        done
        ftl::list::render
}

# Copy every tagged entry to its recorded destination directory.
# Tags are cleared after the copy completes (success or failure per file).
ftl::cmd::dest_tag_copy_tagged() {
        local fc
        for fc in "${!ftl_dest_tags[@]}" ; do
                [[ -n "${ftl_dest_tags[$fc]}" ]] || continue
                [[ -e "$fc" ]] || continue
                cp -r -- "$fc" "${ftl_dest_tags[$fc]}/"
        done
        ftl_dest_tags=()
        ftl::list::render
}

# Move every tagged entry to its recorded destination directory.
# Tags are cleared after the move completes (success or failure per file).
ftl::cmd::dest_tag_move_tagged() {
        local fm
        for fm in "${!ftl_dest_tags[@]}" ; do
                [[ -n "${ftl_dest_tags[$fm]}" ]] || continue
                [[ -e "$fm" ]] || continue
                mv -- "$fm" "${ftl_dest_tags[$fm]}/"
        done
        ftl_dest_tags=()
        ftl::list::change_dir
}

# Internal: format the destination tag annotation for display.
# Returns the formatted annotation string on stdout (empty if no tag).
# The annotation is left-padded to ftl_cfg_dtag_l columns and prefixed
# with " [...". Caller appends the closing "]".
_ftl::dest::format_annotation() {
        local path="$1"
        local tag="${ftl_dest_tags[$path]:-}"
        [[ -n "$tag" ]] || return 0

        # Trim to the last ftl_cfg_dtag_l characters so long paths don't
        # blow out the display column. Note: bash's ${tag: -N} returns
        # empty when N > ${#tag}, so we guard with a length check.
        local trimmed="$tag"
        if (( ${#tag} > ftl_cfg_dtag_l )) ; then
                trimmed="${tag: -$ftl_cfg_dtag_l}"
        fi
        # Left-pad to ftl_cfg_dtag_l columns
        printf -v trimmed "%-${ftl_cfg_dtag_l}s" "$trimmed"
        printf ' [...%s]' "$trimmed"
}
