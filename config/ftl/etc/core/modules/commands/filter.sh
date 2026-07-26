# commands/filter.sh — Filter commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

# 4. Filter commands
#----------------------------------------------------------------------------

ftl::cmd::set_filter_1() {
	ftl::cmd::prompt "filter: " -i "${ftl_tab_filter_1[$ftl_state_current_tab_index]}"
	ftl_tab_filter_1[$ftl_state_current_tab_index]="${ftl_kbd_current_key:-.}"
	ftl_filter_active_glyph="~"
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter() {
	ftl::cmd::set_filter_1
}

ftl::cmd::set_filter_2() {
	ftl::cmd::prompt "filter2: " -i "${ftl_tab_filter_2[$ftl_state_current_tab_index]}"
	ftl_tab_filter_2[$ftl_state_current_tab_index]="${ftl_kbd_current_key:-.}"
	ftl_filter_active_glyph="~"
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter2() {
	ftl::cmd::set_filter_2
}

ftl::cmd::set_dir_filter() {
	ftl::cmd::prompt "filter dir: " -i "${ftl_tab_filter_dirs[$ftl_state_current_tab_index]}"
	ftl_tab_filter_dirs[$ftl_state_current_tab_index]="${ftl_kbd_current_key:-.}"
	ftl_filter_active_glyph="~"
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter_dir() {
	ftl::cmd::set_dir_filter
}

ftl::cmd::set_reverse_filter() {
	ftl::cmd::prompt "rfilter: " -i "${ftl_tab_filter_reverse[$ftl_state_current_tab_index]}"
	ftl_tab_filter_reverse[$ftl_state_current_tab_index]="$ftl_kbd_current_key"
	ftl_filter_active_glyph="~"
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter_reverse() {
	ftl::cmd::set_reverse_filter
}

ftl::cmd::select_external_filter() {
	local filter_name
	filter_name=$(cd "$FTL_CFG/etc/filters" ; fd | fzf-tmux -p 50% --cycle)
	ftl::filt::load_external "$filter_name"
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter_ext() {
	ftl::cmd::select_external_filter
}

ftl::cmd::filter_to_tagged() {
	ftl::filt::load_external by_only_tagged
	ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter_only_tagged() {
	ftl::cmd::filter_to_tagged
}

ftl::cmd::clear_all_filters() {
	local t=$ftl_state_current_tab_index
	ftl_tab_filter_dirs[$t]='.'
	ftl_tab_filter_1[$t]='.'
	ftl_tab_filter_2[$t]='.'
	ftl_tab_filter_reverse[$t]="$ftl_cfg_default_reverse_filter"
	ftl_tab_filter_image_negate[$t]=
	ftl::filt::reset
	ftl_filter_active_glyph=
	ftl::list::change_dir
}

ftl::cmd::clear_filters() {
	ftl::cmd::clear_all_filters
}

#----------------------------------------------------------------------------
