external_bindings()
{
((inc_search)) && case "${REPLY: -1}" in '') inc_search=0 ; cursor_color='\e[7;34m' ; list ;; *) to_search="$to_search$REPLY" ; ffind n ; header "~$to_search" ; esac && return

case "${REPLY: -1}" in
	#\_ ) echo -en '\e[?25l\e[H' ; header "*ran plugin*" ;;

	\_ ) { for i in $(seq 1 50)  ; do  echo $i ; sleep 0.5 ; done } | tmux splitw -dI & ;;

	b  ) to_search= ; inc_search=1 ; header "~$to_search" ; cursor_color='\e[7;35m' ;;
	*  ) false ;;
esac
}


