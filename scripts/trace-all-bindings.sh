#!/usr/bin/env bash
# scripts/trace-all-bindings.sh — feed each binding key to ftl::kbd::dispatch
# and log which functions are called, which crash, and which are missing.
#
# Usage: FTL_CFG=path/to/config bash scripts/trace-all-bindings.sh
#
# Output: /tmp/ftl_binding_trace_report.txt

set -u

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

REPORT="/tmp/ftl_binding_trace_report.txt"
: > "$REPORT"

{
	echo "=== ftl Binding Trace Report ==="
	echo "Date: $(date)"
	echo "FTL_CFG: $FTL_CFG"
	echo ""
} >> "$REPORT"

# Source all modules
source "$FTL_CFG/etc/core/ftl_setup" 2>/dev/null

# Stub heavy I/O
ftl::list::render() { : ; }
ftl::list::change_dir() { : ; }
ftl::pane::stop_file_watcher() { : ; }
ftl::pane::start_file_watcher() { : ; }
ftl::pane::query_geometry() { : ; }
ftl::pane::snapshot_geometry() { : ; }
ftl::pane::split() { : ; }
ftl::pane::split_for_preview() { : ; }
ftl::pane::split_or_respawn() { : ; }
ftl::pane::run_in_bg_window() { : ; }
ftl::pane::select() { : ; }
ftl::prev::dispatch() { : ; }
ftl::prev::clear() { : ; }
ftl::prev::show_image() { : ; }
ftl::prev::show_in_vim() { : ; }
ftl::state::serialize_info() { : ; }
ftl::state::save() { : ; }
ftl::cmd::prompt() { REPLY="" ; ftl_kbd_current_key="" ; }
tmux() { : ; }
stty() { : ; }
tput() { : ; }

# Initialize state
ftl_state_session_dir=$(mktemp -d)
ftl_state_parent_dir="$ftl_state_session_dir"
ftl_state_shared_dir="$ftl_state_session_dir/prev"
ftl_state_main_info_file_path="$ftl_state_session_dir/info"
mkdir -p "$ftl_state_session_dir/prev"
ftl_state_current_tab_index=0
ftl_state_cursor_index=0
ftl_state_current_path="/tmp"
ftl_state_current_dir="/tmp"
ftl_state_current_basename="test"
ftl_state_current_extension=""
ftl_list_entries=("/tmp/test")
ftl_list_entry_count=1
ftl_list_window_top=0
ftl_list_window_bottom=0
ftl_list_window_height=1

# Track results
total=0
ok=0
crashed=0
missing=0

echo "=== Tracing ${#ftl_kbd_trie[@]} bindings ===" >> "$REPORT"
echo "" >> "$REPORT"

for key in "${!ftl_kbd_trie[@]}" ; do
	fn="${ftl_kbd_trie[$key]}"
	[[ "$fn" =~ ^[0-9]+$ ]] && continue
	((total++))

	# Check if function exists
	if [[ $(type -t "$fn" 2>/dev/null) != "function" ]] ; then
		echo "MISSING: $key -> $fn (function not defined)" >> "$REPORT"
		((missing++))
		continue
	fi

	# Set up key state
	ftl_kbd_current_key="$key"
	ftl_kbd_accumulated_keys="$key"
	ftl_kbd_keys_count=1
	ftl_kbd_count=""
	ftl_kbd_has_count=
	ftl_kbd_last_command=
	ftl_kbd_submode_handler=
	declare -Ag ftl_plugin_vfiles=() ftl_plugin_vdirs=()

	# Try to call the function directly
	if error_output=$("$fn" 2>&1) ; then
		echo "OK: $key -> $fn" >> "$REPORT"
		((ok++))
	else
		echo "CRASH: $key -> $fn (exit $?, stderr: $(echo "$error_output" | head -1))" >> "$REPORT"
		((crashed++))
	fi
done

echo "" >> "$REPORT"
echo "=== Summary ===" >> "$REPORT"
echo "Total bindings traced: $total" >> "$REPORT"
echo "OK: $ok" >> "$REPORT"
echo "CRASHED: $crashed" >> "$REPORT"
echo "MISSING: $missing" >> "$REPORT"

# Cleanup
rm -rf "$ftl_state_session_dir" 2>/dev/null

cat "$REPORT"
