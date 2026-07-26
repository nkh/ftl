# commands/prompt.sh — Command prompt
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 14. Command prompt
#----------------------------------------------------------------------------

ftl::cmd::open_command_prompt() {
	_ftl::cmd::build_command_name_list
	echo -ne "\e[H"
	tput cnorm
	stty echo
	local C
	C="$(ftl::cmd::prompt_with_history)"
	stty -echo
	tput civis
	if [[ -n "$C" ]] ; then
		_ftl::list::print_header '' "$ftl_list_header_mode_glyphs"
		ftl::cmd::dispatch_command "$C"
	fi
	ftl::list::render
}

ftl::cmd::command_prompt() {
	ftl::cmd::open_command_prompt
}

_ftl::cmd::build_command_name_list() {
	{
		find "$FTL_CFG/etc/commands" -type f -printf "%f\n"
		printf "%s\n" "${!ftl_kbd_command_to_key[@]}" fsh finfo show_cmd_log
	} >"$ftl_state_session_dir/command_names"
}

ftl::cmd::prompt_with_history() {
	trap 'echo -ne "\e[A\e[K" ; stty -echo ; tput civis' SIGINT
	echo $(rlwrap -p'0;33' -S"${1:-ftl> }" \
		-f"$ftl_state_session_dir/command_names" \
		-H "$FTL_STATE_DIR/shared/command_history" -o cat)
	trap - SIGINT
}

ftl::cmd::prompt() {
	exec 2>&9
	stty echo
	echo -ne '\e[H\e[K\e[33m\e[?25h'
	read -e -rp "$@"
	echo -ne '\e[m'
	stty -echo
	tput civis
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::ftl::plugin::user_command::run_user_command() {
	local p="$FTL_CFG/etc/commands"
	local cmd
	cmd=$(cd "$p" 2>&- && fd -t f | sed 's/^.\///' \
		| fzf-tmux -p80% --cycle --reverse --info=inline)
	[[ -n "$cmd" ]] && source "$p/$cmd"
	ftl::list::render
}

ftl::cmd::show_help() {
	if (( ftl_cfg_help_in_popup )) ; then
		tmux popup -h90% -w90% -E "$ftl_cfg_help_command"
	else
		ftl::prev::clear
		exec 2>&9
		$ftl_cfg_help_command
		exec 2>"$ftl_state_session_dir/log"
		ftl::util::enter_alt_screen
	fi
	ftl::list::change_dir
}

ftl::cmd::ftl_help() {
	ftl::cmd::show_help
}

ftl::cmd::show_bindings() {
	ftl::kbd::show_bindings
}

ftl::cmd::k_bindings() {
	ftl::kbd::show_bindings
}

ftl::cmd::show_tree() {
	tmux popup -h 90% -w 90% -E -d "$PWD" "tree -C $@ | less -R"
}

ftl::cmd::tree_view() {
	ftl::cmd::show_tree
}

# vim: set filetype=bash :
