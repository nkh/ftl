# 02 — Architecture

> **Audience:** A maintainer who has read [01-onboarding.md](./01-onboarding.md).
> **Goal:** Understand the architecture deeply enough to reason about
> cross-cutting changes, performance, and failure modes.
> **Time:** 60 minutes.

This document covers the architecture at four levels: process model,
startup sequence, the listing pipeline, and the keyboard/preview
subsystems. It concludes with a data-flow walkthrough of a typical
user action.

---

## 1. Process Model

### 1.1 Pane Hierarchy

ftl panes form a tree:

```
parent pane (ftl_state_session_dir = $FTL_STATE_DIR/$PARENT_PID)
├── preview pane (session_dir = $FTL_STATE_DIR/$PARENT_PID/$PREVIEW_PID)
├── shell pane (separate bash, not an ftl process)
├── child pane 1 (session_dir = $FTL_STATE_DIR/$PARENT_PID/$CHILD1_PID)
│   └── preview pane (session_dir = $FTL_STATE_DIR/$PARENT_PID/$CHILD1_PID/$GRANDCHILD_PID)
└── child pane 2
```

The parent pane is the one the user launched. It owns the shared state
directory (`$ftl_state_session_dir/prev/`). All child panes (preview
panes, splits) write their state into a subdirectory of the parent's
session dir.

Each pane knows:

- Its own session dir: `ftl_state_session_dir`
- Its parent's session dir: `ftl_state_parent_dir`
- The shared dir: `ftl_state_shared_dir` (= `$ftl_state_parent_dir/prev`)
- The sibling pane's session dir: `ftl_state_other_session_dir` (read
  from `$ftl_state_shared_dir/fs`)

### 1.2 Inter-Process Communication

Panes communicate via three mechanisms:

#### Filesystem state

Each pane writes serialized state to its session dir on every render
(`ftl::state::save`). Sibling panes read this state to sync selection,
cursor position, and view mode. The key files:

| File | Contents | Written by | Read by |
|------|----------|------------|---------|
| `ftl` | Listing state (cursor, sort, filters) | `ftl::state::save` | preview pane |
| `tags` | `declare -p ftl_selection_tags` | `ftl::state::save_selection` | sibling panes |
| `prev/stagsi` | Selection revision counter | `ftl::state::save` | `ftl::sel::sync_from_other_pane` |
| `prev/fs` | This pane's session dir path | `ftl::state::save` | sibling discovery |
| `pane` | This pane's tmux id | `ftl::pane::pid_to_id` | parent pane |

#### tmux signals

Single-character tmux messages sent between panes:

| Character | Meaning |
|-----------|---------|
| `å` | Refresh request (sent to sibling after a file operation) |
| `Å` | Selection sync request |
| `ä` | Preview update request |
| `Ä` | Other pane cleanup |

These are sent via `tmux send-keys -t <pane> <char>` and received as
keypresses in the target pane's main loop. The keyboard engine
recognizes them and dispatches to internal handlers (not the trie).

**These characters are reserved.** Never bind them in a plugin.

#### Environment variables

When spawning a child pane (e.g. a preview pane), ftl passes state via
`tmux split-window -e`:

- `ftl_state_info_file_path` — path to the serialized info file
- `ftl_pfs` — parent session dir
- `ftl_fs` — this pane's session dir

The child sources the info file to reconstruct state.

### 1.3 Process Lifecycle

```
bin/ftl (entry point)
  └── ftl() function
       ├── source ftl_setup
       │    ├── source 17 modules
       │    ├── source viewers/core
       │    ├── source ftlrc
       │    │    └── auto-source etc/bindings/* and bindings/*
       │    └── initialize runtime state
       ├── parse CLI args (-f, -s, -t, dir/file)
       ├── ftl::util::enter_alt_screen
       ├── set up session dirs
       ├── ftl::state::serialize_info
       ├── ftl::list::change_dir  (initial listing)
       └── main loop:
            while true ; do
              ftl::kbd::get_key
              ftl::kbd::dispatch
              ftl::time::tick
              ftl::pane::check_resize
              ftl::sel::sync_from_other_pane
            done
```

On exit (via `q` or `qa`):

1. `ftl::state::cleanup` removes the session dir
2. If this is the parent pane, kill all child panes
3. `tmux kill-pane`

---

## 2. Startup Sequence

`ftl_setup` is the orchestrator. It runs in dependency order:

```bash
# 1. Source modules in dependency order
source "$FTL_CFG/etc/core/modules/util.sh"      # no deps
source "$FTL_CFG/etc/core/modules/log.sh"       # uses util
source "$FTL_CFG/etc/core/modules/debug.sh"     # uses log
source "$FTL_CFG/etc/core/modules/state.sh"     # uses util
source "$FTL_CFG/etc/core/modules/keyboard.sh"  # uses util
source "$FTL_CFG/etc/core/modules/selection.sh" # uses state, util
source "$FTL_CFG/etc/core/modules/tab.sh"       # uses state
source "$FTL_CFG/etc/core/modules/pane.sh"      # uses util, state
source "$FTL_CFG/etc/core/modules/filter.sh"    # uses log, util
source "$FTL_CFG/etc/core/modules/list.sh"      # uses util, pane, filter, state, selection, tab
source "$FTL_CFG/etc/core/modules/preview.sh"   # uses pane, state
source "$FTL_CFG/etc/core/modules/etag.sh"      # uses state
source "$FTL_CFG/etc/core/modules/virtual.sh"   # uses state
source "$FTL_CFG/etc/core/modules/mark.sh"      # uses state
source "$FTL_CFG/etc/core/modules/time.sh"      # uses log
source "$FTL_CFG/etc/core/modules/commands.sh"  # uses everything
source "$FTL_CFG/etc/core/modules/inline_rename.sh" # uses commands, list, selection, keyboard

# 2. Source the viewer dispatcher
FTL_BOOTSTRAP_DONE=1
source "$FTL_CFG/etc/viewers/core"

# 3. Declare core associative arrays (before ftlrc populates them)
declare -Ag ftl_kbd_command_to_key ftl_kbd_bindings_display ftl_kbd_trie
declare -Ag ftl_kbd_submode_handler ftl_plugin_vfiles ftl_plugin_vdirs
declare -Ag ftl_time_handlers ftl_mark_session_marks

# 4. Source the configuration (sets ftl_cfg_* and calls ftl::kbd::bind)
source "$FTL_CFG/ftlrc" 2>&- || source "$FTL_CFG/etc/ftlrc"
#    ftlrc ends with: for b in $(fd . etc/bindings --type f) ; do source "$b" ; done

# 5. Initialize runtime state
ftl_state_session_dir="$FTL_STATE_DIR/$$"
ftl_state_shared_dir="$ftl_state_session_dir/prev"
ftl_pane_self_id="$(ftl::pane::pid_to_id $$)"
ftl::log::init
ftl_selection_total_bytes=0
ftl_selection_revision=0
declare -Ag ftl_state_cursor_memory ftl_list_mime_cache ftl_selection_tags ...
ftl_selection_current=()
ftl_state_current_path=
ftl_state_current_tab_index=0
ftl_tab_directories+=("$PWD")
ftl_tab_count=1
ftl::tab::init_defaults
ftl::filt::reset
ftl::plugin::virtual::reset
ftl::util::create_fifos 4 5 6
ftl::kbd::init_exclusions
ftl::filt::init
```

### Dependency order rationale

The order matters because Bash `source` executes the file top-to-
bottom. A module that calls a function from another module at source
time (outside a function body) will fail if the other module has not
been sourced yet. The order above ensures:

- `util` is first (no dependencies, provides `parse_path`,
  `refresh_screen`, etc.)
- `log` is second (used by everything for `ftl::log::trace`)
- `state` before `selection` (selection uses `ftl_state_session_dir`)
- `keyboard` before `commands` (commands register bindings, but
  actually `ftlrc` does the registration; commands just define
  functions)
- `list` after `pane`, `filter`, `state`, `selection`, `tab` (it uses
  all of them)
- `commands` last (it uses everything)
- `inline_rename` after `commands` (it calls `ftl::cmd::cursor_up`,
  etc.)

If you add a new module, place it in the order that satisfies its
dependencies.

---

## 3. The Listing Pipeline

The listing pipeline is ftl's most complex subsystem. It runs on every
directory change and on every filter/sort modification.

### 3.1 Entry point: `ftl::list::change_dir`

```bash
ftl::list::change_dir() {
    if [[ -n "$ftl_state_custom_list" ]] ; then
        _ftl::list::render_window
    else
        _ftl::list::scan_and_render _ftl::list::scan_directory "$@"
    fi
}
```

If a custom list is active (e.g. from fzf search), skip the scan and
just render. Otherwise, call `_ftl::list::scan_and_render` with the
scan function and the args.

### 3.2 `_ftl::list::scan_and_render`

This is the pipeline orchestrator. Its steps:

1. **Stop the file watcher.** `ftl::pane::stop_file_watcher` kills the
   inotify watcher process (if any) to prevent stale refreshes during
   the scan.

2. **cd to the target directory.** Validates the path first.

3. **Save history.** If the directory changed, save the previous
   directory to the global history and update the session mark `'`.

4. **Update tab state.** `ftl_tab_directories[$tab] = $PWD`. Set
   `ftl_list_path_separator` (/ or empty for root).

5. **Adjust for preview.** `_ftl::list::adjust_for_preview` computes
   the preview pane width and adjusts `ftl_pane_width` accordingly.

6. **Reset caches.** `ftl_list_mime_cache=()`. Resolve the search
   target (the file to select after the scan).

7. **Apply per-directory overrides.** If `.ftlrc_dir` exists in the
   target directory, source it. Apply per-tab sort overrides.

8. **Scan.** Call the scan function (`_ftl::list::scan_directory` for
   normal listings, `_ftl::list::scan_custom_source` for fzf-listen).

9. **Filter and format.** `_ftl::list::apply_filters_and_format` runs
   the filter pipeline and produces `ftl_list_entries` and
   `ftl_list_entry_colors`.

10. **Start the file watcher.** `ftl::pane::start_file_watcher` spawns
    an inotify watcher that sends a refresh signal when the directory
    changes.

11. **Render.** `_ftl::list::render_window` computes the visible
    window and calls `ftl::list::render`.

### 3.3 The scan function: `_ftl::list::scan_directory`

This function runs `find` and tees the output to multiple FIFOs. The
FIFOs are read by the filter pipeline stages, which run concurrently
via process substitution.

Simplified:

```bash
_ftl::list::scan_directory() {
    ftl_list_raw_entries=()

    # Spawn the find process, pipe through external filter
    {
        _ftl::list::find_entries "-xtype f,d,l,p" \
            | ftl::filter::apply_external \
            | _ftl::list::emit_to_fifos
    } &
}
```

The `emit_to_fifos` function tees each entry to FIFOs 4, 5, and 6.
These FIFOs are read by:

- FIFO 4: the dir filter
- FIFO 5: the file filter 1 + file filter 2
- FIFO 6: the size computation (for `du` mode)

The filters run concurrently. The sort stage reads from the filter
outputs and produces the final sorted list.

### 3.4 The filter pipeline: `_ftl::list::apply_filters_and_format`

```bash
_ftl::list::apply_filters_and_format() {
    ftl_list_entries=()
    ftl_list_entry_colors=()

    # Read from the dir filter FIFO, apply dir-specific filters
    while IFS= read -r entry ; do
        # ... format and store
    done < <(cat $fifo_dir | rg "${ftl_tab_filter_dirs[$tab]}" | ftl::filt::sort_entries | cut -f 3-)

    # Read from the file filter FIFO, apply file-specific filters
    while IFS= read -r entry ; do
        # ... format and store
    done < <(cat $fifo_file | eval "$ftl_filter_pipeline_string" | ftl::filt::sort_entries | cut -f 3-)
}
```

The `ftl_filter_pipeline_string` is assembled by `ftl::filt::init` from
the active filters. It typically looks like:

```
rg "pattern" | by_extension | by_size
```

Each filter is a Bash function that reads from stdin and writes to
stdout. The pipeline is composed with `|`.

### 3.5 The renderer: `ftl::list::render`

`ftl::list::render` does not re-scan. It walks the existing
`ftl_list_entries` array and emits terminal escape sequences.

Steps:

1. **Resolve the cursor index** from `ftl_state_cursor_memory` (per-
   tab, per-directory memory of the cursor position).

2. **Clamp the cursor** to the valid range.

3. **Parse the current path.** `ftl::util::parse_path` sets
   `ftl_state_current_path`, `_dir`, `_basename`, `_stem`, `_extension`.

4. **Save state.** `ftl::state::save` writes the listing state to the
   session dir.

5. **Resolve the selection.** `ftl::sel::resolve_current` builds
   `ftl_selection_current` from `ftl_selection_tags` (or falls back to
   the current entry).

6. **Snapshot geometry.** `ftl::pane::snapshot_geometry` saves the
   current pane dimensions for winch detection.

7. **Compute the visible window.** If the cursor is near the top,
   `window_top=0`. If near the bottom, `window_top = entry_count -
   window_height`. Otherwise, center the cursor.

8. **Render the header.** `_ftl::list::render_header` emits the PWD,
   sort glyph, filter glyph, search string, and stats (size, date).

9. **Render the entries.** Loop from `window_top` to `window_bottom`,
   emitting each entry's color string. The cursor row gets the cursor
   color. Selected entries get their tag glyph prepended.

10. **Clear below.** Erase any leftover lines from the previous render.

11. **Dispatch the preview.** `ftl::prev::dispatch` renders the
    preview pane for the current entry.

### 3.6 Performance characteristics

- The scan runs `find` once, teed to multiple FIFOs. The filters run
  concurrently with `find`, so the pipeline is streaming.
- The render walks only the visible window (typically 20–40 entries),
  not the full list. Scrolling is O(1) per line.
- `ftl_list_mime_cache` caches MIME type lookups per session.
- `ftl_list_dir_size_cache` caches `du` output per directory (with
  manual invalidation).

The main performance bottleneck is `find` on network filesystems
(NFS, SSHFS). ftl has no async I/O (Bash limitation); the scan blocks
the main loop. For local filesystems, this is rarely noticeable.

---

## 4. The Keyboard Engine

### 4.1 Key reading: `ftl::kbd::get_key`

```bash
ftl::kbd::get_key() {
    local oifs="$IFS"
    IFS=
    if [[ -n "$1" ]] ; then
        read -rsn 1 -t "$1" ftl_kbd_current_key || ftl_kbd_current_key="ERROR_$?"
    else
        read -rsn 1 ftl_kbd_current_key || ftl_kbd_current_key="ERROR_$?"
    fi
    ftl_kbd_raw_key="$ftl_kbd_current_key"

    # Slurp up to 4 more bytes (for escape sequences) with 1ms timeout
    local e1 e2 e3 e4
    read -rsn 4 -t 0.001 e1 e2 e3 e4

    ftl_kbd_current_key="$(ftl::kbd::normalize_key \
        "$ftl_kbd_current_key$e1$e2$e3$e4")"

    IFS="$oifs"
}
```

The function reads 1 byte, then tries to read up to 4 more bytes with
a 1ms timeout. This captures escape sequences (e.g. `\e[A` for Up)
without blocking on single-byte keys.

### 4.2 Key normalization: `ftl::kbd::normalize_key`

A large `case` statement mapping raw byte sequences to symbolic names:

| Raw | Normalized |
|-----|------------|
| `\e` | `ESCAPE` |
| `\177` | `BACKSPACE` |
| `\e[A` | `UP` |
| `\e[B` | `DOWN` |
| `\e[C` | `RIGHT` |
| `\e[D` | `LEFT` |
| `\e[2~` | `INS` |
| `\e[3~` | `DEL` |
| `\e[1~` / `\e[H` | `HOME` |
| `\e[5~` | `PGUP` |
| `\001` | `CTL-A` |
| ... | ... |

If the raw sequence doesn't match any case, the function outputs
nothing, and `ftl_kbd_current_key` becomes empty. This is a known
limitation: unrecognized keys are silently dropped.

### 4.3 Dispatch: `ftl::kbd::dispatch`

```bash
ftl::kbd::dispatch() {
    local reply="$ftl_kbd_current_key"

    # Overflow guard
    if (( ftl_kbd_keys_count > 3 )) ; then
        ftl_kbd_accumulated_keys=""; ftl_kbd_count=""; ftl_kbd_has_count=
        return
    fi

    # Timeout
    if [[ "$reply" == ERROR_* ]] ; then
        ftl_kbd_accumulated_keys=""; ftl_kbd_count=""; ftl_kbd_has_count=
        return
    fi

    # Translate special keys
    [[ "$reply" == "?" ]] && reply="QUESTION_MARK"
    [[ "$reply" == "$ftl_cfg_leader_key" ]] && reply="LEADER"

    # Sub-mode dispatch
    if [[ -n "$ftl_kbd_submode_handler" ]] ; then
        "$ftl_kbd_submode_handler"
        return
    fi

    # Escape interrupts accumulation
    if [[ "$reply" == "ESCAPE" ]] ; then
        ftl_kbd_accumulated_keys=""; ftl_kbd_count=""; ftl_kbd_has_count=
        return
    fi

    # Count accumulation
    if [[ -z "$ftl_kbd_accumulated_keys" || "$ftl_kbd_accumulated_keys" =~ ^[0-9]$ ]] ; then
        if [[ "$reply" =~ ^[0-9]$ ]] ; then
            if [[ "$ftl_kbd_count$reply" != "0" ]] ; then
                ftl_kbd_has_count=1
                ftl_kbd_count+="$reply"
            fi
            return
        fi
    fi

    # Accumulate this key
    ftl_kbd_accumulated_keys+="$reply"
    (( ftl_kbd_keys_count++ ))

    # Virtual entry intercept
    if (( ${#ftl_plugin_vfiles[@]} || ${#ftl_plugin_vdirs[@]} )) ; then
        if ftl::plugin::virtual::handle_key "$ftl_kbd_accumulated_keys" ; then
            return
        fi
    fi

    # Trie lookup (with optional count prefix)
    lookup="${ftl_kbd_has_count:+COUNT}$ftl_kbd_accumulated_keys"
    cmd="${ftl_kbd_trie[$lookup]:-${ftl_kbd_trie[$ftl_kbd_accumulated_keys]:-}}"

    if [[ -n "$cmd" ]] && [[ $(type -t "$cmd") == function ]] ; then
        ftl::state::serialize_info "$ftl_state_main_info_file_path"
        "$cmd"
        [[ "${ftl_kbd_redo_excluded[$cmd]:-}" ]] || ftl_kbd_last_command="$cmd"
        ftl_kbd_accumulated_keys=""; ftl_kbd_count=""; ftl_kbd_has_count=
        return
    fi

    # Redo key
    if [[ "$lookup" == "$ftl_cfg_redo_key" && -n "$ftl_kbd_last_command" ]] ; then
        "$ftl_kbd_last_command"
        ftl_kbd_accumulated_keys=""; ftl_kbd_count=""; ftl_kbd_has_count=
    fi
}
```

Key points:

1. **Sub-mode handler takes precedence.** If `ftl_kbd_submode_handler`
   is set, the handler function is called with no arguments; it reads
   `ftl_kbd_current_key` directly. This is how incremental search,
   fzf search, and inline rename mode work.

2. **Count accumulation.** If the user types digits before a key, they
   are accumulated in `ftl_kbd_count`. The lookup is then
   `COUNT<keys>`, which is a separate trie entry. Commands that
   support counts register both `<keys>` and `COUNT<keys>`.

3. **Virtual entry intercept.** If virtual files/dirs are active, the
   virtual plugin's `handle_key` is called first. If it returns true,
   the key was consumed and dispatch ends.

4. **Trie lookup.** The concatenated key string is looked up in
   `ftl_kbd_trie`. If found and is a function, it is invoked. The
   command is recorded in `ftl_kbd_last_command` (unless excluded
   from redo).

5. **Redo.** If the key is the redo key (`.`) and there is a last
   command, it is repeated.

### 4.4 Binding registration: `ftl::kbd::bind`

```bash
ftl::kbd::bind() {
    local map="$1" section="$2" keys="$3" command="$4" help="${5:-}"
    local -a keys_arr=( $keys )
    local shortcut="" dscut=""
    local key

    for key in "${keys_arr[@]}" ; do
        shortcut+="$key"

        # Warn on override
        if (( ftl_kbd_warn_on_override )) ; then
            if [[ "${ftl_kbd_trie[$shortcut]:-}" =~ [[:alpha:]] ]] ; then
                echo "ftl: bind: overriding '$shortcut'"
            fi
        fi

        # Track prefix usage count
        local __current="${ftl_kbd_trie[$shortcut]:-}"
        if [[ "$__current" =~ ^[0-9]+$ ]] ; then
            ftl_kbd_trie[$shortcut]=$(( __current + 1 ))
        fi

        # Build display string with AltGr annotations
        if [[ -n "${ftl_kbd_altgr_inverse[$key]:-}" ]] ; then
            dscut+=" ⇑${ftl_kbd_altgr_inverse[$key]}/$key"
        elif [[ -n "${ftl_kbd_shift_altgr_inverse[$key]:-}" ]] ; then
            dscut+=" ⇈${ftl_kbd_shift_altgr_inverse[$key]}/$key"
        else
            dscut+=" $key"
        fi
    done

    ftl_kbd_command_to_key[$command]="$shortcut"
    ftl_kbd_trie[$shortcut]="$command"
    ftl_kbd_bindings_display[$dscut]="$map"$'\t'"$section"$'\t'"$dscut"$'\t'"$command"$'\t'"$help"
}
```

The function:

1. Concatenates the key tokens into a single string (`shortcut`).
2. Increments a numeric prefix counter for each prefix (so `LEADER`
   and `LEADERr` get counts, indicating they are prefixes).
3. Builds a display string with AltGr annotations (for the `c` table).
4. Stores the command in `ftl_kbd_trie[$shortcut]` and the reverse
   mapping in `ftl_kbd_command_to_key[$command]`.
5. Stores the display data in `ftl_kbd_bindings_display[$dscut]`.

---

## 5. The Preview Subsystem

### 5.1 Dispatch: `ftl::prev::dispatch`

Called by `ftl::list::render` after the listing is drawn. It sources
`viewers/core` (which defines `pviewers` and `ext_viewers`) and calls
`ftl::plugin::core::pviewers`.

### 5.2 The viewer dispatcher: `viewers/core`

`pviewers` is a large case statement:

```bash
ftl::plugin::core::pviewers() {
    ((${#ftl_plugin_vfiles[@]} || ${#ftl_plugin_vdirs[@]})) && { vfile_prev && return ; }
    ftl::plugin::core::user_pviewers && return ;

    [[ -d "$ftl_state_current_path" ]] && { ftl::plugin::core::pdir ; return ; }
    [[ $ftl_state_current_extension == cbr ]] && { ftl::plugin::core::pcbr ; return ; }
    [[ $ftl_state_current_extension == cbz ]] && { ftl::plugin::core::pcbz ; return ; }
    [[ $ftl_state_current_extension == html ]] && { ftl::plugin::core::phtml ; return ; }
    # ... 20+ more cases
    ftl::list::get_mime_type
    ftl::util::is_binary_file "$ftl_state_current_path"
    # ... fallback to text or open_with
}
```

Each viewer function (`pimage`, `ppdf`, etc.) follows the pattern:

1. `ftl::prev::clear` — clear the preview pane
2. `ftl::pane::split_for_preview "<command>"` — spawn the backend in a
   split pane

The backend command typically includes `read -sn 100` at the end to
pause before returning control to ftl.

### 5.3 Preview pane lifecycle

The preview pane is a child ftl process (or a plain tmux pane running
a backend program). Its lifecycle:

1. **Creation.** `ftl::pane::split_for_preview` checks if a preview
   pane exists. If not, it splits the current pane and spawns the
   preview ftl process. If it exists, it sends a refresh signal.

2. **Update.** When the cursor moves, the parent ftl writes new state
   to `$ftl_state_shared_dir/ftl`. The preview pane reads this and
   re-renders.

3. **Destruction.** When the parent exits or the user closes the
   preview, the preview pane is killed.

### 5.4 Image preview

Image preview is special: it uses `w3mimgdisplay` (or the configured
backend) which writes directly to the terminal's image buffer. This
requires:

- X11 (for `w3mimgdisplay`)
- A compatible terminal (xterm, urxvt, kitty, wezterm, iTerm2)
- The terminal must be in the right mode

The `pimage` function in `viewers/core` handles this. It computes the
image dimensions, scales to fit the preview pane, and invokes
`w3mimgdisplay`.

---

## 6. State Flow: A Typical User Action

To tie it all together, here is the data flow when the user presses
`j` (move cursor down):

1. **`ftl::kbd::get_key`** reads `j` from stdin. Normalizes to `j`.
   Sets `ftl_kbd_current_key=j`.

2. **`ftl::kbd::dispatch`** is called.
   - `ftl_kbd_submode_handler` is empty (no sub-mode active).
   - `j` is not ESCAPE.
   - `j` is not a digit, so no count accumulation.
   - `ftl_kbd_accumulated_keys` becomes `j`.
   - No virtual entries active.
   - Trie lookup: `ftl_kbd_trie[j]` = `ftl::cmd::cursor_down`.
   - `ftl::cmd::cursor_down` is invoked.

3. **`ftl::cmd::cursor_down`** (in `commands.sh`):
   ```bash
   ftl::cmd::cursor_down() {
       if (( ftl_list_entry_count )) ; then
           ftl::list::move_cursor 1 && ftl::list::render
       fi
   }
   ```

4. **`ftl::list::move_cursor 1`** (in `list.sh`):
   ```bash
   ftl::list::move_cursor() {
       local nf
       (( nf = ftl_state_cursor_index + $1,
          nf = nf < 0 ? 0 : nf >= ftl_list_entry_count ? ftl_list_entry_count - 1 : nf ))
       (( nf != ftl_state_cursor_index )) && \
           ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]=$nf
   }
   ```
   - Computes the new index `nf = cursor + 1`, clamped to
     `[0, entry_count - 1]`.
   - If it changed, stores it in `ftl_state_cursor_memory` (per-tab,
     per-directory).

5. **`ftl::list::render`** (in `list.sh`):
   - Reads `ftl_state_cursor_index` from `ftl_state_cursor_memory`.
   - Clamps to valid range.
   - `ftl::util::parse_path "${ftl_list_entries[$ftl_state_cursor_index]}"`
     — updates `ftl_state_current_path`, `_basename`, `_extension`.
   - `ftl::state::save` — writes listing state to session dir.
   - `ftl::sel::resolve_current` — rebuilds `ftl_selection_current`.
   - Computes the visible window (cursor may have scrolled).
   - `_ftl::list::render_header` — emits the header line.
   - Loops over the visible window, emitting each entry's color
     string. The cursor row gets the cursor color.
   - `_ftl::list::clear_below` — erases leftover lines.
   - `ftl::prev::dispatch` — renders the preview for the new current
     entry.

6. **`ftl::prev::dispatch`** sources `viewers/core` and calls
   `pviewers`, which dispatches to the appropriate viewer function
   based on the new `ftl_state_current_extension`.

7. The viewer function clears the preview pane and spawns the backend
   program (e.g. `mupdf` for a PDF, `w3mimgdisplay` for an image).

8. Control returns to the main loop, which calls `ftl::time::tick`,
   `ftl::pane::check_resize`, and `ftl::sel::sync_from_other_pane`,
   then blocks on `ftl::kbd::get_key` for the next key.

---

## 7. Failure Modes and Edge Cases

### 7.1 Bash limitations

- **No threads.** All I/O is synchronous. A slow `find` on NFS blocks
  the main loop. Mitigation: the file watcher runs in a background
  process; the scan runs in the foreground but is usually fast on
  local filesystems.
- **`set -u` strictness.** Unset variables cause exit. Always use
  `${var:-}` or `${var:+...}` for potentially-unset variables.
- **Subshell array mutation.** Functions called in a subshell (via
  `$(...)` or pipes) cannot mutate parent arrays. The
  `ftl::cmd::prompt` function uses `read` in the current shell to
  avoid this.
- **Associative array key quoting.** Keys with special characters
  (spaces, `/`) work but require careful quoting. Use
  `"${arr[$key]}"` not `${arr[$key]}`.

### 7.2 tmux dependency

- ftl requires tmux. It will not run without it.
- tmux version 3.0+ is required for `tmux popup`. Older versions
  degrade gracefully (popups become fullscreen).
- tmux must be in `$PATH`. The `tmux` function is not overridden.

### 7.3 Terminal compatibility

- Image preview requires X11 (`w3mimgdisplay`) or a modern terminal
  with native image protocols (kitty, wezterm, iTerm2).
- 256-color support is assumed. True color is not required but is
  used if available.
- The terminal must support the escape sequences in
  `ftl::kbd::normalize_key`. Some terminals emit non-standard
  sequences for F-keys, which may not be recognized.

### 7.4 State corruption

- If a pane crashes, its session dir may be left behind. The next
  ftl session will not clean it up (different PID). Periodic
  cleanup of `$FTL_STATE_DIR` may be needed.
- If two ftl instances share the same `$FTL_STATE_DIR` and the same
  PID (impossible in practice, but possible in containers), they will
  corrupt each other's state.

---

## 8. Next Steps

Continue to [03-modules.md](./03-modules.md) for the module-by-module
reference, or jump to [04-api-reference.md](./04-api-reference.md) if
you need to look up a specific function's signature.
