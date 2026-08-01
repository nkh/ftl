# pane.sh — tmux pane management
#
# Manages tmux panes: the main listing pane, the preview pane, the shell
# pane, and child ftl panes. Each pane is a separate tmux pane (and for
# child ftl panes, a separate ftl process).
#
# Public functions:
#   ftl::pane::pid_to_id           — convert a PID to a tmux pane id
#   ftl::pane::query_geometry      — query current pane geometry
#   ftl::pane::snapshot_geometry   — save geometry for winch detection
#   ftl::pane::check_resize        — check if pane was resized
#   ftl::pane::split               — split the pane and run a command
#   ftl::pane::split_or_respawn    — respawn existing pane or split (was: ctsplit)
#   ftl::pane::split_for_preview   — split for preview (fzf-aware) (was: psplit)
#   ftl::pane::select              — select a pane (was: tselectp)
#   ftl::pane::set_border_colors   — set tmux border colors (was: tbcolor)
#   ftl::pane::window_exists       — check if a tmux window exists (was: texists)
#   ftl::pane::count_bg_windows    — count background tmux windows (was: tsc)
#   ftl::pane::ensure_session      — ensure a tmux session exists (was: tsnew)
#   ftl::pane::run_in_bg_window    — run a command in a bg tmux window (was: tscommand)
#   ftl::pane::run_in_user_session — run in a user-named session (was: tsucommand)
#   ftl::pane::read_child_list     — read the child-pane list (was: pane_read)
#   ftl::pane::send_to_all_children — send a key to all children (was: pane_send)
#   ftl::pane::start_file_watcher  — start inotify watcher (was: inotify_s)
#   ftl::pane::stop_file_watcher   — stop inotify watcher (was: inotify_k)
#
# Globals:
#   ftl_pane_self_id               — this pane's tmux id (was: my_pane)
#   ftl_pane_is_primary            — 1 if this is the main pane (was: main)
#   ftl_pane_primary_id            — the main pane's id (was: main_pane)
#   ftl_pane_child_ids             — indexed array of child pane ids (was: panes)
#   ftl_pane_preview_id            — preview pane id (was: pane_id)
#   ftl_pane_fixed_preview_id      — fixed preview pane id (was: pane2_id)
#   ftl_pane_height                — current pane height (was: LINES)
#   ftl_pane_width                 — current pane width (was: COLS)
#   ftl_pane_prev_width            — previous width (for winch) (was: WCOLS)
#   ftl_pane_prev_height           — previous height (was: WLINES)
#   ftl_pane_top                   — pane top position (was: TOP)
#   ftl_pane_window_width          — window width (was: WIDTH)
#   ftl_pane_left                  — pane left position (was: LEFT)
#   ftl_pane_preview_width         — preview pane width (was: COLS_P)
#   ftl_pane_resize_target         — computed resize target (was: x)
#   ftl_pane_inotify_pid           — inotify watcher PID (was: ino1)
#   ftl_pane_inotify_all_pids      — all inotify PIDs (was: ino_processes)
#   ftl_pane_shell_id              — shell pane id (was: shell_id)
#   ftl_pane_session_shell_active  — 1 if session shell exists (was: session_shell)
#   ftl_pane_keep_shell_on_quit    — 1 to keep shell on quit (was: keep_shell)

# Convert a PID to a tmux pane id.
# Args:
#   $1: PID
# Outputs: tmux pane id on stdout
ftl::pane::pid_to_id() {
	local pi pp
	while read -r -s pi pp ; do
		if [[ $1 == "$pp" ]] || [[ $(ps -o pid --no-headers --ppid "$pp" | rg $$) ]] ; then
			echo "$pi"
			break
		fi
	done < <(tmux lsp -F '#{pane_id} #{pane_pid}')
}

# Query the current pane's geometry from tmux.
# Sets ftl_pane_{top,window_width,height,width,left}.
ftl::pane::query_geometry() {
	read -r ftl_pane_top ftl_pane_window_width ftl_pane_height ftl_pane_width ftl_pane_left \
		< <(tmux display -p -t "$ftl_pane_self_id" \
			'#{pane_top} #{window_width} #{pane_height} #{pane_width} #{pane_left}')
}

# Snapshot current geometry for later winch detection.
ftl::pane::snapshot_geometry() {
	ftl::pane::query_geometry
	ftl_pane_prev_width=$ftl_pane_width
	ftl_pane_prev_height=$ftl_pane_height
}

# Check if the pane was resized; if so, queue a refresh.
ftl::pane::check_resize() {
	ftl::pane::query_geometry
	if { (( ! ftl_preview_is_image_daemon )) \
		  && [[ "$ftl_pane_prev_width" != "$ftl_pane_width" ]] ; } \
	   || [[ "$ftl_pane_prev_height" != "$ftl_pane_height" ]] ; then
		if (( ftl_state_winch_pending )) ; then
			ftl_state_pending_input="${ftl_kbd_command_to_key[ftl::cmd::refresh_pane]:-}$ftl_state_pending_input"
		fi
	fi
}

# Split the pane and run a command.
# Args:
#   $1: command string
#   $2: optional size (defaults to zoom level %)
#   $3: optional split direction (-h or -v)
#   $4: optional select direction (-L/-R/-U/-D)
#   $5: optional extra tmux args
ftl::pane::split() {
	local cmd="$1"
	local size="${2:-${ftl_cfg_preview_zoom_levels[$ftl_state_preview_zoom_index]}%}"
	local direction="${3:--h}"
	local select_dir="${4:-}"
	local extra="${5:-}"

	tmux sp $(ftl::state::render_child_env) $extra \
		-t "$ftl_pane_self_id" \
		$direction -l "$size" \
		-c "$PWD" "$cmd"

	sleep 0.04
	ftl_pane_preview_id=$(tmux display -p '#{pane_id}')
	_ftl::pane::split_with_fixed_preview
	ftl::pane::select "$select_dir"
}

# If a fixed preview file is set, open it in a second split.
_ftl::pane::split_with_fixed_preview() {
	[[ -z "$ftl_pane_preview_id" ]] && return 0
	[[ -z "$ftl_state_fixed_preview_filename" ]] && return 0
	tmux sp -b -l 9 -t "$ftl_pane_preview_id" \
		"$ftl_cfg_editor '$ftl_state_fixed_preview_filename' ; read -sn 1"
	sleep 0.04
	ftl_pane_fixed_preview_id=$(tmux display -p '#{pane_id}')
}

# Respawn an existing preview pane with a new command, or split if none.
# Args:
#   $1: command string
ftl::pane::split_or_respawn() {
	ftl_preview_is_dir_ftl=
	ftl_preview_is_vim=
	ftl_preview_is_image_daemon=

	if [[ -n "$ftl_pane_preview_id" ]] ; then
		tmux respawnp -k -t "$ftl_pane_preview_id" "$1" &>/dev/null
	else
		ftl::pane::split "$1"
	fi
	sleep 0.2
}

# Split for preview, with fzf-awareness.
# Args:
#   $@: command and args
ftl::pane::split_for_preview() {
	if (( ftl_view_fzf_as_viewer )) && [[ -n "$ftl_pane_preview_id" ]] ; then
		tmux respawn-pane -k -t "$ftl_pane_preview_id" "$@"
	else
		ftl::pane::split_or_respawn "$@"
	fi
	true
}

# Select a pane.
# Args:
#   $1: pane id (starts with %) or direction (-L/-R/-U/-D)
ftl::pane::select() {
	if [[ "$1" =~ ^% ]] ; then
		tmux selectp -t "$1"
	else
		tmux selectp -t "$ftl_pane_preview_id" "${1:--L}"
	fi
}

# Set tmux pane border colors.
# Args:
#   $1: border color number
#   $2: active border color number
ftl::pane::set_border_colors() {
	tmux set pane-border-style "fg=color$1"
	tmux set pane-active-border-style "fg=color$2"
	sleep 0.01
}

# Check if a tmux window with the given name exists.
# Args:
#   $1: window name
# Returns: 0 if exists, 1 otherwise
ftl::pane::window_exists() {
	tmux list-windows -F '#{window_name}' | grep -Fxq -- "$1"
}

# Count background tmux windows in this session.
# Args:
#   $1: optional expected count (mismatch triggers error)
# Outputs: count on stdout
ftl::pane::count_bg_windows() {
	local w
	w=$(tmux lsw -t "ftl$$" 2>&- | wc -l)
	((w--))
	if (( w > 0 )) ; then
		if [[ "${1:-0}" != "$w" ]] ; then
			ftl::log::error "Error in background command"
		fi
		echo "$w"
	fi
}

# Ensure a tmux session exists (create if not).
# Args:
#   $1: optional session name suffix (defaults to $$)
ftl::pane::ensure_session() {
	local suffix="${1:-$$}"
	if ! tmux has-session -t "ftl$suffix" &>/dev/null ; then
		tmux new -A -d -s "ftl$suffix"
		sleep 0.2
	fi
}

# Run a command in a background tmux window.
# Args:
#   $1: command string (for display)
#   $@: remaining args passed to tmux neww
ftl::pane::run_in_bg_window() {
	ftl::pane::ensure_session
	tmux neww -t "ftl$$" -d ${@:2} \
		"echo -e \"\e[33m$(date)\nftl> $1\e[m\" ; \
		 { $1 ; } || { echo -e \"\e[7;31mftl: failed\e[m\\n\" ; exec bash ; }"
}

# Run a command in a user-named session.
# Args:
#   $1: session name suffix
#   $2: command string
ftl::pane::run_in_user_session() {
	ftl::pane::ensure_session "$1"
	tmux neww -t "ftl$1" -d \
		"echo -e \"\e[33m$(date)\nftl> $2\e[m\" ; \
		 { $2 ; } || { echo -e \"\e[7;31mftl: failed\e[m\\n\" ; exec bash ; }"
}

# Read the child-pane list from $ftl_state_parent_dir/panes.
# Filters out panes that no longer exist in tmux.
ftl::pane::read_child_list() {
	local main_pane
	{ IFS= read -r main_pane; } <"$ftl_state_parent_dir/pane"
	ftl_pane_primary_id="$main_pane"

	if [[ -s "$ftl_state_parent_dir/panes" ]] ; then
		mapfile -t ftl_pane_child_ids < <(
			grep -w -f <(tmux lsp -F "#{pane_id}") "$ftl_state_parent_dir/panes"
		)
	fi
	printf "%s\n" "${ftl_pane_child_ids[@]}" >"$ftl_state_parent_dir/panes"
}

# Send a key to all child panes.
# Args:
#   $1: key to send
ftl::pane::send_to_all_children() {
	local p
	ftl::pane::read_child_list || return 1
	for p in "${ftl_pane_child_ids[@]}" ; do
		tmux send -t "$p" "$1" &>/dev/null
	done
}

# Start the inotify file watcher for the current directory.
ftl::pane::start_file_watcher() {
	ftl::pane::stop_file_watcher
	(_ftl::pane::file_watcher_loop) &
	:  # avoid job control noise
	ftl_pane_inotify_pid=$!
	ftl_pane_inotify_all_pids=($ftl_pane_inotify_pid $(pchild $ftl_pane_inotify_pid 0))
}

# The inotify watcher loop (runs in a subshell).
_ftl::pane::file_watcher_loop() {
	_ftl::pane::run_inotifywait | {
		local a b f
		read -r a b f
		if [[ -n "$f" ]] ; then
			tmux send -t "$ftl_pane_self_id" "${ftl_kbd_command_to_key[ftl::cmd::refresh_pane]:-}" 2>&-
		fi
	}
}

# Run inotifywait on the current directory.
_ftl::pane::run_inotifywait() {
	inotifywait \
		--exclude 'index.lock|(.*\.sw.?)' \
		-e create -e delete -e move -e modify \
		"$PWD/" 2>&-
}

# Stop the inotify file watcher.
ftl::pane::stop_file_watcher() {
	[[ -z "$ftl_pane_inotify_pid" ]] && return 0
	local p
	for p in "${ftl_pane_inotify_all_pids[@]}" ; do
		disown "$p" 2>&-
		kill "$p" 2>&-
	done
	ftl_pane_inotify_pid=
}

# vim: set filetype=bash :
