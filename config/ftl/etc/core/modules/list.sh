# list.sh — directory scanning and rendering
#
# Scans directories via a streaming pipeline (find → filter → sort → fifos)
# and renders the listing to the terminal with ANSI escape codes.
#
# Public functions:
#   ftl::list::change_dir          — change directory and re-list (was: cdir)
#   ftl::list::refresh_dir         — refresh listing without full rescan (was: rdir)
#   ftl::list::render              — render the current listing (was: list)
#   ftl::list::move_cursor         — move the cursor by N entries (was: move)
#
# Private functions:
#   _ftl::list::scan_and_render    — the full cd+scan+render pipeline (was: cview)
#   _ftl::list::scan_directory     — scan a directory into the raw arrays (was: get_dir_entries)
#   _ftl::list::scan_custom_source — scan from a custom source (fzf-listen) (was: ftl::plugin::fzf_search::get_custom_entries)
#   _ftl::list::apply_filters_and_format — filter and format raw entries (was: prepare_entries)
#   _ftl::list::render_window      — compute window and call render (was: view_list)
#   _ftl::list::render_header      — render the header line (was: show_header)
#   _ftl::list::print_header       — print the header with truncation (was: header)
#   _ftl::list::compute_header_truncation — compute PWD/info truncation (was: header_pos)
#   _ftl::list::clear_below        — clear lines below the given row (was: clear_list)
#   _ftl::list::scan_for_dir_view  — scan for the dir-view (tab indexing) (was: as_dir)
#   _ftl::list::scan_full          — full scan with size/color output (was: dir)
#   _ftl::list::find_entries       — run find with given predicates (was: files)
#   _ftl::list::inject_virtual_files — emit virtual files (was: files_virt)
#   _ftl::list::inject_virtual_dirs  — emit virtual dirs (was: dirs_virt)
#   _ftl::list::emit_size_to_fifo  — tee size to fd 6 (was: output_size)
#   _ftl::list::emit_name_to_fifos — tee name to fds 4,5 (was: output_path)
#   _ftl::list::signal_scan_complete — send EOF to fifos (was: dir_done)
#   _ftl::list::format_dir_size    — format a dir's size (was: dir_size)
#   _ftl::list::format_dir_entry_count — format a dir's entry count (was: dir_esize)
#   _ftl::list::compute_dir_sizes  — compute all dir sizes (was: dir_dusize)
#   _ftl::list::run_du             — run du and colorize (was: get_dusize)
#   _ftl::list::adjust_for_preview — adjust COLS for preview pane (was: geo_prev)
#
# Globals:
#   ftl_list_entries               — indexed array of full paths (was: files)
#   ftl_list_entry_colors          — indexed array of colored names (was: files_color)
#   ftl_list_entry_count           — count of entries (was: nfiles)
#   ftl_list_raw_entries           — indexed array of raw names (was: dir_entries_list)
#   ftl_list_raw_paths             — assoc: name → parent dir (was: dir_entries_path)
#   ftl_list_raw_names             — assoc: name → basename (was: dir_entries_file)
#   ftl_list_raw_colors            — assoc: name → color (was: dir_entries_color)
#   ftl_list_raw_sizes             — assoc: name → size (was: dir_entries_size)
#   ftl_list_raw_relpath_len       — assoc: name → relpath length (was: dir_entries_relative_path_length)
#   ftl_list_window_top            — top visible index (was: top)
#   ftl_list_window_bottom         — bottom visible index (was: bottom)
#   ftl_list_window_center         — center index (was: center)
#   ftl_list_window_height         — visible height (was: lines)
#   ftl_list_display_line_no       — 1-based display counter (was: line)
#   ftl_list_total_size            — total bytes (was: sum)
#   ftl_list_index_padding         — width of index column (was: pad)
#   ftl_list_first_file_index      — index of first file (was: first_file)
#   ftl_list_search_found_index    — where search target found (was: found)
#   ftl_list_mime_cache            — assoc: path → mime type (was: mime)
#   ftl_list_dir_size_cache        — assoc: dir → colored size (was: du_size)
#   ftl_state_cursor_index         — current entry index (was: file)
#   ftl_state_cursor_memory        — assoc: tab_PWD → index (was: dir_file)

# Change directory and re-list.
# Args:
#   $1: directory (defaults to $PWD)
#   $2: optional filename to select
#   $3: optional index to select
ftl::list::change_dir() {
        if [[ -n "$ftl_state_custom_list" ]] ; then
                _ftl::list::render_window
        else
                _ftl::list::scan_and_render _ftl::list::scan_directory "$@"
        fi
}

# Refresh listing without full rescan (used by rdir).
# Args:
#   $1: optional index to select
ftl::list::refresh_dir() {
        ftl::pane::query_geometry
        _ftl::list::apply_filters_and_format "$1"
        (( ftl_list_window_height = ftl_list_entry_count > ftl_pane_height - 1 \
                ? ftl_pane_height - 1 : ftl_list_entry_count, \
           ftl_list_window_center = ftl_list_window_height / 2 ))
        ftl_list_quick_display_active=${2:-1}
        ftl::list::render
        ftl_list_quick_display_active=0
}

# The full cd+scan+render pipeline.
# Args:
#   $1: scan function to call
#   $2: directory (optional)
#   $3: filename to select (optional)
#   $4: index to select (optional)
_ftl::list::scan_and_render() {
        local get_entries="$1"
        shift

        ftl::pane::stop_file_watcher

        if [[ -d "${1:-$PWD}" ]] ; then
                cd "${1:-$PWD}"
        else
                return
        fi

        # Save history and update marks on directory change
        if [[ "$ftl_state_previous_pwd" != "$PWD" ]] ; then
                _ftl::mark::save_to_history
                ftl_mark_session_marks["'"]="$ftl_state_current_path"
                ftl_state_previous_pwd="$PWD"
        fi

        ftl_tab_directories[$ftl_state_current_tab_index]="$PWD"
        if [[ "$PWD" == / ]] ; then
                ftl_list_path_separator=
        else
                ftl_list_path_separator=/
        fi
        shopt -s nocasematch
        _ftl::list::adjust_for_preview

        # Reset mime cache and resolve search target
        ftl_list_mime_cache=()
        ftl_state_search_string="${2:-$(\
                [[ -z "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_$ftl_state_previous_pwd]:-}" ]] \
                && echo "$ftl_cfg_auto_select_filename")}"
        ftl_list_resolved_sort_type=$ftl_cfg_default_sort_type
        ftl_list_resolved_sort_reversed=$ftl_cfg_default_sort_reversed

        # Per-directory override
        [[ -f .ftlrc_dir ]] && source .ftlrc_dir
        ftl_list_resolved_sort_type=${ftl_tab_sort_type[$ftl_state_current_tab_index]:-$ftl_list_resolved_sort_type}
        if [[ "${ftl_tab_sort_reversed[$ftl_state_current_tab_index]}" == "-r" ]] ; then
                ftl_list_resolved_sort_reversed=-r
        elif [[ "${ftl_tab_sort_reversed[$ftl_state_current_tab_index]}" == "0" ]] ; then
                ftl_list_resolved_sort_reversed=
        fi

        "$get_entries" "$@"
        _ftl::list::apply_filters_and_format "$@"

        ftl::pane::start_file_watcher
        _ftl::list::render_window
}

# Scan a directory into the raw arrays using the streaming pipeline.
# Args:
#   $1: unused (positional)
#   $2: unused (positional)
_ftl::list::scan_directory() {
        ftl_list_raw_entries=()
        ftl_list_raw_paths=()
        ftl_list_raw_relpath_len=()
        ftl_list_raw_names=()
        ftl_list_raw_colors=()
        ftl_list_raw_sizes=()
        declare -A uniq_file=()

        # Run etag directory scan
        if (( ftl_state_etag_enabled )) ; then
                ftl::etag::scan_directory
        fi

        # Start background thumbnail generation
        if (( ! ftl_pane_is_child )) ; then
                nice -10 "$ftl_gen_dir/generator" "$ftl_cache_thumb_dir" &
        fi

        # Inject virtual entries and run the scan pipeline
        ftl::plugin::virtual::inject_entries
        _ftl::list::scan_full &

        # Consume the pipeline output from fifos
        local pnc pc size
        while true ; do
                read -s -u 4 pnc
                (( $? > 128 )) && break
                read -s -u 5 pc
                read -s -u 6 size

                [[ -z "$entry_name" ]] && break
                (( ${uniq_file[$entry_name]:-0} )) && continue
                uniq_file[$entry_name]=1

                ftl_list_raw_entries+=("$entry_name")
                local _idx=$((${#ftl_list_raw_entries[@]} - 1))
                ftl_list_raw_paths[$_idx]="$PWD"
                ftl_list_raw_relpath_len[$_idx]=0
                ftl_list_raw_names[$_idx]="$entry_name"
                ftl_list_raw_colors[$_idx]="$entry_color"
                ftl_list_raw_sizes[$_idx]=$entry_size

                # Quick display progress indicator
                if (( ftl_cfg_quick_display_threshold \
                          && ftl_list_entry_count > 0 \
                          && 0 == ftl_list_entry_count % ftl_cfg_quick_display_threshold )) ; then
                        echo -e "\e[H\e[31m$ftl_list_entry_count\e[0m"
                        ftl_list_quick_display_active=1
                fi
        done
}

# Apply extension filters, etags, sizes, and formatting to raw entries.
# Produces ftl_list_entries and ftl_list_entry_colors.
# Args:
#   $@: unused (positional)
_ftl::list::apply_filters_and_format() {
        ftl_list_entries=()
        ftl_list_entry_count=0
        ftl_list_entry_colors=()
        ftl_list_display_line_no=0
        ftl_list_total_size=0
        ftl_list_first_file_index=
        ftl_list_search_found_index=

        # Compute padding for index column
        local pad_str
        printf -v pad_str "%d" ${#ftl_list_raw_entries[@]}
        ftl_list_index_padding=${#pad_str}

        local p_index e ext_l
        local e ext_l
        for p_index in "${!ftl_list_raw_entries[@]}" ; do
                local entry_color="${ftl_list_raw_colors[$p_index]}"
                local entry_name="${ftl_list_raw_names[$p_index]}"
                local entry_parent="${ftl_list_raw_paths[$p_index]}"
                local entry_relpath_len=${ftl_list_raw_relpath_len[$p_index]}

                local entry_size=${ftl_list_raw_sizes[$p_index]}
                (( ftl_list_total_size += entry_size ))
                local entry_name_len=${#entry_name}

                # Extension filtering
                if [[ -f "$entry_name" ]] ; then
                        if [[ "$entry_name" =~ '.' ]] ; then
                                e=${entry_name##*.}
                                (( ${ftl_filter_listing_hide_exts[${ftl_state_current_tab_index}_${e@Q}]:-0} \
                                          || ${ftl_filter_listing_hide_exts[${e@Q}]:-0} )) && continue
                                ((${#ftl_filter_listing_keep_exts_per_tab[$ftl_state_current_tab_index]})) && { (( ${ftl_filter_listing_keep_exts_per_tab[${ftl_state_current_tab_index}_${e@Q}]:-0} )) || continue ; }
                                ((${#ftl_filter_listing_keep_exts[@]})) && { (( ${ftl_filter_listing_keep_exts[${e@Q}]:-0} )) || continue ; }
                        else
                                ((${#ftl_filter_listing_keep_exts[@]} || ${#ftl_filter_listing_keep_exts_per_tab[$ftl_state_current_tab_index]})) && continue
                        fi
                fi

                # Quick display progress indicator
                if (( ftl_cfg_quick_display_threshold \
                          && ftl_list_entry_count > 0 \
                          && 0 == ftl_list_entry_count % ftl_cfg_quick_display_threshold )) ; then
                        echo -e "\e[H\e[31m$ftl_list_entry_count\e[0m"
                        ftl_list_quick_display_active=1
                fi

                # Color inaccessible directories red
                if [[ -d "$entry_name" && ! -x "$entry_name" ]] ; then
                                entry_color="\e[31m$entry_name"
                fi

                # Apply etag
                if (( ftl_state_etag_enabled )) ; then
                        ftl::etag::get_entry_tag "$entry_name" ftl_etag_tag ftl_etag_tag_len
                        entry_color="$ftl_etag_tag$entry_color"
                        (( entry_name_len += ftl_etag_tag_len ))
                fi

                # Size column
                if (( ftl_state_show_size_mode )) ; then
                        if [[ -d "$entry_name" ]] ; then
                                if (( ftl_state_show_size_mode > 1 )) ; then
                                        entry_color="$(_ftl::list::format_dir_size "$entry_name") $entry_color"
                                else
                                        entry_color="      $entry_color"
                                fi
                        else
                                entry_color="\e[94m$(ftl::util::format_size_human "$entry_size")\e[m $entry_color"
                        fi
                        (( entry_name_len += 6 ))
                fi

                # Index column
                if (( ftl_cfg_show_entry_index )) ; then
                        (( ftl_list_display_line_no++ ))
                        printf -v entry_color "$ftl_cfg_line_color_default%${ftl_list_index_padding}d\e[m¿${entry_color//\%/%%}" \
                                "$ftl_list_display_line_no"
                        (( entry_name_len += ftl_list_index_padding + 1 ))
                fi

                # Remove trailing color reset if entry is colored
                if [[ ${#entry_color} != $entry_name_len ]] ; then
                        entry_color="${entry_color:0:-4}"
                fi

                # Truncation
                if (( entry_relpath_len + entry_name_len > ftl_pane_width - 1 )) ; then
                        if [[ "$entry_name" =~ '.' ]] ; then
                                e=${entry_name##*.}
                        else
                                e=
                        fi
                        ext_l=$((${#e}+1))
                        entry_color="${entry_color:0:((- (((entry_relpath_len + entry_name_len) - (ftl_pane_width - 1)) + ext_l) ))}…${e}"
                fi

                ftl_list_entry_colors[$ftl_list_entry_count]="$entry_color"
                ftl_list_entries[$ftl_list_entry_count]="$entry_parent$ftl_list_path_separator$entry_name"

                # Track first file and search target
                if [[ -z "$ftl_list_first_file_index" && -f "$entry_name" ]] ; then
                        ftl_list_first_file_index=$ftl_list_entry_count
                fi
                if [[ -n "$ftl_state_search_string" && -z "$ftl_list_search_found_index" ]] ; then
                        if [[ "${entry_name:0:${#ftl_state_search_string}}" == "$ftl_state_search_string" ]] ; then
                                ftl_list_search_found_index=$ftl_list_entry_count
                        fi
                fi

                (( ftl_list_entry_count++ ))
        done

        shopt -u nocasematch
        ftl_list_quick_display_active=0

        # Compute header total size
        if (( ftl_state_show_size_mode || ftl_pane_is_child )) ; then
                ftl_list_header_total_size=$(numfmt --to=iec --format ' %4f' "$ftl_list_total_size")
        else
                ftl_list_header_total_size=
        fi
}

# Compute the visible window and call render.
# Args:
#   $1: index to select (defaults to found index)
_ftl::list::render_window() {
        (( ftl_list_window_height = ftl_list_entry_count > ftl_pane_height - 1 \
                ? ftl_pane_height - 1 : ftl_list_entry_count, \
           ftl_list_window_center = ftl_list_window_height / 2 ))
        sleep 0.02
        (( ftl_list_quick_display_active )) || ftl::util::refresh_screen
        ftl::list::render "${1:-$ftl_list_search_found_index}"
        true
}

# Render the current listing to the terminal.
# Args:
#   $1: optional index to select
ftl::list::render() {
        [[ -n "$1" ]] && ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]="$1"
        ftl_state_cursor_index=${ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]:-0}

        # Clamp cursor to valid range
        (( ftl_state_cursor_index = ftl_state_cursor_index > ftl_list_entry_count - 1 \
                ? ftl_list_entry_count - 1 : ftl_state_cursor_index ))

        if (( ftl_list_entry_count )) ; then
                ftl::util::parse_path "${ftl_list_entries[$ftl_state_cursor_index]}"
        else
                ftl::util::clear_path_vars
        fi

        # Save state (unless we're a child/preview pane)
        (( ftl_pane_is_child )) || ftl::state::save

        ftl::sel::resolve_current
        ftl::pane::snapshot_geometry

        # Compute visible window
        if (( ftl_list_entry_count < ftl_list_window_height \
                  || ftl_state_cursor_index <= ftl_list_window_center )) ; then
                ftl_list_window_top=0
        elif (( ftl_state_cursor_index >= ftl_list_entry_count - ftl_list_window_center )) ; then
                ftl_list_window_top=$(( ftl_list_entry_count - ftl_list_window_height ))
        else
                ftl_list_window_top=$(( ftl_state_cursor_index - ftl_list_window_center ))
        fi
        ftl_list_window_bottom=$(( ftl_list_window_top + ftl_list_window_height - 1 ))
        (( ftl_list_window_bottom < 0 )) && ftl_list_window_bottom=0

        # Alternate row separator
        (( ftl_list_flip_index ^= 1 ))
        ftl_list_current_flip_char="${ftl_cfg_row_separator_chars[$ftl_list_flip_index]}"

        _ftl::list::render_header

        # Render entries
        if (( ftl_list_entry_count )) ; then
                local -i i terminal_line=2
                local selection_glyph
                for (( i = ftl_list_window_top ; i <= ftl_list_window_bottom ; i++, tline++ )) ; do
                        cursor=${ftl_selection_tags[${ftl_list_entries[$i]}]:- }
                        if (( i == ftl_state_cursor_index )) ; then
                                cursor="${ftl_cfg_cursor_color_default}$selection_glyph\e[m"
                        fi
                        echo -ne "\e[${tline};0H\e[m\e[K$selection_glyph${ftl_list_entry_colors[i]/¿/$ftl_list_current_flip_char}\e[0m"
                        (( i != ftl_list_window_bottom )) && echo
                done

                _ftl::list::clear_below "$terminal_line"

                if (( ! ftl_list_quick_display_active && ! ftl_pane_is_child )) ; then
                        ftl::prev::dispatch
                        ftl::pane::snapshot_geometry
                fi
        else
                ftl::prev::clear
                _ftl::list::clear_below 0
        fi
}

# Render the header line.
_ftl::list::render_header() {
        local header_prefix header_search header_tabs header_stat header_date

        head="${ftl_cfg_glyph_listing_mode[${ftl_tab_listing_mode[$ftl_state_current_tab_index]}]}${ftl_cfg_glyph_image_mode[${ftl_tab_view_mode[$ftl_state_current_tab_index]}]}${ftl_tab_preview_dirs_only[$ftl_state_current_tab_index]}${ftl_state_montage_glyph}"
        head=${head:+$header_prefix }

        if [[ -n "$ftl_state_search_string" ]] ; then
                search_h="S:$ftl_state_search_string "
        else
                search_h=
        fi

        if (( ftl_tab_count > 1 )) ; then
                tabsd=" ᵗ$((ftl_state_current_tab_index+1))"
        else
                tabsd=
        fi

        if (( ! ftl_list_entry_count )) ; then
                _ftl::list::print_header '' "\e[33m∅  $header_prefix$ftl_filter_active_glyph$header_tabs$header_search"
                return
        fi

        if (( ftl_state_show_stat )) ; then
                stat="$(stat -c ' %A %U' "${ftl_list_entries[$ftl_state_cursor_index]}") \
$(stat -c %s "${ftl_list_entries[$ftl_state_cursor_index]}" | numfmt --to=iec --format '%4f')"
        else
                stat=
        fi

        if (( ftl_list_resolved_sort_type == 2 && ftl_cfg_show_date_in_header )) ; then
                date=$(find "${ftl_list_entries[$ftl_state_cursor_index]}" -maxdepth 0 -printf ' %Tx-%TH:%TM')
        else
                date=
        fi

        _ftl::list::print_header '' \
                "$header_prefix$ftl_filter_active_glyph$(printf "%${ftl_list_index_padding}d" $((ftl_state_cursor_index+1)))/${ftl_list_header_total_count:-$ftl_list_entry_count}$ftl_list_header_total_size$header_stat$header_date$header_tabs$header_search"
}

# Print the header with PWD (left) and info (right), truncated to fit.
# Args:
#   $1: PWD color code (defaults to 94)
#   $2: info string
_ftl::list::print_header() {
        local bg_window_count
        tsc=$(ftl::pane::count_bg_windows)
        local header_info="${@:2} $(ftl::filt::get_sort_glyph)$ftl_list_resolved_sort_reversed$(ftl::sel::format_header_summary)"
        _ftl::list::compute_header_truncation "$header_info$bg_window_count"
        echo -e "\e[H\e[K\e[${1:-94}m${PWD:0:ftl_list_header_path_length} \e[${1:-95}m${h:ftl_list_header_attr_length}\e[m \e[4;33m$bg_window_count\e[0m"
}

# Compute how much of PWD and info to display.
# Args:
#   $1: the full info string
_ftl::list::compute_header_truncation() {
        local cols
        if [[ -n "$ftl_pane_preview_id" ]] ; then
                cols=$ftl_pane_width
        else
                cols=50
        fi
        ftl_list_header_attr_length=$((${#1} - (cols - 1)))
        ftl_list_header_path_length=$((${#PWD} + (ftl_list_header_attr_length < 0 ? ftl_list_header_attr_length : 0)))
        (( ftl_list_header_attr_length = ftl_list_header_attr_length < 0 ? 0 : ftl_list_header_attr_length, \
           ftl_list_header_path_length = ftl_list_header_path_length < 0 ? 0 : ftl_list_header_path_length ))
}

# Clear lines below the given row.
# Args:
#   $1: starting row
_ftl::list::clear_below() {
        local i
        for (( i = $1 ; i <= ftl_pane_height ; i++ )) ; do
                echo -ne "\e[${i};0H\e[K$ftl_list_current_flip_char"
                (( i <= ftl_pane_height - 1 )) && echo
        done
}

# Move the cursor by N entries.
# Args:
#   $1: delta (positive or negative)
ftl::list::move_cursor() {
        local nf
        (( nf = ftl_state_cursor_index + $1, \
           nf = nf < 0 ? 0 : nf >= ftl_list_entry_count ? ftl_list_entry_count - 1 : nf ))
        (( nf != ftl_state_cursor_index )) && \
                ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]=$nf
}

# Scan for the directory view (used by tab indexing).
# Outputs: find output piped through filters
_ftl::list::scan_for_dir_view() {
        local t=$ftl_state_current_tab_index
        if (( ftl_tab_listing_mode[$t] < 2 )) ; then
                { _ftl::list::find_entries "-type  d,l -xtype d" ; ftl::plugin::virtual::get_virtual_dirs ; } \
                        | ftl::filter::apply_external \
                        | rg ${ftl_tab_filter_dirs[$t]} \
                        | ftl::filt::sort_entries \
                        | cut -f 3-
        fi
        _ftl::list::find_entries "-xtype p,l" \
                | ftl::filter::apply_external \
                | eval "$ftl_filter_pipeline_string" \
                | ftl::filt::sort_entries \
                | cut -f 3-
        if (( ftl_tab_listing_mode[$t] != 1 )) ; then
                { _ftl::list::find_entries "-type  f,l -xtype f" ; ftl::list::inject_virtual_files ; } \
                        | ftl::filter::apply_external \
                        | eval "$ftl_filter_pipeline_string" \
                        | ftl::filt::sort_entries \
                        | cut -f 3-
        fi
}

# Full scan with size/color output to fifos.
_ftl::list::scan_full() {
        local t=$ftl_state_current_tab_index
        if (( ftl_tab_listing_mode[$t] < 2 )) ; then
                { _ftl::list::find_entries "-type  d,l -xtype d" ; ftl::plugin::virtual::get_virtual_dirs ; } \
                        | ftl::filter::apply_external \
                        | rg ${ftl_tab_filter_dirs[$t]} \
                        | ftl::filt::sort_entries \
                        | _ftl::list::emit_size_to_fifo \
                        | _ftl::list::emit_name_to_fifos
        fi
        _ftl::list::find_entries "-xtype p,l" \
                | ftl::filter::apply_external \
                | eval "$ftl_filter_pipeline_string" \
                | ftl::filt::sort_entries \
                | _ftl::list::emit_size_to_fifo \
                | _ftl::list::emit_name_to_fifos
        if (( ftl_tab_listing_mode[$t] != 1 )) ; then
                { _ftl::list::find_entries "-type  f,l -xtype f" ; ftl::list::inject_virtual_files ; } \
                        | ftl::filter::apply_external \
                        | eval "$ftl_filter_pipeline_string" \
                        | ftl::filt::sort_entries \
                        | _ftl::list::emit_size_to_fifo \
                        | _ftl::list::emit_name_to_fifos
        fi
        _ftl::list::signal_scan_complete
}

# Run find with the given predicates.
# Args:
#   $1: find type predicates
_ftl::list::find_entries() {
        find "$PWD/" -mindepth 1 -maxdepth "${ftl_tab_listing_depth[$ftl_state_current_tab_index]:-1}" \
                ${ftl_tab_show_hidden[$ftl_state_current_tab_index]:+\( ! -path "*/.*" \)} \
                $1 -printf '%s\t%T@\t%P\n' 2>&-
}

# Emit virtual files (size=0, date=0).
_ftl::list::inject_virtual_files() {
        (( ${#ftl_plugin_vfiles[@]} )) && printf "0\t0\t%s\n" "${!ftl_plugin_vfiles[@]}"
}

# Tee size (field 1) to fd 6, pass name (field 3+) to stdout.
_ftl::list::emit_size_to_fifo() {
        tee >(cut -f 1 >&6) | cut -f 3-
}

# Tee name to fd 4, colorized name to fd 5.
_ftl::list::emit_name_to_fifos() {
        tee >(cat >&4) | ftl::plugin::virtual::clear_filter | ftl::filt::apply_user_colors | lscolors >&5
}

# Signal that the scan is complete (EOF on all fifos).
_ftl::list::signal_scan_complete() {
        echo >&4
        echo >&5
        echo 0 >&6
}

# Format a directory's size for display.
# Args:
#   $1: directory name
# Outputs: formatted size on stdout
_ftl::list::format_dir_size() {
        if (( ftl_state_show_size_mode == 2 )) ; then
                _ftl::list::format_dir_entry_count "$1"
        else
                printf "\e[94m %4s\e[m" "${ftl_list_dir_size_cache[$PWD/$1]}"
        fi
}

# Format a directory's entry count.
# Args:
#   $1: directory name
# Outputs: formatted count on stdout
_ftl::list::format_dir_entry_count() {
        printf "\e[94m%4s \e[m" "$(
                find "$1/" -mindepth 1 -maxdepth 1 \
                        ${ftl_tab_show_hidden[$ftl_state_current_tab_index]:+\( ! -iname '.*' \)} \
                        -type d,f,l -xtype d,f -printf "1\n" 2>&- | wc -l
        )"
}

# Compute all directory sizes (for show_size mode 3).
ftl::list::compute_dir_sizes() {
        local reset
        reset="$(printf '\e[0m')"
        declare -Ag ftl_list_dir_size_cache
        local color size file
        while IFS=$'\t' read -r color size file ; do
                ftl_list_dir_size_cache[$PWD/$file]="$color$entry_size$reset"
        done < <(_ftl::list::run_du)
}

# Run du and colorize the output.
_ftl::list::run_du() {
        du -L -h | color_size | perl -ne \
                '($c, $s, $f) = m/(\e\[[0-9;]+m)(.*?)\e\[0m\t.\/(.*)/ ; printf "$c\t%4s\t$f\n", $s'
}

# Adjust ftl_pane_width for the preview pane.
_ftl::list::adjust_for_preview() {
        ftl::pane::query_geometry
        if (( ${preview:-$ftl_state_preview_pane_visible} )) && [[ -z "$ftl_pane_preview_id" ]] ; then
                (( ftl_pane_width = (ftl_pane_width - 1) * (100 - ${ftl_cfg_preview_zoom_levels[$ftl_state_preview_zoom_index]}) / 100 ))
        fi
}

# Compute the preview pane resize target.
ftl::list::compute_preview_width() {
        ftl::pane::query_geometry
        if [[ -n "$ftl_pane_preview_id" ]] ; then
                read -r ftl_pane_preview_width < <(tmux display -p -t "$ftl_pane_preview_id" '#{pane_width}')
        else
                ftl_pane_preview_width=0
        fi
        (( ftl_pane_resize_target = ( (ftl_pane_width + ftl_pane_preview_width) * ${ftl_cfg_preview_zoom_levels[$ftl_state_preview_zoom_index]} ) / 100 ))
}

# Get the mime type for the current entry, caching if needed.
ftl::list::get_mime_type() {
        if [[ -z "${ftl_list_mime_cache[$ftl_state_current_path]:-}" ]] ; then
                _ftl::list::cache_mime_types "$ftl_state_current_path"
        fi
        ftl_state_current_mime_type="${ftl_list_mime_cache[$ftl_state_current_path]:-}"
}

# Cache mime types for a batch of entries.
# Args:
#   $1: starting entry
_ftl::list::cache_mime_types() {
        local fm mm
        while IFS=':' read -r fm mm ; do
                mm=${mm## }
                ftl_list_mime_cache[$PWD/$fm]="$mm"
        done < <($ftl_cfg_mime_detector "$1" \
                "${ftl_list_entries[@]:$ftl_state_cursor_index:((ftl_state_cursor_index + 20))}" 2>&1)
}

# Quote all entries for safe shell passage.
# Outputs: quoted entries, one per line
ftl::list::quote_all_entries() {
        printf "%q\n" "${ftl_list_entries[@]}"
}

# Quote only directory entries.
ftl::list::quote_all_dirs() {
        printf "%q\n" "${ftl_list_entries[@]}" | perl -lne '-d && print'
}

# Quote only file entries.
ftl::list::quote_all_files() {
        printf "%q\n" "${ftl_list_entries[@]}" | perl -lne '-d || print'
}

# Quote the current selection.
ftl::list::quote_selection() {
        printf "%q\n" "${ftl_selection_current[@]}"
}

# vim: set filetype=bash :
