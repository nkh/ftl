# commands/movement.sh — Movement commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 1. Movement commands
#----------------------------------------------------------------------------

ftl::cmd::cursor_up() {
	if (( ftl_list_entry_count )) ; then
		ftl::list::move_cursor -1 && ftl::list::render
	fi
}

ftl::cmd::cursor_up_arrow() {
	ftl::cmd::cursor_up
}

ftl::cmd::cursor_down() {
	if (( ftl_list_entry_count )) ; then
		ftl::list::move_cursor 1 && ftl::list::render
	fi
}

ftl::cmd::cursor_down_arrow() {
	ftl::cmd::cursor_down
}

ftl::cmd::cd_to_parent() {
	[[ "$PWD" != / ]] || return 0
	local parent_dir="${PWD%/*}"
	ftl::list::change_dir "${parent_dir:-/}" "$(basename "$ftl_state_current_dir")"
}

ftl::cmd::cursor_left_arrow() {
	ftl::cmd::cd_to_parent
}

ftl::cmd::ftl::plugin::type_handlers::move_left() {
	ftl::cmd::cd_to_parent
}

ftl::cmd::cd_into_entry() {
	(( ftl_list_entry_count )) || return 0
	[[ -d "${ftl_list_entries[$ftl_state_cursor_index]}" ]] \
		&& ftl::list::change_dir "${ftl_list_entries[$ftl_state_cursor_index]}"
}

ftl::cmd::move_right() {
	ftl::cmd::cd_into_entry
}

ftl::cmd::cursor_right_arrow() {
	ftl::cmd::cd_into_entry
}

ftl::cmd::cursor_up_step() {
	if (( ftl_list_entry_count )) ; then
		ftl::list::move_cursor "-$ftl_cfg_move_step_size" && ftl::list::render
	fi
}

ftl::cmd::cursor_down_step() {
	if (( ftl_list_entry_count )) ; then
		ftl::list::move_cursor "$ftl_cfg_move_step_size" && ftl::list::render
	fi
}

ftl::cmd::enter_entry() {
	(( ftl_list_entry_count )) || return 0
	if [[ -f "${ftl_list_entries[$ftl_state_cursor_index]}" ]] ; then
		ftl::cmd::edit_current
	elif [[ -d "${ftl_list_entries[$ftl_state_cursor_index]}" ]] ; then
		ftl::list::change_dir "${ftl_list_entries[$ftl_state_cursor_index]}"
	fi
}

ftl::cmd::ftl::plugin::type_handlers::enter() {
	ftl::cmd::enter_entry
}

ftl::cmd::page_up() {
	ftl::list::move_cursor "-$ftl_pane_height"
	ftl::list::render
}

ftl::cmd::move_page_up() {
	ftl::cmd::page_up
}

ftl::cmd::page_down() {
	ftl::list::move_cursor "$ftl_pane_height"
	ftl::list::render
}

ftl::cmd::move_page_down() {
	ftl::cmd::page_down
}

ftl::cmd::cycle_top_file_bottom() {
	local twd="${ftl_state_current_tab_index}_$PWD"
	if [[ -f "$ftl_state_current_path" ]] ; then
		if (( ftl_state_cursor_index == ftl_list_entry_count - 1 )) ; then
			ftl_state_cursor_memory[$twd]=0
		else
			ftl_state_cursor_memory[$twd]=$ftl_list_entry_count
		fi
	else
		ftl_state_cursor_memory[$twd]=$ftl_list_first_file_index
	fi
	ftl::list::render
}

ftl::cmd::top_file_bottom() {
	ftl::cmd::cycle_top_file_bottom
}

ftl::cmd::goto_first_directory() {
	local twd="${ftl_state_current_tab_index}_$PWD"
	(( ftl_list_entry_count )) && ftl_state_cursor_memory[$twd]=0
	ftl::list::render
}

ftl::cmd::goto_first_file() {
	local twd="${ftl_state_current_tab_index}_$PWD"
	(( ftl_list_entry_count )) && ftl_state_cursor_memory[$twd]=$ftl_list_first_file_index
	ftl::list::render
}

ftl::cmd::goto_last_file() {
	local twd="${ftl_state_current_tab_index}_$PWD"
	(( ftl_list_entry_count )) && ftl_state_cursor_memory[$twd]=$ftl_list_entry_count
	ftl::list::render
}

ftl::cmd::goto_top_of_window() {
	local twd="${ftl_state_current_tab_index}_$PWD"
	ftl_state_cursor_memory[$twd]=$ftl_list_window_top
	ftl::list::render
}

ftl::cmd::goto_high_file() {
	ftl::cmd::goto_top_of_window
}

ftl::cmd::goto_bottom_of_window() {
	local twd="${ftl_state_current_tab_index}_$PWD"
	ftl_state_cursor_memory[$twd]=$ftl_list_window_bottom
	ftl::list::render
}

ftl::cmd::goto_low_file() {
	ftl::cmd::goto_bottom_of_window
}

ftl::cmd::jump_by_percent() {
	local twd="${ftl_state_current_tab_index}_$PWD"
	(( ftl_list_entry_count )) \
		&& ftl_state_cursor_memory[$twd]=$(( ftl_list_entry_count * ftl_kbd_count / 100 ))
	ftl::list::render
}

ftl::cmd::move_percent() {
	ftl::cmd::jump_by_percent
}

ftl::cmd::goto_next_same_extension() {
	ftl_state_search_string=".$ftl_state_current_extension"
	ftl_state_pending_input="${ftl_kbd_command_to_key[find_next]}"
}

ftl::cmd::goto_alt1() {
	ftl::cmd::goto_next_same_extension
}

ftl::cmd::goto_next_diff_extension() {
	local i
	for (( i = ftl_state_cursor_index + 1 ; i != ftl_list_entry_count ; i++ )) ; do
		if [[ ! "${ftl_list_entries[i]##*/}" =~ ".$ftl_state_current_extension" ]] ; then
			ftl::list::render "$i"
			return
		fi
	done
	ftl::list::render
}

ftl::cmd::goto_alt2() {
	ftl::cmd::goto_next_diff_extension
}

ftl::cmd::goto_by_index() {
	ftl_cfg_line_color_current="$ftl_cfg_line_color_highlight"
	ftl::list::change_dir
	ftl_cfg_line_color_current="$ftl_cfg_line_color_default"
	ftl::cmd::prompt 'to: '
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		ftl::cmd::dispatch_command "$ftl_kbd_current_key"
	else
		ftl::list::change_dir
	fi
}

ftl::cmd::goto_entry() {
	ftl::cmd::goto_by_index
}

ftl::cmd::goto_next_selected() {
	(( ${#ftl_selection_tags[@]} )) || return 0
	[[ -z "$ftl_selection_class_cursor" ]] && ftl_selection_class_cursor=0
	(( ftl_selection_class_cursor++ ))
	(( ftl_selection_class_cursor >= ${#ftl_selection_tags[@]} )) && ftl_selection_class_cursor=0
	ftl::sel::goto_by_index "$ftl_selection_class_cursor"
}

ftl::cmd::goto_next_tag() {
	ftl::cmd::goto_next_selected
}

ftl::cmd::goto_prev_selected() {
	(( ${#ftl_selection_tags[@]} )) || return 0
	[[ -z "$ftl_selection_class_cursor" ]] && ftl_selection_class_cursor=0
	(( ftl_selection_class_cursor-- ))
	(( ftl_selection_class_cursor < 0 )) \
		&& ftl_selection_class_cursor=$(( ${#ftl_selection_tags[@]} - 1 ))
	ftl::sel::goto_by_index "$ftl_selection_class_cursor"
}

ftl::cmd::goto_prev_tag() {
	ftl::cmd::goto_prev_selected
}

ftl::cmd::cd_prompt() {
	ftl::cmd::prompt 'cd: '
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		ftl::list::change_dir "${ftl_kbd_current_key/\~/$HOME}"
	else
		ftl::list::render
	fi
}

ftl::cmd::change_dir() {
	ftl::cmd::cd_prompt
}

#----------------------------------------------------------------------------
