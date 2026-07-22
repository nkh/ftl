#!/bin/env bash
# test/unit/test_keyboard_extra.sh — additional keyboard tests

source "$FTL_CFG/etc/core/modules/keyboard.sh"

test_bind_special_keys() {
	ftl::kbd::bind ftl test "ENTER" test_enter "enter"
	ftl::test::assert_eq "test_enter" "${ftl_kbd_trie[ENTER]}"
	ftl::kbd::bind ftl test "TAB" test_tab "tab"
	ftl::test::assert_eq "test_tab" "${ftl_kbd_trie[TAB]}"
	ftl::kbd::bind ftl test "ESCAPE" test_esc "esc"
	ftl::test::assert_eq "test_esc" "${ftl_kbd_trie[ESCAPE]}"
}

test_bind_space_key() {
	ftl::kbd::bind ftl test "SPACE" test_space "space"
	ftl::test::assert_eq "test_space" "${ftl_kbd_trie[SPACE]}"
}

test_bind_arrow_keys() {
	ftl::kbd::bind ftl test "UP" test_up "up"
	ftl::kbd::bind ftl test "DOWN" test_down "down"
	ftl::kbd::bind ftl test "LEFT" test_left "left"
	ftl::kbd::bind ftl test "RIGHT" test_right "right"
	ftl::test::assert_eq "test_up" "${ftl_kbd_trie[UP]}"
	ftl::test::assert_eq "test_down" "${ftl_kbd_trie[DOWN]}"
}

test_bind_function_keys() {
	ftl::kbd::bind ftl test "F1" test_f1 "f1"
	ftl::kbd::bind ftl test "F12" test_f12 "f12"
	ftl::test::assert_eq "test_f1" "${ftl_kbd_trie[F1]}"
	ftl::test::assert_eq "test_f12" "${ftl_kbd_trie[F12]}"
}

test_bind_control_keys() {
	ftl::kbd::bind ftl test "CTL-A" test_ctla "ctrl-a"
	ftl::kbd::bind ftl test "CTL-W" test_ctlw "ctrl-w"
	ftl::test::assert_eq "test_ctla" "${ftl_kbd_trie[CTL-A]}"
}

test_bind_alt_keys() {
	ftl::kbd::bind ftl test "ALT-J" test_altj "alt-j"
	ftl::kbd::bind ftl test "ALT-K" test_altk "alt-k"
	ftl::test::assert_eq "test_altj" "${ftl_kbd_trie[ALT-J]}"
}

test_bind_three_key_sequence() {
	ftl::kbd::bind ftl test "abc" test_abc "three keys"
	ftl::test::assert_eq "test_abc" "${ftl_kbd_trie[abc]}"
}

test_bind_overwrite() {
	ftl::kbd::bind ftl test "z" test_first "first"
	ftl::kbd::bind ftl test "z" test_second "second"
	ftl::test::assert_eq "test_second" "${ftl_kbd_trie[z]}" "second overwrites first"
}

test_unbind_removes_from_display() {
	ftl::kbd::bind ftl test "q" test_cmd "test"
	ftl::kbd::unbind "q"
	ftl::test::assert_eq "" "${ftl_kbd_bindings_display[*]}" "display should be empty"
}

test_unbind_nonexistent() {
	ftl::kbd::unbind "NONEXISTENT_KEY_123"
	ftl::test::pass "unbind nonexistent doesn't crash"
}

test_normalize_backspace() {
	local r=$(ftl::kbd::normalize_key $'\177')
	ftl::test::assert_eq "BACKSPACE" "$r"
}

test_normalize_enter() {
	local r=$(ftl::kbd::normalize_key $'')
	ftl::test::assert_eq "ENTER" "$r"
}

test_normalize_tab() {
	local r=$(ftl::kbd::normalize_key $'\t')
	ftl::test::assert_eq "TAB" "$r"
}

test_normalize_space() {
	local r=$(ftl::kbd::normalize_key $' ')
	ftl::test::assert_eq "SPACE" "$r"
}

test_normalize_star() {
	local r=$(ftl::kbd::normalize_key $'*')
	ftl::test::assert_eq "STAR" "$r"
}

test_normalize_at() {
	local r=$(ftl::kbd::normalize_key $'@')
	ftl::test::assert_eq "AT" "$r"
}

test_normalize_quote() {
	local r=$(ftl::kbd::normalize_key $"'" )
	ftl::test::assert_eq "QUOTE" "$r"
}

test_normalize_dquote() {
	local r=$(ftl::kbd::normalize_key $'"')
	ftl::test::assert_eq "DQUOTE" "$r"
}

test_normalize_ins() {
	local r=$(ftl::kbd::normalize_key $'\e[2~')
	ftl::test::assert_eq "INS" "$r"
}

test_normalize_del() {
	local r=$(ftl::kbd::normalize_key $'\e[3~')
	ftl::test::assert_eq "DEL" "$r"
}

test_normalize_home() {
	local r=$(ftl::kbd::normalize_key $'\e[1~')
	ftl::test::assert_eq "HOME" "$r"
}

test_normalize_end() {
	local r=$(ftl::kbd::normalize_key $'\e[4~')
	ftl::test::assert_eq "END" "$r"
}

test_normalize_pgup() {
	local r=$(ftl::kbd::normalize_key $'\e[5~')
	ftl::test::assert_eq "PGUP" "$r"
}

test_normalize_pgdn() {
	local r=$(ftl::kbd::normalize_key $'\e[6~')
	ftl::test::assert_eq "PGDN" "$r"
}

test_normalize_alt_j() {
	local r=$(ftl::kbd::normalize_key $'\ej')
	ftl::test::assert_eq "ALT-J" "$r"
}

test_normalize_alt_k() {
	local r=$(ftl::kbd::normalize_key $'\ek')
	ftl::test::assert_eq "ALT-K" "$r"
}

test_altgr_table_complete() {
	# Check a few specific AltGr mappings
	ftl::test::assert_eq "©" "${ftl_kbd_altgr_map[c]}" "AltGr+c=©"
	ftl::test::assert_eq "€" "${ftl_kbd_altgr_map[e]}" "AltGr+e=€"
	ftl::test::assert_eq "®" "${ftl_kbd_altgr_map[r]}" "AltGr+r=®"
}

test_shift_altgr_table_complete() {
	ftl::test::assert_eq "Ð" "${ftl_kbd_shift_altgr_map[d]}" "Shift+AltGr+d=Ð"
	ftl::test::assert_eq "Þ" "${ftl_kbd_shift_altgr_map[p]}" "Shift+AltGr+p=Þ"
}

test_inverse_tables_consistent() {
	# Every value in altgr_map should have an inverse
	local key val
	for key in "${!ftl_kbd_altgr_map[@]}"; do
		val="${ftl_kbd_altgr_map[$key]}"
		[[ -n "${ftl_kbd_altgr_inverse[$val]:-}" ]] || ftl::test::fail "no inverse for $val"
	done
	ftl::test::pass "all AltGr values have inverses"
}

test_reset_exclusions_multiple() {
	ftl::kbd::reset_redo_exclusions
	ftl::kbd::exclude_from_redo "cmd_a"
	ftl::kbd::exclude_from_redo "cmd_b"
	ftl::kbd::exclude_from_redo "cmd_c"
	ftl::test::assert_eq "3" "${#ftl_kbd_redo_excluded[@]}" "3 exclusions"
}

test_reset_exclusions_clears_all() {
	ftl::kbd::exclude_from_redo "x"
	ftl::kbd::exclude_from_redo "y"
	ftl::kbd::reset_redo_exclusions
	ftl::test::assert_eq "0" "${#ftl_kbd_redo_excluded[@]}" "all cleared"
}

test_bindings_display_has_help() {
	ftl::kbd::bind ftl test "tt" test_cmd "my help text"
	# The display array should contain the help text
	local found=0
	local key
	for key in "${!ftl_kbd_bindings_display[@]}"; do
		[[ "${ftl_kbd_bindings_display[$key]}" == *"my help text"* ]] && found=1
	done
	ftl::test::assert_eq "1" "$found" "help text in display"
}
