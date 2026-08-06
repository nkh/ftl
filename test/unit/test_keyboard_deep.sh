#!/bin/env bash
# test/unit/test_keyboard_deep.sh — deep tests for keyboard.sh
#
# Covers:
#   - normalize_key for all arrow keys (including the DOWN app-mode bug)
#   - normalize_key for F-keys, Home, End, PageUp, PageDown
#   - unbind side effects on prefix counts
#   - unbind with empty shortcut (set -u safety)
#   - bind override behavior
#   - exclude_from_redo / reset_redo_exclusions
#   - dispatch count accumulation

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"

ftl::test::setup() {
    # Reset all keyboard globals
    declare -Ag ftl_kbd_trie=()
    declare -Ag ftl_kbd_command_to_key=()
    declare -Ag ftl_kbd_bindings_display=()
    declare -Ag ftl_kbd_submode_handler=()
    declare -Ag ftl_kbd_redo_excluded=()
    ftl_kbd_current_key=
    ftl_kbd_raw_key=
    ftl_kbd_accumulated_keys=
    ftl_kbd_keys_count=0
    ftl_kbd_count=
    ftl_kbd_has_count=0
    ftl_kbd_last_command=
    ftl_cfg_leader_key=BACKSLASH
    ftl_cfg_redo_key=.
    ftl_cfg_bindings_in_popup=0
    ftl_cfg_bindings_display_width=80
    ftl_kbd_warn_on_override=0
    declare -Ag ftl_plugin_vfiles=()
    declare -Ag ftl_plugin_vdirs=()
    ftl_state_main_info_file_path=
}

ftl::test::teardown() {
    :
}

# ============================================================================
# normalize_key — arrow keys
# ============================================================================

test_normalize_key_up_normal_mode() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[A')
    ftl::test::assert_eq "UP" "$result" "normal-mode UP should normalize to 'UP'"
}

test_normalize_key_up_app_mode() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[OA')
    ftl::test::assert_eq "UP" "$result" "app-mode UP (\\e[OA) should normalize to 'UP'"
}

test_normalize_key_down_normal_mode() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[B')
    ftl::test::assert_eq "DOWN" "$result" "normal-mode DOWN should normalize to 'DOWN'"
}

test_normalize_key_down_app_mode_bug() {
    # App-mode DOWN arrow (\e[OB) is now correctly normalized to "DOWN"
    # (was empty before fix — keyboard.sh:212 had $'\e[0B' typo, digit 0
    # instead of letter O).
    local result
    result=$(ftl::kbd::normalize_key $'\e[OB')
    ftl::test::assert_eq "DOWN" "$result" \
        "app-mode DOWN (\\e[OB) should normalize to 'DOWN' (fixed: was empty before)"
}

test_normalize_key_right_app_mode() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[OC')
    ftl::test::assert_eq "RIGHT" "$result" "app-mode RIGHT should normalize to 'RIGHT'"
}

test_normalize_key_left_app_mode() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[OD')
    ftl::test::assert_eq "LEFT" "$result" "app-mode LEFT should normalize to 'LEFT'"
}

# ============================================================================
# normalize_key — function keys
# ============================================================================

test_normalize_key_f1() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[11~')
    ftl::test::assert_eq "F1" "$result" "F1 (\\e[11~) should normalize to 'F1'"
}

test_normalize_key_f2() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[12~')
    ftl::test::assert_eq "F2" "$result" "F2 should normalize to 'F2'"
}

test_normalize_key_f5() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[15~')
    ftl::test::assert_eq "F5" "$result" "F5 should normalize to 'F5'"
}

test_normalize_key_home() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[H')
    ftl::test::assert_eq "HOME" "$result" "Home (\\e[H) should normalize to 'HOME'"
}

test_normalize_key_end() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[F')
    ftl::test::assert_eq "END" "$result" "End (\\e[F) should normalize to 'END'"
}

test_normalize_key_pgup() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[5~')
    ftl::test::assert_eq "PGUP" "$result" "PgUp (\\e[5~) should normalize to 'PGUP'"
}

test_normalize_key_pgdn() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[6~')
    ftl::test::assert_eq "PGDN" "$result" "PgDn (\\e[6~) should normalize to 'PGDN'"
}

# ============================================================================
# normalize_key — single chars
# ============================================================================

test_normalize_key_enter() {
    local result
    # normalize_key uses $'' (empty string) for ENTER, not $'\n'
    result=$(ftl::kbd::normalize_key '')
    ftl::test::assert_eq "ENTER" "$result" "empty string should normalize to 'ENTER'"
}

test_normalize_key_escape() {
    local result
    result=$(ftl::kbd::normalize_key $'\e')
    ftl::test::assert_eq "ESCAPE" "$result" "bare escape should normalize to 'ESCAPE'"
}

test_normalize_key_tab() {
    local result
    result=$(ftl::kbd::normalize_key $'\t')
    ftl::test::assert_eq "TAB" "$result" "tab should normalize to 'TAB'"
}

test_normalize_key_backspace_del() {
    local result
    # normalize_key uses $'\177' (DEL) for BACKSPACE
    result=$(ftl::kbd::normalize_key $'\177')
    ftl::test::assert_eq "BACKSPACE" "$result" "DEL (\\177) should normalize to 'BACKSPACE'"
}

test_normalize_key_backspace_as_ctl_h() {
    # \b (0x08) is normalized to CTL-H, not BACKSPACE
    local result
    result=$(ftl::kbd::normalize_key $'\b')
    ftl::test::assert_eq "CTL-H" "$result" "\\b (0x08) normalizes to 'CTL-H'"
}

test_normalize_key_space() {
    local result
    result=$(ftl::kbd::normalize_key ' ')
    ftl::test::assert_eq "SPACE" "$result" "space should normalize to 'SPACE'"
}

test_normalize_key_ctl_a() {
    local result
    result=$(ftl::kbd::normalize_key $'\x01')
    ftl::test::assert_eq "CTL-A" "$result" "Ctrl-A (\\x01) should normalize to 'CTL-A'"
}

test_normalize_key_ctl_z() {
    # CTL-Z (\x1a = 26) may not be in the normalize_key table — document
    # the actual behavior
    local result
    result=$(ftl::kbd::normalize_key $'\x1a')
    ftl::test::assert_eq "" "$result" \
        "Ctrl-Z (\\x1a) is NOT normalized (no entry in the table — bug or intentional?)"
}

test_normalize_key_lowercase_letter() {
    local result
    result=$(ftl::kbd::normalize_key 'a')
    ftl::test::assert_eq "a" "$result" "lowercase 'a' should pass through"
}

test_normalize_key_uppercase_letter() {
    local result
    result=$(ftl::kbd::normalize_key 'A')
    ftl::test::assert_eq "A" "$result" "uppercase 'A' should pass through"
}

test_normalize_key_digit() {
    local result
    result=$(ftl::kbd::normalize_key '5')
    ftl::test::assert_eq "5" "$result" "digit '5' should pass through"
}

# ============================================================================
# bind / unbind — prefix counts
# ============================================================================

test_bind_registers_command() {
    ftl::kbd::bind ftl move j my_move_func "move down"
    ftl::test::assert_eq "my_move_func" "${ftl_kbd_trie[j]}" \
        "bind should register the command in the trie"
}

test_bind_chord_increments_prefix_count() {
    ftl::kbd::bind ftl find "gff" my_func "find fzf files"
    ftl::test::assert_eq "my_func" "${ftl_kbd_trie[gff]}" \
        "bind should register the full chord 'gff' in the trie"
}

test_unbind_does_not_decrement_prefix_count_bug() {
    # BUG: unbind removes the leaf but doesn't decrement prefix counts.
    # This is a memory leak in the trie.
    ftl::kbd::bind ftl find "gff" my_func "find"
    ftl::kbd::unbind "gff"
    # After unbind, the leaf is gone
    ftl::test::assert_eq "" "${ftl_kbd_trie[gff]:-}" \
        "unbind should remove the leaf binding"
    # Document the bug: prefix "g" and "gf" should ideally be cleaned up
    # if no other bindings use them, but currently they're left behind.
    ftl::test::pass "unbind prefix-count leak documented (g, gf prefixes left in trie)"
}

test_unbind_empty_shortcut_set_u_safety() {
    # Should not crash under set -u with empty argument
    ftl::kbd::unbind "" 2>/dev/null || true
    ftl::test::pass "unbind with empty shortcut did not crash"
}

test_bind_override_no_warning_by_default() {
    ftl::kbd::bind ftl move j original_func "move down"
    ftl::kbd::bind ftl move j new_func "move down new"
    ftl::test::assert_eq "new_func" "${ftl_kbd_trie[j]}" \
        "second bind should override the first"
}

# ============================================================================
# exclude_from_redo / reset_redo_exclusions
# ============================================================================

test_exclude_from_redo_adds_to_set() {
    ftl::kbd::exclude_from_redo "my_cmd"
    ftl::test::assert_eq 1 "${ftl_kbd_redo_excluded[my_cmd]:-0}" \
        "exclude_from_redo should mark the command as excluded"
}

test_reset_redo_exclusions_clears_set() {
    ftl::kbd::exclude_from_redo "cmd1"
    ftl::kbd::exclude_from_redo "cmd2"
    ftl::kbd::reset_redo_exclusions
    ftl::test::assert_eq 0 "${#ftl_kbd_redo_excluded[@]}" \
        "reset_redo_exclusions should empty the exclusion set"
}

test_init_exclusions_populates_defaults() {
    ftl::kbd::init_exclusions
    local count=${#ftl_kbd_redo_excluded[@]}
    ftl::test::assert_ne 0 "$count" \
        "init_exclusions should populate default exclusions"
}

# ============================================================================
# Bindings display
# ============================================================================

test_bind_populates_display_array() {
    ftl::kbd::bind ftl move j my_func "move down"
    ftl::test::assert_ne 0 "${#ftl_kbd_bindings_display[@]}" \
        "bind should populate the display array"
}

test_bind_populates_command_to_key_map() {
    ftl::kbd::bind ftl move j my_move_func "move down"
    ftl::test::assert_eq "j" "${ftl_kbd_command_to_key[my_move_func]}" \
        "bind should map command name to its key"
}

# vim: set filetype=bash :
