% FTL(1) | General Commands Manual
%
% © Nadim Khemir 2020-2025, Artistic Licence 2.0

# NAME

ftl — terminal file manager with live previews, hyperorthodox

# SYNOPSIS

**ftl**

**ftl** \[**-f** _filter_\] \[**-s** _file_\] \[**-t** _file_\] \[_directory_\[/_file_\]\]

# DESCRIPTION

**ftl** is a hyperorthodox terminal file manager written in Bash that leverages
**tmux**(1) for pane management and live previews. Each pane is an independent
**ftl** process with its own tabs, filters, and sort order. The preview pane runs
real programs (**vim**(1), **mupdf**(1), **mplayer**(1), **w3mimgdisplay**) rather
than reimplementations, following the Unix philosophy of composition.

The codebase is organized into 16 focused modules under `etc/core/modules/`,
with namespaced functions (`ftl::module::function`) and variables
(`ftl_module_name`). A plugin system provides six extension categories:
filters, etags, generators, viewers, commands, and bindings.

# OPTIONS

**-f** _filter_
:	Load an external filter plugin at startup.

**-s** _file_
:	File containing paths to pre-select. One path per line.

		ftl -s <(find -name '*.py')

**-t** _file_
:	File containing paths to open in separate tabs. Must come after **-s**
	if both are used. One path per line.

		ftl -t <(find -name '*.py')

_directory_/_file_
:	Initial directory to open. If a file is specified, ftl opens its parent
	directory and selects the file.

# CONCEPTS

## Unix Spirit

**ftl** reuses existing Unix tools rather than reimplementing them. It can be
used to change directory, pick files in scripts, or as a **vim**(1) file picker.

## File Listing

The listing consists of a header line and a directory listing. The header
displays:

- Current directory (possibly truncated)
- Listing mode (directory/file)
- Image mode (all/non-image/image)
- Preview dir only (ᴰ)
- Filtered (~)
- Entry index / total entries
- Directory size (if enabled)
- File stat (if enabled)
- Tab indicator
- Sort glyph (⍺ alphanumeric, 🡕 size, 📅 date)
- Reverse sort (r)
- Background shell sessions

Each entry in the listing shows:

- Optional entry index
- Optional etag (git status, date, image size, etc.)
- Colored entry name (per **LS_COLORS**)
- Selection glyph (▪ ¹ ² ³ D)

## Preview Pane

The preview pane is a tmux pane running a real program. When the cursor
moves, the preview program is killed and a new one is started. Supported
types include: images, videos, audio, PDF, EPub, CBR/CBZ, directories,
HTML, JSON, YAML, markdown, SVG, GIF, STL, text, archives, and more.

## Hyperorthodox Panes

Each pane is an independent **ftl** process in a tmux split. Panes have
their own tabs, filters, and view modes. Selection is synchronized between
panes via a revision counter and serialized state files.

## Tabs

Tabs are per-pane views of same or different directories. Each tab has its
own filters, sort order, and view mode. Tab indices are not reused.

## Selection

Multiple entries can be tagged with 4 selectable classes (▪ ¹ ² ³ D).
Selection is synchronized between panes when `ftl_cfg_auto_sync_selection`
is enabled.

## Etags

Etags are optional metadata prepended to each entry. Available types:
git status, modification date, line count, image dimensions, TMSU tags,
and virtual entry markers.

## Virtual Entries

Plugins can inject fake entries into the listing with custom colors,
preview, and keyboard handling. This enables features like save-as dialogs
and custom navigation entries.

# KEY BINDINGS

Press **c** to see the full, fzf-searchable binding list. Press **?** for
this man page.

## General

| Key | Action |
|-----|--------|
| **?** | Show help (man page) |
| **c** | Show keyboard bindings (fzf) |
| **:** | Command prompt |
| **q** | Quit (tab → pane → ftl) |
| **Q** / **ZZ** | Quit all panes |
| **ZS** | Quit, keep shell pane |
| **ZP** | Quit, keep preview zoomed |
| **$** | Detach editor preview |
| **¿** | Debug pane |

## Movement

| Key | Action |
|-----|--------|
| **h** / **LEFT** | Cd to parent directory |
| **j** / **DOWN** | Down to next entry |
| **k** / **UP** | Up to previous entry |
| **l** / **RIGHT** | Cd into entry |
| **ENTER** | Enter directory or open file |
| **PGUP** / **CTL-B** | Page up |
| **PGDN** / **CTL-F** | Page down |
| **gg** | Go to first file |
| **G** | Go to last file |
| **gd** | Go to first directory |
| **gh** | Go to top of window |
| **gl** | Go to bottom of window |
| **g LEADER** | Cycle top/file/bottom |
| **gD** | Cd (prompt with completion) |
| **COUNT %** | Jump by percentage |
| **#** | Goto entry by index |
| **-** | Next entry of same extension |
| **_** | Next entry of different extension |
| **yn** | Goto next selected entry |
| **yN** | Goto previous selected entry |

## Preview Control

| Key | Action |
|-----|--------|
| **zv** | Toggle preview pane |
| **z+** / **+** | Change preview size |
| **zz** | Toggle image zoom |
| **ALT-J** / **ALT-K** | Scroll preview down/up |
| **J** / **K** | Scroll fixed preview down/up |
| **CTL-H** / **CTL-L** | Send left/right to preview |
| **zM** | Refresh preview/montage |
| **z1**–**z5** | Alternative preview modes 1–5 |
| **Z1**–**Z5** | Full-screen alternative modes 1–5 |

## View Modes

| Key | Action |
|-----|--------|
| **zma** / **zmm** | View mode: all files |
| **zmn** | Cycle view mode (all/non-image/image) |
| **zmi** | View mode: images only |
| **zmI** | View mode: non-images |
| **zmd** | Cycle file/dir mode |
| **zmD** | Preview directory only |
| **zmP** | Toggle image preview |
| **zmp** | PDF preview as text or image |
| **z.** | Show/hide dot-files |
| **zs** | Cycle size display (none/files/+dirs/+du) |
| **zS** | Hide size |
| **zg** | Show/hide stat in header |
| **zt** | Show/hide etags |
| **zT** | Select etag type |

## Sorting

| Key | Action |
|-----|--------|
| **zo** | Cycle sort type (alphanumeric/size/date) |
| **zO** | Toggle reverse sort |

## Filtering

| Key | Action |
|-----|--------|
| **ff** | Set filter 1 (regex passed to **rg**(1)) |
| **fF** | Set filter 2 |
| **fd** | Set directory filter |
| **fr** | Set reverse filter |
| **fe** | Select external filter plugin |
| **fy** | Show only tagged files |
| **fc** | Clear all filters |
| **zeh** | Hide current extension (per tab) |
| **zeH** | Hide current extension (global) |
| **zeo** | Show only current extension (per tab) |
| **zeO** | Show only current extension (global) |
| **zec** | Clear extension filters |
| **zes** | Sort by extension |
| **zep** | Toggle current extension preview |
| **z\*** | Set maximum listing depth |

## Searching

| Key | Action |
|-----|--------|
| **/** | Incremental search |
| **n** | Find next |
| **N** | Find previous |
| **gff** / **b** | fzf find in current directory |
| **gfF** / **B** | fzf find recursively |
| **gfd** | fzf find directories only |
| **gfa** / **gfA** | fzf find with regexp/fuzzy |
| **gfp** | fzf with ftl preview pane |
| **gfP** | fzf with ftl preview (recursive) |
| **grr** | Ripgrep, open file |
| **grt** | Ripgrep, goto file |
| **grl** | Ripgrep, edit all matched files |
| **grf** | Ripgrep, single match |
| **gfi** | Goto image via **sxiv**(1) |
| **gfI** | Goto image recursive via **sxiv**(1) |
| **gfu** | Goto image via fzf/ueberzug |
| **gL** | Follow symlink |

## Selection

| Key | Action |
|-----|--------|
| **a** / **yy** | Select current entry, move down |
| **s** / **yu** | Select current entry, move up |
| **COUNT** **a** / **yy** | Select COUNT entries down |
| **ya** | Select all (files and subdirs) |
| **yf** | Select all files |
| **yd** | Select all directories |
| **ye** | Select same extension |
| **yE** | Select same extension (recursive) |
| **yif** | fzf select files |
| **yiF** | fzf select files (recursive) |
| **yii** | Select images via **sxiv**(1) |
| **y1**–**y4** | Select with class 1–4 |
| **yc** | Deselect all |
| **yC** | Deselect via fzf |
| **ytc** | Copy selection paths to clipboard |
| **gy** | fzf goto selected entry |

## File Operations

| Key | Action |
|-----|--------|
| **d** | Delete selection |
| **w** | Copy to (prompts for destination) |
| **pp** | Copy selection to current directory |
| **pm** | Move selection to current directory |
| **PP** | Copy to preset destination |
| **PM** | Move to preset destination |
| **pz** | Move via **fzf_mv**(1) |
| **pZ** | Move to subdirectory via **fzf_mv_sd**(1) |
| **pop** | Copy selection to other tab |
| **pom** | Move selection to other tab |
| **R** | Rename selection (via **edir**(1)) |
| **xl** | Symlink selection |
| **xmr** | Toggle read permission |
| **xmw** | Toggle write permission |
| **xmx** | Toggle execute permission |
| **xmM** | Chmod via **sc-im**(1) |
| **if** | Create new file |
| **id** | Create new directory |
| **iD** | Create directory and cd into it |
| **ib** | Bulk create (via **$EDITOR**) |
| **xv** | Edit in **$EDITOR** |
| **xV** | Edit in separate tmux window |
| **XV** | Edit in shared tmux window |
| **xc** | Cat in terminal |
| **xh** | Hex view |
| **xH** | Hex edit |
| **xp** | Preview with custom command |

## Tabs

| Key | Action |
|-----|--------|
| **§** / **PARAGRAPH** | New tab |
| **TAB** / **gt** | Next tab |
| **gT** | Previous tab |
| **COUNT** **gt** | Goto tab N |

## Panes

| Key | Action |
|-----|--------|
| **CTL-W h** | New pane left |
| **CTL-W l** | New pane right |
| **CTL-W j** | New pane below |
| **CTL-W H** | New pane left, keep focus |
| **CTL-W L** | New pane right, keep focus |
| **CTL-W n** / **gp** | Next pane |

## Shell

| Key | Action |
|-----|--------|
| **CTL-W ss** / **Ss** | Shell pane |
| **CTL-W sv** / **Sv** | Vertical shell pane |
| **CTL-W sS** / **SS** | Shell pane with selected files |
| **CTL-W sz** / **Sz** | Shell pane, zoomed |
| **CTL-W sf** / **Sf** | Send selection to shell |
| **CTL-W sg** / **gS** | Synch shell cwd to ftl |
| **CTL-W sq** / **Sq** | Close shell pane |
| **CTL-W !** / **S!** | View session shell |
| **CTL-W sp** / **Sp** | Run command in pane |

## Marks & History

| Key | Action |
|-----|--------|
| **m** _char_ | Set mark |
| **'** _char_ | Go to mark |
| **\*** _char_ | Go to mark in new tab |
| **gm** | fzf to mark |
| **MM** | Add persistent mark |
| **gM** | fzf to persistent mark |
| **Mc** | Clear persistent marks |
| **Hh** | fzf session history |
| **HH** / **¨** | fzf global history |
| **Hs** | fzf global history (subdir filtered) |
| **He** | Edit global history |
| **Hc** | Clear global history |

## Media

| Key | Action |
|-----|--------|
| **ea** | Background media player |
| **eA** | fzf choose viewer |
| **ek** | Kill media player |
| **eq** | Queue to music player |
| **ee** | External viewer mode 1 |
| **er** | External viewer mode 2 (detached) |
| **ew** | External viewer mode 3 (fullscreen) |

## Leader Key Sequences

The leader key is **\\** (backslash) by default.

| Key | Action |
|-----|--------|
| **\\fc** | Compress (tar.bz2) |
| **\\fd** | Decompress |
| **\\fD** | Decompress to directory |
| **\\fe** | GPG encrypt/decrypt |
| **\\fE** | Password encrypt/decrypt |
| **\\fg** | Show stat in preview |
| **\\fh** | Display help |
| **\\fi** | Optimize image (jpg/png) |
| **\\fl** | Lint directory (**rmlint**(1)) |
| **\\fm** | Send selection via **mutt**(1) |
| **\\fP** | Convert PDF to text |
| **\\fp** | Optimize PDF (**ghostscript**(1)) |
| **\\fs** | Shred selection |
| **\\fv** | Optimize video (**ffmpeg**(1)) |
| **\\s** | Terminal popup |
| **\\gg** | Git etags |
| **\\gt** | Git tree status |
| **\\gd** | Git diff |
| **\\gD** | Git diff (via **fgd**(1)) |
| **\\gf** | Git find changed files |
| **\\gi** | Add to .gitignore |
| **\\ga** | Git add selection |
| **\\gA** | Git add via **forgit**(1) |
| **\\t LEADER** | TMSU show tags |
| **\\t f** | TMSU tag via fzf |
| **\\t g** | TMSU goto via fzf |
| **\\t m** | TMSU mount |
| **\\t q** | TMSU filter by query |
| **\\t r** | TMSU filter via fzf |
| **\\t s** | TMSU tag via **sc-im**(1) |
| **\\t t** | TMSU tag selection |
| **\\v v** | Insert virtual entries |
| **\\v V** | Remove virtual entries |
| **\\v e** | Show virtual entry etag |
| **\\v d** | Diff two selected files |
| **\\u** | Run user command |
| **\\h h** | Leader help |
| **\\a a** | Add filename to log |
| **\\a v** | Edit log |
| **\\a e** | Add to log and edit |

# COMMAND MODE

Press **:** to enter command mode. Commands can be:

- **Empty** — Cancel
- **Number** — Goto entry by index
- **qa** — Quit all
- **load_sel** — Load selection from file
- **etags** — Choose etag type
- **tree** — Display directory tree
- **url** _URL_ — Open URL in browser
- **fsh** _cmd_ — Run command in shell window
- **full** _cmd_ — Run command full screen
- **split** _cmd_ — Run command in split window
- **finfo** — List ftl state (for piping to other commands)
- _ftl command_ — Run a bound ftl command by name
- _user command_ — Run a command from `commands/` directory
- _shell command_ — Run in the session shell

# CONFIGURATION

Configuration is read from `~/.config/ftl/etc/ftlrc`. All variables use the
`ftl_cfg_*` prefix. Key categories:

## Paths

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_gen_dir` | `$FTL_CFG/etc/generators` | Generator scripts location |
| `FTL_STATE_DIR` | `$FTL_CFG/var` | Runtime state directory |
| `FTL_CACHE_DIR` | `$FTL_STATE_DIR/thumbs` | Thumbnail cache |
| `ftl_cache_thumb_dir` | `$FTL_STATE_DIR/thumbs` | Thumbnail cache (alias) |
| `ftl_state_global_history_file` | `$FTL_STATE_DIR/history` | Global history file |

## Behavior

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_key_timeout` | `1` | Key read timeout (seconds) |
| `ftl_cfg_auto_sync_selection` | `1` | Sync selection between panes |
| `ftl_cfg_time_event_interval` | `0` | Time event interval (0=off) |
| `ftl_cfg_quick_display_threshold` | `512` | Quick-display threshold |
| `ftl_cfg_show_entry_index` | `1` | Show entry index column |
| `ftl_cfg_mount_archives` | `0` | Mount archives via fuse |
| `ftl_cfg_auto_select_filename` | `README` | Auto-select this file |
| `ftl_cfg_move_step_size` | `4` | Fast movement step |
| `ftl_cfg_help_in_popup` | `0` | Show help in popup |
| `ftl_cfg_bindings_in_popup` | `1` | Show bindings in popup |

## External Commands

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_editor` | `vim -p` | Text editor |
| `ftl_cfg_image_viewer` | `sxiv` | Image viewer |
| `ftl_cfg_hex_viewer` | `hexdump` | Hex viewer |
| `ftl_cfg_hex_editor` | `hexedit` | Hex editor |
| `ftl_cfg_mime_detector` | `mimemagic` | Mime type detector |
| `ftl_cfg_disk_usage_tool` | `ncdu` | Disk usage viewer |
| `ftl_cfg_json_viewer` | `jless` | JSON viewer |
| `ftl_cfg_yaml_viewer` | `yam -i` | YAML viewer |
| `ftl_cfg_delete_command` | `rm -rf` | Deletion command |
| `ftl_cfg_diff_tool` | `vimdiff` | File diff tool |
| `ftl_cfg_gui_media_player` | `vlc -f` | GUI media player |
| `ftl_cfg_terminal_media_player` | `mplayer -vo null` | Terminal media player |
| `ftl_cfg_background_player` | `viewers/mplayer_local` | Background player |
| `ftl_cfg_queue_player` | `viewers/cmus` | Music queue player |
| `ftl_cfg_markdown_pager` | `less -R` | Markdown preview pager |
| `ftl_cfg_ansi_pager` | `less -R` | ANSI pager |

## Glyphs

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_glyph_sort` | `(⍺ 🡕)` | Sort type glyphs |
| `ftl_cfg_glyph_image_mode` | `('' ᴵ ᴺ)` | Image mode glyphs |
| `ftl_cfg_glyph_listing_mode` | `('' ᵈ ᶠ)` | Listing mode glyphs |
| `ftl_cfg_glyph_tag_classes` | `('' ¹ ² ³ D)` | Tag class glyphs |

## Key Bindings

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_leader_key` | `BACKSLASH` | Leader key token |
| `ftl_cfg_redo_key` | `.` | Redo key token |
| `ftl_cfg_preview_zoom_levels` | `(85 70 50 30)` | Preview pane sizes (%) |

## Filters

| Variable | Default | Description |
|----------|---------|-------------|
| `ftl_cfg_image_extensions_regex` | `svg\|webp\|jpg\|...` | Image extension regex |
| `ftl_cfg_media_extensions_regex` | `mp3\|mp4\|...` | Media extension regex |
| `ftl_cfg_default_reverse_filter` | (empty) | Default reverse filter |

# ENVIRONMENT

**FTL_CFG**
:	Configuration directory (default: `$HOME/.config/ftl`).

**FTL_STATE_DIR**
:	Runtime state directory (default: `$FTL_CFG/var`).

**FTL_CACHE_DIR**
:	Thumbnail cache directory (default: `$FTL_STATE_DIR/thumbs`).

**FTL_DEBUG**
:	Set to `1` to enable debug logging.

# FILES

## Directory Structure

```
~/.config/ftl/
├── ftlrc                          # user configuration override
├── bindings/                      # user binding plugins
├── commands/                      # user command plugins
├── etags/                         # user etag plugins
├── filters/                       # user filter plugins
├── generators/                    # user generator plugins
├── viewers/                       # user viewer plugins
├── man/                           # man page
│   ├── ftl.md
│   └── gen_man_pages
└── etc/
    ├── ftlrc                      # default configuration
    ├── bin/                       # CLI helpers
    │   ├── ftl                    # entry point
    │   ├── ftli                   # image preview daemon
    │   ├── finfo                  # state dumper
    │   ├── fsh                    # shell command runner
    │   └── third_party/           # vendored tools
    ├── bindings/                  # default binding plugins
    │   └── lib/                   # binding libraries
    ├── commands/                  # default command plugins
    ├── core/                      # core engine
    │   ├── ftl_setup              # initialization orchestrator
    │   └── modules/               # ★ core modules
    │       ├── util.sh            # path, size, fifos
    │       ├── log.sh             # logging
    │       ├── debug.sh           # debug helpers
    │       ├── state.sh           # state serialization
    │       ├── keyboard.sh        # key parsing, trie, dispatch
    │       ├── selection.sh       # tag/selection management
    │       ├── tab.sh             # tab management
    │       ├── pane.sh            # tmux pane management
    │       ├── filter.sh          # filter pipeline
    │       ├── list.sh            # directory scan and render
    │       ├── preview.sh         # preview dispatch
    │       ├── etag.sh            # etag dispatch
    │       ├── virtual.sh         # virtual entry injection
    │       ├── mark.sh            # bookmarks and history
    │       ├── time.sh            # time events
    │       └── commands.sh        # all user commands
    ├── etags/                     # default etag plugins
    ├── filters/                   # default filter plugins
    ├── generators/                # preview thumbnail generators
    └── viewers/                   # default viewer plugins
```

## State Files

$FTL_STATE_DIR/$$/
:	Per-session state directory (one per ftl process).

$FTL_STATE_DIR/$$/log
:	Session log file.

$FTL_STATE_DIR/$$/tags
:	Serialized selection (Bash `declare -p` output).

$FTL_STATE_DIR/$$/ftl
:	Serialized state for preview pane synchronization.

$FTL_STATE_DIR/$$/history
:	Session directory-visit history.

$FTL_STATE_DIR/shared/history
:	Global directory-visit history (all sessions).

$FTL_STATE_DIR/shared/marks
:	Persistent bookmarks.

# PLUGIN SYSTEM

## Filter Plugins

Location: `filters/`

A filter plugin is a Bash script that defines a function to filter directory
entries. It receives entries on stdin (format: `size\tdate\tname`) and
outputs the kept entries on stdout.

Lifecycle: `load` (when selected) → `filter` (per directory scan) → `reset`
(when cleared). Filters can cache their computed state.

## Etag Plugins

Location: `etags/`

An etag plugin defines two functions: one to scan a directory (computing
per-entry metadata) and one to retrieve the tag for a single entry (via
nameref out-parameters).

## Generator Plugins

Location: `generators/`

A generator is an executable script that produces a preview thumbnail.
Arguments: source file, thumbnail directory, optional mode, optional FORCE.
Must echo the path to the generated file on stdout.

## Viewer Plugins

Location: `viewers/`

A viewer plugin defines preview functions for specific file types. The
core viewer (`viewers/core`) contains the dispatch logic and all built-in
viewers.

## Command Plugins

Location: `commands/`

A command plugin is either a sourced Bash script (can mutate ftl state)
or an executable in any language. Receives command-line arguments.

## Binding Plugins

Location: `bindings/`

A binding plugin calls `ftl::kbd::bind` to register key bindings. It can
also define helper functions (namespaced as `ftl::plugin::<name>::*`).

# EXAMPLES

## Using ftl as a directory changer

Add to `~/.bashrc`:

	source $FTL_CFG/etc/bin/cdf

Then use `cdf` to navigate. Press `q` to quit and cd to the current
directory.

## Using ftl as a file picker

Add to `~/.bashrc`:

	source $FTL_CFG/etc/bin/ftll

Then use `ftll` to select files. Press `q` to return the selection.

## Using ftl as a vim file picker

Add to `~/.vimrc`:

	function! Ftl(preview)
		let temp = tempname()
		let id = localtime()
		exec "silent !tmux new-window ftlvim " . shellescape(temp) . " ftl_" . id . " " . a:preview . " ; tmux wait ftl_" . id
		if !filereadable(temp)
			redraw!
			return
		endif
		for name in readfile(temp)
			exec 'tabedit ' . fnameescape(name)
		endfor
		redraw!
	endfunction
	map <silent> <leader>f :call Ftl(1)<cr>

# TESTING

	ftl includes a test framework:

	./test/harness.sh                     # run all unit tests
	./test/harness.sh test/unit/test_keyboard.sh  # run one test file
	./test/harness.sh -v                  # verbose mode

# SEE ALSO

**tmux**(1), **fzf**(1), **rg**(1), **fd**(1), **vim**(1), **ranger**(1),
**vifm**(1), **lf**(1), **nnn**(1), **broot**(1)

# BUGS

Report bugs at <https://github.com/nkh/ftl/issues>

# AUTHOR

© Nadim Khemir 2020-2025 · [nadim.khemir@gmail.com](mailto:nadim.khemir@gmail.com) · CPAN/Github ID: NKH

# LICENSE

Artistic Licence 2.0 or GNU General Public License 3.0, at your option.
