# Quick Reference Card

## Essential Keys

| Key | Action |
|-----|--------|
| `j` / `k` | Move cursor down / up |
| `h` / `l` | Go to parent / enter directory |
| `g` / `G` | Jump to first / last entry |
| `SPACE` / `t` | Toggle selection (tag) |
| `q` | Quit ftl |
| `:` | Open command prompt |
| `c` | Show all bindings |
| `?` | Show help (man page) |

## Navigation

| Key | Action |
|-----|--------|
| `j` / `k` | Down / up |
| `J` / `K` | Down / up by step (default 4) |
| `h` / `l` | Parent dir / enter dir |
| `g` | First entry |
| `G` | Last entry |
| `gh` | Top of window |
| `gl` | Bottom of window |
| `gg` | First file |
| `gd` | First directory |
| `-` | Next same extension |
| `_` | Next different extension |
| `CTRL-F` / `CTRL-B` | Page down / up |
| `N` | Previous search match |
| `n` | Next search match |

## Selection

| Key | Action |
|-----|--------|
| `SPACE` / `t` | Toggle tag on current entry |
| `a` | Toggle tag and move down |
| `s` | Toggle tag and move up |
| `ya` | Select all |
| `yf` | Select all files |
| `yc` | Clear all tags |
| `yy` / `y1`–`y4` | Tag with class 1–4 |
| `ye` | Select same extension |
| `yn` / `yN` | Next / previous tagged |
| `yi` | Intersect with file (missing functionality) |

## File Operations

| Key | Action |
|-----|--------|
| `d` | Delete selection |
| `w` | Copy to prompted destination |
| `pp` | Copy selection here |
| `pm` | Move selection here |
| `PP` | Copy to preset |
| `PM` | Move to preset |
| `pz` | Move via fzf |
| `R` | Rename via edir |
| `LEADER r i` | Inline rename mode |
| `xl` | Symlink selection |
| `xmr` / `xmw` / `xmx` | Toggle read / write / exec |
| `if` | Create file |
| `id` | Create directory |
| `iD` | Create directory and cd into it |
| `ib` | Bulk create (via $EDITOR) |
| `xv` | Edit in $EDITOR |

## Filtering

| Key | Action |
|-----|--------|
| `ff` | Set filter 1 (regex) |
| `fF` | Set filter 2 (regex) |
| `fd` | Set directory filter |
| `fr` | Set reverse filter |
| `fe` | Select external filter plugin |
| `fc` | Clear all filters |
| `fy` | Filter to tagged only |
| `z.` | Toggle hidden files |
| `zs` | Cycle size display modes |
| `zo` | Cycle sort type |

## Search

| Key | Action |
|-----|--------|
| `/` | Incremental search |
| `n` | Next match |
| `N` | Previous match |
| `\g` | ripgrep content search |
| `b` | fzf file search |
| `V` | fzf search with preview |

## Tabs & Panes

| Key | Action |
|-----|--------|
| `§` | New tab |
| `TAB` / `gt` | Next tab |
| `gT` | Previous tab |
| `LEADER \|` | Split vertical |
| `LEADER -` | Split horizontal |
| `gp` | Next pane |

## Preview

| Key | Action |
|-----|--------|
| `zv` | Toggle preview pane |
| `z+` | Cycle preview size |
| `zi` / `zo` | Zoom in / out (missing functionality) |
| `zp` | Pin preview (missing functionality) |
| `zP` | Unpin preview (missing functionality) |
| `zr` | Rotate image (missing functionality) |
| `zM` | Refresh preview |

## Leader Key Sequences

| Keys | Action |
|------|--------|
| `LEADER f c` | Compress (tar.bz2) |
| `LEADER f d` | Decompress |
| `LEADER f e` | GPG encrypt/decrypt |
| `LEADER f h` | Show help |
| `LEADER f i` | Optimize image |
| `LEADER f p` | Optimize PDF |
| `LEADER f v` | Optimize video |
| `LEADER f l` | Run rmlint |
| `LEADER f m` | Send via mutt |
| `LEADER s` | Shell popup |
| `LEADER r i` | Inline rename mode |
| `LEADER u` | Run user command |
| `LEADER h h` | Leader help |
| `LEADER d d` | Toggle debug logging |
| `LEADER d t` | Toggle trace logging |

## Shell

| Key | Action |
|-----|--------|
| `;` | Open shell pane |
| `Ss` | Open shell (vertical) |
| `Sz` | Open shell (zoomed) |
| `Sq` | Close shell pane |
| `Sf` | Send files to shell |

## Marks & History

| Key | Action |
|-----|--------|
| `'` + char | Set mark |
| `m` | Set mark (prompts for char) |
| `gm` | Goto mark via fzf |
| `Hh` | Session history |
| `HH` | Global history |
| `MM` | Add persistent mark |
| `Mc` | Clear persistent marks |

## View Modes

| Key | Action |
|-----|--------|
| `zma` | View mode: all |
| `zmi` | View mode: image only |
| `zmn` | View mode: next |
| `zmP` | Toggle image preview |
| `zmD` | Toggle dirs-only preview |
| `zt` | Show tree |
| `zd0`–`zd5` | Directory preview mode |

## Missing Functionalities (Extended Bindings)

| Key | Action |
|-----|--------|
| `xd` | Duplicate selection |
| `xH` | Hard link selection |
| `xt` | Update timestamps |
| `xs` | Compute SHA256 checksums |
| `xv` | Verify checksums |
| `xR` | Rename with sed pattern |
| `xn` | Chmod with octal mode |
| `zA` | Size analysis (top 20) |
| `ALT-z` / `ALT-y` | Navigate back / forward |
| `v` | Visual selection mode |
| `CP` | Command palette |
| `LEADER ws` / `wl` | Save / load workspace |
| `gbl` | Git blame |
| `gll` | Git file log |
| `gds` | Git diff stat |
