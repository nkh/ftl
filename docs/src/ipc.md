# IPC & Pane Synchronization

ftl panes are separate processes. They communicate by sending
single-character signals to each other through tmux's `send-keys`, and
by reading shared files in the rendezvous directory. This page covers
the mechanism, the sync directory layout, and the preview sync
protocol.

## The tmux signal mechanism

Two characters are reserved as ftl-internal signals (registered in the
`SIG` section of the bindings table):

| Char | Handler | Meaning |
|------|---------|---------|
| `å` | `ftl::ipc::handle_pane_focus` | pane-focus event |
| `Ä` | `ftl::ipc::handle_preview_request` | preview-sync request |

When a pane wants to signal another, it does:

```bash
tmux send -t "<target_pane>" 'Ä' &>/dev/null
```

The target pane's main loop reads the `Ä` as if it were a keystroke,
the trie lookup finds `ftl::ipc::handle_preview_request`, and the
handler runs. This is a clever abuse of tmux: tmux becomes ftl's IPC
bus, and the keyboard engine becomes its dispatcher.

The four characters `å`, `Å`, `ä`, `Ä` are reserved — never bind them.

## The shared sync directory ($fsp)

The rendezvous directory is `$ftl_state_shared_dir`, which equals
`$ftl_state_parent_dir/prev`. In older code and docs it's called `$fsp`
(for "ftl sync path"). It contains:

```
$ftl_state_parent_dir/prev/
├── stagsi        # selection revision counter (integer)
├── fs            # session dir of the pane to sync FROM
├── pane          # tmux pane id of the primary pane
└── panes         # newline-separated child pane ids
```

### State files

- **`stagsi`** — `ftl_selection_revision`. Bumps on every selection
  change. Children compare it to their own
  `ftl_selection_other_revision` to decide whether to re-source `tags`.
- **`fs`** — the session dir of the pane that just wrote state. A
  child reads this, then `source "$fs/ftl"` to re-hydrate its state.
- **`pane`** — the primary pane's tmux id. Children use it to send
  `Ä` back to the primary.
- **`panes`** — list of live child pane ids. The primary uses it to
  broadcast keys (`ftl::pane::send_to_all_children`). Stale entries
  (panes that died) are filtered out against `tmux list-panes` on every
  read (`ftl::pane::read_child_list`).

## The preview sync protocol

The preview pane is *itself* an ftl child pane (or a vim/mplayer/ftli
process, but for directory previews it's an ftl child). When the cursor
moves in the primary pane, the preview must update. The protocol:

```
PRIMARY                                     CHILD (preview pane)
  │                                              │
  │  user moves cursor                           │
  │  ftl::prev::dispatch                         │
  │  ftl::state::save  →  $session_dir/ftl       │
  │  echo "$session_dir" > $shared/fs            │
  │  echo "$my_pane_id" > $shared/pane           │
  │  tmux send -t <child> 'Ä'   ───────────────► │
  │                                              │  ftl::kbd::dispatch
  │                                              │  ftl::ipc::handle_preview_request
  │                                              │  ftl::prev::sync_and_dispatch
  │                                              │  read $shared/fs  → other_session_dir
  │                                              │  source $other_session_dir/ftl
  │                                              │  ftl::sel::sync_from_other_pane
  │                                              │  ftl::prev::dispatch (now in child)
  │                                              │  → spawns the right viewer
```

`ftl::prev::sync_and_dispatch` is the key function — it pulls state
from the parent, re-applies filters/etag/view mode, then dispatches the
preview. The same mechanism carries selection changes: every selection
bump writes a fresh `tags` file to the session dir and bumps `stagsi`,
so any child pane can detect the change with a single integer compare.

## Other signals

- **`å` (pane focus)** — sent when a pane gains focus. The handler
  re-syncs state and re-renders, so a pane you tab back to is always
  up-to-date.
- **inotify** — `ftl::pane::start_file_watcher` runs `inotifywait` in a
  subshell on the current directory. On any filesystem event, it sends
  the `refresh_pane` key to the pane, triggering `ftl::ipc::handle_refresh`.
  This is how ftl notices external file changes.
- **`r` (SIG)** — bound to `ftl::ipc::handle_refresh`; the preview pane
  sends it to itself to refresh.

## Why this design?

- **No sockets, no daemons** — tmux is the bus. One less thing to start
  and stop.
- **No locking** — the revision counter is monotonic; the last writer
  wins, and stale reads are harmless.
- **Crash-safe** — if a child dies, the parent's next
  `ftl::pane::read_child_list` prunes it from `panes`. No hanging
  references.
