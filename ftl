#!/bin/env bash
cdf() { mkdir -p /tmp/ftl ; l=/tmp/ftl/location ; ftl 3>$l ; [[ -e $l ]] && d="$(head -n 1 $l)" && cd "$(dirname "$d")" ; } ; [[ ${BASH_SOURCE[0]} != $0 ]] && return ;

ftl() # fd_directory, parent fs. © Nadim Khemir 2021, Artistic licence 2.0
{
my_pane ; mkapipe 4 5 6 ; declare -A dir_file pignore tags marks=([0]=/ [1]=/home/nadim/nadim [2]=/home/nadim/nadim/downloads)
preview_all=${preview_all:-1} ; pdir_only=0 ; previewers=(pdir pignore pmp4 pimage pmedia ppdf phtml get_mime pperl pshell ptext ptype) 
pw3start ; find_auto=README ; quick_display=256 ; exit_mplayer= ; max_depth=1 ; tab=0 ; tabs+=("$PWD") ; imode=0 ; zoom=0 ; zooms=(80 50 35) 
tbcolor 67 67 ; cursor_color='\e[7;34m' ; show_dirs=1 ; show_files=1 ; show_size=0 ; show_date=1 ; ifilter='jpg|jpeg|JPG|png|gif'
sort_type=0 ; find_formats=('%s %P\n' '%s %P\n' '%T@ %s %P\n') ; sort_filters=(by_name by_size by_date) ; sort_name=( ⍺ 🡕 ≣ )

[[ "$1" ]] && { dir="$1" ; [[ -d "$dir" ]] || { echo ftl: \'$1\', no such directory ; exit 1 ; } ; }
echo -en '\e[?1049h' ; mkdir -p /tmp/ftl/thumbs ; pushd "$dir" &>/dev/null ; stty -echo 
[[ "$2" ]] && { fs="$2/$$" ; mkdir -p "$fs" ; parent_fs="$2" ; ftl_pmode "$parent_fs" ; } || { fs=/tmp/ftl/$$ ; mkdir -p $fs ; cdir ; }

while true; do [[ $R ]] && { REPLY=$R ; R= ; } || read  -sn 1 ; case "${REPLY: -1}" in
	g|G    ) [[ $REPLY == G ]] && ((dir_file["$PWD"] = nfiles - 1)) || dir_file["$PWD"]=0 ; list ;;
	h|D    ) [[ "$PWD" != / ]]  && { nd="${PWD%/*}" ; cdir "${nd:-/}" "$(basename "$p")"; } ;;
	j|B|k|A) ((nfiles)) && { [[ $REPLY == j || "$REPLY" == B ]] && move 1 || move -1 ; } ;;
	l|C|'' ) ((nfiles)) && { [[ -f "${files[file]}" ]] && [[ $REPLY == '' ]] && edit || cdir "${files[file]}" ; } ;;
	5|6    ) [[ $REPLY == 5 ]] && move -$LINES || move $LINES ;;
	J|K    ) [[ $REPLY == K ]] && movep U || movep D ;;
	q|Q|Z  ) [[ $REPLY == Z ]] && { exit_mplayer=1 ; quit ; } || close_tab || quit ;;
	z      ) quit2 ; [[ $pane_id ]] && { tmux selectp -t $pane_id ; tmux resizep -Z -t $pane_id ; } ; exit 0 ;;

	0      ) ((gpreview)) && synch $parent_fs ;;
	[1-4]  ) ((tab = $REPLY - 1 , tab >= ${#tabs[@]})) && tab=0 ; cdir ${tabs[tab]} ;;
	7      ) prompt "filter2: " -ei "${filters2[tab]}" ; filters2[tab]="$REPLY" ; filter_tag="~" ; dir_file[$PWD]= ; tcpreview ; cdir '' ;;
	a      ) kmplayer ;;
	b|n|N  ) how=$REPLY ; [[ $how == 'b' ]] && { prompt "find: " -e to_search ; how=n ; } ; ffind $how ;;
	c      ) prompt 'cp to: ' -e && [[ $REPLY ]] && { cp "${selection[@]}" "$REPLY" ; tags=() ; } ; cdir ;;
	d      ) ((${#tags[@]})) && delete " (${#tags[@]} selected)" || delete ;;
	E      ) cdir "$(tac $fs/history | awk '!seen[$0]++' | lscolors | fzf --ansi --info=inline --layout=reverse)" ;;
	e      ) cdir "$(tac /tmp/ftl/history | awk '!seen[$0]++' | lscolors | fzf --ansi --info=inline --layout=reverse)" ;;
	f      ) prompt "filter: " -ei "${filters[tab]}" ; filters[tab]="$REPLY" ; filter_tag="~" ; dir_file[$PWD]= ; tcpreview ; cdir '' ;;
	F      ) filters[tab]= ; filters2[tab]= ; filter_tag= ; tcpreview ; cdir ;;
	H      ) prompt 'clear global history? [y|N]' -sn1 && [[ $REPLY == y ]] && rm /tmp/ftl/history 2>/dev/null ; list ;;
	i      ) ((imode ^= 1)) ; ftl_imode $imode ; cdir ;;
	I      ) tcpreview ; fzf_go "$(fzfi -q '.jpg | .jpeg | .png | .gif ')" ;;
	L      ) for f in "${selection[@]}" ; do ln -s -b "$f" "$PWD" ; done ; tags=() ; cdir ;;
	M      ) prompt 'mkdir: ' && [[ "$REPLY" ]] && mkdir -p "$PWD/$REPLY" ; cdir "$PWD/$REPLY" ;;
	m      ) prompt 'M' -n 1 && [[ -n $REPLY ]] && marks[$REPLY]=$(dirname "${files[file]}") ; list ;;
	o|O    ) [[ $REPLY == o ]] && { ((show_files ^= 1)) ; true ; } || ((show_dirs ^= 1)) ; cdir ;;
	p|P    ) ((${#tags[@]})) && { [[ $REPLY == p ]] && cmd=cp || cmd=mv ; $cmd "${!tags[@]}" "$PWD" ; tags=() ; cdir ; } ;;
	R      ) [[ $show_reversed ]] && show_reversed= || show_reversed=-r ; cdir ;;
	r      ) ((${#tags[@]})) && bulkrename || { prompt "rename ${files[file]##*/} to: " && [[ $REPLY ]] && mv "${files[file]}" "$REPLY" ; } ; cdir ;;
	S      ) ((show_dir_size ^= 1)) ; cdir ;;
	s      ) ((show_size ^= 1)) ; cdir ;;
	T      ) fzf_tag "$(fd . --color=always | fzf -m --ansi --info=inline --layout=reverse --marker '▪')" ; list ;;
	t      ) tabs+=("$PWD") ; ((tab = ${#tabs[@]} - 1)) ; cdir ;;
	u|U    ) [[ $REPLY == u ]] && for p in "${files[@]}" ; do tags["$p"]='▪' ; done || tags=() ; list ;;
	v|V    ) [[ $REPLY == V  ]] && preview=1 || ((preview_all ^= 1)) ; ((${preview:-$preview_all})) || { wcpreview ; tcpreview ; } ; cdir ;;
	w|W    ) external=1 ; [[ $REPLY == W  ]] && detached=1 ; list ;;
	x|X    ) [[ $REPLY == x ]] && mode=a+x || mode=a-x ; chmod $mode "${selection[@]}" ; cdir ;;
	' '|y|Y) tag_flip "${files[file]}" ; ((nfiles == 1)) && list || { [[ $REPLY == Y ]] && R=k || R=j ; } ;;
	\!     ) [[ $e ]] && ((pignore[${e}] ^= 1)) && cdir ;;
	\>|\<  )  tcpreview ; [[ $REPLY == \> ]] && epane || epane '-h -b' -R ; cdir ;;
	$'\t'  ) ((tab += 1, tab >= ${#tabs[@]})) && tab=0 ; cdir ${tabs[tab]} ;;
	\,     ) { /bin/cat $fs/../marks 2>/dev/null ; echo "$n" ; } | awk '!seen[$0]++' | sponge $fs/../marks ;;
	\|     ) kepanes 1 ;;
	\"     ) ((no_image_preview ^= 1)) ; for e in $(tr '|' ' ' <<< "$ifilter") ; do pignore[${e}]=$no_image_preview ; done ; ((zoom == 0)) && R='-' ; cdir ;;
	\\     ) ((pdir_only ^= 1)) ; list ;;
	@      ) prompt 'cd: ' -e ; [[ -n $REPLY ]] && cdir "$REPLY" || list ;;
	\;     ) prompt 'clear persistent marks? [y|N]' -sn1 && [[ $REPLY == y ]] && :>$fs/../marks ; list ;;
	\*     ) prompt 'depth: ' && [ "$REPLY" -eq "$REPLY" ] 2>/dev/null && max_depth=$REPLY && cdir ;;
	\:     ) prompt ': ' -e ; [[ $REPLY ]] && shell ; cdir ;;
	\'     ) prompt "'" -n 1 ; [[ -n ${marks[$REPLY]} ]] && cdir ${marks[$REPLY]} || list ;;
	.      ) ((show_hidden)) && show_hidden= || show_hidden=1 ; cdir ;;
	\^     ) ((show_stat ^= 1)) ; list ;;
	\=     ) ((sort_type++, sort_type = sort_type >= ${#sort_filters[@]} ? 0 : sort_type)) ; cdir ;;
	\}     ) tcpreview ; fzf_go "$(/bin/cat $fs/../marks | lscolors | fzf --ansi --info=inline --layout=reverse)" ;;
	/      ) tcpreview ; fzf_go "$(fd . --color=always -L | fzf --ansi --info=inline --layout=reverse)" ;;
	\{     ) tcpreview ; fzf_go "$(fzfppv -L)" ;;
	\?     ) tcpreview ; rg_go "$(fzfr)" ;;
	_      ) wcpreview ; tcpreview ; opi=$pane_id ; tsplit /bin/bash 30% -v -U ; shell_id=$pane_id ; pane_id=$opi ; list ; tmux selectp -t $shell_id ;;
	\-     ) ((zoom += 1, zoom >= ${#zooms[@]})) && zoom=0 ; tcpreview ; cdir ;;
esac ; done #§¶½~&%¤#$+89
}

cdir() # dir, search, select
{
new_dir=${1:-$PWD} ; [[ -d "$new_dir" ]] || return 
files=() ; files_color= ; mime=() ; search="${2:-${dir_file[$new_dir]:-$find_auto}}" ; select="$3" ; found= ; nfiles=0 

read -r LINES COLS LEFT WIDTH< <(tmux display -p -t $my_pane '#{pane_height} #{pane_width} #{pane_left} #{window_cell_width}')
((${preview:-$preview_all})) && [[ -z $pane_id ]] && ((COLS = (COLS - 1) * (100 - ${zooms[zoom]}) / 100))
((lines = LINES - 1, center = lines / 2)) ; ((img_x = (LEFT + COLS) * 10)) ; 

[[ "$PPWD" != "$PWD" ]] && PPWD="$PWD" ; marks[$'\'']="$PPWD"; PWD="$new_dir" ; tabs[tab]="$PWD"
cd "$PWD" 2>$fs/error || { refresh ; /bin/cat $fs/error ; return ; }
((gpreview)) || [[ "$PPWD" != "$PWD" ]] && echo "$PWD" | tee -a $fs/history >> /tmp/ftl/history ; [[ "$PWD" == / ]] && sep= || sep=/

dir &
while true ; do read -s -u 4 -t 0.04 p ; [ $? -gt 128 ] && break ; read -s -u 5 pc ; read -s -u 6 size
	((quick_display && nfiles > 0 && 0 == nfiles % quick_display)) && { refresh ; list $found ; in_quick_display=1 ; }

	pl=${#p} ; ((show_size)) && { [[ -d "$p" ]] && { ((show_dir_size)) && pc=$(dsize "$p")" $pc" || pc="     $pc" ; } || pc=$(fsize $size)" $pc" ; pl=$((pl + 5)) ; }
	pcl=${pc:0:(( ${#pc} == $pl ? ($COLS - 1) : ( (${#pc} - 4) - $pl ) + ($COLS - 1) )) }
	((${#p} > ($COLS - 1))) && { [[ "$p" =~ '.' ]] && e=….${p##*.} || e=… ; pcl=${pcl:0:((${#pcl} - ${#e}))}$e ; }
	files_color[$nfiles]="$pcl" ; files[$nfiles]="$PWD$sep$p" ;
	[[ -z $found ]] && [[ $p =~ ^$search ]] && found=$nfiles ; ((nfiles++))
done 

in_quick_display=0 ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; parse_path ; refresh ; list ${select:-$found} ;
}

list()
{
[[ $1 ]] && dir_file[$PWD]=$1 ; file=${dir_file[$PWD]:-0} ; ((file = file >= nfiles ? nfiles - 1 : file)) ; selection
((nfiles)) && { parse_path ; fsstate ; echo -en '\e[?25l\e[H' ; wcpreview ; } || { header "\e[33m<Empty>" && tcpreview && return ; }
((top = nfiles < lines || file <= center ? 0 : file >= nfiles - center ? nfiles - lines : file - center))

((show_stat)) && stat="$(stat -c ' %A %U' "${files[file]}") $(stat -c %s "${files[file]}" | numfmt --to=iec --format '%4f')" || stat=
header "$((file+1))/${nfiles}$stat"$( ((sort_type == 2 && show_date)) && date -r "${files[file]}" +" %D-%R") ;
for((i=$top ; i <= ((bottom = top + lines - 1, bottom < 0 ? 0 : bottom)) ; i++))
	do
		cursor=${tags[${files[$i]}]:- } ; [[ $i == $file ]] && cursor="$cursor_color$cursor\e[m"
		echo -ne "\e[K$cursor${files_color[i]}\e[m" ; ((i != bottom)) && echo
	done

((in_quick_display)) && return ; old_in_vipreview=$in_vipreview
((external)) && { echo -en '\e[?1049l' ; edir || eimage || emedia || epdf || ehtml || etext  && { echo -en '\e[?1049h' ; external= ; detached= ; list ; return ; } ; }
((${preview:-$preview_all})) && { preview= ; for v in ${previewers[@]} ; do $v && vcpreview && return ; done ; }
wcpreview ; tcpreview
}

ctsplit()   { [[ $pane_id ]] && tmux respawnp -k -t $pane_id "$1" &> /dev/null  || tsplit "$1" ; }
edir()      { [[ -d "$n" ]] && {  vlc "$n" &>/dev/null & } ; }
ehtml()     { [[ $e == 'html' ]] && { ((detached)) && { (qutebrowser "$n" 2>/dev/null &) ; } || { tcpreview ; w3m -o confirm_qq=0 "$n" ; } ; } ; } 
eimage()    { [[ $e =~ ^($ifilter)$ ]] && fim "$n" ; }
emedia()    { [[ $e =~ ^(mp3|mp4|flv|mkv)$ ]] && { ((! detached)) && { kmplayer ; mplayer -vo null "$n" </dev/null &>/dev/null & } && mplayer=$! || vlc "$n" &>/dev/null & } ; }
epdf()      { [[ $e == 'pdf' ]] && { ((detached)) && (zathura "$n" &) || run_maxed zathura "$n" ; true ; } ; }
etext()     { tcpreview ; tsplit "$EDITOR ${n@Q}" "33%" '-h -b' -R ; pane_id= ; external= ; cdir ; }
ftl_cmd()   { d=${1:-$n} ; echo "ftl ${d@Q} $fs " ; }
ftl_pmode() { gpreview=1 ; preview_all=0 ; external=0 ; synch $parent_fs ; }
ftl_imode() { (($1)) && { tfilters[tab]="$ifilter$" ; dir_file[$PWD]= ; } || tfilters[tab]= ; }
get_mime()  { [[ ${mime[file]} ]] || mime+=($(mimetype -b "${files[@]:${#mime[@]}:((file + 10))}" 2>/dev/null)) ; mtype="${mime[file]}" ; false ; }
kepanes()   { for p in ${epanes[@]} ; do tmux killp -t $p ; done ; epanes=() : sleep 0.01 ; tcpreview ; (($1)) && cdir ; }
kmplayer()  { ((mplayer)) && kill $mplayer &>/dev/null || pkill mplayer ; } 
pdir()      { [[ -d "$n" ]] && { (($in_pdir)) && [[ $pane_id ]] && tmux send -t $pane_id 0 || { ctsplit "$(ftl_cmd)" ; in_pdir=1 ; } ; } || pdir_only ; }
pdir_only() { in_pdir= ; ((pdir_only)) && { wcpreview ; tcpreview ; true ; } || false  ; }
phtml()     { [[ $e == 'html' ]] &&  w3m -dump "$n" > "$fs/$f.txt" && vipreview "$fs/$f.txt" ; }
pignore()   { [[ $e ]] && ((pignore["${e@Q}"])) && { get_mime ; in_pdir= ; in_vipreview= ; ptype ; true ; } || false ; }
pimage()    { [[ $e =~ ^($ifilter)$ ]] && pw3image || { tbcolor 67 67 && false ; } ; }
pmedia()    { [[ $e =~ ^(mp3|mp4|flv|mkv)$ ]] && ctsplit "exiftool ${n@Q} | /bin/less ; read -sn1" ; }
pmp4()      { [[ $e =~ mp4|flv ]] && { t="/tmp/ftl/thumbs/$f.jpg" ; [[ -f "$t" ]] || ffmpegthumbnailer -i "$n" -o "$t" -s 1024 ; pw3image "$t" ; true ; } ; }
pshell()    { [[ $mtype == 'application/x-shellscript' ]] && vipreview "$n" ; }
ppdf()      { [[ $e == 'pdf' ]] && { rm "$fs/$f.txt" 2>/dev/null ; pdftotext -l 3 "$n" "$fs/$f.txt" 2>/dev/null && vipreview "$fs/$f.txt" ; } ; }
pperl()     { [[ $mtype =~ ^application/x-perl$ ]] && [[ -s "$n" ]] && vipreview "$n" ; }
ptext()     { { [[ $e =~ ^json|yml$ ]] || [[ $mtype =~ ^text ]] ; }  && [[ -s "$n" ]] && vipreview "$n" ; }
ptype()     { ctsplit "echo $mtype ; file -b ${n@Q} ; stat -c %s ${n@Q} | numfmt --to=iec ; read -sn 100" ; }
pw3image()  { tbcolor 0 0 ; tcpreview ; sleep 0.01 ; w3p=1 ; echo -e "0;1;$img_x;0;0;0;;;;;${1:-$n}\n4;\n3;" >&7 ; }
pw3start()  { ((w3iproc)) || { mkapipe 7 ; { <&7 /usr/lib/w3m/w3mimgdisplay &> /dev/null & } ; w3iproc=$! ; } ; }
tcpreview() { [[ "$pane_id" ]] && tmux killp -t $pane_id &> /dev/null ; sleep 0.01 ; pane_id= ; in_vipreview= ; }
tsplit()    { tmux sp ${3:--h} -l ${2:-${zooms[zoom]}%} -c "$PWD" "$1" ; sleep 0.01 ; pane_id=$(tmux display -p '#{pane_id}') && tmux selectp ${4:--L} ; true ; }
vipreview() { ((in_vipreview)) && { tmux send -t $pane_id ':e'"$1" C-m ; } || ctsplit "$EDITOR -R ${1@Q}" ; ((in_vipreview++)) ; true ; }
vcpreview() { ((old_in_vipreview == in_vipreview)) && in_vipreview= ; true ; } 
wcpreview() { ((w3p)) && { ctsplit 'read -sn 100' ; sleep 0.01 ; w3p= ; } ; true ; }

bulkrename(){ tcpreview ; bulkedit && bulkverify && { bash $fs/br && tags=() || read -sn 1 ; } ; true ; }
bulkedit()  { /bin/cat $fs/tags | tee $fs/bo > $fs/bd ; $EDITOR $fs/bd ; }
bulkverify(){ echo 'set -e' > $fs/br ; paste $fs/bo $fs/bd | sed 's/^/mv /' >> $fs/br ; $EDITOR $fs/br ; }
by_name()   { sort $show_reversed -t ' ' -k2 | tee >(cut -f 1 -d ' ' >&6) | cut -f 2- -d' ' ; }
by_size()   { sort $show_reversed -n         | tee >(cut -f 1 -d ' ' >&6) | cut -f 2- -d' ' ; }
by_date()   { sort $show_reversed -n         | tee >(cut -f 2 -d ' ' >&6) | cut -f 3- -d' ' ; }
close_tab() { ((${#tabs[@]} > 1)) && { unset -v 'tabs[tab]' ; tabs=("${tabs[@]}") ; ((tab--)) ; R=$'\t' ; true ; } ; }
delete()    { prompt "delete$1? [y|d]: " -n1 && [[ $REPLY == y || $REPLY == d ]] && { rm -rf "${selection[@]}" ; tags=() ; mime=() ; cdir ; } ; }
dir()       { ((show_dirs)) && files d filter2 ; ((show_files)) && files f filter ; }
dsize()     { printf "\e[94m%4s\e[m" $(find "$1/" -mindepth 1 -maxdepth 1 ${show_hidden:+\( ! -iname '.*' \)} -type d,f,l -xtype d,f -printf "1\n" 2>/dev/null | wc -l) ; } 
edit()      { tcpreview ; echo -en '\e[?1049h' ; "${EDITOR}" "${files[file]}"; echo -en '\e[?1049h\e[?25h' ; cdir ; }
epane()     { [[ -d "$n" ]] && tsplit "$(ftl_cmd "$n")" "50%" "$1" "$2" || tsplit "$(ftl_cmd "$p")" "50%" "$1" "$2" ; epanes+=($pane_id) ; pane_id= ; }
ffind()     { [[ $1 == n ]] && { ((from= file + 1)) ; to=$nfiles ; inc='++' ; } || { ((from = file - 1)) ; to=-1 ; inc='--' ; } 
		for((i=$from ; i != $to ; i$inc)) ; do [[ "${files[i]##*/}" =~ "$to_search" ]] && { list $i ; return ; } ; done ; list ; }
files()     { find "$PWD/" -mindepth 1 -maxdepth $max_depth ${show_hidden:+\( ! -iname ".*" \)} -type $1,l -xtype $1 -printf "${find_formats[sort_type]}" 2>/dev/null | $2 ; }
filter()    { rg "${tfilters[tab]}" | rg "${filters[tab]}" | rg "${filters2[tab]}" | filter2 ; }
filter2()   { ${sort_filters[sort_type]} | tee >(cat >&4) | lscolors >&5 ; }
fsize()     { numfmt --to=iec --format '\e[94m%4f\e[m' $1 ; }
fsstate()   { printf "%s\n" "${selection[@]}" >${1:-$fs}/tags ; ((!nfiles)) && echo >${1:-$fs}/ftl || { echo "${files[file]}" >${1:-$fs}/ftl ; fsstate2 "$1" ; } ; }
fsstate2()  { echo -e "${dir_file[${files[file]}]}\n$imode\n$sort_type\n$show_size\n$show_dir_size\n${filters[tab]}" >>${1:-$fs}/ftl ; }
fzf_go()    { [[ "$1" ]] && cdir "$(dirname "$1")" "$(basename "$1")" || { refresh ; list ; } }
fzf_tag()   { [[ "$1" ]] && while read f ; do tags[$PWD/$f]='▪' ; done <<<$1 ; }
header()    { h="${@} $((tab+1))/${#tabs[@]} $filter_tag${sort_name[sort_type]}$show_reversed ${#tags[@]}" ; header_pos "$h" ; echo -e "\e[K\e[94m${PWD:hpl} \e[95m${h:hal}\e[m" ; }
header_pos(){ hal=$((${#1} - ($COLS - 1))) ; hpl=$((${#PWD} + (hal < 0 ? hal : 0) )) ; ((hal = hal < 0 ? 0 : hal, hpl = hpl < 0 ? 0 : hpl)) ; }
location()  { true 2>/dev/null >&3 && { [[ $REPLY == 'Q' ]] && echo "${files[file]}" >&3 || :>&3 ; } ; }
mkapipe()   { for n in "$@" ; do PIPE=$(mktemp -u) && mkfifo $PIPE && eval "exec $n<>$PIPE" && rm $PIPE ; done ; }
move()      { ((nf = file + $1, nf = nf < 0 ? 0 : nf > nfiles - 1 ? nfiles - 1 : nf)) ; dir_file[$PWD]=$nf ; list ; }
movep()     { ((in_vipreview)) && tmux send -t $pane_id C-$1 ; }
my_pane()   { while read -s pi pp ; do _my_pane $pp && my_pane=$pi && break ; done < <(tmux lsp -F '#{pane_id} #{pane_pid}') ; }
_my_pane()  { [[ $$ == $1 ]] || [[ $(ps -o pid --no-headers --ppid $1 | rg $$) ]] ; }
parse_path(){ n="${files[file]}" ; p="${n%/*}" ; f="${n##*/}" ; b="${f%.*}" ; [[ "$f" =~ '.' ]] && e="${f##*.}" || e= ; }
prompt()    { stty echo ; echo -ne '\e[999B\e[0;H\e[K\e[33m\e[?25h' ; read -rp "$@" ; echo -ne '\e[m' ; stty -echo ; }
quit()      { wcpreview ; tcpreview ; fsstate "/tmp/ftl" ; rm -rf $fs ; location ; stty echo ; tbcolor 236 52 ;  refresh "\e[?25h\e[?1049l"
		kepanes ; kill $w3iproc &>/dev/null ; ((exit_mplayer)) && kmplayer ; tmux killp -t $shell_id &> /dev/null ; exit 0 ; }
refresh()   { echo -ne "\e[?25l\e[2J\e[H\e[m$1" ; }
rg_go()     { [[ "$1" ]] && { g=${1%%:*} && nd="$PWD/"$(dirname "$g") && cdir "$nd" "$(basename "$g")" ; } || { refresh ; list ; } ; }
run_maxed() { run_maxed=1 ; ((run_maxed)) && { aw=$(xdotool getwindowfocus -f) ; xdotool windowminimize $aw ; } ; "$@" ; ((run_maxed)) && { wmctrl -ia $aw ; } ; }
selection() { selection=() ; ((${#tags[@]})) && selection+=("${!tags[@]}") || { ((nfiles)) && selection=("${files[file]}") ; } ; }
shell()     { tcpreview ; echo -en '\e[?1049h' ; parse_path ; s="${selection[@]}" ; shellrun ; read -sn 1 ; echo -en '\e[?1049l' ; }
shellrun()  { [[ $REPLY =~ "\$s" ]] && { eval "$REPLY" ; echo '$?': $? ; } || for n in "${selection[@]}" ; do eval "$REPLY" ; echo '$?': $? ; done ; } 
synch()     { { for r in pdir pindex pimode sort_type show_size show_dir_size pfilter ; do read $r ; done ; } < $parent_fs/ftl
		 filter[tab]="$pfilter" ; [[ $pfilter ]] && filter="~" ; ftl_imode "$pimode" ; tag_read "$parent_fs" ; cdir "$pdir" '' "$pindex" ; }
tag_flip()  { [[ ${tags[$1]} ]] && unset -v 'tags[$1]' || tags[$1]='▪' ; } 
tag_read()  { tags=() ; IFS=$'\n' readarray -t stags < "$1/tags" ; for stag in "${stags[@]}" ; do tags[${stag//\\ / }]='▪' ; done ; }
tbcolor()   { tmux set pane-border-style "fg=color$1" ; tmux set pane-active-border-style "fg=color$2" ; sleep 0.01 ; }
ftl "$@"
