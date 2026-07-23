# `ftl` — Missing Functionality & Proposed Bindings

> **Subject:** Features that `ftl` lacks or implements incompletely, with proposed bindings for each.
> **Purpose:** A constructive complement to the analysis documents — what's missing and how to add it.
> **Companion documents:** `ftl-ftlrc-reference.md` (config reference), `ftl-bindings-analysis.md` (binding critique).
> **Approach:** For each missing feature: what it is, why it matters, how it could be implemented (sketch), and what binding(s) it could use.

---

## Table of Contents

1. [File Operations — Missing](#1-file-operations--missing)
2. [Navigation — Missing](#2-navigation--missing)
3. [Selection — Missing](#3-selection--missing)
4. [Search — Missing](#4-search--missing)
5. [Preview — Missing](#5-preview--missing)
6. [Tags & Metadata — Missing](#6-tags--metadata--missing)
7. [Git & VCS — Missing](#7-git--vcs--missing)
8. [Shell Integration — Missing](#8-shell-integration--missing)
9. [Archive Handling — Missing](#9-archive-handling--missing)
10. [Remote & Network — Missing](#10-remote--network--missing)
11. [UI/UX — Missing](#11-uiux--missing)
12. [Configuration — Missing](#12-configuration--missing)
13. [Plugins That Could Exist](#13-plugins-that-could-exist)
14. [Quick-Reference: All Proposed Bindings](#14-quick-reference-all-proposed-bindings)

---

## 1. File Operations — Missing

### 1.1 Duplicate / Clone

**What:** Create a copy of the selected file(s) in the same directory with a suffix like `_copy` or `(1)`.

**Why:** Common operation when you want to experiment with a file while keeping the original. Currently you have to: `w` (copy), type the full path, append a new name. Tedious.

**Implementation sketch:**
```bash
duplicate() {
    for f in "${selection[@]}" ; do
        local base="${f%/*}" name="${f##*/}" ext=
        [[ "$name" =~ \. ]] && ext=".${name##*.}" ; name="${name%.*}"
        local i=1
        while [[ -e "$base/${name}_copy${i}${ext}" ]] ; do ((i++)) ; done
        cp -r "$f" "$base/${name}_copy${i}${ext}"
    done
    cdir
}
bind ftl entry xd duplicate "duplicate selection in same directory"
```

**Proposed binding:** `xd` (x for file-op, d for duplicate) — or `ALT-d` per the bindings analysis.

### 1.2 Hard link

**What:** Create a hard link (vs. the existing `xl` which makes symlinks).

**Why:** Hard links share inodes — useful for deduplication, snapshots, or when you want a file to appear in two places without doubling disk usage.

**Implementation sketch:**
```bash
hardlink() {
    tag_check && prompt "Hard link (${#tags[@]})? [y|N]" -sn1
    [[ $REPLY == y ]] && tags_clear && for f in "${selection[@]}" ; do
        ln "$f" .
    done
    cdir
}
bind ftl entry xH hardlink "hard link selection in current directory"
```

**Proposed binding:** `xH` (capital H, parallels `xl` for symlink vs `xH` for hardlink). Note: `xH` is currently `hexedit` — would need to reassign hexedit to `xeh` per the bindings analysis.

### 1.3 Touch (update timestamp)

**What:** Update the modification time of selected files without opening them.

**Why:** Useful for build systems (make), backup scripts, or marking files as "recently touched".

**Implementation sketch:**
```bash
touch_files() {
    touch "${selection[@]}" ; cdir
}
bind ftl entry xt touch_files "update timestamps"
```

**Proposed binding:** `xt` (x for file-op, t for touch).

### 1.4 File shredding (secure delete) — partially exists

**What:** The `\fs` (shred) binding exists in `etc/bindings/shred`, but only shreds the selection. Missing: shred confirmation, shred-free-space, shred-with-pattern.

**Why:** Secure deletion is important for sensitive data. The current binding is minimal.

**Enhancement sketch:**
```bash
shred_command() {
    local count="${COUNT:-2}"
    ((${#selection[@]} > 1)) && plural='ies' || plural='y'
    prompt "shred: ${#selection[@]} entr${plural} with ${count} passes [yes|N]? "
    [[ $REPLY == yes ]] && {
        for f in "${selection[@]}" ; do
            shred -n "$count" -z -u "$f"
        done
        tags_clear
        cdir
    } || list
}
# COUNT controls passes: 3\fs = 3-pass shred
bind ftl entry "\fs" shred_command "shred selection (COUNT passes)"
```

### 1.5 File integrity (checksums)

**What:** Compute and verify checksums (md5, sha256) of selected files.

**Why:** Verifying downloads, detecting corruption, deduplication.

**Implementation sketch:**
```bash
checksum() {
    local algo="${1:-sha256}"
    for f in "${selection[@]}" ; do
        ${algo}sum "$f"
    done | psplit "cat ; read -sn 100"
}
checksum_verify() {
    for f in "${selection[@]}" ; do
        [[ -e "${f}.sha256" ]] && sha256sum -c "${f}.sha256" || echo "$f: no checksum file"
    done | psplit "cat ; read -sn 100"
}
bind ftl entry xs checksum "compute sha256"
bind ftl entry xv checksum_verify "verify checksums"
```

**Proposed bindings:** `xs` (checksum), `xv` (verify).

### 1.6 Batch rename with patterns

> **Status:** Implemented (extended) — the inline rename mode (`LEADER r i`)
> provides regexp rename (`R` key inside the mode), sequential numbered
> rename (`r`), single-file inline rename (`Return`), TAB-flow multi-file
> rename, and EXIF/IPTC image labeling (`l`). See
> `documentation/ftl-inline-rename-proposal.md` for the full design and
> `docs/src/user-guide/inline-rename.md` for user docs.

**What:** The existing `R` (rename) uses `edir` (interactive bulk renamer). Missing: pattern-based rename (regex substitution).

**Why:** Renaming 100 photos from `IMG_001.jpg` to `vacation_001.jpg` is tedious with `edir` but trivial with a regex.

**Implementation sketch:**
```bash
rename_pattern() {
    prompt "rename pattern (sed): " -i 's/OLD/NEW/'
    local pattern="$REPLY"
    [[ -z "$pattern" ]] && { list ; return ; }
    for f in "${selection[@]}" ; do
        local dir="${f%/*}" name="${f##*/}"
        local new_name="$(echo "$name" | sed -E "$pattern")"
        [[ "$name" != "$new_name" ]] && [[ ! -e "$dir/$new_name" ]] && mv "$f" "$dir/$new_name"
    done
    cdir
}
bind ftl entry xR rename_pattern "rename with sed pattern"
```

**Proposed binding:** `xR` (capital R for pattern-rename, parallels `R` for interactive rename).

### 1.7 File comparison (more than 2 files)

**What:** The `\vd` (file_diff) binding handles exactly 2 files. Missing: diff 3+ files, or directories with options.

**Why:** Comparing multiple variants of a file is common in development.

**Implementation sketch:**
```bash
diff3_files() {
    ((${#selection[@]} == 3)) || { warn "select exactly 3 files" ; list ; return ; }
    tcpreview
    diff3 "${selection[@]}" | $PAGER_ANSI
    cdir
}
bind ftl entry "\vd3" diff3_files "diff three files"
```

### 1.8 File size analysis

**What:** The existing `zs` (show_size) shows per-file sizes. Missing: size distribution, largest files, duplicate-size detection.

**Why:** Disk usage analysis is a common need.

**Implementation sketch:**
```bash
size_analysis() {
    local script='
    use File::Find;
    my %sizes;
    find(sub { $sizes{$File::Find::name} = -s $_ if -f $_ }, ".");
    my @sorted = sort { $sizes{$b} <=> $sizes{$a} } keys %sizes;
    print "Top 20 largest files:\n";
    for my $f (@sorted[0..19]) { printf "%10d  %s\n", $sizes{$f}, $f; }
    my %by_size;
    for my $f (keys %sizes) { push @{$by_size{$sizes{$f}}}, $f; }
    print "\nDuplicate sizes (potential dupes):\n";
    for my $size (sort { $a <=> $b } keys %by_size) {
        next if @{$by_size{$size}} < 2;
        printf "%10d  %d files\n", $size, scalar @{$by_size{$size}};
    }
    '
    tcpreview
    perl -e "$script" | $PAGER_ANSI
    cdir
}
bind ftl entry "\fsa" size_analysis "size analysis"
```

### 1.9 File permissions — numeric chmod

**What:** The existing `xmr`/`xmw`/`xmx` flip r/w/x bits. `xmM` opens sc-im. Missing: direct numeric chmod (e.g. `chmod 755`).

**Why:** Power users often think in octal modes.

**Implementation sketch:**
```bash
chmod_numeric() {
    prompt "chmod (octal, eg 755): "
    [[ "$REPLY" =~ ^[0-7]{3,4}$ ]] && chmod "$REPLY" "${selection[@]}" && cdir || list
}
bind ftl entry xn chmod_numeric "chmod with octal mode"
```

**Proposed binding:** `xn` (x for file-op, n for numeric).

### 1.10 File owner / group change

**What:** Missing entirely. No `chown` integration.

**Why:** Useful for system administration.

**Implementation sketch:**
```bash
chown_files() {
    prompt "chown (user:group): "
    [[ -n "$REPLY" ]] && sudo chown "$REPLY" "${selection[@]}" && cdir || list
}
bind ftl entry xo chown_files "change owner/group"
```

**Proposed binding:** `xo` (x for file-op, o for owner).

### 1.11 Inverse selection

**What:** Select everything that's NOT currently selected.

**Why:** Common operation when you want to delete everything except a few files.

**Implementation sketch:**
```bash
selection_invert() {
    local -A sel
    for f in "${!tags[@]}" ; do sel[$f]=1 ; done
    tags_clear
    for f in "${files[@]}" ; do
        [[ -z "${sel[$f]}" ]] && { tags[$f]='▪' ; tags_size + "$f" ; }
    done
    ((stagsi++))
    list
}
bind ftl selection yi selection_invert "invert selection"
```

**Proposed binding:** `yi` (y for selection, i for invert).

### 1.12 Select by pattern

**What:** Select files matching a glob or regex.

**Why:** Currently you'd use `ff` (filter) and then `yf` (select all files), but that's two steps.

**Implementation sketch:**
```bash
select_pattern() {
    prompt "select pattern (regex): "
    [[ -n "$REPLY" ]] && {
        for f in "${files[@]}" ; do
            [[ "${f##*/}" =~ $REPLY ]] && { tags[$f]='▪' ; tags_size + "$f" ; }
        done
        ((stagsi++))
    }
    list
}
bind ftl selection yp select_pattern "select by pattern"
```

**Proposed binding:** `yp` (y for selection, p for pattern).

---

## 2. Navigation — Missing

### 2.1 Undo/redo navigation

**What:** Go back/forward in the directory-visit history (like a web browser).

**Why:** Currently you can use `Hh` (fzf session history) but that requires fzf interaction. A quick undo is missing.

**Implementation sketch:**
```bash
declare -a nav_history nav_future
declare -i nav_index=0

# Wrap cdir to record history
cdir_record() {
    nav_history=("${nav_history[@]:0:nav_index}" "$PWD")
    ((nav_index++))
    nav_future=()
    cdir "$@"
}

nav_back() {
    ((nav_index > 1)) && {
        nav_future=("$PWD" "${nav_future[@]}")
        ((nav_index--))
        cd "${nav_history[nav_index-1]}"
        cdir
    }
}

nav_forward() {
    ((${#nav_future[@]})) && {
        nav_history=("${nav_history[@]}" "$PWD")
        ((nav_index++))
        cd "${nav_future[0]}"
        nav_future=("${nav_future[@]:1}")
        cdir
    }
}
bind ftl move ALT-z nav_back "go back in history"
bind ftl move ALT-y nav_forward "go forward in history"
```

**Proposed bindings:** `ALT-z` (back), `ALT-y` (forward) — universal browser keys (ALT-Left/Right conflict with tmux).

### 2.2 Quick directory jump (z / autojump integration)

**What:** Jump to a frequently-visited directory by partial name. Integrates with `z`, `autojump`, `fasd`, or `zoxide`.

**Why:** `ftl` has `marks` (manual bookmarks) but no frequency-based jumping.

**Implementation sketch:**
```bash
z_jump() {
    local dest
    if [[ -n "$1" ]] ; then
        dest=$(zoxide query -- "$1" | head -1)
    else
        dest=$(zoxide query -l | fzf-tmux $fzf_opt)
    fi
    [[ -n "$dest" ]] && cdir "$dest"
}
bind ftl move gz z_jump "zoxide jump"
```

**Proposed binding:** `gz` (g for goto, z for zoxide).

### 2.3 Recent files

**What:** Show and jump to recently-modified files anywhere under the current directory.

**Why:** Common need — "where did I just edit?"

**Implementation sketch:**
```bash
recent_files() {
    local fzf_choice
    fzf_choice=$(fd -t f -H -I --changed-within=7days | fzf-tmux $fzf_opt -m --expect=ctrl-t)
    [[ -n "$fzf_choice" ]] && go_loop fzf "$fzf_choice"
}
bind ftl find gr recent_files "recent files (7 days)"
```

**Proposed binding:** `gr` (g for goto, r for recent).

### 2.4 Parent directory navigation with selection

**What:** `h` (move_left) goes to parent but loses cursor position. Missing: "go to parent and select the directory I just came from".

**Why:** When you `l` into a dir then `h` back, you end up at the top of the parent, not at the dir you were just in.

**Implementation sketch:**
```bash
move_left_select() {
    local last_dir="$PWD"
    move_left
    # After move_left, PWD is the parent; select last_dir
    sleep 0.05
    cdir "$PWD" "$(basename "$last_dir")"
}
bind ftl move H move_left_select "cd to parent, select previous dir"
```

**Proposed binding:** `H` (capital, parallels `h`). Currently `H` is unbound.

### 2.5 Directory size column (always-on)

**What:** `zs` (show_size) cycles through modes, but mode 3 (recursive dir sizes) is expensive. Missing: a cached/batched mode that computes dir sizes in the background.

**Why:** Users want to see dir sizes without waiting.

**Implementation sketch:**
```bash
# Background dir-size computation
dir_dusize_async() {
    (dir_dusize ; tmux send -t $my_pane ${C[refresh_pane]}) &
}
# In cview, if show_size == 3, kick off async computation
```

### 2.6 Bookmark management UI

**What:** `gm` (mark_fzf) lets you jump to marks, but there's no UI to view/edit/delete marks.

**Why:** Marks accumulate and become unmanageable.

**Implementation sketch:**
```bash
marks_manage() {
    local action
    action=$(printf "view\ndelete\nedit\n" | fzf-tmux -p 30%)
    case "$action" in
        view) mark_fzf ;;
        delete)
            local to_delete
            to_delete=$(printf "%s\n" "${!marks[@]}" | fzf-tmux -m -p 30%)
            [[ -n "$to_delete" ]] && while read k ; do unset marks[$k] ; done <<<"$to_delete"
            list ;;
        edit)
            local tmp=$(mktemp)
            for k in "${!marks[@]}" ; do echo "$k ${marks[$k]}" ; done > "$tmp"
            $EDITOR "$tmp"
            # Re-parse... (complex)
            rm "$tmp"
            list ;;
    esac
}
bind ftl marks mM marks_manage "manage marks"
```

---

## 3. Selection — Missing

### 3.1 Persistent selection (across directory changes)

**What:** Currently `tags` is per-pane and persists across directory changes, but the UI doesn't show how many tagged files are in other directories.

**Why:** You tag files in dir A, cd to dir B, and forget what you tagged.

**Enhancement:** Show in the header: `5/12 (3 here, 2 in other dirs)`.

### 3.2 Selection by size/age/type

**What:** Select files larger than N, older than N days, of a specific mime type.

**Why:** Common batch operations.

**Implementation sketch:**
```bash
select_by_size() {
    prompt "min size (bytes, k/m/g suffix): "
    local size="$REPLY"
    # Parse size...
    for f in "${files[@]}" ; do
        [[ -f "$f" ]] && (( $(stat -c %s "$f") > size )) && { tags[$f]='▪' ; tags_size + "$f" ; }
    done
    ((stagsi++)) ; list
}
bind ftl selection ys select_by_size "select by size"
```

### 3.3 Selection persistence across sessions

**What:** Tags are lost when `ftl` quits. Missing: save/load selection to a file.

**Why:** Long-running selection workflows (curation, triage).

**Implementation sketch:**
```bash
selection_save() {
    prompt "save selection to: " -i "$fs/saved_selection"
    [[ -n "$REPLY" ]] && printf "%s\n" "${!tags[@]}" > "$REPLY"
    list
}
selection_load() {
    prompt "load selection from: " -i "$fs/saved_selection"
    [[ -n "$REPLY" && -f "$REPLY" ]] && {
        tags_clear
        while read p ; do tag_set "$(path_full "$p")" ; done < "$REPLY"
        ((stagsi++))
    }
    list
}
bind ftl selection ys selection_save "save selection"
bind ftl selection yl selection_load "load selection"
```

### 3.4 Selection operations (union/intersection/difference)

**What:** Combine multiple saved selections with set operations.

**Why:** Complex curation workflows.

**Implementation sketch:**
```bash
selection_union() {
    prompt "union with file: "
    [[ -n "$REPLY" && -f "$REPLY" ]] && {
        while read p ; do tag_set "$(path_full "$p")" ; done < "$REPLY"
        ((stagsi++))
    }
    list
}
# Similarly: selection_intersect, selection_subtract
```

### 3.5 Visual selection mode (vim-style)

**What:** Press `v` to enter visual mode, move cursor to extend selection, press `v` again to confirm.

**Why:** More intuitive than `yy`/`yu` for selecting a range.

**Implementation sketch:**
```bash
visual_mode() {
    key_map=visual_select
    visual_start=$file
    cursor_color="$cursor_color_search"
    list
}
visual_select() {
    case "$REPLY" in
        ESCAPE|ENTER) key_map= ; cursor_color="$cursor_color0" ;;
        j|DOWN) move_down ; for ((i=visual_start; i<=file; i++)) ; do tag_set "${files[$i]}" ; done ; list ;;
        k|UP) move_up ; for ((i=file; i<=visual_start; i++)) ; do tag_set "${files[$i]}" ; done ; list ;;
        *) key_command ;;
    esac
}
bind ftl selection v visual_mode "visual selection mode"
```

**Proposed binding:** `v` (vim-standard).

---

## 4. Search — Missing

### 4.1 Replace (search & replace across files)

**What:** `grr` opens a file with rg matches. Missing: replace matches across multiple files.

**Why:** Refactoring across a project.

**Implementation sketch:**
```bash
rg_replace() {
    prompt "search: "
    local search="$REPLY"
    prompt "replace: "
    local replace="$REPLY"
    prompt "replace in [a]ll/[s]elected/[c]wd? "
    case "$REPLY" in
        a) rg -l "$search" . | xargs sed -i "s/$search/$replace/g" ;;
        s) printf "%s\n" "${selection[@]}" | xargs sed -i "s/$search/$replace/g" ;;
        c) rg -l "$search" . | xargs sed -i "s/$search/$replace/g" ;;
    esac
    cdir
}
bind ftl find rR rg_replace "search and replace"
```

**Proposed binding:** `rR` (r for replace, capital for the search-replace variant).

### 4.2 Search file contents (live, as you type)

**What:** Currently `/` searches filenames. Missing: live content search.

**Why:** "Which of these files contains 'TODO'?"

**Implementation sketch:**
```bash
content_search() {
    key_map=content_search_inc
    to_search=
    cursor_color="$cursor_color_search"
    list
}
content_search_inc() {
    case "$REPLY" in
        ESCAPE) cursor_color="$cursor_color0" ; to_search= ; key_map= ; list ;;
        BACKSPACE) [[ -n "$to_search" ]] && { to_search="${to_search::-1}" ; content_search_update ; } ;;
        ENTER|RIGHT) [[ -n "$content_matches" ]] && cdir "$(dirname "${content_matches[0]}")" "$(basename "${content_matches[0]}")" ;;
        *) to_search="$to_search$REPLY" ; content_search_update ;;
    esac
}
content_search_update() {
    content_matches=()
    while IFS= read -r line ; do
        content_matches+=("$line")
    done < <(rg -l "$to_search" "${files[@]}")
    # Highlight matched files in the listing
    list
}
bind ftl find "/" content_search "incremental content search"
```

### 4.3 Search by mime type

**What:** Filter listing by mime type (e.g. "show only images").

**Why:** More flexible than extension-based filtering.

**Implementation sketch:**
```bash
filter_mime() {
    prompt "mime type (eg image/*): "
    [[ -n "$REPLY" ]] && {
        # Custom filter that checks mime type
        filter_ext="by_mime"
        # ... write a by_mime filter script
    }
    cdir
}
bind ftl filter fm filter_mime "filter by mime type"
```

### 4.4 Search by metadata (exif, id3)

**What:** Find images by camera model, music by artist, etc.

**Why:** Media organization.

**Implementation sketch:**
```bash
search_exif() {
    prompt "exif key=value (eg Make=Canon): "
    local key="${REPLY%%=*}" val="${REPLY#*=}"
    for f in "${files[@]}" ; do
        [[ -f "$f" ]] && exiftool -s3 -"$key" "$f" 2>/dev/null | grep -qi "$val" && tag_set "$f"
    done
    list
}
bind ftl find ge search_exif "search by exif metadata"
```

### 4.5 Fuzzy file finder with frequency ranking

**What:** `ff` (find_fzf) lists files alphabetically. Missing: frequency-ranked (most-opened first).

**Why:** Faster access to frequently-used files.

**Implementation sketch:** Maintain a frequency database in `$ftl_root/freq` and sort fzf results by frequency.

### 4.6 Search history

**What:** `/` doesn't remember previous searches. Missing: search history with up-arrow recall.

**Why:** Repeating a complex search is tedious.

**Implementation sketch:**
```bash
# Use readline history for the find prompt
find_entry() {
    prompt "find: " -i to_search
    # Store in history file
    [[ -n "$REPLY" && "$REPLY" != "$to_search" ]] && {
        echo "$REPLY" >> "$fs/find_history"
        to_search="$REPLY"
    }
    R="${C[find_next]}"
}
```

---

## 5. Preview — Missing

### 5.1 Preview for more file types

**What:** The `viewers/core` handles ~20 file types. Missing types:

- **Office documents** (`.docx`, `.xlsx`, `.pptx`) — could use `pandoc` or `libreoffice --headless`
- **eBooks** (`.mobi`, `.azw3`) — could use `calibre`'s `ebook-convert`
- **Database files** (`.sqlite`, `.db`) — could use `sqlite3` with schema preview
- **Torrent files** (`.torrent`) — could parse with `transmission-show`
- **Disk images** (`.iso`, `.img`) — could show contents with `isoinfo -l`
- **Compressed archives** (`.7z`, `.zst`, `.br`) — only some are handled
- **CAD files** (`.dwg`, `.dxf`) — could use `freecad` headless
- **Audio waveforms** — could render with `ffmpeg` + `sox`
- **Video frames** (multiple, not just first) — could show a grid
- **EPUB chapters** (table of contents view)
- **Markdown rendered HTML** (currently uses `vmd`/`mo` — could add `glow`/`bat`)
- **CSV/TSV** — could use `column -t -s,` or `tvw`
- **Log files** with syntax highlighting (currently plain text)
- **Diff/patch files** — could colorize with `delta`
- **Calendar files** (`.ics`) — could parse with `icalendar`
- **Font files** (`.ttf`, `.otf`) — could render sample text with `fc-query`
- **Color picker for images** — show dominant colors
- **PDF metadata** (author, title, pages) — currently just renders pages
- **SVG with animation** — currently renders static

### 5.2 Preview history / pin

**What:** `preview_lock` exists (in `etc/core/lib/lock_preview/`) but is unbound. Missing: easy pin/unpin of previews.

**Why:** "Keep this preview while I browse other files" — useful for comparison.

**Proposed bindings:**
```bash
bind ftl view zp preview_lock "pin current preview"
bind ftl view zP preview_lock_clr "unpin preview"
```

### 5.3 Split preview (compare two files)

**What:** `zff` (preview_pane2) opens a second preview pane. Missing: easy way to put two specific files in the two panes.

**Why:** Side-by-side comparison.

**Implementation sketch:**
```bash
preview_compare() {
    ((${#selection[@]} == 2)) || { warn "select 2 files" ; return ; }
    preview_pane2="$f"  # First file in main preview
    # ... set up second preview with selection[1]
    tcpreview
    tsplit "$EDITOR -R ${selection[1]@Q}" "30%" "-h -b" "-R"
    pane2_id=$pane_id
    pane_id=
    # Preview first file
    pw3image "${selection[0]}"  # or vipreview
}
bind ftl view zpc preview_compare "compare two files"
```

### 5.4 Preview zoom (in/out)

**What:** `zz` toggles image zoom. Missing: incremental zoom (10%, 25%, 50%, 100%, 200%).

**Why:** Fine-grained image inspection.

**Implementation sketch:**
```bash
declare -i preview_zoom_level=2  # index into zoom_levels
zoom_levels=(25 50 75 100 150 200)
preview_zoom_in() {
    ((preview_zoom_level < ${#zoom_levels[@]} - 1)) && ((preview_zoom_level++))
    FTLI_Z=1  # enable zoom
    # Pass zoom level to ftli... (requires ftli enhancement)
    list
}
preview_zoom_out() {
    ((preview_zoom_level > 0)) && ((preview_zoom_level--))
    FTLI_Z=1
    list
}
bind ftl view zi preview_zoom_in "zoom in"
bind ftl view zo preview_zoom_out "zoom out"
```

### 5.5 Preview rotation (for images)

**What:** Missing entirely.

**Why:** Viewing photos taken in portrait orientation.

**Implementation sketch:**
```bash
preview_rotate() {
    local tmp="$fs/rotated_$(md5sum <<<"$n" | cut -d' ' -f1).jpg"
    convert "$n" -rotate 90 "$tmp"
    pw3image "$tmp"
}
bind ftl view zr preview_rotate "rotate preview 90°"
```

### 5.6 Preview for empty files

**What:** Empty files (`size 0`) show as "empty" in `file -b` but `ptext` (vim) opens them anyway. Missing: special-case display.

**Why:** Distinguish empty files from text files.

### 5.7 Live preview updates

**What:** If a file changes (e.g. log file being written), the preview doesn't auto-update. Missing: tail mode.

**Why:** Monitoring log files.

**Implementation sketch:**
```bash
preview_tail_live() {
    [[ $e =~ log|out|err ]] && {
        tcpreview
        tsplit "tail -f ${n@Q}" "30%"
    }
}
bind ftl view zL preview_tail_live "live tail preview"
```

---

## 6. Tags & Metadata — Missing

### 6.1 Built-in tagging (no TMSU dependency)

**What:** `ftl` has deep TMSU integration but no built-in tagging system for users who don't have TMSU installed.

**Why:** TMSU is a heavy dependency (FUSE). A simple file-based tag store would be more portable.

**Implementation sketch:**
```bash
# Tag store: $ftl_root/tags.db (simple text file: path<TAB>tag)
ftl_tag_add() {
    local tag="$1" ; shift
    for f in "$@" ; do
        echo -e "$(realpath "$f")\t$tag" >> "$ftl_root/tags.db"
    done
}
ftl_tag_list() {
    local f="$1"
    grep "^$(realpath "$f")\t" "$ftl_root/tags.db" | cut -f2
}
ftl_tag_find() {
    local tag="$1"
    grep -P "\t$tag$" "$ftl_root/tags.db" | cut -f1
}
```

### 6.2 Tag autocomplete

**What:** `tmsu_tag_fzf` lets you pick from existing TMSU tags. Missing: tag autocomplete when typing a new tag.

### 6.3 Tag categories / hierarchies

**What:** TMSU tags are flat. Missing: hierarchical tags (e.g. `project/ftl`, `project/ftl/bug`).

### 6.4 Tag-based color coding

**What:** Files with specific tags could be colored differently in the listing.

**Why:** Visual organization.

**Implementation sketch:** Add a `tag_colors` associative array:
```bash
declare -A tag_colors=(
    [important]="1;31"  # bold red
    [todo]="1;33"       # bold yellow
    [done]="1;32"       # bold green
)
```
And modify `user_color()` to check tags.

---

## 7. Git & VCS — Missing

### 7.1 Git blame in preview

**What:** `\gg` shows git status as etag. Missing: git blame in the preview pane.

**Implementation sketch:**
```bash
git_blame_preview() {
    [[ -f "$n" ]] && git rev-parse HEAD &>/dev/null && {
        tcpreview
        git blame "$n" | delta | $PAGER_ANSI
    }
}
bind ftl find gbl git_blame_preview "git blame preview"
```

### 7.2 Git log for file

**What:** Show commit history for the current file.

**Implementation sketch:**
```bash
git_file_log() {
    [[ -f "$n" ]] && git rev-parse HEAD &>/dev/null && {
        tcpreview
        git log --oneline --follow "$n" | $PAGER_ANSI
    }
}
bind ftl find gll git_file_log "git log for file"
```

### 7.3 Git checkout file

**What:** Restore a file from a specific commit.

### 7.4 Git stash integration

**What:** Stash/pop/apply stashes.

### 7.5 Git branch switching

**What:** Switch branches from within ftl.

### 7.6 Git merge conflict resolution

**What:** Detect merge conflicts and offer `git mergetool`.

### 7.7 Other VCS support (Mercurial, SVN, Fossil)

**What:** Only git is supported. Missing: hg, svn, fossil, jj (jujutsu).

**Implementation sketch:** Generalize the git etag to detect the VCS and dispatch.

### 7.8 Git diff stat

**What:** Show diffstat (files changed, insertions, deletions) in preview.

### 7.9 Git show (commit details)

**What:** Show a specific commit's details.

### 7.10 Git cherry-pick / revert

**What:** Cherry-pick or revert commits.

---

## 8. Shell Integration — Missing

### 8.1 Send command to shell pane (with completion)

**What:** `Sp` runs a command in a pane. Missing: command builder with fzf completion.

### 8.2 Repeat last shell command

**What:** Re-run the last command from the shell pane.

### 8.3 Shell pane per directory

**What:** Currently one shell pane. Missing: per-directory shell panes (each tab gets its own shell).

### 8.4 SSH integration

**What:** Open an SSH session to a remote host from ftl.

**Implementation sketch:**
```bash
ssh_connect() {
    local host
    host=$(awk '{print $1}' ~/.ssh/known_hosts | sort -u | fzf-tmux $fzf_opt)
    [[ -n "$host" ]] && tmux new-window "ssh $host"
}
bind ftl shell \ss ssh_connect "ssh to host"
```

### 8.5 Docker integration

**What:** Attach to a Docker container, exec into it.

### 8.6 Tmux session switcher

**What:** Switch between tmux sessions from ftl.

---

## 9. Archive Handling — Missing

### 9.1 Archive creation (more formats)

**What:** `\fc` creates `tar.bz2`. Missing: zip, 7z, gz (single file), xz, zst.

**Implementation sketch:**
```bash
compress_zip() {
    prompt "zip file: "
    [[ -n "$REPLY" ]] && zip -r "${REPLY}.zip" "${selection[@]}" && cdir '' "${REPLY}.zip"
}
compress_7z() {
    prompt "7z file: "
    [[ -n "$REPLY" ]] && 7z a "${REPLY}.7z" "${selection[@]}" && cdir '' "${REPLY}.7z"
}
bind ftl entry "\fcz" compress_zip "compress as zip"
bind ftl entry "\fc7" compress_7z "compress as 7z"
```

### 9.2 Archive listing (without extracting)

**What:** `\fd` extracts. Missing: just list contents.

### 9.3 Archive extraction (partial)

**What:** Extract specific files from an archive.

### 9.4 Archive password support

**What:** Handle encrypted zip/rar/7z.

### 9.5 Archive conversion

**What:** Convert between archive formats (zip → tar.gz).

---

## 10. Remote & Network — Missing

### 10.1 SSH/SCP integration

**What:** Copy selection to a remote host via SCP.

**Implementation sketch:**
```bash
scp_upload() {
    local host
    host=$(awk '{print $1}' ~/.ssh/known_hosts | sort -u | fzf-tmux $fzf_opt)
    [[ -n "$host" ]] && {
        prompt "remote path: " -i "~"
        scp "${selection[@]}" "$host:$REPLY"
    }
}
bind ftl entry "\fsu" scp_upload "upload via scp"
```

### 10.2 rsync integration

**What:** Sync directories with rsync.

### 10.3 SFTP browsing

**What:** Browse remote filesystems via SFTP as if local.

### 10.4 WebDAV / cloud storage

**What:** Mount and browse WebDAV, S3, Google Drive, etc.

### 10.5 Download manager

**What:** Paste a URL, download it to the current directory.

**Implementation sketch:**
```bash
download_url() {
    prompt "URL: "
    [[ -n "$REPLY" ]] && {
        tsucommand _DL "cd '$PWD' ; wget '$REPLY'"
        cdir
    }
}
bind ftl entry "\fdl" download_url "download URL"
```

### 10.6 URL handling (open in browser)

**What:** The `url` command exists (opens in qutebrowser) but takes an argument. Missing: detect URLs in files and open them.

---

## 11. UI/UX — Missing

### 11.1 Help for current context

**What:** `?` shows the full man page. Missing: context-sensitive help (e.g. "what does this binding do?").

**Implementation sketch:**
```bash
context_help() {
    prompt "binding to explain: "
    [[ -n "$REPLY" ]] && {
        local cmd="${kbd_trie[$REPLY]}"
        [[ -n "$cmd" ]] && tmux popup -w 60% -h 20% "echo '$cmd: $(grep \"$cmd\" $FTL_CFG/etc/ftlrc | head -1)'"
    }
}
bind ftl ftl "\?" context_help "explain binding"
```

### 11.2 Command palette

**What:** Like VS Code / Sublime — press a key, type a command name, run it.

**Why:** Discoverability for the 281 bindings.

**Implementation sketch:**
```bash
command_palette() {
    local choice
    choice=$(printf "%s\n" "${!C[@]}" | fzf-tmux -p 50% --preview 'grep {} $FTL_CFG/etc/ftlrc | head -3')
    [[ -n "$choice" ]] && R="${C[$choice]}"
}
bind ftl ftl CP command_palette "command palette"
```

### 11.3 Status line / message log

**What:** Messages (errors, warnings) appear briefly. Missing: a persistent message log.

### 11.4 Mouse support

**What:** Click to select, double-click to open, right-click for menu.

**Why:** Some users prefer mouse for certain operations.

**Note:** tmux supports mouse; ftl would need to handle mouse events in its key loop.

### 11.5 Configurable theme

**What:** Colors are scattered across many variables. Missing: a theme system (dark/light/solarized/etc.).

**Implementation sketch:**
```bash
theme_dark() {
    line_color0="\e[2;40;90m"
    cursor_color0='\e[7;34m'
    # ...
}
theme_light() {
    line_color0="\e[2;47;30m"
    cursor_color0='\e[7;33m'
    # ...
}
bind ftl ftl "\thd" theme_dark "dark theme"
bind ftl ftl "\thl" theme_light "light theme"
```

### 11.6 Bookmark bar / pinned directories

**What:** A persistent UI element showing pinned directories for quick access.

### 11.7 File previews in fzf

**What:** `gff` (find_fzf) uses fzf's default preview (none). Missing: ftl's preview in fzf's preview pane.

**Note:** `fzf_pane_preview` (binding `gfp`) does this, but it's not the default.

### 11.8 Multi-cursor

**What:** Edit multiple files at once with multiple cursors (like vim's `:bufdo`).

### 11.9 Workspace / session save

**What:** Save the current set of tabs/panes/directories to a workspace file. Restore on next launch.

**Implementation sketch:**
```bash
workspace_save() {
    local name
    prompt "workspace name: "
    [[ -n "$REPLY" ]] && {
        local ws="$ftl_root/workspaces/$REPLY"
        mkdir -p "$ws"
        printf "%s\n" "${tabs[@]}" > "$ws/tabs"
        # Save pane layout...
    }
}
workspace_load() {
    local name
    name=$(ls "$ftl_root/workspaces" 2>/dev/null | fzf-tmux)
    [[ -n "$name" ]] && {
        # Restore tabs...
    }
}
bind ftl ftl "\ws" workspace_save "save workspace"
bind ftl ftl "\wl" workspace_load "load workspace"
```

---

## 12. Configuration — Missing

### 12.1 Per-project config

**What:** `.ftlrc_dir` exists but it's per-directory. Missing: per-project (walk up to find project root).

### 12.2 Config validation

**What:** No startup validation. Missing: check that external commands exist, paths are valid, etc.

**Implementation sketch:**
```bash
validate_config() {
    local errors=0
    for cmd in $EDITOR $SXIV $MIMETYPE $HEXVIEW $HEXEDIT $JSON_VIEWER $YAML_VIEWER $NCDU ; do
        command -v "${cmd%% *}" &>/dev/null || { echo "missing: $cmd" ; ((errors++)) ; }
    done
    [[ $errors -gt 0 ]] && tmux popup -w 60% -h 30% "echo 'Missing $errors commands'"
}
# Call at startup
```

### 12.3 Config profiles

**What:** Switch between config profiles (work/home/project).

### 12.4 Live config reload

**What:** Changing `ftlrc` requires restarting ftl. Missing: live reload.

### 12.5 Config import/export

**What:** Export current config to a file, import on another machine.

---

## 13. Plugins That Could Exist

### 13.1 Image viewer with EXIF overlay

**What:** A custom image viewer that overlays EXIF data (camera, settings, GPS) on the preview.

### 13.2 PDF viewer with table of contents

**What:** Show PDF TOC in a sidebar.

### 13.3 Markdown viewer with TOC

**What:** Side panel showing the markdown's table of contents for quick navigation.

### 13.4 Code viewer with LSP integration

**What:** Show symbol definitions, references, hover info using an LSP server.

### 13.5 Music player with playlist

**What:** A full music player UI (playlist, queue, controls) in the preview pane.

### 13.6 Video player with timeline

**What:** Show video preview with a seekable timeline.

### 13.7 Diff viewer with syntax highlighting

**What:** Better diff display using `delta` or `difftastic`.

### 13.8 Archive browser

**What:** Browse archive contents like a directory (with virtual entries).

### 13.9 Trash manager

**What:** UI for browsing and restoring trashed files.

### 13.10 Disk usage visualizer

**What:** Sunburst or treemap visualization of disk usage.

### 13.11 File watcher

**What:** Watch a directory and auto-refresh on changes (more robust than the current inotify).

### 13.12 Sync indicator

**What:** Show whether a directory is synced (Syncthing, rclone, etc.).

### 13.13 Encryption indicator

**What:** Show whether files are encrypted (GPG, age, etc.).

### 13.14 Checksum verification

**What:** Auto-verify `.sha256` files when present.

### 13.15 License detector

**What:** Detect open-source license in source directories.

---

## 14. Quick-Reference: All Proposed Bindings

### File operations (new)

| binding        | action                   | priority   |
| ---------      | --------                 | ---------- |
| `xd` / `ALT-d` | duplicate                | high       |
| `xH`           | hard link                | medium     |
| `xt`           | touch (update timestamp) | medium     |
| `xs`           | checksum (sha256)        | medium     |
| `xv`           | verify checksums         | medium     |
| `xR`           | rename with pattern      | high       |
| `xn`           | chmod (numeric)          | medium     |
| `xo`           | chown                    | low        |
| `\vd3`         | diff 3 files             | low        |
| `\fsa`         | size analysis            | medium     |

### Selection (new)

| binding   | action                     | priority   |
| --------- | --------                   | ---------- |
| `yi`      | invert selection           | high       |
| `yp`      | select by pattern          | high       |
| `ys`      | select by size             | medium     |
| `yb`      | clipboard (replaces `ytc`) | high       |
| `ys`      | save selection             | medium     |
| `yl`      | load selection             | medium     |
| `v`       | visual selection mode      | high       |

### Navigation (new)

| binding   | action                        | priority   |
| --------- | --------                      | ---------- |
| `ALT-z`   | go back                       | high       |
| `ALT-y`   | go forward                    | high       |
| `gz`      | zoxide jump                   | high       |
| `gr`      | recent files                  | high       |
| `H`       | cd to parent, select previous | medium     |

### Search (new)

| binding   | action              | priority   |
| --------- | --------            | ---------- |
| `rR`      | search & replace    | high       |
| `fm`      | filter by mime type | medium     |
| `ge`      | search by exif      | low        |
| `gbl`     | git blame preview   | medium     |
| `gll`     | git log for file    | medium     |

### Preview (new)

| binding   | action            | priority   |
| --------- | --------          | ---------- |
| `zp`      | pin preview       | high       |
| `zP`      | unpin preview     | high       |
| `zpc`     | compare two files | medium     |
| `zi`      | zoom in           | medium     |
| `zo`      | zoom out          | medium     |
| `zr`      | rotate preview    | medium     |
| `zL`      | live tail         | high       |

### View / UI (new)

| binding   | action             | priority   |
| --------- | --------           | ---------- |
| `F1`      | help               | high       |
| `F2`      | rename             | high       |
| `F3`      | external viewer    | high       |
| `F4`      | edit               | high       |
| `F5`      | copy               | high       |
| `F6`      | move               | high       |
| `F7`      | new directory      | high       |
| `F8`      | delete             | high       |
| `F9`      | toggle preview     | high       |
| `F10`     | quit               | high       |
| `F11`     | fullscreen preview | medium     |
| `F12`     | terminal popup     | medium     |
| `CP`      | command palette    | high       |
| `\thd`    | dark theme         | low        |
| `\thl`    | light theme        | low        |

### Git (new)

| binding   | action        | priority   |
| --------- | --------      | ---------- |
| `gbl`     | blame preview | medium     |
| `gll`     | file log      | medium     |
| `gco`     | checkout file | low        |
| `gst`     | stash         | low        |
| `gsp`     | stash pop     | low        |
| `gbr`     | branch switch | low        |

### Archive (new)

| binding   | action                 | priority   |
| --------- | --------               | ---------- |
| `\fcz`    | compress zip           | medium     |
| `\fc7`    | compress 7z            | low        |
| `\fl`     | list archive           | medium     |
| `\fx`     | extract specific files | low        |

### Shell / Network (new)

| binding   | action       | priority   |
| --------- | --------     | ---------- |
| `\ss`     | SSH to host  | medium     |
| `\fsu`    | SCP upload   | medium     |
| `\fsd`    | SCP download | low        |
| `\frsync` | rsync        | low        |
| `\fdl`    | download URL | medium     |

### Workspace (new)

| binding   | action         | priority   |
| --------- | --------       | ---------- |
| `\ws`     | save workspace | medium     |
| `\wl`     | load workspace | medium     |

### Total new bindings proposed: ~60

These would bring the total from ~281 to ~340. To keep cognitive load manageable, many of these should be leader-prefixed (less common) rather than single-key (frequent).

---

## Summary of Priorities

### High priority (common needs, easy to implement)
1. Duplicate (`xd`)
2. Invert selection (`yi`)
3. Visual selection mode (`v`)
4. Undo/redo navigation (`ALT-z`/`ALT-y`)
5. Zoxide jump (`gz`)
6. Recent files (`gr`)
7. Search & replace (`rR`)
8. Pin preview (`zp`/`zP`)
9. Live tail (`zL`)
10. F1-F10 function key bindings
11. Command palette (`CP`)
12. Clipboard shortcut (`yb`)

### Medium priority (useful, more complex)
1. Pattern rename (`xR`)
2. Checksum (`xs`/`xv`)
3. Select by size (`ys`)
4. Save/load selection (`ys`/`yl`)
5. Git blame/log preview (`gbl`/`gll`)
6. Compare two files (`zpc`)
7. Zoom in/out (`zi`/`zo`)
8. Rotate preview (`zr`)
9. SSH/SCP integration (`\ss`/`\fsu`)
10. Workspace save/load (`\ws`/`\wl`)
11. Size analysis (`\fsa`)
12. URL download (`\fdl`)

### Low priority (niche, complex, or requires external deps)
1. Hard link (`xH`)
2. Touch (`xt`)
3. Numeric chmod (`xn`)
4. Chown (`xo`)
5. Diff 3 files (`\vd3`)
6. Filter by mime (`fm`)
7. Search by exif (`ge`)
8. Git checkout/stash/branch (`gco`/`gst`/`gbr`)
9. Archive conversions (`\fcz`/`\fc7`/`\fl`)
10. Theme switching (`\thd`/`\thl`)
11. Mouse support
12. Built-in tagging (no TMSU)
13. LSP integration
14. Disk usage visualizer

