# Tabs & Panes

ftl is hyperorthodox: each pane is a **separate `ftl` process**, and each
process owns its own tabs, filters, and sort state. Panes synchronize
selection and preview state through the filesystem (see
[State Management](../state.md) and [IPC](../ipc.md)).

## Tabs

Tabs are views inside a single pane. Each tab has its own directory,
listing mode, view mode, filters, and sort. Tab indices are not reused —
closing a tab leaves a gap in the `ftl_tab_directories` array.

| Key | Command | Description |
|-----|---------|-------------|
| `PARAGRAPH` (§) | `ftl::cmd::new_tab` | new tab |
| `TAB` / `gt` | `ftl::cmd::next_tab` | next tab |
| `gT` | `ftl::cmd::prev_tab` | previous tab |
| `COUNT gt` | `ftl::cmd::goto_tab` | go to tab N |

Per-tab state lives in indexed arrays keyed by tab index — `ftl_tab_*`:
`ftl_tab_directories`, `ftl_tab_listing_mode`, `ftl_tab_view_mode`,
`ftl_tab_filter_1`, `ftl_tab_filter_2`, `ftl_tab_filter_dirs`,
`ftl_tab_filter_reverse`, `ftl_tab_filter_image_mode`,
`ftl_tab_sort_type`, `ftl_tab_show_hidden`, `ftl_tab_listing_depth`,
`ftl_tab_preview_dirs_only`. See [Variable Index](../variable-index.md).

Tabs can be pre-populated at startup with `ftl -t <file>`:

```bash
ftl -t <(find . -name '*.py')     # one tab per directory containing matches
```

## Panes

A pane is a separate `ftl` process running in a tmux pane. The "primary"
pane (`ftl_pane_is_primary=1`) drives the preview; child panes
(`ftl_pane_is_child=1`) sync from it. Use these bindings to add and
navigate panes:

| Key | Command | Description |
|-----|---------|-------------|
| `CTL-W h` | `ftl::cmd::pane_left` | open a pane to the left |
| `CTL-W l` | `ftl::cmd::pane_right` | open a pane to the right |
| `CTL-W j` | `ftl::cmd::pane_down` | open a pane below |
| `CTL-W H` | `ftl::cmd::pane_left_keep_focus` | open left, keep focus |
| `CTL-W L` | `ftl::cmd::pane_right_keep_focus` | open right, keep focus |
| `CTL-W n` / `gp` | `ftl::cmd::goto_next_pane` | next pane or viewer |

## Child-pane independence

Each child pane runs its own `ftl` process with its own
`ftl_state_session_dir` (under `$FTL_STATE_DIR/$PID`). Child panes:

- have their own tabs, filters, and sort
- share the parent's selection (via `ftl_selection_revision` sync)
- sync their preview state by reading `$ftl_state_shared_dir/ftl` from the
  parent on every preview request
- are tracked in `$ftl_state_parent_dir/panes` (the parent's pane list)

To send a key to all children, the parent uses
`ftl::pane::send_to_all_children`. To enumerate live children,
`ftl::pane::read_child_list` re-reads `panes` and filters out panes that
no longer exist in tmux.

## Selection sync

`ftl_cfg_auto_sync_selection=1` (default) means child panes pick up the
parent's selection on every preview refresh. The mechanism is the
`ftl_selection_revision` counter written to
`$ftl_state_shared_dir/stagsi` — see
[Selection & Tags](selection.md#selection-sync-between-panes).

## Quitting

`q` closes the current tab; if no tabs remain, it closes the pane; if no
panes remain, ftl exits. `Q` / `ZZ` quits everything. `ZS` keeps the
shell pane; `ZP` keeps a zoomed preview.
