# 04 — API Reference

> **Audience:** Maintainers looking up a specific function's signature
> or behavior.
> **Format:** Alphabetical by module, then alphabetical by function
> within each module.

This document lists every public function in ftl's core modules. For
private helpers (prefixed `_ftl::`), see the source file header
comments.

---

## `ftl::cmd::*` (commands.sh)

~390 functions. The most frequently used are listed here. For the full
list, see the section headers in `config/ftl/etc/core/modules/commands.sh`.

### Movement

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::cmd::cursor_up` | — | Move cursor up one entry |
| `ftl::cmd::cursor_up_arrow` | — | Same as `cursor_up` (arrow key alias) |
| `ftl::cmd::cursor_down` | — | Move cursor down one entry |
| `ftl::cmd::cursor_down_arrow` | — | Same as `cursor_down` |
| `ftl::cmd::cd_to_parent` | — | cd to parent directory |
| `ftl::cmd::cursor_left_arrow` | — | Same as `cd_to_parent` |
| `ftl::cmd::cd_into_entry` | — | cd into the current entry if it's a dir |
| `ftl::cmd::move_right` | — | Same as `cd_into_entry` |
| `ftl::cmd::cursor_right_arrow` | — | Same as `move_right` |
| `ftl::cmd::cursor_up_step` | — | Move cursor up by `ftl_cfg_move_step_size` |
| `ftl::cmd::cursor_down_step` | — | Move cursor down by `ftl_cfg_move_step_size` |
| `ftl::cmd::page_up` | — | Move cursor up by one page |
| `ftl::cmd::page_down` | — | Move cursor down by one page |
| `ftl::cmd::goto_first_directory` | — | Jump to the first directory entry |
| `ftl::cmd::goto_first_file` | — | Jump to the first file entry |
| `ftl::cmd::goto_last_file` | — | Jump to the last file entry |
| `ftl::cmd::goto_top_of_window` | — | Jump to the top of the visible window |
| `ftl::cmd::goto_bottom_of_window` | — | Jump to the bottom of the visible window |
| `ftl::cmd::jump_by_percent` | — | Jump to N% of the listing (uses count) |
| `ftl::cmd::goto_next_same_extension` | — | Jump to the next entry with the same extension |
| `ftl::cmd::goto_next_diff_extension` | — | Jump to the next entry with a different extension |
| `ftl::cmd::goto_by_index` | `<index>` | Jump to the Nth entry |
| `ftl::cmd::goto_next_selected` | — | Jump to the next tagged entry |
| `ftl::cmd::goto_prev_selected` | — | Jump to the previous tagged entry |
| `ftl::cmd::cd_prompt` | — | Prompt for a directory and cd to it |
| `ftl::cmd::change_dir` | — | cd to the current entry (if dir) |

### Selection

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::cmd::select_all` | — | Tag all entries |
| `ftl::cmd::select_all_files` | — | Tag all file entries |
| `ftl::cmd::select_all_directories` | — | Tag all directory entries |
| `ftl::cmd::flip_down` | — | Toggle tag on current entry, move down |
| `ftl::cmd::flip_up` | — | Toggle tag on current entry, move up |
| `ftl::cmd::select_class_1` | — | Tag current entry with class ¹ |
| `ftl::cmd::select_class_2` | — | Tag current entry with class ² |
| `ftl::cmd::select_class_3` | — | Tag current entry with class ³ |
| `ftl::cmd::select_class_4` | — | Tag current entry with class D |
| `ftl::cmd::untag_via_fzf` | — | fzf-list tagged entries, untag selected |
| `ftl::cmd::select_via_fzf` | — | fzf-list entries, tag selected |
| `ftl::cmd::select_extension_via_fzf` | — | Tag all entries with the current extension |

### File operations

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::cmd::delete_selection` | — | Delete the selection (with confirmation) |
| `ftl::cmd::copy_to_prompted` | — | Prompt for a destination, copy selection there |
| `ftl::cmd::copy_selection_here` | — | Copy selection to the current directory |
| `ftl::cmd::move_selection_here` | — | Move selection to the current directory |
| `ftl::cmd::copy_to_preset` | — | Copy selection to a preset destination |
| `ftl::cmd::move_to_preset` | — | Move selection to a preset destination |
| `ftl::cmd::rename_selection` | — | Rename selection via `edir` |
| `ftl::cmd::symlink_selection` | — | Create symlinks to the selection in cwd |
| `ftl::cmd::follow_symlink` | — | cd to the target of the current symlink |
| `ftl::cmd::chmod_toggle_read` | — | Toggle read permission on selection |
| `ftl::cmd::chmod_toggle_write` | — | Toggle write permission on selection |
| `ftl::cmd::chmod_toggle_exec` | — | Toggle execute permission on selection |
| `ftl::cmd::create_file` | — | Prompt for a name, touch the file |
| `ftl::cmd::create_dir_and_cd` | — | Prompt for a name, mkdir, cd into it |
| `ftl::cmd::create_bulk` | — | Open $EDITOR on a list, create the entries |
| `ftl::cmd::edit_in_vim` | — | Open the current file in $EDITOR |
| `ftl::cmd::hex_view` | — | Hex view the current file |
| `ftl::cmd::hex_edit` | — | Hex edit the current file |

### Filter / view

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::cmd::filter_cycle` | — | Cycle to the next external filter |
| `ftl::cmd::filter_dir_cycle` | — | Cycle the directory filter |
| `ftl::cmd::filter_reverse` | — | Toggle the reverse filter |
| `ftl::cmd::show_hidden` | — | Toggle hidden files |
| `ftl::cmd::show_size` | — | Cycle size display modes |
| `ftl::cmd::listing_mode_cycle` | — | Cycle listing modes (dirs only, files only, both) |
| `ftl::cmd::sort_cycle` | — | Cycle sort types |
| `ftl::cmd::dirs_only` | — | Toggle dirs-only preview |

### Search

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::cmd::find_in_dir` | — | Incremental filename search |
| `ftl::cmd::find_next` | — | Jump to the next search match |
| `ftl::cmd::find_prev` | — | Jump to the previous search match |
| `ftl::cmd::rg_search` | — | ripgrep content search |

### Tab / pane

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::cmd::tab_new` | — | Create a new tab |
| `ftl::cmd::tab_next` | — | Switch to the next tab |
| `ftl::cmd::tab_prev` | — | Switch to the previous tab |
| `ftl::cmd::tab_close` | — | Close the current tab |
| `ftl::cmd::pane_split_vertical` | — | Split the pane vertically |
| `ftl::cmd::pane_split_horizontal` | — | Split the pane horizontally |
| `ftl::cmd::pane_next` | — | Switch to the next pane |
| `ftl::cmd::pane_prev` | — | Switch to the previous pane |
| `ftl::cmd::pane_zoom` | — | Zoom the current pane |

### Quit / prompt

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::cmd::quit` | — | Quit ftl |
| `ftl::cmd::quit_all` | — | Quit all ftl panes |
| `ftl::cmd::open_command_prompt` | — | Open the `:` command prompt |
| `ftl::cmd::dispatch_command` | `<cmd>` | Dispatch a command from the prompt |
| `ftl::cmd::prompt` | `<prompt> [opts]` | Read user input (sets `$REPLY`) |
| `ftl::cmd::prompt_with_history` | `<prompt>` → stdout | Read input with rlwrap history |

---

## `ftl::etag::*` (etag.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::etag::scan_directory` | — | Scan the current directory for etags (default: no-op) |
| `ftl::etag::get_entry_tag` | `<path> <tag_nameref> <width_nameref>` | Get the tag for a specific entry (default: no-op) |

---

## `ftl::filt::*` (filter.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::filt::pipeline_add` | `<filter>` | Add a filter function to the pipeline |
| `ftl::filt::pipeline_clear` | — | Clear the pipeline |
| `ftl::filt::pipeline_remove` | `<filter>` | Remove a filter from the pipeline |
| `ftl::filt::reset` | — | Reset to default pipeline |
| `ftl::filt::sort_entries` | — | Sort entries (stdin → stdout) |
| `ftl::filt::sort_by` | `<type>` | Set the sort type |
| `ftl::filt::get_sort_glyph` | `<type>` → stdout | Get the glyph for a sort type |
| `ftl::filt::apply_user_colors` | — | Apply user color overrides |
| `ftl::filt::load_external` | `<name>` | Load an external filter plugin |
| `ftl::filt::init` | — | Initialize the pipeline string |

## `ftl::filter::*` (filter.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::filter::apply_external` | — | The external filter slot (stdin → stdout); overridden by plugins |

---

## `ftl::kbd::*` (keyboard.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::kbd::bind` | `<map> <section> <keys> <cmd> <help>` | Register a binding |
| `ftl::kbd::unbind` | `<keys>` | Remove a binding |
| `ftl::kbd::reset_redo_exclusions` | — | Clear redo exclusions |
| `ftl::kbd::exclude_from_redo` | `<cmd>` | Exclude a command from redo |
| `ftl::kbd::get_key` | `[<timeout>]` | Read and normalize one key |
| `ftl::kbd::normalize_key` | `<raw>` → stdout | Normalize a raw escape sequence |
| `ftl::kbd::dispatch` | — | Dispatch the current key |
| `ftl::kbd::drain_input` | — | Drain pending stdin |
| `ftl::kbd::show_bindings` | — | Show the bindings table |
| `ftl::kbd::init_exclusions` | — | Initialize default redo exclusions |

---

## `ftl::list::*` (list.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::list::change_dir` | `[<dir> [<file> [<index>]]]` | Change directory and re-list |
| `ftl::list::refresh_dir` | `[<index> [<quick>]]` | Refresh without full rescan |
| `ftl::list::render` | `[<index>]` | Render the current listing |
| `ftl::list::move_cursor` | `<delta>` | Move the cursor by N entries |
| `ftl::list::compute_dir_sizes` | — | Compute dir sizes (du mode) |
| `ftl::list::compute_preview_width` | — | Compute preview pane width |
| `ftl::list::get_mime_type` | — | Get MIME type for the current entry |
| `ftl::list::quote_all_entries` | — → stdout | Quote all entries for shell |
| `ftl::list::quote_all_dirs` | — → stdout | Quote all directory entries |
| `ftl::list::quote_all_files` | — → stdout | Quote all file entries |
| `ftl::list::quote_selection` | — → stdout | Quote the selection for shell |

---

## `ftl::log::*` (log.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::log::init` | — | Open the log file |
| `ftl::log::set_level` | `<level>` | Set log level (0–4) |
| `ftl::log::wrap` | `<fn> <args...>` | Call a function, log output |
| `ftl::log::show_error_full` | `<msg>` | Show error with stack trace |
| `ftl::log::show_error_popup` | `<msg>` | Show error in a popup |
| `ftl::log::warn` | `<msg>` | Log at warn level |
| `ftl::log::error` | `<msg>` | Log at error level + popup |
| `ftl::log::info` | `<msg>` | Log at info level |
| `ftl::log::debug` | `<msg>` | Log at debug level |
| `ftl::log::trace` | `<msg>` | Log at trace level |
| `ftl::log::show_debug_pane` | — | Open a pane tailing the log |
| `ftl::log::log_caller` | — | Print the calling function |

---

## `ftl::pane::*` (pane.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::pane::pid_to_id` | `<pid>` → stdout | Convert PID to tmux pane id |
| `ftl::pane::query_geometry` | — | Query pane height/width |
| `ftl::pane::snapshot_geometry` | — | Save geometry for winch detection |
| `ftl::pane::check_resize` | — | Re-render if resized |
| `ftl::pane::split` | `<cmd> [<size>]` | Split pane and run command |
| `ftl::pane::split_or_respawn` | `<cmd>` | Respawn or split |
| `ftl::pane::split_for_preview` | `<cmd>` | Split for preview |
| `ftl::pane::select` | `<direction>` | Select a pane |
| `ftl::pane::set_border_colors` | — | Set tmux border colors |
| `ftl::pane::window_exists` | `<name>` | Check if a tmux window exists |
| `ftl::pane::count_bg_windows` | — → stdout | Count background windows |
| `ftl::pane::ensure_session` | — | Ensure a tmux session exists |
| `ftl::pane::run_in_bg_window` | `<cmd>` | Run in a bg window |
| `ftl::pane::run_in_user_session` | `<cmd>` | Run in a user session |
| `ftl::pane::read_child_list` | — | Read the child-pane list |
| `ftl::pane::send_to_all_children` | `<key>` | Send a key to all children |
| `ftl::pane::start_file_watcher` | — | Start inotify watcher |
| `ftl::pane::stop_file_watcher` | — | Stop inotify watcher |

---

## `ftl::prev::*` (preview.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::prev::clear` | — | Clear the preview pane |
| `ftl::prev::dispatch` | — | Dispatch preview for current entry |
| `ftl::prev::show_image` | `<path>` | Show an image in the preview |

---

## `ftl::sel::*` (selection.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::sel::resolve_current` | — | Build `ftl_selection_current` from tags |
| `ftl::sel::clear_all` | — | Clear the selection |
| `ftl::sel::flip` | `<path> [<glyph>]` | Toggle a tag |
| `ftl::sel::set` | `<path> [<glyph>]` | Set a tag |
| `ftl::sel::unset` | `<path>` | Unset a tag |
| `ftl::sel::unset_by_class` | `<glyph>` | Unset all tags with a glyph |
| `ftl::sel::validate_existence` | — | Remove tags for non-existent files |
| `ftl::sel::prompt_for_class` | — → stdout | Ask user which class |
| `ftl::sel::build_class_index` | — | Build inverted class index |
| `ftl::sel::get_by_class` | `<nameref> <nameref>` | Get tags matching a class |
| `ftl::sel::goto_by_index` | `<index>` | Navigate to the Nth tagged file |
| `ftl::sel::fzf_tag_or_untag` | `<mode> <paths>` | Tag/untag from fzf output |
| `ftl::sel::sync_from_other_pane` | — | Sync from sibling pane |
| `ftl::sel::load_from_file` | `<arg1> <file>` | Load selection from a file |
| `ftl::sel::adjust_total_size` | `<+|-> <path>` | Adjust total size |
| `ftl::sel::format_header_summary` | — → stdout | Format "count/size" for header |

---

## `ftl::state::*` (state.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::state::init` | — | Create session dir and subdirs |
| `ftl::state::save` | `[<target_dir>]` | Serialize listing state |
| `ftl::state::load` | `[<file>]` | Source a state file |
| `ftl::state::save_selection` | `[<file>]` | Serialize selection |
| `ftl::state::load_selection` | `<file>` | Source a selection file |
| `ftl::state::serialize_info` | `[<file>]` | Write info file for external commands |
| `ftl::state::render_child_env` | `[<prefix>]` | Render `-e key=val` args |
| `ftl::state::emit_selection_fd3` | — | Write selection to fd 3 |
| `ftl::state::cleanup` | — | Remove session directory |

---

## `ftl::tab::*` (tab.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::tab::init_defaults` | — | Initialize default tab state |
| `ftl::tab::create` | — | Create a new tab |
| `ftl::tab::advance_index` | — | Next tab |
| `ftl::tab::retreat_index` | — | Previous tab |
| `ftl::tab::load_from_file` | `<args>` | Load tabs from a file |
| `ftl::tab::index_directory` | — | Scan for the dir-view |

---

## `ftl::time::*` (time.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::time::tick` | — | Fire handlers whose interval elapsed |

---

## `ftl::util::*` (util.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::util::parse_path` | `<path>` | Decompose a path into globals |
| `ftl::util::clear_path_vars` | — | Reset path globals to empty |
| `ftl::util::resolve_full_path` | `<path>` → stdout | Resolve `./` and trailing `/` |
| `ftl::util::format_size_human` | `<bytes>` → stdout | Format as `1.2K` etc. |
| `ftl::util::is_binary_file` | `<path>` | Set `ftl_state_current_is_binary` |
| `ftl::util::run_maximized` | `<cmd...>` | Minimize, run, restore |
| `ftl::util::refresh_screen` | `[<esc>]` | Hide cursor + optional escape |
| `ftl::util::dedup_file` | `<file>` | Remove duplicate lines |
| `ftl::util::create_fifos` | `<fd>...` | Create named pipes |
| `ftl::util::stacktrace` | — | Print a stack trace |
| `ftl::util::enter_alt_screen` | — | Enter tmux alternate screen |

---

## `ftl::plugin::virtual::*` (virtual.sh)

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
| `ftl::plugin::virtual::get_virtual_dirs` | — | Get virtual dirs |
| `ftl::plugin::virtual::get_virtual_files` | — | Get virtual files |

---

## `ftl::plugin::inline_rename::*` (inline_rename.sh)

| Function | Signature | Description |
|----------|-----------|-------------|
| `ftl::plugin::inline_rename::enter` | — | Enter inline rename mode |
| `ftl::plugin::inline_rename::exit` | — | Exit inline rename mode |
| `ftl::plugin::inline_rename::dispatch` | — | Sub-mode handler |

---

## Globals Reference

For the complete variable reference (2427 lines), see
`documentation/ftl-variables.md`. The most commonly accessed globals:

### State

| Variable | Description |
|----------|-------------|
| `ftl_state_session_dir` | This pane's private session directory |
| `ftl_state_parent_dir` | Parent pane's session directory |
| `ftl_state_shared_dir` | Shared state directory (= parent's `prev/`) |
| `ftl_state_current_path` | Full path of the current entry |
| `ftl_state_current_dir` | Parent directory of the current entry |
| `ftl_state_current_basename` | Basename of the current entry |
| `ftl_state_current_stem` | Stem (basename without extension) |
| `ftl_state_current_extension` | Extension (without the dot) |
| `ftl_state_current_tab_index` | Current tab index (0-based) |
| `ftl_state_cursor_index` | Current cursor position in the listing |
| `ftl_state_cursor_memory` | Assoc: `tab_PWD` → cursor index |
| `ftl_state_search_string` | Current incremental search string |
| `ftl_state_previous_pwd` | Previous directory (for history) |
| `ftl_state_quit_cancelled` | Whether quit was cancelled (for fd 3) |
| `ftl_state_pending_input` | Pending key input (set by command palette) |

### Listing

| Variable | Description |
|----------|-------------|
| `ftl_list_entries` | Indexed array of full paths |
| `ftl_list_entry_colors` | Indexed array of colorized names |
| `ftl_list_entry_count` | Number of entries |
| `ftl_list_window_top` | Top visible index |
| `ftl_list_window_bottom` | Bottom visible index |
| `ftl_list_window_height` | Visible height |
| `ftl_list_window_center` | Center index |
| `ftl_list_mime_cache` | Assoc: path → MIME type |
| `ftl_list_dir_size_cache` | Assoc: dir → colored size |

### Selection

| Variable | Description |
|----------|-------------|
| `ftl_selection_tags` | Assoc: path → glyph |
| `ftl_selection_current` | Indexed array of resolved selection |
| `ftl_selection_total_bytes` | Total size of selection |
| `ftl_selection_revision` | Monotonic counter (for sync) |
| `ftl_selection_class_index` | Assoc: class → 1 |

### Tab

| Variable | Description |
|----------|-------------|
| `ftl_tab_directories` | Indexed array: tab → PWD |
| `ftl_tab_count` | Number of tabs |
| `ftl_tab_sort_type` | Indexed array: tab → sort type |
| `ftl_tab_filter_1` | Indexed array: tab → filter 1 regex |
| `ftl_tab_filter_2` | Indexed array: tab → filter 2 regex |
| `ftl_tab_view_mode` | Indexed array: tab → image mode |
| `ftl_tab_listing_mode` | Indexed array: tab → listing mode |

### Keyboard

| Variable | Description |
|----------|-------------|
| `ftl_kbd_trie` | Assoc: key sequence → command |
| `ftl_kbd_command_to_key` | Assoc: command → key sequence |
| `ftl_kbd_submode_handler` | Current sub-mode handler function |
| `ftl_kbd_current_key` | Current normalized key |
| `ftl_kbd_count` | Current count prefix |
| `ftl_kbd_last_command` | Last non-excluded command (for redo) |

### Pane

| Variable | Description |
|----------|-------------|
| `ftl_pane_self_id` | This pane's tmux id |
| `ftl_pane_is_primary` | 1 if this is the primary pane |
| `ftl_pane_is_child` | 1 if this is a child/preview pane |
| `ftl_pane_height` | Pane height in rows |
| `ftl_pane_width` | Pane width in columns |
