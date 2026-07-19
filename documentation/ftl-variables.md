# `ftl` — Global Variable Reference (Exhaustive)

> **Scope:** Every global variable used by the `ftl` core and its default plugin set.
> **For each variable:** declaration site (file:line, with context), type, default value, purpose, and every usage site with what-for.
> **Path conventions:** All paths are relative to `config/ftl/` inside the repo (i.e. `$FTL_CFG`).
> **Bash version assumptions:** Bash 5+ (uses `declare -A`, `declare -n`, `${var@Q}`, `mapfile`).
> **Source revision analyzed:** `main` branch, shallow clone.

---

## Table of Contents

1. [How Variables Become Global in `ftl`](#1-how-variables-become-global-in-ftl)
2. [Configuration Globals (from `ftlrc`)](#2-configuration-globals-from-ftlrc)
3. [Core Runtime State (from `ftl_setup`)](#3-core-runtime-state-from-ftl_setup)
4. [Per-Pane Filesystem State (`$fs`, `$pfs`, `$fsp`)](#4-per-pane-filesystem-state-fs-pfs-fsp)
5. [Keyboard & Input Globals](#5-keyboard--input-globals)
6. [Listing & Rendering Globals](#6-listing--rendering-globals)
7. [Selection / Tag State](#7-selection--tag-state)
8. [Tab State](#8-tab-state)
9. [Filter State](#9-filter-state)
10. [Preview / Pane State](#10-preview--pane-state)
11. [Tmux / IPC State](#11-tmux--ipc-state)
12. [External-Integration Globals](#12-external-integration-globals)
13. [Plugin-Defined Globals](#13-plugin-defined-globals)
14. [Generated / Serialized Globals (cross-process)](#14-generated--serialized-globals-cross-process)
15. [Appendix: Implicit Globals (No `declare -g`)](#15-appendix-implicit-globals-no-declare--g)

---

## 1. How Variables Become Global in `ftl`

Bash has three ways a variable becomes global in `ftl`'s execution model:

1. **Explicit `declare -g` / `declare -Ag` / `declare -ag`** — the author signals intent. Examples in `etc/core/ftl_setup:6-10`.
2. **Top-level assignment** (outside any function) — automatically global. The entire `etc/ftlrc` file is top-level, so every assignment there is a global declaration.
3. **Assignment inside a function without `local`** — leaks to global scope. `ftl` uses this *heavily*; many "globals" are never declared, they're just first-assigned inside a function. Examples: `pane_id`, `in_pdir`, `keys_command`, `REPLY`, `R`, `top`, `bottom`, `file`, `nfiles`, `files`, `head`, `pad`, etc.

There is **no `local` declaration discipline**. The author treats the global namespace as the primary data structure. This is a deliberate design choice — it lets any function (including plugin functions) read and mutate any state — but it means the "global variable" surface is much larger than the explicit `declare -g` lines suggest.

**Notation in this document:**

- *Declared at* — the file:line where the variable is first declared or assigned.
- *Type* — `scalar`, `indexed array`, `associative array`, `integer`, or `string (read-only config)`.
- *Default* — initial value if any.
- *Purpose* — what the variable is for.
- *Usage sites* — every file:line where the variable is read or written, with the function name and what-for.

All line numbers are 1-indexed within the file. Files are referred to by their path under `config/ftl/`.

---

## 2. Configuration Globals (from `ftlrc`)

**File:** `etc/ftlrc` (419 lines) — sourced by `etc/core/ftl_setup:6`.

This file is the user-tunable configuration. Every top-level assignment here is a global. The file is sourced *after* the empty `declare -Ag` of `C bindings kbd_trie key_map vfiles vdirs time_event_handlers marks`, so the `ftlrc` body populates those arrays plus creates all the scalar globals listed below.

### 2.1 Locale & Loader Sentinels

#### `FTLRC_LOADED`

- **Declared at:** `etc/ftlrc:1` — `FTLRC_LOADED=1`
- **Type:** scalar (integer-as-string)
- **Default:** `1`
- **Purpose:** Sentinel that tells downstream `source`d files (notably `etc/viewers/core:169`) that they are running inside a fully-initialized `ftl` process, not as a standalone script. When `viewers/core` is sourced directly (e.g. by `fzf_pane_preview`), it sees `FTLRC_LOADED` unset and runs its bootstrap branch.
- **Usage sites:**
  1. `etc/ftlrc:1` — set to `1` at the top of the config file.
  2. `etc/viewers/core:169` — `((!FTLRC_LOADED)) && { : ${FTL_CFG:=$HOME/.config/ftl} ; source $FTL_CFG/etc/core/ftl_setup ; [[ "$1" ]] && pfzf "$1" ; }` — if not loaded yet, bootstrap ftl and dispatch to `pfzf` (the fzf preview function).

#### `LANG`, `LC_ALL`

- **Declared at:** `etc/ftlrc:2` — `LANG=C LC_ALL=C`
- **Type:** scalars (strings)
- **Default:** `C`
- **Purpose:** Force the C locale for the entire `ftl` process. This guarantees deterministic `sort` output, deterministic `find` ordering, and avoids locale-related surprises with `rg`/`grep` regexes. The trade-off: non-ASCII filenames sort by byte value, not locale-aware collation.
- **Usage sites:**
  1. `etc/ftlrc:2` — set both to `C`.
  2. (Indirectly consumed by every `sort`, `find`, `rg`, `grep` invocation in the codebase — they inherit the locale from the environment.)

#### `FTL_CFG`

- **Declared at:** `etc/bin/ftl:206` — `: ${FTL_CFG:=$HOME/.config/ftl}` (default if unset) — and `etc/core/ftl_setup:1` — `export FTL_CFG`
- **Type:** scalar (path string)
- **Default:** `$HOME/.config/ftl`
- **Purpose:** Root directory of the entire `ftl` installation — code, config, runtime data. Every `source` and every plugin lookup uses `$FTL_CFG` as its base. Exported so child processes (generators, helpers, sub-shells) inherit it.
- **Usage sites:** 60+ across the codebase. Notable:
  1. `etc/core/ftl_setup:1` — `export FTL_CFG` (export so children see it).
  2. `etc/core/ftl_setup:3-4` — `source $FTL_CFG/etc/core/ftl` / `source $FTL_CFG/etc/core/debug`.
  3. `etc/core/ftl_setup:6` — `source $FTL_CFG/ftlrc 2>&- || source $FTL_CFG/etc/ftlrc` (user override takes precedence).
  4. `etc/core/ftl:129` — `source "$FTL_CFG/filters/$filter_ext" load $ofs` (dynamic filter loading).
  5. `etc/core/ftl:131` — `source "$FTL_CFG/etags/$etag_s"` (dynamic etag loading).
  6. `etc/core/commands:55` — `gcn()` builds the command-name file from `$FTL_CFG/commands`.
  7. `etc/core/commands:77` — `load_filter()` reads from `$FTL_CFG/filters`.
  8. `etc/core/commands:147` — `preview_lock()` reads from `$FTL_CFG/etc/core/lib/lock_preview`.
  9. `etc/core/commands:173` — `preview_show_fzf()` reads from `$FTL_CFG/viewers`.
  10. `etc/core/commands:223` — `selection_merge()` reads from `$FTL_CFG/etc/core/lib/merge`.
  11. `etc/core/commands:228` — `etag_select()` reads from `$FTL_CFG/etags`.
  12. `etc/core/lib/shell:28,34` — command dispatch reads from `$FTL_CFG/commands/$cmd` and parses via `$FTL_CFG/etc/bin/parse_parts`.
  13. `etc/ftlrc:414-415` — auto-source all binding files: `for b in $(fd . "$FTL_CFG/etc/bindings" --type f | sort -u) ; do source "$b" ; done`.
  14. `etc/ftlrc:147` — `source "$FTL_CFG/viewers/core"` (load preview dispatcher).
  15. `etc/bin/ftl:206` — final fallback if user hasn't set it: `: ${FTL_CFG:=$HOME/.config/ftl}`.

### 2.2 Directory Layout Globals

#### `pgen`

- **Declared at:** `etc/ftlrc:5` — `pgen="$FTL_CFG/etc/generators"`
- **Type:** scalar (path)
- **Default:** `$FTL_CFG/etc/generators`
- **Purpose:** Location of preview-generator scripts. Used to invoke the batch generator and per-extension generators.
- **Usage sites:**
  1. `etc/ftlrc:5` — defined.
  2. `etc/bin/ftl:55` — `nice -10 $pgen/generator $thumbs &` (background thumbnail generation).
  3. `etc/viewers/core:84` — `ext_svg() { run_maxed mupdf "$($pgen/svg_to_pdf "$n" "$thumbs/svg")" ; }`.
  4. `etc/viewers/core:94` — `ext_pdf_vi(){ edit "$($pgen/pdf "$n" $thumbs/pdf 1)" ; }`.
  5. `etc/viewers/core:103,104` — `pcbr`/`pcbz` use `$pgen/cbr` / `$pgen/cbz`.
  6. `etc/viewers/core:116` — `pdir_image()` invokes `$pgen/montage`.
  7. `etc/viewers/core:121,123,124` — `phtml`/`psvg`/`pgif` invoke `$pgen/html`/`$pgen/svg`/`$pgen/gif`.
  8. `etc/viewers/core:126,127,128` — `pmp3`/`pmedia`/`pmlive` invoke `$pgen/$e` (per-extension).
  9. `etc/viewers/core:144,147` — `ppdf`/`pepub` invoke `$pgen/pdf` / `$pgen/epub`.
  10. `etc/viewers/core:155` — `pstl` invokes `$pgen/stl`.
  11. `etc/core/commands:170` — `preview_refresh()` invokes `$pgen/generator_one`.
  12. `etc/bindings/lib/extra:11` — `stat_file()` uses `$pgen/...` indirectly via `piper`.

#### `ftl_root`

- **Declared at:** `etc/ftlrc:6` — `ftl_root=$FTL_CFG/var`
- **Type:** scalar (path)
- **Default:** `$FTL_CFG/var`
- **Purpose:** Root of the runtime data tree. Every `ftl` session creates a directory under here named by its PID (`$ftl_root/$$/`). Also holds global history, marks, and the thumbnail cache. Exported so child processes can find it.
- **Usage sites:**
  1. `etc/ftlrc:6-8` — defined, exported, `mkdir -p`.
  2. `etc/core/ftl_setup:12` — `fs=$ftl_root/$$` (per-session directory).
  3. `etc/core/ftl:103` — `echo $fs >$fsp/fs` (writes the current session's fs path to shared state).
  4. `etc/core/ftl:103` — `echo "$stagsi" >$fsp/stagsi` (writes selection counter).
  5. `etc/core/ftl:80` — `quit()` does `rm -rf $fs` (session cleanup).
  6. `etc/core/ftl:86` — referenced in `save_state` for `ftl_root/cmd_history` (command history file).
  7. `etc/core/commands:19` — `cmd_prompt` uses `$ftl_root/cmd_history` via `-H $ftl_root/cmd_history`.
  8. `etc/core/commands:86` — `gmark()` writes to `$ftl_root/marks`.
  9. `etc/core/commands:88` — `gmark_fzf()` reads from `$ftl_root/marks`.
  10. `etc/core/commands:89` — `gmarks_clear()` truncates `$ftl_root/marks`.
  11. `etc/viewers/core:116` — `pdir_image()` reads `$ftl_root/montage/$n/montage.jpg`.
  12. `etc/viewers/core:116` — invokes `"$pgen/montage" "$ftl_root" "$n"` to build the montage.
  13. `etc/core/ftl:19` — `cmd_prompt` uses `-H $ftl_root/cmd_history` for readline history.
  14. `etc/bindings/lib/extra` (indirectly via `$fs`).

#### `ftl_cmds`

- **Declared at:** `etc/ftlrc:10` — `ftl_cmds=$ftl_root/cmds`
- **Type:** scalar (path)
- **Default:** `$ftl_root/cmds`
- **Purpose:** File path for shell command history (separate from directory-visit history). Touched at startup.
- **Usage sites:**
  1. `etc/ftlrc:10-12` — defined and `touch`ed.
  2. (No other references in the codebase — appears to be reserved for future use or for user scripts.)

#### `ghist`

- **Declared at:** `etc/ftlrc:11` — `ghist=$ftl_root/history`
- **Type:** scalar (path)
- **Default:** `$ftl_root/history`
- **Purpose:** Global directory-visit history file (across all sessions). Appended to on every directory change; read by `ghistory()`.
- **Usage sites:**
  1. `etc/ftlrc:11-12` — defined and `touch`ed.
  2. `etc/ftlrc:20` — `marks[$"'"]="$(tail -n1 $ghist)"` (the `'` mark defaults to last-visited directory).
  3. `etc/core/ftl:50` — `hist_save()`: `echo "$n" | tee -a $fs/history >> $ghist` (append current entry to both session and global history).
  4. `etc/core/commands:95` — `ghistory()`: `h=$ghist ; dedup $h && go_loop f fzf "$(<$h lscolors | fzf-tmux $fzf_opt --tac --ansi --expect=ctrl-t)"`.
  5. `etc/core/commands:96` — `ghistory_subdir()`: filters `$ghist` by `pwd`.
  6. `etc/core/commands:97` — `ghistory_clear()`: `rm $ghist 2>&-`.
  7. `etc/core/commands:98` — `ghistory_edit()`: lets user remove entries via fzf.

#### `thumbs`

- **Declared at:** `etc/ftlrc:14` — `thumbs=$ftl_root/thumbs`
- **Type:** scalar (path)
- **Default:** `$ftl_root/thumbs`
- **Purpose:** Root directory of the preview thumbnail cache. Generators create subdirectories per extension and cache files named `<md5_of_path>_<basename>.<extmode>.<format>`.
- **Usage sites:**
  1. `etc/ftlrc:14-15` — defined, `mkdir -p`.
  2. `etc/bin/ftl:55` — `nice -10 $pgen/generator $thumbs &` (background thumbnail generation).
  3. `etc/viewers/core:84` — `ext_svg()` writes to `$thumbs/svg`.
  4. `etc/viewers/core:94` — `ext_pdf_vi()` writes to `$thumbs/pdf`.
  5. `etc/viewers/core:103,104` — `pcbr`/`pcbz` write to `$thumbs/cbr`/`$thumbs/cbz`.
  6. `etc/viewers/core:116` — `pdir_image()` writes montage to `$ftl_root/montage/$n/` (not `$thumbs`).
  7. `etc/viewers/core:121,123,124` — `phtml`/`psvg`/`pgif` write to `$thumbs/html`/`$thumbs/svg`/`$thumbs/gif`.
  8. `etc/viewers/core:126,127,128` — `pmp3`/`pmedia`/`pmlive` write to `$thumbs/$e`.
  9. `etc/viewers/core:135` — `thumb()` builds path: `echo "$thumbs/$1/$(md5sum <<<"$n" | cut -d' ' -f1)_$f.$2"`.
  10. `etc/viewers/core:144,147` — `ppdf`/`pepub` write to `$thumbs/pdf`/`$thumbs/epub`.
  11. `etc/viewers/core:155` — `pstl` writes to `$thumbs/stl`.
  12. `etc/core/commands:170` — `preview_refresh()` invokes `$pgen/generator_one "$thumbs" "$n" "$e" 1`.
  13. All `generators/*` scripts receive `$thumbs/<ext>` as their `$2` argument.

#### `help_command`

- **Declared at:** `etc/ftlrc:17` — `help_command="man ftl.1"`
- **Type:** scalar (shell command string)
- **Default:** `man ftl.1`
- **Purpose:** Command run when the user presses `?` to view help. Configurable so users can substitute a different help system.
- **Usage sites:**
  1. `etc/ftlrc:17` — defined.
  2. `etc/core/commands:13` — `ftl_help()`: `((help_pop)) && { tmux popup -h90% -w90% -E "$help_command" ; } || { tcpreview ; exec 2>&9 ; $help_command ; exec 2>"$fs/log" ; alt_screen ; } ; cdir ;` — runs the command either in a popup or in the preview pane.

### 2.3 Behavior Options (scalars)

These are simple on/off or numeric options that the user sets in `ftlrc` and the core reads at runtime.

#### `KEY_TIMEOUT`

- **Declared at:** `etc/ftlrc:28` — `KEY_TIMEOUT=1`
- **Type:** scalar (integer, in seconds)
- **Default:** `1`
- **Purpose:** Timeout passed to `read -rsn 1 -t $KEY_TIMEOUT` in the main input loop. After this many seconds with no input, `read` returns failure and `REPLY` is set to `ERROR_142`. This lets `time_event` and `winch` fire even without user input.
- **Usage sites:**
  1. `etc/ftlrc:28` — defined.
  2. `etc/bin/ftl:21` — `{ ... || get_key $KEY_TIMEOUT ; }` — main loop uses it.
  3. `etc/core/keyboard:100` — `read -rsn 1 -t "$1"` inside `get_key()`.

#### `shell_h`, `shell_v`

- **Declared at:** `etc/ftlrc:29-30` — `shell_h=40%` / `shell_v=60%`
- **Type:** scalars (tmux size specs)
- **Defaults:** `40%` / `60%`
- **Purpose:** Size of the shell pane when spawned horizontally (`Ss`) or vertically (`Sv`).
- **Usage sites:**
  1. `etc/ftlrc:29-30` — defined.
  2. `etc/core/commands:97` — `shell_pane()`: `tsplit bash $shell_h -v -U`.
  3. `etc/core/commands:98` — `shell_vpane()`: `tsplit bash $shell_v -h -U`.

#### `auto_selection`

- **Declared at:** `etc/ftlrc:31` — `auto_selection=1`
- **Type:** scalar (integer, 0 or 1)
- **Default:** `1`
- **Purpose:** When non-zero, the selection (`tags`) is automatically synchronized between panes — if another pane has a newer `stagsi` counter, this pane sources its serialized tags.
- **Usage sites:**
  1. `etc/ftlrc:31` — defined.
  2. `etc/core/ftl:169` — `tag_synch()`: `((auto_selection && ostagsi > stagsi)) && stagsi=$ostagsi && read ofs <$fsp/fs && source $ofs/tags`.

#### `time_event`

- **Declared at:** `etc/ftlrc:32` — `time_event=0`
- **Type:** scalar (integer, seconds)
- **Default:** `0` (disabled)
- **Purpose:** If positive, the main loop calls all functions in `time_event_handlers` every `time_event` seconds. Used by plugins that need periodic wakeups.
- **Usage sites:**
  1. `etc/ftlrc:32` — defined.
  2. `etc/core/ftl:164` — `time_event()`: `((time_event)) && (($SECONDS - $time_event0 >= $time_event)) && { for teh in "${!time_event_handlers[@]}" ; do $teh ; done ; time_event0=$SECONDS ; }`.

#### `pdhl`

- **Declared at:** `etc/ftlrc:33` — `pdhl=`
- **Type:** scalar (string, a file path or empty)
- **Default:** empty
- **Purpose:** If set to a file path, `pdh()` (the debug-message function) also logs messages to that file. Useful for headless debugging.
- **Usage sites:**
  1. `etc/ftlrc:33` — defined.
  2. `etc/core/ftl:75` — `pdh()`: `((pdhl)) && echo "$$ $my_pane: $1" >>ftl_log` (the `>>ftl_log` is a relative path; `pdhl` is the enable flag — the actual file is `ftl_log` in the cwd).

#### `dirmode`

- **Declared at:** `etc/ftlrc:34` — `dirmode=0`
- **Type:** scalar (integer 0–5)
- **Default:** `0`
- **Purpose:** Default directory-preview mode. 0=ftl, 1=du, 2=ls, 3=README, 4=exa, 5=image-montage. Cycled by `zd0`–`zd5` bindings.
- **Usage sites:**
  1. `etc/ftlrc:34` — defined.
  2. `etc/bin/ftl:108` — `pdir_def()`: `[[ "${pdirv[$dirmode]}" ]] && ${pdirv[$dirmode]} || pdir_ftl` — selects the preview function by index.
  3. `etc/core/commands:164-169` — `set_directory_mode0`–`set_directory_mode5` set `dirmode` to 0–5.
  4. `etc/core/ftl:107` — serialized in `save_state`: `dirmode=\"$dirmode\"`.
  5. `etc/core/ftl:127` — `prev_synch()` sources it back.

#### `extmode`

- **Declared at:** `etc/ftlrc:35` — `extmode=0`
- **Type:** scalar (integer 0–5)
- **Default:** `0`
- **Purpose:** Current "external preview mode" — lets the same file type have multiple preview variants. `z1`–`z5` cycle it. Each previewer (`pmd`, `ppdf`, `pmedia`, etc.) checks `extmode` to decide what to render.
- **Usage sites:** 30+ references across `etc/viewers/core`, `etc/core/commands`, `etc/core/ftl`. Notable:
  1. `etc/ftlrc:35` — defined.
  2. `etc/bin/ftl:17` — set to `0` in child-pane init.
  3. `etc/viewers/core:86` — `ext_image()`: `((emode == 1)) && ext_iall || ext_ipng`.
  4. `etc/viewers/core:92` — `ext_pdf()`: branches on `emode` 1 or 3.
  5. `etc/viewers/core:122` — `pimage()`: `((extmode)) && { exiftool ... } || pw3image "$n"`.
  6. `etc/viewers/core:128` — `pmlive()`: `((extmode)) && { player_k ; ... }`.
  7. `etc/viewers/core:130-134` — `pmd` dispatches `pmd_1`/`pmd_2`/`pmd_3`/`pmd_def` by `extmode`.
  8. `etc/viewers/core:139` — `pansi()`: `((!extmode)) && ... || { ((extmode==1)) && ... }`.
  9. `etc/viewers/core:144,147` — `ppdf`/`pepub`: `((extmode==2 || pdf_prev_image))`.
  10. `etc/viewers/core:157-166` — `pcomp`/`_pcomp`: `((extmode)) && { ... }`.
  11. `etc/core/commands:149-153` — `preview_m1`–`preview_m5` set `extmode` to 1–5.
  12. `etc/core/ftl:107` — serialized in `save_state`.

Note: `extmode` and `emode` are *two different variables*. `extmode` is the user-tunable mode; `emode` is set transiently by `external_mode1`/`2`/`3` (`ee`/`er`/`ew` bindings) and is checked by `ext_viewers` in `etc/viewers/core` and by `preview()` in `etc/bin/ftl:190`.

#### `emode`

- **Declared at:** implicitly global; first assigned in `etc/bin/ftl:17` (`emode=0`) and in `etc/core/commands:67-69`.
- **Type:** scalar (integer 0–3)
- **Default:** `0` (set in child-pane init and after each preview dispatch)
- **Purpose:** Transient external-viewer mode flag. Set by `ee`/`er`/`ew` to 1/2/3, consumed by `preview()` in `etc/bin/ftl` to decide whether to call `ext_viewers` (external) or `pviewers` (in-pane). Reset to `0` after each use.
- **Usage sites:**
  1. `etc/bin/ftl:17` — `emode=0` (child-pane init).
  2. `etc/bin/ftl:190` — `preview()`: `((emode)) && { ext_viewers ; emode=0 ; } || { ((prev_all)) && pviewers ; extmode=0 ; }`.
  3. `etc/viewers/core:24` — `ext_viewers`: `((emode == 3)) && { open_with ; return ; }`.
  4. `etc/viewers/core:83-97` — every `ext_*` function branches on `emode == 1` vs other.
  5. `etc/viewers/core:116` — `pdir_image()` (not `ext_*`, but uses `extmode`).
  6. `etc/core/commands:67-69` — `external_mode1`/`2`/`3`: `emode=1`/`2`/`3` then `preview`.
  7. `etc/core/commands:35` — `edit()`: `emode=0` after editor exits.

#### `zooms`, `zoom`

- **Declared at:** `etc/ftlrc:37-38` — `zooms=(85 70 50 30)` / `zoom=1`
- **Type:** `zooms` is an indexed array of integers (percentages); `zoom` is a scalar index into `zooms`.
- **Defaults:** `zooms=(85 70 50 30)`, `zoom=1` (so default preview pane is 70% width).
- **Purpose:** `zooms` defines the available preview-pane widths as percentages of the pane. `zoom` is the current index. `z+` / `+` cycles `zoom`.
- **Usage sites:**
  1. `etc/ftlrc:37-38` — defined.
  2. `etc/core/ftl:46` — `geo_prev()`: `((COLS=(COLS-1) * (100 - ${zooms[zoom]}) / 100))` — computes the listing-pane width from the preview percentage.
  3. `etc/core/ftl:175` — `tsplit()`: `-l ${2:-${zooms[zoom]}%}` — default split size is the current zoom level.
  4. `etc/core/commands:174` — `preview_size()`: `((zoom += 1, zoom >= ${#zooms[@]})) && zoom=0` — cycle.

#### `move_step`

- **Declared at:** `etc/ftlrc:39` — `move_step=4`
- **Type:** scalar (integer)
- **Default:** `4`
- **Purpose:** Number of entries to move in `move_down_step` / `move_up_step` (currently unbound by default — see commented-out bindings in `etc/ftlrc:260-261`).
- **Usage sites:**
  1. `etc/ftlrc:39` — defined.
  2. `etc/core/commands:22-23` — `move_down_step()`: `move $move_step` / `move_up_step()`: `move -$move_step`.

#### `msg_m`, `msg_du`

- **Declared at:** `etc/ftlrc:40-41` — `msg_m='Creating montage ...'` / `msg_du='Computing dir sizes ...'`
- **Type:** scalars (strings)
- **Defaults:** `'Creating montage ...'` / `'Computing dir sizes ...'`
- **Purpose:** Status messages flashed in the header while long-running operations are in progress.
- **Usage sites:**
  1. `etc/ftlrc:40-41` — defined.
  2. `etc/viewers/core:116` — `pdir_image()`: `header '' "$msg_m"` before invoking montage.
  3. `etc/core/commands:192` — `show_size()`: `header '' "$msg_du"` before `dir_dusize`.

#### `find_auto`

- **Declared at:** `etc/ftlrc:42` — `find_auto=README`
- **Type:** scalar (string, a filename)
- **Default:** `README`
- **Purpose:** When entering a directory for the first time (no remembered cursor position), `ftl` auto-selects this file if present.
- **Usage sites:**
  1. `etc/ftlrc:42` — defined.
  2. `etc/bin/ftl:38` — `search="${2:-$([[ "${dir_file[${tab}_$PPWD]}" ]] || echo "$find_auto")}"` — if no remembered index and no explicit search target, default to `find_auto`.

#### `line_color0`, `line_color`, `line_color_hi`

- **Declared at:** `etc/ftlrc:43-45` — `line_color0="\e[2;40;90m"` / `line_color="$line_color0"` / `line_color_hi="\e[38;5;240m"`
- **Type:** scalars (ANSI escape sequences)
- **Defaults:** see above
- **Purpose:** ANSI color codes for the entry-index column (the number to the left of each entry). `line_color0` is the default, `line_color` is the current (swappable, e.g. for highlight), `line_color_hi` is used during `goto_entry` prompt.
- **Usage sites:**
  1. `etc/ftlrc:43-45` — defined.
  2. `etc/bin/ftl:114` — `prepare_entries()`: `printf -v pc "$line_color%${pad}d\e[m¿${pc/\%/%%}" $line` — applies the color to the index.
  3. `etc/core/commands:5` — `goto_entry()`: `line_color="$line_color_hi" ; cdir ; line_color="$line_color0"` — temporarily swap to highlight color during the prompt.

#### `mount_archive`

- **Declared at:** `etc/ftlrc:46` — `mount_archive=0`
- **Type:** scalar (integer 0/1)
- **Default:** `0`
- **Purpose:** If `1`, the `type_handlers` binding mounts archives (zip, rar, tar, etc.) via `fuse-archive` on `enter`.
- **Usage sites:**
  1. `etc/ftlrc:46` — defined.
  2. `etc/bindings/type_handlers:13` — `enter()`: `[[ $mount_archive && $e =~ ^7z|bz2|cab|gz|iso|rar|tar|tar.bz2|tar.gz|zip$ ]] && { mount_archive "$n" ; return ; }`.

#### `cursor_color0`, `cursor_color`, `cursor_color_search`

- **Declared at:** `etc/ftlrc:47-49` — `cursor_color0='\e[7;34m'` / `cursor_color="$cursor_color0"` / `cursor_color_search='\e[7;35m'`
- **Type:** scalars (ANSI escape sequences)
- **Defaults:** `7;34` (reverse blue) / same / `7;35` (reverse magenta)
- **Purpose:** ANSI color for the cursor (the tag glyph of the current entry). `cursor_color0` is default, `cursor_color` is current, `cursor_color_search` is used during incremental search.
- **Usage sites:**
  1. `etc/ftlrc:47-49` — defined.
  2. `etc/bin/ftl:160` — `list()`: `[[ $i == $file ]] && cursor="${cursor_color}$cursor\e[m"` — highlight the current entry's cursor.
  3. `etc/bindings/incremental_search:2` — `incremental_search()`: `cursor_color="$cursor_color_search"` — swap to search color.
  4. `etc/bindings/incremental_search:8` — `incremental_find()`: on ESCAPE, `cursor_color="$cursor_color0"` — restore.
  5. `etc/bindings/tmsu:12` — `tmsu_preview()`: `(($i == $file)) && tags_table+="$cursor_color"` — uses it for the tag-table rendering.

#### `pop_help`, `pop_kbindings`

- **Declared at:** `etc/ftlrc:50-51` — `pop_help=0` / `pop_kbindings=1`
- **Type:** scalars (integers 0/1)
- **Defaults:** `0` / `1`
- **Purpose:** Whether to show help (`?`) and bindings (`c`) in a tmux popup (`1`) or in the preview pane (`0`).
- **Usage sites:**
  1. `etc/ftlrc:50-51` — defined.
  2. `etc/core/commands:13` — `ftl_help()`: `((help_pop)) && { tmux popup ... }` — note: the variable is named `help_pop` here, but defined as `pop_help` in ftlrc — **this is a bug** (the check always evaluates false because `help_pop` is never set).
  3. `etc/core/ftl:57` — `k_bindings()`: `((pop_kbindings)) && k_bpop || k_bfull` — popup vs full-screen for bindings display.

#### `quick_display`

- **Declared at:** `etc/ftlrc:52` — `quick_display=512`
- **Type:** scalar (integer)
- **Default:** `512`
- **Purpose:** Threshold for "quick display" mode. While scanning a directory, every `quick_display` entries, `ftl` flashes the running count in red on the header so the user knows the scan is progressing. Set to `0` to disable.
- **Usage sites:**
  1. `etc/ftlrc:52` — defined.
  2. `etc/bin/ftl:69` — `get_dir_entries()`: `((quick_display && nfiles > 0 && 0 == nfiles % quick_display)) && { echo -e "\e[H\e[31m$nfiles\e[0m" ; qd=1 ; }`.
  3. `etc/bin/ftl:101` — `prepare_entries()`: same check again (since `prepare_entries` iterates the buffered list).
  4. `etc/bin/ftl:138,148,166` — `view_list()`/`list()`: `((qd || gpreview)) || { preview ; ... }` — skip preview while in quick-display mode.

#### `rfilter0`

- **Declared at:** `etc/ftlrc:53` — `rfilter0=`
- **Type:** scalar (string, a `rg` regex)
- **Default:** empty (no reverse filter)
- **Purpose:** Default reverse-filter regex applied to every tab. Example: `rfilter0='\.sw.$'` to always hide vim swap files.
- **Usage sites:**
  1. `etc/ftlrc:53` — defined.
  2. `etc/core/ftl:150` — `tab_setup()`: `rfilters[tab]="$rfilter0"` — every new tab inherits this default.
  3. `etc/core/commands:53` — `clear_filters()`: `rfilters[tab]="$rfilter0"` — reset restores it.

#### `show_line`, `show_size`, `show_date`, `show_tar`

- **Declared at:** `etc/ftlrc:54-57`
- **Type:** scalars (integers)
- **Defaults:** `show_line=1`, `show_size=0`, `show_date=1`, `show_tar=0`
- **Purpose:** Display toggles. `show_line` controls the entry-index column. `show_size` cycles 0→1→2→3 (none / file sizes / file+dir-entry-counts / file+recursive-dir-sizes). `show_date` shows date in header when sort mode is by date. `show_tar` shows extra tar info (slow).
- **Usage sites:**
  1. `etc/ftlrc:54-57` — defined.
  2. `etc/bin/ftl:114` — `prepare_entries()`: `((show_line)) && { ... ; printf -v pc "$line_color%${pad}d\e[m¿..." $line ; ... }`.
  3. `etc/bin/ftl:108-112` — `prepare_entries()`: `((show_size)) && { ... file_size ... dir_size ... }`.
  4. `etc/bin/ftl:183` — `show_header()`: `((s_type == 2 && show_date)) && date=...`.
  5. `etc/bin/ftl:133` — `prepare_entries()`: `((show_size || gpreview)) && hsum=...`.
  6. `etc/core/ftl:31-33` — `dir_size`/`dir_esize`/`dir_dusize` check `show_size == 2`.
  7. `etc/core/commands:191-192` — `hide_size()` / `show_size()` cycle: `((show_size++, show_size = show_size > 3 ? 0 : show_size))`.
  8. `etc/core/commands:193` — `show_stat()` (separate variable `show_stat`, see §6).

#### `tag_new_tab`

- **Declared at:** `etc/ftlrc:58` — `tag_new_tab=`
- **Type:** scalar (string, a directory path)
- **Default:** empty
- **Purpose:** Default location for "copy/move to other tab" when there's only one tab. If empty, `$HOME` is used.
- **Usage sites:**
  1. `etc/ftlrc:58` — defined.
  2. `etc/bindings/to_other_tab:21` — `tag_new_tab= # in default new tab location if no other tab exists` (re-mentioned in the binding).
  3. `etc/bindings/to_other_tab:28` — `tag_new_tab()`: `warn "..." ; tab_new "${tag_new_tab:-$HOME}"`.

#### `TBCOLORS`

- **Declared at:** `etc/ftlrc:60` — `TBCOLORS='236 52'`
- **Type:** scalar (string, two space-separated tmux color numbers)
- **Default:** `'236 52'`
- **Purpose:** Tmux pane border colors to restore on quit (border + active border). Used by `quit2()` via `tbcolor`.
- **Usage sites:**
  1. `etc/ftlrc:60` — defined.
  2. `etc/core/ftl:81` — `quit2()`: `[[ $pfs == $fs ]] && tbcolor $TBCOLORS` — only the main pane restores colors on quit.

#### `etag`

- **Declared at:** `etc/ftlrc:63` — `etag=0`
- **Type:** scalar (integer 0/1)
- **Default:** `0`
- **Purpose:** Master toggle for the etag column. When `0`, no etags are computed or displayed. When `1`, the current etag source (`etag_s`) is invoked.
- **Usage sites:**
  1. `etc/ftlrc:63` — defined.
  2. `etc/bin/ftl:53` — `get_dir_entries()`: `((etag)) && etag_dir` — invoke the etag's directory-scan function.
  3. `etc/bin/ftl:106` — `prepare_entries()`: `((etag)) && { etag_tag "$pnc" external_tag external_tag_length ; ... }`.
  4. `etc/core/ftl:131` — `prev_synch()`: `((gpreview)) && { [[ "$etag_s" ]] && { source "$FTL_CFG/etags/$etag_s" ; ... } || source "$FTL_CFG/etags/none" ; }`.
  5. `etc/core/commands:227` — `etag_show()`: `((etag^=1))` — toggle.
  6. `etc/core/commands:228` — `etag_select()`: sets `etag=1` after choosing a source.
  7. `etc/etags/git:8,46` — `etag_dir()`: `((etag)) && git rev-parse ...` / `etag_tag()`: `(( is_git && etag ))`.
  8. `etc/etags/tmsu:4` — `etag_dir()`: `((etag)) && { ... }`.
  9. `etc/etags/virtual:2` — `etag_tag()`: `(( etag )) && { ... }`.
  10. `etc/bindings/leader_git:2` — `git_etags()`: `etag_s=git ; source ... ; ((etag^=1))`.

#### `sort_type0`, `sort_reversed0`

- **Declared at:** `etc/ftlrc:66-67` — `sort_type0=0` / `sort_reversed0=`
- **Type:** scalars (`sort_type0` integer 0–2; `sort_reversed0` string, either `-r` or empty)
- **Defaults:** `0` (alphanumeric) / empty (not reversed)
- **Purpose:** Default sort type and reversed flag, applied to every new tab. `sort_type`: 0=alphanumeric, 1=size, 2=date.
- **Usage sites:**
  1. `etc/ftlrc:66-67` — defined.
  2. `etc/bin/ftl:38` — `cview()`: `s_type=$sort_type0 ; s_reversed=$sort_reversed0` — initialize per-directory sort from defaults, before `.ftlrc_dir` overrides.
  3. `etc/bin/ftl:39` — `cview()`: `s_type=${sort_type[tab]:-$s_type}` — per-tab override takes precedence.

### 2.4 Glyph Tables (indexed arrays)

These indexed arrays hold the glyphs rendered in the header to indicate current mode.

#### `sglyph`

- **Declared at:** `etc/ftlrc:70` — `sglyph=( ⍺ 🡕 )`
- **Type:** indexed array of strings (Unicode glyphs)
- **Default:** `( ⍺ 🡕 )` — alphanumeric, size
- **Purpose:** Sort-type glyphs. Index 0 = alphanumeric (`⍺`), 1 = size (`🡕`).
- **Usage sites:**
  1. `etc/ftlrc:70` — defined.
  2. `etc/core/dir_file_filter:7` — `filter_rst()`: `sort_glyph(){ echo ${sglyph[s_type]} ; }` — default sort-glyph function.
  3. `etc/bin/ftl:185` — `show_header()`: `$(sort_glyph)` — invokes the function.

#### `iglyph`

- **Declared at:** `etc/ftlrc:71` — `iglyph=('' ᴵ ᴺ)`
- **Type:** indexed array
- **Default:** `('' ᴵ ᴺ)` — all, no-image, image-only
- **Purpose:** Image-mode glyphs. Index 0 = all (empty), 1 = no-image (`ᴵ`), 2 = image-only (`ᴺ`).
- **Usage sites:**
  1. `etc/ftlrc:71` — defined.
  2. `etc/bin/ftl:176` — `show_header()`: `head="${lglyph[lmode[tab]]}${iglyph[vmode[tab]]}..."`.

#### `lglyph`

- **Declared at:** `etc/ftlrc:72` — `lglyph=('' ᵈ ᶠ)`
- **Type:** indexed array
- **Default:** `('' ᵈ ᶠ)` — all, dir-only, file-only
- **Purpose:** Listing-mode glyphs. Index 0 = all (empty), 1 = dir-only (`ᵈ`), 2 = file-only (`ᶠ`).
- **Usage sites:**
  1. `etc/ftlrc:72` — defined.
  2. `etc/bin/ftl:176` — `show_header()`: `${lglyph[lmode[tab]]}`.

#### `tglyph`

- **Declared at:** `etc/ftlrc:73` — `tglyph=('' ¹ ² ³ D)`
- **Type:** indexed array
- **Default:** `('' ¹ ² ³ D)` — class 0 (default `▪`), class 1 (`¹`), class 2 (`²`), class 3 (`³`), class 4 (`D`)
- **Purpose:** Tag-class glyphs. Index 0 is unused (default tag is `▪`), 1–4 are the four selectable classes.
- **Usage sites:**
  1. `etc/ftlrc:73` — defined.
  2. `etc/core/commands:47` — `selection_class_n()`: `tags[${files[file]}]=${tglyph[$1]}` — assign the class glyph.
  3. `etc/core/commands:47` — also used to check existing class: `[[ ${tags[${files[file]}]} == ${tglyph[$1]} ]]`.

### 2.5 Filter Regexes

#### `ifilter`

- **Declared at:** `etc/ftlrc:76` — `ifilter='svg|webp|jpg|jpeg|JPG|png|gif|bmp'`
- **Type:** scalar (extended regex)
- **Default:** `'svg|webp|jpg|jpeg|JPG|png|gif|bmp'`
- **Purpose:** Regex matching image file extensions. Used by `pviewers`/`ext_viewers` to dispatch to image previewers, by `view_mode_image`/`not_image` to filter the listing, and by `image_size` etag to find images.
- **Usage sites:**
  1. `etc/ftlrc:76` — defined.
  2. `etc/viewers/core:15,50` — `ext_viewers`/`pviewers`: `[[ $e =~ $ifilter ]] && { ext_image ; return ; }` / `{ pimage ; return ; }`.
  3. `etc/core/commands:136` — `preview_image()`: `for e in $(tr '|' ' ' <<< "$ifilter") ; do pignore[${e}]=$no_image_preview ; done`.
  4. `etc/core/commands:210-211` — `view_mode_image`/`not_image`: `tfilters[tab]="$ifilter$"`.
  5. `etc/etags/image_size:9` — `rg "${ifilter@Q}$"` to find images.
  6. `etc/bindings/fzf_pane_preview` (indirectly via `pviewers`).

#### `mfilter`

- **Declared at:** `etc/ftlrc:77` — `mfilter='mp3|mp4|flv|mkv|webm'`
- **Type:** scalar (extended regex)
- **Default:** `'mp3|mp4|flv|mkv|webm'`
- **Purpose:** Regex matching media (video/audio) file extensions.
- **Usage sites:**
  1. `etc/ftlrc:77` — defined.
  2. `etc/viewers/core:17,52` — `ext_viewers`/`pviewers`: `[[ $e =~ $mfilter ]] && { ext_media ; return ; }` / `{ pmedia ; return ; }`.
  3. `etc/core/commands:171-172` — `preview_queue`/`preview_show`: `[[ $e =~ $mfilter ]] && { ... }`.

#### `pdf_prev_image`

- **Declared at:** `etc/ftlrc:78` — `pdf_prev_image=0`
- **Type:** scalar (integer 0/1)
- **Default:** `0`
- **Purpose:** If `1`, PDFs are previewed as PNG images (via `mutool draw` + `w3mimgdisplay`) instead of text.
- **Usage sites:**
  1. `etc/ftlrc:78` — defined.
  2. `etc/viewers/core:92` — `ext_pdf()`: `((pdf_prev_image)) && run_maxed mupdf "$n"`.
  3. `etc/viewers/core:144,147` — `ppdf`/`pepub`: `((extmode==2 || pdf_prev_image)) && ppdfpng`.
  4. `etc/core/commands:145` — `view_mode_pdf()`: `((pdf_prev_image ^= 1))`.

### 2.6 FZF Options

#### `fzf_opt`, `fzfp_opt`, `fzf_sxiv_opt`

- **Declared at:** `etc/ftlrc:81-83`
- **Type:** scalars (strings of fzf flags)
- **Defaults:** `fzf_opt="-p 90% --cycle --reverse --info=inline --color=hl+:214,hl:214"`, `fzfp_opt="--cycle --expect=ctrl-t --reverse"`, `fzf_sxiv_opt="-0 -1 -m --expect=ctrl-t --bind alt-a:select-all"`
- **Purpose:** Reusable fzf option strings. `fzf_opt` for popup-style fzf, `fzfp_opt` for pane fzf (with ctrl-t to open in new tab), `fzf_sxiv_opt` for sxiv integration.
- **Usage sites:** 30+ across `etc/core/commands` (every `find_fzf*`, `gmark_fzf`, `mark_fzf`, `selection_*_fzf`, `ghistory*`, `tag_fzf`, etc.), `etc/bindings/tmsu`, `etc/bindings/to_other_tab`, `etc/bindings/fzf_pane_preview`, `etc/core/ftl` (`tag_fzf`).

#### `FZF_LISTEN`, `FZF_LISTEN_COMMAND`

- **Declared at:** `etc/ftlrc:84-85` — `FZF_LISTEN=4466` / `FZF_LISTEN_COMMAND='fd -H -I'`
- **Type:** scalars (integer port, string shell command)
- **Defaults:** `4466` / `'fd -H -I'`
- **Purpose:** Used by the experimental `fzf_search` binding (`V` key) which runs `fzf --listen` on `FZF_LISTEN` and polls it via `xh` (HTTP). `FZF_LISTEN_COMMAND` is the default command fzf runs to list files.
- **Usage sites:**
  1. `etc/ftlrc:84-85` — defined.
  2. `etc/bindings/fzf_search:10` — `tsucommand _FZF_LISTEN "FZF_DEFAULT_COMMAND='$FZF_LISTEN_COMMAND' fzf --listen $FZF_LISTEN"`.
  3. `etc/bindings/fzf_search:13,64` — `fzf_answer="$(xh :$FZF_LISTEN limit==...)"`.

### 2.7 External Command Config

These scalars name the external programs `ftl` invokes. All are user-overridable.

| variable | default | declared at | used in |
|----------|---------|-------------|---------|
| `SXIV` | `sxiv` | `etc/ftlrc:88` | `etc/core/commands:99-103`, `etc/viewers/core:87` |
| `GIF_VIEWER` | (empty) | `etc/ftlrc:89` | `etc/viewers/core:88` |
| `EDITOR` | `"vim -p"` | `etc/ftlrc:90` | `etc/core/ftl:18,35`, `etc/core/commands:9-12`, `etc/viewers/core:95`, `etc/bindings/lib/extra`, `etc/bindings/virtual_entries:101` |
| `FILE_DIFF` | `vimdiff` | `etc/ftlrc:91` | `etc/bindings/file_diff:13` |
| `FTLI_CLEAN` | `1` | `etc/ftlrc:93` | `etc/core/ftl:14` (passed to `ftli`), `etc/bin/ftli:52` |
| `FTLI_H` | `21` | `etc/ftlrc:94` | `etc/core/ftl:14`, `etc/bin/ftli:54` |
| `FTLI_W` | `10` | `etc/ftlrc:95` | `etc/core/ftl:14`, `etc/bin/ftli:53` |
| `FTLI_Z` | `0` | `etc/ftlrc:96` | `etc/core/ftl:14`, `etc/core/commands:104`, `etc/bin/ftli:62` |
| `GPGID` | `CHANGE.ME` | `etc/ftlrc:98` | `etc/bindings/lib/extra:19` |
| `G_PLAYER` | `"vlc -f"` | `etc/ftlrc:100` | `etc/viewers/core:82,90,91,92,93` |
| `T_PLAYER` | `"mplayer -vo null"` | `etc/ftlrc:101` | `etc/viewers/core:91` |
| `TE_PLAYER` | `"vlc -I curses"` | `etc/ftlrc:102` | `etc/viewers/core:90` |
| `T_PLAYER_STATUS` | (mplayer with statusline) | `etc/ftlrc:103` | `etc/viewers/core:128` |
| `B_PLAYER` | `"$FTL_CFG/etc/viewers/mplayer_local"` | `etc/ftlrc:104` | `etc/viewers/core:172` |
| `Q_PLAYER` | `"$FTL_CFG/etc/viewers/cmus"` | `etc/ftlrc:105` | `etc/viewers/core:171` |
| `PAGER_ANSI` | `'/usr/bin/less -R'` | `etc/ftlrc:107` | `etc/viewers/core:139` |
| `MD_PAGER` | `'/usr/bin/less -R'` | `etc/ftlrc:109` | `etc/viewers/core:131,132,136,23` |
| `MD_RENDER0` | `'ptext'` | `etc/ftlrc:110` | `etc/viewers/core:134` |
| `MD_RENDER1` | `'vmd'` | `etc/ftlrc:111` | `etc/viewers/core:131` |
| `MD_RENDER2` | `'vmd'` | `etc/ftlrc:112` | `etc/viewers/core:132` |
| `MD_DIR_RENDER` | `"vmd"` | `etc/ftlrc:113` | `etc/viewers/core:136` (note: line has a `$` typo: `$MD_DIR_RENDER="vmd"` — this actually runs the command `vmd` with `MD_DIR_RENDER=vmd` as an env var, which is a bug) |
| `HEXVIEW` | `hexdump` | `etc/ftlrc:115` | `etc/core/commands:7` |
| `HEXEDIT` | `hexedit` | `etc/ftlrc:116` | `etc/core/commands:8` |
| `MIMETYPE` | `mimemagic` | `etc/ftlrc:118` | `etc/core/ftl:62` (`mime_cache`), `etc/viewers/core:69` |
| `NCDU` | `ncdu` | `etc/ftlrc:119` | `etc/viewers/core:112` |
| `JSON_VIEWER` | `jless` | `etc/ftlrc:120` | `etc/viewers/core:96,141` |
| `YAML_VIEWER` | `"yam -i"` | `etc/ftlrc:121` | `etc/viewers/core:142` |
| `EXA_COLORS` | (long string) | `etc/ftlrc:123` | `etc/viewers/core:115` |
| `EXA_OPTIONS` | `"-l --tree -L 3 --header --color=always"` | `etc/ftlrc:124` | `etc/viewers/core:115` |
| `RM` | `"rm -rf"` | `etc/ftlrc:127` | `etc/core/ftl:29,30`, `etc/bindings/type_handlers` (indirectly) |
| `CMD_COLS` | `150` | `etc/ftlrc:141` | `etc/core/ftl:60` (`k_bgen`) |

### 2.8 Key Binding Globals

#### `redo_key`, `leader_key`

- **Declared at:** `etc/ftlrc:150-151` — `redo_key='.'` / `leader_key='BACKSLASH'`
- **Type:** scalars (strings, key-token names)
- **Defaults:** `'.'` / `'BACKSLASH'`
- **Purpose:** `redo_key` is the key that re-runs the last command (excludes movement commands). `leader_key` is the prefix key for multi-key bindings. Both are token names from the `get_key` normalizer (e.g. `BACKSLASH`, `SPACE`, `QUESTION_MARK`).
- **Usage sites:**
  1. `etc/ftlrc:150-151` — defined.
  2. `etc/core/keyboard:64` — `key_command()`: `[[ "$REPLY" == "$leader_key" ]] && REPLY=LEADER` — translate the user's key to the internal `LEADER` token.
  3. `etc/core/keyboard:89` — `key_command()`: `[[ "$HAS_COUNT$keys_command" == "$redo_key" && "$keys_latest_command" ]] && { $keys_latest_command ; ... }` — redo dispatch.

### 2.9 Associative Array Config

#### `marks`

- **Declared at:** `etc/ftlrc:20` — `declare -A marks=([0]=/$ [1]="$HOME/$" ...)`
- **Type:** associative array (string key → string path-with-`$`-suffix)
- **Default:** `([0]=/$ [1]="$HOME/$" [2]=/CHANGE_ME/dir/filename [3]=/CHANGE_ME/dir/filename [$"'"]="$(tail -n1 $ghist)")`
- **Purpose:** Local (per-session) bookmarks. Keys are single characters (digits, `'`, letters). Values are paths ending in `$` for directories or no suffix for files. The `'` key is special: it auto-updates to the previous directory on every `cd`.
- **Usage sites:**
  1. `etc/ftlrc:20` — defined.
  2. `etc/core/ftl:35` — `cview()` (in `etc/bin/ftl:35`): `marks["'"]="$n"` — update the `'` mark to the previous entry on every directory change.
  3. `etc/core/commands:107` — `mark()`: `marks[$REPLY]="${files[file]}/$"` (dir) or `"${files[file]}"` (file).
  4. `etc/core/commands:108` — `mark_fzf()`: `printf "%s\n" "${marks[@]}"`.
  5. `etc/core/commands:109` — `mark_go()`: `cdir "$d" "$(basename "${marks[$REPLY]}")"`.
  6. `etc/core/commands:110` — `mark_go_tab()`: like `mark_go` but in a new tab.

#### `dir_dest`

- **Declared at:** `etc/ftlrc:22` — `declare -A dir_dest=()`
- **Type:** associative array (single-char key → directory path)
- **Default:** empty
- **Purpose:** Single-letter aliases for "copy/move to destination" (`PP` / `PM` bindings). User populates this in their `ftlrc`.
- **Usage sites:**
  1. `etc/ftlrc:22` — defined.
  2. `etc/core/commands:205` — `tag_copy_dest()`: `[[ $REPLY && -n ${dir_dest[$REPLY]} ]] && tag_copy "${dir_dest[$REPLY]}"`.
  3. `etc/core/commands:206` — `tag_move_dest()`: same pattern.

#### `cmd_aliases`

- **Declared at:** `etc/ftlrc:144` — `declare -A cmd_aliases=([csx]="split finfo | xargs -0" [cfx]="full finfo | xargs -0")`
- **Type:** associative array (alias name → command string)
- **Default:** `([csx]="split finfo | xargs -0" [cfx]="full finfo | xargs -0")`
- **Purpose:** Aliases for the command prompt. `csx ls -l` expands to `split finfo | xargs -0 ls -l`.
- **Usage sites:**
  1. `etc/ftlrc:144` — defined.
  2. `etc/core/lib/shell:45` — `shell_command()`: `[[ -n "${cmd_aliases[$cmd]}" ]] && cmd_parts=(${cmd_aliases[$cmd]} $(printf "%s " "${cmd_parts[@]:1}")) ; cmd="$cmd_parts"`.

#### `user_colors`

- **Declared at:** `etc/ftlrc:25` (commented out by default) — `# declare -A user_colors=([?]="30;42")`
- **Type:** associative array (filename → ANSI color code)
- **Default:** undefined (commented out)
- **Purpose:** Override `lscolors` for specific filenames. If a filename matches a key, that color is used instead of `LS_COLORS`.
- **Usage sites:**
  1. `etc/ftlrc:25` — commented example.
  2. `etc/core/dir_file_filter:16` — `user_color()`: `((${#user_colors[@]})) && { while read cf ; do ((${#user_colors[$cf]})) && echo -e "\e[${user_colors[$cf]}m$cf\e[m" || echo "$cf" ; done ; } || cat` — applied in the listing pipeline via `output_path`.

---

*Continued in next section...*

## 3. Core Runtime State (from `ftl_setup`)

**File:** `etc/core/ftl_setup` (17 lines). This is the second file sourced after `etc/core/ftl` and `etc/core/debug`. It declares the core runtime globals and sources `ftlrc`.

### 3.1 The Big `declare -Ag` Line (line 6)

```
declare -Ag C bindings kbd_trie key_map vfiles vdirs time_event_handlers marks ; source $FTL_CFG/ftlrc 2>&- || source $FTL_CFG/etc/ftlrc ;
```

This declares seven associative arrays as global *before* sourcing `ftlrc`. The `ftlrc` then populates them via `bind` calls and direct assignments.

#### `C`

- **Declared at:** `etc/core/ftl_setup:6` — `declare -Ag C ...`
- **Type:** associative array (command-name string → key-sequence string)
- **Default:** empty (populated by `bind` calls in `ftlrc` and binding plugins)
- **Purpose:** Reverse map from command name to its key sequence. Used to send a command to the input queue by looking up its key: `R=${C[refresh_pane]}` sets `R` to the key for `refresh_pane`, which the main loop then consumes.
- **Usage sites:**
  1. `etc/core/ftl_setup:6` — declared.
  2. `etc/core/keyboard:24` — `bind()`: `C[$command]="$shortcut"` — populated on every `bind`.
  3. `etc/core/keyboard:40` — `unbind()`: `unset C[$command]`.
  4. `etc/core/keyboard:71` — (commented) `pdhn "[...] -> ${kbd_trie[$HAS_COUNT$keys_command]}"`.
  5. `etc/core/commands:34` — `goto_alt1()`: `R="${C[find_next]}"`.
  6. `etc/core/commands:78` — `find_entry()`: `R="${C[find_next]}"`.
  7. `etc/core/commands:129` — `pane_go_next()`: `tmux send -t $p ${C[refresh_pane]}`.
  8. `etc/core/commands:177` — `quit_all()`: `pane_send "${C[quit_ftl]}"` / `tmux send -t $main_pane ${C[quit_all]}`.
  9. `etc/core/commands:181` — `SIG_PANE()`: `R=${C[refresh_pane]}`.
  10. `etc/core/commands:185` — `shell_files()`: `R=${C[shell_file]}`.
  11. `etc/core/ftl:52` — `inotify_()`: `tmux send -t "$my_pane" ${C[refresh_pane]}`.
  12. `etc/core/ftl:68` — `pane_close()`: `tmux send -t ${panes[0]} ${C[quit_ftl]}`.
  13. `etc/core/ftl:80` — `quit()`: `tmux send -t $main_pane å`.
  14. `etc/core/ftl:180` — `winch()`: `R="${C[refresh_pane]}$R"`.
  15. `etc/core/lib/shell:24-25` — `shell_command()`: `[[ "${kbd_trie[$1]}" ]] && R=${kbd_trie[$1]} && return ; [[ ${C[$1]} ]] && R=${C[$1]} && return` — command-prompt can invoke a binding by name.
  16. `etc/bindings/fzf_pane_preview:46` — `R=${C[refresh_pane]}` (indirectly via `list`).
  17. `etc/bindings/fzf_search:38` — `CTL-V` binding: `R` is set, fzf client polls.

#### `bindings`

- **Declared at:** `etc/core/ftl_setup:6` — `declare -Ag bindings ...`
- **Type:** associative array (display-string → tab-separated metadata)
- **Default:** empty (populated by `bind`)
- **Purpose:** The data behind the `c` (show bindings) command. Each entry is `"map\tsection\tdscut\tcommand\thelp"`. The display key (`dscut`) includes alt-gr / shift-alt-gr annotations like `⇑a/a`.
- **Usage sites:**
  1. `etc/core/ftl_setup:6` — declared.
  2. `etc/core/keyboard:24` — `bind()`: `bindings[$dscut]="$map\t$section\t$dscut\t$command\t$help"`.
  3. `etc/core/keyboard:42` — `unbind()`: `unset bindings[$dscut]`.
  4. `etc/core/ftl:60` — `k_bgen()`: `printf '%s\n' "${bindings[@]}" | sort -h | column -t --table-columns "..." -s $'\t' -c $CMD_COLS` — renders the binding table for fzf.

#### `kbd_trie`

- **Declared at:** `etc/core/ftl_setup:6` — `declare -Ag kbd_trie ...`
- **Type:** associative array (key-sequence string → command-name string OR integer counter)
- **Default:** empty (populated by `bind`)
- **Purpose:** The forward map: key sequence → command. For multi-key sequences, intermediate prefixes store an integer counter (incremented by `bind`) so the dispatcher knows the sequence is a prefix of something longer. Only the full sequence maps to a command name.
- **Usage sites:**
  1. `etc/core/ftl_setup:6` — declared.
  2. `etc/core/keyboard:16-19` — `bind()`: `((kbd_trie[$shortcut]++))` for each prefix, then `kbd_trie[$shortcut]="$command"` for the full sequence.
  3. `etc/core/keyboard:23` — `bind()`: `((ftl_bind_check && ${kbd_trie[$shortcut]} > 1))` — warn on override.
  4. `etc/core/keyboard:38` — `unbind()`: `command="{$kbd_trie[$shortcut]}"` (note: this looks buggy — the braces are literal, not array-syntax).
  5. `etc/core/keyboard:41` — `unbind()`: `unset kbd_trie[$shortcut]`.
  6. `etc/core/keyboard:71` — `key_command()`: `keys_command="$keys_command$REPLY" ; (( keys_in++))` (the `kbd_trie` lookup is on the next line).
  7. `etc/core/keyboard:77` — `key_command()`: `[[ $(type -t "${kbd_trie[$HAS_COUNT$keys_command]}") == function ]]` — is the looked-up command a function?
  8. `etc/core/keyboard:81` — `key_command()`: `keys_function=${kbd_trie[$HAS_COUNT$keys_command]}`.
  9. `etc/core/keyboard:89` — `key_command()`: `[[ "$HAS_COUNT$keys_command" == "$redo_key" && "$keys_latest_command" ]]` (redo doesn't use `kbd_trie` directly).
  10. `etc/core/lib/shell:24` — `shell_command()`: `[[ "${kbd_trie[$1]}" ]] && R=${kbd_trie[$1]} && return` — command-prompt can invoke a binding by its name.

#### `key_map`

- **Declared at:** `etc/core/ftl_setup:6` — `declare -Ag key_map ...`
- **Type:** associative array (effectively used as a scalar flag — only the "is set" matters)
- **Default:** empty
- **Purpose:** Sub-mode dispatch override. When non-empty, `key_command` calls the function named in `key_map` instead of doing normal trie dispatch. Used by `incremental_search` (sets `key_map=incremental_find`) and `fzf_search` (sets `key_map=fzf_client`).
- **Usage sites:**
  1. `etc/core/ftl_setup:6` — declared.
  2. `etc/core/keyboard:66` — `key_command()`: `[[ -n "$key_map" ]] && { $key_map ; return ; }` — if a sub-mode is active, delegate entirely.
  3. `etc/bindings/incremental_search:2` — `incremental_search()`: `key_map=incremental_find` — enter sub-mode.
  4. `etc/bindings/incremental_search:8` — `incremental_find()`: on ESCAPE, `key_map=` — exit sub-mode.
  5. `etc/bindings/fzf_search:22` — `show_fzf_view()`: `key_map=fzf_client`.
  6. `etc/bindings/fzf_search:47,49` — `fzf_client()`: on ENTER/ESCAPE/DEL, `key_map=` — exit.

#### `vfiles`, `vdirs`

- **Declared at:** `etc/core/ftl_setup:6` — `declare -Ag vfiles vdirs ...`
- **Type:** associative arrays (virtual-entry name → `1`)
- **Default:** empty
- **Purpose:** Virtual-entry injection. `vfiles` maps virtual file names to `1`; `vdirs` maps virtual directory names to `1`. Populated by `v_entries()` from user-provided callback functions. The listing pipeline (`files_virt`/`dirs_virt`) includes these as fake entries.
- **Usage sites:**
  1. `etc/core/ftl_setup:6` — declared.
  2. `etc/core/ftl:184` — `vfiles_on()`: `declare -Ag vfiles=() vdirs=()`.
  3. `etc/core/ftl:186` — `v_entries()`: `vfiles=() vdirs=() ; ((vfiles_on)) && { while read -r v ; do vdirs[$v]=1 ; done < <(vdirs_get "$@") ; while read -r v ; do vfiles[$v]=1 ; done < <(vfiles_get "$@") ; }`.
  4. `etc/core/ftl:75` — `key_command()`: `((${#vfiles[@]} || ${#vdirs[@]})) && { vfile_key "$keys_command" && return ; }` — let virtual-entry key handler intercept.
  5. `etc/core/dir_file_filter:42-43` — `files_virt()`: `((${#vfiles[@]})) && printf "0\t0\t%s\n" "${!vfiles[@]}"` / `dirs_virt()`: same for `vdirs`.
  6. `etc/viewers/core:35` — `pviewers()`: `((${#vfiles[@]} || ${#vdirs[@]})) && { vfile_prev && return ; }` — let virtual-entry preview handler intercept.
  7. `etc/etags/virtual:2` — `etag_tag()`: `((${vfiles[$b1]:-0} || ${vdirs[$b1]:-0})) && r2='ᵛ '` — mark virtual entries with `ᵛ`.
  8. `etc/bindings/virtual_entries:26,39,49` — checks `${#vfiles[...]}` / `${#vdirs[...]}` in color/preview/key callbacks.

#### `time_event_handlers`

- **Declared at:** `etc/core/ftl_setup:6` — `declare -Ag time_event_handlers ...`
- **Type:** associative array (function-name → function-name, used as a set)
- **Default:** empty
- **Purpose:** Set of functions to call every `time_event` seconds. User code registers handlers by assignment: `time_event_handlers[my_handler]=my_handler`.
- **Usage sites:**
  1. `etc/core/ftl_setup:6` — declared.
  2. `etc/core/ftl:164` — `time_event()`: `for teh in "${!time_event_handlers[@]}" ; do $teh ; done`.
  3. `etc/core/ftl:86-89` (commented out) — example: `# time_event_handlers[reset_qshell_call]=reset_qshell_call`.

#### `marks` (re-listed for the `ftl_setup` declaration)

- See §2.9 — `marks` is declared both in `ftl_setup:6` (as empty `-Ag`) and in `ftlrc:20` (with default values). The `ftlrc` assignment wins because it runs after.

### 3.2 The Second `declare -A -g` Line (line 7)

```
my_pane=$(pid_2_pane $$) ; tags_size=0 ; declare -A -g dir_file mime pignore lignore lkeep lkeep_tab tail tags ntags ftl_env du_size ; mkapipe 4 5 6
```

This line initializes `my_pane` and `tags_size`, declares nine more associative arrays, and creates three fifos on file descriptors 4, 5, 6.

#### `my_pane`

- **Declared at:** `etc/core/ftl_setup:7` — `my_pane=$(pid_2_pane $$)`
- **Type:** scalar (tmux pane id like `%5`)
- **Default:** result of `pid_2_pane $$`
- **Purpose:** The tmux pane id of *this* `ftl` process. Used in every `tmux send -t $my_pane` / `tmux selectp -t $my_pane` / `tmux split-window -t $my_pane` call. Computed once at startup by walking the tmux pane list and `ps` process tree.
- **Usage sites:** 30+ references. Notable:
  1. `etc/core/ftl_setup:7` — assigned.
  2. `etc/bin/ftl:14` — `echo $my_pane >$fs/pane` (main pane records itself).
  3. `etc/core/ftl:8,10,11` — `try_errorp`/`warn`/`error` use `$my_pane` in tmux popup targeting.
  4. `etc/core/ftl:52` — `inotify_()`: `tmux send -t "$my_pane" ${C[refresh_pane]}`.
  5. `etc/core/ftl:66` — `pane_extra()`: `tmux selectp -t $new_pane` (after spawning child).
  6. `etc/core/ftl:69` — `pane_next()`: `[[ $p == $my_pane ]]` — find the next pane after ours.
  7. `etc/core/ftl:75` — `pdh()`: `tmux send -t $pdh "$$ $my_pane: ..."` — debug pane shows which pane sent the message.
  8. `etc/core/ftl:77` — `pdh_show()`: `tsplit "$FTL_CFG/etc/bin/fpdh $pfs" 30% -v $my_pane`.
  9. `etc/core/ftl:78` — `pid_2_pane()` (the function itself uses `$$`).
  10. `etc/core/ftl:175` — `tsplit()`: `tmux sp ... -t $my_pane ...` — split relative to our pane.
  11. `etc/core/ftl:180` — `winch()`: `geometry` reads from `$my_pane`.
  12. `etc/core/commands:129` — `pane_go_next()`: `tmux selectp -t $my_pane` (fallback).
  13. `etc/core/commands:229` — `SIG_PANE()`: `tmux selectp -t $my_pane` (fallback).
  14. `etc/bin/ftl:191` — `preview()` (child pane): `echo $my_pane >$fsp/pane` so the main pane knows who signaled.
  15. `etc/bin/ftli:46` — `my_pane=$(pid_2_pane $$)` (the image-preview daemon also computes its own).

#### `tags_size`

- **Declared at:** `etc/core/ftl_setup:7` — `tags_size=0`
- **Type:** scalar (integer, in bytes)
- **Default:** `0`
- **Purpose:** Total byte size of all selected (tagged) entries. Displayed in the header by `tags_head()`. Incremented/decremented by `tags_size +`/`-` (which is a *function*, not an arithmetic op — see below).
- **Usage sites:**
  1. `etc/core/ftl_setup:7` — initialized to `0`.
  2. `etc/core/ftl:29` — `delete_cur()`: `tags_size - "$n"` (function call).
  3. `etc/core/ftl:155` — `tags_clear()`: `tags_size=0`.
  4. `etc/core/ftl:157-160` — `tag_flip`/`tag_set`/`tag_unset`/`tags_unset`: call `tags_size +`/`-`.
  5. `etc/core/ftl:167` — `tags_size()`: the function: `[[ $1 == + ]] && { ((tags_size+=$(stat --printf="%s" "$2"))) ; true ; } || ((tags_size-=$(stat --printf="%s" "$2")))`.
  6. `etc/core/ftl:168` — `tags_head()`: `numfmt --to=iec --format "%f" -- "$tags_size"`.
  7. `etc/core/commands:46` — `selection_class_c()`: `((stagsi++))` (doesn't touch `tags_size` directly, but `selection_class_n` does via `tag_flip`).
  8. `etc/core/commands:102-103,200-202` — `image_select*`/`select_all*`: `tags_size + "$i"`.
  9. `etc/bindings/lib/compress:50` — `compress()`: `tags=() ; cdir '' "$new_file"` (doesn't reset `tags_size` — possible bug).

Note the name collision: `tags_size` is *both* a scalar variable *and* a function. Bash allows this because function names and variable names occupy different namespaces — `tags_size` (no `$`) is the function, `$tags_size` is the variable. The function manipulates the variable.

#### `dir_file`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g dir_file ...`
- **Type:** associative array (`"${tab}_${PWD}"` → integer index)
- **Default:** empty
- **Purpose:** Remembers the selected entry index per (tab, directory). Key is `"${tab}_${PWD}"`. When you navigate back to a directory, `ftl` restores the cursor to where you were.
- **Usage sites:**
  1. `etc/core/ftl_setup:7` — declared.
  2. `etc/bin/ftl:38` — `cview()`: `search="${2:-$([[ "${dir_file[${tab}_$PPWD]}" ]] || echo "$find_auto")}"` — if no remembered index, default to `README`.
  3. `etc/bin/ftl:145` — `list()`: `file=${dir_file[${tab}_$PWD]:-0}` — read the remembered index.
  4. `etc/bin/ftl:145` — `list()`: `[[ "$1" ]] && dir_file[${tab}_$PWD]="$1"` — update on explicit selection.
  5. `etc/core/ftl:64` — `move()`: `((nf != file)) && dir_file[${tab}_$PWD]=$nf` — update on movement.
  6. `etc/core/commands:27-33` — `top_file_bottom`/`goto_first_*`/`goto_last_file`/`goto_high_file`/`goto_low_file`/`move_percent`: all set `dir_file[$twd]`.
  7. `etc/core/commands:197-199` — `tab_next`/`tab_prev`/`tab_goto`: read `dir_file[${tab}_${tabs[tab]}]` to restore position in the new tab.
  8. `etc/core/ftl:107` — `save_state`: serializes `sindex=${dir_file[${tab}_${files[file]}]}`.
  9. `etc/core/ftl:133` — `prev_synch`: `cdir "$sdir" '' "$sindex"` — restores from serialized.
  10. `etc/core/ftl:147` — `_tab_read`: `dir_file[${tab}_$(realpath "$1")]=${icache[$1/$2]}` — when reading tabs from a file, restore positions.

#### `mime`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g mime ...`
- **Type:** associative array (`"$PWD/$filename"` → mime-type string)
- **Default:** empty
- **Purpose:** Mime-type cache. Cleared on every directory change. Populated lazily by `mime_cache` in batches of 20 entries at a time (to amortize the `mimemagic` subprocess cost).
- **Usage sites:**
  1. `etc/core/ftl_setup:7` — declared.
  2. `etc/bin/ftl:38` — `cview()`: `mime=()` — clear on every directory change.
  3. `etc/core/ftl:29` — `delete_cur()`: `mime=()` — invalidate after deletion.
  4. `etc/core/ftl:30` — `delete_tag()`: `mime=()` — invalidate after deletion.
  5. `etc/core/ftl:61` — `mime_get()`: `[[ "${mime[$n]}" ]] || mime_cache "$n" ; mtype="${mime[$n]}"` — read or populate.
  6. `etc/core/ftl:62` — `mime_cache()`: `mime[$PWD/$fm]="$mm"` — write 20 entries at once.
  7. `etc/viewers/core:26-28,69,71,77` — `ext_viewers`/`pviewers`: `mime_get ; [[ $mtype =~ ^text ]]` etc.

#### `pignore`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g pignore ...`
- **Type:** associative array (extension → 0/1)
- **Default:** empty
- **Purpose:** Per-extension preview-ignore flag. If `pignore["${e@Q}"]=1`, the extension's preview is skipped (falls through to `ptype`). Set by `zep` (toggle current extension) and `preview_image` (toggle all image extensions).
- **Usage sites:**
  1. `etc/core/ftl_setup:7` — declared.
  2. `etc/viewers/core:41` — `pviewers()`: `[[ $e ]] && ((pignore["${e@Q}"])) && { pignore ; return ; }` — skip preview if ignored.
  3. `etc/core/commands:135` — `preview_ext_ign()`: `((pignore[${e}] ^= 1))` — toggle current extension.
  4. `etc/core/commands:136` — `preview_image()`: `for e in $(tr '|' ' ' <<< "$ifilter") ; do pignore[${e}]=$no_image_preview ; done` — bulk toggle images.

#### `lignore`, `lkeep`, `lkeep_tab`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g lignore lkeep lkeep_tab ...`
- **Type:** associative arrays (extension → 1)
- **Defaults:** empty
- **Purpose:** Listing filters by extension. `lignore["${e@Q}"]=1` hides extension `e` globally. `lkeep["${e@Q}"]=1` shows *only* extension `e` globally. `lkeep_tab["${tab}_${e@Q}"]=1` shows only `e` in tab `tab`. `lkeep_tab[$tab]` (without extension) is a flag indicating that tab has a keep-list.
- **Usage sites:**
  1. `etc/core/ftl_setup:7` — declared.
  2. `etc/bin/ftl:93-98` — `prepare_entries()`: 
     - `((lignore[${tab}_${e@Q}] || lignore[${e@Q}])) && continue` — skip if ignored (tab-specific or global).
     - `((${#lkeep_tab[$tab]})) && { ((lkeep_tab[${tab}_${e@Q}])) || continue ; }` — if tab has a keep-list, only matching extensions pass.
     - `((${#lkeep[@]})) && { ((lkeep[${e@Q}])) || continue ; }` — if global keep-list, only matching pass.
     - `((${#lkeep[@]} || ${#lkeep_tab[$tab]})) && continue` — files with no extension are hidden if any keep-list is active.
  3. `etc/core/commands:139-143` — `extension_hide_tab`/`extension_hide`/`extension_only`/`extension_only_tab`/`extension_clear`:
     - `extension_hide_tab`: `((lignore[${tab}_${e@Q}]= 1))`.
     - `extension_hide`: `((lignore[${e@Q}]= 1))`.
     - `extension_only`: `lkeep[${e@Q}]=1`.
     - `extension_only_tab`: `lkeep_tab[${tab}]=1, lkeep_tab[${tab}_${e@Q}]=1`.
     - `extension_clear`: `lignore=() ; lkeep=() ; lkeep_tab=()`.
  4. `etc/core/ftl:121` — `save_state`: `>>${1:-$fs}/ftl declare -p lignore lkeep` — serialize.
  5. `etc/core/ftl:127` — `prev_synch`: `source "$ofs/ftl"` — restore.

#### `tail`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g tail ...`
- **Type:** associative array (file path → vim ex-command string)
- **Default:** empty
- **Purpose:** Per-file "tail" command for vim preview. If `tail[$n]="+$ "`, vim opens at the end of the file; if `"+0 "`, at the top. Toggled by `preview_tail` binding.
- **Usage sites:**
  1. `etc/core/ftl_setup:7` — declared.
  2. `etc/core/ftl:18` — `vipreview()`: `tmux send -t $pane_id ":e ${tail[$1]}$(...)" C-m` — prepend the tail command to `:e`.
  3. `etc/core/ftl:18` — `vipreview()`: `ctsplit "$EDITOR -R ${tail[$1]}${1@Q}"` — prepend to the editor command.
  4. `etc/core/commands:175` — `preview_tail()`: `[[ "${tail[$n]}" == "+$ " ]] && tail[$n]='+0 ' || tail[$n]='+$ '` — toggle.

#### `tags`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g tags ...`
- **Type:** associative array (file path → tag glyph)
- **Default:** empty
- **Purpose:** The selection. Keys are full file paths; values are tag glyphs (`▪` for default class, `¹`/`²`/`³`/`D` for the four classes). Presence in the array means "selected". Serialized to `$fs/tags` (as `declare -p` output) so other panes can source it.
- **Usage sites:** 40+ references. See §7 for the full breakdown.

#### `ntags`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g ntags ...`
- **Type:** associative array (tag-glyph → `1`)
- **Default:** empty
- **Purpose:** Inverted index of `tags` — which tag classes are currently in use. Built by `tag_ntags()`. Used by `tag_class()` to decide whether to prompt the user for a class (if multiple are present) or auto-pick (if one).
- **Usage sites:**
  1. `etc/core/ftl_setup:7` — declared.
  2. `etc/core/ftl:156` — `tag_ntags()`: `ntags=() ; ... ; ntags[${tags[$t]}]=1`.
  3. `etc/core/ftl:152` — `tag_class()`: `((${#ntags[@]}>1)) && { ... tag_fzf ... }` — prompt if multiple classes.

#### `ftl_env`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g ftl_env ...`
- **Type:** associative array (env-var name → value)
- **Default:** empty (populated at runtime)
- **Purpose:** The set of environment variables to pass to child `ftl` processes. `ftl_env()` renders this as `-e key=value` arguments for `tmux split-window`. Populated with `ftl_pfs`, `ftl_fs`, `ftl_info_file`.
- **Usage sites:**
  1. `etc/core/ftl_setup:7` — declared.
  2. `etc/core/ftl:36` — `ftl_env()`: `ftl_env+=([ftl_pfs]=$pfs [ftl_fs]=$fs) ; for i in "${!ftl_env[@]}" ; do echo -n "${1:--e} $i=${ftl_env[$i]} " ; done`.
  3. `etc/bin/ftl:201` — `setup_finfo()`: `ftl_env+=([ftl_info_file]=$ftl_info_file)`.
  4. `etc/core/ftl:175` — `tsplit()`: `tmux sp $(ftl_env) $5 -t $my_pane ...` — pass env to child.

#### `du_size`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g du_size ...`
- **Type:** associative array (`"$PWD/$filename"` → colored-size string)
- **Default:** empty
- **Purpose:** Cache of directory sizes (with ANSI color from `color_size`). Populated once by `dir_dusize()` when `show_size` reaches level 3. Read by `dir_size()` for display.
- **Usage sites:**
  1. `etc/core/ftl_setup:7` — declared.
  2. `etc/core/ftl:31` — `dir_size()`: `printf "\e[94m %4s\e[m" "${du_size[$PWD/$1]}"` — read.
  3. `etc/core/ftl:33` — `dir_dusize()`: `declare -Ag du_size ; while ... ; do du_size[$PWD/$file]="$color$size$reset" ; done`.

### 3.3 The Third `declare -g` Block (lines 9-10)

```
declare -g  dir_entries_list
declare -Ag dir_entries_path dir_entries_file dir_entries_color dir_entries_size dir_entries_relative_path_length
```

These five arrays hold the raw directory-scan output, before `prepare_entries` filters/transforms it into `files`/`files_color`.

#### `dir_entries_list`

- **Declared at:** `etc/core/ftl_setup:9` — `declare -g dir_entries_list`
- **Type:** indexed array (entry-name strings)
- **Default:** empty
- **Purpose:** The list of entry names (basenames) from the scan. Populated by `get_dir_entries` or `get_custom_entries` (the fzf-listen variant). Iterated by `prepare_entries` to build `files`.
- **Usage sites:**
  1. `etc/core/ftl_setup:9` — declared.
  2. `etc/bin/ftl:50` — `get_dir_entries()`: `dir_entries_list=()` (reset), then `dir_entries_list+=("$pnc")`.
  3. `etc/bin/ftl:77` — `prepare_entries()`: `printf -v pad "%d" ${#dir_entries_list[@]}` — compute padding from count.
  4. `etc/bin/ftl:79` — `prepare_entries()`: `for p_index in "${dir_entries_list[@]}" ; do ...` — iterate.
  5. `etc/bindings/fzf_search:79,90,94` — `get_custom_entries()`: `dir_entries_list=()` then `dir_entries_list+=("$dst")`.

#### `dir_entries_path`, `dir_entries_file`, `dir_entries_color`, `dir_entries_size`, `dir_entries_relative_path_length`

- **Declared at:** `etc/core/ftl_setup:10` — `declare -Ag dir_entries_path dir_entries_file dir_entries_color dir_entries_size dir_entries_relative_path_length`
- **Type:** associative arrays (entry-name → value)
- **Defaults:** empty
- **Purpose:** Parallel maps keyed by entry name. `dir_entries_path` = parent directory path, `dir_entries_file` = basename, `dir_entries_color` = ANSI-colored display string, `dir_entries_size` = byte size, `dir_entries_relative_path_length` = length of the relative-path prefix (for nested entries in depth>1 listings).
- **Usage sites:**
  1. `etc/core/ftl_setup:10` — declared.
  2. `etc/bin/ftl:50,62-67` — `get_dir_entries()`: all five are reset and populated in lockstep with `dir_entries_list`.
  3. `etc/bin/ftl:80-86` — `prepare_entries()`: all five are read in the iteration loop:
     - `pc="${dir_entries_color[$p_index]}"`.
     - `pnc="${dir_entries_file[$p_index]}"`.
     - `ppath="${dir_entries_path[$p_index]}"`.
     - `rpath_l=${dir_entries_relative_path_length[$p_index]}`.
     - `size=${dir_entries_size[$p_index]}`.
  4. `etc/bindings/fzf_search:81-86,95-110,116` — `get_custom_entries()`: same pattern — all five populated and read.

### 3.4 The Initialization Line (line 12)

```
selection=() ; n= ; fs=$ftl_root/$$ ; pfs=$fs ; ofs=$fs ; tab=0 ; tabs+=("$PWD") ; ntabs=1 ; tab_setup ;
```

#### `selection`

- **Declared at:** `etc/core/ftl_setup:12` — `selection=()`
- **Type:** indexed array (file paths)
- **Default:** empty
- **Purpose:** The "current selection" — either the tagged files (if any) or just the current file. Recomputed by `selection()` before every operation that needs it (copy, move, delete, etc.).
- **Usage sites:**
  1. `etc/core/ftl_setup:12` — initialized.
  2. `etc/core/ftl:96` — `selection()`: `selection=() ; ((${#tags[@]})) && selection+=("${!tags[@]}") || { ((nfiles)) && selection=("${files[file]}") ; }` — recompute.
  3. `etc/bin/ftl:149` — `list()`: `selection` — called before every render.
  4. `etc/core/ftl:23` — `cp_mv_tags`: `cp_mv "$1" "$2" "${!ltags[@]}"` (uses local, not `selection`).
  5. `etc/core/ftl:25-26` — `cp_do`/`mv_do`: receive `selection` via `"$@"`.
  6. `etc/core/ftl:91` — `cdfl()`: `printf "%s\n" "${selection[@]}" >&3` — write to fd 3 for `ftll`/`cdf` consumers.
  7. `etc/core/ftl:96` — `selection()`: the function.
  8. `etc/core/commands:56` — `copy()`: `cp_mv copy "$REPLY" "${selection[@]}"`.
  9. `etc/core/commands:57` — `copy_clipboard()`: `q_sel | xsel -b -i` where `q_sel` = `printf "%q\n" "${selection[@]}"`.
  10. `etc/core/commands:58` — `add_selection_to_file()`: `q_sel >> "$REPLY"`.
  11. `etc/core/commands:64` — `delete_selection()`: `tag_check && { ... }`.
  12. `etc/core/commands:102-103,105,141,200-202,205-208,218-222,225-226` — many commands use `${selection[@]}`.
  13. `etc/bin/ftl:203` — `setup_finfo()`: `declare -p FTL_PID FTL_FS FTL_PWD n selection >$ftl_info_file` — serialize for external commands.
  14. `etc/bin/finfo:10,22` — reads `selection` from the info file.

#### `n`

- **Declared at:** `etc/core/ftl_setup:12` — `n=`
- **Type:** scalar (file path)
- **Default:** empty
- **Purpose:** The full path of the current entry (under the cursor). Set by `path()` from `files[file]`. Used everywhere as "the current file".
- **Usage sites:** 100+ references across all core files and most plugins. Too many to list exhaustively. Notable:
  1. `etc/core/ftl:72` — `path()`: `n="$1"` — the assignment.
  2. `etc/bin/ftl:147` — `list()`: `((nfiles)) && path "${files[file]}" || path_none`.
  3. `etc/bin/ftl:203` — `setup_finfo()`: `declare -p ... n ...` — serialize.
  4. `etc/core/ftl:29` — `delete_cur()`: `$RM "$n"`.
  5. `etc/core/ftl:50` — `hist_save()`: `echo "$n" | tee -a $fs/history`.
  6. `etc/viewers/core` — every preview function reads `$n` (the file to preview).
  7. `etc/bindings/type_handlers:13` — `enter()`: `mount_archive "$n"`.

#### `fs`, `pfs`, `ofs`, `fsp`

See §4 (next section).

#### `tab`, `tabs`, `ntabs`

See §8.

### 3.5 The Filter Init Line (line 14)

```
filter_rst ; vfiles_rst ; sort_filters=('-k3 -V' '-n' '-k2 -V') ; flips=(' ' ' ')
```

#### `sort_filters`

- **Declared at:** `etc/core/ftl_setup:14` — `sort_filters=('-k3 -V' '-n' '-k2 -V')`
- **Type:** indexed array (sort-option strings)
- **Default:** `('-k3 -V' '-n' '-k2 -V')` — alphanumeric (by name, version-sort), size (numeric), date (by mtime, version-sort)
- **Purpose:** The available sort modes, indexed by `sort_type[tab]`. Each entry is passed as arguments to `sort`.
- **Usage sites:**
  1. `etc/core/ftl_setup:14` — defined.
  2. `etc/core/dir_file_filter:22` — `sort_by()`: `sort $s_reversed ${sort_filters[s_type]}` — the actual sort invocation.
  3. `etc/core/commands:194` — `sort_entries()`: `((sort_type[tab] = sort_type[tab] + 1 >= ${#sort_filters[@]} ? 0 : sort_type[tab] + 1))` — cycle.

#### `flips`

- **Declared at:** `etc/core/ftl_setup:14` — `flips=(' ' ' ')`
- **Type:** indexed array (single-character strings)
- **Default:** `(' ' ' ')` — regular space, em-space (U+2003)
- **Purpose:** Alternating row-separator characters. `list()` toggles `flipi` on every render and substitutes the `¿` marker in the colored entry with `flips[$flipi]`. The subtle visual difference helps the eye track rows.
- **Usage sites:**
  1. `etc/core/ftl_setup:14` — defined.
  2. `etc/bin/ftl:153` — `list()`: `((flipi^=1)) ; flip="${flips[$flipi]}"`.
  3. `etc/bin/ftl:161` — `list()`: `${files_color[i]/¿/$flip}` — substitute the marker.

---

## 4. Per-Pane Filesystem State (`$fs`, `$pfs`, `$fsp`)

These four scalars define the filesystem layout that `ftl` uses for state persistence and inter-pane communication.

### 4.1 The Four Directories

#### `fs`

- **Declared at:** `etc/core/ftl_setup:12` — `fs=$ftl_root/$$` (main pane) — OR `etc/bin/ftl:14` — `fs=$2/$$` (child pane, where `$2` is the parent's `pfs`)
- **Type:** scalar (directory path)
- **Default:** `$ftl_root/$$` (main pane)
- **Purpose:** This pane's private runtime directory. Holds: `history` (session directory history), `tags` (serialized selection), `ftl` (serialized state for preview pane), `log`, `errors_log`, `cmd_log`, `command_names`, `bash_command`, `permissions`, `load_sel`, `BULK`, `cmv_$SECONDS`, `ntags_*`, `lock_preview/`, `mnt/`, `ftl_main_info_*`, `ftl_info_*`. Removed on quit.
- **Usage sites:** 60+ references. Notable:
  1. `etc/core/ftl_setup:12` — main pane: `fs=$ftl_root/$$`.
  2. `etc/bin/ftl:14` — child pane: `fs=$2/$$ ; mkdir -p $fs ; touch $fs/history`.
  3. `etc/bin/ftl:14` — main pane: `mkdir -p $fs/prev ; echo $my_pane >$fs/pane`.
  4. `etc/core/ftl:8` — `try()`: `exec 9>&2 2>"$fs/log"`.
  5. `etc/core/ftl:9,10` — `try_error`: `cat $fs/log`, `tee -a $fs/errors_log`.
  6. `etc/core/ftl:50` — `hist_save()`: `tee -a $fs/history`.
  7. `etc/core/ftl:80` — `quit()`: `rm -rf $fs`.
  8. `etc/core/ftl:103` — `save_state`: `>${1:-$fs}/ftl echo ...`.
  9. `etc/core/ftl:103` — `save_state`: `declare -p tags | sed ... >$fs/tags`.
  10. `etc/core/ftl:156` — `tag_ntags()`: `rm $fs/ntags*`.
  11. `etc/core/ftl:156` — `tag_ntags()`: `echo "$t" | lscolors >>"$fs/ntags_${tags[$t]}"`.
  12. `etc/core/ftl:171` — `tscommand()`: `tmux neww -t ftl$$ -d ... "echo ... >>$fs/cmd_log"` (wait — this is wrong, `$fs` would be the child's; actually the session shell is in `ftl$$` so `$fs` here refers to whichever pane invoked `tscommand`).
  13. `etc/core/commands:19` — `cmd_prompt()`: `rlwrap ... -f$fs/command_names -H $ftl_root/cmd_history -o cat`.
  14. `etc/core/commands:55` — `gcn()`: `>$fs/command_names`.
  15. `etc/core/commands:59` — `create_bulk()`: `B=$fs/BULK`.
  16. `etc/core/commands:64` — `delete_selection()`: prompt.
  17. `etc/core/lib/shell:8` — `load_sel()`: `sel_file=${1:-$fs/load_sel}`.
  18. `etc/core/lib/shell:42,52,55,58` — `shell_command()`: `>$fs/bash_command`, `>>$fs/cmd_log`.
  19. `etc/bin/ftl:19` — `ftl_main_info_file="$(mktemp -p $fs ftl_main_info_XXXXXXX)"`.
  20. `etc/bin/ftl:198` — `setup_finfo()`: `ftl_info_file="$(mktemp -p $fs ftl_info_XXXXXXX)"`.
  21. `etc/viewers/core:42` — `pviewers()`: `[[ -e "$fs/lock_preview/$n" ]] && { plock ; return ; }`.
  22. `etc/bindings/file_diff`, `etc/bindings/via_bash`, etc. — write temp files to `$fs`.

#### `pfs`

- **Declared at:** `etc/core/ftl_setup:12` — `pfs=$fs` (main pane) — OR `etc/bin/ftl:14` — `pfs=$2` (child pane, where `$2` is the parent's `pfs`)
- **Type:** scalar (directory path)
- **Default:** same as `$fs` for main pane; parent's `$fs` for child pane.
- **Purpose:** "Parent fs" — the shared state directory. For the main pane, `pfs == fs`. For a child pane, `pfs` is the main pane's `fs`, so the child can write to `$fsp/panes`, `$fsp/stagsi`, etc.
- **Usage sites:**
  1. `etc/core/ftl_setup:12` — main: `pfs=$fs`.
  2. `etc/bin/ftl:14` — child: `pfs=$2`.
  3. `etc/bin/ftl:15` — `fsp=$pfs/prev` — the shared preview-sync dir.
  4. `etc/core/ftl:66-71` — `pane_extra`/`pane_ftl`/`pane_close`/`pane_next`/`pane_read`/`pane_send`: read/write `$pfs/panes`.
  5. `etc/core/ftl:103` — `save_state`: `echo "$stagsi" >$fsp/stagsi ; echo $fs >$fsp/fs` (writes to `$fsp`, which is `$pfs/prev`).
  6. `etc/core/ftl:127` — `prev_synch`: `read ofs <$fsp/fs`.
  7. `etc/core/ftl:169` — `tag_synch`: `read ostagsi <$fsp/stagsi`.
  8. `etc/bin/ftl:67` — `pane_ftl()`: `printf "%s\n" "${panes[@]}" >$pfs/panes`.
  9. `etc/bin/ftl:191` — `preview()` (child): `echo "$fs" >$fsp/fs ; echo $my_pane >$fsp/pane`.
  10. `etc/bin/ftl_synch_with_shell:3` — `[[ $ftl_pfs ]] && echo $PWD > $ftl_pfs/synch_with_shell`.

#### `ofs`

- **Declared at:** `etc/core/ftl_setup:12` — `ofs=$fs`
- **Type:** scalar (directory path)
- **Default:** `$fs`
- **Purpose:** "Other fs" — the *other* pane's `fs`, used when synchronizing state. Set by `tag_synch` and `prev_synch` to the value read from `$fsp/fs`. Cleared (`ofs=`) after use.
- **Usage sites:**
  1. `etc/core/ftl_setup:12` — `ofs=$fs` (initially self).
  2. `etc/core/ftl:66` — `pane_extra()`: `echo "${ofs:-$fs}" >$fsp/fs` — write either the other pane's fs or our own.
  3. `etc/core/ftl:127` — `prev_synch()`: `read ofs <$fsp/fs ; source "$ofs/ftl"` — read and source the other pane's state.
  4. `etc/core/ftl:129` — `prev_synch()`: `source "$FTL_CFG/filters/$filter_ext" load $ofs` — load filter from other pane's cache.
  5. `etc/core/ftl:133` — `prev_synch()`: `ofs=` — clear.
  6. `etc/core/ftl:169` — `tag_synch()`: `read ofs <$fsp/fs && source $ofs/tags ; ofs=`.
  7. `etc/bin/ftl:191` — `preview()` (child): `save_state ; echo "$fs" >$fsp/fs` — write our fs as the "other" for the main pane.
  8. `etc/core/commands:229` — `SIG_PANE()`: `ofs=` — clear on pane signal.
  9. `etc/viewers/core:108` — `pdir_def()`: `echo "${ofs:-$fs}" >$fsp/fs`.

#### `fsp`

- **Declared at:** `etc/bin/ftl:15` — `fsp=$pfs/prev`
- **Type:** scalar (directory path)
- **Default:** `$pfs/prev`
- **Purpose:** The shared "preview sync" directory. Contains: `panes` (list of child pane ids), `pane` (current main pane id), `fs` (which pane's state is current), `stagsi` (selection counter), `synch_with_shell`, `synched_tags`, `pdh` (debug pane id). This is the IPC hub.
- **Usage sites:**
  1. `etc/bin/ftl:15` — `fsp=$pfs/prev`.
  2. `etc/bin/ftl:14` — main pane: `mkdir -p $fs/prev` (creates `$fsp`).
  3. `etc/core/ftl:66-71` — `pane_*` functions: `$pfs/panes` (note: `panes` is in `$pfs`, not `$fsp` — wait, looking again: `printf "%s\n" "${panes[@]}" >$pfs/panes` in `pane_ftl`, but `pane_read` reads `$pfs/panes` too. So `panes` file is in `$pfs`, not `$fsp`. The `$fsp` directory holds `fs`, `pane`, `stagsi`).
  4. `etc/core/ftl:103` — `save_state`: `echo "$stagsi" >$fsp/stagsi ; echo $fs >$fsp/fs`.
  5. `etc/core/ftl:127,129` — `prev_synch`: `read ofs <$fsp/fs`.
  6. `etc/core/ftl:169` — `tag_synch`: `read ostagsi <$fsp/stagsi`.
  7. `etc/bin/ftl:191` — `preview()` (child): `echo "$fs" >$fsp/fs ; echo $my_pane >$fsp/pane`.
  8. `etc/core/ftl:77` — `pdh_show()`: `[[ -f $pfs/pdh ]] && { read pdh <$pfs/pdh ; ... }` (note: `pdh` file is in `$pfs`, not `$fsp`).
  9. `etc/core/commands:229` — `SIG_PANE()`: `ofs=` (clears, doesn't read `$fsp`).
  10. `etc/core/commands:231` — `SIG_REMOTE()`: `read op <$fsp/pane`.

### 4.2 The `PPWD` Variable

#### `PPWD`

- **Declared at:** `etc/bin/ftl:15` — `PPWD="$dir"`
- **Type:** scalar (directory path)
- **Default:** the initial directory passed to `ftl`
- **Purpose:** "Previous PWD" — the directory we were in before the current one. Used to detect directory changes (in `cview`) and to update the `'` mark and history.
- **Usage sites:**
  1. `etc/bin/ftl:15` — `PPWD="$dir"` (initial).
  2. `etc/bin/ftl:35` — `cview()`: `[[ "$PPWD" != "$PWD" ]] && { hist_save ; marks["'"]="$n" ; PPWD="$PWD" ; }` — on directory change, save history, update `'` mark, update `PPWD`.


---

## 5. Keyboard & Input Globals

**Files:** `etc/core/keyboard` (the main input system), `etc/bin/ftl` (the main loop), plus `etc/bindings/incremental_search` and `etc/bindings/fzf_search`.

### 5.1 The AltGr Mapping Tables

#### `A`, `LA`, `SA`, `LSA`

- **Declared at:** `etc/core/keyboard:2-5`
- **Type:** associative arrays (single character → single character)
- **Defaults:**
  - `A` (AltGr map): `[a]=ª [b]=" [c]=© [d]=ð ...`
  - `LA` (inverse AltGr): `[ª]=a ["]=b ...`
  - `SA` (Shift+AltGr): `[a]=º [b]=’ ...`
  - `LSA` (inverse Shift+AltGr): `[º]=a ...`
- **Purpose:** Map AltGr and Shift+AltGr key combinations to their produced characters (and back). Used by `bind()` to annotate multi-key bindings with their AltGr equivalents in the binding display.
- **Usage sites:**
  1. `etc/core/keyboard:2-5` — declared.
  2. `etc/core/keyboard:20` — `bind()`: `{ [[ -n "${LA[$key]}"  ]] && dscut="$dscut ⇑${LA[$key]}/$key" ; } || { [[ -n "${LSA[$key]}" ]] && dscut="$dscut ⇈${LSA[$key]}/$key" ; } || dscut="$dscut $key"`.
  3. `etc/core/keyboard:35` — `unbind()`: same pattern.
  4. `etc/ftlrc:153,156,158,168,230,232,234,267,281,311,321,325,327,339,341,343,345,362,396-401,411` — used in `bind` calls like `bind ftl entry "${A[t]}" add_selection_to_file "..."` (binds to the AltGr+T character).
  5. `etc/ftlrc_not_so_vim_like:5-8,30,33,107,120-124` — same pattern.

### 5.2 Input State

#### `REPLY`

- **Declared at:** implicitly global; set by `read` in `get_key()`.
- **Type:** scalar (single character, or a normalized token like `UP`/`DOWN`/`ENTER`)
- **Default:** unset
- **Purpose:** The current keystroke. Set by `read -rsn 1` in `get_key`, then normalized by the `case` statement. Read by `key_command` to dispatch.
- **Usage sites:**
  1. `etc/core/keyboard:100` — `get_key()`: `read -rsn 1 -t "$1" || REPLY=ERROR_$?`.
  2. `etc/core/keyboard:100-175` — `get_key()`: the `case` statement normalizes `REPLY` from raw bytes to tokens.
  3. `etc/core/keyboard:61-93` — `key_command()`: reads `REPLY` throughout.
  4. `etc/bin/ftl:21` — main loop: `{ [[ "$R" ]] && { REPLY="${R:0:1}" ; R="${R:1}" ; } || get_key $KEY_TIMEOUT ; } && try key_command ; kbdf ; winch=1 ; REPLY=`.
  5. `etc/core/commands:64` — `delete_selection()`: `prompt ... -n1 && delete "$PT" ; REPLY=` — `prompt` also uses `REPLY`.
  6. `etc/bindings/incremental_search:6-17` — `incremental_find()`: `case "$REPLY" in ...`.
  7. `etc/bindings/fzf_search:30-55` — `fzf_client()`: `case "$REPLY" in ...`.

#### `OREPLY`

- **Declared at:** `etc/core/keyboard:100` — `OREPLY="$REPLY"`
- **Type:** scalar (single character)
- **Default:** unset
- **Purpose:** The raw, pre-normalization keystroke. Kept for debugging (the commented-out `printf` on line 178 would show both `REPLY` and `OREPLY`).
- **Usage sites:**
  1. `etc/core/keyboard:100` — assigned.
  2. `etc/core/keyboard:178-179` — (commented out) debug print.

#### `R`

- **Declared at:** implicitly global; first assigned in `etc/bin/ftl:21` and in various commands via `R=...`.
- **Type:** scalar (string of key tokens)
- **Default:** empty
- **Purpose:** "Pending input queue" — a string of key tokens that the main loop should consume before reading from the user. Set by signal handlers (`R=${C[refresh_pane]}`), by `winch`, by `shell_command` (when a command-name matches a binding), and by commands that want to chain (e.g. `goto_alt1` sets `R="${C[find_next]}"`). The main loop consumes one character per iteration: `REPLY="${R:0:1}" ; R="${R:1}"`.
- **Usage sites:**
  1. `etc/bin/ftl:21` — main loop: `{ [[ "$R" ]] && { REPLY="${R:0:1}" ; R="${R:1}" ; } || get_key $KEY_TIMEOUT ; }`.
  2. `etc/core/commands:34` — `goto_alt1()`: `R="${C[find_next]}"`.
  3. `etc/core/commands:78` — `find_entry()`: `R="${C[find_next]}"`.
  4. `etc/core/commands:129` — `pane_go_next()`: `tmux send -t $p ${C[refresh_pane]}` (sends to another pane, which sets its own `R`).
  5. `etc/core/commands:177` — `quit_all()`: `pane_send "${C[quit_ftl]}"` (sends to all panes).
  6. `etc/core/commands:181` — `SIG_PANE()`: `R=${C[refresh_pane]}`.
  7. `etc/core/commands:185` — `shell_files()`: `R=${C[shell_file]}`.
  8. `etc/core/ftl:52` — `inotify_()`: `tmux send -t "$my_pane" ${C[refresh_pane]}`.
  9. `etc/core/ftl:180` — `winch()`: `R="${C[refresh_pane]}$R"` (prepend refresh to the queue).
  10. `etc/core/lib/shell:24-25` — `shell_command()`: `R=${kbd_trie[$1]}` / `R=${C[$1]}`.

#### `E1`, `E2`, `E3`, `E4`

- **Declared at:** `etc/core/keyboard:102` — `read -rsn 4 -t 0.001 E1 E2 E3 E4`
- **Type:** scalars (single characters)
- **Default:** empty
- **Purpose:** The up-to-4 bytes following the initial keystroke, used to complete escape sequences. Read with a 1ms timeout so they're only captured if they arrive immediately (as part of an escape sequence).
- **Usage sites:**
  1. `etc/core/keyboard:102` — assigned.
  2. `etc/core/keyboard:104` — `case "$REPLY$E1$E2$E3$E4" in ...` — used in the normalization case statement.

### 5.3 Trie Dispatch State

#### `keys_command`, `keys_in`, `HAS_COUNT`, `COUNT`

- **Declared at:** implicitly global; first assigned in `key_command()`.
- **Types:** `keys_command` scalar (accumulated key tokens), `keys_in` integer (count of tokens accumulated), `HAS_COUNT` scalar (either empty or `COUNT`), `COUNT` scalar (digit string).
- **Defaults:** all empty/zero
- **Purpose:** The multi-key input accumulator. `keys_command` accumulates tokens until the trie has a match or the sequence is too long. `COUNT` accumulates leading digits. `HAS_COUNT` is set to `COUNT` once a non-digit arrives, so the trie lookup can include the count prefix.
- **Usage sites:**
  1. `etc/core/keyboard:61` — `key_command()`: `(( keys_in > 3 )) && { keys_in= keys_command= HAS_COUNT= COUNT= ; return ; }` — overflow guard.
  2. `etc/core/keyboard:62` — `key_command()`: `[[ "$REPLY" == ERROR_142 ]] && { keys_in= keys_command= HAS_COUNT= COUNT= ; return ; }` — timeout reset.
  3. `etc/core/keyboard:67` — `key_command()`: `[[ "$REPLY" == ESCAPE ]] && { keys_in= keys_command= HAS_COUNT= COUNT= ; return ; }` — interrupt.
  4. `etc/core/keyboard:69` — `key_command()`: count accumulation: `[[ -z "$keys_command" || "$keys_command" =~ ^[0-9]$ ]] && [[ "$REPLY" =~ ^[0-9]$ ]] && { [[ "$COUNT$REPLY" != 0 ]] && { HAS_COUNT=COUNT ; COUNT="$COUNT$REPLY" ; } ; return ; }`.
  5. `etc/core/keyboard:71` — `key_command()`: `keys_command="$keys_command$REPLY" ; (( keys_in++))`.
  6. `etc/core/keyboard:77,81` — trie lookup: `${kbd_trie[$HAS_COUNT$keys_command]}`.
  7. `etc/core/keyboard:86,92` — reset after dispatch: `keys_in= keys_command= HAS_COUNT= COUNT= REPLY=`.
  8. `etc/core/commands:46` — `selection_class_c()`: `for ((i=0 ; i < ${COUNT:-1} ...))` — reads `COUNT` for count-aware commands.
  9. `etc/core/commands:218-219` — `selection_flip_down`/`up`: `for ((i=file ; i < file + ${COUNT:-1} ...))`.
  10. `etc/core/commands:199` — `tab_goto()`: `((ntab = $COUNT - 1))`.
  11. `etc/core/commands:33` — `move_percent()`: `$(($nfiles * $COUNT / 100))`.

#### `keys_function`, `keys_latest_command`

- **Declared at:** implicitly global; assigned in `key_command()`.
- **Types:** scalars (function names)
- **Defaults:** empty
- **Purpose:** `keys_function` is the function about to be called (set just before invocation, for debugging). `keys_latest_command` is the last non-movement command, used by the redo key (`.`).
- **Usage sites:**
  1. `etc/core/keyboard:81` — `keys_function=${kbd_trie[$HAS_COUNT$keys_command]}`.
  2. `etc/core/keyboard:82` — `$keys_function` — invoke.
  3. `etc/core/keyboard:84` — `[[ "${exclude_from_redo[$keys_function]}" ]] || keys_latest_command="$keys_function"` — record for redo (unless excluded).
  4. `etc/core/keyboard:89-91` — redo: `[[ "$HAS_COUNT$keys_command" == "$redo_key" && "$keys_latest_command" ]] && { $keys_latest_command ; ... }`.

#### `exclude_from_redo`

- **Declared at:** `etc/core/keyboard:45` — `reset_exclude_command_from_redo() { declare -g -A exclude_from_redo=() ; }` (called on line 48)
- **Type:** associative array (function name → `1`)
- **Default:** populated with the eight movement functions (lines 50-57)
- **Purpose:** Set of functions that should NOT be recorded as `keys_latest_command` (so `.` doesn't repeat them). Movement commands are excluded because repeating `j` with `.` would be confusing.
- **Usage sites:**
  1. `etc/core/keyboard:45` — `reset_exclude_command_from_redo()`: declares and clears.
  2. `etc/core/keyboard:48` — called at module load.
  3. `etc/core/keyboard:50-57` — `exclude_command_from_redo "move_up"`, `"move_up_arrow"`, `"move_down"`, `"move_down_arrow"`, `"move_left"`, `"move_left_arrow"`, `"move_right"`, `"move_right_arrow"`.
  4. `etc/core/keyboard:46` — `exclude_command_from_redo()`: `exclude_from_redo[$1]=1`.
  5. `etc/core/keyboard:84` — `key_command()`: `[[ "${exclude_from_redo[$keys_function]}" ]] || keys_latest_command="$keys_function"`.

#### `ftl_bind_check`

- **Declared at:** not explicitly declared; used as a flag (0/1).
- **Type:** scalar (integer, treated as boolean)
- **Default:** `0` (unset)
- **Purpose:** When non-zero, `bind()` warns on STDERR about overriding existing bindings. Set to `1` in your `ftlrc` to audit your binding changes.
- **Usage sites:**
  1. `etc/core/keyboard:16` — `bind()`: `((ftl_bind_check)) && [[ "${kbd_trie[$shortcut]}" =~ [[:alpha:]] ]] && echo "ftl: bind: ... is overriding '${kbd_trie[$shortcut]}'"`.
  2. `etc/core/keyboard:23` — `bind()`: `((ftl_bind_check && ${kbd_trie[$shortcut]} > 1)) && echo "ftl: bind: ... is overriding command path"`.

---

## 6. Listing & Rendering Globals

**Files:** `etc/bin/ftl` (the listing engine), `etc/core/ftl` (helpers like `header`, `clear_list`).

### 6.1 The Listing Arrays

#### `files`, `files_color`, `nfiles`, `file`

- **Declared at:** `etc/bin/ftl:75` — `files=() ; nfiles=0 ; files_color=() ; line=0 ; sum=0 ; first_file= ; found=`
- **Types:** `files` indexed array (full paths), `files_color` indexed array (ANSI-colored display strings), `nfiles` scalar integer, `file` scalar integer (current index).
- **Defaults:** `files=()`, `files_color=()`, `nfiles=0`, `file` is set by `list()` from `dir_file`.
- **Purpose:** `files` and `files_color` are the filtered, sorted, colorized entries ready for display. `nfiles` is the count. `file` is the index of the current entry (under the cursor).
- **Usage sites:** 100+ references. Notable:
  1. `etc/bin/ftl:75` — `prepare_entries()`: reset and populate.
  2. `etc/bin/ftl:125` — `prepare_entries()`: `files[$nfiles]="$ppath$sep$pnc"`.
  3. `etc/bin/ftl:145-147` — `list()`: `file=${dir_file[${tab}_$PWD]:-0} ; ((file = file > nfiles - 1 ? nfiles - 1 : file)) ; ((nfiles)) && path "${files[file]}"`.
  4. `etc/bin/ftl:159-161` — `list()`: `for((i=$top, tline=2 ; i <= bottom ; i++, tline++)) ; do ... echo -ne "\e[${tline};0H\e[m\e[K$cursor${files_color[i]/¿/$flip}\e[0m" ; done`.
  5. `etc/core/ftl:64` — `move()`: `((nf = file + $1, ...)) ; ((nf != file)) && dir_file[${tab}_$PWD]=$nf`.
  6. `etc/core/ftl:96` — `selection()`: `((nfiles)) && selection=("${files[file]}")`.
  7. `etc/core/ftl:136-138` — `q_files`/`q_dirs`/`q_all`: `printf "%q\n" "${files[@]}"`.
  8. `etc/core/ftl:62` — `mime_cache()`: `"${files[@]:$file:((file + 20))}"` — batch 20 entries starting at current.
  9. `etc/core/commands:16-20` — `move_down`/`up`/`right`: read `nfiles`, check `-d "${files[file]}"`.
  10. `etc/core/commands:79-80` — `find_next`/`find_previous`: iterate `files[]`.
  11. `etc/core/commands:200-202` — `select_all*`: iterate `files[]`.
  12. `etc/bindings/tmsu:7` — `tmsu_preview()`: `"${files[@]:$top:$lines}"` — slice for visible entries.

#### `line`, `sum`, `pad`, `first_file`, `found`

- **Declared at:** `etc/bin/ftl:75` — `line=0 ; sum=0 ; first_file= ; found=`
- **Types:** `line` integer (1-based entry counter for display), `sum` integer (total bytes), `pad` integer (width of the index column), `first_file` integer (index of first file entry), `found` integer (index where search target was found).
- **Defaults:** see above
- **Purpose:** Temporary values used during `prepare_entries`. `line` is the 1-based display index. `sum` accumulates total size for the header. `pad` is the number of digits in `nfiles`, used to right-pad the index column. `first_file` is the index of the first non-directory entry (for `goto_first_file`). `found` is the index where the search target was found.
- **Usage sites:**
  1. `etc/bin/ftl:75` — reset in `prepare_entries`.
  2. `etc/bin/ftl:77` — `prepare_entries()`: `printf -v pad "%d" ${#dir_entries_list[@]} ; pad=${#pad}` — compute padding.
  3. `etc/bin/ftl:85` — `prepare_entries()`: `((sum += size))`.
  4. `etc/bin/ftl:114` — `prepare_entries()`: `((line++)) ; printf -v pc "$line_color%${pad}d\e[m¿..." $line`.
  5. `etc/bin/ftl:127` — `prepare_entries()`: `[[ -z $first_file ]] && [[ -f "$pnc" ]] && first_file=$nfiles`.
  6. `etc/bin/ftl:128` — `prepare_entries()`: `[[ -n "$search" && -z "$found" ]] && [[ "${pnc:0:${#search}}" == "$search" ]] && found=$nfiles`.
  7. `etc/bin/ftl:133` — `prepare_entries()`: `hsum=$(numfmt --to=iec --format ' %4f' "$sum")`.
  8. `etc/core/commands:29` — `goto_first_file()`: `dir_file[$twd]=$first_file`.

### 6.2 Window Geometry

#### `top`, `bottom`, `center`, `lines`

- **Declared at:** implicitly global; computed in `view_list` and `list`.
- **Types:** integers
- **Defaults:** computed per render
- **Purpose:** `top` is the index of the first visible entry, `bottom` is the last visible entry, `center` is the midpoint, `lines` is the number of visible lines (capped at `LINES - 1` to leave room for the header).
- **Usage sites:**
  1. `etc/bin/ftl:138` — `view_list()`: `((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2))`.
  2. `etc/bin/ftl:151` — `list()`: `((top = nfiles < lines || file <= center ? 0 : file >= nfiles - center ? nfiles - lines : file - center, bottom = top + lines - 1, bottom = bottom < 0 ? 0 : bottom))`.
  3. `etc/bin/ftl:159` — `list()`: `for((i=$top, tline=2 ; i <= bottom ; i++, tline++))`.
  4. `etc/core/ftl:32` — `dir_esize()`: (uses `find ... -printf "1\n" | wc -l`).
  5. `etc/bindings/tmsu:7,10` — `tmsu_preview()`: `for((i=top ; i <= bottom ; i++))` — iterate visible entries for tag table.

#### `LINES`, `COLS`, `WCOLS`, `WLINES`, `TOP`, `WIDTH`, `LEFT`

- **Declared at:** implicitly global; set by `geometry()`.
- **Types:** integers
- **Defaults:** from `tmux display -p '#{pane_height}'` etc.
- **Purpose:** Pane geometry. `LINES`/`COLS` are current; `W`-prefixed are "watched" (last seen) for change detection. `TOP`/`WIDTH`/`LEFT` are the pane's position in the tmux window.
- **Usage sites:**
  1. `etc/core/ftl:45` — `geometry()`: `read -r TOP WIDTH LINES COLS LEFT< <(tmux display -p -t $my_pane '#{pane_top} #{window_width} #{pane_height} #{pane_width} #{pane_left}')`.
  2. `etc/core/ftl:47` — `geo_winch()`: `WCOLS=$COLS ; WLINES=$LINES`.
  3. `etc/core/ftl:180` — `winch()`: `{ ((!in_ftli)) && [[ "$WCOLS" != "$COLS" ]] || [[ "$WLINES" != "$LINES" ]] ; } && ((winch)) && R="${C[refresh_pane]}$R"`.
  4. `etc/bin/ftl:138` — `view_list()`: `((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, ...))`.
  5. `etc/bin/ftl:20` — `clear_list()`: `for(( i=$1 ; i <= LINES ; i++))`.
  6. `etc/core/commands:25-26` — `move_page_up`/`down`: `move -$LINES` / `move $LINES`.

#### `COLS_P`, `x`

- **Declared at:** implicitly global; set in `zoom()`.
- **Types:** integers
- **Defaults:** computed
- **Purpose:** `COLS_P` is the width of the preview pane (if any). `x` is the computed resize target for the preview pane.
- **Usage sites:**
  1. `etc/core/ftl:181` — `zoom()`: `[[ $pane_id ]] && read -r COLS_P < <(tmux display -p -t $pane_id '#{pane_width}') || COLS_P=0`.
  2. `etc/core/ftl:181` — `zoom()`: `((x = ( ($COLS + $COLS_P) * ${zooms[$zoom]} ) / 100))`.
  3. `etc/core/commands:174` — `preview_size()`: `[[ $pane_id ]] && tmux resizep -t $pane_id -x $x &>/dev/null ; rdir '' 0`.

### 6.3 Rendering State

#### `head`, `hsum`, `nfiles_h`, `stat`, `date`, `search_h`, `tabsd`, `tsc`, `h`, `hal`, `hpl`

- **Declared at:** implicitly global; computed in `show_header` and `header`.
- **Types:** scalars (strings or integers)
- **Defaults:** computed per render
- **Purpose:** Pieces of the header line. `head` is the mode-glyph prefix. `hsum` is the total-size suffix. `nfiles_h` is the total-match-count from fzf-listen mode. `stat` is the current entry's stat string. `date` is the current entry's date. `search_h` is the search indicator. `tabsd` is the tab indicator. `tsc` is the tmux session command count (background windows). `h` is the assembled header. `hal`/`hpl` are the trimmed lengths for fit.
- **Usage sites:**
  1. `etc/bin/ftl:176` — `show_header()`: `head="${lglyph[lmode[tab]]}${iglyph[vmode[tab]]}${pdir_only[tab]}${montage}" ; head=${head:+$head }`.
  2. `etc/bin/ftl:178` — `show_header()`: `[[ "$to_search" ]] && search_h="S:$to_search " || search_h=`.
  3. `etc/bin/ftl:180` — `show_header()`: `((ntabs>1)) && tabsd=' ᵗ'$((tab+1)) || tabsd=`.
  4. `etc/bin/ftl:182-183` — `show_header()`: `stat="$(stat -c ' %A %U' ...)"` / `date=$(find ... -printf ' %Tx-%TH:%TM')`.
  5. `etc/bin/ftl:185` — `show_header()`: `header '' "$head$ftag$(printf "%${pad}d" $((file+1)))/${nfiles_h:-$nfiles}$hsum$stat$date$tabsd$search_h"`.
  6. `etc/core/ftl:48` — `header()`: `h="${@:2} $(sort_glyph)$s_reversed$(tags_head)" ; header_pos "$h$tsc" ; echo -e "\e[H\e[K\e[${1:-94}m${PWD:hpl} \e[${1:-95}m${h:hal}\e[m \e[4;33m$tsc\e[0m"`.
  7. `etc/core/ftl:49` — `header_pos()`: `hal=$((${#1} - ($cols - 1))) ; hpl=$((${#PWD} + (hal < 0 ? hal : 0) ))`.
  8. `etc/core/ftl:174` — `tsc()`: `w=$(tmux lsw -t ftl$$ 2>&- | wc -l) ; ((w-=1)) ; (( w > 0 )) && { ... ; echo $w ; }`.

#### `flipi`, `flip`, `qd`

- **Declared at:** `flips` at `etc/core/ftl_setup:14`; `flipi`/`flip` at `etc/bin/ftl:153`; `qd` at `etc/bin/ftl:69`.
- **Types:** `flipi` integer (0/1 toggle), `flip` scalar (single char), `qd` integer (0/1 quick-display flag)
- **Defaults:** `flipi` toggles, `flip` from `flips[$flipi]`, `qd=0`
- **Purpose:** `flipi`/`flip` implement the alternating-row visual. `qd` is set to `1` when quick-display mode is active (during scanning of large directories), which skips the preview.
- **Usage sites:**
  1. `etc/bin/ftl:69` — `get_dir_entries()`: `((quick_display && ...)) && { ... ; qd=1 ; }`.
  2. `etc/bin/ftl:101` — `prepare_entries()`: same check, sets `qd=1`.
  3. `etc/bin/ftl:133` — `prepare_entries()`: `qd=0` (reset after prepare).
  4. `etc/bin/ftl:138` — `view_list()`: `((qd)) || refresh` — skip refresh if quick-display.
  5. `etc/bin/ftl:148` — `list()`: `((gpreview)) || save_state $fsi`.
  6. `etc/bin/ftl:153` — `list()`: `((flipi^=1)) ; flip="${flips[$flipi]}"`.
  7. `etc/bin/ftl:161` — `list()`: `${files_color[i]/¿/$flip}`.
  8. `etc/bin/ftl:166` — `list()`: `((qd || gpreview)) || { preview ; geo_winch ; }`.

#### `sep`

- **Declared at:** `etc/bin/ftl:36` — `[[ "$PWD" == / ]] && sep= || sep=/`
- **Type:** scalar (string, either empty or `/`)
- **Default:** `/` (or empty at root)
- **Purpose:** Path separator used when joining `ppath` and `pnc` in `prepare_entries`. Empty at `/` to avoid `//`.
- **Usage sites:**
  1. `etc/bin/ftl:36` — assigned in `cview`.
  2. `etc/bin/ftl:125` — `prepare_entries()`: `files[$nfiles]="$ppath$sep$pnc"`.

### 6.4 Path Parsing Globals

#### `n`, `p`, `f`, `b`, `e`, `mtype`

- **Declared at:** `etc/core/ftl:72` — `path()`: `n="$1" ; [[ "$n" =~ / ]] && p="${n%/*}" || p= ; ... ; f="${n##*/}" ; b="${f%.*}" ; [[ "$f" =~ '.' ]] && e="${f##*.}" || e=`
- **Types:** scalars (strings)
- **Defaults:** set by `path()` from a full path
- **Purpose:** Decomposed current entry. `n` = full path, `p` = parent directory, `f` = basename, `b` = basename without extension, `e` = extension (without dot), `mtype` = mime type (set by `mime_get`).
- **Usage sites:** 200+ references across the entire codebase. These are the most-used variables in `ftl`. Every command and every previewer reads `$n`, `$f`, `$e`, etc.
- **Notable:**
  - `etc/core/ftl:72` — `path()`: the assignment function.
  - `etc/core/ftl:74` — `path_none()`: `n= ; p= ; f= ; b= ; e=` — clear all.
  - `etc/bin/ftl:147` — `list()`: `((nfiles)) && path "${files[file]}" || path_none`.
  - `etc/bin/ftl:10` — `ftl()` entrypoint: `path "$1"` to parse the initial argument.
  - `etc/viewers/core` — every `p*`/`ext_*` function reads `$n`, `$e`, `$f`.
  - `etc/core/commands` — every file-operation command reads `$n`, `$f`, `$e`.
  - `etc/core/ftl:61` — `mime_get()`: `mtype="${mime[$n]}"`.
  - `etc/bin/ftl:203` — `setup_finfo()`: `declare -p ... n ...` — serialize `$n` for external commands.

#### `is_bin`

- **Declared at:** `etc/core/ftl:55` — `is_bin()`: `is_bin=$?`
- **Type:** scalar (integer 0/1)
- **Default:** set by `is_bin()` function
- **Purpose:** 1 if the current file is binary (via Perl's `-B` test), 0 if text. Used by `pviewers` to decide between `ptext` and `ptype`.
- **Usage sites:**
  1. `etc/core/ftl:55` — `is_bin()`: `perl -le 'exit -B $ARGV[0]' "$1" ; is_bin=$?`.
  2. `etc/viewers/core:69` — `pviewers()`: `is_bin "$n" ; file_b="$(file -b "$n")"`.
  3. `etc/viewers/core:77` — `pviewers()`: `((! is_bin)) && [[ -s "$n" ]] && [[ "$file_b" =~ Unicode|ASCII || $mtype =~ ^text ]] && { ptext && return ; }`.

#### `file_b`

- **Declared at:** `etc/viewers/core:69` — `file_b="$(file -b "$n")"`
- **Type:** scalar (string)
- **Default:** output of `file -b`
- **Purpose:** The `file` command's description of the current entry. Used to detect "escape sequence" (ANSI) text files and to distinguish text from binary.
- **Usage sites:**
  1. `etc/viewers/core:69` — assigned.
  2. `etc/viewers/core:73` — `[[ -s "$n" ]] && [[ "$file_b" =~ "escape sequence" ]] && { pansi ; return ; }`.
  3. `etc/viewers/core:77` — `((! is_bin)) && [[ -s "$n" ]] && [[ "$file_b" =~ Unicode|ASCII || $mtype =~ ^text ]] && { ptext && return ; }`.

---

## 7. Selection / Tag State

**Files:** `etc/core/ftl` (tag manipulation), `etc/core/commands` (selection commands), `etc/bindings/tmsu` (TMSU integration).

### 7.1 The Selection Itself

#### `tags`

- **Declared at:** `etc/core/ftl_setup:7` — `declare -A -g tags ...`
- **Type:** associative array (full file path → tag glyph)
- **Default:** empty
- **Purpose:** The selection. Presence of a path as a key means "selected". The value is the tag glyph (`▪` for default, `¹`/`²`/`³`/`D` for classes 1-4). Serialized to `$fs/tags` via `declare -p tags` so other panes can source it.
- **Usage sites:** 50+ references. Exhaustive list:
  1. `etc/core/ftl_setup:7` — declared.
  2. `etc/core/ftl:29` — `delete_cur()`: `[[ "${tags[$n]}" ]] && { unset -v 'tags[$n]' ; tags_size - "$n" ; ((stagsi++)) ; }`.
  3. `etc/core/ftl:43` — `tag_go()`: `for tag_path in "${!tags[@]}" ; do ...`.
  4. `etc/core/ftl:96` — `selection()`: `selection=() ; ((${#tags[@]})) && selection+=("${!tags[@]}") || { ... }`.
  5. `etc/core/ftl:103` — `save_state`: `declare -p tags | sed 's/\-A/-A -g/' >$fs/tags`.
  6. `etc/core/ftl:151` — `tag_check()`: `for tag in "${!tags[@]}" ; do [[ -e "$tag" ]] || unset -v 'tags[$tag]' ; done ; ((${#tags[@]} != 0))`.
  7. `etc/core/ftl:152` — `tag_class()`: `tag_ntags ; ((${#ntags[@]}>1)) && { ... } || echo "${tags[$t]}"`.
  8. `etc/core/ftl:155` — `tags_clear()`: `tags=()`.
  9. `etc/core/ftl:156` — `tag_ntags()`: `for t in "${!tags[@]}" ; do ... ; ntags[${tags[$t]}]=1 ; done`.
  10. `etc/core/ftl:157` — `tag_flip()`: `[[ "${tags[$1]}" ]] && { unset ; ... } || { tags[$1]=${2:-▪} ; ... }`.
  11. `etc/core/ftl:158` — `tag_set()`: `tags[$1]=${2:-▪}`.
  12. `etc/core/ftl:159` — `tag_unset()`: `unset -v 'tags[$1]'`.
  13. `etc/core/ftl:160` — `tags_unset()`: iterate by value.
  14. `etc/core/ftl:161` — `tag_get()`: `for t in "${!tags[@]}" ; do [[ $rclass == ${tags[$t]} ]] && rtags[$t]=1 ; done`.
  15. `etc/core/ftl:168` — `tags_head()`: `((${#tags[@]})) && { echo -n " ${#tags[@]}/" ; ... }`.
  16. `etc/core/ftl:169` — `tag_synch()`: `source $ofs/tags`.
  17. `etc/bin/ftl:160` — `list()`: `cursor=${tags[${files[$i]}]:- }`.
  18. `etc/core/commands:3-4` — `goto_next_tag`/`goto_prev_tag`: `${#tags[@]}`.
  19. `etc/core/commands:46-47` — `selection_class_c`/`n`: read and set `tags[${files[file]}]`.
  20. `etc/core/commands:64` — `delete_selection()`: `tag_check && { ... }`.
  21. `etc/core/commands:102-103` — `image_select*`: `tags[$i]='▪'`.
  22. `etc/core/commands:105` — `link()`: `tag_check && prompt "Link (${#tags[@]})?..."`.
  23. `etc/core/commands:200-202` — `select_all*`: `tags["$p"]='▪'`.
  24. `etc/core/commands:222` — `selection_goto()`: `printf "%s\n" "${!tags[@]}"`.
  25. `etc/core/commands:225` — `selection_untag_all()`: `tags_clear`.
  26. `etc/core/commands:226` — `selection_untag_fzf()`: `printf "%s\n" "${!tags[@]}"`.
  27. `etc/core/lib/merge/all:9` — `tags[$p]="${new_tags[$p]}"`.
  28. `etc/core/lib/merge/pick:9` — same.
  29. `etc/core/lib/merge/synch:6` — same.
  30. `etc/filters/by_only_tagged:6` — `[[ "${tags[$PWD/${file_data[2]}]}" ]]`.
  31. `etc/bindings/lib/compress:50` — `tags=()`.
  32. `etc/bindings/shred:10` — `tags_clear`.
  33. `etc/bindings/tmsu:16` — (local `file_tags` derived from TMSU, not the `tags` global).

#### `stagsi`, `ostagsi`

- **Declared at:** `stagsi` is implicitly global (incremented in many places); `ostagsi` is set in `tag_synch` and `sel_read`.
- **Types:** integers
- **Defaults:** `stagsi=0` (starts at 0); `ostagsi` read from `$fsp/stagsi`
- **Purpose:** "Selection tags index" — a monotonic counter that bumps on every selection change. Used for cross-pane synchronization: when pane A's `stagsi` exceeds pane B's `ostagsi` (the "other" value B last saw), B knows it should source A's serialized `tags`. This avoids polling on every loop iteration — only synchronize when the counter has advanced.
- **Usage sites:**
  1. `etc/core/ftl:29,155-160` — every `tag_*` function does `((stagsi++))`.
  2. `etc/core/ftl:103` — `save_state`: `echo "$stagsi" >$fsp/stagsi`.
  3. `etc/core/ftl:166` — `sel_read()`: `ostagsi=$stagsi` — after reading selection from a file, sync the counters.
  4. `etc/core/ftl:169` — `tag_synch()`: `read ostagsi <$fsp/stagsi ; ((auto_selection && ostagsi > stagsi)) && stagsi=$ostagsi && ... source $ofs/tags`.
  5. `etc/core/commands:46` — `selection_class_c()`: `((stagsi++))`.

#### `ctag`

- **Declared at:** implicitly global; used in `goto_next_tag`/`goto_prev_tag`.
- **Type:** scalar (integer)
- **Default:** unset
- **Purpose:** "Current tag index" — the position within the `tags` array for next/prev tag navigation.
- **Usage sites:**
  1. `etc/core/commands:3` — `goto_next_tag()`: `[[ -z $ctag ]] && ctag=0 || ((ctag++)) ; (( ctag >= ${#tags[@]} )) && ctag=0 ; tag_go $ctag`.
  2. `etc/core/commands:4` — `goto_prev_tag()`: `[[ -z $ctag ]] && ctag=0 || ((ctag--)) ; (( ctag < 0 )) && ctag=$((${#tags[@]} - 1)) ; tag_go $ctag`.

### 7.2 Selection Helpers

#### `PC`, `PT`

- **Declared at:** implicitly global; set in `delete_selection()`.
- **Types:** scalars (strings)
- **Defaults:** empty
- **Purpose:** `PC` is the prompt-choice suffix (`|c` if tags exist, else empty) for the delete confirmation. `PT` is the prompt-text prefix (`*tags* ` if tags exist, else empty).
- **Usage sites:**
  1. `etc/core/commands:64` — `delete_selection()`: `PC= PT= ; tag_check && { PC="|c" ; PT="*tags* " ; } ; prompt "delete $PT[y|d|N$PC] ? " -n1 && delete "$PT" ; REPLY=`.
  2. `etc/core/ftl:28` — `delete()`: `[[ $1 ]] && { [[ $REPLY =~ y|d ]] && delete_tag || { [[ $REPLY =~ c ]] && delete_cur ; } ; } || { [[ $REPLY =~ y|d ]] && delete_cur ; }`.

---

## 8. Tab State

**Files:** `etc/core/ftl` (`tab_setup`, `_tab_new`, `_tab_next`, `_tab_prev`, `tab_read`), `etc/core/commands` (tab commands), `etc/core/ftl_setup:12` (initialization).

### 8.1 The Tab Scalars

#### `tab`, `tabs`, `ntabs`

- **Declared at:** `etc/core/ftl_setup:12` — `tab=0 ; tabs+=("$PWD") ; ntabs=1`
- **Types:** `tab` scalar integer (current tab index), `tabs` indexed array (directory paths), `ntabs` scalar integer (tab count)
- **Defaults:** `tab=0`, `tabs=("$PWD")`, `ntabs=1`
- **Purpose:** `tab` is the index of the current tab. `tabs` holds the directory path for each tab (empty string for closed tabs — indices are not reused). `ntabs` is the count of open tabs.
- **Usage sites:**
  1. `etc/core/ftl_setup:12` — initialized.
  2. `etc/core/ftl:140` — `tab_close()`: `tabs[$tab]= ; ((ntabs--))`.
  3. `etc/core/ftl:141` — `_tab_new()`: `tabs+=("$dir") && ((tab=${#tabs[@]} - 1, ntabs++))`.
  4. `etc/core/ftl:142-143` — `_tab_next`/`_tab_prev()`: iterate `${!tabs[@]}` skipping empty.
  5. `etc/core/ftl:146` — `tab_read()`: `tabs=() ; ntabs=0 ; while read ... ; do _tab_read ... ; done`.
  6. `etc/bin/ftl:36` — `cview()`: `tabs[$tab]="$PWD"`.
  7. `etc/core/commands:140` — `tab_close()`: `(($ntabs > 1))`.
  8. `etc/core/commands:196-199` — `tab_new`/`next`/`prev`/`goto`: read/write `tab`, `tabs`, `ntabs`.
  9. `etc/bin/ftl:180` — `show_header()`: `((ntabs>1)) && tabsd=' ᵗ'$((tab+1))`.
  10. `etc/bindings/to_other_tab:29-31` — `other_tab_dir`/`pick_tab_dir`/`pick_other_tab_dir`: read `tabs`.

### 8.2 Per-Tab Associative Arrays

These arrays are keyed by `${tab}` (or `${tab}_${...}`) so each tab has its own value.

#### `lmode` (listing mode: all/dir-only/file-only)

- **Type:** associative array (`tab` → 0/1/2)
- **Default:** `0` (set by `tab_setup`)
- **Purpose:** 0 = show all, 1 = dir-only, 2 = file-only. Cycled by `zmd` (`file_dir_mode`).
- **Usage sites:**
  1. `etc/core/ftl:150` — `tab_setup()`: `lmode[tab]=0`.
  2. `etc/core/commands:70` — `file_dir_mode()`: `((lmode[tab]++)) ; ((lmode[tab] > 2)) && lmode[tab]=0`.
  3. `etc/core/dir_file_filter:28,30,35,37` — `as_dir`/`dir`: `((lmode[tab]<2)) && { ... dirs ... }` / `((lmode[tab]!=1)) && { ... files ... }`.
  4. `etc/bin/ftl:176` — `show_header()`: `${lglyph[lmode[tab]]}`.
  5. `etc/core/ftl:116` — `save_state`: `lmode[tab]=\"${lmode[tab]}\"`.

#### `vmode` (view mode: all/no-image/image-only)

- **Type:** associative array (`tab` → 0/1/2)
- **Default:** `0`
- **Purpose:** 0 = all, 1 = no-image, 2 = image-only. Controls `tfilters`/`ntfilter` to filter by `ifilter`.
- **Usage sites:**
  1. `etc/core/ftl:150` — `tab_setup()`: `vmode[tab]=0`.
  2. `etc/core/commands:209-213` — `view_mode_all`/`image`/`not_image`/`next`/`view_mode`.
  3. `etc/bin/ftl:176` — `show_header()`: `${iglyph[vmode[tab]]}`.
  4. `etc/core/ftl:112,132` — `save_state`/`prev_synch`.

#### `depth` (listing depth)

- **Type:** associative array (`tab` → integer)
- **Default:** `1`
- **Purpose:** Max depth for `find`. 1 = current dir only. Set by `z*` binding.
- **Usage sites:**
  1. `etc/core/ftl:150` — `tab_setup()`: `depth[tab]=1`.
  2. `etc/core/commands:65` — `depth()`: `depth[tab]=$REPLY`.
  3. `etc/core/dir_file_filter:41` — `files()`: `-maxdepth ${depth[tab]:-1}`.
  4. `etc/core/ftl:32` — `dir_esize()`: `-maxdepth 1` (hardcoded, doesn't use `depth[tab]`).

#### `hidden` (show dot-files)

- **Type:** associative array (`tab` → 0/1)
- **Default:** unset (falsy)
- **Purpose:** If set to `1`, dot-files are shown. Toggled by `z.`.
- **Usage sites:**
  1. `etc/core/ftl:150` — `tab_setup()`: (doesn't set `hidden[tab]` — leaves unset).
  2. `etc/core/commands:190` — `show_hidden()`: `((hidden[tab])) && hidden[tab]= || hidden[tab]=1`.
  3. `etc/core/dir_file_filter:41` — `files()`: `${hidden[tab]:+\( ! -path "*/.*" \)}` — if `hidden[tab]` is set, exclude dot-paths.
  4. `etc/core/ftl:32` — `dir_esize()`: `${hidden[tab]:+\( ! -iname '.*' \)}`.
  5. `etc/core/ftl:117` — `save_state`.

#### `filters_dir`, `filters`, `filters2`, `rfilters`, `tfilters`, `ntfilter`

- See §9 (Filter State).

#### `sort_type`, `reversed`

- **Type:** associative arrays (`tab` → integer / `tab` → `-r`/`0`/empty)
- **Defaults:** fall back to `sort_type0`/`sort_reversed0` if unset
- **Purpose:** Per-tab sort mode and reversed flag.
- **Usage sites:**
  1. `etc/bin/ftl:39` — `cview()`: `s_type=${sort_type[tab]:-$s_type} ; [[ "${reversed[tab]}" == "-r" ]] && s_reversed=-r || { [[ "${reversed[tab]}" == "0" ]] && s_reversed= ; }`.
  2. `etc/core/commands:194` — `sort_entries()`: `sort_type[tab] = sort_type[tab] + 1 >= ${#sort_filters[@]} ? 0 : sort_type[tab] + 1`.
  3. `etc/core/commands:195` — `sort_entries_reversed()`: `[[ ${reversed[tab]} == '-r' ]] && reversed[tab]=0 || reversed[tab]=-r`.
  4. `etc/core/ftl:113,115` — `save_state`.
  5. `etc/filters/sort_by_extension:14` — `${reversed[tab]}`.

#### `pdir_only` (preview directory only)

- **Type:** associative array (`tab` → empty or `ᴰ`)
- **Default:** empty
- **Purpose:** If set, only directories get a preview (files show nothing). Toggled by `zmD`.
- **Usage sites:**
  1. `etc/core/ftl:150` — `tab_setup()`: `pdir_only[tab]=`.
  2. `etc/core/commands:134` — `preview_dir_only()`: `[[ "${pdir_only[tab]}" ]] && pdir_only[tab]= || pdir_only[tab]='ᴰ'`.
  3. `etc/viewers/core:43` — `pviewers()`: `[[ "${pdir_only[tab]}" ]] && { [[ -d "$n" ]] || { tcpreview ; return ; } ; }`.
  4. `etc/bin/ftl:176` — `show_header()`: `${pdir_only[tab]}`.

---

## 9. Filter State

**File:** `etc/core/dir_file_filter` (the filter engine), `etc/core/commands` (filter commands), `etc/core/ftl_setup:14` (init).

### 9.1 Per-Tab Filter Variables

#### `filters`, `filters2`, `filters_dir`, `rfilters`

- **Type:** associative arrays (`tab` → regex string)
- **Defaults:** `.` (match all) for `filters`/`filters2`/`filters_dir`; `$rfilter0` for `rfilters`
- **Purpose:** The four user-tunable regex filters. Each is passed as an argument to `rg`. `filters_dir` applies to directory entries only. `filters`/`filters2` apply to file entries (chained). `rfilters` is a reverse filter (`rg -v`).
- **Usage sites:**
  1. `etc/core/ftl:150` — `tab_setup()`: `filters_dir[tab]='.' ; filters[tab]='.' ; filters2[tab]='.' ; rfilters[tab]="$rfilter0"`.
  2. `etc/core/commands:53` — `clear_filters()`: reset all to defaults.
  3. `etc/core/commands:71-73` — `set_filter`/`set_filter_dir`/`set_filter2`: `filters[tab]="${REPLY:-.}"` etc.
  4. `etc/core/commands:76` — `set_filter_reverse()`: `rfilters[tab]="$REPLY"`.
  5. `etc/core/dir_file_filter:11-14` — `filter_not`/`filter_1`/`filter_2`/`filter_rev`: `rg ${filters[tab]}` etc.
  6. `etc/core/dir_file_filter:28,35` — `as_dir`/`dir`: `rg ${filters_dir[tab]}`.
  7. `etc/core/ftl:114,116,118,119` — `save_state`.

#### `tfilters`, `ntfilter`

- **Type:** associative arrays (`tab` → regex / `tab` → `-v` or empty)
- **Defaults:** empty
- **Purpose:** Image-mode filters. When `vmode[tab]` is 1 (no-image) or 2 (image-only), `tfilters[tab]` is set to `$ifilter$` and `ntfilter[tab]` is `-v` (for no-image) or empty (for image-only). `filter_not` combines them: `rg ${ntfilter[tab]} "${tfilters[tab]}"`.
- **Usage sites:**
  1. `etc/core/commands:209-211` — `view_mode_all`/`image`/`not_image`: set/clear `tfilters`/`ntfilter`.
  2. `etc/core/dir_file_filter:11` — `filter_not()`: `rg ${ntfilter[tab]} "${tfilters[tab]}"`.
  3. `etc/core/ftl:119` — `save_state`: `ntfilter[tab]=\"${ntfilter[tab]}\" "`.

### 9.2 External Filter State

#### `filter_ext`, `filter_list`, `filter_list2`, `filter_pipe`

- **Declared at:** `filter_ext` implicitly global; `filter_list`/`filter_list2` in `dir_file_filter`; `filter_pipe` at `etc/core/dir_file_filter:19`.
- **Types:** `filter_ext` scalar (filter name), `filter_list`/`filter_list2` indexed arrays, `filter_pipe` scalar (`|`-separated function names)
- **Defaults:** `filter_ext=` (empty), `filter_pipe="filter_not|filter_1|filter_2|filter_rev"`
- **Purpose:** `filter_ext` is the name of the currently-loaded external filter (e.g. `by_extension`). `filter_list` is the list of filter functions in the pipe. `filter_pipe` is the rendered pipe string (used with `eval`).
- **Usage sites:**
  1. `etc/core/dir_file_filter:19` — `filter_pipe="$(filter_add filter_not filter_1 filter_2 filter_rev)"`.
  2. `etc/core/dir_file_filter:3-5` — `filter_add`/`filter_clr`/`filter_rmv`: manipulate `filter_list`.
  3. `etc/core/dir_file_filter:7-8` — `filter_rst`/`filter_rxt`: reset, including `filter_ext=`.
  4. `etc/core/dir_file_filter:29,30,36,37` — `as_dir`/`dir`: `eval "$filter_pipe"`.
  5. `etc/core/commands:53` — `clear_filters()`: `filter_rst ; ftag=`.
  6. `etc/core/commands:74,77` — `set_filter_ext`/`load_filter`: `filter_ext="$1"`.
  7. `etc/core/ftl:129` — `prev_synch()`: `[[ "$filter_ext" ]] && source "$FTL_CFG/filters/$filter_ext" load $ofs || filter_rst`.

#### `ftag`

- **Declared at:** implicitly global; set in many filter commands.
- **Type:** scalar (string, a single glyph)
- **Default:** empty
- **Purpose:** "Filter tag" — the glyph shown in the header when a filter is active. Set to `~` when any filter is non-default.
- **Usage sites:**
  1. `etc/core/dir_file_filter:7` — `filter_rst()`: `ftag=`.
  2. `etc/core/commands:53` — `clear_filters()`: `ftag=`.
  3. `etc/core/commands:71-76` — `set_filter*`: `ftag="~"`.
  4. `etc/filters/by_extension:13` — `fexts[$ext]=1 ; ftag="~"`.
  5. `etc/filters/by_regexp:16` — `ftag="~"`.
  6. `etc/filters/by_size:10` — `ftag="~"`.
  7. `etc/filters/by_tag:37` — `ftag="~"`.
  8. `etc/bin/ftl:181,185` — `show_header()`: `$head$ftag$...`.

### 9.3 Sort State

#### `s_type`, `s_reversed`

- **Declared at:** `etc/bin/ftl:38-39` — `s_type=$sort_type0 ; s_reversed=$sort_reversed0` then overridden.
- **Types:** scalars (integer / string)
- **Defaults:** from `sort_type0`/`sort_reversed0`, then per-tab override
- **Purpose:** The resolved sort type and reversed flag for the current directory listing. Computed at the start of `cview` from defaults, then overridden by per-tab values and `.ftlrc_dir`.
- **Usage sites:**
  1. `etc/bin/ftl:38-39` — `cview()`: `s_type=$sort_type0 ; s_reversed=$sort_reversed0 ; ... ; s_type=${sort_type[tab]:-$s_type} ; ...`.
  2. `etc/core/dir_file_filter:22` — `sort_by()`: `sort $s_reversed ${sort_filters[s_type]}`.
  3. `etc/core/dir_file_filter:7` — `filter_rst()`: `sort_glyph(){ echo ${sglyph[s_type]} ; }`.
  4. `etc/bin/ftl:185` — `show_header()`: `$(sort_glyph)$s_reversed`.

---

## 10. Preview / Pane State

**Files:** `etc/core/ftl` (pane management), `etc/viewers/core` (preview dispatch), `etc/bin/ftl` (preview entry).

### 10.1 Pane Identity Flags

#### `main`, `main_pane`, `panes`, `new_pane`

- **Declared at:** `main` at `etc/bin/ftl:14` (`main=1` for main pane); `main_pane`/`panes` from `$pfs/pane`/`$pfs/panes`; `new_pane` at `etc/core/ftl:67`.
- **Types:** `main` scalar (0/1), `main_pane` scalar (tmux pane id), `panes` indexed array (tmux pane ids), `new_pane` scalar (tmux pane id)
- **Defaults:** `main=1` for main pane, `main=0` (unset) for child
- **Purpose:** `main` indicates whether this is the main pane (only the main pane spawns preview panes directly; children signal the main pane). `main_pane` is the id of the main pane (read from `$pfs/pane`). `panes` is the list of child-pane ids. `new_pane` is the most recently spawned child.
- **Usage sites:**
  1. `etc/bin/ftl:14` — `main=1` (main pane init).
  2. `etc/bin/ftl:190` — `preview()`: `((main)) && { ... } || { ... }`.
  3. `etc/core/ftl:66-71` — `pane_extra`/`pane_ftl`/`pane_close`/`pane_next`/`pane_read`/`pane_send`: manage `panes`.
  4. `etc/core/ftl:67` — `pane_ftl()`: `panes+=($pane_id) ; new_pane=$pane_id ; pane_id= ; printf "%s\n" "${panes[@]}" >$pfs/panes`.
  5. `etc/core/ftl:68` — `pane_close()`: `((main && ${#panes[@]})) && { tail -n +2 $pfs/panes | sponge $pfs/panes ; ... }`.
  6. `etc/core/ftl:69` — `pane_next()`: `tp=("${panes[@]}" $main_pane "${panes[@]}")` — find next pane in rotation.
  7. `etc/core/ftl:70` — `pane_read()`: `<$pfs/pane read main_pane ; [[ -s $pfs/panes ]] && mapfile -t panes < <(grep -w -f <(tmux lsp -F "#{pane_id}") $pfs/panes)`.
  8. `etc/core/ftl:80` — `quit()`: `((!main)) && { pane_read ; tmux send -t $main_pane å ; }`.
  9. `etc/core/commands:177` — `quit_all()`: `((main)) && { pane_send "${C[quit_ftl]}" ; ... } || tmux send -t $main_pane ${C[quit_all]}`.
  10. `etc/core/commands:229` — `SIG_PANE()`: `pane_read ; ((${#panes[@]})) && tmux selectp -t ${panes[0]} || tmux selectp -t $my_pane`.
  11. `etc/bin/ftl:191` — `preview()` (child): `echo $my_pane >$fsp/pane` — write our id as the main pane for the signal.

#### `pane_id`, `pane2_id`

- **Declared at:** implicitly global; set in `tsplit`/`ctsplit`/`tcpreview`.
- **Types:** scalars (tmux pane ids)
- **Defaults:** empty
- **Purpose:** `pane_id` is the id of the current preview pane. `pane2_id` is the id of the optional second preview pane (the "fixed preview" opened by `zff`). Both are cleared by `tcpreview`.
- **Usage sites:** 30+ references. Notable:
  1. `etc/core/ftl:16` — `tcpreview()`: `[[ "$pane_id" ]] && { tmux killp -t $pane_id &>/dev/null ; pane_id= ; in_pdir= ; in_viprev= ; in_ftli= ; sleep 0.01 ; } ; tcpreview2 ; [[ $1 ]] && prev_all=$1`.
  2. `etc/core/ftl:17` — `tcpreview2()`: `[[ "$pane2_id" ]] && { tmux killp -t $pane2_id &>/dev/null ; pane2_id= ; sleep 0.01 ; }`.
  3. `etc/core/ftl:175` — `tsplit()`: `pane_id=$(tmux display -p '#{pane_id}')`.
  4. `etc/core/ftl:176` — `tsplitf()`: `pane2_id=$(tmux display -p '#{pane_id}')`.
  5. `etc/core/ftl:22` — `ctsplit()`: `[[ $pane_id ]] && tmux respawnp -k -t $pane_id "$1" &>/dev/null || tsplit "$1"`.
  6. `etc/core/ftl:14` — `pw3image()`: `((in_ftli)) && tmux send -t $pane_id ... || { ctsplit "ftli ..." ; ... }`.
  7. `etc/core/ftl:18` — `vipreview()`: `((in_viprev)) && tmux send -t $pane_id ":e ..." C-m || ctsplit "$EDITOR -R ..."`.
  8. `etc/core/ftl:46` — `geo_prev()`: `((${preview:-$prev_all})) && [[ -z $pane_id ]] && ((COLS=...))`.
  9. `etc/core/ftl:178` — `tselectp()`: `[[ "$1" =~ ^% ]] && tmux selectp -t $1 || tmux selectp -t $pane_id ${1:--L}`.
  10. `etc/core/ftl:181` — `zoom()`: `[[ $pane_id ]] && read -r COLS_P < <(tmux display -p -t $pane_id '#{pane_width}')`.
  11. `etc/bin/ftl:190-191` — `preview()`: `((main)) && { ... } || { save_state ; echo "$fs" >$fsp/fs ; echo $my_pane >$fsp/pane ; tmux send -t $main_pane 'Ä' &>/dev/null ;}`.
  12. `etc/viewers/core:41,42` — `pviewers()`: `[[ -e "$fs/lock_preview/$n" ]] && { plock ; return ; }`.
  13. `etc/core/commands:36-41` — `preview_down`/`up`/`down2`/`up2`/`left`/`right`: `tmux send -t $pane_id ...`.
  14. `etc/core/commands:174` — `preview_size()`: `[[ $pane_id ]] && tmux resizep -t $pane_id -x $x`.

#### `in_pdir`, `in_viprev`, `in_ftli`

- **Declared at:** implicitly global; set in `pdir_ftl`/`vipreview`/`pw3image`.
- **Types:** scalars (0/1 flags)
- **Defaults:** `0` (unset)
- **Purpose:** Track what kind of program is running in the preview pane, so we know how to interact with it. `in_pdir=1` means a child `ftl` is previewing a directory. `in_viprev=1` means `vim -R` is previewing a text file (so we can send `:e` commands to switch files). `in_ftli=1` means `ftli` (the image-preview daemon) is running.
- **Usage sites:**
  1. `etc/core/ftl:14` — `pw3image()`: `in_ftli=1`.
  2. `etc/core/ftl:16,22` — `tcpreview`/`ctsplit`: `in_pdir= in_viprev= in_ftli=`.
  3. `etc/core/ftl:18` — `vipreview()`: `in_viprev=1`.
  4. `etc/core/ftl:110` — `pdir_ftl()`: `in_pdir=1`.
  5. `etc/core/ftl:180` — `winch()`: `((!in_ftli)) && ...`.
  6. `etc/core/commands:36-37` — `preview_down`/`up`: `((in_viprev)) && tmux send -t $pane_id C-D || ...`.
  7. `etc/core/commands:66` — `editor_detach()`: `((in_viprev)) && in_viprev= && pane_id= && cdir`.
  8. `etc/viewers/core:110` — `pdir_ftl()`: `((in_pdir)) && [[ $pane_id ]] && { tmux send -t $pane_id 'r' ; }`.

#### `shell_id`

- **Declared at:** implicitly global; set in `shell_pane`/`shell_vpane`.
- **Type:** scalar (tmux pane id)
- **Default:** empty
- **Purpose:** The id of the shell pane (a sibling `bash -i`), if one is open. Commands like `shell_files` send text to it.
- **Usage sites:**
  1. `etc/core/commands:97-98` — `shell_pane`/`shell_vpane`: `shell_id=$pane_id ; pane_id=$P`.
  2. `etc/core/commands:99` — `shell_send()`: `(( $1 )) && [[ $shell_id ]] && $(tmux has -t $shell_id 2>&-) && tmux send -t $shell_id "${@:2}"`.
  3. `etc/core/commands:183-189` — `shell`/`shell_vertical`/`shell_files`/`shell_send_files`/`shell_view`/`shell_synch`/`shell_zoomed`: check `[[ $shell_id ]]`.
  4. `etc/core/ftl:92` — `quit_shell()`: `[[ $shell_id ]] && tmux killp -t $shell_id &>/dev/null`.

#### `session_shell`, `keep_shell`

- **Declared at:** implicitly global.
- **Types:** scalars (0/1 flags)
- **Defaults:** `0`
- **Purpose:** `session_shell=1` once the session shell (tmux window `ftl$$:ftl$$_bash`) has been created. `keep_shell=1` is set by `quit_keep_shell` to prevent `quit_shell` from killing the shell pane on quit.
- **Usage sites:**
  1. `etc/core/lib/shell:42` — `shell_command()`: `((session_shell)) || { tmux new -A -d -s ftl$$ ; tmux neww ... ; sleep 0.2 ; session_shell=1 ; }`.
  2. `etc/core/commands:187` — `shell_view()`: `((session_shell)) || { ... ; session_shell=1 ; }`.
  3. `etc/core/commands:178` — `quit_keep_shell()`: `keep_shell=1 ; quit_all`.
  4. `etc/core/ftl:92` — `quit_shell()`: `((!keep_shell)) && [[ $shell_id ]] && tmux killp -t $shell_id`.

### 10.2 Preview Mode

#### `prev_all`, `prev_cb`, `preview_pane2`, `no_redraw`, `gpreview`

- **Types:** `prev_all` scalar (0/1), `prev_cb` scalar (callback name), `preview_pane2` scalar (filename), `no_redraw` scalar (0/1), `gpreview` scalar (0/1)
- **Defaults:** `prev_all=1` (from `ftlrc:36`), others empty/0
- **Purpose:** `prev_all` toggles the preview pane on/off (`zv`). `prev_cb` is a callback name invoked during `prev_synch` (used by virtual entries to re-establish themselves in the preview pane). `preview_pane2` is the filename to show in the fixed second preview pane. `no_redraw` is a flag to suppress redraw during mode switches. `gpreview=1` indicates this pane is a child (preview) pane — it doesn't spawn its own previews.
- **Usage sites:**
  1. `etc/ftlrc:36` — `: ${prev_all:=1}`.
  2. `etc/bin/ftl:17` — child pane: `gpreview=1 ; prev_all=0`.
  3. `etc/bin/ftl:46` — `geo_prev()`: `((${preview:-$prev_all})) && [[ -z $pane_id ]] && ...`.
  4. `etc/bin/ftl:148,166` — `list()`: `((gpreview)) || save_state $fsi` / `((qd || gpreview)) || { preview ; ... }`.
  5. `etc/bin/ftl:190` — `preview()`: `((prev_all)) && pviewers`.
  6. `etc/core/ftl:16` — `tcpreview()`: `[[ $1 ]] && prev_all=$1`.
  7. `etc/core/ftl:130` — `prev_synch()`: `((gpreview)) && { [[ "$prev_cb" ]] && eval "$prev_cb" ; }`.
  8. `etc/core/ftl:132` — `prev_synch()`: `((gpreview)) && { view_mode "${vmode[tab]}" 1 ; }`.
  9. `etc/core/commands:131-132` — `preview_pane`/`preview_pane2`: `((prev_all ^= 1))` / `preview_pane2="$f"`.
  10. `etc/core/commands:209-213` — `view_mode_*`: `no_redraw=$1 ; (($no_redraw)) || cdir '' "$f"`.
  11. `etc/bindings/virtual_entries:65,81,102` — `prev_cb="ventries_off"` / `"ventries_on"` / `"ventry_save_as"`.

#### `no_image_preview`

- **Declared at:** implicitly global; toggled in `preview_image`.
- **Type:** scalar (0/1)
- **Default:** `0`
- **Purpose:** When `1`, image previews are disabled (all image extensions are added to `pignore`).
- **Usage sites:**
  1. `etc/core/commands:136` — `preview_image()`: `((no_image_preview ^= 1)) ; for e in $(tr '|' ' ' <<< "$ifilter") ; do pignore[${e}]=$no_image_preview ; done`.

#### `montage`

- **Declared at:** implicitly global; set in `pdir_image`.
- **Type:** scalar (string, a glyph `⠶` or empty)
- **Default:** empty
- **Purpose:** Set to `⠶` when a montage is being displayed for the current directory, so the header can show the montage indicator.
- **Usage sites:**
  1. `etc/viewers/core:116` — `pdir_image()`: (sets `montage` — actually, looking at the code, `montage` is set elsewhere; `pdir_image` reads `$ftl_root/montage/$n/montage.jpg`).
  2. `etc/bin/ftl:176` — `show_header()`: `${montage}` in the head assembly.

Actually, on closer inspection, `montage` is set by the `zd5`/`set_directory_mode5` path which sets `dirmode=5`, and `pdir_image` is invoked. The `montage` glyph seems to be set imperatively but I don't find the assignment in the source — it may be set by `.ftlrc_dir` or by user customization.

### 10.3 Etag State

#### `etag_s`, `etag_cb`

- **Declared at:** implicitly global.
- **Types:** scalars (strings)
- **Defaults:** empty
- **Purpose:** `etag_s` is the name of the current etag source (e.g. `git`, `date`). `etag_cb` is a callback string (built by `vfiles_set`) that gets `eval`ed during `prev_synch` to re-establish virtual-entry callbacks.
- **Usage sites:**
  1. `etc/core/ftl:107,109` — `save_state`: serializes `etag_s`/`etag_cb`.
  2. `etc/core/ftl:131` — `prev_synch()`: `[[ "$etag_s" ]] && { source "$FTL_CFG/etags/$etag_s" ; [[ "$etag_cb" ]] && eval "$etag_cb" ; ... }`.
  3. `etc/core/commands:228` — `etag_select()`: `etag_s=$(cd $p ; fd | fzf-tmux ...) ; [[ $etag_s ]] && { . $p/$etag_s $fs ; etag=1 ; cdir ; }`.
  4. `etc/bindings/leader_git:2` — `git_etags()`: `etag_s=git ; source "$FTL_CFG/etc/etags/$etag_s"`.
  5. `etc/bindings/virtual_entries:86` — `ventries_etag()`: `etag_s="virtual" ; source ...`.
  6. `etc/core/ftl:183-185` — `vfiles_set`/`vfiles_on`/`vfiles_rst`: build/clear `etag_cb`.

#### `external_tag`, `external_tag_length`

- **Declared at:** passed as nameref arguments to `etag_tag()`.
- **Types:** scalars (string / integer)
- **Purpose:** Out-parameters from `etag_tag()`. `external_tag` is the tag string to prepend; `external_tag_length` is its display length (for column alignment).
- **Usage sites:**
  1. `etc/bin/ftl:106` — `prepare_entries()`: `etag_tag "$pnc" external_tag external_tag_length ; pc="$external_tag$pc" ; ((pnc_l+=external_tag_length))`.
  2. `etc/etags/git:46` — `etag_tag()`: `local -n r2=$2 r3=$3 ; r2=... ; r3=3`.
  3. `etc/etags/date:11` — `etag_tag()`: `r3=17`.
  4. `etc/etags/lines:12` — `etag_tag()`: `r3=6`.
  5. `etc/etags/image_size:14` — `etag_tag()`: `r3=10`.
  6. `etc/etags/tmsu:12` — `etag_tag()`: `r3=2`.
  7. `etc/etags/virtual:2` — `etag_tag()`: `r3=2`.

### 10.4 Inotify State

#### `ino1`, `ino_processes`

- **Declared at:** implicitly global; set in `inotify_s`.
- **Types:** `ino1` scalar (PID), `ino_processes` indexed array (PIDs)
- **Defaults:** empty
- **Purpose:** `ino1` is the PID of the inotify watcher subshell. `ino_processes` is the list of the subshell and all its children (via `pchild`). Both are used by `inotify_k` to kill the watcher and its children.
- **Usage sites:**
  1. `etc/core/ftl:51` — `inotify_s()`: `inotify_k ; (inotify_ ) & : ; ino1=$! ; ino_processes=($ino1 $(pchild $ino1 0))`.
  2. `etc/core/ftl:54` — `inotify_k()`: `[[ $ino1 ]] && { for p in "${ino_processes[@]}" ; do disown $p 2>&- ; kill $p 2>&- ; done ; ino1= ; }`.
  3. `etc/bin/ftl:29` — `cview()`: `inotify_k` (before) and `inotify_s` (after).

#### `mplayer`, `w3iproc`

- **Declared at:** implicitly global.
- **Types:** scalars (PIDs)
- **Defaults:** empty
- **Purpose:** PIDs of background media processes, so they can be killed. `mplayer` is the PID of the background mplayer/vlc. `w3iproc` is the PID of the w3mimgdisplay process (in `ftli`).
- **Usage sites:**
  1. `etc/core/ftl:65` — `player_k()`: `((mplayer)) && { kill $mplayer &>/dev/null ; mplayer= ; }`.
  2. `etc/viewers/core:90,91` — `ext_mp3`/`ext_media`: `mplayer=$!`.
  3. `etc/viewers/core:128` — `pmlive()`: (uses `player_k`).
  4. `etc/viewers/mplayer_local:1` — sets `mplayer` (via the parent's `ext_media`).
  5. `etc/bin/ftli:14,59` — `w3iproc=$!` (the ftli daemon's w3mimgdisplay PID).
  6. `etc/bin/ftli:14` — `[[ "$image" == FTL_RESTART_W3M ]] && { kill $w3iproc &>/dev/null ; { <&7 /usr/lib/w3m/w3mimgdisplay &> /dev/null & } ; w3iproc=$! ; }`.

---

## 11. Tmux / IPC State

**Files:** `etc/core/ftl` (tmux helpers), `etc/bin/ftl` (main loop signals).

### 11.1 Signal Handling

#### `in_Q`

- **Declared at:** implicitly global; set in `quit_all`.
- **Type:** scalar (0/1)
- **Default:** `0`
- **Purpose:** "In quit" flag. When `1`, `cdfl()` (the function that writes selection to fd 3 for `ftll`/`cdf` consumers) writes nothing — just a newline. This prevents the selection from being emitted when the user quits with `Q` (cancel) rather than `q` (select-and-quit).
- **Usage sites:**
  1. `etc/core/commands:177` — `quit_all()`: `in_Q=1 ; quit`.
  2. `etc/core/ftl:91` — `cdfl()`: `((! in_Q)) && printf "%s\n" "${selection[@]}" >&3 || echo >&3`.

### 11.2 Time Event State

#### `time_event0`

- **Declared at:** `etc/core/ftl:163` — `time_event0=$SECONDS`
- **Type:** scalar (integer, seconds since shell start)
- **Default:** `$SECONDS` at module load
- **Purpose:** The timestamp of the last time-event firing. Compared to current `$SECONDS` to determine if `time_event` seconds have elapsed.
- **Usage sites:**
  1. `etc/core/ftl:163` — initialized.
  2. `etc/core/ftl:164` — `time_event()`: `(($SECONDS - $time_event0 >= $time_event)) && { ... ; time_event0=$SECONDS ; }`.

### 11.3 Quit State

#### `qshell_c`

- **Declared at:** `etc/core/ftl:83` — `qshell_c=0`
- **Type:** scalar (integer)
- **Default:** `0`
- **Purpose:** Counter for `qshell()` calls. If the user tries to quit while shells are open, `qshell` warns them. After 2 calls, it allows quit. The counter resets after 3 seconds of no calls (via the commented-out `reset_qshell_call` time-event handler).
- **Usage sites:**
  1. `etc/core/ftl:83` — initialized.
  2. `etc/core/ftl:84` — `qshell()`: `((qshell_c++, qshell_c > 2)) && return 1 ; (( $(tmux lsw -t ftl$$ 2>&- | wc -l) > 2 )) && { tmux popup ... ; true ; } || false`.

### 11.4 Alt Screen State

#### `alt_screen`

- **Declared at:** `etc/core/ftl:5` — `alt_screen=0`
- **Type:** scalar (0/1)
- **Default:** `0`
- **Purpose:** Tracks whether the terminal alternate screen (`\e[?1049h`) is active, so `alt_screen()` (the function) only enters it once.
- **Usage sites:**
  1. `etc/core/ftl:5` — initialized.
  2. `etc/core/ftl:6` — `alt_screen()`: `[[ $alt_screen == 0 ]] && { echo -en '\e[?1049h' ; stty -echo ; tput civis ; alt_screen=1 ; }`.
  3. `etc/core/ftl:35` — `edit()`: `alt_screen ; ... ${EDITOR} ... ; alt_screen`.
  4. `etc/core/ftl:57-58` — `k_bindings`/`k_bfull`: `alt_screen` before and after.
  5. `etc/core/commands:13,52,79,94,97` — `ftl_help`/`chmod_dialog`/`prompt`/`run_bash`/`scim`: toggle alt screen around external commands.

### 11.5 Winch State

#### `winch`

- **Declared at:** implicitly global; set to `1` at the end of every main-loop iteration.
- **Type:** scalar (0/1)
- **Default:** `1` (set in main loop)
- **Purpose:** "Window changed" flag. Set to `1` at the end of each loop iteration so the next iteration's `winch()` check will detect geometry changes. Cleared implicitly by the check (only acts if `winch` is set).
- **Usage sites:**
  1. `etc/bin/ftl:21` — main loop: `winch=1` at the end.
  2. `etc/core/ftl:180` — `winch()`: `((winch)) && R="${C[refresh_pane]}$R"` — only trigger refresh if `winch` is set.

### 11.6 Misc IPC

#### `pdh`

- **Declared at:** implicitly global; read from `$pfs/pdh`.
- **Type:** scalar (tmux pane id)
- **Default:** empty
- **Purpose:** The id of the "pdh" (debug) pane, if open. `pdh()` sends messages to it.
- **Usage sites:**
  1. `etc/core/ftl:75` — `pdh()`: `[[ -f $pfs/pdh ]] && { read pdh <$pfs/pdh ; [[ $pdh ]] && tmux send -t $pdh "$$ $my_pane: ${1//\\n/$'\n'}" ; }`.
  2. `etc/core/ftl:77` — `pdh_show()`: `[[ -f $pfs/pdh ]] && { tmux killp -t $(<$pfs/pdh) &>/dev/null ; rm $pfs/pdh ; } || { ... tsplit "$FTL_CFG/etc/bin/fpdh $pfs" ... ; }`.

#### `to_search`

- **Declared at:** implicitly global; set in `find_entry`/`incremental_search`/`goto_alt1`.
- **Type:** scalar (string)
- **Default:** empty
- **Purpose:** The current search string for incremental search and find-next/previous. Shown in the header as `S:$to_search`.
- **Usage sites:**
  1. `etc/core/commands:34` — `goto_alt1()`: `to_search=".$e"`.
  2. `etc/core/commands:78` — `find_entry()`: `prompt "find: " -i to_search`.
  3. `etc/core/commands:79-80` — `find_next`/`find_previous`: `[[ "${files[i]##*/}" =~ "$to_search" ]]`.
  4. `etc/bindings/incremental_search:2,8,9,14,15` — `incremental_search`/`incremental_find`: set/append/delete from `to_search`.
  5. `etc/bin/ftl:178` — `show_header()`: `[[ "$to_search" ]] && search_h="S:$to_search "`.

---

## 12. External-Integration Globals

These globals are read by external scripts (`finfo`, `fsh`, `ftli`, `ftl_synch_with_shell`, `ftl_shell_back`) to communicate with the `ftl` process.

### 12.1 The `ftl_info_file` Block

#### `ftl_info_file`, `ftl_main_info_file`

- **Declared at:** `etc/bin/ftl:19,198-200` — `ftl_main_info_file="$(mktemp -p $fs ftl_main_info_XXXXXXX)"` / `ftl_info_file="$(mktemp -p $fs ftl_info_XXXXXXX)"` / `export ftl_info_file`
- **Types:** scalars (file paths)
- **Defaults:** mktemp-generated paths
- **Purpose:** Path to a temp file containing serialized `ftl` state (`FTL_PID`, `FTL_FS`, `FTL_PWD`, `n`, `selection`). External commands `source` this file to get access to ftl's state. `ftl_main_info_file` is the "main" info file (set once at startup); `ftl_info_file` is re-generated by `setup_finfo` before each command dispatch (so external commands see fresh state).
- **Usage sites:**
  1. `etc/bin/ftl:19` — `ftl_main_info_file="$(mktemp -p $fs ftl_main_info_XXXXXXX)" ; setup_finfo "$ftl_main_info_file"`.
  2. `etc/bin/ftl:198-200` — `setup_finfo()`: `[[ -n "$1" ]] && ftl_info_file="$1" || ftl_info_file="$(mktemp -p $fs ftl_info_XXXXXXX)" ; export ftl_info_file`.
  3. `etc/bin/ftl:201` — `ftl_env+=([ftl_info_file]=$ftl_info_file)`.
  4. `etc/bin/ftl:203` — `{ FTL_PID=$$ ; FTL_FS=$fs ; FTL_PWD=${PWD@Q} ; declare -p FTL_PID FTL_FS FTL_PWD n selection ; } >$ftl_info_file`.
  5. `etc/core/keyboard:79` — `key_command()`: `setup_finfo "$ftl_main_info_file"` — before every command, refresh the main info file.
  6. `etc/core/lib/shell:31` — `shell_command()`: `setup_finfo` — before external command dispatch.
  7. `etc/core/lib/shell:48,52` — `shell_command()`: `tmux split-window -e ftl_info_file="$ftl_info_file" ...` / `echo "export ftl_info_file=$ftl_info_file"`.
  8. `etc/bin/finfo:13` — `[[ -e "$ftl_info_file" ]] && source "$ftl_info_file" || { echo "finfo: no ftl info file" >&2 ; exit 1 ; }`.
  9. `etc/bin/fsh:3,6` — `source $ftl_info_file` / `export ftl_info_file='$ftl_info_file'`.
  10. `etc/commands/02_example:6,9` — `source $ftl_info_file` / `echo ftl_info_file: $ftl_info_file`.

#### `FTL_PID`, `FTL_FS`, `FTL_PWD`

- **Declared at:** `etc/bin/ftl:203` — written to `$ftl_info_file` via `declare -p`.
- **Types:** scalars (PID / path / quoted-path)
- **Defaults:** `$$` / `$fs` / `${PWD@Q}`
- **Purpose:** Serialized state for external commands. `FTL_PID` is ftl's process ID (used to target the right tmux session). `FTL_FS` is ftl's runtime directory. `FTL_PWD` is ftl's current directory (quoted for safe sourcing).
- **Usage sites:**
  1. `etc/bin/ftl:203` — written.
  2. `etc/bin/fsh:3,6,8,12` — `source $ftl_info_file # to get FTL_PID` / `tmux neww -P -a -t ftl${FTL_PID} "..."` / `>>$FTL_FS/cmd_log`.
  3. `etc/commands/02_example:10-11` — `echo FTL_PID: $FTL_PID` / `echo FTL_PWD: $FTL_PWD`.

#### `ftl_pfs`, `ftl_fs` (environment variables)

- **Declared at:** `etc/core/ftl:36` — `ftl_env+=([ftl_pfs]=$pfs [ftl_fs]=$fs)`
- **Types:** scalars (paths, passed as `-e` args to `tmux split-window`)
- **Defaults:** the parent's `$pfs` and `$fs`
- **Purpose:** Environment variables passed to child `ftl` processes so they know their parent's `pfs` (shared state) and `fs` (their own private state).
- **Usage sites:**
  1. `etc/core/ftl:36` — `ftl_env()`: `ftl_env+=([ftl_pfs]=$pfs [ftl_fs]=$fs)`.
  2. `etc/core/ftl:175` — `tsplit()`: `tmux sp $(ftl_env) ...` — passes `-e ftl_pfs=... -e ftl_fs=...`.
  3. `etc/bin/ftl:6,7,8` — child pane reads them: `[[ "$1" == '-f' ]] && { pfs=$ftl_root/$$ ; ... }` — wait, this doesn't use `ftl_pfs`. Actually, looking at `etc/bin/ftl:14`: `[[ "$2" ]] && { fs=$2/$$ ; pfs=$2 ; ... }` — the child receives `pfs` as `$2` (positional arg), not from env. But `ftl_env` is still passed so generators and helpers can read it.
  4. `etc/bin/ftl_synch_with_shell:3` — `[[ $ftl_pfs ]] && echo $PWD > $ftl_pfs/synch_with_shell`.
  5. `etc/bin/ftl_shell_back:3` — `[[ $ftl_pfs ]] && <$ftl_pfs/pane read parent_pane`.

### 12.2 The `fzf_viewer` Flag

#### `fzf_viewer`

- **Declared at:** implicitly global; set in `fzf_pane_preview`.
- **Type:** scalar (0/1)
- **Default:** `0`
- **Purpose:** When `1`, `psplit()` uses `tmux respawn-pane` instead of `ctsplit` (which uses `respawnp`), because fzf doesn't tolerate being killed and respawned.
- **Usage sites:**
  1. `etc/core/ftl:21` — `psplit()`: `((fzf_viewer)) && [[ $pane_id ]] && tmux respawn-pane -k -t $pane_id "$@" || ctsplit "$@"`.
  2. `etc/bindings/fzf_pane_preview:56` — (commented out) `# fzf_viewer=1`.

---

## 13. Plugin-Defined Globals

These globals are declared inside plugin files (filters, etags, generators, bindings) and are only present when the corresponding plugin is loaded.

### 13.1 Filter Globals

Each filter plugin declares its own `keep` (and sometimes `PWDS`/`PWDR`) associative array. These are deliberately named the same across filters (so they share the serialization cache format) but are distinct per-filter-load.

#### `keep` (in every filter)

- **Declared at:** the first line of each filter file, e.g. `etc/filters/by_extension:1` — `declare -g -A fexts=()` (note: `by_extension` uses `fexts`, not `keep`); `etc/filters/by_regexp:1` — `declare -g -A keep PWDS`; `etc/filters/by_size` (no explicit declare, uses `ftl_min_size`); `etc/filters/by_tag:1` — `declare -g -A keep=() PWDS=()`; etc.
- **Type:** associative array (filename or `tab-$PWD/$filename` → `1`)
- **Default:** empty
- **Purpose:** The set of entries to keep. Populated during the filter's `load` phase (often via fzf), checked during `ftl_filter()`.
- **Usage sites:** (per filter, see the filter files). Common pattern:
  - `load` phase: `keep["$tab-$PWD/$file"]=1`.
  - `ftl_filter()`: `[[ "${keep[...]}" == 1 ]] && echo "$file_data"`.
  - `reset`: `unset -v keep`.
  - Cache: `declare -p keep >"$pfs/by_X"`.

#### `PWDS`, `PWDR`

- **Declared at:** alongside `keep` in filters that need per-directory tracking.
- **Type:** associative array (`tab-$PWD` → `1`)
- **Purpose:** Tracks which directories have active keep-lists, so `ftl_filter()` knows whether to filter or pass through (`cat`) for directories not in the list.
- **Usage sites:** `etc/filters/by_regexp`, `by_file`, `by_file_global`, `by_file_reset_dir`, `by_file_global_reset_dir`, `by_all_files`, `by_all_files_reset`, `by_tag`, `by_tag_query`, `by_bash_keep`, `by_bash_hide`, `by_visible_entries`.

#### `fexts` (by_extension only)

- **Declared at:** `etc/filters/by_extension:1` — `declare -g -A fexts=()`
- **Type:** associative array (extension → `1`)
- **Purpose:** The set of extensions to keep. Populated via fzf multi-select.
- **Usage sites:**
  1. `etc/filters/by_extension:1` — declared.
  2. `etc/filters/by_extension:13` — `fexts[$ext]=1`.
  3. `etc/filters/by_extension:16` — `declare -p fexts >"$fs/by_extension"` (cache).
  4. `etc/filters/by_extension:27` — `[[ "$ext" && ${fexts[$ext]} == 1 || -z "$ext" && ${fexts[-no_extension-]} == 1 ]]`.

#### `fnexts` (by_no_extension only)

- Similar to `fexts` but for extensions to hide.

#### `ftl_min_size` (by_size only)

- **Declared at:** `etc/filters/by_size:5` — `ftl_min_size="${REPLY:-0}"`
- **Type:** scalar (integer, bytes)
- **Purpose:** Minimum file size to keep. Files smaller than this are filtered out.
- **Usage sites:**
  1. `etc/filters/by_size:5` — set from user prompt.
  2. `etc/filters/by_size:7` — `declare -p ftl_min_size >"$pfs/by_size"` (cache).
  3. `etc/filters/by_size:17` — `((${file_data[0]} > ${ftl_min_size:-0}))`.

### 13.2 Etag Globals

Each etag plugin declares its own per-directory map.

#### `git_tags`, `is_git` (git etag)

- **Declared at:** `etc/etags/git:6` — `declare -g -A git_tags=() ; is_git=0`
- **Types:** `git_tags` associative array (filename → colored status string), `is_git` scalar (0/1)
- **Purpose:** `git_tags` maps each entry to its git-status short code (with ANSI color). `is_git` is `1` if the current directory is in a git repo.
- **Usage sites:**
  1. `etc/etags/git:6` — declared.
  2. `etc/etags/git:8-11` — `etag_dir()`: `git rev-parse HEAD &>/dev/null && { readarray -t lines < <(unbuffer git status -s *) ; is_git=1 ; ... ; git_tags[$file]="${git_status} " }`.
  3. `etc/etags/git:46` — `etag_tag()`: `(( is_git && etag )) && { r2="${git_tags[$1]:-   }" ; r3=3 ; }`.

#### `ext_dates` (date etag)

- **Declared at:** `etc/etags/date:3` — `declare -g -A ext_dates=()`
- **Usage sites:**
  1. `etc/etags/date:3` — declared.
  2. `etc/etags/date:5-8` — `etag_dir()`: `ext_dates[$ext_file]="$(printf "\e[2;37m$ext_date \e[m")"`.
  3. `etc/etags/date:11` — `etag_tag()`: `r2="${ext_dates[$1]}" ; r3=17`.

#### `ext_lines` (lines etag)

- **Declared at:** `etc/etags/lines:3` — `declare -g -A ext_lines=()`
- **Usage sites:**
  1. `etc/etags/lines:3` — declared.
  2. `etc/etags/lines:5-9` — `etag_dir()`: `ext_lines[$ext_file]="$(printf "\e[2;37m%5s \e[m" "$ext_file_lines")"`.
  3. `etc/etags/lines:12` — `etag_tag()`: `r2="${ext_lines[$1]}" ; r3=6`.

#### `ext_sizes` (image_size etag)

- **Declared at:** `etc/etags/image_size:3` — `declare -g -A ext_sizes=()`
- **Usage sites:**
  1. `etc/etags/image_size:3` — declared.
  2. `etc/etags/image_size:4-11` — `etag_dir()`: populates `ext_sizes` via `file` + perl parse.
  3. `etc/etags/image_size:14` — `etag_tag()`: `r2="${ext_sizes[$PWD/$1]}" ; r3=10`.

#### `tmsu_untags` (tmsu etag)

- **Declared at:** `etc/etags/tmsu:3` — `declare -g -A tmsu_untags=()`
- **Usage sites:**
  1. `etc/etags/tmsu:3` — declared.
  2. `etc/etags/tmsu:4-8` — `etag_dir()`: `readarray -t files < <(unbuffer tmsu untagged | ...) ; for file in "${files[@]}" ; do tmsu_untags[$file]="  " ; done`.
  3. `etc/etags/tmsu:12` — `etag_tag()`: `r2="${tmsu_untags[$1]:-ᵀ }" ; r3=2`.

### 13.3 Binding Globals

#### `leader_help_index` (leader binding)

- **Declared at:** `etc/bindings/leader:2` — `leader_help_index=${FTL_LTC_INDEX:-1}`
- **Type:** scalar (integer)
- **Default:** `${FTL_LTC_INDEX:-1}`
- **Purpose:** Index into the leader-help system (the `FTL_LTC` command). Incremented/decremented by `leader_help_next`/`previous`.
- **Usage sites:**
  1. `etc/bindings/leader:2` — declared.
  2. `etc/bindings/leader:5-7` — `leader_help()`: `leader_help_index='${1:-$leader_help_index}' ; ...`.
  3. `etc/bindings/leader:10-12` — `leader_help_reset`/`next`/`previous`.

#### `SAF` (virtual_entries binding)

- **Declared at:** `etc/bindings/virtual_entries:98` — `SAF='save_as.txt'`
- **Type:** scalar (filename)
- **Default:** `'save_as.txt'`
- **Purpose:** The name of the virtual "save_as" entry.
- **Usage sites:**
  1. `etc/bindings/virtual_entries:98` — declared.
  2. `etc/bindings/virtual_entries:100-104` — `add_save_as`/`get_file_name`/`ventry_save_as`/`virt_files_save_as`.

#### `fzf_to_search`, `fzf_answer`, `fzf_total_count`, `fzf_match_count`, `fzf_entries`, `fzf_rq` (fzf_search binding)

- **Declared at:** implicitly global in `etc/bindings/fzf_search`.
- **Types:** `fzf_to_search` scalar (string), `fzf_answer` scalar (JSON), `fzf_total_count`/`fzf_match_count` scalars (integers), `fzf_entries` scalar (newline-separated strings), `fzf_rq` scalar (fzf action command)
- **Purpose:** State for the `fzf --listen` integration. `fzf_to_search` accumulates the user's search query. `fzf_answer` is the JSON response from `xh`. The counts and entries are parsed from it. `fzf_rq` is the fzf action to send back (e.g. `put(a)`).
- **Usage sites:** all in `etc/bindings/fzf_search:13-74`.

---

## 14. Generated / Serialized Globals (cross-process)

These are not declared with `declare -g` — they're generated by `save_state` as Bash source files, then `source`d back by other panes.

### 14.1 The `$fs/ftl` Serialized State File

Written by `save_state()` at `etc/core/ftl:103-122`. Contains:

```bash
sdir="${files[file]}"    ; sindex=${dir_file[${tab}_${files[file]}]}     ; n="$n"
ftag=$ftag              ; show_size=$show_size                          ; prev_cb="$prev_cb"
etag=$etag              ; etag_s="$etag_s"                            ; etag_cb="$etag_cb"
dirmode="$dirmode"
filter_ext="$filter_ext"
vmode[tab]="${vmode[tab]}"
sort_type[tab]=${sort_type[tab]}
filters[tab]="${filters[tab]}"
filters2[tab]="${filters2[tab]}"
lmode[tab]="${lmode[tab]}"
hidden[tab]="${hidden[tab]}"
rfilters[tab]="${rfilters[tab]}"
ntfilter[tab]="${ntfilter[tab]}"
# plus: declare -p lignore lkeep
```

Read by `prev_synch()` at `etc/core/ftl:127` via `source "$ofs/ftl"`.

### 14.2 The `$fs/tags` Serialized Selection File

Written by `save_state()` at `etc/core/ftl:103` — `declare -p tags | sed 's/\-A/-A -g/' >$fs/tags`. The `sed` rewrites `declare -A tags` to `declare -A -g tags` so that when sourced by another pane, the array is declared global (the sourcing pane may have a local `tags` from a function context).

Read by `tag_synch()` at `etc/core/ftl:169` via `source $ofs/tags`.

### 14.3 The `$ftl_info_file` Serialized Info File

Written by `setup_finfo()` at `etc/bin/ftl:203`:

```bash
{ FTL_PID=$$ ; FTL_FS=$fs ; FTL_PWD=${PWD@Q} ; declare -p FTL_PID FTL_FS FTL_PWD n selection ; } >$ftl_info_file
```

Read by `finfo`, `fsh`, and user commands via `source $ftl_info_file`.

### 14.4 The `$fsp/stagsi` Counter File

Written by `save_state()` at `etc/core/ftl:103` — `echo "$stagsi" >$fsp/stagsi`.

Read by `tag_synch()` at `etc/core/ftl:169` — `read ostagsi <$fsp/stagsi`.

### 14.5 The `$fsp/fs` Pointer File

Written by `save_state()` at `etc/core/ftl:103` — `echo $fs >$fsp/fs` — and by `preview()` (child pane) at `etc/bin/ftl:191` — `echo "$fs" >$fsp/fs`.

Read by `tag_synch()` at `etc/core/ftl:169` — `read ofs <$fsp/fs` — and by `prev_synch()` at `etc/core/ftl:127`.

### 14.6 The `$fsp/pane` Main-Pane File

Written by `etc/bin/ftl:14` — `echo $my_pane >$fs/pane` (main pane init) — and by `preview()` (child) at `etc/bin/ftl:191` — `echo $my_pane >$fsp/pane`.

Read by `pane_read()` at `etc/core/ftl:70` — `<$pfs/pane read main_pane` — and by `SIG_REMOTE()` at `etc/core/commands:231` — `read op <$fsp/pane`.

### 14.7 The `$pfs/panes` Child-Pane List File

Written by `pane_ftl()` at `etc/core/ftl:67` — `printf "%s\n" "${panes[@]}" >$pfs/panes` — and pruned by `pane_close()` at `etc/core/ftl:68` — `tail -n +2 $pfs/panes | sponge $pfs/panes`.

Read by `pane_read()` at `etc/core/ftl:70` — `[[ -s $pfs/panes ]] && mapfile -t panes < <(grep -w -f <(tmux lsp -F "#{pane_id}") $pfs/panes)`.

---

## 15. Appendix: Implicit Globals (No `declare -g`)

The following variables are used as globals but are never explicitly declared with `declare -g`. They're first assigned inside a function (without `local`), which makes them global in Bash. This is the most error-prone category — a typo in any function can create a spurious global, and a `local` declaration in a parent function can shadow them unexpectedly.

### 15.1 Input/Dispatch

| variable              | first assigned in   | purpose                              |
| ----------            | ------------------- | ---------                            |
| `REPLY`               | `get_key()`         | current keystroke                    |
| `OREPLY`              | `get_key()`         | raw pre-normalization keystroke      |
| `R`                   | main loop / various | pending input queue                  |
| `E1`,`E2`,`E3`,`E4`   | `get_key()`         | escape-sequence continuation bytes   |
| `keys_command`        | `key_command()`     | accumulated key tokens               |
| `keys_in`             | `key_command()`     | count of accumulated tokens          |
| `HAS_COUNT`           | `key_command()`     | "COUNT" or empty                     |
| `COUNT`               | `key_command()`     | digit string                         |
| `keys_function`       | `key_command()`     | function about to be called          |
| `keys_latest_command` | `key_command()`     | last non-movement command (for redo) |

### 15.2 Listing/Rendering

| variable                                                                        | first assigned in            | purpose                  |
| ----------                                                                      | -------------------          | ---------                |
| `n`,`p`,`f`,`b`,`e`                                                             | `path()`                     | decomposed current entry |
| `mtype`                                                                         | `mime_get()`                 | mime type                |
| `is_bin`                                                                        | `is_bin()`                   | binary flag              |
| `file_b`                                                                        | `pviewers()`                 | `file -b` output         |
| `files`,`files_color`,`nfiles`                                                  | `prepare_entries()`          | listing arrays           |
| `file`                                                                          | `list()`                     | current entry index      |
| `line`,`sum`,`pad`,`first_file`,`found`                                         | `prepare_entries()`          | render temps             |
| `top`,`bottom`,`center`,`lines`                                                 | `list()`/`view_list()`       | window geometry          |
| `LINES`,`COLS`,`TOP`,`WIDTH`,`LEFT`                                             | `geometry()`                 | pane geometry            |
| `WCOLS`,`WLINES`                                                                | `geo_winch()`                | watched geometry         |
| `COLS_P`,`x`                                                                    | `zoom()`                     | preview-pane geometry    |
| `head`,`hsum`,`nfiles_h`,`stat`,`date`,`search_h`,`tabsd`,`tsc`,`h`,`hal`,`hpl` | `show_header()`/`header()`   | header pieces            |
| `flipi`,`flip`,`qd`                                                             | `list()`/`get_dir_entries()` | render flags             |
| `sep`                                                                           | `cview()`                    | path separator           |

### 15.3 Pane/Preview

| variable                                                    | first assigned in                       | purpose                         |
| ----------                                                  | -------------------                     | ---------                       |
| `pane_id`,`pane2_id`                                        | `tsplit()`/`tcpreview()`                | preview pane ids                |
| `in_pdir`,`in_viprev`,`in_ftli`                             | `pdir_ftl()`/`vipreview()`/`pw3image()` | preview-type flags              |
| `shell_id`                                                  | `shell_pane()`                          | shell pane id                   |
| `main`,`main_pane`                                          | `etc/bin/ftl:14` / `pane_read()`        | main-pane flag/id               |
| `panes`,`new_pane`                                          | `pane_ftl()`/`pane_read()`              | child-pane list / last spawned  |
| `session_shell`,`keep_shell`                                | `shell_command()`/`quit_keep_shell()`   | shell-session flags             |
| `prev_all`,`prev_cb`,`preview_pane2`,`no_redraw`,`gpreview` | various                                 | preview-mode state              |
| `no_image_preview`                                          | `preview_image()`                       | image-preview toggle            |
| `montage`                                                   | (set imperatively)                      | montage glyph                   |
| `emode`,`extmode`                                           | various                                 | external/internal preview modes |
| `dirmode`                                                   | `etc/ftlrc:34`                          | directory preview mode          |
| `pdf_prev_image`                                            | `etc/ftlrc:78`                          | PDF-as-image flag               |
| `mplayer`,`w3iproc`                                         | `ext_media()`/`ftli`                    | background PIDs                 |
| `ino1`,`ino_processes`                                      | `inotify_s()`                           | inotify watcher PIDs            |

### 15.4 Tags/Selection

| variable           | first assigned in       | purpose                     |
| ----------         | -------------------     | ---------                   |
| `stagsi`,`ostagsi` | various / `tag_synch()` | selection counter           |
| `ctag`             | `goto_next_tag()`       | current tag index           |
| `PC`,`PT`          | `delete_selection()`    | delete-prompt suffix/prefix |

### 15.5 Tab State

| variable             | first assigned in       | purpose                    |
| ----------           | -------------------     | ---------                  |
| `tab`,`tabs`,`ntabs` | `etc/core/ftl_setup:12` | current tab / list / count |

### 15.6 Filter State

| variable              | first assigned in   | purpose                      |
| ----------            | ------------------- | ---------                    |
| `filter_ext`          | `load_filter()`     | current external filter name |
| `ftag`                | various             | filter-active glyph          |
| `s_type`,`s_reversed` | `cview()`           | resolved sort type/reversed  |

### 15.7 Etag State

| variable                             | first assigned in                                 | purpose                                |
| ----------                           | -------------------                               | ---------                              |
| `etag`,`etag_s`,`etag_cb`            | `etc/ftlrc:63` / `etag_select()` / `vfiles_set()` | etag master toggle / source / callback |
| `external_tag`,`external_tag_length` | `prepare_entries()` (via nameref)                 | etag per-entry output                  |

### 15.8 IPC/Quit

| variable      | first assigned in                     | purpose                       |
| ----------    | -------------------                   | ---------                     |
| `in_Q`        | `quit_all()`                          | quit-cancel flag              |
| `qshell_c`    | `etc/core/ftl:83`                     | quit-with-shells-open counter |
| `alt_screen`  | `etc/core/ftl:5`                      | alt-screen active flag        |
| `winch`       | main loop                             | window-changed flag           |
| `time_event0` | `etc/core/ftl:163`                    | last time-event timestamp     |
| `to_search`   | `find_entry()`/`incremental_search()` | search string                 |
| `pdh`         | `pdh()`/`pdh_show()`                  | debug pane id                 |

### 15.9 External Integration

| variable                             | first assigned in   | purpose            |
| ----------                           | ------------------- | ---------          |
| `ftl_info_file`,`ftl_main_info_file` | `setup_finfo()`     | info-file paths    |
| `FTL_PID`,`FTL_FS`,`FTL_PWD`         | `setup_finfo()`     | serialized state   |
| `fzf_viewer`                         | (commented)         | fzf-as-viewer flag |

### 15.10 Per-Directory Override

#### `.ftlrc_dir` (sourced file, not a variable)

- **Sourced at:** `etc/bin/ftl:39` — `[[ -f .ftlrc_dir ]] && source .ftlrc_dir`
- **Purpose:** A per-directory override file. If present in the current directory, it's sourced after the default sort/filter setup. It can set `s_type`, `s_reversed`, `sort_type[tab]`, `reversed[tab]`, or any other state. Example: `etc/commands/ftlrc_dir/reverse_date` is a template that sets `sort_type[tab]=2 ; reversed[tab]=-r`.

