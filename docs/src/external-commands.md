# External Commands

ftl shells out to many external programs — for editing, viewing,
deleting, rendering, and detecting file types. Each is configurable via
a `ftl_cfg_*` variable in `etc/ftlrc`. This page lists every external
command variable, its default, alternatives, and recommendations.

## Editing

| Variable | Default | Alternatives | Notes |
|----------|---------|--------------|-------|
| `ftl_cfg_editor` | `vim -p` | `nvim`, `emacs`, `code -w`, `micro` | Used for `xv`, bulk-create (`ib`), and ripgrep-edit (`grl`). `-p` opens matches in tabs. |
| `ftl_cfg_diff_tool` | `vimdiff` | `meld`, `kdiff3`, `diff-so-fancy` | Used by file-diff bindings. |

## Image viewing

| Variable | Default | Alternatives | Notes |
|----------|---------|--------------|-------|
| `ftl_cfg_image_viewer` | `sxiv` | `feh`, `imv`, `pqiv`, `geeqie` | Used for full-image goto (`gfi`). |
| `ftl_cfg_gif_viewer` | (empty) | [pixelhopper](https://github.com/tomas/pixelhopper) | Animated GIF viewer; recommended. |
| `ftl_cfg_image_clean_borders` | `1` | `0` for konsole | Whether to mask borders around image previews. |
| `ftl_cfg_char_width_px` | `10` | depends on font | Pixel width of one terminal cell. |
| `ftl_cfg_char_height_px` | `21` | depends on font | Pixel height of one terminal cell. |
| `ftl_cfg_image_zoomed` | `0` | `1` | Whether image previews start zoomed. |

## Media players

| Variable | Default | Alternatives | Notes |
|----------|---------|--------------|-------|
| `ftl_cfg_gui_media_player` | `vlc -f` | `mpv`, `totem` | GUI player for media files. |
| `ftl_cfg_terminal_media_player` | `mplayer -vo null` | `mpv --no-video` | Terminal media (no video). |
| `ftl_cfg_external_terminal_player` | `vlc -I curses` | `cmus`, `ncmpcpp` | Curses-based external. |
| `ftl_cfg_live_preview_player` | `mplayer ... -vo null` | `mpv --no-video` | Live audio preview in the preview pane. |
| `ftl_cfg_background_player` | `$FTL_CFG/etc/viewers/mplayer_local` | any script | Background player script. |
| `ftl_cfg_queue_player` | `$FTL_CFG/etc/viewers/cmus` | `mpv --player-operation-mode=pseudo-gui` | Queue player (e.g. cmus). |

## Pagers and renderers

| Variable | Default | Alternatives | Notes |
|----------|---------|--------------|-------|
| `ftl_cfg_ansi_pager` | `less -R` | `moar`, `most` | Pager for ANSI text. |
| `ftl_cfg_markdown_pager` | `less -R` | `moar` | Pager for markdown. |
| `ftl_cfg_markdown_renderer_default` | `ptext` | `vmd`, `glow`, `lowdown` | Default MD renderer. |
| `ftl_cfg_markdown_renderer_1` / `_2` | `vmd` | `glow`, `mdcat` | Alternative MD renderers (for `z1`/`z2`). |
| `ftl_cfg_markdown_dir_renderer` | `vmd` | `glow` | Renderer for directory READMEs. |
| `ftl_cfg_json_viewer` | `jless` | `fx`, `jq`, `jid` | Interactive JSON viewer. |
| `ftl_cfg_yaml_viewer` | `yam -i` | `yq` | YAML viewer. |

## Hex / disk / file-type

| Variable | Default | Alternatives | Notes |
|----------|---------|--------------|-------|
| `ftl_cfg_hex_viewer` | `hexdump` | `xxd`, `hexyl`, `bat --paging=never` | Read-only hex. |
| `ftl_cfg_hex_editor` | `hexedit` | `bvi`, `ghex` | Interactive hex editor. |
| `ftl_cfg_disk_usage_tool` | `ncdu` | `dust`, `dua` | Disk-usage viewer. |
| `ftl_cfg_mime_detector` | `mimemagic` | `file`, `xdg-mime` | MIME-type detector. |

## Directory listing (exa/eza)

| Variable | Default | Notes |
|----------|---------|-------|
| `ftl_cfg_exa_colors` | (long string) | Color overrides for exa. |
| `ftl_cfg_exa_options` | `-l --tree -L 3 --header --color=always` | Flags for exa directory preview. |

> `exa` is unmaintained; `eza` is a drop-in replacement. Symlink `exa`
> to `eza` or change these variables.

## Deletion

| Variable | Default | Alternatives | Notes |
|----------|---------|--------------|-------|
| `ftl_cfg_delete_command` | `rm -rf` | `rip` (rm-improved), `trash-put` (trash-cli) | **Strongly** consider a trash-based command. |

Example safe-delete setup with `rip`:

```bash
ftl_cfg_delete_command="rip --graveyard '$HOME/graveyard'"
mkdir -p "$HOME/graveyard"
ftl::kbd::bind ftl entry U unbury "undo last deletion"
unbury() {
    local last_bury
    last_bury="$(rip --graveyard "$HOME/graveyard" -s | tail -n1)"
    [[ -n "$last_bury" ]] && {
        rip --graveyard "$HOME/graveyard" -u
        ftl::list::change_dir "$PWD" "$(basename "$last_bury")"
    }
}
```

Or FreeDesktop.org trash:

```bash
ftl_cfg_delete_command="trash-put"
```

## Help

| Variable | Default | Alternatives | Notes |
|----------|---------|--------------|-------|
| `ftl_cfg_help_command` | `man ftl.1` | `pandoc -t plain ...`, custom script | Run when `?` is pressed. |

## GPG / encryption

| Variable | Default | Notes |
|----------|---------|-------|
| `ftl_cfg_gpg_key_id` | `CHANGE.ME` | Your GPG key id; used by `\fe` (GPG encrypt/decrypt). |
