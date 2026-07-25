# `ftl` — Missing Functionality v2 (Proposed)

> **Subject:** A second round of feature proposals for ftl, informed by
> a survey of 10 popular terminal file managers (ranger, vifm, lf, nnn,
> yazi, broot, mc, fff, clifm, superfile) and community discussions.
> **Purpose:** Identify functionality gaps in ftl relative to its peers
> and propose bindings for each.
> **Companion documents:** `ftl-missing-functionality.md` (v1, 42
> features implemented), `ftl-terminal-file-manager-comparison.md`
> (comparative analysis).
> **Status:** Proposal — not yet implemented.

---

## Table of Contents

1. [UI / Visual](#1-ui--visual)
2. [Navigation](#2-navigation)
3. [File Operations](#3-file-operations)
4. [Selection](#4-selection)
5. [Search](#5-search)
6. [Preview](#6-preview)
7. [Archive / Compression](#7-archive--compression)
8. [Remote / Network](#8-remote--network)
9. [Git / VCS](#9-git--vcs)
10. [Configuration / Session](#10-configuration--session)
11. [Integration](#11-integration)
12. [Safety / Undo](#12-safety--undo)
13. [Quick-Reference: All Proposals](#13-quick-reference-all-proposals)

---

## 1. UI / Visual

### 1.1 File type icons (devicons)

**What:** Display a Nerd Font glyph next to each filename, indicating
its type (folder, image, PDF, video, source file, etc.).

**Why:** Every modern file manager (yazi, lf, nnn, ranger with
devicons plugin) supports this. It improves scannability at the cost of
requiring a Nerd Font.

**Implementation sketch:**
```bash
# A new etag plugin: etags/devicons
ftl::etag::scan_directory() {
    declare -g -A devicon_tags=()
    local f ext
    while IFS= read -r f ; do
        if [[ -d "$f" ]] ; then
            devicon_tags["$f"]=$'\ue5ff'  # folder icon
        else
            ext="${f##*.}"
            case "$ext" in
                jpg|jpeg|png|gif) devicon_tags["$f"]=$'\ue727' ;;  # image
                pdf)              devicon_tags["$f"]=$'\uf724' ;;  # pdf
                mp4|mkv|webm)     devicon_tags["$f"]=$'\uf03d' ;;  # video
                mp3|flac|ogg)     devicon_tags["$f"]=$'\uf001' ;;  # audio
                zip|tar|gz)       devicon_tags["$f"]=$'\uf410' ;;  # archive
                md)               devicon_tags["$f"]=$'\ue609' ;;  # markdown
                py)               devicon_tags["$f"]=$'\ue73c' ;;  # python
                js)               devicon_tags["$f"]=$'\ue74e' ;;  # javascript
                sh|bash)          devicon_tags["$f"]=$'\ue795' ;;  # shell
                *)                devicon_tags["$f"]=$'\ue612' ;;  # default file
            esac
        fi
    done < <(find "$PWD/" -maxdepth 1 2>/dev/null)
}
```
**Proposed binding:** `zTi` (cycle to devicons etag).

---

### 1.2 Color schemes / themes

**What:** User-selectable color schemes for the listing, header, and
cursor.

**Why:** ranger and vifm support themes; yazi has a flavors system. ftl
currently uses a fixed color palette via `ftl_cfg_cursor_color_*`.

**Implementation sketch:**
```bash
# In ftlrc:
ftl_cfg_theme="dark"
# A new command: :theme <name>
# Sources $FTL_CFG/etc/themes/<name> which sets ftl_cfg_*_color variables
```
**Proposed binding:** `LEADER c t` (theme selector via fzf).

---

### 1.3 Status line / footer

**What:** A persistent footer line showing context: git branch, free
disk space, directory entry count, selection count/size, current filter.

**Why:** vifm, mc, and clifm all have status lines. ftl's header shows
some of this, but a dedicated footer would declutter the header and
support more information.

**Implementation sketch:** Add a `_ftl::list::render_footer` function
called after `_ftl::list::render_header`. Content configurable via
`ftl_cfg_footer_format`.

**Proposed binding:** `zof` (toggle footer).

---

### 1.4 Path breadcrumb header

**What:** Replace the single-line PWD header with a clickable
breadcrumb (`/ > home > user > projects > ftl`), where each segment is
selectable to jump to that ancestor.

**Why:** broot and yazi use breadcrumbs. They make deep navigation
context clear.

**Implementation sketch:** Modify `_ftl::list::render_header` to split
`$PWD` on `/` and render each segment. Add a sub-mode (`LEADER b`)
where `j`/`k` select a segment and `Enter` jumps to it.

**Proposed binding:** `LEADER b` (breadcrumb navigation).

---

### 1.5 Mouse support

**What:** Click to select, double-click to open, scroll to navigate,
right-click for context menu.

**Why:** ranger, vifm, lf, yazi all support mouse. ftl currently has
no mouse handling (tmux handles it, but ftl ignores mouse events).

**Implementation sketch:** Enable tmux mouse mode (`tmux set mouse on`),
parse mouse escape sequences in `ftl::kbd::normalize_key`, dispatch to
new `ftl::cmd::mouse_click`, `ftl::cmd::mouse_scroll` functions.

**Proposed binding:** Automatic (no key binding; mouse events are
dispatched directly).

---

### 1.6 Smooth scrolling

**What:** Scroll the listing by lines (not pages) with `CTL-U` / `CTL-D`
half-page jumps, and `CTL-B` / `CTL-F` full-page jumps, matching vim.

**Why:** Every vim-like file manager supports this. ftl currently only
has `J` / `K` (step) and `g` / `G` (top/bottom).

**Implementation sketch:** Add `ftl::cmd::scroll_half_page` and
`ftl::cmd::scroll_full_page` that adjust `ftl_list_window_top` and
re-render.

**Proposed bindings:** `CTL-U` / `CTL-D` (half page), `CTL-B` / `CTL-F`
(full page).

---

## 2. Navigation

### 2.1 zoxide / autojump integration

**What:** Jump to a frequently-visited directory using `zoxide` or
`autojump`'s frequency database.

**Why:** yazi, ranger, and lf all have zoxide plugins. It is the
fastest way to jump to a known directory without typing its full path.

**Implementation sketch:**
```bash
ftl::plugin::zoxide::jump() {
    local dir
    dir=$(zoxide query -l | fzf-tmux -p 50% --reverse) || return
    ftl::list::change_dir "$dir"
}
ftl::kbd::bind ftl move "z" ftl::plugin::zoxide::jump "zoxide jump"
```
**Proposed binding:** `z` (or `LEADER z`).

---

### 2.2 Frecency-based directory jump

**What:** Like zoxide but built into ftl — track directory visit
frequency + recency, jump to the best match for a query.

**Why:** Removes the zoxide dependency; integrates with ftl's existing
history.

**Implementation sketch:** Maintain `ftl_state_frecency` (assoc array:
path → score) in `$FTL_STATE_DIR/frecency`. Score = `visits *
recency_decay`. `LEADER f` prompts for a substring, fzf-lists matching
paths by score.

**Proposed binding:** `LEADER f` (frecency jump).

---

### 2.3 Recent files

**What:** Show recently modified files across the whole tree (or a
configurable depth) as a virtual list.

**Why:** nnn has `--recent` mode; broot shows recent files. Useful for
resuming work.

**Implementation sketch:** `find . -mtime -1 -type f` piped to a
virtual entries list. Reuse the `virtual_entries` binding's framework.

**Proposed binding:** `LEADER r f` (recent files).

---

### 2.4 Directory tree view

**What:** Toggle between the flat listing and a tree view (like `tree`
but interactive — expand/collapse dirs with `Enter`).

**Why:** broot's core feature. lf has a tree preview. Useful for
understanding directory structure without leaving ftl.

**Implementation sketch:** New listing mode (`ftl_tab_listing_mode=2`
already exists for dir-only; add mode 3 = tree). Reuse `tree -J` (JSON
output) parsed into `ftl_list_entries` with indentation.

**Proposed binding:** `zt` (toggle tree view).

---

### 2.5 Two-pane (dual-directory) mode

**What:** Display two directories side-by-side, each independently
navigable, for easy cross-directory copy/move.

**Why:** mc and vifm's core feature. ftl's panes are independent
processes, so this is achievable by splitting the pane and having the
two panes track each other's "other side" for copy/move operations.

**Implementation sketch:** Add `ftl::cmd::copy_to_other_pane` and
`ftl::cmd::move_to_other_pane` that read the sibling pane's PWD from
`$ftl_state_shared_dir`. Bind to `pp` / `pm` (already bound, but
currently copy/move to *current* dir, not *other pane* dir).

**Proposed bindings:** `pp` (copy to other pane), `pm` (move to other
pane).

---

### 2.6 Bookmark sidebar

**What:** A persistent sidebar listing all session marks and project
marks, selectable with `j`/`k` + `Enter`.

**Why:** vifm has a bookmarks pane; ranger has `:mark` commands. A
sidebar makes bookmarks visible rather than requiring memorization of
mark characters.

**Implementation sketch:** A tmux popup (like `LEADER h h`) listing
`ftl_mark_session_marks` and project marks.

**Proposed binding:** `LEADER m b` (bookmark sidebar).

---

## 3. File Operations

### 3.1 Trash / restore

**What:** Move deleted files to a trash directory (`~/.local/share/Trash`
following the XDG spec) instead of removing them. Restore with an
fzf-list of trashed files.

**Why:** ranger, lf, yazi all support trash. ftl has
`ftl_cfg_delete_command` which can be set to `trash-put`, but there is
no restore binding.

**Implementation sketch:**
```bash
ftl::plugin::trash::restore() {
    local f
    f=$(find ~/.local/share/Trash/files -maxdepth 1 | fzf-tmux -p 50%) || return
    mv "$f" "$(grep "^$f$" ~/.local/share/Trash/info/*.trashinfo -l | ...)"
}
ftl::kbd::bind ftl entry "U" ftl::plugin::trash::restore "restore from trash"
```
**Proposed binding:** `U` (restore, currently unbound).

---

### 3.2 File shredding (secure delete) — enhanced

**What:** The existing `shred` binding overwrites and removes. Add
options: shred with a specific pattern, shred free space, shred with N
passes.

**Why:** The current `shred` binding is minimal. Power users want
control over the overwrite pattern and pass count.

**Implementation sketch:** Prompt for pass count and pattern.
`shred -n $passes -v -z -f "$file"`.

**Proposed binding:** `LEADER x s` (shred with options).

---

### 3.3 Batch touch (set arbitrary mtime)

**What:** Set the modification time of selected files to an
arbitrary timestamp (not just "now").

**Why:** Useful for organising photos by date, fixing sort order after
copying files. The existing `xt` only does `touch` (now).

**Implementation sketch:** `touch -d "$timestamp" "${ftl_selection_current[@]}"`.

**Proposed binding:** `LEADER x t` (touch with timestamp).

---

### 3.4 File splitting / joining

**What:** Split a large file into chunks (`split`), or join chunks back
together (`cat`).

**Why:** Useful for transferring large files across size-limited media.
No file manager currently ships this.

**Implementation sketch:** Prompt for chunk size, run `split -b $size
"$file" "$file.part-"`. Join: `cat "$file.part-"* > "$file"`.

**Proposed bindings:** `LEADER x split`, `LEADER x join`.

---

### 3.5 Symlink mass-creation

**What:** Create symlinks to the selection in a target directory (fzf-
selected), with the option to use relative or absolute paths.

**Why:** The existing `xl` creates symlinks in the current directory.
Mass-symlink to a different directory is a common workflow for
dotfile management.

**Implementation sketch:** fzf-select target dir, then `ln -s
"$source" "$target/"`.

**Proposed binding:** `LEADER x l` (symlink to target).

---

### 3.6 File comparison (3-way)

**What:** Diff 3 selected files with `diff3` or `meld`.

**Why:** The existing `\d` (file_diff) handles 2 files. 3-way merge is
useful for conflict resolution.

**Implementation sketch:** Check `${#ftl_selection_current[@]} == 3`,
run `diff3` or `$ftl_cfg_diff3_tool`.

**Proposed binding:** `\d3` (diff3).

---

### 3.7 Directory size cache

**What:** The `zs` (show_size) mode 3 computes recursive dir sizes
expensively. Cache the results with inode-based invalidation.

**Why:** Computing du on every render is slow. A cache makes mode 3
usable.

**Implementation sketch:** Store `ftl_list_dir_size_cache[dir]=size`
with a TTL. Invalidate on `ftl::pane::file_watcher` events.

**Proposed binding:** `zs` (existing; transparent cache).

---

### 3.8 File metadata editor (EXIF, ID3)

**What:** Edit EXIF/IPTC tags for images, ID3 tags for audio, without
opening an external editor.

**Why:** The inline rename mode's `l` key writes a single label. A
full metadata editor would expose all tags.

**Implementation sketch:** A tmux popup with `exiftool -json "$file"`
output in editable form, then `exiftool -overwrite_original
-<tag>=<value>` on save.

**Proposed binding:** `LEADER m e` (metadata editor).

---

## 4. Selection

### 4.1 Visual block selection (rectangle)

**What:** Select a rectangular block of entries (e.g. all `.txt` files
between rows 5 and 15).

**Why:** The existing visual mode (`v`) selects a range. A block
selection would allow pattern-based sub-selection within the range.

**Implementation sketch:** Extend `visual_mode` to accept a pattern;
only entries matching the pattern within the range are tagged.

**Proposed binding:** `LEADER v b` (visual block).

---

### 4.2 Persistent selection (across sessions)

**What:** Save the current selection to a named slot, restore it in a
later session.

**Why:** The existing `yS` / `yL` save/load to files. Named slots would
make this workflow smoother.

**Implementation sketch:** `ftl::plugin::selection::save_named` writes
to `$FTL_STATE_DIR/selections/<name>`. fzf-list on load.

**Proposed bindings:** `LEADER y s` (save named), `LEADER y l` (load
named).

---

### 4.3 Selection by age (mtime/ctime)

**What:** Select files modified within the last N days/hours/minutes.

**Why:** The existing `yz` (select by size) covers size. Age-based
selection is equally common (e.g. "select files modified today").

**Implementation sketch:** `find . -maxdepth 1 -mtime -$N -print`,
tag each result.

**Proposed binding:** `ya` (select by age).

---

### 4.4 Selection by permission

**What:** Select files by permission (e.g. world-writable, setuid,
executable).

**Why:** Security audits. No file manager currently offers this.

**Implementation sketch:** `find . -maxdepth 1 -perm /o+w -print`
(world-writable), etc.

**Proposed binding:** `yp p` (select by permission).

---

### 4.5 Selection by content (ripgrep)

**What:** Select all files whose contents match a regex.

**Why:** The existing `\g` (ripgrep search) jumps to matches. Selecting
all matching files is useful for batch operations on them.

**Implementation sketch:** `rg -l "$pattern" | while read f ; do
ftl::sel::set "$f" ; done`.

**Proposed binding:** `yr` (select by content).

---

## 5. Search

### 5.1 Fuzzy file finder (fd-based)

**What:** Use `fd` + `fzf` for a fuzzy file finder across the whole
tree, with preview.

**Why:** The existing `\f` uses fzf but without `fd`'s speed and
respect for `.gitignore`. yazi and ranger both use `fd` for fuzzy
finding.

**Implementation sketch:** `fd --type f --hidden | fzf-tmux -p 80%
--preview 'head -100 {}'`.

**Proposed binding:** `LEADER f f` (fuzzy find with fd).

---

### 5.2 Live content search (as-you-type)

**What:** Incremental ripgrep search — type a query and the listing
filters to files containing matches.

**Why:** ranger has `:scout -f`. yazi has a search plugin. ftl's
`/` is incremental but only matches filenames.

**Implementation sketch:** A sub-mode handler (like
`incremental_search`) that runs `rg -l "$query"` on each keystroke and
filters the listing.

**Proposed binding:** `\g i` (incremental content search).

---

### 5.3 Search by MIME type

**What:** Filter the listing by MIME type (e.g. "show only images",
"show only audio").

**Why:** Useful for mixed-media directories. Currently ftl filters by
extension, which is imprecise.

**Implementation sketch:** `file --mime-type -b "$f"` per entry, cache
in `ftl_list_mime_cache`, filter by selected MIME type.

**Proposed binding:** `fm` (filter by MIME type).

---

### 5.4 Duplicate file finder

**What:** Find and list duplicate files (by content hash) within the
current directory or tree.

**Why:** nnn has a `fzdu` plugin; rmlint integrates with ftl
(`\fl`). A dedicated duplicate finder would list dupes for selection
and deletion.

**Implementation sketch:** `find . -type f -exec md5sum {} + | sort |
awk 'dups[$1]++ {print $2}'` → virtual entries list.

**Proposed binding:** `LEADER f d` (find duplicates).

---

### 5.5 Search history navigation

**What:** The existing `rh` (find with history) appends to a file. Add
up/down arrow navigation through past search strings (like shell
history).

**Why:** ranger and vifm have search history navigation. ftl's
implementation is append-only.

**Implementation sketch:** In the search prompt, bind `UP`/`DOWN` to
read from `find_history` (already maintained).

**Proposed binding:** `UP` / `DOWN` in the search prompt.

---

## 6. Preview

### 6.1 Image EXIF sidebar

**What:** When previewing an image, show a sidebar with EXIF data
(camera, lens, ISO, aperture, shutter, GPS).

**Why:** The current image preview shows only the image. EXIF data is
useful for photographers.

**Implementation sketch:** `exiftool "$file"` in a split pane
alongside the image preview.

**Proposed binding:** `zei` (toggle EXIF sidebar).

---

### 6.2 Code syntax highlighting

**What:** Preview text/code files with syntax highlighting (via
`bat` or `highlight`).

**Why:** yazi and ranger both support `bat` for preview. ftl's `ptext`
uses `$PAGER` which may not highlight.

**Implementation sketch:** Set `ftl_cfg_pager="bat --paging=always"` in
ftlrc, or add a `pcode` viewer that uses `bat`.

**Proposed binding:** `zc` (toggle code highlighting in preview).

---

### 6.3 PDF page navigation

**What:** When previewing a PDF, navigate pages with `j`/`k` (or
`n`/`p`).

**Why:** The current PDF preview shows only the first page. yazi
supports scrollable preview.

**Implementation sketch:** Maintain `ftl_state_preview_page` (1-based).
On `j`/`k` in PDF preview, render `$file[$page]` via `pdftoppm -f $page
-l $page`.

**Proposed binding:** `j` / `k` (when preview pane has focus and file
is PDF).

---

### 6.4 Video scrubbing

**What:** When previewing a video, scrub to a specific timestamp with
`<` / `>` (or a slider).

**Why:** The current video preview shows the first frame only.

**Implementation sketch:** `ffmpeg -ss $timestamp -i "$file" -frames:v
1 "$thumb"` on each scrub.

**Proposed binding:** `<` / `>` (scrub backward / forward).

---

### 6.5 Archive content preview (with extraction)

**What:** Preview an archive's contents and extract a single file
without unpacking the whole archive.

**Why:** The current `\fl` lists contents. Single-file extraction is a
natural extension.

**Implementation sketch:** In the archive list preview, `Enter` on a
file extracts it to the current directory: `unzip "$archive" "$file"`.

**Proposed binding:** `Enter` (in archive preview).

---

### 6.6 Hex dump preview

**What:** Preview binary files as a hex dump (`xxd` or `hexdump -C`).

**Why:** The current `xh` opens a hex editor (`hexedit`) in a split.
A read-only hex dump in the preview pane would be faster for
inspection.

**Implementation sketch:** Add a `phex` viewer: `hexdump -C "$file" |
$PAGER`.

**Proposed binding:** `zh` (toggle hex preview).

---

### 6.7 Diff preview for git-tracked files

**What:** When the cursor is on a modified git-tracked file, show the
unified diff in the preview pane.

**Why:** The existing `gds` shows `git diff --stat` for the whole repo.
Per-file diff preview is more targeted.

**Implementation sketch:** In `pviewers`, check if the file is in a
git repo and modified. If so, run `git diff "$file" | $PAGER`.

**Proposed binding:** Automatic (preview pane detects git-modified
files).

---

## 7. Archive / Compression

### 7.1 Archive extraction (multi-format)

**What:** Extract archives (zip, tar, rar, 7z, gz, bz2, xz) into a
subdirectory.

**Why:** The current `\fl` lists contents. Extraction is missing.

**Implementation sketch:** Detect type by extension, dispatch to
`unzip` / `tar xf` / `unrar x` / `7z x`.

**Proposed binding:** `LEADER f x` (extract).

---

### 7.2 Archive creation (multi-format)

**What:** Create archives in multiple formats (zip, tar.gz, tar.bz2,
7z, xz) from the selection, with a format selector.

**Why:** The existing `LEADER f c` (compress) uses tar.bz2 only.
Format choice is useful for compatibility.

**Implementation sketch:** fzf-select format, then dispatch.

**Proposed binding:** `LEADER f c` (extended to prompt for format).

---

### 7.3 Archive testing

**What:** Test archive integrity (`unzip -t`, `tar -tf`, `7z t`).

**Why:** Verify archives before deletion or transfer.

**Implementation sketch:** Dispatch by extension, show results in
preview pane.

**Proposed binding:** `LEADER f t` (test archive).

---

### 7.4 Archive encryption

**What:** Create encrypted archives (zip -e, 7z with password, gpg-
encrypted tar).

**Why:** The existing `LEADER f e` does GPG encryption of files.
Encrypted archives are a different use case (single encrypted bundle).

**Implementation sketch:** `zip -e -r "$out.zip" "$@"` or `7z a -p
"$out.7z" "$@"`.

**Proposed binding:** `LEADER f E` (encrypted archive).

---

## 8. Remote / Network

### 8.1 SSH connection manager

**What:** fzf-list of SSH hosts (from `~/.ssh/config` and
`~/.ssh/known_hosts`), connect in a split pane.

**Why:** The existing `\su` (scp_upload) reads known_hosts but only for
upload. A connection manager is more general.

**Implementation sketch:** Parse `~/.ssh/config` for Host entries,
fzf-list, `tmux split "ssh $host"`.

**Proposed binding:** `LEADER s s` (SSH connect).

---

### 8.2 SFTP browse

**What:** Browse a remote SFTP server as if it were a local directory
(via `sshfs` mount).

**Why:** mc has built-in SFTP. ftl's pane model makes this easy: mount
via sshfs, then `cd` into the mountpoint.

**Implementation sketch:** `sshfs "$host:$remote" "$mnt"` then
`ftl::list::change_dir "$mnt"`.

**Proposed binding:** `LEADER s f` (SFTP mount and browse).

---

### 8.3 rsync wrapper

**What:** rsync the selection to a remote host with a configurable
command (dry-run by default, then commit).

**Why:** scp is simple but rsync is more capable (incremental, resume,
bandwidth limit). The existing `\su` uses scp.

**Implementation sketch:** Prompt for `host:path`, run `rsync -avn
--progress "${ftl_selection_current[@]}" "$host:$path"` (dry-run),
prompt to confirm, then run without `-n`.

**Proposed binding:** `LEADER s r` (rsync upload).

---

### 8.4 WebDAV / cloud storage

**What:** Mount WebDAV (Nextcloud, ownCloud) or cloud storage (S3,
Google Drive via rclone) and browse.

**Why:** Modern workflows increasingly involve cloud storage. rclone
supports 40+ providers.

**Implementation sketch:** `rclone mount remote: "$mnt"` then
`ftl::list::change_dir "$mnt"`.

**Proposed binding:** `LEADER s c` (cloud mount).

---

## 9. Git / VCS

### 9.1 Git status pane

**What:** A persistent pane showing `git status` for the current repo,
updating on directory change.

**Why:** The existing `gds` shows diff stat on demand. A persistent
status pane is more useful during active development.

**Implementation sketch:** A tmux split pane running `watch -c 'git
status -s'`, or a time-event handler that refreshes every N seconds.

**Proposed binding:** `LEADER g s` (toggle git status pane).

---

### 9.2 Git branch switcher

**What:** fzf-list of git branches, switch on selection.

**Why:** Faster than typing `git checkout <branch>`.

**Implementation sketch:** `git branch | fzf-tmux | xargs git checkout`.

**Proposed binding:** `LEADER g b` (branch switch).

---

### 9.3 Git stash management

**What:** List, apply, drop, pop stashes via fzf.

**Why:** Stash management is verbose in the shell. An fzf UI is
faster.

**Implementation sketch:** `git stash list`, fzf-select, dispatch to
`git stash apply/drop/pop`.

**Proposed binding:** `LEADER g t` (stash manager).

---

### 9.4 Git log graph

**What:** Display `git log --graph --oneline --all` in the preview pane
for the current repo.

**Why:** Visual git history is a common need. The existing `gll` shows
log for a single file.

**Implementation sketch:** `git log --graph --oneline --all | $PAGER`.

**Proposed binding:** `LEADER g l` (repo log graph).

---

### 9.5 Git conflict resolver

**What:** List files with merge conflicts (`git diff --name-only
--diff-filter=U`), open each in `$EDITOR` for resolution.

**Why:** After a merge with conflicts, this is the fastest path to
resolution.

**Implementation sketch:** `git diff --name-only --diff-filter=U |
fzf-tmux -m | xargs $EDITOR`.

**Proposed binding:** `LEADER g c` (conflict resolver).

---

## 10. Configuration / Session

### 10.1 Live config reload

**What:** Reload `ftlrc` without restarting ftl.

**Why:** Currently, config changes require a restart. Live reload
speeds up configuration iteration.

**Implementation sketch:** `:source $FTL_CFG/ftlrc` (already works for
bindings; needs to re-set `ftl_cfg_*` variables safely).

**Proposed binding:** `LEADER c r` (reload config).

---

### 10.2 Profile support

**What:** Multiple named profiles (e.g. "work", "personal"), each with
its own ftlrc, bindings, marks.

**Why:** Different workflows benefit from different configs.

**Implementation sketch:** `--profile <name>` CLI flag sources
`$FTL_CFG/profiles/<name>/ftlrc` instead of the default.

**Proposed binding:** `LEADER c p` (switch profile).

---

### 10.3 Session save/restore (enhanced)

**What:** The existing `\ws` / `\wl` save/load tabs + selection. Extend
to also save: cursor positions per directory, sort order per tab,
filter state, preview pane state.

**Why:** Full session restore brings you back to exactly where you
left off.

**Implementation sketch:** Extend the workspace format to include
`ftl_state_cursor_memory`, `ftl_tab_sort_type`, etc.

**Proposed binding:** `\ws` (enhanced — same binding, more state saved).

---

### 10.4 Tab naming

**What:** Name tabs (displayed in the tab bar) instead of just
numbers.

**Why:** vifm, lf, yazi all support tab naming. Useful for organising
work contexts.

**Implementation sketch:** `ftl_tab_names[$tab]="$name"`. `LEADER T`
prompts for a name.

**Proposed binding:** `LEADER T` (name current tab).

---

## 11. Integration

### 11.1 Editor integration (vim/nvim picker)

**What:** The existing `ftll` / `cdf` integrate ftl as a file picker.
Add a `vim`/`nvim` plugin that opens ftl in a floating window, returns
the selected file(s) to vim.

**Why:** yazi has `yazi.nvim`; ranger has `ranger.nvim`. vim users
expect this.

**Implementation sketch:** A vim plugin (separate repo) that spawns
ftl in a tmux popup or terminal floating window, reads the selection
from fd 3, and opens the files.

**Proposed binding:** N/A (vim-side plugin).

---

### 11.2 Shell integration (cd on exit)

**What:** When ftl exits, the calling shell's `cd` to ftl's last
directory.

**Why:** The existing `ftll` / `cdf` do this. Make it the default
behavior with a shell function wrapper.

**Implementation sketch:** A `ftl` shell function that runs the real
ftl, then `cd "$(cat $FTL_STATE_DIR/last_pwd)"` on exit.

**Proposed binding:** N/A (shell-side function).

---

### 11.3 FZF as a file picker backend

**What:** Use fzf as the listing itself (not just for search), with
ftl's preview pane.

**Why:** For very large directories, fzf's fuzzy matching is faster
than ftl's listing. yazi has a similar "fzf mode".

**Implementation sketch:** A binding that runs `fd | fzf-tmux --preview
'ftl_preview {}'`, then `ftl::list::change_dir` to the selected file's
parent.

**Proposed binding:** `LEADER f F` (fzf-as-listing mode).

---

### 11.4 TMSU deep integration

**What:** The existing `tmsu` binding previews tags. Add: tag
auto-completion, tag-based virtual directories, tag statistics.

**Why:** ftl already has TMSU support; deepening it would make ftl the
primary TMSU interface.

**Implementation sketch:** Virtual entries plugin that injects entries
matching a TMSU query.

**Proposed binding:** `LEADER t v` (TMSU virtual directory).

---

### 11.5 Notification on long operations

**What:** Send a desktop notification (`notify-send`) when a long
operation (rsync, large copy, archive creation) completes.

**Why:** Useful when the user switches away from ftl during a long
operation.

**Implementation sketch:** Wrap long-running commands with a trap that
calls `notify-send "ftl: $op complete"`.

**Proposed binding:** `ftl_cfg_notify_on_long_ops=1` (config flag).

---

## 12. Safety / Undo

### 12.1 Undo / redo for file operations

**What:** Undo the last file operation (delete, move, rename). Redo
re-applies it.

**Why:** No terminal file manager has this. It would be a significant
safety improvement. The inline rename mode already tracks history
(`ftl_inline_rename_history`); generalize this.

**Implementation sketch:** Maintain `ftl_state_op_log` (array of
inverse operations). On undo, execute the inverse (e.g. `mv` back,
restore from trash).

**Proposed bindings:** `u` (undo), `CTL-r` (redo).

---

### 12.2 Confirmation for destructive operations on > N files

**What:** If a delete/move affects more than N files (configurable),
require explicit confirmation showing the count and total size.

**Why:** Prevents accidental mass deletion. The current `d` binding
prompts but shows only the count.

**Implementation sketch:** In `delete_selection`, if
`${#ftl_selection_current[@]} > ftl_cfg_mass_op_threshold`, show a
detailed prompt.

**Proposed binding:** Automatic (existing `d`, enhanced prompt).

---

### 12.3 Read-only mode

**What:** A flag that disables all mutating operations (delete, move,
rename, chmod). Useful for browsing sensitive directories.

**Why:** Prevents accidental modification during inspection.

**Implementation sketch:** `ftl_cfg_read_only=1`. All mutating
commands check this flag and abort with a warning.

**Proposed binding:** `LEADER c r` (toggle read-only).

---

### 12.4 Operation log

**What:** A persistent log of all file operations performed by ftl
(delete, move, rename, chmod, etc.), viewable with `:show_op_log`.

**Why:** Audit trail. The existing `show_cmd_log` shows shell commands;
this would show file operations.

**Implementation sketch:** Append to
`$FTL_STATE_DIR/op_log` on every mutating command.

**Proposed binding:** `:show_op_log` (command).

---

### 12.5 Trash auto-empty

**What:** Automatically empty the trash directory when it exceeds a
configurable size or age.

**Why:** Prevents unbounded trash growth.

**Implementation sketch:** A time-event handler that checks
`du -s ~/.local/share/Trash` and purges old entries if over the limit.

**Proposed binding:** `ftl_cfg_trash_max_size="1G"` (config).

---

## 13. Quick-Reference: All Proposals

| # | Feature | Binding | Priority |
|---|---------|---------|----------|
| 1.1 | File type icons (devicons) | `zTi` | high |
| 1.2 | Color schemes / themes | `LEADER c t` | medium |
| 1.3 | Status line / footer | `zof` | medium |
| 1.4 | Path breadcrumb header | `LEADER b` | medium |
| 1.5 | Mouse support | (auto) | high |
| 1.6 | Smooth scrolling (half/full page) | `CTL-U/D`, `CTL-B/F` | high |
| 2.1 | zoxide / autojump integration | `z` | high |
| 2.2 | Frecency-based directory jump | `LEADER f` | high |
| 2.3 | Recent files | `LEADER r f` | medium |
| 2.4 | Directory tree view | `zt` | high |
| 2.5 | Two-pane (dual-directory) mode | `pp` / `pm` | medium |
| 2.6 | Bookmark sidebar | `LEADER m b` | medium |
| 3.1 | Trash / restore | `U` | high |
| 3.2 | File shredding (enhanced) | `LEADER x s` | medium |
| 3.3 | Batch touch (arbitrary mtime) | `LEADER x t` | medium |
| 3.4 | File splitting / joining | `LEADER x split/join` | low |
| 3.5 | Symlink mass-creation | `LEADER x l` | medium |
| 3.6 | File comparison (3-way) | `\d3` | low |
| 3.7 | Directory size cache | `zs` (transparent) | high |
| 3.8 | File metadata editor | `LEADER m e` | medium |
| 4.1 | Visual block selection | `LEADER v b` | low |
| 4.2 | Persistent selection (named slots) | `LEADER y s/l` | medium |
| 4.3 | Selection by age | `ya` | high |
| 4.4 | Selection by permission | `yp p` | medium |
| 4.5 | Selection by content (ripgrep) | `yr` | high |
| 5.1 | Fuzzy file finder (fd-based) | `LEADER f f` | high |
| 5.2 | Live content search | `\g i` | high |
| 5.3 | Search by MIME type | `fm` | medium |
| 5.4 | Duplicate file finder | `LEADER f d` | medium |
| 5.5 | Search history navigation | `UP/DN` in search | medium |
| 6.1 | Image EXIF sidebar | `zei` | medium |
| 6.2 | Code syntax highlighting | `zc` | high |
| 6.3 | PDF page navigation | `j/k` in PDF preview | high |
| 6.4 | Video scrubbing | `<` / `>` | medium |
| 6.5 | Archive content preview + extraction | `Enter` in archive | high |
| 6.6 | Hex dump preview | `zh` | medium |
| 6.7 | Diff preview for git-tracked files | (auto) | high |
| 7.1 | Archive extraction (multi-format) | `LEADER f x` | high |
| 7.2 | Archive creation (multi-format) | `LEADER f c` (enhanced) | high |
| 7.3 | Archive testing | `LEADER f t` | medium |
| 7.4 | Archive encryption | `LEADER f E` | medium |
| 8.1 | SSH connection manager | `LEADER s s` | high |
| 8.2 | SFTP browse (sshfs) | `LEADER s f` | medium |
| 8.3 | rsync wrapper | `LEADER s r` | high |
| 8.4 | WebDAV / cloud storage (rclone) | `LEADER s c` | medium |
| 9.1 | Git status pane | `LEADER g s` | high |
| 9.2 | Git branch switcher | `LEADER g b` | high |
| 9.3 | Git stash management | `LEADER g t` | medium |
| 9.4 | Git log graph | `LEADER g l` | medium |
| 9.5 | Git conflict resolver | `LEADER g c` | medium |
| 10.1 | Live config reload | `LEADER c r` | high |
| 10.2 | Profile support | `LEADER c p` | medium |
| 10.3 | Session save/restore (enhanced) | `\ws` (enhanced) | medium |
| 10.4 | Tab naming | `LEADER T` | medium |
| 11.1 | Editor integration (vim/nvim) | (vim plugin) | high |
| 11.2 | Shell integration (cd on exit) | (shell function) | high |
| 11.3 | FZF as a file picker backend | `LEADER f F` | medium |
| 11.4 | TMSU deep integration | `LEADER t v` | low |
| 11.5 | Notification on long operations | (config flag) | low |
| 12.1 | Undo / redo for file operations | `u` / `CTL-r` | high |
| 12.2 | Confirmation for mass operations | (auto) | high |
| 12.3 | Read-only mode | `LEADER c r` | medium |
| 12.4 | Operation log | `:show_op_log` | medium |
| 12.5 | Trash auto-empty | (config) | low |

**Total: 60 proposals.**

---

## Implementation Notes

The proposals above vary widely in implementation complexity:

- **Low effort** (1-2 hours, < 50 lines): 1.1, 1.3, 2.1, 2.3, 3.3,
  4.3, 5.1, 5.3, 6.2, 6.6, 7.3, 9.2, 10.1, 10.4, 12.3
- **Medium effort** (half day, 50-200 lines): 1.2, 1.4, 2.6, 3.5, 3.6,
  3.8, 4.2, 4.4, 5.5, 6.1, 6.4, 7.4, 8.2, 9.3, 9.4, 9.5, 10.2, 10.3,
  11.3, 11.5, 12.4, 12.5
- **High effort** (1+ days, 200+ lines or architectural changes): 1.5
  (mouse), 1.6 (scrolling), 2.2 (frecency), 2.4 (tree view), 2.5
  (two-pane), 3.7 (size cache), 4.5 (content selection), 5.2 (live
  content search), 5.4 (duplicate finder), 6.3 (PDF nav), 6.5
  (archive extraction), 6.7 (git diff preview), 7.1 (extraction), 7.2
  (multi-format compress), 8.1 (SSH manager), 8.3 (rsync wrapper), 8.4
  (rclone), 9.1 (git status pane), 11.1 (vim plugin), 11.2 (shell
  integration), 11.4 (TMSU deep), 12.1 (undo/redo), 12.2 (mass-op
  confirmation)

The high-priority items (marked "high" in the table) are recommended
for the next development cycle. Several overlap with existing ftl
infrastructure and can leverage the `missing_functionalities` binding
pattern (a single sourced file under `bindings/`).

Refer to `ftl-terminal-file-manager-comparison.md` for the competitive
analysis that informed these proposals, and to `ftl-missing-functionality.md`
(v1) for the 42 features already implemented.
