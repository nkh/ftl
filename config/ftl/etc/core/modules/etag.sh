# etag.sh — external tag (etag) dispatch
#
# Etags are optional metadata prepended to each entry in the listing
# (e.g. git status, modification date, line count). The active etag
# source is selected at runtime; its functions are called during the
# directory scan.
#
# Public functions:
#   ftl::etag::scan_directory      — call the active etag's dir scan (was: etag_dir)
#   ftl::etag::get_entry_tag       — get the tag for one entry (was: etag_tag)
#
# Globals:
#   ftl_state_etag_enabled         — master toggle (was: etag)
#   ftl_etag_source_name           — name of the active etag source (was: etag_s)
#   ftl_plugin_virtual_callback              — callback string for virtual entries (was: etag_cb)
#   ftl_etag_tag             — out: the tag string (was: external_tag)
#   ftl_etag_tag_len         — out: the tag display length (was: external_tag_length)

# Default no-op etag functions (overridden by sourcing an etag plugin).
ftl::etag::scan_directory() { : ; }
ftl::etag::get_entry_tag() {
	local -n r2=$2 r3=$3
	r2=
	r3=0
}

# vim: set filetype=bash :
