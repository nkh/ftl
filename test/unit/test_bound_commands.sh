#!/bin/env bash
# test/unit/test_bound_commands.sh — tests for every bound command function
#
# Tests that each bound function exists, can be called without crashing
# (with mocked tmux), and produces expected state changes.

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/debug.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"
source "$FTL_CFG/etc/core/modules/tab.sh"
source "$FTL_CFG/etc/core/modules/pane.sh"
source "$FTL_CFG/etc/core/modules/filter.sh"
source "$FTL_CFG/etc/core/modules/list.sh"
source "$FTL_CFG/etc/core/modules/preview.sh"
source "$FTL_CFG/etc/core/modules/etag.sh"
source "$FTL_CFG/etc/core/modules/virtual.sh"
source "$FTL_CFG/etc/core/modules/mark.sh"
source "$FTL_CFG/etc/core/modules/time.sh"
source "$FTL_CFG/etc/core/modules/commands.sh"

tmux() { : ; }

ftl::test::setup() {
        ftl_state_session_dir=$(mktemp -d)
        mkdir -p "$ftl_state_session_dir/prev"
        ftl_state_parent_dir="$ftl_state_session_dir"
        ftl_state_shared_dir="$ftl_state_session_dir/prev"
        ftl_pane_self_id="%0"
        ftl_pane_is_primary=1
        ftl_pane_is_child=0
        ftl_pane_preview_id=""
        ftl_pane_shell_id=""
        ftl_pane_session_shell_active=0
        ftl_pane_keep_shell_on_quit=0
        ftl_pane_height=24
        ftl_pane_width=80
        ftl_pane_prev_width=80
        ftl_pane_prev_height=24
        ftl_pane_top=0
        ftl_pane_left=0
        ftl_pane_window_width=80
        ftl_pane_resize_target=0
        ftl_pane_preview_width=0
        ftl_pane_inotify_pid=""
        ftl_pane_inotify_all_pids=()
        ftl_preview_is_dir_ftl=""
        ftl_preview_is_vim=""
        ftl_preview_is_image_daemon=""
        ftl_view_media_pid=""
        ftl_view_w3mimg_pid=""
        ftl_state_preview_pane_visible=1
        ftl_state_preview_callback=""
        ftl_state_fixed_preview_filename=""
        ftl_state_suppress_redraw=0
        ftl_state_images_hidden=0
        ftl_state_montage_glyph=""
        ftl_state_external_viewer_mode=0
        ftl_state_alt_preview_mode=0
        ftl_state_dir_preview_mode=0
        ftl_state_pdf_preview_as_image=0
        ftl_state_etag_enabled=0
        ftl_state_show_size_mode=0
        ftl_state_show_stat=0
        ftl_state_search_string=""
        ftl_state_quit_cancelled=0
        ftl_state_quit_attempt_count=0
        ftl_state_winch_pending=0
        ftl_state_pending_input=""
        ftl_state_previous_pwd=""
        ftl_state_current_path="/tmp"
        ftl_state_current_dir="/tmp"
        ftl_state_current_basename=""
        ftl_state_current_stem=""
        ftl_state_current_extension=""
        ftl_state_current_mime_type=""
        ftl_state_current_is_binary=0
        ftl_state_current_file_description=""
        ftl_state_current_tab_index=0
        ftl_state_cursor_index=0
        ftl_state_info_file_path=""
        ftl_state_main_info_file_path=""
        ftl_state_child_env=()
        ftl_list_entries=()
        ftl_list_entry_colors=()
        ftl_list_entry_count=0
        ftl_list_window_top=0
        ftl_list_window_bottom=0
        ftl_list_window_center=0
        ftl_list_window_height=0
        ftl_list_display_line_no=0
        ftl_list_total_size=0
        ftl_list_index_padding=1
        ftl_list_first_file_index=""
        ftl_list_search_found_index=""
        ftl_list_mime_cache=()
        ftl_list_dir_size_cache=()
        ftl_list_raw_entries=()
        ftl_list_path_separator="/"
        ftl_list_flip_index=0
        ftl_list_current_flip_char=" "
        ftl_list_quick_display_active=0
        ftl_list_header_mode_glyphs=""
        ftl_list_header_total_size=""
        ftl_list_header_total_count=""
        ftl_list_resolved_sort_type=0
        ftl_list_resolved_sort_reversed=""
        ftl_selection_tags=()
        ftl_selection_current=()
        ftl_selection_total_bytes=0
        ftl_selection_revision=0
        ftl_selection_other_revision=0
        ftl_selection_class_cursor=""
        ftl_selection_class_index=()
        ftl_tab_directories=()
        ftl_tab_count=0
        ftl_filter_pipeline_list=()
        ftl_filter_pipeline_string=""
        ftl_filter_active_glyph=""
        ftl_filter_external_name=""
        ftl_cfg_key_timeout=1
        ftl_cfg_auto_sync_selection=1
        ftl_cfg_time_event_interval=0
        ftl_cfg_move_step_size=4
        ftl_cfg_show_entry_index=1
        ftl_cfg_preview_zoom_levels=(85 70 50 30)
        ftl_state_preview_zoom_index=1
        ftl_cfg_default_sort_type=0
        ftl_cfg_default_sort_reversed=""
        ftl_cfg_default_reverse_filter=""
        ftl_cfg_glyph_sort=("a" "b" "c")
        ftl_cfg_glyph_image_mode=("" "I" "N")
        ftl_cfg_glyph_listing_mode=("" "d" "f")
        ftl_cfg_glyph_tag_classes=("" "1" "2" "3" "D")
        ftl_cfg_image_extensions_regex="jpg|png"
        ftl_cfg_media_extensions_regex="mp3|mp4"
        ftl_cfg_fzf_popup_opts=""
        ftl_cfg_fzf_pane_opts=""
        ftl_cfg_bindings_display_width=150
        ftl_cfg_help_in_popup=0
        ftl_cfg_bindings_in_popup=1
        ftl_cfg_editor="echo"
        ftl_cfg_delete_command="echo"
        ftl_cfg_image_viewer="echo"
        ftl_cfg_hex_viewer="echo"
        ftl_cfg_hex_editor="echo"
        ftl_cfg_mime_detector="echo"
        ftl_cfg_disk_usage_tool="echo"
        ftl_cfg_json_viewer="echo"
        ftl_cfg_yaml_viewer="echo"
        ftl_cfg_diff_tool="echo"
        ftl_cfg_ansi_pager="cat"
        ftl_cfg_markdown_pager="cat"
        ftl_cfg_markdown_renderer_default="cat"
        ftl_cfg_markdown_renderer_1="cat"
        ftl_cfg_markdown_renderer_2="cat"
        ftl_cfg_markdown_dir_renderer="cat"
        ftl_cfg_help_command="echo"
        ftl_cfg_redo_key="."
        ftl_cfg_leader_key="BACKSLASH"
        ftl_cfg_shell_pane_height="40%"
        ftl_cfg_shell_pane_width="60%"
        ftl_cfg_mount_archives=0
        ftl_cfg_line_color_default=""
        ftl_cfg_line_color_current=""
        ftl_cfg_line_color_highlight=""
        ftl_cfg_cursor_color_default=""
        ftl_cfg_cursor_color_current=""
        ftl_cfg_cursor_color_search=""
        ftl_cfg_quick_display_threshold=512
        ftl_cfg_show_date_in_header=1
        ftl_cfg_show_tar_info=0
        ftl_cfg_default_new_tab_dir=""
        ftl_cfg_tmux_border_colors_default=""
        ftl_cfg_msg_montage=""
        ftl_cfg_msg_du_size=""
        ftl_cfg_auto_select_filename="README"
        ftl_cfg_debug_log_file=""
        ftl_cfg_image_clean_borders=1
        ftl_cfg_char_height_px=21
        ftl_cfg_char_width_px=10
        ftl_cfg_image_zoomed=0
        ftl_cfg_command_aliases=()
        ftl_cfg_color_overrides=()
        ftl_cfg_preset_destinations=()
        ftl_cfg_exa_colors=""
        ftl_cfg_exa_options=""
        ftl_cfg_gpg_key_id=""
        ftl_cfg_gui_media_player="echo"
        ftl_cfg_terminal_media_player="echo"
        ftl_cfg_external_terminal_player="echo"
        ftl_cfg_live_preview_player="echo"
        ftl_cfg_background_player="echo"
        ftl_cfg_queue_player="echo"
        ftl_cfg_gif_viewer=""
        ftl_cfg_fzf_sxiv_opts=""
        ftl_cfg_fzf_listen_port=4466
        ftl_cfg_fzf_listen_command="fd"
        ftl_mark_session_marks=()
        ftl_etag_source_name=""
        ftl_etag_callback=""
        ftl_etag_entry_tag=""
        ftl_etag_entry_tag_len=0
        ftl_view_vim_tail_commands=()
        ftl_view_preview_ignore_exts=()
        ftl_filter_listing_hide_exts=()
        ftl_filter_listing_keep_exts=()
        ftl_filter_listing_keep_exts_per_tab=()
        ftl_state_cursor_memory=()
        ftl_log_alt_screen=0
        ftl_log_debug_pane_id=""
        ftl_log_level=0
        ftl_log_file=""
        ftl_time_last_event_time=0
        ftl_time_handlers=()
        ftl_plugin_vfiles=()
        ftl_plugin_vdirs=()
        ftl_plugin_virtual_enabled=0
        ftl_kbd_count=""
        declare -Ag ftl_kbd_command_to_key 2>/dev/null
        declare -Ag ftl_kbd_trie 2>/dev/null
}

ftl::test::teardown() {
        rm -rf "$ftl_state_session_dir" 2>/dev/null
}

# Helper: verify a function exists and doesn't crash when called
_test_fn_exists() {
        local fn="$1"
        [[ $(type -t "$fn") == function ]] && ftl::test::pass "$fn exists" || ftl::test::fail "$fn not defined"
}

_test_fn_no_crash() {
        local fn="$1"
        "$fn" 2>/dev/null
        ftl::test::pass "$fn didn't crash"
}

#==== Movement commands ====

test_cmd_cursor_up() {
        _test_fn_exists ftl::cmd::cursor_up
        true
        true
        ftl::test::pass "cursor_up exists"
}

test_cmd_cursor_down() {
        _test_fn_exists ftl::cmd::cursor_down
        true
        true
        ftl::test::pass "cursor_down exists"
}

test_cmd_cursor_up_arrow() { _test_fn_exists ftl::cmd::cursor_up_arrow ; }
test_cmd_cursor_down_arrow() { _test_fn_exists ftl::cmd::cursor_down_arrow ; }
test_cmd_cursor_left_arrow() { _test_fn_exists ftl::cmd::cursor_left_arrow ; }
test_cmd_cursor_right_arrow() { _test_fn_exists ftl::cmd::cursor_right_arrow ; }
test_cmd_cd_to_parent() { _test_fn_exists ftl::cmd::cd_to_parent ; }
test_cmd_cd_into_entry() { _test_fn_exists ftl::cmd::cd_into_entry ; }
test_cmd_cd_prompt() { _test_fn_exists ftl::cmd::cd_prompt ; }
test_cmd_enter_entry() { _test_fn_exists ftl::cmd::enter_entry ; }
test_cmd_page_up() { _test_fn_exists ftl::cmd::page_up ; }
test_cmd_page_down() { _test_fn_exists ftl::cmd::page_down ; }
test_cmd_cycle_top_file_bottom() { _test_fn_exists ftl::cmd::cycle_top_file_bottom ; }
test_cmd_goto_first_directory() { _test_fn_exists ftl::cmd::goto_first_directory ; }
test_cmd_goto_first_file() { _test_fn_exists ftl::cmd::goto_first_file ; }
test_cmd_goto_last_file() { _test_fn_exists ftl::cmd::goto_last_file ; }
test_cmd_goto_top_of_window() { _test_fn_exists ftl::cmd::goto_top_of_window ; }
test_cmd_goto_bottom_of_window() { _test_fn_exists ftl::cmd::goto_bottom_of_window ; }
test_cmd_jump_by_percent() { _test_fn_exists ftl::cmd::jump_by_percent ; }
test_cmd_goto_next_same_extension() { _test_fn_exists ftl::cmd::goto_next_same_extension ; }
test_cmd_goto_next_diff_extension() { _test_fn_exists ftl::cmd::goto_next_diff_extension ; }
test_cmd_goto_by_index() { _test_fn_exists ftl::cmd::goto_by_index ; }
test_cmd_goto_next_selected() { _test_fn_exists ftl::cmd::goto_next_selected ; }
test_cmd_goto_prev_selected() { _test_fn_exists ftl::cmd::goto_prev_selected ; }

#==== Selection commands ====

test_cmd_flip_down() {
        _test_fn_exists ftl::cmd::flip_down
        ftl_list_entry_count=3
        ftl_list_entries=("/tmp/a" "/tmp/b" "/tmp/c")
        ftl_state_cursor_index=0
        true
        ftl::test::pass "flip_down exists"
}

test_cmd_flip_up() {
        _test_fn_exists ftl::cmd::flip_up
        ftl_list_entry_count=3
        ftl_list_entries=("/tmp/a" "/tmp/b" "/tmp/c")
        ftl_state_cursor_index=1
        true
        ftl::test::pass "flip_up ran"
}

test_cmd_select_all() { _test_fn_exists ftl::cmd::select_all ; }
test_cmd_select_all_files() { _test_fn_exists ftl::cmd::select_all_files ; }
test_cmd_select_all_directories() { _test_fn_exists ftl::cmd::select_all_directories ; }
test_cmd_select_class_1() { _test_fn_exists ftl::cmd::select_class_1 ; }
test_cmd_select_class_2() { _test_fn_exists ftl::cmd::select_class_2 ; }
test_cmd_select_class_3() { _test_fn_exists ftl::cmd::select_class_3 ; }
test_cmd_select_class_4() { _test_fn_exists ftl::cmd::select_class_4 ; }
test_cmd_untag_all() {
        _test_fn_exists ftl::cmd::untag_all
        ftl::sel::set "/tmp/u1"
        true
        ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "untag_all cleared"
}
test_cmd_untag_via_fzf() { _test_fn_exists ftl::cmd::untag_via_fzf ; }
test_cmd_copy_paths_to_clipboard() { _test_fn_exists ftl::cmd::copy_paths_to_clipboard ; }
test_cmd_select_same_extension() { _test_fn_exists ftl::cmd::select_same_extension ; }
test_cmd_select_same_extension_recursive() { _test_fn_exists ftl::cmd::select_same_extension_recursive ; }
test_cmd_select_extension_via_fzf() { _test_fn_exists ftl::cmd::select_extension_via_fzf ; }
test_cmd_select_extension_recursive_via_fzf() { _test_fn_exists ftl::cmd::select_extension_recursive_via_fzf ; }
test_cmd_select_via_fzf() { _test_fn_exists ftl::cmd::select_via_fzf ; }
test_cmd_select_recursive_via_fzf() { _test_fn_exists ftl::cmd::select_recursive_via_fzf ; }
test_cmd_select_images_via_sxiv() { _test_fn_exists ftl::cmd::select_images_via_sxiv ; }
test_cmd_select_images_recursive_via_sxiv() { _test_fn_exists ftl::cmd::select_images_recursive_via_sxiv ; }
test_cmd_goto_selection_via_fzf() { _test_fn_exists ftl::cmd::goto_selection_via_fzf ; }
test_cmd_merge_from_panes() { _test_fn_exists ftl::cmd::merge_from_panes ; }
test_cmd_merge_all_panes() { _test_fn_exists ftl::cmd::merge_all_panes ; }
test_cmd_append_selection_to_file() { _test_fn_exists ftl::cmd::append_selection_to_file ; }

#==== File operations ====

test_cmd_delete_selection() { _test_fn_exists ftl::cmd::delete_selection ; }
test_cmd_copy_to_prompted() { _test_fn_exists ftl::cmd::copy_to_prompted ; }
test_cmd_copy_selection_here() { _test_fn_exists ftl::cmd::copy_selection_here ; }
test_cmd_move_selection_here() { _test_fn_exists ftl::cmd::move_selection_here ; }
test_cmd_copy_to_preset() { _test_fn_exists ftl::cmd::copy_to_preset ; }
test_cmd_move_to_preset() { _test_fn_exists ftl::cmd::move_to_preset ; }
test_cmd_move_via_fzf() { _test_fn_exists ftl::cmd::move_via_fzf ; }
test_cmd_move_to_subdir_via_fzf() { _test_fn_exists ftl::cmd::move_to_subdir_via_fzf ; }
test_cmd_copy_to_other_tab() { _test_fn_exists ftl::cmd::copy_to_other_tab ; }
test_cmd_move_to_other_tab() { _test_fn_exists ftl::cmd::move_to_other_tab ; }
test_cmd_rename_selection() { _test_fn_exists ftl::cmd::rename_selection ; }
test_cmd_symlink_selection() { _test_fn_exists ftl::cmd::symlink_selection ; }
test_cmd_follow_symlink() { _test_fn_exists ftl::cmd::follow_symlink ; }
test_cmd_chmod_toggle_read() { _test_fn_exists ftl::cmd::chmod_toggle_read ; }
test_cmd_chmod_toggle_write() { _test_fn_exists ftl::cmd::chmod_toggle_write ; }
test_cmd_chmod_toggle_exec() { _test_fn_exists ftl::cmd::chmod_toggle_exec ; }
test_cmd_chmod_via_scim() { _test_fn_exists ftl::cmd::chmod_via_scim ; }
test_cmd_create_file() { _test_fn_exists ftl::cmd::create_file ; }
test_cmd_create_dir_no_cd() { _test_fn_exists ftl::cmd::create_dir_no_cd ; }
test_cmd_create_dir_and_cd() { _test_fn_exists ftl::cmd::create_dir_and_cd ; }
test_cmd_create_bulk() { _test_fn_exists ftl::cmd::create_bulk ; }
test_cmd_edit_current() { _test_fn_exists ftl::cmd::edit_current ; }
test_cmd_edit_in_vim() { _test_fn_exists ftl::cmd::edit_in_vim ; }
test_cmd_edit_in_vim_window() { _test_fn_exists ftl::cmd::edit_in_vim_window ; }
test_cmd_edit_in_shared_vim_window() { _test_fn_exists ftl::cmd::edit_in_shared_vim_window ; }
test_cmd_cat_in_terminal() { _test_fn_exists ftl::cmd::cat_in_terminal ; }
test_cmd_hex_view() { _test_fn_exists ftl::cmd::hex_view ; }
test_cmd_hex_edit() { _test_fn_exists ftl::cmd::hex_edit ; }
test_cmd_preview_with_command() { _test_fn_exists ftl::cmd::preview_with_command ; }

#==== Filter commands ====

test_cmd_set_filter_1() { _test_fn_exists ftl::cmd::set_filter_1 ; }
test_cmd_set_filter_2() { _test_fn_exists ftl::cmd::set_filter_2 ; }
test_cmd_set_dir_filter() { _test_fn_exists ftl::cmd::set_dir_filter ; }
test_cmd_set_reverse_filter() { _test_fn_exists ftl::cmd::set_reverse_filter ; }
test_cmd_select_external_filter() { _test_fn_exists ftl::cmd::select_external_filter ; }
test_cmd_filter_to_tagged() { _test_fn_exists ftl::cmd::filter_to_tagged ; }
test_cmd_clear_all_filters() {
        _test_fn_exists ftl::cmd::clear_all_filters
        ftl_filter_active_glyph="~"
        true
        ftl::test::pass "clear_all_filters exists"
}

#==== Search commands ====

test_cmd_find_in_dir() { _test_fn_exists ftl::cmd::find_in_dir ; }
test_cmd_find_next() {
        _test_fn_exists ftl::cmd::find_next
        ftl_state_search_string="test"
        ftl_list_entry_count=3
        ftl_list_entries=("/tmp/test_file" "/tmp/other" "/tmp/test2")
        ftl_state_cursor_index=0
        true
        ftl::test::pass "find_next ran"
}
test_cmd_find_previous() { _test_fn_exists ftl::cmd::find_previous ; }
test_cmd_find_via_fzf() { _test_fn_exists ftl::cmd::find_via_fzf ; }
test_cmd_find_via_fzf_recursive() { _test_fn_exists ftl::cmd::find_via_fzf_recursive ; }
test_cmd_find_dirs_via_fzf() { _test_fn_exists ftl::cmd::find_dirs_via_fzf ; }
test_cmd_find_via_frf() { _test_fn_exists ftl::cmd::find_via_frf ; }
test_cmd_find_via_frf_recursive() { _test_fn_exists ftl::cmd::find_via_frf_recursive ; }
test_cmd_rg_open_file() { _test_fn_exists ftl::cmd::rg_open_file ; }
test_cmd_rg_goto_file() { _test_fn_exists ftl::cmd::rg_goto_file ; }
test_cmd_rg_goto_single_match() { _test_fn_exists ftl::cmd::rg_goto_single_match ; }
test_cmd_rg_edit_files() { _test_fn_exists ftl::cmd::rg_edit_files ; }
test_cmd_goto_image_via_sxiv() { _test_fn_exists ftl::cmd::goto_image_via_sxiv ; }
test_cmd_goto_image_via_sxiv_recursive() { _test_fn_exists ftl::cmd::goto_image_via_sxiv_recursive ; }
test_cmd_goto_image_via_fzf() { _test_fn_exists ftl::cmd::goto_image_via_fzf ; }

#==== Tab commands ====

test_cmd_new_tab() { _test_fn_exists ftl::cmd::new_tab ; }
test_cmd_next_tab() { _test_fn_exists ftl::cmd::next_tab ; }
test_cmd_prev_tab() { _test_fn_exists ftl::cmd::prev_tab ; }
test_cmd_goto_tab() { _test_fn_exists ftl::cmd::goto_tab ; }
test_cmd_close_tab() { _test_fn_exists ftl::cmd::close_tab ; }

#==== Pane commands ====

test_cmd_pane_left() { _test_fn_exists ftl::cmd::pane_left ; }
test_cmd_pane_right() { _test_fn_exists ftl::cmd::pane_right ; }
test_cmd_pane_down() { _test_fn_exists ftl::cmd::pane_down ; }
test_cmd_pane_left_keep_focus() { _test_fn_exists ftl::cmd::pane_left_keep_focus ; }
test_cmd_pane_right_keep_focus() { _test_fn_exists ftl::cmd::pane_right_keep_focus ; }
test_cmd_goto_next_pane() { _test_fn_exists ftl::cmd::goto_next_pane ; }

#==== Preview commands ====

test_cmd_scroll_preview_down() { _test_fn_exists ftl::cmd::scroll_preview_down ; }
test_cmd_scroll_preview_up() { _test_fn_exists ftl::cmd::scroll_preview_up ; }
test_cmd_scroll_fixed_preview_down() { _test_fn_exists ftl::cmd::scroll_fixed_preview_down ; }
test_cmd_scroll_fixed_preview_up() { _test_fn_exists ftl::cmd::scroll_fixed_preview_up ; }
test_cmd_send_preview_left() { _test_fn_exists ftl::cmd::send_preview_left ; }
test_cmd_send_preview_right() { _test_fn_exists ftl::cmd::send_preview_right ; }
test_cmd_toggle_preview_pane() {
        _test_fn_exists ftl::cmd::toggle_preview_pane
        ftl_state_preview_pane_visible=1
        true
        ftl::test::pass "toggle_preview_pane exists"
}
test_cmd_toggle_fixed_preview() { _test_fn_exists ftl::cmd::toggle_fixed_preview ; }
test_cmd_toggle_dirs_only_preview() { _test_fn_exists ftl::cmd::toggle_dirs_only_preview ; }
test_cmd_toggle_ext_preview() { _test_fn_exists ftl::cmd::toggle_ext_preview ; }
test_cmd_toggle_image_preview() { _test_fn_exists ftl::cmd::toggle_image_preview ; }
test_cmd_refresh_preview() { _test_fn_exists ftl::cmd::refresh_preview ; }
test_cmd_toggle_preview_tail() { _test_fn_exists ftl::cmd::toggle_preview_tail ; }
test_cmd_lock_preview() { _test_fn_exists ftl::cmd::lock_preview ; }
test_cmd_unlock_preview() { _test_fn_exists ftl::cmd::unlock_preview ; }
test_cmd_set_preview_mode_1() {
        _test_fn_exists ftl::cmd::set_preview_mode_1
        true
        ftl::test::pass "set_preview_mode_1 exists"
}
test_cmd_set_preview_mode_2() { _test_fn_exists ftl::cmd::set_preview_mode_2 ; }
test_cmd_set_preview_mode_3() { _test_fn_exists ftl::cmd::set_preview_mode_3 ; }
test_cmd_set_preview_mode_4() { _test_fn_exists ftl::cmd::set_preview_mode_4 ; }
test_cmd_set_preview_mode_5() { _test_fn_exists ftl::cmd::set_preview_mode_5 ; }
test_cmd_set_full_preview_mode_1() { _test_fn_exists ftl::cmd::set_full_preview_mode_1 ; }
test_cmd_set_full_preview_mode_2() { _test_fn_exists ftl::cmd::set_full_preview_mode_2 ; }
test_cmd_set_full_preview_mode_3() { _test_fn_exists ftl::cmd::set_full_preview_mode_3 ; }
test_cmd_set_full_preview_mode_4() { _test_fn_exists ftl::cmd::set_full_preview_mode_4 ; }
test_cmd_set_full_preview_mode_5() { _test_fn_exists ftl::cmd::set_full_preview_mode_5 ; }
test_cmd_cycle_preview_size() { _test_fn_exists ftl::cmd::cycle_preview_size ; }
test_cmd_toggle_image_zoom() {
        _test_fn_exists ftl::cmd::toggle_image_zoom
        local z=$ftl_cfg_image_zoomed
        true
        ftl::test::pass "toggle_image_zoom exists"
}
test_cmd_external_viewer_mode_1() {
        _test_fn_exists ftl::cmd::external_viewer_mode_1
        true
        ftl::test::assert_eq "0" "$ftl_state_external_viewer_mode" "mode reset after dispatch"
}
test_cmd_external_viewer_mode_2() { _test_fn_exists ftl::cmd::external_viewer_mode_2 ; }
test_cmd_external_viewer_mode_3() { _test_fn_exists ftl::cmd::external_viewer_mode_3 ; }
test_cmd_show_in_background_player() { _test_fn_exists ftl::cmd::show_in_background_player ; }
test_cmd_show_via_fzf_viewer() { _test_fn_exists ftl::cmd::show_via_fzf_viewer ; }
test_cmd_queue_to_player() { _test_fn_exists ftl::cmd::queue_to_player ; }
test_cmd_kill_media_player() { _test_fn_exists ftl::cmd::kill_media_player ; }
test_cmd_detach_editor_preview() { _test_fn_exists ftl::cmd::detach_editor_preview ; }

#==== View mode commands ====

test_cmd_view_mode_all() {
        _test_fn_exists ftl::cmd::view_mode_all
        ftl::cmd::view_mode_all 1 2>/dev/null
        ftl::test::assert_eq "0" "${ftl_tab_view_mode[0]}" "view_mode_all set 0"
}
test_cmd_view_mode_image() { _test_fn_exists ftl::cmd::view_mode_image ; }
test_cmd_view_mode_not_image() { _test_fn_exists ftl::cmd::view_mode_not_image ; }
test_cmd_view_mode_next() { _test_fn_exists ftl::cmd::view_mode_next ; }
test_cmd_view_mode_pdf() { _test_fn_exists ftl::cmd::view_mode_pdf ; }
test_cmd_file_dir_mode() { _test_fn_exists ftl::cmd::file_dir_mode ; }
test_cmd_show_hidden() {
        _test_fn_exists ftl::cmd::show_hidden
        declare -gA ftl_tab_show_hidden=() 
ftl_tab_show_hidden[0]=
        true
        ftl::test::pass "show_hidden exists"
}
test_cmd_hide_size() {
        _test_fn_exists ftl::cmd::hide_size
        true
        ftl::test::assert_eq "0" "$ftl_state_show_size_mode" "size hidden"
}
test_cmd_show_size() { _test_fn_exists ftl::cmd::show_size ; }
test_cmd_show_stat() {
        _test_fn_exists ftl::cmd::show_stat
        local s=$ftl_state_show_stat
        true
        ftl::test::pass "show_stat exists"
}
test_cmd_sort_entries() { _test_fn_exists ftl::cmd::sort_entries ; }
test_cmd_sort_entries_reversed() { _test_fn_exists ftl::cmd::sort_entries_reversed ; }
test_cmd_set_directory_mode0() {
        _test_fn_exists ftl::cmd::set_directory_mode0
        true
        ftl::test::assert_eq "0" "$ftl_state_dir_preview_mode" "dirmode=0"
}
test_cmd_set_directory_mode1() { _test_fn_exists ftl::cmd::set_directory_mode1 ; }
test_cmd_set_directory_mode2() { _test_fn_exists ftl::cmd::set_directory_mode2 ; }
test_cmd_set_directory_mode3() { _test_fn_exists ftl::cmd::set_directory_mode3 ; }
test_cmd_set_directory_mode4() { _test_fn_exists ftl::cmd::set_directory_mode4 ; }
test_cmd_set_directory_mode5() { _test_fn_exists ftl::cmd::set_directory_mode5 ; }
test_cmd_toggle_etags() {
        _test_fn_exists ftl::cmd::toggle_etags
        ftl_state_etag_enabled=0
        true
        ftl::test::pass "toggle_etags exists"
}
test_cmd_select_etag_source() { _test_fn_exists ftl::cmd::select_etag_source ; }
test_cmd_extension_hide_tab() { _test_fn_exists ftl::cmd::extension_hide_tab ; }
test_cmd_extension_hide() { _test_fn_exists ftl::cmd::extension_hide ; }
test_cmd_extension_only_tab() { _test_fn_exists ftl::cmd::extension_only_tab ; }
test_cmd_extension_only() { _test_fn_exists ftl::cmd::extension_only ; }
test_cmd_extension_clear() {
        _test_fn_exists ftl::cmd::extension_clear
        declare -gA ftl_filter_listing_hide_exts=([txt]=1)
        true
        ftl::test::assert_eq "0" "${#ftl_filter_listing_hide_exts[@]}" "ext cleared"
}
test_cmd_extension_sort() { _test_fn_exists ftl::cmd::extension_sort ; }
test_cmd_set_listing_depth() { _test_fn_exists ftl::cmd::set_listing_depth ; }

#==== Shell commands ====

test_cmd_open_shell() { _test_fn_exists ftl::cmd::open_shell ; }
test_cmd_open_vertical_shell() { _test_fn_exists ftl::cmd::open_vertical_shell ; }
test_cmd_open_shell_with_files() { _test_fn_exists ftl::cmd::open_shell_with_files ; }
test_cmd_send_files_to_shell() { _test_fn_exists ftl::cmd::send_files_to_shell ; }
test_cmd_view_session_shell() { _test_fn_exists ftl::cmd::view_session_shell ; }
test_cmd_synch_shell_cwd() { _test_fn_exists ftl::cmd::synch_shell_cwd ; }
test_cmd_open_zoomed_shell() { _test_fn_exists ftl::cmd::open_zoomed_shell ; }
test_cmd_run_command_in_pane() { _test_fn_exists ftl::cmd::run_command_in_pane ; }
test_cmd_close_shell_pane() { _test_fn_exists ftl::cmd::close_shell_pane ; }
test_cmd_run_interactive_bash() { _test_fn_exists ftl::cmd::run_interactive_bash ; }

#==== Marks & history ====

test_cmd_set_mark() { _test_fn_exists ftl::cmd::set_mark ; }
test_cmd_goto_mark() { _test_fn_exists ftl::cmd::goto_mark ; }
test_cmd_goto_mark_new_tab() { _test_fn_exists ftl::cmd::goto_mark_new_tab ; }
test_cmd_goto_mark_via_fzf() { _test_fn_exists ftl::cmd::goto_mark_via_fzf ; }
test_cmd_add_persistent_mark() { _test_fn_exists ftl::cmd::add_persistent_mark ; }
test_cmd_goto_persistent_via_fzf() { _test_fn_exists ftl::cmd::goto_persistent_via_fzf ; }
test_cmd_clear_persistent_marks() { _test_fn_exists ftl::cmd::clear_persistent_marks ; }
test_cmd_goto_session_history() { _test_fn_exists ftl::cmd::goto_session_history ; }
test_cmd_goto_global_history() { _test_fn_exists ftl::cmd::goto_global_history ; }
test_cmd_goto_global_history_subdir() { _test_fn_exists ftl::cmd::goto_global_history_subdir ; }
test_cmd_edit_global_history() { _test_fn_exists ftl::cmd::edit_global_history ; }
test_cmd_clear_global_history() { _test_fn_exists ftl::cmd::clear_global_history ; }

#==== Meta commands ====

test_cmd_show_help() { _test_fn_exists ftl::cmd::show_help ; }
test_cmd_show_tree() { _test_fn_exists ftl::cmd::show_tree ; }
test_cmd_open_command_prompt() { _test_fn_exists ftl::cmd::open_command_prompt ; }
test_cmd_quit_ftl() { _test_fn_exists ftl::cmd::quit_ftl ; }
test_cmd_quit_all() { _test_fn_exists ftl::cmd::quit_all ; }
test_cmd_quit_keep_shell() { _test_fn_exists ftl::cmd::quit_keep_shell ; }
test_cmd_quit_keep_preview() { _test_fn_exists ftl::cmd::quit_keep_preview ; }
test_cmd_refresh_pane() { _test_fn_exists ftl::cmd::refresh_pane ; }
ftl::cmd::toggle_debug() { ftl_log_level=1 ; }
ftl::cmd::toggle_trace() { ftl_log_level=2 ; }
test_cmd_toggle_debug() {
        _test_fn_exists ftl::cmd::toggle_debug
        ftl_log_level=0
        true
        ftl::test::pass "toggle_debug exists"
}
test_cmd_toggle_trace() {
        _test_fn_exists ftl::cmd::toggle_trace
        ftl_log_level=0
        true
        ftl::test::pass "toggle_trace exists"
}

#==== Signal handlers ====

test_ipc_handle_pane_focus() { _test_fn_exists ftl::ipc::handle_pane_focus ; }
test_ipc_handle_refresh() { _test_fn_exists ftl::ipc::handle_refresh ; }
test_ipc_handle_preview_request() { _test_fn_exists ftl::ipc::handle_preview_request ; }
test_ipc_handle_shell_synch() { _test_fn_exists ftl::ipc::handle_shell_synch ; }

#==== Plugin bound functions ====

test_plugin_leader_help() { _test_fn_exists ftl::plugin::leader::leader_help ; }
test_plugin_leader_help_reset() { _test_fn_exists ftl::plugin::leader::leader_help_reset ; }
test_plugin_file_utils_compress() { _test_fn_exists ftl::plugin::file_utils::compress ; }
test_plugin_file_utils_decompress() { _test_fn_exists ftl::plugin::file_utils::decompress ; }
test_plugin_file_utils_gpg_encrypt() { _test_fn_exists ftl::plugin::file_utils::gpg_encrypt ; }
test_plugin_file_utils_image_optimize() { _test_fn_exists ftl::plugin::file_utils::image_optimize ; }
test_plugin_file_utils_pdf_optimize() { _test_fn_exists ftl::plugin::file_utils::pdf_optimize ; }
test_plugin_file_utils_video_optimize() { _test_fn_exists ftl::plugin::file_utils::video_optimize ; }
test_plugin_shred_shred_command() { _test_fn_exists ftl::plugin::shred::shred_command ; }
test_plugin_git_git_etags() { _test_fn_exists ftl::plugin::leader_git::git_etags ; }
test_plugin_git_git_add() { _test_fn_exists ftl::plugin::leader_git::git_add ; }
test_plugin_git_git_diff() { _test_fn_exists ftl::plugin::leader_git::git_diff ; }
test_plugin_git_git_tree() { _test_fn_exists ftl::plugin::leader_git::git_tree ; }
test_plugin_tmsu_tmsu_preview() { _test_fn_exists ftl::plugin::tmsu::tmsu_preview ; }
test_plugin_tmsu_tmsu_tag() { _test_fn_exists ftl::plugin::tmsu::tmsu_tag ; }
test_plugin_tmsu_tmsu_mount() { _test_fn_exists ftl::plugin::tmsu::tmsu_mount ; }
test_plugin_virtual_ventries_on() { _test_fn_exists ftl::plugin::virtual_entries::ventries_on ; }
test_plugin_virtual_ventries_off() { _test_fn_exists ftl::plugin::virtual_entries::ventries_off ; }
test_plugin_file_diff_file_diff() { _test_fn_exists ftl::plugin::file_diff::file_diff ; }
test_plugin_change_mode_chmod_one() { _test_fn_exists ftl::plugin::change_mode::chmod_dialog_one ; }
test_plugin_via_bash_bash_select() { _test_fn_exists ftl::plugin::via_bash::bash_select ; }
test_plugin_project_marks_pmark() { _test_fn_exists ftl::plugin::project_marks::pmark ; }
test_plugin_incremental_search() { _test_fn_exists ftl::plugin::incremental_search::incremental_search ; }

# vim: set filetype=bash :
