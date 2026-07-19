# util.sh — utility functions shared across all modules
#
# This module contains low-level helper functions that have no dependencies
# on other ftl modules. They can be sourced and used in isolation.
#
# Public functions:
#   ftl::util::parse_path          — decompose a path into n/p/f/b/e globals
#   ftl::util::clear_path_vars     — reset path globals to empty
#   ftl::util::resolve_full_path   — resolve a relative path to absolute
#   ftl::util::format_size_human   — human-readable size (K/M/G/T)
#   ftl::util::is_binary_file      — check if a file is binary
#   ftl::util::run_maximized       — run a command with ftl minimized
#   ftl::util::refresh_screen      — emit a refresh escape sequence
#   ftl::util::dedup_file          — deduplicate lines in a file
#   ftl::util::create_fifos        — create named pipes on given fds
#   ftl::util::stacktrace          — print a bash stack trace
#
# Path globals (set by ftl::util::parse_path):
#   ftl_state_current_path         — full path (was: n)
#   ftl_state_current_dir          — parent directory (was: p)
#   ftl_state_current_basename     — basename (was: f)
#   ftl_state_current_stem         — basename without extension (was: b)
#   ftl_state_current_extension    — extension without dot (was: e)

# Parse a full path into its components.
# Sets ftl_state_current_{path,dir,basename,stem,extension}.
# Args:
#   $1: full path to parse
ftl::util::parse_path() {
    ftl_state_current_path="$1"

    if [[ "$ftl_state_current_path" =~ / ]] ; then
        ftl_state_current_dir="${ftl_state_current_path%/*}"
    else
        ftl_state_current_dir=
    fi

    if [[ ${ftl_state_current_dir:0:1} != "/" ]] ; then
        ftl_state_current_dir="$PWD/$ftl_state_current_dir"
    fi

    ftl_state_current_basename="${ftl_state_current_path##*/}"
    ftl_state_current_stem="${ftl_state_current_basename%.*}"

    if [[ "$ftl_state_current_basename" =~ '.' ]] ; then
        ftl_state_current_extension="${ftl_state_current_basename##*.}"
    else
        ftl_state_current_extension=
    fi
}

# Reset all path globals to empty.
ftl::util::clear_path_vars() {
    ftl_state_current_path=
    ftl_state_current_dir=
    ftl_state_current_basename=
    ftl_state_current_stem=
    ftl_state_current_extension=
}

# Resolve a relative path to an absolute one.
# Handles leading ./ and trailing /.
# Args:
#   $1: path (possibly relative)
# Outputs: absolute path on stdout
ftl::util::resolve_full_path() {
    local pf="${1/\.\//$PWD\/}"
    pf="${pf%/}"
    echo "$pf"
}

# Format a byte count as a human-readable size.
# Args:
#   $1: size in bytes
# Outputs: formatted size like " 1.2K" on stdout
ftl::util::format_size_human() {
    local h_size=$1
    local u
    for u in ' ' K M G T ; do
        if (( h_size < 1024 )) ; then
            printf "%4s$u" "$h_size"
            return
        fi
        (( h_size /= 1024 ))
    done
}

# Check if a file is binary (using perl's -B test).
# Sets ftl_state_current_is_binary to 0 (text) or 1 (binary).
# Args:
#   $1: file path
ftl::util::is_binary_file() {
    perl -le 'exit -B $ARGV[0]' "$1"
    ftl_state_current_is_binary=$?
}

# Run a command with the ftl window minimized, then restore focus.
# Args:
#   $@: command and args
ftl::util::run_maximized() {
    local active_window
    active_window=$(xdotool getwindowfocus -f)
    xdotool windowminimize "$active_window"
    "$@" 2>/dev/null
    wmctrl -ia "$active_window"
    true
}

# Emit a refresh escape sequence.
# Args:
#   $1: optional escape sequence to append
ftl::util::refresh_screen() {
    echo -ne "\e[?25l$1"
}

# Deduplicate lines in a file, preserving order.
# Args:
#   $1: file path
ftl::util::dedup_file() {
    [[ -s "$1" ]] || return 0
    tac "$1" | awk '!seen[$0]++' | tac | sponge "$1"
    true
}

# Create named pipes and attach them to the given file descriptors.
# The fifo names are not retained (unlinked after open).
# Args:
#   $@: file descriptor numbers
ftl::util::create_fifos() {
    local fd
    local pipe
    for fd in "$@" ; do
        pipe=$(mktemp -u)
        mkfifo "$pipe"
        eval "exec $fd<>$pipe"
        rm "$pipe"
    done
}

# Print a bash stack trace to stderr.
ftl::util::stacktrace() {
    local i=1
    local line func file
    while read -r line func file < <(caller $i) ; do
        echo "[$i] $file:$line $func(): $(sed -n "${line}p" "$file")"
        ((i++))
    done
}

# vim: set filetype=bash :
