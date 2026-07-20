# Writing Etags

An **etag** (external tag) is metadata prepended to each entry in the
listing — for example, git status, line count, or modification date. The
active etag source is selected at runtime with `zT`; its functions run
during the directory scan.

## The contract

The etag system in `etc/core/modules/etag.sh` declares two abstract
functions:

```bash
ftl::etag::scan_directory() { : ; }       # scan the dir, populate your cache
ftl::etag::get_entry_tag() {              # get the tag for one entry
    local -n r2=$2 r3=$3
    r2=
    r3=0
}
```

An etag plugin overrides these. Conventionally, plugins define
`etag_dir()` and `etag_tag()` (the older names) and the dispatcher calls
through; in practice most plugins just define `etag_dir`/`etag_tag`
directly because the listing pipeline calls them by that name. Pick one
convention and be consistent.

The two out-parameters are passed **by name** via namerefs:

- `$2` (nameref, conventionally `r2`) — the tag string (may include ANSI
  color codes)
- `$3` (nameref, conventionally `r3`) — the display length of the tag in
  character cells, used to align the entry column

## A minimal etag: line counts

This is `etc/etags/lines`, which prepends the line count of each file:

```bash
etag_dir() {
    declare -g -A ext_lines=()
    local ext_file_lines ext_file

    while read ext_file_lines ext_file ; do
        ext_lines[$ext_file]="$(printf "\e[2;37m%5s \e[m" "$ext_file_lines")"
    done < <(find "$PWD/" -mindepth 1 -maxdepth 1 -type f,l -printf '%P\n' \
              | xargs grep -I -H -l . 2>&- | xargs wc -l)
}

etag_tag() {
    local -n r2=$2 r3=$3
    r2=
    r3=0
    r2="${ext_lines[$1]}"
    [[ "$r2" ]] || r2='      '
    r3=6       # 6 cells: 5 digits + space
}
```

## How it gets called

`ftl::etag::scan_directory` is called once per directory scan, before
any `get_entry_tag` lookups. `ftl::etag::get_entry_tag <name>` is called
once per entry. Use the scan phase to populate an associative array
keyed by entry name (e.g. `ext_lines`, `git_tags`, `ext_dates`); use the
per-entry phase to look up that name and set `r2`/`r3`.

## Built-in etags

| Plugin | What it shows | Length |
|--------|---------------|--------|
| `git` | git status code (`A`, `M`, `**` for dirs) | 3 |
| `lines` | line count of file | 6 |
| `date` | modification time `MM/DD/YY-HH:MM` | 17 |
| `image_size` | image dimensions | varies |
| `tmsu` | TMSU tags | varies |
| `virtual` | virtual-entry metadata | varies |
| `none` | (default) no etag | 0 |

## Activation

To enable an etag at runtime, press `zT` and pick one. To enable it
permanently, add to `~/.config/ftl/ftlrc`:

```bash
source "$FTL_CFG/etc/etags/git"
ftl_state_etag_enabled=1
```

`zt` toggles etags on/off in the current session.

## Tips

- Always set `r3` to the visible length (excluding ANSI escapes). The
  listing renderer uses `r3` to compute column alignment.
- Cache aggressively in `etag_dir`. Scanning the directory twice (once
  for etags, once for the listing) is fine; scanning it once per entry
  is not.
- Color tags with ANSI codes — `\e[2;37m` (dim white) is a good default
  that doesn't fight the entry colors.
- Use `declare -g -A` so the cache survives across function calls.
