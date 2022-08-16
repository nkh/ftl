#!/bin/env bash

ftl() # dir[/file], pfs, preview_ftl. © Nadim Khemir 2020-2022, Artistic licence 2.0
{
declare -Ag ftl_key_map C bindings ; key_map=ftl_key_map ; source $FTL_CFG/ftlrc || source $FTL_CFG/etc/ftlrc ;

my_pane=$(pid_2_pane $$) ; declare -A -g dir_file mime pignore lignore tail tags ntags ftl_env du_size ; mkapipe 4 5 6 ; tag_read "$@" && shift 2
tab=0 ; tabs+=("$PWD") ; ntabs=1 ; pdir_only[tab]= ; max_depth[tab]=1 ; imode[tab]=0 ; lmode[tab]=0 ; rfilters[tab]=$rfilter0
echo -en '\e[?1049h' ; stty -echo ; filter_rst ; sort_filters=(-k3 -n -k2) ; flips=(' ' ' ') ; dir_done=56fbb22f2967 

[[ "$1" ]] && { [[ -d "$1" ]] && { dir="$1" ; search='' ; } || { [[ -f "$1" ]] && { path "$1" ; dir="${p}" ; search="$f" ; } ; } || { echo ftl: \'$1\', no such path ; exit 1 ; } ; }
[[ "$2" ]] && { fs=$2/$$ ; pfs=$2 ; mkdir -p $fs ; touch $fs/history ; } || { fs=$ftl_root/$$ ; pfs=$fs ; main=1 ; mkdir -p $fs/prev ; touch $ghist ; echo $my_pane >$fs/pane ; } ;
fsp=$pfs/prev ; PPWD="$dir" ; export ftl_root
[[ "$3" ]] && { gpreview=1 ; prev_all=0 ; emode=0 ; prev_synch ; true ; } || { tag_synch ; cdir "$dir" "$search" ; }

while : ; do tag_synch ; winch ; { [[ "$R" ]] && { REPLY="${R:0:1}" ; R="${R:1}" ; } || read -sn 1 -r -t 0.3 ; } && try key_command ; kbdf ; winch=1 ; REPLY= ; done
}

bind()
{
local map="$1" section="$2" key="$3" command="$4" help="$5"

eval "declare -Ag ${map}_key_map ; ${map}_key_map[$key]='$command'"
C[$command]="$key"

{ [[ -n "${LA[$key]}" ]] && shortcut="⇑${LA[$key]}/$key" ; } || { [[ -n "${LSA[$key]}" ]] && shortcut="⇈${LSA[$key]}/$key" ; } || shortcut="$key"
bindings[$command]="$map	$section	$shortcut	$command	$help"
}

key_command()
{
[[ "$REPLY" == ''    ]] && REPLY=ENTER_KEY
[[ "$REPLY" == '\'   ]] && REPLY=BACKSPACE_KEY
[[ "$REPLY" == ' '   ]] && REPLY=SPACE_KEY
[[ "$REPLY" == '*'   ]] && REPLY=STAR_KEY
[[ "$REPLY" == '@'   ]] && REPLY=AT_KEY
[[ "$REPLY" == "'"   ]] && REPLY=QUOTE_KEY
[[ "$REPLY" == '"'   ]] && REPLY=DQUOTE_KEY
[[ "$REPLY" == $'\t' ]] && REPLY=TAB_KEY
[[ "$REPLY" == $'\e' ]] && REPLY=ESCAPE_SEQ1
[[ "$REPLY" == '['   ]] && REPLY=ESCAPE_SEQ2
#pdhn "${key_map}+$REPLY" ; pdh_kfunc=1 

   { [[ $(type -t "${key_map}") == function ]] && $key_map $REPLY ; } \
|| { declare -nl iarray="$key_map" ; [[ $(type -t "${iarray[$REPLY]}") == function ]] && { ((pdh_kfunc)) && pdhn "-> ${iarray[$REPLY]}" ; true ; } && ${iarray[$REPLY]} ; } \
|| key_map=ftl_key_map
}

cdir() { inotify_k ; get_dir "$@" ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; ((qd)) || refresh ; list "${3:-$found}" ; true ; }
get_dir() # dir, search
{
cd "${1:-$PWD}" || return ; [[ "$PPWD" != "$PWD" ]] && { marks["'"]="$n" ; PPWD="$PWD" ; ((gpreview)) || echo "$n" | tee -a $fs/history >> $ghist ; }
tabs[$tab]="$PWD" ; inotify_s ; ((etag)) && etag_dir ; [[ "$PWD" == / ]] && sep= || sep=/ ; shopt -s nocasematch ; geo_prev

files=() ; files_color=() ; mime=() ; nfiles=0 ; search="${2:-$([[ "${dir_file[${tab}_$PPWD]}" ]] || echo "$find_auto")}" ; found= ; s_type=$sort_type0 ; s_reversed=$sort_reversed0
[[ -f .ftlrc_dir ]] && source .ftlrc_dir ; s_type=${sort_type[tab]:-$s_type} ; [[ "${reversed[tab]}" == "-r" ]] && s_reversed=-r || { [[ "${reversed[tab]}" == "0" ]] && s_reversed= ; }

((gpreview)) || nice -15 $pgen/generator $thumbs &

declare -A uniq_file ; pad=(* ?) ; pad=${#pad[@]} ; pad=${#pad} ; line=0 ; sum=0 ; first_file= ; local LANG=C LC_ALL=C ; dir &
while : ; do read -s -u 4 pnc ; [ $? -gt 128 ] && break ; read -s -u 5 pc ; read -s -u 6 size
	[[ $pnc == $dir_done ]] && break ; ((${uniq_file[$pnc]})) && continue ; uniq_file[$pnc]=1
	((quick_display && nfiles > 0 && 0 == nfiles % quick_display)) && { refresh ; qd=1 ; list $found ; }
	[[ ! -r "$pnc" ]] && pc="\e[7m$pnc\e[m" ; [[ -d "$pnc" && ! -x "$pnc" ]] && pc="\e[31m$pnc"
	[[ "$pnc" =~ '.' ]] && { e=${pnc##*.} ; ((lignore[${tab}_${e@Q}] || lignore[${e@Q}])) && continue ; } ; pl=${#pnc}
	((etag)) && { etag_tag "$pnc" external_tag external_tag_length ; pc="$external_tag$pc" ; ((pl+=external_tag_length)) ; }
	((show_size)) && { ((sum += size, pl += 5)) ; [[ -d "$pnc" ]] && { ((show_size > 1)) && pc="$(dir_size "$pnc") $pc" || pc="     $pc" ; true ; } \
			 || { for u in '' K M G T ; do ((size < 1024)) && printf -v pc "\e[94m%4s\e[m $pc" $size$u && break ; ((size/=1024)) ; done  ; } ; }
	((show_line)) && { ((line++)) ; printf -v pc "$line_color%-${pad}d\e[m¿${pc/\%/%%}" $line ; ((pl += 4)) ; }
	pcl=${pc:0:(( ${#pc} == $pl ? ($COLS - 1) : ( (${#pc} - 4) - $pl ) + ($COLS - 1) )) }
	((pl > (COLS - 1))) && { [[ "$pnc" =~ '.' ]] && e=${pnc##*.} || e= ; pcl=${pcl:0:((${#pcl}-(${#e}+1)))}…${e} ; }
	[[ -f "$pnc" ]] && [[ -z $first_file ]] && first_file=$nfiles
	files_color[$nfiles]="$pcl" ; files[$nfiles]="$PWD$sep$pnc" ; [[ -n "$search" && -z "$found" ]] && [[ "${pnc:0:${#search}}" == "$search" ]] && found=$nfiles ; ((nfiles++))
done

shopt -u nocasematch ; qd=0 ; ((show_size)) && hsum=$(numfmt --to=iec --format ' %4f' "$sum") || hsum=
}

list() # select
{
[[ "$1" ]] && dir_file[${tab}_$PWD]="$1" ; file=${dir_file[${tab}_$PWD]:-0}
((file = file > nfiles - 1 ? nfiles - 1 : file)) ; ((nfiles)) && path "${files[file]}" || path_none ; ((gpreview)) || save_state $fs ; selection ; geo_winch
((top = nfiles < lines || file <= center ? 0 : file >= nfiles - center ? nfiles - lines : file - center, bottom = top + lines - 1, bottom = bottom < 0 ? 0 : bottom)) ; l=0

head="${lglyph[lmode[tab]]}${iglyph[imode[tab]]}${pdir_only[tab]}${montage}" ; head=${head:+$head }
((ntabs>1)) && tabsd=' ᵗ'$((tab+1)) || tabsd= ; 
((nfiles)) && { ((qd)) || ((flipi^=1)) ; flip="${flips[$flipi]}" ; } || { head="\e[33m∅ $head$ftag$tabsd" ; header '' "$head" ; tcpreview ; clear_list 0 ; return ; }
((show_stat)) && stat="$(stat -c ' %A %U' "${files[file]}") $(stat -c %s "${files[file]}" | numfmt --to=iec --format '%4f')" || stat= ;
((s_type == 2 && show_date)) && date=$(date -r "${files[file]}" +' %D-%R') || date= ; head="$head$ftag$((file+1))/${nfiles}$hsum$stat$date$tabsd$flip" ; header '' "$head"

for((i=$top ; i <= bottom ; i++))
	do
		cursor=${tags[${files[$i]}]:- } ; [[ $i == $file ]] && cursor="${cursor_color}$cursor\e[m"
		echo -ne "\e[m\e[K$cursor${files_color[i]/¿/$flip}" ; ((i != bottom)) && echo ; ((l++))
	done

((l < LINES - 1)) && echo ; clear_list $i ; ((qd || gpreview)) || { geo_winch ; preview ; }
}

preview() # force_preview
{
((main || prev_all)) || { pane_read ; save_state ; echo "$fs" >$fsp/fs ; echo $my_pane >$fsp/pane ; tmux send -t $main_pane ${C[SIG_REMOTE]} &>/dev/null ; return ; }

((emode)) && { for external in $(externals) ; do $external && { sleep 0.1 ; emode=0 ; return ; } ; done ; } ; emode=0 ;
((${1:-${preview:-$prev_all}})) && { preview= ; for v in $(previewers) ; do $v && { extmode=0 ; return ; } ; done ; extmode=0 ; }
tcpreview
}

[[ $TMUX ]] && { FTL_CFG="$HOME/.config/ftl" ; source $FTL_CFG/etc/core ; source $FTL_CFG/etc/commands ; ftl "$@" ; } || echo 'ftl: run in tmux'
