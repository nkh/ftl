# Searching

ftl provides three families of search: incremental in-directory search,
fzf-based file finding (multiple variants), and ripgrep-based content
search. All are registered in the `find` section.

## Incremental search

| Key | Command | Description |
|-----|---------|-------------|
| `/` | `ftl::cmd::find_in_dir` | incremental search in the current listing |
| `n` | `ftl::cmd::find_next` | next match |
| `N` | `ftl::cmd::find_previous` | previous match |

`/` sets `ftl_kbd_submode_handler` so each character you type filters the
listing live. Press `ENTER` to accept, `ESCAPE` to cancel. `n`/`N` then
walk between matches.

## fzf variants

| Key | Command | Description |
|-----|---------|-------------|
| `gff` / `b` | `ftl::cmd::find_via_fzf` | fzf over the current directory |
| `gfF` / `B` | `ftl::cmd::find_via_fzf_recursive` | fzf from the current directory downward |
| `gfd` | `ftl::cmd::find_dirs_via_fzf` | fzf over directories only |
| `gfa` | `ftl::cmd::find_via_frf` | find file using regexp or fuzzy matching |
| `gfA` | `ftl::cmd::find_via_frf_recursive` | same, recursive |
| `gfi` | `ftl::cmd::goto_image_via_sxiv` | image goto via sxiv |
| `gfI` | `ftl::cmd::goto_image_via_sxiv_recursive` | image goto, recursive, via sxiv |
| `gfu` | `ftl::cmd::goto_image_via_fzf` | image goto via fzf/ueberzug |
| `gL` | `ftl::cmd::follow_symlink` | follow the symlink under the cursor |

The fzf pane options come from `ftl_cfg_fzf_pane_opts`; popup geometry
from `ftl_cfg_fzf_popup_opts`.

## fzf-as-backend (HTTP-polled)

`ftl_cfg_fzf_listen_port=4466` enables an HTTP-polled mode where an
external process feeds filenames to fzf over a socket. The fzf-listen
command (`ftl_cfg_fzf_listen_command='fd -H -I'`) provides the candidate
list. This is useful for picking from a continuously-updated stream.

## ripgrep search

| Key | Command | Description |
|-----|---------|-------------|
| `grr` | `ftl::cmd::rg_open_file` | ripgrep, open the matching file |
| `grf` | `ftl::cmd::rg_goto_single_match` | ripgrep, jump to the single match |
| `grt` | `ftl::cmd::rg_goto_file` | ripgrep, jump to the file |
| `grl` | `ftl::cmd::rg_edit_files` | ripgrep, edit the matching files |

`grr` runs `rg` interactively (via the `frg` wrapper), then opens the
selected file in `vim`. `grl` collects all matches and opens them in
`$ftl_cfg_editor` (default `vim -p`, one tab per match).

## fzf pane preview

`gfp` (registered by the `fzf_pane_preview` binding plugin) runs fzf in
the preview pane with live preview of each candidate — useful for
browsing match results without leaving the listing. The plugin is in
`$FTL_CFG/etc/bindings/fzf_pane_preview` and is auto-sourced at startup.

## Tips

- All fzf bindings honor `CTRL-T` to send the selected file to ftl's
  selection (`ftl_cfg_fzf_pane_opts` includes `--expect=ctrl-t`).
- ripgrep variants use the `frg`, `frf`, `frl` wrappers in `etc/bin/`;
  these integrate with ftl's session state.
- Combine filters with search: `ff \.py$` then `grr` to search only
  Python files in the current directory.
