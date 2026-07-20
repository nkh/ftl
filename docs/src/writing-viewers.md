# Writing Viewers

A **viewer** is what renders a file in the preview pane. ftl's viewer
system is intentionally low-tech: it's a chain of `if`-statements in
`viewers/core` that picks the right function based on the file's
extension, MIME type, and the current preview mode.

## How dispatch works

`ftl::prev::dispatch` (in `preview.sh`) calls `ftl::prev::show_internal`
in the primary pane. `show_internal` is a placeholder overridden by
sourcing `viewers/core`, which defines two dispatcher functions:

- **`pviewers()`** — picks an internal (preview-pane) viewer
- **`ext_viewers()`** — picks an external (full-screen / detached) viewer

Each is a cascade of `[[ ... ]] && { pX ; return ; }` tests. The chain
checks, in order: virtual entries, user overrides, directories, then
each supported extension (`cbr`, `cbz`, `html`, `svg`, `gif`, image
regex, `mp3`, media regex, `md`, `pdf`, `epub`, `man`, archives, pipes,
`json`, `yaml`, `sc`, `stl`, `asciio`), then MIME-type fallback, then
`ptype` (the generic "I don't know" handler).

## The viewer function

A viewer function takes no arguments — it reads the current entry from
`ftl_state_current_path`, `ftl_state_current_basename`,
`ftl_state_current_extension`, etc., and uses `ftl::pane::split_or_respawn`
(or `ftl::prev::show_in_vim` / `ftl::prev::show_image`) to spawn the
preview program in the preview pane. Example (simplified from `pimage`):

```bash
pimage() {
    ftl::prev::show_image "$ftl_state_current_path"
}
```

`ftl::prev::show_image` keeps a single `ftli` daemon alive and sends it
the new path, instead of respawning the daemon each time. Similarly,
`ftl::prev::show_in_vim` reuses the running vim with `:e`.

## Priority-based dispatch

The order of tests in `pviewers()` is the priority. To add a new file
type, insert a test before the MIME fallback:

```bash
[[ $ftl_state_current_extension == myext ]] && { pmyext ; return ; }
```

Then define `pmyext()`:

```bash
pmyext() {
    ftl::pane::split_or_respawn "my_renderer $ftl_state_current_path"
}
```

For external (full-screen) viewers, do the same in `ext_viewers()`:

```bash
ext_myext() { ftl::util::run_maximized my_renderer "$ftl_state_current_path" ; }
```

## User overrides

Two hooks let users inject their own dispatch without editing `core`:

- `user_pviewers()` — called at the top of `pviewers()`; return `0`
  (true) to short-circuit
- `user_eviewers()` — same for `ext_viewers()`

By default both return `false`. Override them in your `ftlrc` to add
custom viewers without touching `viewers/core`.

## Preview modes

`ftl_state_alt_preview_mode` (set by `z1`–`z5`) is a per-pane integer
that viewers can branch on. For example, archives only show their
contents when `ftl_state_alt_preview_mode` is set:

```bash
[[ $ftl_state_current_extension == zip ]] \
    && ((ftl_state_alt_preview_mode)) && { pcomp ; return ; }
```

`Z1`–`Z5` set `ftl_state_external_viewer_mode` for full-screen
alternatives.

## Adding a new file type: checklist

1. Pick a name for your viewer function (e.g. `pfoo`).
2. Add an extension test in `pviewers()` (and `ext_viewers()` if you
   want a full-screen variant).
3. Define the function in `viewers/core` or a sourced viewer plugin.
4. Use `ftl::pane::split_or_respawn "<cmd>"` for one-shot previews, or
   `ftl::prev::show_in_vim` / `ftl::prev::show_image` for reusable
   daemons.
5. Restart ftl (or `source "$FTL_CFG/viewers/core"` from the `:`
   prompt).

Existing viewer plugins: `viewers/core`, `viewers/vlc`,
`viewers/cmus`, `viewers/mplayer_background`, `viewers/mplayer_local`.
