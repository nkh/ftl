# inline_rename.sh — modal inline rename mode
#
# Provides a two-level sub-mode (outer: navigation + dispatch; inner:
# per-entry text editing) entered via LEADER r i. Supports single
# rename, sequential rename, regexp rename, image-label edit, and
# delete-from-within-mode.
#
# Public functions:
#   ftl::plugin::inline_rename::enter        — entry point (bound to LEADER r i)
#   ftl::plugin::inline_rename::exit         — clear sub-mode and state
#   ftl::plugin::inline_rename::dispatch     — sub-mode handler (set as ftl_kbd_submode_handler)
#
# Private functions:
#   _ftl::plugin::inline_rename::dispatch_outer      — outer-mode key dispatch
#   _ftl::plugin::inline_rename::dispatch_inner      — inner-mode key dispatch
#   _ftl::plugin::inline_rename::begin_edit          — enter inner mode for current entry
#   _ftl::plugin::inline_rename::begin_label         — enter inner mode for EXIF label
#   _ftl::plugin::inline_rename::commit              — apply the draft (mv or exiftool)
#   _ftl::plugin::inline_rename::commit_label        — apply EXIF label
#   _ftl::plugin::inline_rename::abort               — discard draft, return to outer
#   _ftl::plugin::inline_rename::sequential          — sequential-numbered bulk rename
#   _ftl::plugin::inline_rename::regexp              — sed-pattern bulk rename
#   _ftl::plugin::inline_rename::delete_one          — delete current entry
#   _ftl::plugin::inline_rename::snapshot_targets    — freeze selection/list for bulk op
#   _ftl::plugin::inline_rename::render_draft        — render the cursor row with the draft
#
# Globals:
#   ftl_inline_rename_active              — 0/1/2 (inactive/outer/inner)
#   ftl_inline_rename_original_path       — entry being edited (inner)
#   ftl_inline_rename_original_name       — basename at edit start
#   ftl_inline_rename_draft               — current draft string
#   ftl_inline_rename_draft_cursor        — insertion offset
#   ftl_inline_rename_is_label            — 1 if editing EXIF label
#   ftl_inline_rename_bulk_targets        — frozen snapshot for bulk ops
#   ftl_inline_rename_history             — array of "old\tnew" for tab-flow
#   ftl_state_inline_rename_error         — transient error message for render

# === Globals ===
ftl_inline_rename_active=0
ftl_inline_rename_original_path=
ftl_inline_rename_original_name=
ftl_inline_rename_draft=
ftl_inline_rename_draft_cursor=0
ftl_inline_rename_is_label=0
ftl_inline_rename_history=()
ftl_inline_rename_bulk_targets=()
ftl_state_inline_rename_error=

# === Public API ===

# Enter inline rename mode.
# Sets ftl_kbd_submode_handler so every subsequent keypress is routed here.
# Refuses to enter if a virtual list is active (renaming virtual entries is meaningless).
# Hands off cleanly from incremental_search if it was active.
ftl::plugin::inline_rename::enter() {
        # Refuse in virtual lists
        if (( ${#ftl_plugin_vfiles[@]} + ${#ftl_plugin_vdirs[@]} )) ; then
                echo "ftl: inline_rename: not available in virtual lists" >&2
                return
        fi

        # Hand off from incremental_search if active (restore cursor colour, clear search string)
        if [[ "${ftl_kbd_submode_handler:-}" == "ftl::plugin::incremental_search::incremental_find" ]] ; then
                ftl_cfg_cursor_color_current="$ftl_cfg_cursor_color_default"
                ftl_state_search_string=
        fi

        ftl_kbd_submode_handler=ftl::plugin::inline_rename::dispatch
        ftl_inline_rename_active=1
        ftl_inline_rename_original_path=
        ftl_inline_rename_original_name=
        ftl_inline_rename_draft=
        ftl_inline_rename_draft_cursor=0
        ftl_inline_rename_is_label=0
        ftl_inline_rename_history=()
        ftl_inline_rename_bulk_targets=()
        ftl_state_inline_rename_error=
        ftl::list::render
}

# Exit inline rename mode.
# Clears all state and unsets the sub-mode handler.
ftl::plugin::inline_rename::exit() {
        ftl_inline_rename_active=0
        ftl_inline_rename_original_path=
        ftl_inline_rename_original_name=
        ftl_inline_rename_draft=
        ftl_inline_rename_draft_cursor=0
        ftl_inline_rename_is_label=0
        ftl_inline_rename_bulk_targets=()
        ftl_state_inline_rename_error=
        ftl_kbd_submode_handler=
        ftl::list::render
}

# Sub-mode dispatcher. Called by ftl::kbd::dispatch on every keypress while active.
# Branches on ftl_inline_rename_active: 1 = outer, 2 = inner.
ftl::plugin::inline_rename::dispatch() {
        local key="$ftl_kbd_current_key"
        [[ "$key" == ERROR_* ]] && return

        if (( ftl_inline_rename_active == 1 )) ; then
                _ftl::plugin::inline_rename::dispatch_outer "$key"
        elif (( ftl_inline_rename_active == 2 )) ; then
                _ftl::plugin::inline_rename::dispatch_inner "$key"
        fi
}

# === Private: Outer Mode ===

# Dispatch a key in outer mode (navigation + bulk-op entry).
_ftl::plugin::inline_rename::dispatch_outer() {
        local key="$1"
        case "$key" in
                UP|k)         ftl::cmd::cursor_up ;;
                DOWN|j)       ftl::cmd::cursor_down ;;
                PGUP|K)       ftl::list::move_cursor "-$ftl_cfg_move_step_size" ; ftl::list::render ;;
                PGDN|J)       ftl::list::move_cursor "$ftl_cfg_move_step_size" ; ftl::list::render ;;
                HOME|g)       ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]=0 ; ftl::list::render ;;
                END|G)        ftl_state_cursor_memory[${ftl_state_current_tab_index}_$PWD]=$(( ftl_list_entry_count - 1 )) ; ftl::list::render ;;
                SPACE|t)      ftl::sel::flip "$ftl_state_current_path" ; ftl::list::render ;;
                TAB)          ftl::sel::flip "$ftl_state_current_path" ; ftl::cmd::cursor_down ;;
                DEL|x)        _ftl::plugin::inline_rename::delete_one 1 ;;
                d)            _ftl::plugin::inline_rename::delete_one "$(( 1 - ftl_cfg_inline_rename_no_confirm_delete ))" ;;
                ENTER|RETURN) _ftl::plugin::inline_rename::begin_edit "" ;;
                r)            _ftl::plugin::inline_rename::sequential ;;
                R)            _ftl::plugin::inline_rename::regexp ;;
                l)            _ftl::plugin::inline_rename::begin_label ;;
                ESCAPE|q)     ftl::plugin::inline_rename::exit ;;
                [a-zA-Z0-9_\-.]) _ftl::plugin::inline_rename::begin_edit "$key" ;;
                *)            : ;;  # ignore unknown keys
        esac
}

# === Private: Inner Mode ===

# Enter inner edit mode for the current entry.
# Args:
#   $1: initial draft content
#       - empty: pre-fill with the existing basename (Return-key flow)
#       - non-empty letter: start a new-name draft with that letter (letter-key flow)
_ftl::plugin::inline_rename::begin_edit() {
        (( ftl_list_entry_count )) || return 0
        ftl_inline_rename_original_path="$ftl_state_current_path"
        ftl_inline_rename_original_name="$ftl_state_current_basename"
        if [[ -z "$1" ]] ; then
                # Return-key flow: pre-fill with existing basename, cursor at end
                ftl_inline_rename_draft="$ftl_state_current_basename"
        else
                # Letter-key flow: new-name draft starting with that letter
                ftl_inline_rename_draft="$1"
        fi
        ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
        ftl_inline_rename_is_label=0
        ftl_inline_rename_active=2
        _ftl::plugin::inline_rename::render_draft
}

# Enter inner edit mode for the EXIF label of the current image.
# No-op if exiftool is missing or the current entry is not an image.
_ftl::plugin::inline_rename::begin_label() {
        command -v exiftool >/dev/null 2>&1 || {
                echo "ftl: inline_rename: exiftool not installed" >&2
                return
        }

        # Check extension against ftl_cfg_image_extensions
        local ext_lc="${ftl_state_current_extension,,}"
        local is_img=0
        local ie
        for ie in "${ftl_cfg_image_extensions[@]}" ; do
                [[ "$ext_lc" == "$ie" ]] && { is_img=1 ; break ; }
        done
        (( is_img )) || return 0

        ftl_inline_rename_original_path="$ftl_state_current_path"
        ftl_inline_rename_original_name="$ftl_state_current_basename"

        # Pre-fill with the existing label (IPTC first, EXIF fallback)
        local existing
        existing="$(exiftool -s3 -IPTC:ObjectName "$ftl_state_current_path" 2>/dev/null)"
        [[ -z "$existing" ]] && existing="$(exiftool -s3 -EXIF:ImageDescription "$ftl_state_current_path" 2>/dev/null)"
        ftl_inline_rename_draft="$existing"
        ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
        ftl_inline_rename_is_label=1
        ftl_inline_rename_active=2
        _ftl::plugin::inline_rename::render_draft
}

# Dispatch a key in inner mode (text editing).
_ftl::plugin::inline_rename::dispatch_inner() {
        local key="$1"
        case "$key" in
                BACKSPACE)
                        (( ${#ftl_inline_rename_draft} > 0 )) && {
                                ftl_inline_rename_draft="${ftl_inline_rename_draft:0:${#ftl_inline_rename_draft}-1}"
                                (( ftl_inline_rename_draft_cursor > 0 )) && (( ftl_inline_rename_draft_cursor-- ))
                        }
                        ;;
                CTL-W)
                        # delete previous word (whitespace-delimited)
                        ftl_inline_rename_draft="${ftl_inline_rename_draft% *}"
                        ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
                        ;;
                CTL-U)
                        ftl_inline_rename_draft=
                        ftl_inline_rename_draft_cursor=0
                        ;;
                CTL-A|HOME)
                        ftl_inline_rename_draft_cursor=0
                        ;;
                CTL-E|END)
                        ftl_inline_rename_draft_cursor=${#ftl_inline_rename_draft}
                        ;;
                ENTER|RETURN)
                        _ftl::plugin::inline_rename::commit
                        return
                        ;;
                ESCAPE)
                        _ftl::plugin::inline_rename::abort
                        return
                        ;;
                TAB)
                        _ftl::plugin::inline_rename::commit
                        (( ftl_state_cursor_index < ftl_list_entry_count - 1 )) && {
                                ftl::cmd::cursor_down
                                _ftl::plugin::inline_rename::begin_edit ""
                        }
                        return
                        ;;
                ERROR_*) return ;;
                *)
                        # Only accept printable ASCII (space through tilde).
                        # Using a variable for the regex avoids bash parser confusion with ~.
                        local _printable_re='^[ -~]$'
                        if [[ "$key" =~ $_printable_re ]] ; then
                                local left="${ftl_inline_rename_draft:0:ftl_inline_rename_draft_cursor}"
                                local right="${ftl_inline_rename_draft:ftl_inline_rename_draft_cursor}"
                                ftl_inline_rename_draft="${left}${key}${right}"
                                (( ftl_inline_rename_draft_cursor++ ))
                        fi
                        ;;
        esac
        _ftl::plugin::inline_rename::render_draft
}

# Commit the current draft.
# For filenames: mv $original $dir/$draft (refuses to overwrite).
# For labels: delegates to commit_label.
_ftl::plugin::inline_rename::commit() {
        [[ -n "$ftl_inline_rename_draft" ]] || { _ftl::plugin::inline_rename::abort ; return ; }

        if (( ftl_inline_rename_is_label )) ; then
                _ftl::plugin::inline_rename::commit_label
                return
        fi

        local dir="${ftl_inline_rename_original_path%/*}"
        local target="$dir/$ftl_inline_rename_draft"

        # No-op if name unchanged
        if [[ "$target" == "$ftl_inline_rename_original_path" ]] ; then
                _ftl::plugin::inline_rename::abort
                return
        fi

        # Refuse to overwrite an existing file
        if [[ -e "$target" ]] ; then
                ftl_state_inline_rename_error="target exists: $ftl_inline_rename_draft"
                _ftl::plugin::inline_rename::render_draft
                ftl_state_inline_rename_error=
                return
        fi

        mv -- "$ftl_inline_rename_original_path" "$target"
        ftl_inline_rename_history+=( "${ftl_inline_rename_original_path}"$'\t'"$target" )
        ftl_inline_rename_active=1
        ftl_list_mime_cache=()
        ftl::list::change_dir '' "$ftl_inline_rename_draft"
}

# Commit an EXIF label (writes IPTC:ObjectName + EXIF:ImageDescription).
_ftl::plugin::inline_rename::commit_label() {
        local path="$ftl_inline_rename_original_path"
        exiftool -overwrite_original \
                -IPTC:ObjectName="$ftl_inline_rename_draft" \
                -EXIF:ImageDescription="$ftl_inline_rename_draft" \
                "$path" >/dev/null 2>&1
        ftl_inline_rename_history+=( "$path(exif)$ftl_inline_rename_draft" )
        ftl_inline_rename_active=1
        ftl::list::render
}

# Abort the current edit. Discard the draft and return to outer mode.
_ftl::plugin::inline_rename::abort() {
        ftl_inline_rename_original_path=
        ftl_inline_rename_original_name=
        ftl_inline_rename_draft=
        ftl_inline_rename_draft_cursor=0
        ftl_inline_rename_is_label=0
        ftl_inline_rename_active=1
        ftl::list::render
}

# === Private: Bulk Ops ===

# Snapshot the targets for a bulk operation.
# Uses the current selection if non-empty, otherwise the full listing.
_ftl::plugin::inline_rename::snapshot_targets() {
        ftl_inline_rename_bulk_targets=()
        if (( ${#ftl_selection_tags[@]} )) ; then
                ftl_inline_rename_bulk_targets=( "${!ftl_selection_tags[@]}" )
        else
                ftl_inline_rename_bulk_targets=( "${ftl_list_entries[@]}" )
        fi
}

# Sequential-numbered bulk rename.
# Prompts for a base name; renames entry[i] -> base_001, base_002, ...
# Preserves extensions; skips targets that already exist.
_ftl::plugin::inline_rename::sequential() {
        ftl::cmd::prompt 'sequential base name: '
        local base="$REPLY"
        [[ -n "$base" ]] || { ftl::list::render ; return ; }

        _ftl::plugin::inline_rename::snapshot_targets
        local i=1 target new_path seq
        for target in "${ftl_inline_rename_bulk_targets[@]}" ; do
                local dir="${target%/*}" name="${target##*/}" ext=
                [[ "$name" == *.* ]] && ext=".${name##*.}"
                printf -v seq "$ftl_cfg_inline_rename_sequence_format" "$i"
                new_path="$dir/$base$seq$ext"
                if [[ -e "$new_path" && "$new_path" != "$target" ]] ; then
                        echo "ftl: inline_rename: skip (target exists): $new_path" >&2
                        ((i++))
                        continue
                fi
                [[ "$new_path" != "$target" ]] && mv -- "$target" "$new_path"
                ftl_inline_rename_history+=( "$target"$'\t'"$new_path" )
                ((i++))
        done
        ftl_list_mime_cache=()
        ftl::list::change_dir
}

# Regexp bulk rename.
# Prompts for a sed -E expression (default s/OLD/NEW/); applies to each basename.
# Skips entries where the pattern produces no change or an existing target.
_ftl::plugin::inline_rename::regexp() {
        ftl::cmd::prompt 'sed -E pattern: ' -i "$ftl_cfg_inline_rename_regexp_default"
        local pat="$REPLY"
        [[ -n "$pat" && "$pat" != "$ftl_cfg_inline_rename_regexp_default" ]] \
                || { ftl::list::render ; return ; }

        _ftl::plugin::inline_rename::snapshot_targets
        local target new_name new_path
        for target in "${ftl_inline_rename_bulk_targets[@]}" ; do
                local dir="${target%/*}" name="${target##*/}"
                new_name="$(printf '%s' "$name" | sed -E "$pat")"
                [[ "$new_name" == "$name" || -z "$new_name" ]] && continue
                new_path="$dir/$new_name"
                if [[ -e "$new_path" ]] ; then
                        echo "ftl: inline_rename: skip (target exists): $new_path" >&2
                        continue
                fi
                mv -- "$target" "$new_path"
                ftl_inline_rename_history+=( "$target"$'\t'"$new_path" )
        done
        ftl_list_mime_cache=()
        ftl::list::change_dir
}

# === Private: Delete ===

# Delete the current entry.
# Args:
#   $1: 1 to prompt for confirmation, 0 to skip the prompt
_ftl::plugin::inline_rename::delete_one() {
        local confirm="$1"
        local target="$ftl_state_current_path"
        [[ -e "$target" ]] || return 0

        if (( confirm )) ; then
                ftl::cmd::prompt "delete $ftl_state_current_basename? [y|N]" -sn1
                [[ "$REPLY" != y ]] && { ftl::list::render ; return ; }
        fi

        $ftl_cfg_delete_command -- "$target"
        ftl_list_mime_cache=()
        ftl::list::change_dir
}

# === Private: Rendering ===

# Render the cursor row with the current draft, replacing the original entry.
# Emits a single terminal line at the cursor's row using tput cup positioning.
# The character at the insertion cursor is shown in inverse video.
_ftl::plugin::inline_rename::render_draft() {
        # Compute the terminal row of the cursor entry (row 1 = header, row 2 = first entry)
        local row=$(( ftl_state_cursor_index - ftl_list_window_top + 2 ))
        local prefix=" "
        local draft_render="${ftl_inline_rename_draft}"

        local left="${draft_render:0:ftl_inline_rename_draft_cursor}"
        local char_at="${draft_render:ftl_inline_rename_draft_cursor:1}"
        local right="${draft_render:ftl_inline_rename_draft_cursor+1}"
        [[ -z "$char_at" ]] && char_at=" "
        local rendered="${left}\e[7m${char_at}\e[0m${right}"

        # If there's an error message (target exists, etc.), append it in red
        [[ -n "${ftl_state_inline_rename_error:-}" ]] \
                && rendered+="  \e[31m[${ftl_state_inline_rename_error}]\e[0m"

        # Position cursor at the entry's row and emit
        echo -ne "\e[${row};0H\e[K\e[33m[RENAME] \e[0m${prefix}${rendered}"
}

# vim: set filetype=bash :
