# tab.sh — tab management
#
# Each pane has its own set of tabs. Each tab has its own directory,
# filters, sort order, view mode, etc. Tab indices are not reused —
# closing a tab leaves a gap in the array.
#
# Public functions:
#   ftl::tab::init_defaults        — set up default state for the current tab
#   ftl::tab::create               — create a new tab (internal, no render)
#   ftl::tab::advance_index        — move to the next tab
#   ftl::tab::retreat_index        — move to the previous tab
#   ftl::tab::load_from_file       — load tabs from a file (for -t option)
#   ftl::tab::index_directory      — build entry-index cache for a directory
#
# Globals:
#   ftl_state_current_tab_index    — current tab index (was: tab)
#   ftl_tab_directories            — indexed array of tab dirs (was: tabs)
#   ftl_tab_count                  — number of open tabs (was: ntabs)
#   ftl_tab_listing_mode           — per-tab: 0=all, 1=dirs, 2=files (was: lmode)
#   ftl_tab_view_mode              — per-tab: 0=all, 1=no-image, 2=image (was: vmode)
#   ftl_tab_listing_depth          — per-tab: max find depth (was: depth)
#   ftl_tab_show_hidden            — per-tab: show dot-files (was: hidden)
#   ftl_tab_sort_type              — per-tab: 0=alpha, 1=size, 2=date (was: sort_type)
#   ftl_tab_sort_reversed          — per-tab: "-r" or empty (was: reversed)
#   ftl_tab_preview_dirs_only      — per-tab: preview dirs only (was: pdir_only)
#   ftl_tab_filter_1               — per-tab: regex filter 1 (was: filters)
#   ftl_tab_filter_2               — per-tab: regex filter 2 (was: filters2)
#   ftl_tab_filter_dirs            — per-tab: dir filter (was: filters_dir)
#   ftl_tab_filter_reverse         — per-tab: reverse filter (was: rfilters)
#   ftl_tab_filter_image_mode      — per-tab: image-mode filter (was: tfilters)
#   ftl_tab_filter_image_negate    — per-tab: -v flag for image mode (was: ntfilter)

# Set up default state for the current tab.
ftl::tab::init_defaults() {
        local t=$ftl_state_current_tab_index
        ftl_tab_preview_dirs_only[$t]=
        ftl_tab_listing_depth[$t]=1
        ftl_tab_view_mode[$t]=0
        ftl_tab_listing_mode[$t]=0
        ftl_tab_show_hidden[$t]=
        ftl_tab_sort_type[$t]=$ftl_cfg_default_sort_type
        ftl_tab_sort_reversed[$t]=
        ftl_tab_filter_dirs[$t]='.'
        ftl_tab_filter_1[$t]='.'
        ftl_tab_filter_2[$t]='.'
        ftl_tab_filter_reverse[$t]="$ftl_cfg_default_reverse_filter"
        ftl_tab_filter_image_mode[$t]=
        ftl_tab_filter_image_negate[$t]=
}

# Create a new tab.
# Args:
#   $1: directory path (or "." for current)
ftl::tab::create() {
        local dir
        if [[ "$1" == "." ]] ; then
                dir=
        else
                dir="$1"
        fi
        [[ "$dir" =~ ^/ ]] || dir="$PWD/$dir"
        ftl_tab_directories+=("$dir")
        (( ftl_state_current_tab_index = ${#ftl_tab_directories[@]} - 1, ftl_tab_count++ ))
        ftl::tab::init_defaults
}

# Move to the next tab (skipping closed gaps).
ftl::tab::advance_index() {
        (( ftl_state_current_tab_index++ ))
        local -a indices=( ${!ftl_tab_directories[@]} )
        local i
        for i in "${indices[@]:$ftl_state_current_tab_index}" "${indices[@]}" ; do
                if [[ -n "${ftl_tab_directories[$i]:-}" ]] ; then
                        ftl_state_current_tab_index=$i
                        break
                fi
        done
}

# Move to the previous tab (skipping closed gaps).
ftl::tab::retreat_index() {
        local -a indices=( ${!ftl_tab_directories[@]} )
        local -a reversed_indices
        reversed_indices=($(echo "${indices[@]}" "${indices[@]:0:ftl_state_current_tab_index}" | rev | tr ' ' '\n'))
        local i
        for i in "${reversed_indices[@]}" ; do
                if [[ -n "${ftl_tab_directories[$i]:-}" ]] ; then
                        ftl_state_current_tab_index=$i
                        break
                fi
        done
}

# Load tabs from a file (one path per line).
# Args:
#   $1: unused (positional)
#   $2: file containing tab paths
ftl::tab::load_from_file() {
        ftl_tab_directories=()
        ftl_tab_count=0
        local p
        while read -r p ; do
                p="$(ftl::util::resolve_full_path "$p")"
                if [[ -d "$p" ]] ; then
                        _ftl::tab::read_one_entry "$p"
                else
                        _ftl::tab::read_one_entry "$(dirname "$p")" "$(basename "$p")"
                fi
        done <"$2"
}

# Read one tab entry from the load file.
# Args:
#   $1: directory
#   $2: optional filename to select within the directory
_ftl::tab::read_one_entry() {
        ftl::tab::create "$1"
        if [[ -d "$1" ]] ; then
                ftl::tab::index_directory "$1"
                ftl_state_cursor_memory[${ftl_state_current_tab_index}_$(realpath "$1")]=${ftl_tab_index_cache[$1/$2]}
        fi
        true
}

# Build the entry-index cache for a directory (for -t option).
# Args:
#   $1: directory path
ftl::tab::index_directory() {
        [[ -n "${ftl_tab_dir_cache[$1]:-}" ]] && return 0
        ftl_tab_dir_cache[$1]=1
        local index=0
        local e
        while IFS= read -r e ; do
                ftl_tab_index_cache["$1/$e"]=$index
                ((index++))
        done < <(cd "$1" && _ftl::list::scan_for_dir_view)
}

# Caches used during tab loading.
declare -Ag ftl_tab_index_cache    # "dir/file" → index
declare -Ag ftl_tab_dir_cache      # "dir" → 1 (already indexed)

# vim: set filetype=bash :
