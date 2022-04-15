#!/bin/env bash
cdf() { P=$(mktemp -u) && mkfifo $P && exec 3<>$P && rm $P ; ftl ; read -ru 3 d ; [[ "$d" ]] && cd "$(dirname "$d")" ; } ; [[ ${BASH_SOURCE[0]} != $0 ]] && return ;

externals() { echo ewith edir eimage emedia epdf ehtml etext ; }
previewers(){ echo plock pdir pignore pmp4 pimage pmp3 ppdf phtml mime_get pperl pshell ptext ptar pcbr ptype ; }
declare -A K=( [a]=ª [b]=” [c]=© [d]=ð [e]=€ [f]=đ [g]=ŋ [h]=ħ [i]=→ [k]=ĸ [l]=ł [m]=µ [o]=œ [p]=þ [q]=@ [r]=® [s]=ß [t]=þ [u]=↓ [v]=“ [x]=» [y]=← [z]=« [.]=· [6]=¥) \
           SK=([a]=º [b]=’ [c]=© [d]=Ð [e]=¢ [f]=ª [g]=Ŋ [h]=Ħ [i]=ı [k]=  [l]=Ł [m]=º [o]=Œ [p]=Þ [q]=Ω [r]=® [s]=§ [t]=Þ [u]=↑ [v]=‘ [x]=  [y]=¥ [z]=  [.]=˙ [6]=⅝ [/]=÷)

ftl() # directory, search, pfs, preview. © Nadim Khemir 2020-2022, Artistic licence 2.0
{
tab=0 ; tabs+=("$PWD") ; ntabs=1 ; : ${preview_all:=1} ; : ${pdir_only[tab]:=} ; : ${find_auto:=README} ; max_depth[tab]=1 ; : ${zoom:=0} ; zooms=(70 50 30) ; mh='Creating montage ...'
tbcolor 67 67 ; quick_display=256 ; cursor_color='\e[7;34m' ; : ${imode[tab]:=0} ; lmode[tab]=0 ; : ${show_line:=1} ; show_size=0 ; show_date=1 ; show_tar=0 ; : ${etag:=0} ; 
ifilter='webp|jpg|jpeg|JPG|png|gif'; mfilter='mp3|mp4|flv|mkv'; : ${sort_type[tab]:=0} ; sort_filters=('-k3' '-n' '-k2')
sglyph=( ⍺ 🡕 ) ; iglyph=('' ᴵ ᴺ) ; lglyph=('' ᵈ ᶠ) ; tglyph=('' ¹ ² ³ D)

declare -A dir_file pignore lignore exift fexts tail tags ftl_env ; ftl_root=/tmp/$USER/ftl ;  ghistory=$ftl_root/history ; dir_done=56fbb22f2967c198
mkapipe 4 5 6 ; echo -en '\e[?1049h'  ; stty -echo ; my_pane=$(pid_2_pane $$) ; thumbs=$ftl_root/thumbs ; mkdir -p $thumbs ; pushd "$dir" &>/dev/null 

[[ "$1" ]] && { path "$1" ; [[ -d "$1" ]] && { dir="$p/$f" ; search="$2" ; } || { [[ -f "$1" ]] && { dir="${p}" ; search="$f" ; } ; } || { echo ftl: \'$1\', no such path ; exit 1 ; } ; }
[[ "$3" ]] && { fs=$3/$$ ; pfs=$3 ; mkdir -p $fs ; touch $fs/history ; } || { fs=$ftl_root/$$ ; pfs=$fs ; main=1 ; mkdir -p $fs/prev ; touch $ghistory ; echo $my_pane >$fs/pane ; } ;
declare -A marks=([0]=/$ [1]="$HOME/$") ; . ~/.ftlrc || . ~/.config/ftl/ftlrc; marks[$"'"]="$(tail -n1 $ghistory)"
[[ "$4" == 1 ]] && { gpreview=1 ; preview_all=0 ; emode=0 ; PPWD="$dir" ; synch $pfs "$search" ; } || { PPWD="$dir" ; cdir "$dir" "$search" ; }

while : ; do winch ; ((kbd_tick++)) ; { [[ "$R" ]] && { REPLY="${R:0:1}" ; R="${R:1}" ; } || read -sn 1 -t 0.3 ; } && bindings ; ((kbd_tick%10)) && kbd_flush ; done 
}

bindings()
{
ext_bindings  || case "${REPLY: -1}" in
	\?     ) tmux popup -h 90% -w 60% -E "< ~/.config/ftl/help fzf --info=inline --layout=reverse --tiebreak=begin --header='⇑: alt-gr, ⇈: shift+alt-gr, ˽: leader'" ; list ;;
	h|D    ) [[ "$PWD" != / ]]  && { nd="${PWD%/*}" ; cdir "${nd:-/}" "$(basename "$p")"; } ;;
	j|B|k|A) ((nfiles)) && { [[ $REPLY == j || "$REPLY" == B ]] && { move 1 && list ; true ; } || { move -1 && list ; } ; } ;;
	l|C|'' ) ((nfiles)) && { [[ -f "${files[file]}" ]] && { [[ $REPLY == '' ]] && edit ; true ; } || cdir "${files[file]}" ; } ;;
	5|6    ) [[ $REPLY == 5 ]] && { move -$LINES && list ; true ; } || { move $LINES && list ; } ;;
	J|K    ) [[ $REPLY == K ]] && movep U || movep D ;;
	0      ) ((gpreview)) && kbd_flush && synch $pfs || cdir "$PWD" "$f" ;;
	1|2|3|4) tags[${files[file]}]=${tglyph[$REPLY]} ; move 1 ; list ;;
	¿|¡    ) [[ $REPLY == ¿ ]] && read pdh <$fs/pdh || pdh_flip ;;
	7      ) list ; pane_read ; ((${#panes[@]})) && tmux selectp -t ${panes[0]} || tmux selectp -t $my_pane ;;
	8      ) ((gpreview)) && read n <$pfs/prev/ftl && cdir "$n" ;;
	9      ) ((preview_all)) && { rdc=8 ; op=$(tmux display -p '#{pane_id}') ; read n <$fs/prev/ftl ; path "$n" ; geo_prev ; preview 1 ; tmux selectp -t $op ; kbd_flush ; rdc=; } ;;
	a      ) mplayer_k ;;
	b|n|N  ) how=$REPLY ; [[ $how == 'b' ]] && { prompt "find: " -e to_search ; how=n ; } ; ffind $how ;;
	/|${K[b]}) tcpreview ; fzf_go "$({ fd . -H -I -d1 -td | sort | lscolors ; fd . -H -I -d1 -tf | sort | lscolors ; } | fzf_vpreview)" ;;
	${SK[b]}) tcpreview ; fzf_go "$(fd . -H -I -E'.git/*' | lscolors | fzf_vpreview)" ;;
	${SK[/]}) tcpreview ; fzf_go "$(fd . -td --no-ignore --color=always -L | sort | fzf_vpreview)" ;;
	c      ) prompt 'cp to: ' -e && [[ $REPLY ]] && { tag_check && cp_mv_tags p "$REPLY" || cp_mv p "$REPLY" "${selection[@]}" ; } ; cdir ;;
	d      ) tag_check && delete_tag || delete '' "${selection[@]}" ;;
	e|E    ) [[ $REPLY == e ]] && emode=1 ; [[ $REPLY == E ]] && emode=2 ; list ;;
	${K[d]}) filters[tab]= ; filters2[tab]= ; rfilters[tab]= ; ntfilter[tab]= ; fexts=() ; eval "ftl_filter(){ cat ; }" ; ftag= ; tcpreview ; cdir ;;
	f      ) prompt "filter: " -ei "${filters[tab]}" ; filters[tab]="$REPLY" ; ftag="~" ; dir_file[$PWD]= ; tcpreview ; cdir '' ;;
	F      ) prompt "filter2: " -ei "${filters2[tab]}" ; filters2[tab]="$REPLY" ; ftag="~" ; dir_file[$PWD]= ; tcpreview ; cdir '' ;;
	${K[f]}) p=~/.config/ftl/external_filters ; file=$(cd $p ; fd | fzf-tmux --reverse --info=inline) ; [[ $file ]] && . $p/$file $fs ; cdir ;;
	${SK[f]}) prompt "rfilter: " -ei "${rfilters[tab]}" ; rfilters[tab]="$REPLY" ; ftag="~" ; dir_file[$PWD]= ; tcpreview ; cdir '' ;;
	g|G    ) [[ $REPLY == G ]] && ((dir_file["$PWD"] = nfiles - 1)) || dir_file["$PWD"]=0 ; list ;;
	${K[g]}) prompt 'cd: ' -e ; [[ -n $REPLY ]] && cdir "${REPLY/\~/$HOME}" || list ;;
	H|${K[h]}|¨) [[ $REPLY == H ]] && h=$fs/history || h=$ghistory ; dedup $h && fzf_go "$(<$h lscolors | fzf-tmux --tac -p 80% --cycle --ansi --info=inline --layout=reverse)" ;;
	${SK[h]}) dedup $ghistory && rg -v -x -F -f <(<$ghistory lscolors | fzf-tmux --tac -p 80% -m --ansi --info=inline --layout=reverse) $ghistory | sponge $ghistory ;;
	${SK[d]}) prompt 'clear global history? [y|N]' -sn1 && [[ $REPLY == y ]] && rm $ghistory 2>&- ; list ;;
	${K[i]}) tcpreview ; fzf_go "$(fzfi -q "$(echo "$ifilter" | perl -pe 's/(^|\|)/ $1 ./g')")" ;;
	i      ) prompt 'touch: ' && [[ "$REPLY" ]] && touch "$PWD/$REPLY" ; cdir "$PWD" "$REPLY" ;;
	I      ) prompt 'mkdir: ' && [[ "$REPLY" ]] && mkdir -p "$PWD/$REPLY" ; cdir "$PWD/$REPLY" ;;
	${K[k]}) prompt 'clear persistent marks? [y|N]' -sn1 && [[ $REPLY == y ]] && :>$ftl_root/marks ; list ;;
	\'     ) read -n 1 ; [[ -n ${marks[$REPLY]} ]] && cdir "$(dirname "${marks[$REPLY]}")" "$(basename "${marks[$REPLY]}")" || list ;;
	\,     ) { cat $ftl_root/marks 2>&- ; [[ -d "$n" ]] && echo "$n/\$" || echo "$n" ; } | awk '!seen[$0]++' | sponge $ftl_root/marks ;;
	\;     ) tcpreview ; fzf_go "$(cat $ftl_root/marks | lscolors | fzf --ansi --info=inline --layout=reverse)" ;;
	\´     ) tcpreview ; fzf_go "$(printf "%s\n" "${marks[@]}" | sort -u | lscolors | fzf --ansi --info=inline --layout=reverse)" ;; #altgr \'
	L      ) tag_check && prompt "Link (${#tags[@]})? [y|N]" -sn1 ; [[ $REPLY == y ]] && { for f in "${selection[@]}" ; do ln -s -b "$f" "$PWD" ; done ; tags=() ; } ; cdir ;;
	${K[l]}) rm "$fs/lock_preview/$n" 2>&- ; list ;;
	${SK[l]}) p=~/.config/ftl/lock_preview ; file=$(cd $p ; fd | fzf-tmux --reverse --info=inline) ; [[ $file ]] && . $p/$file ; list ;;
	M      ) ((imode[tab]--)) ; ((imode[tab] < 0)) && imode[tab]=2 ; ((imode[tab] == 2)) && ftl_nimode || ftl_imode ${imode[tab]} ; cdir ;;
	m      ) read -sn1 ; [[ -n $REPLY ]] && marks[$REPLY]="${files[file]}" ;;
	${K[m]}) [[ "${tail[$n]}" ]] && unset -v "tail[$n]" || tail[$n]='+$ ' ; list ;;
	o      ) ((sort_type[tab]++, sort_type[tab] = sort_type[tab] >= ${#sort_filters[@]} ? 0 : sort_type[tab])) ; cdir ;;
	O      ) [[ ${reversed[tab]} ]] && reversed[tab]= || reversed[tab]=-r ; cdir ;;
	${K[o]}) source ~/.config/ftl/merge/all ; list ;;
	${SK[o]}) p=~/.config/ftl/merge ; file=$(cd $p 2>&- && fd | fzf-tmux --header 'Merge tags:' --cycle --reverse --info=inline) ; [[ $file ]] && . $p/$file ; cdir ;;
	p|P    ) tag_check && cp_mv_tags $REPLY "$PWD" ; cdir ;;
	r      ) ((nfiles)) && path "${files[file]}" || f= ; tag_check ; cdir "$PWD" "$f" ;;  # directory content change signal
	${K[r]}) rm "$n/.montage.png" 2>&- ; list ;;
	R      ) tag_check &&  bulkrename || { prompt "rename ${files[file]##*/} to: " && [[ $REPLY ]] && mv "${files[file]}" "$REPLY" ; } ; cdir ;;
	${K[s]}) ((show_size ^= 1)) || { ((show_size ^= 1)) ; ((show_dir_size ^= 1)) ; } || show_size=0 ; cdir ;;
	\$     ) (($in_vipreview)) && in_vipreview= && pane_id= && cdir ;;
	t|T    ) sdir= ; [[ $REPLY == t ]] && sdir='-d1' ; fzf_tag T "$(fd . -H --color=always $sdir | fzf-tmux -p 90% -m --ansi --info=inline --layout=reverse --marker '▪')" ; list ;;
	${K[t]}) cat $fs/tags | xsel -b -i ;; 
	U      ) tags=() ; list ;;
	u      ) tag_check && { fzf_tag U "$(cat $fs/tags | lscolors | fzf-tmux -p 90%  -m --ansi --info=inline --layout=reverse --marker '⊟')" ; list ; } ;;
	${K[u]}) tag_check && fzf_go "$(printf "%s\n" "${!tags[@]}" | sort -u | lscolors | fzf-tmux --tac -p 80% --cycle --ansi --info=inline --layout=reverse)" ;;
	v|V    ) [[ $REPLY == V  ]] && preview=1 || ((preview_all ^= 1)) ; ((${preview:-$preview_all})) || tcpreview ; cdir ;;
	${K[v]}) extmode=1 ; list ;;
	${SK[v]}) [[ "$montage_preview" ]] && montage_preview= || montage_preview="⠶" ; list ;;
	+      ) ((zoom += 1, zoom >= ${#zooms[@]})) && zoom=0 ; zoom ; [[ $pane_id ]] && tresize $pane_id $x || cdir ;; 
	\=     ) [[ "${pdir_only[tab]}" ]] && pdir_only[tab]= || pdir_only[tab]='⁼' ; list ;;
	\#     ) [[ $e ]] && { ((pignore[${e}] ^= 1)) ; cdir ; } ;;
	w      ) source ~/.config/ftl/viewers/mplayer_local ; list ;;
	W      ) p=~/.config/ftl/viewers ; viewer=$(cd $p 2>&- && fd | fzf-tmux --cycle --reverse --info=inline) ; [[ $viewer ]] && . $p/$viewer ; list ;;
	x|X    ) [[ $REPLY == x ]] && mode=a+x || mode=a-x ; chmod $mode "${selection[@]}" ; cdir ;;
	y|Y    ) tag_flip "${files[file]}" ; [[ $REPLY == y ]] && { move 1 ; true ; } || move -1 ; list ;;
	${K[y]}) for p in "${files[@]}" ; do [[ -f "$p" ]] && tags["$p"]='▪' ; done ; list ;;
	${SK[y]}) for p in "${files[@]}" ; do tags["$p"]='▪' ; done ; list ;;
	q|Q|\@ ) tab_close || pane_close || quit ;;
	Z      ) ((main)) && { pane_read && for p in "${panes[@]}" ; do tmux send -t $p Z &>/dev/null ; done ; } ; quit ;;
	z      ) quit2 ; [[ $pane_id ]] && { tmux selectp -t $pane_id ; tmux resizep -Z -t $pane_id ; } ; exit 0 ;;
	${SK[s]}|$'\t') [[ $REPLY == ${SK[s]} ]] && { tabs+=("$PWD") ; ((tab = ${#tabs[@]} - 1)) ; ((ntabs++)) ; } || { ((ntabs > 1)) && tab_next ; } ; cdir ${tabs[tab]} ;;
	\:     ) prompt ':' ; [[ $REPLY =~ -?[0-9]+ ]] && list $((REPLY > 0 ? (REPLY -1) : 0)) || shell_command "$REPLY" ;; 
	\"     ) ((no_image_preview ^= 1)) ; for e in $(tr '|' ' ' <<< "$ifilter") ; do pignore[${e}]=$no_image_preview ; done ; ((zoom == 0)) && R="-$R" ; cdir ;;
	\%|\&  ) [[ $REPLY == \% ]] && { [[ $e ]] && ((lignore[${e}] ^= 1)); } || lignore=() ; cdir ;;
	\*     ) prompt 'depth: ' && [ "$REPLY" -eq "$REPLY" ] 2>&- && max_depth[tab]=$REPLY && cdir ;;
	.      ) ((show_hidden[tab])) && show_hidden[tab]= || show_hidden[tab]=1 ; cdir ;;
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
	\)     ) ((lmode[tab]--)) ; ((lmode[tab] < 0)) && lmode[tab]=2 ; cdir ;;
esac
}

cdir() { inotify_k ; get_dir "$@" ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; refresh ; list "${3:-$found}"; }
get_dir() # dir, search
{
new_dir="${1:-$PWD}" ; [[ -d "$new_dir" ]] || return ; PWD="$new_dir" ; tabs[$tab]="$PWD" ; [[ "$PWD" == / ]] && sep= || sep=/
[[ "$PPWD" != "$PWD" ]] && { [[ -d "$n" ]] && m="$n" || m="$n" ; marks["'"]="$m" ; PPWD="$PWD" ; ((gpreview)) || echo "$m" | tee -a $fs/history >> $ghistory ; }

cd "$PWD" 2>$fs/error || { refresh ; cat $fs/error ; return ; } ; inotify_s ; ((etag)) && etag_dir
files=() ; files_color=() ; mime=() ; nfiles=0 ; search="${2:-$(((dir_file[$PPWD])) || echo "$find_auto")}" ; found= ; shopt -s nocasematch ; geo_prev

declare -A uniq_file ; pad=(* ?) ; pad=${#pad[@]} ; pad=${#pad} ; line=0 ; sum=0 ; local LANG=C LC_ALL=C ; dir &
while : ; do read -s -u 4 p ; [ $? -gt 128 ] && break ; read -s -u 5 pc ; read -s -u 6 size
	[[ $p == $dir_done ]] && break ; ((${uniq_file[$p]})) && continue ; uniq_file[$p]=1
	((quick_display && nfiles > 0 && 0 == nfiles % quick_display)) && { refresh ; list $found ; in_quick_display=1 ; }
	[[ "$p" =~ '.' ]] && { e=${p##*.} ; ((lignore[${e@Q}])) && continue ; } ; pl=${#p}
	((etag)) && { etag_tag "$p" external_tag external_tag_length ; pc="$external_tag$pc" ; ((pl+=external_tag_length)) ; }
	((show_size)) && { ((sum += size)) ; [[ -d "$p" ]] && { ((show_dir_size)) && pc=$(dsize "$p")" $pc" || pc="     $pc" ; } || pc=$(fsize $size)" $pc" ; pl=$((pl + 5)) ; }
	((show_line)) && { ((line++)) ; printf -v pc "\e[2;30m%-${pad}d\e[m¿${pc/\%/%%}" $line ; ((pl += 4)) ; }
	pcl=${pc:0:(( ${#pc} == $pl ? ($COLS - 1) : ( (${#pc} - 4) - $pl ) + ($COLS - 1) )) }
	((${#p} > ($COLS - 1))) && { [[ "$p" =~ '.' ]] && e=….${p##*.} || e=… ; pcl=${pcl:0:((${#pcl} - ${#e}))}${e} ; }
	files_color[$nfiles]="$pcl" ; files[$nfiles]="$PWD$sep$p" ; [[ -n "$search" && -z "$found" ]] && [[ "${p:0:${#search}}" == "$search" ]] && found=$nfiles ; ((nfiles++))
done 

shopt -u nocasematch ; in_quick_display=0 ; ((show_size)) && hsum=$(numfmt --to=iec --format ' %4f' "$sum") || hsum= ; flipi=1 ; flips=(' ' ' ') #space, EM-space
}

list() # select
{
[[ $1 ]] && dir_file[$PWD]=$1 ; file=${dir_file[$PWD]:-0} ; ((file = file > nfiles - 1 ? nfiles - 1 : file)) ; sstate $fs ; selection

((ntabs>1)) && tabsd=" ᵗ$ntabs" || tabsd= ; head="${lglyph[lmode[tab]]}${iglyph[imode[tab]]}${pdir_only[tab]}${montage_preview}" ; head=${head:+$head } 
((nfiles)) && { path "${files[file]}" ; ((flipi^=1)) ; flip="${flips[$flipi]}" ; true ; } || { head="\e[33m∅ $head$ftag$tabsd" ; header "$head" ; tcpreview ; return ; }
((show_stat)) && stat="$(stat -c ' %A %U' "${files[file]}") $(stat -c %s "${files[file]}" | numfmt --to=iec --format '%4f')" || stat= ; 
((sort_type[tab] == 2 && show_date)) && date=$(date -r "${files[file]}" +' %D-%R') || date= ; head="$head$ftag$((file+1))/${nfiles}$hsum$stat$date$tabsd" ; header "$head"

((top = nfiles < lines || file <= center ? 0 : file >= nfiles - center ? nfiles - lines : file - center)) ; geo_winch 
for((i=$top ; i <= ((bottom = top + lines - 1, bottom < 0 ? 0 : bottom)) ; i++))
	do
		cursor=${tags[${files[$i]}]:- } ; [[ $i == $file ]] && cursor="${cursor_color}$cursor"
		echo -ne "\e[m\e[K$cursor${files_color[i]/¿/$flip}" ; ((i != bottom)) && echo
	done

((in_quick_display)) || { geo_winch ; preview ; }
}

preview()
{
((main || gpreview || preview_all)) || { pane_read ; sstate $pfs/prev ; tmux send -t $main_pane 9 &>/dev/null ; return ; }

((emode)) && { for external in $(externals) ; do $external && { sleep 0.01 ; emode=0 ; list ; return ; } ; done ; } ; emode=0 ; 
((${1:-${preview:-$preview_all}})) && { preview= ; for v in $(previewers) ; do $v && { extmode=0 ; geo_winch ; return ; } ; done ; extmode=0 ; }
tcpreview
}

ewith()     { w=$(rg -v -x -F -f <(echo -e "$n\n$e\$mime") ~/.config/ftl/open_with | cut -f 2- | fzf-tmux -p 80% -m --ansi --info=inline) ; [[ "$w" ]] && { "$w" "$n" ; true ; } ; }
edir()      { [[ -d "$n" ]] && {  vlc "$n" &>/dev/null & } ; }
ehtml()     { [[ $e =~ html ]] && { ((emode == 2)) && { (qutebrowser "$n" 2>&- &) ; } || { tcpreview ; w3m -o confirm_qq=0 "$n" ; } ; } ; } 
eimage()    { [[ $e =~ ^($ifilter)$ ]] && run_maxed fim -a "$n" "$PWD" ; }
emedia()    { [[ $e =~ ^($mfilter)$ ]] && { ((emode == 1)) && { mplayer_k ; mplayer -vo null "$n" </dev/null &>/dev/null & } && mplayer=$! || vlc "$n" &>/dev/null & } ; }
epdf()      { [[ $e == pdf ]] && { ((emode == 2)) && (mupdf "$n" 2>/dev/null &) || ((emode == 1)) && run_maxed mupdf "$n" ; true ; } ; }
etext()     { tcpreview ; tsplit "$EDITOR ${n@Q}" "33%" '-h -b' -R ; pane_id= ; }
pcbr()      { [[ $e == cbr ]] && { t="$thumbs/$b.$e.jpg" ; { [[ -e $t ]] || cbconvert thumbnail "$n" --outfile "$t" &>/dev/null ; } ; [[ -e $t ]] && pw3image "$t" ; } ; }
pdir()      { [[ -d "$n" ]] && { pdir_image || pdir_dir "$n" ; } || { in_pdir= ; pdir_only ; } ; }
pdir_dir()  { ((in_pdir)) && [[ $pane_id ]] && tmux send -t $pane_id ${rdc:-0} || { tmux selectp -t $my_pane ; ctsplit "ftl ${1@Q} '' $fs 1" ; in_pdir=1 ; sleep 0.1 ; } ; }
pdir_image(){ [[ "$montage_preview" ]] && { in_pdir= ; [[ -e "$n/.montage.png" ]] || do_montage "$n" ; [[ -e "$n/.montage.png" ]] && pw3image "$n/.montage.png" ; } ; }
do_montage(){ < <(IFS='\n' fd -a -t f -e ${ifilter//|/ -e} -d 1 . "$1" | head -n 40) mapfile -t a ; ((${#a[@]})) && header "$mh" && montage "${a[@]}" "$1/.montage.png" && header $head ; }
pdir_only() { [[ "${pdir_only[tab]}" ]]  && { tcpreview ; true ; } || false  ; }
phtml()     { [[ $e == html ]] &&  w3m -dump "$n" > "$fs/$f.txt" && vipreview "$fs/$f.txt" ; }
pignore()   { [[ $e ]] && ((pignore["${e@Q}"])) && { mime_get ; in_pdir= ; in_vipreview= ; ptype ; true ; } || false ; }
pimage()    { [[ $e =~ ^($ifilter)$ ]] &&  pw3image ; }
plock()     { [[ -e "$fs/lock_preview/$n" ]] && vipreview "$fs/lock_preview/$n" ; }
pmp3()      { [[ $e == mp3 ]] && { pmlive || { t=$(gen_exift) ; ctsplit "/bin/less <$t ; read -sn1" ; } ; } ; }
pmp4()      { [[ $e =~ mkv|mp4|flv ]] && { pmlive || { t="$thumbs/$f.png" ; [[ -f "$t" ]] || ffmpegthumbnailer -i "$n" -o "$t" -s 1024 ; pw3image "$t" ; true ; } ; } ; }
pmlive()    { ((extmode)) && { mplayer_k ; ctsplit "cat $(gen_exift) ; mplayer -msglevel all=-1 -msglevel statusline=6 -nolirc -msgcolor -novideo -vo null \"$n\"" ; true ; } ; }
pshell()    { [[ $mtype == 'application/x-shellscript' ]] && vipreview "$n" ; }
ppdf()      { [[ $e == pdf ]] && { ((extmode)) && ppdfpng || { mutool draw -o "$fs/$f.txt" "$n" $( ((extmode)) || echo 1-3) 2>/dev/null && vipreview "$fs/$f.txt" ; } ; true ; } ; }
ppdfpng()   { echo ppdfpng ; t="$(gen_uidf).png" ; [[ -f "$t" ]] || { mutool draw -o "$t" "$n" 1 2>/dev/null ; } ; pw3image "$t" ; true ; }
pperl()     { [[ $mtype == application/x-perl ]] && [[ -s "$n" ]] &&  vipreview "$n" ; }
ptext()     { { [[ $e =~ ^json|yml$ ]] || [[ $mtype =~ ^text ]] ; } && [[ -s "$n" ]] && vipreview "$n" ; }
ptar()      { [[ $f =~ \.tar ]] && ((show_tar || extmode)) && { fp="$fs/$f.txt" ; [[ -e "$fp" ]] || timeout 1 tar --list --verbose -f "$f" >"$fp" ; vipreview "$fp" ; } ; }
ptype()     { ctsplit "echo '$f' ; echo '$mtype' ; file -b ${n@Q} ; stat -c %s ${n@Q} | numfmt --to=iec ; read -sn 100" ; }
pw3image()  { image="${1:-$n}" ; ((in_ftli)) &&  { tmux send -t $pane_id "${image}" C-m ; } || { ctsplit "ftli \"${image}\"" ; in_ftli=1 ; } ; sleep 0.05 ; tmux selectp -t $my_pane ; }
tcpreview() { [[ "$pane_id" ]] && { tmux killp -t $pane_id &> /dev/null ; in_pdir= ; pane_id= ; in_vipreview= ; in_ftli= ; sleep 0.01 ; } ; }
vipreview() { ((in_vipreview)) && { tmux send -t $pane_id ":e ${tail[$1]}$(sed -E 's/\$/\\$/g' <<<"$1")" C-m ; } || ctsplit "$EDITOR -R ${tail[$1]}${1@Q}" ; ((in_vipreview++)) ; true ; }
bulkrename(){ tcpreview ; bulkedit && bulkverify && { bash $fs/br && tags=() || read -sn 1 ; } ; true ; }
bulkedit()  { sed "s/.*/\"&\"/" $fs/tags | tee $fs/bo >$fs/bd ; $EDITOR $fs/bd ; >$fs/br echo 'set -e' ; paste $fs/bo $fs/bd >>$fs/br ; }
bulkverify(){ perl -i -ne '/^([^\t]+)\t([^\t]+)\n/ && { $1 ne $2 && print "mv $1 $2\n" } || print' $fs/br ; $EDITOR $fs/br ; }
ctsplit()   { ((in_ftli)) && tcpreview ; { in_pdir= ; in_vipreview= ; in_ftli= ; } ; [[ $pane_id ]] && ((!in_ftli)) && tmux respawnp -k -t $pane_id "$1" &> /dev/null || tsplit "$1" ; }
cp_mv()     { [[ $1 == p ]] && cmd="cp -vr" || cmd=mv ; tscommand "$cmd $(printf '%q ' "${@:3}") ${2@Q}" ; }
cp_mv_tags(){ declare -A ltags ; tag_get ltags class ; ((${#ltags[@]})) && { cp_mv $1 "$2" "${!ltags[@]}" ; tag_clear $class ; } ; true ; }
dedup()     { [[ -s "$1" ]] && { awk '!seen[$0]++' ${1} | sponge ${1} ; true ; } ; } 
delete()    { prompt "delete$1? [y|d|N]: " -n1 && [[ $REPLY == y || $REPLY == d ]] && { rip "${@:2}" ; read -sn1 ; mime=() ; R=0 ; true ; } || { list ; false ; } ; }
delete_tag(){ declare -A ltags ; tag_get ltags class ; ((${#ltags[@]})) && delete " ** tags: ${#ltags[@]} ** " "${!ltags[@]}" && tag_clear $class ; }
dir()       { ((lmode[tab]<2)) && files "-type d,l -xtype d" filter2 ; files "-xtype l" filter ; ((lmode[tab]!=1)) && files "-type f,l -xtype f" filter ; dir_done ; }
dir_done()  { echo "$dir_done" >&4 ; echo '' >&5 ; echo 0 >&6 ; }
def_sub()   { for def in "$@" ; do local sub=${def%%:*} ; local body=${def:((${#sub}+1))} ; type "$sub" &>/dev/null || eval "$sub(){ ${body:-:} ; }" ; done ; } 
dsize()     { printf "\e[94m%4s\e[m" $(find "$1/" -mindepth 1 -maxdepth 1 ${show_hidden[tab]:+\( ! -iname '.*' \)} -type d,f,l -xtype d,f -printf "1\n" 2>&- | wc -l) ; } 
edit()      { tcpreview ; echo -en '\e[?1049h' ; inotify_k ; "${EDITOR}" "${1:-${files[file]}}"; echo -en '\e[?1049h\e[?25h' ; cdir ; }
ffind()     { [[ $1 == n ]] && { ((from = file + 1)) ; to=$nfiles ; inc='++' ; } || { ((from = file - 1)) ; to=-1 ; inc='--' ; }
		for ((i=$from ; i != $to ; i$inc)) ; do [[ "${files[i]##*/}" =~ "$to_search" ]] && { list $i ; return ; } ; done ; list ; }
files()     { find "$PWD/" -mindepth 1 -maxdepth ${max_depth[tab]:-1} ${show_hidden[tab]:+\( ! -path "*/.*" \)} $1  -printf '%s\t%T@\t%P\n' 2>&- | ftl_filter | $2 ; }
filter()    { rg ${ntfilter[tab]} "${tfilters[tab]}" | rg "${filters[tab]}" | rg "${filters2[tab]}" | { [[ "${rfilters[tab]}" ]] && rg -v "${rfilters[tab]}" || cat ; } | filter2 ; }
filter2()   { sort_by | tee >(cat >&4) | lscolors >&5 ; }
fsize()     { numfmt --to=iec --format '\e[94m%4f\e[m' $1 ; }
ftl_env()   { ftl_env=([ftl_pfs]=$pfs [ftl_fs]=$fs) ; for i in "${!ftl_env[@]}" ; do echo -n "${1:--e} $i=${ftl_env[$i]} " ; done ; }
ftl_imode() { (($1)) && { ntfilter[tab]= ; tfilters[tab]="$ifilter$" ; dir_file[$PWD]= ; } || tfilters[tab]= ; }
ftl_nimode(){ tfilters[tab]="$ifilter$" ; ntfilter[tab]='-v' ; dir_file[$PWD]= ; }
fzf_go()    { [[ "$1" ]] && { [[ -d "$1" ]] && cdir "$(dirname "$1")" || cdir "$(dirname "$1")" "$(basename "$1")" ; } || { refresh ; list ; } ; }
fzf_tag()   { [[ "$2" ]] && while read f ; do [[ "$1" == U ]] && unset -v "tags[$f]" || tags[$PWD/$f]='▪' ; done <<<$2 ; }
gen_exift() { t=$(gen_uidf) ; [[ -e $t ]] || exiftool "$n" >$t ; echo $t ; }
gen_uidf()   { echo "$thumbs/et_$(head -c50000 "$n" | md5sum | cut -f1 -d' ')" ; }
geometry()  { read -r TOP WIDTH LINES COLS LEFT< <(tmux display -p -t $my_pane '#{pane_top} #{window_width} #{pane_height} #{pane_width} #{pane_left}') ; }
geo_prev()  { geometry ; ((${preview:-$preview_all})) && [[ -z $pane_id ]] && ((COLS=(COLS-1) * (100 - ${zooms[zoom]}) / 100)) ; }
geo_winch() { geometry ; WCOLS=$COLS ; WLINES=$LINES ; }
header()    { h="${@} ${sglyph[sort_type[tab]]}${reversed[tab]}$( ((${#tags[@]})) && echo " ${#tags[@]}")" ; header_pos "$h" ; echo -e "\e[H\e[K\e[94m${PWD:hpl} \e[95m${h:hal}\e[m" ; }
header_pos(){ hal=$((${#1} - ($COLS - 1))) ; hpl=$((${#PWD} + (hal < 0 ? hal : 0) )) ; ((hal = hal < 0 ? 0 : hal, hpl = hpl < 0 ? 0 : hpl)) ; }
inotify_s() { inotify_ & : ; ino1=$! ; ino2=$(ps --ppid $! | grep inotifywait | awk '{print $1}') ; }
inotify_()  { inotifywait --exclude index.lock -e create -e delete -e move "$PWD/" &>/dev/null && tmux send -t "$my_pane" r 2>&- ; } 
inotify_k() { [[ $ino1 ]] && { kill $ino1 $ino2 2>&- ; ino1= ; ino2= ; } ; }
kbd_flush() { [[ $REPLY != $'\e' && $REPLY != "[" && $leader_command != 1 ]] &&  while read -t 0.01 ; do : ; done ; }
location()  { true 2>&- >&3 && { [[ $REPLY == 'Q' ]] && echo "${files[file]}" >&3 || :>&3 ; } ; }
mime_get()  { ((rdc)) && mtype=$(mimemagic "$n") || mime_cache ; false ; }
mime_cache(){ [[ ${mime[file]} ]] || mime+=($(mimemagic "${files[@]:${#mime[@]}:((file + 10))}" 2>&1 | sed -e "s/cannot.*/n\/a/" -e 's/^.*: //')) ; mtype="${mime[file]}" ; false ; }
mkapipe()   { for arg in "$@" ; do PIPE=$(mktemp -u) && mkfifo $PIPE && eval "exec $arg<>$PIPE" && rm $PIPE ; done ; }
move()      { ((nf = file + $1, nf = nf < 0 ? 0 : nf >= nfiles ? nfiles - 1 : nf)) ; ((nf != file)) && dir_file[$PWD]=$nf ; }
movep()     { ((in_vipreview)) && tmux send -t $pane_id C-$1 ; }
mplayer_k() { ((mplayer)) && { kill $mplayer &>/dev/null ; mplayer= ; } ; } 
pane_extra(){ pane_ftl "'${3:-$n}' '$4' $pfs 0" "$1" "$2" ; list ; sleep 0.05 ; tmux selectp -t $new_pane ; }
pane_ftl()  { pane_read ; tcpreview ; tsplit "preview_all=0 ftl $1" 30% "$2" $3 ; panes+=($pane_id) ; new_pane=$pane_id ; pane_id= ; printf "%s\n" "${panes[@]}" >$pfs/panes ; }
pane_close(){ pane_read ; ((main && ${#panes[@]})) && { tail -n +2 $pfs/panes | sponge $pfs/panes ; tmux send -t ${panes[0]} q 2>&- ; sleep 0.03 ; } ; }
pane_read() { <$pfs/pane read main_pane ; [[ -s $pfs/panes ]] && mapfile -t panes < <(grep -w -f <(tmux lsp -F "#{pane_id}") $pfs/panes) ; printf "%s\n" "${panes[@]}" >$pfs/panes ; }
path()      { n="$1" ; [[ "$n" =~ / ]] && p="${n%/*}" || p= ; [[ ${p:0:1} != "/" ]] && p="$PWD/$p" ; f="${n##*/}" ; b="${f%.*}" ; [[ "$f" =~ '.' ]] && e="${f##*.}" || e= ; }
pdh()       { [[ $pdh ]] && tmux send -t $pdh "ftl: $my_pane: ${1//\\n/$'\n'}" ; }
pdh_flip()  { [[ $pdh ]] && { tmux killp -t $pdh &> /dev/null ; pdh= ; } || { tcpreview ; tsplit "$HOME/.config/ftl/fpdh $fs" 20% -v -R ; pane_id= ; cdir ; } ; }
pid_2_pane(){ while read -s pi pp ; do [[ $1 == $pp ]] || [[ $(ps -o pid --no-headers --ppid $pp | rg $$) ]] && echo $pi && break ; done < <(tmux lsp -F '#{pane_id} #{pane_pid}') ; }
prompt()    { stty echo ; echo -ne '\e[0;H\e[K\e[33m\e[?25h' ; read -rp "$@" ; echo -ne '\e[m' ; stty -echo ; tput civis ; }
quit()      { tcpreview ; quit2 ; quit_shell ; tmux kill-session -t ftl$$ &>/dev/null ; ((!main)) && { pane_read ; tmux send -t $main_pane 7 ; } ; rm -rf $fs ; exit 0 ; }
quit2()     { inotify_k ; location ; stty echo ; [[ $pfs == $fs ]] && tbcolor 236 52 ; mplayer_k ; kill $w3iproc &>/dev/null ; refresh "\e[?25h\e[?1049l" ; }
quit_shell(){ [[ $REPLY != @ ]] && [[ $shell_id ]] && tmux killp -t $shell_id &> /dev/null ; }
rdir()      { get_dir ; in_quick_display=1 ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; refresh ; list ; in_quick_display=0 ; }
refresh()   { echo -ne "\e[?25l\e[2J\e[H\e[m$1" ; }
rg_go()     { [[ "$1" ]] && { g=${1%%:*} && nd="$PWD/"$(dirname "$g") && cdir "$nd" "$(basename "$g")" ; } || { refresh ; list ; } ; }
run_maxed() { run_maxed=1 ; ((run_maxed)) && { aw=$(xdotool getwindowfocus -f) ; xdotool windowminimize $aw ; } ; "$@" 2>/dev/null ; ((run_maxed)) && { wmctrl -ia $aw ; } ; }
selection() { selection=() ; ((${#tags[@]})) && selection+=("${!tags[@]}") || { ((nfiles)) && selection=("${files[file]}") ; } ; }
shell()     { tcpreview ; echo -en '\e[?1049l' ; path "${files[file]}" ; s="${selection[@]}" ; shell_run ; read -sn 1 ; echo -en '\e[?1049h' ; }
shell_run() { [[ $REPLY =~ "\$s" ]] && { eval "$REPLY" ; echo '$?': $? ; } || for n in "${selection[@]}" ; do eval "echo -e '\e[7;34mftl\> $REPLY\e[m' ; $REPLY" ; echo '$?': $? ; done ; }
shell_pane(){ tcpreview ; opi=$pane_id ; tsplit /bin/bash 30% -v -U ; shell_id=$pane_id ; pane_id=$opi ; cdir ; tmux selectp -t $shell_id ; }
sort_by()   { sort ${reversed[tab]} ${sort_filters[sort_type[tab]]} | tee >(cut -f 1 >&6) | cut -f 3- ; }
sstate()    { printf "%s\n" "${!tags[@]}" >$fs/tags ; ((!nfiles)) && echo >${1:-$fs}/ftl || { echo "${files[file]}" >${1:-$fs}/ftl ; sstateftl2 "${1:-$fs}" ; } ; }
sstateftl2(){ echo -e "${dir_file[${files[file]}]}\n${imode[tab]}\n$etag\n${sort_type[tab]}\n$show_size\n$show_dir_size\n${filters[tab]}\n${filters2[tab]}\n" >>$1/ftl ; }
synch()     { synch_read "$1/ftl" ; filters2[tab]="$pfil2" ; filters[tab]="$pfil" ; [[ $pfi ]] && ftag="~" ; ftl_imode "${imode[tab]}" ; tag_read "$1" ; cdir "$pdir" "$2" "$pindex" ; }
synch_read(){ [[ -e "$1" ]] && { for r in pdir pindex imode[tab] etag sort_type[tab] show_size show_dir_size pfil pfil2 ; do read $r ; done ; } <$1 ; }
tab_close() { (($ntabs > 1)) && { tabs[$tab]= ; ((ntabs--)) ; tab_next ; cdir ${tabs[tab]} ; } ; }
tab_next()  { ((tab++)) ; for i in "${tabs[@]:$tab}" FTL_RESET "${tabs[@]}" ; do [[ "$i" == FTL_RESET ]] && tab=0 && continue ; [[ -n "$i" ]] && break ; ((tab++)) ; done ; }
tag_check() { for tag in "${!tags[@]}" ; do [[ -e "$tag" ]] || unset -v "tags[$tag]" ; done ; ((${#tags[@]} != 0)) ; }
tag_class() { declare -A ntags ; for t in "${!tags[@]}" ; do ntags[${tags[$t]}]=1 ; done ; echo "$(printf "%s\n" "${!ntags[@]}" | sort | fzf-tmux --reverse --info=inline -1 )" ; }
tag_clear() { pdh "class: $1\n" ; for t in "${!tags[@]}" ; do [[ $1 == ${tags[$t]} ]] && unset -v "tags[$t]" ; done ; }
tag_flip()  { [[ ${tags[$1]} ]] && unset -v "tags[$1]" || tags[$1]=${2:-▪} ; } 
tag_get() { ((${#tags[@]})) && { declare -n rtags="$1" rclass="$2" ; rclass=$(tag_class) ; for t in "${!tags[@]}" ; do [[ $rclass == ${tags[$t]} ]] && rtags[$t]=1 ; done ; } ; }
tag_read()  { tags=() ; [[ -e "$1/tags" ]] && { readarray -t stags < "$1/tags" ; for stag in "${stags[@]}" ; do [[ "$stag" ]] && tags[${stag//\\ / }]='▪' ; done ; } ; }
tbcolor()   { tmux set pane-border-style "fg=color$1" ; tmux set pane-active-border-style "fg=color$2" ; sleep 0.01 ; }
tpop()      { read -r PLEFT PTOP< <(tmux display -p -t $1 '#{pane_left} #{pane_top}') && tmux popup -E -h 3 -w 3 -x $PLEFT -y $(($PTOP + 3)) "sleep 0.07 ; true" ; }
tresize()   { tmux resizep -t $1 -x $2 &>/dev/null ; rdir ; }
tscommand() { tmux new -A -d -s ftl$$ ; tmux neww -t ftl$$ -d "date ; echo -e \"\nftl\> $1\n\n\" ; $1 ; echo \$\?: $? ; read -sn5 -t 1800" ; }
tsplit()    { tmux sp $(ftl_env) $5 -t $my_pane ${3:--h} -l ${2:-${zooms[zoom]}%} -c "$PWD" "$1" && { sleep 0.03 ; pane_id=$(tmux display -p '#{pane_id}') && tselectp $4 ; } ; }
tselectp()  { tmux selectp -t $pane_id ${1:--L} ; }
winch()     { geometry ; { ((!in_ftli)) && [[ "$WCOLS" != "$COLS" ]] || [[ "$WLINES" != "$LINES" ]] ; }  && cdir ; }
zoom()      { geometry ; [[ $pane_id ]] && read -r COLS_P < <(tmux display -p -t $pane_id '#{pane_width}') || COLS_P=0 ; ((x = ( ($COLS + $COLS_P) * ${zooms[$zoom]} ) / 100)) ; }

def_sub "ftl_filter:cat" etag_dir etag_tag 'ext_bindings:false' ; . ~/.config/ftl/ftl.eb ; [[ $TMUX ]] && ftl "$@" || echo "ftl: program must be run inside a tmux session"

