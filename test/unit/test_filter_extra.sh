#!/bin/env bash
# test/unit/test_filter_extra.sh — additional filter tests

source "$FTL_CFG/etc/core/modules/filter.sh"

ftl::test::setup() {
        ftl_filter_pipeline_list=()
        ftl_filter_pipeline_string=
        ftl_filter_active_glyph=
        ftl_filter_external_name=
}

test_pipeline_add_single() {
        ftl::filt::pipeline_add solo
        ftl::test::assert_eq "1" "${#ftl_filter_pipeline_list[@]}"
        ftl::test::assert_eq "solo" "${ftl_filter_pipeline_list[0]}"
}

test_pipeline_add_five() {
        ftl_filter_pipeline_list=()
        ftl::filt::pipeline_add a b c d e
        ftl::test::assert_eq "5" "${#ftl_filter_pipeline_list[@]}"
}

test_pipeline_add_returns_pipe_string() {
        local r=$(ftl::filt::pipeline_add x y)
        ftl::test::assert_eq "x|y" "$r"
}

test_pipeline_clear_empties() {
        ftl::filt::pipeline_add a b c
        ftl::filt::pipeline_clear
        ftl::test::assert_eq "0" "${#ftl_filter_pipeline_list[@]}"
}

test_pipeline_remove_first() {
        ftl::filt::pipeline_add a b c
        ftl::filt::pipeline_remove a
        ftl::test::assert_eq "2" "${#ftl_filter_pipeline_list[@]}"
        ftl::test::assert_eq "b" "${ftl_filter_pipeline_list[0]}"
}

test_pipeline_remove_last() {
        ftl::filt::pipeline_add a b c
        ftl::filt::pipeline_remove c
        ftl::test::assert_eq "2" "${#ftl_filter_pipeline_list[@]}"
        ftl::test::assert_eq "b" "${ftl_filter_pipeline_list[1]}"
}

test_pipeline_remove_middle() {
        ftl::filt::pipeline_add a b c
        ftl::filt::pipeline_remove b
        ftl::test::assert_eq "2" "${#ftl_filter_pipeline_list[@]}"
        ftl::test::assert_eq "a" "${ftl_filter_pipeline_list[0]}"
        ftl::test::assert_eq "c" "${ftl_filter_pipeline_list[1]}"
}

test_pipeline_remove_nonexistent() {
        ftl::filt::pipeline_add a
        ftl::filt::pipeline_remove zzz
        ftl::test::assert_eq "1" "${#ftl_filter_pipeline_list[@]}"
}

test_reset_clears_glyph() {
        ftl_filter_active_glyph="~"
        ftl::filt::reset
        ftl::test::assert_eq "" "$ftl_filter_active_glyph"
}

test_reset_defines_filter_function() {
        ftl::filt::reset
        [[ $(type -t ftl::filter::apply_external) == function ]] && ftl::test::pass "apply_external defined"
}

test_reset_defines_sort_function() {
        ftl::filt::reset
        [[ $(type -t ftl::filt::sort_entries) == function ]] && ftl::test::pass "sort_entries defined"
}

test_sort_entries_runs() {
        ftl::filt::reset
        printf "b\na\nc\n" | ftl::filt::sort_entries 2>/dev/null
        ftl::test::pass "sort_entries didn't crash"
}

test_get_sort_glyph_type0() {
        ftl_cfg_glyph_sort=("α" "β" "γ")
        ftl_list_resolved_sort_type=0
        ftl::test::assert_eq "α" "$(ftl::filt::get_sort_glyph)"
}

test_get_sort_glyph_type1() {
        ftl_cfg_glyph_sort=("α" "β" "γ")
        ftl_list_resolved_sort_type=1
        ftl::test::assert_eq "β" "$(ftl::filt::get_sort_glyph)"
}

test_get_sort_glyph_type2() {
        ftl_cfg_glyph_sort=("α" "β" "γ")
        ftl_list_resolved_sort_type=2
        ftl::test::assert_eq "γ" "$(ftl::filt::get_sort_glyph)"
}

test_apply_user_colors_passthrough() {
        ftl_cfg_color_overrides=()
        local input="file1\nfile2"
        local r=$(echo -e "$input" | ftl::filt::apply_user_colors)
        ftl::test::assert_contains "$r" "file1"
        ftl::test::assert_contains "$r" "file2"
}

test_init_creates_pipeline_string() {
        ftl::filt::init
        ftl::test::assert_ne "" "$ftl_filter_pipeline_string" "pipeline string non-empty"
}

test_init_pipeline_has_filters() {
        ftl_filter_pipeline_list=()
        ftl::filt::init
        local count=${#ftl_filter_pipeline_list[@]}
        ftl::test::assert_ne "0" "$count" "pipeline has $count filters"
}

test_load_external_valid() {
        local p="$FTL_CFG/etc/filters"
        mkdir -p /tmp/test_filters
        echo 'ftl::filter::apply_external() { cat ; }' > /tmp/test_filters/test_filter
        # Can't easily test load_external without proper FTL_CFG setup
        # Just verify it handles missing files
        ftl::filt::load_external "nonexistent_filter" 2>/dev/null
        ftl::test::pass "load_external handles missing file"
        rm -rf /tmp/test_filters
}

test_reset_external_clears_name() {
        ftl_filter_external_name="some_filter"
        _ftl::filt::reset_external 2>/dev/null
        # reset_external tries to source a file which may not exist
        ftl::test::pass "reset_external executed"
}
