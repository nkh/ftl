# First Steps

This is a five-minute tour. Start ftl inside tmux:

```bash
tmux
ftl
```

You should see a header line, a numbered list of entries on the left, and a
preview pane on the right (the pane is visible by default —
`ftl_state_preview_pane_visible=1`).

## Basic navigation

ftl uses vim-style movement keys. The listing cursor is the highlighted
entry; the preview pane shows whatever the cursor is on.

| Key | Action |
|-----|--------|
| `j` / `k` | move down / up one entry |
| `h` | cd to the parent directory |
| `l` or `ENTER` | cd into a directory, or open a file |
| `g g` | go to the first entry |
| `G` | go to the last entry |
| `CTL-F` / `PGDN` | page down |
| `CTL-B` / `PGUP` | page up |

Try it: press `j` a few times, then `l` to enter a directory, then `h` to
come back out. The preview pane updates as you move because each cursor
change respawns the preview program in the preview pane.

## The preview pane

The preview pane runs real programs: text files are shown in `vim -R`,
images in `ftli` (a w3mimgdisplay wrapper), PDFs in `mupdf`, audio in
`mplayer`, and so on. To toggle the preview pane:

```
zv       toggle preview pane on/off
+        cycle preview pane size (uses ftl_cfg_preview_zoom_levels)
zz       toggle image zoom
zM       refresh the current preview
```

Scroll the preview pane with `ALT-J` / `ALT-K`.

## Selecting and acting

ftl's "selection" is a set of tagged entries. Tag the current entry with
`yy` (tag down — tags the entry and moves the cursor down), or `s` (tag
up). Tagged entries show a `▪` glyph next to their name.

```
yy            tag and move down
s             tag and move up
ya            select all entries
yc            clear selection
d             delete the selection
pp            copy the selection to the current directory
pm            move the selection to the current directory
R             rename the current entry
```

## Quitting

| Key | Action |
|-----|--------|
| `q` | quit (closes current tab → pane → ftl) |
| `Q` | quit everything |
| `ZS` | quit, but keep the shell pane |
| `ZP` | quit, but keep the preview zoomed |

## Help

Press `?` to open the man page, and `c` to open the full, fzf-searchable
binding list — that list is the authoritative reference for every key. When
in doubt, press `c`.
