#!/bin/env bash
# test/unit/test_keyboard.sh — tests for the keyboard module
#
# Tests ftl::kbd::bind, ftl::kbd::unbind, ftl::kbd::normalize_key,
# and the trie dispatch mechanism.

# Source the module under test
source "$FTL_CFG/etc/core/modules/keyboard.sh"

# Test: bind registers a single-key binding
test_bind_single_key() {
    ftl::kbd::bind ftl move "j" test_move_down "down"
    ftl::test::assert_eq "test_move_down" "${ftl_kbd_trie[j]}" "trie should map j to test_move_down"
    ftl::test::assert_eq "j" "${ftl_kbd_command_to_key[test_move_down]}" "reverse map"
}

# Test: bind registers a multi-key binding
test_bind_multi_key() {
    ftl::kbd::bind ftl find "gff" test_find_fzf "fzf find"
    ftl::test::assert_eq "test_find_fzf" "${ftl_kbd_trie[gff]}" "trie should map gff"
}

# Test: bind registers a leader-key binding
test_bind_leader() {
    ftl::kbd::bind leader_ftl extra "LEADER f c" test_compress "compress"
    ftl::test::assert_eq "test_compress" "${ftl_kbd_trie[LEADERfc]}" "leader binding"
}

# Test: bind with count prefix
test_bind_with_count() {
    ftl::kbd::bind ftl move "COUNT %" test_move_percent "move by percent"
    # The count-prefixed binding should be in the trie
    ftl::test::assert_eq "test_move_percent" "${ftl_kbd_trie[COUNT%]}" "count binding"
}

# Test: unbind removes a binding
test_unbind() {
    ftl::kbd::bind ftl move "x" test_func "test"
    ftl::kbd::unbind "x"
    ftl::test::assert_eq "" "${ftl_kbd_trie[x]:-}" "trie should not have x after unbind"
    ftl::test::assert_eq "" "${ftl_kbd_command_to_key[test_func]:-}" "reverse map should be gone"
}

# Test: normalize_key translates escape sequences
test_normalize_escape() {
    local result
    result=$(ftl::kbd::normalize_key $'\e')
    ftl::test::assert_eq "ESCAPE" "$result" "ESC should normalize to ESCAPE"
}

# Test: normalize_key translates arrow keys
test_normalize_arrows() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[A')
    ftl::test::assert_eq "UP" "$result" "ESC[A should be UP"
    
    result=$(ftl::kbd::normalize_key $'\e[B')
    ftl::test::assert_eq "DOWN" "$result" "ESC[B should be DOWN"
    
    result=$(ftl::kbd::normalize_key $'\e[C')
    ftl::test::assert_eq "RIGHT" "$result" "ESC[C should be RIGHT"
    
    result=$(ftl::kbd::normalize_key $'\e[D')
    ftl::test::assert_eq "LEFT" "$result" "ESC[D should be LEFT"
}

# Test: normalize_key translates function keys
test_normalize_function_keys() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[11~')
    ftl::test::assert_eq "F1" "$result" "F1"
    
    result=$(ftl::kbd::normalize_key $'\e[12~')
    ftl::test::assert_eq "F2" "$result" "F2"
}

# Test: normalize_key translates control keys
test_normalize_control_keys() {
    local result
    result=$(ftl::kbd::normalize_key $'\001')
    ftl::test::assert_eq "CTL-A" "$result" "Ctrl-A"
    
    result=$(ftl::kbd::normalize_key $'\004')
    ftl::test::assert_eq "CTL-D" "$result" "Ctrl-D"
}

# Test: normalize_key translates special characters
test_normalize_special_chars() {
    local result
    result=$(ftl::kbd::normalize_key $'\177')
    ftl::test::assert_eq "BACKSPACE" "$result" "Backspace"
    
    result=$(ftl::kbd::normalize_key $'\t')
    ftl::test::assert_eq "TAB" "$result" "Tab"
    
    result=$(ftl::kbd::normalize_key $' ')
    ftl::test::assert_eq "SPACE" "$result" "Space"
}

# Test: normalize_key passes through plain ASCII letters and digits
# This is critical — without the *) fallback, j/k/h/l navigation breaks
test_normalize_plain_ascii() {
    local result
    result=$(ftl::kbd::normalize_key "j")
    ftl::test::assert_eq "j" "$result" "plain j passes through"
    
    result=$(ftl::kbd::normalize_key "k")
    ftl::test::assert_eq "k" "$result" "plain k passes through"
    
    result=$(ftl::kbd::normalize_key "h")
    ftl::test::assert_eq "h" "$result" "plain h passes through"
    
    result=$(ftl::kbd::normalize_key "l")
    ftl::test::assert_eq "l" "$result" "plain l passes through"
    
    result=$(ftl::kbd::normalize_key "q")
    ftl::test::assert_eq "q" "$result" "plain q passes through"
    
    result=$(ftl::kbd::normalize_key "a")
    ftl::test::assert_eq "a" "$result" "plain a passes through"
    
    result=$(ftl::kbd::normalize_key "5")
    ftl::test::assert_eq "5" "$result" "plain 5 passes through"
    
    result=$(ftl::kbd::normalize_key "Z")
    ftl::test::assert_eq "Z" "$result" "plain Z passes through"
    
    result=$(ftl::kbd::normalize_key ".")
    ftl::test::assert_eq "." "$result" "plain . passes through"
    
    result=$(ftl::kbd::normalize_key "-")
    ftl::test::assert_eq "-" "$result" "plain - passes through"
}

# Test: normalize_key drops multi-byte / unrecognized sequences
test_normalize_unrecognized() {
    local result
    # Multi-byte UTF-8 (é = \xc3\xa9) should produce empty
    result=$(ftl::kbd::normalize_key $'\xc3\xa9')
    ftl::test::assert_eq "" "$result" "multi-byte UTF-8 drops to empty"
}

# Test: exclude_from_redo adds to the exclusion set
test_exclude_from_redo() {
    ftl::kbd::exclude_from_redo "test_cmd"
    ftl::test::assert_eq "1" "${ftl_kbd_redo_excluded[test_cmd]}" "should be excluded"
}

# Test: reset_redo_exclusions clears the set
test_reset_redo_exclusions() {
    ftl::kbd::exclude_from_redo "cmd1"
    ftl::kbd::exclude_from_redo "cmd2"
    ftl::kbd::reset_redo_exclusions
    ftl::test::assert_eq "" "${ftl_kbd_redo_excluded[cmd1]:-}" "cmd1 should be cleared"
    ftl::test::assert_eq "" "${ftl_kbd_redo_excluded[cmd2]:-}" "cmd2 should be cleared"
}

# Test: AltGr mapping tables are populated
test_altgr_tables_exist() {
    ftl::test::assert_eq "ª" "${ftl_kbd_altgr_map[a]}" "AltGr+a should be ª"
    ftl::test::assert_eq "a" "${ftl_kbd_altgr_inverse[ª]}" "inverse AltGr ª should be a"
}
