# keyboard.sh — keyboard input engine
#
# Handles key reading, normalization, trie-based dispatch, and binding
# management. The trie supports multi-key sequences, count prefixes, a
# leader key, and a redo key.
#
# Public functions:
#   ftl::kbd::bind                — register a key binding
#   ftl::kbd::unbind              — remove a key binding
#   ftl::kbd::get_key             — read and normalize a single key
#   ftl::kbd::normalize_key       — normalize a raw escape sequence
#   ftl::kbd::dispatch            — dispatch the current key to a command
#   ftl::kbd::drain_input         — drain pending stdin
#   ftl::kbd::show_bindings       — show the bindings table (was: k_bindings)
#   ftl::kbd::reset_redo_exclusions — clear the redo-exclusion set
#   ftl::kbd::exclude_from_redo   — exclude a command from redo
#
# Globals:
#   ftl_kbd_altgr_map             — AltGr key mapping (was: A)
#   ftl_kbd_altgr_inverse         — inverse AltGr map (was: LA)
#   ftl_kbd_shift_altgr_map       — Shift+AltGr map (was: SA)
#   ftl_kbd_shift_altgr_inverse   — inverse Shift+AltGr (was: LSA)
#   ftl_kbd_command_to_key        — command→key reverse map (was: C)
#   ftl_kbd_bindings_display      — display data for `c` command (was: bindings)
#   ftl_kbd_trie                  — key→command trie (was: kbd_trie)
#   ftl_kbd_submode_handler       — sub-mode dispatch function (was: key_map)
#   ftl_kbd_redo_excluded         — commands excluded from redo (was: exclude_from_redo)
#   ftl_kbd_current_key           — current normalized key (was: REPLY)
#   ftl_kbd_raw_key               — raw pre-normalization key (was: OREPLY)
#   ftl_kbd_accumulated_keys      — accumulated key sequence (was: keys_command)
#   ftl_kbd_keys_count            — count of accumulated keys (was: keys_in)
#   ftl_kbd_has_count             — whether a count was entered (was: HAS_COUNT)
#   ftl_kbd_count                 — count prefix digits (was: COUNT)
#   ftl_kbd_last_command          — last non-excluded command (was: keys_latest_command)
#   ftl_kbd_warn_on_override      — warn on binding override (was: ftl_bind_check)

# AltGr and Shift+AltGr mapping tables.
# These map single characters to their AltGr/Shift+AltGr equivalents and back,
# for displaying bindings with alt-gr annotations.
declare -Ag ftl_kbd_altgr_map=(
	[a]=ª [b]=” [c]=© [d]=ð [e]=€ [f]=đ [g]=ŋ [h]=ħ [i]=→ [k]=ĸ [l]=ł [m]=µ
	[o]=œ [p]=þ [q]='@' [r]=® [s]=ß [t]=þ [u]=↓ [v]=“ [x]=» [y]=← [z]=«
	["'"]="´" [.]=·
)
declare -Ag ftl_kbd_altgr_inverse=(
	[ª]=a [”]=b [©]=c [ð]=d [€]=e [đ]=f [ŋ]=g [ħ]=h [→]=i [ĸ]=k [ł]=l [µ]=m
	[œ]=o [þ]=p ['@']=q [®]=r [ß]=s [þ]=t [↓]=u [“]=v [»]=x [←]=y [«]=z
	["´"]="'" [·]='.'
)
declare -Ag ftl_kbd_shift_altgr_map=(
	[a]=º [b]=’ [c]=© [d]=Ð [e]=¢ [f]=ª [g]=Ŋ [h]=Ħ [i]=ı [k]='&' [l]=Ł [m]=º
	[o]=Œ [p]=Þ [q]=Ω [r]=® [s]=§ [t]=Þ [u]=↑ [v]=‘ [x]='>' [y]=¥ [z]='<'
	["'"]=× [.]=˙ [0]=° [/]=÷
)
declare -Ag ftl_kbd_shift_altgr_inverse=(
	[º]=a [’]=b [©]=c [Ð]=d [¢]=e [ª]=f [Ŋ]=g [Ħ]=h [ı]=i ['&']=k [Ł]=l
	[º]=m [Œ]=o [Þ]=p [Ω]=q [®]=r [§]=s [Þ]=t [↑]=u [‘]=v ['>']=x [¥]=y
	['<']=z [×]="'" [˙]=. [°]=0 [÷]=/
)

# Core dispatch data structures.
declare -Ag ftl_kbd_command_to_key        # command → key sequence
declare -Ag ftl_kbd_bindings_display      # display key → metadata
declare -Ag ftl_kbd_trie                  # key sequence → command
declare -Ag ftl_kbd_redo_excluded         # command → 1 (excluded from redo)

# Input state (mutated during dispatch).
ftl_kbd_submode_handler=
ftl_kbd_current_key=
ftl_kbd_raw_key=
ftl_kbd_accumulated_keys=
ftl_kbd_keys_count=0
ftl_kbd_has_count=
ftl_kbd_count=
ftl_kbd_last_command=
ftl_kbd_warn_on_override=0

# Register a key binding.
# Args:
#   $1: map name (hint, e.g. "ftl", "leader")
#   $2: section name (hint, e.g. "move", "filter")
#   $3: keys (space-separated tokens, e.g. "LEADER f c")
#   $4: command function name
#   $5: short help text
ftl::kbd::bind() {
	local map="$1" section="$2" keys="$3" command="$4" help="${5:-}"
	local -a keys_arr=( $keys )
	local shortcut="" dscut=""
	local key

	for key in "${keys_arr[@]}" ; do
		shortcut+="$key"

		# Warn on override if requested
		if (( ftl_kbd_warn_on_override )) ; then
			if [[ "${ftl_kbd_trie[$shortcut]:-}" =~ [[:alpha:]] ]] ; then
				echo "ftl: bind: map: $map, section: $section, keys:'$keys'," \
					 "command: '$command' is overriding '${ftl_kbd_trie[$shortcut]}'"
			fi
		fi

		# Track prefix usage count (safe for non-numeric values)
		local __current="${ftl_kbd_trie[$shortcut]:-}"
		if [[ "$__current" =~ ^[0-9]+$ ]] ; then
			ftl_kbd_trie[$shortcut]=$(( __current + 1 ))
		fi

		# Build display string with AltGr annotations
		if [[ -n "${ftl_kbd_altgr_inverse[$key]:-}" ]] ; then
			dscut+=" ⇑${ftl_kbd_altgr_inverse[$key]}/$key"
		elif [[ -n "${ftl_kbd_shift_altgr_inverse[$key]:-}" ]] ; then
			dscut+=" ⇈${ftl_kbd_shift_altgr_inverse[$key]}/$key"
		else
			dscut+=" $key"
		fi
	done

	if (( ftl_kbd_warn_on_override )) && [[ "${ftl_kbd_trie[$shortcut]:-}" != "$command" ]] ; then
		echo "ftl: bind: map: $map, section: $section, keys:'$keys'," \
			 "command: '$command' is overriding command path"
	fi

	ftl_kbd_command_to_key[$command]="$shortcut"
	ftl_kbd_trie[$shortcut]="$command"
	ftl_kbd_bindings_display[$dscut]="$map"$'\t'"$section"$'\t'"$dscut"$'\t'"$command"$'\t'"$help"
}

# Remove a key binding.
# Args:
#   $1: keys (space-separated tokens)
ftl::kbd::unbind() {
	local keys="$1"
	local -a keys_arr=( $keys )
	local shortcut="" dscut=""
	local key command

	for key in "${keys_arr[@]}" ; do
		shortcut+="$key"
		if [[ -n "${ftl_kbd_altgr_inverse[$key]:-}" ]] ; then
			dscut+=" ⇑${ftl_kbd_altgr_inverse[$key]}/$key"
		elif [[ -n "${ftl_kbd_shift_altgr_inverse[$key]:-}" ]] ; then
			dscut+=" ⇈${ftl_kbd_shift_altgr_inverse[$key]}/$key"
		else
			dscut+=" $key"
		fi
	done

	command="${ftl_kbd_trie[$shortcut]}"
	unset 'ftl_kbd_command_to_key[$command]'
	unset 'ftl_kbd_trie[$shortcut]'
	unset 'ftl_kbd_bindings_display[$dscut]'
}

# Reset the redo-exclusion set.
ftl::kbd::reset_redo_exclusions() {
	declare -gA ftl_kbd_redo_excluded=()
}

# Exclude a command from being recorded as the last command (for redo).
# Args:
#   $1: command name
ftl::kbd::exclude_from_redo() {
	ftl_kbd_redo_excluded[$1]=1
}

# Read a single key from stdin and normalize it.
# Sets ftl_kbd_current_key (normalized) and ftl_kbd_raw_key (raw).
# Args:
#   $1: optional timeout in seconds (was: KEY_TIMEOUT)
ftl::kbd::get_key() {
	local oifs="$IFS"
	IFS=

	if [[ -n "$1" ]] ; then
		read -rsn 1 -t "$1" ftl_kbd_current_key || ftl_kbd_current_key="ERROR_$?"
	else
		read -rsn 1 ftl_kbd_current_key || ftl_kbd_current_key="ERROR_$?"
	fi
	ftl_kbd_raw_key="$ftl_kbd_current_key"

	# Slurp up to 4 more bytes (for escape sequences) with 1ms timeout
	local e1 e2 e3 e4
	read -rsn 4 -t 0.001 e1 e2 e3 e4

	ftl_kbd_current_key="$(ftl::kbd::normalize_key \
		"$ftl_kbd_current_key$e1$e2$e3$e4")"

	IFS="$oifs"
}

# Normalize a raw escape sequence to a symbolic key name.
# Args:
#   $1: raw key sequence
# Outputs: normalized key name (e.g. "UP", "ENTER", "CTL-A")
ftl::kbd::normalize_key() {
	case "$1" in
		$'\e')                           echo "ESCAPE" ;;
		$'\177')                         echo "BACKSPACE" ;;
		$'\\')                           echo "BACKSLASH" ;;
		$' ')                            echo "SPACE" ;;
		$'*')                            echo "STAR" ;;
		$'@')                            echo "AT" ;;
		$"'" )                           echo "QUOTE" ;;
		$'"')                            echo "DQUOTE" ;;
		$'\t')                           echo "TAB" ;;
		$'')                             echo "ENTER" ;;
		$'\302\247')                     echo "PARAGRAPH" ;;
		$'\302\277')                     echo "INVERSED_QUESTION_MARK" ;;
		$'\302\250')                     echo "DIAERESIS" ;;

		$'\e[A' | $'\e[OA' | $'\e[A\e[') echo "UP" ;;
		$'\e[B' | $'\e[0B' | $'\e[B\e[') echo "DOWN" ;;
		$'\e[C' | $'\e[OC' | $'\e[C\e[') echo "RIGHT" ;;
		$'\e[D' | $'\e[OD' | $'\e[D\e[') echo "LEFT" ;;

		$'\e[2~')                        echo "INS" ;;
		$'\e[3~')                        echo "DEL" ;;
		$'\e[1~' | $'\e[H')              echo "HOME" ;;
		$'\e[4~' | $'\e[F')              echo "END" ;;
		$'\e[5~')                        echo "PGUP" ;;
		$'\e[6~')                        echo "PGDN" ;;

		$'\e[11~' | $'\e[[A' | $'\eOP')  echo "F1" ;;
		$'\e[12~' | $'\e[[B' | $'\eOQ')  echo "F2" ;;
		$'\e[13~' | $'\e[[C' | $'\eOR')  echo "F3" ;;
		$'\e[14~' | $'\e[[D' | $'\eOS')  echo "F4" ;;
		$'\e['15~ | $'\e[[E')            echo "F5" ;;
		$'\e['17~ | $'\e[[F')            echo "F6" ;;
		$'\e['18~)                       echo "F7" ;;
		$'\e['19~)                       echo "F8" ;;
		$'\e['20~)                       echo "F9" ;;
		$'\e['21~)                       echo "F10" ;;
		$'\e['23~)                       echo "F11" ;;
		$'\e['24~)                       echo "F12" ;;

		$'\001')                         echo "CTL-A" ;;
		$'\002')                         echo "CTL-B" ;;
		$'\004')                         echo "CTL-D" ;;
		$'\005')                         echo "CTL-E" ;;
		$'\006')                         echo "CTL-F" ;;
		$'\a')                           echo "CTL-G" ;;
		$'\b')                           echo "CTL-H" ;;
		$'\v')                           echo "CTL-K" ;;
		$'\f')                           echo "CTL-L" ;;
		$'\016')                         echo "CTL-N" ;;
		$'\017')                         echo "CTL-O" ;;
		$'\020')                         echo "CTL-P" ;;
		$'\021')                         echo "CTL-Q" ;;
		$'\022')                         echo "CTL-R" ;;
		$'\023')                         echo "CTL-S" ;;
		$'\024')                         echo "CTL-T" ;;
		$'\025')                         echo "CTL-U" ;;
		$'\026')                         echo "CTL-V" ;;
		$'\027')                         echo "CTL-W" ;;
		$'\030')                         echo "CTL-X" ;;
		$'\031')                         echo "CTL-Y" ;;

		$'\ej')                          echo "ALT-J" ;;
		$'\ek')                          echo "ALT-K" ;;

		*)
			# Pass through single printable ASCII characters
			# (space 0x20 through tilde 0x7E). This covers all
			# letters, digits, and punctuation that bindings use.
			# Without this fallback, plain keys like j, k, h, l
			# are silently dropped (the case falls through with
			# no output, and ftl_kbd_current_key becomes empty).
			# Using a variable for the regex avoids bash parser
			# confusion with the tilde character.
			local _printable_re='^[ -~]$'
			if [[ "$1" =~ $_printable_re ]] ; then
				echo "$1"
			fi
			# Multi-byte or unrecognized sequences: output nothing.
			# The dispatch overflow guard resets after 4 empty keys.
			;;
	esac
}

# Dispatch the current key to a command.
# Reads ftl_kbd_current_key, invokes the matching command function.
ftl::kbd::dispatch() {
	local reply="$ftl_kbd_current_key"
	local lookup cmd keys_function

	# Overflow guard — too many keys accumulated without a match
	if (( ftl_kbd_keys_count > 3 )) ; then
		ftl_kbd_accumulated_keys=""
		ftl_kbd_count=""
		ftl_kbd_has_count=
		return
	fi

	# Timeout — reset accumulation
	if [[ "$reply" == ERROR_* ]] ; then
		ftl_kbd_accumulated_keys=""
		ftl_kbd_count=""
		ftl_kbd_has_count=
		return
	fi

	# Translate special keys
	[[ "$reply" == "?" ]] && reply="QUESTION_MARK"
	[[ "$reply" == "$ftl_cfg_leader_key" ]] && reply="LEADER"

	# Sub-mode dispatch (e.g. incremental search, fzf client)
	if [[ -n "$ftl_kbd_submode_handler" ]] ; then
		"$ftl_kbd_submode_handler"
		return
	fi

	# Escape interrupts any accumulation
	if [[ "$reply" == "ESCAPE" ]] ; then
		ftl_kbd_accumulated_keys=""
		ftl_kbd_count=""
		ftl_kbd_has_count=
		return
	fi

	# Count accumulation
	if [[ -z "$ftl_kbd_accumulated_keys" || "$ftl_kbd_accumulated_keys" =~ ^[0-9]$ ]] ; then
		if [[ "$reply" =~ ^[0-9]$ ]] ; then
			if [[ "$ftl_kbd_count$reply" != "0" ]] ; then
				ftl_kbd_has_count=1
				ftl_kbd_count+="$reply"
			fi
			return
		fi
	fi

	# Accumulate this key
	ftl_kbd_accumulated_keys+="$reply"
	(( ftl_kbd_keys_count++ ))

	# Virtual entry intercept
	if (( ${#ftl_plugin_vfiles[@]} || ${#ftl_plugin_vdirs[@]} )) ; then
		if ftl::plugin::virtual::handle_key "$ftl_kbd_accumulated_keys" ; then
			return
		fi
	fi

	# Trie lookup (with optional count prefix)
	lookup="${ftl_kbd_has_count:+COUNT}$ftl_kbd_accumulated_keys"
	# Guard against empty lookup — ftl_kbd_trie[""] causes
	# "bad array subscript" under set -u. This happens when
	# normalize_key returns empty (unrecognized key).
	if [[ -n "$lookup" && -n "$ftl_kbd_accumulated_keys" ]] ; then
		cmd="${ftl_kbd_trie[$lookup]:-${ftl_kbd_trie[$ftl_kbd_accumulated_keys]:-}}"
	else
		cmd=
	fi

	if [[ -n "$cmd" ]] && [[ $(type -t "$cmd") == function ]] ; then
		ftl::state::serialize_info "$ftl_state_main_info_file_path"
		keys_function="$cmd"
		"$cmd"
		[[ "${ftl_kbd_redo_excluded[$keys_function]:-}" ]] || ftl_kbd_last_command="$keys_function"
		ftl_kbd_accumulated_keys=""
		ftl_kbd_count=""
		ftl_kbd_has_count=
		ftl_kbd_current_key=
		return
	fi

	# Redo key
	if [[ "$lookup" == "$ftl_cfg_redo_key" && -n "$ftl_kbd_last_command" ]] ; then
		"$ftl_kbd_last_command"
		ftl_kbd_accumulated_keys=""
		ftl_kbd_count=""
		ftl_kbd_has_count=
		ftl_kbd_current_key=
	fi
}

# Drain pending input from stdin (was: kbdf).
ftl::kbd::drain_input() {
	while read -t 0.01 ; do : ; done
}

# Show the keyboard bindings table (was: k_bindings).
ftl::kbd::show_bindings() {
	if (( ftl_cfg_bindings_in_popup )) ; then
		_ftl::kbd::show_bindings_popup
	else
		_ftl::kbd::show_bindings_fullscreen
	fi
	ftl::util::enter_alt_screen
	ftl::list::render
}

# Show bindings in a fullscreen fzf.
_ftl::kbd::show_bindings_fullscreen() {
	ftl::prev::clear
	exec 2>&9
	_ftl::kbd::generate_bindings_table | fzf
	exec 2>"$ftl_state_session_dir/log"
	ftl::util::enter_alt_screen
	true
}

# Show bindings in a tmux popup.
_ftl::kbd::show_bindings_popup() {
	_ftl::kbd::generate_bindings_table | fzf-tmux $ftl_cfg_fzf_popup_opts
	true
}

# Generate the bindings table for display.
# Outputs: formatted table on stdout
_ftl::kbd::generate_bindings_table() {
	printf '%s\n' "${ftl_kbd_bindings_display[@]}" \
		| sort -h \
		| column -t \
			  --table-columns "____map____,____section____, ____key____,____command____,____does____" \
			  -s $'\t' \
			  -c "$ftl_cfg_bindings_display_width"
}

# Initialize default redo exclusions (movement commands).
ftl::kbd::init_exclusions() {
	ftl::kbd::reset_redo_exclusions
	ftl::kbd::exclude_from_redo "move_up"
	ftl::kbd::exclude_from_redo "move_up_arrow"
	ftl::kbd::exclude_from_redo "move_down"
	ftl::kbd::exclude_from_redo "move_down_arrow"
	ftl::kbd::exclude_from_redo "ftl::plugin::type_handlers::move_left"
	ftl::kbd::exclude_from_redo "move_left_arrow"
	ftl::kbd::exclude_from_redo "move_right"
	ftl::kbd::exclude_from_redo "move_right_arrow"
}

# vim: set filetype=bash :
