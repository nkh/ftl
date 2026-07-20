# Architecture

ftl is a Bash program that drives tmux. This page describes the four
models that shape the codebase: the **process model**, the **state
model**, the **IPC model**, and the **plugin model**, then traces the
main loop.

## Process model: per-pane independent processes

Every pane is a separate `ftl` process. The first pane is the
**primary** (`ftl_pane_is_primary=1`); panes opened with `CTL-W h/j/k/l`
are **children** (`ftl_pane_is_child=1`). Each process has its own
session directory under `$FTL_STATE_DIR/$$/`:

```
$FTL_STATE_DIR/$$/                  # this pane's private dir
├── prev/                           # shared sync dir (= fsp)
│   ├── stagsi                      # selection revision counter
│   ├── fs                          # pane session dir to sync from
│   ├── pane                        # primary pane id
│   └── panes                       # list of child pane ids
├── lock_preview/                   # locked-preview files
├── mnt/                            # fuse mount points
├── tmp/
├── ftl                             # serialized state file
├── tags                            # serialized selection
├── history                         # session history
└── log                             # stderr capture
```

Children inherit the parent's `$ftl_state_parent_dir` (the parent's
session dir) and use `$ftl_state_shared_dir` (`= $ftl_state_parent_dir/prev`)
as the rendezvous point.

## State model: filesystem-based sync

State that needs to cross process boundaries is serialized to Bash
source files and `source`d back. `ftl::state::save` writes
`$ftl_state_session_dir/ftl`, a file of `var="value"` assignments
describing the current path, cursor, view mode, filters, sort, etag
source, and more:

```bash
{
    echo "sdir=\"${ftl_list_entries[$ftl_state_cursor_index]}\""
    echo "n=\"$ftl_state_current_path\""
    echo "ftag=$ftl_filt_active_glyph"
    # ... view mode, sort, filters, etag, ...
} >"$target_dir/ftl"
declare -p ftl_filt_listing_hide_exts ftl_filt_listing_keep_exts >>"$target_dir/ftl"
```

Selection is serialized separately with `declare -p ftl_selection_tags
| sed 's/-A/-A -g/'` so it round-trips through `source`.

The four state **scopes** are:

1. **Process-local** — only this pane sees it (e.g. `ftl_kbd_trie`)
2. **Per-session** — `$ftl_state_session_dir/` (e.g. `tags`, `history`)
3. **Shared-parent** — `$ftl_state_shared_dir/` (e.g. `stagsi`, `fs`)
4. **Cross-session** — `$FTL_STATE_DIR/shared/` (e.g. global history,
   persistent marks)

See [State Management](state.md) for the full breakdown.

## IPC model: tmux signals

Panes communicate by sending single characters to each other via
`tmux send-keys`. Two characters are reserved:

- **`å`** — pane-focus event. Sent to a pane when it gains focus.
  Handled by `ftl::ipc::handle_pane_focus`.
- **`Ä`** — preview request. Sent from a child pane to the primary when
  the child wants the primary to save state and let the child
  re-dispatch the preview. Handled by `ftl::ipc::handle_preview_request`.

Because these arrive as ordinary keys, they go through the trie like any
other binding (registered in the `SIG` section). See [IPC](ipc.md) for
the protocol diagram.

## Plugin model: sourced scripts

Plugins are Bash scripts `source`d into ftl's shell. This means they
share all globals, can override any placeholder function (e.g.
`ftl::filter::apply_external`, `ftl::prev::show_internal`), and can call
any `ftl::*` API. The trade-off is no isolation — a buggy plugin can
clobber ftl state. See [Plugin API](plugins.md).

## The main loop

```
ftl::util::enter_alt_screen
ftl::list::change_dir "$PWD"                  # initial scan + render
ftl::pane::start_file_watcher                 # inotify for current dir

while true ; do
    ftl::kbd::get_key $ftl_cfg_key_timeout    # read one key (with timeout)
    ftl::time::tick                            # periodic time events
    ftl::sel::sync_from_other_pane             # pull parent's selection
    ftl::pane::check_resize                    # winch detection
    ftl::kbd::dispatch                         # trie lookup + invoke command
    ftl::list::render                          # re-render
done
```

The `ftl_cfg_key_timeout` (default 1 second) is what makes time events
work: if no key arrives within that window, `get_key` returns an
`ERROR_*` sentinel and the loop body runs anyway, so `ftl::time::tick`
and `ftl::pane::check_resize` get a turn.

## Module layout

The 16 core modules under `etc/core/modules/` are sourced in dependency
order by `etc/core/ftl`:

```
util → log → state → pane → list → preview → selection → tab →
etag → virtual → mark → time → keyboard → filter → debug → commands
```

See [Module Reference](modules.md) for what each one does.
