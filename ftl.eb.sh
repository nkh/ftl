external_bindings()
{
((inc_search)) && case "${REPLY: -1}" in '') inc_search=0 ; cursor_color='\e[7;34m' ; list ;; *) to_search="$to_search$REPLY" ; ffind n ; esac && return

case "${REPLY: -1}" in
	# montage: time montage -geometry 200x200+3+3 $(printf "%s\n" *.jpg | head -n 10 | tr '\n' ' ') -background '#232627' montage.png
	#\_ ) { for i in $(seq 1 50)  ; do  echo $i ; sleep 0.5 ; done } | tmux splitw -dI & ;;

	b  ) to_search= ; inc_search=1 ; cursor_color='\e[7;35m' ;;
	*  ) false ;;
esac
}



