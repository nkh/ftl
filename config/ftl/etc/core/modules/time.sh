# time.sh — time-based event handlers
#
# Manages periodic time events. If ftl_cfg_time_event_interval is positive,
# all registered handlers in ftl_time_handlers are called every N seconds.
#
# Public functions:
#   ftl::time::tick                — check if it's time to fire handlers
#
# Globals:
#   ftl_time_handlers              — assoc: handler fn name → fn name (was: time_event_handlers)
#   ftl_time_last_event_time       — timestamp of last firing (was: time_event0)

declare -Ag ftl_time_handlers
ftl_time_last_event_time=$SECONDS

# Check if enough time has elapsed to fire time-event handlers.
# If so, call all registered handlers and reset the timer.
ftl::time::tick() {
    (( ftl_cfg_time_event_interval )) || return 0
    (( SECONDS - ftl_time_last_event_time >= ftl_cfg_time_event_interval )) || return 0
    local handler
    for handler in "${!ftl_time_handlers[@]}" ; do
        "$handler"
    done
    ftl_time_last_event_time=$SECONDS
}

# vim: set filetype=bash :
