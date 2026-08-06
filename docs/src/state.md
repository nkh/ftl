# State Management

ftl's state is spread across four scopes, each with a different
visibility and lifetime. Understanding them is essential for writing
plugins and reasoning about pane sync.

## The four scopes

| Scope | Lifetime | Visibility | Location | Examples |
|-------|----------|------------|----------|----------|
| **Process-local** | this pane's process | this process only | in-memory globals | `ftl_kbd_trie`, `ftl_list_entries` |
| **Per-session** | this pane's session | this pane (and any re-source) | `$ftl_state_session_dir/` | `tags`, `history`, `ftl` |
| **Shared-parent** | the parent pane's session | parent + all its children | `$ftl_state_shared_dir/` (= `$ftl_state_parent_dir/prev`) | `stagsi` (selection revision), `fs` (session dir), `pane` (pane id), `panes` (child panes) |
| **Cross-session** | forever, across all ftl invocations | every ftl process | `$FTL_STATE_DIR/shared/` | `history` (global), persistent marks |

### Process-local

Variables declared in ftl's main shell. They never leave the process.
This includes the keyboard trie, the current listing arrays, the
cursor index, and most `ftl_*` globals. They're lost when the pane
quits.

### Per-session

Files under `$ftl_state_session_dir` (which is `$FTL_STATE_DIR/$$/`,
keyed by PID). The most important is **`ftl`** — the serialized state
file written by `ftl::state::save`:

```bash
sdir="<entry under cursor>"
sindex=<cursor memory index>
n="<current path>"
ftag=<active filter glyph>
show_size=<size mode>
prev_cb="<preview callback>"
etag=<etag enabled>
etag_s="<etag source name>"
dirmode=<dir preview mode>
filter_ext="<external filter name>"
vmode[tab]=<view mode>
sort_type[tab]=<sort type>
filters[tab]="<filter 1>"
filters2[tab]="<filter 2>"
lmode[tab]=<listing mode>
hidden[tab]=<show hidden>
rfilters[tab]="<reverse filter>"
ntfilter[tab]="<image-mode negate filter>"
```

This file is **Bash source**: the preview pane `source`s it to re-hydrate
its own state to match the listing pane.

### Shared-parent

The rendezvous directory `$ftl_state_shared_dir` (=`$ftl_state_parent_dir/prev`,
often referred to as `$fsp` in older docs). It contains four files:

| File | Contents | Purpose |
|------|----------|---------|
| `stagsi` | integer | selection revision counter |
| `fs` | session dir path | which pane to sync from |
| `pane` | tmux pane id | the primary pane |
| `panes` | newline-separated pane ids | all child panes |

Children read these to know whether to re-sync; the parent writes them
on every state change.

### Cross-session

`$FTL_STATE_DIR/shared/` holds things that should outlive any single ftl
process: the global directory-visit history (`history`), persistent
marks, and the TMSU tag cache. Anything you want to survive `Q` (quit
all) goes here.

## Serialization format

State is serialized as **Bash source files**. Two idioms dominate:

1. **Plain `var="value"` lines** for simple scalars — easy to read,
   easy to `source`. Used in `ftl::state::save`.
2. **`declare -p` output** for arrays and assoc arrays — preserves
   types. Used in `ftl::state::save_selection`:

   ```bash
   declare -p ftl_selection_tags | sed 's/\-A/-A -g/' >"$file"
   ```

   The `sed` rewrites the `declare -A` to `declare -A -g` so that
   re-sourcing in another shell scope declares the variable **globally**
   rather than locally.

Both formats are `source`d back with `ftl::state::load` /
`ftl::state::load_selection`.

## The stagsi revision counter

`ftl_selection_revision` (persisted as `stagsi` in the shared dir) is a
monotonic integer that bumps on every selection change. It's the heart
of pane sync:

```bash
ftl::sel::sync_from_other_pane() {
    read ftl_selection_other_revision <"$ftl_state_shared_dir/stagsi"
    if (( ftl_cfg_auto_sync_selection \
          && ftl_selection_other_revision > ftl_selection_revision )) ; then
        ftl_selection_revision=$ftl_selection_other_revision
        read ftl_state_other_session_dir <"$ftl_state_shared_dir/fs"
        source "$ftl_state_other_session_dir/tags"
    fi
}
```

Because it's monotonic, a child can cheaply check "did the parent's
selection change since I last looked?" with a single integer compare.
The same pattern (`stagsi`/`fs` pair) is reused for any state that
needs to propagate parent → child.

## Cleanup

`ftl::state::cleanup` removes `$ftl_state_session_dir` on quit. The
shared dir lives under the parent, so it's cleaned when the parent
quits. Cross-session state is never auto-cleaned — that's the user's
prerogative (`Hc` clears global history, `Mc` clears persistent marks).
