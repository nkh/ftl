# mark.sh — bookmarks and history
#
# Manages session marks (single-char bookmarks), persistent marks (saved
# across sessions), and directory-visit history (session and global).
#
# Public functions:
#   ftl::mark::save_to_history     — append current path to history files
#
# Globals:
#   ftl_mark_session_marks         — assoc: char → path (was: marks)

# Save the current path to session and global history.
_ftl::mark::save_to_history() {
	(( ftl_pane_is_child )) && return 0
	[[ -z "$ftl_state_current_path" ]] && return 0
	echo "$ftl_state_current_path" \
		| tee -a "$ftl_state_session_dir/history" >> "$FTL_STATE_DIR/shared/history"
}

# vim: set filetype=bash :
