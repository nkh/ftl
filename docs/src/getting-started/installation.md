# Installation

ftl runs on Linux under X11 or XWayland. It is a Bash program that drives
tmux, so the prerequisites are a real terminal environment with the usual
modern Unix tools.

## Prerequisites

| Tool | Purpose | Minimum |
|------|---------|---------|
| [tmux](https://github.com/tmux/tmux) | pane composition, live previews | 3.0+ |
| Bash | core runtime | 5.0+ |
| [fzf](https://github.com/junegunn/fzf) | finding, selecting, command prompt | 0.30+ |
| [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`) | content search, filter pipeline | any recent |
| [fd](https://github.com/sharkdp/fd) (`fd`) | file listing for fzf | any recent |
| vim | text preview and editing | 8+ |

Optional but recommended for previews: `mupdf-tools`, `mplayer`/`vlc`,
`imagemagick`, `w3m-img` (for `w3mimgdisplay`), `sxiv`, `ffmpegthumbnailer`,
`jq`, `pandoc`, `zathura`, `exa`/`eza`, `ncdu`. For TMSU tagging, install
[TMSU](https://github.com/oniony/TMSU).

## Installation

ftl ships an `INSTALL` script that installs system dependencies, clones the
repo, and sets up symlinks.

```bash
# 1. Download the installer
wget https://raw.githubusercontent.com/nkh/ftl/reformat/INSTALL

# 2. READ IT — and modify the package list for optional components

# 3. Source it (it sets $FTL_CFG and updates your $PATH)
source INSTALL
```

The installer performs these steps:

1. Installs apt packages, pip packages, and cpan modules
2. Clones the repo shallowly into `$FTL_CFG/ftl_repo`
3. Copies `config/ftl/*` into `~/.config/ftl/`
4. Symlinks plugin directories: `commands/`, `etags/`, `filters/`,
   `generators/`, `viewers/`
5. Generates man pages via `man/gen_man_pages`
6. Generates a `image_bg.png` matching your terminal background colour (used
   to mask around image previews)
7. Appends `FTL_CFG` and the `etc/bin` paths to `~/.bashrc`

## Post-install verification

```bash
# Reload your shell
source ~/.bashrc

# Confirm the install location
echo "$FTL_CFG"                       # should print ~/.config/ftl

# Confirm the launcher is on PATH
which ftl                             # ~/.config/ftl/etc/bin/ftl

# ftl MUST be run from inside tmux
tmux
ftl                                   # opens in $PWD
ftl /etc                              # opens in a specific directory
ftl /etc/hostname                     # opens and selects a file
```

Inside ftl, press `?` for the man page and `c` for the full, fzf-searchable
binding list. If either of those works, your install is good.
