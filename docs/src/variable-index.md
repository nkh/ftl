# Variable Index

A consolidated index of ftl's namespaced globals, grouped by prefix.
Each row lists the variable, the owning module, and its purpose. See
also [Function Index](function-index.md).

## ftl_cfg_* — configuration

| Variable | Module | Purpose |
|----------|--------|---------|
| `ftl_cfg_leader_key` | keyboard | the leader key (default `BACKSLASH`) |
| `ftl_cfg_redo_key` | keyboard | the redo key (default `.`) |
| `ftl_cfg_key_timeout` | main loop | seconds for key read timeout |
| `ftl_cfg_help_command` | commands | command run for `?` |
| `ftl_cfg_help_in_popup` | commands | show help in a popup |
| `ftl_cfg_bindings_in_popup` | keyboard | show bindings in a popup |
| `ftl_cfg_bindings_display_width` | keyboard | width of the bindings table |
| `ftl_cfg_command_aliases` | commands | aliases for the `:` prompt |
| `ftl_cfg_move_step_size` | commands | entries per step |
| `ftl_cfg_auto_select_filename` | list | file to auto-select on cd |
| `ftl_cfg_shell_pane_height` / `_width` | pane | shell pane dimensions |
| `ftl_cfg_auto_sync_selection` | selection | sync selection between panes |
| `ftl_cfg_time_event_interval` | time | seconds between time events |
| `ftl_cfg_debug_log_file` | log | optional debug log file |
| `ftl_cfg_preview_zoom_levels` | preview | preview pane sizes (%) |
| `ftl_cfg_default_reverse_filter` | filter | per-tab default reverse filter |
| `ftl_cfg_default_sort_type` / `_reversed` | filter | default sort |
| `ftl_cfg_sort_options` | filter | sort flags per sort type |
| `ftl_cfg_mount_archives` | commands | mount archives via fuse |
| `ftl_cfg_quick_display_threshold` | list | flash count threshold |
| `ftl_cfg_show_entry_index` | list | show entry-index column |
| `ftl_cfg_show_date_in_header` | list | show date in header |
| `ftl_cfg_show_tar_info` | list | show tar info |
| `ftl_cfg_line_color_default`/`_current`/`_highlight` | list | index column colors |
| `ftl_cfg_cursor_color_default`/`_current`/`_search` | list | cursor glyph colors |
| `ftl_cfg_color_overrides` | filter | LS_COLORS overrides per filename |
| `ftl_cfg_glyph_sort` / `_image_mode` / `_listing_mode` / `_tag_classes` | filter/list | glyph tables |
| `ftl_cfg_image_extensions_regex` / `_media_extensions_regex` | preview | media regexes |
| `ftl_cfg_fzf_popup_opts` / `_pane_opts` / `_sxiv_opts` | commands | fzf option strings |
| `ftl_cfg_fzf_listen_port` / `_listen_command` | commands | HTTP-polled fzf |
| `ftl_cfg_editor` | commands | editor (default `vim -p`) |
| `ftl_cfg_diff_tool` | commands | diff tool |
| `ftl_cfg_image_viewer` / `_gif_viewer` | preview | image viewers |
| `ftl_cfg_image_clean_borders` / `_char_width_px` / `_char_height_px` / `_image_zoomed` | preview | image preview hints |
| `ftl_cfg_gui_media_player` / `_terminal_media_player` / `_external_terminal_player` / `_live_preview_player` / `_background_player` / `_queue_player` | preview | media players |
| `ftl_cfg_ansi_pager` / `_markdown_pager` | preview | pagers |
| `ftl_cfg_markdown_renderer_default` / `_1` / `_2` / `_dir_renderer` | preview | MD renderers |
| `ftl_cfg_hex_viewer` / `_hex_editor` | commands | hex tools |
| `ftl_cfg_json_viewer` / `_yaml_viewer` | preview | structured-data viewers |
| `ftl_cfg_disk_usage_tool` | commands | disk-usage tool |
| `ftl_cfg_mime_detector` | util | MIME detector |
| `ftl_cfg_exa_colors` / `_exa_options` | preview | exa directory preview |
| `ftl_cfg_delete_command` | commands | delete command |
| `ftl_cfg_gpg_key_id` | commands | GPG key id |
| `ftl_cfg_preset_destinations` | commands | preset copy/move destinations |
| `ftl_cfg_default_new_tab_dir` | tab | default new-tab dir |
| `ftl_cfg_tmux_border_colors_default` | pane | border colors restored on quit |
| `ftl_cfg_msg_montage` / `_du_size` | commands | status messages |

## ftl_state_* — runtime state

| Variable | Module | Purpose |
|----------|--------|---------|
| `ftl_state_session_dir` | state | this pane's private dir |
| `ftl_state_parent_dir` | state | parent pane's session dir |
| `ftl_state_shared_dir` | state | rendezvous dir (= `$ftl_state_parent_dir/prev`) |
| `ftl_state_other_session_dir` | state | the pane being synced from |
| `ftl_state_previous_pwd` | state | previous PWD |
| `ftl_state_child_env` | state | assoc of env vars for children |
| `ftl_state_info_file_path` | state | path to the info file |
| `ftl_state_current_path` | util | full path under cursor |
| `ftl_state_current_dir` / `_basename` / `_stem` / `_extension` | util | path components |
| `ftl_state_current_tab_index` | tab | current tab index |
| `ftl_state_cursor_index` | list | cursor position in `ftl_list_entries` |
| `ftl_state_cursor_memory` | list | per-dir cursor memory |
| `ftl_state_current_path` (alt use) | list | entry under cursor |
| `ftl_state_preview_pane_visible` | preview | preview pane on/off |
| `ftl_state_preview_callback` | preview | virtual-entry callback |
| `ftl_state_preview_zoom_index` | preview | index into `ftl_cfg_preview_zoom_levels` |
| `ftl_state_fixed_preview_filename` | preview | file for the fixed preview |
| `ftl_state_alt_preview_mode` | preview | alt preview mode (0–5) |
| `ftl_state_external_viewer_mode` | preview | external viewer mode |
| `ftl_state_dir_preview_mode` | preview | directory preview mode |
| `ftl_state_etag_enabled` | etag | etag master toggle |
| `ftl_state_show_size_mode` | list | size column on/off |
| `ftl_state_winch_pending` | pane | resize detected |
| `ftl_state_pending_input` | keyboard | queued key input |
| `ftl_state_main_info_file_path` | state | main info file path |
| `ftl_state_current_mime_type` | util | detected MIME type |
| `ftl_state_current_file_description` | util | `file -b` output |
| `ftl_state_current_is_binary` | util | is the file binary |
| `ftl_state_quit_cancelled` | state | was quit cancelled |
| `ftl_state_global_history_file` | mark | global history path |

## ftl_kbd_* — keyboard

| Variable | Purpose |
|----------|---------|
| `ftl_kbd_trie` | key sequence → command function |
| `ftl_kbd_command_to_key` | command → key sequence (reverse map) |
| `ftl_kbd_bindings_display` | display metadata for the `c` table |
| `ftl_kbd_submode_handler` | active sub-mode dispatch function |
| `ftl_kbd_current_key` / `_raw_key` | current / raw key |
| `ftl_kbd_accumulated_keys` | accumulated key sequence |
| `ftl_kbd_keys_count` | count of accumulated keys |
| `ftl_kbd_count` / `_has_count` | count prefix |
| `ftl_kbd_last_command` | last non-excluded command (for redo) |
| `ftl_kbd_redo_excluded` | commands excluded from redo |
| `ftl_kbd_warn_on_override` | warn on binding override |
| `ftl_kbd_altgr_map` / `_inverse` | AltGr key map |
| `ftl_kbd_shift_altgr_map` / `_inverse` | Shift+AltGr key map |

## ftl_list_* — listing

| Variable | Purpose |
|----------|---------|
| `ftl_list_entries` | indexed array of entry paths |
| `ftl_list_entry_count` | number of entries |
| `ftl_list_resolved_sort_type` / `_sort_reversed` | resolved sort config |

## ftl_pane_* — panes

| Variable | Purpose |
|----------|---------|
| `ftl_pane_self_id` | this pane's tmux id |
| `ftl_pane_is_primary` / `_is_child` | primary/child flags |
| `ftl_pane_primary_id` | primary pane's tmux id |
| `ftl_pane_child_ids` | child pane ids |
| `ftl_pane_preview_id` / `_fixed_preview_id` | preview pane ids |
| `ftl_pane_height` / `_width` / `_prev_height` / `_prev_width` | geometry |
| `ftl_pane_top` / `_left` / `_window_width` / `_preview_width` | geometry |
| `ftl_pane_inotify_pid` / `_inotify_all_pids` | inotify watcher PIDs |
| `ftl_pane_shell_id` | shell pane id |
| `ftl_pane_session_shell_active` | session shell exists |
| `ftl_pane_keep_shell_on_quit` | keep shell on quit |
| `ftl_pane_resize_target` | computed resize target |

## ftl_sel* — selection

| Variable | Purpose |
|----------|---------|
| `ftl_selection_tags` | assoc: path → class glyph |
| `ftl_selection_current` | indexed array: resolved selection |
| `ftl_selection_total_bytes` | total size of selected files |
| `ftl_selection_revision` | monotonic counter (stagsi) |
| `ftl_selection_other_revision` | other pane's counter |
| `ftl_selection_class_cursor` | position for next/prev tag nav |
| `ftl_selection_class_index` | inverted index: class → 1 |

## ftl_tab_* — tabs

| Variable | Purpose |
|----------|---------|
| `ftl_tab_directories` | indexed array of tab dirs |
| `ftl_tab_count` | number of open tabs |
| `ftl_tab_listing_mode` | per-tab: 0=all, 1=dirs, 2=files |
| `ftl_tab_view_mode` | per-tab: 0=all, 1=no-image, 2=image |
| `ftl_tab_listing_depth` | per-tab: max find depth |
| `ftl_tab_show_hidden` | per-tab: show dot-files |
| `ftl_tab_sort_type` / `_sort_reversed` | per-tab sort |
| `ftl_tab_preview_dirs_only` | per-tab: preview dirs only |
| `ftl_tab_filter_1` / `_filter_2` | per-tab file filters |
| `ftl_tab_filter_dirs` | per-tab dir filter |
| `ftl_tab_filter_reverse` | per-tab reverse filter |
| `ftl_tab_filter_image_mode` | per-tab image-mode filter |
| `ftl_tab_filter_image_negate` | per-tab negate flag |

## ftl_filt_* — filter pipeline

| Variable | Purpose |
|----------|---------|
| `ftl_filt_pipeline_list` | indexed array of filter fn names |
| `ftl_filt_pipeline_string` | eval-able pipe string |
| `ftl_filt_external_name` | name of the loaded external filter |
| `ftl_filt_active_glyph` | glyph shown when filter active |
| `ftl_filt_listing_hide_exts` | assoc: extension → 1 (hide) |
| `ftl_filt_listing_keep_exts` | assoc: extension → 1 (keep only) |
| `ftl_filt_listing_keep_exts_per_tab` | per-tab keep list |

## Other namespaces

| Variable | Purpose |
|----------|---------|
| `ftl_etag_source_name` / `_callback` / `_entry_tag` / `_entry_tag_len` | etag dispatch |
| `ftl_mark_session_marks` | assoc: char → path |
| `ftl_time_handlers` / `_last_event_time` | time events |
| `ftl_plugin_vfiles` / `_vdirs` / `_virtual_enabled` | virtual entries |
| `ftl_preview_is_dir_ftl` / `_is_vim` / `_is_image_daemon` | preview state flags |
| `ftl_view_media_pid` / `_w3mimg_pid` | background preview PIDs |
| `ftl_log_alt_screen` / `_debug_pane_id` | logging state |
| `ftl_dest_tags` | assoc: full_path → destination_directory (38a073a) |
| `ftl_dest_dir_dest` | assoc (user config): shortcut_key → directory |
| `ftl_dest_last_dest` | last shortcut key used (for `TT` re-apply) |
| `ftl_cfg_dtag_move` | if non-zero, auto-advance cursor after tagging |
| `ftl_cfg_dtag_l` | display column width for ` [...dest]` annotation |
