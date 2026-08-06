# commands/preview.sh — Preview commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 8. Preview commands
#----------------------------------------------------------------------------

ftl::cmd::scroll_preview_down() {
	if (( ftl_preview_is_vim )) ; then
		tmux send -t "$ftl_pane_preview_id" C-D
	elif [[ -n "$ftl_pane_preview_id" ]] ; then
		tmux send -t "$ftl_pane_preview_id" j
	fi
}

ftl::cmd::preview_down() {
	ftl::cmd::scroll_preview_down
}

ftl::cmd::scroll_preview_up() {
	if (( ftl_preview_is_vim )) ; then
		tmux send -t "$ftl_pane_preview_id" C-U
	elif [[ -n "$ftl_pane_preview_id" ]] ; then
		tmux send -t "$ftl_pane_preview_id" k
	fi
}

ftl::cmd::preview_up() {
	ftl::cmd::scroll_preview_up
}

ftl::cmd::scroll_fixed_preview_down() {
	[[ -n "$ftl_pane_fixed_preview_id" ]] \
		&& tmux send -t "$ftl_pane_fixed_preview_id" C-D
}

ftl::cmd::preview_down2() {
	ftl::cmd::scroll_fixed_preview_down
}

ftl::cmd::scroll_fixed_preview_up() {
	[[ -n "$ftl_pane_fixed_preview_id" ]] \
		&& tmux send -t "$ftl_pane_fixed_preview_id" C-U
}

ftl::cmd::preview_up2() {
	ftl::cmd::scroll_fixed_preview_up
}

ftl::cmd::send_preview_left() {
	[[ -n "$ftl_pane_preview_id" ]] \
		&& tmux send -t "$ftl_pane_preview_id" Left
}

ftl::cmd::preview_left() {
	ftl::cmd::send_preview_left
}

ftl::cmd::send_preview_right() {
	[[ -n "$ftl_pane_preview_id" ]] \
		&& tmux send -t "$ftl_pane_preview_id" Right
}

ftl::cmd::preview_right() {
	ftl::cmd::send_preview_right
}

ftl::cmd::toggle_preview_pane() {
	(( ftl_state_preview_pane_visible ^= 1 ))
	ftl::prev::clear
	sleep 0.05
	ftl::list::change_dir
}

ftl::cmd::preview_pane() {
	ftl::cmd::toggle_preview_pane
}

ftl::cmd::toggle_fixed_preview() {
	ftl_state_fixed_preview_filename="$ftl_state_current_basename"
	ftl::prev::clear
	sleep 0.05
	ftl::list::change_dir
}

ftl::cmd::preview_pane2() {
	ftl::cmd::toggle_fixed_preview
}

ftl::cmd::toggle_dirs_only_preview() {
	local t=$ftl_state_current_tab_index
	if [[ -n "${ftl_tab_preview_dirs_only[$t]}" ]] ; then
		ftl_tab_preview_dirs_only[$t]=
	else
		ftl_tab_preview_dirs_only[$t]='ᴰ'
	fi
	ftl::list::render
}

ftl::cmd::preview_dir_only() {
	ftl::cmd::toggle_dirs_only_preview
}

ftl::cmd::toggle_ext_preview() {
	[[ -n "$ftl_state_current_extension" ]] || return 0
	(( ftl_view_preview_ignore_exts[$ftl_state_current_extension] ^= 1 ))
	ftl::list::change_dir
}

ftl::cmd::preview_ext_ign() {
	ftl::cmd::toggle_ext_preview
}

ftl::cmd::toggle_image_preview() {
	(( ftl_state_images_hidden ^= 1 ))
	local e
	for e in $(tr '|' ' ' <<< "$ftl_cfg_image_extensions_regex") ; do
		ftl_view_preview_ignore_exts[$e]=$ftl_state_images_hidden
	done
	ftl::list::change_dir
}

ftl::cmd::preview_image() {
	ftl::cmd::toggle_image_preview
}

ftl::cmd::refresh_preview() {
	if [[ -d "$ftl_state_current_path" ]] ; then
		rm "$FTL_STATE_DIR/montage/$ftl_state_current_path/montage.jpg" 2>&-
		true
	else
		"$ftl_gen_dir/generator_one" "$ftl_cache_thumb_dir" \
			"$ftl_state_current_path" "$ftl_state_current_extension" 1
	fi
	ftl::prev::show_image FTL_RESTART_W3M
	ftl::list::render
}

ftl::cmd::preview_refresh() {
	ftl::cmd::refresh_preview
}

ftl::cmd::toggle_preview_tail() {
	if [[ "${ftl_view_vim_tail_commands[$ftl_state_current_path]}" == "+$ " ]] ; then
		ftl_view_vim_tail_commands[$ftl_state_current_path]='+0 '
	else
		ftl_view_vim_tail_commands[$ftl_state_current_path]='+$ '
	fi
	ftl::list::render
}

ftl::cmd::preview_tail() {
	ftl::cmd::toggle_preview_tail
}

ftl::cmd::lock_preview() {
	local p="$FTL_CFG/etc/core/lib/lock_preview"
	local file
	file=$(cd "$p" ; fd | fzf-tmux $ftl_cfg_fzf_popup_opts)
	[[ -n "$file" ]] && source "$p/$file"
	ftl::list::render
}

ftl::cmd::preview_lock() {
	ftl::cmd::lock_preview
}

ftl::cmd::unlock_preview() {
	rm "$ftl_state_session_dir/lock_preview/$ftl_state_current_path" 2>&-
	ftl::list::render
}

ftl::cmd::preview_lock_clr() {
	ftl::cmd::unlock_preview
}

ftl::cmd::set_preview_mode_1() {
	ftl_state_alt_preview_mode=1
	ftl::list::render
}

ftl::cmd::preview_m1() {
	ftl::cmd::set_preview_mode_1
}

ftl::cmd::set_preview_mode_2() {
	ftl_state_alt_preview_mode=2
	ftl::list::render
}

ftl::cmd::preview_m2() {
	ftl::cmd::set_preview_mode_2
}

ftl::cmd::set_preview_mode_3() {
	ftl_state_alt_preview_mode=3
	ftl::list::render
}

ftl::cmd::preview_m3() {
	ftl::cmd::set_preview_mode_3
}

ftl::cmd::set_preview_mode_4() {
	ftl_state_alt_preview_mode=4
	ftl::list::render
}

ftl::cmd::preview_m4() {
	ftl::cmd::set_preview_mode_4
}

ftl::cmd::set_preview_mode_5() {
	ftl_state_alt_preview_mode=5
	ftl::list::render
}

ftl::cmd::preview_m5() {
	ftl::cmd::set_preview_mode_5
}

ftl::cmd::set_full_preview_mode_1() {
	[[ "$ftl_state_current_extension" == 'md' ]] || return 0
	ftl::prev::clear
	glow "$ftl_state_current_basename" --pager
	ftl::list::render
}

ftl::cmd::full_preview_m1() {
	ftl::cmd::set_full_preview_mode_1
}

ftl::cmd::set_full_preview_mode_2() {
	[[ "$ftl_state_current_extension" == 'md' ]] || return 0
	ftl::util::run_maximized _ftl::cmd::_ftl::plugin::core::mo_vimb "$ftl_state_current_basename"
	ftl::list::render
}

ftl::cmd::full_preview_m2() {
	ftl::cmd::set_full_preview_mode_2
}

ftl::cmd::set_full_preview_mode_3() {
	[[ "$ftl_state_current_extension" == 'md' ]] || return 0
	ftl::util::run_maximized _ftl::cmd::_ftl::plugin::core::mo_vimb -R .
	ftl::list::render
}

ftl::cmd::full_preview_m3() {
	ftl::cmd::set_full_preview_mode_3
}

ftl::cmd::set_full_preview_mode_4() {
	ftl_state_alt_preview_mode=4
	ftl::list::render
}

ftl::cmd::full_preview_m4() {
	ftl::cmd::set_full_preview_mode_4
}

ftl::cmd::set_full_preview_mode_5() {
	ftl_state_alt_preview_mode=5
	ftl::list::render
}

ftl::cmd::full_preview_m5() {
	ftl::cmd::set_full_preview_mode_5
}

_ftl::cmd::_ftl::plugin::core::mo_vimb() {
	mo --no-open "$@" &>/dev/null
	vimb "http://localhost:6275" 2>/dev/null
}

ftl::cmd::cycle_preview_size() {
	(( ftl_state_preview_zoom_index += 1, \
	   ftl_state_preview_zoom_index >= ${#ftl_cfg_preview_zoom_levels[@]} )) \
		&& ftl_state_preview_zoom_index=0
	ftl::list::compute_preview_width
	[[ -n "$ftl_pane_preview_id" ]] \
		&& tmux resizep -t "$ftl_pane_preview_id" -x "$ftl_pane_resize_target" &>/dev/null
	ftl::list::refresh_dir '' 0
}

ftl::cmd::preview_size() {
	ftl::cmd::cycle_preview_size
}

ftl::cmd::toggle_image_zoom() {
	(( ftl_cfg_image_zoomed ^= 1 ))
	ftl::list::render
}

ftl::cmd::image_zoom() {
	ftl::cmd::toggle_image_zoom
}

ftl::cmd::external_viewer_mode_1() {
	ftl_state_external_viewer_mode=1
	ftl::prev::dispatch
}

ftl::cmd::external_mode1() {
	ftl::cmd::external_viewer_mode_1
}

ftl::cmd::external_viewer_mode_2() {
	ftl_state_external_viewer_mode=2
	ftl::prev::dispatch
}

ftl::cmd::external_mode2() {
	ftl::cmd::external_viewer_mode_2
}

ftl::cmd::external_viewer_mode_3() {
	ftl_state_external_viewer_mode=3
	ftl::prev::dispatch
}

ftl::cmd::external_mode3() {
	ftl::cmd::external_viewer_mode_3
}

ftl::cmd::show_in_background_player() {
	[[ "$ftl_state_current_extension" =~ $ftl_cfg_media_extensions_regex ]] || return 0
	source "$ftl_cfg_background_player" "${ftl_selection_current[@]}"
	ftl::list::render
}

ftl::cmd::preview_show() {
	ftl::cmd::show_in_background_player
}

ftl::cmd::show_via_fzf_viewer() {
	local p="$FTL_CFG/etc/viewers"
	local viewer
	viewer=$(cd "$p" 2>&- && fd | fzf-tmux -p80% --cycle --reverse --info=inline)
	[[ -n "$viewer" ]] && source "$p/$viewer"
	ftl::list::render
}

ftl::cmd::preview_show_fzf() {
	ftl::cmd::show_via_fzf_viewer
}

ftl::cmd::queue_to_player() {
	[[ "$ftl_state_current_extension" =~ $ftl_cfg_media_extensions_regex ]] || return 0
	( $ftl_cfg_queue_player "${ftl_selection_current[@]}" & )
	ftl::sel::clear_all
	ftl::list::render
}

ftl::cmd::preview_queue() {
	ftl::cmd::queue_to_player
}

ftl::cmd::kill_media_player() {
	if (( ftl_preview_media_pid )) ; then
		kill "$ftl_preview_media_pid" &>/dev/null
		ftl_preview_media_pid=
	fi
}

ftl::cmd::player_kill() {
	ftl::cmd::kill_media_player
}

ftl::cmd::detach_editor_preview() {
	if (( ftl_preview_is_vim )) ; then
		ftl_preview_is_vim=
		ftl_pane_preview_id=
		ftl::list::change_dir
	fi
}

ftl::cmd::editor_detach() {
	ftl::cmd::detach_editor_preview
}

#----------------------------------------------------------------------------
