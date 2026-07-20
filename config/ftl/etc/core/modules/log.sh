# log.sh — logging and error reporting
#
# Replaces v1's try/try_error/try_errorp/warn/error/pdh/pdhn functions
# with a unified logging system. All functions route through ftl::log::write
# which appends to $ftl_state_session_dir/log and optionally shows a status
# message.
#
# Public functions:
#   ftl::log::wrap              — run a command with stderr captured
#   ftl::log::error             — log an error (red popup)
#   ftl::log::warn              — log a warning (yellow popup)
#   ftl::log::info              — log an info message (status line only)
#   ftl::log::debug             — log a debug message (pdh pane or file)
#   ftl::log::show_debug_pane   — open/close the pdh debug pane
#   ftl::log::log_caller        — log BASH_SOURCE/LINENO/FUNCNAME (was: log)
#
# Globals:
#   ftl_log_alt_screen          — whether alt screen is active (was: alt_screen)
#   ftl_log_debug_pane_id       — tmux pane id of the pdh pane (was: pdh)

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
	ftl::log::debug "$*"
	tmux popup -w 60% -h 20% "echo -ne '\e[2J\e[H\e[33m$*'"
}

# Log an error and show it in a red popup.
# Args:
#   $@: message
ftl::log::error() {
	ftl::log::debug "$*"
	tmux popup -w 60% -h 20% "echo -ne '\e[2J\e[H\e[31m$*'"
}

# Log a debug message to the pdh pane and/or a log file.
# Args:
#   $1: message (may contain \n)
ftl::log::debug() {
	if [[ -n "$ftl_cfg_debug_log_file" ]] ; then
		echo "$$ $ftl_pane_self_id: $1" >>"$ftl_cfg_debug_log_file"
	fi
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

# vim: set filetype=bash :
