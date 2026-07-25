# ftl Plugin Ideas: 25 New Plugins + 25 Improvements

> **Subject:** Concrete plugin proposals for ftl, with implementation
> sketches, target APIs, and integration points.
> **Purpose:** Provide contributors with actionable ideas for extending
> ftl, with enough detail to begin implementation immediately.
> **Companion documents:** `ftl-missing-functionality.md` (v1, 42
> implemented), `ftl-missing-functionality-v2.md` (60 proposals),
> `maintenance/07-modification-guide.md` (implementation recipes).
> **Status:** Proposals — not yet implemented.

---

## Table of Contents

1. [25 New Plugin Ideas](#1-25-new-plugin-ideas)
2. [25 Improvements to Existing Plugins](#2-25-improvements-to-existing-plugins)
3. [Implementation Priority](#3-implementation-priority)

---

## 1. 25 New Plugin Ideas

Each idea includes: description, proposed binding, target plugin
category, implementation sketch, dependencies, and integration points.

### 1.1 zoxide integration

**Description:** Jump to a frequently-visited directory using zoxide's
frequency database.

**Binding:** `z`

**Category:** Binding plugin (`bindings/zoxide`)

**Implementation:**
```bash
ftl::plugin::zoxide::jump() {
    local dir
    dir=$(zoxide query -l 2>/dev/null | fzf-tmux -p 50% --reverse --info=inline) || return
    ftl::list::change_dir "$dir"
}
ftl::kbd::bind	ftl	move	"z"	ftl::plugin::zoxide::jump	"zoxide jump"
```

**Dependencies:** `zoxide`, `fzf-tmux`

**Integration:** Calls `ftl::list::change_dir`. No state changes.

---

### 1.2 File type icons (devicons)

**Description:** Display a Nerd Font glyph next to each filename
indicating its type.

**Binding:** `zTi` (cycle to the devicons etag)

**Category:** Etag plugin (`etags/devicons`)

**Implementation:**
```bash
declare -g -A devicon_tags=()

ftl::etag::scan_directory() {
    declare -g -A devicon_tags=()
    local f ext
    while IFS= read -r f ; do
        if [[ -d "$f" ]] ; then
            devicon_tags["$f"]=$'\ue5ff'
        else
            ext="${f##*.}"
            case "$ext" in
                jpg|jpeg|png|gif) devicon_tags["$f"]=$'\ue727' ;;
                pdf)              devicon_tags["$f"]=$'\uf724' ;;
                mp4|mkv|webm)     devicon_tags["$f"]=$'\uf03d' ;;
                mp3|flac|ogg)     devicon_tags["$f"]=$'\uf001' ;;
                zip|tar|gz)       devicon_tags["$f"]=$'\uf410' ;;
                md)               devicon_tags["$f"]=$'\ue609' ;;
                py)               devicon_tags["$f"]=$'\ue73c' ;;
                *)                devicon_tags["$f"]=$'\ue612' ;;
            esac
        fi
    done < <(find "$PWD/" -maxdepth 1 2>/dev/null)
}

ftl::etag::get_entry_tag() {
    local -n r2=$2 r3=$3
    r2="${devicon_tags[$1]:-}"
    r3=1
}
```

**Dependencies:** A Nerd Font installed in the terminal.

**Integration:** Implements the etag contract (`scan_directory` +
`get_entry_tag`). Activated via `zT` or `:etags devicons`.

---

### 1.3 Duplicate file finder

**Description:** Find and list duplicate files (by content hash) as a
virtual list for selection and deletion.

**Binding:** `LEADER f d`

**Category:** Binding plugin (`bindings/find_duplicates`)

**Implementation:**
```bash
ftl::plugin::find_duplicates::run() {
    local hashfile="$ftl_state_session_dir/dups"
    find . -type f -exec md5sum {} + 2>/dev/null \
        | sort \
        | awk 'dups[$1]++ {print $2}' > "$hashfile"

    if [[ ! -s "$hashfile" ]] ; then
        ftl::log::info "no duplicates found"
        ftl::list::render
        return
    fi

    # Tag the duplicates for review
    ftl::sel::clear_all
    local f
    while IFS= read -r f ; do
        ftl::sel::set "$(ftl::util::resolve_full_path "$f")"
    done < "$hashfile"
    ftl::list::render
}
ftl::kbd::bind	ftl	entry	"LEADER f d"	ftl::plugin::find_duplicates::run	"find duplicate files"
```

**Dependencies:** `md5sum`, `find`, `awk`

**Integration:** Tags duplicates with `ftl::sel::set`. User can then
review and delete with `d`.

---

### 1.4 SSH connection manager

**Description:** fzf-list of SSH hosts from `~/.ssh/config` and
`~/.ssh/known_hosts`, connect in a split pane.

**Binding:** `LEADER s s`

**Category:** Binding plugin (`bindings/ssh_manager`)

**Implementation:**
```bash
ftl::plugin::ssh_manager::connect() {
    local hosts
    hosts=$(awk '/^Host / {print $2}' ~/.ssh/config 2>/dev/null)
    hosts+=$(awk '{print $1}' ~/.ssh/known_hosts 2>/dev/null | sort -u)
    local host
    host=$(echo "$hosts" | fzf-tmux -p 30% --reverse) || return
    ftl::pane::split "ssh $host" 50%
}
ftl::kbd::bind	ftl	entry	"LEADER s s"	ftl::plugin::ssh_manager::connect	"SSH connect"
```

**Dependencies:** `fzf-tmux`, `~/.ssh/config` or `~/.ssh/known_hosts`

**Integration:** Uses `ftl::pane::split` to open the SSH session in a
sibling pane.

---

### 1.5 rsync wrapper with dry-run

**Description:** rsync the selection to a remote host with a dry-run
preview, then commit.

**Binding:** `LEADER s r`

**Category:** Binding plugin (`bindings/rsync_upload`)

**Implementation:**
```bash
ftl::plugin::rsync_upload::run() {
    ftl::cmd::prompt "rsync to (host:path): "
    local target="$REPLY"
    [[ -n "$target" ]] || { ftl::list::render ; return ; }

    # Dry run
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "rsync -avn --progress ${ftl_selection_current[*]@Q} '$target' ; read -sn 1"

    ftl::cmd::prompt "commit? [y|N]" -sn1
    [[ "$REPLY" == y ]] || { ftl::list::render ; return ; }

    rsync -av --progress "${ftl_selection_current[@]}" "$target"
    ftl::list::render
}
ftl::kbd::bind	ftl	entry	"LEADER s r"	ftl::plugin::rsync_upload::run	"rsync upload"
```

**Dependencies:** `rsync`

**Integration:** Uses `ftl::cmd::prompt` for input, `ftl::pane::split_for_preview`
for the dry-run output.

---

### 1.6 Live content search (incremental ripgrep)

**Description:** Incremental content search — type a query and the
listing filters to files containing matches, live as you type.

**Binding:** `\g i`

**Category:** Binding plugin with sub-mode handler (`bindings/live_content_search`)

**Implementation:**
```bash
ftl::plugin::live_content_search::enter() {
    ftl_kbd_submode_handler=ftl::plugin::live_content_search::dispatch
    ftl_plugin_live_content_search_query=
    ftl::list::render
}

ftl::plugin::live_content_search::dispatch() {
    local key="$ftl_kbd_current_key"
    case "$key" in
        ESCAPE)
            ftl_kbd_submode_handler=
            ftl_filter_active_glyph=
            ftl::list::change_dir
            ;;
        BACKSPACE)
            ftl_plugin_live_content_search_query="${ftl_plugin_live_content_search_query:0:-1}"
            ftl::plugin::live_content_search::apply
            ;;
        *)
            if [[ "$key" =~ ^[ -~]$ ]] ; then
                ftl_plugin_live_content_search_query+="$key"
                ftl::plugin::live_content_search::apply
            fi
            ;;
    esac
}

ftl::plugin::live_content_search::apply() {
    # Get matching files from rg, set as virtual list
    local q="$ftl_plugin_live_content_search_query"
    [[ -z "$q" ]] && { ftl::list::change_dir ; return ; }

    ftl_plugin_vfiles=()
    local f
    while IFS= read -r f ; do
        ftl_plugin_vfiles["$f"]=1
    done < <(rg -l "$q" "$PWD" 2>/dev/null)
    ftl::plugin::virtual::enable
    ftl_filter_active_glyph="🔍"
    ftl::list::render
}
ftl::kbd::bind	ftl	find	"\g i"	ftl::plugin::live_content_search::enter	"incremental content search"
```

**Dependencies:** `rg` (ripgrep)

**Integration:** Sets `ftl_kbd_submode_handler` (sub-mode pattern).
Uses the virtual entries framework to display matching files.

---

### 1.7 Image EXIF sidebar viewer

**Description:** When previewing an image, show a sidebar with EXIF
data (camera, lens, ISO, aperture, GPS).

**Binding:** `zei`

**Category:** Binding plugin (`bindings/exif_sidebar`)

**Implementation:**
```bash
ftl::plugin::exif_sidebar::toggle() {
    local lockdir="$ftl_state_session_dir/lock_preview"
    if [[ -f "$lockdir/exif_sidebar" ]] ; then
        rm -f "$lockdir/exif_sidebar"
    else
        : > "$lockdir/exif_sidebar"
    fi
    ftl::list::render
}

ftl::plugin::exif_sidebar::show() {
    [[ -f "$ftl_state_session_dir/lock_preview/exif_sidebar" ]] || return 1
    [[ $ftl_state_current_extension =~ jpg|jpeg|png|tiff ]] || return 1
    exiftool "$ftl_state_current_path" | ftl::pane::split_for_preview "cat ; read -sn 100"
}
ftl::kbd::bind	ftl	view	"zei"	ftl::plugin::exif_sidebar::toggle	"toggle EXIF sidebar"
```

**Dependencies:** `exiftool`

**Integration:** Hook into `ftl::prev::dispatch` (or wrap
`pviewers`) to call `show` when the sidebar is enabled.

---

### 1.8 Code syntax highlighting (bat)

**Description:** Preview text/code files with syntax highlighting via
`bat`.

**Binding:** `zc` (toggle)

**Category:** Viewer enhancement (wrap `ptext` in `viewers/core`)

**Implementation:**
```bash
# In a new viewer plugin, or by modifying viewers/core:

ftl::plugin::core::ptext_bat() {
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "bat --paging=always --style=plain '${ftl_state_current_path@Q}' ; read -sn 100"
}

# Override ptext to use bat when the toggle is on
ftl::plugin::core::ptext_orig() { ftl::plugin::core::ptext ; }
ftl::plugin::core::ptext() {
    [[ -f "$ftl_state_session_dir/bat_toggle" ]] \
        && { ftl::plugin::core::ptext_bat ; return ; }
    ftl::plugin::core::ptext_orig
}
```

**Dependencies:** `bat`

---

### 1.9 PDF page navigation

**Description:** When previewing a PDF, navigate pages with `j`/`k`.

**Binding:** `j` / `k` (in PDF preview sub-mode)

**Category:** Sub-mode handler (`bindings/pdf_nav`)

**Implementation:**
```bash
declare -g ftl_plugin_pdf_nav_page=1

ftl::plugin::pdf_nav::enter() {
    [[ $ftl_state_current_extension != pdf ]] && return
    ftl_kbd_submode_handler=ftl::plugin::pdf_nav::dispatch
    ftl_plugin_pdf_nav_page=1
    ftl::plugin::pdf_nav::render
}

ftl::plugin::pdf_nav::dispatch() {
    case "$ftl_kbd_current_key" in
        j|DOWN)  ((ftl_plugin_pdf_nav_page++)) ; ftl::plugin::pdf_nav::render ;;
        k|UP)    ((ftl_plugin_pdf_nav_page > 1)) && ((ftl_plugin_pdf_nav_page--)) ; ftl::plugin::pdf_nav::render ;;
        ESCAPE)  ftl_kbd_submode_handler= ; ftl::list::render ;;
    esac
}

ftl::plugin::pdf_nav::render() {
    ftl::prev::clear
    local tmp="$ftl_state_session_dir/pdf_page.png"
    pdftoppm -png -r 150 -f $ftl_plugin_pdf_nav_page -l $ftl_plugin_pdf_nav_page \
        "$ftl_state_current_path" "$tmp" 2>/dev/null
    ftl::prev::show_image "$tmp"
}
```

**Dependencies:** `pdftoppm` (poppler-utils)

---

### 1.10 Trash / restore

**Description:** Move deleted files to `~/.local/share/Trash` (XDG
spec) instead of removing them. Restore with an fzf list.

**Binding:** `U` (restore)

**Category:** Binding plugin (`bindings/trash`)

**Implementation:**
```bash
ftl::plugin::trash::restore() {
    local trashdir=~/.local/share/Trash/files
    [[ -d "$trashdir" ]] || { ftl::log::warn "no trash" ; return ; }

    local f
    f=$(find "$trashdir" -maxdepth 1 -type f | fzf-tmux -p 50%) || return

    # Read original path from .trashinfo
    local base="${f##*/}"
    local infofile=~/.local/share/Trash/info/"$base".trashinfo
    local origpath
    origpath=$(grep "^Path=" "$infofile" 2>/dev/null | cut -d= -f2- | sed 's/%20/ /g')

    if [[ -n "$origpath" ]] ; then
        mv "$f" "$origpath"
        rm -f "$infofile"
        ftl::log::info "restored to $origpath"
    else
        mv "$f" "$PWD"
        ftl::log::info "restored to $PWD"
    fi
    ftl::list::change_dir
}
ftl::kbd::bind	ftl	entry	"U"	ftl::plugin::trash::restore	"restore from trash"
```

**Dependencies:** `fzf-tmux`, XDG trash directory

---

### 1.11 Directory tree view

**Description:** Toggle between the flat listing and a tree view (like
`tree` but interactive — expand/collapse dirs with `Enter`).

**Binding:** `zt`

**Category:** Listing mode enhancement

**Implementation:** This is a larger feature. Sketch:

```bash
ftl::plugin::tree_view::toggle() {
    if [[ -n "$ftl_plugin_tree_view_active" ]] ; then
        ftl_plugin_tree_view_active=
        ftl::list::change_dir
    else
        ftl_plugin_tree_view_active=1
        ftl::plugin::tree_view::render
    fi
}

ftl::plugin::tree_view::render() {
    # Run tree -J (JSON), parse into ftl_list_entries with indentation
    local tmp="$ftl_state_session_dir/tree.json"
    tree -J "$PWD" > "$tmp"
    # Parse JSON (use jq or awk), populate ftl_list_entries
    # ...
    ftl::list::render
}
ftl::kbd::bind	ftl	view	"zt"	ftl::plugin::tree_view::toggle	"toggle tree view"
```

**Dependencies:** `tree` (with JSON output), `jq` (for parsing)

---

### 1.12 Frecency-based directory jump

**Description:** Built-in frecency (frequency + recency) tracking,
jump to the best match for a query.

**Binding:** `LEADER f`

**Category:** Binding plugin (`bindings/frecency`)

**Implementation:**
```bash
declare -gA ftl_plugin_frecency_scores=()
declare -g ftl_plugin_frecency_file="$FTL_STATE_DIR/frecency"

ftl::plugin::frecency::record() {
    [[ -f "$ftl_plugin_frecency_file" ]] && source "$ftl_plugin_frecency_file"
    local now=$(date +%s)
    local p="$PWD"
    local score=${ftl_plugin_frecency_scores[$p]:-0}
    # Frecency: visits * recency_decay
    score=$((score + 1))
    ftl_plugin_frecency_scores[$p]=$score
    # Save
    declare -p ftl_plugin_frecency_scores > "$ftl_plugin_frecency_file"
}

ftl::plugin::frecency::jump() {
    [[ -f "$ftl_plugin_frecency_file" ]] && source "$ftl_plugin_frecency_file"
    ftl::cmd::prompt "jump to: "
    local q="$REPLY"
    [[ -n "$q" ]] || return

    local best="" best_score=0
    for p in "${!ftl_plugin_frecency_scores[@]}" ; do
        [[ "$p" == *"$q"* ]] || continue
        if (( ${ftl_plugin_frecency_scores[$p]} > best_score )) ; then
            best="$p"
            best_score=${ftl_plugin_frecency_scores[$p]}
        fi
    done
    [[ -n "$best" ]] && ftl::list::change_dir "$best"
}
ftl::kbd::bind	ftl	move	"LEADER f"	ftl::plugin::frecency::jump	"frecency jump"
```

**Integration:** Call `ftl::plugin::frecency::record` from
`ftl::list::change_dir` (or hook into the directory-change event).

---

### 1.13 Workspace autosave

**Description:** Automatically save the current workspace (tabs,
selection, cursor positions) on a timer, and restore on startup.

**Binding:** Automatic (no key)

**Category:** Time-event handler + binding plugin

**Implementation:**
```bash
ftl::plugin::workspace_autosave::init() {
    ftl_time_handlers[workspace_autosave]="60:0"  # every 60 seconds
}

ftl::plugin::workspace_autosave::tick() {
    local ws="$FTL_STATE_DIR/autosave"
    mkdir -p "$ws"
    printf '%s\n' "${ftl_tab_directories[@]}" > "$ws/tabs"
    echo "$ftl_state_current_tab_index" > "$ws/active_tab"
    declare -p ftl_selection_tags > "$ws/selection" 2>/dev/null
}
```

**Integration:** Register with `ftl::time::tick`. Restore in `ftl_setup`
if the autosave file exists.

---

### 1.14 Notification on long operations

**Description:** Send a desktop notification when a long operation
(rsync, large copy, archive creation) completes.

**Binding:** Automatic (config flag)

**Category:** Configuration + wrapper

**Implementation:**
```bash
ftl_cfg_notify_on_long_ops=1
ftl_cfg_long_op_threshold=5  # seconds

ftl::plugin::notify::wrap() {
    local start=$(date +%s)
    "$@"
    local elapsed=$(( $(date +%s) - start ))
    if (( ftl_cfg_notify_on_long_ops && elapsed > ftl_cfg_long_op_threshold )) ; then
        notify-send "ftl" "operation complete (${elapsed}s)"
    fi
}
```

**Integration:** Wrap long-running commands with
`ftl::plugin::notify::wrap`.

---

### 1.15 File metadata editor

**Description:** Edit EXIF/IPTC tags for images, ID3 tags for audio,
in a tmux popup with editable fields.

**Binding:** `LEADER m e`

**Category:** Binding plugin (`bindings/metadata_editor`)

**Implementation:**
```bash
ftl::plugin::metadata_editor::edit() {
    local f="$ftl_state_current_path"
    local tmp="$ftl_state_session_dir/metadata.txt"

    case "$ftl_state_current_extension" in
        jpg|jpeg|png|tiff)
            exiftool -s "$f" > "$tmp"
            $ftl_cfg_editor "$tmp"
            # Parse edits and apply
            # ...
            ;;
        mp3|flac)
            # Use id3v2 or eyeD3
            ;;
    esac
    ftl::list::render
}
ftl::kbd::bind	ftl	entry	"LEADER m e"	ftl::plugin::metadata_editor::edit	"edit metadata"
```

**Dependencies:** `exiftool`, `$EDITOR`

---

### 1.16 Visual block selection

**Description:** Select a rectangular block of entries (e.g. all
`.txt` files between rows 5 and 15).

**Binding:** `LEADER v b`

**Category:** Binding plugin extending `visual_mode`

**Implementation:** Extend `ftl::plugin::missing::visual_mode` to
accept a pattern. Tag only entries matching the pattern within the
range.

---

### 1.17 Selection by content (ripgrep)

**Description:** Select all files whose contents match a regex.

**Binding:** `yr`

**Category:** Binding plugin (`bindings/select_by_content`)

**Implementation:**
```bash
ftl::plugin::select_by_content::run() {
    ftl::cmd::prompt "content pattern: "
    local pat="$REPLY"
    [[ -n "$pat" ]] || { ftl::list::render ; return ; }

    local f
    while IFS= read -r f ; do
        ftl::sel::set "$(ftl::util::resolve_full_path "$f")"
    done < <(rg -l "$pat" "$PWD" 2>/dev/null)
    ftl::list::render
}
ftl::kbd::bind	ftl	selection	"yr"	ftl::plugin::select_by_content::run	"select by content"
```

**Dependencies:** `rg`

---

### 1.18 Selection by age (mtime)

**Description:** Select files modified within the last N days.

**Binding:** `ya`

**Category:** Binding plugin

**Implementation:**
```bash
ftl::plugin::select_by_age::run() {
    ftl::cmd::prompt "max age (days): "
    local days="$REPLY"
    [[ "$days" =~ ^[0-9]+$ ]] || { ftl::list::render ; return ; }

    local f
    while IFS= read -r f ; do
        ftl::sel::set "$(ftl::util::resolve_full_path "$f")"
    done < <(find "$PWD" -maxdepth 1 -type f -mtime "-$days")
    ftl::list::render
}
ftl::kbd::bind	ftl	selection	"ya"	ftl::plugin::select_by_age::run	"select by age"
```

---

### 1.19 Hex dump preview

**Description:** Preview binary files as a hex dump (`xxd` or
`hexdump -C`).

**Binding:** `zh`

**Category:** Viewer function (`phex`)

**Implementation:**
```bash
ftl::plugin::core::phex() {
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "hexdump -C '${ftl_state_current_path@Q}' | $ftl_cfg_markdown_pager ; read -sn 100"
}
# Add to pviewers:
# [[ $ftl_state_current_extension == bin ]] && { ftl::plugin::core::phex ; return ; }
```

**Dependencies:** `hexdump` (bsdmainutils) or `xxl`

---

### 1.20 Git conflict resolver

**Description:** List files with merge conflicts, open each in
`$EDITOR` for resolution.

**Binding:** `LEADER g c`

**Category:** Binding plugin (`bindings/git_conflict_resolver`)

**Implementation:**
```bash
ftl::plugin::git_conflict_resolver::run() {
    git rev-parse HEAD &>/dev/null || { ftl::log::warn "not a git repo" ; return ; }

    local conflicts
    conflicts=$(git diff --name-only --diff-filter=U 2>/dev/null)
    [[ -n "$conflicts" ]] || { ftl::log::info "no conflicts" ; return ; }

    local f
    f=$(echo "$conflicts" | fzf-tmux -p 30% -m) || return
    $ftl_cfg_editor $f
    ftl::list::change_dir
}
ftl::kbd::bind	ftl	find	"LEADER g c"	ftl::plugin::git_conflict_resolver::run	"resolve merge conflicts"
```

**Dependencies:** `git`, `fzf-tmux`, `$EDITOR`

---

### 1.21 Cloud storage mount (rclone)

**Description:** Mount WebDAV, S3, Google Drive, etc. via rclone and
browse.

**Binding:** `LEADER s c`

**Category:** Binding plugin (`bindings/cloud_mount`)

**Implementation:**
```bash
ftl::plugin::cloud_mount::mount() {
    local remotes
    remotes=$(rclone listremotes 2>/dev/null) || { ftl::log::warn "rclone not configured" ; return ; }
    local remote
    remote=$(echo "$remotes" | fzf-tmux -p 30%) || return

    local mnt="$HOME/mnt${remote%:}"
    mkdir -p "$mnt"
    rclone mount "$remote" "$mnt" --daemon 2>/dev/null
    sleep 1
    ftl::list::change_dir "$mnt"
}
ftl::kbd::bind	ftl	entry	"LEADER s c"	ftl::plugin::cloud_mount::mount	"mount cloud storage"
```

**Dependencies:** `rclone`, FUSE

---

### 1.22 SFTP browse (sshfs)

**Description:** Mount a remote SFTP server via sshfs and browse as a
local directory.

**Binding:** `LEADER s f`

**Category:** Binding plugin

**Implementation:**
```bash
ftl::plugin::sftp_browse::mount() {
    local hosts
    hosts=$(awk '/^Host / {print $2}' ~/.ssh/config 2>/dev/null)
    local host
    host=$(echo "$hosts" | fzf-tmux -p 30%) || return

    ftl::cmd::prompt "remote path: " -i "~"
    local rpath="$REPLY"

    local mnt="$HOME/mnt/$host"
    mkdir -p "$mnt"
    sshfs "$host:$rpath" "$mnt" 2>/dev/null
    ftl::list::change_dir "$mnt"
}
ftl::kbd::bind	ftl	entry	"LEADER s f"	ftl::plugin::sftp_browse::mount	"SFTP mount"
```

**Dependencies:** `sshfs`, FUSE, `fzf-tmux`

---

### 1.23 Operation log viewer

**Description:** A persistent log of all file operations (delete,
move, rename, chmod) performed by ftl, viewable with `:show_op_log`.

**Binding:** `:show_op_log`

**Category:** Command (`commands/show_op_log`) + logging hooks

**Implementation:**
```bash
# In commands/show_op_log:
[[ -f "$FTL_STATE_DIR/op_log" ]] && tmux popup -w 80% -h 80% $ftl_cfg_markdown_pager "$FTL_STATE_DIR/op_log"

# Hook into mutating commands (e.g. in a wrapper):
ftl::plugin::op_log::record() {
    local op="$1"
    local ts=$(date -R)
    echo "[$ts] $op: ${ftl_selection_current[*]}" >> "$FTL_STATE_DIR/op_log"
}
```

---

### 1.24 Undo / redo for file operations

**Description:** Undo the last file operation (delete, move, rename).
Redo re-applies it.

**Binding:** `u` (undo), `CTL-r` (redo)

**Category:** Binding plugin with state tracking

**Implementation:**
```bash
declare -ga ftl_plugin_undo_stack=()
declare -ga ftl_plugin_redo_stack=()

ftl::plugin::undo::record() {
    local inverse="$1"
    ftl_plugin_undo_stack+=("$inverse")
    ftl_plugin_redo_stack=()  # clear redo on new op
}

ftl::plugin::undo::undo() {
    (( ${#ftl_plugin_undo_stack[@]} )) || return
    local inverse="${ftl_plugin_undo_stack[-1]}"
    unset 'ftl_plugin_undo_stack[-1]'
    ftl_plugin_redo_stack+=("$inverse")
    eval "$inverse"
    ftl::list::change_dir
}

ftl::plugin::undo::redo() {
    (( ${#ftl_plugin_redo_stack[@]} )) || return
    local op="${ftl_plugin_redo_stack[-1]}"
    unset 'ftl_plugin_redo_stack[-1]'
    ftl_plugin_undo_stack+=("$op")
    eval "$op"
    ftl::list::change_dir
}
ftl::kbd::bind	ftl	entry	"u"	ftl::plugin::undo::undo	"undo"
ftl::kbd::bind	ftl	entry	"CTL-r"	ftl::plugin::undo::redo	"redo"
```

**Integration:** Wrap mutating commands (`delete_selection`,
`move_selection_here`, `rename_selection`, etc.) to call
`ftl::plugin::undo::record` with the inverse operation.

---

### 1.25 Tab naming

**Description:** Name tabs (displayed in the tab bar) instead of just
numbers.

**Binding:** `LEADER T`

**Category:** Binding plugin + `tab.sh` enhancement

**Implementation:**
```bash
declare -ga ftl_tab_names=()

ftl::plugin::tab_name::set() {
    ftl::cmd::prompt "tab name: " -i "${ftl_tab_names[$ftl_state_current_tab_index]:-}"
    [[ -n "$REPLY" ]] && ftl_tab_names[$ftl_state_current_tab_index]="$REPLY"
    ftl::list::render
}
ftl::kbd::bind	ftl	ftl	"LEADER T"	ftl::plugin::tab_name::set	"name current tab"
```

Modify `_ftl::list::render_header` to display `ftl_tab_names[$tab]` if
set.

---

## 2. 25 Improvements to Existing Plugins

### Git-Focused Improvements (1–10)

#### 2.1 Git status etag — show ahead/behind count

**Existing:** `etags/git` shows `M`, `A`, `??` per file.

**Improvement:** Add ahead/behind branch indicator (e.g. `↑2↓1`) to
the etag column when the local branch is ahead/behind the remote.

**Implementation:**
```bash
# In etags/git, during scan_directory:
local ahead_behind
ahead_behind=$(git rev-list --left-right --count @{u}...HEAD 2>/dev/null)
# ahead_behind is "behind\tahead"
if [[ -n "$ahead_behind" ]] ; then
    local behind=${ahead_behind%$'\t'*}
    local ahead=${ahead_behind#*$'\t'}
    (( ahead > 0 )) && git_branch_glyph+="↑$ahead"
    (( behind > 0 )) && git_branch_glyph+="↓$behind"
fi
```

---

#### 2.2 Git blame preview — show commit date and author

**Existing:** `git_blame_preview` shows raw `git blame` output.

**Improvement:** Format the output to show only commit date, author,
and the line content (not the full commit hash). Use `--line-porcelain`
and parse.

**Implementation:**
```bash
ftl::plugin::missing::git_blame_preview() {
    [[ -f "$ftl_state_current_path" ]] || return 0
    git rev-parse HEAD &>/dev/null || return 0
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "git blame --date=short --format='%an %ad | ' '$ftl_state_current_path' | $ftl_cfg_markdown_pager ; read -sn 100"
}
```

---

#### 2.3 Git file log — show diff for selected commit

**Existing:** `git_file_log` shows `git log --oneline --follow`.

**Improvement:** After showing the log, allow the user to select a
commit and view its diff for the file. Use fzf with a preview pane.

**Implementation:**
```bash
ftl::plugin::missing::git_file_log() {
    [[ -f "$ftl_state_current_path" ]] || return 0
    git rev-parse HEAD &>/dev/null || return 0
    ftl::prev::clear

    local commit
    commit=$(git log --oneline --follow "$ftl_state_current_path" 2>/dev/null \
        | fzf-tmux -p 60% --preview \
            "git show --stat {1} -- '$ftl_state_current_path'") || return

    ftl::pane::split_for_preview \
        "git show ${commit%% *} -- '$ftl_state_current_path' | $ftl_cfg_markdown_pager ; read -sn 100"
}
```

---

#### 2.4 Git diff stat — scope to selection

**Existing:** `git_diff_stat` shows `git diff --stat` for the whole
repo.

**Improvement:** If files are selected, scope the diff to the
selection. Otherwise, show the whole repo.

**Implementation:**
```bash
ftl::plugin::missing::git_diff_stat() {
    git rev-parse HEAD &>/dev/null || return 0
    ftl::prev::clear
    local args=()
    if (( ${#ftl_selection_current[@]} )) ; then
        args=("${ftl_selection_current[@]}")
    fi
    ftl::pane::split_for_preview \
        "git diff --stat -- ${args[*]@Q} | $ftl_cfg_markdown_pager ; read -sn 100"
}
```

---

#### 2.5 Git branch switcher

**Existing:** No git branch switching binding.

**Improvement:** Add `LEADER g b` to fzf-list branches and checkout.

**Implementation:**
```bash
ftl::plugin::git_branch::switch() {
    git rev-parse HEAD &>/dev/null || return 0
    local branch
    branch=$(git branch --format='%(refname:short)' 2>/dev/null \
        | fzf-tmux -p 30% --preview "git log --oneline {} | head -20") || return
    git checkout "$branch"
    ftl::list::change_dir
}
ftl::kbd::bind	ftl	find	"LEADER g b"	ftl::plugin::git_branch::switch	"git branch switch"
```

---

#### 2.6 Git stash manager

**Existing:** No git stash management.

**Improvement:** Add `LEADER g t` to list, apply, drop, pop stashes
via fzf.

**Implementation:**
```bash
ftl::plugin::git_stash::manage() {
    git rev-parse HEAD &>/dev/null || return 0
    local stash
    stash=$(git stash list 2>/dev/null | fzf-tmux -p 40%) || return
    local ref="${stash%%:*}"

    local action
    action=$(printf "apply\ndrop\npop\n" | fzf-tmux -p 20%) || return

    case "$action" in
        apply) git stash apply "$ref" ;;
        drop)  git stash drop "$ref" ;;
        pop)   git stash pop "$ref" ;;
    esac
    ftl::list::change_dir
}
ftl::kbd::bind	ftl	find	"LEADER g t"	ftl::plugin::git_stash::manage	"git stash manager"
```

---

#### 2.7 Git log graph

**Existing:** `git_file_log` shows log for a single file.

**Improvement:** Add `LEADER g l` to show the full repo log graph
(`git log --graph --oneline --all`) in the preview pane.

**Implementation:**
```bash
ftl::plugin::git_log_graph::show() {
    git rev-parse HEAD &>/dev/null || return 0
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "git log --graph --oneline --all --decorate | $ftl_cfg_markdown_pager ; read -sn 100"
}
ftl::kbd::bind	ftl	find	"LEADER g l"	ftl::plugin::git_log_graph::show	"git log graph"
```

---

#### 2.8 Git status pane (persistent)

**Existing:** `git_diff_stat` shows a one-shot diff.

**Improvement:** Add `LEADER g s` to toggle a persistent pane showing
`git status -s`, refreshing on directory change.

**Implementation:**
```bash
ftl::plugin::git_status_pane::toggle() {
    if ftl::pane::window_exists "git_status" ; then
        tmux kill-window -t "git_status"
    else
        tmux new-window -n "git_status" -d \
            "watch -c -n 5 'git -C $PWD status -s 2>/dev/null || echo \"not a git repo\"'"
    fi
}
ftl::kbd::bind	ftl	find	"LEADER g s"	ftl::plugin::git_status_pane::toggle	"toggle git status pane"
```

---

#### 2.9 Git stage/unstage from ftl

**Existing:** No git staging from ftl.

**Improvement:** Tag files, then press `LEADER g a` to `git add`, or
`LEADER g r` to `git reset` (unstage).

**Implementation:**
```bash
ftl::plugin::git_stage::add() {
    git rev-parse HEAD &>/dev/null || return 0
    (( ${#ftl_selection_current[@]} )) || { ftl::log::warn "no selection" ; return ; }
    git add "${ftl_selection_current[@]}"
    ftl::log::info "staged ${#ftl_selection_current[@]} files"
    ftl::list::render
}
ftl::plugin::git_stage::unstage() {
    git rev-parse HEAD &>/dev/null || return 0
    (( ${#ftl_selection_current[@]} )) || return
    git reset -- "${ftl_selection_current[@]}"
    ftl::log::info "unstaged ${#ftl_selection_current[@]} files"
    ftl::list::render
}
ftl::kbd::bind	ftl	find	"LEADER g a"	ftl::plugin::git_stage::add	"git add selection"
ftl::kbd::bind	ftl	find	"LEADER g r"	ftl::plugin::git_stage::unstage	"git reset selection"
```

---

#### 2.10 Git commit from ftl

**Existing:** No git commit from ftl.

**Improvement:** Add `LEADER g c` to open `$EDITOR` for a commit
message and commit the staged changes.

**Implementation:**
```bash
ftl::plugin::git_commit::commit() {
    git rev-parse HEAD &>/dev/null || return 0
    local msgfile="$ftl_state_session_dir/COMMIT_EDITMSG"
    $ftl_cfg_editor "$msgfile"
    [[ -s "$msgfile" ]] || { ftl::log::warn "empty commit message" ; return ; }
    git commit -F "$msgfile"
    ftl::log::info "committed"
    ftl::list::change_dir
}
ftl::kbd::bind	ftl	find	"LEADER g c"	ftl::plugin::git_commit::commit	"git commit"
```

---

### General Improvements (11–25)

#### 2.11 duplicate — preserve directory structure

**Existing:** `ftl::plugin::missing::duplicate` copies files with
`_copy<N>` suffix.

**Improvement:** Add an option to duplicate into a subdirectory
(`_copies/`) to keep the source directory clean.

---

#### 2.12 hardlink — allow specifying target directory

**Existing:** `hardlink` creates links in `$PWD` only.

**Improvement:** Prompt for a target directory (fzf-selected) and
create links there.

---

#### 2.13 rename_pattern — preview before applying

**Existing:** `rename_pattern` applies the sed pattern immediately.

**Improvement:** Show a preview of old → new names, prompt for
confirmation, then apply.

---

#### 2.14 selection_invert — preserve class glyphs

**Existing:** `selection_invert` tags all untagged entries with the
default glyph `▪`.

**Improvement:** Preserve the original class glyphs of the previously-
tagged entries (so re-inverting restores them).

---

#### 2.15 select_by_pattern — case-insensitive option

**Existing:** `select_by_pattern` uses `[[ "$name" =~ $pattern ]]`
(case-sensitive).

**Improvement:** Add a config flag `ftl_cfg_pattern_case_insensitive=1`
that converts both to lowercase before matching.

---

#### 2.16 preview_pin — show pin indicator in header

**Existing:** `preview_pin` creates a lock file but gives no visual
feedback in the listing.

**Improvement:** Set a header glyph (e.g. `📌`) when a pin is active.
Modify `_ftl::list::render_header` to check for the lock file.

---

#### 2.17 preview_zoom_in/out — show zoom level

**Existing:** `preview_zoom_in/out` adjust `ftl_plugin_missing_preview_zoom`
silently.

**Improvement:** Display the current zoom level in the header (e.g.
`zoom:3`).

---

#### 2.18 preview_tail_live — support more extensions

**Existing:** `preview_tail_live` matches `log|out|err`.

**Improvement:** Add `txt` (when the file is large), `json` (for live
JSON logs), and a config variable `ftl_cfg_tail_extensions` for
user-defined extensions.

---

#### 2.19 command_palette — show keybinding alongside command

**Existing:** `command_palette` shows command names in fzf.

**Improvement:** Show the keybinding alongside each command (e.g.
`ftl::cmd::cursor_down [j]`), so the user learns bindings while using
the palette.

---

#### 2.20 workspace_save — save cursor positions per directory

**Existing:** `workspace_save` saves tabs, active tab, and selection.

**Improvement:** Also save `ftl_state_cursor_memory` (the per-tab,
per-directory cursor positions) so a restored workspace puts the
cursor back where it was.

---

#### 2.21 compress_zip — set compression level

**Existing:** `compress_zip` uses default compression.

**Improvement:** Prompt for compression level (0=store, 6=default,
9=max) and pass `-$level` to `zip`.

---

#### 2.22 archive_list — support .7z

**Existing:** `archive_list` handles zip, rar, tar, gz, bz2, xz.

**Improvement:** Add `7z` case using `7z l`.

---

#### 2.23 scp_upload — show progress

**Existing:** `scp_upload` runs scp with no progress feedback.

**Improvement:** Use `scp -v` and pipe to a split pane so the user
sees progress.

---

#### 2.24 download_url — support multiple URLs

**Existing:** `download_url` downloads a single URL.

**Improvement:** Accept space-separated URLs and download all in
parallel with `xargs -P`.

---

#### 2.25 inline_rename — undo last rename

**Existing:** `inline_rename` tracks `ftl_inline_rename_history` but
does not expose an undo.

**Improvement:** Add `LEADER r u` to undo the last rename from the
history array (mv the file back).

---

## 3. Implementation Priority

### High priority (high impact, low effort)

1. **1.1** zoxide integration — single function, no state
2. **1.10** Trash / restore — single function, file-based
3. **1.17** Selection by content — single function, uses `rg`
4. **1.18** Selection by age — single function, uses `find`
5. **1.19** Hex dump preview — single viewer function
6. **2.1** Git etag ahead/behind — small etag enhancement
7. **2.4** Git diff stat scoped to selection — small change
8. **2.5** Git branch switcher — single function
9. **2.7** Git log graph — single function
10. **2.9** Git stage/unstage — two small functions
11. **2.10** Git commit — single function
12. **2.22** archive_list .7z support — one case
13. **2.13** rename_pattern preview — moderate
14. **2.20** workspace_save cursor positions — moderate

### Medium priority (high impact, medium effort)

15. **1.2** File type icons (devicons) — etag plugin, moderate
16. **1.3** Duplicate file finder — moderate
17. **1.4** SSH connection manager — moderate
18. **1.5** rsync wrapper — moderate
19. **1.7** Image EXIF sidebar — moderate
20. **1.8** Code syntax highlighting (bat) — viewer enhancement
21. **1.20** Git conflict resolver — moderate
22. **1.21** Cloud storage mount — moderate
23. **1.22** SFTP browse — moderate
24. **1.23** Operation log viewer — moderate
25. **1.25** Tab naming — moderate
26. **2.6** Git stash manager — moderate
27. **2.8** Git status pane — moderate
28. **2.16** preview_pin header indicator — moderate
29. **2.19** command_palette keybinding display — moderate

### Low priority (high effort or lower impact)

30. **1.6** Live content search — sub-mode handler, complex
31. **1.9** PDF page navigation — sub-mode, complex
32. **1.11** Directory tree view — large feature
33. **1.12** Frecency jump — state tracking, complex
34. **1.13** Workspace autosave — time events, state
35. **1.14** Notification on long ops — wrapping, config
36. **1.15** File metadata editor — large
37. **1.16** Visual block selection — extends visual_mode
38. **1.24** Undo/redo — large, touches many commands
39. **2.3** Git file log with diff — fzf preview, complex
40. **2.11–2.15, 2.17, 2.18, 2.21, 2.23, 2.24, 2.25** — various

### Recommended first batch for new contributors

The following 5 improvements are ideal for a new contributor to
tackle, as they are well-scoped, touch a single file, and have clear
acceptance criteria:

1. **2.22** archive_list .7z support (one case statement)
2. **2.4** Git diff stat scoped to selection (one conditional)
3. **2.7** Git log graph (one new function + binding)
4. **1.18** Selection by age (one new binding plugin)
5. **2.10** Git commit (one new function + binding)

Each can be implemented in under 30 lines of code, with 2–3 tests,
and committed as a single PR.
