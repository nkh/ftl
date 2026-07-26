# ftl — 30 Architectural Expansion Ideas

> **Subject:** Large-scale architectural changes that could be
> integrated into ftl itself or its architecture. These are not
> plugins (5-line Bash scripts) — they are fundamental changes to
> ftl's structure, capabilities, or interaction model.
> **Purpose:** Provide a roadmap for ftl's long-term evolution beyond
> incremental plugin additions.
> **Companion documents:** `ftl-adventurous-ideas.md` (50 ideas,
> mostly plugins), `ftl-missing-functionality-v2.md` (60 proposals),
> `ftl-plugin-ideas.md` (25+25), `ftl-help-system-design.md`.
> **Status:** Proposals — not yet implemented. Several would require
> significant refactoring or architectural redesign.

---

## Table of Contents

1. [Multi-Argument Virtual Directory](#1-multi-argument-virtual-directory)
2. [Async I/O via Background Coprocesses](#2-async-io-via-background-coprocesses)
3. [Plugin Package Manager](#3-plugin-package-manager)
4. [Embedded Scripting Engine (Lua/Python)](#4-embedded-scripting-engine)
5. [Configuration Validation and Schema](#5-configuration-validation-and-schema)
6. [Structured State Backend (SQLite/JSON)](#6-structured-state-backend)
7. [Network Transparent Operation](#7-network-transparent-operation)
8. [Event-Driven Architecture](#8-event-driven-architecture)
9. [Undo/Redo Infrastructure](#9-undoredo-infrastructure)
10. [Persistent Selection Across Sessions](#10-persistent-selection-across-sessions)
11. [Multi-Pane Layout System](#11-multi-pane-layout-system)
12. [File System Watcher Framework](#12-file-system-watcher-framework)
13. [Permission and Sandboxing Model](#13-permission-and-sandboxing-model)
14. [Internationalization (i18n) Framework](#14-internationalization-framework)
15. [Accessibility (a11y) Layer](#15-accessibility-layer)
16. [Remote Protocol (gRPC/JSON-RPC)](#16-remote-protocol)
17. [Embedded Documentation Engine](#17-embedded-documentation-engine)
18. [Build System Integration](#18-build-system-integration)
19. [Version Control Abstraction Layer](#19-version-control-abstraction-layer)
20. [Content-Addressed File Cache](#20-content-addressed-file-cache)
21. [Distributed ftl (Multi-Machine)](#21-distributed-ftl)
22. [Embedded Database Query Interface](#22-embedded-database-query-interface)
23. [Terminal Protocol Abstraction](#23-terminal-protocol-abstraction)
24. [Plugin Dependency Resolution](#24-plugin-dependency-resolution)
25. [Hot-Reload Architecture](#25-hot-reload-architecture)
26. [Structured Logging and Telemetry](#26-structured-logging-and-telemetry)
27. [Compression-Aware File Operations](#27-compression-aware-file-operations)
28. [Cross-Platform Abstraction (macOS/BSD/Windows)](#28-cross-platform-abstraction)
29. [Embedded Test Framework for Plugins](#29-embedded-test-framework-for-plugins)
30. [Semantic File System Layer](#30-semantic-file-system-layer)

---

## 1. Multi-Argument Virtual Directory

**Scale:** Large. Changes CLI parsing, listing pipeline, and rendering.

### Problem

ftl currently accepts a single directory or file argument:

```bash
ftl ~/projects        # one directory
ftl ~/file.txt        # one file (opens parent, selects file)
```

Users often want to work with multiple files or directories
simultaneously — e.g. comparing two directories, working with files
from different locations, or curating a temporary working set.

### Proposal

Accept multiple path arguments. When more than one is given, ftl
creates a **virtual directory** that aggregates them:

```bash
ftl ~/projects/a ~/projects/b ~/docs/report.pdf
```

This opens ftl in a virtual listing showing:
```
  a/          (directory, from ~/projects/)
  b/          (directory, from ~/projects/)
  report.pdf  (file, from ~/docs/)
```

### Architecture

- **CLI parsing:** `bin/ftl` collects all non-option arguments into
  an array. If the array has 0 or 1 elements, behavior is unchanged.
  If it has 2+, enter virtual-directory mode.

- **Virtual directory state:** A new global
  `ftl_state_virtual_dir_paths` (indexed array of absolute paths).
  When set, `ftl::list::change_dir` skips the `find` scan and instead
  populates `ftl_list_entries` from the array.

- **Navigation:** `Enter` on a virtual entry `cd`s to its real
  location. `h` (parent) exits the virtual directory (returns to
  `$HOME` or the last real directory).

- **Rendering:** A header indicator `[VIRTUAL]` distinguishes the
  virtual listing. Entries show their real path in the etag column or
  a tooltip.

- **Selection:** Works normally — tag entries, copy, move, etc. The
  operations affect the real files.

- **Persistence:** The virtual directory can be saved as a workspace
  (`\ws`) and restored later.

### Use cases

- Compare two directories side by side (open both in a virtual dir,
  tag differences)
- Curate a working set from multiple locations (tag files from
  different projects)
- Bulk rename across directories (select all, `LEADER r i`, regexp
  rename)
- Clean up downloads (open `~/Downloads/*.pdf` as a virtual dir,
  review, delete)

### Impact

- `bin/ftl`: +30 lines for multi-arg parsing
- `list.sh`: +50 lines for virtual-dir scan path in `change_dir`
- `keyboard.sh` or `commands/movement.sh`: +10 lines for
  virtual-aware `h` (exit virtual dir)
- New config: `ftl_cfg_virtual_dir_glyph` for the header indicator
- Tests: new test file for virtual-dir behavior

---

## 2. Async I/O via Background Coprocesses

**Scale:** Large. Changes the listing pipeline and main loop.

### Problem

ftl's listing pipeline is synchronous. A slow `find` on NFS or a
large directory blocks the main loop — no keys are processed until
the scan completes. This is the single biggest performance complaint.

### Proposal

Run the `find` + filter pipeline in a **background coprocess**. The
main loop continues processing keys. When the pipeline completes,
ftl renders the results.

### Architecture

- **Coprocess:** Use Bash 4+ `coproc` to run the pipeline:
  ```bash
  coproc ftl::list::scan_pipeline {
      find ... | filter ... | sort ...
  } 2>"$ftl_state_session_dir/scan.log"
  ```

- **State:** A new `ftl_state_scan_in_progress` flag. While set,
  `ftl::list::render` shows a "scanning..." indicator. Key presses
  are buffered or queued.

- **Completion detection:** The main loop checks
  `ftl_state_scan_in_progress` on each iteration. When the coproc's
  fd closes (EOF), the scan is done. Read the results from a temp
  file or named pipe.

- **Cancellation:** If the user navigates away (presses `h` or
  `cd`s elsewhere) while a scan is in progress, kill the coproc
  (`kill $COPROC_PID`) and start a new one for the new directory.

- **Progress:** For very large directories, the pipeline can emit
  progress (entry count) to a separate fd, which the main loop
  displays.

### Challenges

- Bash's `coproc` is limited (one coproc at a time, no easy way to
  check if it's still running without blocking).
- Cancellation requires tracking the coproc PID and sending signals.
- The current four-FIFO pipeline is already complex; adding async
  increases complexity.
- Alternative: use a background `bash -c` process with a PID file,
  checked via `kill -0 $pid` on each main-loop iteration.

### Impact

- `list.sh`: significant changes to `scan_and_render` and
  `apply_filters_and_format`
- `bin/ftl`: main loop changes to check scan status
- New state: `ftl_state_scan_in_progress`, `ftl_state_scan_pid`,
  `ftl_state_scan_progress`
- Tests: hard to test async in the current synchronous harness

---

## 3. Plugin Package Manager

**Scale:** Large. New subsystem.

### Problem

ftl plugins are currently installed by copying files into
`$FTL_CFG/bindings/`, `$FTL_CFG/filters/`, etc. There is no
dependency resolution, version management, or central repository.

### Proposal

A plugin package manager (`ftl-plugin` or `ya pkg`-equivalent) that:

- Installs plugins from a Git repository or tarball
- Tracks installed plugins and their versions
- Resolves dependencies (plugin A requires plugin B)
- Updates and uninstalls plugins
- Lists available plugins from a community registry

### Architecture

- **Plugin manifest:** Each plugin ships a `plugin.toml` (or
  `plugin.sh` with header metadata):
  ```toml
  name = "my-filter"
  version = "1.0.0"
  category = "filter"
  description = "Filter by max file size"
  depends = []
  conflicts = []
  ```

- **Plugin store:** `$FTL_STATE_DIR/plugins/installed/` — one
  directory per plugin, containing the plugin files and manifest.

- **Registry:** A community-maintained Git repository
  (`ftl-plugins/registry`) listing available plugins. `ftl-plugin
  search <query>` queries it.

- **Commands:** `ftl-plugin install <name>`, `ftl-plugin update
  [<name>]`, `ftl-plugin remove <name>`, `ftl-plugin list`,
  `ftl-plugin search <query>`.

- **Integration with ftl:** At startup, `ftl_setup` sources installed
  plugins from `$FTL_STATE_DIR/plugins/installed/*/` in dependency
  order.

### Impact

- New CLI tool (`config/ftl/etc/bin/ftl-plugin`)
- New state directory (`$FTL_STATE_DIR/plugins/`)
- `ftl_setup` changes to source from the plugin store
- Documentation: plugin authoring guide with manifest format
- Community: a registry repository

---

## 4. Embedded Scripting Engine (Lua/Python)

**Scale:** Very large. Adds a new extension language.

### Problem

ftl plugins are written in Bash. This is accessible but limiting:
no data structures beyond arrays/assoc arrays, no closures, no
modules, no error handling beyond exit codes. Complex plugins
(`missing_functionalities`, `inline_rename`) become hard to maintain.

### Proposal

Embed a scripting engine (Lua or Python) for complex plugin logic.
Bash remains the "glue" (sourcing, binding registration), but the
implementation of complex commands can be in Lua/Python.

### Architecture

- **Lua embedding:** Use `lua` as a coprocess. ftl sends commands via
  a pipe, receives results via another. State is shared via
  environment variables or a serialized JSON file.

- **Python embedding:** Use `python3 -i` as a coprocess, or use
  `python3 -c` for one-shot invocations. The `finfo` command already
  does this pattern.

- **Plugin contract:** A Lua/Python plugin defines functions that
  ftl calls via the embedded engine. The functions receive ftl's
  state (as a JSON dict) and return actions (as JSON).

- **Hybrid:** Bash plugins remain for simple cases. Lua/Python plugins
  are for complex logic (parsing, data transformation, network
  operations).

### Challenges

- Performance: spawning a Lua/Python interpreter per key press is
  slow. A persistent coprocess is needed.
- State sync: ftl's globals must be exported to the scripting engine
  on each call.
- Two extension models (Bash + Lua) increases complexity.

### Impact

- New dependency: `lua5.3` or `python3`
- New module: `config/ftl/etc/core/modules/scripting.sh`
- Changes to `ftl::kbd::bind` to accept Lua/Python functions
- New plugin directories: `plugins/lua/`, `plugins/python/`

---

## 5. Configuration Validation and Schema

**Scale:** Medium. New subsystem.

### Problem

`ftlrc` is a Bash script with no validation. Typos in variable names
(`ftl_cfg_leader_keys` instead of `ftl_cfg_leader_key`) are silently
ignored. Invalid values (`ftl_cfg_move_step_size="abc"`) cause
arithmetic errors at runtime. There is no way to check the config
without running ftl.

### Proposal

A configuration schema and validator:

- **Schema:** A declarative file (`config/ftl/etc/schema.toml`) listing
  all valid `ftl_cfg_*` variables, their types, default values, and
  constraints.

- **Validator:** `ftl --check-config` sources `ftlrc` and checks every
  `ftl_cfg_*` variable against the schema. Reports type mismatches,
  unknown variables, and out-of-range values.

- **Runtime validation:** On startup, ftl checks critical variables
  (those used in arithmetic) and warns if they are non-numeric.

### Architecture

```toml
# schema.toml
[ftl_cfg_leader_key]
type = "string"
default = "BACKSLASH"
description = "The leader key"

[ftl_cfg_move_step_size]
type = "integer"
default = 4
min = 1
max = 100
description = "Number of entries to move with J/K"
```

### Impact

- New file: `config/ftl/etc/schema.toml`
- New CLI flag: `--check-config`
- New module: `config/ftl/etc/core/modules/config_validate.sh`
- Documentation: every `ftl_cfg_*` variable documented in the schema

---

## 6. Structured State Backend (SQLite/JSON)

**Scale:** Very large. Replaces the filesystem-based state.

### Problem

ftl's state is serialized as Bash-sourceable files (`$ftl_state_session_dir/ftl`,
`tags`, etc.). This works but has limitations:
- No querying (find all tagged files matching a pattern)
- No history (what was the cursor position 5 renders ago?)
- No concurrent access (two ftl instances writing to the same file
  corrupt it)
- No size limits (large selections make `tags` huge)

### Proposal

Use SQLite (or a structured JSON store) as the state backend.

### Architecture

- **Database:** `$FTL_STATE_DIR/state.db` (SQLite). Tables:
  `sessions`, `tabs`, `selections`, `marks`, `history`, `cursor_memory`.

- **Access layer:** `ftl::state::db_query`, `ftl::state::db_exec` —
  wrappers around `sqlite3`.

- **Migration:** The current file-based state is imported into the
  database on first run. File-based state is kept as a fallback.

- **Querying:** New commands like `:query selection WHERE class=1`
  or `:query history WHERE path LIKE '%/src/%'`.

### Challenges

- Adds a `sqlite3` dependency
- Bash's interaction with SQLite is via subprocess (`sqlite3` CLI),
  which is slow for frequent access
- The current file-based approach is simple and debuggable; SQLite
  adds opacity

### Impact

- New dependency: `sqlite3`
- New module: `config/ftl/etc/core/modules/db.sh`
- Rewrite of `state.sh` to use the database
- Migration path for existing sessions

---

## 7. Network Transparent Operation

**Scale:** Very large. New transport layer.

### Problem

ftl operates on local files only. Remote directories require SSHFS
mounts or manual `scp`. There is no way to browse a remote server as
natively as a local directory.

### Proposal

A network abstraction layer that lets ftl operate on remote paths
 transparently, using SSH, SFTP, or a custom protocol.

### Architecture

- **Path abstraction:** Introduce `ftl::path::*` functions
  (`ftl::path::list`, `ftl::path::stat`, `ftl::path::read`,
  `ftl::path::write`) that dispatch to local or remote backends
  based on the path prefix.

- **Remote path syntax:** `ssh://user@host/path` or `sftp://host/path`.
  ftl recognizes these and uses `ssh`/`sftp` for operations.

- **Caching:** Remote directory listings are cached with a TTL.
  File contents are cached on preview.

- **Operations:** `cp`, `mv`, `rm`, `mkdir` are replaced with
  remote-aware equivalents (`scp`, `sftp rename`, `ssh rm`).

- **Preview:** Remote files are downloaded to a temp dir for preview.

### Challenges

- Latency: every operation is a network round-trip
- Authentication: SSH agent forwarding or key management
- Partial support: some operations (chmod, chown) need SSH exec
- The listing pipeline (`find | filter | sort`) must run remotely
  (`ssh host "find ..."`)

### Impact

- New module: `config/ftl/etc/core/modules/remote.sh`
- Rewrite of `list.sh` scan to support remote `find`
- Rewrite of `commands/file_ops.sh` to use remote-aware operations
- New path-parsing logic in `util.sh`

---

## 8. Event-Driven Architecture

**Scale:** Large. Changes the main loop.

### Problem

ftl's main loop is a polling loop: `get_key` → `dispatch` → `tick` →
`check_resize` → `sync_selection`. Every iteration checks everything,
even if nothing changed. This is simple but wasteful.

### Proposal

An event-driven architecture where subsystems emit events and
handlers react:

- **Event types:** `key_pressed`, `dir_changed`, `file_modified`,
  `selection_changed`, `pane_resized`, `timer_fired`,
  `child_exited`.

- **Event bus:** A central dispatcher (`ftl::event::emit <type>
  <data>`). Handlers register with `ftl::event::on <type> <handler>`.

- **Main loop:** Becomes `ftl::event::wait` (blocks until an event
  arrives) → `ftl::event::dispatch` (calls handlers).

### Architecture

```bash
# Registration (in ftl_setup or plugins)
ftl::event::on key_pressed   ftl::kbd::handle_key
ftl::event::on dir_changed   ftl::list::scan
ftl::event::on file_modified ftl::list::refresh
ftl::event::on timer_fired   ftl::time::run_handlers

# Main loop
while true ; do
    ftl::event::wait    # blocks on select/poll
    ftl::event::dispatch
done
```

### Challenges

- Bash does not have `select`/`poll` on file descriptors in the
  traditional sense. `read -t` with timeout is the closest.
- The current polling loop is simple and works. Event-driven adds
  complexity for unclear benefit (Bash is not performance-sensitive
  enough to warrant it for a file manager).
- Better suited to a rewrite in a systems language.

### Impact

- New module: `config/ftl/etc/core/modules/event.sh`
- Rewrite of `bin/ftl` main loop
- Every subsystem registers handlers instead of being called directly

---

## 9. Undo/Redo Infrastructure

**Scale:** Large. Cross-cutting changes to all mutating commands.

### Problem

ftl has no undo. A mistaken `d` (delete) or `mv` is permanent (unless
the user has trash configured). The `inline_rename` mode tracks
history but does not expose undo.

### Proposal

A general-purpose undo/redo stack that wraps all mutating file
operations.

### Architecture

- **Operation log:** Every mutating command (`delete_selection`,
  `move_selection_here`, `rename_selection`, `chmod_*`, etc.) calls
  `ftl::undo::record "<inverse_command>"` before executing.

- **Inverse commands:**
  - `mv A B` → inverse is `mv B A`
  - `rm A` → inverse is `restore A from trash`
  - `chmod 755 A` → inverse is `chmod <old_mode> A`
  - `cp A B` → inverse is `rm B`

- **Stack:** `ftl_state_undo_stack` (array of inverse commands) and
  `ftl_state_redo_stack`.

- **Bindings:** `u` (undo) pops the undo stack, executes the inverse,
  pushes the original to the redo stack. `Ctrl-R` (redo) reverses.

- **Persistence:** The undo stack is saved to
  `$FTL_STATE_DIR/undo_log` and survives session restart.

### Challenges

- Not all operations are invertible (e.g. `shred`, `chmod` on a
  file that has since been modified)
- Trash integration is required for `rm` undo
- The stack grows unbounded without a size limit
- Every mutating command must be wrapped — significant code changes

### Impact

- New module: `config/ftl/etc/core/modules/undo.sh`
- Changes to every mutating command in `commands/file_ops.sh`
- New bindings: `u`, `Ctrl-R`
- New state: `ftl_state_undo_stack`, `ftl_state_redo_stack`
- Tests for every undoable operation

---

## 10. Persistent Selection Across Sessions

**Scale:** Medium. Changes state serialization.

### Problem

ftl's selection (`ftl_selection_tags`) is per-session. When the user
quits ftl and restarts, the selection is lost. The `yS`/`yL` bindings
save/load to files, but this is manual.

### Proposal

Selection persists automatically across sessions, tied to the
directory.

### Architecture

- **Auto-save:** On quit, `ftl::state::save_selection` writes to
  `$FTL_STATE_DIR/selections/$PWD_hash` (hashed to avoid path
  issues).

- **Auto-load:** On `change_dir`, ftl checks for a saved selection
  for that directory and restores it.

- **TTL:** Saved selections expire after a configurable period
  (`ftl_cfg_selection_ttl_days=7`) to prevent stale data.

- **Management:** `:selections` command lists saved selections;
  `:selections clear <dir>` removes one.

### Impact

- `state.sh`: new save/load functions
- `list.sh`: `change_dir` calls the auto-load
- New state directory: `$FTL_STATE_DIR/selections/`
- Config: `ftl_cfg_persist_selection=1`, `ftl_cfg_selection_ttl_days`

---

## 11. Multi-Pane Layout System

**Scale:** Large. Changes pane management and rendering.

### Problem

ftl's pane model is ad-hoc: `LEADER |` splits vertically, `LEADER -`
horizontally. There is no way to define, save, or restore a layout
(e.g. "3 panes: left=file manager, top-right=shell,
bottom-right=preview").

### Proposal

A layout system where users define pane arrangements declaratively
and switch between them.

### Architecture

- **Layout definition:** In `ftlrc` or a separate `layouts/` directory:
  ```bash
  ftl::layout::define dev {
      pane main ftl "$PWD"
      pane right split vertical 50 {
          pane top shell
          pane bottom preview
      }
  }
  ```

- **Layout commands:** `:layout dev` switches to the "dev" layout.
  `:layout save <name>` saves the current arrangement.

- **Implementation:** Uses tmux's `select-layout` and `split-window`
  with specific percentages. Each pane is tagged with its role
  (`ftl`, `shell`, `preview`) via tmux pane titles.

- **Layout switching:** `LEADER L` opens an fzf list of saved layouts.

### Impact

- New module: `config/ftl/etc/core/modules/layout.sh`
- Changes to `commands/pane.sh` to use the layout system
- New config: `ftl_cfg_layouts` (assoc array of layout definitions)
- New directory: `config/ftl/layouts/`

---

## 12. File System Watcher Framework

**Scale:** Medium. Extends the existing inotify watcher.

### Problem

ftl's file watcher (`ftl::pane::start_file_watcher`) uses inotify to
detect directory changes and refresh. But it is a single hardcoded
watcher with no extensibility. Users cannot add custom reactions to
file events (e.g. "when a .log file appears, tail it").

### Proposal

A watcher framework where plugins register handlers for file events.

### Architecture

- **Event types:** `create`, `modify`, `delete`, `move`, `attrib`.

- **Registration:** `ftl::watch::on <pattern> <event> <handler>`:
  ```bash
  ftl::watch::on "*.log" create ftl::plugin::log_tail::start
  ftl::watch::on "*.torrent" create ftl::plugin::torrent::move
  ```

- **Watcher process:** A background process running `inotifywait -m
  -r` (or `fswatch` on macOS), piping events to ftl via a named pipe.

- **Dispatch:** The main loop reads events from the pipe and calls
  matching handlers.

### Impact

- New module: `config/ftl/etc/core/modules/watch.sh`
- Changes to `pane.sh` to use the new framework
- Plugin API: `ftl::watch::on` for registration
- New dependency: `inotifywait` (inotify-tools) or `fswatch`

---

## 13. Permission and Sandboxing Model

**Scale:** Large. New security subsystem.

### Problem

ftl plugins run with full user privileges. A malicious or buggy
plugin can `rm -rf ~` or exfiltrate data. There is no way to
restrict what a plugin can do.

### Proposal

A sandboxing model where plugins declare their required permissions,
and ftl enforces them.

### Architecture

- **Permission declaration:** Plugin manifest specifies:
  ```toml
  [permissions]
  fs_read = ["/tmp", "~/projects"]
  fs_write = ["~/projects"]
  net = false
  exec = ["git", "rg"]
  ```

- **Enforcement:** ftl wraps plugin function calls in a sandbox.
  File operations are checked against the declared paths. Network
  access is blocked if `net = false`. `exec` calls are filtered
  against the allowed list.

- **Implementation:** Bash does not have native sandboxing. Options:
  - Path checking: wrap `ftl::util::resolve_full_path` and reject
    paths outside declared scopes.
  - Subprocess: run untrusted plugins in a separate process with
    `firejail` or `bwrap`.
  - Interpretation: for Lua/Python plugins (idea #4), enforce
    permissions in the interpreter.

### Challenges

- Bash cannot truly sandbox itself (any function can call `rm`)
- Real sandboxing requires external tools (`firejail`, `bwrap`)
- The overhead may not be worth it for a single-user tool

### Impact

- New module: `config/ftl/etc/core/modules/sandbox.sh`
- Plugin manifest changes (permission declaration)
- Documentation: plugin security guide
- External dependency: `firejail` or `bwrap` (optional)

---

## 14. Internationalization (i18n) Framework

**Scale:** Large. Cross-cutting changes to all user-facing strings.

### Problem

All ftl messages, prompts, and help text are in English. There is no
framework for translation. Users in non-English locales cannot use
ftl in their language.

### Proposal

An i18n framework that extracts user-facing strings and supports
translations.

### Architecture

- **String extraction:** All user-facing strings use
  `ftl::i18n::t "message_id"` instead of literal strings:
  ```bash
  ftl::log::warn "$(ftl::i18n::t no_selection)"
  ```

- **Translation files:** `config/ftl/etc/i18n/<locale>.sh`:
  ```bash
  declare -gA ftl_i18n_messages=(
      [no_selection]="Aucune sélection"
      [entering_mode]="Entrée en mode %s"
      # ...
  )
  ```

- **Locale detection:** `$LANG` or `ftl_cfg_locale`. Fallback to
  English.

- **Format strings:** `ftl::i18n::t` supports `printf`-style
  formatting for interpolated messages.

### Impact

- New module: `config/ftl/etc/core/modules/i18n.sh`
- Every user-facing string in `commands/`, `keyboard.sh`, `list.sh`
  must be wrapped — thousands of changes
- Translation files for each supported locale
- Documentation: translation contribution guide

---

## 15. Accessibility (a11y) Layer

**Scale:** Large. New subsystem + terminal protocol support.

### Problem

ftl is inaccessible to screen reader users. TUI applications in tmux
generally lack accessibility because tmux does not expose text to
AT-SPI/Orca. There is no keyboard-only mode (some operations require
mouse in certain terminals), no high-contrast theme toggle, and no
text-only fallback for image previews.

### Proposal

An accessibility layer that:

1. **Exports screen content to a text file** (or named pipe) on every
   render, so screen readers can read it.
2. **Provides a text-only preview mode** (no images, no ANSI escapes
   — just plain text descriptions).
3. **Supports a high-contrast theme** with minimal colors.
4. **Announces state changes** (cursor moved, selection changed,
   mode entered) via a notification mechanism.

### Architecture

- **Screen export:** `ftl::a11y::export` writes the current listing
  as plain text to `$FTL_STATE_DIR/screen.txt` after every render.
  A screen reader tails this file.

- **Text-only mode:** `ftl_cfg_a11y_text_only=1` disables image
  preview, ANSI colors, and box-drawing characters. Preview pane
  shows file descriptions instead of rendered content.

- **Announcements:** `ftl::a11y::announce "<message>"` writes to a
  named pipe that a screen reader can read aloud. Triggered on
  cursor move, selection change, mode entry/exit.

- **High contrast:** A theme with white-on-black, no dim colors, no
  256-color sequences.

### Impact

- New module: `config/ftl/etc/core/modules/a11y.sh`
- Changes to `list.sh` render to call `ftl::a11y::export`
- Changes to `preview.sh` to support text-only mode
- New config: `ftl_cfg_a11y_*` variables
- Documentation: accessibility guide

---

## 16. Remote Protocol (gRPC/JSON-RPC)

**Scale:** Very large. New subsystem.

### Problem

ftl's state is accessible only via files (`$ftl_state_info_file_path`)
and the `finfo`/`fsh` commands. External tools (editors, IDEs, other
file managers) cannot interact with a running ftl instance
programmatically.

### Proposal

A remote protocol (JSON-RPC over Unix socket) that allows external
tools to query and control ftl.

### Architecture

- **Socket:** `$FTL_STATE_DIR/ftl.sock` (Unix domain socket).

- **Protocol:** JSON-RPC 2.0. Methods:
  - `ftl.getState` → returns current path, selection, cursor, mode
  - `ftl.getListing` → returns the current listing entries
  - `ftl.setCursor` → moves the cursor
  - `ftl.setSelection` → tags/untags entries
  - `ftl.runCommand` → executes a `:` command
  - `ftl.subscribe` → subscribes to events (cursor moved, dir changed)

- **Server:** A background process (`ftl::rpc::server`) reading from
  the socket and dispatching to ftl functions. Uses `socat` or a
  custom Bash loop with `coproc`.

- **Client library:** `ftl-rpc` CLI tool for testing, plus language
  bindings for vim/neovim plugins.

### Impact

- New module: `config/ftl/etc/core/modules/rpc.sh`
- New dependency: `socat` or `jq` (for JSON)
- Background server process
- Documentation: protocol specification
- Client libraries for vim/neovim

---

## 17. Embedded Documentation Engine

**Scale:** Large. New subsystem (see also `ftl-help-system-design.md`).

### Problem

ftl's documentation (man page, mdBook) is separate from the binary.
Users cannot access context-sensitive help from within ftl without
leaving the terminal.

### Proposal

An embedded documentation engine that provides:

1. **Context-sensitive help:** Press `F1` (or `?`) on any entry to
   see help for that entry type (file extension, directory type,
   virtual entry).
2. **Inline tooltips:** Hover-like (or press-a-key) tooltips for
   bindings, config variables, and commands.
3. **Searchable help:** `:help <query>` searches the documentation
   and displays matching sections.
4. **Tutorial mode:** A guided onboarding flow for new users.

### Architecture

This is essentially the `-h` help system design
(`ftl-help-system-design.md`) integrated into ftl's runtime, plus
context sensitivity.

- **Help index:** Pre-built at install time (see
  `ftl-help-system-design.md`).
- **Context detection:** `ftl::help::context` determines what help
  to show based on the current state (cursor on a PDF? show PDF
  preview help. In inline rename mode? show rename help).
- **Rendering:** Help is displayed in a tmux popup, piped through
  `less`.

### Impact

- Implements the design in `ftl-help-system-design.md`
- New module: `config/ftl/etc/core/modules/help.sh`
- New command: `:help [topic]`
- New binding: `F1` or `?` (context-sensitive)
- Pre-built help index and cache

---

## 18. Build System Integration

**Scale:** Medium. New subsystem.

### Problem**

ftl has no awareness of build systems. Users must switch to a shell
to run `make`, `cargo build`, `npm test`, etc. ftl does not know
which files are build outputs, which are sources, or whether the
project is in a clean or dirty state.

### Proposal

A build system integration layer that:

1. **Detects the build system** (Makefile, Cargo.toml, package.json,
   go.mod, CMakeLists.txt, build.gradle, etc.).
2. **Provides build commands** as ftl bindings (`LEADER b` for build,
   `LEADER t` for test, `LEADER c` for clean).
3. **Tags build outputs** (files in `target/`, `build/`, `dist/`,
   `node_modules/`) with a special etag glyph.
4. **Shows build status** in the header (clean/dirty/error).

### Architecture

- **Detector:** `ftl::build::detect` checks for build manifest files
  in the current directory and ancestors.

- **Commands:** `ftl::build::run`, `ftl::build::test`,
  `ftl::build::clean` dispatch to the appropriate tool.

- **Output tagging:** A filter plugin (`filters/build_outputs`)
  identifies and tags build output directories.

- **Status:** `ftl::build::status` runs a quick check (e.g. `git
  status --porcelain | wc -l` for dirty state) and sets a header
  glyph.

### Impact

- New module: `config/ftl/etc/core/modules/build.sh`
- New binding plugin: `bindings/build_integration`
- New filter: `filters/build_outputs`
- New etag: `etags/build_status`
- Config: `ftl_cfg_build_commands` (assoc array: build system →
  command)

---

## 19. Version Control Abstraction Layer

**Scale:** Large. New subsystem.

### Problem

ftl's Git integration (`etags/git`, `git_blame_preview`,
`git_file_log`, `git_diff_stat`) is hardcoded to Git. Users of Mercurial,
Bazaar, Fossil, Jujutsu, or Pijul cannot use these features.

### Proposal

A VCS abstraction layer that provides a uniform API across version
control systems.

### Architecture

- **Interface:** `ftl::vcs::status`, `ftl::vcs::blame`,
  `ftl::vcs::log`, `ftl::vcs::diff`, `ftl::vcs::add`,
  `ftl::vcs::commit`.

- **Backends:** `vcs/git.sh`, `vcs/hg.sh`, `vcs/fossil.sh`,
  `vcs/jujutsu.sh`, `vcs/pijul.sh`. Each implements the interface
  using the VCS's CLI.

- **Detection:** `ftl::vcs::detect` checks for `.git/`, `.hg/`,
  `.fossil`, `.jj/`, `.pijul/` in the current directory and
  ancestors.

- **Integration:** The existing `etags/git` becomes `etags/vcs` and
  calls `ftl::vcs::status` instead of `git status` directly.

### Impact

- New module: `config/ftl/etc/core/modules/vcs.sh`
- New directory: `config/ftl/etc/vcs/` with backend files
- Rewrite of `etags/git` to use the abstraction
- Rewrite of Git bindings to use the abstraction
- Config: `ftl_cfg_vcs_backends` (ordered list of preferred VCSs)

---

## 20. Content-Addressed File Cache

**Scale:** Large. New subsystem.

### Problem

ftl re-reads and re-previews files on every cursor move. For large
files (PDFs, videos), this is slow. The generator cache helps for
thumbnails, but there is no cache for file content previews.

### Proposal

A content-addressed cache for file content and preview output.

### Architecture

- **Cache key:** `sha256(file_content)` or `sha256(file_path +
  mtime + size)` (for speed).

- **Cache store:** `$FTL_STATE_DIR/cache/content/<hash[:2]>/<hash>`.

- **Cache population:** When a preview is generated (e.g. PDF →
  PNG), the result is stored in the cache.

- **Cache lookup:** Before generating a preview, check the cache.
  If hit, display the cached result.

- **Eviction:** LRU eviction when the cache exceeds a configurable
  size (`ftl_cfg_cache_max_size="500M"`).

### Impact

- New module: `config/ftl/etc/core/modules/cache.sh`
- Changes to `preview.sh` to check/populate the cache
- Changes to `generators/generator` to use the cache
- New state directory: `$FTL_STATE_DIR/cache/content/`
- Config: `ftl_cfg_cache_max_size`, `ftl_cfg_cache_ttl`

---

## 21. Distributed ftl (Multi-Machine)

**Scale:** Very large. New subsystem.

### Problem

ftl operates on a single machine. Teams working on shared file
systems (NFS) or remote servers cannot share ftl state (selections,
marks, layouts) across machines.

### Proposal

A distributed mode where ftl instances on different machines
synchronize state.

### Architecture

- **Sync daemon:** A background process that watches
  `$FTL_STATE_DIR/` for changes and syncs them to a central server
  (or peer-to-peer via Syncthing).

- **Conflict resolution:** Last-write-wins for selection state.
  Marks and layouts are merged (union of all instances' marks).

- **Security:** TLS for client-server; SSH tunnel for peer-to-peer.

- **Scope:** Only state files are synced, not the files themselves.
  Each machine has its own file system; ftl just shares the
  navigation context.

### Challenges

- Network latency and offline operation
- Conflict resolution for concurrent edits
- Security (don't leak file paths to untrusted machines)
- This is essentially building a distributed file manager, which is
  a different product

### Impact

- New module: `config/ftl/etc/core/modules/sync.sh`
- External dependency: `syncthing` or a custom sync daemon
- New config: `ftl_cfg_sync_*` variables
- Documentation: distributed setup guide

---

## 22. Embedded Database Query Interface

**Scale:** Large. New subsystem.

### Problem

ftl's listing is a flat array. Users cannot query it ("show all
files larger than 1MB modified in the last week that are not tagged"),
sort by multiple columns, or join with external data (e.g. TMSU
tags).

### Proposal

An embedded query interface (SQL or jq-like) that operates on the
listing.

### Architecture

- **Listing as table:** The current `ftl_list_entries` is augmented
  with metadata (size, mtime, owner, permissions, extension, tag
  class) as columns.

- **Query language:** A subset of SQL:
  ```
  :query SELECT path, size FROM listing WHERE size > 1M AND mtime > now() - 7d ORDER BY size DESC
  ```

- **Backend:** `sqlite3` (in-memory) or a custom Bash query engine.
  The listing is loaded into a temp table on each scan.

- **Output:** Results become a virtual listing (idea #1), navigable
  with the cursor.

- **Joins:** `:query SELECT l.path, t.tags FROM listing l JOIN tmsu
  t ON l.path = t.path` — joins with external data sources.

### Impact

- New module: `config/ftl/etc/core/modules/query.sh`
- New dependency: `sqlite3`
- Changes to `list.sh` to maintain metadata columns
- New command: `:query <SQL>`
- Documentation: query language reference

---

## 23. Terminal Protocol Abstraction

**Scale:** Large. Changes rendering and preview.

### Problem

ftl's rendering assumes a specific terminal model (ANSI escape codes,
`w3mimgdisplay` for images). Modern terminals support multiple image
protocols (Kitty graphics, Sixel, iTerm2 inline images, HTML
overlay) and advanced features (true color, styled underlines,
hyperlinks). ftl cannot take advantage of these.

### Proposal

A terminal protocol abstraction layer that detects the terminal's
capabilities and uses the best available protocol.

### Architecture

- **Capability detection:** `ftl::term::detect` checks `$TERM`,
  `$TERM_PROGRAM`, `$KITTY_WINDOW_ID`, `$WEZTERM_EXECUTABLE`, etc.
  to determine the terminal and its capabilities.

- **Protocol backends:** `term/ansi.sh`, `term/sixel.sh`,
  `term/kitty.sh`, `term/iterm2.sh`. Each implements:
  - `ftl::term::show_image <path> <width> <height>`
  - `ftl::term::hyperlink <url> <text>`
  - `ftl::term::styled_text <text> <style>`

- **Fallback:** If the preferred protocol is unavailable, fall back
  to ANSI. If no image protocol is available, show a placeholder.

- **Configuration:** `ftl_cfg_term_protocol=auto` (detect) or
  `sixel`/`kitty`/`iterm2`/`ansi` (force).

### Impact

- New module: `config/ftl/etc/core/modules/term.sh`
- Changes to `viewers/core` `pimage` to use the abstraction
- Changes to `list.sh` render to use hyperlinks and styled text
  where available
- Config: `ftl_cfg_term_protocol`

---

## 24. Plugin Dependency Resolution

**Scale:** Medium. New subsystem.

### Problem

ftl plugins are sourced in alphabetical order (via `fd | sort`).
If plugin B depends on plugin A (e.g. B calls a function defined in
A), and B sorts before A, B fails. There is no dependency
declaration or resolution.

### Proposal

A dependency resolution system for plugins.

### Architecture

- **Dependency declaration:** Each plugin file has a header comment:
  ```bash
  # Depends: incremental_search, selection
  ```

- **Parser:** `ftl::plugin::parse_deps <file>` extracts the
  `Depends:` line.

- **Resolver:** `ftl::plugin::resolve_order <dir>` topologically
  sorts plugins based on their dependencies. Uses `tsort` or a
  custom Bash implementation.

- **Sourcing:** `ftl_setup` uses the resolved order instead of
  alphabetical.

### Impact

- New module: `config/ftl/etc/core/modules/plugin_deps.sh`
- Changes to `ftl_setup` and `ftlrc` auto-sourcing
- Documentation: plugin dependency declaration format
- Error reporting: circular dependencies, missing dependencies

---

## 25. Hot-Reload Architecture

**Scale:** Large. Changes the main loop and module loading.

### Problem**

When a developer modifies a module or plugin, they must restart ftl
(or manually `:source` the file). There is no automatic reload on
file change.

### Proposal

A hot-reload architecture where ftl monitors its own source files and
automatically reloads them on change.

### Architecture

- **File watcher:** `inotifywait -m` on
  `$FTL_CFG/etc/core/modules/`, `$FTL_CFG/etc/bindings/`, and
  `$FTL_CFG/bindings/`.

- **Reload logic:** On file change, ftl re-sources the file. Bash
  function redefinition is safe (the new definition replaces the
  old). Variable redefinition requires care (use `declare -g` to
  avoid local scoping).

- **State preservation:** ftl's state (`ftl_state_*`, selection,
  cursor) is not affected by re-sourcing modules. Only function
  definitions change.

- **Feedback:** A toast/notification ("Reloaded keyboard.sh")
  confirms the reload.

### Challenges

- Not all modules are safely re-sourceable (e.g. `ftl_setup` has
  side effects at source time)
- State that depends on module-level globals may become inconsistent
- inotify on network filesystems is unreliable

### Impact

- New module: `config/ftl/etc/core/modules/hot_reload.sh`
- Changes to `ftl_setup` to start the watcher
- New config: `ftl_cfg_hot_reload=1` (enable/disable)
- Documentation: hot-reload development workflow

---

## 26. Structured Logging and Telemetry

**Scale:** Medium. Changes the logging module.

### Problem

ftl's logging is text-based (`ftl::log::info "message"`). Logs are
human-readable but not machine-parseable. There is no structured
logging, no metrics, no tracing.

### Proposal**

Structured logging with JSON output, metrics collection, and
distributed tracing.

### Architecture

- **Structured logs:** `ftl::log::emit <level> <message>
  <metadata_json>`:
  ```bash
  ftl::log::emit info "dir_changed" '{"path": "/tmp", "entry_count": 42}'
  ```

- **Output:** Logs are written as JSON lines to
  `$ftl_state_session_dir/log.jsonl`. The existing text log remains
  for backward compatibility.

- **Metrics:** Counters and timers for key operations (scan time,
  render time, dispatch time). Exported to Prometheus format on
  request.

- **Tracing:** Each key press starts a trace span. Sub-operations
  (scan, filter, render, preview) are child spans. Exported in
  OpenTelemetry format.

### Impact

- Changes to `log.sh` to add structured logging
- New module: `config/ftl/etc/core/modules/telemetry.sh`
- New state files: `log.jsonl`, `metrics.prom`
- Config: `ftl_cfg_structured_logging=1`, `ftl_cfg_telemetry_endpoint`

---

## 27. Compression-Aware File Operations

**Scale:** Medium. Changes file operation commands.

### Problem

ftl treats compressed files (zip, tar.gz, 7z) as opaque blobs.
Copying a 1GB tar.gz across a network is 1GB of transfer, even if
the destination already has a similar file. There is no
compression-aware diff, no incremental transfer, no transparent
decompression for preview.

### Proposal

Compression-aware file operations that:

1. **Transparently decompress for preview** (already done for
   archives via `\fl`, but not for single compressed files like
   `.gz`, `.bz2`, `.xz`, `.zst`).
2. **Use rsync for copies** when available (incremental transfer).
3. **Diff compressed files** by decompressing both and diffing the
   content.
4. **Transparently recompress** on modify (edit a `.gz` file in
   place: decompress, edit, recompress).

### Architecture

- **Transparent decompression:** `viewers/core` adds cases for
  `.gz`, `.bz2`, `.xz`, `.zst` that pipe through `gunzip`/`bunzip2`/
  `xz -d`/`zstd -d` for preview.

- **rsync copy:** `ftl::cmd::copy_to_prompted` checks if `rsync` is
  available and uses it instead of `cp` for large files or remote
  destinations.

- **Compressed diff:** `ftl::cmd::file_diff` detects compressed
  inputs and pipes through decompressors before diffing.

- **In-place edit:** A new command `ftl::cmd::edit_compressed`
  decompresses to a temp file, opens `$EDITOR`, recompresses on
  save.

### Impact

- Changes to `viewers/core` (add compressed-file viewers)
- Changes to `commands/file_ops.sh` (rsync-aware copy, compressed
  diff)
- New command: `ftl::cmd::edit_compressed`
- Config: `ftl_cfg_use_rsync=1`, `ftl_cfg_decompressors` (assoc
  array: extension → decompressor)

---

## 28. Cross-Platform Abstraction (macOS/BSD/Windows)

**Scale:** Large. Cross-cutting changes.

### Problem

ftl is Linux-specific. It uses `inotifywait` (Linux only), GNU
`stat` (not BSD `stat`), GNU `find` (not BSD `find`), and assumes
`/proc` and GNU coreutils. macOS and BSD users cannot use ftl
without significant patching. Windows is completely unsupported.

### Proposal

A cross-platform abstraction layer that provides consistent APIs
across Linux, macOS, BSD, and Windows (via WSL or Cygwin).

### Architecture

- **Platform detection:** `ftl::platform::detect` returns `linux`,
  `macos`, `bsd`, or `wsl`.

- **Abstraction modules:**
  - `platform/inotify.sh` — wraps `inotifywait` (Linux),
    `fswatch` (macOS/BSD), or polling (WSL).
  - `platform/stat.sh` — wraps GNU `stat` or BSD `stat` (different
    flags for `%s`, `%Y`, etc.).
  - `platform/find.sh` — wraps GNU `find` or BSD `find` (different
    `-printf` support).
  - `platform/proc.sh` — wraps `/proc` (Linux) or `ps`/`sysctl`
    (macOS/BSD).

- **Conditional logic:** Platform-specific modules are sourced based
  on `ftl::platform::detect`. The rest of ftl calls the abstraction,
  not the platform-specific tool.

### Challenges

- macOS `stat` uses `-f %z` instead of `-c %s`
- BSD `find` does not support `-printf`
- macOS does not have `/proc`
- WSL has `/proc` but may have different inotify behavior
- Windows (without WSL) is a completely different world (no Bash,
  no tmux)

### Impact

- New module: `config/ftl/etc/core/modules/platform.sh`
- New directory: `config/ftl/etc/platform/` with platform-specific
  files
- Changes to `pane.sh` (file watcher), `util.sh` (stat), `list.sh`
  (find) to use abstractions
- Testing: CI on Linux, macOS, and BSD
- Documentation: platform-specific installation notes

---

## 29. Embedded Test Framework for Plugins

**Scale:** Medium. New subsystem.

### Problem

Plugin authors have no easy way to test their plugins. The core test
harness (`test/harness.sh`) is designed for ftl's core modules, not
user plugins. Plugin testing requires understanding the full test
infrastructure.

### Proposal

An embedded test framework that plugin authors can use with minimal
boilerplate.

### Architecture

- **Test file convention:** A plugin at `bindings/my_plugin` has a
  corresponding test at `bindings/my_plugin.test` (or
  `test/plugin/test_my_plugin.sh`).

- **Test runner:** `ftl-plugin test <name>` (or `:test <name>` from
  inside ftl) runs the plugin's tests.

- **Test API:** Simple assertions, no need to source core modules:
  ```bash
  # bindings/my_plugin.test
  source "$FTL_CFG/bindings/my_plugin"

  test_my_feature() {
      ftl_selection_current=("/tmp/a" "/tmp/b")
      my_plugin::run
      assert_exists "/tmp/a_copy1"
  }
  ```

- **Stubs:** The framework provides standard stubs for `ftl::list::render`,
  `tmux`, etc., so plugin tests don't need to set up the full
  environment.

- **Integration:** `test/harness.sh` auto-discovers plugin tests and
  runs them alongside core tests.

### Impact

- New module: `config/ftl/etc/core/modules/plugin_test.sh`
- New command: `:test [plugin_name]`
- New CLI: `ftl-plugin test <name>`
- Changes to `test/harness.sh` to discover plugin tests
- Documentation: plugin testing guide

---

## 30. Semantic File System Layer

**Scale:** Very large. New subsystem, potentially a fork.

### Problem**

ftl (and all file managers) present files as a hierarchy of
directories and filenames. But users think in terms of **semantics**:
"show me my vacation photos from 2023", "show me the PDFs I was
working on last week", "show me files tagged 'urgent'". The
hierarchical file system is a poor match for semantic queries.

### Proposal

A semantic layer that overlays the file system with metadata-driven
views.

### Architecture

- **Metadata sources:**
  - File system attributes (mtime, size, type, permissions)
  - EXIF/IPTC (photos: date, location, camera)
  - ID3 (music: artist, album, genre)
  - Git (last commit, author, branch)
  - TMSU tags (user-defined)
  - User annotations (idea #4.6 in `ftl-adventurous-ideas.md`)

- **Semantic index:** A database (SQLite or full-text search engine
  like `meilisearch` or `tantivy`) that indexes all metadata.
  Updated incrementally via the file watcher framework (idea #12).

- **Query language:** Natural-language-ish:
  ```
  :semantic photos from 2023 tagged vacation
  :semantic PDFs modified last week
  :semantic files larger than 100MB not tagged archived
  ```

- **Views:** Results are presented as virtual directories (idea #1).
  The user navigates them with normal ftl keys.

- **Faceted browsing:** The sidebar shows facets (year, tag, type,
  size range) that the user can filter by.

- **Auto-tagging:** Machine learning or rule-based auto-tagging
  (e.g. "tag all .cr2 files as 'raw-photos'", "tag files in
  ~/Downloads older than 30 days as 'to-archive'").

### Challenges

- Indexing is expensive (full-text search of all files)
- Privacy (the index reveals file contents)
- Storage (the index can be large)
- This is essentially building a personal search engine on top of a
  file manager — it may be a separate product

### Impact

- New module: `config/ftl/etc/core/modules/semantic.sh`
- New dependency: `sqlite3` or a search engine
- New command: `:semantic <query>`
- New viewer: faceted browsing sidebar
- Integration with TMSU, EXIF, ID3, Git
- Documentation: semantic query language reference

---

## Summary

| # | Idea | Scale | Key Benefit |
|---|------|-------|-------------|
| 1 | Multi-arg virtual directory | Large | Work with files from multiple locations |
| 2 | Async I/O via coprocesses | Large | Non-blocking scans on slow filesystems |
| 3 | Plugin package manager | Large | Easy plugin installation and updates |
| 4 | Embedded scripting (Lua/Python) | Very large | Complex plugin logic without Bash limitations |
| 5 | Config validation and schema | Medium | Catch config errors before runtime |
| 6 | Structured state backend (SQLite) | Very large | Queryable, historical state |
| 7 | Network transparent operation | Very large | Browse remote servers natively |
| 8 | Event-driven architecture | Large | Efficient, reactive main loop |
| 9 | Undo/redo infrastructure | Large | Safety for destructive operations |
| 10 | Persistent selection | Medium | Selection survives restart |
| 11 | Multi-pane layout system | Large | Saveable, switchable pane arrangements |
| 12 | File watcher framework | Medium | Custom reactions to file events |
| 13 | Permission and sandboxing | Large | Plugin security |
| 14 | Internationalization (i18n) | Large | Non-English user support |
| 15 | Accessibility (a11y) layer | Large | Screen reader support |
| 16 | Remote protocol (gRPC/JSON-RPC) | Very large | External tool integration |
| 17 | Embedded documentation engine | Large | Context-sensitive help |
| 18 | Build system integration | Medium | Build/test/clean from ftl |
| 19 | VCS abstraction layer | Large | Support Git/Hg/Fossil/Jujutsu/Pijul |
| 20 | Content-addressed file cache | Large | Fast preview of large files |
| 21 | Distributed ftl (multi-machine) | Very large | Shared state across machines |
| 22 | Database query interface | Large | SQL queries on the listing |
| 23 | Terminal protocol abstraction | Large | Sixel/Kitty/iTerm2 image support |
| 24 | Plugin dependency resolution | Medium | Correct plugin load order |
| 25 | Hot-reload architecture | Large | Live module reload during development |
| 26 | Structured logging and telemetry | Medium | Machine-parseable logs and metrics |
| 27 | Compression-aware file ops | Medium | Transparent decompression, rsync copy |
| 28 | Cross-platform (macOS/BSD/Windows) | Large | Run on non-Linux systems |
| 29 | Embedded test framework for plugins | Medium | Easy plugin testing |
| 30 | Semantic file system layer | Very large | Metadata-driven views and queries |

### Recommended Priority

**High impact, moderate effort (do first):**
- #1 Multi-arg virtual directory
- #5 Config validation
- #10 Persistent selection
- #12 File watcher framework
- #24 Plugin dependency resolution
- #26 Structured logging
- #27 Compression-aware file ops
- #29 Embedded test framework

**High impact, high effort (strategic):**
- #2 Async I/O
- #9 Undo/redo
- #11 Layout system
- #17 Embedded documentation
- #19 VCS abstraction
- #23 Terminal protocol abstraction
- #25 Hot-reload

**Speculative (long-term):**
- #4 Embedded scripting
- #6 SQLite state backend
- #7 Network transparent operation
- #16 Remote protocol
- #21 Distributed ftl
- #30 Semantic file system
