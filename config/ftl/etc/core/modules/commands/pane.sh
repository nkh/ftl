declare -ag ftl_pane_child_ids=()
# commands/pane.sh — Pane commands
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

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
                tmux send -t "${ftl_pane_child_ids[0]}" "${ftl_kbd_command_to_key[ftl::cmd::quit_ftl]:-}" 2>&-
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
                tmux send -t "$p" "${ftl_kbd_command_to_key[ftl::cmd::refresh_pane]:-}"
        fi
}

ftl::cmd::pane_go_next() {
        ftl::cmd::goto_next_pane
}

#----------------------------------------------------------------------------
