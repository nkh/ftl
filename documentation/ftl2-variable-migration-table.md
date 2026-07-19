# `ftl` v1 → v2 Variable Migration Table

> **Source:** Based on `ftl-variables.md` (the exhaustive v1 variable reference).
> **Purpose:** A complete mapping of every v1 global variable to its proposed v2 namespaced equivalent, organized by category, with the owning module and rationale for non-obvious renames.
> **Naming scheme:** `ftl_<module>_<name>` for variables, `FTL_<MODULE>_<NAME>` for environment variables, `ftl::<module>::<function>` for functions.
> **Module abbreviations** used in the table: `cfg` (config), `state`, `log`, `ipc`, `kbd` (keyboard), `list` (listing), `prev` (preview), `pane`, `plug` (plugin), `sel` (selection), `tab`, `mark`, `filt` (filter), `etag`, `view`, `gen` (generator), `cmd` (command), `util`.

---

## Table of Contents

1. [Environment & Loader Sentinels](#1-environment--loader-sentinels)
2. [Paths & Directory Layout](#2-paths--directory-layout)
3. [Behavior Options](#3-behavior-options)
4. [Glyph Tables](#4-glyph-tables)
5. [Filter Regexes & Media Filters](#5-filter-regexes--media-filters)
6. [FZF Options](#6-fzf-options)
7. [External Command Config](#7-external-command-config)
8. [Key Binding Globals](#8-key-binding-globals)
9. [Associative Array Config](#9-associative-array-config)
10. [Core Runtime State](#10-core-runtime-state)
11. [Per-Pane Filesystem State](#11-per-pane-filesystem-state)
12. [Keyboard & Input State](#12-keyboard--input-state)
13. [Listing & Rendering State](#13-listing--rendering-state)
14. [Path Parsing Globals](#14-path-parsing-globals)
15. [Selection / Tag State](#15-selection--tag-state)
16. [Tab State](#16-tab-state)
17. [Filter State](#17-filter-state)
18. [Preview / Pane State](#18-preview--pane-state)
19. [Tmux / IPC State](#19-tmux--ipc-state)
20. [External Integration Globals](#20-external-integration-globals)
21. [Plugin-Defined Globals (per-plugin)](#21-plugin-defined-globals-per-plugin)
22. [Serialized State Files](#22-serialized-state-files)
23. [Removed / Merged / Renamed Variables](#23-removed--merged--renamed-variables)
24. [Summary Statistics](#24-summary-statistics)

---

## 1. Environment & Loader Sentinels

 v1 name        | v2 name                         | module  | type       | rationale                                                                                               
----------------|---------------------------------|---------|------------|---------------------------------------------------------------------------------------------------------
 `FTLRC_LOADED` | `FTL_BOOTSTRAP_DONE`            | `boot`  | env flag   | "RC loaded" is misleading — it really means "core is bootstrapped"                                      
 `LANG`         | `LANG`                          | —       | env        | Keep (standard POSIX)                                                                                   
 `LC_ALL`       | `LC_ALL`                        | —       | env        | Keep (standard POSIX)                                                                                   
 `FTL_CFG`      | `FTL_CONFIG_DIR`                | `cfg`   | env path   | "CFG" is abbreviation; spell out for clarity. `$FTL_CONFIG_DIR/lib/ftl2/...`                            
 (new)          | `FTL_STATE_DIR`                 | `state` | env path   | Split from `FTL_CFG` — config and state should be separable                                             
 (new)          | `FTL_CACHE_DIR`                 | `state` | env path   | Separate cache dir for LRU eviction                                                                     
 (new)          | `FTL_LIB_DIR`                   | `boot`  | env path   | Where the core library lives (was implicit in `$FTL_CFG/etc/`)                                          
 (new)          | `FTL_PLUGIN_DIR`                | `plug`  | env path   | Where plugins live (was implicit in `$FTL_CFG/`)                                                        
 (new)          | `FTL_DEBUG`                     | `log`   | env flag   | Enable debug logging (replaces implicit `pdhl` check)                                                   
 (new)          | `FTL_PROFILE`                   | `cfg`   | env string | Config profile name (vim/cua/minimal/emacs)                                                             

---

## 2. Paths & Directory Layout

 v1 name        | v2 name                         | module  | type       | rationale                                                                                               
----------------|---------------------------------|---------|------------|---------------------------------------------------------------------------------------------------------
 `pgen`         | `ftl_gen_dir`                   | `gen`   | path       | "pgen" is cryptic; spell out "generator dir"                                                            
 `ftl_root`     | `ftl_state_dir`                 | `state` | path       | Was misleadingly called "root" but is actually the state dir. Exported as `FTL_STATE_DIR` for children. 
 `ftl_cmds`     | *(removed)*                     | —       | —          | **Unused in v1** — remove                                                                               
 `ghist`        | `ftl_state_global_history_file` | `state` | path       | "ghist" is cryptic; spell out                                                                           
 `thumbs`       | `ftl_cache_thumb_dir`           | `state` | path       | "thumbs" is casual; "cache_thumb_dir" is consistent with XDG cache                                      
 `help_command` | `ftl_cfg_help_command`          | `cfg`   | string     | Move to config namespace                                                                                

---

## 3. Behavior Options

All behavior options move to the `cfg` module with `ftl_cfg_` prefix. The table below uses these abbreviations in the rationale column: **NS** = namespace added, **CL** = clarified/renamed, **KV** = keep v1 value.

 v1 name               | v2 name                              | module         | type     | rationale                                                                            
-----------------------|--------------------------------------|----------------|----------|--------------------------------------------------------------------------------------
 `KEY_TIMEOUT`         | `ftl_cfg_key_timeout`                | `cfg` `kbd`    | float    | NS; was all-caps, now lowercase per convention                                       
 `shell_h`             | `ftl_cfg_shell_pane_height`          | `cfg` `pane`   | string   | CL; spell out "h" → "height"                                                         
 `shell_v`             | `ftl_cfg_shell_pane_width`           | `cfg` `pane`   | string   | CL; spell out "v" → "width" (vertical pane = wider)                                  
 `auto_selection`      | `ftl_cfg_auto_sync_selection`        | `cfg` `sel`    | bool     | CL; "auto_selection" is vague; "auto_sync_selection" is explicit                     
 `time_event`          | `ftl_cfg_time_event_interval`        | `cfg`          | int      | CL; spell out "interval"                                                             
 `pdhl`                | *(removed)*                          | —              | —        | **Bug in v1** (writes to `ftl_log` not `$pdhl`). Replace with `FTL_DEBUG=1` env var. 
 `dirmode`             | `ftl_state_dir_preview_mode`         | `state` `view` | int 0-5  | Move from cfg to state — it's runtime state, not config. Renamed for clarity.        
 `extmode`             | `ftl_state_alt_preview_mode`         | `state` `view` | int 0-5  | CL; "extmode" is vague; "alt_preview_mode" is explicit                               
 `emode`               | `ftl_state_external_viewer_mode`     | `state` `view` | int 0-3  | CL; distinguish from `extmode` (which is the persistent alt mode)                    
 `zooms`               | `ftl_cfg_preview_zoom_levels`        | `cfg` `view`   | array    | CL; spell out                                                                        
 `zoom`                | `ftl_state_preview_zoom_index`       | `state` `view` | int      | Move to state (runtime, not config)                                                  
 `move_step`           | `ftl_cfg_move_step_size`             | `cfg` `kbd`    | int      | CL; spell out                                                                        
 `msg_m`               | `ftl_cfg_msg_montage`                | `cfg`          | string   | CL; "m" → "montage"                                                                  
 `msg_du`              | `ftl_cfg_msg_du_size`                | `cfg`          | string   | CL; "du" → "du_size"                                                                 
 `find_auto`           | `ftl_cfg_auto_select_filename`       | `cfg` `list`   | string   | CL; spell out                                                                        
 `line_color0`         | `ftl_cfg_line_color_default`         | `cfg` `view`   | string   | CL; "0" → "default"                                                                  
 `line_color`          | `ftl_state_line_color_current`       | `state` `view` | string   | Move to state (mutated at runtime by `goto_entry`)                                   
 `line_color_hi`       | `ftl_cfg_line_color_highlight`       | `cfg` `view`   | string   | CL; "hi" → "highlight"                                                               
 `mount_archive`       | `ftl_cfg_mount_archives`             | `cfg`          | bool     | CL; plural for boolean toggle                                                        
 `cursor_color0`       | `ftl_cfg_cursor_color_default`       | `cfg` `view`   | string   | CL                                                                                   
 `cursor_color`        | `ftl_state_cursor_color_current`     | `state` `view` | string   | Move to state                                                                        
 `cursor_color_search` | `ftl_cfg_cursor_color_search`        | `cfg` `view`   | string   | NS                                                                                   
 `pop_help`            | `ftl_cfg_help_in_popup`              | `cfg`          | bool     | CL; "pop_help" is ambiguous                                                          
 `pop_kbindings`       | `ftl_cfg_bindings_in_popup`          | `cfg`          | bool     | CL                                                                                   
 `quick_display`       | `ftl_cfg_quick_display_threshold`    | `cfg` `list`   | int      | CL; spell out "threshold"                                                            
 `rfilter0`            | `ftl_cfg_default_reverse_filter`     | `cfg` `filt`   | string   | CL; "0" → "default"                                                                  
 `show_line`           | `ftl_cfg_show_entry_index`           | `cfg` `view`   | bool     | CL; "line" → "entry_index"                                                           
 `show_size`           | `ftl_state_show_size_mode`           | `state` `view` | int 0-3  | Move to state (cycles at runtime)                                                    
 `show_date`           | `ftl_cfg_show_date_in_header`        | `cfg` `view`   | bool     | CL                                                                                   
 `show_tar`            | `ftl_cfg_show_tar_info`              | `cfg` `view`   | bool     | CL                                                                                   
 `tag_new_tab`         | `ftl_cfg_default_new_tab_dir`        | `cfg` `tab`    | path     | CL                                                                                   
 `TBCOLORS`            | `ftl_cfg_tmux_border_colors_default` | `cfg` `pane`   | string   | CL; spell out                                                                        
 `tbcolor` (function)  | `ftl::pane::set_border_colors`       | `pane`         | function | NS                                                                                   
 `etag`                | `ftl_state_etag_enabled`             | `state` `etag` | bool     | Move to state (toggled at runtime)                                                   
 `sort_type0`          | `ftl_cfg_default_sort_type`          | `cfg` `list`   | int 0-2  | CL; "0" → "default"                                                                  
 `sort_reversed0`      | `ftl_cfg_default_sort_reversed`      | `cfg` `list`   | string   | CL                                                                                   

---

## 4. Glyph Tables

All glyph arrays move to `cfg` module. Note: v1's `sglyph` had only 2 entries (missing the date glyph — a bug). v2 adds the third entry.

 v1 name              | v2 name                          | module         | type     | rationale                                                      
----------------------|----------------------------------|----------------|----------|----------------------------------------------------------------
 `sglyph`             | `ftl_cfg_glyph_sort`             | `cfg` `view`   | array(3) | NS; **fix v1 bug**: add date glyph (`📅` or similar) as index 2 
 `iglyph`             | `ftl_cfg_glyph_image_mode`       | `cfg` `view`   | array(3) | CL                                                             
 `lglyph`             | `ftl_cfg_glyph_listing_mode`     | `cfg` `view`   | array(3) | CL                                                             
 `tglyph`             | `ftl_cfg_glyph_tag_classes`      | `cfg` `view`   | array(5) | CL; index 0 unused in v1 — keep for compatibility              

---

## 5. Filter Regexes & Media Filters

 v1 name              | v2 name                          | module         | type     | rationale                                                      
----------------------|----------------------------------|----------------|----------|----------------------------------------------------------------
 `ifilter`            | `ftl_cfg_image_extensions_regex` | `cfg` `view`   | regex    | CL; "ifilter" is cryptic                                       
 `mfilter`            | `ftl_cfg_media_extensions_regex` | `cfg` `view`   | regex    | CL; "mfilter" is cryptic                                       
 `pdf_prev_image`     | `ftl_state_pdf_preview_as_image` | `state` `view` | bool     | Move to state (toggled at runtime via `zmp`)                   

---

## 6. FZF Options

 v1 name              | v2 name                          | module         | type     | rationale                                                      
----------------------|----------------------------------|----------------|----------|----------------------------------------------------------------
 `fzf_opt`            | `ftl_cfg_fzf_popup_opts`         | `cfg`          | string   | CL; "popup" because `-p` makes it a popup                      
 `fzfp_opt`           | `ftl_cfg_fzf_pane_opts`          | `cfg`          | string   | CL; "pane" because no `-p`                                     
 `fzf_sxiv_opt`       | `ftl_cfg_fzf_sxiv_opts`          | `cfg`          | string   | NS                                                             
 `FZF_LISTEN`         | `ftl_cfg_fzf_listen_port`        | `cfg`          | int      | CL                                                             
 `FZF_LISTEN_COMMAND` | `ftl_cfg_fzf_listen_command`     | `cfg`          | string   | NS                                                             

---

## 7. External Command Config

All external command names move to `cfg` with `ftl_cfg_` prefix. The pattern: spell out abbreviations.

 v1 name                   | v2 name                             | module         | type   | rationale                                                  
---------------------------|-------------------------------------|----------------|--------|------------------------------------------------------------
 `SXIV`                    | `ftl_cfg_image_viewer`              | `cfg` `view`   | string | CL; "SXIV" is the default, not the concept                 
 `GIF_VIEWER`              | `ftl_cfg_gif_viewer`                | `cfg` `view`   | string | NS (lowercase prefix)                                      
 `EDITOR`                  | `ftl_cfg_editor`                    | `cfg`          | string | NS                                                         
 `FILE_DIFF`               | `ftl_cfg_diff_tool`                 | `cfg`          | string | CL; "FILE_DIFF" → "diff_tool"                              
 `FTLI_CLEAN`              | `ftl_cfg_image_clean_borders`       | `cfg` `view`   | bool   | CL; "FTLI_CLEAN" is internal jargon                        
 `FTLI_H`                  | `ftl_cfg_char_height_px`            | `cfg` `view`   | int    | CL                                                         
 `FTLI_W`                  | `ftl_cfg_char_width_px`             | `cfg` `view`   | int    | CL                                                         
 `FTLI_Z`                  | `ftl_state_image_zoomed`            | `state` `view` | bool   | Move to state (toggled via `zz`)                           
 `GPGID`                   | `ftl_cfg_gpg_key_id`                | `cfg`          | string | CL                                                         
 `G_PLAYER`                | `ftl_cfg_gui_media_player`          | `cfg` `view`   | string | CL                                                         
 `T_PLAYER`                | `ftl_cfg_terminal_media_player`     | `cfg` `view`   | string | CL                                                         
 `TE_PLAYER`               | `ftl_cfg_external_terminal_player`  | `cfg` `view`   | string | CL                                                         
 `T_PLAYER_STATUS`         | `ftl_cfg_live_preview_player`       | `cfg` `view`   | string | CL; "T_PLAYER_STATUS" is confusing                         
 `B_PLAYER`                | `ftl_cfg_background_player`         | `cfg` `view`   | string | CL                                                         
 `Q_PLAYER`                | `ftl_cfg_queue_player`              | `cfg` `view`   | string | CL                                                         
 `PAGER_ANSI`              | `ftl_cfg_ansi_pager`                | `cfg`          | string | NS                                                         
 `MD_PAGER`                | `ftl_cfg_markdown_pager`            | `cfg` `view`   | string | CL                                                         
 `MD_RENDER0`              | `ftl_cfg_markdown_renderer_default` | `cfg` `view`   | string | CL; "0" → "default"                                        
 `MD_RENDER1`              | `ftl_cfg_markdown_renderer_1`       | `cfg` `view`   | string | NS                                                         
 `MD_RENDER2`              | `ftl_cfg_markdown_renderer_2`       | `cfg` `view`   | string | NS                                                         
 `$MD_DIR_RENDER` (v1 bug) | `ftl_cfg_markdown_dir_renderer`     | `cfg` `view`   | string | **Fix v1 bug**: remove leading `$` so it's an assignment   
 `HEXVIEW`                 | `ftl_cfg_hex_viewer`                | `cfg`          | string | NS                                                         
 `HEXEDIT`                 | `ftl_cfg_hex_editor`                | `cfg`          | string | NS                                                         
 `MIMETYPE`                | `ftl_cfg_mime_detector`             | `cfg`          | string | CL                                                         
 `NCDU`                    | `ftl_cfg_disk_usage_tool`           | `cfg` `view`   | string | CL; "NCDU" is one option, "disk_usage_tool" is the concept 
 `JSON_VIEWER`             | `ftl_cfg_json_viewer`               | `cfg` `view`   | string | NS                                                         
 `YAML_VIEWER`             | `ftl_cfg_yaml_viewer`               | `cfg` `view`   | string | NS                                                         
 `EXA_COLORS`              | `ftl_cfg_exa_colors`                | `cfg` `view`   | string | NS                                                         
 `EXA_OPTIONS`             | `ftl_cfg_exa_options`               | `cfg` `view`   | string | NS                                                         
 `RM`                      | `ftl_cfg_delete_command`            | `cfg`          | string | CL; "RM" is one option, "delete_command" is the concept    
 `CMD_COLS`                | `ftl_cfg_bindings_display_width`    | `cfg` `kbd`    | int    | CL                                                         

---

## 8. Key Binding Globals

 v1 name                         | v2 name                              | module         | type   | rationale                                                                          
---------------------------------|--------------------------------------|----------------|--------|------------------------------------------------------------------------------------
 `redo_key`                      | `ftl_cfg_redo_key`                   | `cfg` `kbd`    | string | NS                                                                                 
 `leader_key`                    | `ftl_cfg_leader_key`                 | `cfg` `kbd`    | string | NS                                                                                 

---

## 9. Associative Array Config

 v1 name                         | v2 name                              | module         | type   | rationale                                                                          
---------------------------------|--------------------------------------|----------------|--------|------------------------------------------------------------------------------------
 `marks`                         | `ftl_mark_session_marks`             | `mark`         | assoc  | Move from cfg to mark module (it's runtime state, not config)                      
 `dir_dest`                      | `ftl_cfg_preset_destinations`        | `cfg` `entry`  | assoc  | CL; "dir_dest" is cryptic                                                          
 `cmd_aliases`                   | `ftl_cfg_command_aliases`            | `cfg` `cmd`    | assoc  | NS                                                                                 
 `user_colors` (commented in v1) | `ftl_cfg_color_overrides`            | `cfg` `view`   | assoc  | CL; "user_colors" is vague                                                         

---

## 10. Core Runtime State

These are the big declarations from `ftl_setup:6-12`. Each moves to its semantic module.

### 10.1 The seven `declare -Ag` arrays (ftl_setup line 6)

 v1 name                         | v2 name                              | module         | type   | rationale                                                                          
---------------------------------|--------------------------------------|----------------|--------|------------------------------------------------------------------------------------
 `C`                             | `ftl_kbd_command_to_key`             | `kbd`          | assoc  | CL; "C" is one letter — spell out the semantics (reverse map: command → key)       
 `bindings`                      | `ftl_kbd_bindings_display`           | `kbd`          | assoc  | CL; used for the `c` binding-display command                                       
 `kbd_trie`                      | `ftl_kbd_trie`                       | `kbd`          | assoc  | NS (already well-named)                                                            
 `key_map`                       | `ftl_kbd_submode_handler`            | `kbd`          | scalar | CL; "key_map" is misleading — it's the sub-mode dispatcher                         
 `vfiles`                        | `ftl_plugin_vfiles`                  | `plug`         | assoc  | NS; move to plugin module                                                          
 `vdirs`                         | `ftl_plugin_vdirs`                   | `plug`         | assoc  | NS; move to plugin module                                                          
 `time_event_handlers`           | `ftl_time_handlers`                  | `state`        | assoc  | NS; move to a `time` submodule of state                                            

### 10.2 The nine `declare -A -g` arrays (ftl_setup line 7)

 v1 name                         | v2 name                              | module         | type   | rationale                                                                          
---------------------------------|--------------------------------------|----------------|--------|------------------------------------------------------------------------------------
 `dir_file`                      | `ftl_state_cursor_memory`            | `state` `list` | assoc  | CL; "dir_file" is opaque; this stores "which entry was selected in each (tab,dir)" 
 `mime`                          | `ftl_list_mime_cache`                | `list`         | assoc  | CL; move to listing module                                                         
 `pignore`                       | `ftl_view_preview_ignore_exts`       | `view`         | assoc  | CL; "pignore" = "preview ignore" — spell out                                       
 `lignore`                       | `ftl_filt_listing_hide_exts`         | `filt`         | assoc  | CL; "lignore" = "listing ignore"                                                   
 `lkeep`                         | `ftl_filt_listing_keep_exts`         | `filt`         | assoc  | CL                                                                                 
 `lkeep_tab`                     | `ftl_filt_listing_keep_exts_per_tab` | `filt`         | assoc  | CL                                                                                 
 `tail`                          | `ftl_view_vim_tail_commands`         | `view`         | assoc  | CL; "tail" is vim-specific (the `+$ ` ex command)                                  
 `tags`                          | `ftl_selection_tags`                 | `sel`          | assoc  | CL; "tags" is ambiguous (TMSU tags vs selection) — explicitly "selection_tags"     
 `ntags`                         | `ftl_selection_class_index`          | `sel`          | assoc  | CL; "ntags" is opaque; this is the inverted index of which classes are in use      
 `ftl_env`                       | `ftl_state_child_env`                | `state`        | assoc  | CL; "ftl_env" is OK but spell out "child_env"                                      
 `du_size`                       | `ftl_list_dir_size_cache`            | `list`         | assoc  | CL; "du_size" is casual                                                            

### 10.3 Scalars from ftl_setup line 7

 v1 name                            | v2 name                       | module        | type     | rationale                                                                               
------------------------------------|-------------------------------|---------------|----------|-----------------------------------------------------------------------------------------
 `my_pane`                          | `ftl_pane_self_id`            | `pane`        | scalar   | CL; "my_pane" is casual; "self_id" is clear                                             
 `tags_size`                        | `ftl_selection_total_bytes`   | `sel`         | int      | CL; **also a function in v1**, rename the function to `ftl::selection::adjust_size`     

### 10.4 The dir_entries_* family (ftl_setup lines 9-10)

 v1 name                            | v2 name                       | module        | type     | rationale                                                                               
------------------------------------|-------------------------------|---------------|----------|-----------------------------------------------------------------------------------------
 `dir_entries_list`                 | `ftl_list_raw_entries`        | `list`        | array    | CL; drop "dir_" prefix (it's the listing entries, not just dirs)                        
 `dir_entries_path`                 | `ftl_list_raw_paths`          | `list`        | assoc    | CL                                                                                      
 `dir_entries_file`                 | `ftl_list_raw_names`          | `list`        | assoc    | CL; "file" → "names" (basenames)                                                        
 `dir_entries_color`                | `ftl_list_raw_colors`         | `list`        | assoc    | CL                                                                                      
 `dir_entries_size`                 | `ftl_list_raw_sizes`          | `list`        | assoc    | CL                                                                                      
 `dir_entries_relative_path_length` | `ftl_list_raw_relpath_len`    | `list`        | assoc    | CL; abbreviate "length" → "len"                                                         

### 10.5 Scalars from ftl_setup line 12

 v1 name                            | v2 name                       | module        | type     | rationale                                                                               
------------------------------------|-------------------------------|---------------|----------|-----------------------------------------------------------------------------------------
 `selection`                        | `ftl_selection_current`       | `sel`         | array    | CL; "selection" → "current" (the resolved selection array)                              
 `n`                                | `ftl_state_current_path`      | `state`       | path     | CL; "n" is one letter — spell out (this is the full path of the current entry)          
 `tab`                              | `ftl_state_current_tab_index` | `state` `tab` | int      | CL                                                                                      
 `tabs`                             | `ftl_tab_directories`         | `tab`         | array    | CL                                                                                      
 `ntabs`                            | `ftl_tab_count`               | `tab`         | int      | CL                                                                                      

### 10.6 Filter init (ftl_setup line 14)

 v1 name                            | v2 name                       | module        | type     | rationale                                                                               
------------------------------------|-------------------------------|---------------|----------|-----------------------------------------------------------------------------------------
 `sort_filters`                     | `ftl_cfg_sort_options`        | `cfg` `list`  | array    | CL; "sort_filters" is misleading (these are sort option strings, not filters)           
 `flips`                            | `ftl_cfg_row_separator_chars` | `cfg` `list`  | array(2) | CL; "flips" is cryptic — these are the alternating row-separator characters             

---

## 11. Per-Pane Filesystem State

The most confusing v1 variables. v2 clarifies by using `ftl_state_*` consistently and documenting the role of each.

 v1 name                            | v2 name                       | module        | type     | rationale                                                                               
------------------------------------|-------------------------------|---------------|----------|-----------------------------------------------------------------------------------------
 `fs`                               | `ftl_state_session_dir`       | `state`       | path     | CL; "fs" is one letter — this is the per-session state directory (`$FTL_STATE_DIR/$$/`) 
 `pfs`                              | `ftl_state_parent_dir`        | `state`       | path     | CL; "pfs" = "parent fs" — the parent pane's session dir                                 
 `ofs`                              | `ftl_state_other_session_dir` | `state`       | path     | CL; "ofs" = "other fs" — the pane we're syncing with                                    
 `fsp`                              | `ftl_state_shared_dir`        | `state`       | path     | CL; "fsp" = "fs/prev" — the shared sync directory                                       
 `PPWD`                             | `ftl_state_previous_pwd`      | `state`       | path     | NS; lowercase                                                                           

---

## 12. Keyboard & Input State

### 12.1 AltGr mapping tables

 v1 name                | v2 name                       | module        | type     | rationale                                                      
------------------------|-------------------------------|---------------|----------|----------------------------------------------------------------
 `A`                    | `ftl_kbd_altgr_map`           | `kbd`         | assoc    | CL; "A" is one letter                                          
 `LA`                   | `ftl_kbd_altgr_inverse`       | `kbd`         | assoc    | CL                                                             
 `SA`                   | `ftl_kbd_shift_altgr_map`     | `kbd`         | assoc    | CL                                                             
 `LSA`                  | `ftl_kbd_shift_altgr_inverse` | `kbd`         | assoc    | CL                                                             

### 12.2 Input state

 v1 name                | v2 name                       | module        | type     | rationale                                                      
------------------------|-------------------------------|---------------|----------|----------------------------------------------------------------
 `REPLY`                | `ftl_kbd_current_key`         | `kbd`         | scalar   | CL; "REPLY" is the bash `read` builtin's default — too generic 
 `OREPLY`               | `ftl_kbd_raw_key`             | `kbd`         | scalar   | CL; "OREPLY" = "original reply" — spell out as "raw"           
 `R`                    | `ftl_state_pending_input`     | `state` `kbd` | string   | CL; "R" is one letter — this is the pending input queue        
 `E1`, `E2`, `E3`, `E4` | `ftl_kbd_esc_seq_bytes`       | `kbd`         | array(4) | CL; consolidate 4 vars into 1 array                            

### 12.3 Trie dispatch state

 v1 name                | v2 name                       | module        | type     | rationale                                                      
------------------------|-------------------------------|---------------|----------|----------------------------------------------------------------
 `keys_command`         | `ftl_kbd_accumulated_keys`    | `kbd`         | scalar   | CL                                                             
 `keys_in`              | `ftl_kbd_keys_count`          | `kbd`         | int      | CL                                                             
 `HAS_COUNT`            | `ftl_kbd_has_count`           | `kbd`         | bool     | NS (lowercase)                                                 
 `COUNT`                | `ftl_kbd_count`               | `kbd`         | string   | NS (lowercase)                                                 
 `keys_function`        | `ftl_kbd_pending_function`    | `kbd`         | scalar   | CL                                                             
 `keys_latest_command`  | `ftl_kbd_last_command`        | `kbd`         | scalar   | CL                                                             
 `exclude_from_redo`    | `ftl_kbd_redo_excluded`       | `kbd`         | assoc    | CL                                                             
 `ftl_bind_check`       | `ftl_kbd_warn_on_override`    | `kbd`         | bool     | CL                                                             

---

## 13. Listing & Rendering State

### 13.1 The listing arrays

 v1 name       | v2 name                              | module         | type    | rationale                                                            
---------------|--------------------------------------|----------------|---------|----------------------------------------------------------------------
 `files`       | `ftl_list_entries`                   | `list`         | array   | CL; "files" is misleading (includes dirs) — "entries" is correct     
 `files_color` | `ftl_list_entry_colors`              | `list`         | array   | CL                                                                   
 `nfiles`      | `ftl_list_entry_count`               | `list`         | int     | CL                                                                   
 `file`        | `ftl_state_cursor_index`             | `state` `list` | int     | CL; "file" is misleading — this is the cursor position               

### 13.2 Render temporaries

 v1 name       | v2 name                              | module         | type    | rationale                                                            
---------------|--------------------------------------|----------------|---------|----------------------------------------------------------------------
 `line`        | `ftl_list_display_line_no`           | `list`         | int     | CL                                                                   
 `sum`         | `ftl_list_total_size`                | `list`         | int     | CL                                                                   
 `pad`         | `ftl_list_index_padding`             | `list`         | int     | CL                                                                   
 `first_file`  | `ftl_list_first_file_index`          | `list`         | int     | CL                                                                   
 `found`       | `ftl_list_search_found_index`        | `list`         | int     | CL                                                                   

### 13.3 Window geometry

 v1 name       | v2 name                              | module         | type    | rationale                                                            
---------------|--------------------------------------|----------------|---------|----------------------------------------------------------------------
 `top`         | `ftl_list_window_top`                | `list`         | int     | CL                                                                   
 `bottom`      | `ftl_list_window_bottom`             | `list`         | int     | CL                                                                   
 `center`      | `ftl_list_window_center`             | `list`         | int     | CL                                                                   
 `lines`       | `ftl_list_window_height`             | `list`         | int     | CL; "lines" is ambiguous (could be terminal LINES)                   
 `LINES`       | `ftl_pane_height`                    | `pane`         | int     | CL; conflicts with bash builtin — rename                             
 `COLS`        | `ftl_pane_width`                     | `pane`         | int     | CL; same                                                             
 `WCOLS`       | `ftl_pane_prev_width`                | `pane`         | int     | CL; "W" prefix unclear — "prev" for "previous" (for winch detection) 
 `WLINES`      | `ftl_pane_prev_height`               | `pane`         | int     | CL                                                                   
 `TOP`         | `ftl_pane_top`                       | `pane`         | int     | NS (lowercase)                                                       
 `WIDTH`       | `ftl_pane_window_width`              | `pane`         | int     | CL; distinguish from `ftl_pane_width`                                
 `LEFT`        | `ftl_pane_left`                      | `pane`         | int     | NS (lowercase)                                                       
 `COLS_P`      | `ftl_pane_preview_width`             | `pane`         | int     | CL; "_P" → "_preview"                                                
 `x`           | `ftl_pane_resize_target`             | `pane`         | int     | CL; "x" is one letter                                                

### 13.4 Header rendering state

 v1 name       | v2 name                              | module         | type    | rationale                                                            
---------------|--------------------------------------|----------------|---------|----------------------------------------------------------------------
 `head`        | `ftl_list_header_mode_glyphs`        | `list`         | string  | CL; "head" is vague                                                  
 `hsum`        | `ftl_list_header_total_size`         | `list`         | string  | CL                                                                   
 `nfiles_h`    | `ftl_list_header_total_count`        | `list`         | int     | CL; "_h" → "_header"                                                 
 `stat`        | `ftl_list_header_stat`               | `list`         | string  | NS                                                                   
 `date`        | `ftl_list_header_date`               | `list`         | string  | NS                                                                   
 `search_h`    | `ftl_list_header_search`             | `list`         | string  | CL                                                                   
 `tabsd`       | `ftl_list_header_tab_indicator`      | `list`         | string  | CL; "tabsd" is opaque                                                
 `tsc`         | `ftl_pane_bg_window_count`           | `pane`         | int     | CL; "tsc" = "tmux session command" — spell out                       
 `h`           | `ftl_list_header_assembled`          | `list`         | string  | CL; "h" is one letter                                                
 `hal`         | `ftl_list_header_attr_length`        | `list`         | int     | CL; "hal" = "header attribute length"                                
 `hpl`         | `ftl_list_header_path_length`        | `list`         | int     | CL; "hpl" = "header path length"                                     

### 13.5 Render flags

 v1 name       | v2 name                              | module         | type    | rationale                                                            
---------------|--------------------------------------|----------------|---------|----------------------------------------------------------------------
 `flipi`       | `ftl_list_flip_index`                | `list`         | int 0/1 | CL                                                                   
 `flip`        | `ftl_list_current_flip_char`         | `list`         | string  | CL                                                                   
 `qd`          | `ftl_list_quick_display_active`      | `list`         | bool    | CL; "qd" is opaque                                                   
 `sep`         | `ftl_list_path_separator`            | `list`         | string  | NS                                                                   

---

## 14. Path Parsing Globals

The `path()` function sets 5 globals (`n`, `p`, `f`, `b`, `e`). v2 keeps them as a tightly-coupled group but gives them clear names.

 v1 name       | v2 name                              | module         | type    | rationale                                                            
---------------|--------------------------------------|----------------|---------|----------------------------------------------------------------------
 `n`           | `ftl_state_current_path`             | `state`        | path    | CL; already listed in §10.5 — this is the full path                  
 `p`           | `ftl_state_current_dir`              | `state`        | path    | CL; "p" → "dir" (parent directory of the current entry)              
 `f`           | `ftl_state_current_basename`         | `state`        | string  | CL; "f" → "basename"                                                 
 `b`           | `ftl_state_current_stem`             | `state`        | string  | CL; "b" → "stem" (basename without extension)                        
 `e`           | `ftl_state_current_extension`        | `state`        | string  | CL; "e" → "extension"                                                
 `mtype`       | `ftl_state_current_mime_type`        | `state` `list` | string  | CL                                                                   
 `is_bin`      | `ftl_state_current_is_binary`        | `state` `list` | bool    | CL                                                                   
 `file_b`      | `ftl_state_current_file_description` | `state` `list` | string  | CL; "file_b" = output of `file -b` — spell out                       

---

## 15. Selection / Tag State

 v1 name                | v2 name                           | module        | type     | rationale                                                                          
------------------------|-----------------------------------|---------------|----------|------------------------------------------------------------------------------------
 `tags`                 | `ftl_selection_tags`              | `sel`         | assoc    | CL (already in §10.2)                                                              
 `tags_size` (var)      | `ftl_selection_total_bytes`       | `sel`         | int      | CL (already in §10.3)                                                              
 `tags_size` (function) | `ftl::selection::adjust_size`     | `sel`         | function | CL; **v1 had name collision** — function and variable shared the name              
 `stagsi`               | `ftl_selection_revision`          | `sel`         | int      | CL; "stagsi" is opaque — this is a monotonic revision counter for sync             
 `ostagsi`              | `ftl_selection_other_revision`    | `sel`         | int      | CL                                                                                 
 `ctag`                 | `ftl_selection_class_cursor`      | `sel`         | int      | CL; "ctag" is opaque — position within the tags array for next/prev tag navigation 
 `PC`                   | `ftl_sel_delete_prompt_choice`    | `sel`         | string   | CL; "PC" = "prompt choice"                                                         
 `PT`                   | `ftl_sel_delete_prompt_text`      | `sel`         | string   | CL; "PT" = "prompt text"                                                           

---

## 16. Tab State

### 16.1 Tab scalars (already in §10.5)

 v1 name                | v2 name                           | module        | type     | rationale                                                                          
------------------------|-----------------------------------|---------------|----------|------------------------------------------------------------------------------------
 `tab`                  | `ftl_state_current_tab_index`     | `state` `tab` | int      | (see §10.5)                                                                        
 `tabs`                 | `ftl_tab_directories`             | `tab`         | array    | (see §10.5)                                                                        
 `ntabs`                | `ftl_tab_count`                   | `tab`         | int      | (see §10.5)                                                                        

### 16.2 Per-tab associative arrays

 v1 name                | v2 name                           | module        | type     | rationale                                                                          
------------------------|-----------------------------------|---------------|----------|------------------------------------------------------------------------------------
 `lmode`                | `ftl_tab_listing_mode`            | `tab`         | assoc    | CL; "lmode" = "listing mode"                                                       
 `vmode`                | `ftl_tab_view_mode`               | `tab`         | assoc    | CL                                                                                 
 `depth`                | `ftl_tab_listing_depth`           | `tab`         | assoc    | CL                                                                                 
 `hidden`               | `ftl_tab_show_hidden`             | `tab`         | assoc    | CL                                                                                 
 `sort_type`            | `ftl_tab_sort_type`               | `tab`         | assoc    | NS                                                                                 
 `reversed`             | `ftl_tab_sort_reversed`           | `tab`         | assoc    | CL                                                                                 
 `pdir_only`            | `ftl_tab_preview_dirs_only`       | `tab`         | assoc    | CL                                                                                 

---

## 17. Filter State

### 17.1 Per-tab filter variables

 v1 name                | v2 name                           | module        | type     | rationale                                                                          
------------------------|-----------------------------------|---------------|----------|------------------------------------------------------------------------------------
 `filters`              | `ftl_tab_filter_1`                | `tab` `filt`  | assoc    | CL; "filters" is plural and vague — number them                                    
 `filters2`             | `ftl_tab_filter_2`                | `tab` `filt`  | assoc    | CL                                                                                 
 `filters_dir`          | `ftl_tab_filter_dirs`             | `tab` `filt`  | assoc    | CL                                                                                 
 `rfilters`             | `ftl_tab_filter_reverse`          | `tab` `filt`  | assoc    | CL                                                                                 
 `tfilters`             | `ftl_tab_filter_image_mode`       | `tab` `filt`  | assoc    | CL; "tfilters" is opaque — this is the image-mode filter                           
 `ntfilter`             | `ftl_tab_filter_image_negate`     | `tab` `filt`  | assoc    | CL; "ntfilter" is opaque — this is the `-v` flag for image mode                    

### 17.2 External filter state

 v1 name                | v2 name                           | module        | type     | rationale                                                                          
------------------------|-----------------------------------|---------------|----------|------------------------------------------------------------------------------------
 `filter_ext`           | `ftl_filt_external_name`          | `filt`        | string   | CL                                                                                 
 `filter_list`          | `ftl_filt_pipeline_list`          | `filt`        | array    | CL                                                                                 
 `filter_list2`         | `ftl_filt_pipeline_tmp`           | `filt`        | array    | CL; "2" → "tmp" (this is the temp array used by `filter_rmv`)                      
 `filter_pipe`          | `ftl_filt_pipeline_string`        | `filt`        | string   | CL; this is the eval'd pipe string                                                 
 `ftag`                 | `ftl_filt_active_glyph`           | `filt`        | string   | CL; "ftag" = "filter tag" — the glyph shown in header when filter active           

### 17.3 Sort state (resolved per-directory)

 v1 name                | v2 name                           | module        | type     | rationale                                                                          
------------------------|-----------------------------------|---------------|----------|------------------------------------------------------------------------------------
 `s_type`               | `ftl_list_resolved_sort_type`     | `list` `filt` | int      | CL; "s_type" = "sort type"                                                         
 `s_reversed`           | `ftl_list_resolved_sort_reversed` | `list` `filt` | string   | CL                                                                                 

---

## 18. Preview / Pane State

### 18.1 Pane identity

 v1 name               | v2 name                            | module         | type   | rationale                                                                            
-----------------------|------------------------------------|----------------|--------|--------------------------------------------------------------------------------------
 `main`                | `ftl_pane_is_primary`              | `pane`         | bool   | CL; "main" → "is_primary" (the primary pane spawns previews)                         
 `main_pane`           | `ftl_pane_primary_id`              | `pane`         | scalar | CL                                                                                   
 `panes`               | `ftl_pane_child_ids`               | `pane`         | array  | CL                                                                                   
 `new_pane`            | `ftl_pane_last_spawned_id`         | `pane`         | scalar | CL                                                                                   
 `pane_id`             | `ftl_pane_preview_id`              | `pane`         | scalar | CL; "pane_id" is ambiguous — this is specifically the preview pane                   
 `pane2_id`            | `ftl_pane_fixed_preview_id`        | `pane`         | scalar | CL; "pane2" → "fixed_preview" (the `zff` second preview)                             

### 18.2 Preview type flags

 v1 name               | v2 name                            | module         | type   | rationale                                                                            
-----------------------|------------------------------------|----------------|--------|--------------------------------------------------------------------------------------
 `in_pdir`             | `ftl_preview_is_dir_ftl`           | `view`         | bool   | CL; "in_pdir" = "in pane directory" — the preview is a child ftl showing a directory 
 `in_viprev`           | `ftl_preview_is_vim`               | `view`         | bool   | CL; "in_viprev" = "in vim preview"                                                   
 `in_ftli`             | `ftl_preview_is_image_daemon`      | `view`         | bool   | CL; "in_ftli" = "in ftli" (the image daemon)                                         
 `shell_id`            | `ftl_pane_shell_id`                | `pane`         | scalar | NS                                                                                   
 `session_shell`       | `ftl_pane_session_shell_active`    | `pane`         | bool   | CL                                                                                   
 `keep_shell`          | `ftl_pane_keep_shell_on_quit`      | `pane`         | bool   | CL                                                                                   

### 18.3 Preview mode

 v1 name               | v2 name                            | module         | type   | rationale                                                                            
-----------------------|------------------------------------|----------------|--------|--------------------------------------------------------------------------------------
 `prev_all`            | `ftl_state_preview_pane_visible`   | `state` `view` | bool   | CL; "prev_all" is opaque                                                             
 `prev_cb`             | `ftl_state_preview_callback`       | `state` `view` | string | CL; "prev_cb" = "preview callback"                                                   
 `preview_pane2`       | `ftl_state_fixed_preview_filename` | `state` `view` | string | CL; "preview_pane2" is the *filename* shown in the fixed preview                     
 `no_redraw`           | `ftl_state_suppress_redraw`        | `state` `view` | bool   | CL                                                                                   
 `gpreview`            | `ftl_pane_is_child`                | `pane`         | bool   | CL; "gpreview" is opaque — this flag means "this pane is a child (preview) pane"     
 `no_image_preview`    | `ftl_state_images_hidden`          | `state` `view` | bool   | CL                                                                                   
 `montage`             | `ftl_state_montage_glyph`          | `state` `view` | string | CL                                                                                   

### 18.4 Etag state

 v1 name               | v2 name                            | module         | type   | rationale                                                                            
-----------------------|------------------------------------|----------------|--------|--------------------------------------------------------------------------------------
 `etag_s`              | `ftl_etag_source_name`             | `etag`         | string | CL; "etag_s" = "etag source"                                                         
 `etag_cb`             | `ftl_etag_callback`                | `etag`         | string | CL                                                                                   
 `external_tag`        | `ftl_etag_entry_tag`               | `etag`         | string | CL; this is the out-parameter from `etag_tag()`                                      
 `external_tag_length` | `ftl_etag_entry_tag_len`           | `etag`         | int    | CL                                                                                   

### 18.5 Background process state

 v1 name              | v2 name                         | module         | type     | rationale                                                             
----------------------|---------------------------------|----------------|----------|-----------------------------------------------------------------------
 `ino1`               | `ftl_pane_inotify_pid`          | `pane`         | pid      | CL                                                                    
 `ino_processes`      | `ftl_pane_inotify_all_pids`     | `pane`         | array    | CL                                                                    
 `mplayer`            | `ftl_view_media_pid`            | `view`         | pid      | CL                                                                    
 `w3iproc`            | `ftl_view_w3mimg_pid`           | `view`         | pid      | CL; "w3iproc" = "w3m image process"                                   

---

## 19. Tmux / IPC State

### 19.1 Quit / signal state

 v1 name              | v2 name                         | module         | type     | rationale                                                             
----------------------|---------------------------------|----------------|----------|-----------------------------------------------------------------------
 `in_Q`               | `ftl_state_quit_cancelled`      | `state`        | bool     | CL; "in_Q" is opaque — set by `quit_all` to suppress selection output 
 `qshell_c`           | `ftl_state_quit_attempt_count`  | `state`        | int      | CL; "qshell_c" = "quit shell counter"                                 
 `alt_screen`         | `ftl_state_alt_screen_active`   | `state`        | bool     | CL                                                                    
 `winch`              | `ftl_state_winch_pending`       | `state`        | bool     | CL                                                                    

### 19.2 Time / debug

 v1 name              | v2 name                         | module         | type     | rationale                                                             
----------------------|---------------------------------|----------------|----------|-----------------------------------------------------------------------
 `time_event0`        | `ftl_time_last_event_time`      | `state` `time` | int      | CL; "0" suffix is opaque                                              
 `pdh`                | `ftl_log_debug_pane_id`         | `log`          | scalar   | CL; "pdh" = "pane debug helper" — move to log module                  
 `to_search`          | `ftl_state_search_string`       | `state` `kbd`  | string   | CL                                                                    

---

## 20. External Integration Globals

### 20.1 Info file block

 v1 name              | v2 name                         | module         | type     | rationale                                                             
----------------------|---------------------------------|----------------|----------|-----------------------------------------------------------------------
 `ftl_info_file`      | `ftl_state_info_file_path`      | `state`        | path     | CL                                                                    
 `ftl_main_info_file` | `ftl_state_main_info_file_path` | `state`        | path     | CL                                                                    
 `FTL_PID`            | `FTL_PID`                       | `state`        | env int  | Keep (serialized for external commands)                               
 `FTL_FS`             | `FTL_SESSION_DIR`               | `state`        | env path | CL; "FS" is opaque — spell out                                        
 `FTL_PWD`            | `FTL_CWD`                       | `state`        | env path | CL; "PWD" conflicts with shell builtin — use "CWD"                    
 `ftl_pfs` (env)      | `FTL_PARENT_SESSION_DIR`        | `state`        | env path | CL                                                                    
 `ftl_fs` (env)       | `FTL_OWN_SESSION_DIR`           | `state`        | env path | CL                                                                    

### 20.2 Other integration

 v1 name              | v2 name                         | module         | type     | rationale                                                             
----------------------|---------------------------------|----------------|----------|-----------------------------------------------------------------------
 `fzf_viewer`         | `ftl_view_fzf_as_viewer`        | `view`         | bool     | CL                                                                    

---

## 21. Plugin-Defined Globals (per-plugin)

Each plugin gets its own `ftl_plugin_<name>_*` namespace. The pattern: `ftl_plugin_<plugin_name>_<purpose>`.

### 21.1 Filter plugins

 v1 name                       | v2 name                                   | module        | type   | rationale                                                                         
-------------------------------|-------------------------------------------|---------------|--------|-----------------------------------------------------------------------------------
 `keep` (in every filter)      | `ftl_plugin_<name>_keep`                  | `plug` `filt` | assoc  | NS; **v1 had name collision** — every filter used `keep`                          
 `PWDS`                        | `ftl_plugin_<name>_active_dirs`           | `plug` `filt` | assoc  | CL; "PWDS" is opaque — these are the directories where the filter has a keep-list 
 `PWDR`                        | `ftl_plugin_<name>_active_dirs_recursive` | `plug` `filt` | assoc  | CL; "PWDR" = "PWDS Recursive"                                                     
 `fexts` (by_extension)        | `ftl_plugin_by_extension_selected`        | `plug` `filt` | assoc  | CL                                                                                
 `fnexts` (by_no_extension)    | `ftl_plugin_by_no_extension_hidden`       | `plug` `filt` | assoc  | CL                                                                                
 `ftl_min_size` (by_size)      | `ftl_plugin_by_size_min_bytes`            | `plug` `filt` | int    | CL                                                                                

### 21.2 Etag plugins

 v1 name                       | v2 name                                   | module        | type   | rationale                                                                         
-------------------------------|-------------------------------------------|---------------|--------|-----------------------------------------------------------------------------------
 `git_tags` (git etag)         | `ftl_plugin_git_status_map`               | `plug` `etag` | assoc  | CL                                                                                
 `is_git` (git etag)           | `ftl_plugin_git_in_repo`                  | `plug` `etag` | bool   | CL                                                                                
 `ext_dates` (date etag)       | `ftl_plugin_date_dates`                   | `plug` `etag` | assoc  | CL; "ext_" prefix is misleading (means "external" but conflicts with extension)   
 `ext_lines` (lines etag)      | `ftl_plugin_lines_counts`                 | `plug` `etag` | assoc  | CL                                                                                
 `ext_sizes` (image_size etag) | `ftl_plugin_image_size_dims`              | `plug` `etag` | assoc  | CL                                                                                
 `tmsu_untags` (tmsu etag)     | `ftl_plugin_tmsu_untagged`                | `plug` `etag` | assoc  | CL                                                                                

### 21.3 Binding plugins

 v1 name                       | v2 name                                   | module        | type   | rationale                                                                         
-------------------------------|-------------------------------------------|---------------|--------|-----------------------------------------------------------------------------------
 `leader_help_index`           | `ftl_plugin_leader_help_index`            | `plug` `kbd`  | int    | NS                                                                                
 `SAF` (virtual_entries)       | `ftl_plugin_virtual_entries_save_as_name` | `plug` `kbd`  | string | CL; "SAF" is opaque                                                               
 `fzf_to_search`               | `ftl_plugin_fzf_search_query`             | `plug` `kbd`  | string | CL                                                                                
 `fzf_answer`                  | `ftl_plugin_fzf_search_response`          | `plug` `kbd`  | string | CL                                                                                
 `fzf_total_count`             | `ftl_plugin_fzf_search_total`             | `plug` `kbd`  | int    | CL                                                                                
 `fzf_match_count`             | `ftl_plugin_fzf_search_match_count`       | `plug` `kbd`  | int    | CL                                                                                
 `fzf_entries`                 | `ftl_plugin_fzf_search_entries`           | `plug` `kbd`  | string | CL                                                                                
 `fzf_rq`                      | `ftl_plugin_fzf_search_action`            | `plug` `kbd`  | string | CL; "rq" = "request" — spell out                                                  

---

## 22. Serialized State Files

These aren't variables but file paths used for cross-process state. v2 keeps the same approach (Bash-sourceable files) but with consistent naming.

### 22.1 v1 file paths → v2 file paths

 v1 path                   | v2 path                                     | format                     | rationale                                                    
---------------------------|---------------------------------------------|----------------------------|--------------------------------------------------------------
 `$fs/ftl`                 | `$ftl_state_session_dir/state.sh`           | Bash source                | CL; "ftl" is the filename — rename to "state.sh" for clarity 
 `$fs/tags`                | `$ftl_state_session_dir/selection.sh`       | Bash source (`declare -p`) | CL; "tags" is ambiguous                                      
 `$ftl_info_file` (mktemp) | `$ftl_state_session_dir/info.sh`            | Bash source                | CL; consolidate (no mktemp)                                  
 `$fsp/stagsi`             | `$ftl_state_shared_dir/selection_revision`  | plain int                  | CL                                                           
 `$fsp/fs`                 | `$ftl_state_shared_dir/current_session_dir` | path                       | CL; "fs" is opaque                                           
 `$fsp/pane`               | `$ftl_state_shared_dir/primary_pane_id`     | pane id                    | CL                                                           
 `$pfs/panes`              | `$ftl_state_parent_dir/child_pane_ids`      | newline-separated          | CL; note: in v1 this was in `$pfs` not `$fsp`                
 `$fs/history`             | `$ftl_state_session_dir/history`            | newline paths              | NS                                                           
 `$fs/log`                 | `$ftl_state_session_dir/log`                | text                       | NS                                                           
 `$fs/errors_log`          | `$ftl_state_session_dir/errors.log`         | text                       | NS                                                           
 `$fs/cmd_log`             | `$ftl_state_session_dir/command.log`        | text                       | CL                                                           
 `$fs/command_names`       | `$ftl_state_session_dir/command_names.txt`  | newline                    | CL                                                           
 `$fs/bash_command`        | `$ftl_state_session_dir/bash_command.sh`    | Bash source                | CL                                                           
 `$fs/permissions`         | `$ftl_state_session_dir/permissions.txt`    | newline                    | CL                                                           
 `$fs/load_sel`            | `$ftl_state_session_dir/load_selection.txt` | newline paths              | CL                                                           
 `$fs/BULK`                | `$ftl_state_session_dir/bulk_create.txt`    | newline                    | CL                                                           
 `$fs/cmv_$SECONDS`        | `$ftl_state_session_dir/copy_move_list.txt` | paths                      | CL                                                           
 `$fs/ntags_*`             | `$ftl_state_session_dir/class_lists/`       | files                      | CL; reorganize into subdirectory                             
 `$fs/lock_preview/`       | `$ftl_state_session_dir/locked_previews/`   | files                      | CL                                                           
 `$fs/mnt/`                | `$ftl_state_session_dir/mounts/`            | dirs                       | CL                                                           
 `$ftl_root/marks`         | `$FTL_STATE_DIR/shared/marks`               | newline paths              | CL; move to `shared/`                                        
 `$ftl_root/history`       | `$FTL_STATE_DIR/shared/history`             | newline paths              | CL; move to `shared/`                                        
 `$ftl_root/cmd_history`   | `$FTL_STATE_DIR/shared/command_history`     | newline                    | CL                                                           
 `$ftl_root/thumbs/`       | `$FTL_CACHE_DIR/thumbs/`                    | files                      | CL; move to cache dir (with LRU)                             

### 22.2 Serialized variable names inside files

When v1 serializes state to `$fs/ftl`, it uses bare names like `sdir=`, `sindex=`, `ftag=`. v2 uses the namespaced names:

 v1 serialized name       | v2 serialized name                                                  | in file                                              
--------------------------|---------------------------------------------------------------------|------------------------------------------------------
 `sdir`                   | `ftl_state_current_path`                                            | `state.sh`                                           
 `sindex`                 | `ftl_state_cursor_index`                                            | `state.sh`                                           
 `n`                      | `ftl_state_current_path`                                            | `state.sh`                                           
 `ftag`                   | `ftl_filt_active_glyph`                                             | `state.sh`                                           
 `show_size`              | `ftl_state_show_size_mode`                                          | `state.sh`                                           
 `prev_cb`                | `ftl_state_preview_callback`                                        | `state.sh`                                           
 `etag`                   | `ftl_state_etag_enabled`                                            | `state.sh`                                           
 `etag_s`                 | `ftl_etag_source_name`                                              | `state.sh`                                           
 `etag_cb`                | `ftl_etag_callback`                                                 | `state.sh`                                           
 `dirmode`                | `ftl_state_dir_preview_mode`                                        | `state.sh`                                           
 `filter_ext`             | `ftl_filt_external_name`                                            | `state.sh`                                           
 `vmode[tab]`             | `ftl_tab_view_mode[$ftl_state_current_tab_index]`                   | `state.sh`                                           
 `sort_type[tab]`         | `ftl_tab_sort_type[$ftl_state_current_tab_index]`                   | `state.sh`                                           
 `filters[tab]`           | `ftl_tab_filter_1[$ftl_state_current_tab_index]`                    | `state.sh`                                           
 `filters2[tab]`          | `ftl_tab_filter_2[$ftl_state_current_tab_index]`                    | `state.sh`                                           
 `lmode[tab]`             | `ftl_tab_listing_mode[$ftl_state_current_tab_index]`                | `state.sh`                                           
 `hidden[tab]`            | `ftl_tab_show_hidden[$ftl_state_current_tab_index]`                 | `state.sh`                                           
 `rfilters[tab]`          | `ftl_tab_filter_reverse[$ftl_state_current_tab_index]`              | `state.sh`                                           
 `ntfilter[tab]`          | `ftl_tab_filter_image_negate[$ftl_state_current_tab_index]`         | `state.sh`                                           
 `lignore`, `lkeep`       | `ftl_filt_listing_hide_exts`, `ftl_filt_listing_keep_exts`          | `state.sh` (via `declare -p`)                        

---

## 23. Removed / Merged / Renamed Variables

### 23.1 Removed (v1 bugs or unused)

 v1 name                  | reason                                                              | replacement                                          
--------------------------|---------------------------------------------------------------------|------------------------------------------------------
 `ftl_cmds`               | Unused — defined and touched but never read                         | None                                                 
 `pdhl`                   | Buggy — used as boolean but `pdh()` writes to `ftl_log` not `$pdhl` | `FTL_DEBUG=1` env var + `ftl::log::debug`            
 `pop_help`               | Buggy — `ftl_help()` checks `help_pop` not `pop_help`               | `ftl_cfg_help_in_popup` (with the function fixed)    

### 23.2 Merged

 v1 names                 | v2 name                                                             | reason                                               
--------------------------|---------------------------------------------------------------------|------------------------------------------------------
 `E1`, `E2`, `E3`, `E4`   | `ftl_kbd_esc_seq_bytes` (array)                                     | 4 single-char vars → 1 array                         

### 23.3 Split (v1 had one var serving two purposes)

 v1 name                  | v2 names                                                            | reason                                               
--------------------------|---------------------------------------------------------------------|------------------------------------------------------
 `tags_size` (variable)   | `ftl_selection_total_bytes`                                         | Variable                                             
 `tags_size` (function)   | `ftl::selection::adjust_size`                                       | Function — v1 had name collision                     

### 23.4 Recategorized (moved from cfg to state, or vice versa)

Several v1 "config" variables are actually runtime state (toggled at runtime, not set at startup). v2 moves them to the `state` module:

 v1 name (was cfg)        | v2 name (now state)                                                 | reason                                               
--------------------------|---------------------------------------------------------------------|------------------------------------------------------
 `dirmode`                | `ftl_state_dir_preview_mode`                                        | Cycled at runtime via `zd0`-`zd5`                    
 `extmode`                | `ftl_state_alt_preview_mode`                                        | Cycled at runtime via `z1`-`z5`                      
 `zoom`                   | `ftl_state_preview_zoom_index`                                      | Cycled at runtime via `z+`                           
 `line_color`             | `ftl_state_line_color_current`                                      | Mutated by `goto_entry`                              
 `cursor_color`           | `ftl_state_cursor_color_current`                                    | Mutated by `incremental_search`                      
 `show_size`              | `ftl_state_show_size_mode`                                          | Cycled at runtime via `zs`                           
 `etag`                   | `ftl_state_etag_enabled`                                            | Toggled at runtime via `zt`                          
 `pdf_prev_image`         | `ftl_state_pdf_preview_as_image`                                    | Toggled at runtime via `zmp`                         
 `FTLI_Z`                 | `ftl_state_image_zoomed`                                            | Toggled at runtime via `zz`                          
 `prev_all`               | `ftl_state_preview_pane_visible`                                    | Toggled at runtime via `zv`                          

Conversely, some v1 "state" variables are actually config (set once at startup):

 v1 name (was state)      | v2 name (now cfg)                                                   | reason                                               
--------------------------|---------------------------------------------------------------------|------------------------------------------------------
 `marks` (initial values) | `ftl_cfg_default_marks`                                             | The defaults are config; runtime additions are state 

---

## 24. Summary Statistics

### 24.1 Variable counts

 category             | v1 count | v2 count | change                                                                                                   
----------------------|----------|----------|----------------------------------------------------------------------------------------------------------
 Environment & loader | 4        | 10       | +6 (added `FTL_STATE_DIR`, `FTL_CACHE_DIR`, `FTL_LIB_DIR`, `FTL_PLUGIN_DIR`, `FTL_DEBUG`, `FTL_PROFILE`) 
 Paths                | 6        | 5        | -1 (removed `ftl_cmds`)                                                                                  
 Behavior options     | ~35      | ~35      | 0 (renamed, not added/removed)                                                                           
 Glyph tables         | 4        | 4        | 0 (fixed `sglyph` to 3 entries)                                                                          
 Filter regexes       | 3        | 3        | 0                                                                                                        
 FZF options          | 5        | 5        | 0                                                                                                        
 External commands    | ~30      | ~30      | 0                                                                                                        
 Key binding globals  | 2        | 2        | 0                                                                                                        
 Assoc array config   | 4        | 4        | 0                                                                                                        
 Core runtime state   | ~25      | ~25      | 0                                                                                                        
 Per-pane fs state    | 5        | 5        | 0                                                                                                        
 Keyboard & input     | ~15      | ~12      | -3 (merged `E1`-`E4` into array)                                                                         
 Listing & rendering  | ~30      | ~30      | 0                                                                                                        
 Path parsing         | 8        | 8        | 0                                                                                                        
 Selection / tags     | 8        | 8        | 0                                                                                                        
 Tab state            | 10       | 10       | 0                                                                                                        
 Filter state         | 12       | 12       | 0                                                                                                        
 Preview / pane       | ~25      | ~25      | 0                                                                                                        
 Tmux / IPC           | 7        | 7        | 0                                                                                                        
 External integration | 8        | 8        | 0                                                                                                        
 Plugin-defined       | ~25      | ~25      | 0                                                                                                        
 **Total**            | **~265** | **~264** | **-1**                                                                                                   

### 24.2 Module distribution (v2)

 module  | variable count | notes                               
---------|----------------|-------------------------------------
 `cfg`   | ~85            | All user-tunable config             
 `state` | ~30            | Cross-module runtime state          
 `kbd`   | ~20            | Keyboard/input                      
 `list`  | ~25            | Listing & rendering                 
 `pane`  | ~20            | Tmux pane management                
 `view`  | ~20            | Preview & view modes                
 `sel`   | ~10            | Selection/tags                      
 `tab`   | ~10            | Tab state                           
 `filt`  | ~15            | Filter pipeline                     
 `etag`  | ~6             | Etag dispatch                       
 `mark`  | ~3             | Bookmarks & history                 
 `log`   | ~2             | Logging                             
 `plug`  | ~25            | Plugin-owned (per-plugin namespace) 
 `gen`   | ~2             | Generators                          
 `cmd`   | ~3             | Command prompt                      
 `util`  | ~0             | Utilities (no state)                
 `boot`  | ~2             | Bootstrap                           

### 24.3 Naming pattern distribution (v2)

 pattern                        | count | example                                           
--------------------------------|-------|---------------------------------------------------
 `ftl_cfg_*`                    | ~85   | `ftl_cfg_editor`, `ftl_cfg_key_timeout`           
 `ftl_state_*`                  | ~30   | `ftl_state_pwd`, `ftl_state_cursor_index`         
 `ftl_kbd_*`                    | ~20   | `ftl_kbd_trie`, `ftl_kbd_current_key`             
 `ftl_list_*`                   | ~25   | `ftl_list_entries`, `ftl_list_window_top`         
 `ftl_pane_*`                   | ~20   | `ftl_pane_self_id`, `ftl_pane_height`             
 `ftl_view_*`                   | ~20   | `ftl_view_preview_id`, `ftl_view_media_pid`       
 `ftl_sel*` / `ftl_selection_*` | ~10   | `ftl_selection_tags`, `ftl_selection_total_bytes` 
 `ftl_tab_*`                    | ~10   | `ftl_tab_directories`, `ftl_tab_filter_1`         
 `ftl_filt_*`                   | ~15   | `ftl_filt_pipeline_list`, `ftl_filt_active_glyph` 
 `ftl_etag_*`                   | ~6    | `ftl_etag_source_name`                            
 `ftl_mark_*`                   | ~3    | `ftl_mark_session_marks`                          
 `ftl_log_*`                    | ~2    | `ftl_log_debug_pane_id`                           
 `ftl_plugin_*`                 | ~25   | `ftl_plugin_bytag_keep`                           
 `ftl_gen_*`                    | ~2    | `ftl_gen_dir`                                     
 `FTL_*` (env)                  | ~10   | `FTL_CONFIG_DIR`, `FTL_PID`                       

### 24.4 Key rename patterns

 pattern               | v1 examples                                                                      | v2 pattern                        | reason      
-----------------------|----------------------------------------------------------------------------------|-----------------------------------|-------------
 Single-letter vars    | `n`, `f`, `e`, `b`, `p`, `R`, `C`, `h`, `x`                                      | Spell out                         | Readability 
 Cryptic abbreviations | `pgen`, `ghist`, `pdhl`, `qd`, `tsc`, `hal`, `hpl`, `ftag`                       | Spell out                         | Readability 
 `_0` suffix           | `line_color0`, `cursor_color0`, `sort_type0`, `rfilter0`, `MD_RENDER0`           | `_default`                        | Clarity     
 `_P` / `_H` suffix    | `COLS_P`, `FTLI_H`, `FTLI_W`                                                     | `_preview` / `_height` / `_width` | Clarity     
 All-caps scalars      | `KEY_TIMEOUT`, `SHELL_H`, `RM`, `EDITOR`                                         | lowercase with prefix             | Convention  
 `in_*` flags          | `in_pdir`, `in_viprev`, `in_ftli`, `in_Q`                                        | `ftl_*_is_*`                      | Clarity     
 Ambiguous names       | `tags` (selection vs TMSU), `file` (index vs path), `lines` (window vs terminal) | Disambiguate                      | Correctness 

### 24.5 Bug fixes in v2

 v1 bug                                                             | v2 fix                                                                         
--------------------------------------------------------------------|--------------------------------------------------------------------------------
 `$MD_DIR_RENDER="vmd"` (line 113) — leading `$` makes it a command | `ftl_cfg_markdown_dir_renderer="vmd"` (proper assignment)                      
 `pop_help` vs `help_pop` mismatch                                  | Both renamed to `ftl_cfg_help_in_popup` and the function fixed                 
 `pdhl` used as boolean but `pdh()` writes to `ftl_log`             | Replaced with `FTL_DEBUG=1` env var; `ftl::log::debug` writes to proper log    
 `ftl_cmds` defined but unused                                      | Removed                                                                        
 `sglyph` missing date entry                                        | `ftl_cfg_glyph_sort` has 3 entries                                             
 `tags_size` name collision (var + function)                        | Variable: `ftl_selection_total_bytes`; function: `ftl::selection::adjust_size` 
 `keep` collision (every filter uses `keep`)                        | Each filter uses `ftl_plugin_<name>_keep`                                      
 `E1`-`E4` four separate vars                                       | Merged into `ftl_kbd_esc_seq_bytes` array                                      

---

## Usage Notes

### How to read this table

1. **Find the v1 variable** in the leftmost column of the appropriate category section.
2. **The v2 name** (second column) is what to use in v2 code.
3. **The module** (third column) indicates which `lib/core/<module>.sh` file owns the variable.
4. **The type** (fourth column) is the Bash type: `scalar`, `int`, `bool`, `string`, `array`, `assoc`, `path`, `pid`, `regex`, `function`, `env flag`, `env path`, etc.
5. **The rationale** (fifth column) explains the rename if non-obvious. Common abbreviations:
   - **NS** = namespace added (just prefixed)
   - **CL** = clarified/renamed for readability
   - **KV** = keep v1 value (default unchanged)

### Migration tooling

A `tools/migrate-variables.sh` script can automate the rename for v1 plugins:

```bash
#!/bin/bash
# tools/migrate-variables.sh
# Renames v1 variables to v2 names in a given file.
# Usage: migrate-variables.sh <file.sh>

sed -i \
    -e 's/\bFTLRC_LOADED\b/FTL_BOOTSTRAP_DONE/g' \
    -e 's/\bFTL_CFG\b/FTL_CONFIG_DIR/g' \
    -e 's/\bpgen\b/ftl_gen_dir/g' \
    -e 's/\bftl_root\b/ftl_state_dir/g' \
    -e 's/\bghist\b/ftl_state_global_history_file/g' \
    -e 's/\bthumbs\b/ftl_cache_thumb_dir/g' \
    -e 's/\bKEY_TIMEOUT\b/ftl_cfg_key_timeout/g' \
    -e 's/\bshell_h\b/ftl_cfg_shell_pane_height/g' \
    -e 's/\bshell_v\b/ftl_cfg_shell_pane_width/g' \
    -e 's/\bauto_selection\b/ftl_cfg_auto_sync_selection/g' \
    -e 's/\bmy_pane\b/ftl_pane_self_id/g' \
    -e 's/\bpane_id\b/ftl_pane_preview_id/g' \
    -e 's/\btags_size\b/ftl_selection_total_bytes/g' \
    -e 's/\bstagsi\b/ftl_selection_revision/g' \
    -e 's/\bostagsi\b/ftl_selection_other_revision/g' \
    -e 's/\bdir_file\b/ftl_state_cursor_memory/g' \
    -e 's/\bmime\b/ftl_list_mime_cache/g' \
    -e 's/\bpignore\b/ftl_view_preview_ignore_exts/g' \
    -e 's/\blignore\b/ftl_filt_listing_hide_exts/g' \
    -e 's/\blkeep\b/ftl_filt_listing_keep_exts/g' \
    -e 's/\btail\b/ftl_view_vim_tail_commands/g' \
    -e 's/\btags\b/ftl_selection_tags/g' \
    -e 's/\bntags\b/ftl_selection_class_index/g' \
    -e 's/\bftl_env\b/ftl_state_child_env/g' \
    -e 's/\bdu_size\b/ftl_list_dir_size_cache/g' \
    -e 's/\bselection\b/ftl_selection_current/g' \
    -e 's/\bfs\b/ftl_state_session_dir/g' \
    -e 's/\bpfs\b/ftl_state_parent_dir/g' \
    -e 's/\bofs\b/ftl_state_other_session_dir/g' \
    -e 's/\bfsp\b/ftl_state_shared_dir/g' \
    -e 's/\bPPWD\b/ftl_state_previous_pwd/g' \
    -e 's/\bREPLY\b/ftl_kbd_current_key/g' \
    -e 's/\bOREPLY\b/ftl_kbd_raw_key/g' \
    -e 's/\bR\b/ftl_state_pending_input/g' \
    "$1"
```

**Warning:** This is a starting point, not a complete solution. Many renames require context (e.g. `n` is a common loop variable; only the `path()` output `n` should be renamed). Manual review is essential.

### Compatibility layer

For gradual migration, a `compat/v1.sh` file can alias v1 names to v2 names:

```bash
# compat/v1.sh — v1 variable name shims
# Source this AFTER v2 init to make v1 plugins work.

# Note: these are one-way aliases (v1 name → v2 value).
# Changes via the v1 name won't propagate to v2.
# For full compat, use `declare -n` (namerefs) where possible.

n="$ftl_state_current_path"
f="$ftl_state_current_basename"
e="$ftl_state_current_extension"
b="$ftl_state_current_stem"
p="$ftl_state_current_dir"
mtype="$ftl_state_current_mime_type"

# These need namerefs to stay in sync
declare -n n="ftl_state_current_path"
declare -n f="ftl_state_current_basename"
# ...

# Arrays can't be nameref'd easily in Bash; copy them
files=("${ftl_list_entries[@]}")
nfiles=$ftl_list_entry_count
file=$ftl_state_cursor_index
tags=("${ftl_selection_tags[@]}")  # copy (won't sync back)
```

