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
export FTL_STATE_DIR="$FTL_CFG/var"

REPORT="/tmp/ftl_binding_trace_report.txt"
: > "$REPORT"

source "$FTL_CFG/etc/core/ftl_setup" 2>/dev/null

# Stub ALL heavy I/O — every external command or function that touches
# the terminal, tmux, or the filesystem in a way that would block or crash.
ftl::list::render() { : ; }
ftl::list::change_dir() {
	# Simulate change_dir: update path vars from cursor
	if (( ftl_list_entry_count )) ; then
		local idx=${ftl_state_cursor_index:-0}
		(( idx >= ftl_list_entry_count )) && idx=$(( ftl_list_entry_count - 1 ))
		(( idx < 0 )) && idx=0
		ftl_state_current_path="${ftl_list_entries[$idx]:-/tmp}"
		ftl_state_current_basename="${ftl_state_current_path##*/}"
		if [[ "$ftl_state_current_basename" == *.* ]] ; then
			ftl_state_current_extension="${ftl_state_current_basename##*.}"
			ftl_state_current_stem="${ftl_state_current_basename%.*}"
		else
			ftl_state_current_extension=
			ftl_state_current_stem="$ftl_state_current_basename"
		fi
		ftl_state_current_dir="${ftl_state_current_path%/*}"
	fi
}
ftl::list::refresh_dir() { : ; }
ftl::list::move_cursor() {
	local nf
	(( nf = ftl_state_cursor_index + $1, \
	   nf = nf < 0 ? 0 : nf >= ftl_list_entry_count ? ftl_list_entry_count - 1 : nf ))
	(( nf != ftl_state_cursor_index )) && \
		ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]=$nf
	ftl_state_cursor_index=$nf
}
ftl::pane::stop_file_watcher() { : ; }
ftl::pane::start_file_watcher() { : ; }
ftl::pane::query_geometry() { : ; }
ftl::pane::snapshot_geometry() { : ; }
ftl::pane::check_resize() { : ; }
ftl::pane::split() { : ; }
ftl::pane::split_for_preview() { : ; }
ftl::pane::split_or_respawn() { : ; }
ftl::pane::run_in_bg_window() { : ; }
ftl::pane::run_in_user_session() { : ; }
ftl::pane::select() { : ; }
ftl::pane::set_border_colors() { : ; }
ftl::pane::ensure_session() { : ; }
ftl::pane::send_to_all_children() { : ; }
ftl::pane::read_child_list() { : ; }
ftl::pane::count_bg_windows() { echo 0 ; }
ftl::pane::window_exists() { false ; }
ftl::pane::pid_to_id() { echo "%0" ; }
ftl::prev::dispatch() { : ; }
ftl::prev::clear() { : ; }
ftl::prev::show_image() { : ; }
ftl::prev::show_in_vim() { : ; }
ftl::prev::sync_and_dispatch() { : ; }
ftl::state::serialize_info() { : ; }
ftl::state::save() { : ; }
ftl::state::save_selection() { : ; }
ftl::state::emit_selection_fd3() { : ; }
ftl::state::render_child_env() { echo "" ; }
ftl::state::cleanup() { : ; }
ftl::cmd::prompt() { REPLY="" ; ftl_kbd_current_key="" ; }
ftl::cmd::prompt_with_history() { echo "" ; }
ftl::util::enter_alt_screen() { : ; }
ftl::util::refresh_screen() { : ; }
ftl::util::run_maximized() { : ; }
ftl::log::show_error_full() { : ; }
ftl::log::show_error_popup() { : ; }
ftl::log::warn() { : ; }
ftl::log::error() { : ; }
ftl::log::show_debug_pane() { : ; }
ftl::kbd::show_bindings() { : ; }
ftl::tab::create() { : ; }
ftl::tab::advance_index() { : ; }
ftl::tab::retreat_index() { : ; }
ftl::tab::index_directory() { : ; }
ftl::tab::load_from_file() { : ; }
ftl::time::tick() { : ; }
ftl::sel::sync_from_other_pane() { false ; }
ftl::sel::format_header_summary() { echo "" ; }
ftl::sel::build_class_index() { : ; }
ftl::sel::prompt_for_class() { echo "1" ; }
ftl::sel::fzf_choose_class() { echo "1" ; }
ftl::sel::fzf_tag_or_untag() { : ; }
ftl::sel::goto_by_index() { : ; }
ftl::filt::load_external() { : ; }
ftl::filt::sort_entries() { cat ; }
ftl::filt::init() { : ; }
ftl::filt::apply_user_colors() { cat ; }
ftl::filter::apply_external() { cat ; }
tmux() { : ; }
stty() { : ; }
tput() { : ; }
lscolors() { cat ; }
column() { cat ; }
numfmt() { echo "0" ; }

# Set up realistic state
ftl_state_session_dir=$(mktemp -d)
ftl_state_parent_dir="$ftl_state_session_dir"
ftl_state_shared_dir="$ftl_state_session_dir/prev"
ftl_state_main_info_file_path="$ftl_state_session_dir/info"
ftl_state_info_file_path="$ftl_state_session_dir/info"
ftl_log_file="$ftl_state_session_dir/debug.log"
mkdir -p "$ftl_state_session_dir/prev" "$ftl_state_session_dir/lock_preview"

# Create a fake directory listing
TESTDIR=$(mktemp -d)
touch "$TESTDIR/file1.txt" "$TESTDIR/file2.py" "$TESTDIR/image.jpg"
mkdir -p "$TESTDIR/subdir"
ftl_list_entries=(
	"$TESTDIR/subdir"
	"$TESTDIR/file1.txt"
	"$TESTDIR/file2.py"
	"$TESTDIR/image.jpg"
)
ftl_list_entry_count=${#ftl_list_entries[@]}
ftl_list_entry_colors=(
	"\e[34msubdir\e[0m"
	"\e[0mfile1.txt\e[0m"
	"\e[0mfile2.py\e[0m"
	"\e[0mimage.jpg\e[0m"
)
ftl_state_cursor_index=0
ftl_state_current_path="${ftl_list_entries[0]}"
ftl_state_current_dir="$TESTDIR"
ftl_state_current_basename="subdir"
ftl_state_current_stem="subdir"
ftl_state_current_extension=
ftl_state_current_tab_index=0
ftl_state_current_mime_type=
ftl_state_current_is_binary=0
ftl_state_current_file_description=
ftl_state_previous_pwd=
ftl_state_custom_list=
ftl_state_quit_cancelled=0
ftl_state_pending_input=
ftl_state_winch_pending=0
ftl_state_search_string=
ftl_state_preview_callback=
ftl_state_montage_glyph=
ftl_state_external_viewer_mode=0
ftl_state_preview_pane_visible=1
ftl_state_alt_preview_mode=0
ftl_state_dir_preview_mode=0
ftl_state_show_size_mode=0
ftl_state_etag_enabled=0
ftl_state_images_hidden=0
ftl_state_show_stat=0
ftl_preview_is_vim=0
ftl_list_window_top=0
ftl_list_window_bottom=$((ftl_list_entry_count - 1))
ftl_list_window_height=24
ftl_list_window_center=12
ftl_list_display_line_no=0
ftl_list_total_size=0
ftl_list_index_padding=1
ftl_list_first_file_index=1
ftl_list_search_found_index=0
ftl_list_header_total_count=
ftl_list_header_total_size=
ftl_list_quick_display_active=0
ftl_list_flip_index=0
ftl_list_current_flip_char=" "
ftl_list_path_separator=/
ftl_list_resolved_sort_type=0
ftl_list_resolved_sort_reversed=
ftl_list_raw_entries=()
ftl_cfg_leader_key='BACKSLASH'
ftl_cfg_redo_key='.'
ftl_cfg_move_step_size=4
ftl_cfg_delete_command='echo'
ftl_cfg_editor='echo'
ftl_cfg_diff_tool='echo'
ftl_cfg_markdown_pager='cat'
ftl_cfg_hex_viewer='echo'
ftl_cfg_hex_editor='echo'
ftl_cfg_help_command='echo'
ftl_cfg_image_extensions_regex='jpg|jpeg|png|gif|bmp|webp'
ftl_cfg_media_extensions_regex='mp3|mp4|mkv|webm'
ftl_cfg_image_extensions=(jpg jpeg png gif bmp webp)
ftl_cfg_sort_options=('-k3 -V' '-n' '-k2 -V')
ftl_cfg_glyph_sort=(a s d)
ftl_cfg_default_sort_type=0
ftl_cfg_default_sort_reversed=
ftl_cfg_default_reverse_filter=
ftl_cfg_fzf_popup_opts=''
ftl_cfg_quick_display_threshold=0
ftl_cfg_show_date_in_header=0
ftl_cfg_bindings_display_width=120
ftl_cfg_bindings_in_popup=0
ftl_cfg_help_in_popup=0
ftl_cfg_shell_pane_height='40%'
ftl_cfg_shell_pane_width='60%'
ftl_cfg_auto_select_filename=
ftl_cfg_auto_sync_selection=1
ftl_cfg_key_timeout=1
ftl_cfg_time_event_interval=0
ftl_cfg_debug_log_file=
ftl_cfg_command_aliases=()
ftl_cfg_color_overrides=()
ftl_cfg_glyph_listing_mode=()
ftl_cfg_glyph_image_mode=()
ftl_cfg_row_separator_chars=(' ' ' ')
ftl_cfg_preview_zoom_levels=(85 70 50 30)
ftl_state_preview_zoom_index=1
ftl_cfg_image_zoomed=0
ftl_gen_dir="$FTL_CFG/etc/generators"
ftl_cache_thumb_dir="$FTL_STATE_DIR/thumbs"
ftl_state_global_history_file="$FTL_STATE_DIR/history"
ftl_state_dir_preview_mode=0
ftl_pane_self_id="%0"
ftl_pane_is_primary=1
ftl_pane_is_child=0
ftl_pane_height=24
ftl_pane_width=80
ftl_pane_preview_id=
ftl_pane_fixed_preview_id=
ftl_pane_shell_id=
ftl_pane_session_shell_active=0

# Declare arrays that commands access
declare -Ag ftl_mark_session_marks=()
declare -Ag ftl_state_cursor_memory=()
declare -Ag ftl_list_mime_cache=()
declare -Ag ftl_list_dir_size_cache=()
declare -Ag ftl_view_preview_ignore_exts=()
declare -Ag ftl_filter_listing_hide_exts=()
declare -Ag ftl_filter_listing_keep_exts=()
declare -Ag ftl_filter_listing_keep_exts_per_tab=()
declare -Ag ftl_view_vim_tail_commands=()
declare -Ag ftl_tab_view_mode=([0]=0)
declare -Ag ftl_tab_listing_mode=([0]=0)
declare -Ag ftl_tab_show_hidden=([0]=)
declare -Ag ftl_tab_sort_type=([0]=0)
declare -Ag ftl_tab_sort_reversed=([0]=)
declare -Ag ftl_tab_filter_dirs=([0]='.')
declare -Ag ftl_tab_filter_1=([0]='.')
declare -Ag ftl_tab_filter_2=([0]='.')
declare -Ag ftl_tab_filter_reverse=([0]=)
declare -Ag ftl_tab_filter_image_mode=([0]=)
declare -Ag ftl_tab_filter_image_negate=([0]=)
declare -Ag ftl_tab_preview_dirs_only=([0]=)
declare -Ag ftl_tab_listing_depth=([0]=1)
declare -ag ftl_tab_directories=("$TESTDIR")
ftl_tab_count=1

# Selection state
declare -Ag ftl_selection_tags=()
ftl_selection_current=("${ftl_list_entries[0]}")
ftl_selection_total_bytes=0
ftl_selection_revision=0
ftl_selection_other_revision=0
ftl_selection_class_cursor=0
declare -Ag ftl_selection_class_index=()

# Virtual entries
declare -Ag ftl_plugin_vfiles=()
declare -Ag ftl_plugin_vdirs=()
ftl_plugin_virtual_enabled=0

# Nav history
declare -ag ftl_plugin_missing_nav_history=()
ftl_plugin_missing_nav_index=0

# Missing functionalities state
ftl_plugin_missing_preview_zoom=2

cd "$TESTDIR"

# Now trace each binding
total=0; ok=0; crashed=0; missing=0

{
echo "=== ftl Binding Trace Report ==="
echo "Date: $(date)"
echo "FTL_CFG: $FTL_CFG"
echo "Test dir: $TESTDIR"
echo "Entries: ${ftl_list_entries[*]}"
echo ""
} >> "$REPORT"

for key in "${!ftl_kbd_trie[@]}" ; do
	fn="${ftl_kbd_trie[$key]}"
	[[ "$fn" =~ ^[0-9]+$ ]] && continue
	((total++))

	if [[ $(type -t "$fn" 2>/dev/null) != "function" ]] ; then
		echo "MISSING: $key -> $fn" >> "$REPORT"
		((missing++))
		continue
	fi

	# Reset key state
	ftl_kbd_current_key="$key"
	ftl_kbd_accumulated_keys="$key"
	ftl_kbd_keys_count=1
	ftl_kbd_count=""
	ftl_kbd_has_count=
	ftl_kbd_last_command=
	ftl_kbd_submode_handler=
	ftl_state_pending_input=

	# Call the function
	if error_output=$("$fn" 2>&1) ; then
		echo "OK: $key -> $fn" >> "$REPORT"
		((ok++))
	else
		# Extract first line of error
		local_err=$(echo "$error_output" | head -1)
		echo "CRASH: $key -> $fn (exit $?) $local_err" >> "$REPORT"
		((crashed++))
	fi
done

{
echo ""
echo "=== Summary ==="
echo "Total bindings traced: $total"
echo "OK: $ok"
echo "CRASHED: $crashed"
echo "MISSING: $missing"
} >> "$REPORT"

# Cleanup
rm -rf "$ftl_state_session_dir" "$TESTDIR" 2>/dev/null

cat "$REPORT"
