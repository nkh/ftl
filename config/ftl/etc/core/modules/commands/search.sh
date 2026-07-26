# commands/search.sh — Search commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 5. Search commands
#----------------------------------------------------------------------------

ftl::cmd::find_in_dir() {
	ftl::cmd::prompt "find: " -i "$ftl_state_search_string"
	ftl_state_pending_input="${ftl_kbd_command_to_key[find_next]}"
}

ftl::cmd::find_entry() {
	ftl::cmd::find_in_dir
}

ftl::cmd::find_next() {
	local i
	for (( i = ftl_state_cursor_index + 1 ; i != ftl_list_entry_count ; i++ )) ; do
		if [[ "${ftl_list_entries[i]##*/}" =~ "$ftl_state_search_string" ]] ; then
			ftl::list::render "$i"
			return
		fi
	done
	ftl::list::render
}

ftl::cmd::find_previous() {
	local i
	for (( i = ftl_state_cursor_index - 1 ; i != -1 ; i-- )) ; do
		if [[ "${ftl_list_entries[i]##*/}" =~ "$ftl_state_search_string" ]] ; then
			ftl::list::render "$i"
			return
		fi
	done
	ftl::list::render
}

ftl::cmd::find_via_fzf() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results fzf \
		"$({ fd -HI -d1 -td | sort ; fd -HI -d1 -tf -tl | sort ; } \
			| sed 's/^.\///' | fzf_vvip -m $ftl_cfg_fzf_pane_opts)"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_fzf() {
	ftl::cmd::find_via_fzf
}

ftl::cmd::find_via_fzf_recursive() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results fzf \
		"$(fd -HI -E'.git/*' | sed 's/^.\///' | fzf_vvip -m $ftl_cfg_fzf_pane_opts)"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_fzf_all() {
	ftl::cmd::find_via_fzf_recursive
}

ftl::cmd::find_dirs_via_fzf() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results fzf \
		"$(fd -td -I -L | sed 's/^.\///' | fzf_vvip -m $ftl_cfg_fzf_pane_opts)"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_fzf_dirs() {
	ftl::cmd::find_dirs_via_fzf
}

ftl::cmd::find_via_frf() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results fzf "$(frf 1 '' ctrl-t)"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_frf() {
	ftl::cmd::find_via_frf
}

ftl::cmd::find_via_frf_recursive() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results fzf "$(frf 1000 '' ctrl-t)"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_frf_all() {
	ftl::cmd::find_via_frf_recursive
}

ftl::cmd::rg_open_file() {
	exec 2>&9
	ftl::prev::clear
	local rg_e
	rg_e="$(fzfr fzf+m)"
	exec 2>"$ftl_state_session_dir/log"
	ftl::util::enter_alt_screen
	[[ -n "$rg_e" ]] && $ftl_cfg_editor $(<<<"$rg_e" awk -F: '{printf "%s +%s", $1, $2}')
}

ftl::cmd::open_rg() {
	ftl::cmd::rg_open_file
}

ftl::cmd::rg_goto_file() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results rg "$(fzfr "fzf--expect=ctrl-t")"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::go_rg() {
	ftl::cmd::rg_goto_file
}

ftl::cmd::rg_goto_single_match() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results rg "$(frf 1000 '' ctrl-t frg)"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::go_rg_one_match() {
	ftl::cmd::rg_goto_single_match
}

ftl::cmd::rg_edit_files() {
	exec 2>&9
	ftl::prev::clear
	local rgls
	rgls="$(_ftl::cmd::build_vim_args_from_rg)"
	[[ -n "$rgls" ]] && /bin/bash -c "$ftl_cfg_editor $rgls"
	exec 2>"$ftl_state_session_dir/log"
	ftl::list::change_dir
}

ftl::cmd::go_rgl() {
	ftl::cmd::rg_edit_files
}

_ftl::cmd::build_vim_args_from_rg() {
	local gls=""
	local g l _
	while IFS=: read -r g l _ ; do
		[[ -z "$g" ]] && continue
		if [[ -n "$gls" ]] ; then
			gls+=" -c \"tabe +$l $g\""
		else
			gls+=" +$l $g"
		fi
	done <<<"$(fzfr)"
	echo "$gls"
}

_ftl::cmd::process_search_results() {
	local type="$1"
	local results="$2"
	local prev_pwd=
	local in_tab=
	local dst

	if [[ $type == "f" ]] ; then
		prev_pwd=
		shift
	else
		prev_pwd="$PWD"
	fi
	shift

	while read -r dst ; do
		_ftl::cmd::check_open_in_tab "$dst"
		if [[ $type == "fzf" ]] ; then
			_ftl::cmd::goto_fzf_result "$in_tab" "$prev_pwd" "$dst"
		elif [[ $type == "rg" ]] ; then
			_ftl::cmd::goto_rg_result "$in_tab" "$prev_pwd" "$dst"
		fi
	done <<<"$results"
}

_ftl::cmd::check_open_in_tab() {
	if [[ -z "$in_tab" ]] ; then
		if [[ "$1" == ctrl-t ]] ; then
			in_tab=1
		else
			in_tab=0
		fi
	fi
}

_ftl::cmd::goto_fzf_result() {
	local in_tab="$1"
	local prev_pwd="$2"
	local dst="$3"
	local d
	d="$(dirname "$dst")"
	(( in_tab )) && ftl::tab::create
	local nd
	if [[ -n "$prev_pwd" ]] ; then
		nd="$prev_pwd/$d"
	else
		nd="$d"
	fi
	local dst_basename
	dst_basename="$(basename "$dst")"
	if [[ -d "$nd/$dst_basename" ]] ; then
		ftl::list::change_dir "$nd/$dst_basename"
	else
		ftl::list::change_dir "$nd" "$dst_basename"
	fi
}

_ftl::cmd::goto_rg_result() {
	local in_tab="$1"
	local prev_pwd="$2"
	local dst="$3"
	local g l
	g=${dst%%:*}
	l=${dst#*:}
	l=${l%%:*}
	echo "$dst -> $g => $l" >&3
	local d
	d="$(dirname "$g")"
	(( in_tab )) && ftl::tab::create
	ftl::list::change_dir "$prev_pwd/$d" "$(basename "$g")"
}

ftl::cmd::goto_image_via_sxiv() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results f fzf \
		"$(ftl::list::quote_all_files | $ftl_cfg_image_viewer -i -b -q -o -f -t \
			| fzf-tmux $ftl_cfg_fzf_popup_opts $ftl_cfg_fzf_sxiv_opts)"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::image_go_sxiv() {
	ftl::cmd::goto_image_via_sxiv
}

ftl::cmd::goto_image_via_sxiv_recursive() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results f fzf \
		"$($ftl_cfg_image_viewer -b -q -o -f -t * \
			| fzf-tmux $ftl_cfg_fzf_popup_opts $ftl_cfg_fzf_sxiv_opts)"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::image_go_sxiv_rec() {
	ftl::cmd::goto_image_via_sxiv_recursive
}

ftl::cmd::goto_image_via_fzf() {
	exec 2>&9
	ftl::prev::clear
	_ftl::cmd::process_search_results f fzf \
		"$(fzfi --expect=ctrl-t -q "$(echo "$ftl_cfg_image_extensions_regex" \
			| perl -pe 's/(^|\|)/ $1 ./g')")"
	exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::image_fzf() {
	ftl::cmd::goto_image_via_fzf
}

#----------------------------------------------------------------------------
