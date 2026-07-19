# Introduction

**ftl** is a terminal file manager written in Bash 5+ that uses **tmux** as its
composition substrate. Where most terminal file managers implement their own
preview pane and pane multiplexer, ftl leans on tmux for both: each pane is a
separate `ftl` process, and the preview pane runs *real programs* — `vim`,
`mupdf`, `mplayer`, `w3mimgdisplay`, `vlc` — rather than re-implementations of
them. This makes ftl **hyperorthodox**: panes are independent processes that
happen to share state through the filesystem, exactly as separate Unix
processes should.

## Philosophy

ftl follows the Unix spirit — *reuse what's already there*. It is designed to
integrate other Unix applications and tools rather than reinvent them. It can
be used to change directory, to pick files in scripts, or as a `vim` file
picker (via `ftll`/`cdf`). It is written in Bash, the language that "packs a
real punch … and sometimes punches you"; it won't run under other shells, but
it's structured to be easy to expand.

The codebase is organized into **16 core modules** under `etc/core/modules/`
with strict namespacing:

- Functions: `ftl::<module>::<function>` (e.g. `ftl::kbd::bind`)
- Module variables: `ftl_<module>_<name>` (e.g. `ftl_kbd_trie`)
- Config variables: `ftl_cfg_*`
- State variables: `ftl_state_*`

## Key Features

- **Live previews** — 20+ file types: images, PDFs, video, audio, markdown, JSON, archives, and more
- **Hyperorthodox panes** — each pane is a separate `ftl` process with its own tabs, filters, and sort
- **Vim-like bindings** — leader key, count prefix, multi-key sequences, sub-modes, and a redo key
- **fzf integration** — 8+ fzf variants for finding files, plus an HTTP-polled fzf-as-backend mode
- **ripgrep integration** — search file contents and jump to matches in-place
- **TMSU tagging** — deep integration with the TMSU file-tagging tool
- **Filter pipeline** — a 5-layer filter system (external, dir, two file filters, reverse) with composable plugins
- **Selection classes** — 4 selectable tag classes (`¹²³D`) for organizing different selection groups
- **Shell pane** — a real `bash -i` in a sibling tmux pane, synchronized with ftl's directory
- **Virtual entries** — inject fake entries with custom previews and key handling
- **Plugin system** — 6 categories: filters, etags, generators, viewers, commands, bindings

If you have used `ranger`, `vifm`, `lf`, `nnn`, or `broot`, ftl will feel
familiar — but the hyperorthodox pane model and tmux-native previews give it a
distinct character.
