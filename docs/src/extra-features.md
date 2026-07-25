# Extra Features

This document catalogs every binding, command, etag, filter, viewer,
and generator shipped with ftl. It is intended as a reference for users
discovering ftl's capabilities and as a starting point for
contributors evaluating existing code before writing new plugins.

The ftl distribution comprises six plugin categories distributed across
two directory trees:

- `config/ftl/etc/<category>/` — the canonical location, sourced at
  install time
- `config/ftl/<category>/` — a user-writable mirror with the same
  structure; ftl sources both trees

At startup, `ftl_setup` sources `etc/ftlrc`, which in turn auto-sources
every file in `etc/bindings/` and `bindings/`. Etags, filters, viewers,
and commands are loaded lazily — only when selected at runtime.

---

## Table of Contents

1. [Bindings](#1-bindings)
2. [Commands](#2-commands)
3. [Etags](#3-etags)
4. [Filters](#4-filters)
5. [Generators](#5-generators)
6. [Viewers](#6-viewers)

---

## 1. Bindings

Binding plugins register key sequences via `ftl::kbd::bind`. They are
auto-sourced at startup from `etc/bindings/` (built-in) and `bindings/`
(user). Each binding file defines one or more functions and registers
them with the keyboard trie.

### Built-in Bindings (`etc/bindings/`)

| File | Purpose | Key Examples |
|------|---------|--------------|
| `leader` | Leader-key help system (`LEADER h h` opens a tmux popup with the help index) | `LEADER h h`, `LEADER h n`, `LEADER h p` |
| `leader_ftl` | File-utility family: compress, decompress, GPG encrypt, image/video/PDF optimization, mail, shell popup | `LEADER f c` (compress), `LEADER f d` (decompress), `LEADER f e` (GPG), `LEADER f i` (image optimize), `LEADER f p` (PDF optimize), `LEADER f v` (video optimize), `LEADER s` (shell popup) |
| `leader_git` | Git operations via leader | `LEADER g *` sequences |
| `incremental_search` | Live incremental search (`/`) with cursor color change and `LEADER` to add a space to the search string | `/` |
| `fzf_search` | fzf-based file search with HTTP-polled backend support | `\f` |
| `inline_rename` | Modal rename workflow: single, sequential, regexp, image-label | `LEADER r i` |
| `add_to_a_log` | Append the current path to a log file | `LEADER ${ftl_kbd_altgr_map[t]}` |
| `shred` | Secure file deletion via `shred` | (bound in ftlrc) |
| `to_other_tab` | Send the current entry or selection to another tab | (bound in ftlrc) |
| `user_command` | FZF-selectable user command runner | `LEADER u` |
| `lib/compress` | Library: tar.bz2 compression/decompression (sourced by `leader_ftl`) | — |
| `lib/optimize` | Library: image/video/PDF optimization (sourced by `leader_ftl`) | — |
| `lib/extra` | Library: PDF-to-text, rmlint, mutt mail, shell popup, stat file (sourced by `leader_ftl`) | — |

### User Bindings (`bindings/`)

| File | Purpose | Key Examples |
|------|---------|--------------|
| `change_mode` | chmod dialog via whiptail for the current entry | `xmm` |
| `file_diff` | Diff exactly 2 selected files (or directories) | `\d` |
| `fzf_pane_preview` | Experimental fzf search with ftl preview in a pane | (experimental) |
| `missing_functionalities` | 42 extended features: duplicate, hardlink, touch, checksums, rename_pattern, chmod_numeric, chown, selection_invert, select_by_pattern, select_by_size, size_analysis, nav_back/forward, move_left_select, marks_manage, selection_save/load/union/intersect/subtract, visual_mode, rg_replace, find_with_history, preview_pin/unpin/compare/zoom/rotate/tail_live, command_palette, workspace_save/load, git_blame/log/diff_stat, compress_zip/7z, archive_list, scp_upload, download_url | `xd`, `xH`, `xt`, `xs`, `xv`, `xR`, `xn`, `xo`, `zA`, `ALT-z`, `ALT-y`, `H`, `mM`, `yi`, `yp`, `yz`, `yS`, `yL`, `yu`, `yd`, `v`, `rR`, `rh`, `zp`, `zP`, `zpc`, `zi`, `zo`, `zr`, `zL`, `CP`, `LEADER ws`, `LEADER wl`, `gbl`, `gll`, `gds`, `LEADER fz`, `LEADER f7`, `LEADER fl`, `LEADER su`, `LEADER dl` |
| `project_marks` | Per-project bookmark management with hierarchical search (`.ftl_project_marks` files searched upward and downward) | (bound in plugin) |
| `tmsu` | TMSU tagging integration: preview shows tags, manage tags via fzf | (bound in plugin) |
| `type_handlers` | Type-aware navigation: enter archives as virtual directories, exit on `h` | `l` (on archives), `h` (to exit) |
| `via_bash` | Run a Bash command on the selection, capturing output | (bound in plugin) |
| `virtual_entries` | Injects virtual directories and files with custom previews and key handling (reference implementation) | (auto-injected) |

---

## 2. Commands

Commands are invoked from the `:` prompt (opened with `:`). They are
sourced or executed Bash scripts in `etc/commands/`. Arguments are
passed positionally. Commands have access to ftl's environment via
`$FTL_PID`, `$FTL_SESSION_DIR`, `$FTL_CWD`, and the serialized state in
`$ftl_state_info_file_path`.

| Command | Invocation | Description |
|---------|------------|-------------|
| `01_example` | `:01_example` | Reference implementation: a sourced script that writes ftl state to `$fs/01_example_info` |
| `02_example` | `:02_example` | Reference implementation: an executable script that reads `$ftl_state_info_file_path` |
| `etags` | `:etags <name>` | Activates the named etag plugin (or opens an fzf list if no name given) |
| `fma` | `:fma <args>` | Adds paths to the fzf-mv queue |
| `fmr` | `:fmr` | Runs the fzf-mv rename operation (removes from queue) |
| `ftlrc_dir` | `:ftlrc_dir` | Sources a per-directory `.ftlrc_dir` override (called automatically by `change_dir`) |
| `open_with` | `:open_with` | Opens the current file with a viewer selected from a MIME-type / extension table |
| `show_cmd_log` | `:show_cmd_log` | Displays the command log in a tmux popup |
| `tree` | `:tree [args]` | Runs `tree -C` in a tmux popup at 90% width/height |
| `url` | `:url <URL>` | Opens the given URL in `qutebrowser` (or the configured browser) |

### Authoring Commands

A command is a Bash script. If executable, it is invoked directly; if
not executable, it is sourced. Sourced commands run in ftl's shell and
have direct access to all `ftl::*` functions and globals. Executable
commands receive the serialized state via `$ftl_state_info_file_path`
and must `source` it to access ftl's state.

Refer to [Extending ftl — Commands](./extending-ftl.md#commands) for
the authoring walkthrough.

---

## 3. Etags

Etags (extension tags) annotate each listing entry with a short glyph
column to the left of the filename. The etag plugin scans the directory
and populates an associative array mapping file paths to tag strings.
Etags are activated with `zT` (cycle) or `:etags <name>`.

| Etag | Description | Sample Output |
|------|-------------|---------------|
| `none` | No etags (default) | (empty) |
| `date` | Modification date (MM-DD) | `07-24` |
| `git` | Git status (modified, staged, untracked, etc.) | `M`, `A`, `??` |
| `image_size` | Image dimensions (WxH) | `1920x1080` |
| `lines` | Line count for text files | `  42` |
| `tmsu` | TMSU tags for the file | `tag1,tag2` |
| `virtual` | Etag for virtual entries (used by `virtual_entries` binding) | (entry-specific) |

### Authoring Etags

An etag plugin defines two functions: `ftl::etag::scan_directory()`
(populates the tag arrays) and `ftl::etag::get_entry_tag()` (returns
the tag for a specific entry). Refer to
[Extending ftl — Etags](./extending-ftl.md#etags) for the contract.

---

## 4. Filters

Filters participate in the listing pipeline. They sit between `find`
and the sort stage, receiving paths on stdin and emitting filtered
paths on stdout. Filters are activated with `fe` (cycle) or selected
directly.

### Filter Plugins

| Filter | Description |
|--------|-------------|
| `no_filter` | Pass-through (no filtering) |
| `no_sort` | Disable sorting (preserve `find` order) |
| `by_extension` | Show only entries matching a configured extension set |
| `by_no_extension` | Show only entries without an extension |
| `by_file` | Per-directory file whitelist (persists across `cd`) |
| `by_file_global` | Global file whitelist (applies across all directories) |
| `by_file_reset_dir` | `by_file` with a reset variant |
| `by_file_global_reset_dir` | `by_file_global` with a reset variant |
| `by_all_files` | Show all files (overrides other filters) |
| `by_all_files_reset` | Reset variant of `by_all_files` |
| `by_bash_hide` | Hide entries matching a Bash expression |
| `by_bash_keep` | Keep only entries matching a Bash expression |
| `by_only_tagged` | Show only tagged entries |
| `by_regexp` | Filter by regex on the basename |
| `by_size` | Filter by file size (min/max) |
| `by_tag` | Filter by TMSU tag |
| `by_tag_query` | Filter by TMSU tag query (complex expressions) |
| `by_visible_entries` | Show only entries currently visible (used internally) |
| `sort_by_extension` | Sort entries by extension |

### Filter Pipeline

The listing pipeline applies filters in this order:

1. `find` emits raw entries
2. External filter (`ftl::filter::apply_external`) — the swap-in plugin slot
3. Directory filter (`ftl::tab_filter_dirs[$tab]`)
4. File filter 1 (`ftl::tab_filter_1[$tab]`)
5. File filter 2 (`ftl::tab_filter_2[$tab]`)
6. Reverse filter (`ftl::tab_filter_reverse[$tab]`)
7. Sort (`ftl::filt::sort_entries`)

Refer to [Extending ftl — Filters](./extending-ftl.md#filters) for the
authoring contract.

---

## 5. Generators

Generators produce preview thumbnails for file types that require
pre-processing (e.g. extracting a PDF page as an image, rendering an
STL model, generating a montage). They are executable scripts invoked
by `generators/generator` (the driver).

Each generator receives two arguments: the source file path and an
output directory. The generator writes one or more thumbnail files to
the output directory. The driver handles caching via md5sum-based
invalidation.

| Generator | File Type | Description |
|-----------|-----------|-------------|
| `apng` | Animated PNG | Extracts frames for animated preview |
| `cbr` | Comic book (RAR) | Extracts first page as JPEG |
| `cbz` | Comic book (ZIP) | Extracts first page as JPEG |
| `epub` | EPUB ebook | Renders cover image |
| `flv` | Flash video | Extracts first frame |
| `gif` | Animated GIF | Extracts frames for animated preview |
| `html` | HTML | Renders page as image (via `wkhtmltoimage` or similar) |
| `mkv` | Matroska video | Extracts first frame |
| `montage` | Directory | Generates a thumbnail montage of directory contents |
| `mp3` | MP3 audio | Extracts album art |
| `mp4` | MP4 video | Extracts first frame |
| `pdf` | PDF | Renders first page as image |
| `stl` | STL 3D model | Renders the model |
| `svg` | SVG | Rasterizes to PNG |
| `svg_to_pdf` | SVG | Converts to PDF (for PDF-based preview) |
| `webm` | WebM video | Extracts first frame |
| `generator` | (driver) | Dispatches to the appropriate generator based on extension |
| `generator_one` | (utility) | Runs all generators against a single file (for testing) |

### Authoring Generators

A generator is an executable Bash script. It receives `$1` (source
file) and `$2` (output directory). It must write at least one thumbnail
to `$2`. Refer to [Extending ftl — Generators](./extending-ftl.md#generators)
for the contract.

---

## 6. Viewers

Viewers render the preview pane for a given file type. The core viewer
dispatcher (`viewers/core`) is a large case statement that routes by
extension and MIME type to viewer functions (`pimage`, `ppdf`, `pmp3`,
`pmedia`, `pmd`, `pjson`, `pyaml`, `pcbr`, `pcbz`, `phtml`, `psvg`,
`pgif`, `pepub`, `pman`, `pcomp`, `ppipe`, `pscim`, `pstl`, `pasciio`,
`ptext`, `pansi`, `pdir`, `plock`, etc.).

### Shipped Viewers

| Viewer | Description |
|--------|-------------|
| `core` | The core dispatcher; routes by extension/MIME to specific viewer functions. Defines ~25 viewer functions covering images, PDFs, video, audio, markdown, JSON, YAML, archives, comics, ebooks, STL, man pages, pipes, sc-im, asciio, text, ANSI, and directories. |
| `cmus` | Audio preview via `cmus` (music player) |
| `mplayer_background` | Video/audio preview via `mplayer` running in the background |
| `mplayer_local` | Video/audio preview via `mplayer` in the local pane |
| `vlc` | Video/audio preview via `vlc` |

### Viewer Functions in `core`

The `core` viewer defines the following functions, each handling a
specific file type:

| Function | Handles | Backend |
|----------|---------|---------|
| `pimage` | JPEG, PNG, GIF, WebP, TIFF, BMP, HEIC | `w3mimgdisplay` |
| `ppdf` | PDF | `mupdf` or `pdftoppm` |
| `pmp3` | MP3 | `exiftool` + album art |
| `pmedia` | Video, other audio | `mplayer` / `vlc` |
| `pmd` | Markdown | configured markdown pager (`glow`, `moar`, etc.) |
| `pjson` | JSON | `jless` or `jq` |
| `pyaml` | YAML | `yam -i` |
| `pcbr` / `pcbz` | Comic books | `zathura` / `mcomix` |
| `phtml` | HTML | `qutebrowser` or `wkhtmltoimage` |
| `psvg` | SVG | `rsvg-convert` or `inkscape` |
| `pgif` | Animated GIF | frame extraction + `w3mimgdisplay` |
| `pepub` | EPUB | cover extraction |
| `pman` | Man pages | `man -l` |
| `pcomp` | Archives (zip, rar, tar) | `unzip -l` / `unrar l` / `tar -tf` |
| `ppipe` | Named pipes | `cat` with timeout |
| `pscim` | sc-im spreadsheets | `sc-im` |
| `pstl` | STL 3D models | configured STL viewer |
| `pasciio` | Asciio diagrams | `asciio` |
| `ptext` | Text files | `$PAGER` with syntax highlighting |
| `pansi` | Files with ANSI escapes | `cat` (raw) |
| `pdir` | Directories | configurable: ftl, du, ls, README, exa, or image montage |
| `plock` | Pinned previews | displays the lock file contents |

### Authoring Viewers

A viewer plugin defines a function (e.g. `pmytype`) and registers it
in the dispatcher. Refer to [Extending ftl — Viewers](./extending-ftl.md#viewers)
for the contract.

---

## Reference

- [Plugin API](./plugins.md) — the 6 plugin categories at a glance
- [Extending ftl](./extending-ftl.md) — authoring guide for each plugin type
- [Writing Bindings](./writing-bindings.md), [Writing Commands](./writing-commands.md), [Writing Filters](./writing-filters.md), [Writing Etags](./writing-etags.md), [Writing Viewers](./writing-viewers.md) — per-category deep dives
- [Missing Functionalities](./missing-functionalities.md) — 42 extended features with full reference documentation
