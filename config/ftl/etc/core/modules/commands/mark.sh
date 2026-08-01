# commands/mark.sh — Mark/history commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 11. Mark/history commands
#----------------------------------------------------------------------------

ftl::cmd::set_mark() {
	read -sn1
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		if [[ -d "${ftl_list_entries[$ftl_state_cursor_index]}" ]] ; then
			ftl_mark_session_marks[$ftl_kbd_current_key]="${ftl_list_entries[$ftl_state_cursor_index]}/$"
		else
			ftl_mark_session_marks[$ftl_kbd_current_key]="${ftl_list_entries[$ftl_state_cursor_index]}"
		fi
	fi
}

ftl::cmd::mark() {
	ftl::cmd::set_mark
}

ftl::cmd::goto_mark() {
	read -n 1
	if [[ -n "$ftl_kbd_current_key" && -n "${ftl_mark_session_marks[$ftl_kbd_current_key]:-}" ]] ; then
		local d
		d="$(dirname "${ftl_mark_session_marks[$ftl_kbd_current_key]}")"
		ftl::list::change_dir "$d" "$(basename "${ftl_mark_session_marks[$ftl_kbd_current_key]}")"
	else
		ftl::list::render
	fi
}

ftl::cmd::mark_go() {
	ftl::cmd::goto_mark
}

ftl::cmd::goto_mark_new_tab() {
	read -n 1
	if [[ -n "$ftl_kbd_current_key" && -n "${ftl_mark_session_marks[$ftl_kbd_current_key]:-}" ]] ; then
		local d
		d="$(dirname "${ftl_mark_session_marks[$ftl_kbd_current_key]}")"
		ftl::tab::create
		ftl::list::change_dir "$d" "$(basename "${ftl_mark_session_marks[$ftl_kbd_current_key]}")"
	else
		ftl::list::render
	fi
}

ftl::cmd::mark_go_tab() {
	ftl::cmd::goto_mark_new_tab
}

ftl::cmd::goto_mark_via_fzf() {
	_ftl::cmd::process_search_results f fzf \
		"$({ ftl::mark::user_marks_provider ; printf "%s\n" "${ftl_mark_session_marks[@]}" ; } \
			| sort -u | lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts -m --expect=ctrl-t --ansi)"
}

ftl::cmd::mark_fzf() {
	ftl::cmd::goto_mark_via_fzf
}

ftl::mark::user_marks_provider() {
	:
}

ftl::cmd::add_persistent_mark() {
	{
		cat "$FTL_STATE_DIR/shared/marks" 2>&-
		if [[ -d "$ftl_state_current_path" ]] ; then
			echo "$ftl_state_current_path/\$"
		else
			echo "$ftl_state_current_path"
		fi
	} | awk '!seen[$0]++' > /tmp/ftl_marks_tmp ; mv /tmp/ftl_marks_tmp "$FTL_STATE_DIR/shared/marks"
}

ftl::cmd::gmark() {
	ftl::cmd::add_persistent_mark
}

ftl::cmd::goto_persistent_via_fzf() {
	[[ -e "$FTL_STATE_DIR/shared/marks" ]] || return 0
	_ftl::cmd::process_search_results f fzf \
		"$({ cat "$FTL_STATE_DIR/shared/marks" ; ftl::mark::user_marks_provider ; } \
			| lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts --cycle -m --expect=ctrl-t --ansi)"
}

ftl::cmd::gmark_fzf() {
	ftl::cmd::goto_persistent_via_fzf
}

ftl::cmd::clear_persistent_marks() {
	ftl::cmd::prompt 'clear persistent marks? [y|N]' -sn1
	if [[ $ftl_kbd_current_key == y ]] ; then
		: >"$FTL_STATE_DIR/shared/marks"
	fi
	ftl::list::render
}

ftl::cmd::gmarks_clear() {
	ftl::cmd::clear_persistent_marks
}

ftl::cmd::goto_session_history() {
	local h="$ftl_state_session_dir/history"
	ftl::util::dedup_file "$h"
	_ftl::cmd::process_search_results f fzf \
		"$(<"$h" lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts --tac --ansi --expect=ctrl-t)"
}

ftl::cmd::history_go() {
	ftl::cmd::goto_session_history
}

ftl::cmd::goto_global_history() {
	local h="$FTL_STATE_DIR/shared/history"
	ftl::util::dedup_file "$h"
	_ftl::cmd::process_search_results f fzf \
		"$(<"$h" lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts --tac --ansi --expect=ctrl-t)"
}

ftl::cmd::ghistory() {
	ftl::cmd::goto_global_history
}

ftl::cmd::goto_global_history_subdir() {
	local h="$FTL_STATE_DIR/shared/history"
	ftl::util::dedup_file "$h"
	_ftl::cmd::process_search_results f fzf \
		"$(cat "$h" | rg "$(pwd)" | lscolors \
			| fzf-tmux $ftl_cfg_fzf_popup_opts --tac --ansi --expect=ctrl-t)"
}

ftl::cmd::ghistory_subdir() {
	ftl::cmd::goto_global_history_subdir
}

ftl::cmd::edit_global_history() {
	ftl::util::dedup_file "$FTL_STATE_DIR/shared/history"
	rg -v -x -F -f \
		"$(<"$FTL_STATE_DIR/shared/history" lscolors \
			| fzf-tmux $ftl_cfg_fzf_popup_opts --tac -m --ansi)" \
		"$FTL_STATE_DIR/shared/history" > /tmp/ftl_hist_tmp ; mv /tmp/ftl_hist_tmp "$FTL_STATE_DIR/shared/history"
}

ftl::cmd::ghistory_edit() {
	ftl::cmd::edit_global_history
}

ftl::cmd::clear_global_history() {
	ftl::cmd::prompt 'clear global history? [y|N]' -sn1
	if [[ $ftl_kbd_current_key == y ]] ; then
		rm "$FTL_STATE_DIR/shared/history" 2>&-
	fi
	ftl::list::render
}

ftl::cmd::ghistory_clear() {
	ftl::cmd::clear_global_history
}

#----------------------------------------------------------------------------
