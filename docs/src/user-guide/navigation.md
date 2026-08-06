# Navigation

This page lists every movement binding. All of these are registered in the
`move` section and dispatch to `ftl::cmd::*` functions.

## Cursor movement

| Key | Command | Description |
|-----|---------|-------------|
| `j` | `ftl::cmd::cursor_down` | next entry |
| `k` | `ftl::cmd::cursor_up` | previous entry |
| `DOWN` | `ftl::cmd::cursor_down_arrow` | next entry (arrow) |
| `UP` | `ftl::cmd::cursor_up_arrow` | previous entry (arrow) |
| `h` | `ftl::cmd::cd_to_parent` | cd to parent directory |
| `l` | `ftl::cmd::cd_into_entry` | cd into directory under cursor |
| `LEFT` | `ftl::cmd::cursor_left_arrow` | cd to parent (arrow) |
| `RIGHT` | `ftl::cmd::cursor_right_arrow` | cd into entry (arrow) |
| `ENTER` | `ftl::cmd::enter_entry` | cd into dir or open file |

## Paging

| Key | Command | Description |
|-----|---------|-------------|
| `PGUP` / `CTL-B` | `ftl::cmd::page_up` | page up |
| `PGDN` / `CTL-F` | `ftl::cmd::page_down` | page down |
| `ALT-J` | `ftl::cmd::scroll_preview_down` | scroll preview down |
| `ALT-K` | `ftl::cmd::scroll_preview_up` | scroll preview up |
| `J` | `ftl::cmd::scroll_fixed_preview_down` | scroll fixed preview down |
| `K` | `ftl::cmd::scroll_fixed_preview_up` | scroll fixed preview up |
| `CTL-H` / `CTL-L` | `ftl::cmd::send_preview_left`/`right` | send arrow key to preview |

## First / last / window

| Key | Command | Description |
|-----|---------|-------------|
| `gg` | `ftl::cmd::goto_first_file` | first entry |
| `G` | `ftl::cmd::goto_last_file` | last entry |
| `gh` | `ftl::cmd::goto_top_of_window` | top of the visible window |
| `gl` | `ftl::cmd::goto_bottom_of_window` | bottom of the visible window |
| `g LEADER` | `ftl::cmd::cycle_top_file_bottom` | cycle top → file → bottom |
| `gd` | `ftl::cmd::goto_first_directory` | first directory entry |
| `gD` | `ftl::cmd::cd_prompt` | cd to a prompted path |

## By index, percent, and extension

| Key | Command | Description |
|-----|---------|-------------|
| `COUNT %` | `ftl::cmd::jump_by_percent` | jump to N% of the listing |
| `#` | `ftl::cmd::goto_by_index` | jump to entry by index |
| `-` | `ftl::cmd::goto_next_same_extension` | next entry with the same extension |
| `_` | `ftl::cmd::goto_next_diff_extension` | next entry with a different extension |

## Tag navigation

| Key | Command | Description |
|-----|---------|-------------|
| `yn` | `ftl::cmd::goto_next_selected` | go to the next tagged entry |
| `yN` | `ftl::cmd::goto_prev_selected` | go to the previous tagged entry |
| `gy` | `ftl::cmd::goto_selection_via_fzf` | fzf over the selection |

## Behavior knobs

- `ftl_cfg_move_step_size=4` — number of entries the step commands move
  (used by larger step bindings).
- `ftl_cfg_auto_select_filename=README` — when entering a directory, ftl
  tries to select this file if it exists.
- Movement commands are excluded from redo via
  `ftl::kbd::exclude_from_redo`, so the `.` (redo) key never re-moves.

The cursor index itself lives in `ftl_state_cursor_index`, and per-directory
cursor memory is stored in `ftl_state_cursor_memory` so revisiting a
directory restores your position.

## See Also

- [Selection & Tags](./selection.md) — tagging entries for batch operations
- [Filtering](./filtering.md) — narrowing the listing with filters
- [Searching](./searching.md) — incremental search and ripgrep
- [Marks & History](./marks-history.md) — bookmarks and directory history
