# commands/signals.sh — Signal handlers
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 13. Signal handlers
#----------------------------------------------------------------------------

ftl::ipc::handle_pane_focus() {
	ftl::pane::read_child_list
	if (( ${#ftl_pane_child_ids[@]} )) ; then
		tmux selectp -t "${ftl_pane_child_ids[0]}"
	else
		tmux selectp -t "$ftl_pane_self_id"
	fi
	ftl_state_other_session_dir=
	ftl_state_pending_input="${ftl_kbd_command_to_key[ftl::cmd::refresh_pane]:-}"
}

ftl::cmd::SIG_PANE() {
	ftl::ipc::handle_pane_focus
}

ftl::ipc::handle_refresh() {
	(( ftl_pane_is_child )) && ftl::kbd::drain_input && ftl::prev::sync_and_dispatch
}

ftl::cmd::SIG_REFRESH() {
	ftl::ipc::handle_refresh
}

ftl::ipc::handle_preview_request() {
	(( ftl_state_preview_pane_visible )) || return 0
	local op
	read -r op <"$ftl_state_shared_dir/pane"
	ftl::prev::sync_and_dispatch prev
	tmux selectp -t "$op"
	ftl::kbd::drain_input
}

ftl::cmd::SIG_REMOTE() {
	ftl::ipc::handle_preview_request
}

ftl::ipc::handle_shell_synch() {
	local shell_dir
	IFS=$'\n' read -r shell_dir <"$ftl_state_parent_dir/synch_with_shell"
	ftl::list::change_dir "$shell_dir"
}

ftl::cmd::SIG_SYNCH_SHELL() {
	ftl::ipc::handle_shell_synch
}

#----------------------------------------------------------------------------
