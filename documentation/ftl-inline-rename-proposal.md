# `ftl` — Inline Rename Mode: Design & Implementation Proposal

> **Subject:** A new modal, multi-entry renaming workflow that subsumes single rename, batch rename, sequential rename, regexp rename, and image labeling into one keyboard sub-mode.
> **Target branch:** `missing_functionalities` (forked from `reformat`)
> **Companion documents:** `ftl-missing-functionality.md` §1.6 (batch rename), `ftl-bindings-analysis.md`, `ftl-variables.md`
> **Status:** Proposal — pending review before implementation
> **Author of proposal:** continuation agent, 2026-07-23

---

## Table of Contents

1. [Why This Proposal Exists](#1-why-this-proposal-exists)
2. [Goals & Non-Goals](#2-goals--non-goals)
3. [User-Facing Behaviour](#3-user-facing-behaviour)
4. [Keymap Specification](#4-keymap-specification)
5. [State Model](#5-state-model)
6. [Module Layout](#6-module-layout)
7. [Algorithmic Walkthrough](#7-algorithmic-walkthrough)
8. [Edge Cases & Failure Modes](#8-edge-cases--failure-modes)
9. [Rendering & UI Cues](#9-rendering--ui-cues)
10. [Image Labeling — Design Choice](#10-image-labeling--design-choice)
11. [Integration With Existing Subsystems](#11-integration-with-existing-subsystems)
12. [Test Plan](#12-test-plan)
13. [Documentation Plan](#13-documentation-plan)
14. [Rollout & Migration](#14-rollout--migration)
15. [Open Questions](#15-open-questions)
16. [Appendix A: Full Pseudocode Listing](#appendix-a-full-pseudocode-listing)
17. [Appendix B: Pre-existing Bugs This Work Should Avoid](#appendix-b-pre-existing-bugs-this-work-should-avoid)

---

## 1. Why This Proposal Exists

`ftl` today has exactly **one** rename entry point: the `R` key (bound in `etc/bindings/leader_ftl` / `etc/ftlrc` to `ftl::cmd::rename_selection`), which delegates to the external tool `edir`. `edir` is a fine bulk renamer — it opens your `$EDITOR` on a list of filenames and applies the diff on save — but it has three problems inside `ftl`'s modal flow:

1. **It escapes the modal context.** The user leaves `ftl`'s keyboard engine, enters `vim` (or whatever), saves, returns, and `ftl::list::change_dir` rescans. There is no live preview of the new name *while typing*, no per-entry navigation *during* the rename, and no way to abort a single rename without aborting the whole batch.
2. **It is binary: either edit all, or edit none.** A common workflow — "rename this one, move down, rename that one, move down, batch-rename everything that ends in `.jpeg` to `.jpg`" — is impossible without leaving the rename mindset and re-entering `edir` repeatedly.
3. **It does not compose with selection.** Renaming a tagged subset requires first selecting exactly that subset, then `R`, then `edir` shows only those names. There is no "rename this one file, then jump to the next tagged file" affordance.

The `missing_functionalities` roadmap (`documentation/ftl-missing-functionality.md` §1.6) already lists **batch rename with regexp** as a separate binding (`xR`). The user's request goes further: instead of N separate rename commands (`R` for `edir`, `xR` for sed-pattern, plus separate ideas for sequential-numbered and image-label renames), define **one modal entry point** that exposes all of them as keys inside a sub-mode. This is the same design pattern that `incremental_search` already uses (`ftl_kbd_submode_handler`), so it is consistent with the codebase's architecture rather than a new idiom.

---

## 2. Goals & Non-Goals

### Goals

1. **One entry point, multiple operations.** `LEADER r i` enters "inline rename mode". Inside, the user can: rename a single entry inline (with live cursor on the name), navigate up/down, delete entries, toggle selection, run a sequential-numbered rename across the selection or all entries, run a regexp/sed-pattern rename across the same, write EXIF labels into image files, and exit cleanly.
2. **Live, in-place rename editing.** While editing one entry, the user sees the draft name rendered at the cursor position (replacing the original name), with the cursor cell highlighted. Backspace deletes from the right; letters/numbers/symbols append on the right; `Escape` aborts and restores the original; `Return` commits via `mv`.
3. **Two-level modal state.** An *outer* mode (navigation + dispatch) and an *inner* mode (per-entry text editing). The inner mode is the only place text is mutated. This mirrors how the existing `incremental_search` sub-mode handler is structured (one handler function, branching on `ftl_kbd_current_key`), so the new code will be familiar to anyone who has read `etc/bindings/incremental_search`.
4. **No new external dependencies.** `mv`, `sed -E`, `exiftool` (already used in `viewers/core:303`), and Bash 5 associative arrays are sufficient. No new packages, no `perl` (except via `exiftool` which already pulls it in).
5. **Composable with selection.** Sequential and regexp renames operate on `ftl_selection_current` if non-empty, otherwise on `ftl_list_entries`. This matches the convention used by `ftl::cmd::rename_selection` and the `delete` command.
6. **Testable in isolation.** The sub-mode handler is a plain Bash function that reads `ftl_kbd_current_key` and mutates globals. Unit tests can call it directly with a fake `ftl_kbd_current_key` and assert on the resulting state, without spawning tmux. This is exactly the test pattern already used in `test/unit/test_keyboard.sh` and `test/unit/test_missing_functionalities.sh`.

### Non-Goals

1. **Replacing `edir`.** `R` continues to invoke `edir` for users who want a full `$EDITOR`-based bulk rename. The new mode is additive.
2. **Cross-directory rename.** Inline rename only changes the basename of entries inside the current `PWD`. Cross-directory moves are out of scope (they are a different operation, already covered by `PM` / move-to-preset-destination).
3. **Undo/redo of renames.** Out of scope; the user can re-enter the mode and retype.
4. **Mouse support inside the rename input.** Tmux mouse handling is unchanged; only keyboard input is processed by the sub-mode handler.
5. **Unicode-aware grapheme editing.** Backspace deletes one *byte* (matching Bash's `read` behaviour). Handling combining marks is out of scope; this matches how `incremental_search` already handles `BACKSPACE` (`${ftl_state_search_string::-1}`).
6. **Concurrent multi-entry editing.** Only one entry is being renamed at a time. Bulk operations (sequential, regexp) act atomically on the whole set, not by interleaving edits.

---

## 3. User-Facing Behaviour

### 3.1 Entry

The user presses `LEADER r i` (Leader = `\`, the existing `ftl_cfg_leader_key='BACKSLASH'`). The dispatch trie (`ftl_kbd_trie["LEADERri"]`) maps to `ftl::plugin::inline_rename::enter`. That function:

- Sets `ftl_kbd_submode_handler=ftl::plugin::inline_rename::dispatch`
- Initialises the per-mode state (see §5)
- Forces a `ftl::list::render` so the user sees the mode glyph in the header (see §9)

From this point until `ftl_kbd_submode_handler` is cleared, every keypress is routed by `ftl::kbd::dispatch` (see `keyboard.sh:290-293`) to `ftl::plugin::inline_rename::dispatch`.

### 3.2 Outer Mode (Navigation + Dispatch)

Default state on entry. The header shows `[RENAME]` (or a glyph from `ftl_cfg_glyph_inline_rename`). The user can:

- **`UP` / `k`** — move cursor up one entry. Equivalent to `ftl::cmd::cursor_up`.
- **`DOWN` / `j`** — move cursor down one entry.
- **`PGUP` / `K`** — move cursor up by `ftl_cfg_move_step_size`.
- **`PGDN` / `J`** — move cursor down by `ftl_cfg_move_step_size`.
- **`HOME` / `g`** — jump to first entry.
- **`END` / `G`** — jump to last entry.
- **`SPACE` / `t`** — toggle selection tag on the current entry (delegates to `ftl::sel::flip`).
- **`TAB`** — toggle selection and move down (mirrors the existing `TAB` binding in `ftlrc`).
- **`DEL` / `x`** — delete the current entry (delegates to a constrained variant of `ftl::cmd::delete` that operates only on the current entry, with a single-key confirmation prompt — see §7.4).
- **`d`** — delete the current entry without confirmation (matches the existing `d` binding's "delete" semantics for power users; this is opt-in via `ftl_cfg_inline_rename_no_confirm_delete=0`).
- **`Return`** — enter inner rename mode for the current entry, with the draft pre-filled by the existing basename (cursor at end). This is the most common case: "rename this file".
- **Any other letter `[a-zA-Z0-9_\-.]`** — enter inner rename mode for the current entry, with the draft *starting empty* and that letter as the first character. This is the "I want a totally new name" case.
- **`r`** — sequential rename across the selection (or all entries if no selection). Prompts for a base name via `ftl::cmd::prompt`, then renames `entry[i] → base_001`, `entry[i+1] → base_002`, etc.
- **`R`** — regexp rename across the selection (or all entries). Prompts for a `sed -E` expression (default `s/OLD/NEW/`), applies it to each basename.
- **`l`** — image-label mode for the current entry (only valid if `ftl_state_current_extension` is in `ftl_cfg_image_extensions`; otherwise no-ops with a brief flash). Drops into a variant of inner mode where the draft is the new EXIF label, not the new filename.
- **`Escape`** — exit inline rename mode entirely. Clear `ftl_kbd_submode_handler`. The header glyph is removed on the next render.
- **`q`** — same as `Escape` (mnemonic: "quit mode").

### 3.3 Inner Mode (Per-Entry Text Editing)

The cursor row's entry is replaced by an editable draft. The draft is rendered in inverse video (or with the existing `ftl_cfg_cursor_color_search` repurposed). The user can:

- **Any printable character `[ -~]`** (ASCII space through tilde, minus the ones already reserved) — append to draft.
- **`BACKSPACE`** — delete last character of draft. If draft is empty, no-op.
- **`LEFT`** — move draft cursor left one character (for insertion). *Optional — can be deferred to a later revision if the cursor model adds complexity. Initial implementation can be append-only with backspace, like the existing `incremental_search`.*
- **`RIGHT`** — move draft cursor right.
- **`HOME` / `CTL-A`** — move draft cursor to start.
- **`END` / `CTL-E`** — move draft cursor to end.
- **`CTL-W`** — delete previous word (whitespace-delimited).
- **`CTL-U`** — delete entire draft.
- **`Return`** — commit: `mv "$original_path" "$dir/$draft"`. If the target name already exists and is not the original, show an error and stay in inner mode. On success, refresh the listing and return to outer mode, leaving the cursor on the renamed entry.
- **`Escape`** — abort: discard the draft, return to outer mode. The original entry is unchanged.
- **`TAB`** — commit current rename, then immediately enter inner mode on the *next* entry down (with empty draft). This is the "rename this one, move on" affordance that `edir` lacks.

### 3.4 Image-Label Sub-Mode

Triggered by `l` in outer mode when the current entry is an image. The draft edits an EXIF/IPTC label, not the filename. On commit:

- `exiftool -overwrite_original -IPTC:ObjectName="$draft" -EXIF:ImageDescription="$draft" "$path"`
- The filename is **not** changed.
- The preview pane (if any) is signalled to re-read EXIF.

On `Escape`, the EXIF is untouched. The user returns to outer mode.

The draft is initially pre-filled with the existing label, retrieved via:
- `exiftool -s3 -IPTC:ObjectName "$path"` (fallback to `-EXIF:ImageDescription` if empty).

---

## 4. Keymap Specification

### 4.1 Outer Mode

| Key                | Action                                              | Existing function reused                  |
|--------------------|-----------------------------------------------------|-------------------------------------------|
| `UP`, `k`          | cursor up                                           | `ftl::cmd::cursor_up`                     |
| `DOWN`, `j`        | cursor down                                         | `ftl::cmd::cursor_down`                   |
| `PGUP`, `K`        | cursor up by step                                   | `ftl::cmd::cursor_up_step` (new wrapper)  |
| `PGDN`, `J`        | cursor down by step                                 | `ftl::cmd::cursor_down_step` (new wrapper)|
| `HOME`, `g`        | jump to first                                       | inline assignment + `ftl::list::render`   |
| `END`, `G`         | jump to last                                        | inline assignment + `ftl::list::render`   |
| `SPACE`, `t`       | toggle selection                                    | `ftl::sel::flip "$ftl_state_current_path"`|
| `TAB`              | toggle + move down                                  | `ftl::sel::flip` + `ftl::cmd::cursor_down`|
| `DEL`, `x`         | delete current (with confirm)                       | `ftl::plugin::inline_rename::delete_one`  |
| `d`                | delete current (no confirm, opt-in)                 | `ftl::plugin::inline_rename::delete_one`  |
| `Return`           | inner mode, draft = current basename                | `ftl::plugin::inline_rename::begin_edit`  |
| `[a-zA-Z0-9_\-.]`  | inner mode, draft = that character                  | `ftl::plugin::inline_rename::begin_edit`  |
| `r`                | sequential rename                                   | `ftl::plugin::inline_rename::sequential`  |
| `R`                | regexp rename                                       | `ftl::plugin::inline_rename::regexp`      |
| `l`                | image-label inner mode (if image)                   | `ftl::plugin::inline_rename::begin_label` |
| `Escape`, `q`      | exit inline rename mode                             | `ftl::plugin::inline_rename::exit`        |

### 4.2 Inner Mode

| Key                  | Action                                                |
|----------------------|-------------------------------------------------------|
| `[ -~]` (printable)  | append char to draft                                  |
| `BACKSPACE`          | delete last char                                      |
| `LEFT` (deferred)    | move draft cursor left                                |
| `RIGHT` (deferred)   | move draft cursor right                               |
| `HOME` / `CTL-A`     | draft cursor to start                                 |
| `END` / `CTL-E`      | draft cursor to end                                   |
| `CTL-W`              | delete previous word                                  |
| `CTL-U`              | clear draft                                           |
| `Return`             | commit `mv`, return to outer mode                     |
| `Escape`             | abort, return to outer mode                           |
| `TAB`                | commit, then enter inner mode on next entry           |

### 4.3 Binding Registration

In a new file `config/ftl/etc/bindings/inline_rename` (mirroring the layout of `incremental_search`):

```bash
ftl::kbd::bind	leader	rename	"LEADER r i"	ftl::plugin::inline_rename::enter	"inline rename mode"
```

And in `config/ftl/etc/core/ftl_setup`, the new binding file is sourced alongside the other leader bindings:

```bash
. "$FTL_CFG/etc/bindings/inline_rename"
```

Note: the existing `LEADER r` namespace is currently **unused** (verified by grep over `etc/bindings/`), so `LEADER r i` does not collide with any existing binding. `LEADER r` alone is also free; reserving it for the "rename family" is consistent with how `LEADER f` is the "file-utils family" and `LEADER h` is "help".

---

## 5. State Model

All state lives in module-global variables, following the project's `ftl_<module>_<name>` convention. None of these are persisted to disk — they are entirely transient and cleared on `exit`.

### 5.1 Mode State

```bash
ftl_inline_rename_active=0          # 1 = outer mode, 2 = inner mode, 0 = inactive
ftl_inline_rename_original_path=    # full path of entry being edited (inner mode)
ftl_inline_rename_original_name=    # basename at edit start, for restore-on-abort
ftl_inline_rename_draft=            # current draft string
ftl_inline_rename_draft_cursor=0    # 0-based offset into draft (insertion point)
ftl_inline_rename_is_label=0        # 1 = editing EXIF label, not filename
ftl_inline_rename_history=()        # array of "oldpath\tnewpath" for tab-rename flow
```

### 5.2 Selection Snapshot for Bulk Ops

When the user presses `r` or `R`, the operation must act on a *frozen snapshot* of entries — not on whatever is selected at the moment of the actual `mv`. Reason: a regexp rename can change the sort order (e.g. prefixing all with `a_` re-sorts), and we do not want the operation to apply to the wrong entries mid-flight.

```bash
ftl_inline_rename_bulk_targets=()   # snapshot of full paths for the bulk op
```

Populated by `ftl::plugin::inline_rename::snapshot_targets`:

```bash
ftl::plugin::inline_rename::snapshot_targets() {
    ftl_inline_rename_bulk_targets=()
    if (( ${#ftl_selection_tags[@]} )) ; then
        ftl_inline_rename_bulk_targets=( "${!ftl_selection_tags[@]}" )
    else
        ftl_inline_rename_bulk_targets=( "${ftl_list_entries[@]}" )
    fi
}
```

### 5.3 Configuration Variables (added to `etc/ftlrc`)

```bash
# Whether 'd' in inline-rename mode deletes without confirmation
ftl_cfg_inline_rename_no_confirm_delete=0

# Format string for sequential rename. %d is the 1-based index, %03d for zero-padded.
ftl_cfg_inline_rename_sequence_format='%03d'

# Default sed expression pre-filled in the regexp-rename prompt
ftl_cfg_inline_rename_regexp_default='s/OLD/NEW/'

# File extensions considered images (for the 'l' label sub-mode)
ftl_cfg_image_extensions=(jpg jpeg png gif tiff bmp webp heic)
```

### 5.4 No Persistence

None of the `ftl_inline_rename_*` variables are written by `ftl::state::save` (which only serializes a fixed allow-list — see `state.sh:38-75`). This is intentional: inline-rename state is per-keystroke and should never leak to the preview pane or to a sibling ftl process. The state is also not part of `ftl::state::serialize_info`, so external commands (`finfo`, `fsh`) cannot see it.

---

## 6. Module Layout

### 6.1 New Files

| Path                                             | Purpose                                              |
|--------------------------------------------------|------------------------------------------------------|
| `config/ftl/etc/core/modules/inline_rename.sh`   | All functions, globals, and dispatch logic           |
| `config/ftl/etc/bindings/inline_rename`          | The `ftl::kbd::bind` registration (1 line)           |
| `test/unit/test_inline_rename.sh`                | Unit tests for the dispatch logic                    |
| `test/integration/test_inline_rename_integration.sh` | End-to-end tmux test (rename, abort, sequential)  |
| `documentation/ftl-inline-rename-proposal.md`    | This document                                        |
| `docs/src/bindings/inline-rename.md`             | mdBook user-facing documentation                     |

### 6.2 Modified Files

| Path                                              | Change                                                                |
|---------------------------------------------------|----------------------------------------------------------------------|
| `config/ftl/etc/core/ftl_setup`                   | Source the new module + binding file                                 |
| `config/ftl/etc/ftlrc`                            | Add the four `ftl_cfg_inline_rename_*` config variables              |
| `man/ftl.md`                                      | Document the new `LEADER r i` binding and the sub-mode keymap        |
| `docs/src/SUMMARY.md`                             | Add link to the new mdBook page                                      |
| `docs/src/bindings.md` (or equivalent)            | Cross-reference the new mode                                         |

### 6.3 Module Header (Module File Skeleton)

The new module file follows the same header convention as every other module (see `keyboard.sh:1-35`, `selection.sh:1-32` for templates):

```bash
# inline_rename.sh — modal inline rename mode
#
# Provides a two-level sub-mode (outer: navigation + dispatch; inner:
# per-entry text editing) entered via LEADER r i. Supports single
# rename, sequential rename, regexp rename, image-label edit, and
# delete-from-within-mode.
#
# Public functions:
#   ftl::plugin::inline_rename::enter        — entry point (bound to LEADER r i)
#   ftl::plugin::inline_rename::exit         — clear sub-mode and state
#   ftl::plugin::inline_rename::dispatch     — sub-mode handler (set as ftl_kbd_submode_handler)
#
# Private functions:
#   _ftl::plugin::inline_rename::begin_edit  — enter inner mode for current entry
#   _ftl::plugin::inline_rename::begin_label — enter inner mode for EXIF label
#   _ftl::plugin::inline_rename::commit      — apply the draft (mv or exiftool)
#   _ftl::plugin::inline_rename::abort       — discard draft, return to outer
#   _ftl::plugin::inline_rename::sequential  — sequential-numbered bulk rename
#   _ftl::plugin::inline_rename::regexp      — sed-pattern bulk rename
#   _ftl::plugin::inline_rename::delete_one  — delete current entry
#   _ftl::plugin::inline_rename::snapshot_targets — freeze selection/list for bulk op
#   _ftl::plugin::inline_rename::render_draft — render the cursor row with the draft
#
# Globals:
#   ftl_inline_rename_active              — 0/1/2 (inactive/outer/inner)
#   ftl_inline_rename_original_path       — entry being edited (inner)
#   ftl_inline_rename_original_name       — basename at edit start
#   ftl_inline_rename_draft               — current draft string
#   ftl_inline_rename_draft_cursor        — insertion offset
#   ftl_inline_rename_is_label            — 1 if editing EXIF label
#   ftl_inline_rename_bulk_targets        — frozen snapshot for bulk ops
#   ftl_inline_rename_history             — array of "old\tnew" for tab-flow
```

### 6.4 Why a Single Module, Not a Plugin Directory

The `incremental_search` and `fzf_search` bindings live directly under `etc/bindings/` (not under `etc/bindings/lib/`). They are short — under 50 lines each. The inline rename mode is larger (~250-350 lines estimated) but still cohesive: all its functions share the same state, the same dispatch entry point, and the same lifecycle. Splitting it into a `lib/inline_rename/` directory with one file per function would create artificial seams (each function would need to re-source the others). Keeping it as one module file under `etc/core/modules/` matches how `keyboard.sh`, `selection.sh`, etc. are organised: cohesive domain → one file.

The binding *registration* still lives in `etc/bindings/inline_rename` (one line), which is the pattern `incremental_search` uses. The module file lives in `etc/core/modules/` so it gets sourced once at startup by `ftl_setup` (alongside the other modules), not lazily on first key press. This avoids the bug class where a binding fires before its function is defined.

---

## 7. Algorithmic Walkthrough

### 7.1 Entry: `ftl::plugin::inline_rename::enter`

```bash
ftl::plugin::inline_rename::enter() {
    ftl_kbd_submode_handler=ftl::plugin::inline_rename::dispatch
    ftl_inline_rename_active=1
    ftl_inline_rename_original_path=
    ftl_inline_rename_original_name=
    ftl_inline_rename_draft=
    ftl_inline_rename_draft_cursor=0
    ftl_inline_rename_is_label=0
    ftl_inline_rename_history=()
    ftl_inline_rename_bulk_targets=()
    ftl::list::render   # re-render to show the [RENAME] glyph in header
}
```

### 7.2 Dispatch: `ftl::plugin::inline_rename::dispatch`

This is the function set as `ftl_kbd_submode_handler`. It is called by `ftl::kbd::dispatch` (see `keyboard.sh:290-293`) on every keypress while the sub-mode is active. It branches first on `ftl_inline_rename_active` (outer vs inner), then on `ftl_kbd_current_key`.

```bash
ftl::plugin::inline_rename::dispatch() {
    local key="$ftl_kbd_current_key"

    # Timeout/error from read — ignore
    [[ "$key" == ERROR_* ]] && return

    if (( ftl_inline_rename_active == 1 )) ; then
        _ftl::plugin::inline_rename::dispatch_outer "$key"
    elif (( ftl_inline_rename_active == 2 )) ; then
        _ftl::plugin::inline_rename::dispatch_inner "$key"
    fi
}
```

### 7.3 Outer Dispatch

```bash
_ftl::plugin::inline_rename::dispatch_outer() {
    local key="$1"
    case "$key" in
        UP|k)            ftl::cmd::cursor_up ;;
        DOWN|j)          ftl::cmd::cursor_down ;;
        PGUP|K)          ftl::cmd::cursor_up_step ;;
        PGDN|J)          ftl::cmd::cursor_down_step ;;
        HOME|g)          ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]=0 ; ftl::list::render ;;
        END|G)           ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]=$(( ftl_list_entry_count - 1 )) ; ftl::list::render ;;
        SPACE|t)         ftl::sel::flip "$ftl_state_current_path" ; ftl::list::render ;;
        TAB)             ftl::sel::flip "$ftl_state_current_path" ; ftl::cmd::cursor_down ;;
        DEL|x)           _ftl::plugin::inline_rename::delete_one 1 ;;
        d)               _ftl::plugin::inline_rename::delete_one "$(( 1 - ftl_cfg_inline_rename_no_confirm_delete ))" ;;
        ENTER|RETURN)    _ftl::plugin::inline_rename::begin_edit "" ;;
        r)               _ftl::plugin::inline_rename::sequential ;;
        R)               _ftl::plugin::inline_rename::regexp ;;
        l)               _ftl::plugin::inline_rename::begin_label ;;
        ESCAPE|q)        ftl::plugin::inline_rename::exit ;;
        [a-zA-Z0-9_\-.]) _ftl::plugin::inline_rename::begin_edit "$key" ;;
        *)               : ;; # ignore unknown keys
    esac
}
```

### 7.4 Delete One

```bash
_ftl::plugin::inline_rename::delete_one() {
    local confirm="$1"
    local target="$ftl_state_current_path"
    [[ -e "$target" ]] || return 0

    if (( confirm )) ; then
        ftl::cmd::prompt "delete $ftl_state_current_basename? [y|N]" -sn1
        [[ "$REPLY" != y ]] && { ftl::list::render ; return ; }
    fi

    $ftl_cfg_delete_command "$target"
    ftl_list_mime_cache=()
    ftl::list::change_dir
}
```

**Important:** note that we read `$REPLY` here, not `$ftl_kbd_current_key`. This is the documented contract of `read -e -rp "$@"` (see Appendix B for why some existing call sites appear to misuse this).

### 7.5 Begin Edit

```bash
_ftl::plugin::inline_rename::begin_edit() {
    local first_char="$1"
    ftl_inline_rename_original_path="$ftl_state_current_path"
    ftl_inline_rename_original_name="$ftl_state_current_basename"
    ftl_inline_rename_draft="$first_char"
    ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
    ftl_inline_rename_is_label=0
    ftl_inline_rename_active=2
    _ftl::plugin::inline_rename::render_draft
}
```

### 7.6 Inner Dispatch

```bash
_ftl::plugin::inline_rename::dispatch_inner() {
    local key="$1"
    case "$key" in
        BACKSPACE)
            (( ${#ftl_inline_rename_draft} > 0 )) && {
                ftl_inline_rename_draft="${ftl_inline_rename_draft:0:${#ftl_inline_rename_draft}-1}"
                (( ftl_inline_rename_draft_cursor > 0 )) && (( ftl_inline_rename_draft_cursor-- ))
            }
            ;;
        CTL-W)
            # delete previous word (whitespace-delimited)
            ftl_inline_rename_draft="${ftl_inline_rename_draft% *}"
            ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
            ;;
        CTL-U)
            ftl_inline_rename_draft=
            ftl_inline_rename_draft_cursor=0
            ;;
        CTL-A|HOME)
            ftl_inline_rename_draft_cursor=0
            ;;
        CTL-E|END)
            ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
            ;;
        # LEFT/RIGHT deferred to v2 — initial release is append-only with backspace
        ENTER|RETURN)
            _ftl::plugin::inline_rename::commit
            return
            ;;
        ESCAPE)
            _ftl::plugin::inline_rename::abort
            return
            ;;
        TAB)
            _ftl::plugin::inline_rename::commit
            (( ftl_state_cursor_index < ftl_list_entry_count - 1 )) && {
                ftl::cmd::cursor_down
                _ftl::plugin::inline_rename::begin_edit ""
            }
            return
            ;;
        ERROR_*) return ;;
        *)
            # Printable ASCII (space through tilde). Reject anything outside.
            if [[ "$key" =~ ^[ -~]$ ]] ; then
                local left="${ftl_inline_rename_draft:0:ftl_inline_rename_draft_cursor}"
                local right="${ftl_inline_rename_draft:ftl_inline_rename_draft_cursor}"
                ftl_inline_rename_draft="${left}${key}${right}"
                (( ftl_inline_rename_draft_cursor++ ))
            fi
            ;;
    esac
    _ftl::plugin::inline_rename::render_draft
}
```

### 7.7 Commit (Filename)

```bash
_ftl::plugin::inline_rename::commit() {
    [[ -n "$ftl_inline_rename_draft" ]] || { _ftl::plugin::inline_rename::abort ; return ; }

    if (( ftl_inline_rename_is_label )) ; then
        _ftl::plugin::inline_rename::commit_label
        return
    fi

    local dir="${ftl_inline_rename_original_path%/*}"
    local target="$dir/$ftl_inline_rename_draft"

    # No-op if name unchanged
    if [[ "$target" == "$ftl_inline_rename_original_path" ]] ; then
        _ftl::plugin::inline_rename::abort
        return
    fi

    # Refuse to overwrite
    if [[ -e "$target" ]] ; then
        # Brief flash — render an error message in the header area
        ftl_state_inline_rename_error="target exists: $ftl_inline_rename_draft"
        _ftl::plugin::inline_rename::render_draft
        ftl_state_inline_rename_error=
        return
    fi

    mv -- "$ftl_inline_rename_original_path" "$target"
    ftl_inline_rename_history+=( "${ftl_inline_rename_original_path}"$'\t'"$target" )
    ftl_inline_rename_active=1
    ftl_list_mime_cache=()
    ftl::list::change_dir '' "$ftl_inline_rename_draft"
}
```

### 7.8 Commit (EXIF Label)

```bash
_ftl::plugin::inline_rename::commit_label() {
    local path="$ftl_inline_rename_original_path"
    exiftool -overwrite_original \
        -IPTC:ObjectName="$ftl_inline_rename_draft" \
        -EXIF:ImageDescription="$ftl_inline_rename_draft" \
        "$path" >/dev/null 2>&1
    ftl_inline_rename_history+=( "$path(exif)$ftl_inline_rename_draft" )
    ftl_inline_rename_active=1
    ftl::list::render
}
```

### 7.9 Sequential Rename

```bash
_ftl::plugin::inline_rename::sequential() {
    ftl::cmd::prompt 'sequential base name: '
    local base="$REPLY"
    [[ -n "$base" ]] || { ftl::list::render ; return ; }

    _ftl::plugin::inline_rename::snapshot_targets
    local i=1 target new_path
    for target in "${ftl_inline_rename_bulk_targets[@]}" ; do
        local dir="${target%/*}" ext=
        local name="${target##*/}"
        [[ "$name" == *.* ]] && ext=".${name##*.}"
        # Don't double-apply the extension
        local seq
        printf -v seq "$ftl_cfg_inline_rename_sequence_format" "$i"
        new_path="$dir/$base$seq$ext"
        [[ -e "$new_path" && "$new_path" != "$target" ]] && {
            echo "ftl: inline_rename: skip (target exists): $new_path" >&2
            ((i++)) ; continue
        }
        [[ "$new_path" != "$target" ]] && mv -- "$target" "$new_path"
        ftl_inline_rename_history+=( "$target"$'\t'"$new_path" )
        ((i++))
    done
    ftl_list_mime_cache=()
    ftl::list::change_dir
}
```

### 7.10 Regexp Rename

```bash
_ftl::plugin::inline_rename::regexp() {
    ftl::cmd::prompt 'sed -E pattern: ' -i "$ftl_cfg_inline_rename_regexp_default"
    local pat="$REPLY"
    [[ -n "$pat" && "$pat" != "$ftl_cfg_inline_rename_regexp_default" ]] \
        || { ftl::list::render ; return ; }

    _ftl::plugin::inline_rename::snapshot_targets
    local target new_name new_path
    for target in "${ftl_inline_rename_bulk_targets[@]}" ; do
        local dir="${target%/*}" name="${target##*/}"
        new_name="$(printf '%s' "$name" | sed -E "$pat")"
        [[ "$new_name" == "$name" || -z "$new_name" ]] && continue
        new_path="$dir/$new_name"
        [[ -e "$new_path" ]] && {
            echo "ftl: inline_rename: skip (target exists): $new_path" >&2
            continue
        }
        mv -- "$target" "$new_path"
        ftl_inline_rename_history+=( "$target"$'\t'"$new_path" )
    done
    ftl_list_mime_cache=()
    ftl::list::change_dir
}
```

### 7.11 Exit

```bash
ftl::plugin::inline_rename::exit() {
    ftl_inline_rename_active=0
    ftl_inline_rename_original_path=
    ftl_inline_rename_original_name=
    ftl_inline_rename_draft=
    ftl_inline_rename_draft_cursor=0
    ftl_inline_rename_is_label=0
    ftl_inline_rename_bulk_targets=()
    ftl_kbd_submode_handler=
    ftl::list::render
}
```

### 7.12 Render Draft

This is the trickiest piece. It must redraw the cursor row with the draft in place of the original name, without disturbing the rest of the listing. Two approaches:

**Approach A (minimal):** Don't touch the listing; just emit a one-line overlay at the cursor's terminal position using `tput cup`. The draft appears in inverse video at the cursor's row.

**Approach B (integrated):** Patch `ftl::list::render` to check `ftl_inline_rename_active == 2` and, if so, substitute `${ftl_list_entry_colors[$ftl_state_cursor_index]}` with a rendered draft string.

**Recommendation: Approach A.** It is less invasive (no change to `list.sh`), re-renders only one row per keystroke (fast), and naturally falls through to a full `ftl::list::render` on commit/abort. The cost is a small visual artefact if the cursor row scrolls, but since the user is editing in place, scroll should not happen mid-edit.

```bash
_ftl::plugin::inline_rename::render_draft() {
    # Compute the terminal row of the cursor entry
    local row=$(( ftl_state_cursor_index - ftl_list_window_top + 2 ))

    # Compute the prefix (cursor glyph + any indentation already emitted by list::render)
    # The list rendering uses column 0 for the selection glyph, then the colored name.
    local prefix=" "  # selection glyph slot (assume unselected during edit)
    local draft_render="${ftl_inline_rename_draft}"

    # Show cursor as inverse-video on the char at draft_cursor
    local left="${draft_render:0:ftl_inline_rename_draft_cursor}"
    local char_at="${draft_render:ftl_inline_rename_draft_cursor:1}"
    local right="${draft_render:ftl_inline_rename_draft_cursor+1}"
    [[ -z "$char_at" ]] && char_at=" "  # trailing cursor shows as space
    local rendered="${left}\e[7m${char_at}\e[0m${right}"

    # If there's an error message, append it
    [[ -n "${ftl_state_inline_rename_error:-}" ]] \
        && rendered+="  \e[31m[${ftl_state_inline_rename_error}]\e[0m"

    # Position and emit
    echo -ne "\e[${row};0H\e[K\e[33m[RENAME] \e[0m${prefix}${rendered}"
}
```

### 7.13 Snapshot Targets

Already shown in §5.2. Included here for completeness — it's the safety mechanism that makes bulk ops deterministic.

---

## 8. Edge Cases & Failure Modes

### 8.1 The User Presses `LEADER r i` While a Search Is Active

`ftl_kbd_submode_handler` is currently set to `ftl::plugin::incremental_search::incremental_find`. Overwriting it from inside `enter` is fine — but we should first call the search's exit logic to restore `ftl_cfg_cursor_color_current` from `ftl_cfg_cursor_color_search` back to `ftl_cfg_cursor_color_default`. This means `enter` should:

```bash
if [[ "$ftl_kbd_submode_handler" == "ftl::plugin::incremental_search::incremental_find" ]] ; then
    ftl_cfg_cursor_color_current="$ftl_cfg_cursor_color_default"
    ftl_state_search_string=
fi
```

(Reverse-engineered from `incremental_search` lines 8-18.)

### 8.2 The User Presses `LEADER r i` Inside a Virtual List

`ftl_plugin_vfiles` / `ftl_plugin_vdirs` may be non-empty (e.g. inside an `fzf_search` result list). Renaming a virtual entry is meaningless — there is no underlying file. The `enter` function should check:

```bash
(( ${#ftl_plugin_vfiles[@]} || ${#ftl_plugin_vdirs[@]} )) && {
    echo "ftl: inline_rename: not available in virtual lists" >&2
    return
}
```

### 8.3 The Cursor Is on an Empty Listing

If `ftl_list_entry_count == 0`, the outer mode's navigation keys are no-ops, the `Return` and letter keys do nothing (no entry to edit), and the only useful keys are `Escape`/`q` to exit. `enter` should still succeed (so the user can `LEADER r i` then immediately `Escape`), but `begin_edit` and the bulk ops should be guarded:

```bash
_ftl::plugin::inline_rename::begin_edit() {
    (( ftl_list_entry_count )) || return 0
    ...
}
```

### 8.4 The Draft Is Empty on Commit

Treated as abort — the user pressed `Return` without typing anything. Calling `mv` to an empty name would be a disaster. Already handled in §7.7.

### 8.5 The Draft Equals the Existing Name

No-op commit — same as abort. Already handled in §7.7.

### 8.6 The Target Name Already Exists

We refuse to overwrite. The error message is shown in the cursor row (see §7.7 and §7.12), and the user stays in inner mode. This is the safest default; an opt-in overwrite flag (`ftl_cfg_inline_rename_overwrite=0`) can be added later.

### 8.7 The User Presses `TAB` on the Last Entry

`ftl::cmd::cursor_down` is a no-op (cursor is already at the bottom). The commit still happens, but we do not enter inner mode on a non-existent next entry. Already guarded in §7.6 by the `(( ftl_state_cursor_index < ftl_list_entry_count - 1 ))` check.

### 8.8 The Directory Changes Under Us (External `mv`)

`ftl::pane::start_file_watcher` (called by `_ftl::list::scan_and_render`) will trigger a rescan. If the entry being edited disappears mid-edit, the commit's `mv` will fail with "No such file or directory", which is the correct behaviour. The user sees the error and returns to outer mode.

### 8.9 `exiftool` Is Not Installed

`begin_label` should check `command -v exiftool` and bail early with a message if it's missing. `exiftool` is already an implicit dependency of `viewers/core:303`, so this is consistent with the rest of `ftl` — but the check should be explicit, since image-labeling is an opt-in sub-mode.

### 8.10 The Selection Contains Files From Multiple Directories

Sequential and regexp rename only change the *basename*; the directory prefix is preserved. So a multi-directory selection is safe — each file is renamed in its own directory. This is the correct behaviour and matches `edir`'s contract.

### 8.11 The User Leaves the Mode via Pane Switch

If the user switches tmux panes (`LEADER`-arrow or similar) while inner mode is active, the `ftl_kbd_submode_handler` is still set when they return. This is actually fine — the draft is preserved in the module globals, and the next keypress resumes the edit. No special handling needed. (This matches `incremental_search`'s behaviour.)

---

## 9. Rendering & UI Cues

### 9.1 Header Glyph

`_ftl::list::render_header` (in `list.sh:418-490`) builds the header from `ftl_cfg_glyph_listing_mode[...]`, `ftl_cfg_glyph_image_mode[...]`, etc. The new mode should add a glyph when `ftl_inline_rename_active`:

```bash
# In _ftl::list::render_header, after computing $head:
(( ftl_inline_rename_active == 1 )) && head+=" ${ftl_cfg_glyph_inline_rename:-⟦R⟧}"
(( ftl_inline_rename_active == 2 )) && head+=" ${ftl_cfg_glyph_inline_rename_edit:-⟦R✎⟧}"
```

This is a one-line addition to `list.sh`. The glyphs are configurable via `ftl_cfg_glyph_inline_rename` and `ftl_cfg_glyph_inline_rename_edit` (defaults shown).

### 9.2 Cursor Row Draft

See §7.12. The draft is rendered in inverse video at the cursor's terminal row, with the insertion cursor highlighted (also inverse video, but on the character at the insertion offset). The original name is not shown during editing — it can be restored with `Escape`.

### 9.3 Error Overlay

When a commit fails (target exists, `mv` error, etc.), the error message is rendered in red at the right side of the cursor row, separated by two spaces. It is cleared on the next keystroke.

### 9.4 Bulk-Operation Progress

Sequential and regexp renames can be slow on large selections (hundreds of files). During the operation, the header should show:

```
[RENAME] sequential: 42/100...
```

This requires `ftl::list::render_header` to be called between each `mv`. Since `mv` is fast on local filesystems, this is only a real concern on NFS or large files. The implementation can debounce: update the header every 10 operations.

---

## 10. Image Labeling — Design Choice

### 10.1 Why EXIF, Not Filename Prefix

The user's spec says "special shortcut to add label to image". Two interpretations:

1. **Filename-based:** Rename `IMG_001.jpg` to `vacation_001.jpg` where "vacation" is the label.
2. **Metadata-based:** Write the label into the image's EXIF/IPTC metadata, leaving the filename unchanged.

The proposal chooses (2) because:

- It matches the user's wording ("add label to image", not "rename image with label"). A label is metadata, not a filename component.
- It is non-destructive to the filename (which may be a sequence number that other tools depend on).
- `exiftool` is already a dependency.
- It composes with the filename rename: you can label an image with `l` and rename it with `Return`, in either order.

If the user prefers (1), the change is trivial: route `l` to `_ftl::plugin::inline_rename::begin_edit` with a pre-filled draft of `"${ftl_state_current_stem}_"`. No other code changes.

### 10.2 Which EXIF/IPTC Fields

Three reasonable candidates:

| Field                       | Standard | Tool support       | Typical use                 |
|-----------------------------|----------|--------------------|-----------------------------|
| `IPTC:ObjectName`           | IPTC     | exiftool, digikam  | Short title                 |
| `EXIF:ImageDescription`     | EXIF     | exiftool, most     | Free-form description       |
| `XMP-dc:Title`              | XMP      | exiftool, Adobe    | Modern, UTF-8 friendly      |

The proposal writes to **both** `IPTC:ObjectName` and `EXIF:ImageDescription` for maximum compatibility. `XMP-dc:Title` can be added as a third write if `ftl_cfg_inline_rename_write_xmp=1` is set.

### 10.3 Reading the Existing Label

On `begin_label`, the draft is pre-filled with the current label, retrieved via:

```bash
existing="$(exiftool -s3 -IPTC:ObjectName "$path" 2>/dev/null)"
[[ -z "$existing" ]] && existing="$(exiftool -s3 -EXIF:ImageDescription "$path" 2>/dev/null)"
```

If both are empty, the draft starts empty.

---

## 11. Integration With Existing Subsystems

### 11.1 Keyboard Engine (`keyboard.sh`)

The only integration point is `ftl_kbd_submode_handler` (set by `enter`, cleared by `exit`). No changes to `keyboard.sh` itself.

The dispatch trie entry (`ftl_kbd_trie["LEADERri"]`) is registered by the binding file. The trie's existing prefix-tracking (`ftl_kbd_trie["LEADER"]++`, `ftl_kbd_trie["LEADERr"]++`) works as-is.

### 11.2 Selection (`selection.sh`)

The `SPACE`/`t`/`TAB` keys in outer mode reuse `ftl::sel::flip` directly. No changes to `selection.sh`.

### 11.3 List Rendering (`list.sh`)

Two small changes:

1. `_ftl::list::render_header` adds the inline-rename glyph (one conditional line, see §9.1).
2. (Optional, for Approach B) `ftl::list::render` checks `ftl_inline_rename_active == 2` and substitutes the draft for the cursor row's color string. Approach A avoids this change entirely.

### 11.4 State (`state.sh`)

No changes. The inline-rename state is not persisted (see §5.4).

### 11.5 Commands (`commands.sh`)

Two thin wrappers added:

```bash
ftl::cmd::cursor_up_step() {
    local i
    for (( i=0 ; i < ftl_cfg_move_step_size ; i++ )) ; do ftl::cmd::cursor_up ; done
}

ftl::cmd::cursor_down_step() {
    local i
    for (( i=0 ; i < ftl_cfg_move_step_size ; i++ )) ; do ftl::cmd::cursor_down ; done
}
```

(Or, more efficiently, a single `ftl::list::move_cursor $ftl_cfg_move_step_size && ftl::list::render`. The wrappers are clearer.)

### 11.6 Mark / History (`mark.sh`)

The `ftl_inline_rename_history` array is purely informational — it is not written to `ftl_state_global_history_file`. If we later want an "undo" for renames done in this mode, the history is already there; for now, it's just a debug aid (`FTL_DEBUG=1` could dump it on exit).

### 11.7 Preview (`preview.sh`)

When an EXIF label is committed, the preview pane (if visible) should be re-triggered to re-read EXIF. The existing `ftl::prev::dispatch` is called by `ftl::list::render`, so calling `ftl::list::render` after `commit_label` is sufficient.

### 11.8 Existing `R` Binding

Unchanged. `R` continues to call `ftl::cmd::rename_selection` → `edir`. The new mode is purely additive (`LEADER r i`). Users who prefer `edir` keep their workflow.

---

## 12. Test Plan

Tests live in `test/unit/test_inline_rename.sh` and `test/integration/test_inline_rename_integration.sh`. The unit tests follow the pattern of `test/unit/test_keyboard.sh` and `test/unit/test_missing_functionalities.sh` (source the module, set up state, call the function, assert on state).

### 12.1 Unit Tests (no tmux)

| Test name                                  | Asserts                                                                    |
|--------------------------------------------|----------------------------------------------------------------------------|
| `test_enter_sets_submode_handler`          | After `enter`, `ftl_kbd_submode_handler == ftl::plugin::inline_rename::dispatch` |
| `test_enter_sets_active_flag`              | `ftl_inline_rename_active == 1`                                            |
| `test_exit_clears_submode_handler`         | After `exit`, `ftl_kbd_submode_handler == ""`                              |
| `test_exit_clears_state`                   | All `ftl_inline_rename_*` vars are empty/zero                              |
| `test_outer_up_moves_cursor`               | Set cursor_index=5, dispatch `UP`, cursor_index=4                          |
| `test_outer_down_moves_cursor`             | Set cursor_index=5, dispatch `DOWN`, cursor_index=6                        |
| `test_outer_space_toggles_selection`       | Dispatch `SPACE`, `ftl_selection_tags[$path]` is set                       |
| `test_outer_enter_begins_edit`             | Dispatch `ENTER`, `ftl_inline_rename_active == 2`, draft == basename       |
| `test_outer_letter_begins_edit_with_letter`| Dispatch `a`, draft == "a"                                                 |
| `test_outer_escape_exits`                  | Dispatch `ESCAPE`, `ftl_inline_rename_active == 0`                         |
| `test_inner_letter_appends`                | In inner mode, dispatch `b`, draft has "b" appended                        |
| `test_inner_backspace_removes`             | In inner mode with draft="abc", dispatch `BACKSPACE`, draft="ab"           |
| `test_inner_ctl_u_clears`                  | Draft="abc", dispatch `CTL-U`, draft=""                                    |
| `test_inner_ctl_w_deletes_word`            | Draft="foo bar baz", dispatch `CTL-W`, draft="foo bar "                    |
| `test_inner_escape_aborts`                 | In inner mode, dispatch `ESCAPE`, active==1, draft empty, original intact  |
| `test_inner_return_commits`                | In inner mode with draft="newname", set up a tempdir, dispatch `RETURN`, file renamed |
| `test_inner_return_empty_draft_aborts`     | In inner mode with empty draft, dispatch `RETURN`, no mv, active==1        |
| `test_inner_return_same_name_aborts`       | Draft equals original name, dispatch `RETURN`, no mv, active==1            |
| `test_inner_return_target_exists_refuses`  | Target name exists, dispatch `RETURN`, no mv, stays in inner mode          |
| `test_inner_tab_commits_and_advances`      | In inner mode with valid draft, dispatch `TAB`, file renamed, cursor moved down, active==2 on next entry |
| `test_commit_label_writes_exif`            | Set is_label=1, draft="my label", commit, exiftool reads back "my label"   |
| `test_sequential_rename`                   | Snapshot of 3 files, base="img", after sequential: img001, img002, img003  |
| `test_sequential_preserves_extension`      | Snapshot of `foo.txt`, `bar.jpg`, base="x", after: x001.txt, x002.jpg      |
| `test_sequential_skips_existing_target`    | If x001.txt exists, that file is skipped, others renamed                   |
| `test_regexp_rename`                       | Snapshot of `a.txt`, `b.txt`, pattern `s/$/.bak/`, after: a.txt.bak, b.txt.bak |
| `test_regexp_rename_no_change_skips`       | Pattern that doesn't match, file unchanged                                |
| `test_snapshot_targets_uses_selection`     | With selection of 2, snapshot has 2 entries                               |
| `test_snapshot_targets_uses_list_when_no_sel` | With no selection and 5 list entries, snapshot has 5 entries            |
| `test_delete_one_with_confirm_y`           | Confirm prompt answered with "y", file deleted                            |
| `test_delete_one_with_confirm_n`           | Confirm prompt answered with "n", file not deleted                        |
| `test_delete_one_no_confirm`               | With `ftl_cfg_inline_rename_no_confirm_delete=1`, file deleted without prompt |
| `test_dispatch_outer_unknown_key_ignored`  | Dispatch "Z" (not in keymap), state unchanged                             |
| `test_dispatch_inner_non_printable_ignored`| In inner mode, dispatch "F1" (function key), draft unchanged              |
| `test_enter_in_virtual_list_refuses`       | With vfiles set, enter does not set submode handler                       |

### 12.2 Integration Tests (with tmux, skipped if no tmux)

| Test name                              | Asserts                                                       |
|----------------------------------------|---------------------------------------------------------------|
| `test_e2e_enter_and_exit`              | `LEADER r i` then `Escape`, listing unchanged                 |
| `test_e2e_rename_single_file`          | `LEADER r i`, `Return`, type "newname", `Return`, file renamed on disk |
| `test_e2e_rename_abort`                | `LEADER r i`, `Return`, type "newname", `Escape`, file unchanged |
| `test_e2e_sequential_rename`           | Select 3 files, `LEADER r i`, `r`, type "img", `Return`, 3 files renamed |
| `test_e2e_regexp_rename`               | Select 2 files, `LEADER r i`, `R`, type `s/\.txt$/.md/`, `Return`, 2 files renamed |
| `test_e2e_tab_flow`                    | `LEADER r i`, type "a", `TAB`, type "b", `TAB`, type "c", `Return` — 3 files renamed a, b, c |
| `test_e2e_image_label`                 | On a .jpg, `LEADER r i`, `l`, type "vacation", `Return`, exiftool reads "vacation" |
| `test_e2e_delete_one`                  | `LEADER r i`, `x`, `y`, file deleted                          |

### 12.3 Test File Skeleton

```bash
#!/bin/env bash
# test/unit/test_inline_rename.sh — tests for inline_rename module

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"
source "$FTL_CFG/etc/core/modules/tab.sh"
source "$FTL_CFG/etc/core/modules/pane.sh"
source "$FTL_CFG/etc/core/modules/filter.sh"
source "$FTL_CFG/etc/core/modules/list.sh"
source "$FTL_CFG/etc/core/modules/preview.sh"
source "$FTL_CFG/etc/core/modules/etag.sh"
source "$FTL_CFG/etc/core/modules/virtual.sh"
source "$FTL_CFG/etc/core/modules/mark.sh"
source "$FTL_CFG/etc/core/modules/time.sh"
source "$FTL_CFG/etc/core/modules/commands.sh"
source "$FTL_CFG/etc/core/modules/inline_rename.sh"
source "$FTL_CFG/etc/bindings/inline_rename"

tmux() { : ; }
ftl::cmd::prompt() { REPLY="$FTL_TEST_FAKE_REPLY" ; }

ftl::test::setup() {
    ftl_state_session_dir=$(mktemp -d)
    mkdir -p "$ftl_state_session_dir/prev"
    ftl_state_current_tab_index=0
    ftl_state_cursor_index=0
    ftl_state_current_path=
    ftl_state_current_basename=
    ftl_list_entries=()
    ftl_list_entry_count=0
    ftl_selection_tags=()
    ftl_kbd_current_key=
    ftl_kbd_submode_handler=
    ftl_cfg_move_step_size=4
    ftl_cfg_inline_rename_sequence_format='%03d'
    ftl_cfg_inline_rename_regexp_default='s/OLD/NEW/'
    ftl_cfg_inline_rename_no_confirm_delete=0
    ftl_cfg_delete_command='rm -f'
    ftl_inline_rename_active=0
    ftl_inline_rename_draft=
    FTL_TEST_FAKE_REPLY=
}

ftl::test::teardown() {
    rm -rf "$ftl_state_session_dir" 2>/dev/null
}

# Helper: simulate a keypress in the current sub-mode
press() {
    ftl_kbd_current_key="$1"
    ftl::plugin::inline_rename::dispatch
}

# Helper: set up a fake listing
setup_listing() {
    ftl_state_session_dir=$(mktemp -d)
    local f
    for f in "$@" ; do
        touch "$ftl_state_session_dir/$f"
        ftl_list_entries+=( "$ftl_state_session_dir/$f" )
    done
    ftl_list_entry_count=${#ftl_list_entries[@]}
    ftl_state_cursor_index=0
    ftl_state_current_path="${ftl_list_entries[0]}"
    ftl_state_current_basename="$1"
    ftl_state_current_dir="$ftl_state_session_dir"
    cd "$ftl_state_session_dir"
}

test_enter_sets_submode_handler() {
    ftl::plugin::inline_rename::enter
    ftl::test::assert_eq "ftl::plugin::inline_rename::dispatch" \
        "$ftl_kbd_submode_handler" "submode handler set"
}

test_inner_return_commits() {
    setup_listing "oldname.txt"
    ftl::plugin::inline_rename::enter
    press ENTER
    press n ; press e ; press w
    press RETURN
    ftl::test::assert_eq 1 "$ftl_inline_rename_active" "back to outer mode"
    [[ -e "$ftl_state_session_dir/new" ]] \
        && ftl::test::pass "file renamed" \
        || ftl::test::fail "file not renamed"
}

# ... (remaining 30+ tests) ...
```

---

## 13. Documentation Plan

### 13.1 man page (`man/ftl.md`)

A new subsection under "Modal Modes" (or a new section if no such section exists yet):

```markdown
### Inline Rename Mode

Press `LEADER r i` to enter inline rename mode. The header shows `[RENAME]`.

In this mode:

- `j`/`k` or arrow keys navigate the listing.
- `Return` enters inline edit on the current entry. Type a new name and press
  `Return` to commit, or `Escape` to abort.
- Any letter immediately starts a new-name edit with that letter as the first
  character.
- `TAB` commits the current rename and starts editing the next entry down —
  useful for renaming a sequence of files in order.
- `SPACE` or `t` toggles selection on the current entry.
- `r` runs a sequential rename across the selection (or all entries if none
  selected). You'll be prompted for a base name; entries become `base001`,
  `base002`, etc., preserving extensions.
- `R` runs a regexp rename. You'll be prompted for a `sed -E` expression;
  it is applied to each basename.
- `l` edits the EXIF/IPTC label of the current image (only for image files).
  The filename is not changed.
- `x` or `DEL` deletes the current entry (with confirmation).
- `d` deletes without confirmation if `ftl_cfg_inline_rename_no_confirm_delete=1`.
- `Escape` or `q` exits inline rename mode.

This mode is additive to the existing `R` binding (which invokes `edir` for
full `$EDITOR`-based bulk rename). Use inline rename for quick single-file
renames and small sequential/regexp batches; use `edir` for complex
multi-cursor edits.
```

### 13.2 mdBook (`docs/src/bindings/inline-rename.md`)

A longer-form version of the man page, with:

- A diagram showing the outer → inner state transition
- A table of all keys in both modes
- Screenshots (or ASCII-art mock-ups) of the cursor row during edit
- Worked examples: "rename 50 vacation photos", "fix file extensions", "label images for search"

### 13.3 `docs/src/SUMMARY.md`

Add the new page under the "Bindings" section.

### 13.4 `documentation/ftl-missing-functionality.md`

Update §1.6 (batch rename) to mark it as **implemented** by inline rename mode's `R` key, with a cross-reference to this proposal.

### 13.5 `documentation/ftl-bindings-analysis.md`

Add `LEADER r i` to the binding inventory table.

---

## 14. Rollout & Migration

### 14.1 Phased Implementation

| Phase | Scope                                                              | Tests      |
|-------|--------------------------------------------------------------------|------------|
| 1     | Module skeleton + `enter`/`exit` + outer navigation               | 8 tests    |
| 2     | Inner mode: append, backspace, commit, abort                      | 10 tests   |
| 3     | `TAB` flow (commit + advance)                                     | 2 tests    |
| 4     | Sequential rename (`r`)                                           | 4 tests    |
| 5     | Regexp rename (`R`)                                               | 3 tests    |
| 6     | Delete from within mode (`x`/`d`)                                 | 3 tests    |
| 7     | Image labeling (`l`)                                              | 2 tests    |
| 8     | Header glyph + render_draft overlay                               | manual     |
| 9     | Integration tests (tmux)                                          | 8 tests    |
| 10    | Docs: man page, mdBook, missing-func update                       | n/a        |

Each phase is independently committable. Phases 1-3 are useful on their own (single-file inline rename). Phases 4-5 are the bulk-rename replacement. Phase 7 is the image-label feature.

### 14.2 Backward Compatibility

- `R` (existing `edir` binding) is unchanged.
- No existing binding is removed or remapped.
- The new mode is opt-in: users who never press `LEADER r i` see no behavioural change.
- The two changes to `list.sh` (header glyph + optional draft overlay) are guarded by `if (( ftl_inline_rename_active ))` checks, so they are no-ops when the mode is inactive.

### 14.3 Performance

- The dispatch function is called on every keypress while the mode is active. It is a single `case` statement (no external commands), so overhead is negligible.
- `render_draft` emits one terminal line per keystroke — comparable to `incremental_search`'s `find_next` + `ftl::list::render`.
- Bulk operations (sequential, regexp) do one `mv` per file. For 1000 files, this is ~1 second on local filesystems. The header progress indicator (§9.4) keeps the user informed.

### 14.4 Rollback

If the feature needs to be reverted:

1. Remove the `source "$FTL_CFG/etc/bindings/inline_rename"` line from `ftl_setup`.
2. Remove the `source "$FTL_CFG/etc/core/modules/inline_rename.sh"` line from `ftl_setup`.
3. Remove the two `if (( ftl_inline_rename_active ))` blocks from `list.sh`.

The module file and binding file can remain on disk (they will not be sourced, so they have no effect). This makes rollback trivial and non-destructive.

---

## 15. Open Questions

These are design decisions that should be confirmed before (or during) implementation. They are not blockers for Phase 1-3.

1. **Should `LEFT`/`RIGHT` be in Phase 2 or deferred?** The user spec doesn't explicitly require cursor movement within the draft; "backspace remove letter" implies append-only editing is acceptable. Recommendation: defer to v2; initial release is append-only with `BACKSPACE`.

2. **Should `d` (no-confirm delete) be opt-in or opt-out?** The proposal defaults to opt-in (`ftl_cfg_inline_rename_no_confirm_delete=0`). Some users may expect `d` to delete immediately, matching vim's `d` binding. Recommendation: opt-in, since `ftl`'s existing `d` binding *does* prompt for confirmation.

3. **Should the image-label mode also write `XMP-dc:Title`?** Default: no (only IPTC + EXIF). `ftl_cfg_inline_rename_write_xmp=1` enables it. This is the lowest-common-denominator approach.

4. **Should the regexp rename prompt support `perl` regexes (`-P`) instead of `-E`?** `sed -E` is more portable and well-understood. `perl -pe` is more powerful but adds a dependency (already present via `exiftool`). Recommendation: stick with `sed -E`; users who need `perl` can pipe through a script.

5. **Should the sequential rename preserve leading-number sort order?** Currently `mv` operations may cause `ftl::list::change_dir` to re-sort and re-position the cursor. The proposal calls `ftl::list::change_dir` (no second arg) after the bulk op, which lands the cursor on the first entry. Some users may want the cursor to stay on the last-edited entry. Recommendation: leave as-is for v1; add `ftl_cfg_inline_rename_keep_cursor=0` later if requested.

6. **Should the mode be entered by a non-leader key (e.g. `F2`)?** The user spec says `leader r i`. The missing-functionality doc lists `F2` as an alternative binding for plain rename. Recommendation: ship `LEADER r i` only; users can rebind to `F2` in their `~/.config/ftl/ftlrc` if desired.

7. **Should there be a "preview" of the bulk-rename result before applying?** `edir` shows the diff in `$EDITOR` before applying. The current proposal applies immediately. Recommendation: add a confirmation prompt for bulk ops affecting > 10 entries: `Apply 42 renames? [y|N]`.

8. **Should `ftl_inline_rename_history` be exposed via a command (e.g. `:rename_undo`)?** Out of scope for v1. The history is collected for debugging and as a foundation for a future undo feature.

---

## Appendix A: Full Pseudocode Listing

This appendix collects the function bodies from §7 into a single reference, in the order they would appear in `inline_rename.sh`. It is pseudocode — variable initialisation, exact whitespace, and the `case` arms' order are not final. Real implementation would also include the header comment block from §6.3.

```bash
# (Header comment — see §6.3)

# === Globals ===
ftl_inline_rename_active=0
ftl_inline_rename_original_path=
ftl_inline_rename_original_name=
ftl_inline_rename_draft=
ftl_inline_rename_draft_cursor=0
ftl_inline_rename_is_label=0
ftl_inline_rename_history=()
ftl_inline_rename_bulk_targets=()
ftl_state_inline_rename_error=

# === Public API ===

ftl::plugin::inline_rename::enter() {
    # Refuse in virtual lists
    (( ${#ftl_plugin_vfiles[@]} || ${#ftl_plugin_vdirs[@]} )) && {
        echo "ftl: inline_rename: not available in virtual lists" >&2
        return
    }
    # Hand off from incremental_search if active
    if [[ "$ftl_kbd_submode_handler" == "ftl::plugin::incremental_search::incremental_find" ]] ; then
        ftl_cfg_cursor_color_current="$ftl_cfg_cursor_color_default"
        ftl_state_search_string=
    fi
    ftl_kbd_submode_handler=ftl::plugin::inline_rename::dispatch
    ftl_inline_rename_active=1
    ftl_inline_rename_original_path=
    ftl_inline_rename_original_name=
    ftl_inline_rename_draft=
    ftl_inline_rename_draft_cursor=0
    ftl_inline_rename_is_label=0
    ftl_inline_rename_history=()
    ftl_inline_rename_bulk_targets=()
    ftl::list::render
}

ftl::plugin::inline_rename::exit() {
    ftl_inline_rename_active=0
    ftl_inline_rename_original_path=
    ftl_inline_rename_original_name=
    ftl_inline_rename_draft=
    ftl_inline_rename_draft_cursor=0
    ftl_inline_rename_is_label=0
    ftl_inline_rename_bulk_targets=()
    ftl_state_inline_rename_error=
    ftl_kbd_submode_handler=
    ftl::list::render
}

ftl::plugin::inline_rename::dispatch() {
    local key="$ftl_kbd_current_key"
    [[ "$key" == ERROR_* ]] && return
    if (( ftl_inline_rename_active == 1 )) ; then
        _ftl::plugin::inline_rename::dispatch_outer "$key"
    elif (( ftl_inline_rename_active == 2 )) ; then
        _ftl::plugin::inline_rename::dispatch_inner "$key"
    fi
}

# === Private: Outer Mode ===

_ftl::plugin::inline_rename::dispatch_outer() {
    local key="$1"
    case "$key" in
        UP|k)         ftl::cmd::cursor_up ;;
        DOWN|j)       ftl::cmd::cursor_down ;;
        PGUP|K)       ftl::list::move_cursor -$ftl_cfg_move_step_size ; ftl::list::render ;;
        PGDN|J)       ftl::list::move_cursor  $ftl_cfg_move_step_size ; ftl::list::render ;;
        HOME|g)       ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]=0 ; ftl::list::render ;;
        END|G)        ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]=$(( ftl_list_entry_count - 1 )) ; ftl::list::render ;;
        SPACE|t)      ftl::sel::flip "$ftl_state_current_path" ; ftl::list::render ;;
        TAB)          ftl::sel::flip "$ftl_state_current_path" ; ftl::cmd::cursor_down ;;
        DEL|x)        _ftl::plugin::inline_rename::delete_one 1 ;;
        d)            _ftl::plugin::inline_rename::delete_one "$(( 1 - ftl_cfg_inline_rename_no_confirm_delete ))" ;;
        ENTER|RETURN) _ftl::plugin::inline_rename::begin_edit "" ;;
        r)            _ftl::plugin::inline_rename::sequential ;;
        R)            _ftl::plugin::inline_rename::regexp ;;
        l)            _ftl::plugin::inline_rename::begin_label ;;
        ESCAPE|q)     ftl::plugin::inline_rename::exit ;;
        [a-zA-Z0-9_\-.]) _ftl::plugin::inline_rename::begin_edit "$key" ;;
        *)            : ;;
    esac
}

# === Private: Inner Mode ===

_ftl::plugin::inline_rename::begin_edit() {
    (( ftl_list_entry_count )) || return 0
    ftl_inline_rename_original_path="$ftl_state_current_path"
    ftl_inline_rename_original_name="$ftl_state_current_basename"
    ftl_inline_rename_draft="$1"
    ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
    ftl_inline_rename_is_label=0
    ftl_inline_rename_active=2
    _ftl::plugin::inline_rename::render_draft
}

_ftl::plugin::inline_rename::begin_label() {
    command -v exiftool >/dev/null 2>&1 || {
        echo "ftl: inline_rename: exiftool not installed" >&2
        return
    }
    local ext_lc="${ftl_state_current_extension,,}"
    local is_img=0
    local ie
    for ie in "${ftl_cfg_image_extensions[@]}" ; do
        [[ "$ext_lc" == "$ie" ]] && { is_img=1 ; break ; }
    done
    (( is_img )) || return 0

    ftl_inline_rename_original_path="$ftl_state_current_path"
    ftl_inline_rename_original_name="$ftl_state_current_basename"
    local existing
    existing="$(exiftool -s3 -IPTC:ObjectName "$ftl_state_current_path" 2>/dev/null)"
    [[ -z "$existing" ]] && existing="$(exiftool -s3 -EXIF:ImageDescription "$ftl_state_current_path" 2>/dev/null)"
    ftl_inline_rename_draft="$existing"
    ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
    ftl_inline_rename_is_label=1
    ftl_inline_rename_active=2
    _ftl::plugin::inline_rename::render_draft
}

_ftl::plugin::inline_rename::dispatch_inner() {
    local key="$1"
    case "$key" in
        BACKSPACE)
            (( ${#ftl_inline_rename_draft} > 0 )) && {
                ftl_inline_rename_draft="${ftl_inline_rename_draft:0:${#ftl_inline_rename_draft}-1}"
                (( ftl_inline_rename_draft_cursor > 0 )) && (( ftl_inline_rename_draft_cursor-- ))
            }
            ;;
        CTL-W)
            ftl_inline_rename_draft="${ftl_inline_rename_draft% *}"
            ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
            ;;
        CTL-U)
            ftl_inline_rename_draft=
            ftl_inline_rename_draft_cursor=0
            ;;
        CTL-A|HOME)
            ftl_inline_rename_draft_cursor=0
            ;;
        CTL-E|END)
            ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
            ;;
        ENTER|RETURN)
            _ftl::plugin::inline_rename::commit
            return
            ;;
        ESCAPE)
            _ftl::plugin::inline_rename::abort
            return
            ;;
        TAB)
            _ftl::plugin::inline_rename::commit
            (( ftl_state_cursor_index < ftl_list_entry_count - 1 )) && {
                ftl::cmd::cursor_down
                _ftl::plugin::inline_rename::begin_edit ""
            }
            return
            ;;
        ERROR_*) return ;;
        *)
            if [[ "$key" =~ ^[ -~]$ ]] ; then
                local left="${ftl_inline_rename_draft:0:ftl_inline_rename_draft_cursor}"
                local right="${ftl_inline_rename_draft:ftl_inline_rename_draft_cursor}"
                ftl_inline_rename_draft="${left}${key}${right}"
                (( ftl_inline_rename_draft_cursor++ ))
            fi
            ;;
    esac
    _ftl::plugin::inline_rename::render_draft
}

_ftl::plugin::inline_rename::commit() {
    [[ -n "$ftl_inline_rename_draft" ]] || { _ftl::plugin::inline_rename::abort ; return ; }

    if (( ftl_inline_rename_is_label )) ; then
        _ftl::plugin::inline_rename::commit_label
        return
    fi

    local dir="${ftl_inline_rename_original_path%/*}"
    local target="$dir/$ftl_inline_rename_draft"

    [[ "$target" == "$ftl_inline_rename_original_path" ]] && {
        _ftl::plugin::inline_rename::abort
        return
    }

    if [[ -e "$target" ]] ; then
        ftl_state_inline_rename_error="target exists: $ftl_inline_rename_draft"
        _ftl::plugin::inline_rename::render_draft
        ftl_state_inline_rename_error=
        return
    fi

    mv -- "$ftl_inline_rename_original_path" "$target"
    ftl_inline_rename_history+=( "${ftl_inline_rename_original_path}"$'\t'"$target" )
    ftl_inline_rename_active=1
    ftl_list_mime_cache=()
    ftl::list::change_dir '' "$ftl_inline_rename_draft"
}

_ftl::plugin::inline_rename::commit_label() {
    local path="$ftl_inline_rename_original_path"
    exiftool -overwrite_original \
        -IPTC:ObjectName="$ftl_inline_rename_draft" \
        -EXIF:ImageDescription="$ftl_inline_rename_draft" \
        "$path" >/dev/null 2>&1
    ftl_inline_rename_history+=( "$path(exif)$ftl_inline_rename_draft" )
    ftl_inline_rename_active=1
    ftl::list::render
}

_ftl::plugin::inline_rename::abort() {
    ftl_inline_rename_original_path=
    ftl_inline_rename_original_name=
    ftl_inline_rename_draft=
    ftl_inline_rename_draft_cursor=0
    ftl_inline_rename_is_label=0
    ftl_inline_rename_active=1
    ftl::list::render
}

# === Private: Bulk Ops ===

_ftl::plugin::inline_rename::snapshot_targets() {
    ftl_inline_rename_bulk_targets=()
    if (( ${#ftl_selection_tags[@]} )) ; then
        ftl_inline_rename_bulk_targets=( "${!ftl_selection_tags[@]}" )
    else
        ftl_inline_rename_bulk_targets=( "${ftl_list_entries[@]}" )
    fi
}

_ftl::plugin::inline_rename::sequential() {
    ftl::cmd::prompt 'sequential base name: '
    local base="$REPLY"
    [[ -n "$base" ]] || { ftl::list::render ; return ; }

    _ftl::plugin::inline_rename::snapshot_targets
    local i=1 target new_path seq
    for target in "${ftl_inline_rename_bulk_targets[@]}" ; do
        local dir="${target%/*}" name="${target##*/}" ext=
        [[ "$name" == *.* ]] && ext=".${name##*.}"
        printf -v seq "$ftl_cfg_inline_rename_sequence_format" "$i"
        new_path="$dir/$base$seq$ext"
        if [[ -e "$new_path" && "$new_path" != "$target" ]] ; then
            echo "ftl: inline_rename: skip (target exists): $new_path" >&2
            ((i++)) ; continue
        fi
        [[ "$new_path" != "$target" ]] && mv -- "$target" "$new_path"
        ftl_inline_rename_history+=( "$target"$'\t'"$new_path" )
        ((i++))
    done
    ftl_list_mime_cache=()
    ftl::list::change_dir
}

_ftl::plugin::inline_rename::regexp() {
    ftl::cmd::prompt 'sed -E pattern: ' -i "$ftl_cfg_inline_rename_regexp_default"
    local pat="$REPLY"
    [[ -n "$pat" && "$pat" != "$ftl_cfg_inline_rename_regexp_default" ]] \
        || { ftl::list::render ; return ; }

    _ftl::plugin::inline_rename::snapshot_targets
    local target new_name new_path
    for target in "${ftl_inline_rename_bulk_targets[@]}" ; do
        local dir="${target%/*}" name="${target##*/}"
        new_name="$(printf '%s' "$name" | sed -E "$pat")"
        [[ "$new_name" == "$name" || -z "$new_name" ]] && continue
        new_path="$dir/$new_name"
        if [[ -e "$new_path" ]] ; then
            echo "ftl: inline_rename: skip (target exists): $new_path" >&2
            continue
        fi
        mv -- "$target" "$new_path"
        ftl_inline_rename_history+=( "$target"$'\t'"$new_path" )
    done
    ftl_list_mime_cache=()
    ftl::list::change_dir
}

# === Private: Delete ===

_ftl::plugin::inline_rename::delete_one() {
    local confirm="$1"
    local target="$ftl_state_current_path"
    [[ -e "$target" ]] || return 0

    if (( confirm )) ; then
        ftl::cmd::prompt "delete $ftl_state_current_basename? [y|N]" -sn1
        [[ "$REPLY" != y ]] && { ftl::list::render ; return ; }
    fi

    $ftl_cfg_delete_command -- "$target"
    ftl_list_mime_cache=()
    ftl::list::change_dir
}

# === Private: Rendering ===

_ftl::plugin::inline_rename::render_draft() {
    local row=$(( ftl_state_cursor_index - ftl_list_window_top + 2 ))
    local prefix=" "
    local draft_render="${ftl_inline_rename_draft}"

    local left="${draft_render:0:ftl_inline_rename_draft_cursor}"
    local char_at="${draft_render:ftl_inline_rename_draft_cursor:1}"
    local right="${draft_render:ftl_inline_rename_draft_cursor+1}"
    [[ -z "$char_at" ]] && char_at=" "
    local rendered="${left}\e[7m${char_at}\e[0m${right}"

    [[ -n "${ftl_state_inline_rename_error:-}" ]] \
        && rendered+="  \e[31m[${ftl_state_inline_rename_error}]\e[0m"

    echo -ne "\e[${row};0H\e[K\e[33m[RENAME] \e[0m${prefix}${rendered}"
}

# === Binding ===
# (This line lives in etc/bindings/inline_rename, not in the module file)
# ftl::kbd::bind	leader	rename	"LEADER r i"	ftl::plugin::inline_rename::enter	"inline rename mode"

# vim: set filetype=bash :
```

---

## Appendix B: Pre-existing Bugs This Work Should Avoid

While reading the codebase to write this proposal, two latent issues were observed. The new code must not repeat them.

### B.1 `ftl::cmd::prompt` vs `$REPLY` vs `$ftl_kbd_current_key`

`ftl::cmd::prompt` (in `commands.sh:2679-2688`) is:

```bash
ftl::cmd::prompt() {
    exec 2>&9
    stty echo
    echo -ne '\e[H\e[K\e[33m\e[?25h'
    read -e -rp "$@"
    echo -ne '\e[m'
    stty -echo
    tput civis
    exec 2>"$ftl_state_session_dir/log"
}
```

`read -e -rp "$@"` reads into `$REPLY` by default (no variable name is given). However, several call sites then read `$ftl_kbd_current_key` instead — e.g. `ftl::cmd::create_file` (line 792-797):

```bash
ftl::cmd::create_file() {
    ftl::cmd::prompt 'touch: '
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        touch "$PWD/$ftl_kbd_current_key"
    fi
    ftl::list::change_dir "$PWD" "$ftl_kbd_current_key"
}
```

This appears to be a bug: `$ftl_kbd_current_key` is the *last key pressed before the prompt*, not the prompt's result. The `touch` would receive whatever key triggered the `create_file` binding (e.g. the last letter of the key sequence), not what the user typed at the prompt.

**The new inline rename code must read `$REPLY` after `ftl::cmd::prompt`.** This is what the `delete_one`, `sequential`, and `regexp` functions in §7 do.

(A separate cleanup PR could fix the existing call sites — but that is out of scope for this proposal.)

### B.2 Subshell Array Mutation

The pre-existing `ftl::filt::init` bug (documented in the conversation summary) was: subshells lose array mutations. The new inline rename code calls `ftl::cmd::prompt`, which runs `read` in the current shell (not a subshell) — so `$REPLY` is visible afterwards. Good.

However, the `ftl::cmd::prompt_with_history` function (line 2671-2677) uses `echo $(rlwrap ...)`, which *does* run in a subshell. The new code does not use `prompt_with_history`, so this is not a concern — but the pattern is worth noting for future maintainers.

### B.3 Keyboard Trie Numeric Prefix Collision

`ftl::kbd::bind` (in `keyboard.sh:103-106`) does:

```bash
local __current="${ftl_kbd_trie[$shortcut]:-}"
if [[ "$__current" =~ ^[0-9]+$ ]] ; then
    ftl_kbd_trie[$shortcut]=$(( __current + 1 ))
fi
```

This tracks prefix usage *as a count*. The intent is that `LEADER` and `LEADERr` get numeric values (1, 2, ...) indicating "this is a prefix", while `LEADERri` gets the command string. The check `[[ "$__current" =~ ^[0-9]+$ ]]` ensures we don't overwrite a real command with a count.

The new binding `LEADER r i` registers `LEADER`, `LEADERr`, and `LEADERri` in the trie. The first two get counts (or have their counts incremented); the third gets the function name. This is exactly how every other multi-key binding works, and the new code does not need to do anything special — `ftl::kbd::bind` handles it.

---

*End of proposal. Implementation can proceed phase-by-phase per §14.1 once the open questions in §15 are resolved.*
