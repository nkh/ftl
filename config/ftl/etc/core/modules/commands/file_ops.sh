# commands/file_ops.sh — File operation commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 3. File operation commands
#----------------------------------------------------------------------------

ftl::cmd::edit_current() {
	ftl::prev::clear
	ftl::util::enter_alt_screen
	ftl::pane::stop_file_watcher
	${ftl_cfg_editor} "${1:-${ftl_list_entries[$ftl_state_cursor_index]}}"
	ftl::util::enter_alt_screen
	ftl_state_external_viewer_mode=0
	ftl::list::change_dir
}

ftl::cmd::edit() {
	ftl::cmd::edit_current
}

ftl::cmd::edit_in_vim() {
	ftl::prev::clear
	$ftl_cfg_editor "${ftl_selection_current[@]}"
	ftl::list::change_dir
}

ftl::cmd::vim_edit() {
	ftl::cmd::edit_in_vim
}

ftl::cmd::edit_in_vim_window() {
	tmux new-window "$ftl_cfg_editor ${ftl_selection_current[*]@Q}"
}

ftl::cmd::vim_edit_window() {
	ftl::cmd::edit_in_vim_window
}

ftl::cmd::edit_in_shared_vim_window() {
	if ftl::pane::window_exists "v$$" ; then
		_ftl::cmd::open_files_in_shared_vim "${ftl_selection_current[@]}"
	else
		ftl::cmd::edit_in_vim_window -n "v$$"
	fi
	tmux select-window -t "v$$"
}

ftl::cmd::vim_edit_shared_window() {
	ftl::cmd::edit_in_shared_vim_window
}

_ftl::cmd::open_files_in_shared_vim() {
	local a
	for a in "$@" ; do
		tmux send-keys -t "v$$" Escape escape :tabe \ "$(printf '%q\n' "$a")" ENTER
	done
}

ftl::cmd::vim_tabe_shared_window() {
	_ftl::cmd::open_files_in_shared_vim
}

ftl::cmd::cat_in_terminal() {
	ftl::pane::split_or_respawn "cat ${ftl_state_current_path@Q} ; read -sn 100"
}

ftl::cmd::terminal_cat() {
	ftl::cmd::cat_in_terminal
}

ftl::cmd::hex_view() {
	ftl::pane::split_or_respawn "$ftl_cfg_hex_viewer ${ftl_state_current_path@Q} ; read -sn 100"
}

ftl::cmd::hexview() {
	ftl::cmd::hex_view
}

ftl::cmd::hex_edit() {
	ftl::pane::split_or_respawn "$ftl_cfg_hex_editor ${ftl_state_current_path@Q}"
}

ftl::cmd::hexedit() {
	ftl::cmd::hex_edit
}

ftl::cmd::copy_to_prompted() {
	ftl::cmd::prompt 'write to: '
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		if ftl::sel::validate_existence ; then
			_ftl::cmd::copy_or_move_with_tags copy "$ftl_kbd_current_key"
		else
			_ftl::cmd::copy_or_move copy "$ftl_kbd_current_key" "${ftl_selection_current[@]}"
		fi
	fi
	ftl::list::change_dir
}

ftl::cmd::copy() {
	ftl::cmd::copy_to_prompted
}

ftl::cmd::delete_selection() {
	(( ftl_list_entry_count )) || return 0
	local pc="" pt=""
	if ftl::sel::validate_existence ; then
		pc="|c"
		pt="*tags* "
	fi
	ftl::cmd::prompt "delete $pt[y|d|N$pc] ? " -n1
	_ftl::cmd::dispatch_delete "$pt"
	ftl_kbd_current_key=
	ftl::list::change_dir
}

ftl::cmd::delete_selection_cmd() {
	ftl::cmd::delete_selection
}

_ftl::cmd::dispatch_delete() {
	local pt="$1"
	if [[ -n "$pt" ]] ; then
		if [[ $ftl_kbd_current_key =~ y|d ]] ; then
			_ftl::cmd::delete_tagged
		elif [[ $ftl_kbd_current_key =~ c ]] ; then
			_ftl::cmd::delete_current
		fi
	else
		if [[ $ftl_kbd_current_key =~ y|d ]] ; then
			_ftl::cmd::delete_current
		fi
	fi
}

_ftl::cmd::delete_current() {
	if [[ "${ftl_selection_tags[$ftl_state_current_path]:-}" ]] ; then
		unset 'ftl_selection_tags[$ftl_state_current_path]'
		ftl::sel::adjust_total_size - "$ftl_state_current_path"
		(( ftl_selection_revision++ ))
	fi
	$ftl_cfg_delete_command "$ftl_state_current_path"
	ftl_list_mime_cache=()
	true
}

_ftl::cmd::delete_tagged() {
	declare -A ltags=() ; local class=
	ftl::sel::get_by_class ltags class
	(( ${#ltags[@]} )) || return 0
	ftl::sel::unset_by_class "$class"
	$ftl_cfg_delete_command "${!ltags[@]}"
	ftl_list_mime_cache=()
	true
}

ftl::cmd::create_file() {
	ftl::cmd::prompt 'touch: '
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		touch "$PWD/$ftl_kbd_current_key"
	fi
	ftl::list::change_dir "$PWD" "$ftl_kbd_current_key"
}

ftl::cmd::create_file_cmd() {
	ftl::cmd::create_file
}

ftl::cmd::create_dir_no_cd() {
	ftl::cmd::prompt 'mkdir: '
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		mkdir -p "$PWD/$ftl_kbd_current_key"
	fi
	ftl::list::change_dir
}

ftl::cmd::create_dir_no_cd_cmd() {
	ftl::cmd::create_dir_no_cd
}

ftl::cmd::create_dir_and_cd() {
	ftl::cmd::prompt 'mkdir: '
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		mkdir -p "$PWD/$ftl_kbd_current_key" \
			&& ftl::list::change_dir "$PWD/$ftl_kbd_current_key" \
			|| ftl::list::render
	else
		ftl::list::render
	fi
}

ftl::cmd::create_dir() {
	ftl::cmd::create_dir_and_cd
}

ftl::cmd::create_bulk() {
	local bulk_file="$ftl_state_session_dir/BULK"
	: >"$bulk_file"
	$ftl_cfg_editor "$bulk_file"
	if [[ -s "$bulk_file" ]] ; then
		grep '/$' "$bulk_file" | tr '\n' '\0' | xargs -r -0 mkdir -p
		_ftl::cmd::create_bulk_files "$bulk_file"
	fi
	ftl::list::change_dir
}

ftl::cmd::create_bulk_cmd() {
	ftl::cmd::create_bulk
}

_ftl::cmd::create_bulk_files() {
	grep -v '/$' "$1" | tr '\n' '\0' | xargs -r -0 dirname -z | xargs -0 mkdir -p
	grep -v '/$' "$1" | grep -v '^$' | tr '\n' '\0' | xargs -r -0 touch
}

ftl::cmd::rename_selection() {
	ftl::prev::clear
	printf "%s\n" "${ftl_selection_current[@]}" | edir
	ftl::sel::clear_all
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::rename() {
	ftl::cmd::rename_selection
}

ftl::cmd::symlink_selection() {
	ftl::sel::validate_existence && ftl::cmd::prompt "Link (${#ftl_selection_tags[@]})? [y|N]" -sn1
	if [[ $ftl_kbd_current_key == y ]] ; then
		ftl::sel::clear_all
		local f
		for f in "${ftl_selection_current[@]}" ; do
			ln -s -b "$f" .
		done
	fi
	ftl::list::change_dir
}

ftl::cmd::link() {
	ftl::cmd::symlink_selection
}

ftl::cmd::follow_symlink() {
	[[ -L "$ftl_state_current_path" ]] || return 0
	local resolved
	resolved=$(realpath "$ftl_state_current_path")
	ftl::list::change_dir "$(dirname "$resolved")" "$(basename "$resolved")"
}

ftl::cmd::follow_link() {
	ftl::cmd::follow_symlink
}

ftl::cmd::chmod_toggle_read() {
	local i mode
	for i in "${ftl_selection_current[@]}" ; do
		if [[ -r "$i" ]] ; then mode=a-r ; else mode=a+r ; fi
		chmod "$mode" "$i"
	done
	ftl::list::change_dir
}

ftl::cmd::chmod_ar() {
	ftl::cmd::chmod_toggle_read
}

ftl::cmd::chmod_toggle_write() {
	local i mode
	for i in "${ftl_selection_current[@]}" ; do
		if [[ -w "$i" ]] ; then mode=a-w ; else mode=a+w ; fi
		chmod "$mode" "$i"
	done
	ftl::list::change_dir
}

ftl::cmd::chmod_aw() {
	ftl::cmd::chmod_toggle_write
}

ftl::cmd::chmod_toggle_exec() {
	local i mode
	for i in "${ftl_selection_current[@]}" ; do
		if [[ -x "$i" ]] ; then mode=a-x ; else mode=a+x ; fi
		chmod "$mode" "$i"
	done
	ftl::list::change_dir
}

ftl::cmd::chmod_ax() {
	ftl::cmd::chmod_toggle_exec
}

ftl::cmd::chmod_via_scim() {
	ftl::prev::clear
	exec 2>&9
	"$FTL_CFG/etc/bin/scim_permission" "${ftl_selection_current[@]}"
	exec 2>"$ftl_state_session_dir/log"
	ftl::util::enter_alt_screen
}

ftl::cmd::chmod_dialog() {
	ftl::cmd::chmod_via_scim
}

ftl::cmd::copy_selection_here() {
	_ftl::cmd::copy_or_move_with_tags copy "${1:-$PWD}"
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::tag_copy() {
	ftl::cmd::copy_selection_here
}

ftl::cmd::move_selection_here() {
	_ftl::cmd::copy_or_move_with_tags move "${1:-$PWD}"
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::tag_move() {
	ftl::cmd::move_selection_here
}

ftl::cmd::copy_to_preset() {
	read -n 1
	if [[ -n "$ftl_kbd_current_key" && -n "${ftl_cfg_preset_destinations[$ftl_kbd_current_key]:-}" ]] ; then
		ftl::cmd::copy_selection_here "${ftl_cfg_preset_destinations[$ftl_kbd_current_key]}"
	fi
}

ftl::cmd::tag_copy_dest() {
	ftl::cmd::copy_to_preset
}

ftl::cmd::move_to_preset() {
	read -n 1
	if [[ -n "$ftl_kbd_current_key" && -n "${ftl_cfg_preset_destinations[$ftl_kbd_current_key]:-}" ]] ; then
		ftl::cmd::move_selection_here "${ftl_cfg_preset_destinations[$ftl_kbd_current_key]}"
	fi
}

ftl::cmd::tag_move_dest() {
	ftl::cmd::move_to_preset
}

ftl::cmd::move_via_fzf() {
	declare -A ltags=() ; local class=
	ftl::sel::get_by_class ltags class
	if (( ${#ltags[@]} )) ; then
		fzf_mv "${!ltags[@]}" && ftl::sel::unset_by_class "$class"
		true
	else
		fzf_mv "$ftl_state_current_basename"
	fi
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::tag_move_fzf() {
	ftl::cmd::move_via_fzf
}

ftl::cmd::move_to_subdir_via_fzf() {
	declare -A ltags=() ; local class=
	ftl::sel::get_by_class ltags class
	if (( ${#ltags[@]} )) ; then
		fzf_mv_sd "${!ltags[@]}" && ftl::sel::unset_by_class "$class"
		true
	else
		fzf_mv_sd "$ftl_state_current_basename"
	fi
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::tag_move_fzf_sd() {
	ftl::cmd::move_to_subdir_via_fzf
}

ftl::cmd::copy_to_other_tab() {
	ftl::sel::validate_existence || return 1
	local other_dir
	other_dir="$(_ftl::cmd::find_other_tab_dir)"
	if [[ -n "$other_dir" ]] ; then
		ftl::cmd::copy_selection_here "$other_dir"
		ftl::list::change_dir '' "$ftl_state_current_basename"
	else
		ftl::plugin::to_other_tab::create_tab_for_move
	fi
}

ftl::plugin::to_other_tab::tag_copy_to_tab() {
	ftl::cmd::copy_to_other_tab
}

ftl::cmd::move_to_other_tab() {
	ftl::sel::validate_existence || return 1
	local other_dir
	other_dir="$(_ftl::cmd::find_other_tab_dir)"
	if [[ -n "$other_dir" ]] ; then
		ftl::cmd::move_selection_here "$other_dir"
		ftl::list::change_dir '' "$ftl_state_current_basename"
	else
		ftl::plugin::to_other_tab::create_tab_for_move
	fi
}

ftl::plugin::to_other_tab::tag_move_to_tab() {
	ftl::cmd::move_to_other_tab
}

_ftl::cmd::find_other_tab_dir() {
	if (( ftl_tab_count > 2 )) ; then
		_ftl::plugin::to_other_tab::pick_via_fzf
		return $?
	fi
	_ftl::plugin::to_other_tab::pick_single
}

_ftl::cmd::copy_or_move_with_tags() {
	declare -A ltags=() ; local class=
	ftl::sel::get_by_class ltags class
	if (( ${#ltags[@]} )) ; then
		ftl::sel::unset_by_class "$class"
		_ftl::cmd::copy_or_move "$1" "$2" "${!ltags[@]}"
	else
		_ftl::cmd::copy_or_move "$1" "$2" "$ftl_state_current_basename"
	fi
	true
}

_ftl::cmd::copy_or_move() {
	if [[ $1 == copy ]] ; then
		_ftl::cmd::do_copy "$@"
	else
		_ftl::cmd::do_move "$@"
	fi
	sleep 0.01
}

_ftl::cmd::do_copy() {
	local cmvs="$ftl_state_session_dir/cmv_$SECONDS"
	printf '%s\n' "${@:3}" >"$cmvs"
	ftl::pane::run_in_bg_window \
		"xargs -a $cmvs -t -I{} -- cp -r \$'{}' ${2@Q}"
}

_ftl::cmd::do_move() {
	local cmvs="$ftl_state_session_dir/cmv_$SECONDS"
	printf '%s\0' "${@:3}" >"$cmvs"
	ftl::pane::run_in_bg_window \
		"xargs -0 -a $cmvs -t -- mv -t ${2@Q}"
}

ftl::cmd::preview_with_command() {
	ftl::cmd::prompt 'preview with: '
	ftl::list::render
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		ftl::prev::clear
		ftl::pane::split "$ftl_kbd_current_key '$ftl_state_current_basename' ; read -sn1"
	else
		ftl::list::change_dir
	fi
}

ftl::cmd::preview_with() {
	ftl::cmd::preview_with_command
}

#----------------------------------------------------------------------------
