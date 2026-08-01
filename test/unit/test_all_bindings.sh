#!/bin/env bash
# test/unit/test_all_bindings.sh — existence test for every registered binding
#
# Sources ftl_setup, iterates all bindings in ftl_kbd_trie, and verifies
# that each bound function exists. This catches missing functions,
# misspelled names, and broken references.

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

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
source "$FTL_CFG/etc/core/modules/inline_rename.sh"

# Stub tmux
tmux() { : ; }

ftl::test::setup() {
        :
}

ftl::test::teardown() {
        :
}

# Source ftlrc to register bindings
source "$FTL_CFG/etc/ftlrc" 2>/dev/null

# Test: every binding's function exists
test_all_binding_functions_exist() {
        local missing=0
        local total=0
        for key in "${!ftl_kbd_trie[@]}" ; do
                fn="${ftl_kbd_trie[$key]}"
                [[ "$fn" =~ ^[0-9]+$ ]] && continue
                ((total++))
                if [[ $(type -t "$fn" 2>/dev/null) != "function" ]] ; then
                        ftl::test::fail "MISSING: $key -> $fn"
                        ((missing++))
                fi
        done
        (( missing == 0 )) && ftl::test::pass "all $total binding functions exist"
}

# Test: core navigation bindings exist
test_core_navigation_bindings() {
        local keys=(j k h l q ENTER UP DOWN LEFT RIGHT)
        for key in "${keys[@]}" ; do
                local fn="${ftl_kbd_trie[$key]:-}"
                [[ -n "$fn" ]] || ftl::test::fail "binding '$key' not registered"
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "binding '$key' -> '$fn' is not a function"
        done
        ftl::test::pass "core navigation bindings exist"
}

# Test: leader key bindings exist
test_leader_bindings() {
        local keys=(LEADERri LEADERhh LEADERdd LEADERdt)
        for key in "${keys[@]}" ; do
                local fn="${ftl_kbd_trie[$key]:-}"
                [[ -n "$fn" ]] || ftl::test::fail "binding '$key' not registered"
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "binding '$key' -> '$fn' is not a function"
        done
        ftl::test::pass "leader bindings exist"
}

# Test: file operation bindings exist
test_file_operation_bindings() {
        local keys=(d w pp pm R xd xH xt xs xv xR xn xo)
        for key in "${keys[@]}" ; do
                local fn="${ftl_kbd_trie[$key]:-}"
                [[ -n "$fn" ]] || ftl::test::fail "binding '$key' not registered"
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "binding '$key' -> '$fn' is not a function"
        done
        ftl::test::pass "file operation bindings exist"
}

# Test: selection bindings exist
test_selection_bindings() {
        local keys=(y1 y2 y3 y4 ya yf yi yS yL)
        for key in "${keys[@]}" ; do
                local fn="${ftl_kbd_trie[$key]:-}"
                [[ -n "$fn" ]] || ftl::test::fail "binding '$key' not registered"
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "binding '$key' -> '$fn' is not a function"
        done
        ftl::test::pass "selection bindings exist"
}

# Test: preview bindings exist
test_preview_bindings() {
        local keys=(zi zp zP zpc zr zL z+ zv zz)
        for key in "${keys[@]}" ; do
                local fn="${ftl_kbd_trie[$key]:-}"
                [[ -n "$fn" ]] || ftl::test::fail "binding '$key' not registered"
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "binding '$key' -> '$fn' is not a function"
        done
        ftl::test::pass "preview bindings exist"
}

# Test: filter bindings exist
test_filter_bindings() {
        local keys=(fe ff fF fd fr fc fy fx fX)
        for key in "${keys[@]}" ; do
                local fn="${ftl_kbd_trie[$key]:-}"
                [[ -n "$fn" ]] || ftl::test::fail "binding '$key' not registered"
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "binding '$key' -> '$fn' is not a function"
        done
        ftl::test::pass "filter bindings exist"
}

# Test: tab bindings exist
test_tab_bindings() {
        local keys=(TAB gt gT)
        for key in "${keys[@]}" ; do
                local fn="${ftl_kbd_trie[$key]:-}"
                [[ -n "$fn" ]] || ftl::test::fail "binding '$key' not registered"
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "binding '$key' -> '$fn' is not a function"
        done
        ftl::test::pass "tab bindings exist"
}

# Test: search bindings exist
test_search_bindings() {
        local keys=(n N rR rh grr grf grl grt)
        for key in "${keys[@]}" ; do
                local fn="${ftl_kbd_trie[$key]:-}"
                [[ -n "$fn" ]] || ftl::test::fail "binding '$key' not registered"
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "binding '$key' -> '$fn' is not a function"
        done
        ftl::test::pass "search bindings exist"
}

# Test: missing functionalities bindings exist
test_missing_functionalities_bindings() {
        local keys=(xd xH xt xs xv xR xn xo zA ALT-z ALT-y v rR rh zp zP zpc zi zo zr zL CP gbl gll gds)
        for key in "${keys[@]}" ; do
                local fn="${ftl_kbd_trie[$key]:-}"
                [[ -n "$fn" ]] || ftl::test::fail "binding '$key' not registered"
                [[ $(type -t "$fn") == function ]] || ftl::test::fail "binding '$key' -> '$fn' is not a function"
        done
        ftl::test::pass "missing functionalities bindings exist"
}

# vim: set filetype=bash :
