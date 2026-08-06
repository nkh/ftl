# Extending ftl

This document describes how to extend ftl by authoring bindings,
commands, filters, etags, viewers, and generators. Each section
provides the plugin contract, a reference implementation, and notes on
design rationale and common pitfalls.

The extension model is uniform across all plugin categories: a plugin is
a Bash script placed in a known directory, auto-discovered (or
explicitly sourced) by ftl at startup or runtime, and executed in ftl's
shell process with full access to the `ftl::*` API and global state.
There is no build step, no manifest, and no compilation.

---

## Table of Contents

1. [Bindings](#1-bindings)
2. [Commands](#2-commands)
3. [Filters](#3-filters)
4. [Etags](#4-etags)
5. [Viewers](#5-viewers)
6. [Generators](#6-generators)
7. [Conventions and Pitfalls](#7-conventions-and-pitfalls)

---

## 1. Bindings

A binding plugin registers a key sequence with the keyboard trie via
`ftl::kbd::bind`, optionally defining helper functions invoked by the
binding.

### Location

- `$FTL_CFG/etc/bindings/<name>` — built-in (shipped with ftl)
- `$FTL_CFG/bindings/<name>` — user-defined

Both directories are auto-sourced at startup:

```bash
for b in $(fd . "$FTL_CFG/etc/bindings" --type f | sort -u) ; do source "$b" ; done
for b in $(fd . "$FTL_CFG/bindings" --type f | sort -u) ; do source "$b" ; done
```

### Contract

```bash
ftl::kbd::bind <map> <section> "<keys>" <command_fn> "<help>"
```

| Parameter | Description |
|-----------|-------------|
| `map` | Hint string for the binding table (`ftl`, `leader`, `leader_ftl`). Does not affect dispatch. |
| `section` | Grouping hint for the `c` bindings table (`move`, `selection`, `filter`, etc.). |
| `keys` | Space-separated symbolic key tokens: single chars, `LEADER`, `COUNT`, `ENTER`, `TAB`, `CTL-W`, `UP`, `DOWN`, etc. |
| `command_fn` | The Bash function to invoke when the key sequence matches. |
| `help` | Short description shown in the `c` table. |

The keyboard engine concatenates the tokens into a single key string and
stores it in the `ftl_kbd_trie` associative array. Counts are handled by
registering a `COUNT`-prefixed variant explicitly.

### Reference Implementation

The following binding compresses the current selection into a tar.bz2
archive in the current directory.

```bash
# ~/.config/ftl/etc/bindings/my_compress

# Helper function: compress the selection into a tar.bz2 next to the current dir
my_compress() {
    local out="$PWD/selection-$(date +%s).tar.bz2"

    # Validate selection
    if (( ${#ftl_selection_current[@]} == 0 )) ; then
        ftl::log::warn "no selection to compress"
        ftl::list::render
        return
    fi

    # Compress
    if tar cjf "$out" "${ftl_selection_current[@]}" 2>/dev/null ; then
        ftl::log::info "wrote $out"
    else
        ftl::log::error "compression failed"
    fi

    # Refresh the listing to show the new archive
    ftl::list::refresh_dir
}

# Register the binding: LEADER f z
ftl::kbd::bind	ftl	entry	"LEADER f z"	my_compress	"compress selection into tar.bz2"

# vim: set filetype=bash :
```

### Key Points

1. **Helper functions are defined in the same file.** They are sourced
   into ftl's shell and persist for the session. Use namespaced names
   (`ftl::plugin::my_compress::run`) to avoid collisions; the bare name
   (`my_compress`) is acceptable for personal plugins.

2. **Selection access.** The current selection is in
   `ftl_selection_current` (indexed array of full paths) and
   `ftl_selection_tags` (associative array: path → glyph). Always check
   `${#ftl_selection_current[@]}` before iterating.

3. **Refresh after mutation.** Any file operation that changes the
   directory contents must call `ftl::list::refresh_dir` (fast, reuses
   the scan) or `ftl::list::change_dir` (full rescan). The difference:
   `refresh_dir` reuses the raw entry arrays and only re-applies filters
   and re-renders; `change_dir` re-runs `find`. Use `refresh_dir` when
   only a few files changed; use `change_dir` when the directory
   structure itself changed.

4. **Logging.** Use `ftl::log::info`, `ftl::log::warn`,
   `ftl::log::error` for user-visible messages. These respect the
   configured log level and write to the session log file.

5. **Tab indentation.** The `ftl::kbd::bind` call uses tabs (not
   spaces) to separate fields. This is a project convention; the parser
   handles both, but the `c` bindings table display relies on
   tab-delimited fields for column alignment.

### Live Loading

To load a binding without restarting ftl:

```
:source ~/.config/ftl/etc/bindings/my_compress
```

The `:` prompt opens the command dispatcher. The `source` command
re-sources the file, redefining the function and re-registering the
binding. This is sufficient for development; no restart is needed.

### Overriding and Unbinding

- **Override:** Call `ftl::kbd::bind` with the same key sequence. The
  new command replaces the old. Set `ftl_kbd_warn_on_override=1` first
  to receive a warning if you are stomping an existing binding.
- **Remove:** Call `ftl::kbd::unbind "<keys>"`.
- **Exclude from redo:** Call `ftl::kbd::exclude_from_redo "<command_fn>"`
  to prevent a command from being recorded as `ftl_kbd_last_command`
  (so `.` does not repeat it). Movement commands are excluded by
  default.

### Reserved Keys

The characters `å`, `Å`, `ä`, `Ä` are reserved for ftl's internal
tmux-signal IPC (see [IPC](./ipc.md)). Do not bind them.

---

## 2. Commands

A command is a script invoked from the `:` prompt. Commands have access
to ftl's state via environment variables and a serialized state file.

### Location

- `$FTL_CFG/etc/commands/<name>` — built-in
- `$FTL_CFG/commands/<name>` — user-defined

Both directories are searched; the first match wins.

### Contract

A command is either:

1. **Sourced** (not executable) — runs in ftl's shell with direct
   access to all `ftl::*` functions and globals. Arguments are in `$@`.
2. **Executable** — runs as a subprocess. Receives the serialized state
   via `$ftl_state_info_file_path` (which must be sourced to access
   ftl's state). Arguments are in `$@`.

### Sourced Command Example

```bash
# ~/.config/ftl/etc/commands/count_lines
# Count lines in all selected text files

{
    for f in "${ftl_selection_current[@]}" ; do
        if file "$ftl_state_current_path" | grep -q text| grep -q text ; then
            lines=$(wc -l < "$ftl_state_current_path")
            printf '%6d  %s\n' "$lines" "${f##*/}"
        fi
    done
} | ftl::pane::split_for_preview "cat ; read -sn 100"
```

Invoke with `:count_lines`. The script runs in ftl's shell, accesses
`ftl_selection_current` directly, and pipes output to the preview pane.

### Executable Command Example

```bash
#!/bin/bash
# ~/.config/ftl/etc/commands/external_info
# An executable command that reads ftl's serialized state

# Source the info file to get FTL_PID, FTL_SESSION_DIR, FTL_CWD, etc.
source "$ftl_state_info_file_path"

echo "ftl PID: $FTL_PID"
echo "Session dir: $FTL_SESSION_DIR"
echo "Current dir: $FTL_CWD"
echo "Current file: $ftl_state_current_path"
echo "Selection:"
printf '  %s\n' "${ftl_selection_current[@]}"

read -sn 1
```

Mark it executable (`chmod +x`) and invoke with `:external_info`.

### Key Points

1. **Argument passing.** Arguments after the command name are passed
   positionally. `:tree -L 2` invokes `etc/commands/tree` with `$1=-L`
   and `$2=2`.

2. **State access.** Sourced commands have direct access to all ftl
   globals (`ftl_state_*`, `ftl_selection_*`, `ftl_list_*`, etc.).
   Executable commands must `source "$ftl_state_info_file_path"` to
   receive a snapshot of `FTL_PID`, `FTL_SESSION_DIR`, `FTL_CWD`,
   `ftl_state_current_path`, and `ftl_selection_current`.

3. **Output.** Commands that produce output should pipe it to
   `ftl::pane::split_for_preview` (sourced) or write to a temp file and
   display it via `tmux popup` (executable). Direct stdout is not
   visible to the user because ftl owns the terminal.

4. **Built-in command forms.** The dispatcher (`ftl::cmd::dispatch_command`)
   recognizes several built-in forms before searching `etc/commands/`:
   - `qa` — quit all
   - `load_sel` — load selection from file
   - Numeric — goto entry by index
   - `full <cmd>` — run a command in a cleared screen, then refresh
   - `split <cmd>` — run a command in a split pane
   - `fsh <cmd>` — run a command in the session shell
   - Bound command name — dispatches the bound function

5. **Command aliases.** Set `ftl_cfg_command_aliases[<alias>]="<expansion>"`
   in `ftlrc` to alias a command name.

---

## 3. Filters

A filter plugin participates in the listing pipeline. It receives paths
on stdin and emits filtered paths on stdout. The external filter slot
(`ftl::filter::apply_external`) is the swap-in point.

### Location

- `$FTL_CFG/filters/<name>`

Filters are loaded lazily when selected via `fe` (cycle) or when
referenced by name.

### Contract

A filter plugin overrides `ftl::filter::apply_external`:

```bash
ftl::filter::apply_external() {
    ftl::plugin::my_filter::filter
}

ftl::plugin::my_filter::filter() {
    # Read paths from stdin, emit filtered paths on stdout
    local p
    while IFS= read -r p ; do
        # Filter logic here
        echo "$p"
    done
}
```

The filter function reads from stdin (the upstream `find` output) and
writes to stdout (consumed by the next pipeline stage). Filters must be
streaming — do not buffer the entire input.

### Reference Implementation

The following filter hides files larger than a configurable threshold.

```bash
# ~/.config/ftl/filters/by_max_size

declare -g ftl_plugin_by_max_size_limit=$(( 10 * 1024 * 1024 ))  # 10 MB default

ftl::plugin::by_max_size::filter() {
    local p size
    while IFS= read -r p ; do
        if [[ -f "$p" ]] ; then
            size=$(stat -c %s "$p" 2>/dev/null || echo 0)
            (( size <= ftl_plugin_by_max_size_limit )) && echo "$p"
        else
            # Always pass directories through
            echo "$p"
        fi
    done
}

ftl::filter::apply_external() {
    ftl::plugin::by_max_size::filter
}

# Reset hook: called when the filter is deactivated
ftl::plugin::by_max_size::reset() {
    :
}

# vim: set filetype=bash :
```

### Key Points

1. **Streaming.** The pipeline processes entries as they arrive from
   `find`. Do not collect all entries into an array before filtering —
   this defeats the streaming design and increases memory usage on
   large directories.

2. **State.** Filter plugins can use module-level globals (declared
   with `declare -g`) to maintain state across invocations. The
   `by_regexp` filter, for example, stores the regex pattern in a
   global so it persists across re-renders.

3. **Reset.** When a filter is deactivated (via `fe` cycling or
   `no_filter` selection), ftl calls the filter's `reset` function if
   defined. Use this to clear state. The `by_file` filter uses this to
   clear its whitelist.

4. **Pipeline order.** The external filter runs first, immediately
   after `find`. Subsequent stages (directory filter, two file filters,
   reverse filter, sort) see only the entries the external filter
   emitted.

5. **Performance.** Filters run on every directory scan. Avoid
   expensive operations (e.g. `stat` on network filesystems) inside
   the hot loop. Cache results in globals when possible.

---

## 4. Etags

An etag plugin annotates each listing entry with a short glyph column
displayed to the left of the filename. The etag is computed per-entry
and cached in an associative array.

### Location

- `$FTL_CFG/etags/<name>`

Etags are activated with `zT` (cycle through available etags) or
`:etags <name>` (activate by name).

### Contract

An etag plugin defines two functions:

```bash
# Scan the current directory and populate the tag arrays
ftl::etag::scan_directory() {
    # Populate:
    #   - one or more associative arrays mapping file paths to tag strings
    #   - these arrays are read by get_entry_tag
}

# Return the tag for a specific entry
# Args:
#   $1: file path
#   $2: nameref for the tag string (output)
#   $3: nameref for the tag width (output, for column alignment)
ftl::etag::get_entry_tag() {
    local -n r2=$2 r3=$3
    r2=...  # the tag string
    r3=...  # the width (number of display columns)
}
```

### Reference Implementation

The following etag displays the file's owner.

```bash
# ~/.config/ftl/etags/owner

declare -g -A owner_tags=()

ftl::etag::scan_directory() {
    declare -g -A owner_tags=()
    local f owner

    while IFS= read -r f ; do
        owner=$(stat -c %U "$ftl_state_current_path" 2>/dev/null || echo "?")
        # Truncate to 8 chars for column alignment
        owner="${owner:0:8}"
        owner_tags["$ftl_state_current_path"]="$owner"
    done < <(find "$PWD/" -maxdepth 1 2>/dev/null)
}

ftl::etag::get_entry_tag() {
    local -n r2=$2 r3=$3
    r2="${owner_tags[$1]:-?}"
    r3=8
}

# vim: set filetype=bash :
```

### Key Points

1. **Performance.** `scan_directory` runs on every directory change.
   For directories with thousands of entries, avoid per-file `stat`
   calls where possible. The `git` etag, for example, runs a single
   `git status --porcelain` and parses the output, rather than calling
   `git status` per file.

2. **Width.** The `r3` output (width) is used for column alignment. All
   entries in a directory should use the same width. If widths vary,
   the column will be ragged.

3. **Color.** Tag strings can include ANSI escape sequences for color.
   The `date` etag uses `\e[33m` (yellow) for the date. The `git` etag
   uses red for modified, green for staged, etc.

4. **The `none` etag.** The `none` etag is the default; its
   `scan_directory` is a no-op and `get_entry_tag` returns an empty
   string. Activate it with `zT` until "no etag" is selected, or
   `:etags none`.

---

## 5. Viewers

A viewer plugin renders the preview pane for a specific file type. The
core viewer dispatcher (`viewers/core`) routes by extension and MIME
type to viewer functions.

### Location

- `$FTL_CFG/viewers/<name>` — but in practice, most viewers are defined
  directly in `viewers/core`. User-defined viewers can override core
  functions by redefining them after `core` is sourced.

### Contract

A viewer function takes no arguments and renders the current file
(`$ftl_state_current_path`) to the preview pane. It typically:

1. Calls `ftl::prev::clear` to clear the preview pane
2. Invokes a backend program (`mupdf`, `mplayer`, `w3mimgdisplay`, etc.)
   in a tmux pane via `ftl::pane::split` or `ftl::pane::split_for_preview`
3. The backend program reads the file and renders output

### Reference Implementation

The following viewer previews CSV files using `column` for alignment.

```bash
# ~/.config/ftl/viewers/my_csv_viewer
# (sourced after viewers/core, so it can override or augment)

ftl::plugin::core::pcsv() {
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "column -t -s, '${ftl_state_current_path@Q}' | $ftl_cfg_markdown_pager ; read -sn 100"
}

# Register the viewer in the dispatcher by overriding pviewers
_ftl::plugin::core::pviewers_orig() { ftl::plugin::core::pviewers ; }

ftl::plugin::core::pviewers() {
    [[ $ftl_state_current_extension == csv ]] && { ftl::plugin::core::pcsv ; return ; }
    _ftl::plugin::core::pviewers_orig
}
```

### Key Points

1. **Two dispatchers.** `viewers/core` defines two dispatchers:
   `ftl::plugin::core::pviewers` (preview pane) and
   `ftl::plugin::core::ext_viewers` (external/alt-screen viewer). The
   preview dispatcher runs in the preview pane; the external dispatcher
   takes over the full terminal.

2. **`ftl::prev::clear`.** Always clear the preview pane before
   rendering. Stale content from the previous file will otherwise
   persist.

3. **Quoting.** Use `${ftl_state_current_path@Q}` (Bash 4.4+) to safely
   quote the file path for shell interpolation. This handles paths with
   spaces, quotes, and other special characters.

4. **Backend selection.** The `ftl_cfg_*` variables define which
   backend to use for each type (e.g. `ftl_cfg_markdown_pager`,
   `ftl_cfg_hex_viewer`, `ftl_cfg_diff_tool`). Users override these in
   `ftlrc`. Viewer functions should reference these variables rather
   than hardcoding program names.

5. **Read pause.** Interactive viewers (text, code) should end with
   `read -sn 100` to pause before returning control to ftl. Without
   this, the preview pane closes immediately after the backend exits.

6. **Image preview.** Image preview uses `w3mimgdisplay` (or the
   configured image preview backend) which writes directly to the
   terminal's image buffer. This requires terminal support (kitty,
   wezterm, iTerm2, or `w3m` with X11). The `pimage` function in
   `core` handles this; user viewers that need image display should
   delegate to `pimage` or `ftl::prev::show_image`.

---

## 6. Generators

A generator produces a preview thumbnail for a file type that requires
pre-processing. Generators are executable scripts invoked by the
`generators/generator` driver.

### Location

- `$FTL_CFG/generators/<extension>` — the filename must match the file
  extension it handles (e.g. `generators/pdf` handles `.pdf` files).

### Contract

A generator is an executable script that receives:

- `$1` — the source file path
- `$2` — the output directory (write thumbnails here)

The generator must write at least one thumbnail file to `$2`. The
driver handles caching via md5sum-based invalidation: if the source
file's md5 matches the cached md5, the generator is not re-run.

### Reference Implementation

The following generator renders the first page of a PDF as a PNG
thumbnail.

```bash
#!/bin/bash
# ~/.config/ftl/generators/pdf_first_page
# Render the first page of a PDF as a PNG thumbnail

# $1 = source file, $2 = output directory
src="$1"
outdir="$2"

mkdir -p "$outdir"
exec 2>>"$outdir/generators_log"

# Compute a stable filename based on the source's md5
md5=$(md5sum <<<"$src" | cut -d' ' -f1)
basename="${src##*/}"
thumb="$outdir/${md5}_${basename%.*}.png"

# Render the first page at 1000px wide
pdftoppm -png -r 150 -f 1 -l 1 "$src" "$outdir/${md5}_${basename%.*}" 2>/dev/null

# pdftoppm appends -1.png, so rename if needed
[[ -f "$outdir/${md5}_${basename%.*}-1.png" ]] && \
    mv "$outdir/${md5}_${basename%.*}-1.png" "$thumb"

# vim: set filetype=bash :
```

Mark it executable (`chmod +x`).

### Key Points

1. **Caching.** The `generators/generator` driver computes the source
   file's md5 and checks a cache. If the md5 matches the cached value,
   the generator is not invoked. Generators must therefore produce
   deterministic output for a given input.

2. **Output filename.** Use a stable filename (incorporating the md5)
   to avoid collisions when multiple files of the same type are
   previewed. The driver scans `$outdir` for thumbnails matching the
   current source.

3. **Logging.** Redirect stderr to `$outdir/generators_log` for
   debugging. The driver does not display generator errors to the user.

4. **Backend tools.** Generators depend on external tools (`pdftoppm`,
   `ffmpeg`, `identify`, `rsvg-convert`, etc.). Document these
   dependencies in a comment. The generator should fail gracefully (no
   output) if the backend is missing, rather than crashing.

5. **The driver.** `generators/generator` is the entry point. It
   receives the source file path, computes the md5, checks the cache,
   and dispatches to the appropriate generator based on the file
   extension. `generators/generator_one` is a testing utility that
   runs all generators against a single file.

---

## 7. Conventions and Pitfalls

### Naming

- **Functions:** `ftl::plugin::<plugin_name>::<function>` (e.g.
  `ftl::plugin::my_compress::run`). The double-colon namespace is
  parsed correctly by Bash 5+ and avoids collisions with core
  functions.
- **Variables:** `ftl_plugin_<plugin_name>_<var>` (e.g.
  `ftl_plugin_by_max_size_limit`). Use `declare -g` for module-level
  globals.
- **Files:** Plugin filenames should be lowercase, underscore-separated
  (`my_compress`, `by_max_size`). Avoid uppercase and hyphens.

### Tab Indentation

The project uses **tabs** (not spaces) for indentation in Bash files.
The `ftl::kbd::bind` call uses tabs to separate fields; the `c`
bindings table relies on tab-delimited fields for column alignment.
Configure your editor to insert tabs, not spaces.

### `set -u`

ftl runs under `set -u` (treat unset variables as an error). Always
provide defaults when accessing potentially-unset variables:

```bash
# Bad: crashes if ftl_selection_tags is unset
for p in "${!ftl_selection_tags[@]}" ; do ...

# Good: defaults to empty array
for p in "${!ftl_selection_tags[@]:-}" ; do ...

# Better: use the +u guard for the whole expansion
local -n tags=ftl_selection_tags
for p in "${!tags[@]:-}" ; do ...
```

### Subshells and Array Mutation

Functions that modify arrays must not run in a subshell. The
`ftl::cmd::prompt` function uses `read -e -rp` which runs in the
current shell; the result is in `$REPLY`. Do not wrap prompt-reading
code in `$(...)` or pipe it, or the array mutations will be lost.

### State Serialization

ftl's state is serialized to `$ftl_state_session_dir/ftl` (a Bash
sourceable file) by `ftl::state::save`. This file is read by the
preview pane and sibling ftl processes. Do not store transient or
large data in `ftl_state_*` variables — they will be serialized on
every render.

### Testing

Test files live in `test/unit/` and `test/integration/`. The harness
(`test/harness.sh`) auto-discovers `test_*.sh` files. Each test file
sources the modules under test, defines `test_*` functions, and the
harness runs them in subshells with `ftl::test::setup` before and
`ftl::test::teardown` after.

For binding plugins, test that the function is defined and that the
trie entry exists. For commands and filters, test the function's
behavior against a temp directory. Refer to
`test/unit/test_inline_rename.sh` and
`test/unit/test_missing_functionalities_behavior.sh` for patterns.

### Live Development Workflow

1. Edit the plugin file.
2. From the `:` prompt, run `:source ~/.config/ftl/etc/bindings/my_plugin`.
3. Test the binding.
4. If broken, edit and re-source.
5. Commit when stable.

No restart is needed for bindings, commands, etags, or filters.
Viewers and generators may require a re-render (`r` or move the
cursor) to pick up changes.

### Reference Plugins

The ftl distribution ships reference implementations for every plugin
category. Read them as templates:

| Category | Reference File | Notes |
|----------|----------------|-------|
| Binding | `etc/bindings/incremental_search` | Minimal: 1 function, 1 bind call |
| Binding | `etc/bindings/leader_ftl` | Library pattern: sources `lib/compress`, `lib/optimize`, `lib/extra` |
| Binding | `bindings/missing_functionalities` | Large: 42 features, 582 lines |
| Command | `etc/commands/01_example` | Sourced command template |
| Command | `etc/commands/02_example` | Executable command template |
| Command | `etc/commands/tree` | Minimal executable: 1 line |
| Filter | `filters/by_regexp` | Stateful filter with reset |
| Filter | `filters/by_size` | Filter with persistence |
| Etag | `etags/git` | Single `git status` call, parsed |
| Etag | `etags/lines` | Per-file `wc -l` |
| Viewer | `viewers/core` | The full dispatcher (~25 viewer functions) |
| Generator | `generators/pdf` | `pdftoppm`-based thumbnail |
| Generator | `generators/mp4` | `ffmpeg`-based thumbnail |

## See Also

- [Writing Bindings](./writing-bindings.md) — detailed binding plugin guide
- [Writing Commands](./writing-commands.md) — detailed command guide
- [Writing Filters](./writing-filters.md) — detailed filter plugin guide
- [Writing Etags](./writing-etags.md) — detailed etag plugin guide
- [Writing Viewers](./writing-viewers.md) — detailed viewer plugin guide
- [Plugin API](./plugins.md) — the 6 plugin categories
- [Extra Features](./extra-features.md) — catalog of shipped plugins
