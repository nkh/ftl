# Function Index

A consolidated index of ftl's namespaced functions. Public functions
are under `ftl::*`; private helpers are under `_ftl::*`. Each row lists
the function, its module, and a short purpose. See also
[Module Reference](modules.md) and
[Variable Index](variable-index.md).

## util — `ftl::util::*`

| Function | Purpose |
|----------|---------|
| `ftl::util::parse_path` | decompose a path into `n/p/f/b/e` globals |
| `ftl::util::clear_path_vars` | reset path globals to empty |
| `ftl::util::resolve_full_path` | resolve a relative path to absolute |
| `ftl::util::format_size_human` | human-readable size (K/M/G/T) |
| `ftl::util::is_binary_file` | check if a file is binary |
| `ftl::util::run_maximized` | run a command with ftl minimized |
| `ftl::util::refresh_screen` | emit a refresh escape sequence |
| `ftl::util::dedup_file` | deduplicate lines in a file |
| `ftl::util::create_fifos` | create named pipes on given fds |
| `ftl::util::enter_alt_screen` | enter the alt screen |
| `ftl::util::stacktrace` | print a bash stack trace |

## log — `ftl::log::*`

| Function | Purpose |
|----------|---------|
| `ftl::log::wrap` | run a command with stderr captured to log |
| `ftl::log::error` | log an error (red popup) |
| `ftl::log::warn` | log a warning (yellow popup) |
| `ftl::log::info` | log an info message (status line) |
| `ftl::log::debug` | log a debug message (pdh pane or file) |
| `ftl::log::show_debug_pane` | open/close the pdh debug pane |
| `ftl::log::show_error_full` | full-screen red error |
| `ftl::log::show_error_popup` | error in a tmux popup |
| `ftl::log::log_caller` | log caller context |
| `ftl::log::write` | append to session log |

## debug — `ftl::debug::*`

| Function | Purpose |
|----------|---------|
| `ftl::debug::stacktrace` | print a bash stack trace to stderr |
| `ftl::debug::log_caller` | log BASH_SOURCE/LINENO/FUNCNAME |
| `ftl::debug::format_size` | numfmt wrapper with error catching |

## state — `ftl::state::*`

| Function | Purpose |
|----------|---------|
| `ftl::state::init` | initialize per-session state dirs |
| `ftl::state::save` | serialize state to `$session_dir/ftl` |
| `ftl::state::load` | source a state file |
| `ftl::state::save_selection` | serialize the `ftl_selection_tags` array |
| `ftl::state::load_selection` | source a selection file |
| `ftl::state::serialize_info` | write info file for external commands |
| `ftl::state::render_child_env` | render `-e` args for child processes |
| `ftl::state::emit_selection_fd3` | write selection to fd 3 (for ftll/cdf) |
| `ftl::state::cleanup` | remove the session directory |

## keyboard — `ftl::kbd::*`

| Function | Purpose |
|----------|---------|
| `ftl::kbd::bind` | register a key binding |
| `ftl::kbd::unbind` | remove a key binding |
| `ftl::kbd::get_key` | read and normalize a single key |
| `ftl::kbd::normalize_key` | normalize a raw escape sequence |
| `ftl::kbd::dispatch` | dispatch the current key to a command |
| `ftl::kbd::drain_input` | drain pending stdin |
| `ftl::kbd::show_bindings` | show the bindings table |
| `ftl::kbd::reset_redo_exclusions` | clear the redo-exclusion set |
| `ftl::kbd::exclude_from_redo` | exclude a command from redo |
| `ftl::kbd::init_exclusions` | init default redo exclusions (movement) |
| `_ftl::kbd::show_bindings_popup` | show bindings in a tmux popup |
| `_ftl::kbd::show_bindings_fullscreen` | show bindings fullscreen |
| `_ftl::kbd::generate_bindings_table` | generate the bindings table |

## selection — `ftl::sel::*`

| Function | Purpose |
|----------|---------|
| `ftl::sel::resolve_current` | build `ftl_selection_current` from tags |
| `ftl::sel::clear_all` | clear the entire selection |
| `ftl::sel::flip` | toggle a tag on/off |
| `ftl::sel::set` / `unset` | set / unset a tag |
| `ftl::sel::unset_by_class` | unset all tags with a given class |
| `ftl::sel::validate_existence` | remove tags for non-existent files |
| `ftl::sel::prompt_for_class` | ask user which class to operate on |
| `ftl::sel::fzf_choose_class` | fzf-based class chooser |
| `ftl::sel::build_class_index` | build inverted index of classes |
| `ftl::sel::get_by_class` | get tags matching a class (nameref) |
| `ftl::sel::goto_by_index` | navigate to the Nth tagged file |
| `ftl::sel::fzf_tag_or_untag` | tag/untag from fzf output |
| `ftl::sel::sync_from_other_pane` | sync selection from another pane |
| `ftl::sel::load_from_file` | load selection from a file of paths |
| `ftl::sel::adjust_total_size` | adjust `ftl_selection_total_bytes` |
| `ftl::sel::format_header_summary` | format "count/size" for the header |

## tab — `ftl::tab::*`

| Function | Purpose |
|----------|---------|
| `ftl::tab::init_defaults` | set up default state for the current tab |
| `ftl::tab::create` | create a new tab |
| `ftl::tab::advance_index` | move to the next tab |
| `ftl::tab::retreat_index` | move to the previous tab |
| `ftl::tab::load_from_file` | load tabs from a file (for `-t`) |
| `ftl::tab::index_directory` | build entry-index cache for a directory |

## pane — `ftl::pane::*`

| Function | Purpose |
|----------|---------|
| `ftl::pane::pid_to_id` | convert a PID to a tmux pane id |
| `ftl::pane::query_geometry` | query current pane geometry |
| `ftl::pane::snapshot_geometry` | save geometry for winch detection |
| `ftl::pane::check_resize` | check if pane was resized |
| `ftl::pane::split` | split the pane and run a command |
| `ftl::pane::split_or_respawn` | respawn existing pane or split |
| `ftl::pane::split_for_preview` | split for preview (fzf-aware) |
| `ftl::pane::select` | select a pane |
| `ftl::pane::set_border_colors` | set tmux border colors |
| `ftl::pane::window_exists` | check if a tmux window exists |
| `ftl::pane::count_bg_windows` | count background tmux windows |
| `ftl::pane::ensure_session` | ensure a tmux session exists |
| `ftl::pane::run_in_bg_window` | run a command in a bg tmux window |
| `ftl::pane::run_in_user_session` | run in a user-named session |
| `ftl::pane::read_child_list` | read the child-pane list |
| `ftl::pane::send_to_all_children` | send a key to all children |
| `ftl::pane::start_file_watcher` | start inotify watcher |
| `ftl::pane::stop_file_watcher` | stop inotify watcher |
| `_ftl::pane::split_with_fixed_preview` | open a second split for fixed preview |
| `_ftl::pane::file_watcher_loop` | inotify watcher loop (subshell) |
| `_ftl::pane::run_inotifywait` | run inotifywait on current dir |

## filter — `ftl::filt::*` / `ftl::filter::*`

| Function | Purpose |
|----------|---------|
| `ftl::filt::pipeline_add` | add a filter to the pipeline |
| `ftl::filt::pipeline_clear` | clear the pipeline |
| `ftl::filt::pipeline_remove` | remove a filter from the pipeline |
| `ftl::filt::reset` | reset all filters to defaults |
| `ftl::filt::sort_entries` / `ftl::filt::sort_entries` | default sort |
| `ftl::filt::get_sort_glyph` | return the sort glyph |
| `ftl::filt::apply_user_colors` | apply user color overrides |
| `ftl::filt::load_external` | load an external filter plugin |
| `ftl::filt::init` | initialize the default pipeline |
| `ftl::filter::apply_external` | placeholder, overridden by plugins |
| `_ftl::filt::reset_external` | reset the external filter |
| `_ftl::filt::apply_image_mode_filter` / `_apply_filter_1` / `_apply_filter_2` / `_apply_reverse_filter` | private pipeline stages |

## list — `ftl::list::*`

| Function | Purpose |
|----------|---------|
| `ftl::list::change_dir` | change directory and re-list |
| `ftl::list::refresh_dir` | refresh listing without full rescan |
| `ftl::list::render` | render the current listing |
| `ftl::list::move_cursor` | move the cursor by N entries |
| `_ftl::list::scan_and_render` | full cd+scan+render pipeline |
| `_ftl::list::scan_directory` | scan a directory into raw arrays |
| `_ftl::list::scan_custom_source` | scan from a custom source |
| `_ftl::list::apply_filters_and_format` | filter and format raw entries |
| `_ftl::list::render_window` | compute window and call render |
| `_ftl::list::render_header` | render the header line |
| `_ftl::list::print_header` | print the header with truncation |
| `_ftl::list::compute_header_truncation` | compute PWD/info truncation |
| `_ftl::list::clear_below` | clear lines below the given row |
| `_ftl::list::scan_for_dir_view` | scan for the dir-view |
| `_ftl::list::scan_full` | full scan with size/color output |
| `_ftl::list::find_entries` | run find with given predicates |
| `_ftl::list::inject_virtual_files` / `_inject_virtual_dirs` | emit virtual entries |

## preview — `ftl::prev::*`

| Function | Purpose |
|----------|---------|
| `ftl::prev::dispatch` | dispatch preview for current entry |
| `ftl::prev::clear` | clear the preview pane |
| `ftl::prev::show_in_vim` | show a file in vim (read-only) |
| `ftl::prev::show_image` | show an image via ftli/w3m |
| `ftl::prev::sync_and_dispatch` | sync state and dispatch |
| `ftl::prev::show_internal` / `show_external` | placeholders, overridden by viewers/core |
| `_ftl::prev::clear_fixed` | clear the fixed preview pane |
| `_ftl::prev::select_self_after_delay` | select our pane after a delay |
| `ftl::gen::thumb_path` | compute thumbnail path for a file |

## etag — `ftl::etag::*`

| Function | Purpose |
|----------|---------|
| `ftl::etag::scan_directory` | call the active etag's dir scan |
| `ftl::etag::get_entry_tag` | get the tag for one entry |

## virtual — `ftl::plugin::virtual::*`

| Function | Purpose |
|----------|---------|
| `ftl::plugin::virtual::set_callbacks` | register plugin callbacks |
| `ftl::plugin::virtual::enable` | turn on virtual entries |
| `ftl::plugin::virtual::reset` | turn off and clear callbacks |
| `ftl::plugin::virtual::inject_entries` | populate vfiles/vdirs arrays |
| `ftl::plugin::virtual::get_virtual_dirs` | emit virtual dirs (for pipeline) |
| `ftl::plugin::virtual::handle_key` | let plugin handle a key |
| `ftl::plugin::virtual::clear_filter` | passthrough (no-op filter) |

## mark / time / commands / ipc

| Function | Purpose |
|----------|---------|
| `_ftl::mark::save_to_history` | append current path to history files |
| `ftl::time::tick` | check if it's time to fire handlers |
| `ftl::cmd::dispatch_command` | dispatch a command entered at the prompt |
| `ftl::cmd::*` (hundreds) | every binding's command function — see [Key Bindings](key-bindings.md) |
| `ftl::cmd::dest_tag_current` | tag current entry with a destination directory (38a073a) |
| `ftl::cmd::dest_tag_clear_current` | clear current entry's dest tag |
| `ftl::cmd::dest_tag_clear_all` | clear all dest tags |
| `ftl::cmd::dest_tag_apply_last_to_count` | re-apply last dest shortcut to COUNT entries |
| `ftl::cmd::dest_tag_copy_tagged` | copy all tagged entries to their dests |
| `ftl::cmd::dest_tag_move_tagged` | move all tagged entries to their dests |
| `_ftl::dest::format_annotation` | format the ` [...dest]` annotation for display |
| `ftl::ipc::handle_pane_focus` | handle `å` pane-focus signal |
| `ftl::ipc::handle_preview_request` | handle `Ä` preview-sync signal |
| `ftl::ipc::handle_refresh` | handle `r` refresh signal |
