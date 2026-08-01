# log.sh — logging and error reporting
#
# Unified logging system with toggleable debug levels. Set FTL_DEBUG=1
# in the environment or ftlrc to enable debug logging to a file.
# Set ftl_cfg_debug_log_file to a path to write debug messages to a file.
#
# Public functions:
#   ftl::log::wrap              — run a command with stderr captured
#   ftl::log::error             — log an error (red popup)
#   ftl::log::warn              — log a warning (yellow popup)
#   ftl::log::info              — log an info message (to log file)
#   ftl::log::debug             — log a debug message (if FTL_DEBUG=1)
#   ftl::log::trace             — log a trace message (if FTL_TRACE=1)
#   ftl::log::show_debug_pane   — open/close the pdh debug pane
#   ftl::log::log_caller        — log BASH_SOURCE/LINENO/FUNCNAME
#   ftl::log::init              — initialize logging (called from ftl_setup)
#   ftl::log::set_level         — set debug level at runtime
#
# Globals:
#   ftl_log_alt_screen          — whether alt screen is active
#   ftl_log_debug_pane_id       — tmux pane id of the pdh pane
#   ftl_log_level               — current debug level (0=off, 1=debug, 2=trace)
#   ftl_log_file                — log file path (set by init)

# Initialize logging. Called from ftl_setup after ftl_state_session_dir is set.
ftl::log::init() {
        # Determine log level from environment
        if [[ "${FTL_TRACE:-0}" == "1" ]] ; then
                ftl_log_level=2
        elif [[ "${FTL_DEBUG:-0}" == "1" ]] ; then
                ftl_log_level=1
        else
                ftl_log_level=0
        fi

        # Set log file path
        if [[ -n "$ftl_cfg_debug_log_file" ]] ; then
                ftl_log_file="$ftl_cfg_debug_log_file"
        elif [[ -n "$ftl_state_session_dir" ]] ; then
                ftl_log_file="$ftl_state_session_dir/debug.log"
                # Ensure the session directory exists
                mkdir -p "$ftl_state_session_dir"
        else
                ftl_log_file=
        fi

        # Write startup banner
        if (( ftl_log_level > 0 )) && [[ -n "$ftl_log_file" ]] ; then
                {
                        echo "=== ftl debug log started $(date) ==="
                        echo "PID: $$"
                        echo "FTL_CFG: $FTL_CFG"
                        echo "FTL_STATE_DIR: ${FTL_STATE_DIR:-}"
                        echo "Log level: $ftl_log_level (1=debug, 2=trace)"
                        echo ""
                } >"$ftl_log_file"
        fi
}

# Set the debug level at runtime.
# Args:
#   $1: level (0=off, 1=debug, 2=trace)
ftl::log::set_level() {
        ftl_log_level="${1:-0}"
        ftl::log::info "log level set to $ftl_log_level"
}

# Run a command with stderr captured to $ftl_state_session_dir/log.
# If the log is non-empty after the command, show an error popup.
# Args:
#   $@: command and args
ftl::log::wrap() {
        exec 9>&2 2>"$ftl_state_session_dir/log"
        "$@"
        exec 2>&9
        if [[ -s $ftl_state_session_dir/log ]] ; then
                if (( ftl_pane_is_child )) ; then
                        ftl::log::show_error_full "$@"
                else
                        ftl::log::show_error_popup "$@"
                fi
        fi
}

# Show a full-screen red error.
# Args:
#   $@: command that failed (for context)
ftl::log::show_error_full() {
        echo -en "\e[2J\e[H\e[31m;"
        if [[ -s $ftl_state_session_dir/log ]] ; then
                cat "$ftl_state_session_dir/log" | tee -a "$ftl_state_session_dir/errors.log"
                rm "$ftl_state_session_dir/log"
        fi
}

# Show an error in a tmux popup.
# Args:
#   $@: command that failed (for context)
ftl::log::show_error_popup() {
        ftl::log::debug "$(cat "$ftl_state_session_dir/log")"
        read -sn1
        tmux popup -w 80% "$(ftl::log::show_error_full "$@")"
}

# Log a warning and show it in a yellow popup.
# Args:
#   $@: message
ftl::log::warn() {
        ftl::log::debug "WARN: $*"
        tmux popup -w 60% -h 20% "echo -ne '\e[2J\e[H\e[33m$*'"
}

# Log an error and show it in a red popup.
# Args:
#   $@: message
ftl::log::error() {
        ftl::log::debug "ERROR: $*"
        tmux popup -w 60% -h 20% "echo -ne '\e[2J\e[H\e[31m$*'"
}

# Log an info message to the log file (always, regardless of debug level).
# Args:
#   $1: message
ftl::log::info() {
        [[ -n "$ftl_log_file" ]] || return 0
        echo "[$(date +%H:%M:%S)] $$ INFO: $1" >>"$ftl_log_file"
}

# Log a debug message (only if ftl_log_level >= 1).
# Writes to the log file and optionally the pdh debug pane.
# Args:
#   $1: message (may contain \n)
ftl::log::debug() {
        (( ftl_log_level >= 1 )) || return 0

        # Write to log file
        if [[ -n "$ftl_log_file" ]] ; then
                echo "[$(date +%H:%M:%S)] $$ DEBUG: $1" >>"$ftl_log_file"
        fi

        # Send to pdh pane if open
        if [[ -f $ftl_state_parent_dir/pdh ]] ; then
                local pane_id
                read -r pane_id <"$ftl_state_parent_dir/pdh"
                if [[ -n "$pane_id" ]] ; then
                        ftl_log_debug_pane_id="$pane_id"
                        tmux send -t "$ftl_log_debug_pane_id" "$$ $ftl_pane_self_id: ${1//\\n/$'\n'}"
                fi
        fi
        true
}

# Log a trace message (only if ftl_log_level >= 2).
# Includes caller info (file:line:function).
# Args:
#   $1: message
ftl::log::trace() {
        (( ftl_log_level >= 2 )) || return 0
        local caller_info
        caller_info="$(caller 1 2>/dev/null || echo 'unknown')"
        [[ -n "$ftl_log_file" ]] && \
                echo "[$(date +%H:%M:%S)] $$ TRACE: [$caller_info] $1" >>"$ftl_log_file"
}

# Log every function call when trace is enabled.
# This is called via the DEBUG trap when FTL_TRACE=1.
# Usage: set -o functrace; trap 'ftl::log::trace_call' DEBUG
ftl::log::trace_call() {
        (( ftl_log_level >= 2 )) || return 0
        [[ -n "$ftl_log_file" ]] || return 0
        local func="${FUNCNAME[1]:-main}"
        local file="${BASH_SOURCE[2]:-?}"
        local line="${BASH_LINENO[0]:-?}"
        # Skip logging infrastructure itself
        [[ "$func" == "ftl::log::trace_call" ]] && return 0
        [[ "$func" == "ftl::log::trace" ]] && return 0
        [[ "$func" == "ftl::log::debug" ]] && return 0
        [[ "$func" == "ftl::log::info" ]] && return 0
        echo "[$(date +%H:%M:%S)] $$ CALL: $func() at $file:$line" >>"$ftl_log_file"
}

# Open or close the pdh debug pane.
ftl::log::show_debug_pane() {
        if [[ -f $ftl_state_parent_dir/pdh ]] ; then
                tmux killp -t "$(<$ftl_state_parent_dir/pdh)" &>/dev/null
                rm "$ftl_state_parent_dir/pdh"
        else
                ftl::prev::clear
                ftl::pane::split "$FTL_CFG/etc/bin/fpdh $ftl_state_parent_dir" 30% -v "$ftl_pane_self_id"
                ftl_pane_preview_id=
        fi
        ftl::list::change_dir
}

# Log the caller's BASH_SOURCE/LINENO/FUNCNAME to stderr.
# Used for debugging.
ftl::log::log_caller() {
        echo "[$( caller )] $*" >&2
        echo "BASH_SOURCE: ${BASH_SOURCE[*]}" >&2
        echo "BASH_LINENO: ${BASH_LINENO[*]}" >&2
        echo "FUNCNAME: ${FUNCNAME[*]}" >&2
}

# Initialize defaults (before ftl::log::init is called)
ftl_log_alt_screen=0
ftl_log_debug_pane_id=
ftl_log_level=0
ftl_log_file=

# vim: set filetype=bash :
