# Missing Functionalities (Implemented)

This page documents all the features that were implemented from the
`ftl-missing-functionality.md` analysis. Each feature has a binding, a
function, behavioral tests, and detailed documentation.

**Test coverage**: 42 features, 128 behavioral tests in
`test/unit/test_missing_functionalities_behavior.sh` (plus 48 existence
tests in `test/unit/test_missing_functionalities.sh`).

**Implementation**: `config/ftl/bindings/missing_functionalities` (582 lines).

## Table of Contents

1. [File Operations](#1-file-operations)
2. [Navigation](#2-navigation)
3. [Selection](#3-selection)
4. [Search](#4-search)
5. [Preview](#5-preview)
6. [UI](#6-ui)
7. [Git](#7-git)
8. [Archives](#8-archives)
9. [Remote / Network](#9-remote--network)
10. [Configuration](#10-configuration)
11. [Dependencies](#11-dependencies)

---

## 1. File Operations

### `xd` — Duplicate selection

**Function**: `ftl::plugin::missing::duplicate`

Creates a copy of each selected file in the same directory with a
`_copy<N>` suffix before the extension. The `<N>` increments to avoid
overwriting existing copies.

**Behaviour**:
- Source: `report.txt` → Copy: `report_copy1.txt`
- If `report_copy1.txt` exists → Copy: `report_copy2.txt`
- Files without extensions: `Makefile` → `Makefile_copy1`
- Directories are copied recursively (`cp -r`).

**Example workflow**:
1. Tag the file(s) you want to duplicate (`SPACE` or `t`)
2. Press `xd`
3. The copies appear in the listing, cursor stays on the original

**Tests**: `test_duplicate_creates_copy_with_suffix`,
`test_duplicate_increments_suffix`, `test_duplicate_preserves_no_extension`,
`test_duplicate_handles_multiple_selection`, `test_duplicate_uses_cp_r_for_directories`

---

### `xH` — Hard link selection

**Function**: `ftl::plugin::missing::hardlink`

Creates hard links (not symlinks) to each selected file in the current
directory. Hard links share the same inode — useful for deduplication,
snapshots, or having a file appear in two places without doubling disk
usage.

**Behaviour**:
- Prompts `Hard link (N)? [y|N]` — press `y` to confirm, anything else aborts.
- The links are created in `$PWD` (the current directory), not the source
  directory. If the source is in `$PWD`, the link would overwrite the
  source — so typically you tag files in a subdirectory and press `xH`
  from the parent.
- The new link has the same basename as the source.

**Example workflow**:
1. `cd` into a subdirectory
2. Tag the file(s) you want to hardlink
3. `H` (move left to parent — or use `\` to cd to parent)
4. Press `xH`, then `y`

**Tests**: `test_hardlink_creates_link_in_cwd` (verifies inode match),
`test_hardlink_declined_does_nothing`

---

### `xt` — Update timestamps

**Function**: `ftl::plugin::missing::touch_files`

Runs `touch` on each selected file, updating its modification and access
times to the current time. Files that don't exist are silently skipped
(`touch` is called with stderr suppressed).

**Use cases**:
- Force a build system (make) to consider the file "newer"
- Mark files as recently touched for backup scripts
- Refresh mtime after editing metadata

**Tests**: `test_touch_files_updates_mtime`,
`test_touch_files_handles_multiple`

---

### `xs` — Compute SHA256 checksums

**Function**: `ftl::plugin::missing::checksum`

Runs `sha256sum` on each selected file and displays the output in the
preview pane. Useful for verifying file integrity or generating checksums
for distribution.

**Output format** (one line per file):
```
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  /path/to/file.txt
```

**Dependencies**: `sha256sum` (from coreutils, always available).

**Tests**: `test_checksum_computes_sha256`, `test_checksum_for_multiple_files`

---

### `xv` — Verify checksums

**Function**: `ftl::plugin::missing::checksum_verify`

For each selected file, checks for a `.sha256` sidecar file and runs
`sha256sum -c` to verify. If no `.sha256` file exists, reports
`<file>: no checksum file`.

**Sidecar format** (standard sha256sum output):
```
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  file.txt
```

**Example workflow**:
1. Select `data.txt` and press `xs` to generate checksums
2. Save the output to `data.txt.sha256`
3. Later, select `data.txt` and press `xv` to verify

**Tests**: `test_checksum_verify_with_valid_sha256_file`,
`test_checksum_verify_without_sha256_file`

---

### `xR` — Rename with sed pattern

**Function**: `ftl::plugin::missing::rename_pattern`

Prompts for a `sed -E` expression and applies it to each selected file's
basename. Files where the pattern produces no change are skipped. Files
where the target name already exists are also skipped (no overwrite).

**Prompt**: `rename pattern (sed): ` with default `s/OLD/NEW/`

**Examples**:
- `s/\.jpeg$/.jpg/` — fix extension
- `s/^IMG_/vacation_/` — rebrand photo filenames
- `s/ /_/g` — replace spaces with underscores

**Note**: For interactive single-file rename, sequential numbered rename,
or image-label editing, use the [Inline Rename Mode](./user-guide/inline-rename.md)
(`LEADER r i`) instead — it provides a modal workflow with live preview.

**Tests**: `test_rename_pattern_applies_sed`, `test_rename_pattern_empty_aborts`,
`test_rename_pattern_no_match_skips`, `test_rename_pattern_skips_existing_target`,
`test_rename_pattern_multiple_files`

---

### `xn` — Chmod with octal mode

**Function**: `ftl::plugin::missing::chmod_numeric`

Prompts for an octal mode (3 or 4 digits) and applies `chmod` to each
selected file. Invalid input (non-octal, wrong length) is silently
ignored.

**Prompt**: `chmod (octal, eg 755): `

**Examples**:
- `755` — rwxr-xr-x (executable, world-readable)
- `644` — rw-r--r-- (default for files)
- `600` — rw------- (private)
- `4755` — setuid + rwxr-xr-x

**Tests**: `test_chmod_numeric_applies_octal`,
`test_chmod_numeric_invalid_pattern_aborts`, `test_chmod_numeric_4_digit`

---

### `xo` — Change owner/group

**Function**: `ftl::plugin::missing::chown_files`

Prompts for a `user:group` specification and runs `sudo chown` on each
selected file. Empty input aborts. **Requires sudo privileges** — this
is the only feature in ftl that escalates privileges.

**Prompt**: `chown (user:group): `

**Examples**:
- `alice` — change owner only
- `alice:staff` — change owner and group
- `:staff` — change group only

**Tests**: `test_chown_files_empty_aborts` (the non-empty path requires
root, so only the abort path is tested behaviourally)

---

### `zA` — Size analysis

**Function**: `ftl::plugin::missing::size_analysis`

Finds the top 20 largest files in the current directory tree (recursive)
and displays them in the preview pane, sorted by size descending.

**Output format**:
```
     1048576  ./large_file.bin
      524288  ./docs/manual.pdf
      ...
```

**Implementation**: `find . -type f -printf '%s\t%p\n' | sort -rn | head -20 | awk '{printf "%10s  %s\n", $1, $2}'`

**Tests**: `test_size_analysis_finds_largest`

---

## 2. Navigation

### `ALT-z` — Go back

**Function**: `ftl::plugin::missing::nav_back`

Navigate backward through the directory history maintained by
`nav_record`. The history is a simple stack — `nav_back` decrements the
index and `cd`s to the previous entry.

**At the start of history** (index ≤ 1), `nav_back` is a no-op.

---

### `ALT-y` — Go forward

**Function**: `ftl::plugin::missing::nav_forward`

Navigate forward through the directory history. At the end of history,
`nav_forward` is a no-op.

---

### `nav_record` (internal)

**Function**: `ftl::plugin::missing::nav_record`

Records the current `$PWD` in the navigation history. This is called
internally by ftl's directory-change machinery (not directly user-facing),
but is tested to verify the history-stack semantics.

**Skips**: child panes (`ftl_pane_is_child == 1`) and empty paths.

**Tests**: `test_nav_record_appends_to_history`,
`test_nav_record_skipped_in_child_pane`, `test_nav_record_skipped_with_empty_path`,
`test_nav_back_does_nothing_at_start`, `test_nav_back_decrements_index`,
`test_nav_forward_does_nothing_at_end`, `test_nav_forward_increments_index`,
`test_nav_back_forward_roundtrip`

---

### `H` — Cd to parent, select previous directory

**Function**: `ftl::plugin::missing::move_left_select`

Moves up one directory level (like `h`), but also positions the cursor on
the directory you just left. This is useful when you `cd` into a
subdirectory to inspect it, then want to return to the parent and
continue navigating from where you were.

**Behaviour**:
1. Records the current `$PWD`
2. `cd` to parent (`ftl::cmd::cd_to_parent`)
3. `ftl::list::change_dir "$PWD" "$(basename "$last_dir")"` — positions cursor on the previous dir

**Tests**: `test_move_left_select_cd_to_parent`

---

### `mM` — Manage marks (bookmark UI)

**Function**: `ftl::plugin::missing::marks_manage`

Opens an fzf-based UI with two actions:
- **view** — jump to a mark (delegates to `ftl::cmd::goto_mark_via_fzf`)
- **delete** — select marks to delete (multi-select fzf), then `unset` them from `ftl_mark_session_marks`

**Tests**: `test_marks_manage_view_action`

---

## 3. Selection

### `yi` — Invert selection

**Function**: `ftl::plugin::missing::selection_invert`

Inverts the current selection: every entry in the listing that was
**not** tagged becomes tagged, and every entry that **was** tagged
becomes untagged.

**Example**: If you have 100 files and 3 are tagged, `yi` tags the
other 97 and untags the original 3.

**Tests**: `test_selection_invert_selects_untagged`,
`test_selection_invert_with_no_initial_selection`,
`test_selection_invert_with_all_selected`

---

### `yp` — Select by pattern

**Function**: `ftl::plugin::missing::select_by_pattern`

Prompts for a regex and tags every listing entry whose basename matches.

**Prompt**: `select pattern (regex): `

**Examples**:
- `\.jpg$` — select all JPEGs
- `^IMG_` — select files starting with `IMG_`
- `^[0-9]{4}-[0-9]{2}-[0-9]{2}` — select ISO-date-prefixed files

**Tests**: `test_select_by_pattern_matches_names`,
`test_select_by_pattern_regex`, `test_select_by_pattern_empty_aborts`

---

### `yz` — Select by size

**Function**: `ftl::plugin::missing::select_by_size`

Prompts for a minimum size in bytes and tags every regular file larger
than that size. Non-numeric input aborts. `0` selects all non-empty files.

**Prompt**: `min size (bytes): `

**Examples**:
- `1000000` — select files larger than 1 MB
- `0` — select all non-empty files

**Tests**: `test_select_by_size_picks_large_files`,
`test_select_by_size_invalid_input_aborts`, `test_select_by_size_zero_selects_all_files`

---

### `yS` — Save selection to file

**Function**: `ftl::plugin::missing::selection_save`

Prompts for a filename and writes the current selection (one path per
line) to that file.

**Prompt**: `save selection to: ` (default: `$ftl_state_session_dir/saved_selection`)

**File format**:
```
/path/to/first/file
/path/to/second/file
```

**Tests**: `test_selection_save_writes_file`

---

### `yL` — Load selection from file

**Function**: `ftl::plugin::missing::selection_load`

Prompts for a filename, clears the current selection, and tags every
path listed in the file. If the file doesn't exist, the current
selection is left untouched.

**Prompt**: `load selection from: ` (default: `$ftl_state_session_dir/saved_selection`)

**Tests**: `test_selection_load_restores_tags`,
`test_selection_load_missing_file_does_nothing`

---

### `yu` — Union with file

**Function**: `ftl::plugin::missing::selection_union`

Prompts for a filename and adds every path in that file to the current
selection (without clearing the existing selection). Paths that don't
exist are silently ignored by `ftl::sel::set`.

**Prompt**: `union with file: `

**Tests**: `test_selection_union_merges_from_file`,
`test_selection_union_with_missing_file`

---

### `yi` (intersect) — Intersect with file

**Function**: `ftl::plugin::missing::selection_intersect`

Prompts for a filename and keeps only the entries that are in **both**
the current selection and the file. The selection class (tag glyph) of
each kept entry is preserved.

**Prompt**: `intersect with file: `

**Tests**: `test_selection_intersect_keeps_only_common`,
`test_selection_intersect_empty_result`

---

### `yd` — Subtract file entries

**Function**: `ftl::plugin::missing::selection_subtract`

Prompts for a filename and removes every path in that file from the
current selection.

**Prompt**: `subtract file: `

**Tests**: `test_selection_subtract_removes_from_file`,
`test_selection_subtract_missing_file_no_op`

---

### `v` — Visual selection mode

**Function**: `ftl::plugin::missing::visual_mode`

Enters a modal visual-selection loop. Starting from the current cursor
position, you can move up (`k`) or down (`j`); every entry between the
start and current cursor is tagged. Press `Escape` to exit.

**Behaviour**:
1. Records the starting cursor index
2. Reads keys in a loop:
   - `j` — move cursor down, tag the range
   - `k` — move cursor up, tag the range
   - `Escape` — exit
3. Tags every entry between `visual_start` and `cursor` (inclusive)

**Tests**: `test_visual_mode_completes_without_crash`

---

## 4. Search

### `rR` — Search & replace across files

**Function**: `ftl::plugin::missing::rg_replace`

Prompts for a search string, a replacement string, and a scope, then
runs `sed -i` to replace all occurrences in the chosen scope.

**Prompts**:
1. `search: `
2. `replace: `
3. `replace in [a]ll/[s]elected/[c]wd? `

**Scopes**:
- `a` (all) — `rg -l <search> . | xargs sed -i "s/<search>/<replace>/g"`
- `s` (selected) — `printf '%s\n' "${ftl_selection_current[@]}" | xargs sed -i ...`
- `c` (cwd) — same as `a`

**Empty search aborts.** **Dependencies**: `rg` (ripgrep), `sed`.

**Tests**: `test_rg_replace_replaces_in_selected`,
`test_rg_replace_empty_search_aborts`

---

### `rh` — Find with history

**Function**: `ftl::plugin::missing::find_with_history`

Like the standard `find_in_dir`, but pre-fills the search string from
the last entry in `$ftl_state_session_dir/find_history`, and appends
the current search string to that file after the search.

**Behaviour**:
1. Reads the last line of `find_history` into `ftl_state_search_string`
2. Calls `ftl::cmd::find_in_dir` (which prompts the user, pre-filled)
3. If `ftl_state_search_string` is non-empty after the search, appends it to `find_history`

**Tests**: `test_find_with_history_appends_to_history_file`,
`test_find_with_history_loads_last_entry`

---

## 5. Preview

### `zp` — Pin preview

**Function**: `ftl::plugin::missing::preview_pin`

Locks the preview pane to the current file. A lock file is created in
`$ftl_state_session_dir/lock_preview/<full_path>` containing the pinned
path and stat output. While the lock exists, the preview pane should not
switch to other files.

**Lock file contents**:
```
>>> LOCKED PREVIEW: /path/to/file
    Pinned at: Thu Jul 24 01:39:37 UTC 2026
  File: /path/to/file
  Size: 1234        ...
```

**Tests**: `test_preview_pin_creates_lock_file`

---

### `zP` — Unpin preview

**Function**: `ftl::plugin::missing::preview_unpin`

Removes the lock file for the current file, allowing the preview pane to
switch again. If no lock file exists, this is a silent no-op.

**Tests**: `test_preview_unpin_removes_lock_file`,
`test_preview_unpin_without_prior_pin_no_op`

---

### `zpc` — Compare two files

**Function**: `ftl::plugin::missing::preview_compare`

Opens a split pane running `$ftl_cfg_diff_tool` on the two selected
files. Requires **exactly 2 selected files** — any other count warns
and aborts.

**Configuration**: `ftl_cfg_diff_tool` (default: `diff`).

**Tests**: `test_preview_compare_with_two_files`,
`test_preview_compare_wrong_count_aborts`

---

### `zi` / `zo` — Zoom in / out

**Functions**: `ftl::plugin::missing::preview_zoom_in`,
`ftl::plugin::missing::preview_zoom_out`

Adjusts the image-preview zoom level (0–5). `zi` increments (capped at
5) and sets `ftl_cfg_image_zoomed=1`. `zo` decrements (floored at 0).

**Tests**: `test_preview_zoom_in_increments`,
`test_preview_zoom_in_caps_at_5`, `test_preview_zoom_out_decrements`,
`test_preview_zoom_out_floors_at_0`, `test_preview_zoom_in_sets_image_zoomed_flag`

---

### `zr` — Rotate preview

**Function**: `ftl::plugin::missing::preview_rotate`

Rotates the current image 90° clockwise and displays the result. Uses
ImageMagick's `convert` to create a temp file, then calls
`ftl::prev::show_image` on the temp path.

**Dependencies**: `convert` (ImageMagick).

**Tests**: `test_preview_rotate_invokes_convert`

---

### `zL` — Live tail for logs

**Function**: `ftl::plugin::missing::preview_tail_live`

Opens a split pane running `tail -f` on the current file. Only activates
for files with extensions matching `log|out|err` — other files are
silently skipped.

**Tests**: `test_preview_tail_live_with_log_file`,
`test_preview_tail_live_skips_non_log_file`,
`test_preview_tail_live_accepts_out_extension`,
`test_preview_tail_live_accepts_err_extension`

---

## 6. UI

### `CP` — Command palette

**Function**: `ftl::plugin::missing::command_palette`

Opens an fzf-searchable list of all bound commands. Selecting a command
sets `ftl_state_pending_input` to its key sequence, which the keyboard
engine then dispatches.

**Dependencies**: `fzf-tmux`.

**Tests**: `test_command_palette_sets_pending_input`,
`test_command_palette_empty_choice_no_op`

---

### `\ws` — Save workspace

**Function**: `ftl::plugin::missing::workspace_save`

Prompts for a workspace name and saves the current ftl state:
- `tabs` — one directory per line (all open tabs)
- `active_tab` — the current tab index
- `selection` — `declare -p ftl_selection_tags` output (sourceable)

**Location**: `$FTL_STATE_DIR/workspaces/<name>/`

**Tests**: `test_workspace_save_writes_files`,
`test_workspace_save_empty_name_aborts`

---

### `\wl` — Load workspace

**Function**: `ftl::plugin::missing::workspace_load`

Opens an fzf list of saved workspaces, loads the selected one's tabs,
active tab, and selection, then `cd`s to the active tab's directory.

**Tests**: `test_workspace_load_restores_tabs`

---

## 7. Git

### `gbl` — Git blame in preview

**Function**: `ftl::plugin::missing::git_blame_preview`

Runs `git blame` on the current file and displays the output in the
preview pane. Skips silently if:
- The current entry is not a regular file
- Not inside a git repository (`git rev-parse HEAD` fails)

**Tests**: `test_git_blame_preview_runs_in_repo`,
`test_git_blame_preview_skips_non_file`,
`test_git_blame_preview_skips_outside_repo`

---

### `gll` — Git file log

**Function**: `ftl::plugin::missing::git_file_log`

Runs `git log --oneline --follow` on the current file and displays the
output in the preview pane. `--follow` tracks the file across renames.
Same skip conditions as `git_blame_preview`.

**Tests**: `test_git_file_log_runs_in_repo`,
`test_git_file_log_skips_non_file`

---

### `gds` — Git diff stat

**Function**: `ftl::plugin::missing::git_diff_stat`

Runs `git diff --stat` (uncommitted changes) and displays the output in
the preview pane. Skips outside a git repo.

**Tests**: `test_git_diff_stat_runs_in_repo`,
`test_git_diff_stat_skips_outside_repo`

---

## 8. Archives

### `\fz` — Compress as zip

**Function**: `ftl::plugin::missing::compress_zip`

Prompts for an archive name (without extension) and creates `<name>.zip`
containing the selected files. The archive is created in the current
directory.

**Prompt**: `zip file: `

**Dependencies**: `zip`.

**Tests**: `test_compress_zip_creates_archive`,
`test_compress_zip_empty_name_aborts`

---

### `\f7` — Compress as 7z

**Function**: `ftl::plugin::missing::compress_7z`

Prompts for an archive name and creates `<name>.7z` containing the
selected files. 7z offers better compression than zip, especially for
text-heavy archives.

**Prompt**: `7z file: `

**Dependencies**: `7z` (p7zip).

**Tests**: `test_compress_7z_creates_archive`

---

### `\fl` — List archive contents

**Function**: `ftl::plugin::missing::archive_list`

Lists the contents of the current archive in the preview pane. Detects
the archive type by extension:

| Extension | Tool |
|-----------|------|
| `zip` | `unzip -l` |
| `rar` | `unrar list` |
| `tar`, `gz`, `bz2`, `xz` | `tar -tf` |

Other extensions are silently ignored.

**Tests**: `test_archive_list_zip`, `test_archive_list_tar`,
`test_archive_list_unsupported_extension_no_op`

---

## 9. Remote / Network

### `\su` — Upload via SCP

**Function**: `ftl::plugin::missing::scp_upload`

1. Opens an fzf list of hosts from `~/.ssh/known_hosts`
2. Prompts for a remote path (default: `~`)
3. Runs `scp <selection> <host>:<remote_path>`

Aborts silently if no host is selected.

**Dependencies**: `scp`, `fzf-tmux`, `~/.ssh/known_hosts`.

**Tests**: `test_scp_upload_no_known_hosts_no_op`,
`test_scp_upload_with_host_prompts_for_path`

---

### `\dl` — Download URL with wget

**Function**: `ftl::plugin::missing::download_url`

Prompts for a URL and runs `wget <url>` in a background tmux window,
with the current directory as the download destination. Empty input
aborts.

**Prompt**: `URL: `

**Dependencies**: `wget`.

**Tests**: `test_download_url_invokes_wget`,
`test_download_url_empty_aborts`

---

## 10. Configuration

These variables can be set in `~/.config/ftl/ftlrc`:

```bash
# Diff tool used by preview_compare (zpc)
ftl_cfg_diff_tool="diff"

# Delete command (used by some file operations)
ftl_cfg_delete_command="rm -rf"
```

The missing-functionalities features don't introduce new config variables
of their own — they use the existing ftl infrastructure (`ftl_cfg_*`,
`ftl_state_*`).

---

## 11. Dependencies

| Tool | Used by | Required? |
|------|---------|-----------|
| `cp` | duplicate | yes (coreutils) |
| `ln` | hardlink | yes (coreutils) |
| `touch` | touch_files | yes (coreutils) |
| `sha256sum` | checksum, checksum_verify | yes (coreutils) |
| `sed` | rename_pattern, rg_replace | yes (coreutils) |
| `chmod` | chmod_numeric | yes (coreutils) |
| `sudo` | chown_files | only for chown |
| `stat` | size_analysis, preview_pin | yes (coreutils) |
| `find` | size_analysis | yes (findutils) |
| `awk` | size_analysis | yes (gawk) |
| `sort` | size_analysis | yes (coreutils) |
| `head` | size_analysis | yes (coreutils) |
| `rg` (ripgrep) | rg_replace | optional — feature skips if missing |
| `fzf-tmux` | marks_manage, command_palette, workspace_load, scp_upload | optional — features no-op if missing |
| `git` | git_blame_preview, git_file_log, git_diff_stat | optional — features skip if missing |
| `zip` | compress_zip | optional — feature skips if missing |
| `7z` (p7zip) | compress_7z | optional — feature skips if missing |
| `unzip` | archive_list (zip) | optional |
| `unrar` | archive_list (rar) | optional |
| `tar` | archive_list (tar/gz/bz2/xz) | yes (tar) |
| `scp` | scp_upload | optional |
| `wget` | download_url | optional |
| `convert` (ImageMagick) | preview_rotate | optional — feature skips if missing |
| `tail` | preview_tail_live | yes (coreutils) |

**Installing all optional dependencies on Debian/Ubuntu**:
```bash
sudo apt install ripgrep fzf p7zip-full unzip unrar imagemagick
```

---

## Test Coverage

All 42 functions are covered by two test files:

1. **`test/unit/test_missing_functionalities.sh`** — 48 existence tests
   (verify each function is defined and bound)
2. **`test/unit/test_missing_functionalities_behavior.sh`** — 128
   behavioral tests (exercise each function against a real temp
   directory and assert on the resulting filesystem / state changes)

Run the full behavioral suite:
```bash
bash test/harness.sh test/unit/test_missing_functionalities_behavior.sh
```

Expected output: `Passed: 128, Failed: 0, Skipped: 0` (some tests skip
if their optional dependency is missing).
