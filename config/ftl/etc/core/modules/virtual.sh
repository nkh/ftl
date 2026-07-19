# virtual.sh — virtual entry injection
#
# Allows plugins to inject fake entries into the listing. Each plugin
# provides callbacks to get virtual dirs/files, color them, preview them,
# and handle their keys.
#
# Public functions:
#   ftl::plugin::virtual::set_callbacks  — register the plugin callbacks
#   ftl::plugin::virtual::enable         — turn on virtual entries
#   ftl::plugin::virtual::reset          — turn off and clear callbacks
#   ftl::plugin::virtual::inject_entries — populate vfiles/vdirs arrays
#   ftl::plugin::virtual::get_virtual_dirs  — emit virtual dirs (for pipeline)
#   ftl::plugin::virtual::handle_key     — let plugin handle a key
#   ftl::plugin::virtual::clear_filter   — passthrough (no-op filter)
#
# Globals:
#   ftl_plugin_vfiles       — assoc: virtual file name → 1 (was: vfiles)
#   ftl_plugin_vdirs        — assoc: virtual dir name → 1 (was: vdirs)
#   ftl_plugin_virtual_enabled — 1 if virtual entries are active

declare -Ag ftl_plugin_vfiles ftl_plugin_vdirs
ftl_plugin_virtual_enabled=0

# Default no-op callbacks (overridden by plugins).
ftl::plugin::virtual::get_dirs_callback()   { : ; }
ftl::plugin::virtual::get_files_callback()  { : ; }
ftl::plugin::virtual::clear_filter()        { cat ; }
ftl::plugin::virtual::preview_callback()    { : ; }
ftl::plugin::virtual::handle_key()          { false ; }

# Register plugin callbacks.
# Args:
#   $1: get_dirs_callback function name
#   $2: get_files_callback function name
#   $3: clear_filter function name
#   $4: preview_callback function name
#   $5: handle_key function name
ftl::plugin::virtual::set_callbacks() {
    ftl_etag_callback="ftl::plugin::virtual::get_dirs_callback(){ $1 ; } ; \
ftl::plugin::virtual::get_files_callback(){ $2 ; } ; \
ftl::plugin::virtual::clear_filter(){ $3 ; } ; \
ftl::plugin::virtual::preview_callback(){ $4 ; } ; \
ftl::plugin::virtual::handle_key(){ $5 \"\$@\"; }"
    eval "$ftl_etag_callback"
}

# Enable virtual entries.
# Args:
#   $1: enable flag (1=on)
ftl::plugin::virtual::enable() {
    ftl_etag_callback+="; ftl::plugin::virtual::enable $1"
    ftl_plugin_virtual_enabled=$1
    declare -Ag ftl_plugin_vfiles=() ftl_plugin_vdirs=()
}

# Reset (disable) virtual entries.
ftl::plugin::virtual::reset() {
    eval 'ftl::plugin::virtual::get_dirs_callback(){ : ; } ; \
ftl::plugin::virtual::get_files_callback(){ : ; } ; \
ftl::plugin::virtual::clear_filter(){ cat ; } ; \
ftl::plugin::virtual::preview_callback(){ : ; } ; \
ftl::plugin::virtual::handle_key(){ : ; }'
    ftl_etag_callback=
    ftl_plugin_virtual_enabled=0
}

# Populate the vfiles/vdirs arrays by calling the plugin callbacks.
# Args:
#   $@: passed through to the callbacks
ftl::plugin::virtual::inject_entries() {
    ftl_plugin_vfiles=()
    ftl_plugin_vdirs=()
    if (( ftl_plugin_virtual_enabled )) ; then
        local v
        while read -r v ; do ftl_plugin_vdirs[$v]=1 ; done \
            < <(ftl::plugin::virtual::get_dirs_callback "$@")
        while read -r v ; do ftl_plugin_vfiles[$v]=1 ; done \
            < <(ftl::plugin::virtual::get_files_callback "$@")
    fi
}

# Get virtual dirs (emit as find-format lines for the pipeline).
ftl::plugin::virtual::get_virtual_dirs() {
    (( ${#ftl_plugin_vdirs[@]} )) && printf "0\t0\t%s\n" "${!ftl_plugin_vdirs[@]}"
}

# vim: set filetype=bash :
