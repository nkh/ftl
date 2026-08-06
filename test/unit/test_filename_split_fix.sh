#!/bin/env bash
# test/unit/test_filename_split_fix.sh — tests for upstream b1234f0
# "FIXED: bad splitting of file name"
#
# Covers the two non-truncation changes in b1234f0:
#   1. find_dirs_via_fzf appends a final _ftl::list::render_window call
#      (mirrors upstream appending `view_list` to find_fzf_dirs)
#   2. pcbr no longer emits a debug line before showing the cover
#      (parity with pcbz — upstream removed `pdhn "preview file: $t"`)

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

# Source the modules under test
source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"
source "$FTL_CFG/etc/core/modules/selection.sh"
source "$FTL_CFG/etc/core/modules/tab.sh"
source "$FTL_CFG/etc/core/modules/pane.sh"
source "$FTL_CFG/etc/core/modules/filter.sh"
source "$FTL_CFG/etc/core/modules/list.sh"
source "$FTL_CFG/etc/core/modules/preview.sh"
source "$FTL_CFG/etc/core/modules/etag.sh"
source "$FTL_CFG/etc/core/modules/virtual.sh"
source "$FTL_CFG/etc/core/modules/mark.sh"
source "$FTL_CFG/etc/core/modules/time.sh"
source "$FTL_CFG/etc/core/modules/commands.sh"
source "$FTL_CFG/etc/viewers/core"

# Stubs — these touch tmux / preview / external state we don't want
tmux() { : ; }
stty() { : ; }
tput() { : ; }
ftl::pane::stop_file_watcher() { : ; }
ftl::pane::start_file_watcher() { : ; }
ftl::pane::query_geometry() { : ; }
ftl::pane::snapshot_geometry() { : ; }
ftl::prev::dispatch() { : ; }
ftl::prev::clear() { : ; }
ftl::prev::show_image() { : ; }
ftl::state::save() { : ; }
ftl::sel::resolve_current() { : ; }
ftl::sel::sync_from_other_pane() { false ; }

ftl::test::setup() {
        ftl_state_session_dir=$(mktemp -d)
        ftl_state_current_path=
        ftl_state_current_tab_index=0
        ftl_state_cursor_index=0
        ftl_pane_height=24
        ftl_pane_width=80
        ftl_pane_is_child=0
        ftl_cfg_fzf_pane_opts=
        ftl_cfg_fzf_popup_opts=
}

ftl::test::teardown() {
        [[ -n "${ftl_state_session_dir:-}" ]] && rm -rf "$ftl_state_session_dir"
}

# ---------------------------------------------------------------------------
# find_dirs_via_fzf — final render_window call (b1234f0)
# ---------------------------------------------------------------------------

# Test: find_dirs_via_fzf calls _ftl::list::render_window after the search
test_find_dirs_via_fzf_calls_render_window() {
        # Stub process_search_results so the fzf pipeline is short-circuited
        _ftl::cmd::process_search_results() { : ; }
        # Stub render_window with a recorder
        _ftl_test_render_window_calls=0
        _ftl::list::render_window() { ((_ftl_test_render_window_calls++)) ; }

        # Stub external commands so the function body completes
        fd() { : ; }
        fzf_vvip() { : ; }

        # find_dirs_via_fzf uses `exec 2>&9` — fd 9 must be open
        exec 9>&2
        ftl::cmd::find_dirs_via_fzf
        exec 9>&-

        ftl::test::assert_eq 1 "$_ftl_test_render_window_calls" \
                "find_dirs_via_fzf should call _ftl::list::render_window exactly once at the end"
}

# Test: render_window is called even if process_search_results receives no results
test_find_dirs_via_fzf_renders_even_with_empty_results() {
        _ftl::cmd::process_search_results() { : ; }
        _ftl_test_render_window_calls=0
        _ftl::list::render_window() { ((_ftl_test_render_window_calls++)) ; }
        fd() { : ; }
        fzf_vvip() { : ; }

        exec 9>&2
        ftl::cmd::find_dirs_via_fzf
        exec 9>&-

        ftl::test::assert_eq 1 "$_ftl_test_render_window_calls" \
                "render_window should be called even with no search results"
}

# Test: other find variants (find_via_fzf, find_via_frf) do NOT append render_window
# (only find_dirs_via_fzf was changed by b1234f0)
test_find_via_fzf_does_not_call_render_window() {
        _ftl::cmd::process_search_results() { : ; }
        _ftl_test_render_window_calls=0
        _ftl::list::render_window() { ((_ftl_test_render_window_calls++)) ; }
        fd() { : ; }
        fzf_vvip() { : ; }

        exec 9>&2
        ftl::cmd::find_via_fzf
        exec 9>&-

        ftl::test::assert_eq 0 "$_ftl_test_render_window_calls" \
                "find_via_fzf should NOT call render_window (only find_dirs_via_fzf was changed)"
}

# ---------------------------------------------------------------------------
# pcbr — debug log removed (b1234f0)
# ---------------------------------------------------------------------------

# Test: pcbr does not call ftl::log::debug when the extracted file exists
test_pcbr_no_debug_log_when_file_exists() {
        local fake_gen_dir
        fake_gen_dir=$(mktemp -d)
        ftl_gen_dir="$fake_gen_dir"
        ftl_cache_thumb_dir="$fake_gen_dir"
        mkdir -p "$fake_gen_dir/cbr"
        # Create the extracted file so the [[ -e $t ]] branch is taken
        local fake_t="$fake_gen_dir/cbr/extracted.png"
        : > "$fake_t"
        # Generator script echoes the fake path
        cat > "$fake_gen_dir/cbr" <<EOF
#!/usr/bin/env bash
echo "$fake_t"
EOF
        chmod +x "$fake_gen_dir/cbr"

        ftl_state_current_path="dummy.cbr"
        ftl::plugin::core::ptype() { : ; }

        _ftl_test_pcbr_log_calls=0
        ftl::log::debug() { ((_ftl_test_pcbr_log_calls++)) ; }

        ftl::plugin::core::pcbr

        ftl::test::assert_eq 0 "$_ftl_test_pcbr_log_calls" \
                "pcbr should NOT call ftl::log::debug (b1234f0 removed the debug call)"

        rm -rf "$fake_gen_dir"
}

# Test: pcbr does not call ftl::log::debug when the extracted file is missing
test_pcbr_no_debug_log_when_file_missing() {
        local fake_gen_dir
        fake_gen_dir=$(mktemp -d)
        ftl_gen_dir="$fake_gen_dir"
        ftl_cache_thumb_dir="$fake_gen_dir"
        mkdir -p "$fake_gen_dir/cbr"
        # Generator echoes a non-existent path
        cat > "$fake_gen_dir/cbr" <<'EOF'
#!/usr/bin/env bash
echo "/nonexistent/missing.png"
EOF
        chmod +x "$fake_gen_dir/cbr"

        ftl_state_current_path="dummy.cbr"
        ftl::plugin::core::ptype() { : ; }

        _ftl_test_pcbr_log_calls=0
        ftl::log::debug() { ((_ftl_test_pcbr_log_calls++)) ; }

        ftl::plugin::core::pcbr

        ftl::test::assert_eq 0 "$_ftl_test_pcbr_log_calls" \
                "pcbr should NOT call ftl::log::debug even when the file is missing"

        rm -rf "$fake_gen_dir"
}

# Test: pcbr still calls ftl::prev::show_image when the file exists
test_pcbr_calls_show_image_when_file_exists() {
        local fake_gen_dir
        fake_gen_dir=$(mktemp -d)
        ftl_gen_dir="$fake_gen_dir"
        ftl_cache_thumb_dir="$fake_gen_dir"
        mkdir -p "$fake_gen_dir/cbr"
        local fake_t="$fake_gen_dir/cbr/extracted.png"
        : > "$fake_t"
        cat > "$fake_gen_dir/cbr" <<EOF
#!/usr/bin/env bash
echo "$fake_t"
EOF
        chmod +x "$fake_gen_dir/cbr"

        ftl_state_current_path="dummy.cbr"
        ftl::plugin::core::ptype() { : ; }
        _ftl_test_show_image_calls=0
        ftl::prev::show_image() { ((_ftl_test_show_image_calls++)) ; }

        ftl::plugin::core::pcbr

        ftl::test::assert_eq 1 "$_ftl_test_show_image_calls" \
                "pcbr should call show_image when the extracted file exists"

        rm -rf "$fake_gen_dir"
}

# Test: pcbr falls back to ptype when the file is missing
test_pcbr_calls_ptype_when_file_missing() {
        local fake_gen_dir
        fake_gen_dir=$(mktemp -d)
        ftl_gen_dir="$fake_gen_dir"
        ftl_cache_thumb_dir="$fake_gen_dir"
        mkdir -p "$fake_gen_dir/cbr"
        cat > "$fake_gen_dir/cbr" <<'EOF'
#!/usr/bin/env bash
echo "/nonexistent/missing.png"
EOF
        chmod +x "$fake_gen_dir/cbr"

        ftl_state_current_path="dummy.cbr"
        _ftl_test_ptype_calls=0
        ftl::plugin::core::ptype() { ((_ftl_test_ptype_calls++)) ; }

        ftl::plugin::core::pcbr

        ftl::test::assert_eq 1 "$_ftl_test_ptype_calls" \
                "pcbr should fall back to ptype when the extracted file is missing"

        rm -rf "$fake_gen_dir"
}

# Test: pcbr and pcbz have the same structure (no extra debug call)
test_pcbr_matches_pcbr_structure() {
        # Source both function bodies and compare their structure (ignoring
        # the generator name and thumb subdir). Both should:
        #   1. Call the generator to get a path
        #   2. If [[ -e $t ]]: call ftl::prev::show_image
        #   3. Else: call ftl::plugin::core::ptype
        # pcbr should NOT have an extra log::debug call that pcbz lacks.
        local pcbr_body pcbz_body
        pcbr_body=$(type -f ftl::plugin::core::pcbr 2>/dev/null || true)
        pcbz_body=$(type -f ftl::plugin::core::pcbz 2>/dev/null || true)

        # Both functions should exist
        ftl::test::assert_contains "$pcbr_body" "ftl::plugin::core::pcbr" \
                "pcbr function should be defined"
        ftl::test::assert_contains "$pcbz_body" "ftl::plugin::core::pcbz" \
                "pcbz function should be defined"

        # pcbr should NOT call ftl::log::debug
        ftl::test::assert_not_contains "$pcbr_body" "ftl::log::debug" \
                "pcbr should not contain a ftl::log::debug call (parity with pcbz, b1234f0)"
        # pcbz should NOT call ftl::log::debug either (control)
        ftl::test::assert_not_contains "$pcbz_body" "ftl::log::debug" \
                "pcbz should not contain a ftl::log::debug call"
}

# vim: set filetype=bash :
