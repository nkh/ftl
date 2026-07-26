# commands/tab.sh — Tab commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 6. Tab commands
#----------------------------------------------------------------------------

ftl::cmd::close_tab() {
	(( ftl_tab_count > 1 )) || return 1
	ftl_tab_directories[$ftl_state_current_tab_index]=
	(( ftl_tab_count-- ))
	ftl::cmd::next_tab
	ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}"
}

ftl::cmd::tab_close() {
	ftl::cmd::close_tab
}

ftl::cmd::new_tab() {
	if [[ -d "$ftl_state_current_basename" ]] ; then
		ftl::tab::create "$ftl_state_current_path"
	else
		ftl::tab::create "${1:-$PWD}"
	fi
	ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}"
}

ftl::cmd::tab_new() {
	ftl::cmd::new_tab
}

ftl::cmd::next_tab() {
	local ctab=$ftl_state_current_tab_index
	ftl::tab::advance_index
	if (( ftl_state_current_tab_index != ctab )) ; then
		ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}" \
			'' "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_${ftl_tab_directories[$ftl_state_current_tab_index]}]}"
	fi
}

ftl::cmd::tab_next() {
	ftl::cmd::next_tab
}

ftl::cmd::prev_tab() {
	local ctab=$ftl_state_current_tab_index
	ftl::tab::retreat_index
	if (( ftl_state_current_tab_index != ctab )) ; then
		ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}" \
			'' "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_${ftl_tab_directories[$ftl_state_current_tab_index]}]}"
	fi
}

ftl::cmd::tab_prev() {
	ftl::cmd::prev_tab
}

ftl::cmd::goto_tab() {
	local ntab=$(( ftl_kbd_count - 1 ))
	if (( ntab != ftl_state_current_tab_index )) \
	   && [[ -n "${ftl_tab_directories[$ntab]:-}" ]] ; then
		ftl_state_current_tab_index=$ntab
		ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}" \
			'' "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_${ftl_tab_directories[$ftl_state_current_tab_index]}]}"
	fi
}

ftl::cmd::tab_goto() {
	ftl::cmd::goto_tab
}

#----------------------------------------------------------------------------
