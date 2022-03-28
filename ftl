#!/bin/env bash
cdf() { d=/tmp/$USER/ftl ; l=$d/cdf ; mkdir -p $d ; ftl 3> >(cat > $l) ; cd "$(cat $l)" &>/dev/null; } ; [[ ${BASH_SOURCE[0]} != $0 ]] && return ;

externals() { echo edir eimage emedia epdf ehtml etext ; }
previewers(){ echo plock pdir pignore pmp4 pimage pmedia ppdf phtml mime_get pperl pshell ptext ptar pcbr ptype ; }
declare -A K=( [a]=ª [b]=” [c]=© [d]=ð [e]=€ [f]=đ [g]=ŋ [h]=ħ [i]=→ [k]=ĸ [l]=ł [m]=µ [o]=œ [p]=þ [q]=@ [r]=® [s]=ß [t]=þ [u]=↓ [v]=“ [x]=» [y]=← [z]=« [.]=· [6]=¥) \
           SK=([a]=º [b]=’ [c]=© [d]=Ð [e]=¢ [f]=ª [g]=Ŋ [h]=Ħ [i]=ı [k]=  [l]=Ł [m]=º [o]=Œ [p]=Þ [q]=Ω [r]=® [s]=§ [t]=Þ [u]=↑ [v]=‘ [x]=  [y]=¥ [z]=  [.]=˙ [6]=⅝ [/]=÷)

ftl() # directory, search, pfs, preview. © Nadim Khemir 2020-2022, Artistic licence 2.0
{
: ${preview_all:=1} ; : ${pdir_only:=} ; : ${find_auto:=README} ; exit_mplayer= ; max_depth=1 ; tab=0 ; tabs+=("$PWD") ; ntabs=1 ; : ${imode:=0} ; : ${zoom:=0} ; zooms=(70 50 30) 
tbcolor 67 67 ; quick_display=256 ; cursor_color='\e[7;34m' ; show_dirs=1 ; show_files=1 ; : ${show_line:=1} ; show_size=0 ; show_date=1 ; show_tar=0 ; etag=0
ifilter='webp|jpg|jpeg|JPG|png|gif'; : ${sort_type:=0} ; sort_filters=(by_name by_size by_date) ; sort_name=( ⍺ 🡕 ≣ ) ; imode_glyph=(⁺ ᴵ ᴺ) ; GPGID= ; 

mkapipe 4 5 6 ; declare -A dir_file pignore lignore fexts tail tags ftl_env marks=([0]=/ [1]="$HOME") ; . ~/.ftlrc || . ~/.config/ftl/ftlrc ; ftl_root=/tmp/$USER/ftl ; dir_done=9d0471 
echo -en '\e[?1049h'  ; stty -echo ; my_pane=$(pid_2_pane $$) ; thumbs=$ftl_root/thumbs ; mkdir -p $thumbs ; pushd "$dir" &>/dev/null
[[ "$1" ]] && { [[ -d "$1" ]] && dir="$1" ; search="$2" ; } || { [[ -f $1 ]] && dir=$(dirname "$1") ; search="${2:-${1##*/}}" ; } || { echo ftl: \'$1\', no such path ; exit 1 ; }
[[ "$3" ]] && { fs=$3/$$ ; pfs=$3 ; mkdir -p $fs ; } || { fs=$ftl_root/$$ ; pfs=$fs ; main=1 ; mkdir -p $fs ; echo $my_pane >$fs/pane ; }
[[ "$4" == 1 ]] && { gpreview=1 ; preview_all=0 ; external=0 ; synch $pfs/ftl "$search" ; } || cdir "$dir" "$search"

while : ; do ((winch++, winch>15)) && { winch && continue ; } ; { [[ "$R" ]] && { REPLY="${R:0:1}" ; R="${R:1}" ; } || read -sn 1 -t 0.1 ; } && { ext_bindings || bindings ; } ; done 
}

bindings()
{
case "${REPLY: -1}" in
	\?     ) tmux popup -h 90% -w 70% -E "$EDITOR -R ~/.config/ftl/help" ;;
	h|D    ) [[ "$PWD" != / ]]  && { nd="${PWD%/*}" ; cdir "${nd:-/}" "$(basename "$p")"; } ;;
	j|B|k|A) ((nfiles)) && { [[ $REPLY == j || "$REPLY" == B ]] && move 1 || move -1 ; } ;;
	l|C|'' ) ((nfiles)) && { [[ -f "${files[file]}" ]] && { [[ $REPLY == '' ]] && edit ; true ; } ||  cdir "${files[file]}" ; } ;;
	5|6    ) [[ $REPLY == 5 ]] && move -$LINES || move $LINES ;;
	J|K    ) [[ $REPLY == K ]] && movep U || movep D ;;
	0      ) ((gpreview)) && kbd_flush && synch $pfs/ftl || cdir "$PWD" "$f" ;;
	7      ) ((main)) && list ; sleep 0.01 ; pane_read ; ((${#panes[@]})) && tmux selectp -t ${panes[0]} || tmux selectp -t $my_pane ;;
	8      ) ((gpreview)) && read n <$pfs/ftl && cdir "$n" ;;
	9      ) ((preview_all)) && { kbd_flush ; rdc=8 ; op=$(tmux display -p '#{pane_id}') ; read n <$fs/ftl ; path "$n" ; geo_prev ; preview 1 ; path ; tmux selectp -t $op ; rdc=; } ;;
	a      ) mplayer_k ;;
	b|n|N  ) how=$REPLY ; [[ $how == 'b' ]] && { prompt "find: " -e to_search ; how=n ; } ; ffind $how ;;
	/      ) tcpreview ; fzf_go "$({ fd . -H -I -d1 -td | sort | lscolors ; fd . -H -I -d1 -tf | sort | lscolors ; } | fzf_vpreview)" ;;
	${SK[/]}) tcpreview ; fzf_go "$(fd . -H -I -E'.git/*' | lscolors | fzf_vpreview)" ;;
	${K[b]}) tcpreview ; fzf_go "$(fd . -td --no-ignore --color=always -L | sort | fzf_vpreview)" ;;
	c      ) prompt 'cp to: ' -e && [[ $REPLY ]] && { copy "$REPLY" "${selection[@]}" ; tags=() ; } ; cdir ;;
	${K[c]}) [[ $f =~ \.tar ]] && tar -xf "$f" || { prompt 'tar.bz2 file: ' -e ; [[ -n $REPLY ]] && tar -cvjSf $REPLY.tar.bz2 "${selection[@]}" ; } ; tags=() ; cdir '' "$REPLY" ;;
	d      ) ((${#tags[@]})) && delete " (${#tags[@]} selected)" || delete ;;
	${K[d]}) filters[tab]= ; filters2[tab]= ; rfilters[tab]= ; ntfilter= ; fexts=() ; eval "ftl_filter(){ cat ; }" ; filter_tag= ; tcpreview ; cdir ;;
	e      ) cdir "$(tac $ftl_root/history 2>&- | awk '!seen[$0]++' | lscolors | fzf-tmux -p 80% --ansi --info=inline --layout=reverse)" ;;
	E      ) cdir "$(tac $fs/history 2>&- | awk '!seen[$0]++' | lscolors | fzf-tmux -p 80% --ansi --info=inline --layout=reverse)" ;;
	${K[e]}) prompt 'clear global history? [y|N]' -sn1 && [[ $REPLY == y ]] && rm $ftl_root/history 2>&- ; list ;;
	f      ) prompt "filter: " -ei "${filters[tab]}" ; filters[tab]="$REPLY" ; filter_tag="~" ; dir_file[$PWD]= ; tcpreview ; cdir '' ;;
	F      ) prompt "filter2: " -ei "${filters2[tab]}" ; filters2[tab]="$REPLY" ; filter_tag="~" ; dir_file[$PWD]= ; tcpreview ; cdir '' ;;
	${K[f]}) p=~/.config/ftl/external_filters ; file=$(cd $p ; fd | fzf-tmux --reverse --info=inline) ; [[ $file ]] && . $p/$file $fs ; cdir ;;
	${K[6]}) prompt "rfilter: " -ei "${rfilters[tab]}" ; rfilters[tab]="$REPLY" ; filter_tag="~" ; dir_file[$PWD]= ; tcpreview ; cdir '' ;;
	g|G    ) [[ $REPLY == G ]] && ((dir_file["$PWD"] = nfiles - 1)) || dir_file["$PWD"]=0 ; list ;;
	${K[g]}) prompt 'cd: ' -e ; [[ -n $REPLY ]] && cdir "${REPLY/\~/$HOME}" || list ;;
	${K[i]}) tcpreview ; fzf_go "$(fzfi -q "$(echo "$ifilter" | perl -pe 's/(^|\|)/ $1 ./g')")" ;;
	i      ) prompt 'touch: ' && [[ "$REPLY" ]] && touch "$PWD/$REPLY" ; cdir "$PWD" "$REPLY" ;;
	I      ) prompt 'mkdir: ' && [[ "$REPLY" ]] && mkdir -p "$PWD/$REPLY" ; cdir "$PWD/$REPLY" ;;
	${K[k]}) prompt 'clear persistent marks? [y|N]' -sn1 && [[ $REPLY == y ]] && :>$fs/../marks ; list ;;
	\,     ) { cat $fs/../marks 2>&- ; echo "$n" ; } | awk '!seen[$0]++' | sponge $fs/../marks ;;
	\;     ) tcpreview ; fzf_go "$(cat $fs/../marks | lscolors | fzf --ansi --info=inline --layout=reverse)" ;;
	\´     ) tcpreview ; fzf_go "$(printf "%s\n" "${marks[@]}" | sort -u | lscolors | fzf --ansi --info=inline --layout=reverse)" ;; #altgr \'
	L      ) ((${#tags[@]})) && prompt "Link (${#tags[@]})? [y|N]" -sn1 ; [[ $REPLY == y ]] && { for f in "${selection[@]}" ; do ln -s -b "$f" "$PWD" ; done ; tags=() ; } ; cdir ;;
	${K[l]}) rm "$fs/lock_preview/$n" 2>&- ; list ;;
	${SK[l]}) p=~/.config/ftl/lock_preview ; file=$(cd $p ; fd | fzf-tmux --reverse --info=inline) ; [[ $file ]] && . $p/$file ; list ;;
	M      ) ((imode--)) ; ((imode < 0)) && imode=2 ; ((imode == 2)) && ftl_nimode || ftl_imode $imode ; cdir ;;
	m      ) read -sn1 ; [[ -n $REPLY ]] && marks[$REPLY]="${files[file]}" ; list ;;
	${K[m]}) p=~/.config/ftl/merge ; file=$(cd $p 2>&- && fd | fzf-tmux --header 'Merge tags:' --cycle --reverse --info=inline) ; [[ $file ]] && . $p/$file ; cdir ;;
	${SK[m]}) mutt $([[ ${#selection[@]} ]] && printf "\055a %s\n" "${selection[@]}" || [[ $f ]] && echo "-a $f") -s 'ftl files' -- ; refresh ; list ;;
	o      ) ((sort_type++, sort_type = sort_type >= ${#sort_filters[@]} ? 0 : sort_type)) ; cdir ;;
	O      ) [[ $reversed ]] && reversed= || reversed=-r ; cdir ;;
	p|P    ) ((${#tags[@]})) && { [[ $REPLY == p ]] && copy "$PWD" "${!tags[@]}" || tscommand "mv $(printf "'%s' " "${!tags[@]}") '$PWD'" ; tags=() ; cdir ; } ;;
	r      ) cdir "$PWD" "$f" ;; # directory content change signal
	${K[r]}) rm "$n/montage.png" 2>&- ; list ;;
	R      ) ((${#tags[@]})) && bulkrename || { prompt "rename ${files[file]##*/} to: " && [[ $REPLY ]] && mv "${files[file]}" "$REPLY" ; } ; cdir ;;
	${K[s]}) ((show_size ^= 1)) || { ((show_size ^= 1)) ; ((show_dir_size ^= 1)) ; } || show_size=0 ; cdir ;;
	\$     ) (($in_vipreview)) && in_vipreview= && pane_id= && cdir ;;
	t|${K[t]}) sdir= ; [[ $REPLY == t ]] && sdir='-d1' ; fzf_tag T "$(fd . -H --color=always $sdir | fzf-tmux -p 90% -m --ansi --info=inline --layout=reverse --marker '▪')" ; list ;;
	T      ) fzf_tag U "$(cat $fs/tags | lscolors | fzf-tmux -p 90%  -m --ansi --info=inline --layout=reverse --marker '⊟')" ; list ;;
	${SK[t]}) [[ "${tail[$n]}" ]] && unset -v "tail[$n]" || tail[$n]='+$ ' ; list ;;
	u|U    ) [[ $REPLY == u ]] && for p in "${files[@]}" ; do tags["$p"]='▪' ; done || tags=() ; list ;;
	${K[u]}) tcpreview ; fzf_go "$(printf "%s\n" "${!tags[@]}" | sort -u | lscolors | fzf --ansi --info=inline --layout=reverse)" ;;
	v|V    ) [[ $REPLY == V  ]] && preview=1 || ((preview_all ^= 1)) ; ((${preview:-$preview_all})) || tcpreview ; cdir ;;
	${K[v]}) [[ "$montage_preview" ]] && montage_preview= || montage_preview="⠶ " ; list ;;
	+      ) ((zoom += 1, zoom >= ${#zooms[@]})) && zoom=0 ; zoom ; [[ $pane_id ]] && tresize $pane_id $x || cdir ;; 
	\=     ) [[ "$pdir_only" ]] && pdir_only= || pdir_only='- ' ; list ;;
	\#     ) [[ $e ]] && { ((pignore[${e}] ^= 1)) ; cdir ; } ;;
	w      ) external=1 ; [[ $REPLY == W  ]] && detached=1 ; list ;;
	W      ) p=~/.config/ftl/viewers ; viewer=$(cd $p 2>&- && fd | fzf-tmux --cycle --reverse --info=inline) ; [[ $viewer ]] && . $p/$viewer ;;
	x|X    ) [[ $REPLY == x ]] && mode=a+x || mode=a-x ; chmod $mode "${selection[@]}" ; cdir ;;
	${K[x]}) [[ $e =~ gpg ]] && tmux popup -h90% -w90% "gpg -d $n" || gpg -e -u "$GPGID" -r "$(gpg -K | grep uid | cut -d' ' -f 13- | fzf)" "$f" || read -sn1 ; cdir '' "$f.gpg" ;;
	y|Y    ) tag_flip "${files[file]}" ; { [[ $REPLY == Y ]] && R="k$R" || R="j$R" ; } ; list ;;
	${K[y]}) cat $fs/tags | xsel -b -i ;; 
	q|Q|\@ ) tab_close || pane_close || quit ;;
	Z      ) ((main)) && { pane_read && for p in "${panes[@]}" ; do tmux send -t $p Z &>/dev/null ; done ; } ; exit_mplayer=1 ; quit ;;
	z      ) quit2 ; [[ $pane_id ]] && { tmux selectp -t $pane_id ; tmux resizep -Z -t $pane_id ; } ; exit 0 ;;
	${K[z]}) [[ $e =~ gpg ]] && prompt 'file: ' -e && [[ -n "$REPLY" ]] && gpg -d "$n" > "$REPLY" || gpg --output "$f.gpg" --symmetric "$f" || read -sn1 ; cdir '' "$REPLY" ;;
	${SK[s]}|$'\t') [[ $REPLY == ${SK[s]} ]] && { tabs+=("$PWD") ; ((tab = ${#tabs[@]} - 1)) ; ((ntabs++)) ; } || ((ntabs > 1)) && { tab_next ; cdir ${tabs[tab]} ; } ;;
	½      ) tcpreview ; tsplit "ftl ${files[file]} '' '' 0" 50% -h -R ; ftl2_pane=$pane_id ; pane_id= ; cdir ; tmux send -t $ftl2_pane v ;;
	\:     ) prompt ':' ; [[ $REPLY =~ -?[0-9]+ ]] && list $((REPLY > 0 ? (REPLY -1) : 0)) || shell_command "$REPLY" ;; 
	\'     ) read -n 1 ; [[ -n ${marks[$REPLY]} ]] && cdir "$(dirname ${marks[$REPLY]})" "$(basename ${marks[$REPLY]})" || list ;;
	\"     ) ((no_image_preview ^= 1)) ; for e in $(tr '|' ' ' <<< "$ifilter") ; do pignore[${e}]=$no_image_preview ; done ; ((zoom == 0)) && R="-$R" ; cdir ;;
	\%|\&  ) [[ $REPLY == \% ]] && { [[ $e ]] && ((lignore[${e}] ^= 1)); } || lignore=() ; cdir ;;
	\*     ) prompt 'depth: ' && [ "$REPLY" -eq "$REPLY" ] 2>&- && max_depth=$REPLY && cdir ;;
	.      ) ((show_hidden)) && show_hidden= || show_hidden=1 ; cdir ;;
	${K[.]}) ((etag^=1)) ; cdir ;;
	\{     ) tcpreview ; fzf_go "$(fzfppv -L)" ;;
	\}     ) tcpreview ; rg_go "$(fzfr)" ;;
	s|S    ) [[ $shell_id ]] && tmux selectp -t $shell_id &>/dev/null || shell_pane ; [[ $REPLY == S ]] && tmux resizep -Z -t $shell_id ;;
	\!     ) tcpreview ; cmd=$(cat $ftl_root/commands | awk '!seen[$0]++' | fzf --tac --info=inline --layout=reverse)
		 prompt 'ftl> ' -ei "$cmd" ; [[ $REPLY ]] && { echo $REPLY >>$ftl_root/commands ; shell ; } ; cdir ;;
	\-     ) pane_read ; tp=("${panes[@]}" $main_pane "${panes[@]}") ; pf=0 ;
			for p in "${tp[@]}" ; do [[ $p == $my_pane ]] && pf=1 || { ((pf)) && tmux selectp -t $p &>/dev/null && tpop $p && tmux send -t $p r && break ; } ; done ;;
	\<     ) pane_extra "-h -b" '' "$(dirname "$PWD")" "$(basename "$PWD")" ;;
	\>     ) pane_ftl "'$PWD' '$f' $pfs 0" "-h -b" -R ; [[ "$n" ]] && cdir "$n" ; tmux send -t $my_pane r ;;
	\¦|_|\|) pfm= ; pfn= ; [[ $REPLY == \¦ ]] && { pfm='-h -b' ; pfn=-R ; } ; [[ $REPLY == \_ ]] && pfm='-v' ; pane_extra "$pfm" "$pfn" ;;
	\^     ) ((show_stat ^= 1)) ; refresh ; list ;;
	\)     ) ((show_files ^= 1)) || { ((show_file ^= 1)) ; ((show_dirs ^= 1)) ; } || show_files=0 ; ((show_files || show_dirs)) || { show_files=1 ; show_dirs=0 ; } ; cdir ;;
esac
}

cdir() { inotify_k ; get_dir "$@" ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; refresh ; list "${3:-$found}" ; inotify_s ; }
get_dir() # dir, search
{
new_dir="${1:-$PWD}" ; [[ -d "$new_dir" ]] || return ; [[ "$PPWD" != "$PWD" ]] && { PPWD="$PWD" ; marks[$'\'']="$PPWD/$" ; } ; PWD="$new_dir" ; tabs[tab]="$PWD"
files=() ; files_color=() ; mime=() ; nfiles=0 ; search="${2:-$(((dir_file[$PPWD])) || echo "$find_auto")}" ; found= ; shopt -s nocasematch ; geo_prev

cd "$PWD" 2>$fs/error || { refresh ; cat $fs/error ; return ; } ; ((etag)) && ext_dir
((gpreview)) || echo "$PWD" | tee -a $fs/history >> $ftl_root/history ; [[ "$PWD" == / ]] && sep= || sep=/

declare -A uniq_file ; pad=(*) ; pad=${#pad[@]} ; pad=${#pad} ; line=0 ; sum=0 ; local LANG=C LC_ALL=C ; dir &
while : ; do read -s -u 4 p ; [ $? -gt 128 ] && break ; read -s -u 5 pc ; read -s -u 6 size
	[[ $p == $dir_done ]] && break ; ((${uniq_file[$p]})) && continue ; uniq_file[$p]=1
	((quick_display && nfiles > 0 && 0 == nfiles % quick_display)) && { refresh ; list $found ; in_quick_display=1 ; }
	[[ "$p" =~ '.' ]] && { e=${p##*.} ; ((lignore[${e@Q}])) && continue ; } ; pl=${#p}
	
	((etag)) && { ext_tag "$p" external_tag external_tag_length ; pc="$external_tag$pc" ; ((pl+=external_tag_length)) ; }
	((show_size)) && { ((sum += size)) ; [[ -d "$p" ]] && { ((show_dir_size)) && pc=$(dsize "$p")" $pc" || pc="     $pc" ; } || pc=$(fsize $size)" $pc" ; pl=$((pl + 5)) ; }
	((show_line)) && { ((line++)) ; printf -v pc "\e[2;30m%-${pad}d\e[m ${pc/\%/%%}" $line ; ((pl += 4)) ; }
	pcl=${pc:0:(( ${#pc} == $pl ? ($COLS - 1) : ( (${#pc} - 4) - $pl ) + ($COLS - 1) )) }
	((${#p} > ($COLS - 1))) && { [[ "$p" =~ '.' ]] && e=….${p##*.} || e=… ; pcl=${pcl:0:((${#pcl} - ${#e}))}${e} ; }
	files_color[$nfiles]="$pcl" ; files[$nfiles]="$PWD$sep$p" ; [[ -n "$search" && -z "$found" ]] && [[ "$p" =~ ^$search ]] && found=$nfiles ; ((nfiles++))
done 

shopt -u nocasematch ; in_quick_display=0 ; ((show_size)) && hsum=$(numfmt --to=iec --format ' %4f' "$sum") || hsum=
}

list() # select
{
[[ $1 ]] && dir_file[$PWD]=$1 ; file=${dir_file[$PWD]:-0} ; ((file = file > nfiles - 1 ? nfiles - 1 : file)) ; selection ; sstate $fs
((nfiles)) && path || { header "\e[33m<Empty>" && tcpreview && return ; }
((top = nfiles < lines || file <= center ? 0 : file >= nfiles - center ? nfiles - lines : file - center)) ; geo_winch 
 
((show_stat)) && stat="$(stat -c ' %A %U' "${files[file]}") $(stat -c %s "${files[file]}" | numfmt --to=iec --format '%4f')" || stat= ; T= ; ((ntabs>1)) && T=" ᵗ$ntabs" ; 
header "${pdir_only}${imode_glyph[$imode]}$hsplit$montage_preview $((file+1))/${nfiles}$hsum$stat"$(((sort_type == 2 && show_date)) && date -r "${files[file]}" +" %D-%R")"$T"

for((i=$top ; i <= ((bottom = top + lines - 1, bottom < 0 ? 0 : bottom)) ; i++))
	do
		cursor=${tags[${files[$i]}]:- } ; [[ $i == $file ]] && cursor="$cursor_color$cursor\e[m"
		echo -ne "\e[K$cursor${files_color[i]}" ; ((i != bottom)) && echo
	done

((in_quick_display)) || { geo_winch ; preview ; }
}

preview()
{
((main || gpreview || preview_all)) || { kbd_flush ; pane_read ; sstate $pfs ; tmux send -t $main_pane 9 &>/dev/null ; return ; }

old_in_vipreview=$in_vipreview
((external)) && { for external in $(externals) ; do $external && { sleep 0.01 ; list ; return ; } ; done ; } ; external= ; detached= ; 
((${1:-${preview:-$preview_all}})) && { preview= ; for v in $(previewers) ; do $v && geo_winch && vcpreview && return ; done ; }
tcpreview
}

edir()      { [[ -d "$n" ]] && {  vlc "$n" &>/dev/null & } ; }
ehtml()     { [[ $e == 'html' ]] && { ((detached)) && { (qutebrowser "$n" 2>&- &) ; } || { tcpreview ; w3m -o confirm_qq=0 "$n" ; } ; } ; } 
eimage()    { [[ $e =~ ^($ifilter)$ ]] && run_maxed fim -a "$n" "$PWD" ; }
emedia()    { [[ $e =~ ^(mp3|mp4|flv|mkv)$ ]] && { ((! detached)) && { mplayer_k ; mplayer -vo null "$n" </dev/null &>/dev/null & } && mplayer=$! || vlc "$n" &>/dev/null & } ; }
epdf()      { [[ $e == pdf ]] && { ((detached)) && (zathura "$n" &) || run_maxed zathura "$n" ; true ; } ; }
etext()     { tcpreview ; tsplit "$EDITOR ${n@Q}" "33%" '-h -b' -R ; pane_id= ; }
pcbr()      { [[ $e =~ ^(cbr)$ ]] && { t="$thumbs/$b.$e.jpg" ; { [[ -e $t ]] || cbconvert thumbnail "$n" --outfile "$t" &>/dev/null ; } ; [[ -e $t ]] && pw3image "$t" ; } ; }
pdir()      { [[ -d "$n" ]] && { pdir_image || pdir_dir "$n" ; } || { in_pdir= ; pdir_only ; } ; }
pdir_dir()  { ((in_pdir)) && [[ $pane_id ]] && tmux send -t $pane_id ${rdc:-0} || { tmux selectp -t $my_pane ; ctsplit "ftl ${1@Q} '' $fs 1" ; in_pdir=1 ; sleep 0.1 ; } ; }
pdir_image(){ [[ "$montage_preview" ]] && { in_pdir= ; [[ -e "$n/montage.png" ]] || do_montage "$n" ; [[ -e "$n/montage.png" ]] && pw3image "$n/montage.png" ; } ; }
do_montage(){ < <(IFS='\n' fd -a -t f -e ${ifilter//|/ -e} -d 1 . "$1" | head -n 30) mapfile -t args ; ((${#args[@]})) && montage "${args[@]}" "$1/montage.png" ; }
pdir_only() { [[ "$pdir_only" ]]  && { tcpreview ; true ; } || false  ; }
phtml()     { [[ $e == 'html' ]] &&  w3m -dump "$n" > "$fs/$f.txt" && vipreview "$fs/$f.txt" ; }
pignore()   { [[ $e ]] && ((pignore["${e@Q}"])) && { mime_get ; in_pdir= ; in_vipreview= ; ptype ; true ; } || false ; }
pimage()    { [[ $e =~ ^($ifilter)$ ]] &&  pw3image ; }
plock()     { [[ -e "$fs/lock_preview/$n" ]] && vipreview "$fs/lock_preview/$n" ; }
pmedia()    { [[ $e =~ ^(mp3|mkv)$ ]] && { t="$thumbs/et_$(head -c50000 "$n" | md5sum | cut -f1 -d' ')" ; [[ -e $t ]] || exiftool "$n" >$t ; ctsplit "/bin/less <$t ; read -sn1" ; } ; }
pmp4()      { [[ $e =~ mp4|flv ]] && { t="$thumbs/$f.jpg" ; [[ -f "$t" ]] || ffmpegthumbnailer -i "$n" -o "$t" -s 1024 ; pw3image "$t" ; true ; } ; }
pshell()    { [[ $mtype == 'application/x-shellscript' ]] && vipreview "$n" ; }
ppdf()      { [[ $e == 'pdf' ]] && { pdftotext -l 3 "$n" "$fs/$f.txt" 2>&- && vipreview "$fs/$f.txt" ; } ; }
pperl()     { [[ $mtype =~ ^application/x-perl$ ]] && [[ -s "$n" ]] && vipreview "$n" ; }
ptext()     { { [[ $e =~ ^json|yml$ ]] || [[ $mtype =~ ^text ]] ; } && [[ -s "$n" ]] && vipreview "$n" ; }
ptar()      { [[ $f =~ \.tar ]] && ((show_tar)) && { fp="$fs/$f.txt" ; [[ -e "$fp" ]] || timeout 1 tar --list --verbose -f "$f" >"$fp" ; vipreview "$fp" ; } ; }
ptype()     { ctsplit "echo $f ; echo $mtype ; file -b ${n@Q} ; stat -c %s ${n@Q} | numfmt --to=iec ; read -sn 100" ; }
pw3image()  { ((in_ftli)) &&  { tmux send -t $pane_id $n C-m ; } || { ctsplit "ftli '${1:-$n}'" ; in_ftli=1 ; } ; sleep 0.05 ; tmux selectp -t $my_pane ; }
tcpreview() { [[ "$pane_id" ]] && { tmux killp -t $pane_id &> /dev/null ; in_pdir= ; pane_id= ; in_vipreview= ; in_ftli= ; sleep 0.01 ; } ; }
vipreview() { ((in_vipreview)) && { tmux send -t $pane_id ":e ${tail[$1]}$(sed -E 's/\$/\\$/g' <<<"$1")" C-m ; } || ctsplit "$EDITOR -R ${tail[$1]}${1@Q}" ; ((in_vipreview++)) ; true ; }
vcpreview() { ((old_in_vipreview == in_vipreview)) && in_vipreview= ; true ; }
bulkrename(){ tcpreview ; bulkedit && bulkverify && { bash $fs/br && tags=() || read -sn 1 ; } ; true ; }
bulkedit()  { cat $fs/tags | tee $fs/bo > $fs/bd ; $EDITOR $fs/bd ; }
bulkverify(){ echo 'set -e' > $fs/br ; paste $fs/bo $fs/bd | sed 's/^/mv /' >> $fs/br ; $EDITOR $fs/br ; }
by_name()   { sort $reversed -t ' ' -k3 | tee >(cut -f 1 >&6) | cut -f 3- ; }
by_size()   { sort $reversed -n         | tee >(cut -f 1 >&6) | cut -f 3- ; }
by_date()   { sort $([[ -z "$reversed" ]] && echo '-r') -t ' ' -k2 | tee >(cut -f 1 >&6) | cut -f 3- ; }
ctsplit()   { ((in_ftli)) && tcpreview ; { in_pdir= ; in_vipreview= ; in_ftli= ; } ; [[ $pane_id ]] && ((!in_ftli)) && tmux respawnp -k -t $pane_id "$1" &> /dev/null || tsplit "$1" ; }
copy()      { [[ -d "$1" ]] && dir=r || dir= ; tscommand "cp -v$dir $(printf "'%s' " "${@:2}") '$1'" ; } 
delete()    { prompt "delete$1? [y|d|N]: " -n1 && [[ $REPLY == y || $REPLY == d ]] && { rip "${selection[@]}" ; tags=() ; mime=() ; cdir ; } ; }
dir()       { ((show_dirs)) && files "-type d,l -xtype d" filter2 ; files "-xtype l" filter ; ((show_files)) && files "-type f,l -xtype f" filter ; dir_done ; }
dir_done()  { echo "$dir_done" >&4 ; echo '' >&5 ; echo 0 >&6 ; }
dsize()     { printf "\e[94m%4s\e[m" $(find "$1/" -mindepth 1 -maxdepth 1 ${show_hidden:+\( ! -iname '.*' \)} -type d,f,l -xtype d,f -printf "1\n" 2>&- | wc -l) ; } 
edit()      { tcpreview ; echo -en '\e[?1049h' ; inotify_k ; "${EDITOR}" "${1:-${files[file]}}"; echo -en '\e[?1049h\e[?25h' ; cdir ; }
ffind()     { [[ $1 == n ]] && { ((from = file + 1)) ; to=$nfiles ; inc='++' ; } || { ((from = file - 1)) ; to=-1 ; inc='--' ; }
		for ((i=$from ; i != $to ; i$inc)) ; do [[ "${files[i]##*/}" =~ "$to_search" ]] && { list $i ; return ; } ; done ; list ; }
files()     { find "$PWD/" -mindepth 1 -maxdepth $max_depth ${show_hidden:+\( ! -path "*/.*" \)} $1  -printf '%s\t%T@\t%P\n' 2>&- | ftl_filter | $2 ; }
filter()    { rg $ntfilter "${tfilters[tab]}" | rg "${filters[tab]}" | rg "${filters2[tab]}" | { [[ "${rfilters[tab]}" ]] && rg -v "${rfilters[tab]}" || cat ; } | filter2 ; }
filter2()   { ${sort_filters[sort_type]} | tee >(cat >&4) | lscolors >&5 ; }
fsize()     { numfmt --to=iec --format '\e[94m%4f\e[m' $1 ; }
ftl_env()   { ftl_env[ftl_pfs]=$pfs ; ftl_env[ftl_fs]=$fs ; for i in "${!ftl_env[@]}" ; do printf -- "${1:--e }$i=${ftl_env[$i]} " ; done ; }
ftl_imode() { (($1)) && { ntfilter= ; tfilters[tab]="$ifilter$" ; dir_file[$PWD]= ; } || tfilters[tab]= ; }
ftl_nimode(){ tfilters[tab]="$ifilter$" ; ntfilter='-v' ; dir_file[$PWD]= ; }
fzf_go()    { [[ "$1" ]] && { [[ -d "$1" ]] && cdir "$1" || cdir "$(dirname "$1")" "$(basename "$1")" ; } || { refresh ; list ; } ; }
fzf_tag()   { [[ "$2" ]] && while read f ; do [[ "$1" == U ]] && unset -v "tags[$f]" || tags[$PWD/$f]='▪' ; done <<<$2 ; }
geometry()  { read -r TOP WIDTH LINES COLS LEFT< <(tmux display -p -t $my_pane '#{pane_top} #{window_width} #{pane_height} #{pane_width} #{pane_left}') ; }
geo_prev()  { geometry ; ((${preview:-$preview_all})) && [[ -z $pane_id ]] && ((COLS=(COLS-1) * (100 - ${zooms[zoom]}) / 100)) ; }
geo_winch() { geometry ; WCOLS=$COLS ; WLINES=$LINES ; }
header()    { h="${@} $filter_tag${sort_name[sort_type]}$reversed ${#tags[@]}" ; header_pos "$h" ; echo -e "\e[H\e[94m${PWD:hpl} \e[95m${h:hal}\e[m" ; }
header_pos(){ hal=$((${#1} - ($COLS - 1))) ; hpl=$((${#PWD} + (hal < 0 ? hal : 0) )) ; ((hal = hal < 0 ? 0 : hal, hpl = hpl < 0 ? 0 : hpl)) ; }
inotify_s() { inotify_ & : ; ino1=$! ; ino2=$(ps --ppid $! | grep inotifywait | awk '{print $1}') ; }
inotify_()  { inotifywait --exclude index.lock -e create -e delete "$PWD/" &>/dev/null && tmux send -t "$my_pane" r 2>&- ; } 
inotify_k() { [[ $ino1 ]] && { kill $ino1 $ino2 2>&- ; ino1= ; ino2= ; } ; }
kbd_flush() { while read -t 0.01 ; do : ; done ; }
location()  { true 2>&- >&3 && { [[ $REPLY == 'Q' ]] && echo "${files[file]}" >&3 || :>&3 ; } ; }
mime_get()  { ((rdc)) && mtype=$(mimemagic "$n") || mime_cache ; false ; }
mime_cache(){ [[ ${mime[file]} ]] || mime+=($(mimemagic "${files[@]:${#mime[@]}:((file + 10))}" 2>&1 | sed -e "s/cannot.*/n\/a/" -e 's/^.*: //')) ; mtype="${mime[file]}" ; false ; }
mkapipe()   { for arg in "$@" ; do PIPE=$(mktemp -u) && mkfifo $PIPE && eval "exec $arg<>$PIPE" && rm $PIPE ; done ; }
move()      { ((nf = file + $1, nf = nf < 0 ? 0 : nf > nfiles -1 ? nfiles - 1 : nf)) ; ((nf != file)) && { dir_file[$PWD]=$nf ; list ; } || kbd_flush ; }
movep()     { ((in_vipreview)) && tmux send -t $pane_id C-$1 ; }
mplayer_k() { ((mplayer)) && kill $mplayer &>/dev/null || pkill mplayer ; } 
pane_extra(){ pane_ftl "'${3:-$n}' '$4' $pfs 0" "$1" "$2" ; list ; sleep 0.05 ; tmux selectp -t $new_pane ; }
pane_ftl()  { pane_read ; tcpreview ; tsplit "preview_all=0 ftl $1" 30% "$2" $3 ; panes+=($pane_id) ; new_pane=$pane_id ; pane_id= ; printf "%s\n" "${panes[@]}" >$pfs/panes ; }
pane_close(){ pane_read ; ((main && ${#panes[@]})) && { tmux send -t ${panes[0]} q 2>&- ; tail -n +2 $fs/panes | sponge $fs/panes ; } ; }
pane_event(){ pane_read ; ((${#panes})) && ((!main)) && tmux send -t $main_pane 7 ; }
pane_read() { <$pfs/pane read main_pane ; [[ -s $pfs/panes ]] && mapfile -t panes < <(grep -w -f <(tmux lsp -F "#{pane_id}") $pfs/panes) ; printf "%s\n" "${panes[@]}" >$pfs/panes ; }
path()      { n="${1:-${files[file]}}" ; p="${n%/*}" ; f="${n##*/}" ; b="${f%.*}" ; [[ "$f" =~ '.' ]] && e="${f##*.}" || e= ; }
pid_2_pane(){ while read -s pi pp ; do [[ $1 == $pp ]] || [[ $(ps -o pid --no-headers --ppid $pp | rg $$) ]] && echo $pi && break ; done < <(tmux lsp -F '#{pane_id} #{pane_pid}') ; }
prompt()    { stty echo ; echo -ne '\e[999B\e[0;H\e[K\e[33m\e[?25h' ; read -rp "$@" ; echo -ne '\e[m' ; stty -echo ; }
quit()      { tcpreview ; quit2 ; quit_shell ; tmux kill-session -t ftl$$ &>/dev/null ; pane_event ; rm -rf $fs ; exit 0 ; }
quit2()     { inotify_k ; location ; stty echo ; [[ $pfs == $fs ]] && tbcolor 236 52 ; ((exit_mplayer)) && mplayer_k ; kill $w3iproc &>/dev/null ; refresh "\e[?25h\e[?1049l" ; }
quit_shell(){ [[ $REPLY != @ ]] && [[ $shell_id ]] && tmux killp -t $shell_id &> /dev/null ; }
rdir()      { get_dir ; in_quick_display=1 ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; refresh ; list ; in_quick_display=0 ; }
refresh()   { echo -ne "\e[?25l\e[2J\e[H\e[m$1" ; }
rg_go()     { [[ "$1" ]] && { g=${1%%:*} && nd="$PWD/"$(dirname "$g") && cdir "$nd" "$(basename "$g")" ; } || { refresh ; list ; } ; }
run_maxed() { run_maxed=1 ; ((run_maxed)) && { aw=$(xdotool getwindowfocus -f) ; xdotool windowminimize $aw ; } ; "$@" ; ((run_maxed)) && { wmctrl -ia $aw ; } ; }
selection() { selection=() ; ((${#tags[@]})) && selection+=("${!tags[@]}") || { ((nfiles)) && selection=("${files[file]}") ; } ; }
shell()     { tcpreview ; echo -en '\e[?1049l' ; path ; s="${selection[@]}" ; shell_run ; read -sn 1 ; echo -en '\e[?1049h' ; }
shell_run() { [[ $REPLY =~ "\$s" ]] && { eval "$REPLY" ; echo '$?': $? ; } || for n in "${selection[@]}" ; do eval "echo -e '\e[7;34mftl\> $REPLY\e[m' ; $REPLY" ; echo '$?': $? ; done ; }
shell_pane(){ tcpreview ; opi=$pane_id ; tsplit /bin/bash 30% -v -U ; shell_id=$pane_id ; pane_id=$opi ; cdir ; tmux selectp -t $shell_id ; }
sstate()    { printf "%s\n" "${!tags[@]}" >$fs/tags ; ((!nfiles)) && echo >${1:-$fs}/ftl || { echo "${files[file]}" >${1:-$fs}/ftl ; sstateftl2 "${1:-$fs}" ; } ; }
sstateftl2(){ echo -e "${dir_file[${files[file]}]}\n$imode\n$etag\n$sort_type\n$show_size\n$show_dir_size\n${filters[tab]}\n${filters2[tab]}\n" >>$1/ftl ; }
synch()     { synch_read "$1" ; filters2[tab]="$pfil2" ; filters[tab]="$pfil" ; [[ $pfi ]] && filter_tag="~" ; ftl_imode "$pimode" ; tag_read "$1" ; cdir "$pdir" "$2" "$pindex" ; }
synch_read(){ [[ -e "$1" ]] && { for r in pdir pindex pimode etag sort_type show_size show_dir_size pfil pfil2 ; do read $r ; done ; } <$1 ; }
tab_close() { (($ntabs > 1)) && { tabs[$tab]= ; ((ntabs--)) ; tab_next ; cdir ${tabs[tab]} ; } ; }
tab_next()  { ((tab++)) ; for i in "${tabs[@]:$tab}" FTL_RESET "${tabs[@]}" ; do [[ "$i" == FTL_RESET ]] && tab=0 && continue ; [[ -n "$i" ]] && break ; ((tab++)) ; done ; }
tag_flip()  { [[ ${tags[$1]} ]] && unset -v 'tags[$1]' || tags[$1]='▪' ; } 
tag_read()  { tags=() ; [[ -e "$1/tags" ]] && { readarray -t stags < "$1/tags" ; for stag in "${stags[@]}" ; do tags[${stag//\\ / }]='▪' ; done ; } ; }
tbcolor()   { tmux set pane-border-style "fg=color$1" ; tmux set pane-active-border-style "fg=color$2" ; sleep 0.01 ; }
tpop()      { read -r PLEFT PTOP< <(tmux display -p -t $1 '#{pane_left} #{pane_top}') && tmux popup -E -h 3 -w 3 -x $PLEFT -y $(($PTOP + 3)) "sleep 0.07 ; true" ; }
tresize()   { tmux resizep -t $1 -x $2 &>/dev/null ; rdir ; }
tscommand() { tmux new -A -d -s ftl$$ ; tmux neww -t ftl$$ -d "echo ftl\> ${1@Q} ; $1 ; echo \$\?: $? ; read -sn2 -t 1800" ; }
tsplit()    { tmux sp $(ftl_env) $5 -t $my_pane ${3:--h} -l ${2:-${zooms[zoom]}%} -c "$PWD" "$1" && { sleep 0.03 ; pane_id=$(tmux display -p '#{pane_id}') && tselectp $4 ; } ; }
tselectp()  { tmux selectp -t $pane_id ${1:--L} ; }
winch()     { winch= ; geometry ; { ((!w3p)) && [[ "$WCOLS" != "$COLS" ]] || [[ "$WLINES" != "$LINES" ]] ; }  && cdir ; }
zoom()      { geometry ; [[ $pane_id ]] && read -r COLS_P < <(tmux display -p -t $pane_id '#{pane_width}') || COLS_P=0 ; ((x = ( ($COLS + $COLS_P) * ${zooms[$zoom]} ) / 100)) ; }

type ftl_filter &>/dev/null || eval "ftl_filter(){ cat ; }" ; ext_dir() { : ; } ; ext_tag() { : ; } ; ext_bindings() { false ; } ; . ~/.config/ftl/ftl.et ; . ~/.config/ftl/ftl.eb
ftl "$@"
