# Selection & Tags

ftl's "selection" is a set of tagged entries. Each tag carries a **class
glyph** so you can keep several independent selection groups at once. The
selection is stored in the associative array `ftl_selection_tags` keyed by
absolute path, with a per-pane revision counter
`ftl_selection_revision` (`stagsi`) used for synchronization.

## Tagging

| Key | Command | Description |
|-----|---------|-------------|
| `yy` / `a` | `ftl::cmd::flip_down` | tag the current entry and move down |
| `s` / `yu` | `ftl::cmd::flip_up` | tag the current entry and move up |
| `COUNT yy` | `ftl::cmd::flip_down` | tag N entries downward |
| `yc` | `ftl::cmd::untag_all` | clear the entire selection |
| `yC` | `ftl::cmd::untag_via_fzf` | deselect via fzf |
| `gy` | `ftl::cmd::goto_selection_via_fzf` | jump to a tagged entry via fzf |

## Classes

Tags are grouped into four selectable classes plus a default class. The
glyphs are configured in `ftl_cfg_glyph_tag_classes=('' ¹ ² ³ D')`.

| Key | Command | Description |
|-----|---------|-------------|
| `y1` | `ftl::cmd::select_class_1` | tag with class `¹` |
| `y2` | `ftl::cmd::select_class_2` | tag with class `²` |
| `y3` | `ftl::cmd::select_class_3` | tag with class `³` |
| `y4` | `ftl::cmd::select_class_4` | tag with class `D` |

When you act on the selection (copy, move, delete), ftl prompts you to
choose which class to operate on if more than one is in use — see
`ftl::sel::prompt_for_class` and `ftl::sel::fzf_choose_class`.

## Select-all variants

| Key | Command | Description |
|-----|---------|-------------|
| `ya` | `ftl::cmd::select_all` | select all files and subdirectories |
| `yf` | `ftl::cmd::select_all_files` | select all files |
| `yd` | `ftl::cmd::select_all_directories` | select all directories |
| `ye` | `ftl::cmd::select_same_extension` | select files with the same extension |
| `yE` | `ftl::cmd::select_same_extension_recursive` | same, recursive |

## fzf-based selection

| Key | Command | Description |
|-----|---------|-------------|
| `yif` | `ftl::cmd::select_via_fzf` | fzf-select files |
| `yiF` | `ftl::cmd::select_recursive_via_fzf` | fzf-select files and subdirs |
| `yie` | `ftl::cmd::select_extension_via_fzf` | fzf-select files by extension |
| `yiE` | `ftl::cmd::select_extension_recursive_via_fzf` | same, recursive |
| `yii` | `ftl::cmd::select_images_via_sxiv` | select images via sxiv |
| `yiI` | `ftl::cmd::select_images_recursive_via_sxiv` | same, recursive |

## Clipboard

| Key | Command | Description |
|-----|---------|-------------|
| `ytc` | `ftl::cmd::copy_paths_to_clipboard` | copy selection paths to clipboard |

## Selection sync between panes

When `ftl_cfg_auto_sync_selection=1` (the default), child panes pull the
parent's selection on every preview sync. The mechanism is the
`ftl_selection_revision` counter, written to
`$ftl_state_shared_dir/stagsi`:

```bash
ftl::sel::sync_from_other_pane() {
    read ftl_selection_other_revision <"$ftl_state_shared_dir/stagsi"
    if (( ftl_cfg_auto_sync_selection \
          && ftl_selection_other_revision > ftl_selection_revision )) ; then
        ftl_selection_revision=$ftl_selection_other_revision
        read ftl_state_other_session_dir <"$ftl_state_shared_dir/fs"
        source "$ftl_state_other_session_dir/tags"
    fi
}
```

The selection array is serialized with `declare -p ftl_selection_tags |
sed 's/-A/-A -g/'` so it can be `source`d back into another shell.

## Destination tags

Destination tags are a separate annotation system from selection tags.
Instead of grouping entries by class glyph, each destination tag records
a *target directory* that the entry should be copied or moved to. The
user picks the target by pressing a single shortcut key whose mapping
to a directory path is configurable.

This is useful when you have a batch of files scattered across one
directory that need to be sorted into several target directories — tag
each one with its destination, then issue a single "move tagged" command
to dispatch them all in one shot.

### Configuring destination shortcuts

Define the shortcut-key → directory map in your `ftlrc`:

```bash
declare -Ag ftl_dest_dir_dest=(
    [d]="$HOME/Documents"
    [t]="$HOME/Downloads"
    [s]="$HOME/src"
    [p]="$HOME/projects"
)
```

Now pressing `t` (the destination-tag binding) followed by `d` marks
the current entry for dispatch to `~/Documents`.

### Destination-tag bindings

| Key | Command | Description |
|-----|---------|-------------|
| `t` + key | `ftl::cmd::dest_tag_current` | mark current entry for the dest mapped to `key` |
| `TCC` | `ftl::cmd::dest_tag_clear_current` | clear current entry's dest tag |
| `TCA` | `ftl::cmd::dest_tag_clear_all` | clear all dest tags |
| `TT` | `ftl::cmd::dest_tag_apply_last_to_count` | re-apply the last dest shortcut |
| `COUNT TT` | `ftl::cmd::dest_tag_apply_last_to_count` | re-apply to COUNT entries |
| `Tc` | `ftl::cmd::dest_tag_copy_tagged` | copy all tagged entries to their dests |
| `Tm` | `ftl::cmd::dest_tag_move_tagged` | move all tagged entries to their dests |

### Config variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `ftl_cfg_dtag_move` | `1` | If non-zero, the cursor advances to the next entry after tagging, so you can rapidly tag a sequence of files. |
| `ftl_cfg_dtag_l` | `15` | Display column width for the `[...dest]` annotation shown next to each tagged entry. Long destination paths are trimmed to the last N characters so the entry column aligns. |

### Display

Tagged entries are annotated in the listing with a ` [...dest]` block
between the cursor glyph and the entry name. The destination path is
trimmed to the last `ftl_cfg_dtag_l` characters and left-padded so the
entry column stays aligned regardless of path length. Untagged entries
show no annotation.

### State

Destination tags live in three globals:

- `ftl_dest_tags` — assoc array: `full_path → destination_directory`
- `ftl_dest_dir_dest` — assoc array (user config): `shortcut_key → directory`
- `ftl_dest_last_dest` — the last shortcut key used (so `TT` can re-apply it)

Tags are session-scoped (not persisted to disk). If you quit ftl, the
tags are lost — issue `Tc` or `Tm` before quitting to dispatch them.

## See Also

- [File Operations](./file-operations.md) — operations on the selection
- [Inline Rename Mode](./inline-rename.md) — modal rename of selected entries
- [Filtering](./filtering.md) — filtering the listing
