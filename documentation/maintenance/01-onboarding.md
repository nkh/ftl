# 01 — Onboarding

> **Audience:** A maintainer who has never seen ftl before.
> **Goal:** By the end of this document, you will understand what ftl
> is, how to run it, how to navigate the source tree, and the mental
> model that underpins every subsequent document.
> **Time:** 30 minutes.

---

## 1. What ftl Is

ftl is a terminal file manager written in **Bash 5+** that uses
**tmux** as its composition substrate. The name is a play on "faster
than light" — the original author's aspiration for navigation speed.

The defining architectural decision is that ftl is **hyperorthodox**:
rather than reimplementing preview rendering, pane multiplexing, and
shell integration inside its own process, ftl delegates all of these
to tmux and to external programs. Each pane is a separate `ftl`
process. The preview pane runs real programs (`mupdf`, `mplayer`,
`w3mimgdisplay`, `vim -R`) in real tmux panes. The "shell pane" is a
real `bash -i` in a sibling tmux pane.

This decision shapes every aspect of the codebase:

- **No custom rendering pipeline.** ftl does not parse image formats,
  render PDFs, or decode video. It spawns the appropriate tool and
  lets it write to the terminal.
- **No custom pane management.** ftl does not implement a windowing
  system. It uses tmux splits, popups, and windows.
- **No custom event loop.** ftl's main loop is `while true ; do
  ftl::kbd::get_key ; ftl::kbd::dispatch ; done`. Background work
  (file watching, time events) is handled by tmux and inotify.
- **Bash as the implementation language.** Because ftl does not do
  rendering or event-loop work, the performance-critical path is
  small. Bash is sufficient. The choice of Bash also makes the
  extension surface trivially accessible: any shell user can write a
  plugin.

## 2. Running ftl

ftl requires:

- Bash 5+ (associative arrays, namerefs, `${var:offset:length}`,
  `${var,,}` lowercasing)
- tmux 3.0+ (popups, `display-message -p`, `pipe-pane`)
- A terminal with X11 support for image preview (or a modern terminal
  like kitty/wezterm/iTerm2 with native image protocols)
- Standard Unix tools: `find`, `stat`, `file`, `sed`, `awk`, `grep`,
  `sort`, `head`, `tail`, `cut`, `tr`, `xargs`

Optional tools that unlock specific features:

- `fzf` and `fzf-tmux` — fuzzy search, command palette, marks
- `ripgrep` (`rg`) — content search
- `fd` — fast file discovery (used by some plugins)
- `mupdf`, `pdftoppm` — PDF preview
- `ffmpeg` — video preview
- `w3mimgdisplay` — image preview (X11)
- `ImageMagick` (`convert`) — image rotation, GIF frame extraction
- `exiftool` — EXIF metadata, image labeling
- `glow`, `moar` — markdown preview
- `bat` — syntax-highlighted text preview
- `jless` — JSON preview
- `7z`, `zip`, `unzip`, `tar`, `unrar` — archive operations
- `tmsu` — file tagging

To run ftl from the source tree (no installation required):

```bash
cd /path/to/ftl-work
export FTL_CFG="$PWD/config/ftl"
# ftl must run inside tmux
tmux new -s ftl-dev "$FTL_CFG/etc/bin/ftl"
```

The `FTL_CFG` environment variable tells ftl where its configuration
directory is. The default is `$HOME/.config/ftl`. For development, set
it to the source tree's `config/ftl`.

## 3. The Source Tree

```
ftl-work/
├── config/ftl/                 ← the ftl configuration tree (FTL_CFG)
│   ├── etc/
│   │   ├── bin/                ← entry point and CLI helpers
│   │   │   └── ftl             ← the main executable
│   │   ├── core/
│   │   │   ├── ftl_setup       ← startup orchestrator (sourced by bin/ftl)
│   │   │   └── modules/        ← 17 core modules
│   │   │       ├── commands.sh
│   │   │       ├── debug.sh
│   │   │       ├── etag.sh
│   │   │       ├── filter.sh
│   │   │       ├── inline_rename.sh
│   │   │       ├── keyboard.sh
│   │   │       ├── list.sh
│   │   │       ├── log.sh
│   │   │       ├── mark.sh
│   │   │       ├── pane.sh
│   │   │       ├── preview.sh
│   │   │       ├── selection.sh
│   │   │       ├── state.sh
│   │   │       ├── tab.sh
│   │   │       ├── time.sh
│   │   │       ├── util.sh
│   │   │       └── virtual.sh
│   │   ├── bindings/           ← built-in binding plugins (auto-sourced)
│   │   ├── commands/           ← built-in : commands
│   │   ├── etags/              ← etag plugins
│   │   ├── filters/            ← filter plugins
│   │   ├── generators/         ← preview thumbnail generators
│   │   ├── viewers/            ← viewer plugins (core is the dispatcher)
│   │   ├── ftlrc               ← default configuration
│   │   └── ftlrc_not_so_vim_like ← alternative config
│   ├── bindings/               ← user binding plugins (also auto-sourced)
│   ├── commands/               ← user : commands
│   ├── etags/                  ← user etag plugins
│   ├── filters/                ← user filter plugins
│   ├── generators/             ← user generators
│   ├── viewers/                ← user viewers
│   └── man/ftl.md              ← the man page (mdBook source)
├── docs/                       ← mdBook user documentation
│   ├── book.toml
│   └── src/
│       ├── SUMMARY.md          ← mdBook table of contents
│       ├── introduction.md
│       ├── extra-features.md
│       ├── extending-ftl.md
│       ├── *.md                ← 31 pages total
│       └── user-guide/
│           └── *.md
├── documentation/              ← analysis and design documents
│   ├── maintenance/            ← this directory (maintainer docs)
│   ├── ftl-analysis.md
│   ├── ftl2-architecture-analysis.md
│   ├── ftl-variables.md
│   └── ...
├── test/
│   ├── harness.sh              ← the test framework
│   ├── unit/                   ← unit tests (test_*.sh)
│   ├── integration/            ← integration tests (test_*.sh)
│   └── mock/                   ← test mocks (currently empty)
├── screenshots/
├── README.md
├── INSTALL
└── Todo.txt
```

### Key directories

- **`config/ftl/etc/core/modules/`** — the 17 modules. This is where
  the engine lives. If you are fixing a bug or adding a core feature,
  you will edit files here.
- **`config/ftl/etc/bindings/` and `config/ftl/bindings/`** — binding
  plugins. Both directories are auto-sourced at startup. The `etc/`
  versions are built-in; the top-level versions are user-extensible.
- **`config/ftl/etc/ftlrc`** — the default configuration. Sets all
  `ftl_cfg_*` variables and registers built-in bindings.
- **`config/ftl/etc/bin/ftl`** — the entry point. Defines the `ftl()`
  function, the main loop, and signal handlers.
- **`config/ftl/etc/core/ftl_setup`** — the startup orchestrator.
  Sources all modules in dependency order, sources `ftlrc`, initializes
  runtime state.
- **`test/`** — the test suite. `harness.sh` is the framework; `unit/`
  and `integration/` contain the tests.

## 4. The Mental Model

Before reading any source, internalize this model. Every subsequent
document assumes it.

### 4.1 Process Model

Each pane is a separate `ftl` process. When you split a pane, ftl
spawns a new `ftl` process via `tmux split-window`. The two processes
do not share memory; they communicate through:

1. **The filesystem.** Each pane has a session directory
   (`$FTL_STATE_DIR/$PID/`). State is serialized to files in this
   directory. Sibling panes read each other's state files.
2. **tmux signals.** Single-character tmux messages (`å`, `Å`, `ä`,
   `Ä`) are sent between panes to trigger refreshes, selection sync,
   etc.

The parent pane (the one the user launched) has a session directory.
Child panes (splits, preview panes) have session directories nested
under the parent's. The parent's `$ftl_state_session_dir/prev/` is the
shared state directory (`$ftl_state_shared_dir`).

### 4.2 The Main Loop

ftl's main loop (in `bin/ftl`, after setup) is:

```bash
while true ; do
    ftl::kbd::get_key "$ftl_cfg_key_timeout"
    ftl::kbd::dispatch
    ftl::time::tick
    ftl::pane::check_resize
    ftl::sel::sync_from_other_pane
done
```

- `ftl::kbd::get_key` reads one key from stdin (with an optional
  timeout) and normalizes it to a symbolic name (`UP`, `ENTER`,
  `LEADER`, `a`, etc.).
- `ftl::kbd::dispatch` looks up the key in the trie and invokes the
  bound function. If a sub-mode handler is active (`ftl_kbd_submode_handler`),
  it is called instead of the trie lookup.
- `ftl::time::tick` fires registered time-event handlers if their
  interval has elapsed.
- `ftl::pane::check_resize` re-renders if the terminal was resized.
- `ftl::sel::sync_from_other_pane` pulls selection state from the
  sibling pane if its revision counter is newer.

### 4.3 The Listing Pipeline

When ftl enters a directory (`ftl::list::change_dir`), it runs a
streaming pipeline:

```
find → external filter → dir filter → file filter 1 → file filter 2 → reverse filter → sort → render
```

Each stage reads from stdin and writes to stdout. The pipeline is
assembled with process substitution and named pipes (FIFOs). The
`find` output is teed to multiple FIFOs (one per pipeline stage) so
the stages run concurrently.

The external filter is the swap-in plugin slot (`ftl::filter::apply_external`).
The dir filter and two file filters are per-tab state. The reverse
filter inverts the sort order for a subset of entries. The sort stage
uses `sort` with configurable keys.

The result is two arrays: `ftl_list_entries` (full paths) and
`ftl_list_entry_colors` (colorized names for display). The render
function walks a window of these arrays and emits terminal escape
sequences.

### 4.4 The Keyboard Engine

The keyboard engine is a hand-rolled trie built on `read -rsn 1`. Key
sequences are stored in `ftl_kbd_trie` (associative array: concatenated
key string → command function). The trie supports:

- **Multi-key sequences** — `LEADER f c` is stored as `LEADERfc`.
- **Count prefixes** — `3j` is stored as `COUNTj`. The count is
  available to the command as `$ftl_kbd_count`.
- **Leader key** — `\` (configurable via `ftl_cfg_leader_key`).
- **Redo key** — `.` (configurable via `ftl_cfg_redo_key`) repeats the
  last non-excluded command.
- **Sub-mode handlers** — `ftl_kbd_submode_handler` is a function name.
  When set, all keys are routed to it instead of the trie. This is how
  incremental search, fzf search, and inline rename mode work.

### 4.5 The Preview Pipeline

When the cursor moves, `ftl::list::render` calls `ftl::prev::dispatch`
(after rendering the listing). `ftl::prev::dispatch` sources
`viewers/core` and calls `ftl::plugin::core::pviewers` (for the
preview pane) or `ftl::plugin::core::ext_viewers` (for full-terminal
external viewers).

`pviewers` is a large case statement that routes by extension and
MIME type to specific viewer functions (`pimage`, `ppdf`, `pmp3`,
`pmd`, `pjson`, etc.). Each viewer function clears the preview pane
(`ftl::prev::clear`) and spawns a backend program in a tmux split pane
(`ftl::pane::split_for_preview`).

### 4.6 State and Serialization

ftl's state is a collection of global variables (`ftl_state_*`,
`ftl_list_*`, `ftl_selection_*`, `ftl_tab_*`). Key state is serialized
to files in the session directory:

- `ftl` — the listing state (cursor index, sort, filters, view mode)
- `tags` — the selection (`declare -p ftl_selection_tags`)
- `prev/stagsi` — the selection revision counter
- `prev/fs` — the session directory path (for sibling discovery)
- `pane` — this pane's tmux id

`ftl::state::save` is called on every render. `ftl::state::load` is
called by sibling panes to sync. `ftl::state::serialize_info` writes a
snapshot for external commands (`finfo`, `fsh`).

### 4.7 Plugins

Everything user-facing is a plugin. There are 6 categories:

| Category | Location | Loaded by | Contract |
|----------|----------|-----------|----------|
| Bindings | `etc/bindings/`, `bindings/` | auto-source at startup | calls `ftl::kbd::bind` |
| Commands | `etc/commands/`, `commands/` | invoked from `:` prompt | sourced or executable script |
| Filters | `filters/` | `fe` (cycle) or `:etags <name>` | overrides `ftl::filter::apply_external` |
| Etags | `etags/` | `zT` (cycle) or `:etags <name>` | defines `etag_dir()` + `etag_tag()` |
| Generators | `generators/` | `generators/generator` driver | executable producing thumbnails |
| Viewers | `viewers/` | sourced by `viewers/core` | defines viewer functions |

Plugins run in ftl's shell with full access to the `ftl::*` API and
all globals. There is no sandbox; a plugin can do anything ftl can do.

## 5. Reading the Source

The recommended reading order for the source:

1. **`config/ftl/etc/bin/ftl`** — the entry point. Read the `ftl()`
   function to understand startup, option parsing, and the main loop.

2. **`config/ftl/etc/core/ftl_setup`** — the orchestrator. Read this
   to understand module sourcing order and runtime state
   initialization.

3. **`config/ftl/etc/core/modules/keyboard.sh`** — the keyboard
   engine. This is the most self-contained module. Read it to
   understand the trie, key normalization, and dispatch.

4. **`config/ftl/etc/core/modules/list.sh`** — the listing pipeline
   and renderer. This is the largest module (709 lines). Read
   `change_dir`, `scan_and_render`, `render`, and `move_cursor` first;
   skip the scan helpers and FIFO management until you need them.

5. **`config/ftl/etc/core/modules/state.sh`** — state serialization.
   Short (155 lines). Read all of it.

6. **`config/ftl/etc/core/modules/selection.sh`** — selection
   management. Short (239 lines). Read all of it.

7. **`config/ftl/etc/core/modules/commands.sh`** — user-facing
   commands. Large (2732 lines, ~390 functions). Skim the section
   headers; read the commands you are interested in modifying.

8. **`config/ftl/etc/core/modules/pane.sh`** — tmux interaction.
   Medium (296 lines). Read the public API; skip the private helpers
   unless you are modifying pane management.

9. **`config/ftl/etc/core/modules/filter.sh`** — the filter pipeline.
   Short (167 lines). Read all of it.

10. **`config/ftl/etc/viewers/core`** — the viewer dispatcher. Medium
    (496 lines). Read `pviewers` and `ext_viewers`; skim the individual
    viewer functions.

11. **`config/ftl/etc/ftlrc`** — the configuration. Long (606 lines)
    but straightforward. Read the sections relevant to your change.

12. **The binding plugins** in `etc/bindings/` — read
    `incremental_search` (shortest, clearest example) and
    `leader_ftl` (library pattern). Then read
    `bindings/missing_functionalities` (largest, 582 lines) to see
    the full range of what a binding plugin can do.

## 6. Conventions

### 6.1 Namespacing

All functions and variables are namespaced:

- **Functions:** `ftl::<module>::<function>` (e.g.
  `ftl::kbd::bind`, `ftl::list::render`)
- **Module variables:** `ftl_<module>_<name>` (e.g.
  `ftl_kbd_trie`, `ftl_list_entries`)
- **Config variables:** `ftl_cfg_*` (e.g. `ftl_cfg_leader_key`)
- **State variables:** `ftl_state_*` (e.g. `ftl_state_cursor_index`)
- **Plugin functions:** `ftl::plugin::<name>::<function>` (e.g.
  `ftl::plugin::missing::duplicate`)
- **Plugin variables:** `ftl_plugin_<name>_*` (e.g.
  `ftl_plugin_missing_nav_history`)

Private helper functions use a leading underscore:
`_ftl::list::scan_directory`, `_ftl::pane::split_with_fixed_preview`.

### 6.2 Tab Indentation

The project uses **tabs** (not spaces) for indentation. The
`ftl::kbd::bind` call uses tabs to separate fields; the bindings table
display relies on tab-delimited fields for column alignment. Configure
your editor to insert tabs.

### 6.3 `set -u`

ftl runs under `set -u` (treat unset variables as an error). Always
provide defaults when accessing potentially-unset variables:

```bash
# Bad: crashes if ftl_selection_tags is unset
for p in "${!ftl_selection_tags[@]}" ; do ...

# Good: defaults to empty
for p in "${!ftl_selection_tags[@]:-}" ; do ...
```

### 6.4 No One-Liners

The `reformat` branch eliminated all one-liners. Every function body
is multi-line with one statement per line. This is enforced by code
review, not by a linter. Maintain the style.

### 6.5 Comments

Every module begins with a header comment block listing:
- The module's purpose
- Public functions (with one-line descriptions)
- Private functions (with one-line descriptions)
- Globals (with one-line descriptions)

Maintain this header when adding functions or globals.

## 7. Next Steps

Continue to [02-architecture.md](./02-architecture.md) for the deep
architectural walkthrough, or skip to
[03-modules.md](./03-modules.md) if you prefer to learn by reading
module-by-module. If you have a specific modification in mind, go
directly to [07-modification-guide.md](./07-modification-guide.md) and
use it as a recipe index.
