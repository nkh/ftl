# commands/view.sh — View mode commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 10. View mode commands
#----------------------------------------------------------------------------

ftl::cmd::view_mode_all() {
        local no_redraw=$1
        local t=$ftl_state_current_tab_index
        ftl_tab_view_mode[$t]=0
        ftl_tab_filter_image_mode[$t]=
        ftl_tab_filter_image_negate[$t]=
        (( no_redraw )) || ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::view_mode_image() {
        local no_redraw=$1
        local t=$ftl_state_current_tab_index
        ftl_tab_view_mode[$t]=1
        ftl_tab_filter_image_negate[$t]=
        ftl_tab_filter_image_mode[$t]="$ftl_cfg_image_extensions_regex$"
        (( no_redraw )) || ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::view_mode_not_image() {
        local no_redraw=$1
        local t=$ftl_state_current_tab_index
        ftl_tab_view_mode[$t]=2
        ftl_tab_filter_image_mode[$t]="$ftl_cfg_image_extensions_regex$"
        ftl_tab_filter_image_negate[$t]='-v'
        (( no_redraw )) || ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::view_mode_next() {
        local t=$ftl_state_current_tab_index
        (( ftl_tab_view_mode[$t]++ ))
        (( ftl_tab_view_mode[$t] > 2 )) && ftl_tab_view_mode[$t]=0
        ftl::cmd::view_mode "${ftl_tab_view_mode[$t]}"
}

ftl::cmd::view_mode() {
        local no_redraw=$2
        [[ $1 == 0 ]] && ftl::cmd::view_mode_all "$no_redraw"
        [[ $1 == 1 ]] && ftl::cmd::view_mode_image "$no_redraw"
        [[ $1 == 2 ]] && ftl::cmd::view_mode_not_image "$no_redraw"
}

ftl::cmd::file_dir_mode() {
        local t=$ftl_state_current_tab_index
        (( ftl_tab_listing_mode[$t]++ ))
        (( ftl_tab_listing_mode[$t] > 2 )) && ftl_tab_listing_mode[$t]=0
        ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::show_hidden() {
        local t=$ftl_state_current_tab_index
        if (( ftl_tab_show_hidden[$t] )) ; then
                ftl_tab_show_hidden[$t]=
        else
                ftl_tab_show_hidden[$t]=1
        fi
        ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::hide_size() {
        ftl_state_show_size_mode=0
        ftl::list::change_dir
}

ftl::cmd::show_size() {
        (( ftl_state_show_size_mode++, \
           ftl_state_show_size_mode = ftl_state_show_size_mode > 3 ? 0 : ftl_state_show_size_mode ))
        if (( ftl_state_show_size_mode == 3 )) ; then
                _ftl::list::print_header '' "$ftl_cfg_msg_du_size"
                ftl::list::compute_dir_sizes
                _ftl::list::print_header '' "$ftl_list_header_mode_glyphs"
        fi
        ftl::list::change_dir
}

ftl::cmd::show_stat() {
        (( ftl_state_show_stat ^= 1 ))
        ftl::util::refresh_screen
        ftl::list::render
}

ftl::cmd::sort_entries() {
        local t=$ftl_state_current_tab_index
        (( ftl_tab_sort_type[$t] = ftl_tab_sort_type[$t] + 1 >= ${#ftl_cfg_sort_options[@]} \
                ? 0 : ftl_tab_sort_type[$t] + 1 ))
        ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::sort_entries_reversed() {
        local t=$ftl_state_current_tab_index
        if [[ "${ftl_tab_sort_reversed[$t]}" == '-r' ]] ; then
                ftl_tab_sort_reversed[$t]=0
        else
                ftl_tab_sort_reversed[$t]=-r
        fi
        ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_directory_mode0() { ftl_state_dir_preview_mode=0 ; ftl::list::render ; }
ftl::cmd::set_directory_mode1() { ftl_state_dir_preview_mode=1 ; ftl::list::render ; }
ftl::cmd::set_directory_mode2() { ftl_state_dir_preview_mode=2 ; ftl::list::render ; }
ftl::cmd::set_directory_mode3() { ftl_state_dir_preview_mode=3 ; ftl::list::render ; }
ftl::cmd::set_directory_mode4() { ftl_state_dir_preview_mode=4 ; ftl::list::render ; }
ftl::cmd::set_directory_mode5() { ftl_state_dir_preview_mode=5 ; ftl::list::render ; }

ftl::cmd::view_mode_pdf() {
        (( ftl_state_pdf_preview_as_image ^= 1 ))
        ftl::list::render
}

ftl::cmd::toggle_etags() {
        (( ftl_state_etag_enabled ^= 1 ))
        ftl::list::change_dir
}

ftl::cmd::etag_show() {
        ftl::cmd::toggle_etags
}

ftl::cmd::select_etag_source() {
        local p="$FTL_CFG/etc/etags"
        ftl_etag_source_name=$(cd "$p" ; fd | fzf-tmux -p 50% --cycle --reverse --info=inline)
        if [[ -n "$ftl_etag_source_name" ]] ; then
                source "$p/$ftl_etag_source_name" "$ftl_state_session_dir"
                ftl_state_etag_enabled=1
                ftl::list::change_dir
        fi
}

ftl::cmd::etag_select() {
        ftl::cmd::select_etag_source
}

ftl::cmd::extension_hide_tab() {
        [[ -n "$ftl_state_current_extension" ]] || return 0
        local t=$ftl_state_current_tab_index
        (( ftl_filter_listing_hide_exts[${t}_${ftl_state_current_extension@Q}] = 1 ))
        ftl::list::change_dir
}

ftl::cmd::extension_hide() {
        [[ -n "$ftl_state_current_extension" ]] || return 0
        (( ftl_filter_listing_hide_exts[${ftl_state_current_extension@Q}] = 1 ))
        ftl::list::change_dir
}

ftl::cmd::extension_only_tab() {
        local i e
        local t=$ftl_state_current_tab_index
        for i in "${ftl_selection_current[@]}" ; do
                e="${i##*.}"
                [[ -n "$e" ]] && (( ftl_filter_listing_keep_exts_per_tab[$t] = 1, \
                        ftl_filter_listing_keep_exts_per_tab[${t}_${e@Q}] = 1 ))
        done
        ftl::sel::clear_all
        ftl::list::change_dir
}

ftl::cmd::extension_only() {
        local i e
        for i in "${ftl_selection_current[@]}" ; do
                e="${i##*.}"
                [[ -n "$e" ]] && (( ftl_filter_listing_keep_exts[${e@Q}] = 1 ))
        done
        ftl::sel::clear_all
        ftl::list::change_dir
}

ftl::cmd::extension_clear() {
        ftl_filter_listing_hide_exts=()
        ftl_filter_listing_keep_exts=()
        ftl_filter_listing_keep_exts_per_tab=()
        ftl::list::change_dir
}

ftl::cmd::extension_sort() {
        source "$FTL_CFG/etc/filters/sort_by_extension"
        ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_listing_depth() {
        ftl::cmd::prompt 'depth: '
        if [[ "$ftl_kbd_current_key" -eq "$ftl_kbd_current_key" ]] 2>&- ; then
                local t=$ftl_state_current_tab_index
                ftl_tab_listing_depth[$t]=$ftl_kbd_current_key
                ftl::list::change_dir '' "$ftl_state_current_basename"
        else
                ftl::list::render
        fi
}

ftl::cmd::depth() {
        ftl::cmd::set_listing_depth
}

#----------------------------------------------------------------------------
