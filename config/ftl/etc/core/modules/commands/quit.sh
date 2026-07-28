# commands/quit.sh — Quit commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 12. Quit commands
#----------------------------------------------------------------------------

ftl::cmd::quit() {
	_ftl::cmd::check_shells_before_quit && return
	ftl::prev::clear
	_ftl::cmd::quit_cleanup
	ftl::cmd::close_shell_pane
	tmux kill-session -t "ftl$$" &>/dev/null
	if (( ! ftl_pane_is_primary )) ; then
		ftl::pane::read_child_list
		tmux send -t "$ftl_pane_primary_id" å
	fi
	ftl::state::cleanup
	exit
}

ftl::cmd::quit_ftl() {
	ftl::cmd::close_tab || ftl::cmd::close_pane || ftl::cmd::quit
}

_ftl::cmd::check_shells_before_quit() {
	(( ftl_state_quit_attempt_count++, ftl_state_quit_attempt_count > 2 )) && return 1
	if (( $(tmux lsw -t "ftl$$" 2>&- | wc -l) > 2 )) ; then
		tmux popup -h 5 "echo Shells open! «session: ctl-w !». "
		true
	else
		false
	fi
}

_ftl::cmd::quit_cleanup() {
	_ftl::mark::save_to_history
	ftl::pane::stop_file_watcher
	stty echo
	[[ "$ftl_state_parent_dir" == "$ftl_state_session_dir" ]] \
		&& ftl::pane::set_border_colors $ftl_cfg_tmux_border_colors_default
	ftl::cmd::kill_media_player
	ftl::boot::on_quit
	ftl::util::refresh_screen "\e[?25h\e[?1049l"
	ftl::state::emit_selection_fd3
}

ftl::cmd::quit_all() {
	if (( ftl_pane_is_primary )) ; then
		ftl::pane::send_to_all_children "${ftl_kbd_command_to_key[quit_ftl]}"
		sleep 0.05
		ftl_state_quit_cancelled=1
		ftl::cmd::quit
	else
		tmux send -t "$ftl_pane_primary_id" "${ftl_kbd_command_to_key[quit_all]}"
	fi
}

ftl::cmd::quit_keep_shell() {
	ftl_pane_keep_shell_on_quit=1
	ftl::cmd::quit_all
}

ftl::cmd::quit_keep_preview() {
	_ftl::cmd::quit_cleanup
	if [[ -n "$ftl_pane_preview_id" ]] ; then
		echo >"$ftl_state_parent_dir/pane"
		tmux selectp -t "$ftl_pane_preview_id"
		tmux resizep -Z -t "$ftl_pane_preview_id"
	fi
	exit 0
}

ftl::cmd::refresh_pane() {
	ftl::prev::sync_and_dispatch
	if (( ftl_list_entry_count )) ; then
		ftl::util::parse_path "${ftl_list_entries[$ftl_state_cursor_index]}"
	else
		ftl_state_current_basename=
	fi
	ftl::sel::validate_existence
	ftl::list::change_dir "$PWD" "$ftl_state_current_basename"
}

#----------------------------------------------------------------------------
