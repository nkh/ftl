# Configuration Reference

All ftl configuration lives in `~/.config/ftl/etc/ftlrc`, sourced at
startup by `ftl_setup`. Every config variable is prefixed `ftl_cfg_*`;
runtime state uses `ftl_state_*`. You can override anything by creating
your own `~/.config/ftl/ftlrc` that sources the default and then mutates
values.

## Paths and directories

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_gen_dir` | `$FTL_CFG/etc/generators` | location of preview generator scripts |
| `ftl_state_dir` | `$FTL_CFG/var` | runtime state directory |
| `FTL_STATE_DIR` | `$ftl_state_dir` | exported form, used by children |
| `FTL_CACHE_DIR` | `$ftl_state_dir/thumbs` | thumbnail cache |
| `ftl_state_global_history_file` | `$ftl_state_dir/history` | global dir-visit history |
| `ftl_cache_thumb_dir` | `$ftl_state_dir/thumbs` | thumbnail cache (alias) |

## Behavior

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_key_timeout` | `1` | seconds for key read timeout |
| `ftl_cfg_shell_pane_height` | `40%` | shell pane height (tmux size spec) |
| `ftl_cfg_shell_pane_width` | `60%` | shell pane width |
| `ftl_cfg_auto_sync_selection` | `1` | sync selection between panes |
| `ftl_cfg_time_event_interval` | `0` | seconds between time events (0=off) |
| `ftl_cfg_debug_log_file` | (empty) | if set, debug messages also go here |
| `ftl_cfg_preview_zoom_levels` | `(85 70 50 30)` | preview pane sizes (%) |
| `ftl_cfg_move_step_size` | `4` | entries moved by step commands |
| `ftl_cfg_auto_select_filename` | `README` | file to auto-select on cd |
| `ftl_cfg_mount_archives` | `0` | mount archives via fuse-archive |
| `ftl_cfg_quick_display_threshold` | `512` | flash count threshold during scan |
| `ftl_cfg_default_reverse_filter` | (empty) | default reverse filter per tab |
| `ftl_cfg_show_entry_index` | `1` | show the entry-index column |
| `ftl_cfg_show_date_in_header` | `1` | show date in the header |
| `ftl_cfg_show_tar_info` | `0` | show tar info |
| `ftl_cfg_help_in_popup` | `0` | show help in a popup |
| `ftl_cfg_bindings_in_popup` | `1` | show bindings in a popup |
| `ftl_cfg_bindings_display_width` | `150` | display width of the bindings table |

## Glyphs

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_glyph_sort` | `(⍺ 🡕)` | sort glyphs: alphanumeric, size |
| `ftl_cfg_glyph_image_mode` | `('' ᴵ ᴺ)` | image-mode glyphs |
| `ftl_cfg_glyph_listing_mode` | `('' ᵈ ᶠ)` | listing-mode glyphs (all/dir/file) |
| `ftl_cfg_glyph_tag_classes` | `('' ¹ ² ³ D)` | tag class glyphs |
| `ftl_cfg_line_color_default` | `\e[2;40;90m` | entry-index column color |
| `ftl_cfg_line_color_current` | `\e[2;40;90m` | current-entry index color |
| `ftl_cfg_line_color_highlight` | `\e[38;5;240m` | highlighted index color |
| `ftl_cfg_cursor_color_default` | `\e[7;34m` | cursor glyph color |
| `ftl_cfg_cursor_color_current` | `\e[7;34m` | current cursor color |
| `ftl_cfg_cursor_color_search` | `\e[7;35m` | search cursor color |
| `ftl_cfg_color_overrides` | `()` | LS_COLORS overrides per filename |

## Filters

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_default_sort_type` | `0` | 0=alpha, 1=size, 2=date |
| `ftl_cfg_default_sort_reversed` | (empty) | `-r` or empty |
| `ftl_cfg_sort_options` | (set in ftlrc) | sort flags per sort type |
| `ftl_cfg_image_extensions_regex` | `svg\|webp\|jpg\|...` | image regex |
| `ftl_cfg_media_extensions_regex` | `mp3\|mp4\|flv\|...` | media regex |
| `ftl_filt_listing_hide_exts` | `()` | extensions to hide |
| `ftl_filt_listing_keep_exts` | `()` | extensions to keep only |

## FZF

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_fzf_popup_opts` | `-p 90% --cycle ...` | popup fzf options |
| `ftl_cfg_fzf_pane_opts` | `--cycle --expect=ctrl-t ...` | pane fzf options |
| `ftl_cfg_fzf_sxiv_opts` | `-0 -1 -m --expect=ctrl-t ...` | sxiv fzf options |
| `ftl_cfg_fzf_listen_port` | `4466` | HTTP-polled fzf port |
| `ftl_cfg_fzf_listen_command` | `fd -H -I` | candidate generator |

## External commands

See [External Commands](external-commands.md) for the full table. Highlights:

| Variable | Default |
|----------|---------|
| `ftl_cfg_editor` | `vim -p` |
| `ftl_cfg_diff_tool` | `vimdiff` |
| `ftl_cfg_image_viewer` | `sxiv` |
| `ftl_cfg_delete_command` | `rm -rf` |
| `ftl_cfg_gui_media_player` | `vlc -f` |
| `ftl_cfg_terminal_media_player` | `mplayer -vo null` |
| `ftl_cfg_markdown_pager` | `less -R` |
| `ftl_cfg_json_viewer` | `jless` |
| `ftl_cfg_hex_viewer` / `ftl_cfg_hex_editor` | `hexdump` / `hexedit` |
| `ftl_cfg_disk_usage_tool` | `ncdu` |
| `ftl_cfg_mime_detector` | `mimemagic` |

## Key bindings

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_leader_key` | `BACKSLASH` | the leader key |
| `ftl_cfg_redo_key` | `.` | the redo key |
| `ftl_cfg_command_aliases` | `([csx]="split finfo \| xargs -0" ...)` | aliases for the `:` prompt |

## Etags

```bash
ftl_state_etag_enabled=0
# To enable git etags:
# source "$FTL_CFG/etc/etags/git"
# ftl_state_etag_enabled=1
```

The `zt` binding toggles etags on/off; `zT` selects the etag source.
