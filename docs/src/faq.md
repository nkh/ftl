# Frequently Asked Questions

## General

### Why does ftl require tmux?

ftl uses tmux as its composition substrate. Each pane is a separate ftl
process, and the preview pane runs real programs (`mupdf`, `mplayer`,
`w3mimgdisplay`) in real tmux panes. Without tmux, ftl cannot create
panes or run preview backends.

### How do I change the leader key?

Set `ftl_cfg_leader_key` in your `~/.config/ftl/ftlrc`:

```bash
ftl_cfg_leader_key='SPACE'
```

The value must be a symbolic key name recognized by
`ftl::kbd::normalize_key` (e.g. `BACKSLASH`, `SPACE`, `TAB`).

### How do I change the redo key?

Set `ftl_cfg_redo_key` in your `ftlrc`:

```bash
ftl_cfg_redo_key=','
```

### Why doesn't my image preview work?

Image preview requires either X11 (via `w3mimgdisplay`) or a modern
terminal with native image protocols (kitty, wezterm, iTerm2). Check:

1. `w3mimgdisplay` is installed and in your `PATH`
2. You are running inside a terminal that supports image display
3. The `ftl_cfg_image_extensions_regex` variable includes your file's
   extension

### How do I add a custom key binding?

Create a file in `~/.config/ftl/etc/bindings/my_binding`:

```bash
my_function() {
    ftl::log::info "hello from my binding"
    ftl::list::render
}

ftl::kbd::bind  ftl     entry   "LEADER m x"    my_function     "my custom binding"
```

Restart ftl (or run `:source ~/.config/ftl/etc/bindings/my_binding`
from the `:` prompt). Press `LEADER m x` to invoke.

See [Extending ftl](./extending-ftl.md) and
[Writing Bindings](./writing-bindings.md) for details.

### How do I change the default directory on startup?

Pass the directory as an argument:

```bash
ftl ~/projects
```

Or set it in your shell alias:

```bash
alias ftl='ftl ~/projects'
```

## Preview

### How do I disable the preview pane?

Press `zv` to toggle the preview pane. To disable it permanently, add
to your `ftlrc`:

```bash
ftl_state_preview_pane_visible=0
```

### How do I change the preview pane size?

Use `z+` to cycle through preview sizes, or set the zoom levels in
your `ftlrc`:

```bash
ftl_cfg_preview_zoom_levels=(85 70 50 30)
ftl_state_preview_zoom_index=1
```

### Why is my PDF preview blank?

PDF preview requires `mupdf` or `pdftoppm`. Install one of them:

```bash
sudo apt install mupdf-tools
# or
sudo apt install poppler-utils
```

## Selection

### How do I select all files?

Press `ya` (select all). To select all files only (not directories),
press `yf`. To select all directories, there is no direct binding, but
you can use the extension filter or visual mode.

### How do I select files by extension?

Press `ye` to select all files with the same extension as the current
entry. To select a specific extension via fzf, press `yie`.

### How do I clear the selection?

Press `yc` (clear all tags).

## Filtering

### How do I show only files of a specific extension?

Press `zeO` (extension only), then type the extension. Or tag files
by extension with `ye`, then press `fy` (filter to tagged).

### How do I show hidden files?

Press `z.` to toggle hidden files.

## Search

### How do I search for a file by name?

Press `/` to start incremental search. Type letters and the cursor
jumps to the first matching entry. Press `n` for next, `N` for
previous. Press `Escape` to exit search mode.

### How do to search file contents?

Press `\g` to search with ripgrep. Results appear in the preview pane.

## Display

### Why are long file names truncated and the dot before the extension missing?

When an entry's combined path + name length exceeds the pane width,
ftl truncates it to fit on one line. The truncation keeps the
extension visible (so you can still tell a `.txt` from a `.png`) but
drops the dot between the ellipsis and the extension — the visible
form is `prefix…ext` rather than `prefix…ext`. This matches upstream
behaviour and is intentional.

If you see garbled truncation (e.g. random characters from the middle
of the name appearing where the prefix should be), make sure you have
the b1234f0 fix applied — older versions used a negative slice index
that bash silently reinterpreted as "from end of string", producing
mangled output for entries that barely overflowed.

## Shell Integration

### How do I use ftl as a directory changer?

Add this to your `~/.bashrc`:

```bash
ftll() {
    local dir
    dir=$(ftl --picker 2>/dev/null) && cd "$dir"
}
```

Then run `ftll` to open ftl, navigate to a directory, and press `q`.
Your shell will `cd` to that directory.

### How do I use ftl as a file picker for vim?

Use the `ftlvim` command:

```bash
vim $(ftlvim)
```

See [Shell Integration](./user-guide/shell.md) for details.
