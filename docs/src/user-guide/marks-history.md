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

## Tips

- Marks and history are complementary: use marks for "I'll come back here
  often" (a few fixed places) and history for "where was I yesterday".
- The `He` binding lets you prune stale entries; the history file is just
  one path per line.
- The global history is shared across all ftl processes and panes, which
  is why `Hs` is handy for filtering to the current subtree.
