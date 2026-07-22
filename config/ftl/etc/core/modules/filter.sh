# filter.sh — filter pipeline for directory listings
#
# Manages the filter pipeline that narrows directory listings. Filters
# are applied in a fixed order: external filter → dir filter → file
# filters (1, 2, reverse) → image-mode filter → sort.
#
# Public functions:
#   ftl::filt::pipeline_add        — add a filter to the pipeline (was: filter_add)
#   ftl::filt::pipeline_clear      — clear the pipeline (was: filter_clr)
#   ftl::filt::pipeline_remove     — remove a filter from the pipeline (was: filter_rmv)
#   ftl::filt::reset               — reset all filters to defaults (was: filter_rst)
#   ftl::filt::sort_entries        — default sort function (was: sort_by)
#   ftl::filt::get_sort_glyph      — return the sort glyph (was: sort_glyph)
#   ftl::filt::apply_user_colors   — apply user color overrides (was: user_color)
#   ftl::filt::load_external       — load an external filter plugin (was: load_filter)
#
# Private functions:
#   _ftl::filt::reset_external     — reset the external filter (was: filter_rxt)
#   _ftl::filt::apply_image_mode_filter — apply image-mode filter (was: filter_not)
#   _ftl::filt::apply_filter_1     — apply filter 1 (was: filter_1)
#   _ftl::filt::apply_filter_2     — apply filter 2 (was: filter_2)
#   _ftl::filt::apply_reverse_filter — apply reverse filter (was: filter_rev)
#
# Globals:
#   ftl_filter_pipeline_list         — indexed array of filter fn names (was: filter_list)
#   ftl_filter_pipeline_string       — eval-able pipe string (was: filter_pipe)
#   ftl_filter_external_name         — name of loaded external filter (was: filter_ext)
#   ftl_filter_active_glyph          — glyph shown when filter active (was: ftag)
#   ftl_filter_listing_hide_exts     — assoc: extension → 1 (hide) (was: lignore)
#   ftl_filter_listing_keep_exts     — assoc: extension → 1 (keep only) (was: lkeep)
#   ftl_filter_listing_keep_exts_per_tab — per-tab keep list (was: lkeep_tab)

# The pipeline list and string.
declare -ag ftl_filter_pipeline_list
ftl_filter_pipeline_string=

# Add a filter to the pipeline.
# Args:
#   $@: filter function names
# Outputs: pipe-separated string on stdout
ftl::filt::pipeline_add() {
        ftl_filter_pipeline_list+=("$@")
        local IFS='|'
        echo "${ftl_filter_pipeline_list[*]}"
}

# Clear the pipeline.
ftl::filt::pipeline_clear() {
        ftl_filter_pipeline_list=()
}

# Remove a filter from the pipeline.
# Args:
#   $1: filter function name to remove
ftl::filt::pipeline_remove() {
        local -a new_list=()
        local f
        for f in "${ftl_filter_pipeline_list[@]}" ; do
                [[ "$f" != "$1" ]] && new_list+=("$f")
        done
        ftl_filter_pipeline_list=("${new_list[@]}")
}

# Reset all filters to defaults.
ftl::filt::reset() {
        ftl_filter_active_glyph=
        _ftl::filt::reset_external
        eval 'ftl::filter::apply_external() { cat ; } ; ftl::filt::sort_entries() { ftl::filt::sort_by ; } ; ftl::filt::get_sort_glyph() { echo ${ftl_cfg_glyph_sort[$ftl_list_resolved_sort_type]} ; }'
}

# Reset the external filter (call its reset hook).
_ftl::filt::reset_external() {
        [[ -z "$ftl_filter_external_name" ]] && return 0
        source "$FTL_CFG/etc/filters/$ftl_filter_external_name" "reset"
        ftl_filter_external_name=
}

# Apply the image-mode filter (with optional negation).
_ftl::filt::apply_image_mode_filter() {
        rg ${ftl_tab_filter_image_negate[$ftl_state_current_tab_index]} \
           "${ftl_tab_filter_image_mode[$ftl_state_current_tab_index]}"
}

# Apply filter 1.
_ftl::filt::apply_filter_1() {
        rg ${ftl_tab_filter_1[$ftl_state_current_tab_index]}
}

# Apply filter 2.
_ftl::filt::apply_filter_2() {
        rg ${ftl_tab_filter_2[$ftl_state_current_tab_index]}
}

# Apply the reverse filter.
_ftl::filt::apply_reverse_filter() {
        if [[ -n "${ftl_tab_filter_reverse[$ftl_state_current_tab_index]}" ]] ; then
                rg -v ${ftl_tab_filter_reverse[$ftl_state_current_tab_index]}
        else
                cat
        fi
}

# Default sort function.
ftl::filt::sort_entries() {
        sort $ftl_list_resolved_sort_reversed ${ftl_cfg_sort_options[$ftl_list_resolved_sort_type]}
}

# Alias for sort_entries (used by sort_by_extension plugin).
ftl::filt::sort_by() {
        ftl::filt::sort_entries
}

# Return the sort glyph for the current sort type.
ftl::filt::get_sort_glyph() {
        echo "${ftl_cfg_glyph_sort[$ftl_list_resolved_sort_type]}"
}

# Apply user color overrides to entries read from stdin.
ftl::filt::apply_user_colors() {
        if (( ${#ftl_cfg_color_overrides[@]} )) ; then
                local cf
                while read -r cf ; do
                        if (( ${#ftl_cfg_color_overrides[$cf]:-0} )) ; then
                                echo -e "\e[${ftl_cfg_color_overrides[$cf]}m$cf\e[m"
                        else
                                echo "$cf"
                        fi
                done
        else
                cat
        fi
}

# Load an external filter plugin.
# Args:
#   $1: filter name
ftl::filt::load_external() {
        local p="$FTL_CFG/etc/filters"
        if [[ -f "$p/$1" ]] ; then
                source "$p/$1"
                ftl_filter_external_name="$1"
        else
                ftl_filter_external_name=
                echo "ftl: load_filter error" >&2
                false
        fi
}

# Initialize the default pipeline.
ftl::filt::init() {
        ftl_filter_pipeline_list=()
        ftl::filt::pipeline_add \
                _ftl::filt::apply_image_mode_filter \
                _ftl::filt::apply_filter_1 \
                _ftl::filt::apply_filter_2 \
                _ftl::filt::apply_reverse_filter
        ftl_filter_pipeline_string="${ftl_filter_pipeline_list[*]}"
        local IFS='|'
        ftl_filter_pipeline_string="${ftl_filter_pipeline_list[*]}"
}

# Placeholder for the external filter (overridden by plugins).
ftl::filter::apply_external() {
        cat
}

# vim: set filetype=bash :
