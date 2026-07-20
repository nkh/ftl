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
