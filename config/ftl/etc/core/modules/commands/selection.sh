# commands/selection.sh — Selection commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 2. Selection commands
#----------------------------------------------------------------------------

ftl::cmd::select_all() {
	local p
	for p in "${ftl_list_entries[@]}" ; do
		[[ -z "${ftl_selection_tags[$p]:-}" ]] \
			&& ftl_selection_tags["$p"]='▪' \
			&& ftl::sel::adjust_total_size + "$p"
	done
	ftl::list::render
}

ftl::cmd::select_all_files() {
	local p
	for p in "${ftl_list_entries[@]}" ; do
		if [[ -f "$p" && -z "${ftl_selection_tags[$p]:-}" ]] ; then
			ftl_selection_tags["$p"]='▪'
			ftl::sel::adjust_total_size + "$p"
		fi
	done
	ftl::list::render
}

ftl::cmd::select_all_directories() {
	local p
	for p in "${ftl_list_entries[@]}" ; do
		if [[ -d "$p" && -z "${ftl_selection_tags[$p]:-}" ]] ; then
			ftl_selection_tags["$p"]='▪'
			ftl::sel::adjust_total_size + "$p"
		fi
	done
	ftl::list::render
}

ftl::cmd::flip_down() {
	local i
	local count="${ftl_kbd_count:-1}"
	for (( i = ftl_state_cursor_index ; i < ftl_state_cursor_index + count && i < ftl_list_entry_count ; i++ )) ; do
		ftl::sel::flip "${ftl_list_entries[i]}"
	done
	ftl::list::move_cursor "${count}"
	ftl::list::render
}

ftl::cmd::selection_flip_down() {
	ftl::cmd::flip_down
}

ftl::cmd::flip_up() {
	local i
	local count="${ftl_kbd_count:-1}"
	for (( i = ftl_state_cursor_index ; i > ftl_state_cursor_index - count && i > 0 ; i-- )) ; do
		ftl::sel::flip "${ftl_list_entries[i]}"
	done
	ftl::list::move_cursor "-${count}"
	ftl::list::render
}

ftl::cmd::selection_flip_up() {
	ftl::cmd::flip_up
}

_ftl::cmd::select_class_with_count() {
	local class="$1"
	local i
	local count="${ftl_kbd_count:-1}"
	for (( i = 0 ; i < count && ftl_state_cursor_index < ftl_list_entry_count ; i++ )) ; do
		_ftl::cmd::toggle_class "$class"
		ftl::list::move_cursor 1
		ftl_state_cursor_index=$nf
	done
	(( ftl_selection_revision++ ))
	ftl::list::render
}

_ftl::cmd::toggle_class() {
	local class="$1"
	local entry="${ftl_list_entries[$ftl_state_cursor_index]}"
	if [[ "${ftl_selection_tags[$entry]:-}" == "${ftl_cfg_glyph_tag_classes[$class]}" ]] ; then
		unset 'ftl_selection_tags[$entry]'
	else
		ftl_selection_tags[$entry]=${ftl_cfg_glyph_tag_classes[$class]}
	fi
}

ftl::cmd::select_class_1() { _ftl::cmd::select_class_with_count 1 ; }
ftl::cmd::select_class_2() { _ftl::cmd::select_class_with_count 2 ; }
ftl::cmd::select_class_3() { _ftl::cmd::select_class_with_count 3 ; }
ftl::cmd::select_class_4() { _ftl::cmd::select_class_with_count 4 ; }

ftl::cmd::selection_class_1() { ftl::cmd::select_class_1 ; }
ftl::cmd::selection_class_2() { ftl::cmd::select_class_2 ; }
ftl::cmd::selection_class_3() { ftl::cmd::select_class_3 ; }
ftl::cmd::selection_class_4() { ftl::cmd::select_class_4 ; }

ftl::cmd::untag_all() {
	ftl::sel::clear_all
	ftl::list::render
}

ftl::cmd::selection_untag_all() {
	ftl::cmd::untag_all
}

ftl::cmd::untag_via_fzf() {
	ftl::sel::validate_existence || return 0
	ftl::sel::fzf_tag_or_untag U "$(printf "%s\n" "${!ftl_selection_tags[@]}" \
		| lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '⊟')"
	ftl::list::render
}

ftl::cmd::selection_untag_fzf() {
	ftl::cmd::untag_via_fzf
}

ftl::cmd::copy_paths_to_clipboard() {
	ftl::list::quote_selection | xsel -b -i
}

ftl::cmd::copy_clipboard() {
	ftl::cmd::copy_paths_to_clipboard
}

ftl::cmd::select_same_extension() {
	local oifs="$IFS"
	IFS=$'\n'
	local p
	for p in $(fd -H -I -d1 | sed 's/^.\///' | rg "\.$ftl_state_current_extension$") ; do
		ftl::sel::set "$PWD/$p"
	done
	IFS="$oifs"
	ftl::list::render
}

ftl::cmd::selection_ext() {
	ftl::cmd::select_same_extension
}

ftl::cmd::select_same_extension_recursive() {
	local oifs="$IFS"
	IFS=$'\n'
	local p
	for p in $(fd -H -I | sed 's/^.\///' | rg "\.$ftl_state_current_extension$") ; do
		ftl::sel::set "$PWD/$p"
	done
	IFS="$oifs"
	ftl::list::render
}

ftl::cmd::selection_ext_all() {
	ftl::cmd::select_same_extension_recursive
}

ftl::cmd::select_extension_via_fzf() {
	ftl::sel::fzf_tag_or_untag T "$(fd -H -I -d1 | rg "\.$ftl_state_current_extension$" \
		| lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '▪')"
	ftl::list::render
}

ftl::cmd::selection_ext_fzf() {
	ftl::cmd::select_extension_via_fzf
}

ftl::cmd::select_extension_recursive_via_fzf() {
	ftl::sel::fzf_tag_or_untag T "$(fd -H -I | rg "\.$ftl_state_current_extension$" \
		| lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '▪')"
	ftl::list::render
}

ftl::cmd::selection_ext_all_fzf() {
	ftl::cmd::select_extension_recursive_via_fzf
}

ftl::cmd::select_via_fzf() {
	ftl::sel::fzf_tag_or_untag T "$(fd -H -I --color=always -d1 \
		| fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '▪')"
	ftl::list::render
}

ftl::cmd::selection_fzf() {
	ftl::cmd::select_via_fzf
}

ftl::cmd::select_recursive_via_fzf() {
	ftl::sel::fzf_tag_or_untag T "$(fd -H -I --color=always \
		| fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '▪')"
	ftl::list::render
}

ftl::cmd::selection_fzf_all() {
	ftl::cmd::select_recursive_via_fzf
}

ftl::cmd::select_images_via_sxiv() {
	local oifs="$IFS"
	IFS=$'\n'
	local i
	for i in $(ftl::list::quote_all_files | $ftl_cfg_image_viewer -i -b -q -o -f -t) ; do
		ftl_selection_tags[$i]='▪'
		ftl::sel::adjust_total_size + "$i"
	done
	IFS="$oifs"
	ftl::list::change_dir
}

ftl::cmd::image_select() {
	ftl::cmd::select_images_via_sxiv
}

ftl::cmd::select_images_recursive_via_sxiv() {
	local oifs="$IFS"
	IFS=$'\n'
	local image
	for image in $($ftl_cfg_image_viewer -b -q -o -f -t *) ; do
		ftl_selection_tags[$PWD/$image]='▪'
		ftl::sel::adjust_total_size + "$image"
	done
	IFS="$oifs"
	ftl::list::change_dir
}

ftl::cmd::image_select_rec() {
	ftl::cmd::select_images_recursive_via_sxiv
}

ftl::cmd::goto_selection_via_fzf() {
	ftl::sel::validate_existence || return 0
	_ftl::cmd::process_search_results f fzf "$(printf "%s\n" "${!ftl_selection_tags[@]}" \
		| sort -u | lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts --tac --ansi --expect=ctrl-t)"
}

ftl::cmd::selection_goto() {
	ftl::cmd::goto_selection_via_fzf
}

ftl::cmd::merge_from_panes() {
	local p="$FTL_CFG/etc/core/lib/merge"
	local file
	file=$(cd "$p" 2>&- && fd | fzf-tmux --header 'Merge tags:' $ftl_cfg_fzf_popup_opts)
	[[ -n "$file" ]] && source "$p/$file"
	ftl::list::change_dir
}

ftl::cmd::selection_merge() {
	ftl::cmd::merge_from_panes
}

ftl::cmd::merge_all_panes() {
	source "$FTL_CFG/etc/core/lib/merge/all"
	ftl::list::render
}

ftl::cmd::selection_merge_all() {
	ftl::cmd::merge_all_panes
}

ftl::cmd::append_selection_to_file() {
	ftl::cmd::prompt 'add selection to: '
	if [[ -n "$ftl_kbd_current_key" ]] ; then
		ftl::list::quote_selection >> "$ftl_kbd_current_key"
	fi
	ftl::list::change_dir
}

ftl::cmd::add_selection_to_file() {
	ftl::cmd::append_selection_to_file
}

#----------------------------------------------------------------------------
