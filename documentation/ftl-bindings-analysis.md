# `ftl` Bindings — Grouping & Shortcut Analysis

> **Subject:** The complete binding set of `ftl` — 226 in `ftlrc` + 34 in `etc/bindings/` + 21 in `bindings/` = **~281 bindings**.
> **Purpose:** Analyze the current grouping scheme, identify problems (collisions, inconsistencies, missing mnemonics, under/over-used keys), and propose better groupings and shortcuts.
> **Companion documents:** `ftl-ftlrc-reference.md` (config reference), `ftl-missing-functionality.md` (missing features & proposed bindings).

---

## Table of Contents

1. [Current Binding Inventory](#1-current-binding-inventory)
2. [The 14 Section Model](#2-the-14-section-model)
3. [Key Usage Heatmap](#3-key-usage-heatmap)
4. [Problems with the Current Scheme](#4-problems-with-the-current-scheme)
5. [Proposed New Grouping](#5-proposed-new-grouping)
6. [Proposed Shortcut Reassignments](#6-proposed-shortcut-reassignments)
7. [Migration Path](#7-migration-path)
8. [Alternative Binding Schemes](#8-alternative-binding-schemes)

---

## 1. Current Binding Inventory

### 1.1 Counts by section (from `ftlrc` only)

| section     | count   | % of total   |
| ---------   | ------- | ------------ |
| `view`      | 48      | 21%          |
| `move`      | 32      | 14%          |
| `selection` | 31      | 14%          |
| `entry`     | 27      | 12%          |
| `shell`     | 18      | 8%           |
| `find`      | 18      | 8%           |
| `ftl`       | 10      | 4%           |
| `pane`      | 7       | 3%           |
| `media`     | 7       | 3%           |
| `marks`     | 7       | 3%           |
| `filter`    | 7       | 3%           |
| `history`   | 6       | 3%           |
| `tabs`      | 5       | 2%           |
| `SIG`       | 3       | 1%           |
| **total**   | **226** |              |

### 1.2 Plus auto-sourced plugins

| source                            | count                             | examples                                         |
| --------                          | -------                           | ----------                                       |
| `etc/bindings/leader`             | 5                                 | leader help (hh/hr/hn/hp), add-selection-to-file |
| `etc/bindings/leader_ftl`         | 15                                | compress/decompress/encrypt/optimize/mail/etc.   |
| `etc/bindings/leader_git`         | 8                                 | git etag/diff/add/find/tree/etc.                 |
| `etc/bindings/incremental_search` | 1                                 | `/` (overrides `find_entry` from ftlrc)          |
| `etc/bindings/fzf_search`         | 1                                 | `V` (experimental fzf-listen)                    |
| `etc/bindings/user_command`       | 1                                 | `\u` (run user command)                          |
| `etc/bindings/shred`              | 1                                 | `\fs` (shred)                                    |
| `etc/bindings/add_to_a_log`       | 2                                 | `\aa`/`\av`/`\ae` (log helpers)                  |
| `bindings/virtual_entries`        | 5                                 | `\vv`/`\vV`/`\ve`/`vf`/`\vd`                     |
| `bindings/tmsu`                   | 8                                 | `\t<t/f/g/m/q/r/s/LEADER>`                       |
| `bindings/fzf_pane_preview`       | 3                                 | `/` (overrides), `gfp`, `gfP`                    |
| `bindings/via_bash`               | 4                                 | `yx`/`yX`/`fx`/`fX`                              |
| `bindings/file_diff`              | 1                                 | `\vd`                                            |
| `bindings/change_mode`            | 1                                 | `xmm`                                            |
| `bindings/type_handlers`          | 0 (overrides `enter`/`move_left`) | archive mounting                                 |
| **total**                         | **55**                            |                                                  |

### 1.3 Grand total: ~281 bindings

---

## 2. The 14 Section Model

The current sections were chosen by the author based on vim-style mnemonic grouping. Let's examine each:

### 2.1 `ftl ftl` (10 binds) — meta commands

| key   | command             | purpose               |
| ----- | ---------           | ---------             |
| `?`   | `ftl_help`          | show man page         |
| `q`   | `quit_ftl`          | quit tab/pane/ftl     |
| `Q`   | `quit_all`          | quit everything       |
| `ZZ`  | `quit_all`          | vim-style quit all    |
| `ZS`  | `quit_keep_shell`   | quit, keep shell      |
| `ZP`  | `quit_keep_preview` | quit, keep preview    |
| `c`   | `k_bindings`        | show bindings         |
| `$`   | `editor_detach`     | detach editor preview |
| `:`   | `command_prompt`    | run command           |
| `¿`   | `pdh_show`          | debug pane            |

**Critique:** Well-organized. The `Z`-prefix for quit variants mirrors vim's `ZZ`/`ZQ`. The `¿` for debug is appropriately obscure. The `:` for command prompt is vim-standard.

### 2.2 `ftl entry` (27 binds) — file operations

| key   | command                  | purpose                |
| ----- | ---------                | ---------              |
| `d`   | `delete_selection`       | delete                 |
| `if`  | `create_file`            | create file            |
| `id`  | `create_dir_no_cd`       | create dir             |
| `iD`  | `create_dir`             | create dir + cd        |
| `ib`  | `create_bulk`            | bulk create            |
| `R`   | `rename`                 | rename                 |
| `w`   | `copy`                   | copy (prompt)          |
| `pp`  | `tag_copy`               | copy selection here    |
| `pm`  | `tag_move`               | move selection here    |
| `PP`  | `tag_copy_dest`          | copy to preset         |
| `PM`  | `tag_move_dest`          | move to preset         |
| `pz`  | `tag_move_fzf`           | move via fzf           |
| `pZ`  | `tag_move_fzf_sd`        | move to subdir via fzf |
| `pop` | `tag_copy_to_tab`        | copy to other tab      |
| `pom` | `tag_move_to_tab`        | move to other tab      |
| `xmr` | `chmod_ar`               | chmod +r               |
| `xmw` | `chmod_aw`               | chmod +w               |
| `xmx` | `chmod_ax`               | chmod +x               |
| `xmM` | `chmod_dialog`           | chmod via sc-im        |
| `xh`  | `hexview`                | hex view               |
| `xH`  | `hexedit`                | hex edit               |
| `xv`  | `vim_edit`               | vim                    |
| `xV`  | `vim_edit_window`        | vim in new window      |
| `XV`  | `vim_edit_shared_window` | vim in shared window   |
| `xc`  | `terminal_cat`           | cat                    |
| `xl`  | `link`                   | symlink                |
| `xp`  | `preview_with`           | preview with...        |

**Critique:** Several issues:

1. **`p` is overloaded.** `pp`/`pm`/`PP`/`PM`/`pz`/`pZ`/`pop`/`pom` all start with `p` but mean different things (paste here / paste to preset / paste to tab). The mnemonic is "put" (vim-style), but the variants are hard to remember.
2. **`x` is overloaded.** `xmr`/`xmw`/`xmx`/`xmM`/`xh`/`xH`/`xv`/`xV`/`XV`/`xc`/`xl`/`xp` all start with `x`. The mnemonic is unclear — maybe "eXecute" or "eXtended"?
3. **`i` for create is non-mnemonic.** Vim uses `i` for insert, but `if`/`id`/`iD`/`ib` don't obviously map to "create file/dir/bulk".
4. **`xmm` (from `change_mode` plugin) conflicts conceptually with `xmM`.** `xmM` is chmod-via-sc-im for the selection; `xmm` is chmod-via-whiptail for one entry. The capital/lowercase distinction is too subtle.
5. **`R` for rename** is good (vim-style).
6. **`d` for delete** is good but dangerous with the default `RM="rm -rf"`.

### 2.3 `ftl filter` (7 binds) — listing filters

| key   | command                  | purpose         |
| ----- | ---------                | ---------       |
| `fe`  | `set_filter_ext`         | external filter |
| `fy`  | `set_filter_only_tagged` | only tagged     |
| `fd`  | `set_filter_dir`         | dir filter      |
| `ff`  | `set_filter`             | filter 1        |
| `fF`  | `set_filter2`            | filter 2        |
| `fr`  | `set_filter_reverse`     | reverse filter  |
| `fc`  | `clear_filters`          | clear           |

**Critique:** Clean and consistent. `f`-prefix for filters, second letter is mnemonic (`e`xtension, `y` tagged, `d`ir, `f`ilter1, `F`ilter2, `r`everse, `c`lear). This is one of the best-organized sections.

### 2.4 `ftl find` (18 binds) — search

| key   | command                                           | purpose                    |
| ----- | ---------                                         | ---------                  |
| `/`   | `find_entry` (overridden by `incremental_search`) | find                       |
| `n`   | `find_next`                                       | next                       |
| `N`   | `find_previous`                                   | previous                   |
| `gff` | `find_fzf`                                        | fzf current dir            |
| `b`   | `find_fzf`                                        | fzf (alias)                |
| `gfF` | `find_fzf_all`                                    | fzf recursive              |
| `B`   | `find_fzf_all`                                    | fzf recursive (alias)      |
| `gfa` | `find_frf`                                        | fzf regexp/fuzzy           |
| `gfA` | `find_frf_all`                                    | fzf regexp/fuzzy recursive |
| `grr` | `open_rg`                                         | rg, open file              |
| `grf` | `go_rg_one_match`                                 | rg, single match           |
| `grt` | `go_rg`                                           | rg, goto file              |
| `grl` | `go_rgl`                                          | rg, edit files             |
| `gfd` | `find_fzf_dirs`                                   | fzf dirs only              |
| `gfi` | `image_go_sxiv`                                   | image goto (sxiv)          |
| `gfI` | `image_go_sxiv_rec`                               | image goto recursive       |
| `gfu` | `image_fzf`                                       | image goto (fzf)           |
| `gL`  | `follow_link`                                     | follow symlink             |

**Critique:**

1. **`g`-prefix overload.** `gff`/`gfF`/`gfa`/`gfA`/`grr`/`grf`/`grt`/`grl`/`gfd`/`gfi`/`gfI`/`gfu`/`gL` — 13 bindings start with `g`. The `g` is vim-style "goto", but the second letter (`f` for fzf, `r` for ripgrep) and third letter create a dense matrix.
2. **`b`/`B` as aliases for `gff`/`gfF`** — these are non-mnemonic. `b` for "buffer"? Unclear.
3. **`/` is overridden** by `incremental_search` (from `etc/bindings/`). So pressing `/` enters incremental search mode, not the simple `find_entry` prompt. The `find_entry` binding is effectively dead.
4. **`n`/`N` for next/previous** is vim-standard and good.
5. **`gL` for follow-link** breaks the `gf`/`gr` pattern. Should be `gl` or `gL` under a different prefix.

### 2.5 `ftl history` (6 binds)

| key             | command           | purpose                |
| -----           | ---------         | ---------              |
| `Hh`            | `history_go`      | session history        |
| `HH`            | `ghistory`        | global history         |
| `¨` (diaeresis) | `ghistory`        | global history (alias) |
| `Hs`            | `ghistory_subdir` | subdir-filtered global |
| `He`            | `ghistory_edit`   | edit global history    |
| `Hc`            | `ghistory_clear`  | clear global           |

**Critique:** `H`-prefix is fine, but `Hh`/`HH`/`Hs`/`He`/`Hc` is a lot of `H`-prefixed bindings. The `¨` alias for `HH` is AltGr-only and hard to type on non-European keyboards. The capital/lowercase distinction (`Hh` vs `HH`) is too subtle for such different actions.

### 2.6 `ftl marks` (7 binds)

| key         | command        | purpose                |
| -----       | ---------      | ---------              |
| `m`         | `mark`         | set mark               |
| `'` (QUOTE) | `mark_go`      | go to mark             |
| `*` (STAR)  | `mark_go_tab`  | go to mark in new tab  |
| `gm`        | `mark_fzf`     | fzf to mark            |
| `MM`        | `gmark`        | add persistent mark    |
| `gM`        | `gmark_fzf`    | fzf to persistent mark |
| `Mc`        | `gmarks_clear` | clear persistent       |

**Critique:** Mostly good. `m`/`'`/`*` mirror vim's mark bindings. `gm`/`gM` are consistent (goto mark / goto persistent). `MM`/`Mc` for persistent-mark management is slightly awkward (capital M for persistent, but `m` for session).

### 2.7 `ftl media` (7 binds)

| key   | command            | purpose           |
| ----- | ---------          | ---------         |
| `ea`  | `preview_show`     | background player |
| `eA`  | `preview_show_fzf` | fzf viewer        |
| `ek`  | `player_kill`      | kill player       |
| `eq`  | `preview_queue`    | queue to player   |
| `ee`  | `external_mode1`   | external m1       |
| `er`  | `external_mode2`   | external m2       |
| `ew`  | `external_mode3`   | external m3       |

**Critique:** `e`-prefix for "external" is reasonable, but:
1. `ea`/`eA`/`ek`/`eq` are media-playback, while `ee`/`er`/`ew` are external-viewer modes. These are different concerns mixed under one prefix.
2. `ek` for "kill" is good. `eq` for "queue" is good. But `ea`/`eA` for "show"/"fzf viewer" is not mnemonic.
3. `ee`/`er`/`ew` for modes 1/2/3 — why `e`/`r`/`w`? Not mnemonic.

### 2.8 `ftl move` (32 binds) — the largest section

| key            | command                | purpose               |
| -----          | ---------              | ---------             |
| `ENTER`        | `enter`                | cd or open            |
| `PGUP`/`CTL-B` | `move_page_up`         | page up               |
| `PGDN`/`CTL-F` | `move_page_down`       | page down             |
| `UP`           | `move_up_arrow`        | up                    |
| `DOWN`         | `move_down_arrow`      | down                  |
| `RIGHT`        | `move_right_arrow`     | cd in                 |
| `LEFT`         | `move_left_arrow`      | cd up                 |
| `ALT-J`        | `preview_down`         | scroll preview        |
| `ALT-K`        | `preview_up`           | scroll preview        |
| `J`            | `preview_down2`        | scroll fixed preview  |
| `K`            | `preview_up2`          | scroll fixed preview  |
| `CTL-H`        | `preview_left`         | send left to preview  |
| `CTL-L`        | `preview_right`        | send right to preview |
| `gD`           | `change_dir`           | cd (prompt)           |
| `g LEADER`     | `top_file_bottom`      | cycle top/file/bottom |
| `gd`           | `goto_first_directory` | first dir             |
| `gg`           | `goto_first_file`      | first file            |
| `gh`           | `goto_high_file`       | first visible         |
| `gl`           | `goto_low_file`        | last visible          |
| `G`            | `goto_last_file`       | last file             |
| `h`            | `move_left`            | cd up                 |
| `j`            | `move_down`            | down                  |
| `k`            | `move_up`              | up                    |
| `l`            | `move_right`           | cd in                 |
| `COUNT %`      | `move_percent`         | jump by %             |
| `-`            | `goto_alt1`            | next same extension   |
| `_`            | `goto_alt2`            | next diff extension   |
| `#`            | `goto_entry`           | goto by index         |
| `yN`           | `goto_prev_tag`        | prev tagged           |
| `yn`           | `goto_next_tag`        | next tagged           |

**Critique:**

1. **Arrow keys + vim keys are duplicated.** `UP`/`j`, `DOWN`/`k`, `LEFT`/`h`, `RIGHT`/`l` — both bound. This is intentional (supports both styles) but doubles the binding count.
2. **`J`/`K` for preview scroll** conflicts with the commented-out `move_down_step`/`move_up_step` (lines 260-261). The user has to choose.
3. **`ALT-J`/`ALT-K` for preview scroll** is good (doesn't conflict with `J`/`K`).
4. **`g`-prefix bindings** (`gD`/`gd`/`gg`/`gh`/`gl`/`G`/`g LEADER`) are vim-standard and well-organized.
5. **`-`/`_` for next-same/diff-extension** is non-mnemonic. These are obscure bindings that could use better keys.
6. **`yN`/`yn` for next/prev tag** breaks the `y`-for-selection convention (see §2.12).

### 2.9 `ftl pane` (7 binds)

| key       | command        | purpose                |
| -----     | ---------      | ---------              |
| `CTL-W h` | `pane_left`    | pane left              |
| `CTL-W l` | `pane_right`   | pane right             |
| `CTL-W j` | `pane_down`    | pane below             |
| `CTL-W H` | `pane_L`       | pane left, keep focus  |
| `CTL-W L` | `pane_R`       | pane right, keep focus |
| `CTL_W n` | `pane_go_next` | next pane              |
| `gp`      | `pane_go_next` | next pane (alias)      |

**Critique:** `CTL-W` prefix mirrors vim's window commands — excellent. But:
2. **`gp` for next-pane** conflicts conceptually with vim's `gp` (goto-paste). Minor.

### 2.10 `ftl shell` (18 binds)

| key               | command             | purpose             |
| -----             | ---------           | ---------           |
| `CTL-W !` / `S!`  | `shell_view`        | view shell          |
| `CTL-W sS` / `SS` | `shell_files`       | shell + selection   |
| `CTL-W ss` / `Ss` | `shell`             | shell               |
| `CTL-W sq` / `Sq` | `quit_shell`        | close shell         |
| `CTL-W sv` / `Sv` | `shell_vertical`    | vertical shell      |
| `CTL-W sz` / `Sz` | `shell_zoomed`      | zoomed shell        |
| `CTL-W sf` / `Sf` | `shell_send_files`  | send files to shell |
| `CTL-W sg` / `gS` | `shell_synch`       | cd shell to ftl     |
| `CTL-Z sp` / `Sp` | `shell_cmd_in_pane` | run cmd in pane     |

**Critique:**

1. **Every command has two bindings** — a `CTL-W <keys>` form and an `S<key>` form. This is intentional (vim-style vs shortcut), but doubles the count.
2. **`CTL-W ss`/`Ss` vs `CTL-W sS`/`SS`** — the case distinction is too subtle. `Ss` (shell) vs `SS` (shell+files) is easy to mistype.
3. **`CTL-Z sp`** breaks the `CTL-W` pattern — why `CTL-Z`? Inconsistent.
4. **`gS` for shell_synch** breaks the `S`-prefix pattern (it's `gS`, not `Sg`).

### 2.11 `ftl tabs` (5 binds)

| key             | command    | purpose    |
| -----           | ---------  | ---------  |
| `§` (PARAGRAPH) | `tab_new`  | new tab    |
| `TAB` / `gt`    | `tab_next` | next tab   |
| `COUNT gt`      | `tab_goto` | goto tab N |
| `gT`            | `tab_prev` | prev tab   |

**Critique:** `gt`/`gT` are vim-standard. `TAB` for next-tab is good. `§` (AltGr) for new-tab is hard to type on non-European keyboards — should have an ASCII alternative.

### 2.12 `ftl selection` (31 binds)

| key                                 | command                  | purpose              |
| -----                               | ---------                | ---------            |
| `ya`                                | `select_all`             | select all           |
| `yf`                                | `select_all_files`       | select all files     |
| `yd`                                | `select_all_directories` | select all dirs      |
| `yii`                               | `image_select`           | images via sxiv      |
| `yiI`                               | `image_select_rec`       | images recursive     |
| `yif`                               | `selection_fzf`          | fzf select           |
| `yiF`                               | `selection_fzf_all`      | fzf select recursive |
| `ye`                                | `selection_ext`          | same extension       |
| `yie`                               | `selection_ext_fzf`      | fzf same extension   |
| `yE`                                | `selection_ext_all`      | ext recursive        |
| `yiE`                               | `selection_ext_all_fzf`  | fzf ext recursive    |
| `a` / `COUNT a` / `yy` / `COUNT yy` | `selection_flip_down`    | select down          |
| `s` / `COUNT s` / `yu` / `COUNT yu` | `selection_flip_up`      | select up            |
| `y1`/`COUNT y1`                     | `selection_class_1`      | class 1              |
| `y2`/`COUNT y2`                     | `selection_class_2`      | class 2              |
| `y3`/`COUNT y3`                     | `selection_class_3`      | class 3              |
| `y4`/`COUNT y4`                     | `selection_class_4`      | class 4              |
| `yc`                                | `selection_untag_all`    | deselect all         |
| `yC`                                | `selection_untag_fzf`    | deselect fzf         |
| `ytc`                               | `copy_clipboard`         | copy to clipboard    |
| `gy`                                | `selection_goto`         | fzf goto selection   |

**Critique:**

1. **`y` is heavily overloaded.** 27 of 31 bindings start with `y`. The mnemonic is "yank" (vim-style selection), but the variants are extremely dense.
2. **`a`/`s` vs `yy`/`yu`** — four bindings for two actions (select-down / select-up). `a`/`s` are short, `yy`/`yu` are vim-style. Pick one.
3. **`yi` prefix for image-selection** — `yii`/`yiI`/`yif`/`yiF`/`yie`/`yiE`. The `i` is for "image", but the third letter is hard to remember (`i` for sxiv, `I` for recursive sxiv, `f` for fzf, `F` for recursive fzf, `e`/`E` for extension).
4. **`ytc` for clipboard** — why `t`? Not mnemonic. Should be `yc` for clipboard (but that's taken by `selection_untag_all`).
5. **`y1`/`y2`/`y3`/`y4` for classes** — good, but no `y0` for default class.
6. **`gy` for goto-selection** — breaks the `y`-prefix convention (it's `gy`, not `yg`).

### 2.13 `ftl view` (48 binds) — the largest section

This is the most problematic section. 48 bindings, almost all under the `z` prefix:

| key         | command                                     | purpose               |
| -----       | ---------                                   | ---------             |
| `zma`/`zmm` | `view_mode_all`                             | all files             |
| `zmn`       | `view_mode_next`                            | cycle view mode       |
| `zmi`       | `view_mode_image`                           | images only           |
| `zmI`       | `view_mode_not_image`                       | non-images            |
| `zmP`       | `preview_image`                             | toggle image preview  |
| `zmd`       | `file_dir_mode`                             | cycle file/dir mode   |
| `zmD`       | `preview_dir_only`                          | dir-only preview      |
| `zmp`       | `view_mode_pdf`                             | pdf text/image        |
| `zz`        | `image_zoom`                                | zoom image            |
| `z+` / `+`  | `preview_size`                              | preview size          |
| `zg`        | `show_stat`                                 | toggle stat           |
| `zs`        | `show_size`                                 | cycle size display    |
| `zS`        | `hide_size`                                 | hide size             |
| `zo`        | `sort_entries`                              | cycle sort            |
| `zO`        | `sort_entries_reversed`                     | reverse sort          |
| `zv`        | `preview_pane`                              | toggle preview        |
| `zff`       | `preview_pane2`                             | fixed preview         |
| `zfc`       | `tcpreview2`                                | close fixed preview   |
| `z*`        | `depth`                                     | listing depth         |
| `zt`        | `etag_show`                                 | toggle etags          |
| `zT`        | `etag_select`                               | select etag type      |
| `zep`       | `preview_ext_ign`                           | toggle ext preview    |
| `zeh`       | `extension_hide_tab`                        | hide ext (tab)        |
| `zeH`       | `extension_hide`                            | hide ext (global)     |
| `zeo`       | `extension_only_tab`                        | only ext (tab)        |
| `zeO`       | `extension_only`                            | only ext (global)     |
| `zec`       | `extension_clear`                           | clear ext filters     |
| `zes`       | `extension_sort`                            | sort by extension     |
| `z.`        | `show_hidden`                               | toggle dot-files      |
| `z1`-`z5`   | `preview_m1`-`preview_m5`                   | alt preview modes     |
| `Z1`-`Z5`   | `full_preview_m1`-`full_preview_m5`         | full-screen alt modes |
| `zd0`-`zd5` | `set_directory_mode0`-`set_directory_mode5` | dir preview modes     |
| `zM`        | `preview_refresh`                           | refresh preview       |

**Critique:**

1. **`z` is massively overloaded.** 47 of 48 bindings start with `z`. This is the vim "fold" prefix, but here it's used for everything view-related.
2. **`zm` sub-prefix** for view modes (8 bindings) — adds a third letter, making sequences like `zmi`/`zmI`/`zmn`/`zmm`/`zma`/`zmP`/`zmd`/`zmD` hard to distinguish.
3. **`ze` sub-prefix** for extension filters (7 bindings) — same problem.
4. **`zd` sub-prefix** for directory modes (6 bindings) — same problem.
5. **`z1`-`z5` / `Z1`-`Z5`** — 10 bindings for alternative preview modes. The capital/lowercase distinction (in-pane vs full-screen) is subtle.
6. **`z+` / `+`** — two bindings for the same action. Redundant.
7. **`zs` / `zS`** — show-size vs hide-size. But `show_size` already cycles (0→1→2→3→0), so `zS` is redundant.
8. **No mnemonic structure.** Why is `zt` for etag-show but `zT` for etag-select? Why is `zg` for stat but `zs` for size? The letters seem arbitrary.

### 2.14 `ftl SIG` (3 binds) — reserved

| key   | command       | purpose                      |
| ----- | ---------     | ---------                    |
| `r`   | `SIG_REFRESH` | preview-pane refresh signal  |
| `å`   | `SIG_PANE`    | pane-focus-changed signal    |
| `Ä`   | `SIG_REMOTE`  | preview-state-changed signal |

**Critique:** `r` for refresh is fine. `å`/`Ä` are reserved for IPC (see ftlrc reference). The user shouldn't bind these.

---

## 3. Key Usage Heatmap

Let's count how many bindings use each prefix (first key):

| prefix                               | count   | examples                                                                                              |
| --------                             | ------- | ----------                                                                                            |
| `z`                                  | 47      | `zv`, `zs`, `zo`, `zt`, `z1`-`z5`, `zm*`, `ze*`, `zd*`                                                |
| `g`                                  | 18      | `gg`, `G`, `gd`, `gh`, `gl`, `gD`, `gm`, `gM`, `gff`, `grr`, `gS`, `gy`, `gL`, `gt`, `gT`, `g LEADER` |
| `y`                                  | 27      | `ya`, `yf`, `yd`, `yy`, `yu`, `y1`-`y4`, `yc`, `yC`, `ytc`, `yi*`, `ye*`                              |
| `f`                                  | 7       | `ff`, `fF`, `fd`, `fr`, `fe`, `fy`, `fc`                                                              |
| `x`                                  | 9       | `xmr`, `xmw`, `xmx`, `xmM`, `xh`, `xH`, `xv`, `xV`, `xc`, `xl`, `xp`                                  |
| `p`                                  | 8       | `pp`, `pm`, `PP`, `PM`, `pz`, `pZ`, `pop`, `pom`                                                      |
| `e`                                  | 7       | `ea`, `eA`, `ek`, `eq`, `ee`, `er`, `ew`                                                              |
| `S`/`CTL-W s`                        | 9       | `Ss`, `Sv`, `SS`, `Sf`, `Sq`, `Sz`, `Sp`, `S!`, `gS`                                                  |
| `H`                                  | 5       | `Hh`, `HH`, `Hs`, `He`, `Hc`                                                                          |
| `i`                                  | 4       | `if`, `id`, `iD`, `ib`                                                                                |
| `m`/`M`                              | 4       | `m`, `MM`, `Mc`, (gm/gM counted under g)                                                              |
| `d`                                  | 1       | `d`                                                                                                   |
| `R`                                  | 1       | `R`                                                                                                   |
| `w`                                  | 1       | `w`                                                                                                   |
| `b`/`B`                              | 2       | `b`, `B` (aliases for gff/gfF)                                                                        |
| `n`/`N`                              | 2       | `n`, `N`                                                                                              |
| `h`/`j`/`k`/`l`                      | 4       | movement                                                                                              |
| `-`/`_`/`#`/`*`/`$`/`:`/`?`/`¿`      | 8       | various                                                                                               |
| `LEADER`                             | 28      | `\fc`, `\gG`, `\tt`, `\vv`, `\fs`, etc.                                                               |
| `TAB`/`ENTER`/`ESC`/arrows/pgup/pgdn | ~10     | movement                                                                                              |
| `CTL-*`                              | ~15     | `CTL-W *`, `CTL-B`, `CTL-F`, `CTL-H`, `CTL-L`                                                         |
| `ALT-*`                              | 2       | `ALT-J`, `ALT-K`                                                                                      |
| `F1`-`F12`                           | 0       | unused!                                                                                               |
| `0`-`9` (as count)                   | ~10     | `COUNT gt`, `COUNT %`, `COUNT a`, etc.                                                                |

### Observations

1. **`z` is dangerously overloaded** — 47 bindings under one prefix. The user has to remember `z` + 1-2 more keys, with no mnemonic structure.
2. **`y` is overloaded** — 27 bindings. The `y` (yank) convention is stretched beyond its natural meaning.
3. **`g` is overloaded** — 18 bindings, but at least `g` has a clear "goto" mnemonic.
4. **`F1`-`F12` are completely unused** — 12 easy-to-reach keys wasted.
5. **`ALT-*` is barely used** — only `ALT-J`/`ALT-K`. Alt combinations are easy to reach and under-utilized.
6. **`CTL-*` is mostly `CTL-W`** (window commands) plus a few vim-standard (`CTL-B`/`CTL-F` for page).
7. **Digits `0`-`9` are mostly count prefixes** — but `0` is also a mark (root directory), creating ambiguity.

---

## 4. Problems with the Current Scheme

### 4.1 Cognitive load

The current scheme requires the user to memorize ~281 bindings. Even with mnemonics, this is overwhelming. The `z`-prefix alone has 47 bindings — more than many entire applications.

### 4.2 Mnemonic inconsistency

- `f` = filter (good)
- `g` = goto (good)
- `y` = yank/select (stretched — `ytc` for clipboard?)
- `z` = ??? (view, but also size, sort, etag, extension, depth, etc.)
- `x` = ??? (execute? extended? chmod + hex + vim + cat + link?)
- `p` = put/paste (good, but overloaded with variants)
- `e` = external (good, but mixes media-playback with viewer-modes)
- `i` = insert/create (vim-style, but `if`/`id`/`iD`/`ib` aren't obvious)
- `m` = mark (good)
- `H` = history (good)
- `S` = shell (good)
- `d` = delete (good)
- `R` = rename (good)
- `w` = write/copy (vim-style `w` for write, but only one binding)

### 4.3 Collision-prone aliases

Many bindings have two forms (a `CTL-W` form and a shortcut form). This is good for discoverability but doubles the binding count and creates maintenance burden.

### 4.4 Dead/overridden bindings

- `find_entry` (bound to `/`) is overridden by `incremental_search` (also bound to `/`).
- `find_fzf` is bound to both `gff` and `b` — but `b` is non-mnemonic.
- `find_fzf_all` is bound to both `gfF` and `B` — same issue.
- `ghistory` is bound to both `HH` and `¨` — the `¨` alias is AltGr-only.
- `preview_size` is bound to both `z+` and `+` — redundant.
- `move_page_up`/`down` are bound to both `PGUP`/`PGDN` and `CTL-B`/`CTL-F` — reasonable (vim + modern).

### 4.5 Subtle case distinctions

- `Hh` vs `HH` (session vs global history)
- `Ss` vs `SS` (shell vs shell+files)
- `zmi` vs `zmI` (image vs not-image)
- `zeh` vs `zeH` (tab vs global hide)
- `zeo` vs `zeO` (tab vs global only)
- `zs` vs `zS` (show vs hide size — but show already cycles!)
- `z1`-`z5` vs `Z1`-`Z5` (in-pane vs full-screen)

These are easy to mistype and hard to discover.

### 4.6 Non-mnemonic bindings

- `b`/`B` for fzf-find (why?)
- `yi*` for image-selection (the `i` is for image, but the third letter is arbitrary)
- `z+`/`+` for preview-size (why `+`? because it zooms?)
- `zmP` for preview-image (why capital `P`?)
- `ytc` for clipboard (why `t`?)
- `g LEADER` for top-file-bottom (vim-style, but obscure)
- `-`/`_` for next-same/diff-extension (why these keys?)

### 4.7 Unused key real estate

- `F1`-`F12` — 12 keys, 0 bindings
- `ALT-*` (except `ALT-J`/`ALT-K`) — ~26 keys, 0 bindings
- `CTL-*` (except `CTL-W*`, `CTL-B`, `CTL-F`, `CTL-H`, `CTL-L`, `CTL-Z sp`) — ~20 keys, 0 bindings
- `0` (as a binding, not count) — 0 bindings (but is a mark)
- `,` / `;` — 0 bindings
- `.` (redo key, but could be double-bound) — 0 user bindings

---

## 5. Proposed New Grouping

I propose a **7-category grouping** based on action semantics rather than vim convention:

### Category 1: Navigation (NAV) — movement and directory traversal

**Prefix:** none (single keys) + `g` for goto

| key                        | action                  | current key   | change                                |
| -----                      | --------                | ------------- | --------                              |
| `h`/`j`/`k`/`l`            | move left/down/up/right | same          | —                                     |
| `LEFT`/`DOWN`/`UP`/`RIGHT` | arrow aliases           | same          | —                                     |
| `ENTER`                    | enter dir / open file   | same          | —                                     |
| `PGUP`/`PGDN`              | page up/down            | same          | —                                     |
| `CTL-B`/`CTL-F`            | page up/down (vim)      | same          | —                                     |
| `gg`                       | first file              | same          | —                                     |
| `G`                        | last file               | same          | —                                     |
| `gd`                       | first directory         | same          | —                                     |
| `gh`                       | first visible           | same          | —                                     |
| `gl`                       | last visible            | same          | —                                     |
| `gD`                       | cd (prompt)             | same          | —                                     |
| `g LEADER`                 | cycle top/file/bottom   | same          | —                                     |
| `COUNT %`                  | jump by percent         | same          | —                                     |
| `#`                        | goto by index           | same          | —                                     |
| `(`                        | next same extension     | `-`           | **change** (mnemonic: similar to `)`) |
| `)`                        | next diff extension     | `_`           | **change**                            |
| `gn`                       | next tagged             | `yn`          | **change** (g-prefix for goto)        |
| `gN`                       | prev tagged             | `yN`          | **change**                            |

### Category 2: View (VIEW) — display modes and toggles

**Prefix:** `z` (keep) but with **structured sub-prefixes**

**Sub-prefix scheme:**

| sub-prefix   | meaning               | bindings                                                                             |
| ------------ | ---------             | ----------                                                                           |
| `zm`         | mode (file/dir/image) | `zma`, `zmn`, `zmi`, `zmI`, `zmd`, `zmD`                                             |
| `zp`         | preview pane          | `zv` → `zpv`, `z+` → `zps`, `zz` → `zpz`, `zM` → `zpr`                               |
| `zs`         | sort                  | `zo` → `zst`, `zO` → `zsr`                                                           |
| `zt`         | toggle display        | `zg` → `ztg` (stat), `zs` → `zts` (size), `z.` → `zth` (hidden), `zt` → `zte` (etag) |
| `ze`         | extension filter      | `zeh`/`zeH`/`zeo`/`zeO`/`zec`/`zes`/`zep` (keep)                                     |
| `zd`         | directory mode        | `zd0`-`zd5` (keep)                                                                   |
| `z1`-`z5`    | alt preview mode      | keep                                                                                 |
| `Z1`-`Z5`    | full-screen alt       | keep                                                                                 |

This adds one letter but makes the structure explicit: `z` + category + specific. E.g. `zts` = "z toggle size" instead of the cryptic `zs`.

### Category 3: Selection (SEL) — tagging and selection

**Prefix:** `y` (keep) but **simplify the variants**

| key       | action                  | current key   | change                                   |
| -----     | --------                | ------------- | --------                                 |
| `yy`      | select down             | `a`/`yy`      | **drop `a`**                             |
| `yu`      | select up               | `s`/`yu`      | **drop `s`**                             |
| `ya`      | select all              | same          | —                                        |
| `yf`      | select all files        | same          | —                                        |
| `yd`      | select all dirs         | same          | —                                        |
| `ye`      | select same extension   | same          | —                                        |
| `yE`      | select ext recursive    | same          | —                                        |
| `yc`      | clear selection         | same          | —                                        |
| `yC`      | clear via fzf           | same          | —                                        |
| `y1`-`y4` | selection classes       | same          | —                                        |
| `yg`      | fzf goto selection      | `gy`          | **change to `yg`** (y-prefix)            |
| `yb`      | clipboard copy          | `ytc`         | **change** (`b` for buffer/clipboard)    |
| `yi`      | select images (sxiv)    | `yii`         | **simplify**                             |
| `yI`      | select images recursive | `yiI`         | **simplify**                             |
| `yF`      | fzf select              | `yif`         | **simplify**                             |
| `yG`      | fzf select recursive    | `yiF`         | **simplify** (G for "greater" recursive) |

### Category 4: File Ops (FILE) — operations on the current entry/selection

**Prefix:** `x` (keep) but **clarify sub-prefixes**

**Sub-prefix scheme:**

| sub-prefix   | meaning    | bindings                                                                                                                                   |
| ------------ | ---------  | ----------                                                                                                                                 |
| `xc`         | create     | `xcf` (file), `xcd` (dir), `xcD` (dir+cd), `xcb` (bulk) — **change from `if`/`id`/`iD`/`ib`**                                              |
| `xd`         | delete     | `xd` — **change from `d`** (safer, two-key)                                                                                                |
| `xr`         | rename     | `xr` — **change from `R`**                                                                                                                 |
| `xp`         | paste/put  | `xpp` (here), `xpm` (move here), `xpP` (preset copy), `xpM` (preset move), `xpz` (fzf), `xpt` (to tab) — **change from `p*`**              |
| `xm`         | mode/chmod | `xmr`, `xmw`, `xmx`, `xmM` (keep)                                                                                                          |
| `xe`         | edit       | `xev` (vim), `xeV` (vim window), `xeS` (shared), `xeh` (hex), `xeH` (hexedit), `xec` (cat) — **change from `xv`/`xV`/`XV`/`xh`/`xH`/`xc`** |
| `xl`         | link       | `xll` (symlink), `xlf` (follow) — **change**                                                                                               |

### Category 5: Search (SEARCH) — find, fzf, ripgrep

**Prefix:** `/` for incremental, `f` for fzf, `r` for ripgrep

| key     | action                | current key   | change                      |
| -----   | --------              | ------------- | --------                    |
| `/`     | incremental search    | same          | —                           |
| `n`/`N` | next/previous         | same          | —                           |
| `ff`    | fzf current dir       | `gff`/`b`     | **change** (drop `b` alias) |
| `fF`    | fzf recursive         | `gfF`/`B`     | **change** (drop `B` alias) |
| `fd`    | fzf dirs              | `gfd`         | **change**                  |
| `fa`    | fzf regexp/fuzzy      | `gfa`         | **change**                  |
| `fA`    | fzf regexp recursive  | `gfA`         | **change**                  |
| `fi`    | fzf images (sxiv)     | `gfi`         | **change**                  |
| `fI`    | fzf images recursive  | `gfI`         | **change**                  |
| `fu`    | fzf images (ueberzug) | `gfu`         | **change**                  |
| `rf`    | rg, open file         | `grr`         | **change**                  |
| `rr`    | rg, goto file         | `grt`         | **change**                  |
| `rl`    | rg, edit files        | `grl`         | **change**                  |
| `ro`    | rg, one match         | `grf`         | **change**                  |

### Category 6: Pane/Tab/Shell (PTS) — window management

**Prefix:** `CTL-W` (keep) + single-key shortcuts

Keep the `CTL-W` scheme but **fix the typos and inconsistencies**:

| key                   | action                 | current key      | change                    |
| -----                 | --------               | -------------    | --------                  |
| `CTL-W h`/`j`/`k`/`l` | pane split             | same             | —                         |
| `CTL-W H`/`L`         | pane split, keep focus | same             | —                         |
| `CTL-W n`             | next pane              | `CTL_W n` (typo) | **fix typo**              |
| `gp`                  | next pane (alias)      | same             | —                         |
| `CTL-W s`             | shell                  | `CTL-W ss`/`Ss`  | **simplify**              |
| `CTL-W S`             | shell + files          | `CTL-W sS`/`SS`  | **simplify**              |
| `CTL-W v`             | vertical shell         | `CTL-W sv`/`Sv`  | **simplify**              |
| `CTL-W z`             | zoomed shell           | `CTL-W sz`/`Sz`  | **simplify**              |
| `CTL-W f`             | send files             | `CTL-W sf`/`Sf`  | **simplify**              |
| `CTL-W g`             | synch shell            | `CTL-W sg`/`gS`  | **simplify**              |
| `CTL-W q`             | close shell            | `CTL-W sq`/`Sq`  | **simplify**              |
| `CTL-W !`             | view shell             | same             | —                         |
| `CTL-W p`             | run cmd in pane        | `CTL-Z sp`/`Sp`  | **fix prefix**            |
| `gt`/`gT`             | next/prev tab          | same             | —                         |
| `COUNT gt`            | goto tab               | same             | —                         |
| `TAB`                 | next tab (alias)       | same             | —                         |
| `tn`                  | new tab                | `§`              | **add ASCII alternative** |

### Category 7: Meta (META) — help, quit, command prompt, config

| key      | action             | current key   | change   |
| -----    | --------           | ------------- | -------- |
| `?`      | help               | same          | —        |
| `c`      | show bindings      | same          | —        |
| `:`      | command prompt     | same          | —        |
| `q`      | quit               | same          | —        |
| `Q`/`ZZ` | quit all           | same          | —        |
| `ZS`     | quit, keep shell   | same          | —        |
| `ZP`     | quit, keep preview | same          | —        |
| `$`      | detach editor      | same          | —        |
| `¿`      | debug pane         | same          | —        |
| `.`      | redo               | same          | —        |

### Leader-prefixed (LEADER) — extended/less-common operations

Keep the `\` leader for:
- `\f*` — file utilities (compress, encrypt, optimize, etc.)
- `\g*` — git operations
- `\t*` — TMSU tag operations
- `\v*` — virtual entries / diff
- `\a*` — add-to-log
- `\h*` — leader help
- `\u` — user command
- `\s` — shell popup

---

## 6. Proposed Shortcut Reassignments

### 6.1 Bind F1-F12

The function keys are completely unused. Proposed:

| key   | action                      | rationale               |
| ----- | --------                    | -----------             |
| `F1`  | help (`?` alias)            | universal help key      |
| `F2`  | rename (`R` alias)          | common in file managers |
| `F3`  | external viewer             | common in file managers |
| `F4`  | edit (`xv` alias)           | common in file managers |
| `F5`  | copy (`w` alias)            | common in file managers |
| `F6`  | move (`pm` alias)           | common in file managers |
| `F7`  | new directory (`id` alias)  | common in file managers |
| `F8`  | delete (`d` alias)          | common in file managers |
| `F9`  | toggle preview (`zv` alias) |                         |
| `F10` | quit (`q` alias)            | universal quit key      |
| `F11` | fullscreen preview          |                         |
| `F12` | terminal popup (`\s` alias) |                         |

### 6.2 Bind ALT-* keys

Alt combinations are easy to reach and under-utilized. Proposed:

| key                             | action               | rationale                                                |
| -----                           | --------             | -----------                                              |
| `ALT-h`/`ALT-j`/`ALT-k`/`ALT-l` | scroll preview       | currently `ALT-J`/`ALT-K` only (down/up); add left/right |
| `ALT-d`                         | duplicate selection  | new feature                                              |
| `ALT-e`                         | extract (decompress) | currently `\fd`                                          |
| `ALT-z`                         | undo last navigation | new feature                                              |
| `ALT-y`                         | redo last navigation | new feature                                              |
| `ALT-r`                         | refresh              | currently `r` (SIG_REFRESH)                              |
| `ALT-t`                         | new tab              | currently `§` (AltGr)                                    |
| `ALT-w`                         | close tab            | currently `q`                                            |
| `ALT-q`                         | quit all             | currently `Q`                                            |
| `ALT-ENTER`                     | open in external app | currently `\fE` or `open_with`                           |

### 6.3 Bind CTL-* keys (beyond CTL-W)

| key     | action                 | rationale                                           |
| -----   | --------               | -----------                                         |
| `CTL-D` | delete                 | vim-style (down/half-page in vim, but here: delete) |
| `CTL-R` | refresh preview        | common refresh key                                  |
| `CTL-S` | save selection to file | new feature                                         |
| `CTL-O` | open with...           | common key                                          |
| `CTL-N` | new file               | common key                                          |
| `CTL-A` | select all             | universal                                           |
| `CTL-C` | copy to clipboard      | universal (currently `ytc`)                         |
| `CTL-V` | paste                  | universal                                           |
| `CTL-X` | cut                    | universal                                           |
| `CTL-Z` | undo                   | universal                                           |

**Note:** `CTL-C`/`CTL-V`/`CTL-X`/`CTL-Z` may conflict with terminal/OS conventions. Use with caution.

### 6.4 Reassign problematic bindings

| current                      | proposed                          | reason                                 |
| ---------                    | ----------                        | --------                               |
| `b`/`B` (fzf aliases)        | remove                            | non-mnemonic, redundant with `ff`/`fF` |
| `¨` (ghistory alias)         | remove                            | AltGr-only, hard to type               |
| `z+`/`+` (both preview_size) | keep only `z+`                    | redundant                              |
| `zS` (hide_size)             | remove                            | `zs` already cycles                    |
| `Hh`/`HH`                    | `Hs` (session) / `Hg` (global)    | add mnemonic                           |
| `Ss`/`SS`                    | `Ss` (shell) / `Sf` (shell+files) | remove case distinction                |
| `yi*` (image select)         | `yi`/`yI`/`yF`/`yG`               | simplify                               |
| `ytc` (clipboard)            | `yb` (buffer)                     | mnemonic                               |
| `gff`/`gfa`/`gfd`/etc.       | `ff`/`fa`/`fd`/etc.               | drop `g` prefix for fzf                |
| `grr`/`grt`/`grl`/`grf`      | `rf`/`rr`/`rl`/`ro`               | drop `g` prefix for ripgrep            |
| `CTL_W n` (typo)             | `CTL-W n`                         | fix typo                               |
| `CTL-Z sp`                   | `CTL-W p`                         | consistent prefix                      |
| `§` (tab_new)                | `tn` or `ALT-t`                   | ASCII alternative                      |

---

## 7. Migration Path

A complete re-binding would break existing users' muscle memory. Proposed migration:

### 7.1 Phase 1: Add new bindings alongside old (non-breaking)

Add the F1-F12 and ALT-* bindings as **aliases** without removing the old ones. This lets users try the new scheme gradually.

### 7.2 Phase 2: Deprecate old bindings

Mark the old bindings as deprecated in the `c` (show bindings) display. Add a `ftl_bind_check` warning when deprecated bindings are used.

### 7.3 Phase 3: Remove deprecated bindings (major version bump)

After a deprecation period, remove the old bindings. Users who want the old scheme can source `ftlrc_not_so_vim_like` or a new `ftlrc_legacy` file.

### 7.4 Compatibility layer

Provide a `ftlrc_compat` file that re-adds the old bindings on top of the new scheme, for users who can't retrain.

---

## 8. Alternative Binding Schemes

### 8.1 The "Minimal" scheme

Reduce to ~50 bindings by:
- Removing all aliases (one binding per action)
- Putting everything uncommon under `\` leader
- Using only single keys + `g` prefix + `\` leader

### 8.2 The "Cua" scheme (Common User Access)

Adopt standard GUI conventions:
- `CTL-C`/`V`/`X`/`A`/`Z` for clipboard/select/undo
- `F2` rename, `F5` copy, `F8` delete, `F10` quit
- Arrow keys for navigation
- Keep `:` for command prompt

### 8.3 The "Emacs" scheme

For emacs users:
- `CTL-N`/`P`/`F`/`B` for movement
- `CTL-X` prefix for file ops
- `META-X` for command prompt
- `CTL-H` for help

### 8.4 The "Modular" scheme

Ship multiple binding files and let the user choose:
```
ftlrc-bindings-vim      # current default
ftlrc-bindings-cua      # GUI-style
ftlrc-bindings-emacs    # emacs-style
ftlrc-bindings-minimal  # 50 bindings max
```

User sets `bindings_scheme=vim` in their `ftlrc` and the appropriate file is sourced.

---

## Summary of Recommendations

1. **Reduce `z`-prefix overload** by adding structured sub-prefixes (`zm`/`zp`/`zs`/`zt`/`ze`/`zd`).
2. **Bind F1-F12** — 12 easy keys currently wasted.
3. **Bind ALT-* keys** — 26 easy keys currently wasted.
4. **Fix the `CTL_W n` typo** and the `CTL-Z sp` inconsistency.
5. **Drop non-mnemonic aliases** (`b`/`B`/`¨`/`+`).
6. **Simplify `yi*` image-selection bindings.**
7. **Move ripgrep bindings from `gr*` to `r*`** (single prefix).
8. **Move fzf bindings from `gf*` to `f*`** (single prefix, no conflict with `f` filter since filter is `ff`/`fF`/`fd`/`fr`/`fe`/`fy`/`fc`).
9. **Add ASCII alternatives for AltGr bindings** (`§` → `tn`).
10. **Consider a "Minimal" or "CUA" alternative scheme** for non-vim users.

