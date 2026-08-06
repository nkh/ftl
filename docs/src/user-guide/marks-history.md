# Marks & History

ftl has two related navigation systems: **marks** (single-character
bookmarks you set and jump to) and **history** (the list of directories
you've visited).

## Marks

Session marks are stored in the associative array
`ftl_mark_session_marks`, keyed by a single character. Values are paths
ending in `/` for directories or no suffix for files.

| Key | Command | Description |
|-----|---------|-------------|
| `m<char>` | `ftl::cmd::set_mark` | mark the current entry under `<char>` |
| `'<char>` | `ftl::cmd::goto_mark` | go to mark `<char>` |
| `*<char>` | `ftl::cmd::goto_mark_new_tab` | go to mark `<char>` in a new tab |
| `gm` | `ftl::cmd::goto_mark_via_fzf` | fzf over all marks |

A few marks are pre-populated in `etc/ftlrc`:

```bash
declare -Ag ftl_mark_session_marks=(
    [0]=/
    [1]="$HOME/"
    [2]=/CHANGE_ME/dir/filename
    ["'"]="$(tail -n1 "$ftl_state_global_history_file")"
)
```

Mark `'` (quote) always points at the last directory in global history —
a convenient "back" button.

## Persistent marks

Persistent marks survive across sessions. They live in
`$FTL_STATE_DIR/shared/` and are managed by `ftl::cmd::*_persistent_mark`
functions.

| Key | Command | Description |
|-----|---------|-------------|
| `MM` | `ftl::cmd::add_persistent_mark` | add the current path as a persistent mark |
| `gM` | `ftl::cmd::goto_persistent_via_fzf` | fzf over persistent marks |
| `Mc` | `ftl::cmd::clear_persistent_marks` | clear all persistent marks |

## History

Every directory you visit is appended to two history files:

- **Session history**: `$ftl_state_session_dir/history`
- **Global history**: `$FTL_STATE_DIR/shared/history` (cross-session)

The append happens in `_ftl::mark::save_to_history`:

```bash
echo "$ftl_state_current_path" \
    | tee -a "$ftl_state_session_dir/history" \
           >> "$FTL_STATE_DIR/shared/history"
```

### History bindings

| Key | Command | Description |
|-----|---------|-------------|
| `Hh` | `ftl::cmd::goto_session_history` | fzf over this session's history |
| `HH` / `DIAERESIS` (¨) | `ftl::cmd::goto_global_history` | fzf over all sessions' history |
| `Hs` | `ftl::cmd::goto_global_history_subdir` | global history, filtered to current subdir |
| `He` | `ftl::cmd::edit_global_history` | edit the global history file |
| `Hc` | `ftl::cmd::clear_global_history` | clear the global history |

## Project marks

Project marks are a third, directory-scoped bookmark system provided by
the `bindings/project_marks` plugin (auto-sourced from `etc/ftlrc`).
Unlike session marks (single-character, in-memory) and persistent marks
(global, in `$FTL_STATE_DIR/shared/`), project marks live in plain
`.ftl_project_marks` files inside your directory tree, so they travel
with the project, can be checked into version control, and can be
edited by hand or by any other tool.

Each `.ftl_project_marks` file contains one absolute path per line.
When you ask ftl to jump to a project mark, the plugin walks the
filesystem to collect every relevant mark file:

1. **Upward walk** (parents): from `$PWD` up to `/`, concatenating any
   `.ftl_project_marks` it finds. This lets a parent directory (e.g. a
   repo root) advertise shared shortcuts that apply to every subdirectory.
2. **Downward walk** (children): a `find -type f -name .ftl_project_marks`
   under `$PWD`. This lets nested subdirectories advertise their own
   shortcuts without polluting the parent.

The combined list is deduplicated, the `$PWD/` prefix is stripped for
display, and the result is piped through `fzf-tmux` for selection.
Selecting multiple marks (with `Tab`) opens each one in turn; `Ctrl-T`
opens the selection in a new tab.

The `gps` variant (subdir-only) skips the upward walk — useful in deep
project trees where you only want to see marks defined *inside* the
current directory, not the inherited parent shortcuts.

### Project mark bindings

| Key | Command | Description |
|-----|---------|-------------|
| `Mpp` | `ftl::plugin::project_marks::pmark` | add the current entry to the local `.ftl_project_marks` |
| `Mpe` | `ftl::plugin::project_marks::pmarks_edit` | open `.ftl_project_marks` in `$EDITOR` |
| `gpp` | `ftl::plugin::project_marks::pmarks_fzf` | fzf over marks from parents + children |
| `gps` | `ftl::plugin::project_marks::pmarks_subdir_fzf` | fzf over marks from children only |

### Mark file format

The file is plain text, one path per line, newest first (the plugin
reverses the list on insert so the most recently added mark is at the
top). Duplicate paths are removed automatically.

```
/home/user/project/src
/home/user/project/tests
/home/user/project/docs
```

### Why `gp` is unbound

The `gpp` and `gps` chords share the `gp` prefix. To make this work,
`etc/ftlrc` intentionally leaves `gp` unbound and binds the related
"next pane" shortcut to `gP` instead. If you rebind `gp` to a leaf
command, the `gpp`/`gps` chords will stop working.

## Tips

- Marks and history are complementary: use marks for "I'll come back here
  often" (a few fixed places) and history for "where was I yesterday".
- The `He` binding lets you prune stale entries; the history file is just
  one path per line.
- The global history is shared across all ftl processes and panes, which
  is why `Hs` is handy for filtering to the current subtree.
- Project marks are the only system that's **portable**: commit
  `.ftl_project_marks` to your repo and anyone who clones it gets the
  same set of shortcuts.
