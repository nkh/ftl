# 07 — Modification Guide

> **Audience:** Maintainers ready to make changes.
> **Goal:** Provide step-by-step recipes for common modifications.
> **Time:** 90 minutes.

This document provides recipes for the most common modifications. Each
recipe includes: the files to edit, the pattern to follow, a reference
implementation, and the tests to write.

---

## Table of Contents

1. [Add a Key Binding](#1-add-a-key-binding)
2. [Add a `:` Command](#2-add-a--command)
3. [Add a Filter Plugin](#3-add-a-filter-plugin)
4. [Add an Etag Plugin](#4-add-an-etag-plugin)
5. [Add a Viewer](#5-add-a-viewer)
6. [Add a Generator](#6-add-a-generator)
7. [Modify the Listing Pipeline](#7-modify-the-listing-pipeline)
8. [Modify the Keyboard Engine](#8-modify-the-keyboard-engine)
9. [Modify the Preview Dispatcher](#9-modify-the-preview-dispatcher)
10. [Add a Sub-mode Handler](#10-add-a-sub-mode-handler)
11. [Add a New Module](#11-add-a-new-module)
12. [Modify the Configuration](#12-modify-the-configuration)
13. [Modify the Man Page](#13-modify-the-man-page)
14. [Add a Test](#14-add-a-test)

---

## 1. Add a Key Binding

**Scenario:** You want to bind `LEADER x y` to a function that
displays the current file's MIME type.

### Files to edit

- `config/ftl/etc/bindings/my_binding` (new file) — or
  `config/ftl/bindings/my_binding` for a user-level binding
- `test/unit/test_my_binding.sh` (new file) — tests

### Pattern

A binding plugin is a Bash script that:

1. Defines one or more helper functions
2. Calls `ftl::kbd::bind` to register the binding

### Reference implementation

```bash
# config/ftl/etc/bindings/show_mime

ftl::plugin::show_mime::run() {
    ftl::list::get_mime_type
    ftl::log::info "MIME type: $ftl_state_current_mime_type"
    ftl::list::render
}

ftl::kbd::bind	ftl	entry	"LEADER x y"	ftl::plugin::show_mime::run	"show current file's MIME type"

# vim: set filetype=bash :
```

### Steps

1. Create the file `config/ftl/etc/bindings/show_mime`.
2. Add the function and the `ftl::kbd::bind` call.
3. Test live: from the `:` prompt, run
   `:source ~/.config/ftl/etc/bindings/show_mime`.
4. Press `LEADER x y` to verify.
5. Write a test (see recipe 14).
6. Update `docs/src/key-bindings.md` and the man page.
7. Commit.

### Key points

- Use the `ftl::plugin::<name>::<function>` namespace.
- Use **tabs** to separate `ftl::kbd::bind` fields.
- Call `ftl::list::render` at the end to refresh the display (unless
  the binding opens a full-screen view).
- For bindings that need user input, call `ftl::cmd::prompt` and read
  `$REPLY` (not `$ftl_kbd_current_key` — that is the key that
  triggered the binding, not the prompt result).

---

## 2. Add a `:` Command

**Scenario:** You want `:count` to display the number of entries in
the current directory.

### Files to edit

- `config/ftl/etc/commands/count` (new file)
- `test/unit/test_commands.sh` (add a test)

### Pattern

A command is either:

- **Sourced** (not executable) — runs in ftl's shell with direct
  access to all globals.
- **Executable** — runs as a subprocess, sources
  `$ftl_state_info_file_path` for state.

### Reference implementation (sourced)

```bash
# config/ftl/etc/commands/count
# Count entries in the current directory

{
    echo "Entries: $ftl_list_entry_count"
    echo "Selected: ${#ftl_selection_tags[@]}"
    echo "Current: $ftl_state_current_basename"
} | ftl::pane::split_for_preview "cat ; read -sn 100"

# vim: set filetype=bash :
```

### Reference implementation (executable)

```bash
#!/bin/bash
# config/ftl/etc/commands/count
# Executable version — must source the info file

source "$ftl_state_info_file_path"

echo "ftl PID: $FTL_PID"
echo "CWD: $FTL_CWD"
echo "Current: $ftl_state_current_path"
echo "Selection:"
printf '  %s\n' "${ftl_selection_current[@]}"

read -sn 1
```

Mark executable: `chmod +x config/ftl/etc/commands/count`.

### Steps

1. Create the file.
2. (If executable) `chmod +x` it.
3. Test from the `:` prompt: `:count`.
4. Write a test.
5. Update `docs/src/external-commands.md`.
6. Commit.

---

## 3. Add a Filter Plugin

**Scenario:** You want a filter that hides files larger than 10 MB.

### Files to edit

- `config/ftl/filters/by_max_size` (new file)
- `test/unit/test_filter_extra.sh` (add tests)

### Pattern

A filter plugin overrides `ftl::filter::apply_external` with a
function that reads from stdin and writes to stdout.

### Reference implementation

```bash
# config/ftl/filters/by_max_size

declare -g ftl_plugin_by_max_size_limit=$(( 10 * 1024 * 1024 ))

ftl::plugin::by_max_size::filter() {
    local p size
    while IFS= read -r p ; do
        if [[ -f "$p" ]] ; then
            size=$(stat -c %s "$p" 2>/dev/null || echo 0)
            (( size <= ftl_plugin_by_max_size_limit )) && echo "$p"
        else
            echo "$p"  # always pass directories
        fi
    done
}

ftl::filter::apply_external() {
    ftl::plugin::by_max_size::filter
}

ftl::plugin::by_max_size::reset() {
    :
}

# vim: set filetype=bash :
```

### Steps

1. Create the file in `config/ftl/filters/by_max_size`.
2. Activate with `fe` (cycle) or `:filter by_max_size` (if such a
   command exists; otherwise, source it: `:source $FTL_CFG/filters/by_max_size`).
3. Write tests (test the filter function directly with stdin/stdout).
4. Update `docs/src/writing-filters.md`.
5. Commit.

### Key points

- **Streaming:** Read from stdin in a loop; do not buffer the entire
  input into an array.
- **State:** Use `declare -g` for module-level globals.
- **Reset:** Define a `reset` function for cleanup when the filter is
  deactivated.
- **Directories:** Always pass directories through; filtering them
  breaks navigation.

---

## 4. Add an Etag Plugin

**Scenario:** You want an etag that shows the file's owner.

### Files to edit

- `config/ftl/etags/owner` (new file)
- `test/unit/test_etag.sh` (add tests)

### Pattern

An etag plugin defines `ftl::etag::scan_directory` (populates arrays)
and `ftl::etag::get_entry_tag` (returns the tag for one entry).

### Reference implementation

```bash
# config/ftl/etags/owner

declare -g -A owner_tags=()

ftl::etag::scan_directory() {
    declare -g -A owner_tags=()
    local f owner
    while IFS= read -r f ; do
        owner=$(stat -c %U "$f" 2>/dev/null || echo "?")
        owner="${owner:0:8}"  # truncate to 8 chars
        owner_tags["$f"]="$owner"
    done < <(find "$PWD/" -maxdepth 1 2>/dev/null)
}

ftl::etag::get_entry_tag() {
    local -n r2=$2 r3=$3
    r2="${owner_tags[$1]:-?}"
    r3=8  # width for column alignment
}

# vim: set filetype=bash :
```

### Steps

1. Create the file.
2. Activate with `zT` (cycle) or `:etags owner`.
3. Write tests.
4. Update `docs/src/writing-etags.md`.
5. Commit.

### Key points

- **Performance:** `scan_directory` runs on every directory change.
  Avoid per-file `stat` where possible. The `git` etag runs a single
  `git status --porcelain` and parses it.
- **Width:** The `r3` output (width) is used for column alignment. All
  entries should use the same width.
- **Color:** Tag strings can include ANSI escapes for color.

---

## 5. Add a Viewer

**Scenario:** You want to preview CSV files with column alignment.

### Files to edit

- `config/ftl/viewers/my_csv_viewer` (new file) — or modify
  `config/ftl/etc/viewers/core` directly

### Pattern

A viewer function takes no arguments and renders
`$ftl_state_current_path` to the preview pane. It typically calls
`ftl::prev::clear` and `ftl::pane::split_for_preview`.

### Reference implementation (new file)

```bash
# config/ftl/viewers/my_csv_viewer
# Sourced after viewers/core; overrides the dispatcher

ftl::plugin::core::pcsv() {
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "column -t -s, '${ftl_state_current_path@Q}' | $ftl_cfg_markdown_pager ; read -sn 100"
}

# Wrap the original pviewers to add CSV support
ftl::plugin::core::pviewers_orig() { ftl::plugin::core::pviewers ; }
ftl::plugin::core::pviewers() {
    [[ $ftl_state_current_extension == csv ]] && { ftl::plugin::core::pcsv ; return ; }
    ftl::plugin::core::pviewers_orig
}
```

### Reference implementation (modifying `viewers/core`)

Add a case to the `pviewers` function:

```bash
ftl::plugin::core::pviewers() {
    # ... existing cases ...
    [[ $ftl_state_current_extension == csv ]] && { ftl::plugin::core::pcsv ; return ; }
    # ... rest of existing cases ...
}

ftl::plugin::core::pcsv() {
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "column -t -s, '${ftl_state_current_path@Q}' | $ftl_cfg_markdown_pager ; read -sn 100"
}
```

### Steps

1. Create the viewer function.
2. Register it in the dispatcher (either by modifying `core` or by
   wrapping `pviewers`).
3. Test by moving the cursor over a `.csv` file.
4. Update `docs/src/writing-viewers.md`.
5. Commit.

### Key points

- **`ftl::prev::clear`:** Always clear the preview pane before
  rendering.
- **Quoting:** Use `${ftl_state_current_path@Q}` for safe shell
  quoting.
- **Read pause:** End interactive viewers with `read -sn 100` to
  pause before returning control.
- **Backend config:** Use `ftl_cfg_*` variables (e.g.
  `ftl_cfg_markdown_pager`) instead of hardcoding program names.

---

## 6. Add a Generator

**Scenario:** You want to generate thumbnails for `.webp` images.

### Files to edit

- `config/ftl/generators/webp` (new file, executable)

### Pattern

A generator is an executable script receiving `$1` (source file) and
`$2` (output directory). It writes at least one thumbnail to `$2`.

### Reference implementation

```bash
#!/bin/bash
# config/ftl/generators/webp
# Generate a thumbnail for a WebP image

src="$1"
outdir="$2"

mkdir -p "$outdir"
exec 2>>"$outdir/generators_log"

md5=$(md5sum <<<"$src" | cut -d' ' -f1)
basename="${src##*/}"
thumb="$outdir/${md5}_${basename%.*}.png"

# Convert WebP to PNG at a max width of 1000px
convert "$src" -resize 1000x "$thumb" 2>/dev/null

# vim: set filetype=bash :
```

### Steps

1. Create the file.
2. `chmod +x config/ftl/generators/webp`.
3. Test by previewing a `.webp` file.
4. Update `docs/src/extra-features.md` (the generators table).
5. Commit.

### Key points

- **Caching:** The `generators/generator` driver caches by md5.
  Generators must produce deterministic output.
- **Filename:** Use a stable filename (incorporating md5) to avoid
  collisions.
- **Logging:** Redirect stderr to `$outdir/generators_log`.
- **Graceful failure:** If the backend tool is missing, produce no
  output (do not crash).

---

## 7. Modify the Listing Pipeline

**Scenario:** You want to add a new sort type (sort by owner).

### Files to edit

- `config/ftl/etc/core/modules/filter.sh` — add the sort type
- `config/ftl/etc/core/modules/list.sh` — handle the sort in
  `_ftl::list::apply_filters_and_format` (if needed)
- `config/ftl/etc/ftlrc` — bind a key to cycle to the new sort

### Pattern

1. Add a new sort type constant.
2. Handle it in `ftl::filt::sort_entries`.
3. Add a glyph in `ftl::filt::get_sort_glyph`.
4. Bind a key to `ftl::cmd::sort_cycle` (or add a dedicated command).

### Reference implementation

In `filter.sh`:

```bash
ftl::filt::sort_entries() {
    case "$ftl_list_resolved_sort_type" in
        0) sort -df ... ;;  # alphanumeric
        1) sort -n ... ;;   # size
        2) sort -t $'\t' -k1 ... ;;  # date
        3) sort -t $'\t' -k4 ... ;;  # owner (new)
    esac
}

ftl::filt::get_sort_glyph() {
    case "$1" in
        0) echo "α" ;;
        1) echo "σ" ;;
        2) echo "δ" ;;
        3) echo "υ" ;;  # owner (new)
    esac
}
```

### Steps

1. Modify `filter.sh`.
2. Update `ftl::cmd::sort_cycle` in `commands.sh` to cycle through the
   new type.
3. Test sorting with a directory containing files owned by different
   users.
4. Update the man page and `docs/src/user-guide/navigation.md`.
5. Commit.

### Key points

- The sort runs in the streaming pipeline. Use `sort` with
  appropriate keys; do not sort in Bash (too slow for large
  directories).
- The sort type is stored per-tab in `ftl_tab_sort_type[$tab]`.
- The glyph is displayed in the header.

---

## 8. Modify the Keyboard Engine

**Scenario:** You want to add a new modifier key (e.g. `SUPER-x`).

### Files to edit

- `config/ftl/etc/core/modules/keyboard.sh` — add the key to
  `normalize_key`

### Pattern

Add a case to `ftl::kbd::normalize_key` mapping the raw escape
sequence to a symbolic name.

### Reference implementation

```bash
ftl::kbd::normalize_key() {
    case "$1" in
        # ... existing cases ...
        $'\e[27;6;120~') echo "CTL-SHIFT-x" ;;  # depending on terminal
        # ... etc ...
    esac
}
```

### Steps

1. Determine the raw escape sequence your terminal emits. Use
   `cat -v` and press the key:
   ```bash
   cat -v
   # press the key
   # observe the output (e.g. ^[[27;6;120~)
   ```
2. Add a case to `normalize_key`.
3. Test: bind a function to the new key and verify it fires.
4. Update `test/unit/test_keyboard.sh` (add a `normalize_key` test).
5. Commit.

### Key points

- Different terminals emit different sequences for the same key.
  Add all known variants.
- The `read -rsn 4 -t 0.001` in `get_key` captures up to 4 bytes
  after the first. If the sequence is longer, increase the limit.
- Test with `ftl::kbd::normalize_key` directly:
  ```bash
  ftl::kbd::normalize_key $'\e[27;6;120~'  # should output CTL-SHIFT-x
  ```

---

## 9. Modify the Preview Dispatcher

**Scenario:** You want to add preview support for a new file type
(e.g. `.csv`).

### Files to edit

- `config/ftl/etc/viewers/core` — add a case to `pviewers`

### Pattern

Add a case to the `pviewers` function (or `ext_viewers` for
full-terminal preview).

### Reference implementation

```bash
ftl::plugin::core::pviewers() {
    # ... existing cases ...
    [[ $ftl_state_current_extension == csv ]] && { ftl::plugin::core::pcsv ; return ; }
    # ... rest ...
}

ftl::plugin::core::pcsv() {
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "column -t -s, '${ftl_state_current_path@Q}' | $ftl_cfg_markdown_pager ; read -sn 100"
}
```

### Steps

1. Add the case to `pviewers` (place it before the generic
   `ptext` fallback).
2. Define the viewer function (`pcsv`).
3. Test by moving the cursor over a `.csv` file.
4. Update `docs/src/extra-features.md` (the viewers table).
5. Commit.

---

## 10. Add a Sub-mode Handler

**Scenario:** You want a modal workflow (like incremental search or
inline rename) that intercepts all keys until exit.

### Files to edit

- `config/ftl/etc/core/modules/my_mode.sh` (new module) — or a binding
  plugin
- `config/ftl/etc/core/ftl_setup` — source the new module
- `config/ftl/etc/bindings/my_mode` (new file) — bind the entry key

### Pattern

1. Define an `enter` function that sets `ftl_kbd_submode_handler`.
2. Define a `dispatch` function that reads `ftl_kbd_current_key` and
   branches.
3. Define an `exit` function that clears `ftl_kbd_submode_handler`.

### Reference implementation

```bash
# config/ftl/etc/core/modules/my_mode.sh

ftl_my_mode_active=0

ftl::plugin::my_mode::enter() {
    ftl_kbd_submode_handler=ftl::plugin::my_mode::dispatch
    ftl_my_mode_active=1
    ftl::list::render
}

ftl::plugin::my_mode::exit() {
    ftl_kbd_submode_handler=
    ftl_my_mode_active=0
    ftl::list::render
}

ftl::plugin::my_mode::dispatch() {
    local key="$ftl_kbd_current_key"
    case "$key" in
        ESCAPE|q) ftl::plugin::my_mode::exit ;;
        j)        ftl::cmd::cursor_down ;;
        k)        ftl::cmd::cursor_up ;;
        *)        : ;;  # ignore unknown keys
    esac
}

# vim: set filetype=bash :
```

```bash
# config/ftl/etc/bindings/my_mode

ftl::kbd::bind	ftl	entry	"LEADER m m"	ftl::plugin::my_mode::enter	"enter my mode"
```

### Steps

1. Create the module file.
2. Add a `source` line to `ftl_setup` (after `inline_rename.sh`).
3. Create the binding file.
4. Test: press `LEADER m m`, then `j`/`k`/`Escape`.
5. Write tests (see `test/unit/test_inline_rename.sh` for the pattern).
6. Update the man page and docs.
7. Commit.

### Key points

- `ftl_kbd_submode_handler` is checked by `ftl::kbd::dispatch` before
  the trie. When set, all keys go to the handler.
- The handler reads `ftl_kbd_current_key` (already normalized).
- Always provide an exit (Escape or `q`) and clear the handler on
  exit.
- See `inline_rename.sh` for a complete two-level modal example.

---

## 11. Add a New Module

**Scenario:** You want to add a new core module for a subsystem that
doesn't fit in any existing module.

### Files to edit

- `config/ftl/etc/core/modules/my_subsystem.sh` (new file)
- `config/ftl/etc/core/ftl_setup` — add the `source` line in
  dependency order
- `test/unit/test_my_subsystem.sh` (new file)

### Pattern

1. Create the module file with a header comment block (purpose,
   public API, private helpers, globals).
2. Define the globals (with `declare -g` for module-level).
3. Define the public functions (with `ftl::my_subsystem::*` namespace).
4. Define private helpers (with `_ftl::my_subsystem::*` namespace).
5. Source the module in `ftl_setup` in the correct dependency order.
6. Write tests.

### Reference implementation

```bash
# config/ftl/etc/core/modules/my_subsystem.sh
#
# my_subsystem.sh — <purpose>
#
# Public functions:
#   ftl::my_subsystem::do_thing   — <description>
#
# Private functions:
#   _ftl::my_subsystem::helper    — <description>
#
# Globals:
#   ftl_my_subsystem_state        — <description>

declare -g ftl_my_subsystem_state=

ftl::my_subsystem::do_thing() {
    _ftl::my_subsystem::helper "$1"
    ftl_my_subsystem_state="done"
    ftl::log::info "did the thing"
}

_ftl::my_subsystem::helper() {
    # ...
}

# vim: set filetype=bash :
```

### Steps

1. Create the module file.
2. Add the `source` line to `ftl_setup` in the right position
   (after its dependencies, before modules that depend on it).
3. Write tests.
4. Update `documentation/maintenance/03-modules.md` and
   `04-api-reference.md`.
5. Commit.

### Key points

- **Dependency order:** The module must be sourced after all its
  dependencies. If it calls `ftl::util::*` at source time (outside
  function bodies), `util.sh` must be sourced first.
- **Namespace:** Use `ftl::<module>::*` for functions and
  `ftl_<module>_*` for variables.
- **Header comment:** Maintain the header block listing public API,
  private helpers, and globals.

---

## 12. Modify the Configuration

**Scenario:** You want to add a new `ftl_cfg_*` variable.

### Files to edit

- `config/ftl/etc/ftlrc` — add the variable with a default value
- `documentation/ftl-ftlrc-reference.md` — document it
- `config/ftl/man/ftl.md` — add it to the Configuration section (if
  user-facing)

### Pattern

Add the variable to `ftlrc` in the appropriate section.

### Reference implementation

```bash
# In config/ftl/etc/ftlrc, in the "Behavior options" section:

# Whether to show file owner in the listing (0=no, 1=yes)
ftl_cfg_show_owner=0
```

### Steps

1. Add the variable to `ftlrc` with a sensible default.
2. Use it in the relevant module (e.g. check `$ftl_cfg_show_owner` in
   `_ftl::list::render_header`).
3. Document it in `ftl-ftlrc-reference.md`.
4. Add it to the man page if user-facing.
5. Commit.

---

## 13. Modify the Man Page

**Scenario:** You added a new binding and want to document it in the
man page.

### Files to edit

- `config/ftl/man/ftl.md`

### Pattern

Add a row to the appropriate table, and (if needed) a subsection with
details.

### Reference implementation

```markdown
## File Operations

| Key | Action |
|-----|--------|
| ... | ... |
| **LEADER x y** | Show current file's MIME type |
| ... | ... |
```

### Steps

1. Find the appropriate table in the man page.
2. Add the row.
3. (If needed) Add a subsection with details.
4. Test: `pandoc -f markdown -t man config/ftl/man/ftl.md | man -l -`
5. Commit.

### Key points

- Use **spaces** (not tabs) in the man page.
- Use `**key**` for key names.
- Use backticks for code/config variables: `` `ftl_cfg_*` ``.

---

## 14. Add a Test

**Scenario:** You added a feature and want to test it.

### Files to edit

- `test/unit/test_my_feature.sh` (new file) — or add to an existing
  test file

### Pattern

Follow the test file structure in
[05-testing.md, §3](./05-testing.md#3-test-file-structure).

### Reference implementation

```bash
#!/bin/env bash
# test/unit/test_my_feature.sh — tests for my_feature

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"
source "$FTL_CFG/etc/core/modules/list.sh"
source "$FTL_CFG/etc/core/modules/commands.sh"
source "$FTL_CFG/etc/core/modules/my_module.sh"

# Stubs
ftl::list::render() { : ; }
tmux() { : ; }
stty() { : ; }
tput() { : ; }

ftl::test::setup() {
    ftl_state_session_dir=$(mktemp -d)
    # ... initialize state
}

ftl::test::teardown() {
    rm -rf "$ftl_state_session_dir" 2>/dev/null
}

test_my_feature_works() {
    # ... set up ...
    ftl::my_module::do_thing
    ftl::test::assert_eq "expected" "$actual" "feature works"
}

test_my_feature_edge_case() {
    # ...
}

# vim: set filetype=bash :
```

### Steps

1. Create the test file.
2. Source the modules under test.
3. Add stubs for I/O functions.
4. Define `setup` and `teardown`.
5. Write test functions.
6. Run: `bash test/harness.sh test/unit/test_my_feature.sh -v`.
7. Iterate until all tests pass.
8. Commit.

### Key points

- Test **behavior**, not implementation. Assert on observable state
  (filesystem changes, global variables), not on which internal
  functions were called.
- Test edge cases: empty input, missing files, invalid arguments,
  concurrent access.
- Use `ftl::test::skip` for tests that require optional tools.
- See `test/unit/test_inline_rename.sh` and
  `test/unit/test_missing_functionalities_behavior.sh` for patterns.
