#!/bin/env bash
cdf() { d=/tmp/$USER/ftl ; l=$d/cdf ; mkdir -p $d ; ftl 3> >(cat > $l) ; cd "$(cat $l)" &>/dev/null; } ; [[ ${BASH_SOURCE[0]} != $0 ]] && return ;

externals() { echo edir eimage emedia epdf ehtml etext ; }
previewers(){ echo plock pdir pignore pmp4 pimage pmedia ppdf phtml mime_get pperl pshell ptext ptar ptype ; }
type ftl_filter &>/dev/null || eval "ftl_filter(){ /bin/cat ; }" ; ext_dir() { : ; } ; ext_tag() { : ; } ; ext_bindings() { false ; } 

ftl() # directory, parent fs, preview. © Nadim Khemir 2020-2022, Artistic licence 2.0
{
: ${preview_all:=1} ; : ${pdir_only:=} ; : ${find_auto:=README} ; exit_mplayer= ; max_depth=1 ; tab=0 ; tabs+=("$PWD") ; : ${imode:=0} ; : ${zoom:=0} ; zooms=(70 50 30) 
tbcolor 67 67 ; quick_display=256 ; cursor_color='\e[7;34m' ; show_dirs=1 ; show_files=1 ; : ${show_line:=1} ; show_size=0 ; show_date=1 ; ifilter='webp|jpg|jpeg|JPG|png|gif'
etag=0 ; : ${sort_type:=0} ; find_format='%s %T@ %P\n' ; sort_filters=(by_name by_size by_date) ; sort_name=( ⍺ 🡕 ≣ )
GPGID= ; mkapipe 4 5 6 ; declare -A dir_file pignore lignore fexts tail tags marks=([0]=/ [1]="$HOME") ; . ~/.ftlrc || . ~/.config/ftl/ftlrc ; ftl_root=/tmp/$USER/ftl

echo -en '\e[?1049h'  ; stty -echo ; pw3start ; my_pane ; mkdir -p $ftl_root/thumbs ; pushd "$dir" &>/dev/null
[[ "$1" ]] && { [[ -d "$1" ]] && dir="$1" ; } || { [[ -f $1 ]] && dir=$(dirname "$1") ; search="${1##*/}" ; } || { echo ftl: \'$1\', no such path ; exit 1 ; }
[[ "$2" ]] && { fs=$2/$$ ; parent_fs=$2 ; } || { fs=$ftl_root/$$ ; parent_fs=$fs ; main=1 ; } ; mkdir -p $fs
[[ "$3" ]] && { gpreview=1 ; preview_all=0 ; external=0 ; synch $parent_fs "$search" ; } || cdir "$dir" "$search"
 
while : ; do  ((winch++, winch>10)) && { winch && continue ; } ; { [[ $R ]] && { REPLY=$R ; R= ; } || read -sn 1 -t 0.1 ; } && { ext_bindings || bindings ; } ; done 
}

declare -A K=( [a]=ª [b]=” [c]=© [d]=ð [e]=€ [f]=đ [g]=ŋ [h]=ħ [i]=→ [k]=ĸ [l]=ł [m]=µ [o]=œ [p]=þ [q]=@ [r]=® [s]=ß [t]=þ [u]=↓ [v]=“ [x]=» [y]=← [z]=« [.]=· [6]=¥) \
           SK=([a]=º [b]=’ [c]=© [d]=Ð [e]=¢ [f]=ª [g]=Ŋ [h]=Ħ [i]=ı [k]=  [l]=Ł [m]=º [o]=Œ [p]=Þ [q]=Ω [r]=® [s]=§ [t]=Þ [u]=↑ [v]=‘ [x]=  [y]=¥ [z]=  [.]=˙ [6]=⅝)

bindings()
{
case "${REPLY: -1}" in
	h|D    ) [[ "$PWD" != / ]]  && { nd="${PWD%/*}" ; cdir "${nd:-/}" "$(basename "$p")"; } ;;
	j|B|k|A) ((nfiles)) && { [[ $REPLY == j || "$REPLY" == B ]] && move 1 || move -1 ; } ;;
	l|C|'' ) ((nfiles)) && { [[ -f "${files[file]}" ]] && { [[ $REPLY == '' ]] && edit ; true ; } ||  cdir "${files[file]}" ; } ;;
	5|6    ) [[ $REPLY == 5 ]] && move -$LINES || move $LINES ;;
	J|K    ) [[ $REPLY == K ]] && movep U || movep D ;;
	[1-4]  ) ((tab = $REPLY - 1, tab >= ${#tabs[@]})) && tab=0 ; cdir ${tabs[tab]} ;;
	0      ) ((gpreview)) && synch $parent_fs || cdir "$PWD" "$f" ;;
	9      ) ((main && preview_all)) && { remote=1 ; op=$(tmux display -p '#{pane_id}') ; tmux selectp -t $my_pane ; { read n ; read parent_fs ; } <$fs/preview
		 parse_path "$n" ; preview=1 ; preview ; tmux selectp -t $op ; remote=0 ; parent_fs=$fs ; kbd_flush ; } ;;
	a      ) mplayer_k ;;
	b|n|N  ) how=$REPLY ; [[ $how == 'b' ]] && { prompt "find: " -e to_search ; how=n ; } ; ffind $how ;;
	c      ) prompt 'cp to: ' -e && [[ $REPLY ]] && { copy "$REPLY" "${selection[@]}" ; tags=() ; } ; cdir ;;
	${K[c]}) [[ $f =~ \.tar ]] && tar -xf "$f" || { prompt 'tar.bz2 file: ' -e ; [[ -n $REPLY ]] && tar -cvjSf $REPLY.tar.bz2 "${selection[@]}" ; } ; tags=() ; cdir '' "$REPLY" ;;
	d      ) ((${#tags[@]})) && delete " (${#tags[@]} selected)" || delete ;;
	${K[d]}) filters[tab]= ; filters2[tab]= ; rfilters[tab]= ; ntfilter= ; fexts=() ; eval "ftl_filter(){ /bin/cat ; }" ; filter_tag= ; tcpreview ; cdir ;;
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
	\,     ) { /bin/cat $fs/../marks 2>&- ; echo "$n" ; } | awk '!seen[$0]++' | sponge $fs/../marks ;;
	\;     ) tcpreview ; fzf_go "$(/bin/cat $fs/../marks | lscolors | fzf --ansi --info=inline --layout=reverse)" ;;
	\´     ) tcpreview ; fzf_go "$(printf "%s\n" "${marks[@]}" | sort -u | lscolors | fzf --ansi --info=inline --layout=reverse)" ;; #altgr \'
	L      ) ((${#tags[@]})) && prompt "Link (${#tags[@]})? [y|N]" -sn1 ; [[ $REPLY == y ]] && { for f in "${selection[@]}" ; do ln -s -b "$f" "$PWD" ; done ; tags=() ; } ; cdir ;;
	${K[l]}) rm "$fs/lock_preview/$n" 2>&- ; list ;;
	${SK[l]}) p=~/.config/ftl/lock_preview ; file=$(cd $p ; fd | fzf-tmux --reverse --info=inline) ; [[ $file ]] && . $p/$file $fs ; list ;;
	M      ) ((imode--)) ; ((imode < 0)) && imode=2 ; ((imode == 2)) && ftl_nimode || ftl_imode $imode ; cdir ;;
	m      ) read -sn1 ; [[ -n $REPLY ]] && marks[$REPLY]=$(dirname "${files[file]}") ; list ;;
	${K[m]}) mutt $([[ ${#selection[@]} ]] && printf "\055a %s\n" "${selection[@]}" || [[ $f ]] && echo "-a $f") -s 'ftl files' -- ; refresh ; list ;;
	o      ) ((sort_type++, sort_type = sort_type >= ${#sort_filters[@]} ? 0 : sort_type)) ; cdir ;;
	O      ) [[ $show_reversed ]] && show_reversed= || show_reversed=-r ; cdir ;;
	p|P    ) ((${#tags[@]})) && { [[ $REPLY == p ]] && copy "$PWD" "${!tags[@]}" || tscommand "mv $(printf "'%s' " "${!tags[@]}") '$PWD'" ; tags=() ; cdir ; } ;;
	r      ) cdir ;; # directory content change signal
	${K[r]}) rm "$n/montage.png" 2>&- && { exec 7>&- ; w3iproc= ; kill $w3iproc &>/dev/null ; pw3start ; } ; list ;;
	R      ) ((${#tags[@]})) && bulkrename || { prompt "rename ${files[file]##*/} to: " && [[ $REPLY ]] && mv "${files[file]}" "$REPLY" ; } ; cdir ;;
	s      ) ((show_size ^= 1)) || { ((show_size ^= 1)) ; ((show_dir_size ^= 1)) ; } || show_size=0 ; cdir ;;
	S      ) (($in_vipreview)) && in_vipreview= && pane_id= ;;
	t|${K[t]}) sdir= ; [[ $REPLY == t ]] && sdir='-d1' ; fzf_tag T "$(fd . -H --color=always $sdir | fzf-tmux -p 90% -m --ansi --info=inline --layout=reverse --marker '▪')" ; list ;;
	T      ) fzf_tag U "$(cat $fs/tags | lscolors | fzf-tmux -p 90%  -m --ansi --info=inline --layout=reverse --marker '⊟')" ; list ;;
	${SK[t]}) [[ "${tail[$n]}" ]] && unset -v "tail[$n]" || tail[$n]="+$ " ; list ;;
	u|U    ) [[ $REPLY == u ]] && for p in "${files[@]}" ; do tags["$p"]='▪' ; done || tags=() ; list ;;
	${K[u]}) tcpreview ; fzf_go "$(printf "%s\n" "${!tags[@]}" | sort -u | lscolors | fzf --ansi --info=inline --layout=reverse)" ;;
	v|V    ) [[ $REPLY == V  ]] && preview=1 || ((preview_all ^= 1)) ; ((${preview:-$preview_all})) || { wcpreview ; tcpreview ; } ; echo $pane_id >$fs/preview_pane ; cdir ;;
	${K[v]}) [[ "$montage_preview" ]] && montage_preview= || montage_preview="⠶ " ; list ;;
	+      ) ((zoom += 1, zoom >= ${#zooms[@]})) && zoom=0 ; zoom ; [[ $pane_id ]] && tresize $pane_id $x || cdir ;; 
	\-     ) [[ "$pdir_only" ]] && pdir_only= || pdir_only='- ' ; list ;;
	\#     ) [[ $e ]] && { ((pignore[${e}] ^= 1)) ; cdir ; } ;;
	w|W    ) external=1 ; [[ $REPLY == W  ]] && detached=1 ; list ;;
	x|X    ) [[ $REPLY == x ]] && mode=a+x || mode=a-x ; chmod $mode "${selection[@]}" ; cdir ;;
	${K[x]}) [[ $e =~ gpg ]] && tmux popup -h90% -w90% "gpg -d $n" || gpg -e -u "$GPGID" -r "$(gpg -K | grep uid | cut -d' ' -f 13- | fzf)" "$f" || read -sn1 ; cdir '' "$f.gpg" ;;
	y|Y    ) tag_flip "${files[file]}" ; ((nfiles == 1)) && list || { [[ $REPLY == Y ]] && R=k || R=j ; } ;;
	${K[y]}) cat $fs/tags | xsel -b -i ;; 
	Z|q|Q|\@) [[ $REPLY == Z ]] && { exit_mplayer=1 ; quit ; } || close_tab || pane_close || quit ;;
	z      ) quit2 ; [[ $pane_id ]] && { tmux selectp -t $pane_id ; tmux resizep -Z -t $pane_id ; } ; exit 0 ;;
	${K[z]}) [[ $e =~ gpg ]] && prompt 'file: ' -e && [[ -n "$REPLY" ]] && gpg -d "$n" > "$REPLY" || gpg --output "$f.gpg" --symmetric "$f" || read -sn1 ; cdir '' "$REPLY" ;;
	\§     ) tabs+=("$PWD") ; ((tab = ${#tabs[@]} - 1)) ; cdir ;;
	\?     ) vipreview ~/.config/ftl/README.md ; in_pdir=0 ;;
	$'\t'  ) ((${#tabs[@]} > 1)) && { ((tab += 1, tab >= ${#tabs[@]})) && tab=0 ; cdir ${tabs[tab]} ; } ;;
	½      ) tcpreview ; tsplit "ftl ${files[file]} '' 0" 50% -h -R ; ftl2_pane=$pane_id ; pane_id= ; cdir ; tmux send -t $ftl2_pane v ;;
	\:     ) prompt ':' ; [[ $REPLY =~ -?[0-9]+ ]] && list $((REPLY > 0 ? (REPLY -1) : 0)) || shell_command "$REPLY" ;; 
	\'     ) read -n 1 ; [[ -n ${marks[$REPLY]} ]] && cdir ${marks[$REPLY]} || list ;;
	\"     ) ((no_image_preview ^= 1)) ; for e in $(tr '|' ' ' <<< "$ifilter") ; do pignore[${e}]=$no_image_preview ; done ; ((zoom == 0)) && R='-' ; cdir ;;
	\%|\&  ) [[ $REPLY == \% ]] && { [[ $e ]] && ((lignore[${e}] ^= 1)); } || lignore=() ; cdir ;;
	\*     ) prompt 'depth: ' && [ "$REPLY" -eq "$REPLY" ] 2>&- && max_depth=$REPLY && cdir ;;
	.      ) ((show_hidden)) && show_hidden= || show_hidden=1 ; cdir ;;
	${K[.]}) ((etag^=1)) ; cdir ;;
	/|\\   ) [[ $REPLY == / ]] && dir= || dir="-t d" ; tcpreview ; fzf_go "$(fd . $dir --color=always -L | fzf --ansi --info=inline --layout=reverse)" ;;
	\{     ) tcpreview ; fzf_go "$(fzfppv -L)" ;;
	\}     ) tcpreview ; rg_go "$(fzfr)" ;;
	\$|${K[s]}) [[ $shell_id ]] && tmux selectp -t $shell_id &>/dev/null || shell_pane ; [[ $REPLY == \ß ]] && tmux resizep -Z -t $shell_id ;;
	\!     ) tcpreview ; cmd=$(cat $ftl_root/commands | awk '!seen[$0]++' | fzf --tac --info=inline --layout=reverse)
		 prompt 'ftl> ' -ei "$cmd" ; [[ $REPLY ]] && { echo $REPLY >>$ftl_root/commands ; shell ; } ; cdir ;;
	\>|\<|_) [[ $REPLY == \> ]] && pane_ftl || { [[ $REPLY == \< ]] && pane_ftl '-h -b' -R || pane_ftl '-v' -U ; } ; cdir ; sstate ;;
	\=     ) pane_read ; tp=("${panes[@]}" "${panes[@]}") ; pf=0 ;
			for p in "${tp[@]}" ; do ((pf)) && tmux selectp -t $p &>/dev/null && tpop $p && tmux send -t $p r && break || [[ $p == $my_pane ]] && pf=1 ; done ;;
	\|     ) pane_k && tcpreview && cdir ;;
	\^     ) ((show_stat ^= 1)) ; refresh ; list ;;
	\)     ) ((show_files ^= 1)) || { ((show_file ^= 1)) ; ((show_dirs ^= 1)) ; } || show_files=0 ; ((show_files || show_dirs)) || { show_files=1 ; show_dirs=0 ; } ; cdir ;;
esac
}

cdir() { inotify_k ; get_dir "$@" ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; refresh ; list "${3:-$found}" ; inotify_s ; }
get_dir() # dir, search
{
new_dir="${1:-$PWD}" ; [[ -d "$new_dir" ]] || return ; [[ "$PPWD" != "$PWD" ]] && PPWD="$PWD" ; marks[$'\'']="$PPWD"; PWD="$new_dir" ; tabs[tab]="$PWD"
files=() ; files_color=() ; mime=() ; nfiles=0 ; search="${2:-$(((dir_file[$PPWD])) || echo "$find_auto")}" ; found= ; shopt -s nocasematch
geometry ; ((${preview:-$preview_all})) && [[ -z $pane_id ]] && ((COLS=(COLS-1) * (100 - ${zooms[zoom]}) / 100))

cd "$PWD" 2>$fs/error || { refresh ; /bin/cat $fs/error ; return ; } ; ((etag)) && ext_dir
((gpreview)) || echo "$PWD" | tee -a $fs/history >> $ftl_root/history ; [[ "$PWD" == / ]] && sep= || sep=/

declare -A uniq_file ; pad=(*) ; pad=${#pad[@]} ; pad=${#pad} ; line=0 ; sum=0 ; local LANG=C LC_ALL=C ; dir &
while : ; do read -s -u 4 -t 0.07 p ; [ $? -gt 128 ] && break ; read -s -u 5 pc ; read -s -u 6 size
	((${uniq_file[$p]})) && continue ; uniq_file[$p]=1
	((quick_display && nfiles > 0 && 0 == nfiles % quick_display)) && { refresh ; list $found ; in_quick_display=1 ; }
	[[ "$p" =~ '.' ]] && { e=${p##*.} ; ((lignore[${e@Q}])) && continue ; } ; pl=${#p}
	
	((etag)) && { ext_tag "$p" external_tag external_tag_length ; pc="$external_tag$pc" ; ((pl+=external_tag_length)) ; }
	((show_size)) && { ((sum += size)) ; [[ -d "$p" ]] && { ((show_dir_size)) && pc=$(dsize "$p")" $pc" || pc="     $pc" ; } || pc=$(fsize $size)" $pc" ; pl=$((pl + 5)) ; }
	((show_line)) && { ((line++)) ; printf -v pc "\e[2;30m%-${pad}d\e[m $pc" $line ; ((pl += 4)) ; }
	pcl=${pc:0:(( ${#pc} == $pl ? ($COLS - 1) : ( (${#pc} - 4) - $pl ) + ($COLS - 1) )) }
	((${#p} > ($COLS - 1))) && { [[ "$p" =~ '.' ]] && e=….${p##*.} || e=… ; pcl=${pcl:0:((${#pcl} - ${#e}))}$e ; }
	files_color[$nfiles]="$pcl" ; files[$nfiles]="$PWD$sep$p" ; [[ -n "$search" && -z "$found" ]] && [[ "$p" =~ ^$search ]] && found=$nfiles ; ((nfiles++))
done 

shopt -u nocasematch ; in_quick_display=0 ; ((show_size)) && hsum=$(numfmt --to=iec --format ' %4f' "$sum") || hsum=
}

list() # select
{
[[ $1 ]] && dir_file[$PWD]=$1 ; file=${dir_file[$PWD]:-0} ; ((file = file >= nfiles ? nfiles - 1 : file)) ; selection ; sstate "$fs"
((nfiles)) && { parse_path ; wcpreview ; } || { header "\e[33m<Empty>" && tcpreview && return ; }
((top = nfiles < lines || file <= center ? 0 : file >= nfiles - center ? nfiles - lines : file - center)) ; geometry
 
((show_stat)) && stat="$(stat -c ' %A %U' "${files[file]}") $(stat -c %s "${files[file]}" | numfmt --to=iec --format '%4f')" || stat=
header "${pdir_only}ᵐ$imode$hsplit$montage_preview $((file+1))/${nfiles}$hsum$stat"$( ((sort_type == 2 && show_date)) && date -r "${files[file]}" +" %D-%R")

for((i=$top ; i <= ((bottom = top + lines - 1, bottom < 0 ? 0 : bottom)) ; i++))
	do
		cursor=${tags[${files[$i]}]:- } ; [[ $i == $file ]] && cursor="$cursor_color$cursor\e[m"
		echo -ne "\e[K$cursor${files_color[i]}\e[m" ; ((i != bottom)) && echo
	done

((in_quick_display)) || preview ; geometry ; WCOLS=$COLS ; WLINES=$LINES
}

preview()
{
((main || gpreview || preview_all)) || { kbd_flush ; pane_read && echo -en "$n\n$fs\n" >$parent_fs/preview && for p in "${panes[@]}" ; do tmux send -t $p 9 &>/dev/null ; done ; return ; }
old_in_vipreview=$in_vipreview
((external)) && { for external in $(externals) ; do $external && { sleep 0.01 ; list ; return ; } ; done ; } ; external= ; detached= ; 
((${preview:-$preview_all})) && { preview= ; for v in $(previewers) ; do $v && vcpreview && return ; done ; }
wcpreview ; tcpreview
}

edir()      { [[ -d "$n" ]] && {  vlc "$n" &>/dev/null & } ; }
ehtml()     { [[ $e == 'html' ]] && { ((detached)) && { (qutebrowser "$n" 2>&- &) ; } || { tcpreview ; w3m -o confirm_qq=0 "$n" ; } ; } ; } 
eimage()    { [[ $e =~ ^($ifilter)$ ]] && run_maxed fim -a "$n" "$PWD" ; }
emedia()    { [[ $e =~ ^(mp3|mp4|flv|mkv)$ ]] && { ((! detached)) && { mplayer_k ; mplayer -vo null "$n" </dev/null &>/dev/null & } && mplayer=$! || vlc "$n" &>/dev/null & } ; }
epdf()      { [[ $e == pdf ]] && { ((detached)) && (zathura "$n" &) || run_maxed zathura "$n" ; true ; } ; }
etext()     { tcpreview ; tsplit "$EDITOR ${n@Q}" "33%" '-h -b' -R ; pane_id= ; }
pdir()      { [[ -d "$n" ]] && { pdir_image || pdir_dir ; } || { in_pdir= ; pdir_only ; } ; }
pdir_dir()  { ((in_pdir)) && [[ $pane_id ]] && tmux send -t $pane_id 0 || { arg=${1:-$p} ; ctsplit "ftl ${arg@Q} $fs 1" ; in_pdir=1 ; } ; }
pdir_image(){ [[ "$montage_preview" ]] && { in_pdir= ; [[ -e "$n/montage.png" ]] || do_montage "$n" ; [[ -e "$n/montage.png" ]] && pw3image "$n/montage.png" ; } ; }
do_montage(){ < <(IFS='\n' fd -a -t f -e ${ifilter//|/ -e} -d 1 . "$1" | head -n 30) mapfile -t args ; ((${#args[@]})) && montage "${args[@]}" "$1/montage.png" ; }
pdir_only() { [[ "$pdir_only" ]]  && { wcpreview ; tcpreview ; true ; } || false  ; }
phtml()     { [[ $e == 'html' ]] &&  w3m -dump "$n" > "$fs/$f.txt" && vipreview "$fs/$f.txt" ; }
pignore()   { [[ $e ]] && ((pignore["${e@Q}"])) && { mime_get ; in_pdir= ; in_vipreview= ; ptype ; true ; } || false ; }
pimage()    { [[ $e =~ ^($ifilter)$ ]] && pw3image || { tbcolor 67 67 && false ; } ; }
plock()     { [[ -e "$fs/lock_preview/$n" ]] && vipreview "$fs/lock_preview/$n" ; }
pmedia()    { [[ $e =~ ^(mp3|mp4|flv|mkv)$ ]] && ctsplit "exiftool ${n@Q} | /bin/less ; read -sn1" ; }
pmp4()      { [[ $e =~ mp4|flv ]] && { t="$ftl_root/thumbs/$f.jpg" ; [[ -f "$t" ]] || ffmpegthumbnailer -i "$n" -o "$t" -s 1024 ; pw3image "$t" ; true ; } ; }
pshell()    { [[ $mtype == 'application/x-shellscript' ]] && vipreview "$n" ; }
ppdf()      { [[ $e == 'pdf' ]] && { pdftotext -l 3 "$n" "$fs/$f.txt" 2>&- && vipreview "$fs/$f.txt" ; } ; }
pperl()     { [[ $mtype =~ ^application/x-perl$ ]] && [[ -s "$n" ]] && vipreview "$n" ; }
ptext()     { { [[ $e =~ ^json|yml$ ]] || [[ $mtype =~ ^text ]] ; } && [[ -s "$n" ]] && vipreview "$n" ; }
ptar()      { [[ $f =~ \.tar ]] && { fp="$fs/$f.txt" ; [[ -e "$fp" ]] || timeout 1 tar --list --verbose -f "$f" >"$fp" ; vipreview "$fp" ; } ; }
ptype()     { ctsplit "echo $f ; echo $mtype ; file -b ${n@Q} ; stat -c %s ${n@Q} | numfmt --to=iec ; read -sn 100" ; }
pw3image()  { tbcolor 0 0 ; tcpreview ; sleep 0.01 ; w3p=1 ; image="${1:-$n}" ; read -r w h < <(identify -format '%w %h' "$image")
		((w==0 || h==0)) && { h=1 ; w=1 ; } ; rw=0 ; rh=0 ; pw3size ; ((w>img_w || h>img_h)) && pw3scale ; echo -e "0;1;$img_x;$img_y;$rw;$rh;;;;;$image\n4;\n3;" >&7 ; }
pw3scale()  { { read rw ; read rh ; } < <(bc <<<"scale=2 ; r=rw=$img_w/$w ; rh=$img_h/$h ; if(rh<rw) r=rh ; if(r>1) r=1 ; scale=0 ; $w*r/1; $h*r/1") ; }
pw3size()   { ((img_y=TOP*20, img_x=(LEFT+COLS) * 10, img_w=(WIDTH-COLS)*10, img_h=((LINES-1))*20)) ; }
pw3start()  { ((w3iproc)) || { mkapipe 7 ; { <&7 /usr/lib/w3m/w3mimgdisplay &> /dev/null & } ; w3iproc=$! ; } ; }
tcpreview() { [[ "$pane_id" ]] && tmux killp -t $pane_id &> /dev/null ; sleep 0.01 ; in_pdir= ; pane_id= ; in_vipreview= ; }
vipreview() { ((in_vipreview)) && { tmux send -t $pane_id ":e ${tail[$1]}$(sed -E 's/\$/\\$/g' <<<"$1")" C-m ; } || ctsplit "$EDITOR -R ${tail[$1]}${1@Q}" ; ((in_vipreview++)) ; true ; }
vcpreview() { ((old_in_vipreview == in_vipreview)) && in_vipreview= ; true ; }
wcpreview() { ((w3p)) && { ctsplit 'read -sn 100' ; sleep 0.01 ; w3p= ; } ; true ; }

bulkrename(){ tcpreview ; bulkedit && bulkverify && { bash $fs/br && tags=() || read -sn 1 ; } ; true ; }
bulkedit()  { /bin/cat $fs/tags | tee $fs/bo > $fs/bd ; $EDITOR $fs/bd ; }
bulkverify(){ echo 'set -e' > $fs/br ; paste $fs/bo $fs/bd | sed 's/^/mv /' >> $fs/br ; $EDITOR $fs/br ; }
by_name()   { sort $show_reversed -t ' ' -k3 | tee >(cut -f 1 -d ' ' >&6) | cut -f 3- -d' ' ; }
by_size()   { sort $show_reversed -n         | tee >(cut -f 1 -d ' ' >&6) | cut -f 3- -d' ' ; }
by_date()   { sort $([[ -z "$show_reversed" ]] && echo '-r') -t ' ' -k2 | tee >(cut -f 1 -d ' ' >&6) | cut -f 3- -d' ' ; }
close_tab() { ((${#tabs[@]} > 1)) && { unset -v 'tabs[tab]' ; tabs=("${tabs[@]}") ; ((tab--)) ; R=$'\t' ; true ; } ; }
ctsplit()   { [[ $pane_id ]] && tmux respawnp -k -t $pane_id "$1" &> /dev/null || tsplit "$1" ; }
copy()      { [[ -d "$1" ]] && dir=r || dir= ; tscommand "cp -v$dir $(printf "'%s' " "${@:2}") '$1'" ; } 
delete()    { prompt "delete$1? [y|d|N]: " -n1 && [[ $REPLY == y || $REPLY == d ]] && { rip "${selection[@]}" ; tags=() ; mime=() ; cdir ; } ; }
dir()       { ((show_dirs)) && files "-type d,l -xtype d" filter2 ; files "-xtype l" filter ; ((show_files)) && files "-type f,l -xtype f" filter ; }
dsize()     { printf "\e[94m%4s\e[m" $(find "$1/" -mindepth 1 -maxdepth 1 ${show_hidden:+\( ! -iname '.*' \)} -type d,f,l -xtype d,f -printf "1\n" 2>&- | wc -l) ; } 
edit()      { tcpreview ; echo -en '\e[?1049h' ; "${EDITOR}" "${1:-${files[file]}}"; echo -en '\e[?1049h\e[?25h' ; cdir ; }
ffind()     { [[ $1 == n ]] && { ((from = file + 1)) ; to=$nfiles ; inc='++' ; } || { ((from = file - 1)) ; to=-1 ; inc='--' ; }
		for ((i=$from ; i != $to ; i$inc)) ; do [[ "${files[i]##*/}" =~ "$to_search" ]] && { list $i ; return ; } ; done ; list ; }
files()     { find "$PWD/" -mindepth 1 -maxdepth $max_depth ${show_hidden:+\( ! -iname ".*" \)} $1  -printf "$find_format" 2>&- | ftl_filter | $2 ; }
filter()    { rg $ntfilter "${tfilters[tab]}" | rg "${filters[tab]}" | rg "${filters2[tab]}" | { [[ "${rfilters[tab]}" ]] && cat | rg -v "${rfilters[tab]}" || cat ; } | filter2 ; }
filter2()   { ${sort_filters[sort_type]} | tee >(cat >&4) | lscolors >&5 ; }
fsize()     { numfmt --to=iec --format '\e[94m%4f\e[m' $1 ; }
ftl_imode() { (($1)) && { ntfilter= ; tfilters[tab]="$ifilter$" ; dir_file[$PWD]= ; } || tfilters[tab]= ; }
ftl_nimode(){ tfilters[tab]="$ifilter$" ; ntfilter='-v' ; dir_file[$PWD]= ; }
fzf_go()    { [[ "$1" ]] && { [[ -d "$1" ]] && cdir "$1" || cdir "$(dirname "$1")" "$(basename "$1")" ; } || { refresh ; list ; } ; }
fzf_tag()   { [[ "$2" ]] && while read f ; do [[ "$1" == U ]] && unset -v "tags[$f]" || tags[$PWD/$f]='▪' ; done <<<$2 ; }
geometry()  { read -r TOP WIDTH LINES COLS LEFT< <(tmux display -p -t $my_pane '#{pane_top} #{window_width} #{pane_height} #{pane_width} #{pane_left}') ; }
header()    { h="${@} $((tab+1))/${#tabs[@]} $filter_tag${sort_name[sort_type]}$show_reversed ${#tags[@]}" ; header_pos "$h" ; echo -e "\e[H\e[K\e[94m${PWD:hpl} \e[95m${h:hal}\e[m" ; }
header_pos(){ hal=$((${#1} - ($COLS - 1))) ; hpl=$((${#PWD} + (hal < 0 ? hal : 0) )) ; ((hal = hal < 0 ? 0 : hal, hpl = hpl < 0 ? 0 : hpl)) ; }
inotify_s() { inotify_ & : ; ino1=$! ; ino2=$(ps --ppid $! | grep inotifywait | awk '{print $1}') ; }
inotify_()  { inotifywait --exclude index.lock -e create -e delete "$PWD/" &>/dev/null && tmux send -t "$my_pane" r 2>&- ; } 
inotify_k() { kill $ino1 $ino2 2>&- ; }
kbd_flush() { while read -t 0.01 ; do : ; done ; }
location()  { true 2>&- >&3 && { [[ $REPLY == 'Q' ]] && echo "${files[file]}" >&3 || :>&3 ; } ; }
mime_get()  { ((remote)) && mtype=$(mimemagic "$n") || mime_cache ; false ; }
mime_cache(){ [[ ${mime[file]} ]] || mime+=($(mimemagic "${files[@]:${#mime[@]}:((file + 10))}" 2>&1 | sed -e "s/cannot.*/n\/a/" -e 's/^.*: //')) ; mtype="${mime[file]}" ; false ; }
mkapipe()   { for n in "$@" ; do PIPE=$(mktemp -u) && mkfifo $PIPE && eval "exec $n<>$PIPE" && rm $PIPE ; done ; }
move()      { ((nf = file + $1, nf = nf < 0 ? 0 : nf > nfiles - 1 ? nfiles - 1 : nf)) ; dir_file[$PWD]=$nf ; list ; }
movep()     { ((in_vipreview)) && tmux send -t $pane_id C-$1 ; }
mplayer_k() { ((mplayer)) && kill $mplayer &>/dev/null || pkill mplayer ; } 
my_pane()   { while read -s pi pp ; do [[ $$ == $pp ]] || [[ $(ps -o pid --no-headers --ppid $pp | rg $$) ]] && my_pane=$pi && break ; done < <(tmux lsp -F '#{pane_id} #{pane_pid}') ; }
pane_ftl()  { pane_read ; [[ -d "$n" ]] && arg="$n" || arg="$PWD" ; tcpreview ; tsplit "preview_all=0 ftl ${arg@Q} $fs" "30%" "$1" $2 && { np=$pane_id ; panes+=($np) ; pane_id= ; }
		 { printf "%s\n" "${panes[@]}" ; echo $my_pane ; } >$parent_fs/panes ; echo $np ; }
pane_close(){ panes_wout "$my_pane" ; ((main && ${#panes[@]})) && { tmux send -t ${panes[0]} q 2>&- ; cat $fs/panes | grep -v "${panes[0]}" | sponge $fs/panes ; } || false ; }
panes_wout(){ pane_read ; for i in ${!panes[@]} ; do  if [ "${panes[$i]}" == "$1" ] ; then  unset panes[$i] ;  fi ; done ; panes=("${panes[@]}") ; }
pane_k()    { ((main)) && { pane_read && for p in "${panes[@]}" ; do [[ $p != $my_pane ]] && tmux send -t $p Z &>/dev/null ; done ; } && rm $parent_fs/panes && panes=() ; }
pane_read() { [[ -s $parent_fs/panes ]] && readarray -t panes < <(tmux list-panes -F "#{pane_left} #{pane_id}" | sort -h | grep -w -f $parent_fs/panes | cut -d' ' -f 2) || false ; }
parse_path(){ n="${1:-${files[file]}}" ; p="${n%/*}" ; f="${n##*/}" ; b="${f%.*}" ; [[ "$f" =~ '.' ]] && e="${f##*.}" || e= ; }
prompt()    { stty echo ; echo -ne '\e[999B\e[0;H\e[K\e[33m\e[?25h' ; read -rp "$@" ; echo -ne '\e[m' ; stty -echo ; }
quit()      { wcpreview ; tcpreview ; pane_k ; rm -rf $fs ; quit2 ; quit_shell ; tmux kill-session -t ftl$$ &>/dev/null ; exit 0 ; }
quit2()     { inotify_k ; location ; stty echo ; [[ $parent_fs == $fs ]] && tbcolor 236 52 ; ((exit_mplayer)) && mplayer_k ; kill $w3iproc &>/dev/null ; refresh "\e[?25h\e[?1049l" ; }
quit_shell(){ [[ $REPLY != @ ]] && tmux killp -t $shell_id &> /dev/null ; }
rdir()      { get_dir ; in_quick_display=1 ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; refresh ; list ; in_quick_display=0 ; }
refresh()   { echo -ne "\e[?25l\e[2J\e[H\e[m$1" ; }
rg_go()     { [[ "$1" ]] && { g=${1%%:*} && nd="$PWD/"$(dirname "$g") && cdir "$nd" "$(basename "$g")" ; } || { refresh ; list ; } ; }
run_maxed() { run_maxed=1 ; ((run_maxed)) && { aw=$(xdotool getwindowfocus -f) ; xdotool windowminimize $aw ; } ; "$@" ; ((run_maxed)) && { wmctrl -ia $aw ; } ; }
selection() { selection=() ; ((${#tags[@]})) && selection+=("${!tags[@]}") || { ((nfiles)) && selection=("${files[file]}") ; } ; }
shell()     { tcpreview ; echo -en '\e[?1049l' ; parse_path ; s="${selection[@]}" ; shell_run ; read -sn 1 ; echo -en '\e[?1049h' ; }
shell_run() { [[ $REPLY =~ "\$s" ]] && { eval "$REPLY" ; echo '$?': $? ; } || for n in "${selection[@]}" ; do eval "echo -e '\e[7;34mftl\> $REPLY\e[m' ; $REPLY" ; echo '$?': $? ; done ; }
shell_pane(){ wcpreview ; tcpreview ; opi=$pane_id ; tsplit /bin/bash 30% -v -U "-e ftl_root=$fs" ; shell_id=$pane_id ; pane_id=$opi ; cdir ; tmux selectp -t $shell_id ; }
sstate()    { printf "%s\n" "${selection[@]}" >${1:-$fs}/tags ; ((!nfiles)) && echo >${1:-$fs}/ftl || { echo "${files[file]}" >${1:-$fs}/ftl ; sstateftl2 "${1:-$fs}" ; } ; }
sstateftl2(){ echo -e "${dir_file[${files[file]}]}\n$imode\n$etag\n$sort_type\n$show_size\n$show_dir_size\n${filters[tab]}\n${filters2[tab]}\n" >>${1:-$fs}/ftl ; }
synch()     { synch_read ; filters2[tab]="$pfil2" ; filters[tab]="$pfil" ; [[ $pfi ]] && filter_tag="~" ; ftl_imode "$pimode" ; tag_read "$parent_fs" ; cdir "$pdir" "$2" "$pindex" ; }
synch_read(){ [[ -e "$parent_fs/ftl" ]] && { for r in pdir pindex pimode etag sort_type show_size show_dir_size pfil pfil2 ; do read $r ; done ; } < $parent_fs/ftl ; }
tag_flip()  { [[ ${tags[$1]} ]] && unset -v 'tags[$1]' || tags[$1]='▪' ; } 
tag_read()  { tags=() ; [[ -e "$1/tags" ]] && { readarray -t stags < "$1/tags" ; for stag in "${stags[@]}" ; do tags[${stag//\\ / }]='▪' ; done ; } ; }
tbcolor()   { tmux set pane-border-style "fg=color$1" ; tmux set pane-active-border-style "fg=color$2" ; sleep 0.01 ; }
tpop()      { read -r PLEFT PTOP< <(tmux display -p -t $1 '#{pane_left} #{pane_top}') && tmux popup -E -h 3 -w 3 -x $PLEFT -y $(($PTOP + 3)) "sleep 0.07 ; true" ; }
tresize()   { tmux resizep -t $1 -x $2 &>/dev/null ; rdir ; }
tscommand() { tmux new -A -d -s ftl$$ ; tmux neww -t ftl$$ -d "echo ftl\> ${1@Q} ; $1 ; echo \$\?: $? ; read -sn2 -t 1800" ; }
tsplit()    { tmux sp $5 -t $my_pane -e n="$n" ${3:--h} -l ${2:-${zooms[zoom]}%} -c "$PWD" "$1" && { sleep 0.03 ; pane_id=$(tmux display -p '#{pane_id}') && tmux selectp ${4:--L} ; } ; }
winch()     { winch= ; geometry ; { ((!w3p)) && [[ "$WCOLS" != "$COLS" ]] || [[ "$WLINES" != "$LINES" ]] ; }  && cdir ; }
zoom()      { geometry ; [[ $pane_id ]] && read -r COLS_P < <(tmux display -p -t $pane_id '#{pane_width}') || COLS_P=0 ; ((x = ( ($COLS + $COLS_P) * ${zooms[$zoom]} ) / 100)) ; }

. ~/.config/ftl/ftl.et ; . ~/.config/ftl/ftl.eb ; ftl "$@"
