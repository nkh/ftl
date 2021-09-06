external_bindings()
{
# incrementa search, binding: b
((inc_search)) && case "${REPLY: -1}" in '') inc_search=0 ; cursor_color='\e[7;34m' ; list ;; *) to_search="$to_search$REPLY" ; ffind n ; esac && return

case "${REPLY: -1}" in
	# commands for image optimisation
	# montage: time montage -geometry 200x200+3+3 $(printf "%s\n" *.jpg | head -n 10 | tr '\n' ' ') -background '#232627' montage.png

	b  ) to_search= ; inc_search=1 ; cursor_color='\e[7;35m' ;;
	*  ) false ;;
esac
}



