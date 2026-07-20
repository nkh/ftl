# File Operations

This page covers everything you can do to a file: create, delete, rename,
copy, move, link, chmod, hex-edit, vim, cat. All bindings are in the
`entry` section and dispatch to `ftl::cmd::*` functions.

## Creating entries

| Key | Command | Description |
|-----|---------|-------------|
| `if` | `ftl::cmd::create_file` | create a new file (prompts inline) |
| `id` | `ftl::cmd::create_dir_no_cd` | create a new directory |
| `iD` | `ftl::cmd::create_dir_and_cd` | create a directory and cd into it |
| `ib` | `ftl::cmd::create_bulk` | bulk-create files and dirs via `$ftl_cfg_editor` (end with `/` for directories) |

## Deleting

| Key | Command | Description |
|-----|---------|-------------|
| `d` | `ftl::cmd::delete_selection` | delete the selection using `$ftl_cfg_delete_command` |

The default `ftl_cfg_delete_command="rm -rf"` is destructive. Consider
`rip` (rm-improved) or `trash-put`:

```bash
ftl_cfg_delete_command="rip --graveyard '$HOME/graveyard'"
# or
ftl_cfg_delete_command="trash-put"
```

See [External Commands](../external-commands.md) for full alternatives.

## Copy, move, link

| Key | Command | Description |
|-----|---------|-------------|
| `w` | `ftl::cmd::copy_to_prompted` | copy the current file to a prompted path |
| `pp` | `ftl::cmd::copy_selection_here` | copy the selection to the current directory |
| `pm` | `ftl::cmd::move_selection_here` | move the selection to the current directory |
| `PP` | `ftl::cmd::copy_to_preset` | copy to a preset in `ftl_cfg_preset_destinations` |
| `PM` | `ftl::cmd::move_to_preset` | move to a preset in `ftl_cfg_preset_destinations` |
| `pz` | `ftl::cmd::move_via_fzf` | move the selection to an fzf-picked location |
| `pZ` | `ftl::cmd::move_to_subdir_via_fzf` | move the selection to a sub-directory via fzf |
| `pop` | `ftl::cmd::copy_to_other_tab` | copy the selection to the other tab |
| `pom` | `ftl::cmd::move_to_other_tab` | move the selection to the other tab |
| `xl` | `ftl::cmd::symlink_selection` | symlink the selection in the current directory |

Presets are configured as:

```bash
declare -Ag ftl_cfg_preset_destinations=(
    [docs]="$HOME/Documents/"
    [tmp]="/tmp/"
)
```

## Rename

| Key | Command | Description |
|-----|---------|-------------|
| `R` | `ftl::cmd::rename_selection` | rename the current entry (or bulk-rename the selection) |

## Permissions (chmod)

| Key | Command | Description |
|-----|---------|-------------|
| `xmr` | `ftl::cmd::chmod_toggle_read` | `chmod a+r` |
| `xmw` | `ftl::cmd::chmod_toggle_write` | `chmod a+w` |
| `xmx` | `ftl::cmd::chmod_toggle_exec` | `chmod a+x` |
| `xmM` | `ftl::cmd::chmod_via_scim` | chmod via sc-im spreadsheet (bulk edit) |

## Hex / vim / cat

| Key | Command | Description |
|-----|---------|-------------|
| `xh` | `ftl::cmd::hex_view` | hex view (`$ftl_cfg_hex_viewer=hexdump`) |
| `xH` | `ftl::cmd::hex_edit` | hexedit (`$ftl_cfg_hex_editor=hexedit`) |
| `xv` | `ftl::cmd::edit_in_vim` | edit in vim (current window) |
| `xV` | `ftl::cmd::edit_in_vim_window` | edit in vim in a separate tmux window |
| `XV` | `ftl::cmd::edit_in_shared_vim_window` | edit in a shared vim tmux window |
| `xc` | `ftl::cmd::cat_in_terminal` | `cat` in a popup |
| `xp` | `ftl::cmd::preview_with_command` | pipe the current file through a prompted command |

## Notes

- File operations honor the selection: if anything is tagged, the
  operation acts on the tagged set; otherwise it acts on the current
  entry.
- After most operations, ftl calls `ftl::list::change_dir "$PWD"` (or
  `ftl::list::refresh_dir`) to re-render.
- `$ftl_cfg_editor` (default `vim -p`) is used for bulk-create and
  ripgrep-edit; change it if you prefer another editor.
