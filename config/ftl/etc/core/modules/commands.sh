# commands.sh — user-facing command functions
#
# This module defines all the commands that can be bound to keys. It's the
# largest module and is organized into sections by category. Each command
# is a function that takes no arguments (it reads state from globals) and
# performs its action, usually ending with ftl::list::render or
# ftl::list::change_dir to update the display.
#
# Sections:
#   1. Movement commands
#   2. Selection commands
#   3. File operation commands
#   4. Filter commands
#   5. Search commands
#   6. Tab commands
#   7. Pane commands
#   8. Preview commands
#   9. Shell commands
#  10. View mode commands
#  11. Mark/history commands
#  12. Quit commands
#  13. Signal handlers
#  14. Command prompt

#----------------------------------------------------------------------------
# 0. Shell-command dispatcher
#----------------------------------------------------------------------------

# Dispatch a command entered at the command prompt.
# Args:
#   $1: command string
ftl::cmd::dispatch_command() {
    # Empty command — cancel
    [[ "$1" == 0 ]] && return 1

    # Numeric — goto entry by index
    if [[ "$1" =~ ^[1-9][0-9]*$ ]] ; then
        ftl_state_cursor_index="${ftl_list_entries[$(( $1 - 1 ))]}"
        if [[ -d "$ftl_state_cursor_index" ]] ; then
            ftl::list::change_dir "$ftl_state_cursor_index"
        else
            ftl::list::render $(( $1 - 1 ))
        fi
        return 1
    fi

    # Built-in commands
    [[ "$1" == "qa" ]] && { ftl::cmd::quit_all ; return ; }
    [[ "$1" == "load_sel" ]] && { ftl::sel::load_from_file ; return ; }

    # Shortcut bound to a command
    if [[ -n "${ftl_kbd_trie[$1]:-}" ]] ; then
        ftl_state_pending_input=${ftl_kbd_trie[$1]}
        return
    fi
    if [[ -n "${ftl_kbd_command_to_key[$1]:-}" ]] ; then
        ftl_state_pending_input=${ftl_kbd_command_to_key[$1]}
        return
    fi

    # Split the command into parts
    local -a cmd_parts=()
    eval "$($FTL_CFG/etc/bin/parse_parts "$1")"
    local cmd="${cmd_parts[0]}"

    # Serialize ftl info for external commands
    ftl::state::serialize_info

    # User command
    local user_cmd="$FTL_CFG/commands/$cmd"
    if [[ -f "$user_cmd" ]] ; then
        if [[ ! -x "$user_cmd" ]] ; then
            source "$user_cmd" "${cmd_parts[@]:1}"
        else
            "$user_cmd" "${cmd_parts[@]:1}"
        fi
        return
    fi

    # Ensure the session shell exists
    if (( ! ftl_pane_session_shell_active )) ; then
        tmux new -A -d -s "ftl$$"
        tmux neww -t "ftl$$" -n "ftl$$_bash"
        sleep 0.2
        ftl_pane_session_shell_active=1
    fi

    # Check for command aliases
    if [[ -n "${ftl_cfg_command_aliases[$cmd]:-}" ]] ; then
        cmd_parts=(${ftl_cfg_command_aliases[$cmd]} $(printf "%s " "${cmd_parts[@]:1}"))
        cmd="${cmd_parts[0]}"
    fi

    # Built-in command forms
    if [[ "$cmd" == "full" ]] ; then
        ftl::prev::clear
        clear
        eval "${cmd_parts[@]:1}"
        ftl::list::change_dir
        return
    fi
    if [[ "$cmd" == "split" ]] ; then
        ftl::prev::clear
        tmux split-window -e ftl_state_info_file_path="$ftl_state_info_file_path" -l 50% \
            "$(printf "%s " "${cmd_parts[@]:1}")"
        ftl::list::change_dir
        tmux selectp -D
        return
    fi
    if [[ "$cmd" == "fsh" ]] ; then
        fsh "$(printf "%s " "${cmd_parts[@]:1}")"
        return
    fi

    # Run in the session shell
    {
        echo "export ftl_state_info_file_path=$ftl_state_info_file_path"
        echo "cd '$PWD'"
        echo "echo -e '\e[2;33m[$(date -R)] $PWD\n\e[0;33mftl> $@ \e[m'"
        echo "echo -e \"\e[33m[$(date -R)] $PWD\n\e[33mftl> $@ \e[m\" >>$ftl_state_session_dir/command.log"
        echo "${cmd_parts[@]}"
        echo "exit_code=\$?"
        echo "echo -e \"\e[33mexit code: \$exit_code\e[m\n\" >>$ftl_state_session_dir/command.log"
        echo "echo -e \"\n\e[2;33mexit code: \$exit_code\e[m\""
    } >"$ftl_state_session_dir/bash_command"
    tmux send -t "ftl$$:ftl$$_bash" ". $ftl_state_session_dir/bash_command" Enter
}

#----------------------------------------------------------------------------
# 1. Movement commands
#----------------------------------------------------------------------------

ftl::cmd::cursor_up() {
    if (( ftl_list_entry_count )) ; then
        ftl::list::move_cursor -1 && ftl::list::render
    fi
}

ftl::cmd::cursor_up_arrow() {
    ftl::cmd::cursor_up
}

ftl::cmd::cursor_down() {
    if (( ftl_list_entry_count )) ; then
        ftl::list::move_cursor 1 && ftl::list::render
    fi
}

ftl::cmd::cursor_down_arrow() {
    ftl::cmd::cursor_down
}

ftl::cmd::cd_to_parent() {
    [[ "$PWD" != / ]] || return 0
    local parent_dir="${PWD%/*}"
    ftl::list::change_dir "${parent_dir:-/}" "$(basename "$ftl_state_current_dir")"
}

ftl::cmd::cursor_left_arrow() {
    ftl::cmd::cd_to_parent
}

ftl::cmd::move_left() {
    ftl::cmd::cd_to_parent
}

ftl::cmd::cd_into_entry() {
    (( ftl_list_entry_count )) || return 0
    [[ -d "${ftl_list_entries[$ftl_state_cursor_index]}" ]] \
        && ftl::list::change_dir "${ftl_list_entries[$ftl_state_cursor_index]}"
}

ftl::cmd::move_right() {
    ftl::cmd::cd_into_entry
}

ftl::cmd::cursor_right_arrow() {
    ftl::cmd::cd_into_entry
}

ftl::cmd::cursor_up_step() {
    if (( ftl_list_entry_count )) ; then
        ftl::list::move_cursor "-$ftl_cfg_move_step_size" && ftl::list::render
    fi
}

ftl::cmd::cursor_down_step() {
    if (( ftl_list_entry_count )) ; then
        ftl::list::move_cursor "$ftl_cfg_move_step_size" && ftl::list::render
    fi
}

ftl::cmd::enter_entry() {
    (( ftl_list_entry_count )) || return 0
    if [[ -f "${ftl_list_entries[$ftl_state_cursor_index]}" ]] ; then
        ftl::cmd::edit_current
    elif [[ -d "${ftl_list_entries[$ftl_state_cursor_index]}" ]] ; then
        ftl::list::change_dir "${ftl_list_entries[$ftl_state_cursor_index]}"
    fi
}

ftl::cmd::enter() {
    ftl::cmd::enter_entry
}

ftl::cmd::page_up() {
    ftl::list::move_cursor "-$ftl_pane_height"
    ftl::list::render
}

ftl::cmd::move_page_up() {
    ftl::cmd::page_up
}

ftl::cmd::page_down() {
    ftl::list::move_cursor "$ftl_pane_height"
    ftl::list::render
}

ftl::cmd::move_page_down() {
    ftl::cmd::page_down
}

ftl::cmd::cycle_top_file_bottom() {
    local twd="${ftl_state_current_tab_index}_$PWD"
    if [[ -f "$ftl_state_current_path" ]] ; then
        if (( ftl_state_cursor_index == ftl_list_entry_count - 1 )) ; then
            ftl_state_cursor_memory[$twd]=0
        else
            ftl_state_cursor_memory[$twd]=$ftl_list_entry_count
        fi
    else
        ftl_state_cursor_memory[$twd]=$ftl_list_first_file_index
    fi
    ftl::list::render
}

ftl::cmd::top_file_bottom() {
    ftl::cmd::cycle_top_file_bottom
}

ftl::cmd::goto_first_directory() {
    local twd="${ftl_state_current_tab_index}_$PWD"
    (( ftl_list_entry_count )) && ftl_state_cursor_memory[$twd]=0
    ftl::list::render
}

ftl::cmd::goto_first_file() {
    local twd="${ftl_state_current_tab_index}_$PWD"
    (( ftl_list_entry_count )) && ftl_state_cursor_memory[$twd]=$ftl_list_first_file_index
    ftl::list::render
}

ftl::cmd::goto_last_file() {
    local twd="${ftl_state_current_tab_index}_$PWD"
    (( ftl_list_entry_count )) && ftl_state_cursor_memory[$twd]=$ftl_list_entry_count
    ftl::list::render
}

ftl::cmd::goto_top_of_window() {
    local twd="${ftl_state_current_tab_index}_$PWD"
    ftl_state_cursor_memory[$twd]=$ftl_list_window_top
    ftl::list::render
}

ftl::cmd::goto_high_file() {
    ftl::cmd::goto_top_of_window
}

ftl::cmd::goto_bottom_of_window() {
    local twd="${ftl_state_current_tab_index}_$PWD"
    ftl_state_cursor_memory[$twd]=$ftl_list_window_bottom
    ftl::list::render
}

ftl::cmd::goto_low_file() {
    ftl::cmd::goto_bottom_of_window
}

ftl::cmd::jump_by_percent() {
    local twd="${ftl_state_current_tab_index}_$PWD"
    (( ftl_list_entry_count )) \
        && ftl_state_cursor_memory[$twd]=$(( ftl_list_entry_count * ftl_kbd_count / 100 ))
    ftl::list::render
}

ftl::cmd::move_percent() {
    ftl::cmd::jump_by_percent
}

ftl::cmd::goto_next_same_extension() {
    ftl_state_search_string=".$ftl_state_current_extension"
    ftl_state_pending_input="${ftl_kbd_command_to_key[find_next]}"
}

ftl::cmd::goto_alt1() {
    ftl::cmd::goto_next_same_extension
}

ftl::cmd::goto_next_diff_extension() {
    local i
    for (( i = ftl_state_cursor_index + 1 ; i != ftl_list_entry_count ; i++ )) ; do
        if [[ ! "${ftl_list_entries[i]##*/}" =~ ".$ftl_state_current_extension" ]] ; then
            ftl::list::render "$i"
            return
        fi
    done
    ftl::list::render
}

ftl::cmd::goto_alt2() {
    ftl::cmd::goto_next_diff_extension
}

ftl::cmd::goto_by_index() {
    ftl_cfg_line_color_current="$ftl_cfg_line_color_highlight"
    ftl::list::change_dir
    ftl_cfg_line_color_current="$ftl_cfg_line_color_default"
    ftl::cmd::prompt 'to: '
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        ftl::cmd::dispatch_command "$ftl_kbd_current_key"
    else
        ftl::list::change_dir
    fi
}

ftl::cmd::goto_entry() {
    ftl::cmd::goto_by_index
}

ftl::cmd::goto_next_selected() {
    (( ${#ftl_selection_tags[@]} )) || return 0
    [[ -z "$ftl_selection_class_cursor" ]] && ftl_selection_class_cursor=0
    (( ftl_selection_class_cursor++ ))
    (( ftl_selection_class_cursor >= ${#ftl_selection_tags[@]} )) && ftl_selection_class_cursor=0
    ftl::sel::goto_by_index "$ftl_selection_class_cursor"
}

ftl::cmd::goto_next_tag() {
    ftl::cmd::goto_next_selected
}

ftl::cmd::goto_prev_selected() {
    (( ${#ftl_selection_tags[@]} )) || return 0
    [[ -z "$ftl_selection_class_cursor" ]] && ftl_selection_class_cursor=0
    (( ftl_selection_class_cursor-- ))
    (( ftl_selection_class_cursor < 0 )) \
        && ftl_selection_class_cursor=$(( ${#ftl_selection_tags[@]} - 1 ))
    ftl::sel::goto_by_index "$ftl_selection_class_cursor"
}

ftl::cmd::goto_prev_tag() {
    ftl::cmd::goto_prev_selected
}

ftl::cmd::cd_prompt() {
    ftl::cmd::prompt 'cd: '
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        ftl::list::change_dir "${ftl_kbd_current_key/\~/$HOME}"
    else
        ftl::list::render
    fi
}

ftl::cmd::change_dir() {
    ftl::cmd::cd_prompt
}

#----------------------------------------------------------------------------
# 2. Selection commands
#----------------------------------------------------------------------------

ftl::cmd::select_all() {
    local p
    for p in "${ftl_list_entries[@]}" ; do
        [[ -z "${ftl_selection_tags[$p]:-}" ]] \
            && ftl_selection_tags["$p"]='▪' \
            && ftl::sel::adjust_total_size + "$p"
    done
    ftl::list::render
}

ftl::cmd::select_all_files() {
    local p
    for p in "${ftl_list_entries[@]}" ; do
        if [[ -f "$p" && -z "${ftl_selection_tags[$p]:-}" ]] ; then
            ftl_selection_tags["$p"]='▪'
            ftl::sel::adjust_total_size + "$p"
        fi
    done
    ftl::list::render
}

ftl::cmd::select_all_directories() {
    local p
    for p in "${ftl_list_entries[@]}" ; do
        if [[ -d "$p" && -z "${ftl_selection_tags[$p]:-}" ]] ; then
            ftl_selection_tags["$p"]='▪'
            ftl::sel::adjust_total_size + "$p"
        fi
    done
    ftl::list::render
}

ftl::cmd::flip_down() {
    local i
    local count="${ftl_kbd_count:-1}"
    for (( i = ftl_state_cursor_index ; i < ftl_state_cursor_index + count && i < ftl_list_entry_count ; i++ )) ; do
        ftl::sel::flip "${ftl_list_entries[i]}"
    done
    ftl::list::move_cursor "${count}"
    ftl::list::render
}

ftl::cmd::selection_flip_down() {
    ftl::cmd::flip_down
}

ftl::cmd::flip_up() {
    local i
    local count="${ftl_kbd_count:-1}"
    for (( i = ftl_state_cursor_index ; i > ftl_state_cursor_index - count && i > 0 ; i-- )) ; do
        ftl::sel::flip "${ftl_list_entries[i]}"
    done
    ftl::list::move_cursor "-${count}"
    ftl::list::render
}

ftl::cmd::selection_flip_up() {
    ftl::cmd::flip_up
}

_ftl::cmd::select_class_with_count() {
    local class="$1"
    local i
    local count="${ftl_kbd_count:-1}"
    for (( i = 0 ; i < count && ftl_state_cursor_index < ftl_list_entry_count ; i++ )) ; do
        _ftl::cmd::toggle_class "$class"
        ftl::list::move_cursor 1
        ftl_state_cursor_index=$nf
    done
    (( ftl_selection_revision++ ))
    ftl::list::render
}

_ftl::cmd::toggle_class() {
    local class="$1"
    local entry="${ftl_list_entries[$ftl_state_cursor_index]}"
    if [[ "${ftl_selection_tags[$entry]:-}" == "${ftl_cfg_glyph_tag_classes[$class]}" ]] ; then
        unset 'ftl_selection_tags[$entry]'
    else
        ftl_selection_tags[$entry]=${ftl_cfg_glyph_tag_classes[$class]}
    fi
}

ftl::cmd::select_class_1() { _ftl::cmd::select_class_with_count 1 ; }
ftl::cmd::select_class_2() { _ftl::cmd::select_class_with_count 2 ; }
ftl::cmd::select_class_3() { _ftl::cmd::select_class_with_count 3 ; }
ftl::cmd::select_class_4() { _ftl::cmd::select_class_with_count 4 ; }

ftl::cmd::selection_class_1() { ftl::cmd::select_class_1 ; }
ftl::cmd::selection_class_2() { ftl::cmd::select_class_2 ; }
ftl::cmd::selection_class_3() { ftl::cmd::select_class_3 ; }
ftl::cmd::selection_class_4() { ftl::cmd::select_class_4 ; }

ftl::cmd::untag_all() {
    ftl::sel::clear_all
    ftl::list::render
}

ftl::cmd::selection_untag_all() {
    ftl::cmd::untag_all
}

ftl::cmd::untag_via_fzf() {
    ftl::sel::validate_existence || return 0
    ftl::sel::fzf_tag_or_untag U "$(printf "%s\n" "${!ftl_selection_tags[@]}" \
        | lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '⊟')"
    ftl::list::render
}

ftl::cmd::selection_untag_fzf() {
    ftl::cmd::untag_via_fzf
}

ftl::cmd::copy_paths_to_clipboard() {
    ftl::list::quote_selection | xsel -b -i
}

ftl::cmd::copy_clipboard() {
    ftl::cmd::copy_paths_to_clipboard
}

ftl::cmd::select_same_extension() {
    local oifs="$IFS"
    IFS=$'\n'
    local p
    for p in $(fd -H -I -d1 | sed 's/^.\///' | rg "\.$ftl_state_current_extension$") ; do
        ftl::sel::set "$PWD/$p"
    done
    IFS="$oifs"
    ftl::list::render
}

ftl::cmd::selection_ext() {
    ftl::cmd::select_same_extension
}

ftl::cmd::select_same_extension_recursive() {
    local oifs="$IFS"
    IFS=$'\n'
    local p
    for p in $(fd -H -I | sed 's/^.\///' | rg "\.$ftl_state_current_extension$") ; do
        ftl::sel::set "$PWD/$p"
    done
    IFS="$oifs"
    ftl::list::render
}

ftl::cmd::selection_ext_all() {
    ftl::cmd::select_same_extension_recursive
}

ftl::cmd::select_extension_via_fzf() {
    ftl::sel::fzf_tag_or_untag T "$(fd -H -I -d1 | rg "\.$ftl_state_current_extension$" \
        | lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '▪')"
    ftl::list::render
}

ftl::cmd::selection_ext_fzf() {
    ftl::cmd::select_extension_via_fzf
}

ftl::cmd::select_extension_recursive_via_fzf() {
    ftl::sel::fzf_tag_or_untag T "$(fd -H -I | rg "\.$ftl_state_current_extension$" \
        | lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '▪')"
    ftl::list::render
}

ftl::cmd::selection_ext_all_fzf() {
    ftl::cmd::select_extension_recursive_via_fzf
}

ftl::cmd::select_via_fzf() {
    ftl::sel::fzf_tag_or_untag T "$(fd -H -I --color=always -d1 \
        | fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '▪')"
    ftl::list::render
}

ftl::cmd::selection_fzf() {
    ftl::cmd::select_via_fzf
}

ftl::cmd::select_recursive_via_fzf() {
    ftl::sel::fzf_tag_or_untag T "$(fd -H -I --color=always \
        | fzf-tmux $ftl_cfg_fzf_popup_opts -m --ansi --marker '▪')"
    ftl::list::render
}

ftl::cmd::selection_fzf_all() {
    ftl::cmd::select_recursive_via_fzf
}

ftl::cmd::select_images_via_sxiv() {
    local oifs="$IFS"
    IFS=$'\n'
    local i
    for i in $(ftl::list::quote_all_files | $ftl_cfg_image_viewer -i -b -q -o -f -t) ; do
        ftl_selection_tags[$i]='▪'
        ftl::sel::adjust_total_size + "$i"
    done
    IFS="$oifs"
    ftl::list::change_dir
}

ftl::cmd::image_select() {
    ftl::cmd::select_images_via_sxiv
}

ftl::cmd::select_images_recursive_via_sxiv() {
    local oifs="$IFS"
    IFS=$'\n'
    local image
    for image in $($ftl_cfg_image_viewer -b -q -o -f -t *) ; do
        ftl_selection_tags[$PWD/$image]='▪'
        ftl::sel::adjust_total_size + "$image"
    done
    IFS="$oifs"
    ftl::list::change_dir
}

ftl::cmd::image_select_rec() {
    ftl::cmd::select_images_recursive_via_sxiv
}

ftl::cmd::goto_selection_via_fzf() {
    ftl::sel::validate_existence || return 0
    _ftl::cmd::process_search_results f fzf "$(printf "%s\n" "${!ftl_selection_tags[@]}" \
        | sort -u | lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts --tac --ansi --expect=ctrl-t)"
}

ftl::cmd::selection_goto() {
    ftl::cmd::goto_selection_via_fzf
}

ftl::cmd::merge_from_panes() {
    local p="$FTL_CFG/etc/core/lib/merge"
    local file
    file=$(cd "$p" 2>&- && fd | fzf-tmux --header 'Merge tags:' $ftl_cfg_fzf_popup_opts)
    [[ -n "$file" ]] && source "$p/$file"
    ftl::list::change_dir
}

ftl::cmd::selection_merge() {
    ftl::cmd::merge_from_panes
}

ftl::cmd::merge_all_panes() {
    source "$FTL_CFG/etc/core/lib/merge/all"
    ftl::list::render
}

ftl::cmd::selection_merge_all() {
    ftl::cmd::merge_all_panes
}

ftl::cmd::append_selection_to_file() {
    ftl::cmd::prompt 'add selection to: '
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        ftl::list::quote_selection >> "$ftl_kbd_current_key"
    fi
    ftl::list::change_dir
}

ftl::cmd::add_selection_to_file() {
    ftl::cmd::append_selection_to_file
}

#----------------------------------------------------------------------------
# 3. File operation commands
#----------------------------------------------------------------------------

ftl::cmd::edit_current() {
    ftl::prev::clear
    ftl::util::enter_alt_screen
    ftl::pane::stop_file_watcher
    ${ftl_cfg_editor} "${1:-${ftl_list_entries[$ftl_state_cursor_index]}}"
    ftl::util::enter_alt_screen
    ftl_state_external_viewer_mode=0
    ftl::list::change_dir
}

ftl::cmd::edit() {
    ftl::cmd::edit_current
}

ftl::cmd::edit_in_vim() {
    ftl::prev::clear
    $ftl_cfg_editor "${ftl_selection_current[@]}"
    ftl::list::change_dir
}

ftl::cmd::vim_edit() {
    ftl::cmd::edit_in_vim
}

ftl::cmd::edit_in_vim_window() {
    tmux new-window "$ftl_cfg_editor ${ftl_selection_current[*]@Q}"
}

ftl::cmd::vim_edit_window() {
    ftl::cmd::edit_in_vim_window
}

ftl::cmd::edit_in_shared_vim_window() {
    if ftl::pane::window_exists "v$$" ; then
        _ftl::cmd::open_files_in_shared_vim "${ftl_selection_current[@]}"
    else
        ftl::cmd::edit_in_vim_window -n "v$$"
    fi
    tmux select-window -t "v$$"
}

ftl::cmd::vim_edit_shared_window() {
    ftl::cmd::edit_in_shared_vim_window
}

_ftl::cmd::open_files_in_shared_vim() {
    local a
    for a in "$@" ; do
        tmux send-keys -t "v$$" Escape escape :tabe \ "$(printf '%q\n' "$a")" ENTER
    done
}

ftl::cmd::vim_tabe_shared_window() {
    _ftl::cmd::open_files_in_shared_vim
}

ftl::cmd::cat_in_terminal() {
    ftl::pane::split_or_respawn "cat ${ftl_state_current_path@Q} ; read -sn 100"
}

ftl::cmd::terminal_cat() {
    ftl::cmd::cat_in_terminal
}

ftl::cmd::hex_view() {
    ftl::pane::split_or_respawn "$ftl_cfg_hex_viewer ${ftl_state_current_path@Q} ; read -sn 100"
}

ftl::cmd::hexview() {
    ftl::cmd::hex_view
}

ftl::cmd::hex_edit() {
    ftl::pane::split_or_respawn "$ftl_cfg_hex_editor ${ftl_state_current_path@Q}"
}

ftl::cmd::hexedit() {
    ftl::cmd::hex_edit
}

ftl::cmd::copy_to_prompted() {
    ftl::cmd::prompt 'write to: '
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        if ftl::sel::validate_existence ; then
            _ftl::cmd::copy_or_move_with_tags copy "$ftl_kbd_current_key"
        else
            _ftl::cmd::copy_or_move copy "$ftl_kbd_current_key" "${ftl_selection_current[@]}"
        fi
    fi
    ftl::list::change_dir
}

ftl::cmd::copy() {
    ftl::cmd::copy_to_prompted
}

ftl::cmd::delete_selection() {
    (( ftl_list_entry_count )) || return 0
    local pc="" pt=""
    if ftl::sel::validate_existence ; then
        pc="|c"
        pt="*tags* "
    fi
    ftl::cmd::prompt "delete $pt[y|d|N$pc] ? " -n1
    _ftl::cmd::dispatch_delete "$pt"
    ftl_kbd_current_key=
    ftl::list::change_dir
}

ftl::cmd::delete_selection_cmd() {
    ftl::cmd::delete_selection
}

_ftl::cmd::dispatch_delete() {
    local pt="$1"
    if [[ -n "$pt" ]] ; then
        if [[ $ftl_kbd_current_key =~ y|d ]] ; then
            _ftl::cmd::delete_tagged
        elif [[ $ftl_kbd_current_key =~ c ]] ; then
            _ftl::cmd::delete_current
        fi
    else
        if [[ $ftl_kbd_current_key =~ y|d ]] ; then
            _ftl::cmd::delete_current
        fi
    fi
}

_ftl::cmd::delete_current() {
    if [[ "${ftl_selection_tags[$ftl_state_current_path]:-}" ]] ; then
        unset 'ftl_selection_tags[$ftl_state_current_path]'
        ftl::sel::adjust_total_size - "$ftl_state_current_path"
        (( ftl_selection_revision++ ))
    fi
    $ftl_cfg_delete_command "$ftl_state_current_path"
    ftl_list_mime_cache=()
    true
}

_ftl::cmd::delete_tagged() {
    declare -A ltags
    ftl::sel::get_by_class ltags class
    (( ${#ltags[@]} )) || return 0
    ftl::sel::unset_by_class "$class"
    $ftl_cfg_delete_command "${!ltags[@]}"
    ftl_list_mime_cache=()
    true
}

ftl::cmd::create_file() {
    ftl::cmd::prompt 'touch: '
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        touch "$PWD/$ftl_kbd_current_key"
    fi
    ftl::list::change_dir "$PWD" "$ftl_kbd_current_key"
}

ftl::cmd::create_file_cmd() {
    ftl::cmd::create_file
}

ftl::cmd::create_dir_no_cd() {
    ftl::cmd::prompt 'mkdir: '
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        mkdir -p "$PWD/$ftl_kbd_current_key"
    fi
    ftl::list::change_dir
}

ftl::cmd::create_dir_no_cd_cmd() {
    ftl::cmd::create_dir_no_cd
}

ftl::cmd::create_dir_and_cd() {
    ftl::cmd::prompt 'mkdir: '
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        mkdir -p "$PWD/$ftl_kbd_current_key" \
            && ftl::list::change_dir "$PWD/$ftl_kbd_current_key" \
            || ftl::list::render
    else
        ftl::list::render
    fi
}

ftl::cmd::create_dir() {
    ftl::cmd::create_dir_and_cd
}

ftl::cmd::create_bulk() {
    local bulk_file="$ftl_state_session_dir/BULK"
    : >"$bulk_file"
    $ftl_cfg_editor "$bulk_file"
    if [[ -s "$bulk_file" ]] ; then
        grep '/$' "$bulk_file" | tr '\n' '\0' | xargs -r -0 mkdir -p
        _ftl::cmd::create_bulk_files "$bulk_file"
    fi
    ftl::list::change_dir
}

ftl::cmd::create_bulk_cmd() {
    ftl::cmd::create_bulk
}

_ftl::cmd::create_bulk_files() {
    grep -v '/$' "$1" | tr '\n' '\0' | xargs -r -0 dirname -z | xargs -0 mkdir -p
    grep -v '/$' "$1" | grep -v '^$' | tr '\n' '\0' | xargs -r -0 touch
}

ftl::cmd::rename_selection() {
    ftl::prev::clear
    printf "%s\n" "${ftl_selection_current[@]}" | edir
    ftl::sel::clear_all
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::rename() {
    ftl::cmd::rename_selection
}

ftl::cmd::symlink_selection() {
    ftl::sel::validate_existence && ftl::cmd::prompt "Link (${#ftl_selection_tags[@]})? [y|N]" -sn1
    if [[ $ftl_kbd_current_key == y ]] ; then
        ftl::sel::clear_all
        local f
        for f in "${ftl_selection_current[@]}" ; do
            ln -s -b "$f" .
        done
    fi
    ftl::list::change_dir
}

ftl::cmd::link() {
    ftl::cmd::symlink_selection
}

ftl::cmd::follow_symlink() {
    [[ -L "$ftl_state_current_path" ]] || return 0
    local resolved
    resolved=$(realpath "$ftl_state_current_path")
    ftl::list::change_dir "$(dirname "$resolved")" "$(basename "$resolved")"
}

ftl::cmd::follow_link() {
    ftl::cmd::follow_symlink
}

ftl::cmd::chmod_toggle_read() {
    local i mode
    for i in "${ftl_selection_current[@]}" ; do
        if [[ -r "$i" ]] ; then mode=a-r ; else mode=a+r ; fi
        chmod "$mode" "$i"
    done
    ftl::list::change_dir
}

ftl::cmd::chmod_ar() {
    ftl::cmd::chmod_toggle_read
}

ftl::cmd::chmod_toggle_write() {
    local i mode
    for i in "${ftl_selection_current[@]}" ; do
        if [[ -w "$i" ]] ; then mode=a-w ; else mode=a+w ; fi
        chmod "$mode" "$i"
    done
    ftl::list::change_dir
}

ftl::cmd::chmod_aw() {
    ftl::cmd::chmod_toggle_write
}

ftl::cmd::chmod_toggle_exec() {
    local i mode
    for i in "${ftl_selection_current[@]}" ; do
        if [[ -x "$i" ]] ; then mode=a-x ; else mode=a+x ; fi
        chmod "$mode" "$i"
    done
    ftl::list::change_dir
}

ftl::cmd::chmod_ax() {
    ftl::cmd::chmod_toggle_exec
}

ftl::cmd::chmod_via_scim() {
    ftl::prev::clear
    exec 2>&9
    "$FTL_CFG/etc/bin/scim_permission" "${ftl_selection_current[@]}"
    exec 2>"$ftl_state_session_dir/log"
    ftl::util::enter_alt_screen
}

ftl::cmd::chmod_dialog() {
    ftl::cmd::chmod_via_scim
}

ftl::cmd::copy_selection_here() {
    _ftl::cmd::copy_or_move_with_tags copy "${1:-$PWD}"
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::tag_copy() {
    ftl::cmd::copy_selection_here
}

ftl::cmd::move_selection_here() {
    _ftl::cmd::copy_or_move_with_tags move "${1:-$PWD}"
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::tag_move() {
    ftl::cmd::move_selection_here
}

ftl::cmd::copy_to_preset() {
    read -n 1
    if [[ -n "$ftl_kbd_current_key" && -n "${ftl_cfg_preset_destinations[$ftl_kbd_current_key]:-}" ]] ; then
        ftl::cmd::copy_selection_here "${ftl_cfg_preset_destinations[$ftl_kbd_current_key]}"
    fi
}

ftl::cmd::tag_copy_dest() {
    ftl::cmd::copy_to_preset
}

ftl::cmd::move_to_preset() {
    read -n 1
    if [[ -n "$ftl_kbd_current_key" && -n "${ftl_cfg_preset_destinations[$ftl_kbd_current_key]:-}" ]] ; then
        ftl::cmd::move_selection_here "${ftl_cfg_preset_destinations[$ftl_kbd_current_key]}"
    fi
}

ftl::cmd::tag_move_dest() {
    ftl::cmd::move_to_preset
}

ftl::cmd::move_via_fzf() {
    declare -A ltags
    ftl::sel::get_by_class ltags class
    if (( ${#ltags[@]} )) ; then
        fzf_mv "${!ltags[@]}" && ftl::sel::unset_by_class "$class"
        true
    else
        fzf_mv "$ftl_state_current_basename"
    fi
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::tag_move_fzf() {
    ftl::cmd::move_via_fzf
}

ftl::cmd::move_to_subdir_via_fzf() {
    declare -A ltags
    ftl::sel::get_by_class ltags class
    if (( ${#ltags[@]} )) ; then
        fzf_mv_sd "${!ltags[@]}" && ftl::sel::unset_by_class "$class"
        true
    else
        fzf_mv_sd "$ftl_state_current_basename"
    fi
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::tag_move_fzf_sd() {
    ftl::cmd::move_to_subdir_via_fzf
}

ftl::cmd::copy_to_other_tab() {
    ftl::sel::validate_existence || return 1
    local other_dir
    other_dir="$(_ftl::cmd::find_other_tab_dir)"
    if [[ -n "$other_dir" ]] ; then
        ftl::cmd::copy_selection_here "$other_dir"
        ftl::list::change_dir '' "$ftl_state_current_basename"
    else
        ftl::plugin::to_other_tab::create_tab_for_move
    fi
}

ftl::cmd::tag_copy_to_tab() {
    ftl::cmd::copy_to_other_tab
}

ftl::cmd::move_to_other_tab() {
    ftl::sel::validate_existence || return 1
    local other_dir
    other_dir="$(_ftl::cmd::find_other_tab_dir)"
    if [[ -n "$other_dir" ]] ; then
        ftl::cmd::move_selection_here "$other_dir"
        ftl::list::change_dir '' "$ftl_state_current_basename"
    else
        ftl::plugin::to_other_tab::create_tab_for_move
    fi
}

ftl::cmd::tag_move_to_tab() {
    ftl::cmd::move_to_other_tab
}

_ftl::cmd::find_other_tab_dir() {
    if (( ftl_tab_count > 2 )) ; then
        _ftl::plugin::to_other_tab::pick_via_fzf
        return $?
    fi
    _ftl::plugin::to_other_tab::pick_single
}

_ftl::cmd::copy_or_move_with_tags() {
    declare -A ltags
    ftl::sel::get_by_class ltags class
    if (( ${#ltags[@]} )) ; then
        ftl::sel::unset_by_class "$class"
        _ftl::cmd::copy_or_move "$1" "$2" "${!ltags[@]}"
    else
        _ftl::cmd::copy_or_move "$1" "$2" "$ftl_state_current_basename"
    fi
    true
}

_ftl::cmd::copy_or_move() {
    if [[ $1 == copy ]] ; then
        _ftl::cmd::do_copy "$@"
    else
        _ftl::cmd::do_move "$@"
    fi
    sleep 0.01
}

_ftl::cmd::do_copy() {
    local cmvs="$ftl_state_session_dir/cmv_$SECONDS"
    printf '%s\n' "${@:3}" >"$cmvs"
    ftl::pane::run_in_bg_window \
        "xargs -a $cmvs -t -I{} -- cp -r \$'{}' ${2@Q}"
}

_ftl::cmd::do_move() {
    local cmvs="$ftl_state_session_dir/cmv_$SECONDS"
    printf '%s\0' "${@:3}" >"$cmvs"
    ftl::pane::run_in_bg_window \
        "xargs -0 -a $cmvs -t -- mv -t ${2@Q}"
}

ftl::cmd::preview_with_command() {
    ftl::cmd::prompt 'preview with: '
    ftl::list::render
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        ftl::prev::clear
        ftl::pane::split "$ftl_kbd_current_key '$ftl_state_current_basename' ; read -sn1"
    else
        ftl::list::change_dir
    fi
}

ftl::cmd::preview_with() {
    ftl::cmd::preview_with_command
}

#----------------------------------------------------------------------------
# 4. Filter commands
#----------------------------------------------------------------------------

ftl::cmd::set_filter_1() {
    ftl::cmd::prompt "filter: " -i "${ftl_tab_filter_1[$ftl_state_current_tab_index]}"
    ftl_tab_filter_1[$ftl_state_current_tab_index]="${ftl_kbd_current_key:-.}"
    ftl_filt_active_glyph="~"
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter() {
    ftl::cmd::set_filter_1
}

ftl::cmd::set_filter_2() {
    ftl::cmd::prompt "filter2: " -i "${ftl_tab_filter_2[$ftl_state_current_tab_index]}"
    ftl_tab_filter_2[$ftl_state_current_tab_index]="${ftl_kbd_current_key:-.}"
    ftl_filt_active_glyph="~"
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter2() {
    ftl::cmd::set_filter_2
}

ftl::cmd::set_dir_filter() {
    ftl::cmd::prompt "filter dir: " -i "${ftl_tab_filter_dirs[$ftl_state_current_tab_index]}"
    ftl_tab_filter_dirs[$ftl_state_current_tab_index]="${ftl_kbd_current_key:-.}"
    ftl_filt_active_glyph="~"
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter_dir() {
    ftl::cmd::set_dir_filter
}

ftl::cmd::set_reverse_filter() {
    ftl::cmd::prompt "rfilter: " -i "${ftl_tab_filter_reverse[$ftl_state_current_tab_index]}"
    ftl_tab_filter_reverse[$ftl_state_current_tab_index]="$ftl_kbd_current_key"
    ftl_filt_active_glyph="~"
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter_reverse() {
    ftl::cmd::set_reverse_filter
}

ftl::cmd::select_external_filter() {
    local filter_name
    filter_name=$(cd "$FTL_CFG/filters" ; fd | fzf-tmux -p 50% --cycle)
    ftl::filt::load_external "$filter_name"
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter_ext() {
    ftl::cmd::select_external_filter
}

ftl::cmd::filter_to_tagged() {
    ftl::filt::load_external by_only_tagged
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_filter_only_tagged() {
    ftl::cmd::filter_to_tagged
}

ftl::cmd::clear_all_filters() {
    local t=$ftl_state_current_tab_index
    ftl_tab_filter_dirs[$t]='.'
    ftl_tab_filter_1[$t]='.'
    ftl_tab_filter_2[$t]='.'
    ftl_tab_filter_reverse[$t]="$ftl_cfg_default_reverse_filter"
    ftl_tab_filter_image_negate[$t]=
    ftl::filt::reset
    ftl_filt_active_glyph=
    ftl::list::change_dir
}

ftl::cmd::clear_filters() {
    ftl::cmd::clear_all_filters
}

#----------------------------------------------------------------------------
# 5. Search commands
#----------------------------------------------------------------------------

ftl::cmd::find_in_dir() {
    ftl::cmd::prompt "find: " -i "$ftl_state_search_string"
    ftl_state_pending_input="${ftl_kbd_command_to_key[find_next]}"
}

ftl::cmd::find_entry() {
    ftl::cmd::find_in_dir
}

ftl::cmd::find_next() {
    local i
    for (( i = ftl_state_cursor_index + 1 ; i != ftl_list_entry_count ; i++ )) ; do
        if [[ "${ftl_list_entries[i]##*/}" =~ "$ftl_state_search_string" ]] ; then
            ftl::list::render "$i"
            return
        fi
    done
    ftl::list::render
}

ftl::cmd::find_previous() {
    local i
    for (( i = ftl_state_cursor_index - 1 ; i != -1 ; i-- )) ; do
        if [[ "${ftl_list_entries[i]##*/}" =~ "$ftl_state_search_string" ]] ; then
            ftl::list::render "$i"
            return
        fi
    done
    ftl::list::render
}

ftl::cmd::find_via_fzf() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results fzf \
        "$({ fd -HI -d1 -td | sort ; fd -HI -d1 -tf -tl | sort ; } \
            | sed 's/^.\///' | fzf_vvip -m $ftl_cfg_fzf_pane_opts)"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_fzf() {
    ftl::cmd::find_via_fzf
}

ftl::cmd::find_via_fzf_recursive() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results fzf \
        "$(fd -HI -E'.git/*' | sed 's/^.\///' | fzf_vvip -m $ftl_cfg_fzf_pane_opts)"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_fzf_all() {
    ftl::cmd::find_via_fzf_recursive
}

ftl::cmd::find_dirs_via_fzf() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results fzf \
        "$(fd -td -I -L | sed 's/^.\///' | fzf_vvip -m $ftl_cfg_fzf_pane_opts)"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_fzf_dirs() {
    ftl::cmd::find_dirs_via_fzf
}

ftl::cmd::find_via_frf() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results fzf "$(frf 1 '' ctrl-t)"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_frf() {
    ftl::cmd::find_via_frf
}

ftl::cmd::find_via_frf_recursive() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results fzf "$(frf 1000 '' ctrl-t)"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::find_frf_all() {
    ftl::cmd::find_via_frf_recursive
}

ftl::cmd::rg_open_file() {
    exec 2>&9
    ftl::prev::clear
    local rg_e
    rg_e="$(fzfr fzf+m)"
    exec 2>"$ftl_state_session_dir/log"
    ftl::util::enter_alt_screen
    [[ -n "$rg_e" ]] && $ftl_cfg_editor $(<<<"$rg_e" awk -F: '{printf "%s +%s", $1, $2}')
}

ftl::cmd::open_rg() {
    ftl::cmd::rg_open_file
}

ftl::cmd::rg_goto_file() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results rg "$(fzfr "fzf--expect=ctrl-t")"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::go_rg() {
    ftl::cmd::rg_goto_file
}

ftl::cmd::rg_goto_single_match() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results rg "$(frf 1000 '' ctrl-t frg)"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::go_rg_one_match() {
    ftl::cmd::rg_goto_single_match
}

ftl::cmd::rg_edit_files() {
    exec 2>&9
    ftl::prev::clear
    local rgls
    rgls="$(_ftl::cmd::build_vim_args_from_rg)"
    [[ -n "$rgls" ]] && /bin/bash -c "$ftl_cfg_editor $rgls"
    exec 2>"$ftl_state_session_dir/log"
    ftl::list::change_dir
}

ftl::cmd::go_rgl() {
    ftl::cmd::rg_edit_files
}

_ftl::cmd::build_vim_args_from_rg() {
    local gls=""
    local g l _
    while IFS=: read -r g l _ ; do
        [[ -z "$g" ]] && continue
        if [[ -n "$gls" ]] ; then
            gls+=" -c \"tabe +$l $g\""
        else
            gls+=" +$l $g"
        fi
    done <<<"$(fzfr)"
    echo "$gls"
}

_ftl::cmd::process_search_results() {
    local type="$1"
    local results="$2"
    local prev_pwd=
    local in_tab=
    local dst

    if [[ $type == "f" ]] ; then
        prev_pwd=
        shift
    else
        prev_pwd="$PWD"
    fi
    shift

    while read -r dst ; do
        _ftl::cmd::check_open_in_tab "$dst"
        if [[ $type == "fzf" ]] ; then
            _ftl::cmd::goto_fzf_result "$in_tab" "$prev_pwd" "$dst"
        elif [[ $type == "rg" ]] ; then
            _ftl::cmd::goto_rg_result "$in_tab" "$prev_pwd" "$dst"
        fi
    done <<<"$results"
}

_ftl::cmd::check_open_in_tab() {
    if [[ -z "$in_tab" ]] ; then
        if [[ "$1" == ctrl-t ]] ; then
            in_tab=1
        else
            in_tab=0
        fi
    fi
}

_ftl::cmd::goto_fzf_result() {
    local in_tab="$1"
    local prev_pwd="$2"
    local dst="$3"
    local d
    d="$(dirname "$dst")"
    (( in_tab )) && ftl::tab::create
    local nd
    if [[ -n "$prev_pwd" ]] ; then
        nd="$prev_pwd/$d"
    else
        nd="$d"
    fi
    local dst_basename
    dst_basename="$(basename "$dst")"
    if [[ -d "$nd/$dst_basename" ]] ; then
        ftl::list::change_dir "$nd/$dst_basename"
    else
        ftl::list::change_dir "$nd" "$dst_basename"
    fi
}

_ftl::cmd::goto_rg_result() {
    local in_tab="$1"
    local prev_pwd="$2"
    local dst="$3"
    local g l
    g=${dst%%:*}
    l=${dst#*:}
    l=${l%%:*}
    echo "$dst -> $g => $l" >&3
    local d
    d="$(dirname "$g")"
    (( in_tab )) && ftl::tab::create
    ftl::list::change_dir "$prev_pwd/$d" "$(basename "$g")"
}

ftl::cmd::goto_image_via_sxiv() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results f fzf \
        "$(ftl::list::quote_all_files | $ftl_cfg_image_viewer -i -b -q -o -f -t \
            | fzf-tmux $ftl_cfg_fzf_popup_opts $ftl_cfg_fzf_sxiv_opts)"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::image_go_sxiv() {
    ftl::cmd::goto_image_via_sxiv
}

ftl::cmd::goto_image_via_sxiv_recursive() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results f fzf \
        "$($ftl_cfg_image_viewer -b -q -o -f -t * \
            | fzf-tmux $ftl_cfg_fzf_popup_opts $ftl_cfg_fzf_sxiv_opts)"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::image_go_sxiv_rec() {
    ftl::cmd::goto_image_via_sxiv_recursive
}

ftl::cmd::goto_image_via_fzf() {
    exec 2>&9
    ftl::prev::clear
    _ftl::cmd::process_search_results f fzf \
        "$(fzfi --expect=ctrl-t -q "$(echo "$ftl_cfg_image_extensions_regex" \
            | perl -pe 's/(^|\|)/ $1 ./g')")"
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::image_fzf() {
    ftl::cmd::goto_image_via_fzf
}

#----------------------------------------------------------------------------
# 6. Tab commands
#----------------------------------------------------------------------------

ftl::cmd::close_tab() {
    (( ftl_tab_count > 1 )) || return 1
    ftl_tab_directories[$ftl_state_current_tab_index]=
    (( ftl_tab_count-- ))
    ftl::cmd::next_tab
    ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}"
}

ftl::cmd::tab_close() {
    ftl::cmd::close_tab
}

ftl::cmd::new_tab() {
    if [[ -d "$ftl_state_current_basename" ]] ; then
        ftl::tab::create "$ftl_state_current_path"
    else
        ftl::tab::create "${1:-$PWD}"
    fi
    ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}"
}

ftl::cmd::tab_new() {
    ftl::cmd::new_tab
}

ftl::cmd::next_tab() {
    local ctab=$ftl_state_current_tab_index
    ftl::tab::advance_index
    if (( ftl_state_current_tab_index != ctab )) ; then
        ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}" \
            '' "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_${ftl_tab_directories[$ftl_state_current_tab_index]}]}"
    fi
}

ftl::cmd::tab_next() {
    ftl::cmd::next_tab
}

ftl::cmd::prev_tab() {
    local ctab=$ftl_state_current_tab_index
    ftl::tab::retreat_index
    if (( ftl_state_current_tab_index != ctab )) ; then
        ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}" \
            '' "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_${ftl_tab_directories[$ftl_state_current_tab_index]}]}"
    fi
}

ftl::cmd::tab_prev() {
    ftl::cmd::prev_tab
}

ftl::cmd::goto_tab() {
    local ntab=$(( ftl_kbd_count - 1 ))
    if (( ntab != ftl_state_current_tab_index )) \
       && [[ -n "${ftl_tab_directories[$ntab]:-}" ]] ; then
        ftl_state_current_tab_index=$ntab
        ftl::list::change_dir "${ftl_tab_directories[$ftl_state_current_tab_index]}" \
            '' "${ftl_state_cursor_memory[${ftl_state_current_tab_index}_${ftl_tab_directories[$ftl_state_current_tab_index]}]}"
    fi
}

ftl::cmd::tab_goto() {
    ftl::cmd::goto_tab
}

#----------------------------------------------------------------------------
# 7. Pane commands
#----------------------------------------------------------------------------

ftl::cmd::spawn_extra_pane() {
    echo "${ftl_state_other_session_dir:-$ftl_state_session_dir}" >"$ftl_state_shared_dir/fs"
    _ftl::cmd::spawn_ftl_pane "'$ftl_state_current_path' $ftl_state_parent_dir" "$1" "$2"
    sleep 0.05
    tmux selectp -t "$ftl_pane_last_spawned_id"
    echo -e "\e[H\e[K"
    _ftl::list::print_header '2;97' "$ftl_list_header_mode_glyphs"
}

ftl::cmd::pane_extra() {
    ftl::cmd::spawn_extra_pane "$@"
}

_ftl::cmd::spawn_ftl_pane() {
    ftl::pane::read_child_list
    ftl::prev::clear
    ftl::pane::split "prev_all=0 ftl $1" 30% "$2" $3
    ftl_pane_child_ids+=("$ftl_pane_preview_id")
    ftl_pane_last_spawned_id=$ftl_pane_preview_id
    ftl_pane_preview_id=
    printf "%s\n" "${ftl_pane_child_ids[@]}" >"$ftl_state_parent_dir/panes"
}

ftl::cmd::close_pane() {
    ftl::pane::read_child_list
    if (( ftl_pane_is_primary && ${#ftl_pane_child_ids[@]} )) ; then
        tail -n +2 "$ftl_state_parent_dir/panes" | sponge "$ftl_state_parent_dir/panes"
        tmux send -t "${ftl_pane_child_ids[0]}" "${ftl_kbd_command_to_key[quit_ftl]}" 2>&-
        sleep 0.03
    fi
}

ftl::cmd::pane_close() {
    ftl::cmd::close_pane
}

ftl::cmd::pane_left() {
    ftl::cmd::spawn_extra_pane "-h -b" ''
}

ftl::cmd::pane_right() {
    ftl::cmd::spawn_extra_pane "" '-R'
}

ftl::cmd::pane_down() {
    ftl::cmd::spawn_extra_pane "-v" ""
}

ftl::cmd::pane_left_keep_focus() {
    ftl::cmd::spawn_extra_pane "-h -b" "-R"
}

ftl::cmd::pane_L() {
    ftl::cmd::pane_left_keep_focus
}

ftl::cmd::pane_right_keep_focus() {
    ftl::cmd::spawn_extra_pane "" ""
}

ftl::cmd::pane_R() {
    ftl::cmd::pane_right_keep_focus
}

ftl::cmd::goto_next_pane() {
    local p
    p=$(_ftl::pane::find_next_pane)
    if [[ -n "$p" ]] ; then
        echo -e "\e[H\e[K"
        _ftl::list::print_header '2;97' "$ftl_list_header_mode_glyphs"
        tmux selectp -t "$p" &>/dev/null
        tmux send -t "$p" "${ftl_kbd_command_to_key[refresh_pane]}"
    fi
}

ftl::cmd::pane_go_next() {
    ftl::cmd::goto_next_pane
}

#----------------------------------------------------------------------------
# 8. Preview commands
#----------------------------------------------------------------------------

ftl::cmd::scroll_preview_down() {
    if (( ftl_preview_is_vim )) ; then
        tmux send -t "$ftl_pane_preview_id" C-D
    elif [[ -n "$ftl_pane_preview_id" ]] ; then
        tmux send -t "$ftl_pane_preview_id" j
    fi
}

ftl::cmd::preview_down() {
    ftl::cmd::scroll_preview_down
}

ftl::cmd::scroll_preview_up() {
    if (( ftl_preview_is_vim )) ; then
        tmux send -t "$ftl_pane_preview_id" C-U
    elif [[ -n "$ftl_pane_preview_id" ]] ; then
        tmux send -t "$ftl_pane_preview_id" k
    fi
}

ftl::cmd::preview_up() {
    ftl::cmd::scroll_preview_up
}

ftl::cmd::scroll_fixed_preview_down() {
    [[ -n "$ftl_pane_fixed_preview_id" ]] \
        && tmux send -t "$ftl_pane_fixed_preview_id" C-D
}

ftl::cmd::preview_down2() {
    ftl::cmd::scroll_fixed_preview_down
}

ftl::cmd::scroll_fixed_preview_up() {
    [[ -n "$ftl_pane_fixed_preview_id" ]] \
        && tmux send -t "$ftl_pane_fixed_preview_id" C-U
}

ftl::cmd::preview_up2() {
    ftl::cmd::scroll_fixed_preview_up
}

ftl::cmd::send_preview_left() {
    [[ -n "$ftl_pane_preview_id" ]] \
        && tmux send -t "$ftl_pane_preview_id" Left
}

ftl::cmd::preview_left() {
    ftl::cmd::send_preview_left
}

ftl::cmd::send_preview_right() {
    [[ -n "$ftl_pane_preview_id" ]] \
        && tmux send -t "$ftl_pane_preview_id" Right
}

ftl::cmd::preview_right() {
    ftl::cmd::send_preview_right
}

ftl::cmd::toggle_preview_pane() {
    (( ftl_state_preview_pane_visible ^= 1 ))
    ftl::prev::clear
    sleep 0.05
    ftl::list::change_dir
}

ftl::cmd::preview_pane() {
    ftl::cmd::toggle_preview_pane
}

ftl::cmd::toggle_fixed_preview() {
    ftl_state_fixed_preview_filename="$ftl_state_current_basename"
    ftl::prev::clear
    sleep 0.05
    ftl::list::change_dir
}

ftl::cmd::preview_pane2() {
    ftl::cmd::toggle_fixed_preview
}

ftl::cmd::toggle_dirs_only_preview() {
    local t=$ftl_state_current_tab_index
    if [[ -n "${ftl_tab_preview_dirs_only[$t]}" ]] ; then
        ftl_tab_preview_dirs_only[$t]=
    else
        ftl_tab_preview_dirs_only[$t]='ᴰ'
    fi
    ftl::list::render
}

ftl::cmd::preview_dir_only() {
    ftl::cmd::toggle_dirs_only_preview
}

ftl::cmd::toggle_ext_preview() {
    [[ -n "$ftl_state_current_extension" ]] || return 0
    (( ftl_view_preview_ignore_exts[$ftl_state_current_extension] ^= 1 ))
    ftl::list::change_dir
}

ftl::cmd::preview_ext_ign() {
    ftl::cmd::toggle_ext_preview
}

ftl::cmd::toggle_image_preview() {
    (( ftl_state_images_hidden ^= 1 ))
    local e
    for e in $(tr '|' ' ' <<< "$ftl_cfg_image_extensions_regex") ; do
        ftl_view_preview_ignore_exts[$e]=$ftl_state_images_hidden
    done
    ftl::list::change_dir
}

ftl::cmd::preview_image() {
    ftl::cmd::toggle_image_preview
}

ftl::cmd::refresh_preview() {
    if [[ -d "$ftl_state_current_path" ]] ; then
        rm "$FTL_STATE_DIR/montage/$ftl_state_current_path/montage.jpg" 2>&-
        true
    else
        "$ftl_gen_dir/generator_one" "$ftl_cache_thumb_dir" \
            "$ftl_state_current_path" "$ftl_state_current_extension" 1
    fi
    ftl::prev::show_image FTL_RESTART_W3M
    ftl::list::render
}

ftl::cmd::preview_refresh() {
    ftl::cmd::refresh_preview
}

ftl::cmd::toggle_preview_tail() {
    if [[ "${ftl_view_vim_tail_commands[$ftl_state_current_path]}" == "+$ " ]] ; then
        ftl_view_vim_tail_commands[$ftl_state_current_path]='+0 '
    else
        ftl_view_vim_tail_commands[$ftl_state_current_path]='+$ '
    fi
    ftl::list::render
}

ftl::cmd::preview_tail() {
    ftl::cmd::toggle_preview_tail
}

ftl::cmd::lock_preview() {
    local p="$FTL_CFG/etc/core/lib/lock_preview"
    local file
    file=$(cd "$p" ; fd | fzf-tmux $ftl_cfg_fzf_popup_opts)
    [[ -n "$file" ]] && source "$p/$file"
    ftl::list::render
}

ftl::cmd::preview_lock() {
    ftl::cmd::lock_preview
}

ftl::cmd::unlock_preview() {
    rm "$ftl_state_session_dir/lock_preview/$ftl_state_current_path" 2>&-
    ftl::list::render
}

ftl::cmd::preview_lock_clr() {
    ftl::cmd::unlock_preview
}

ftl::cmd::set_preview_mode_1() {
    ftl_state_alt_preview_mode=1
    ftl::list::render
}

ftl::cmd::preview_m1() {
    ftl::cmd::set_preview_mode_1
}

ftl::cmd::set_preview_mode_2() {
    ftl_state_alt_preview_mode=2
    ftl::list::render
}

ftl::cmd::preview_m2() {
    ftl::cmd::set_preview_mode_2
}

ftl::cmd::set_preview_mode_3() {
    ftl_state_alt_preview_mode=3
    ftl::list::render
}

ftl::cmd::preview_m3() {
    ftl::cmd::set_preview_mode_3
}

ftl::cmd::set_preview_mode_4() {
    ftl_state_alt_preview_mode=4
    ftl::list::render
}

ftl::cmd::preview_m4() {
    ftl::cmd::set_preview_mode_4
}

ftl::cmd::set_preview_mode_5() {
    ftl_state_alt_preview_mode=5
    ftl::list::render
}

ftl::cmd::preview_m5() {
    ftl::cmd::set_preview_mode_5
}

ftl::cmd::set_full_preview_mode_1() {
    [[ "$ftl_state_current_extension" == 'md' ]] || return 0
    ftl::prev::clear
    glow "$ftl_state_current_basename" --pager
    ftl::list::render
}

ftl::cmd::full_preview_m1() {
    ftl::cmd::set_full_preview_mode_1
}

ftl::cmd::set_full_preview_mode_2() {
    [[ "$ftl_state_current_extension" == 'md' ]] || return 0
    ftl::util::run_maximized _ftl::cmd::mo_vimb "$ftl_state_current_basename"
    ftl::list::render
}

ftl::cmd::full_preview_m2() {
    ftl::cmd::set_full_preview_mode_2
}

ftl::cmd::set_full_preview_mode_3() {
    [[ "$ftl_state_current_extension" == 'md' ]] || return 0
    ftl::util::run_maximized _ftl::cmd::mo_vimb -R .
    ftl::list::render
}

ftl::cmd::full_preview_m3() {
    ftl::cmd::set_full_preview_mode_3
}

ftl::cmd::set_full_preview_mode_4() {
    ftl_state_alt_preview_mode=4
    ftl::list::render
}

ftl::cmd::full_preview_m4() {
    ftl::cmd::set_full_preview_mode_4
}

ftl::cmd::set_full_preview_mode_5() {
    ftl_state_alt_preview_mode=5
    ftl::list::render
}

ftl::cmd::full_preview_m5() {
    ftl::cmd::set_full_preview_mode_5
}

_ftl::cmd::mo_vimb() {
    mo --no-open "$@" &>/dev/null
    vimb "http://localhost:6275" 2>/dev/null
}

ftl::cmd::cycle_preview_size() {
    (( ftl_state_preview_zoom_index += 1, \
       ftl_state_preview_zoom_index >= ${#ftl_cfg_preview_zoom_levels[@]} )) \
        && ftl_state_preview_zoom_index=0
    ftl::list::compute_preview_width
    [[ -n "$ftl_pane_preview_id" ]] \
        && tmux resizep -t "$ftl_pane_preview_id" -x "$ftl_pane_resize_target" &>/dev/null
    ftl::list::refresh_dir '' 0
}

ftl::cmd::preview_size() {
    ftl::cmd::cycle_preview_size
}

ftl::cmd::toggle_image_zoom() {
    (( ftl_cfg_image_zoomed ^= 1 ))
    ftl::list::render
}

ftl::cmd::image_zoom() {
    ftl::cmd::toggle_image_zoom
}

ftl::cmd::external_viewer_mode_1() {
    ftl_state_external_viewer_mode=1
    ftl::prev::dispatch
}

ftl::cmd::external_mode1() {
    ftl::cmd::external_viewer_mode_1
}

ftl::cmd::external_viewer_mode_2() {
    ftl_state_external_viewer_mode=2
    ftl::prev::dispatch
}

ftl::cmd::external_mode2() {
    ftl::cmd::external_viewer_mode_2
}

ftl::cmd::external_viewer_mode_3() {
    ftl_state_external_viewer_mode=3
    ftl::prev::dispatch
}

ftl::cmd::external_mode3() {
    ftl::cmd::external_viewer_mode_3
}

ftl::cmd::show_in_background_player() {
    [[ "$ftl_state_current_extension" =~ $ftl_cfg_media_extensions_regex ]] || return 0
    source "$ftl_cfg_background_player" "${ftl_selection_current[@]}"
    ftl::list::render
}

ftl::cmd::preview_show() {
    ftl::cmd::show_in_background_player
}

ftl::cmd::show_via_fzf_viewer() {
    local p="$FTL_CFG/viewers"
    local viewer
    viewer=$(cd "$p" 2>&- && fd | fzf-tmux -p80% --cycle --reverse --info=inline)
    [[ -n "$viewer" ]] && source "$p/$viewer"
    ftl::list::render
}

ftl::cmd::preview_show_fzf() {
    ftl::cmd::show_via_fzf_viewer
}

ftl::cmd::queue_to_player() {
    [[ "$ftl_state_current_extension" =~ $ftl_cfg_media_extensions_regex ]] || return 0
    ( $ftl_cfg_queue_player "${ftl_selection_current[@]}" & )
    ftl::sel::clear_all
    ftl::list::render
}

ftl::cmd::preview_queue() {
    ftl::cmd::queue_to_player
}

ftl::cmd::kill_media_player() {
    if (( ftl_view_media_pid )) ; then
        kill "$ftl_view_media_pid" &>/dev/null
        ftl_view_media_pid=
    fi
}

ftl::cmd::player_kill() {
    ftl::cmd::kill_media_player
}

ftl::cmd::detach_editor_preview() {
    if (( ftl_preview_is_vim )) ; then
        ftl_preview_is_vim=
        ftl_pane_preview_id=
        ftl::list::change_dir
    fi
}

ftl::cmd::editor_detach() {
    ftl::cmd::detach_editor_preview
}

#----------------------------------------------------------------------------
# 9. Shell commands
#----------------------------------------------------------------------------

ftl::pane::send_to_shell() {
    { (( $1 )) && [[ -n "$ftl_pane_shell_id" ]] \
        && $(tmux has -t "$ftl_pane_shell_id" 2>&-) ; } \
        && tmux send -t "$ftl_pane_shell_id" "${@:2}"
}

ftl::cmd::open_shell_pane() {
    ftl::prev::clear
    local saved_pane=$ftl_pane_preview_id
    ftl::pane::split "bash $ftl_cfg_shell_pane_height -v -U"
    ftl_pane_shell_id=$ftl_pane_preview_id
    ftl_pane_preview_id=$saved_pane
    sleep 0.2
    ftl::pane::send_to_shell "$1" "$(printf "%s " "${ftl_selection_current[@]@Q}")" C-b
    ftl::list::change_dir
}

ftl::cmd::shell_pane() {
    ftl::cmd::open_shell_pane
}

ftl::cmd::open_vertical_shell_pane() {
    ftl::prev::clear 0
    local saved_pane=$ftl_pane_preview_id
    ftl::pane::split "bash $ftl_cfg_shell_pane_width -h -U"
    ftl_pane_shell_id=$ftl_pane_preview_id
    ftl_pane_preview_id=$saved_pane
    sleep 0.2
    ftl::pane::send_to_shell "$1" "$(printf "%s " "${ftl_selection_current[@]@Q}")" C-b
    ftl::list::change_dir
}

ftl::cmd::shell_vpane() {
    ftl::cmd::open_vertical_shell_pane
}

ftl::cmd::open_shell() {
    if [[ -z "$ftl_pane_shell_id" ]] || ! tmux has -t "$ftl_pane_shell_id" 2>&- ; then
        ftl::cmd::open_shell_pane
    fi
    tmux selectp -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::shell() {
    ftl::cmd::open_shell
}

ftl::cmd::open_vertical_shell() {
    if [[ -z "$ftl_pane_shell_id" ]] || ! tmux has -t "$ftl_pane_shell_id" 2>&- ; then
        ftl::cmd::open_vertical_shell_pane
    fi
    tmux selectp -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::shell_vertical() {
    ftl::cmd::open_vertical_shell
}

ftl::cmd::open_shell_with_files() {
    if [[ -n "$ftl_pane_shell_id" ]] && tmux has -t "$ftl_pane_shell_id" 2>&- ; then
        ftl_state_pending_input="${ftl_kbd_command_to_key[shell_file]}"
    else
        ftl::cmd::open_shell_pane 1
    fi
    tmux selectp -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::shell_files() {
    ftl::cmd::open_shell_with_files
}

ftl::cmd::send_files_to_shell() {
    local i
    for i in "${ftl_selection_current[@]}" ; do
        ftl::pane::send_to_shell 1 "'$i'" " "
    done
}

ftl::cmd::shell_send_files() {
    ftl::cmd::send_files_to_shell
}

ftl::cmd::view_session_shell() {
    if (( ! ftl_pane_session_shell_active )) ; then
        tmux new -A -d -s "ftl$$"
        tmux newww -t "ftl$$" -n "ftl$$_bash"
        sleep 0.2
        ftl_pane_session_shell_active=1
    fi
    tmux switch -t "ftl$$:ftl$$_bash"
}

ftl::cmd::shell_view() {
    ftl::cmd::view_session_shell
}

ftl::cmd::synch_shell_cwd() {
    ftl::pane::send_to_shell 1 "cd '$ftl_state_current_dir'" C-m
}

ftl::cmd::shell_synch() {
    ftl::cmd::synch_shell_cwd
}

ftl::cmd::open_zoomed_shell() {
    if [[ -z "$ftl_pane_shell_id" ]] || ! tmux has -t "$ftl_pane_shell_id" 2>&- ; then
        ftl::cmd::open_shell_pane
    fi
    tmux selectp -t "$ftl_pane_shell_id" &>/dev/null
    tmux resizep -Z -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::shell_zoomed() {
    ftl::cmd::open_zoomed_shell
}

ftl::cmd::run_command_in_pane() {
    ftl::cmd::prompt "ftl> "
    ftl_list_quick_display_active=1
    ftl::list::render
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        ftl::pane::split_for_preview "$ftl_kbd_current_key ; read -sn10"
    fi
    sleep 0.05
}

ftl::cmd::shell_cmd_in_pane() {
    ftl::cmd::run_command_in_pane
}

ftl::cmd::close_shell_pane() {
    [[ -n "$ftl_pane_shell_id" ]] \
        && tmux killp -t "$ftl_pane_shell_id" &>/dev/null
}

ftl::cmd::quit_shell() {
    ftl::cmd::close_shell_pane
}

ftl::cmd::run_interactive_bash() {
    exec 2>&9
    stty echo
    echo -ne '\e[H\e[K\e[33m\e[?25h'
    clear
    bash -i
    ftl::util::enter_alt_screen
    exec 2>"$ftl_state_session_dir/log"
}

ftl::cmd::run_bash() {
    ftl::cmd::run_interactive_bash
}

#----------------------------------------------------------------------------
# 10. View mode commands
#----------------------------------------------------------------------------

ftl::cmd::view_mode_all() {
    local no_redraw=$1
    local t=$ftl_state_current_tab_index
    ftl_tab_view_mode[$t]=0
    ftl_tab_filter_image_mode[$t]=
    ftl_tab_filter_image_negate[$t]=
    (( no_redraw )) || ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::view_mode_image() {
    local no_redraw=$1
    local t=$ftl_state_current_tab_index
    ftl_tab_view_mode[$t]=1
    ftl_tab_filter_image_negate[$t]=
    ftl_tab_filter_image_mode[$t]="$ftl_cfg_image_extensions_regex$"
    (( no_redraw )) || ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::view_mode_not_image() {
    local no_redraw=$1
    local t=$ftl_state_current_tab_index
    ftl_tab_view_mode[$t]=2
    ftl_tab_filter_image_mode[$t]="$ftl_cfg_image_extensions_regex$"
    ftl_tab_filter_image_negate[$t]='-v'
    (( no_redraw )) || ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::view_mode_next() {
    local t=$ftl_state_current_tab_index
    (( ftl_tab_view_mode[$t]++ ))
    (( ftl_tab_view_mode[$t] > 2 )) && ftl_tab_view_mode[$t]=0
    ftl::cmd::view_mode "${ftl_tab_view_mode[$t]}"
}

ftl::cmd::view_mode() {
    local no_redraw=$2
    [[ $1 == 0 ]] && ftl::cmd::view_mode_all "$no_redraw"
    [[ $1 == 1 ]] && ftl::cmd::view_mode_image "$no_redraw"
    [[ $1 == 2 ]] && ftl::cmd::view_mode_not_image "$no_redraw"
}

ftl::cmd::file_dir_mode() {
    local t=$ftl_state_current_tab_index
    (( ftl_tab_listing_mode[$t]++ ))
    (( ftl_tab_listing_mode[$t] > 2 )) && ftl_tab_listing_mode[$t]=0
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::show_hidden() {
    local t=$ftl_state_current_tab_index
    if (( ftl_tab_show_hidden[$t] )) ; then
        ftl_tab_show_hidden[$t]=
    else
        ftl_tab_show_hidden[$t]=1
    fi
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::hide_size() {
    ftl_state_show_size_mode=0
    ftl::list::change_dir
}

ftl::cmd::show_size() {
    (( ftl_state_show_size_mode++, \
       ftl_state_show_size_mode = ftl_state_show_size_mode > 3 ? 0 : ftl_state_show_size_mode ))
    if (( ftl_state_show_size_mode == 3 )) ; then
        _ftl::list::print_header '' "$ftl_cfg_msg_du_size"
        ftl::list::compute_dir_sizes
        _ftl::list::print_header '' "$ftl_list_header_mode_glyphs"
    fi
    ftl::list::change_dir
}

ftl::cmd::show_stat() {
    (( ftl_state_show_stat ^= 1 ))
    ftl::util::refresh_screen
    ftl::list::render
}

ftl::cmd::sort_entries() {
    local t=$ftl_state_current_tab_index
    (( ftl_tab_sort_type[$t] = ftl_tab_sort_type[$t] + 1 >= ${#ftl_cfg_sort_options[@]} \
        ? 0 : ftl_tab_sort_type[$t] + 1 ))
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::sort_entries_reversed() {
    local t=$ftl_state_current_tab_index
    if [[ "${ftl_tab_sort_reversed[$t]}" == '-r' ]] ; then
        ftl_tab_sort_reversed[$t]=0
    else
        ftl_tab_sort_reversed[$t]=-r
    fi
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_directory_mode0() { ftl_state_dir_preview_mode=0 ; ftl::list::render ; }
ftl::cmd::set_directory_mode1() { ftl_state_dir_preview_mode=1 ; ftl::list::render ; }
ftl::cmd::set_directory_mode2() { ftl_state_dir_preview_mode=2 ; ftl::list::render ; }
ftl::cmd::set_directory_mode3() { ftl_state_dir_preview_mode=3 ; ftl::list::render ; }
ftl::cmd::set_directory_mode4() { ftl_state_dir_preview_mode=4 ; ftl::list::render ; }
ftl::cmd::set_directory_mode5() { ftl_state_dir_preview_mode=5 ; ftl::list::render ; }

ftl::cmd::view_mode_pdf() {
    (( ftl_state_pdf_preview_as_image ^= 1 ))
    ftl::list::render
}

ftl::cmd::toggle_etags() {
    (( ftl_state_etag_enabled ^= 1 ))
    ftl::list::change_dir
}

ftl::cmd::etag_show() {
    ftl::cmd::toggle_etags
}

ftl::cmd::select_etag_source() {
    local p="$FTL_CFG/etags"
    ftl_etag_source_name=$(cd "$p" ; fd | fzf-tmux -p 50% --cycle --reverse --info=inline)
    if [[ -n "$ftl_etag_source_name" ]] ; then
        source "$p/$ftl_etag_source_name" "$ftl_state_session_dir"
        ftl_state_etag_enabled=1
        ftl::list::change_dir
    fi
}

ftl::cmd::etag_select() {
    ftl::cmd::select_etag_source
}

ftl::cmd::extension_hide_tab() {
    [[ -n "$ftl_state_current_extension" ]] || return 0
    local t=$ftl_state_current_tab_index
    (( ftl_filt_listing_hide_exts[${t}_${ftl_state_current_extension@Q}] = 1 ))
    ftl::list::change_dir
}

ftl::cmd::extension_hide() {
    [[ -n "$ftl_state_current_extension" ]] || return 0
    (( ftl_filt_listing_hide_exts[${ftl_state_current_extension@Q}] = 1 ))
    ftl::list::change_dir
}

ftl::cmd::extension_only_tab() {
    local i e
    local t=$ftl_state_current_tab_index
    for i in "${ftl_selection_current[@]}" ; do
        e="${i##*.}"
        [[ -n "$e" ]] && (( ftl_filt_listing_keep_exts_per_tab[$t] = 1, \
            ftl_filt_listing_keep_exts_per_tab[${t}_${e@Q}] = 1 ))
    done
    ftl::sel::clear_all
    ftl::list::change_dir
}

ftl::cmd::extension_only() {
    local i e
    for i in "${ftl_selection_current[@]}" ; do
        e="${i##*.}"
        [[ -n "$e" ]] && (( ftl_filt_listing_keep_exts[${e@Q}] = 1 ))
    done
    ftl::sel::clear_all
    ftl::list::change_dir
}

ftl::cmd::extension_clear() {
    ftl_filt_listing_hide_exts=()
    ftl_filt_listing_keep_exts=()
    ftl_filt_listing_keep_exts_per_tab=()
    ftl::filt::sort_entries() { ftl::filt::sort_by ; }
    ftl::list::change_dir
}

ftl::cmd::extension_sort() {
    source "$FTL_CFG/filters/sort_by_extension"
    ftl::list::change_dir '' "$ftl_state_current_basename"
}

ftl::cmd::set_listing_depth() {
    ftl::cmd::prompt 'depth: '
    if [[ "$ftl_kbd_current_key" -eq "$ftl_kbd_current_key" ]] 2>&- ; then
        local t=$ftl_state_current_tab_index
        ftl_tab_listing_depth[$t]=$ftl_kbd_current_key
        ftl::list::change_dir '' "$ftl_state_current_basename"
    else
        ftl::list::render
    fi
}

ftl::cmd::depth() {
    ftl::cmd::set_listing_depth
}

#----------------------------------------------------------------------------
# 11. Mark/history commands
#----------------------------------------------------------------------------

ftl::cmd::set_mark() {
    read -sn1
    if [[ -n "$ftl_kbd_current_key" ]] ; then
        if [[ -d "${ftl_list_entries[$ftl_state_cursor_index]}" ]] ; then
            ftl_mark_session_marks[$ftl_kbd_current_key]="${ftl_list_entries[$ftl_state_cursor_index]}/$"
        else
            ftl_mark_session_marks[$ftl_kbd_current_key]="${ftl_list_entries[$ftl_state_cursor_index]}"
        fi
    fi
}

ftl::cmd::mark() {
    ftl::cmd::set_mark
}

ftl::cmd::goto_mark() {
    read -n 1
    if [[ -n "$ftl_kbd_current_key" && -n "${ftl_mark_session_marks[$ftl_kbd_current_key]:-}" ]] ; then
        local d
        d="$(dirname "${ftl_mark_session_marks[$ftl_kbd_current_key]}")"
        ftl::list::change_dir "$d" "$(basename "${ftl_mark_session_marks[$ftl_kbd_current_key]}")"
    else
        ftl::list::render
    fi
}

ftl::cmd::mark_go() {
    ftl::cmd::goto_mark
}

ftl::cmd::goto_mark_new_tab() {
    read -n 1
    if [[ -n "$ftl_kbd_current_key" && -n "${ftl_mark_session_marks[$ftl_kbd_current_key]:-}" ]] ; then
        local d
        d="$(dirname "${ftl_mark_session_marks[$ftl_kbd_current_key]}")"
        ftl::tab::create
        ftl::list::change_dir "$d" "$(basename "${ftl_mark_session_marks[$ftl_kbd_current_key]}")"
    else
        ftl::list::render
    fi
}

ftl::cmd::mark_go_tab() {
    ftl::cmd::goto_mark_new_tab
}

ftl::cmd::goto_mark_via_fzf() {
    _ftl::cmd::process_search_results f fzf \
        "$({ ftl::mark::user_marks_provider ; printf "%s\n" "${ftl_mark_session_marks[@]}" ; } \
            | sort -u | lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts -m --expect=ctrl-t --ansi)"
}

ftl::cmd::mark_fzf() {
    ftl::cmd::goto_mark_via_fzf
}

ftl::mark::user_marks_provider() {
    :
}

ftl::cmd::add_persistent_mark() {
    {
        cat "$FTL_STATE_DIR/shared/marks" 2>&-
        if [[ -d "$ftl_state_current_path" ]] ; then
            echo "$ftl_state_current_path/\$"
        else
            echo "$ftl_state_current_path"
        fi
    } | awk '!seen[$0]++' | sponge "$FTL_STATE_DIR/shared/marks"
}

ftl::cmd::gmark() {
    ftl::cmd::add_persistent_mark
}

ftl::cmd::goto_persistent_via_fzf() {
    [[ -e "$FTL_STATE_DIR/shared/marks" ]] || return 0
    _ftl::cmd::process_search_results f fzf \
        "$({ cat "$FTL_STATE_DIR/shared/marks" ; ftl::mark::user_marks_provider ; } \
            | lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts --cycle -m --expect=ctrl-t --ansi)"
}

ftl::cmd::gmark_fzf() {
    ftl::cmd::goto_persistent_via_fzf
}

ftl::cmd::clear_persistent_marks() {
    ftl::cmd::prompt 'clear persistent marks? [y|N]' -sn1
    if [[ $ftl_kbd_current_key == y ]] ; then
        : >"$FTL_STATE_DIR/shared/marks"
    fi
    ftl::list::render
}

ftl::cmd::gmarks_clear() {
    ftl::cmd::clear_persistent_marks
}

ftl::cmd::goto_session_history() {
    local h="$ftl_state_session_dir/history"
    ftl::util::dedup_file "$h"
    _ftl::cmd::process_search_results f fzf \
        "$(<"$h" lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts --tac --ansi --expect=ctrl-t)"
}

ftl::cmd::history_go() {
    ftl::cmd::goto_session_history
}

ftl::cmd::goto_global_history() {
    local h="$FTL_STATE_DIR/shared/history"
    ftl::util::dedup_file "$h"
    _ftl::cmd::process_search_results f fzf \
        "$(<"$h" lscolors | fzf-tmux $ftl_cfg_fzf_popup_opts --tac --ansi --expect=ctrl-t)"
}

ftl::cmd::ghistory() {
    ftl::cmd::goto_global_history
}

ftl::cmd::goto_global_history_subdir() {
    local h="$FTL_STATE_DIR/shared/history"
    ftl::util::dedup_file "$h"
    _ftl::cmd::process_search_results f fzf \
        "$(cat "$h" | rg "$(pwd)" | lscolors \
            | fzf-tmux $ftl_cfg_fzf_popup_opts --tac --ansi --expect=ctrl-t)"
}

ftl::cmd::ghistory_subdir() {
    ftl::cmd::goto_global_history_subdir
}

ftl::cmd::edit_global_history() {
    ftl::util::dedup_file "$FTL_STATE_DIR/shared/history"
    rg -v -x -F -f \
        "$(<"$FTL_STATE_DIR/shared/history" lscolors \
            | fzf-tmux $ftl_cfg_fzf_popup_opts --tac -m --ansi)" \
        "$FTL_STATE_DIR/shared/history" | sponge "$FTL_STATE_DIR/shared/history"
}

ftl::cmd::ghistory_edit() {
    ftl::cmd::edit_global_history
}

ftl::cmd::clear_global_history() {
    ftl::cmd::prompt 'clear global history? [y|N]' -sn1
    if [[ $ftl_kbd_current_key == y ]] ; then
        rm "$FTL_STATE_DIR/shared/history" 2>&-
    fi
    ftl::list::render
}

ftl::cmd::ghistory_clear() {
    ftl::cmd::clear_global_history
}

#----------------------------------------------------------------------------
# 12. Quit commands
#----------------------------------------------------------------------------

ftl::cmd::quit() {
    _ftl::cmd::check_shells_before_quit && return
    ftl::prev::clear
    _ftl::cmd::quit_cleanup
    ftl::cmd::close_shell_pane
    tmux kill-session -t "ftl$$" &>/dev/null
    if (( ! ftl_pane_is_primary )) ; then
        ftl::pane::read_child_list
        tmux send -t "$ftl_pane_primary_id" å
    fi
    ftl::state::cleanup
    exit
}

ftl::cmd::quit_ftl() {
    ftl::cmd::close_tab || ftl::cmd::close_pane || ftl::cmd::quit
}

_ftl::cmd::check_shells_before_quit() {
    (( ftl_state_quit_attempt_count++, ftl_state_quit_attempt_count > 2 )) && return 1
    if (( $(tmux lsw -t "ftl$$" 2>&- | wc -l) > 2 )) ; then
        tmux popup -h 5 "echo Shells open! «session: ctl-w !». "
        true
    else
        false
    fi
}

_ftl::cmd::quit_cleanup() {
    _ftl::mark::save_to_history
    ftl::pane::stop_file_watcher
    stty echo
    [[ "$ftl_state_parent_dir" == "$ftl_state_session_dir" ]] \
        && ftl::pane::set_border_colors $ftl_cfg_tmux_border_colors_default
    ftl::cmd::kill_media_player
    ftl::boot::on_quit
    ftl::util::refresh_screen "\e[?25h\e[?1049l"
    ftl::state::emit_selection_fd3
}

ftl::cmd::quit_all() {
    if (( ftl_pane_is_primary )) ; then
        ftl::pane::send_to_all_children "${ftl_kbd_command_to_key[quit_ftl]}"
        sleep 0.05
        ftl_state_quit_cancelled=1
        ftl::cmd::quit
    else
        tmux send -t "$ftl_pane_primary_id" "${ftl_kbd_command_to_key[quit_all]}"
    fi
}

ftl::cmd::quit_keep_shell() {
    ftl_pane_keep_shell_on_quit=1
    ftl::cmd::quit_all
}

ftl::cmd::quit_keep_preview() {
    _ftl::cmd::quit_cleanup
    if [[ -n "$ftl_pane_preview_id" ]] ; then
        echo >"$ftl_state_parent_dir/pane"
        tmux selectp -t "$ftl_pane_preview_id"
        tmux resizep -Z -t "$ftl_pane_preview_id"
    fi
    exit 0
}

ftl::boot::on_quit() {
    :
}

ftl::cmd::ftl_event_quit() {
    ftl::boot::on_quit
}

ftl::cmd::refresh_pane() {
    ftl::prev::sync_and_dispatch
    if (( ftl_list_entry_count )) ; then
        ftl::util::parse_path "${ftl_list_entries[$ftl_state_cursor_index]}"
    else
        ftl_state_current_basename=
    fi
    ftl::sel::validate_existence
    ftl::list::change_dir "$PWD" "$ftl_state_current_basename"
}

#----------------------------------------------------------------------------
# 13. Signal handlers
#----------------------------------------------------------------------------

ftl::ipc::handle_pane_focus() {
    ftl::pane::read_child_list
    if (( ${#ftl_pane_child_ids[@]} )) ; then
        tmux selectp -t "${ftl_pane_child_ids[0]}"
    else
        tmux selectp -t "$ftl_pane_self_id"
    fi
    ftl_state_other_session_dir=
    ftl_state_pending_input="${ftl_kbd_command_to_key[refresh_pane]}"
}

ftl::cmd::SIG_PANE() {
    ftl::ipc::handle_pane_focus
}

ftl::ipc::handle_refresh() {
    (( ftl_pane_is_child )) && ftl::kbd::drain_input && ftl::prev::sync_and_dispatch
}

ftl::cmd::SIG_REFRESH() {
    ftl::ipc::handle_refresh
}

ftl::ipc::handle_preview_request() {
    (( ftl_state_preview_pane_visible )) || return 0
    local op
    read -r op <"$ftl_state_shared_dir/pane"
    ftl::prev::sync_and_dispatch prev
    tmux selectp -t "$op"
    ftl::kbd::drain_input
}

ftl::cmd::SIG_REMOTE() {
    ftl::ipc::handle_preview_request
}

ftl::ipc::handle_shell_synch() {
    local shell_dir
    IFS=$'\n' read -r shell_dir <"$ftl_state_parent_dir/synch_with_shell"
    ftl::list::change_dir "$shell_dir"
}

ftl::cmd::SIG_SYNCH_SHELL() {
    ftl::ipc::handle_shell_synch
}

#----------------------------------------------------------------------------
# 14. Command prompt
#----------------------------------------------------------------------------

ftl::cmd::open_command_prompt() {
    _ftl::cmd::build_command_name_list
    echo -ne "\e[H"
    tput cnorm
    stty echo
    local C
    C="$(ftl::cmd::prompt_with_history)"
    stty -echo
    tput civis
    if [[ -n "$C" ]] ; then
        _ftl::list::print_header '' "$ftl_list_header_mode_glyphs"
        ftl::cmd::dispatch_command "$C"
    fi
    ftl::list::render
}

ftl::cmd::command_prompt() {
    ftl::cmd::open_command_prompt
}

_ftl::cmd::build_command_name_list() {
    {
        find "$FTL_CFG/commands" -type f -printf "%f\n"
        printf "%s\n" "${!ftl_kbd_command_to_key[@]}" fsh finfo show_cmd_log
    } >"$ftl_state_session_dir/command_names"
}

ftl::cmd::prompt_with_history() {
    trap 'echo -ne "\e[A\e[K" ; stty -echo ; tput civis' SIGINT
    echo $(rlwrap -p'0;33' -S"${1:-ftl> }" \
        -f"$ftl_state_session_dir/command_names" \
        -H "$FTL_STATE_DIR/shared/command_history" -o cat)
    trap - SIGINT
}

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

ftl::cmd::run_user_command() {
    local p="$FTL_CFG/commands"
    local cmd
    cmd=$(cd "$p" 2>&- && fd -t f | sed 's/^.\///' \
        | fzf-tmux -p80% --cycle --reverse --info=inline)
    [[ -n "$cmd" ]] && source "$p/$cmd"
    ftl::list::render
}

ftl::cmd::show_help() {
    if (( ftl_cfg_help_in_popup )) ; then
        tmux popup -h90% -w90% -E "$ftl_cfg_help_command"
    else
        ftl::prev::clear
        exec 2>&9
        $ftl_cfg_help_command
        exec 2>"$ftl_state_session_dir/log"
        ftl::util::enter_alt_screen
    fi
    ftl::list::change_dir
}

ftl::cmd::ftl_help() {
    ftl::cmd::show_help
}

ftl::cmd::show_bindings() {
    ftl::kbd::show_bindings
}

ftl::cmd::k_bindings() {
    ftl::kbd::show_bindings
}

ftl::cmd::show_tree() {
    tmux popup -h 90% -w 90% -E -d "$PWD" "tree -C $@ | less -R"
}

ftl::cmd::tree_view() {
    ftl::cmd::show_tree
}

# vim: set filetype=bash :
