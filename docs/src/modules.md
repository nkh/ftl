# Module Reference

ftl's core is split into 16 modules under `etc/core/modules/`. Each
module owns a `ftl::<module>::*` function namespace and a
`ftl_<module>_*` variable namespace. This page is a one-line map; for
deep dives see [Variable Index](variable-index.md) and
[Function Index](function-index.md).

## util.sh — low-level helpers

No dependencies on other modules. Path parsing, size formatting,
binary-file detection, fifo creation, stack traces.

- **Key functions**: `ftl::util::parse_path`,
  `ftl::util::resolve_full_path`, `ftl::util::format_size_human`,
  `ftl::util::is_binary_file`, `ftl::util::run_maximized`,
  `ftl::util::enter_alt_screen`, `ftl::util::stacktrace`.
- **Key variables**: `ftl_state_current_path`, `ftl_state_current_dir`,
  `ftl_state_current_basename`, `ftl_state_current_stem`,
  `ftl_state_current_extension` (set by `parse_path`).

## log.sh — logging and error reporting

Routes everything through `ftl::log::write`, which appends to
`$ftl_state_session_dir/log` and optionally shows a popup.

- **Functions**: `ftl::log::wrap`, `ftl::log::error`, `ftl::log::warn`,
  `ftl::log::info`, `ftl::log::debug`, `ftl::log::show_debug_pane`.
- **Variables**: `ftl_log_alt_screen`, `ftl_log_debug_pane_id`.

## debug.sh — debug helpers

- **Functions**: `ftl::debug::stacktrace`, `ftl::debug::log_caller`,
  `ftl::debug::format_size` (a numfmt wrapper that logs stack traces on
  failure).

## state.sh — state management and serialization

- **Functions**: `ftl::state::init`, `ftl::state::save`,
  `ftl::state::load`, `ftl::state::save_selection`,
  `ftl::state::load_selection`, `ftl::state::serialize_info`,
  `ftl::state::render_child_env`, `ftl::state::emit_selection_fd3`,
  `ftl::state::cleanup`.
- **Variables**: `ftl_state_session_dir`, `ftl_state_parent_dir`,
  `ftl_state_shared_dir`, `ftl_state_previous_pwd`,
  `ftl_state_child_env`.

## keyboard.sh — keyboard input engine

- **Functions**: `ftl::kbd::bind`, `ftl::kbd::unbind`,
  `ftl::kbd::get_key`, `ftl::kbd::normalize_key`, `ftl::kbd::dispatch`,
  `ftl::kbd::drain_input`, `ftl::kbd::show_bindings`,
  `ftl::kbd::reset_redo_exclusions`, `ftl::kbd::exclude_from_redo`.
- **Variables**: `ftl_kbd_trie`, `ftl_kbd_command_to_key`,
  `ftl_kbd_bindings_display`, `ftl_kbd_sub-mode_handler`,
  `ftl_kbd_current_key`, `ftl_kbd_count`, `ftl_kbd_has_count`,
  `ftl_kbd_last_command`, `ftl_kbd_redo_excluded`,
  `ftl_kbd_altgr_map`/`_inverse`, `ftl_kbd_shift_altgr_map`/`_inverse`.

## selection.sh — selection (tag) management

- **Functions**: `ftl::sel::resolve_current`, `ftl::sel::clear_all`,
  `ftl::sel::flip`, `ftl::sel::set`, `ftl::sel::unset`,
  `ftl::sel::unset_by_class`, `ftl::sel::validate_existence`,
  `ftl::sel::prompt_for_class`, `ftl::sel::build_class_index`,
  `ftl::sel::get_by_class`, `ftl::sel::goto_by_index`,
  `ftl::sel::fzf_tag_or_untag`, `ftl::sel::sync_from_other_pane`,
  `ftl::sel::load_from_file`, `ftl::sel::adjust_total_size`,
  `ftl::sel::format_header_summary`.
- **Variables**: `ftl_selection_tags`, `ftl_selection_current`,
  `ftl_selection_total_bytes`, `ftl_selection_revision`,
  `ftl_selection_other_revision`, `ftl_selection_class_cursor`,
  `ftl_selection_class_index`.

## tab.sh — tab management

- **Functions**: `ftl::tab::init_defaults`, `ftl::tab::create`,
  `ftl::tab::advance_index`, `ftl::tab::retreat_index`,
  `ftl::tab::load_from_file`, `ftl::tab::index_directory`.
- **Variables**: `ftl_state_current_tab_index`, `ftl_tab_directories`,
  `ftl_tab_count`, `ftl_tab_listing_mode`, `ftl_tab_view_mode`,
  `ftl_tab_listing_depth`, `ftl_tab_show_hidden`, `ftl_tab_sort_type`,
  `ftl_tab_sort_reversed`, `ftl_tab_preview_dirs_only`,
  `ftl_tab_filter_1`, `ftl_tab_filter_2`, `ftl_tab_filter_dirs`,
  `ftl_tab_filter_reverse`, `ftl_tab_filter_image_mode`,
  `ftl_tab_filter_image_negate`.

## pane.sh — tmux pane management

- **Functions**: `ftl::pane::pid_to_id`, `ftl::pane::query_geometry`,
  `ftl::pane::snapshot_geometry`, `ftl::pane::check_resize`,
  `ftl::pane::split`, `ftl::pane::split_or_respawn`,
  `ftl::pane::split_for_preview`, `ftl::pane::select`,
  `ftl::pane::set_border_colors`, `ftl::pane::window_exists`,
  `ftl::pane::count_bg_windows`, `ftl::pane::ensure_session`,
  `ftl::pane::run_in_bg_window`, `ftl::pane::run_in_user_session`,
  `ftl::pane::read_child_list`, `ftl::pane::send_to_all_children`,
  `ftl::pane::start_file_watcher`, `ftl::pane::stop_file_watcher`.
- **Variables**: `ftl_pane_self_id`, `ftl_pane_is_primary`,
  `ftl_pane_primary_id`, `ftl_pane_child_ids`, `ftl_pane_preview_id`,
  `ftl_pane_fixed_preview_id`, `ftl_pane_height`, `ftl_pane_width`,
  `ftl_pane_prev_width/height`, `ftl_pane_top/left`,
  `ftl_pane_window_width`, `ftl_pane_preview_width`,
  `ftl_pane_inotify_pid`, `ftl_pane_inotify_all_pids`,
  `ftl_pane_shell_id`, `ftl_pane_session_shell_active`,
  `ftl_pane_keep_shell_on_quit`.

## filter.sh — filter pipeline

- **Functions**: `ftl::filt::pipeline_add`, `pipeline_clear`,
  `pipeline_remove`, `reset`, `sort_entries`, `get_sort_glyph`,
  `apply_user_colors`, `load_external`, `init`.
- **Variables**: `ftl_filt_pipeline_list`, `ftl_filt_pipeline_string`,
  `ftl_filt_external_name`, `ftl_filt_active_glyph`,
  `ftl_filt_listing_hide_exts`, `ftl_filt_listing_keep_exts`,
  `ftl_filt_listing_keep_exts_per_tab`.

## list.sh — directory scanning and rendering

- **Functions**: `ftl::list::change_dir`, `refresh_dir`, `render`,
  `move_cursor`, plus many private `_ftl::list::*` helpers for scanning,
  filtering, windowing, and rendering.
- **Variables**: `ftl_list_entries`, `ftl_list_entry_count`,
  `ftl_list_resolved_sort_type`, `ftl_list_resolved_sort_reversed`,
  `ftl_state_cursor_index`, `ftl_state_cursor_memory`.
- **Truncation**: `_ftl::list::apply_filters_and_format` shortens
  overflowing entries to fit `ftl_pane_width` by keeping the extension
  visible and replacing the middle with an ellipsis. The slice length
  (`prefix_length`) is clamped to a minimum of `ftl_pane_width - (ext_l + 1)`
  so the arithmetic never goes negative — bash treats negative slice
  lengths as "from end" semantics, which would mangle the output. This
  fix was backported from upstream commit b1234f0 "FIXED: bad splitting
  of file name".

## preview.sh — preview pane management

- **Functions**: `ftl::prev::dispatch`, `clear`, `show_in_vim`,
  `show_image`, `sync_and_dispatch`.
- **Variables**: `ftl_preview_is_dir_ftl`, `ftl_preview_is_vim`,
  `ftl_preview_is_image_daemon`, `ftl_state_preview_pane_visible`,
  `ftl_state_preview_callback`, `ftl_state_fixed_preview_filename`,
  `ftl_view_media_pid`, `ftl_view_w3mimg_pid`.

## etag.sh — external tag dispatch

- **Functions**: `ftl::etag::scan_directory`, `ftl::etag::get_entry_tag`
  (both placeholders, overridden by the active etag plugin).
- **Variables**: `ftl_state_etag_enabled`, `ftl_etag_source_name`,
  `ftl_etag_callback`, `ftl_etag_entry_tag`, `ftl_etag_entry_tag_len`.

## virtual.sh — virtual entry injection

- **Functions**: `ftl::plugin::virtual::set_callbacks`, `enable`,
  `reset`, `inject_entries`, `get_virtual_dirs`, `handle_key`,
  `clear_filter`.
- **Variables**: `ftl_plugin_vfiles`, `ftl_plugin_vdirs`,
  `ftl_plugin_virtual_enabled`.

## mark.sh — bookmarks and history

- **Functions**: `_ftl::mark::save_to_history`.
- **Variables**: `ftl_mark_session_marks`.

## time.sh — time-based event handlers

- **Functions**: `ftl::time::tick`.
- **Variables**: `ftl_time_handlers`, `ftl_time_last_event_time`.

## commands.sh — user-facing command functions

The largest module. Defines every `ftl::cmd::*` function that bindings
dispatch to, organized into 15 sections (movement, selection, file ops,
filters, search, tabs, panes, preview, shell, view mode, marks/history,
**destination tags**, quit, signal handlers, command prompt). Entry
point: `ftl::cmd::dispatch_command`.

## commands/dest_tags.sh — destination tag commands (38a073a backport)

- **Functions**: `ftl::cmd::dest_tag_current`,
  `dest_tag_clear_current`, `dest_tag_clear_all`,
  `dest_tag_apply_last_to_count`, `dest_tag_copy_tagged`,
  `dest_tag_move_tagged`, plus the private `_ftl::dest::format_annotation`
  used by `ftl::list::render` to emit the ` [...dest]` block.
- **Variables**: `ftl_dest_tags` (assoc: path → dest dir),
  `ftl_dest_dir_dest` (assoc, user-configurable: shortcut → dir),
  `ftl_dest_last_dest` (last shortcut key used).
- **Config**: `ftl_cfg_dtag_move` (auto-advance after tagging),
  `ftl_cfg_dtag_l` (display column width for the annotation).
