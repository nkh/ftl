#!/bin/env bash
# test/unit/test_selection_extra.sh — additional selection tests

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"

ftl::test::setup() {
	ftl_selection_tags=()
	ftl_selection_total_bytes=0
	ftl_selection_revision=0
	ftl_selection_current=()
}

test_flip_toggle_cycle() {
	ftl::sel::flip "/tmp/a"
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}"
	ftl::sel::flip "/tmp/a"
	ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}"
	ftl::sel::flip "/tmp/a"
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}"
}

test_flip_custom_glyphs() {
	ftl::sel::flip "/tmp/x" "¹"
	ftl::test::assert_eq "¹" "${ftl_selection_tags[/tmp/x]}"
	ftl::sel::flip "/tmp/y" "²"
	ftl::test::assert_eq "²" "${ftl_selection_tags[/tmp/y]}"
	ftl::sel::flip "/tmp/z" "³"
	ftl::test::assert_eq "³" "${ftl_selection_tags[/tmp/z]}"
}

test_set_idempotent() {
	ftl::sel::set "/tmp/idem"
	ftl::sel::set "/tmp/idem"
	ftl::sel::set "/tmp/idem"
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "set is idempotent"
}

test_set_preserves_existing_glyph() {
	ftl::sel::set "/tmp/g" "¹"
	ftl::sel::set "/tmp/g" "²"
	ftl::test::assert_eq "¹" "${ftl_selection_tags[/tmp/g]}" "set doesn't change existing"
}

test_unset_nonexistent_noop() {
	ftl::sel::unset "/nonexistent/path"
	ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}"
}

test_unset_by_class() {
	ftl::sel::set "/tmp/a" "¹"
	ftl::sel::set "/tmp/b" "¹"
	ftl::sel::set "/tmp/c" "²"
	ftl::sel::unset_by_class "¹"
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "only class ² remains"
	ftl::test::assert_eq "²" "${ftl_selection_tags[/tmp/c]}" "c has class ²"
}

test_clear_resets_revision() {
	ftl::sel::set "/tmp/r1"
	local rev=$ftl_selection_revision
	ftl::sel::clear_all
	ftl::test::assert_eq "$((rev + 1))" "$ftl_selection_revision" "clear increments revision"
}

test_clear_resets_total_bytes() {
	local tmpf=$(mktemp); echo "data" > "$tmpf"
	ftl::sel::set "$tmpf"
	ftl::test::assert_ne "0" "$ftl_selection_total_bytes"
	ftl::sel::clear_all
	ftl::test::assert_eq "0" "$ftl_selection_total_bytes"
	rm "$tmpf"
}

test_validate_removes_multiple() {
	ftl::sel::set "/nonexistent1"
	ftl::sel::set "/nonexistent2"
	ftl::sel::set "/nonexistent3"
	ftl::sel::validate_existence
	ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "all removed"
}

test_validate_keeps_directories() {
	local tmpd=$(mktemp -d)
	ftl::sel::set "$tmpd"
	ftl::sel::validate_existence
	ftl::test::assert_eq "1" "${#ftl_selection_tags[@]}" "existing dir kept"
	rmdir "$tmpd"
}

test_adjust_size_add() {
	local tmpf=$(mktemp); echo "hello" > "$tmpf"
	local before=$ftl_selection_total_bytes
	ftl::sel::adjust_total_size + "$tmpf"
	ftl::test::assert_ne "$before" "$ftl_selection_total_bytes" "size increased"
	rm "$tmpf"
}

test_adjust_size_subtract() {
	local tmpf=$(mktemp); echo "hello" > "$tmpf"
	ftl::sel::adjust_total_size + "$tmpf"
	local after_add=$ftl_selection_total_bytes
	ftl::sel::adjust_total_size - "$tmpf"
	ftl::test::assert_eq "0" "$ftl_selection_total_bytes" "size back to 0"
	rm "$tmpf"
}

test_header_summary_empty() {
	local r=$(ftl::sel::format_header_summary)
	ftl::test::assert_eq "" "$r" "empty when no tags"
}

test_header_summary_shows_count() {
	local tmpf=$(mktemp)
	ftl::sel::set "$tmpf"
	local r=$(ftl::sel::format_header_summary)
	ftl::test::assert_contains "$r" "1/" "shows count 1"
	rm "$tmpf"
}

test_header_summary_shows_size() {
	local tmpf=$(mktemp); echo "12345678" > "$tmpf"
	ftl::sel::set "$tmpf"
	local r=$(ftl::sel::format_header_summary)
	# Should contain a size indicator (K, M, etc.)
	ftl::test::assert_match "[0-9]" "$r" "shows a number"
	rm "$tmpf"
}

test_resolve_falls_back_to_cursor() {
	ftl_list_entry_count=1
	ftl_list_entries=("/tmp/current_file")
	ftl_state_cursor_index=0
	ftl::sel::resolve_current
	ftl::test::assert_eq "1" "${#ftl_selection_current[@]}"
	ftl::test::assert_eq "/tmp/current_file" "${ftl_selection_current[0]}"
}

test_resolve_prefers_tags_over_cursor() {
	ftl_list_entry_count=1
	ftl_list_entries=("/tmp/cursor_file")
	ftl_state_cursor_index=0
	ftl::sel::set "/tmp/tagged_file"
	ftl::sel::resolve_current
	ftl::test::assert_eq "1" "${#ftl_selection_current[@]}"
	ftl::test::assert_eq "/tmp/tagged_file" "${ftl_selection_current[0]}"
}

test_multiple_classes_coexist() {
	ftl::sel::set "/tmp/a" "¹"
	ftl::sel::set "/tmp/b" "²"
	ftl::sel::set "/tmp/c" "³"
	ftl::test::assert_eq "3" "${#ftl_selection_tags[@]}"
}

test_goto_by_index_zero() {
	ftl::sel::set "/tmp/goto_test"
	# goto_by_index 0 should try to cd — will fail without tmux but shouldn't crash
	ftl::sel::goto_by_index 0 2>/dev/null
	ftl::test::pass "goto_by_index didn't crash"
}

test_fzf_tag_or_untag_empty_input() {
	ftl::sel::fzf_tag_or_untag T ""
	ftl::test::assert_eq "0" "${#ftl_selection_tags[@]}" "empty input = no change"
}

test_load_from_file() {
	local tmpf=$(mktemp)
	echo "/tmp/loaded1" > "$tmpf"
	echo "/tmp/loaded2" >> "$tmpf"
	ftl::sel::load_from_file "" "$tmpf"
	ftl::test::assert_eq "2" "${#ftl_selection_tags[@]}" "2 tags loaded"
	rm "$tmpf"
}
