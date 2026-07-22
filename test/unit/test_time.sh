#!/bin/env bash
# test/unit/test_time.sh — tests for the time module
#
# Tests ftl::time::tick: no-op when interval=0, no-op when interval not
# reached, and handler invocation when the interval has elapsed.

# Source the module under test
source "$FTL_CFG/etc/core/modules/time.sh"

ftl::test::setup() {
    # Reset state
    declare -Ag ftl_time_handlers=()
    ftl_cfg_time_event_interval=0
    ftl_time_last_event_time=$SECONDS
    # Clear any handler call counter from a previous test
    FTL_TEST_HANDLER_CALLS=0
}

# A test handler that increments a counter
_test_time_handler_a() {
    FTL_TEST_HANDLER_CALLS=$((FTL_TEST_HANDLER_CALLS + 1))
}

# A second test handler that increments a different counter
_test_time_handler_b() {
    FTL_TEST_HANDLER_CALLS=$((FTL_TEST_HANDLER_CALLS + 100))
}

# Test: tick does nothing when interval is 0
test_tick_noop_when_interval_zero() {
    ftl_cfg_time_event_interval=0
    ftl_time_handlers["_test_time_handler_a"]=_test_time_handler_a
    ftl::time::tick
    ftl::test::assert_eq "0" "$FTL_TEST_HANDLER_CALLS" \
        "no handler should be called when interval=0"
}

# Test: tick does nothing when interval not yet reached
test_tick_noop_when_interval_not_reached() {
    ftl_cfg_time_event_interval=10
    ftl_time_last_event_time=$SECONDS
    ftl_time_handlers["_test_time_handler_a"]=_test_time_handler_a
    ftl::time::tick
    ftl::test::assert_eq "0" "$FTL_TEST_HANDLER_CALLS" \
        "no handler should be called when interval not reached"
}

# Test: tick calls handler when interval has elapsed
test_tick_calls_handler_when_elapsed() {
    ftl_cfg_time_event_interval=1
    # Set last event time far in the past so the interval is definitely elapsed
    ftl_time_last_event_time=$((SECONDS - 100))
    ftl_time_handlers["_test_time_handler_a"]=_test_time_handler_a
    ftl::time::tick
    ftl::test::assert_eq "1" "$FTL_TEST_HANDLER_CALLS" \
        "handler should be called once when interval elapsed"
}

# Test: tick calls multiple handlers
test_tick_calls_multiple_handlers() {
    ftl_cfg_time_event_interval=1
    ftl_time_last_event_time=$((SECONDS - 100))
    ftl_time_handlers["_test_time_handler_a"]=_test_time_handler_a
    ftl_time_handlers["_test_time_handler_b"]=_test_time_handler_b
    ftl::time::tick
    # a adds 1, b adds 100 -> total 101
    ftl::test::assert_eq "101" "$FTL_TEST_HANDLER_CALLS" \
        "both handlers should be called (1 + 100 = 101)"
}

# Test: tick resets the timer after firing
test_tick_resets_timer() {
    ftl_cfg_time_event_interval=5
    ftl_time_last_event_time=$((SECONDS - 100))
    ftl_time_handlers["_test_time_handler_a"]=_test_time_handler_a
    ftl::time::tick
    local after_first=$FTL_TEST_HANDLER_CALLS
    ftl::test::assert_eq "1" "$after_first" "first tick should fire handler"
    # Immediately tick again - should NOT fire (timer was just reset)
    ftl::time::tick
    ftl::test::assert_eq "1" "$FTL_TEST_HANDLER_CALLS" \
        "second tick immediately after should not fire (timer reset)"
}

# Test: tick returns 0 in all cases (interval=0)
test_tick_returns_zero_when_interval_zero() {
    ftl_cfg_time_event_interval=0
    if ftl::time::tick ; then
        ftl::test::pass "tick returns 0 when interval=0"
    else
        ftl::test::fail "tick should return 0 when interval=0"
    fi
}

# Test: tick returns 0 when firing handlers
test_tick_returns_zero_when_firing() {
    ftl_cfg_time_event_interval=1
    ftl_time_last_event_time=$((SECONDS - 100))
    ftl_time_handlers["_test_time_handler_a"]=_test_time_handler_a
    if ftl::time::tick ; then
        ftl::test::pass "tick returns 0 when firing handlers"
    else
        ftl::test::fail "tick should return 0 when firing handlers"
    fi
}

# Test: tick with no handlers registered is safe
test_tick_no_handlers() {
    ftl_cfg_time_event_interval=1
    ftl_time_last_event_time=$((SECONDS - 100))
    ftl_time_handlers=()
    if ftl::time::tick ; then
        ftl::test::pass "tick with no handlers is safe"
    else
        ftl::test::fail "tick should not fail with no handlers"
    fi
}
