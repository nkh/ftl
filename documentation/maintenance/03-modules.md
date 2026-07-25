# 03 — Module Reference

> **Audience:** A maintainer who has read [01-onboarding.md](./01-onboarding.md)
> and [02-architecture.md](./02-architecture.md).
> **Goal:** Understand each module's responsibility, public API,
> private helpers, and interactions with other modules.
> **Time:** 90 minutes.

This document covers the 17 core modules in dependency order. For each
module, it lists: purpose, public API (with signatures), private
helpers, globals, and interactions.

For alphabetical function lookup with full signatures, see
[04-api-reference.md](./04-api-reference.md).

---

## 1. `util.sh` (161 lines)

**Purpose:** Path manipulation, screen refresh, FIFO creation,
stack traces.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::util::parse_path` | `<path>` | Decompose a path into `ftl_state_current_{path,dir,basename,stem,extension}` |
| `ftl::util::clear_path_vars` | — | Reset all path globals to empty |
| `ftl::util::resolve_full_path` | `<path>` → stdout | Resolve `./` prefix and trailing `/` |
| `ftl::util::format_size_human` | `<bytes>` → stdout | Format as `1.2K`, `3.4M`, etc. |
| `ftl::util::is_binary_file` | `<path>` | Set `ftl_state_current_is_binary` (0=text, 1=binary) via perl `-B` |
| `ftl::util::run_maximized` | `<cmd...>` | Minimize ftl window, run command, restore |
| `ftl::util::refresh_screen` | `[<esc>]` | Emit `\e[?25l` (hide cursor) + optional escape |
| `ftl::util::dedup_file` | `<file>` | Remove duplicate lines (requires `sponge`) |
| `ftl::util::create_fifos` | `<fd>...` | Create named pipes for the given file descriptors |
| `ftl::util::stacktrace` | — | Print a stack trace to stderr |
| `ftl::util::enter_alt_screen` | — | Enter tmux alternate screen |

**Globals set:** `ftl_state_current_path`, `ftl_state_current_dir`,
`ftl_state_current_basename`, `ftl_state_current_stem`,
`ftl_state_current_extension`, `ftl_state_current_is_binary`.

**Interactions:** Used by virtually every module. `parse_path` is
called by `ftl::list::render` on every cursor move.

---

## 2. `log.sh` (193 lines)

**Purpose:** Logging at 5 levels (error, warn, info, debug, trace).
Logs go to `$ftl_state_session_dir/log` and optionally to a popup.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::log::init` | — | Open the log file, set level from `ftl_cfg_log_level` |
| `ftl::log::set_level` | `<level>` | Set the log level (0–4) |
| `ftl::log::wrap` | `<fn> <args...>` | Call a function, log its output |
| `ftl::log::show_error_full` | `<msg>` | Show error in a popup with stack trace |
| `ftl::log::show_error_popup` | `<msg>` | Show error in a tmux popup |
| `ftl::log::warn` | `<msg>` | Log at warn level (1) |
| `ftl::log::error` | `<msg>` | Log at error level (0) + show popup |
| `ftl::log::info` | `<msg>` | Log at info level (2) |
| `ftl::log::debug` | `<msg>` | Log at debug level (3) |
| `ftl::log::trace` | `<msg>` | Log at trace level (4) |
| `ftl::log::show_debug_pane` | — | Open a pane tailing the log file |
| `ftl::log::log_caller` | — | Print the calling function's name |

**Globals:** `ftl_log_level`, `ftl_log_file`, `ftl_cfg_debug_log_file`.

**Interactions:** Used by every module for diagnostics. The level is
controlled by `FTL_DEBUG=1` (sets level 3) and `FTL_TRACE=1` (sets
level 4) environment variables.

---

## 3. `debug.sh` (46 lines)

**Purpose:** Debug mode toggle.

**Public API:**

| Function | Description |
|----------|-------------|
| `ftl::cmd::toggle_debug` | Toggle debug logging on/off |
| `ftl::cmd::toggle_trace` | Toggle trace logging on/off |

**Interactions:** Bound to `LEADER d d` and `LEADER d t`.

---

## 4. `state.sh` (155 lines)

**Purpose:** Per-session state management and serialization. Creates
the session directory, serializes state for sibling panes and external
commands.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::state::init` | — | Create `$ftl_state_session_dir` and subdirs |
| `ftl::state::save` | `[<target_dir>]` | Serialize listing state to `<dir>/ftl` |
| `ftl::state::load` | `[<file>]` | Source a state file |
| `ftl::state::save_selection` | `[<file>]` | Serialize `ftl_selection_tags` |
| `ftl::state::load_selection` | `<file>` | Source a selection file |
| `ftl::state::serialize_info` | `[<file>]` | Write info file for external commands |
| `ftl::state::render_child_env` | `[<prefix>]` | Render `-e key=val` args for tmux |
| `ftl::state::emit_selection_fd3` | — | Write selection to fd 3 (for `ftll`/`cdf`) |
| `ftl::state::cleanup` | — | Remove the session directory |

**Globals:** `ftl_state_session_dir`, `ftl_state_parent_dir`,
`ftl_state_other_session_dir`, `ftl_state_shared_dir`,
`ftl_state_previous_pwd`, `ftl_state_child_env`,
`ftl_state_info_file_path`, `ftl_state_main_info_file_path`.

**Interactions:**

- `ftl::list::render` calls `ftl::state::save` on every render.
- `ftl::kbd::dispatch` calls `ftl::state::serialize_info` before
  invoking any command (so external commands have fresh state).
- Sibling panes read `$ftl_state_shared_dir/ftl` and
  `$ftl_state_shared_dir/stagsi` to sync.
- External commands (`finfo`, `fsh`) source the info file to access
  ftl's state.

---

## 5. `keyboard.sh` (407 lines)

**Purpose:** Keyboard input engine. Key reading, normalization,
trie-based dispatch, binding management.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::kbd::bind` | `<map> <section> <keys> <cmd> <help>` | Register a key binding |
| `ftl::kbd::unbind` | `<keys>` | Remove a key binding |
| `ftl::kbd::reset_redo_exclusions` | — | Clear the redo-exclusion set |
| `ftl::kbd::exclude_from_redo` | `<cmd>` | Exclude a command from redo |
| `ftl::kbd::get_key` | `[<timeout>]` | Read and normalize one key |
| `ftl::kbd::normalize_key` | `<raw>` → stdout | Normalize a raw escape sequence |
| `ftl::kbd::dispatch` | — | Dispatch the current key to a command |
| `ftl::kbd::drain_input` | — | Drain pending stdin |
| `ftl::kbd::show_bindings` | — | Show the bindings table (`c` command) |
| `ftl::kbd::init_exclusions` | — | Initialize default redo exclusions |

**Private helpers:** `_ftl::kbd::show_bindings_popup`,
`_ftl::kbd::show_bindings_fullscreen`, `_ftl::kbd::generate_bindings_table`.

**Globals:** `ftl_kbd_altgr_map`, `ftl_kbd_altgr_inverse`,
`ftl_kbd_shift_altgr_map`, `ftl_kbd_shift_altgr_inverse`,
`ftl_kbd_command_to_key`, `ftl_kbd_bindings_display`, `ftl_kbd_trie`,
`ftl_kbd_redo_excluded`, `ftl_kbd_submode_handler`,
`ftl_kbd_current_key`, `ftl_kbd_raw_key`, `ftl_kbd_accumulated_keys`,
`ftl_kbd_keys_count`, `ftl_kbd_has_count`, `ftl_kbd_count`,
`ftl_kbd_last_command`, `ftl_kbd_warn_on_override`.

**Interactions:**

- The main loop calls `get_key` and `dispatch` on every iteration.
- `ftlrc` and binding plugins call `bind` to register bindings.
- Sub-mode handlers (incremental search, fzf search, inline rename)
  set `ftl_kbd_submode_handler` to redirect dispatch.

---

## 6. `selection.sh` (239 lines)

**Purpose:** Selection (tag) management. Maintains
`ftl_selection_tags` (assoc array: path → glyph) and
`ftl_selection_current` (indexed array of resolved paths).

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::sel::resolve_current` | — | Build `ftl_selection_current` from tags (or current entry) |
| `ftl::sel::clear_all` | — | Clear the entire selection |
| `ftl::sel::flip` | `<path> [<glyph>]` | Toggle a tag |
| `ftl::sel::set` | `<path> [<glyph>]` | Set a tag |
| `ftl::sel::unset` | `<path>` | Unset a tag |
| `ftl::sel::unset_by_class` | `<glyph>` | Unset all tags with a given glyph |
| `ftl::sel::validate_existence` | — | Remove tags for non-existent files |
| `ftl::sel::prompt_for_class` | — → stdout | Ask user which class to operate on |
| `ftl::sel::build_class_index` | — | Build inverted index of classes |
| `ftl::sel::get_by_class` | `<nameref> <nameref>` | Get tags matching a class |
| `ftl::sel::goto_by_index` | `<index>` | Navigate to the Nth tagged file |
| `ftl::sel::fzf_tag_or_untag` | `<mode> <paths>` | Tag/untag from fzf output |
| `ftl::sel::sync_from_other_pane` | — | Sync selection from sibling pane |
| `ftl::sel::load_from_file` | `<arg1> <file>` | Load selection from a file of paths |
| `ftl::sel::adjust_total_size` | `<+|-> <path>` | Adjust `ftl_selection_total_bytes` |
| `ftl::sel::format_header_summary` | — → stdout | Format "count/size" for the header |

**Globals:** `ftl_selection_tags`, `ftl_selection_current`,
`ftl_selection_total_bytes`, `ftl_selection_revision`,
`ftl_selection_other_revision`, `ftl_selection_class_cursor`,
`ftl_selection_class_index`.

**Interactions:**

- `ftl::list::render` calls `resolve_current` to build
  `ftl_selection_current` for commands that operate on the selection.
- The main loop calls `sync_from_other_pane` on every iteration.
- Commands (`ftl::cmd::delete_selection`, `ftl::cmd::copy_selection_here`,
  etc.) read `ftl_selection_current`.
- `ftl::state::save` serializes `ftl_selection_tags`.

---

## 7. `tab.sh` (138 lines)

**Purpose:** Tab management. Each tab has its own directory, sort,
filters, and view mode.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::tab::init_defaults` | — | Initialize default tab state |
| `ftl::tab::create` | — | Create a new tab |
| `ftl::tab::advance_index` | — | Switch to the next tab |
| `ftl::tab::retreat_index` | — | Switch to the previous tab |
| `ftl::tab::load_from_file` | `<args>` | Load tabs from a file (CLI `-t`) |
| `ftl::tab::index_directory` | — | Scan for the dir-view (tab indexing) |

**Globals:** `ftl_tab_directories`, `ftl_tab_count`,
`ftl_tab_sort_type`, `ftl_tab_sort_reversed`, `ftl_tab_filter_1`,
`ftl_tab_filter_2`, `ftl_tab_filter_dirs`, `ftl_tab_filter_reverse`,
`ftl_tab_view_mode`, `ftl_tab_listing_mode`, `ftl_tab_show_hidden`,
`ftl_tab_preview_dirs_only`, `ftl_tab_filter_image_negate`.

**Interactions:**

- `ftl::list::change_dir` updates `ftl_tab_directories[$tab]`.
- `ftl::list::render` reads per-tab sort and filter state.
- `ftl::tab::load_from_file` is called by `bin/ftl` for the `-t` CLI
  option.

---

## 8. `pane.sh` (296 lines)

**Purpose:** tmux interaction. Pane creation, geometry queries,
splitting, file watching.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::pane::pid_to_id` | `<pid>` → stdout | Convert a PID to a tmux pane id |
| `ftl::pane::query_geometry` | — | Query current pane height/width |
| `ftl::pane::snapshot_geometry` | — | Save geometry for winch detection |
| `ftl::pane::check_resize` | — | Re-render if pane was resized |
| `ftl::pane::split` | `<cmd> [<size>]` | Split the pane and run a command |
| `ftl::pane::split_or_respawn` | `<cmd>` | Respawn existing pane or split |
| `ftl::pane::split_for_preview` | `<cmd>` | Split for preview (fzf-aware) |
| `ftl::pane::select` | `<direction>` | Select a pane |
| `ftl::pane::set_border_colors` | — | Set tmux border colors |
| `ftl::pane::window_exists` | `<name>` | Check if a tmux window exists |
| `ftl::pane::count_bg_windows` | — → stdout | Count background tmux windows |
| `ftl::pane::ensure_session` | — | Ensure a tmux session exists |
| `ftl::pane::run_in_bg_window` | `<cmd>` | Run a command in a bg tmux window |
| `ftl::pane::run_in_user_session` | `<cmd>` | Run in a user-named session |
| `ftl::pane::read_child_list` | — | Read the child-pane list |
| `ftl::pane::send_to_all_children` | `<key>` | Send a key to all child panes |
| `ftl::pane::start_file_watcher` | — | Start inotify watcher |
| `ftl::pane::stop_file_watcher` | — | Stop inotify watcher |

**Private helpers:** `_ftl::pane::split_with_fixed_preview`.

**Globals:** `ftl_pane_self_id`, `ftl_pane_is_primary`,
`ftl_pane_is_child`, `ftl_pane_height`, `ftl_pane_width`,
`ftl_pane_session_shell_active`, `ftl_pane_preview_id`.

**Interactions:**

- `ftl::list::change_dir` calls `stop_file_watcher` before scanning
  and `start_file_watcher` after.
- `ftl::list::render` calls `snapshot_geometry` and `check_resize`.
- Viewer functions call `split_for_preview` to spawn backend programs.
- The file watcher sends a `å` signal to the pane on directory
  changes, triggering a refresh.

---

## 9. `filter.sh` (167 lines)

**Purpose:** The filter pipeline. Assembles the pipeline string,
applies the external filter, sorts entries.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::filt::pipeline_add` | `<filter>` | Add a filter to the pipeline |
| `ftl::filt::pipeline_clear` | — | Clear the pipeline |
| `ftl::filt::pipeline_remove` | `<filter>` | Remove a filter from the pipeline |
| `ftl::filt::reset` | — | Reset the filter pipeline to defaults |
| `ftl::filt::sort_entries` | — | Sort entries (stdin → stdout) |
| `ftl::filt::sort_by` | `<type>` | Set the sort type |
| `ftl::filt::get_sort_glyph` | `<type>` → stdout | Get the glyph for a sort type |
| `ftl::filt::apply_user_colors` | — | Apply user-defined color overrides |
| `ftl::filt::load_external` | `<name>` | Load an external filter plugin |
| `ftl::filt::init` | — | Initialize the filter pipeline string |
| `ftl::filter::apply_external` | — | The external filter slot (stdin → stdout) |

**Globals:** `ftl_filter_pipeline_list`, `ftl_filter_pipeline_string`,
`ftl_filter_active_glyph`, `ftl_filter_external_name`,
`ftl_filter_listing_hide_exts`, `ftl_filter_listing_keep_exts`.

**Interactions:**

- `ftl::list::scan_and_render` calls `ftl::filt::init` and then runs
  the pipeline.
- `ftl::filt::load_external` is called by the `fe` binding to swap
  the external filter.
- Filter plugins override `ftl::filter::apply_external`.

---

## 10. `list.sh` (709 lines)

**Purpose:** Directory scanning and rendering. The largest module.
Runs the streaming pipeline, computes the visible window, renders the
listing and header.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::list::change_dir` | `[<dir> [<file> [<index>]]]` | Change directory and re-list |
| `ftl::list::refresh_dir` | `[<index> [<quick>]]` | Refresh listing without full rescan |
| `ftl::list::render` | `[<index>]` | Render the current listing |
| `ftl::list::move_cursor` | `<delta>` | Move the cursor by N entries |
| `ftl::list::compute_dir_sizes` | — | Compute all dir sizes (du mode) |
| `ftl::list::compute_preview_width` | — | Compute the preview pane width |
| `ftl::list::get_mime_type` | — | Get MIME type for the current entry |
| `ftl::list::quote_all_entries` | — → stdout | Quote all entries for shell |
| `ftl::list::quote_all_dirs` | — → stdout | Quote all directory entries |
| `ftl::list::quote_all_files` | — → stdout | Quote all file entries |
| `ftl::list::quote_selection` | — → stdout | Quote the selection for shell |

**Private helpers:** `_ftl::list::scan_and_render`,
`_ftl::list::scan_directory`, `_ftl::list::scan_custom_source`,
`_ftl::list::apply_filters_and_format`, `_ftl::list::render_window`,
`_ftl::list::render_header`, `_ftl::list::print_header`,
`_ftl::list::compute_header_truncation`, `_ftl::list::clear_below`,
`_ftl::list::scan_for_dir_view`, `_ftl::list::scan_full`,
`_ftl::list::find_entries`, `_ftl::list::inject_virtual_files`,
`_ftl::list::inject_virtual_dirs`, `_ftl::list::emit_size_to_fifo`,
`_ftl::list::emit_name_to_fifos`, `_ftl::list::signal_scan_complete`,
`_ftl::list::format_dir_size`, `_ftl::list::format_dir_entry_count`,
`_ftl::list::adjust_for_preview`.

**Globals:** `ftl_list_entries`, `ftl_list_entry_colors`,
`ftl_list_entry_count`, `ftl_list_raw_entries`, `ftl_list_raw_paths`,
`ftl_list_raw_names`, `ftl_list_raw_colors`, `ftl_list_raw_sizes`,
`ftl_list_raw_relpath_len`, `ftl_list_window_top`,
`ftl_list_window_bottom`, `ftl_list_window_center`,
`ftl_list_window_height`, `ftl_list_display_line_no`,
`ftl_list_total_size`, `ftl_list_index_padding`,
`ftl_list_first_file_index`, `ftl_list_search_found_index`,
`ftl_list_mime_cache`, `ftl_list_dir_size_cache`,
`ftl_list_path_separator`, `ftl_list_quick_display_active`,
`ftl_list_resolved_sort_type`, `ftl_list_resolved_sort_reversed`,
`ftl_list_flip_index`, `ftl_list_current_flip_char`,
`ftl_list_header_total_count`, `ftl_list_header_total_size`.

**Interactions:** Uses `pane` (file watcher, geometry), `filter`
(pipeline), `state` (save), `selection` (resolve_current),
`tab` (per-tab state), `virtual` (inject entries), `util` (parse_path).

---

## 11. `preview.sh` (174 lines)

**Purpose:** Preview pane management. Clears the preview, dispatches
to the viewer.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::prev::clear` | — | Clear the preview pane |
| `ftl::prev::dispatch` | — | Dispatch the preview for the current entry |
| `ftl::prev::show_image` | `<path>` | Show an image in the preview pane |

**Globals:** `ftl_state_preview_callback`,
`ftl_state_preview_pane_visible`, `ftl_state_dir_preview_mode`,
`ftl_state_show_size_mode`, `ftl_state_external_viewer_mode`,
`ftl_state_alt_preview_mode`, `ftl_state_montage_glyph`.

**Interactions:** `ftl::list::render` calls `ftl::prev::dispatch`
after rendering the listing. `dispatch` sources `viewers/core` and
calls `pviewers`.

---

## 12. `etag.sh` (27 lines)

**Purpose:** Etag (extension tag) framework. Defines the default
no-op etag functions that plugins override.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::etag::scan_directory` | — | No-op default; plugins override |
| `ftl::etag::get_entry_tag` | `<path> <nameref> <nameref>` | No-op default; plugins override |

**Interactions:** `ftl::list::scan_and_render` calls
`ftl::etag::scan_directory` after scanning. `ftl::list::render` calls
`ftl::etag::get_entry_tag` per entry to display the etag column.

---

## 13. `virtual.sh` (87 lines)

**Purpose:** Virtual entries framework. Allows plugins to inject fake
entries (dirs or files) with custom previews and key handling.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::plugin::virtual::get_dirs_callback` | — | Default no-op; plugins override |
| `ftl::plugin::virtual::get_files_callback` | — | Default no-op; plugins override |
| `ftl::plugin::virtual::clear_filter` | — | Default passthrough; plugins override |
| `ftl::plugin::virtual::preview_callback` | — | Default no-op; plugins override |
| `ftl::plugin::virtual::handle_key` | — | Default false; plugins override |
| `ftl::plugin::virtual::set_callbacks` | `<args>` | Set the callbacks |
| `ftl::plugin::virtual::enable` | — | Enable virtual entries |
| `ftl::plugin::virtual::disable` | — | Disable virtual entries |
| `ftl::plugin::virtual::reset` | — | Reset to defaults |
| `ftl::plugin::virtual::get_virtual_dirs` | — | Get virtual dirs (called by list) |
| `ftl::plugin::virtual::get_virtual_files` | — | Get virtual files (called by list) |

**Globals:** `ftl_plugin_vfiles`, `ftl_plugin_vdirs`,
`ftl_plugin_virtual_enabled`.

**Interactions:** `ftl::list::scan_directory` calls
`get_virtual_dirs` and `get_virtual_files` to inject entries.
`ftl::kbd::dispatch` calls `handle_key` to intercept keys when
virtual entries are active.

---

## 14. `mark.sh` (20 lines)

**Purpose:** Session marks (single-character bookmarks) and global
history.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `_ftl::mark::save_to_history` | — | Save current path to global history |

**Globals:** `ftl_mark_session_marks` (assoc array: char → path),
`ftl_state_global_history_file`.

**Interactions:** `ftl::list::scan_and_render` calls
`save_to_history` on directory change. The `'` binding sets session
marks. `LEADER H` shows the history as an fzf list.

---

## 15. `time.sh` (28 lines)

**Purpose:** Time-event handlers. Allows plugins to register functions
that fire at a configurable interval.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::time::tick` | — | Fire handlers whose interval has elapsed |

**Globals:** `ftl_time_handlers` (assoc array: name → "interval:last"),
`ftl_cfg_time_event_interval`.

**Interactions:** The main loop calls `ftl::time::tick` on every
iteration. If the global interval (`ftl_cfg_time_event_interval`) is
0, tick is a no-op.

---

## 16. `commands.sh` (2732 lines)

**Purpose:** User-facing command functions. The largest module.
Organized into 14 sections: dispatcher, movement, selection, file
operations, filter, search, tab, pane, preview, shell, view mode,
mark/history, quit, command prompt.

**Public API:** ~390 functions, all named `ftl::cmd::*`. Key
categories:

- **Movement:** `cursor_up`, `cursor_down`, `cursor_left_arrow`,
  `cursor_right_arrow`, `cd_to_parent`, `cd_into_entry`, `move_right`,
  `page_up`, `page_down`, `goto_first_directory`, `goto_last_file`,
  `jump_by_percent`, `goto_next_same_extension`, `goto_by_index`.
- **Selection:** `select_all`, `select_all_files`,
  `select_all_directories`, `flip_down`, `flip_up`, `select_class_1`
  through `select_class_4`, `tag_with_class`, `untag_via_fzf`,
  `select_via_fzf`, `select_extension_via_fzf`.
- **File operations:** `delete_selection`, `copy_to_prompted`,
  `copy_selection_here`, `move_selection_here`, `copy_to_preset`,
  `move_to_preset`, `rename_selection`, `symlink_selection`,
  `follow_symlink`, `chmod_toggle_read`, `chmod_toggle_write`,
  `chmod_toggle_exec`, `create_file`, `create_dir_and_cd`,
  `create_bulk`, `edit_in_vim`, `hex_view`, `hex_edit`.
- **Filter:** `filter_cycle`, `filter_dir_cycle`, `filter_reverse`,
  `filter_image_negate`, `show_hidden`, `show_size`,
  `listing_mode_cycle`, `sort_cycle`, `dirs_only`.
- **Search:** `find_in_dir`, `find_next`, `find_prev`, `rg_search`.
- **Tab:** `tab_new`, `tab_next`, `tab_prev`, `tab_close`,
  `tab_move_to_other`.
- **Pane:** `pane_split_vertical`, `pane_split_horizontal`,
  `pane_next`, `pane_prev`, `pane_zoom`.
- **Preview:** `preview_pin`, `preview_unpin`, `preview_zoom_in`,
  `preview_zoom_out`, `preview_clear`.
- **Shell:** `shell_popup`, `shell_split`.
- **View mode:** `view_mode_cycle`, `image_mode_cycle`.
- **Mark/history:** `set_mark`, `goto_mark`, `show_history`,
  `clear_history`.
- **Quit:** `quit`, `quit_all`, `quit_cancelled`.
- **Command prompt:** `open_command_prompt`, `dispatch_command`,
  `prompt`, `prompt_with_history`.

**Interactions:** Commands are invoked by `ftl::kbd::dispatch` (via
the trie). They call `ftl::list::render` or `ftl::list::change_dir` to
update the display. They read `ftl_selection_current`,
`ftl_state_current_path`, etc.

---

## 17. `inline_rename.sh` (418 lines)

**Purpose:** Modal inline rename mode. Entered via `LEADER r i`.
Provides single, sequential, regexp, and image-label rename in a
two-level modal workflow.

**Public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::plugin::inline_rename::enter` | — | Enter inline rename mode |
| `ftl::plugin::inline_rename::exit` | — | Exit inline rename mode |
| `ftl::plugin::inline_rename::dispatch` | — | Sub-mode handler (set as `ftl_kbd_submode_handler`) |

**Private helpers:** `_ftl::plugin::inline_rename::dispatch_outer`,
`_ftl::plugin::inline_rename::dispatch_inner`,
`_ftl::plugin::inline_rename::begin_edit`,
`_ftl::plugin::inline_rename::begin_label`,
`_ftl::plugin::inline_rename::commit`,
`_ftl::plugin::inline_rename::commit_label`,
`_ftl::plugin::inline_rename::abort`,
`_ftl::plugin::inline_rename::sequential`,
`_ftl::plugin::inline_rename::regexp`,
`_ftl::plugin::inline_rename::delete_one`,
`_ftl::plugin::inline_rename::snapshot_targets`,
`_ftl::plugin::inline_rename::render_draft`.

**Globals:** `ftl_inline_rename_active`, `ftl_inline_rename_original_path`,
`ftl_inline_rename_original_name`, `ftl_inline_rename_draft`,
`ftl_inline_rename_draft_cursor`, `ftl_inline_rename_is_label`,
`ftl_inline_rename_history`, `ftl_inline_rename_bulk_targets`,
`ftl_state_inline_rename_error`.

**Interactions:** Sets `ftl_kbd_submode_handler` to redirect keyboard
dispatch. Calls `ftl::cmd::cursor_up`, `ftl::cmd::cursor_down`,
`ftl::sel::flip`, `ftl::cmd::prompt`, `ftl::list::change_dir`,
`ftl::list::render`. The sub-mode handler is called by
`ftl::kbd::dispatch` on every keypress while the mode is active.

---

## Module Interaction Diagram

```
                    ┌──────────┐
                    │ bin/ftl  │ (entry point, main loop)
                    └────┬─────┘
                         │ sources
                         ▼
                ┌────────────────┐
                │  ftl_setup     │ (orchestrator)
                └────┬───────────┘
                     │ sources in order
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   ┌─────────┐ ┌──────────┐ ┌──────────┐
   │  util   │ │   log    │ │  state   │
   └────┬────┘ └────┬─────┘ └────┬─────┘
        │           │            │
        ▼           ▼            ▼
   ┌─────────┐ ┌──────────┐ ┌──────────┐
   │keyboard │ │ selection│ │   tab    │
   └────┬────┘ └────┬─────┘ └────┬─────┘
        │           │            │
        ▼           ▼            ▼
   ┌─────────┐ ┌──────────┐ ┌──────────┐
   │  pane   │ │  filter  │ │  virtual │
   └────┬────┘ └────┬─────┘ └────┬─────┘
        │           │            │
        ▼           ▼            ▼
        └───────────┴────────────┘
                   │
                   ▼
              ┌─────────┐
              │  list   │ (uses all of the above)
              └────┬────┘
                   │
                   ▼
              ┌─────────┐
              │ preview │
              └────┬────┘
                   │
                   ▼
              ┌─────────┐
              │commands │ (uses everything; defines ftl::cmd::*)
              └────┬────┘
                   │
                   ▼
              ┌──────────────┐
              │inline_rename │ (uses commands, list, selection, keyboard)
              └──────────────┘

   Other modules: debug (standalone), etag (called by list),
   mark (called by list), time (called by main loop)
```

---

## Next Steps

Continue to [04-api-reference.md](./04-api-reference.md) for the
alphabetical API listing, or jump to
[05-testing.md](./05-testing.md) to learn the testing system.
