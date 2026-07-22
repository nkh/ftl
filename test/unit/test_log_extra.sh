#!/bin/env bash
# test/unit/test_log_extra.sh — additional log tests

source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"

ftl::test::setup() {
	ftl_log_level=0
	ftl_log_file=""
}

ftl::test::teardown() {
	rm -f /tmp/ftl_log_test_*.log 2>/dev/null
}

test_init_level_from_ftl_debug() {
	FTL_DEBUG=1 ftl::log::init
	ftl::test::assert_eq "1" "$ftl_log_level"
}

test_init_level_from_ftl_trace() {
	FTL_TRACE=1 ftl::log::init
	ftl::test::assert_eq "2" "$ftl_log_level"
}

test_init_level_default_zero() {
	FTL_DEBUG= FTL_TRACE= ftl::log::init
	ftl::test::assert_eq "0" "$ftl_log_level"
}

test_init_creates_log_file() {
	ftl_state_session_dir=$(mktemp -d)
	FTL_DEBUG=1 ftl::log::init
	ftl::test::assert_eq "1" "$(test -f "$ftl_state_session_dir/debug.log" && echo 1)"
	rm -rf "$ftl_state_session_dir"
}

test_init_writes_banner() {
	ftl_state_session_dir=$(mktemp -d)
	FTL_DEBUG=1 ftl::log::init
	local content=$(cat "$ftl_state_session_dir/debug.log")
	ftl::test::assert_contains "$content" "ftl debug log"
	ftl::test::assert_contains "$content" "PID:"
	rm -rf "$ftl_state_session_dir"
}

test_set_level_debug() {
	ftl::log::set_level 1
	ftl::test::assert_eq "1" "$ftl_log_level"
}

test_set_level_trace() {
	ftl::log::set_level 2
	ftl::test::assert_eq "2" "$ftl_log_level"
}

test_set_level_off() {
	ftl_log_level=1
	ftl::log::set_level 0
	ftl::test::assert_eq "0" "$ftl_log_level"
}

test_debug_writes_when_enabled() {
	ftl_log_level=1
	ftl_log_file="/tmp/ftl_log_test_debug.log"
	: > "$ftl_log_file"
	ftl::log::debug "test message 123"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "test message 123"
}

test_debug_skips_when_disabled() {
	ftl_log_level=0
	ftl_log_file="/tmp/ftl_log_test_skip.log"
	: > "$ftl_log_file"
	ftl::log::debug "should not appear"
	ftl::test::assert_eq "" "$(cat "$ftl_log_file")"
}

test_trace_writes_at_level2() {
	ftl_log_level=2
	ftl_log_file="/tmp/ftl_log_test_trace.log"
	: > "$ftl_log_file"
	ftl::log::trace "trace msg"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "trace msg"
}

test_trace_skips_at_level1() {
	ftl_log_level=1
	ftl_log_file="/tmp/ftl_log_test_trace2.log"
	: > "$ftl_log_file"
	ftl::log::trace "should not appear"
	ftl::test::assert_eq "" "$(cat "$ftl_log_file")"
}

test_info_always_writes() {
	ftl_log_level=0
	ftl_log_file="/tmp/ftl_log_test_info.log"
	: > "$ftl_log_file"
	ftl::log::info "info always"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "info always"
}

test_info_includes_timestamp() {
	ftl_log_file="/tmp/ftl_log_test_ts.log"
	: > "$ftl_log_file"
	ftl::log::info "ts test"
	local content=$(cat "$ftl_log_file")
	ftl::test::assert_match "[0-9][0-9]:[0-9][0-9]:[0-9][0-9]" "$content"
}

test_debug_includes_level_label() {
	ftl_log_level=1
	ftl_log_file="/tmp/ftl_log_test_label.log"
	: > "$ftl_log_file"
	ftl::log::debug "labeled"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "DEBUG"
}

test_trace_includes_level_label() {
	ftl_log_level=2
	ftl_log_file="/tmp/ftl_log_test_tlabel.log"
	: > "$ftl_log_file"
	ftl::log::trace "traced"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "TRACE"
}

test_warn_calls_debug() {
	ftl_log_level=1
	ftl_log_file="/tmp/ftl_log_test_warn.log"
	: > "$ftl_log_file"
	ftl::log::warn "warning msg"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "WARN: warning msg"
}

test_error_calls_debug() {
	ftl_log_level=1
	ftl_log_file="/tmp/ftl_log_test_error.log"
	: > "$ftl_log_file"
	ftl::log::error "error msg"
	ftl::test::assert_contains "$(cat "$ftl_log_file")" "ERROR: error msg"
}

test_custom_log_file() {
	ftl_cfg_debug_log_file="/tmp/ftl_log_test_custom.log"
	FTL_DEBUG=1 ftl::log::init
	ftl::test::assert_eq "/tmp/ftl_log_test_custom.log" "$ftl_log_file"
}

test_wrap_captures_stderr() {
	ftl_state_session_dir=$(mktemp -d)
	local r=$(ftl::log::wrap echo "hello" 2>&1)
	ftl::test::assert_contains "$r" "hello"
	rm -rf "$ftl_state_session_dir"
}

test_wrap_silent_on_success() {
	ftl_state_session_dir=$(mktemp -d)
	ftl::log::wrap true 2>/dev/null
	ftl::test::assert_eq "0" "$(test -s "$ftl_state_session_dir/log" && echo 1 || echo 0)" "log empty on success"
	rm -rf "$ftl_state_session_dir"
}
