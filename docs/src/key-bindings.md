# Key Bindings Reference

This is the complete binding reference, generated from the default
`etc/ftlrc`. Bindings are organized by **section** (the second argument
to `ftl::kbd::bind`). Press `c` inside ftl for a live, fzf-searchable
view of the same data. All keys are symbolic tokens; multi-key sequences
are space-separated.

## Move

| Key | Command | Description |
|-----|---------|-------------|
| `j` / `k` | `cursor_down` / `cursor_up` | down / up one entry |
| `h` / `l` | `cd_to_parent` / `cd_into_entry` | parent / into entry |
| `ENTER` | `enter_entry` | cd into dir or open file |
| `DOWN` / `UP` / `LEFT` / `RIGHT` | arrow equivalents | arrow-key movement |
| `PGUP` / `CTL-B` | `page_up` | page up |
| `PGDN` / `CTL-F` | `page_down` | page down |
| `ALT-J` / `ALT-K` | `scroll_preview_down` / `_up` | scroll preview |
| `J` / `K` | `scroll_fixed_preview_down` / `_up` | scroll fixed preview |
| `CTL-H` / `CTL-L` | `send_preview_left` / `_right` | send arrow to preview |
| `gg` / `G` | `goto_first_file` / `goto_last_file` | first / last |
| `gh` / `gl` | `goto_top_of_window` / `goto_bottom_of_window` | window top / bottom |
| `g LEADER` | `cycle_top_file_bottom` | cycle top/file/bottom |
| `gd` / `gD` | `goto_first_directory` / `cd_prompt` | first dir / cd prompt |
| `COUNT %` | `jump_by_percent` | jump to N% |
| `#` | `goto_by_index` | jump by index |
| `-` / `_` | `goto_next_same_extension` / `goto_next_diff_extension` | by extension |
| `yn` / `yN` | `goto_next_selected` / `goto_prev_selected` | next / prev tag |

## Selection

| Key | Command | Description |
|-----|---------|-------------|
| `yy` / `a` / `COUNT yy` | `flip_down` | tag down |
| `s` / `yu` / `COUNT s` | `flip_up` | tag up |
| `y1`–`y4` / `COUNT y1`–`y4` | `select_class_1`–`_4` | tag class N |
| `ya` / `yf` / `yd` | `select_all` / `select_all_files` / `select_all_directories` | select all variants |
| `ye` / `yE` | `select_same_extension` / `_recursive` | by extension |
| `yii` / `yiI` | `select_images_via_sxiv` / `_recursive` | images via sxiv |
| `yif` / `yiF` | `select_via_fzf` / `select_recursive_via_fzf` | fzf-select |
| `yie` / `yiE` | `select_extension_via_fzf` / `_recursive` | fzf by extension |
| `yc` / `yC` | `untag_all` / `untag_via_fzf` | clear / fzf-clear |
| `ytc` | `copy_paths_to_clipboard` | copy to clipboard |
| `gy` | `goto_selection_via_fzf` | fzf over selection |

## Filter

| Key | Command | Description |
|-----|---------|-------------|
| `fe` | `select_external_filter` | pick external filter |
| `fd` | `set_dir_filter` | directory filter regex |
| `ff` / `fF` | `set_filter_1` / `set_filter_2` | file filters 1 / 2 |
| `fr` | `set_reverse_filter` | reverse filter |
| `fy` | `filter_to_tagged` | only tagged |
| `fc` | `clear_all_filters` | clear all |

## Find

| Key | Command | Description |
|-----|---------|-------------|
| `/` | `find_in_dir` | incremental search |
| `n` / `N` | `find_next` / `find_previous` | next / prev match |
| `gff` / `b` | `find_via_fzf` | fzf in current dir |
| `gfF` / `B` | `find_via_fzf_recursive` | fzf recursive |
| `gfd` | `find_dirs_via_fzf` | fzf directories |
| `gfa` / `gfA` | `find_via_frf` / `_recursive` | fuzzy/regex find |
| `gfi` / `gfI` | `goto_image_via_sxiv` / `_recursive` | image goto via sxiv |
| `gfu` | `goto_image_via_fzf` | image goto via fzf |
| `grr` | `rg_open_file` | ripgrep, open file |
| `grf` | `rg_goto_single_match` | ripgrep, single match |
| `grt` | `rg_goto_file` | ripgrep, jump to file |
| `grl` | `rg_edit_files` | ripgrep, edit files |
| `gL` | `follow_symlink` | follow symlink |

## View

| Key | Command | Description |
|-----|---------|-------------|
| `zv` | `toggle_preview_pane` | show/hide preview |
| `+` / `z+` | `cycle_preview_size` | cycle size |
| `zz` | `toggle_image_zoom` | zoom image |
| `zM` | `refresh_preview` | refresh preview |
| `zff` / `zfc` | `toggle_fixed_preview` / `_ftl::prev::clear_fixed` | fixed preview on/off |
| `z1`–`z5` | `set_preview_mode_1`–`_5` | alt preview mode |
| `Z1`–`Z5` | `set_full_preview_mode_1`–`_5` | full-screen alt mode |
| `zd0`–`zd5` | `set_directory_mode0`–`_5` | directory preview modes |
| `zma` / `zmn` / `zmi` / `zmI` / `zmP` / `zmd` / `zmD` / `zmp` | view-mode commands | view-mode toggles |
| `zo` / `zO` | `sort_entries` / `_reversed` | sort type / reversed |
| `zg` / `zs` / `zS` | `show_stat` / `show_size` / `hide_size` | stat / size |
| `zt` / `zT` | `toggle_etags` / `select_etag_source` | etags |
| `z.` | `show_hidden` | dot-files |
| `zeh` / `zeH` / `zeo` / `zeO` / `zec` / `zes` | extension commands | extension hide/only/clear/sort |
| `z STAR` | `set_listing_depth` | max listing depth |
| `zep` | `toggle_ext_preview` | extension preview |

## Pane

| Key | Command | Description |
|-----|---------|-------------|
| `CTL-W h` / `CTL-W l` / `CTL-W j` | `pane_left` / `_right` / `_down` | open pane |
| `CTL-W H` / `CTL-W L` | `pane_left_keep_focus` / `_right_keep_focus` | open, keep focus |
| `CTL-W n` / `gp` | `goto_next_pane` | next pane |

## Shell

| Key | Command | Description |
|-----|---------|-------------|
| `Ss` / `CTL-W ss` | `open_shell` | shell pane |
| `Sv` / `CTL-W sv` | `open_vertical_shell` | vertical shell |
| `Sz` / `CTL-W sz` | `open_zoomed_shell` | zoomed shell |
| `S!` / `CTL-W !` | `view_session_shell` | session shell |
| `Sq` / `CTL-W sq` | `close_shell_pane` | close shell |
| `Sf` / `CTL-W sf` | `send_files_to_shell` | send selection to shell |
| `SS` / `CTL-W sS` | `open_shell_with_files` | open shell with selection |
| `gS` / `CTL-W sg` | `synch_shell_cwd` | cd ftl to shell cwd |
| `Sp` / `CTL-Z sp` | `run_command_in_pane` | run command in pane |

## Tabs

| Key | Command | Description |
|-----|---------|-------------|
| `PARAGRAPH` (§) | `new_tab` | new tab |
| `TAB` / `gt` | `next_tab` | next tab |
| `gT` | `prev_tab` | previous tab |
| `COUNT gt` | `goto_tab` | go to tab N |

## Marks

| Key | Command | Description |
|-----|---------|-------------|
| `m` | `set_mark` | set mark |
| `QUOTE` (') | `goto_mark` | go to mark |
| `STAR` (*) | `goto_mark_new_tab` | go to mark, new tab |
| `gm` | `goto_mark_via_fzf` | fzf marks |
| `MM` | `add_persistent_mark` | add persistent mark |
| `gM` | `goto_persistent_via_fzf` | fzf persistent marks |
| `Mc` | `clear_persistent_marks` | clear persistent |

## Project marks

Per-directory bookmarks stored in `.ftl_project_marks` files. See
[user guide: marks & history](user-guide/marks-history.md#project-marks)
for the full mechanism.

| Key | Command | Description |
|-----|---------|-------------|
| `Mpp` | `ftl::plugin::project_marks::pmark` | add current entry to local `.ftl_project_marks` |
| `Mpe` | `ftl::plugin::project_marks::pmarks_edit` | edit the local mark file |
| `gpp` | `ftl::plugin::project_marks::pmarks_fzf` | fzf over marks (parents + children) |
| `gps` | `ftl::plugin::project_marks::pmarks_subdir_fzf` | fzf over marks (children only) |

## History

| Key | Command | Description |
|-----|---------|-------------|
| `Hh` | `goto_session_history` | session history |
| `HH` / `DIAERESIS` (¨) | `goto_global_history` | global history |
| `Hs` | `goto_global_history_subdir` | global, current subdir |
| `He` | `edit_global_history` | edit history |
| `Hc` | `clear_global_history` | clear history |

## Media

| Key | Command | Description |
|-----|---------|-------------|
| `ea` | `show_in_background_player` | background media player |
| `eA` | `show_via_fzf_viewer` | fzf a viewer |
| `ek` | `kill_media_player` | kill sound preview |
| `eq` | `queue_to_player` | queue to player |
| `ee` / `er` / `ew` | `external_viewer_mode_1` / `_2` / `_3` | external viewer modes |

## Entry (file operations)

| Key | Command | Description |
|-----|---------|-------------|
| `d` | `delete_selection` | delete |
| `if` / `id` / `iD` / `ib` | `create_file` / `create_dir_no_cd` / `create_dir_and_cd` / `create_bulk` | create |
| `R` | `rename_selection` | rename |
| `LEADER r i` | `ftl::plugin::inline_rename::enter` | inline rename mode (modal) |
| `w` | `copy_to_prompted` | copy to prompted |
| `pp` / `pm` | `copy_selection_here` / `move_selection_here` | copy / move here |
| `PP` / `PM` | `copy_to_preset` / `move_to_preset` | to preset |
| `pz` / `pZ` | `move_via_fzf` / `move_to_subdir_via_fzf` | move via fzf |
| `pop` / `pom` | `copy_to_other_tab` / `move_to_other_tab` | to other tab |
| `xl` | `symlink_selection` | symlink |
| `xmr` / `xmw` / `xmx` / `xmM` | `chmod_toggle_read` / `_write` / `_exec` / `chmod_via_scim` | chmod |
| `xh` / `xH` | `hex_view` / `hex_edit` | hex |
| `xv` / `xV` / `XV` | `edit_in_vim` / `_window` / `_shared_vim_window` | vim |
| `xc` | `cat_in_terminal` | cat |
| `xp` | `preview_with_command` | preview with command |

## ftl meta

| Key | Command | Description |
|-----|---------|-------------|
| `q` | `quit_ftl` | quit |
| `Q` / `ZZ` | `quit_all` | quit all |
| `ZS` | `quit_keep_shell` | quit, keep shell |
| `ZP` | `quit_keep_preview` | quit, keep preview |
| `c` | `ftl::kbd::show_bindings` | show bindings |
| `:` | `open_command_prompt` | command prompt |
| `$` | `detach_editor_preview` | detach editor preview |
| `?` | `ftl::cmd::show_help` | man page |
| `INVERSED_QUESTION_MARK` (¿) | `ftl::log::show_debug_pane` | debug pane |

## SIG (reserved for ftl internal use)

| Key | Command | Description |
|-----|---------|-------------|
| `å` | `ftl::ipc::handle_pane_focus` | handle pane event |
| `Ä` | `ftl::ipc::handle_preview_request` | handle pane preview |
| `r` (in SIG context) | `ftl::ipc::handle_refresh` | preview pane signal |

> The characters `å`, `Å`, `ä`, `Ä` are reserved for ftl's tmux-signal
> IPC — do not bind them yourself.
