# commands/shell.sh — Shell commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 9. Shell commands
#----------------------------------------------------------------------------

ftl::pane::send_to_shell() {
	{ (( $1 )) && [[ -n "$ftl_pane_shell_id" ]] \
		&& $(tmux has -t "$ftl_pane_shell_id" 2>&-) ; } \
		&& tmux send -t "$ftl_pane_shell_id" "${@:2}"
}

ftl::cmd::open_shell_pane() {
	ftl::prev::clear
	local saved_pane=$ftl_pane_preview_id
	ftl::pane::split "bash $ftl_cfg_shell_pane_height -v -U"
	ftl_pane_shell_id=$ftl_pane_preview_id
	ftl_pane_preview_id=$saved_pane
	sleep 0.2
	ftl::pane::send_to_shell "$1" "$(printf "%s " "${ftl_selection_current[@]@Q}")" C-b
	ftl::list::change_dir
}

ftl::cmd::shell_pane() {
	ftl::cmd::open_shell_pane
}

ftl::cmd::open_vertical_shell_pane() {
	ftl::prev::clear 0
	local saved_pane=$ftl_pane_preview_id
	ftl::pane::split "bash $ftl_cfg_shell_pane_width -h -U"
	ftl_pane_shell_id=$ftl_pane_preview_id
	ftl_pane_preview_id=$saved_pane
	sleep 0.2
	ftl::pane::send_to_shell "$1" "$(printf "%s " "${ftl_selection_current[@]@Q}")" C-b
	ftl::list::change_dir
}

ftl::cmd::shell_vpane() {
	ftl::cmd::open_vertical_shell_pane
}

ftl::cmd::open_shell() {
	if [[ -z "$ftl_pane_shell_id" ]] || ! tmux has -t "$ftl_pane_shell_id" 2>&- ; then
		ftl::cmd::open_shell_pane
	fi
	tmux selectp -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::shell() {
	ftl::cmd::open_shell
}

ftl::cmd::open_vertical_shell() {
	if [[ -z "$ftl_pane_shell_id" ]] || ! tmux has -t "$ftl_pane_shell_id" 2>&- ; then
		ftl::cmd::open_vertical_shell_pane
	fi
	tmux selectp -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::shell_vertical() {
	ftl::cmd::open_vertical_shell
}

ftl::cmd::open_shell_with_files() {
	if [[ -n "$ftl_pane_shell_id" ]] && tmux has -t "$ftl_pane_shell_id" 2>&- ; then
		ftl_state_pending_input="${ftl_kbd_command_to_key[ftl::cmd::shell_file]:-}"
	else
		ftl::cmd::open_shell_pane 1
	fi
	tmux selectp -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::shell_files() {
	ftl::cmd::open_shell_with_files
}

ftl::cmd::send_files_to_shell() {
	local i
	for i in "${ftl_selection_current[@]}" ; do
		ftl::pane::send_to_shell 1 "'$i'" " "
	done
}

ftl::cmd::shell_send_files() {
	ftl::cmd::send_files_to_shell
}

ftl::cmd::view_session_shell() {
	if (( ! ftl_pane_session_shell_active )) ; then
		tmux new -A -d -s "ftl$$"
		tmux newww -t "ftl$$" -n "ftl$$_bash"
		sleep 0.2
		ftl_pane_session_shell_active=1
	fi
	tmux switch -t "ftl$$:ftl$$_bash"
}

ftl::cmd::shell_view() {
	ftl::cmd::view_session_shell
}

ftl::cmd::synch_shell_cwd() {
	ftl::pane::send_to_shell 1 "cd '$ftl_state_current_dir'" C-m
}

ftl::cmd::shell_synch() {
	ftl::cmd::synch_shell_cwd
}

ftl::cmd::open_zoomed_shell() {
	if [[ -z "$ftl_pane_shell_id" ]] || ! tmux has -t "$ftl_pane_shell_id" 2>&- ; then
		ftl::cmd::open_shell_pane
	fi
	tmux selectp -t "$ftl_pane_shell_id" &>/dev/null
	tmux resizep -Z -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::shell_zoomed() {
	ftl::cmd::open_zoomed_shell
}

ftl::cmd::run_command_in_pane() {
	ftl::cmd::prompt "ftl> "
	ftl_list_quick_display_active=1
	ftl::list::render
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		ftl::pane::split_for_preview "$ftl_kbd_current_key ; read -sn10"
	fi
	sleep 0.05
}

ftl::cmd::shell_cmd_in_pane() {
	ftl::cmd::run_command_in_pane
}

ftl::cmd::close_shell_pane() {
	[[ -n "$ftl_pane_shell_id" ]] \
		&& tmux killp -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::quit_shell() {
	ftl::cmd::close_shell_pane
}

ftl::cmd::run_interactive_bash() {
	exec 2>&9
	stty echo
	echo -ne '\e[H\e[K\e[33m\e[?25h'
	clear
	bash -i
	ftl::util::enter_alt_screen
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::run_bash() {
	ftl::cmd::run_interactive_bash
}

#----------------------------------------------------------------------------
