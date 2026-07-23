# Missing Functionalities (Implemented)

This page documents all the features that were implemented from the
`ftl-missing-functionality.md` analysis. Each feature has a binding, a
function, and a test.

## File Operations

| Binding | Function | Description |
|---------|----------|-------------|
| `xd` | `ftl::plugin::missing::duplicate` | Duplicate selection with `_copy` suffix |
| `xH` | `ftl::plugin::missing::hardlink` | Hard link selection |
| `xt` | `ftl::plugin::missing::touch_files` | Update timestamps |
| `xs` | `ftl::plugin::missing::checksum` | Compute SHA256 checksums |
| `xv` | `ftl::plugin::missing::checksum_verify` | Verify `.sha256` files |
| `xR` | `ftl::plugin::missing::rename_pattern` | Rename with sed pattern |
| `LEADER r i` | `ftl::plugin::inline_rename::enter` | Inline rename mode (single/sequential/regexp/image-label). See [Inline Rename Mode](./user-guide/inline-rename.md). |
| `xn` | `ftl::plugin::missing::chmod_numeric` | Chmod with octal mode |
| `xo` | `ftl::plugin::missing::chown_files` | Change owner/group |
| `zA` | `ftl::plugin::missing::size_analysis` | Show top 20 largest files |

## Selection

| Binding | Function | Description |
|---------|----------|-------------|
| `yi` | `ftl::plugin::missing::selection_invert` | Invert selection |
| `yp` | `ftl::plugin::missing::select_by_pattern` | Select by regex |
| `yz` | `ftl::plugin::missing::select_by_size` | Select by minimum size |
| `yS` | `ftl::plugin::missing::selection_save` | Save selection to file |
| `yL` | `ftl::plugin::missing::selection_load` | Load selection from file |
| `yu` | `ftl::plugin::missing::selection_union` | Union with file |
| `yd` | `ftl::plugin::missing::selection_subtract` | Subtract file entries |
| `v` | `ftl::plugin::missing::visual_mode` | Visual selection mode |

## Navigation

| Binding | Function | Description |
|---------|----------|-------------|
| `ALT-z` | `ftl::plugin::missing::nav_back` | Go back in history |
| `ALT-y` | `ftl::plugin::missing::nav_forward` | Go forward in history |
| `H` | `ftl::plugin::missing::move_left_select` | Cd to parent, select previous |
| `mM` | `ftl::plugin::missing::marks_manage` | Bookmark management UI |

## Search

| Binding | Function | Description |
|---------|----------|-------------|
| `rR` | `ftl::plugin::missing::rg_replace` | Search & replace across files |
| `rh` | `ftl::plugin::missing::find_with_history` | Find with history recall |

## Preview

| Binding | Function | Description |
|---------|----------|-------------|
| `zp` | `ftl::plugin::missing::preview_pin` | Pin (lock) preview |
| `zP` | `ftl::plugin::missing::preview_unpin` | Unpin preview |
| `zpc` | `ftl::plugin::missing::preview_compare` | Compare two files |
| `zi` | `ftl::plugin::missing::preview_zoom_in` | Zoom in |
| `zo` | `ftl::plugin::missing::preview_zoom_out` | Zoom out |
| `zr` | `ftl::plugin::missing::preview_rotate` | Rotate 90° |
| `zL` | `ftl::plugin::missing::preview_tail_live` | Live tail for logs |

## UI

| Binding | Function | Description |
|---------|----------|-------------|
| `CP` | `ftl::plugin::missing::command_palette` | Fzf-searchable command list |
| `\ws` | `ftl::plugin::missing::workspace_save` | Save workspace |
| `\wl` | `ftl::plugin::missing::workspace_load` | Load workspace |

## Git (additional)

| Binding | Function | Description |
|---------|----------|-------------|
| `gbl` | `ftl::plugin::missing::git_blame_preview` | Git blame in preview |
| `gll` | `ftl::plugin::missing::git_file_log` | Git log for file |
| `gds` | `ftl::plugin::missing::git_diff_stat` | Git diff stat |

## Archives

| Binding | Function | Description |
|---------|----------|-------------|
| `\fz` | `ftl::plugin::missing::compress_zip` | Compress as zip |
| `\f7` | `ftl::plugin::missing::compress_7z` | Compress as 7z |
| `\fl` | `ftl::plugin::missing::archive_list` | List archive contents |

## Remote

| Binding | Function | Description |
|---------|----------|-------------|
| `\su` | `ftl::plugin::missing::scp_upload` | Upload via SCP |
| `\dl` | `ftl::plugin::missing::download_url` | Download URL with wget |

## Test Coverage

All 42 functions are tested in `test/unit/test_missing_functionalities.sh`.
Tests verify function existence and, where safe, test actual behavior
(duplicate, touch, invert selection, select by pattern/size, workspace save/load).
