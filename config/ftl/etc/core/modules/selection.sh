# selection.sh — selection (tag) management
#
# Manages the selection: a set of tagged file paths. Each tag has a glyph
# indicating its class (▪ default, ¹²³D for classes 1-4). The selection
# is synchronized between panes via a revision counter.
#
# Public functions:
#   ftl::sel::resolve_current      — build ftl_selection_current from tags
#   ftl::sel::clear_all            — clear the entire selection
#   ftl::sel::flip                 — toggle a tag on/off
#   ftl::sel::set                  — set a tag (if not already set)
#   ftl::sel::unset                — unset a tag (if set)
#   ftl::sel::unset_by_class       — unset all tags with a given class
#   ftl::sel::validate_existence   — remove tags for non-existent files
#   ftl::sel::prompt_for_class     — ask user which class to operate on
#   ftl::sel::build_class_index    — build inverted index of classes
#   ftl::sel::get_by_class         — get tags matching a class into a nameref
#   ftl::sel::goto_by_index        — navigate to the Nth tagged file
#   ftl::sel::fzf_tag_or_untag     — tag or untag files from fzf output
#   ftl::sel::sync_from_other_pane — sync selection from another pane
#   ftl::sel::load_from_file       — load selection from a file of paths
#   ftl::sel::adjust_total_size    — adjust ftl_selection_total_bytes
#   ftl::sel::format_header_summary — format "count/size" for the header
#
# Globals:
#   ftl_selection_tags             — assoc array: path → glyph (was: tags)
#   ftl_selection_current          — indexed array: resolved selection (was: selection)
#   ftl_selection_total_bytes      — total size of selected files (was: tags_size var)
#   ftl_selection_revision         — monotonic counter (was: stagsi)
#   ftl_selection_other_revision   — other pane's counter (was: ostagsi)
#   ftl_selection_class_cursor     — position for next/prev tag nav (was: ctag)
#   ftl_selection_class_index      — inverted index: class → 1 (was: ntags)

# Build the ftl_selection_current array from ftl_selection_tags.
# If no tags, falls back to the current entry.
ftl::sel::resolve_current() {
    ftl_selection_current=()
    if (( ${#ftl_selection_tags[@]} )) ; then
        ftl_selection_current+=("${!ftl_selection_tags[@]}")
    elif (( ftl_list_entry_count )) ; then
        ftl_selection_current=("${ftl_list_entries[$ftl_state_cursor_index]}")
    fi
}

# Clear the entire selection.
ftl::sel::clear_all() {
    (( ftl_selection_revision++ ))
    ftl_selection_tags=()
    ftl_selection_total_bytes=0
    true
}

# Toggle a tag on/off.
# Args:
#   $1: file path
#   $2: optional glyph (defaults to ▪)
ftl::sel::flip() {
    (( ftl_selection_revision++ ))
    if [[ "${ftl_selection_tags[$1]:-}" ]] ; then
        unset 'ftl_selection_tags[$1]'
        ftl::sel::adjust_total_size - "$1"
        true
    else
        ftl_selection_tags[$1]=${2:-▪}
        ftl::sel::adjust_total_size + "$1"
    fi
}

# Set a tag (if not already set).
# Args:
#   $1: file path
#   $2: optional glyph (defaults to ▪)
ftl::sel::set() {
    (( ftl_selection_revision++ ))
    if [[ ! "${ftl_selection_tags[$1]:-}" ]] ; then
        ftl_selection_tags[$1]=${2:-▪}
        ftl::sel::adjust_total_size + "$1"
    fi
}

# Unset a tag (if set).
# Args:
#   $1: file path
ftl::sel::unset() {
    (( ftl_selection_revision++ ))
    if [[ ${ftl_selection_tags[$1]:-} ]] ; then
        unset 'ftl_selection_tags[$1]'
        ftl::sel::adjust_total_size - "$1"
    fi
}

# Unset all tags with a given class glyph.
# Args:
#   $1: class glyph
ftl::sel::unset_by_class() {
    local tag
    for tag in "${!ftl_selection_tags[@]}" ; do
        if [[ "$1" == "${ftl_selection_tags[$tag]}" ]] ; then
            unset 'ftl_selection_tags[$tag]'
            ftl::sel::adjust_total_size - "$tag"
            (( ftl_selection_revision++ ))
        fi
    done
}

# Remove tags for files that no longer exist.
# Returns: 0 if any tags remain, 1 if all were removed
ftl::sel::validate_existence() {
    local tag
    for tag in "${!ftl_selection_tags[@]}" ; do
        [[ -e "$tag" ]] || unset 'ftl_selection_tags[$tag]'
    done
    (( ${#ftl_selection_tags[@]} != 0 ))
}

# Prompt the user to choose a class (if multiple are in use).
# Outputs: the chosen class glyph on stdout
ftl::sel::prompt_for_class() {
    ftl::sel::build_class_index
    if (( ${#ftl_selection_class_index[@]} > 1 )) ; then
        printf "%s\n" "${!ftl_selection_class_index[@]}" | sort | ftl::sel::fzf_choose_class
    else
        echo "${ftl_selection_tags[$ftl_state_current_path]}"
    fi
}

# fzf-based class chooser.
ftl::sel::fzf_choose_class() {
    fzf-tmux -1 -p 80% --cycle --reverse --info=inline \
        --preview 'entry={} ; cat "'$ftl_state_session_dir'/ntags_${entry}"'
}

# Build the inverted index of classes (which classes are in use).
ftl::sel::build_class_index() {
    (( ftl_selection_revision++ ))
    ftl_selection_class_index=()
    rm "$ftl_state_session_dir"/ntags* 2>/dev/null
    local t
    for t in "${!ftl_selection_tags[@]}" ; do
        echo "$t" | lscolors >>"$ftl_state_session_dir/ntags_${ftl_selection_tags[$t]}"
        ftl_selection_class_index[${ftl_selection_tags[$t]}]=1
    done
}

# Get tags matching a class into a nameref array.
# Args:
#   $1: nameref for the output assoc array
#   $2: nameref for the class string
ftl::sel::get_by_class() {
    (( ${#ftl_selection_tags[@]} )) || return 0
    declare -n rtags="$1" rclass="$2"
    rclass=$(ftl::sel::prompt_for_class)
    ftl::list::render
    local t
    for t in "${!ftl_selection_tags[@]}" ; do
        [[ $rclass == "${ftl_selection_tags[$t]}" ]] && rtags[$t]=1
    done
}

# Navigate to the Nth tagged file.
# Args:
#   $1: index (0-based)
ftl::sel::goto_by_index() {
    local ti=0
    local tag_path nn=
    for tag_path in "${!ftl_selection_tags[@]}" ; do
        if (( ti == $1 )) ; then
            nn="$tag_path"
            break
        fi
        ((ti++))
    done
    [[ -n "$nn" ]] && ftl::list::change_dir "$(dirname "$nn")" "$(basename "$nn")"
}

# Tag or untag files from fzf output.
# Args:
#   $1: "U" to untag, anything else to tag
#   $2: newline-separated file paths
ftl::sel::fzf_tag_or_untag() {
    [[ -z "$2" ]] && return 0
    local f
    while read -r f ; do
        f="$(ftl::util::resolve_full_path "$f")"
        if [[ "$1" == "U" ]] ; then
            ftl::sel::unset "$f"
        else
            ftl::sel::set "$f"
        fi
    done <<<"$2"
}

# Sync selection from another pane (if its revision is newer).
ftl::sel::sync_from_other_pane() {
    2>&- read ftl_selection_other_revision <"$ftl_state_shared_dir/stagsi"
    if (( ftl_cfg_auto_sync_selection && ftl_selection_other_revision > ftl_selection_revision )) ; then
        ftl_selection_revision=$ftl_selection_other_revision
        read ftl_state_other_session_dir <"$ftl_state_shared_dir/fs"
        source "$ftl_state_other_session_dir/tags"
        ftl_state_other_session_dir=
    fi
    false
}

# Load selection from a file of paths (one per line).
# Args:
#   $1: file path (unused — $2 is the actual file)
#   $2: file containing paths
ftl::sel::load_from_file() {
    local p
    while read -r p ; do
        p="$(ftl::util::resolve_full_path "$p")"
        ftl::sel::flip "$p"
    done <"$2"
    ftl_selection_other_revision=$ftl_selection_revision
}

# Adjust ftl_selection_total_bytes by the size of a file.
# Args:
#   $1: "+" to add, anything else to subtract
#   $2: file path
ftl::sel::adjust_total_size() {
    if [[ $1 == "+" ]] ; then
        (( ftl_selection_total_bytes += $(stat --printf="%s" "$2") ))
        true
    else
        (( ftl_selection_total_bytes -= $(stat --printf="%s" "$2") ))
    fi
}

# Format the selection summary for the header.
# Outputs: " count/size" on stdout (empty if no selection)
ftl::sel::format_header_summary() {
    (( ${#ftl_selection_tags[@]} )) || return 0
    echo -n " ${#ftl_selection_tags[@]}/"
    numfmt --to=iec --format "%f" -- "$ftl_selection_total_bytes"
}

# vim: set filetype=bash :
