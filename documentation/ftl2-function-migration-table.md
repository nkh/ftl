# `ftl` v1 → v2 Function Migration Table

> **Source:** Based on the v1 codebase — ~250 core functions + ~100 plugin functions = **~350 functions**.
> **Purpose:** A complete mapping of every v1 function to its proposed v2 namespaced equivalent, organized by module, with rationale for non-obvious renames.
> **Naming scheme:** `ftl::<module>::<function>` for public functions, `_ftl::<module>::<function>` for private functions, `ftl::plugin::<name>::<function>` for plugin functions.
> **Module abbreviations:** `boot`, `cfg`, `state`, `log`, `ipc`, `kbd`, `list`, `prev`, `pane`, `plug`, `sel`, `tab`, `mark`, `filt`, `etag`, `view`, `gen`, `cmd`, `util`, `time`.

---

## Table of Contents

1. [Core Engine Functions](#1-core-engine-functions)
2. [Keyboard Functions](#2-keyboard-functions)
3. [Listing & Rendering Functions](#3-listing--rendering-functions)
4. [Filter Pipeline Functions](#4-filter-pipeline-functions)
5. [Selection / Tag Functions](#5-selection--tag-functions)
6. [Tab Functions](#6-tab-functions)
7. [Pane & Tmux Functions](#7-pane--tmux-functions)
8. [Preview Functions](#8-preview-functions)
9. [Etag Functions](#9-etag-functions)
10. [Marks & History Functions](#10-marks--history-functions)
11. [Search Functions](#11-search-functions)
12. [Shell Integration Functions](#12-shell-integration-functions)
13. [File Operation Functions](#13-file-operation-functions)
14. [Command Prompt Functions](#14-command-prompt-functions)
15. [State & IPC Functions](#15-state--ipc-functions)
16. [Utility Functions](#16-utility-functions)
17. [Plugin Functions — Filters](#17-plugin-functions--filters)
18. [Plugin Functions — Etags](#18-plugin-functions--etags)
19. [Plugin Functions — Viewers](#19-plugin-functions--viewers)
20. [Plugin Functions — Bindings](#20-plugin-functions--bindings)
21. [Plugin Functions — Commands](#21-plugin-functions--commands)
22. [Removed / Merged / Split Functions](#22-removed--merged--split-functions)
23. [Summary Statistics](#23-summary-statistics)

---

## 1. Core Engine Functions

The bootstrap and main loop.

| v1 name            | v2 name                           | module   | visibility  | rationale                                                               |
| ---------          | ---------                         | -------- | ----------- | -----------                                                             |
| `ftl`              | `ftl::boot::main`                 | `boot`   | public      | Entry point — the function called from `bin/ftl2`                       |
| (new)              | `ftl::boot::init`                 | `boot`   | public      | Initialization orchestrator (splits v1's `ftl` into init + loop)        |
| (new)              | `ftl::boot::setup_traps`          | `boot`   | public      | Signal trap setup (was inline in v1)                                    |
| (new)              | `ftl::boot::validate_environment` | `boot`   | public      | Check tmux, Bash version, dependencies (was missing in v1)              |
| `alt_screen`       | `ftl::util::enter_alt_screen`     | `util`   | public      | CL; spell out                                                           |
| (new)              | `ftl::util::exit_alt_screen`      | `util`   | public      | Symmetric counterpart (v1 only had enter)                               |
| `try`              | *(removed)*                       | —        | —           | **Replaced** by `ftl::log::wrap` with proper error capture              |
| `try_error`        | *(removed)*                       | —        | —           | **Replaced** by `ftl::log::show_error_full`                             |
| `try_errorp`       | *(removed)*                       | —        | —           | **Replaced** by `ftl::log::show_error_popup`                            |
| `warn`             | `ftl::log::warn`                  | `log`    | public      | NS                                                                      |
| `error`            | `ftl::log::error`                 | `log`    | public      | NS                                                                      |
| (new)              | `ftl::log::info`                  | `log`    | public      | New level (v1 only had warn/error)                                      |
| (new)              | `ftl::log::debug`                 | `log`    | public      | New level (replaces `pdh` debug messages)                               |
| `pdh`              | *(removed)*                       | —        | —           | **Replaced** by `ftl::log::debug`                                       |
| `pdhn`             | *(removed)*                       | —        | —           | **Replaced** by `ftl::log::debug` (with newline)                        |
| `pdh_show`         | `ftl::log::show_debug_pane`       | `log`    | public      | CL; "pdh_show" → "show_debug_pane"                                      |
| `numfmt` (wrapper) | `ftl::util::format_size`          | `util`   | public      | CL; v1 overrode `numfmt` globally (dangerous) — v2 uses a distinct name |
| `refresh`          | `ftl::util::refresh_screen`       | `util`   | public      | CL; "refresh" is too generic                                            |
| `kbdf`             | `ftl::kbd::drain_input`           | `kbd`    | public      | CL; "kbdf" is opaque — drains pending stdin                             |
| `winch`            | `ftl::pane::check_resize`         | `pane`   | public      | CL; "winch" is the signal name, not the action                          |
| `time_event`       | `ftl::time::tick`                 | `time`   | public      | CL; "time_event" is the trigger, "tick" is the action                   |
| `ftl_event_quit`   | `ftl::boot::on_quit`              | `boot`   | public      | CL; hook for plugins to clean up on quit                                |

---

## 2. Keyboard Functions

| v1 name                           | v2 name                                       | module       | visibility  | rationale                        |
| ---------                         | ---------                                     | --------     | ----------- | -----------                      |
| `bind`                            | `ftl::kbd::bind`                              | `kbd`        | public      | NS                               |
| `unbind`                          | `ftl::kbd::unbind`                            | `kbd`        | public      | NS                               |
| `get_key`                         | `ftl::kbd::get_key`                           | `kbd`        | public      | NS                               |
| (new)                             | `ftl::kbd::normalize_key`                     | `kbd`        | public      | **Split** from `get_key`         |
| `key_command`                     | `ftl::kbd::dispatch`                          | `kbd`        | public      | CL; "key_command" is misleading  |
| `reset_exclude_command_from_redo` | `ftl::kbd::reset_redo_exclusions`             | `kbd`        | public      | CL                               |
| `exclude_command_from_redo`       | `ftl::kbd::exclude_from_redo`                 | `kbd`        | public      | CL                               |
| `k_bindings`                      | `ftl::kbd::show_bindings`                     | `kbd`        | public      | CL; "k_bindings" is cryptic      |
| `k_bfull`                         | `_ftl::kbd::show_bindings_fullscreen`         | `kbd`        | private     | CL; "bfull" = "bindings full"    |
| `k_bpop`                          | `_ftl::kbd::show_bindings_popup`              | `kbd`        | private     | CL; "bpop" = "bindings popup"    |
| `k_bgen`                          | `_ftl::kbd::generate_bindings_table`          | `kbd`        | private     | CL; "bgen" = "bindings generate" |
| `cmd_prompt`                      | `ftl::cmd::prompt_with_history`               | `cmd`        | public      | CL; "cmd_prompt" is vague        |
| `prompt`                          | `ftl::cmd::prompt`                            | `cmd`        | public      | NS                               |
| `incremental_search`              | `ftl::plugin::incremental_search::enter`      | `plug` `kbd` | plugin      | NS; moved to plugin              |
| `incremental_find`                | `ftl::plugin::incremental_search::handle_key` | `plug` `kbd` | plugin      | CL                               |

---

## 3. Listing & Rendering Functions

| v1 name              | v2 name                                 | module   | visibility  | rationale                                                           |
| ---------            | ---------                               | -------- | ----------- | -----------                                                         |
| `cdir`               | `ftl::list::change_dir`                 | `list`   | public      | CL; "cdir" is cryptic                                               |
| `rdir`               | `ftl::list::refresh_dir`                | `list`   | public      | CL; "rdir" is cryptic                                               |
| `cview`              | `_ftl::list::scan_and_render`           | `list`   | private     | CL; "cview" is cryptic                                              |
| `view_list`          | `_ftl::list::render_window`             | `list`   | private     | CL                                                                  |
| `get_dir_entries`    | `_ftl::list::scan_directory`            | `list`   | private     | CL                                                                  |
| `prepare_entries`    | `_ftl::list::apply_filters_and_format`  | `list`   | private     | CL; "prepare_entries" is vague                                      |
| `get_custom_entries` | `_ftl::list::scan_custom_source`        | `list`   | private     | CL; used by fzf-listen mode                                         |
| `list`               | `ftl::list::render`                     | `list`   | public      | CL; "list" is too generic                                           |
| `show_header`        | `_ftl::list::render_header`             | `list`   | private     | CL                                                                  |
| `header`             | `_ftl::list::print_header`              | `list`   | private     | CL; "header" is a noun, "print_header" is a verb                    |
| `header_pos`         | `_ftl::list::compute_header_truncation` | `list`   | private     | CL                                                                  |
| `clear_list`         | `_ftl::list::clear_below`               | `list`   | private     | CL                                                                  |
| `as_dir`             | `_ftl::list::scan_for_dir_view`         | `list`   | private     | CL; "as_dir" is cryptic — used by `tab_read` to index a directory   |
| `dir`                | `_ftl::list::scan_full`                 | `list`   | private     | CL; "dir" is the main scan function (used by `cview`)               |
| `files`              | `_ftl::list::find_entries`              | `list`   | private     | CL; "files" is misleading (also finds dirs) — wraps `find`          |
| `files_virt`         | `_ftl::list::inject_virtual_files`      | `list`   | private     | CL                                                                  |
| `dirs_virt`          | `_ftl::list::inject_virtual_dirs`       | `list`   | private     | CL                                                                  |
| `output_size`        | `_ftl::list::emit_size_to_fifo`         | `list`   | private     | CL                                                                  |
| `output_path`        | `_ftl::list::emit_name_to_fifos`        | `list`   | private     | CL                                                                  |
| `dir_done`           | `_ftl::list::signal_scan_complete`      | `list`   | private     | CL                                                                  |
| `file_size`          | `ftl::util::format_size_human`          | `util`   | public      | CL; "file_size" formats, doesn't return the size                    |
| `dir_size`           | `_ftl::list::format_dir_size`           | `list`   | private     | CL                                                                  |
| `dir_esize`          | `_ftl::list::format_dir_entry_count`    | `list`   | private     | CL; "esize" = "entry size" — count of entries                       |
| `dir_dusize`         | `_ftl::list::compute_dir_sizes`         | `list`   | private     | CL; "dir_dusize" = "directory du size"                              |
| `get_dusize`         | `_ftl::list::run_du`                    | `list`   | private     | CL                                                                  |
| `geometry`           | `ftl::pane::query_geometry`             | `pane`   | public      | CL; "geometry" is a noun, "query_geometry" is a verb                |
| `geo_prev`           | `_ftl::list::adjust_for_preview`        | `list`   | private     | CL; "geo_prev" = "geometry preview" — adjusts COLS for preview pane |
| `geo_winch`          | `_ftl::pane::snapshot_geometry`         | `pane`   | private     | CL; saves current geometry for winch detection                      |
| `zoom`               | `_ftl::list::compute_preview_width`     | `list`   | private     | CL; "zoom" is misleading — this computes the resize target          |

---

## 4. Filter Pipeline Functions

| v1 name                  | v2 name                               | module       | visibility  | rationale                                                                |
| ---------                | ---------                             | --------     | ----------- | -----------                                                              |
| `filter_add`             | `ftl::filt::pipeline_add`             | `filt`       | public      | NS                                                                       |
| `filter_clr`             | `ftl::filt::pipeline_clear`           | `filt`       | public      | NS                                                                       |
| `filter_rmv`             | `ftl::filt::pipeline_remove`          | `filt`       | public      | CL; "rmv" → "remove"                                                     |
| `filter_rst`             | `ftl::filt::reset`                    | `filt`       | public      | CL                                                                       |
| `filter_rxt`             | `_ftl::filt::reset_external`          | `filt`       | private     | CL; "rxt" = "reset external"                                             |
| `filter_not`             | `_ftl::filt::apply_image_mode_filter` | `filt`       | private     | CL; "filter_not" is misleading — applies the image-mode (negated) filter |
| `filter_1`               | `_ftl::filt::apply_filter_1`          | `filt`       | private     | NS                                                                       |
| `filter_2`               | `_ftl::filt::apply_filter_2`          | `filt`       | private     | NS                                                                       |
| `filter_rev`             | `_ftl::filt::apply_reverse_filter`    | `filt`       | private     | CL                                                                       |
| `sort_by`                | `ftl::filt::sort_entries`             | `filt`       | public      | CL; "sort_by" is vague — this is the default sort function               |
| `sort_glyph`             | `ftl::filt::get_sort_glyph`           | `filt`       | public      | CL                                                                       |
| `user_color`             | `ftl::filt::apply_user_colors`        | `filt`       | public      | CL                                                                       |
| `set_filter`             | `ftl::cmd::set_filter_1`              | `cmd` `filt` | public      | CL; move to cmd module (user-facing)                                     |
| `set_filter2`            | `ftl::cmd::set_filter_2`              | `cmd` `filt` | public      | CL                                                                       |
| `set_filter_dir`         | `ftl::cmd::set_dir_filter`            | `cmd` `filt` | public      | CL                                                                       |
| `set_filter_reverse`     | `ftl::cmd::set_reverse_filter`        | `cmd` `filt` | public      | CL                                                                       |
| `set_filter_ext`         | `ftl::cmd::select_external_filter`    | `cmd` `filt` | public      | CL                                                                       |
| `set_filter_only_tagged` | `ftl::cmd::filter_to_tagged`          | `cmd` `filt` | public      | CL                                                                       |
| `load_filter`            | `ftl::filt::load_external`            | `filt`       | public      | CL                                                                       |
| `clear_filters`          | `ftl::cmd::clear_all_filters`         | `cmd` `filt` | public      | CL                                                                       |

---

## 5. Selection / Tag Functions

| v1 name                  | v2 name                                        | module            | visibility  | rationale                                               |
| ---------                | ---------                                      | --------          | ----------- | -----------                                             |
| `selection`              | `ftl::sel::resolve_current`                    | `sel`             | public      | CL; "selection" is a noun                               |
| `tags_clear`             | `ftl::sel::clear_all`                          | `sel`             | public      | CL                                                      |
| `tags_size`              | `ftl::sel::adjust_total_size`                  | `sel`             | public      | CL; **v1 had name collision**                           |
| `tags_head`              | `ftl::sel::format_header_summary`              | `sel`             | public      | CL; "tags_head" = "tags header"                         |
| `tags_unset`             | `ftl::sel::unset_by_class`                     | `sel`             | public      | CL; unsets all tags with a given class glyph            |
| `tag_flip`               | `ftl::sel::flip`                               | `sel`             | public      | CL                                                      |
| `tag_set`                | `ftl::sel::set`                                | `sel`             | public      | CL                                                      |
| `tag_unset`              | `ftl::sel::unset`                              | `sel`             | public      | CL                                                      |
| `tag_get`                | `ftl::sel::get_by_class`                       | `sel`             | public      | CL; gets tags matching a class into a nameref           |
| `tag_check`              | `ftl::sel::validate_existence`                 | `sel`             | public      | CL; "tag_check" validates that tagged files still exist |
| `tag_class`              | `ftl::sel::prompt_for_class`                   | `sel`             | public      | CL                                                      |
| `tag_ntags`              | `ftl::sel::build_class_index`                  | `sel`             | public      | CL; "tag_ntags" builds the inverted index `ntags`       |
| `tag_fzf`                | `ftl::sel::fzf_tag_or_untag`                   | `sel`             | public      | CL                                                      |
| `tag_go`                 | `ftl::sel::goto_by_index`                      | `sel`             | public      | CL                                                      |
| `tag_synch`              | `ftl::sel::sync_from_other_pane`               | `sel`             | public      | CL                                                      |
| `do_tag_synch`           | `_ftl::sel::apply_synced_tags`                 | `sel`             | private     | CL                                                      |
| `sel_read`               | `ftl::sel::load_from_file`                     | `sel`             | public      | CL                                                      |
| `tag_copy`               | `ftl::cmd::copy_selection_here`                | `cmd` `sel`       | public      | CL; move to cmd module                                  |
| `tag_move`               | `ftl::cmd::move_selection_here`                | `cmd` `sel`       | public      | CL                                                      |
| `tag_copy_dest`          | `ftl::cmd::copy_to_preset`                     | `cmd` `sel`       | public      | CL                                                      |
| `tag_move_dest`          | `ftl::cmd::move_to_preset`                     | `cmd` `sel`       | public      | CL                                                      |
| `tag_move_fzf`           | `ftl::cmd::move_via_fzf`                       | `cmd` `sel`       | public      | CL                                                      |
| `tag_move_fzf_sd`        | `ftl::cmd::move_to_subdir_via_fzf`             | `cmd` `sel`       | public      | CL                                                      |
| `tag_copy_to_tab`        | `ftl::cmd::copy_to_other_tab`                  | `cmd` `sel` `tab` | public      | CL                                                      |
| `tag_move_to_tab`        | `ftl::cmd::move_to_other_tab`                  | `cmd` `sel` `tab` | public      | CL                                                      |
| `tag_new_tab`            | `ftl::cmd::create_tab_for_move`                | `cmd` `tab`       | public      | CL; **name collision** with config var `tag_new_tab`    |
| `cp_mv_tags`             | `_ftl::cmd::copy_or_move_with_tags`            | `cmd`             | private     | CL                                                      |
| `cp_mv`                  | `_ftl::cmd::copy_or_move`                      | `cmd`             | private     | CL                                                      |
| `cp_do`                  | `_ftl::cmd::do_copy`                           | `cmd`             | private     | CL                                                      |
| `mv_do`                  | `_ftl::cmd::do_move`                           | `cmd`             | private     | CL                                                      |
| `selection_class_c`      | `_ftl::cmd::select_class_with_count`           | `cmd` `sel`       | private     | CL                                                      |
| `selection_class_n`      | `_ftl::cmd::toggle_class`                      | `cmd` `sel`       | private     | CL                                                      |
| `selection_class_1`      | `ftl::cmd::select_class_1`                     | `cmd` `sel`       | public      | NS                                                      |
| `selection_class_2`      | `ftl::cmd::select_class_2`                     | `cmd` `sel`       | public      | NS                                                      |
| `selection_class_3`      | `ftl::cmd::select_class_3`                     | `cmd` `sel`       | public      | NS                                                      |
| `selection_class_4`      | `ftl::cmd::select_class_4`                     | `cmd` `sel`       | public      | NS                                                      |
| `selection_flip_down`    | `ftl::cmd::flip_down`                          | `cmd` `sel`       | public      | CL                                                      |
| `selection_flip_up`      | `ftl::cmd::flip_up`                            | `cmd` `sel`       | public      | CL                                                      |
| `selection_ext`          | `ftl::cmd::select_same_extension`              | `cmd` `sel`       | public      | CL                                                      |
| `selection_ext_all`      | `ftl::cmd::select_same_extension_recursive`    | `cmd` `sel`       | public      | CL                                                      |
| `selection_ext_fzf`      | `ftl::cmd::select_extension_via_fzf`           | `cmd` `sel`       | public      | CL                                                      |
| `selection_ext_all_fzf`  | `ftl::cmd::select_extension_recursive_via_fzf` | `cmd` `sel`       | public      | CL                                                      |
| `selection_fzf`          | `ftl::cmd::select_via_fzf`                     | `cmd` `sel`       | public      | CL                                                      |
| `selection_fzf_all`      | `ftl::cmd::select_recursive_via_fzf`           | `cmd` `sel`       | public      | CL                                                      |
| `selection_goto`         | `ftl::cmd::goto_selection_via_fzf`             | `cmd` `sel`       | public      | CL                                                      |
| `selection_merge`        | `ftl::cmd::merge_from_panes`                   | `cmd` `sel`       | public      | CL                                                      |
| `selection_merge_all`    | `ftl::cmd::merge_all_panes`                    | `cmd` `sel`       | public      | CL                                                      |
| `selection_untag_all`    | `ftl::cmd::untag_all`                          | `cmd` `sel`       | public      | CL                                                      |
| `selection_untag_fzf`    | `ftl::cmd::untag_via_fzf`                      | `cmd` `sel`       | public      | CL                                                      |
| `select_all`             | `ftl::cmd::select_all`                         | `cmd` `sel`       | public      | NS                                                      |
| `select_all_files`       | `ftl::cmd::select_all_files`                   | `cmd` `sel`       | public      | NS                                                      |
| `select_all_directories` | `ftl::cmd::select_all_directories`             | `cmd` `sel`       | public      | NS                                                      |
| `image_select`           | `ftl::cmd::select_images_via_sxiv`             | `cmd` `sel`       | public      | CL                                                      |
| `image_select_rec`       | `ftl::cmd::select_images_recursive_via_sxiv`   | `cmd` `sel`       | public      | CL                                                      |
| `goto_next_tag`          | `ftl::cmd::goto_next_selected`                 | `cmd` `sel`       | public      | CL                                                      |
| `goto_prev_tag`          | `ftl::cmd::goto_prev_selected`                 | `cmd` `sel`       | public      | CL                                                      |
| `copy`                   | `ftl::cmd::copy_to_prompted`                   | `cmd`             | public      | CL; "copy" is too generic                               |
| `copy_clipboard`         | `ftl::cmd::copy_paths_to_clipboard`            | `cmd`             | public      | CL                                                      |
| `add_selection_to_file`  | `ftl::cmd::append_selection_to_file`           | `cmd` `sel`       | public      | CL                                                      |

---

## 6. Tab Functions

| v1 name              | v2 name                            | module      | visibility  | rationale                                 |
| ---------            | ---------                          | --------    | ----------- | -----------                               |
| `tab_setup`          | `ftl::tab::init_defaults`          | `tab`       | public      | CL                                        |
| `tab_close`          | `ftl::cmd::close_tab`              | `cmd` `tab` | public      | CL; move to cmd (user-facing)             |
| `tab_new`            | `ftl::cmd::new_tab`                | `cmd` `tab` | public      | CL                                        |
| `tab_next`           | `ftl::cmd::next_tab`               | `cmd` `tab` | public      | CL                                        |
| `tab_prev`           | `ftl::cmd::prev_tab`               | `cmd` `tab` | public      | CL                                        |
| `tab_goto`           | `ftl::cmd::goto_tab`               | `cmd` `tab` | public      | CL                                        |
| `tab_read`           | `ftl::tab::load_from_file`         | `tab`       | public      | CL; used by `-t` option                   |
| `_tab_new`           | `_ftl::tab::create`                | `tab`       | private     | CL; the internal creator (no cdir)        |
| `_tab_next`          | `_ftl::tab::advance_index`         | `tab`       | private     | CL                                        |
| `_tab_prev`          | `_ftl::tab::retreat_index`         | `tab`       | private     | CL                                        |
| `_tab_read`          | `_ftl::tab::read_one_entry`        | `tab`       | private     | CL                                        |
| `_tab_index`         | `_ftl::tab::index_directory`       | `tab`       | private     | CL; builds the entry-index cache for `-t` |
| `other_tab_dir`      | `_ftl::tab::find_other_tab_dir`    | `tab`       | private     | CL                                        |
| `pick_tab_dir`       | `_ftl::tab::pick_tab_via_fzf`      | `tab`       | private     | CL                                        |
| `pick_other_tab_dir` | `_ftl::tab::pick_single_other_tab` | `tab`       | private     | CL                                        |

---

## 7. Pane & Tmux Functions

| v1 name           | v2 name                                | module       | visibility  | rationale                                                    |
| ---------         | ---------                              | --------     | ----------- | -----------                                                  |
| `pid_2_pane`      | `ftl::pane::pid_to_id`                 | `pane`       | public      | CL; "2" → "to"                                               |
| `texists`         | `ftl::pane::window_exists`             | `pane`       | public      | CL; "texists" = "tmux exists"                                |
| `tsnew`           | `_ftl::pane::ensure_session`           | `pane`       | private     | CL; "tsnew" = "tmux session new"                             |
| `tsc`             | `ftl::pane::count_bg_windows`          | `pane`       | public      | CL; "tsc" = "tmux session count"                             |
| `tscommand`       | `ftl::pane::run_in_bg_window`          | `pane`       | public      | CL; "tscommand" = "tmux session command"                     |
| `tsucommand`      | `ftl::pane::run_in_user_session`       | `pane`       | public      | CL                                                           |
| `tsplit`          | `ftl::pane::split`                     | `pane`       | public      | CL; "tsplit" = "tmux split"                                  |
| `tsplitf`         | `_ftl::pane::split_with_fixed_preview` | `pane`       | private     | CL; "tsplitf" = "tmux split fixed"                           |
| `ctsplit`         | `ftl::pane::split_or_respawn`          | `pane`       | public      | CL; "ctsplit" = "clear then split" — respawns if pane exists |
| `psplit`          | `ftl::pane::split_for_preview`         | `pane`       | public      | CL; "psplit" = "preview split"                               |
| `tselectp`        | `ftl::pane::select`                    | `pane`       | public      | CL; "tselectp" = "tmux select pane"                          |
| `tbcolor`         | `ftl::pane::set_border_colors`         | `pane`       | public      | CL                                                           |
| `pane_extra`      | `ftl::cmd::spawn_extra_pane`           | `cmd` `pane` | public      | CL                                                           |
| `pane_ftl`        | `_ftl::cmd::spawn_ftl_pane`            | `cmd` `pane` | private     | CL                                                           |
| `pane_close`      | `ftl::cmd::close_pane`                 | `cmd` `pane` | public      | CL                                                           |
| `pane_next`       | `_ftl::pane::find_next_pane`           | `pane`       | private     | CL                                                           |
| `pane_read`       | `ftl::pane::read_child_list`           | `pane`       | public      | CL; reads `$pfs/panes`                                       |
| `pane_send`       | `ftl::pane::send_to_all_children`      | `pane`       | public      | CL                                                           |
| `pane_go_next`    | `ftl::cmd::goto_next_pane`             | `cmd` `pane` | public      | CL                                                           |
| `pane_left`       | `ftl::cmd::pane_left`                  | `cmd` `pane` | public      | NS                                                           |
| `pane_right`      | `ftl::cmd::pane_right`                 | `cmd` `pane` | public      | NS                                                           |
| `pane_down`       | `ftl::cmd::pane_down`                  | `cmd` `pane` | public      | NS                                                           |
| `pane_L`          | `ftl::cmd::pane_left_keep_focus`       | `cmd` `pane` | public      | CL; "L" → "left_keep_focus"                                  |
| `pane_R`          | `ftl::cmd::pane_right_keep_focus`      | `cmd` `pane` | public      | CL                                                           |
| `select_myp`      | `_ftl::pane::select_self_after_delay`  | `pane`       | private     | CL; "myp" = "my pane"                                        |
| `SIG_PANE`        | `ftl::ipc::handle_pane_focus`          | `ipc`        | public      | CL; move to IPC module                                       |
| `SIG_REMOTE`      | `ftl::ipc::handle_preview_request`     | `ipc`        | public      | CL                                                           |
| `SIG_REFRESH`     | `ftl::ipc::handle_refresh`             | `ipc`        | public      | CL                                                           |
| `SIG_SYNCH_SHELL` | `ftl::ipc::handle_shell_synch`         | `ipc`        | public      | CL                                                           |

---

## 8. Preview Functions

| v1 name            | v2 name                               | module       | visibility  | rationale                            |
| ---------          | ---------                             | --------     | ----------- | -----------                          |
| `preview`          | `ftl::prev::dispatch`                 | `prev`       | public      | CL; "preview" is too generic         |
| `prev_synch`       | `ftl::prev::sync_and_dispatch`        | `prev`       | public      | CL                                   |
| `tcpreview`        | `ftl::prev::clear`                    | `prev`       | public      | CL; "tcpreview" = "clear preview"    |
| `tcpreview2`       | `_ftl::prev::clear_fixed`             | `prev`       | private     | CL                                   |
| `vipreview`        | `ftl::prev::show_in_vim`              | `prev`       | public      | CL; "vipreview" = "vim preview"      |
| `pw3image`         | `ftl::prev::show_image`               | `prev`       | public      | CL; "pw3image" = "preview w3m image" |
| `preview_pane`     | `ftl::cmd::toggle_preview_pane`       | `cmd` `prev` | public      | CL                                   |
| `preview_pane2`    | `ftl::cmd::toggle_fixed_preview`      | `cmd` `prev` | public      | CL                                   |
| `preview_size`     | `ftl::cmd::cycle_preview_size`        | `cmd` `prev` | public      | CL                                   |
| `preview_dir_only` | `ftl::cmd::toggle_dirs_only_preview`  | `cmd` `prev` | public      | CL                                   |
| `preview_ext_ign`  | `ftl::cmd::toggle_ext_preview`        | `cmd` `prev` | public      | CL; "ign" → "ignore" → "toggle"      |
| `preview_image`    | `ftl::cmd::toggle_image_preview`      | `cmd` `prev` | public      | CL                                   |
| `preview_refresh`  | `ftl::cmd::refresh_preview`           | `cmd` `prev` | public      | CL                                   |
| `preview_tail`     | `ftl::cmd::toggle_preview_tail`       | `cmd` `prev` | public      | CL                                   |
| `preview_lock`     | `ftl::cmd::lock_preview`              | `cmd` `prev` | public      | CL                                   |
| `preview_lock_clr` | `ftl::cmd::unlock_preview`            | `cmd` `prev` | public      | CL                                   |
| `preview_with`     | `ftl::cmd::preview_with_command`      | `cmd` `prev` | public      | CL                                   |
| `preview_show`     | `ftl::cmd::show_in_background_player` | `cmd` `prev` | public      | CL                                   |
| `preview_show_fzf` | `ftl::cmd::show_via_fzf_viewer`       | `cmd` `prev` | public      | CL                                   |
| `preview_queue`    | `ftl::cmd::queue_to_player`           | `cmd` `prev` | public      | CL                                   |
| `preview_down`     | `ftl::cmd::scroll_preview_down`       | `cmd` `prev` | public      | CL                                   |
| `preview_up`       | `ftl::cmd::scroll_preview_up`         | `cmd` `prev` | public      | CL                                   |
| `preview_down2`    | `ftl::cmd::scroll_fixed_preview_down` | `cmd` `prev` | public      | CL                                   |
| `preview_up2`      | `ftl::cmd::scroll_fixed_preview_up`   | `cmd` `prev` | public      | CL                                   |
| `preview_left`     | `ftl::cmd::send_preview_left`         | `cmd` `prev` | public      | CL                                   |
| `preview_right`    | `ftl::cmd::send_preview_right`        | `cmd` `prev` | public      | CL                                   |
| `preview_m1`       | `ftl::cmd::set_preview_mode_1`        | `cmd` `prev` | public      | CL                                   |
| `preview_m2`       | `ftl::cmd::set_preview_mode_2`        | `cmd` `prev` | public      | CL                                   |
| `preview_m3`       | `ftl::cmd::set_preview_mode_3`        | `cmd` `prev` | public      | CL                                   |
| `preview_m4`       | `ftl::cmd::set_preview_mode_4`        | `cmd` `prev` | public      | CL                                   |
| `preview_m5`       | `ftl::cmd::set_preview_mode_5`        | `cmd` `prev` | public      | CL                                   |
| `full_preview_m1`  | `ftl::cmd::set_full_preview_mode_1`   | `cmd` `prev` | public      | CL                                   |
| `full_preview_m2`  | `ftl::cmd::set_full_preview_mode_2`   | `cmd` `prev` | public      | CL                                   |
| `full_preview_m3`  | `ftl::cmd::set_full_preview_mode_3`   | `cmd` `prev` | public      | CL                                   |
| `full_preview_m4`  | `ftl::cmd::set_full_preview_mode_4`   | `cmd` `prev` | public      | CL                                   |
| `full_preview_m5`  | `ftl::cmd::set_full_preview_mode_5`   | `cmd` `prev` | public      | CL                                   |
| `external_mode1`   | `ftl::cmd::external_viewer_mode_1`    | `cmd` `prev` | public      | CL                                   |
| `external_mode2`   | `ftl::cmd::external_viewer_mode_2`    | `cmd` `prev` | public      | CL                                   |
| `external_mode3`   | `ftl::cmd::external_viewer_mode_3`    | `cmd` `prev` | public      | CL                                   |
| `image_zoom`       | `ftl::cmd::toggle_image_zoom`         | `cmd` `prev` | public      | CL                                   |

---

## 9. Etag Functions

| v1 name       | v2 name                        | module       | visibility  | rationale                                        |
| ---------     | ---------                      | --------     | ----------- | -----------                                      |
| `etag_dir`    | `ftl::etag::scan_directory`    | `etag`       | public      | CL; "etag_dir" scans the directory for etag data |
| `etag_tag`    | `ftl::etag::get_entry_tag`     | `etag`       | public      | CL; "etag_tag" gets the tag for one entry        |
| `etag_show`   | `ftl::cmd::toggle_etags`       | `cmd` `etag` | public      | CL                                               |
| `etag_select` | `ftl::cmd::select_etag_source` | `cmd` `etag` | public      | CL                                               |
| (new)         | `ftl::etag::register_source`   | `etag`       | public      | New registry function (v1 had no registry)       |
| (new)         | `ftl::etag::list_sources`      | `etag`       | public      | New — for `zT` selection                         |

---

## 10. Marks & History Functions

| v1 name           | v2 name                                | module             | visibility  | rationale                                       |
| ---------         | ---------                              | --------           | ----------- | -----------                                     |
| `mark`            | `ftl::cmd::set_mark`                   | `cmd` `mark`       | public      | CL                                              |
| `mark_go`         | `ftl::cmd::goto_mark`                  | `cmd` `mark`       | public      | CL                                              |
| `mark_go_tab`     | `ftl::cmd::goto_mark_new_tab`          | `cmd` `mark` `tab` | public      | CL                                              |
| `mark_fzf`        | `ftl::cmd::goto_mark_via_fzf`          | `cmd` `mark`       | public      | CL                                              |
| `gmark`           | `ftl::cmd::add_persistent_mark`        | `cmd` `mark`       | public      | CL; "gmark" = "global mark"                     |
| `gmark_fzf`       | `ftl::cmd::goto_persistent_via_fzf`    | `cmd` `mark`       | public      | CL                                              |
| `gmark_fzf_user`  | `ftl::mark::user_marks_provider`       | `mark`             | public      | CL; hook for user customization                 |
| `gmarks_clear`    | `ftl::cmd::clear_persistent_marks`     | `cmd` `mark`       | public      | CL                                              |
| `hist_save`       | `_ftl::mark::save_to_history`          | `mark`             | private     | CL                                              |
| `history_go`      | `ftl::cmd::goto_session_history`       | `cmd` `mark`       | public      | CL                                              |
| `ghistory`        | `ftl::cmd::goto_global_history`        | `cmd` `mark`       | public      | CL                                              |
| `ghistory_subdir` | `ftl::cmd::goto_global_history_subdir` | `cmd` `mark`       | public      | CL                                              |
| `ghistory_edit`   | `ftl::cmd::edit_global_history`        | `cmd` `mark`       | public      | CL                                              |
| `ghistory_clear`  | `ftl::cmd::clear_global_history`       | `cmd` `mark`       | public      | CL                                              |
| `dedup`           | `ftl::util::dedup_file`                | `util`             | public      | CL; "dedup" → "dedup_file" (operates on a file) |

---

## 11. Search Functions

| v1 name             | v2 name                                   | module      | visibility  | rationale                                      |
| ---------           | ---------                                 | --------    | ----------- | -----------                                    |
| `find_entry`        | `ftl::cmd::find_in_dir`                   | `cmd` `kbd` | public      | CL; "find_entry" is vague                      |
| `find_next`         | `ftl::cmd::find_next`                     | `cmd` `kbd` | public      | NS                                             |
| `find_previous`     | `ftl::cmd::find_previous`                 | `cmd` `kbd` | public      | NS                                             |
| `find_fzf`          | `ftl::cmd::find_via_fzf`                  | `cmd`       | public      | CL                                             |
| `find_fzf_all`      | `ftl::cmd::find_via_fzf_recursive`        | `cmd`       | public      | CL                                             |
| `find_fzf_dirs`     | `ftl::cmd::find_dirs_via_fzf`             | `cmd`       | public      | CL                                             |
| `find_frf`          | `ftl::cmd::find_via_frf`                  | `cmd`       | public      | CL; "frf" is the tool name                     |
| `find_frf_all`      | `ftl::cmd::find_via_frf_recursive`        | `cmd`       | public      | CL                                             |
| `image_go_sxiv`     | `ftl::cmd::goto_image_via_sxiv`           | `cmd`       | public      | CL                                             |
| `image_go_sxiv_rec` | `ftl::cmd::goto_image_via_sxiv_recursive` | `cmd`       | public      | CL                                             |
| `image_fzf`         | `ftl::cmd::goto_image_via_fzf`            | `cmd`       | public      | CL                                             |
| `follow_link`       | `ftl::cmd::follow_symlink`                | `cmd`       | public      | CL                                             |
| `open_rg`           | `ftl::cmd::rg_open_file`                  | `cmd`       | public      | CL                                             |
| `go_rg`             | `ftl::cmd::rg_goto_file`                  | `cmd`       | public      | CL                                             |
| `go_rg_one_match`   | `ftl::cmd::rg_goto_single_match`          | `cmd`       | public      | CL                                             |
| `go_rgl`            | `ftl::cmd::rg_edit_files`                 | `cmd`       | public      | CL; "rgl" = "rg list" — edit all matched files |
| `go_rl_args`        | `_ftl::cmd::build_vim_args_from_rg`       | `cmd`       | private     | CL                                             |
| `go_loop`           | `_ftl::cmd::process_search_results`       | `cmd`       | private     | CL; "go_loop" iterates fzf/rg results          |
| `fzf_in_tab`        | `_ftl::cmd::check_open_in_tab`            | `cmd` `tab` | private     | CL; checks if ctrl-t was pressed               |
| `fzf_go`            | `_ftl::cmd::goto_fzf_result`              | `cmd`       | private     | CL                                             |
| `rg_go`             | `_ftl::cmd::goto_rg_result`               | `cmd`       | private     | CL                                             |

---

## 12. Shell Integration Functions

| v1 name             | v2 name                                | module       | visibility  | rationale                                                        |
| ---------           | ---------                              | --------     | ----------- | -----------                                                      |
| `shell`             | `ftl::cmd::open_shell_pane`            | `cmd` `pane` | public      | CL                                                               |
| `shell_vertical`    | `ftl::cmd::open_vertical_shell_pane`   | `cmd` `pane` | public      | CL                                                               |
| `shell_pane`        | `_ftl::cmd::spawn_shell_pane`          | `cmd` `pane` | private     | CL                                                               |
| `shell_vpane`       | `_ftl::cmd::spawn_vertical_shell_pane` | `cmd` `pane` | private     | CL                                                               |
| `shell_files`       | `ftl::cmd::open_shell_with_files`      | `cmd` `pane` | public      | CL                                                               |
| `shell_send`        | `ftl::pane::send_to_shell`             | `pane`       | public      | CL                                                               |
| `shell_send_files`  | `ftl::cmd::send_files_to_shell`        | `cmd` `pane` | public      | CL                                                               |
| `shell_view`        | `ftl::cmd::view_session_shell`         | `cmd` `pane` | public      | CL                                                               |
| `shell_synch`       | `ftl::cmd::synch_shell_cwd`            | `cmd` `pane` | public      | CL                                                               |
| `shell_zoomed`      | `ftl::cmd::open_zoomed_shell`          | `cmd` `pane` | public      | CL                                                               |
| `shell_cmd_in_pane` | `ftl::cmd::run_command_in_pane`        | `cmd` `pane` | public      | CL                                                               |
| `quit_shell`        | `ftl::cmd::close_shell_pane`           | `cmd` `pane` | public      | CL                                                               |
| `shell_command`     | `ftl::cmd::dispatch_command`           | `cmd`        | public      | CL; "shell_command" is misleading — this dispatches `:` commands |
| `run_bash`          | `ftl::cmd::run_interactive_bash`       | `cmd`        | public      | CL                                                               |
| `shell_popup`       | `ftl::cmd::open_shell_popup`           | `cmd` `pane` | public      | CL                                                               |

---

## 13. File Operation Functions

| v1 name                  | v2 name                               | module   | visibility  | rationale                                     |
| ---------                | ---------                             | -------- | ----------- | -----------                                   |
| `enter`                  | `ftl::cmd::enter_entry`               | `cmd`    | public      | CL; "enter" is too generic                    |
| `move_left`              | `ftl::cmd::cd_to_parent`              | `cmd`    | public      | CL                                            |
| `move_right`             | `ftl::cmd::cd_into_entry`             | `cmd`    | public      | CL                                            |
| `move_up`                | `ftl::cmd::cursor_up`                 | `cmd`    | public      | CL                                            |
| `move_down`              | `ftl::cmd::cursor_down`               | `cmd`    | public      | CL                                            |
| `move_left_arrow`        | `ftl::cmd::cursor_left_arrow`         | `cmd`    | public      | NS (alias)                                    |
| `move_right_arrow`       | `ftl::cmd::cursor_right_arrow`        | `cmd`    | public      | NS (alias)                                    |
| `move_up_arrow`          | `ftl::cmd::cursor_up_arrow`           | `cmd`    | public      | NS (alias)                                    |
| `move_down_arrow`        | `ftl::cmd::cursor_down_arrow`         | `cmd`    | public      | NS (alias)                                    |
| `move`                   | `_ftl::list::move_cursor`             | `list`   | private     | CL; "move" is too generic                     |
| `move_page_up`           | `ftl::cmd::page_up`                   | `cmd`    | public      | CL                                            |
| `move_page_down`         | `ftl::cmd::page_down`                 | `cmd`    | public      | CL                                            |
| `move_up_step`           | `ftl::cmd::cursor_up_step`            | `cmd`    | public      | CL                                            |
| `move_down_step`         | `ftl::cmd::cursor_down_step`          | `cmd`    | public      | CL                                            |
| `move_percent`           | `ftl::cmd::jump_by_percent`           | `cmd`    | public      | CL                                            |
| `top_file_bottom`        | `ftl::cmd::cycle_top_file_bottom`     | `cmd`    | public      | CL                                            |
| `goto_first_directory`   | `ftl::cmd::goto_first_directory`      | `cmd`    | public      | NS                                            |
| `goto_first_file`        | `ftl::cmd::goto_first_file`           | `cmd`    | public      | NS                                            |
| `goto_last_file`         | `ftl::cmd::goto_last_file`            | `cmd`    | public      | NS                                            |
| `goto_high_file`         | `ftl::cmd::goto_top_of_window`        | `cmd`    | public      | CL; "high_file" → "top_of_window"             |
| `goto_low_file`          | `ftl::cmd::goto_bottom_of_window`     | `cmd`    | public      | CL                                            |
| `goto_entry`             | `ftl::cmd::goto_by_index`             | `cmd`    | public      | CL                                            |
| `goto_alt1`              | `ftl::cmd::goto_next_same_extension`  | `cmd`    | public      | CL; "alt1" is opaque                          |
| `goto_alt2`              | `ftl::cmd::goto_next_diff_extension`  | `cmd`    | public      | CL; "alt2" is opaque                          |
| `change_dir`             | `ftl::cmd::cd_prompt`                 | `cmd`    | public      | CL                                            |
| `create_file`            | `ftl::cmd::create_file`               | `cmd`    | public      | NS                                            |
| `create_dir`             | `ftl::cmd::create_dir_and_cd`         | `cmd`    | public      | CL                                            |
| `create_dir_no_cd`       | `ftl::cmd::create_dir`                | `cmd`    | public      | CL                                            |
| `create_bulk`            | `ftl::cmd::create_bulk`               | `cmd`    | public      | NS                                            |
| `create_bulk_files`      | `_ftl::cmd::create_bulk_files_impl`   | `cmd`    | private     | CL                                            |
| `delete_selection`       | `ftl::cmd::delete_selection`          | `cmd`    | public      | NS                                            |
| `delete`                 | `_ftl::cmd::dispatch_delete`          | `cmd`    | private     | CL; "delete" dispatches based on prompt reply |
| `delete_cur`             | `_ftl::cmd::delete_current`           | `cmd`    | private     | CL                                            |
| `delete_tag`             | `_ftl::cmd::delete_tagged`            | `cmd`    | private     | CL                                            |
| `rename`                 | `ftl::cmd::rename_selection`          | `cmd`    | public      | CL                                            |
| `link`                   | `ftl::cmd::symlink_selection`         | `cmd`    | public      | CL                                            |
| `copy`                   | `ftl::cmd::copy_to_prompted`          | `cmd`    | public      | CL                                            |
| `chmod_ar`               | `ftl::cmd::chmod_toggle_read`         | `cmd`    | public      | CL; "ar" → "toggle_read"                      |
| `chmod_aw`               | `ftl::cmd::chmod_toggle_write`        | `cmd`    | public      | CL                                            |
| `chmod_ax`               | `ftl::cmd::chmod_toggle_exec`         | `cmd`    | public      | CL                                            |
| `chmod_dialog`           | `ftl::cmd::chmod_via_scim`            | `cmd`    | public      | CL                                            |
| `chmod_dialog_one`       | `ftl::cmd::chmod_via_whiptail`        | `cmd`    | public      | CL                                            |
| `hexview`                | `ftl::cmd::hex_view`                  | `cmd`    | public      | CL                                            |
| `hexedit`                | `ftl::cmd::hex_edit`                  | `cmd`    | public      | CL                                            |
| `vim_edit`               | `ftl::cmd::edit_in_vim`               | `cmd`    | public      | CL                                            |
| `vim_edit_window`        | `ftl::cmd::edit_in_vim_window`        | `cmd`    | public      | CL                                            |
| `vim_edit_shared_window` | `ftl::cmd::edit_in_shared_vim_window` | `cmd`    | public      | CL                                            |
| `vim_tabe_shared_window` | `_ftl::cmd::open_files_in_shared_vim` | `cmd`    | private     | CL                                            |
| `terminal_cat`           | `ftl::cmd::cat_in_terminal`           | `cmd`    | public      | CL                                            |
| `edit`                   | `ftl::cmd::edit_current`              | `cmd`    | public      | CL; "edit" is too generic                     |
| `editor_detach`          | `ftl::cmd::detach_editor_preview`     | `cmd`    | public      | CL                                            |

---

## 14. Command Prompt Functions

| v1 name            | v2 name                              | module   | visibility  | rationale                                                        |
| ---------          | ---------                            | -------- | ----------- | -----------                                                      |
| `command_prompt`   | `ftl::cmd::open_command_prompt`      | `cmd`    | public      | CL                                                               |
| `gcn`              | `_ftl::cmd::build_command_name_list` | `cmd`    | private     | CL; "gcn" = "generate command names"                             |
| `run_user_command` | `ftl::cmd::run_user_command`         | `cmd`    | public      | CL                                                               |
| `load_sel`         | `ftl::sel::load_from_file`           | `sel`    | public      | CL (same as `sel_read`) — **merge**                              |
| `setup_finfo`      | `ftl::state::serialize_info`         | `state`  | public      | CL; "setup_finfo" = "setup finfo file"                           |
| `ftl_env`          | `ftl::state::render_child_env`       | `state`  | public      | CL; "ftl_env" renders env args for tmux                          |
| `cdfl`             | `ftl::state::emit_selection_to_fd3`  | `state`  | public      | CL; "cdfl" is opaque — writes selection to fd 3 for `ftll`/`cdf` |
| `q_all`            | `_ftl::cmd::quote_all_entries`       | `cmd`    | private     | CL                                                               |
| `q_dirs`           | `_ftl::cmd::quote_all_dirs`          | `cmd`    | private     | CL                                                               |
| `q_files`          | `_ftl::cmd::quote_all_files`         | `cmd`    | private     | CL                                                               |
| `q_sel`            | `_ftl::cmd::quote_selection`         | `cmd`    | private     | CL                                                               |
| `fsh`              | `ftl::cmd::run_in_shell_window`      | `cmd`    | public      | CL; "fsh" is the command name, not the action                    |
| `path_full`        | `ftl::util::resolve_full_path`       | `util`   | public      | CL                                                               |
| `path`             | `ftl::util::parse_path`              | `util`   | public      | CL; "path" is too generic                                        |
| `path_none`        | `ftl::util::clear_path_vars`         | `util`   | public      | CL                                                               |

---

## 15. State & IPC Functions

| v1 name             | v2 name                               | module       | visibility  | rationale                                               |
| ---------           | ---------                             | --------     | ----------- | -----------                                             |
| `save_state`        | `ftl::state::save`                    | `state`      | public      | CL                                                      |
| (new)               | `ftl::state::load`                    | `state`      | public      | New (v1 had `prev_synch` do double duty)                |
| `mkapipe`           | `ftl::util::create_fifos`             | `util`       | public      | CL; "mkapipe" = "make a pipe"                           |
| `quit`              | `ftl::cmd::quit`                      | `cmd`        | public      | CL                                                      |
| `quit2`             | `_ftl::cmd::quit_cleanup`             | `cmd`        | private     | CL; "quit2" is the cleanup phase                        |
| `quit_ftl`          | `ftl::cmd::quit_tab_or_pane_or_ftl`   | `cmd`        | public      | CL; "quit_ftl" is misleading — it's the smart quit      |
| `quit_all`          | `ftl::cmd::quit_all`                  | `cmd`        | public      | NS                                                      |
| `quit_keep_shell`   | `ftl::cmd::quit_keep_shell`           | `cmd`        | public      | NS                                                      |
| `quit_keep_preview` | `ftl::cmd::quit_keep_preview`         | `cmd`        | public      | NS                                                      |
| `qshell`            | `_ftl::cmd::check_shells_before_quit` | `cmd`        | private     | CL; "qshell" = "quit shell check"                       |
| `inotify_s`         | `ftl::pane::start_file_watcher`       | `pane`       | public      | CL; "inotify_s" = "inotify start"                       |
| `inotify_`          | `_ftl::pane::file_watcher_loop`       | `pane`       | private     | CL; trailing underscore is bad style                    |
| `inotify_w`         | `_ftl::pane::run_inotifywait`         | `pane`       | private     | CL; "inotify_w" = "inotify wait"                        |
| `inotify_k`         | `ftl::pane::stop_file_watcher`        | `pane`       | public      | CL; "inotify_k" = "inotify kill"                        |
| `player_k`          | `ftl::cmd::kill_media_player`         | `cmd` `prev` | public      | CL; "player_k" = "player kill"                          |
| `player_kill`       | `ftl::cmd::kill_media_player`         | `cmd` `prev` | public      | **Duplicate** of `player_k` — merge                     |
| `run_maxed`         | `ftl::util::run_maximized`            | `util`       | public      | CL; "run_maxed" runs a command, minimizes ftl, restores |
| `is_bin`            | `ftl::util::is_binary_file`           | `util`       | public      | CL                                                      |
| `mime_get`          | `ftl::list::get_mime_type`            | `list`       | public      | CL                                                      |
| `mime_cache`        | `_ftl::list::cache_mime_types`        | `list`       | private     | CL                                                      |
| `thumb`             | `ftl::gen::thumb_path`                | `gen`        | public      | CL; "thumb" computes the path, doesn't generate         |

---

## 16. Utility Functions

| v1 name            | v2 name                        | module   | visibility  | rationale                                                                   |
| ---------          | ---------                      | -------- | ----------- | -----------                                                                 |
| `refresh`          | `ftl::util::refresh_screen`    | `util`   | public      | CL                                                                          |
| `clear_list`       | `_ftl::list::clear_below`      | `list`   | private     | (see §3)                                                                    |
| `file_size`        | `ftl::util::format_size_human` | `util`   | public      | (see §3)                                                                    |
| `stacktrace`       | `ftl::util::stacktrace`        | `util`   | public      | NS                                                                          |
| `log`              | `ftl::log::log_caller`         | `log`    | public      | CL; v1's `log` logs BASH_SOURCE — rename to disambiguate from `ftl::log::*` |
| `numfmt` (wrapper) | `ftl::util::format_size`       | `util`   | public      | (see §1)                                                                    |

---

## 17. Plugin Functions — Filters

Each filter plugin defines `ftl_filter`. v2 requires namespaced functions.

| v1 name (in every filter)      | v2 name                           | module        | visibility  | rationale                                                                           |
| ---------------------------    | ---------                         | --------      | ----------- | -----------                                                                         |
| `ftl_filter`                   | `ftl::plugin::<name>::filter`     | `plug` `filt` | plugin      | NS; **v1 had name collision** — every filter defined `ftl_filter`, last-loaded wins |
| (new)                          | `ftl::plugin::<name>::load`       | `plug` `filt` | plugin      | New explicit lifecycle (v1 used `[[ "$1" == load ]]`)                               |
| (new)                          | `ftl::plugin::<name>::reset`      | `plug` `filt` | plugin      | New explicit lifecycle (v1 used `[[ "$1" == reset ]]`)                              |
| `ftl_sort` (in sort plugins)   | `ftl::plugin::<name>::sort`       | `plug` `filt` | plugin      | NS                                                                                  |
| `sort_glyph` (in sort plugins) | `ftl::plugin::<name>::sort_glyph` | `plug` `filt` | plugin      | NS                                                                                  |
| `bash_filter_keep_imp`         | `ftl::plugin::by_bash_keep::impl` | `plug` `filt` | plugin      | CL; "imp" → "impl"                                                                  |
| `bash_filter_hide_imp`         | `ftl::plugin::by_bash_hide::impl` | `plug` `filt` | plugin      | CL                                                                                  |

---

## 18. Plugin Functions — Etags

Each etag plugin defines `etag_dir` and `etag_tag`. v2 requires namespaced functions.

| v1 name (in every etag)   | v2 name                               | module        | visibility  | rationale                     |
| ------------------------- | ---------                             | --------      | ----------- | -----------                   |
| `etag_dir`                | `ftl::plugin::<name>::scan_directory` | `plug` `etag` | plugin      | NS; **v1 had name collision** |
| `etag_tag`                | `ftl::plugin::<name>::get_entry_tag`  | `plug` `etag` | plugin      | NS                            |

Note: in v1, the etag plugins are *sourced* (replacing the previous `etag_dir`/`etag_tag`). v2 uses a registry — all etag plugins coexist, and `ftl::etag::scan_directory` dispatches to the active one.

---

## 19. Plugin Functions — Viewers

v1's `viewers/core` defines ~40 `p*` and `ext_*` functions. v2 moves these to a viewer registry with namespaced names.

### 19.1 Dispatch functions

| v1 name         | v2 name                               | module        | visibility  | rationale                                                 |
| ---------       | ---------                             | --------      | ----------- | -----------                                               |
| `pviewers`      | `ftl::prev::show_internal`            | `prev`        | public      | CL; "pviewers" = "preview viewers" — the in-pane dispatch |
| `ext_viewers`   | `ftl::prev::show_external`            | `prev`        | public      | CL                                                        |
| `user_pviewers` | `ftl::plugin::user::internal_preview` | `plug` `prev` | plugin      | CL; user override hook                                    |
| `user_eviewers` | `ftl::plugin::user::external_preview` | `plug` `prev` | plugin      | CL                                                        |

### 19.2 Per-type preview functions (in-pane, `p*`)

| v1 name      | v2 name                                            | module        | rationale                                 |
| ---------    | ---------                                          | --------      | -----------                               |
| `pdir`       | `ftl::plugin::core::preview_directory`             | `plug` `view` | CL                                        |
| `pdir_def`   | `ftl::plugin::core::preview_directory_default`     | `plug` `view` | CL                                        |
| `pdir_ftl`   | `ftl::plugin::core::preview_directory_via_ftl`     | `plug` `view` | CL                                        |
| `pdir_du`    | `ftl::plugin::core::preview_directory_via_du`      | `plug` `view` | CL                                        |
| `pdir_ls`    | `ftl::plugin::core::preview_directory_via_ls`      | `plug` `view` | CL                                        |
| `pdir_rmd`   | `ftl::plugin::core::preview_directory_via_readme`  | `plug` `view` | CL                                        |
| `pdir_exa`   | `ftl::plugin::core::preview_directory_via_exa`     | `plug` `view` | CL                                        |
| `pdir_image` | `ftl::plugin::core::preview_directory_via_montage` | `plug` `view` | CL                                        |
| `pimage`     | `ftl::plugin::core::preview_image`                 | `plug` `view` | CL                                        |
| `psvg`       | `ftl::plugin::core::preview_svg`                   | `plug` `view` | CL                                        |
| `pgif`       | `ftl::plugin::core::preview_gif`                   | `plug` `view` | CL                                        |
| `phtml`      | `ftl::plugin::core::preview_html`                  | `plug` `view` | CL                                        |
| `pmp3`       | `ftl::plugin::core::preview_mp3`                   | `plug` `view` | CL                                        |
| `pmedia`     | `ftl::plugin::core::preview_media`                 | `plug` `view` | CL                                        |
| `pmlive`     | `ftl::plugin::core::preview_media_live`            | `plug` `view` | CL                                        |
| `pmd`        | `ftl::plugin::core::preview_markdown`              | `plug` `view` | CL                                        |
| `pmd_1`      | `ftl::plugin::core::preview_markdown_mode_1`       | `plug` `view` | CL                                        |
| `pmd_2`      | `ftl::plugin::core::preview_markdown_mode_2`       | `plug` `view` | CL                                        |
| `pmd_3`      | `ftl::plugin::core::preview_markdown_mode_3`       | `plug` `view` | CL                                        |
| `pmd_def`    | `ftl::plugin::core::preview_markdown_default`      | `plug` `view` | CL                                        |
| `pmdd`       | `ftl::plugin::core::preview_markdown_dir`          | `plug` `view` | CL; "pmdd" = "pmd dir"                    |
| `ppdf`       | `ftl::plugin::core::preview_pdf`                   | `plug` `view` | CL                                        |
| `ppdfpng`    | `ftl::plugin::core::preview_pdf_as_png`            | `plug` `view` | CL                                        |
| `pepub`      | `ftl::plugin::core::preview_epub`                  | `plug` `view` | CL                                        |
| `pepubpng`   | `ftl::plugin::core::preview_epub_as_png`           | `plug` `view` | CL                                        |
| `pcbr`       | `ftl::plugin::core::preview_cbr`                   | `plug` `view` | CL                                        |
| `pcbz`       | `ftl::plugin::core::preview_cbz`                   | `plug` `view` | CL                                        |
| `pjson`      | `ftl::plugin::core::preview_json`                  | `plug` `view` | CL                                        |
| `pyaml`      | `ftl::plugin::core::preview_yaml`                  | `plug` `view` | CL                                        |
| `ptext`      | `ftl::plugin::core::preview_text`                  | `plug` `view` | CL                                        |
| `pansi`      | `ftl::plugin::core::preview_ansi_text`             | `plug` `view` | CL                                        |
| `pman`       | `ftl::plugin::core::preview_manpage`               | `plug` `view` | CL                                        |
| `pscim`      | `ftl::plugin::core::preview_scim`                  | `plug` `view` | CL                                        |
| `pasciio`    | `ftl::plugin::core::preview_asciio`                | `plug` `view` | CL                                        |
| `pstl`       | `ftl::plugin::core::preview_stl`                   | `plug` `view` | CL                                        |
| `pcomp`      | `ftl::plugin::core::preview_archive`               | `plug` `view` | CL; "pcomp" = "preview compressed"        |
| `_pcomp`     | `_ftl::plugin::core::preview_archive_impl`         | `plug` `view` | CL                                        |
| `ppipe`      | `ftl::plugin::core::preview_pipe`                  | `plug` `view` | CL                                        |
| `plock`      | `ftl::plugin::core::preview_locked`                | `plug` `view` | CL                                        |
| `ptype`      | `ftl::plugin::core::show_type_info`                | `plug` `view` | CL; fallback for unknown types            |
| `pignore`    | `ftl::plugin::core::show_ignored`                  | `plug` `view` | CL; fallback when extension is in pignore |

### 19.3 Per-type external viewer functions (`ext_*`)

| v1 name      | v2 name                                    | module        | rationale                 |
| ---------    | ---------                                  | --------      | -----------               |
| `ext_dir`    | `ftl::plugin::core::external_directory`    | `plug` `view` | CL                        |
| `ext_html`   | `ftl::plugin::core::external_html`         | `plug` `view` | CL                        |
| `ext_svg`    | `ftl::plugin::core::external_svg`          | `plug` `view` | CL                        |
| `ext_image`  | `ftl::plugin::core::external_image`        | `plug` `view` | CL                        |
| `ext_iall`   | `ftl::plugin::core::external_image_all`    | `plug` `view` | CL                        |
| `ext_ipng`   | `ftl::plugin::core::external_image_single` | `plug` `view` | CL                        |
| `ext_mp3`    | `ftl::plugin::core::external_mp3`          | `plug` `view` | CL                        |
| `ext_media`  | `ftl::plugin::core::external_media`        | `plug` `view` | CL                        |
| `ext_pdf`    | `ftl::plugin::core::external_pdf`          | `plug` `view` | CL                        |
| `ext_pdf_vi` | `ftl::plugin::core::external_pdf_as_text`  | `plug` `view` | CL; "vi" = "view as text" |
| `ext_epub`   | `ftl::plugin::core::external_epub`         | `plug` `view` | CL                        |
| `ext_text`   | `ftl::plugin::core::external_text`         | `plug` `view` | CL                        |
| `ext_json`   | `ftl::plugin::core::external_json`         | `plug` `view` | CL                        |
| `ext_scim`   | `ftl::plugin::core::external_scim`         | `plug` `view` | CL                        |
| `open_with`  | `ftl::plugin::core::open_with_dialog`      | `plug` `view` | CL                        |

---

## 20. Plugin Functions — Bindings

### 20.1 Leader / help

| v1 name                | v2 name                                 | module       | rationale   |
| ---------              | ---------                               | --------     | ----------- |
| `leader_help`          | `ftl::plugin::leader::show_help`        | `plug` `kbd` | CL          |
| `leader_help_reset`    | `ftl::plugin::leader::reset_help_index` | `plug` `kbd` | CL          |
| `leader_help_next`     | `ftl::plugin::leader::next_help`        | `plug` `kbd` | CL          |
| `leader_help_previous` | `ftl::plugin::leader::prev_help`        | `plug` `kbd` | CL          |

### 20.2 Leader_ftl (file utilities)

| v1 name             | v2 name                                      | module       | rationale   |
| ---------           | ---------                                    | --------     | ----------- |
| `compress`          | `ftl::plugin::file_utils::compress_tar_bz2`  | `plug` `cmd` | CL          |
| `decompress`        | `ftl::plugin::file_utils::decompress`        | `plug` `cmd` | NS          |
| `decompress_in_dir` | `ftl::plugin::file_utils::decompress_to_dir` | `plug` `cmd` | CL          |
| `gpg_encrypt`       | `ftl::plugin::file_utils::gpg_encrypt`       | `plug` `cmd` | NS          |
| `pass_encrypt`      | `ftl::plugin::file_utils::password_encrypt`  | `plug` `cmd` | CL          |
| `stat_file`         | `ftl::plugin::file_utils::show_stat`         | `plug` `cmd` | CL          |
| `image_optimize`    | `ftl::plugin::file_utils::optimize_image`    | `plug` `cmd` | CL          |
| `pdf_optimize`      | `ftl::plugin::file_utils::optimize_pdf`      | `plug` `cmd` | CL          |
| `video_optimize`    | `ftl::plugin::file_utils::optimize_video`    | `plug` `cmd` | CL          |
| `pdf2txt`           | `ftl::plugin::file_utils::pdf_to_text`       | `plug` `cmd` | CL          |
| `lint`              | `ftl::plugin::file_utils::lint_directory`    | `plug` `cmd` | CL          |
| `run_mutt`          | `ftl::plugin::file_utils::send_via_mutt`     | `plug` `cmd` | CL          |
| `shell_popup`       | `ftl::plugin::file_utils::open_shell_popup`  | `plug` `cmd` | CL          |
| `shred_command`     | `ftl::plugin::file_utils::shred_selection`   | `plug` `cmd` | CL          |

### 20.3 Leader_git

| v1 name      | v2 name                                | module        | rationale            |
| ---------    | ---------                              | --------      | -----------          |
| `git_etags`  | `ftl::plugin::git::show_etags`         | `plug` `etag` | CL                   |
| `git_tree`   | `ftl::plugin::git::show_tree_status`   | `plug` `cmd`  | CL                   |
| `git_diff`   | `ftl::plugin::git::diff_via_fgd`       | `plug` `cmd`  | CL; "fgd" = the tool |
| `git_diff2`  | `ftl::plugin::git::diff_with_fancy`    | `plug` `cmd`  | CL                   |
| `git_find`   | `ftl::plugin::git::find_changed_files` | `plug` `cmd`  | CL                   |
| `git_ignore` | `ftl::plugin::git::add_to_gitignore`   | `plug` `cmd`  | CL                   |
| `git_add`    | `ftl::plugin::git::add_selection`      | `plug` `cmd`  | CL                   |
| `git_fga`    | `ftl::plugin::git::add_via_forgit`     | `plug` `cmd`  | CL                   |

### 20.4 TMSU

| v1 name             | v2 name                               | module        | rationale   |
| ---------           | ---------                             | --------      | ----------- |
| `tmsu_preview`      | `ftl::plugin::tmsu::show_tags_table`  | `plug` `cmd`  | CL          |
| `tmsu_tag`          | `ftl::plugin::tmsu::tag_via_vim`      | `plug` `cmd`  | CL          |
| `tmsu_tag_fzf`      | `ftl::plugin::tmsu::tag_via_fzf`      | `plug` `cmd`  | CL          |
| `tmsu_tag_scim`     | `ftl::plugin::tmsu::tag_via_scim`     | `plug` `cmd`  | CL          |
| `tmsu_mount`        | `ftl::plugin::tmsu::mount_filesystem` | `plug` `cmd`  | CL          |
| `tmsu_filter`       | `ftl::plugin::tmsu::filter_by_tags`   | `plug` `filt` | CL          |
| `tmsu_filter_query` | `ftl::plugin::tmsu::filter_by_query`  | `plug` `filt` | CL          |
| `tmsu_goto`         | `ftl::plugin::tmsu::goto_via_fzf`     | `plug` `cmd`  | CL          |
| `tmsu_table2`       | `_ftl::plugin::tmsu::build_tag_table` | `plug` `cmd`  | CL          |

### 20.5 Virtual entries

| v1 name              | v2 name                                           | module        | rationale   |
| ---------            | ---------                                         | --------      | ----------- |
| `ventries_on`        | `ftl::plugin::virtual_entries::enable`            | `plug` `cmd`  | CL          |
| `ventries_off`       | `ftl::plugin::virtual_entries::disable`           | `plug` `cmd`  | CL          |
| `ventries_etag`      | `ftl::plugin::virtual_entries::show_etag`         | `plug` `etag` | CL          |
| `add_save_as`        | `ftl::plugin::virtual_entries::add_save_as_entry` | `plug` `cmd`  | CL          |
| `get_file_name`      | `_ftl::plugin::virtual_entries::prompt_for_name`  | `plug` `cmd`  | CL          |
| `ventry_save_as`     | `_ftl::plugin::virtual_entries::setup_save_as`    | `plug` `cmd`  | CL          |
| `virt_dirs_get`      | `ftl::plugin::virtual_entries::get_virtual_dirs`  | `plug` `list` | CL          |
| `virt_files_get`     | `ftl::plugin::virtual_entries::get_virtual_files` | `plug` `list` | CL          |
| `virt_dirs_save_as`  | `ftl::plugin::virtual_entries::get_save_as_dir`   | `plug` `list` | CL          |
| `virt_files_save_as` | `ftl::plugin::virtual_entries::get_save_as_file`  | `plug` `list` | CL          |
| `virt_color`         | `ftl::plugin::virtual_entries::colorize`          | `plug` `view` | CL          |
| `virt_prev`          | `ftl::plugin::virtual_entries::preview`           | `plug` `prev` | CL          |
| `virt_key`           | `ftl::plugin::virtual_entries::handle_key`        | `plug` `kbd`  | CL          |

### 20.6 fzf_pane_preview

| v1 name                | v2 name                                         | module        | rationale                         |
| ---------              | ---------                                       | --------      | -----------                       |
| `fzf_pane_preview`     | `ftl::plugin::fzf_pane_preview::find`           | `plug` `cmd`  | CL                                |
| `fzf_pane_preview_all` | `ftl::plugin::fzf_pane_preview::find_recursive` | `plug` `cmd`  | CL                                |
| `previewd`             | `_ftl::plugin::fzf_pane_preview::daemon`        | `plug` `cmd`  | CL; "previewd" = "preview daemon" |
| `pfzf`                 | `ftl::plugin::fzf_pane_preview::show`           | `plug` `prev` | CL                                |

### 20.7 fzf_search (experimental)

| v1 name              | v2 name                                   | module        | rationale   |
| ---------            | ---------                                 | --------      | ----------- |
| `show_fzf_view`      | `ftl::plugin::fzf_search::show`           | `plug` `cmd`  | CL          |
| `fzf_client`         | `ftl::plugin::fzf_search::handle_key`     | `plug` `kbd`  | CL          |
| `get_custom_entries` | `_ftl::plugin::fzf_search::fetch_results` | `plug` `list` | CL          |

### 20.8 via_bash

| v1 name            | v2 name                                | module        | rationale                     |
| ---------          | ---------                              | --------      | -----------                   |
| `bash_select`      | `ftl::plugin::via_bash::select`        | `plug` `sel`  | CL                            |
| `up_select`        | `ftl::plugin::via_bash::select_via_up` | `plug` `sel`  | CL; "up" = "ultimate plumber" |
| `bash_filter_keep` | `ftl::plugin::via_bash::filter_keep`   | `plug` `filt` | CL                            |
| `bash_filter_hide` | `ftl::plugin::via_bash::filter_hide`   | `plug` `filt` | CL                            |

### 20.9 type_handlers

| v1 name                     | v2 name                                     | module        | rationale                        |
| ---------                   | ---------                                   | --------      | -----------                      |
| `enter` (override)          | `ftl::plugin::type_handlers::enter`         | `plug` `cmd`  | NS; v1 overrode the core `enter` |
| `move_left` (override)      | `ftl::plugin::type_handlers::move_left`     | `plug` `cmd`  | NS                               |
| `mount_archive`             | `ftl::plugin::type_handlers::mount_archive` | `plug` `cmd`  | NS                               |
| `unmount_archives`          | `ftl::plugin::type_handlers::unmount_all`   | `plug` `cmd`  | CL                               |
| `exit_archive`              | `ftl::plugin::type_handlers::exit_archive`  | `plug` `cmd`  | NS                               |
| `ftl_event_quit` (override) | `ftl::plugin::type_handlers::on_quit`       | `plug` `boot` | CL                               |

### 20.10 file_diff / change_mode / to_other_tab / add_to_a_log

| v1 name                        | v2 name                                          | module       | rationale                                             |
| ---------                      | ---------                                        | --------     | -----------                                           |
| `file_diff`                    | `ftl::plugin::file_diff::diff_selection`         | `plug` `cmd` | CL                                                    |
| `chmod_dialog_one`             | `ftl::plugin::change_mode::chmod_one`            | `plug` `cmd` | CL                                                    |
| `other_tab_dir`                | `_ftl::plugin::to_other_tab::find_dest`          | `plug` `tab` | CL                                                    |
| `pick_tab_dir`                 | `_ftl::plugin::to_other_tab::pick_via_fzf`       | `plug` `tab` | CL                                                    |
| `pick_other_tab_dir`           | `_ftl::plugin::to_other_tab::pick_single`        | `plug` `tab` | CL                                                    |
| `tag_copy_to_tab`              | `ftl::plugin::to_other_tab::copy`                | `plug` `cmd` | CL                                                    |
| `tag_move_to_tab`              | `ftl::plugin::to_other_tab::move`                | `plug` `cmd` | CL                                                    |
| `tag_new_tab`                  | `ftl::plugin::to_other_tab::create_tab_for_move` | `plug` `tab` | CL; **name collision** with config var — disambiguate |
| `leader_add_to_a_log`          | `ftl::plugin::add_to_a_log::add`                 | `plug` `cmd` | CL                                                    |
| `leader_a_edit_leader_a_log`   | `ftl::plugin::add_to_a_log::edit`                | `plug` `cmd` | CL                                                    |
| `leader_a_add_to_log_and_edit` | `ftl::plugin::add_to_a_log::add_and_edit`        | `plug` `cmd` | CL                                                    |

---

## 21. Plugin Functions — Commands

| v1 name                    | v2 name                                      | module       | rationale   |
| ---------                  | ---------                                    | --------     | ----------- |
| `tree` (command)           | `ftl::plugin::cmd_tree::run`                 | `plug` `cmd` | NS          |
| `url` (command)            | `ftl::plugin::cmd_url::run`                  | `plug` `cmd` | NS          |
| `fma` (command)            | `ftl::plugin::cmd_fma::run`                  | `plug` `cmd` | NS          |
| `fmr` (command)            | `ftl::plugin::cmd_fmr::run`                  | `plug` `cmd` | NS          |
| `open_with` (command)      | `ftl::plugin::cmd_open_with::run`            | `plug` `cmd` | NS          |
| `etags` (command)          | `ftl::plugin::cmd_etags::run`                | `plug` `cmd` | NS          |
| `show_cmd_log` (command)   | `ftl::plugin::cmd_show_log::run`             | `plug` `cmd` | NS          |
| `reverse_date` (ftlrc_dir) | `ftl::plugin::ftlrc_dir_reverse_date::apply` | `plug` `cfg` | CL          |

---

## 22. Removed / Merged / Split Functions

### 22.1 Removed (replaced by better mechanisms)

| v1 function         | replacement                              | reason                                             |
| -------------       | -------------                            | --------                                           |
| `try`               | `ftl::log::wrap` + explicit error checks | v1's `try` swallows stderr and uses jarring popups |
| `try_error`         | `ftl::log::show_error_full`              | Properly named                                     |
| `try_errorp`        | `ftl::log::show_error_popup`             | Properly named                                     |
| `pdh`               | `ftl::log::debug`                        | Unified logging system                             |
| `pdhn`              | `ftl::log::debug` (with newline)         | Unified logging system                             |
| `numfmt` (override) | `ftl::util::format_size`                 | v1 overrode `numfmt` globally — dangerous          |
| `qshell`            | `_ftl::cmd::check_shells_before_quit`    | Properly named                                     |

### 22.2 Merged (v1 had duplicates)

| v1 functions               | v2 function                   | reason                                   |
| --------------             | -------------                 | --------                                 |
| `player_k` + `player_kill` | `ftl::cmd::kill_media_player` | Identical functions with different names |
| `sel_read` + `load_sel`    | `ftl::sel::load_from_file`    | Identical purpose                        |

### 22.3 Split (v1 had one function doing too much)

| v1 function             | v2 functions                                                                                         | reason                                         |
| --------------          | -------------                                                                                        | --------                                       |
| `ftl` (the entry point) | `ftl::boot::main` + `ftl::boot::init` + `ftl::boot::setup_traps` + `ftl::boot::validate_environment` |                                                |
| `get_key`               | `ftl::kbd::get_key` + `ftl::kbd::normalize_key`                                                      | The normalizer is now separately testable      |
| `key_command`           | `ftl::kbd::dispatch` + (sub-mode handlers via `ftl_kbd_submode_handler`)                             |                                                |
| `cview`                 | `_ftl::list::scan_and_render` + `ftl::list::change_dir`                                              | v1's `cview` did cd + scan + render all in one |
| `save_state`            | `ftl::state::save` + `ftl::state::save_selection`                                                    | Separate state-file from selection-file        |

### 22.4 Name collisions fixed

| v1 collision                                               | v2 resolution                                                                                       |
| --------------                                             | ---------------                                                                                     |
| `tags_size` (variable) vs `tags_size` (function)           | Variable: `ftl_selection_total_bytes`; Function: `ftl::sel::adjust_total_size`                      |
| `tag_new_tab` (config var) vs `tag_new_tab` (function)     | Variable: `ftl_cfg_default_new_tab_dir`; Function: `ftl::plugin::to_other_tab::create_tab_for_move` |
| `ftl_filter` (in every filter plugin)                      | `ftl::plugin::<name>::filter` (namespaced per plugin)                                               |
| `etag_dir` / `etag_tag` (in every etag plugin)             | `ftl::plugin::<name>::scan_directory` / `ftl::plugin::<name>::get_entry_tag`                        |
| `enter` (core) vs `enter` (type_handlers override)         | Core: `ftl::cmd::enter_entry`; Plugin: `ftl::plugin::type_handlers::enter`                          |
| `move_left` (core) vs `move_left` (type_handlers override) | Core: `ftl::cmd::cd_to_parent`; Plugin: `ftl::plugin::type_handlers::move_left`                     |

---

## 23. Summary Statistics

### 23.1 Function counts

| category            | v1 count               | v2 count                       | change                                                       |
| ----------          | ----------             | ----------                     | --------                                                     |
| Core engine         | ~20                    | ~25                            | +5 (split `ftl`, added `validate_environment`, `init`, etc.) |
| Keyboard            | ~12                    | ~13                            | +1 (split `get_key`)                                         |
| Listing & rendering | ~25                    | ~25                            | 0                                                            |
| Filter pipeline     | ~18                    | ~18                            | 0                                                            |
| Selection / tags    | ~35                    | ~35                            | 0                                                            |
| Tab                 | ~12                    | ~12                            | 0                                                            |
| Pane & tmux         | ~25                    | ~25                            | 0                                                            |
| Preview             | ~40                    | ~40                            | 0                                                            |
| Etag                | ~4                     | ~6                             | +2 (registry functions)                                      |
| Marks & history     | ~15                    | ~15                            | 0                                                            |
| Search              | ~20                    | ~20                            | 0                                                            |
| Shell integration   | ~15                    | ~15                            | 0                                                            |
| File operations     | ~45                    | ~45                            | 0                                                            |
| Command prompt      | ~12                    | ~12                            | 0                                                            |
| State & IPC         | ~18                    | ~20                            | +2 (split `save_state`)                                      |
| Utility             | ~6                     | ~6                             | 0                                                            |
| Plugin: filters     | ~18 (all `ftl_filter`) | ~54 (3 per plugin, 18 plugins) | +36 (namespaced)                                             |
| Plugin: etags       | ~14 (2 per × 7)        | ~14                            | 0 (namespaced)                                               |
| Plugin: viewers     | ~45                    | ~45                            | 0 (namespaced)                                               |
| Plugin: bindings    | ~60                    | ~60                            | 0 (namespaced)                                               |
| Plugin: commands    | ~8                     | ~8                             | 0 (namespaced)                                               |
| **Total**           | **~425**               | **~465**                       | **+40**                                                      |

### 23.2 Visibility distribution (v2)

| visibility  | count   | pattern                           |
| ----------- | ------- | ---------                         |
| public      | ~280    | `ftl::<module>::<name>`           |
| private     | ~100    | `_ftl::<module>::<name>`          |
| plugin      | ~85     | `ftl::plugin::<name>::<function>` |

### 23.3 Module distribution (v2)

| module   | function count   | notes                                                            |
| -------- | ---------------- | -------                                                          |
| `cmd`    | ~140             | All user-facing commands (was scattered in v1's `commands` file) |
| `plug`   | ~85              | Plugin functions (filters, etags, viewers, bindings, commands)   |
| `list`   | ~25              | Listing & rendering                                              |
| `pane`   | ~25              | Tmux pane management                                             |
| `prev`   | ~40              | Preview dispatch                                                 |
| `sel`    | ~20              | Selection management                                             |
| `kbd`    | ~13              | Keyboard engine                                                  |
| `filt`   | ~18              | Filter pipeline                                                  |
| `tab`    | ~12              | Tab management                                                   |
| `mark`   | ~15              | Marks & history                                                  |
| `state`  | ~20              | State & IPC                                                      |
| `util`   | ~10              | Utilities                                                        |
| `boot`   | ~5               | Bootstrap                                                        |
| `log`    | ~6               | Logging                                                          |
| `etag`   | ~6               | Etag dispatch                                                    |
| `view`   | ~40              | Viewer dispatch (mostly plugin)                                  |
| `gen`    | ~2               | Generators                                                       |
| `time`   | ~1               | Time events                                                      |
| `ipc`    | ~4               | Inter-pane communication                                         |

### 23.4 Key rename patterns

| pattern                | v1 examples                                                                                | v2 pattern                                      | reason       |
| ---------              | -------------                                                                              | ------------                                    | --------     |
| Single-letter prefixes | `t*` (tsplit, tsc, etc.), `k_*` (k_bindings, k_bgen), `p*` (pimage, pmd), `ext_*`          | Spell out                                       | Readability  |
| Cryptic abbreviations  | `cdir`, `rdir`, `cview`, `kbdf`, `pdh`, `pdhn`, `qshell`, `gcn`, `cdfl`, `tsc`, `tselectp` | Spell out                                       | Readability  |
| Noun-as-function-name  | `header`, `selection`, `preview`, `geometry`, `path`                                       | Verb_noun (`print_header`, `resolve_selection`) | Convention   |
| Trailing underscore    | `inotify_`                                                                                 | Remove (use `_ftl::` prefix for private)        | Bad style    |
| `*2` suffix            | `tcpreview2`, `preview_down2`, `preview_up2`, `tmsu_table2`                                | Spell out                                       | Cryptic      |
| `*_imp` suffix         | `bash_filter_keep_imp`, `bash_filter_hide_imp`                                             | `_impl` (private)                               | Abbreviation |
| `enter`/`move_left`    | Same name in core and plugin                                                               | Namespace (`ftl::cmd::*` vs `ftl::plugin::*`)   | Collision    |

### 23.5 Bug fixes / design improvements in v2

| v1 issue                                     | v2 fix                                                                      |
| ----------                                   | --------                                                                    |
| `try` swallows stderr                        | `ftl::log::wrap` captures and routes to logging system                      |
| `numfmt` globally overridden                 | `ftl::util::format_size` (distinct name)                                    |
| `tags_size` var/function collision           | Separate names: `ftl_selection_total_bytes` / `ftl::sel::adjust_total_size` |
| `tag_new_tab` var/function collision         | Separate names                                                              |
| `ftl_filter` collision across plugins        | Namespaced per plugin                                                       |
| `etag_dir`/`etag_tag` collision across etags | Namespaced per plugin + registry                                            |
| `enter`/`move_left` override collision       | Namespaced: core vs plugin                                                  |
| `player_k`/`player_kill` duplicates          | Merged into one                                                             |
| `sel_read`/`load_sel` duplicates             | Merged into one                                                             |
| `ftl` function does too much                 | Split into 4 boot functions                                                 |
| `get_key` mixes read + normalize             | Split into 2 functions                                                      |
| `cview` does cd + scan + render              | Split into 3 functions                                                      |
| No viewer registry (40-line if-else)         | Data-driven registry                                                        |
| No etag registry (source replaces)           | Registry with all etags coexisting                                          |
| No plugin contract validation                | Loader validates manifest                                                   |

---

## Usage Notes

### Migration tooling

A `tools/migrate-functions.sh` sed script can handle mechanical renames:

```bash
#!/bin/bash
# tools/migrate-functions.sh
# Renames v1 function names to v2 in a given file.
# Note: only handles the simple cases; manual review required.

sed -i \
    -e 's/\bcdir\b/ftl::list::change_dir/g' \
    -e 's/\blist\b/ftl::list::render/g' \
    -e 's/\bpreview\b/ftl::prev::dispatch/g' \
    -e 's/\bsave_state\b/ftl::state::save/g' \
    -e 's/\bget_key\b/ftl::kbd::get_key/g' \
    -e 's/\bkey_command\b/ftl::kbd::dispatch/g' \
    -e 's/\bmy_pane\b/ftl_pane_self_id/g' \
    -e 's/\bpane_id\b/ftl_pane_preview_id/g' \
    -e 's/\btags_size\b/ftl_selection_total_bytes/g' \
    -e 's/\bstagsi\b/ftl_selection_revision/g' \
    "$1"
```

**Warning:** Function renames require updating both the definition AND every call site. The compat layer (below) is the safer migration path.

### Compatibility layer

A `compat/v1.sh` file can alias v1 function names to v2:

```bash
# compat/v1.sh — v1 function name shims
# Source AFTER v2 init to make v1 plugins work.

cdir()      { ftl::list::change_dir "$@" ; }
list()      { ftl::list::render "$@" ; }
preview()   { ftl::prev::dispatch ; }
save_state() { ftl::state::save "$@" ; }
get_key()   { ftl::kbd::get_key "$@" ; }
key_command() { ftl::kbd::dispatch ; }
# ... (full list)
```

Note: this only works for functions that have identical signatures. Functions whose signatures changed (e.g. `etag_tag` now uses namerefs differently) need adapter functions.

