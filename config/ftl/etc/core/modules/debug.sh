# debug.sh — debug helpers
#
# Provides a stacktrace function and a numfmt wrapper that catches errors.
# This module is sourced early so its wrappers are available everywhere.
#
# Public functions:
#   ftl::debug::stacktrace   — print a bash stack trace (was: stacktrace)
#   ftl::debug::log_caller   — log BASH_SOURCE/LINENO/FUNCNAME (was: log)
#   ftl::debug::format_size  — numfmt wrapper with error catching (was: numfmt override)

# Print a bash stack trace to stderr.
ftl::debug::stacktrace() {
    local i=1
    local line func file
    while read -r line func file < <(caller $i) ; do
        echo "[$i] $file:$line $func(): $(sed -n "${line}p" "$file")"
        ((i++))
    done
}

# Log the caller's context to stderr.
# Args:
#   $@: message
ftl::debug::log_caller() {
    echo "[$( caller )] $*" >&2
    echo "BASH_SOURCE: ${BASH_SOURCE[*]}" >&2
    echo "BASH_LINENO: ${BASH_LINENO[*]}" >&2
    echo "FUNCNAME: ${FUNCNAME[*]}" >&2
}

# numfmt wrapper that catches errors and logs a stacktrace.
# v1 overrode numfmt globally; v2 uses a distinct name to avoid confusion.
# Args:
#   $@: passed through to /usr/bin/numfmt
ftl::debug::format_size() {
    if /usr/bin/numfmt "$@" ; then
        return 0
    else
        echo "$@" >>"$ftl_state_session_dir/numfmt_errors.log"
        echo -e "------------------\n\n" >>"$ftl_state_session_dir/numfmt_errors.log"
        ftl::debug::stacktrace >>"$ftl_state_session_dir/numfmt_errors.log"
        ftl::log::error "numfmt: error with args: $*"
    fi
}

# vim: set filetype=bash :
