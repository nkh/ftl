# commands/dispatcher.sh — Shell-command dispatcher
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

#----------------------------------------------------------------------------
# 0. Shell-command dispatcher
#----------------------------------------------------------------------------

# Dispatch a command entered at the command prompt.
# Args:
#   $1: command string
ftl::cmd::dispatch_command() {
	# Empty command — cancel
	[[ "$1" == 0 ]] && return 1

	# Numeric — goto entry by index
	if [[ "$1" =~ ^[1-9][0-9]*$ ]] ; then
		ftl_state_cursor_index="${ftl_list_entries[$(( $1 - 1 ))]}"
		if [[ -d "$ftl_state_cursor_index" ]] ; then
			ftl::list::change_dir "$ftl_state_cursor_index"
		else
			ftl::list::render $(( $1 - 1 ))
		fi
		return 1
	fi

	# Built-in commands
	[[ "$1" == "qa" ]] && { ftl::cmd::quit_all ; return ; }
	[[ "$1" == "load_sel" ]] && { ftl::sel::load_from_file ; return ; }

	# Shortcut bound to a command
	if [[ -n "${ftl_kbd_trie[$1]:-}" ]] ; then
		ftl_state_pending_input=${ftl_kbd_trie[$1]}
		return
	fi
	if [[ -n "${ftl_kbd_command_to_key[$1]:-}" ]] ; then
		ftl_state_pending_input=${ftl_kbd_command_to_key[$1]}
		return
	fi

	# Split the command into parts
	local -a cmd_parts=()
	eval "$($FTL_CFG/etc/bin/parse_parts "$1")"
	local cmd="${cmd_parts[0]}"

	# Serialize ftl info for external commands
	ftl::state::serialize_info

	# User command
	local user_cmd="$FTL_CFG/etc/commands/$cmd"
	if [[ -f "$user_cmd" ]] ; then
		if [[ ! -x "$user_cmd" ]] ; then
			source "$user_cmd" "${cmd_parts[@]:1}"
		else
			"$user_cmd" "${cmd_parts[@]:1}"
		fi
		return
	fi

	# Ensure the session shell exists
	if (( ! ftl_pane_session_shell_active )) ; then
		tmux new -A -d -s "ftl$$"
		tmux neww -t "ftl$$" -n "ftl$$_bash"
		sleep 0.2
		ftl_pane_session_shell_active=1
	fi

	# Check for command aliases
	if [[ -n "${ftl_cfg_command_aliases[$cmd]:-}" ]] ; then
		cmd_parts=(${ftl_cfg_command_aliases[$cmd]} $(printf "%s " "${cmd_parts[@]:1}"))
		cmd="${cmd_parts[0]}"
	fi

	# Built-in command forms
	if [[ "$cmd" == "full" ]] ; then
		ftl::prev::clear
		clear
		eval "${cmd_parts[@]:1}"
		ftl::list::change_dir
		return
	fi
	if [[ "$cmd" == "split" ]] ; then
		ftl::prev::clear
		tmux split-window -e ftl_state_info_file_path="$ftl_state_info_file_path" -l 50% \
			"$(printf "%s " "${cmd_parts[@]:1}")"
		ftl::list::change_dir
		tmux selectp -D
		return
	fi
	if [[ "$cmd" == "fsh" ]] ; then
		fsh "$(printf "%s " "${cmd_parts[@]:1}")"
		return
	fi

	# Run in the session shell
	{
		echo "export ftl_state_info_file_path=$ftl_state_info_file_path"
		echo "cd '$PWD'"
		echo "echo -e '\e[2;33m[$(date -R)] $PWD\n\e[0;33mftl> $@ \e[m'"
		echo "echo -e \"\e[33m[$(date -R)] $PWD\n\e[33mftl> $@ \e[m\" >>$ftl_state_session_dir/command.log"
		echo "${cmd_parts[@]}"
		echo "exit_code=\$?"
		echo "echo -e \"\e[33mexit code: \$exit_code\e[m\n\" >>$ftl_state_session_dir/command.log"
		echo "echo -e \"\n\e[2;33mexit code: \$exit_code\e[m\""
	} >"$ftl_state_session_dir/bash_command"
	tmux send -t "ftl$$:ftl$$_bash" ". $ftl_state_session_dir/bash_command" Enter
}

#----------------------------------------------------------------------------
