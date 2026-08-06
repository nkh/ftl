# Preview System

The preview pane is the heart of ftl. Because ftl uses tmux, the preview
pane is a **real tmux pane running a real program**, not a re-rendered
view. When you move the cursor, ftl kills the current preview program and
starts a new one for the new entry — there's no fancy in-process
re-painting, just `tmux respawnp`.

## How it works

The dispatcher is `ftl::prev::dispatch` in `etc/core/modules/preview.sh`.
In the primary pane it calls `ftl::prev::show_internal`, which is defined
by sourcing `viewers/core` — a script that, given the current entry's
extension and MIME type, picks a viewer function (`pimage`, `pmp3`,
`ppdf`, `pmd`, `ptext`, …). In a child pane, `ftl::prev::dispatch` saves
state and signals the parent with the `Ä` tmux character.

Long-lived preview programs are kept alive when possible. If `vim` is
already running in the preview pane, ftl sends `:e <file>` instead of
respawning. If `ftli` (the w3mimgdisplay daemon) is running, ftl sends it
the new image path. This is tracked by three flags:
`ftl_preview_is_vim`, `ftl_preview_is_image_daemon`,
`ftl_preview_is_dir_ftl`.

## Supported types

Images (jpg/png/gif/bmp/svg/webp), PDFs, EPUB, cbr/cbz, mp3 and other
media (mkv/mp4/flv/webm), HTML, JSON, YAML, Markdown, sc-im spreadsheets,
STL 3D models, manpages, named pipes, directories (five modes), and any
text file detected via `mimemagic`.

## Preview modes (z1–z5, Z1–Z5)

Some file types have multiple alternative previews. The lowercase
variants select an alternative in the preview pane; the uppercase variants
go **full-screen** (covering the listing).

| Key | Command | Description |
|-----|---------|-------------|
| `z1`–`z5` | `ftl::cmd::set_preview_mode_1` … `_5` | alternative preview mode N |
| `Z1`–`Z5` | `ftl::cmd::set_full_preview_mode_1` … `_5` | full-screen alternative mode N |

Directory previews specifically have six modes (`zd0`–`zd5`): default, `du`,
`ls`, README, `exa`, and image-montage.

## Zoom and size

| Key | Command | Description |
|-----|---------|-------------|
| `zv` | `ftl::cmd::toggle_preview_pane` | show/hide the preview pane |
| `+` / `z+` | `ftl::cmd::cycle_preview_size` | cycle preview size |
| `zz` | `ftl::cmd::toggle_image_zoom` | toggle image zoom |

Pane sizes come from `ftl_cfg_preview_zoom_levels=(85 70 50 30)` and the
current index is `ftl_state_preview_zoom_index`.

## Scroll, pin/lock, refresh

| Key | Command | Description |
|-----|---------|-------------|
| `ALT-J` / `ALT-K` | `ftl::cmd::scroll_preview_down`/`up` | scroll the preview |
| `zff` | `ftl::cmd::toggle_fixed_preview` | open a second, "fixed" preview pane |
| `zfc` | `_ftl::prev::clear_fixed` | close the fixed preview |
| `zM` | `ftl::cmd::refresh_preview` | refresh preview (e.g. regenerate montage) |

The fixed preview pane (`ftl_state_fixed_preview_filename`) shows a
specific file alongside the live preview, useful for diffing. A "locked"
preview is a file appearing in `$ftl_state_session_dir/lock_preview/` —
when present, ftl shows that file regardless of the cursor (`plock`).

## Detached / external viewers

For media, `ee`/`er`/`ew` launch the file in an external viewer in three
modes (mode 1 inline, mode 2 detached, mode 3 detached + fullscreen). See
[External Commands](../external-commands.md) for the underlying config
variables.

## See Also

- [Navigation](./navigation.md) — moving the cursor
- [Configuration](../configuration.md) — preview-related config variables
