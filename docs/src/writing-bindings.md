# Writing Bindings

A **binding plugin** is a sourced Bash script that calls
`ftl::kbd::bind` to register one or more key bindings, plus any helper
functions those bindings need. Binding plugins live in
`$FTL_CFG/etc/bindings/` or `$FTL_CFG/bindings/` and are auto-sourced
at the end of `ftlrc`:

```bash
for b in $(fd . "$FTL_CFG/etc/bindings" --type f | sort -u) ; do source "$b" ; done
for b in $(fd . "$FTL_CFG/bindings" --type f | sort -u) ; do source "$b" ; done
```

Because they're sourced into ftl's shell, they can define helper
functions and call any `ftl::*` API.

## The bind call

```bash
ftl::kbd::bind <map> <section> "<keys>" <command_fn> "<help>"
```

- **`map`** — a hint string (e.g. `ftl`, `leader`, `leader_ftl`).
- **`section`** — grouping hint for the `c` table (`move`, `selection`,
  `filter`, …).
- **`keys`** — space-separated tokens. Tokens are symbolic key names:
  single chars, `LEADER`, `COUNT`, `ENTER`, `TAB`, `CTL-W`, etc.
- **`command_fn`** — the Bash function to call.
- **`help`** — short description shown in the `c` table.

The keyboard engine concatenates the tokens into a single key and
stores it in `ftl_kbd_trie`. Counts are handled by registering a
`COUNT`-prefixed variant explicitly when the command should honor a
count.

## A complete binding plugin

Here's a self-contained example (`bindings/my_compress`):

```bash
# Helper: compress the selection into a tar.bz2 next to the current dir
my_compress() {
    local out="$PWD/selection-$(date +%s).tar.bz2"
    tar cjf "$out" "${ftl_selection_current[@]}" \
        && ftl::log::info "wrote $out"
    ftl::list::refresh_dir
}

ftl::kbd::bind ftl entry "LEADER f z" my_compress \
    "compress selection into tar.bz2"
```

Drop this file in `$FTL_CFG/etc/bindings/my_compress`, restart ftl
(or run `:source $FTL_CFG/etc/bindings/my_compress` from the prompt),
and `\fz` will compress the selection.

## Defining helper functions

Helper functions can be:

- **Inline** in the binding plugin (as above).
- **Factored into a library** under `etc/bindings/lib/`. The built-in
  `leader_ftl` plugin does this:

  ```bash
  . "$FTL_CFG/etc/bindings/lib/compress"
  . "$FTL_CFG/etc/bindings/lib/optimize"
  . "$FTL_CFG/etc/bindings/lib/extra"

  ftl::kbd::bind leader_ftl extra "LEADER f c" compress "compress in tar.bz2"
  ftl::kbd::bind leader_ftl extra "LEADER f d" decompress "decompress"
  # ...
  ```

  Library files are sourced with `.` (not auto-sourced), so name them
  whatever you like.

## Overriding and unbinding

- To override an existing binding, just call `ftl::kbd::bind` again with
  the same keys — the new command wins. Set
  `ftl_kbd_warn_on_override=1` first to get a warning if you're
  stomping on something.
- To remove a binding entirely, call `ftl::kbd::unbind "<keys>"`.
- To exclude a command from redo (`.`), call
  `ftl::kbd::exclude_from_redo "<command_fn>"`.

## Reserved keys

Never bind `å`, `Å`, `ä`, `Ä` — they're ftl's internal tmux-signal IPC
(see [IPC](ipc.md)). The `c` table marks them under the `SIG` section.

## Built-in binding plugins

`etc/bindings/` ships: `leader`, `leader_ftl`, `leader_git`,
`fzf_search`, `incremental_search`, `add_to_a_log`, `change_mode`,
`file_diff`, `fzf_pane_preview`, `shred`, `tmsu`, `type_handlers`,
`user_command`, `virtual_entries`, `via_bash`, plus `lib/compress`,
`lib/optimize`, `lib/extra`. Read them as templates.
