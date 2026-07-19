# `ftlrc` — Deep Reference Analysis

> **Subject:** `etc/ftlrc` — the 419-line default configuration file for `ftl`.
> **Purpose of this document:** a complete reference for every section, every variable, every default, every commented-out alternative, and every subtle behavior in the file. Use this as the authoritative companion when writing your own `ftlrc` or auditing the default.
> **Source revision analyzed:** `main` branch.

---

## Table of Contents

1. [File Structure Overview](#1-file-structure-overview)
2. [Section 1: Loader Sentinels & Locale (lines 1-2)](#2-section-1-loader-sentinels--locale-lines-1-2)
3. [Section 2: Directory Layout (lines 4-17)](#3-section-2-directory-layout-lines-4-17)
4. [Section 3: Bookmarks & Destinations (lines 19-25)](#4-section-3-bookmarks--destinations-lines-19-25)
5. [Section 4: Behavior Options (lines 27-60)](#5-section-4-behavior-options-lines-27-60)
6. [Section 5: External Tags (lines 62-67)](#5-section-5-external-tags-lines-62-67)
7. [Section 6: Glyph Tables (lines 69-73)](#6-section-6-glyph-tables-lines-69-73)
8. [Section 7: Media Filters (lines 75-78)](#7-section-7-media-filters-lines-75-78)
9. [Section 8: FZF Options (lines 80-85)](#8-section-8-fzf-options-lines-80-85)
10. [Section 9: External Commands (lines 87-124)](#9-section-9-external-commands-lines-87-124)
11. [Section 10: Deletion (lines 126-139)](#10-section-10-deletion-lines-126-139)
12. [Section 11: Display & Aliases (lines 141-147)](#11-section-11-display--aliases-lines-141-147)
13. [Section 12: Bindings (lines 149-415)](#12-section-12-bindings-lines-149-415)
14. [Cross-Cutting Observations](#13-cross-cutting-observations)
15. [Bugs, Smells, and Improvement Opportunities](#14-bugs-smells-and-improvement-opportunities)
16. [Reference: Variable Index by Category](#15-reference-variable-index-by-category)

---

## 1. File Structure Overview

`etc/ftlrc` is a Bash source file executed by `etc/core/ftl_setup:6`:

```bash
declare -Ag C bindings kbd_trie key_map vfiles vdirs time_event_handlers marks
source $FTL_CFG/ftlrc 2>&- || source $FTL_CFG/etc/ftlrc
```

The first `source` (user override at `$FTL_CFG/ftlrc`) is tried with stderr suppressed; if it fails (file doesn't exist), the default `$FTL_CFG/etc/ftlrc` is sourced. This means **the user can completely replace `ftlrc`** by creating `~/.config/ftl/ftlrc`, OR **selectively override** it by sourcing the default first and then changing variables.

The file has a clear linear structure — 12 logical sections in 419 lines:

| lines   | section                                  | # vars          | # binds    |
| ------- | ---------                                | --------        | ---------  |
| 1-2     | Loader sentinels & locale                | 3               | —          |
| 4-17    | Directory layout                         | 6               | —          |
| 19-25   | Bookmarks & destinations                 | 2 arrays        | —          |
| 27-60   | Behavior options                         | ~25             | —          |
| 62-67   | External tags config                     | 3               | —          |
| 69-73   | Glyph tables                             | 4 arrays        | —          |
| 75-78   | Media filters                            | 3               | —          |
| 80-85   | FZF options                              | 5               | —          |
| 87-124  | External commands                        | ~25             | —          |
| 126-139 | Deletion (with 3 commented alternatives) | 1               | —          |
| 141-147 | Display columns & aliases                | 2 + 1 array     | —          |
| 149-415 | Bindings                                 | 2 (leader/redo) | 226        |
| 413-415 | Auto-source binding plugins              | —               | (+34, +21) |

**Total:** ~75 user-tunable variables, ~30 external command names, 226 direct `bind` calls plus 55 from auto-sourced binding plugins = **~281 bindings** defined by default.

---

## 2. Section 1: Loader Sentinels & Locale (lines 1-2)

```bash
FTLRC_LOADED=1
LANG=C LC_ALL=C
```

### `FTLRC_LOADED=1`

- **Purpose:** Sentinel that tells downstream code (notably `etc/viewers/core:169`) that the ftlrc has been sourced. Without this, `viewers/core` thinks it's being sourced standalone (e.g. by `fzf_pane_preview`'s `previewd` subshell) and runs a bootstrap that re-sources `ftl_setup`.
- **Why a sentinel instead of a function check?** Because `viewers/core` may be sourced in a subshell where functions aren't exported. A variable is inherited via the environment if exported, but here it's not exported — it relies on subshell inheritance (Bash subshells inherit parent variables automatically).
- **Override guidance:** Never unset this in your own `ftlrc`. If you write a standalone script that sources `viewers/core`, set `FTLRC_LOADED=1` first if you want to skip the bootstrap.

### `LANG=C LC_ALL=C`

- **Purpose:** Force the C locale for the entire `ftl` process. This guarantees:
  - Deterministic `sort` output (byte-order, not locale-aware).
  - Deterministic `find` ordering.
  - `rg`/`grep` regexes use POSIX semantics.
  - No timezone-aware date formatting (dates come out as `MM/DD/YYYY-HH:MM` from `find -printf`).
- **Trade-off:** Non-ASCII filenames work but sort by byte value (`é` sorts after `z`). Locale-aware collation is unavailable.
- **Override guidance:** If you need locale-aware sorting (e.g. for a music library with accented artist names), set `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8` *after* the default `ftlrc` is sourced. Note that `generators/cbr` independently sets `LC_ALL=en_US.UTF-8` for its own subprocess.
- **Subtle behavior:** `LC_ALL` overrides `LANG`, so setting both is redundant but defensive.

---

## 3. Section 2: Directory Layout (lines 4-17)

```bash
# Directories
pgen="$FTL_CFG/etc/generators"          # location of preview generators
ftl_root=$FTL_CFG/var                   # runtime directory, every session gets a directory here
export ftl_root
mkdir -p $ftl_root

ftl_cmds=$ftl_root/cmds                 # history of shell commands
ghist=$ftl_root/history                 # global history file
touch $ftl_cmds $ghist

thumbs=$ftl_root/thumbs                 # where preview generators cache the previews
mkdir -p $thumbs                        # make sure the directory exists

help_command="man ftl.1"                # command to run to show help, see # Vim in man page
```

### `pgen="$FTL_CFG/etc/generators"`

- **Purpose:** Path to the generators directory. Every preview-generator script (`pdf`, `svg`, `mp4`, `stl`, `montage`, etc.) lives here. The batch driver is `$pgen/generator`, the single-file regenerator is `$pgen/generator_one`.
- **Override guidance:** Override only if you want to maintain your own generator set without forking the repo. Set `pgen="$HOME/.config/ftl/my-generators"` and put your scripts there.
- **Used by:** `etc/bin/ftl:55` (background thumbnail generation), `etc/viewers/core` (every `p*` and `ext_*` function), `etc/core/commands:170` (`preview_refresh`).

### `ftl_root=$FTL_CFG/var` (exported)

- **Purpose:** Root of the runtime data tree. Each `ftl` session creates `$ftl_root/$$/` for its private state. The global history file, persistent marks, and thumbnail cache also live under here.
- **Why exported:** So child processes (generators, `fsh` shell windows, subshells) can find it.
- **`mkdir -p $ftl_root`:** Defensive — ensures the directory exists. Idempotent.
- **Override guidance:** You might want to put this on a tmpfs for speed (`ftl_root=/dev/shm/ftl-var`), but then you lose persistent history and marks across reboots. A hybrid: `ftl_root=$HOME/.local/share/ftl` (XDG-compliant) — but then you should also update the `INSTALL` script.
- **Disk growth warning:** `$ftl_root/thumbs/` grows unbounded. There is no LRU, no max-size, no cleanup. After months of use this can be 10+ GB. The user is expected to `rm -rf $ftl_root/thumbs/*` manually.

### `ftl_cmds=$ftl_root/cmds`

- **Purpose:** File path for shell-command history (separate from directory-visit history).
- **`touch $ftl_cmds $ghist`:** Ensures both files exist (creates empty files if missing).
- **Usage:** **Never referenced elsewhere in the codebase.** This appears to be a vestigial or reserved variable. The actual command history is stored in `$ftl_root/cmd_history` (see `etc/core/ftl:19` — `cmd_prompt` uses `-H $ftl_root/cmd_history`). The `ftl_cmds` variable is unused.
- **Action item:** Either remove this variable or rename `$ftl_root/cmd_history` to `$ftl_cmds` for consistency.

### `ghist=$ftl_root/history`

- **Purpose:** Global directory-visit history file. Appended on every directory change (`hist_save()` in `etc/core/ftl:50`). Read by `ghistory*` commands.
- **Override guidance:** Set to a shared path (e.g. on a network filesystem) if you want history shared across machines. The file format is one path per line.
- **Subtle behavior:** The file grows unbounded. `ghistory_edit` lets you prune via fzf. `ghistory_clear` truncates it.

### `thumbs=$ftl_root/thumbs`

- **Purpose:** Root of the thumbnail/preview cache. Each generator creates a subdirectory per extension (e.g. `thumbs/pdf/`, `thumbs/svg/`). Files are named `<md5_of_source_path>_<basename>.<extmode>.<format>`.
- **`mkdir -p $thumbs`:** Defensive.
- **Override guidance:** Put on a fast SSD or tmpfs for snappier previews. Don't put on a network filesystem — the random small-file I/O will be painful.
- **Cleanup:** None automatic. See "Disk growth warning" under `ftl_root` above.

### `help_command="man ftl.1"`

- **Purpose:** Shell command run when the user presses `?` (`ftl_help` binding). Invoked either in a tmux popup (if `pop_help` is set — see §5) or directly in the preview pane.
- **Override guidance:** Replace with any command that displays help. Examples:
  - `help_command="glow $FTL_CFG/man/ftl.md"` — render the markdown source with `glow`.
  - `help_command="$EDITOR -R $FTL_CFG/man/ftl.md"` — open in vim read-only.
  - `help_command="bat --plain $FTL_CFG/man/ftl.md"` — with `bat`'s syntax highlighting.
- **Subtle behavior:** The man page (`ftl.1.gz`) is generated from `ftl.md` by `pandoc` (see `man/gen_man_pages`). If you haven't run `gen_man_pages`, `man ftl.1` will fail. The `INSTALL` script runs it for you.

---

## 4. Section 3: Bookmarks & Destinations (lines 19-25)

```bash
# Bookmarks
declare -A marks=([0]=/$ [1]="$HOME/$" [2]=/CHANGE_ME/dir/filename [3]=/CHANGE_ME/dir/filename [$"'"]="$(tail -n1 $ghist)")

declare -A dir_dest=()                  # directory destinations 1 letter alias

# User colors
# declare -A user_colors=([?]="30;42")  # override LS_COLORS
```

### `declare -A marks=(...)`

- **Purpose:** Per-session bookmarks. Keys are single characters (digits, `'`, letters). Values are paths ending in `$` for directories or no suffix for files.
- **The `$` suffix convention:** Used by `mark()` to decide whether to treat the destination as a directory (cd into it) or a file (select it). `mark()` in `etc/core/commands:107`:
  ```bash
  mark() { read -sn1 ; [[ -n $REPLY ]] && { [[ -d "${files[file]}" ]] && marks[$REPLY]="${files[file]}/$" || marks[$REPLY]="${files[file]}" ; } ; }
  ```
- **Defaults:**
  - `[0]=/$` — root directory.
  - `[1]="$HOME/$"` — home directory.
  - `[2]=/CHANGE_ME/dir/filename` — **placeholder, must be edited**.
  - `[3]=/CHANGE_ME/dir/filename` — **placeholder, must be edited**.
  - `[$"'"]="$(tail -n1 $ghist)"` — the `'` mark auto-points to the last-visited directory from global history.
- **The `'` mark is special:** `cview()` updates `marks["'"]="$n"` on every directory change, so `'` always points to the *previous* directory (not the global-history tail). The default value here is only the initial value before the first directory change.
- **Override guidance:** Replace the `CHANGE_ME` entries with your own common locations:
  ```bash
  declare -A marks=(
      [0]=/$
      [1]="$HOME/$"
      [2]="$HOME/projects/$"
      [3]="$HOME/downloads/$"
      [$"'"]="$(tail -n1 $ghist)"
  )
  ```
- **Adding more marks:** Add entries with keys `4`-`9` or letters. Note that single-letter marks collide with the `m<char>` / `'<char>` bindings, so choose letters that don't conflict with your other bindings.

### `declare -A dir_dest=()`

- **Purpose:** Single-letter aliases for "copy/move to destination" (`PP` / `PM` bindings). User populates this.
- **Empty by default:** The `PP`/`PM` bindings are useless until you add entries.
- **Override guidance:**
  ```bash
  declare -A dir_dest=(
      [1]="$HOME/downloads"
      [2]="$HOME/projects/active"
      [3]="/tmp"
  )
  ```
  Then `PP 1` copies the selection to `~/downloads`, `PM 2` moves to `~/projects/active`, etc.
- **Subtle behavior:** The key is read with `read -n 1`, so it must be a single character. Digits and letters work; punctuation may conflict with shell special characters.

### `# declare -A user_colors=([?]="30;42")`

- **Purpose (commented out):** Override `lscolors` for specific filenames. If a filename matches a key, that ANSI color is used instead of the `LS_COLORS` default.
- **The key `?`:** This is a literal `?` character — it would color any file matching `?` (which is every file, since `?` matches any single character in glob-speak — but this is associative array lookup, not glob, so it's the literal filename `?`).
- **Override guidance:** To override colors for specific files:
  ```bash
  declare -A user_colors=(
      [Makefile]="1;33"      # bold yellow
      [README.md]="1;36"     # bold cyan
      ["*.bak"]="2;37"       # dim white (this won't work — AA lookup is exact, not glob)
  )
  ```
  Note: the lookup is `user_colors[$cf]` where `$cf` is the exact filename, so globs don't work. You'd need to color each exact filename.
- **Used by:** `etc/core/dir_file_filter:16` — `user_color()` function, applied in the listing pipeline via `output_path`.

---

## 5. Section 4: Behavior Options (lines 27-60)

This is the largest config section — 25+ scalar options that control `ftl`'s runtime behavior.

```bash
# Options 
KEY_TIMEOUT=1                           # timeout between key presses
shell_h=40%                             # shell pane height
shell_v=60%                             # vertical shell pane width
auto_selection=1                        # automatically synch tags between panes
time_event=0                            # set to positive integer to trigger time events
pdhl=                                   # log pdh message in file too
dirmode=0                               # default directory mode
extmode=0                               # default preview mode
: ${prev_all:=1}                        # open preview window
zooms=(85 70 50 30)                     # sizes of preview pane in percent
zoom=1                                  # start zoom level
move_step=4                             # fast movement size
msg_m='Creating montage ...'            # message displayed when creating image montage for directories
msg_du='Computing dir sizes ...'        # message displayed when computing directory sizes
find_auto=README                        # file to select by default
line_color0="\e[2;40;90m"               # default line color
line_color="$line_color0"               # line color
line_color_hi="\e[38;5;240m"            # line color highlight
mount_archive=0                         # set if fuse-archive is installed
cursor_color0='\e[7;34m'                # default cursor color
cursor_color="$cursor_color0"           # cursor color
cursor_color_search='\e[7;35m'          # cursor color in interactive search
pop_help=0                              # show help in pop up
pop_kbindings=1                         # show bindings in pop up
quick_display=512                       # display entries during scanning if over this number
rfilter0=                               # default reverse filter, eg: rfilter0='\.sw.$'
show_line=1                             # show line (entry index)
show_size=0                             # 0:none, 1: file sizes, 2: file sized + dir entries, 3: file sizes + dir sized recursive
show_date=1                             # show date in header if sort mode is by date
show_tar=0                              # show extra information about tar file, takes time
tag_new_tab=                            # in copy/move to tab, default new tab location if no other tab exists
tbcolor 67 67                           # set tmux separation line color
TBCOLORS='236 52'
```

### `KEY_TIMEOUT=1`

- **Purpose:** Seconds for `read -rsn 1 -t $KEY_TIMEOUT` in the main loop. After 1 second with no input, `read` returns failure (`ERROR_142`), which lets `time_event` and `winch` fire.
- **Override guidance:**
  - `KEY_TIMEOUT=0.1` — more responsive time events, but uses more CPU (the loop spins 10x/second even when idle).
  - `KEY_TIMEOUT=5` — less CPU, but time events lag up to 5 seconds.
- **Subtle behavior:** Fractional timeouts work in Bash 5+. The `1` second default is a reasonable balance.

### `shell_h=40%` / `shell_v=60%`

- **Purpose:** Size of the shell pane when spawned horizontally (`Ss`) or vertically (`Sv`). Passed as tmux `-l` size specs.
- **Override guidance:** Adjust to your screen size. `shell_h=50%` for equal split. `shell_h=30%` if you want the shell small and the listing large.
- **Subtle behavior:** These are tmux size specs, so they accept `%`, absolute numbers, or tmux's other size formats.

### `auto_selection=1`

- **Purpose:** When non-zero, the selection (`tags`) is automatically synchronized between panes — if another pane has a newer `stagsi` counter, this pane sources its serialized tags.
- **Override guidance:** Set to `0` if you want panes to have independent selections (useful for complex multi-pane workflows where you're selecting different things in different panes).
- **Subtle behavior:** The sync is one-way (from the pane with the higher counter to the one with the lower). If two panes both modify selection simultaneously, the last writer wins.

### `time_event=0`

- **Purpose:** If positive, the main loop calls all functions in `time_event_handlers` every `time_event` seconds. Default `0` disables time events.
- **Override guidance:** Set to `5` or `10` if you have time-event handlers (e.g. periodic auto-refresh, status updates).
- **Subtle behavior:** The granularity is `KEY_TIMEOUT` seconds — the loop only checks `time_event` after each `read` timeout. So with `KEY_TIMEOUT=1` and `time_event=5`, handlers fire every 5 seconds (±1 second).

### `pdhl=`

- **Purpose:** If set to a file path, `pdh()` (the debug-message function) also logs messages to that file. Useful for headless debugging.
- **Override guidance:** `pdhl=/tmp/ftl-debug.log` to capture all `pdh` messages.
- **Subtle behavior:** The file is appended to (not truncated). The `pdh()` function in `etc/core/ftl:75`:
  ```bash
  pdh() { ((pdhl)) && echo "$$ $my_pane: $1" >>ftl_log ; ... }
  ```
  Note: the `>>ftl_log` is a relative path, not `$pdhl` — **this looks like a bug**. The `pdhl` variable is used as a boolean flag (truthy/non-empty), but the log file is hardcoded to `ftl_log` in the current directory. The intended behavior was probably `>>"$pdhl"`.

### `dirmode=0` / `extmode=0`

- **Purpose:** Default directory-preview mode (0=ftl, 1=du, 2=ls, 3=README, 4=exa, 5=image-montage) and default external-preview mode (0=default, 1-5=alternative).
- **Override guidance:** Set `dirmode=3` if you prefer README previews by default. Set `extmode=1` if you prefer the first alternative preview.
- **Subtle behavior:** `dirmode` is overridden per-directory by `.ftlrc_dir`. `extmode` is reset to 0 after each preview dispatch (it's a transient mode, not a sticky preference).

### `: ${prev_all:=1}`

- **Purpose:** Open the preview pane by default. The `: ${var:=default}` idiom sets `prev_all=1` only if it's not already set — so users can `export prev_all=0` before launching ftl to start without a preview.
- **Override guidance:** `prev_all=0` to start without preview. Toggle at runtime with `zv`.
- **Subtle behavior:** The `:=` syntax means you can override via environment variable: `prev_all=0 ftl`.

### `zooms=(85 70 50 30)` / `zoom=1`

- **Purpose:** Available preview-pane widths as percentages of the pane. `zoom` is the index into `zooms`. `z+` cycles.
- **Override guidance:** Add more sizes: `zooms=(90 80 70 60 50 40 30 20)`. Or fewer: `zooms=(70 50)` for a simpler cycle.
- **Subtle behavior:** `zoom=1` means the default preview width is `70%` (the second element). The first element (`85%`) is the "almost no preview" mode.

### `move_step=4`

- **Purpose:** Number of entries to move in `move_down_step` / `move_up_step`.
- **Subtle behavior:** These commands are **not bound by default** (see commented-out lines 260-261). The variable exists but is unused unless you bind it yourself:
  ```bash
  bind ftl move J move_down_step "move down multiple lines"
  bind ftl move K move_up_step "move up multiple lines"
  ```
  But this conflicts with the existing `J`/`K` bindings for preview scrolling. See the bindings analysis document for a proposed resolution.

### `msg_m` / `msg_du`

- **Purpose:** Status messages flashed in the header during long operations (montage generation, dir-size computation).
- **Override guidance:** Translate to your language, or make them more/less verbose.

### `find_auto=README`

- **Purpose:** When entering a directory for the first time (no remembered cursor), `ftl` auto-selects this file if present.
- **Override guidance:** `find_auto=Makefile` if you're a C developer. `find_auto=Cargo.toml` if Rust. `find_auto=package.json` if Node.
- **Subtle behavior:** Only matches by basename. If the file doesn't exist, falls back to the first entry.

### `line_color0` / `line_color` / `line_color_hi`

- **Purpose:** ANSI codes for the entry-index column. `line_color0` is the default, `line_color` is the current (swappable), `line_color_hi` is used during `goto_entry` prompt.
- **Override guidance:** Change colors to match your terminal theme. Examples:
  ```bash
  line_color0="\e[2;90m"        # dim grey (default)
  line_color_hi="\e[1;33m"      # bold yellow (highlight)
  ```
- **Subtle behavior:** `line_color` is mutated during `goto_entry` and restored after. Don't set it directly — set `line_color0` instead.

### `mount_archive=0`

- **Purpose:** If `1`, the `type_handlers` binding mounts archives (zip, rar, tar, etc.) via `fuse-archive` on `enter`.
- **Override guidance:** Set to `1` if you have `fuse-archive` installed. The `INSTALL` script shows how to install it.
- **Subtle behavior:** The `type_handlers` binding file must be sourced (it is, by default, via the auto-source loop on line 414). The mounted archives use `fuse-archive -o allow_other`, which exposes them to other users — a security concern in multi-user environments.

### `cursor_color0` / `cursor_color` / `cursor_color_search`

- **Purpose:** ANSI codes for the cursor (the tag glyph of the current entry). Same pattern as `line_color*`.
- **Override guidance:** Change to match your theme. `cursor_color_search` is the color during incremental search.

### `pop_help=0` / `pop_kbindings=1`

- **Purpose:** Whether to show help (`?`) and bindings (`c`) in a tmux popup (`1`) or in the preview pane (`0`).
- **BUG:** `ftl_help()` in `etc/core/commands:13` checks `help_pop`, not `pop_help`:
  ```bash
  ftl_help() { ((help_pop)) && { tmux popup ... } || { ... } ; }
  ```
  So `pop_help` has no effect. To actually get popup help, you'd need to set `help_pop=1` (which is never referenced in the default config). **This is a bug.**

### `quick_display=512`

- **Purpose:** Threshold for "quick display" mode. While scanning a directory, every 512 entries, `ftl` flashes the running count in red on the header. Set to `0` to disable.
- **Override guidance:** `quick_display=100` for more frequent updates (useful on slow filesystems). `quick_display=0` to disable (no progress indication during scan).
- **Subtle behavior:** This is purely cosmetic — it doesn't affect the actual listing speed.

### `rfilter0=`

- **Purpose:** Default reverse-filter regex applied to every tab. Empty means no reverse filter.
- **Override guidance:** `rfilter0='\.sw.$'` to always hide vim swap files. `rfilter0='\.o$|\.obj$'` to hide build artifacts.
- **Subtle behavior:** This is the *default* for new tabs. The `clear_filters` command restores `rfilters[tab]="$rfilter0"`. So if you change `rfilter0` at runtime, existing tabs keep their old `rfilters`.

### `show_line=1` / `show_size=0` / `show_date=1` / `show_tar=0`

- **Purpose:** Display toggles.
  - `show_line`: entry-index column (1=on, 0=off).
  - `show_size`: cycles 0→1→2→3 (none / file sizes / file+dir-entry-counts / file+recursive-dir-sizes).
  - `show_date`: show date in header when sort mode is by date.
  - `show_tar`: show extra tar info (slow).
- **Override guidance:** `show_line=0` if you find the index column noisy. `show_size=1` if you always want file sizes.
- **Subtle behavior:** `show_size=3` triggers `dir_dusize()` which runs `du -h` on every directory — expensive on large trees.

### `tag_new_tab=`

- **Purpose:** Default location for "copy/move to other tab" when there's only one tab. If empty, `$HOME` is used.
- **Override guidance:** `tag_new_tab=$HOME/projects` to default new tabs to your projects directory.

### `tbcolor 67 67` / `TBCOLORS='236 52'`

- **Purpose:** `tbcolor` is a *function call* (defined in `etc/core/ftl:170`) that sets tmux pane border colors. It's called at startup with args `67 67` (border=67, active border=67). `TBCOLORS` is the value restored on quit (`quit2` calls `tbcolor $TBCOLORS`).
- **Subtle behavior:** `67` is a 256-color code (medium grey-blue). `TBCOLORS='236 52'` is dark grey + dark red — the default tmux colors. So at startup, ftl sets both border and active-border to `67` (uniform), and on quit restores to `236 52` (which is what most tmux users have).
- **Override guidance:** Change `67 67` to your preferred colors. Change `TBCOLORS` to your tmux session's default border colors so quit restores them correctly.

---

## 6. Section 5: External Tags (lines 62-67)

```bash
# External Tags
etag=0                                  # show etags
#. $FTL_CFG/etc/etags/git ; etag=1      # if you want to show git tags by default

sort_type0=0                            # default sort. 0: alphanumeric, 1: size, 2: date.
sort_reversed0=                         # default reverse sort order
```

### `etag=0`

- **Purpose:** Master toggle for the etag column. When `0`, no etags are computed. When `1`, the current etag source (`etag_s`) is invoked.
- **Override guidance:** Set `etag=1` and source an etag file to enable by default:
  ```bash
  etag=1
  . $FTL_CFG/etc/etags/git
  ```
- **Subtle behavior:** The commented-out line `. $FTL_CFG/etc/etags/git ; etag=1` does both — sources the git etag (which defines `etag_dir`/`etag_tag`) and enables it. Note: this is the *default* etag; the user can switch at runtime with `zT` (etag_select).

### `sort_type0=0` / `sort_reversed0=`

- **Purpose:** Default sort type (0=alphanumeric, 1=size, 2=date) and reversed flag (`-r` or empty).
- **Override guidance:** `sort_type0=2 ; sort_reversed0=-r` to default to reverse-chronological (newest first) — useful for download directories.
- **Subtle behavior:** These are *defaults* applied to new tabs. Per-tab overrides via `sort_type[tab]`/`reversed[tab]` take precedence. The `.ftlrc_dir` file can also override per-directory.

---

## 7. Section 6: Glyph Tables (lines 69-73)

```bash
# Glyphs
sglyph=( ⍺ 🡕 )                          # sorting: alphanumeric, size
iglyph=('' ᴵ ᴺ)                         # image mode: all, no-image, image
lglyph=('' ᵈ ᶠ)                         # preview: all, directory-only, file-only
tglyph=('' ¹ ² ³ D)                     # tag classes 
```

### `sglyph=( ⍺ 🡕 )`

- **Purpose:** Sort-type glyphs shown in the header. Index 0=alphanumeric (`⍺`), 1=size (`🡕`).
- **Note:** The array has only 2 entries, but `sort_type` can be 0, 1, or 2 (date). Index 2 has no glyph — when sorting by date, no glyph is shown. **This is a bug or oversight** — `sglyph` should have 3 entries.
- **Override guidance:** Add a date glyph: `sglyph=( ⍺ 🡕 📅 )`.

### `iglyph=('' ᴵ ᴺ)`

- **Purpose:** Image-mode glyphs. Index 0=all (empty), 1=no-image (`ᴵ`), 2=image-only (`ᴺ`).
- **Subtle behavior:** Empty string for "all" means no glyph is shown — the default mode is invisible.

### `lglyph=('' ᵈ ᶠ)`

- **Purpose:** Listing-mode glyphs. Index 0=all (empty), 1=dir-only (`ᵈ`), 2=file-only (`ᶠ`).

### `tglyph=('' ¹ ² ³ D)`

- **Purpose:** Tag-class glyphs. Index 0=unused (default tag is `▪`), 1-4 are the four selectable classes (`¹`/`²`/`³`/`D`).
- **Subtle behavior:** Index 0 is unused because the default tag glyph is hardcoded as `▪` in `tag_flip`/`tag_set`:
  ```bash
  tag_flip() { ((stagsi++)) ; [[ "${tags[$1]}" ]] && { ... } || { tags[$1]=${2:-▪} ; ... } ; }
  ```
  The `${2:-▪}` means "use argument 2, or `▪` if not given". So `tglyph[0]` is never consulted.

---

## 8. Section 7: Media Filters (lines 75-78)

```bash
# Media Filters
ifilter='svg|webp|jpg|jpeg|JPG|png|gif|bmp'     # images
mfilter='mp3|mp4|flv|mkv|webm'                  # video
pdf_prev_image=0                                # show pdf as images if set
```

### `ifilter='svg|webp|jpg|jpeg|JPG|png|gif|bmp'`

- **Purpose:** Extended regex matching image file extensions. Used by `pviewers`/`ext_viewers` to dispatch to image previewers, by `view_mode_image`/`not_image` to filter the listing, and by `image_size` etag to find images.
- **Coverage:** svg, webp, jpg/jpeg (both cases for jpg), png, gif, bmp.
- **Missing:** tiff, heic, avif, jxl, ico, psd, xcf, cr2 (raw), nef (raw), etc.
- **Override guidance:** Add modern formats: `ifilter='svg|webp|jpg|jpeg|JPG|png|gif|bmp|tiff|tif|heic|avif|jxl|ico'`.
- **Subtle behavior:** The regex is passed to `rg` and to bash `[[ =~ ]]`. Both use POSIX ERE. The `JPG` uppercase is redundant if you use `rg -i` (which ftl doesn't by default).

### `mfilter='mp3|mp4|flv|mkv|webm'`

- **Purpose:** Regex matching media (video/audio) file extensions.
- **Coverage:** mp3, mp4, flv, mkv, webm.
- **Missing:** avi, mov, wmv, m4v, m4a, ogg, opus, flac, wav, aac, ts, m2ts.
- **Override guidance:** Expand: `mfilter='mp3|mp4|flv|mkv|webm|avi|mov|wmv|m4v|m4a|ogg|opus|flac|wav|aac|ts|m2ts'`.

### `pdf_prev_image=0`

- **Purpose:** If `1`, PDFs are previewed as PNG images (via `mutool draw` + `w3mimgdisplay`) instead of text.
- **Override guidance:** Set to `1` if you prefer visual PDF previews. Toggle at runtime with `zmp`.

---

## 9. Section 8: FZF Options (lines 80-85)

```bash
# FZF Options
fzf_opt="-p 90% --cycle --reverse --info=inline --color=hl+:214,hl:214"
fzfp_opt="--cycle --expect=ctrl-t --reverse"
fzf_sxiv_opt="-0 -1 -m --expect=ctrl-t --bind alt-a:select-all"
FZF_LISTEN=4466
FZF_LISTEN_COMMAND='fd -H -I' # -E '*.git'
```

### `fzf_opt` / `fzfp_opt` / `fzf_sxiv_opt`

- **Purpose:** Reusable fzf option strings.
  - `fzf_opt`: popup-style fzf (90% of screen, cycle, reverse layout, inline info, orange highlights).
  - `fzfp_opt`: pane fzf (cycle, ctrl-t to open in new tab, reverse).
  - `fzf_sxiv_opt`: sxiv integration (no preview window, single-select by default, multi with `-m`, ctrl-t, alt-a for select-all).
- **Override guidance:** Customize the colors: `fzf_opt="-p 90% --cycle --reverse --info=inline --color=hl+:blue,hl:blue"` for blue highlights.
- **Subtle behavior:** These are passed unquoted to fzf, so they undergo word-splitting. Don't put spaces inside option values (e.g. `--color='hl+:blue'` is fine, but `--color="hl+: light blue"` would break).

### `FZF_LISTEN=4466` / `FZF_LISTEN_COMMAND='fd -H -I'`

- **Purpose:** Used by the experimental `fzf_search` binding (`V` key) which runs `fzf --listen` on port `FZF_LISTEN` and polls it via `xh` (HTTP). `FZF_LISTEN_COMMAND` is the default command fzf runs to list files.
- **Subtle behavior:** Port `4466` is arbitrary — if it conflicts, change it. The `fzf_search` binding is loaded from `etc/bindings/fzf_search` and is experimental (the `V` binding).
- **Override guidance:** `FZF_LISTEN_COMMAND='fd -H -I -E .git -E node_modules'` to exclude common noise directories.

---

## 10. Section 9: External Commands (lines 87-124)

This section names the external programs `ftl` invokes. All are user-overridable. The full table:

| variable          | default                                    | line   | notes                                                                    |
| ----------        | ---------                                  | ------ | -------                                                                  |
| `SXIV`            | `sxiv`                                     | 88     | Image viewer. Alt: `nsxiv`.                                              |
| `GIF_VIEWER`      | (empty)                                    | 89     | Recommended: `pixelhopper`. Empty means GIFs show first frame only.      |
| `EDITOR`          | `"vim -p"`                                 | 90     | `-p` opens files in tabs. Alt: `nvim`, `emacs -nw`.                      |
| `FILE_DIFF`       | `vimdiff`                                  | 91     | Two-file diff. Alt: `meld` (GUI), `delta` (with `git diff`).             |
| `FTLI_CLEAN`      | `1`                                        | 93     | Set to `0` if using konsole (image-preview cleanup behavior).            |
| `FTLI_H`          | `21`                                       | 94     | Character height in pixels — hint to `ftli` for image positioning.       |
| `FTLI_W`          | `10`                                       | 95     | Character width in pixels.                                               |
| `FTLI_Z`          | `0`                                        | 96     | Image zoom (0=fit, 1=actual size).                                       |
| `GPGID`           | `CHANGE.ME`                                | 98     | **Must be changed** — your GPG key ID for `\fe` encryption.              |
| `G_PLAYER`        | `"vlc -f"`                                 | 100    | GUI media player (`-f` = fullscreen).                                    |
| `T_PLAYER`        | `"mplayer -vo null"`                       | 101    | Terminal media player (no video output — audio only).                    |
| `TE_PLAYER`       | `"vlc -I curses"`                          | 102    | Terminal-external media player (curses UI).                              |
| `T_PLAYER_STATUS` | (mplayer with statusline)                  | 103    | Live-preview media player with status line.                              |
| `B_PLAYER`        | `"$FTL_CFG/etc/viewers/mplayer_local"`     | 104    | Background player script.                                                |
| `Q_PLAYER`        | `"$FTL_CFG/etc/viewers/cmus"`              | 105    | Music queue player script (cmus).                                        |
| `PAGER_ANSI`      | `'/usr/bin/less -R'`                       | 107    | Pager for ANSI-colored output.                                           |
| `MD_PAGER`        | `'/usr/bin/less -R'`                       | 109    | Markdown preview pager. Alt: `moar --no-statusbar --no-linenumbers`.     |
| `MD_RENDER0`      | `'ptext'`                                  | 110    | Default markdown renderer (plain text).                                  |
| `MD_RENDER1`      | `'vmd'`                                    | 111    | Markdown renderer mode 1. Alt: `lowdown -Tterm`.                         |
| `MD_RENDER2`      | `'vmd'`                                    | 112    | Markdown renderer mode 2.                                                |
| `$MD_DIR_RENDER`  | `"vmd"`                                    | 113    | **BUG**: leading `$` makes this a command invocation, not an assignment. |
| `HEXVIEW`         | `hexdump`                                  | 115    | Hex viewer. Alt: `xxd`, `hexyl`.                                         |
| `HEXEDIT`         | `hexedit`                                  | 116    | Hex editor. Alt: `bvi`, `ghex` (GUI).                                    |
| `MIMETYPE`        | `mimemagic`                                | 118    | Mime-type detection command.                                             |
| `NCDU`            | `ncdu`                                     | 119    | Disk-usage viewer. Alt: `gdu`, `tdu`, `dust`.                            |
| `JSON_VIEWER`     | `jless`                                    | 120    | JSON viewer. Alt: `jq`, `fx`, `jid`.                                     |
| `YAML_VIEWER`     | `"yam -i"`                                 | 121    | YAML viewer. Alt: `yj`, `yaml2json \                                     | jless`. |
| `EXA_COLORS`      | (long string)                              | 123    | Color config for `exa`.                                                  |
| `EXA_OPTIONS`     | `"-l --tree -L 3 --header --color=always"` | 124    | Options for `exa` directory preview.                                     |

### Notable issues

- **`GPGID=CHANGE.ME`** — must be edited or `\fe` (GPG encrypt) will fail. The default is a placeholder.
- **`$MD_DIR_RENDER="vmd"`** (line 113) — **this is a bug**. The leading `$` causes Bash to interpret `MD_DIR_RENDER` as a command (which doesn't exist) with `="vmd"` as an argument — actually, no: `$MD_DIR_RENDER` expands to empty (since the variable is unset), so the line becomes `="vmd"` which is a syntax error... actually no: the line is `$MD_DIR_RENDER="vmd"` which Bash parses as a command `=` with args `"vmd"` and `MD_DIR_RENDER` set as a temporary env var. Wait, let me re-read: `$MD_DIR_RENDER="vmd"` — the `$` causes `MD_DIR_RENDER` to be expanded (to empty), so the line becomes `="vmd"`. This is a command `=` with argument `vmd` (after quote removal). The `=` command doesn't exist, so Bash tries to execute `=vmd` as a command, which fails. The variable `MD_DIR_RENDER` is never set. The fix is to remove the `$`: `MD_DIR_RENDER="vmd"`.
- **`GIF_VIEWER=`** (empty) — animated GIFs show only the first frame. Install `pixelhopper` (per the comment) and set `GIF_VIEWER=pixelhopper` for animation.

### Override patterns

```bash
# Modern editor setup
EDITOR="nvim -p"
FILE_DIFF="delta"

# Modern hex tools
HEXVIEW="hexyl"                    # prettier output
HEXEDIT="bvi"                      # binary vim

# Modern disk usage
NCDU="gdu"                         # faster than ncdu

# Modern JSON/YAML
JSON_VIEWER="fx"                   # interactive TUI
YAML_VIEWER="yj -ji \| jless"      # convert to JSON first

# Markdown rendering
MD_PAGER="moar --no-statusbar --no-linenumbers"
MD_RENDER1="lowdown -Tterm"
MD_RENDER2="glow -s dark"
```

---

## 11. Section 10: Deletion (lines 126-139)

```bash
# Deletion command
RM="rm -rf"

# using rm-improved
# RM="rip --graveyard '$HOME/graveyard'" ; mkdir -p $HOME/graveyard
# bind ftl file U       unbury          "undo last deletion in current directory"
# unbury() { last_bury="$(rip --graveyard $HOME/graveyard -s | tail -n1)" ; [[ -n "$last_bury" ]] && { rip --graveyard $HOME/graveyard -u ; cdir "$PWD" "$(basename "$last_bury")" ; } ; } 

# using FreeDesktop.org Trash 
# RM="trash-put"

# using your own delete function
# my_delete() { echo my_delete ; printf "%s\n" "$@" ; read -sn1 ; }
# RM=my_delete
```

### `RM="rm -rf"`

- **Purpose:** The deletion command. Used by `delete_cur` and `delete_tag` in `etc/core/ftl:29-30`.
- **Default is destructive:** `rm -rf` is irreversible. **This is a significant risk** — a single accidental `d` + `y` deletes files permanently.
- **Three commented alternatives:**

1. **`rip` (rm-improved):** Sends deleted files to a "graveyard" directory, from which they can be recovered. Includes an `unbury` function and a `U` binding to undo the last deletion.

2. **`trash-put` (FreeDesktop.org Trash):** Sends files to the system trash, compatible with KDE/GNOME/other file managers' trash.

3. **Custom function:** Define `my_delete()` and set `RM=my_delete`. The function receives the files as arguments.

- **Recommendation:** **Always override `RM`** to use trash or graveyard. The default `rm -rf` is dangerous. Example:
  ```bash
  RM="trash-put"
  # or
  RM="rip --graveyard '$HOME/.local/share/ftl-graveyard'"
  mkdir -p "$HOME/.local/share/ftl-graveyard"
  bind ftl entry U unbury "undo last deletion"
  unbury() {
      last_bury="$(rip --graveyard "$HOME/.local/share/ftl-graveyard" -s | tail -n1)"
      [[ -n "$last_bury" ]] && {
          rip --graveyard "$HOME/.local/share/ftl-graveyard" -u
          cdir "$PWD" "$(basename "$last_bury")"
      }
  }
  ```

---

## 12. Section 11: Display & Aliases (lines 141-147)

```bash
CMD_COLS=150                            # columns when displaying command mapping in popup

# Command aliases
declare -A cmd_aliases=([csx]="split finfo | xargs -0" [cfx]="full finfo | xargs -0")

# preview
source "$FTL_CFG/viewers/core"
```

### `CMD_COLS=150`

- **Purpose:** Column width when displaying the binding table (via `k_bgen` → `column -t -c $CMD_COLS`).
- **Override guidance:** Increase if you have long binding descriptions and a wide terminal. Decrease for narrow terminals.

### `declare -A cmd_aliases=([csx]="split finfo | xargs -0" [cfx]="full finfo | xargs -0")`

- **Purpose:** Aliases for the command prompt (`:`). `csx ls -l` expands to `split finfo | xargs -0 ls -l`.
- **Defaults:**
  - `csx` → `split finfo | xargs -0` — split window, run command on each selected file.
  - `cfx` → `full finfo | xargs -0` — full screen, run command on all selected files at once.
- **Override guidance:** Add your own:
  ```bash
  declare -A cmd_aliases=(
      [csx]="split finfo | xargs -0"
      [cfx]="full finfo | xargs -0"
      [csg]="split finfo | xargs -0 git add"  # add selection to git
      [cgr]="split finfo | xargs -0 rg"       # ripgrep in selection
  )
  ```

### `source "$FTL_CFG/viewers/core"`

- **Purpose:** Load the preview dispatcher. This defines `pviewers`, `ext_viewers`, and all the `p*`/`ext_*` functions.
- **Subtle behavior:** This is sourced *before* the bindings, so the viewer functions are available when bindings like `ee` (external_mode1) are defined.
- **Override guidance:** You can source additional viewer files here:
  ```bash
  source "$FTL_CFG/viewers/core"
  source "$FTL_CFG/viewers/my-custom-viewer"
  ```

---

## 12. Section 12: Bindings (lines 149-415)

This section is 266 lines and contains 226 `bind` calls. It's covered in detail in the separate **Bindings Analysis** document. Here's the structural overview:

```bash
# Bindings
redo_key='.'
leader_key='BACKSLASH'
```

### `redo_key='.'` / `leader_key='BACKSLASH'`

- **Purpose:** `redo_key` is the key that re-runs the last command (excludes movement). `leader_key` is the prefix for multi-key bindings.
- **Override guidance:**
  - `leader_key=SPACE` — use space as leader (conflicts with the `SPACE` binding, if any).
  - `redo_key=','` — comma for redo (conflicts with nothing by default).
- **Subtle behavior:** These are token names from the `get_key` normalizer, not raw characters. `BACKSLASH` corresponds to `\`, `SPACE` to ` ` (space), etc.

### Binding sections

The 226 binds are organized into 14 sections:

| section | # binds | line range | purpose |
|---------|---------|------------|---------|
| `ftl ftl` | 10 | 153, 210-221 | Core ftl commands (help, quit, command prompt, pdh) |
| `ftl entry` | 27 | 155-181 | File/directory operations (delete, create, copy, move, chmod, hex, vim, link) |
| `ftl filter` | 7 | 183-189 | Listing filters |
| `ftl find` | 18 | 191-208 | Search (find, fzf, ripgrep) |
| `ftl history` | 6 | 223-228 | History navigation |
| `ftl marks` | 7 | 230-236 | Bookmarks |
| `ftl media` | 7 | 238-244 | Media playback |
| `ftl move` | 32 | 246-282 | Movement (arrows, vim keys, page, goto) |
| `ftl pane` | 7 | 284-290 | Pane splitting |
| `ftl shell` | 18 | 292-309 | Shell pane management |
| `ftl tabs` | 5 | 311-315 | Tab management |
| `ftl selection` | 31 | 317-353 | Selection (tag, untag, classes, fzf) |
| `ftl view` | 48 | 355-402 | View modes (zoom, sort, filter, preview modes) |
| `ftl SIG` | 3 | 219, 409-410 | Internal signals (reserved) |

### Auto-sourced binding plugins (lines 413-415)

```bash
# Extra Bindings
for b in $(fd  . "$FTL_CFG/etc/bindings" --type f | sort -u) ; do source "$b" ; done
for b in $(fd  . "$FTL_CFG/bindings" --type f | sort -u) ; do source "$b" ; done
```

- **Purpose:** Auto-source all binding files from two directories:
  1. `$FTL_CFG/etc/bindings/` — the default plugin set (8 files, 34 binds).
  2. `$FTL_CFG/bindings/` — user-defined bindings (8 files, 21 binds by default, but this is where you drop your own).
- **Subtle behavior:** `fd --type f` lists regular files. `sort -u` deduplicates. Files are sourced in alphabetical order. All files are sourced — there's no opt-out mechanism.
- **Override guidance:** To disable a default binding plugin, either delete the file or rename it (e.g. `tmsu` → `tmsu.disabled`). To add your own, drop a file in `$FTL_CFG/bindings/`.

### Reserved keys (line 408)

```bash
# don't change, reserved for *ftl*: [ÅåÄä]
```

- **Purpose:** `å` and `Ä` are used as IPC signals between panes. `Å` and `ä` are reserved for future use. Don't bind these.

---

## 13. Cross-Cutting Observations

### 13.1 The `0`/empty duality

Many `ftl` variables treat `0` and empty as falsy. This is Bash's default behavior, but it means:
- `etag=0` and `etag=` are equivalent (both disable etags).
- `mount_archive=0` and `mount_archive=` are equivalent.
- `time_event=0` and `time_event=` are equivalent.

But some variables distinguish:
- `reversed[tab]` can be `-r`, `0`, or empty — and `cview` checks all three:
  ```bash
  [[ "${reversed[tab]}" == "-r" ]] && s_reversed=-r || { [[ "${reversed[tab]}" == "0" ]] && s_reversed= ; }
  ```
  So `0` means "explicitly not reversed" (clears `s_reversed`), while empty means "use the default" (leaves `s_reversed` as `sort_reversed0`).

### 13.2 The `${var:-default}` idiom

Several variables use `:-` to provide defaults at use-time rather than declaration-time:
- `: ${prev_all:=1}` — set if unset.
- `${depth[tab]:-1}` — default to 1 if unset.
- `${COUNT:-1}` — default to 1 if no count given.
- `${zooms[zoom]}` (no default) — relies on `zoom` always being set.

### 13.3 The `ftlrc_not_so_vim_like` alternative

The file `etc/ftlrc_not_so_vim_like` is an older, less-vim-like binding set. It's described as "older and not maintained". It uses AltGr characters heavily (via `${A[...]}` and `${SA[...]}`) instead of multi-key sequences. It's a reference for alternative binding schemes, not a recommended replacement.

### 13.4 The `.ftlrc_dir` per-directory override

Not in `ftlrc` itself, but referenced by `cview()`:
```bash
[[ -f .ftlrc_dir ]] && source .ftlrc_dir
```
If a directory contains a `.ftlrc_dir` file, it's sourced on every entry. This lets you set per-directory defaults like `sort_type[tab]=2 ; reversed[tab]=-r` for a downloads directory. A template is at `etc/commands/ftlrc_dir/reverse_date`.

---

## 14. Bugs, Smells, and Improvement Opportunities

### 14.1 Confirmed bugs

1. **`$MD_DIR_RENDER="vmd"` (line 113)** — leading `$` makes this a command invocation, not an assignment. The variable `MD_DIR_RENDER` is never set. Fix: remove the `$`.

2. **`pop_help` vs `help_pop` (line 50 vs `etc/core/commands:13`)** — `ftlrc` defines `pop_help`, but `ftl_help()` checks `help_pop`. The `pop_help` variable has no effect. Fix: rename one to match the other.

3. **`pdhl` log file (line 33 vs `etc/core/ftl:75`)** — `ftlrc` says "log pdh message in file too", but `pdh()` writes to `ftl_log` (relative path), not to `$pdhl`. The `pdhl` variable is used as a boolean flag only. Fix: `pdh()` should write to `>>"$pdhl"` if `pdhl` is set.

4. **`ftl_cmds` unused (line 10)** — the variable is defined and the file is touched, but never referenced. The actual command history is in `$ftl_root/cmd_history`. Fix: either use `ftl_cmds` or remove it.

5. **`sglyph` missing date entry (line 70)** — `sglyph=( ⍺ 🡕 )` has 2 entries, but `sort_type` can be 0/1/2. When sorting by date, no glyph is shown. Fix: `sglyph=( ⍺ 🡕 📅 )`.

### 14.2 Code smells

1. **Hardcoded paths** — `PAGER_ANSI='/usr/bin/less -R'` and `MD_PAGER='/usr/bin/less -R'` hardcode `/usr/bin/less`. On systems where `less` is elsewhere (e.g. `/bin/less` on some distros, or Homebrew's `/opt/homebrew/bin/less`), these fail. Fix: `PAGER_ANSI='less -R'` (let PATH resolve it).

2. **Inconsistent quoting** — some assignments quote, some don't: `KEY_TIMEOUT=1` (no quotes) vs `shell_h=40%` (no quotes) vs `find_auto=README` (no quotes) vs `msg_m='Creating montage ...'` (quotes). The rule: quote if the value contains spaces or special characters. The current file is mostly consistent but has a few oddities.

3. **Commented-out code** — lines 131-132 (the `unbury` function), lines 260-261 (`move_down_step`/`move_up_step` bindings), lines 352-353 (`selection_merge`), lines 404-406 (`preview_tail`/`preview_lock`). These should either be uncommented (if useful) or removed (if not).

4. **Placeholder defaults** — `marks[2]=/CHANGE_ME/dir/filename` and `marks[3]=/CHANGE_ME/dir/filename` and `GPGID=CHANGE.ME`. These are placeholders that users must edit. A startup warning would help (but `ftl` has no startup warning system).

### 14.3 Improvement opportunities

1. **Add a `ftlrc.local` mechanism** — let users drop overrides in `~/.config/ftl/ftlrc.local` that's sourced after the default, so they don't need to copy the whole file. Currently the pattern is "source the default then override", which requires the user to know the default exists.

2. **Validate external commands** — at startup, check that `EDITOR`, `SXIV`, `MIMETYPE`, etc. are installed. If not, warn the user. Currently missing commands cause silent failures.

3. **Thumbnail cache cleanup** — add a `thumbs_max_size` variable and a cleanup routine that evicts oldest entries when the cache exceeds the limit.

4. **Profile-based defaults** — offer preset profiles (e.g. `profile=developer`, `profile=photographer`, `profile=minimal`) that set sensible defaults for different user types.

5. **Per-project `.ftlrc_dir` recipes** — ship templates for common project types (git project, node project, rust project) that set appropriate `find_auto`, `rfilter0`, etc.

---

## 15. Reference: Variable Index by Category

### Path variables
`FTL_CFG`, `pgen`, `ftl_root`, `ftl_cmds` (unused), `ghist`, `thumbs`, `ftl_info_file`, `ftl_main_info_file`, `fs`, `pfs`, `ofs`, `fsp`

### Toggles (0/1)
`auto_selection`, `etag`, `mount_archive`, `pdf_prev_image`, `pop_help` (broken), `pop_kbindings`, `show_date`, `show_line`, `show_tar`, `time_event`, `in_Q`, `keep_shell`, `session_shell`, `gpreview`, `no_image_preview`, `in_pdir`, `in_viprev`, `in_ftli`, `main`, `alt_screen`, `winch`, `ftl_bind_check`, `fzf_viewer`

### Multi-value scalars
`dirmode` (0-5), `extmode`/`emode` (0-5), `show_size` (0-3), `sort_type0` (0-2), `zoom` (index), `KEY_TIMEOUT` (seconds), `quick_display` (count), `move_step` (count), `CMD_COLS` (columns), `FZF_LISTEN` (port)

### Strings (regex / commands / messages)
`ifilter`, `mfilter`, `rfilter0`, `help_command`, `msg_m`, `msg_du`, `find_auto`, `RM`, `EDITOR`, `SXIV`, `GIF_VIEWER`, `FILE_DIFF`, `G_PLAYER`, `T_PLAYER`, `TE_PLAYER`, `T_PLAYER_STATUS`, `B_PLAYER`, `Q_PLAYER`, `PAGER_ANSI`, `MD_PAGER`, `MD_RENDER0`, `MD_RENDER1`, `MD_RENDER2`, `MD_DIR_RENDER` (broken), `HEXVIEW`, `HEXEDIT`, `MIMETYPE`, `NCDU`, `JSON_VIEWER`, `YAML_VIEWER`, `EXA_COLORS`, `EXA_OPTIONS`, `GPGID`, `FZF_LISTEN_COMMAND`

### Tmux sizes
`shell_h`, `shell_v`, `zooms` (array), `FTLI_CLEAN`, `FTLI_H`, `FTLI_W`, `FTLI_Z`, `TBCOLORS`

### ANSI colors
`line_color0`, `line_color`, `line_color_hi`, `cursor_color0`, `cursor_color`, `cursor_color_search`

### Glyph arrays
`sglyph`, `iglyph`, `lglyph`, `tglyph`

### FZF options
`fzf_opt`, `fzfp_opt`, `fzf_sxiv_opt`

### Sort state
`sort_type0`, `sort_reversed0`, `s_type`, `s_reversed`, `sort_filters` (array)

### Key bindings
`redo_key`, `leader_key`, `flips` (array)

### Locales
`LANG`, `LC_ALL`

### Sentinels
`FTLRC_LOADED`

### Debug
`pdhl` (broken)

### Associative arrays (config)
`marks`, `dir_dest`, `cmd_aliases`, `user_colors` (commented)

### Associative arrays (per-tab state)
`lmode`, `vmode`, `depth`, `hidden`, `filters`, `filters2`, `filters_dir`, `rfilters`, `tfilters`, `ntfilter`, `sort_type`, `reversed`, `pdir_only`

### Associative arrays (runtime state)
`C`, `bindings`, `kbd_trie`, `key_map`, `vfiles`, `vdirs`, `time_event_handlers`, `dir_file`, `mime`, `pignore`, `lignore`, `lkeep`, `lkeep_tab`, `tail`, `tags`, `ntags`, `ftl_env`, `du_size`, `exclude_from_redo`, `marks` (runtime), `icache`, `dcache`

### Indexed arrays (runtime)
`dir_entries_list`, `dir_entries_path`, `dir_entries_file`, `dir_entries_color`, `dir_entries_size`, `dir_entries_relative_path_length`, `files`, `files_color`, `selection`, `tabs`, `panes`, `ino_processes`, `sort_filters`, `flips`, `zooms`

---

*End of `ftlrc` reference analysis.*
