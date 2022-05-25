#!/bin/env bash

ftl() # directory, search, pfs, preview. © Nadim Khemir 2020-2022, Artistic licence 2.0
{
tab=0 ; tabs+=("$PWD") ; ntabs=1 ; : ${prev_all:=1} ; : ${pdir_only[tab]:=} ; : ${find_auto:=README} ; max_depth[tab]=1 ; : ${zoom:=0} ; zooms=(70 50 30) ; mh='Creating montage ...'
tbcolor 67 67 ; quick_display=256 ; cursor_color='\e[7;34m' ; : ${imode[tab]:=0} ; lmode[tab]=0 ; : ${show_line:=1} ; show_size=0 ; show_date=1 ; show_tar=0 ; : ${etag:=0} ;
ifilter='webp|jpg|jpeg|JPG|png|gif'; mfilter='mp3|mp4|flv|mkv'; : ${sort_type0:=0} ; sort_filters=('-k3' '-n' '-k2') ; fzf_opt="-p 80% --cycle --reverse --info=inline --color=hl:214" 
sglyph=( ⍺ 🡕 ) ; iglyph=('' ᴵ ᴺ) ; lglyph=('' ᵈ ᶠ) ; tglyph=('' ¹ ² ³ D) ; ftl_cfg="$HOME/.config/ftl" ; pgen="$ftl_cfg/generators"

declare -A dir_file mime pignore lignore tail tags ntags ftl_env ; ftl_root=$ftl_cfg/var ; ftl_cmds=$ftl_root/cmds ; ghist=$ftl_root/history ; dir_done=56fbb22f2967 ; RM="rm -rf"
mkapipe 4 5 6 ; echo -en '\e[?1049h' ; stty -echo ; my_pane=$(pid_2_pane $$) ; thumbs=$ftl_root/thumbs ; mkdir -p $thumbs ; $pushd "$dir" &>/dev/null

[[ "$1" ]] && { [[ -d "$1" ]] && { dir="$1" ; search='' ; } || { [[ -f "$1" ]] && { path "$1" ; dir="${p}" ; search="$f" ; } ; } || { echo ftl: \'$1\', no such path ; exit 1 ; } ; }
[[ "$2" ]] && { fs=$2/$$ ; pfs=$2 ; mkdir -p $fs ; touch $fs/history ; } || { fs=$ftl_root/$$ ; pfs=$fs ; main=1 ; mkdir -p $fs/prev ; touch $ghist ; echo $my_pane >$fs/pane ; } ;
fsp=$pfs/prev ; declare -A marks=([0]=/$ [1]="$HOME/$") ; . ~/.ftlrc || . ~/.config/ftl/ftlrc; marks[$"'"]="$(tail -n1 $ghist)"
[[ "$3" ]] && { gpreview=1 ; prev_all=0 ; emode=0 ; PPWD="$dir" ; prev_synch ; true ; } || { PPWD="$dir" ; cdir "$dir" "$search" ; }

while : ; do winch ; { [[ "$R" ]] && { REPLY="${R:0:1}" ; R="${R:1}" ; } || read -sn 1 -t 0.3 ; } && bindings ; kbdf ; winch=1 ; REPLY= ; done
}

bindings()
{
ext_bindings || case "${REPLY: -1}" in
	${C[hexedit]})		tcpreview ; ctsplit "hexedit ${n@Q}" ;;
	${C[help]})		<~/.config/ftl/help fzf-tmux $fzf_opt --tiebreak=begin --header="$(echo -e "\t\t\t")""⇑: alt-gr, ⇈: shift+alt-gr, ˽: leader" ; list ;;
	h|D)			[[ "$PWD" != / ]]  && { nd="${PWD%/*}" ; cdir "${nd:-/}" "$(basename "$p")"; } ;;
	j|B|k|A)		((nfiles)) && { [[ $REPLY == j || "$REPLY" == B ]] && { move 1 && list ; true ; } || { move -1 && list ; } ; } ;;
	l|C|'')			((nfiles)) && { [[ -f "${files[file]}" ]] && { [[ $REPLY == '' ]] && edit ; true ; } || cdir "${files[file]}" ; } ;;
	5|6)			[[ $REPLY == 5 ]] && { move -$LINES && list ; true ; } || { move $LINES && list ; } ;;
	${C[top]})		dir_file["${tab}_$PWD"]=0 ; list ;;
	${C[bottom]})		((dir_file["${tab}_$PWD"] = nfiles - 1)) ; list ;;
	${C[preview_down]})	((in_vipreview)) && tmux send -t $pane_id C-D ;;
	${C[preview_up]})	((in_vipreview)) && tmux send -t $pane_id C-U ;;
	1|2|3|4)		[[ ${tags[${files[file]}]} == ${tglyph[$REPLY]} ]] && unset -v "tags[${files[file]}]" || tags[${files[file]}]=${tglyph[$REPLY]} ; move 1 ; list ;;
	${C[pdh]}) 		[[ -f $pfs/pdh ]] && { R="${C[pdh_kill]}$R" ; } || { tcpreview ; tsplit "$ftl_cfg/fpdh $pfs" 30% -v -R ; pane_id= ; } ; cdir ;;
	${C[pdh_kill]})		[[ -f $pfs/pdh ]] && { read pdh <$pfs/pdh ; [[ $pdh ]] && tmux killp -t $pdh &>/dev/null ; rm $pfs/pdh ; } ;;
	${C[cd]})		prompt 'cd: ' ; [[ -n $REPLY ]] && cdir "${REPLY/\~/$HOME}" || list ;;
	${C[chmod_x]})		mode=a+x ; chmod $mode "${selection[@]}" ; cdir ;;
	${C[chmod_minus_x]})	mode=a-x ; chmod $mode "${selection[@]}" ; cdir ;;
	${C[clear_filters]})	filters[tab]= ; filters2[tab]= ; rfilters[tab]= ; ntfilter[tab]= ; filter_rst ; ftag= ; cdir ;;
	${C[command_fzf]})	prompt "ftl> " -i "$(shell_hist)" ; [[ $REPLY ]] && { echo $REPLY >>$ftl_cmds ; shell_run shell_eval ; } ; cdir ;;
	${C[command_prompt]})	echo -ne "\e[H" ; tput cnorm ; stty echo ; C=$(cmd_prompt) ; stty -echo ; tput civis ; [[ "$C" ]] && { header "$head" ; shell_command "$C" ; } || list ;;
	${C[command_mapping]})	for k in "${!C[@]}" ; do echo $k ${C[$k]} ; done | sort | column -c 160 | fzf-tmux $fzf_opt --tiebreak=begin --header="Commands mapping" ; list ;;
	${C[copy]})		prompt 'cp to: ' && [[ $REPLY ]] && { tag_check && cp_mv_tags p "$REPLY" || cp_mv p "$REPLY" "${selection[@]}" ; } ; cdir ;;
	${C[copy_clipboard]})	printf "%q " "${selection[@]}" | xsel -b -i ;;
	${C[create_bulk]})	tcpreview ; : >$fs/bc ; $EDITOR $fs/bc && perl -i -ne 'if(m-^.$i-){ if(m-/$-){ print "mkdir $_" }else{ print "touch $_" }}' $fs/bc && bash $fs/bc ; cdir ;;
	${C[create_dir]})	prompt 'mkdir: ' && [[ "$REPLY" ]] && mkdir -p "$PWD/$REPLY" && cdir "$PWD/$REPLY" || list ;;
	${C[create_file]})	prompt 'touch: ' && [[ "$REPLY" ]] && touch "$PWD/$REPLY" ; cdir "$PWD" "$REPLY" ;;
	${C[delete]})		tag_check && { delete_tag ; true ; } || delete '' "${selection[@]}" ;;
	${C[depth]})		prompt 'depth: ' && [ "$REPLY" -eq "$REPLY" ] 2>&- && max_depth[tab]=$REPLY && cdir '' "$f" ;;
	${C[editor_detach]})	((in_vipreview)) && in_vipreview= && pane_id= && cdir ;;
	${C[external_mode1]})	emode=1 ; preview ;;
	${C[external_mode2]})	emode=2 ; preview ;;
	${C[external_mode3]})	emode=3 ; preview ;;
	${C[external_mode4]})	emode=4 ; preview ;;
	${C[file_dir_mode]})	((lmode[tab]--)) ; ((lmode[tab] < 0)) && lmode[tab]=2 ; cdir '' "$f" ;;
	${C[filter]})		prompt "filter: " -i "${filters[tab]}" ; filters[tab]="$REPLY" ; ftag="~" ; cdir '' "$f" ;;
	${C[filter2]})		prompt "filter2: " -i "${filters2[tab]}" ; filters2[tab]="$REPLY" ; ftag="~" ; cdir '' "$f" ;;
	${C[filter_ext]})	p=~/.config/ftl/external_filters ; file=$(cd $p ; fd | fzf-tmux ) ; [[ $file ]] && . $p/$file $fs ; cdir '' "$f";;
	${C[filter_reverse]}) 	prompt "rfilter: " -i "${rfilters[tab]}" ; rfilters[tab]="$REPLY" ; ftag="~" ; cdir '' "$f";;
	${C[find]})		prompt "find: " -i to_search ; R="${C[find_next]}" ;;
	${C[find_next]})	for ((i=file + 1 ; i != $nfiles ; i++)) ; do [[ "${files[i]##*/}" =~ "$to_search" ]] && { list $i ; return ; } ; done ; list ;;
	${C[find_previous]})	for ((i=file - 1 ; i != -1 ; i--)) ; do [[ "${files[i]##*/}" =~ "$to_search" ]] && { list $i ; return ; } ; done ; list ;;
	${C[find_fzf_all]})	tcpreview ; fzf_go "$(fd -HI -E'.git/*' | fzf_vpreview +m --cycle --expect=ctrl-t --reverse --header="$PWD")" ;;
	${C[find_fzf_dirs]})	tcpreview ; fzf_go "$(fd -td -I -L | fzf_vpreview +m --cycle --expect=ctrl-t --reverse --header="$PWD")" ;;
	${C[find_fzf]})		tcpreview ; fzf_go "$({ fd -HI -d1 -td | sort ; fd -HI -d1 -tf -tl | sort ; } | fzf_vpreview +m --cycle --expect=ctrl-t --reverse --header="$PWD")" ;;
	${C[gmark]})		{ cat $ftl_root/marks 2>&- ; [[ -d "$n" ]] && echo "$n/\$" || echo "$n" ; } | awk '!seen[$0]++' | sponge $ftl_root/marks ;;
	${C[gmark_fzf]})	[[ -e $ftl_root/marks ]] && fzf_go "$(cat $ftl_root/marks | lscolors | fzf-tmux $fzf_opt --cycle --expect=ctrl-t --ansi)" ;;
	${C[gmarks_clear]})	prompt 'clear persistent marks? [y|N]' -sn1 && [[ $REPLY == y ]] && :>$ftl_root/marks ; list ;;
	${C[go_fzf]})		tcpreview ; fzf_go "$(fzfppv --expect=ctrl-t)" ;;
	${C[go_rg]})		tcpreview ; fzf_rg_go "$(fzfr "fzf--expect=ctrl-t")" ;;
	${C[history]})		h=$fs/history ; dedup $h && fzf_go "$(<$h lscolors | fzf-tmux $fzf_opt --tac --ansi --expect=ctrl-t)" ;;
	${C[ghistory]})		h=$ghist ; dedup $h && fzf_go "$(<$h lscolors | fzf-tmux $fzf_opt --tac --ansi --expect=ctrl-t)" ;;
	${C[ghistory2]})	h=$ghist ; dedup $h && fzf_go "$(<$h lscolors | fzf-tmux $fzf_opt --tac --ansi --expect=ctrl-t)" ;;
	${C[ghistory_clear]})	prompt 'clear global history? [y|N]' -sn1 && [[ $REPLY == y ]] && rm $ghist 2>&- ; list ;;
	${C[ghistory_edit]})	dedup $ghist && rg -v -x -F -f <(<$ghist lscolors | fzf-tmux $fzf_opt --tac -m --ansi) $ghist | sponge $ghist ;;
	${C[image_fzf]})	tcpreview ; fzf_go "$(fzfi --expect=ctrl-t -q "$(echo "$ifilter" | perl -pe 's/(^|\|)/ $1 ./g')")" ;;
	${C[image_mode]})	((imode[tab]--)) ; ((imode[tab] < 0)) && imode[tab]=2 ; ftl_imode ; cdir '' "$f";;
	${C[link]})		tag_check && prompt "Link (${#tags[@]})? [y|N]" -sn1 ; [[ $REPLY == y ]] && tags=() && for f in "${selection[@]}" ; do ln -s -b "$f" . ; done ; cdir ;;
	${C[mark_fzf]})		fzf_go "$(printf "%s\n" "${marks[@]}" | sort -u | lscolors | fzf-tmux $fzf_opt --expect=ctrl-t --ansi)" ;;
	${C[mark_go]})		read -n 1 ; [[ -n ${marks[$REPLY]} ]] && { dir="$(dirname "${marks[$REPLY]}")" ; cdir "$dir" '' "${dir_file[${tab}_$dir]}" ; } || list ;;
	${C[mark_go_tab]})	read -n 1 ; [[ -n ${marks[$REPLY]} ]] && { dir="$(dirname "${marks[$REPLY]}")" ; tab_new "$dir" ; cdir "$dir" '' "${dir_file[${tab}_$dir]}" ; } || list ;;
	${C[mark]})		read -sn1 ; [[ -n $REPLY ]] && marks[$REPLY]="${files[file]}" ;;
	${C[montage_clear]})	[[ -d "$n" ]] && { rm "$ftl_root/montage/$n/montage.jpg" 2>&- ; pw3image FTL_RESTART_W3M ; list ; } ;;
	${C[montage_preview]})	[[ "$montage" ]] && montage= || montage="⠶" ; list ;;
	${C[mplayer_kill]})	mplayer_k ;;
	${C[pane_down]})	pane_extra "-v" "" ;;
	${C[pane_left]})	pane_extra "-h -b" '' ;;
	${C[pane_right]})	pane_ftl "'$n' $pfs" "-h -b" -R ; [[ "$n" ]] && rdir "$n" ;;
	${C[pane_R]})		pane_extra "" "" ;;
	${C[pane_L]})		pane_extra "-h -b" "-R" ;;
	${C[pane_next]})	p=$(pane_next) ; tmux selectp -t $p &>/dev/null && tpop $p && tmux send -t $p ${C[refresh]} ;;
	${C[preview]})		((prev_all ^= 1)) ; tcpreview ; sleep 0.05 ; cdir ;;
	${C[preview_once]})	preview=1 ; tcpreview ; sleep 0.05 ; cdir ;;
	${C[preview_dir_only]}) [[ "${pdir_only[tab]}" ]] && pdir_only[tab]= || pdir_only[tab]='⁼' ; list ;;
	${C[preview_ext_ign]})	[[ $e ]] && { ((pignore[${e}] ^= 1)) ; cdir ; } ;;
	${C[preview_hide_ext]})	[[ $e ]] && ((lignore[${e}] ^= 1)) ; cdir ;;
	${C[preview_hide_cl]})	lignore=() ; cdir ;;
	${C[preview_image]})	((no_image_preview ^= 1)) ; for e in $(tr '|' ' ' <<< "$ifilter") ; do pignore[${e}]=$no_image_preview ; done ; ((zoom == 0)) && R=${C[refresh]} ; cdir ;;
	${C[preview_lock_cl]})	rm "$fs/lock_preview/$n" 2>&- ; list ;;
	${C[preview_lock]})	p=~/.config/ftl/lock_preview ; file=$(cd $p ; fd | fzf-tmux $fzf_opt) ; [[ $file ]] && . $p/$file ; list ;;
	${C[preview_m1]})	extmode=1 ; list ;;
	${C[preview_m2]})	extmode=2 ; list ;;
	${C[preview_show]})	[[ $e =~ $mfilter ]] && { (~/.config/ftl/viewers/cmus "${selection[@]}" & ) ; ((${#tags[@]})) && { tags=() ; list ; } ; } ;;
	${C[preview_show_fzf]})	p=~/.config/ftl/viewers ; viewer=$(cd $p 2>&- && fd | fzf-tmux -p80% --cycle --reverse --info=inline) ; [[ $viewer ]] && . $p/$viewer ; list ;;
	${C[preview_size]})	((zoom += 1, zoom >= ${#zooms[@]})) && zoom=0 ; zoom ; [[ $pane_id ]] && tmux resizep -t $pane_id -x $x &>/dev/null ; rdir ; ;;
	${C[preview_tail]})	[[ "${tail[$n]}" ]] && unset -v "tail[$n]" || tail[$n]='+$ ' ; list ;;
	${C[quit]})		tab_close || pane_close || quit ;;
	${C[quit_keep_shell]})	tab_close || pane_close || quit ;;
	${C[quit_all]})		((main)) && { pane_send "${C[quit]}" ; sleep 0.05 ; R=${C[quit]} ; in_Q=1 ; } || tmux send -t $main_pane ${C[quit_all]}  ;;
	${C[quit_keep_zoom]})	quit2 ; [[ $pane_id ]] && { echo >$pfs/pane ; tmux selectp -t $pane_id ; tmux resizep -Z -t $pane_id ; } ; exit 0 ;;
	${C[refresh]})		((nfiles)) && path "${files[file]}" || f= ; tag_check ; cdir "$PWD" "$f" ;;  # directory content change signal
	${C[rename]})		tag_check &&  bulkrename || { prompt "rename $f to: " -i "$f" && [[ $REPLY ]] && mv "${files[file]}" "$REPLY" && f="$REPLY" ; } ; cdir '' "$f" ;;
	${C[shell]})		[[ $shell_id ]] && tmux selectp -t $shell_id &>/dev/null || shell_pane ;;
	${C[shell_view]})	shell_run ;;
	${C[shell_zoomed]})	[[ $shell_id ]] && tmux selectp -t $shell_id &>/dev/null || shell_pane ; tmux resizep -Z -t $shell_id ;;
	${C[show_etag]})	((etag^=1)) ; cdir ;;
	${C[show_hidden]})	((show_hidden[tab])) && show_hidden[tab]= || show_hidden[tab]=1 ; cdir '' "$f" ;;
	${C[show_size]})	((show_size ^= 1)) || { ((show_size ^= 1)) ; ((show_dir_size ^= 1)) ; } || show_size=0 ; cdir ;;
	${C[show_stat]})	((show_stat ^= 1)) ; refresh ; list ;;
	${C[sort_reverse]})	[[ ${reversed[tab]} == '-r' ]] && reversed[tab]=0 || reversed[tab]=-r ; cdir '' "$f";;
	${C[sort]})		((sort_type[tab] = sort_type[tab] + 1 >= ${#sort_filters[@]} ? 0 : sort_type[tab] + 1)) ; cdir '' "$f" ;;
	${C[tab_new]})		[[ -d "$f" ]] && tab_new "$n" || tab_new "$PWD" ; cdir ${tabs[tab]} ;;
	${C[tab_next]})		tab_next ; cdir ${tabs[tab]} '' "${dir_file[${tab}_${tabs[tab]}]}";;
	${C[tag_all_files]})	for p in "${files[@]}" ; do [[ -f "$p" ]] && tags["$p"]='▪' ; done ; list ;;
	${C[tag_all]})		for p in "${files[@]}" ; do tags["$p"]='▪' ; done ; list ;;
	${C[tag_copy]})		tag_check && cp_mv_tags $REPLY "$PWD" ; cdir '' "$f";;
	${C[tag_move]})		tag_check && cp_mv_tags $REPLY "$PWD" ; cdir '' "$f";;
	${C[tag_flip]})		tag_flip "${files[file]}" ; move 1 ; list ;;
	${C[tag_flip_up]})	tag_flip "${files[file]}" ; move -1 ; list ;;
	${C[tag_fzf]})		fzf_tag T "$(fd -H --color=always -d1 | fzf-tmux $fzf_opt -m --ansi --marker '▪')" ; list ;;
	${C[tag_fzf_all]})	fzf_tag T "$(fd -H --color=always | fzf-tmux $fzf_opt -m --ansi --marker '▪')" ; list ;;
	${C[tag_goto]})		tag_check && fzf_go "$(printf "%s\n" "${!tags[@]}" | sort -u | lscolors | fzf-tmux $fzf_opt --tac --ansi --expect=ctrl-t)" ;;
	${C[tag_merge]})	p=~/.config/ftl/merge ; file=$(cd $p 2>&- && fd | fzf-tmux --header 'Merge tags:' $fzf_opt) ; [[ $file ]] && . $p/$file ; cdir ;;
	${C[tags_merge_all]})	source ~/.config/ftl/merge/all ; list ;;
	${C[tag_untag_all]})	tags=() ; list ;;
	${C[tag_untag_fzf]})	tag_check && { fzf_tag U "$(printf "%s\n" "${!tags[@]}" | lscolors | fzf-tmux $fzf_opt -m --ansi --marker '⊟')" ; list ; } ;;
	${C[SIG_PANE]})		pane_read ; ((${#panes[@]})) && tmux selectp -t ${panes[0]} || tmux selectp -t $my_pane ; ofs= ; R=${C[refresh]} ;;
	${C[SIG_REFRESH]})	((gpreview)) && kbdf && prev_synch ;;
	${C[SIG_REMOTE]})	((prev_all)) && { read op <$fsp/pane ; prev_synch prev ; tmux selectp -t $op ; kbdf ; } ;;
esac
}

cdir() { inotify_k ; get_dir "$@" ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; ((qd)) || refresh ; list "${3:-$found}" ; true ; }
get_dir() # dir, search
{
new_dir="${1:-$PWD}" ; [[ -d "$new_dir" ]] || return ; PWD="$new_dir" ; tabs[$tab]="$PWD" ; [[ "$PWD" == / ]] && sep= || sep=/
[[ "$PPWD" != "$PWD" ]] && { marks["'"]="$n" ; PPWD="$PWD" ; ((gpreview)) || echo "$n" | tee -a $fs/history >> $ghist ; }

cd "$PWD" 2>$fs/error || { refresh ; cat $fs/error ; return ; } ; inotify_s ; ((etag)) && etag_dir ; shopt -s nocasematch ; geo_prev
files=() ; files_color=() ; mime=() ; nfiles=0 ; search="${2:-$([[ "${dir_file[${tab}_$PPWD]}" ]] || echo "$find_auto")}" ; found= ; s_type=$sort_type0 ; s_reversed=$sort_reversed0
[[ -f .ftlrc_dir ]] && . .ftlrc_dir ; s_type=${sort_type[tab]:-$s_type} ; [[ "${reversed[tab]}" == "-r" ]] && s_reversed=-r || { [[ "${reversed[tab]}" == "0" ]] && s_reversed= ; }

$ftl_cfg/generators/generator $thumbs &

declare -A uniq_file ; pad=(* ?) ; pad=${#pad[@]} ; pad=${#pad} ; line=0 ; sum=0 ; local LANG=C LC_ALL=C ; dir &
while : ; do read -s -u 4 p ; [ $? -gt 128 ] && break ; read -s -u 5 pc ; read -s -u 6 size
	[[ $p == $dir_done ]] && break ; ((${uniq_file[$p]})) && continue ; uniq_file[$p]=1
	((quick_display && nfiles > 0 && 0 == nfiles % quick_display)) && { refresh ; qd=1 ; list $found ; }
	[[ "$p" =~ '.' ]] && { e=${p##*.} ; ((lignore[${e@Q}])) && continue ; } ; pl=${#p}
	((etag)) && { etag_tag "$p" external_tag external_tag_length ; pc="$external_tag$pc" ; ((pl+=external_tag_length)) ; }
	((show_size)) && { ((sum += size, pl += 5)) ; [[ -d "$p" ]] && { ((show_dir_size)) && pc="$(dsize "$p") $pc" || pc="     $pc" ; true ; } \
			 || { for u in '' K M G T ; do ((size < 1024)) && printf -v pc "\e[94m%4s\e[m $pc" $size$u && break ; ((size/=1024)) ; done  ; } ; }
	((show_line)) && { ((line++)) ; printf -v pc "\e[2;30m%-${pad}d\e[m¿${pc/\%/%%}" $line ; ((pl += 4)) ; }
	pcl=${pc:0:(( ${#pc} == $pl ? ($COLS - 1) : ( (${#pc} - 4) - $pl ) + ($COLS - 1) )) }
	((pl > (COLS - 1))) && { [[ "$p" =~ '.' ]] && e=${p##*.} || e= ; pcl=${pcl:0:((${#pcl}-(${#e}+1)))}…${e} ; }
	files_color[$nfiles]="$pcl" ; files[$nfiles]="$PWD$sep$p" ; [[ -n "$search" && -z "$found" ]] && [[ "${p:0:${#search}}" == "$search" ]] && found=$nfiles ; ((nfiles++))
done

shopt -u nocasematch ; qd=0 ; ((show_size)) && hsum=$(numfmt --to=iec --format ' %4f' "$sum") || hsum= ; flips=(' ' ' ') #space, EM-space
}

list() # select
{
[[ $1 ]] && dir_file[${tab}_$PWD]=$1 ; file=${dir_file[${tab}_$PWD]:-0} ; ((file = file > nfiles - 1 ? nfiles - 1 : file))

((nfiles)) && path "${files[file]}" || path_none ; save_state $fs ; selection
((ntabs>1)) && tabsd=' ᵗ'$((tab+1)) || tabsd= ; 
head="${lglyph[lmode[tab]]}${iglyph[imode[tab]]}${pdir_only[tab]}${montage}" ; head=${head:+$head }
((nfiles)) && { ((qd)) || ((flipi^=1)) ; flip="${flips[$flipi]}" ; } || { head="\e[33m∅ $head$ftag$tabsd" ; header "$head" ; tcpreview ; geo_winch ; return ; }

((show_stat)) && stat="$(stat -c ' %A %U' "${files[file]}") $(stat -c %s "${files[file]}" | numfmt --to=iec --format '%4f')" || stat= ;
((s_type == 2 && show_date)) && date=$(date -r "${files[file]}" +' %D-%R') || date= ; head="$head$ftag$((file+1))/${nfiles}$hsum$stat$date$tabsd$flip" ; header "$head"

((top = nfiles < lines || file <= center ? 0 : file >= nfiles - center ? nfiles - lines : file - center, bottom = top + lines - 1, bottom = bottom < 0 ? 0 : bottom)) ; geo_winch
for((i=$top ; i <= bottom ; i++))
	do
		cursor=${tags[${files[$i]}]:- } ; [[ $i == $file ]] && cursor="${cursor_color}$cursor\e[m"
		echo -ne "\e[m\e[K$cursor${files_color[i]/¿/$flip}" ; ((i != bottom)) && echo
	done

for(( ; i < ((LINES - 1)) ; i++)) ; do echo -ne "\e[K$flip" ; ((i != LINES)) && echo ; done
((qd || gpreview)) || { geo_winch ; preview ; }
}

preview() # force_preview
{
((main || prev_all)) || { pane_read ; save_state ; echo "$fs" >$fsp/fs ; echo $my_pane >$fsp/pane ; tmux send -t $main_pane ${C[SIG_REMOTE]} &>/dev/null ; return ; }

((emode)) && { for external in $(externals) ; do $external && { sleep 0.1 ; emode=0 ; return ; } ; done ; } ; emode=0 ;
((${1:-${preview:-$prev_all}})) && { preview= ; for v in $(previewers) ; do $v && { extmode=0 ; return ; } ; done ; extmode=0 ; }
tcpreview
}

ewith()     { . ~/.config/ftl/open_with ; }
edir()      { [[ -d "$n" ]] && {  vlc "$n" &>/dev/null & } ; }
ehtml()     { [[ $e =~ html ]] && { ((emode == 1)) && { tcpreview ; w3m -o confirm_qq=0 "$n" ; } || { (qutebrowser "$n" 2>&- &) ; } ; } ; }
eimage()    { [[ $e =~ $ifilter ]] && run_maxed fim -a "$n" "$PWD" ; }
emedia()    { [[ $e =~ $mfilter ]] && { ((emode == 1)) && { mplayer_k ; mplayer -vo null "$n" </dev/null &>/dev/null & } || (vlc "$n" &>/dev/null &) ; R="${C[refresh]}$R" ; } ;  }
epdf()      { [[ $e == pdf ]] && { ((emode == 1)) && epdf_vi || { ((emode == 2)) && (mupdf "$n" 2>/dev/null &) && true ; } || { ((emode == 3)) && run_maxed mupdf "$n" ; } ; } ; }
epdf_vi()   { t="$thumbs/pdf/${f}1.txt" ; [[ -e $t ]] || $pgen/pdf "$f" $thumbs/pdf 1 && edit "$t" ; true ; }
etext()     { { [[ $e =~ ^json|yml$ ]] || [[ $mtype =~ ^text ]] ; } && [[ -s "$n" ]] && { tcpreview ; tsplit "$EDITOR ${n@Q}" "33%" '-h -b' -R ; pane_id= ; } ; }
pcbr()      { [[ $e == cbr ]] && { t="$thumbs/cbr/$f.jpg" ; [[ -e $t ]] || $pgen/cbr "$f" "$thumbs/cbr" ; pw3image "$t" ; true ; } ; }
pcbz()      { [[ $e == cbz ]] && { t="$thumbs/cbz/$f.jpg" ; [[ -e $t ]] || $pgen/cbz "$f" "$thumbs/cbz" ; pw3image "$t" ; true ; } ; }
pdir()      { [[ -d "$n" ]] && { [[ "$montage" ]] && pdir_image "$n" || { echo "${ofs:-$fs}" >$fsp/fs ; pdir_dir "$n" ; } ; } || { in_pdir= ; pdir_only ; } ; }
pdir_dir()  { ((in_pdir)) && [[ $pane_id ]] && tmux send -t $pane_id ${C[SIG_REFRESH]} || { tmux selectp -t $my_pane ; ctsplit "ftl ${1@Q} $fs 1" ; in_pdir=1 ; } ; }
pdir_image(){ in_pdir= ; m="$ftl_root/montage/$1/montage.jpg" ; [[ -e "$m" ]] || { header "$mh" ; "$pgen/montage" "$ftl_root" "$1" ; header "$head" ; } ; pw3image "$m" ; }
pdir_only() { [[ "${pdir_only[tab]}" ]]  && { tcpreview ; true ; } || false  ; }
phtml()     { [[ $e == html ]] &&  { t="$thumbs/html/$f.txt" ; [[ -e $t ]] || $pgen/html "$f" "$thumbs/html" ; vipreview "$t" ; } ; }
pignore()   { [[ $e ]] && ((pignore["${e@Q}"])) && { mime_get ; in_pdir= ; in_vipreview= ; ptype ; true ; } || false ; }
pimage()    { [[ $e =~ $ifilter ]] && pw3image ; }
plock()     { [[ -e "$fs/lock_preview/$n" ]] && vipreview "$fs/lock_preview/$n" ; }
pmp3()      { [[ $e == mp3 ]] && { pmlive || { ctsplit "/bin/less -R <$(gen_exift) ; read -sn1" ; } ; } ; }
pmp4()      { [[ $e =~ mkv|mp4|flv ]] && { pmlive || { t="$thumbs/$e/$f.png" ; [[ -f "$t" ]] || $pgen/$e "$f" "$thumbs/$e"; pw3image "$t" ; true ; } ; } ; }
pmlive()    { ((extmode)) && { mplayer_k ; ctsplit "cat $(gen_exift) ; mplayer -msglevel all=-1 -msglevel statusline=6 -nolirc -msgcolor -novideo -vo null \"$n\"" ; true ; } ; }
pshell()    { [[ $mtype == 'application/x-shellscript' ]] && vipreview "$n" ; }
ppdf()      { [[ $e == pdf ]] && { ((extmode==2)) && ppdfpng || { t="$thumbs/pdf/$f$extmode.txt" ; [[ -e $t ]] || $pgen/pdf "$f" $thumbs/pdf $extmode && vipreview "$t" ; } ; true ; } ; }
ppdfpng()   { t="$thumbs/$e/et_$(head -c50000 "$n" | md5sum | cut -f1 -d' ').png" ; [[ -f "$t" ]] || { mutool draw -o "$t" "$n" 1 2>/dev/null ; } ; pw3image "$t" ; true ; }
pperl()     { [[ $mtype == application/x-perl ]] && [[ -s "$n" ]] &&  vipreview "$n" ; }
ptext()     { { [[ $e =~ ^json|yml$ ]] || [[ $mtype =~ ^text ]] ; } && [[ -s "$n" ]] && vipreview "$n" ; }
ptar()      { [[ $f =~ \.tar ]] && ((show_tar || extmode)) && { fp="$fs/$f.txt" ; [[ -e "$fp" ]] || timeout 1 tar --list --verbose -f "$f" >"$fp" ; vipreview "$fp" ; } ; }
ptype()     { ctsplit "echo '$f' ; echo '$mtype' ; file -b ${n@Q} ; stat -c %s ${n@Q} | numfmt --to=iec ; read -sn 100" ; true ; }
pw3image()  { image="${1:-$n}" ; ((in_ftli)) && tmux send -t $pane_id "${image}" C-m || { ctsplit "ftli $pfs \"${image}\"" ; in_ftli=1 ; sleep 0.05 ; tmux selectp -t $my_pane ; } ; }
tcpreview() { [[ "$pane_id" ]] && { tmux killp -t $pane_id &> /dev/null ; in_pdir= ; pane_id= ; in_vipreview= ; in_ftli= ; sleep 0.01 ; } ; }
vipreview() { ((in_vipreview)) && tmux send -t $pane_id ":e ${tail[$1]}$(sed -E 's/\$/\\$/g' <<<"$1")" C-m || ctsplit "$EDITOR -R ${tail[$1]}${1@Q}" ; in_vipreview=1 ; true ; }
bulkrename(){ bulkedit && bulkverify && { bash $fs/br && tags=() || read -sn 1 ; } ; true ; }
bulkedit()  { printf "%s\n" "${!tags[@]}" | sed "s/.*/\"&\"/" | tee $fs/bo >$fs/bd ; $EDITOR $fs/bd && { >$fs/br echo 'set -e' ; paste $fs/bo $fs/bd >>$fs/br ; } ; }
bulkverify(){ perl -i -ne '/^([^\t]+)\t([^\t]+)\n/ && { $1 ne $2 && print "mv $1 $2\n" } || print' $fs/br ; $EDITOR $fs/br ; }
cmd_prompt(){ trap 'echo -ne "\e[A\e[K" ; stty -echo ; tput civis' SIGINT ; echo $(rlwrap -p'0;33' -S 'ftl > ' -f $ftl_cfg/cmd_names -H $ftl_root/cmd_history -o cat) ; trap - SIGINT ; }
ctsplit()   { { in_pdir= ; in_vipreview= ; in_ftli= ; } ; [[ $pane_id ]] && tmux respawnp -k -t $pane_id "$1" &> /dev/null || tsplit "$1" ; }
cp_mv()     { [[ $1 == ${C[tag_copy]} ]] && cmd="cp -vr" || cmd=mv ; tscommand "$cmd $(printf '%q ' "${@:3}") ${2@Q}" ; }
cp_mv_tags(){ declare -A ltags ; tag_get ltags class ; ((${#ltags[@]})) && { cp_mv $1 "$2" "${!ltags[@]}" ; tag_clear $class ; } ; true ; }
dedup()     { [[ -s "$1" ]] && { tac "$1" | awk '!seen[$0]++' | tac | sponge "$1" ; true ; } ; }
delete()    { prompt "delete$1? [y|d|N|c]: " -n1 && [[ $REPLY =~ y|d|c ]] && { [[ $REPLY == c ]] && $RM "$n" || $RM "${@:2}" ; mime=() ; cdir "" "" $file ; }  || { list ; false ; } ; }
delete_tag(){ declare -A ltags ; tag_get ltags class ; ((${#ltags[@]})) && delete " *tags: ${#ltags[@]}* " "${!ltags[@]}" ; [[ $REPLY =~ y|d ]] && tag_clear $class ; }
dir()       { ((lmode[tab]<2)) && files "-type d,l -xtype d" filter2 ; files "-xtype l" filter ; ((lmode[tab]!=1)) && files "-type f,l -xtype f" filter ; dir_done ; }
dir_done()  { echo "$dir_done" >&4 ; echo '' >&5 ; echo 0 >&6 ; }
def_sub()   { for def in "$@" ; do local sub=${def%%:*} ; local body=${def:((${#sub}+1))} ; type "$sub" &>/dev/null || eval "$sub(){ ${body:-:} ; }" ; done ; }
dsize()     { printf "\e[94m%4s\e[m" $(find "$1/" -mindepth 1 -maxdepth 1 ${show_hidden[tab]:+\( ! -iname '.*' \)} -type d,f,l -xtype d,f -printf "1\n" 2>&- | wc -l) ; }
edit()      { tcpreview ; echo -en '\e[?1049h' ; inotify_k ; "${EDITOR}" "${1:-${files[file]}}"; echo -en '\e[?1049h\e[?25h' ; emode=0 ; cdir ; }
files()     { find "$PWD/" -mindepth 1 -maxdepth ${max_depth[tab]:-1} ${show_hidden[tab]:+\( ! -path "*/.*" \)} $1  -printf '%s\t%T@\t%P\n' 2>&- | ftl_filter | $2 ; }
filter()    { rg ${ntfilter[tab]} "${tfilters[tab]}" | rg "${filters[tab]}" | rg "${filters2[tab]}" | { [[ "${rfilters[tab]}" ]] && rg -v "${rfilters[tab]}" || cat ; } | filter2 ; }
filter2()   { ftl_sort | tee >(cat >&4) | lscolors >&5 ; }
filter_rst(){ eval 'ftl_filter(){ cat ; } ; ftl_sort(){ sort_by ; } ; sort_glyph(){ echo ${sglyph[s_type]} ; }' ; }
ftl_env()   { ftl_env=([ftl_pfs]=$pfs [ftl_fs]=$fs) ; for i in "${!ftl_env[@]}" ; do echo -n "${1:--e} $i=${ftl_env[$i]} " ; done ; }
ftl_imode() { ((imode[tab] == 2)) && { tfilters[tab]="$ifilter$" ; ntfilter[tab]='-v' ; } || { ((imode[tab])) && { ntfilter[tab]= ; tfilters[tab]="$ifilter$" ; } || tfilters[tab]= ; } ; }
fzf_go()    { { IFS= read e ; IFS= read p ; } <<<"$1" ; [[ "$p" ]] && { d="$(dirname "$p")" ; [[ -n $e ]] && tab_new "$d" ; cdir "$d" "$(basename "$p")" ; } || list ; }
fzf_rg_go() { { IFS= read e ; IFS= read p ; } <<<"$1" ; [[ "$p" ]] && { g=${p%%:*} && d="$PWD/"$(dirname "$g") ; [[ -n $e ]] && tab_new "$d" ; cdir "$d" "$(basename "$g")" ; } || list ; }
fzf_tag()   { [[ "$2" ]] && while read f ; do [[ "$1" == U ]] && unset -v "tags[$f]" || tags[$PWD/$f]='▪' ; done <<<$2 ; }
gen_exift() { t="$thumbs/$e/et_$(head -c50000 "$n" | md5sum | cut -f1 -d' ')" ; [[ -e $t ]] || $ftl_cfg/generators/$e "$f" "$thumbs/$e" ; echo $t ; }
geometry()  { read -r TOP WIDTH LINES COLS LEFT< <(tmux display -p -t $my_pane '#{pane_top} #{window_width} #{pane_height} #{pane_width} #{pane_left}') ; }
geo_prev()  { geometry ; ((${preview:-$prev_all})) && [[ -z $pane_id ]] && ((COLS=(COLS-1) * (100 - ${zooms[zoom]}) / 100)) ; }
geo_winch() { geometry ; WCOLS=$COLS ; WLINES=$LINES ; }
header()    { h="${@}$(sort_glyph)$s_reversed$( ((${#tags[@]})) && echo " ${#tags[@]}")" ; header_pos "$h" ; echo -e "\e[H\e[K\e[94m${PWD:hpl} \e[95m${h:hal}\e[m" ; }
header_pos(){ hal=$((${#1} - ($COLS - 1))) ; hpl=$((${#PWD} + (hal < 0 ? hal : 0) )) ; ((hal = hal < 0 ? 0 : hal, hpl = hpl < 0 ? 0 : hpl)) ; }
inotify_s() { inotify_ & : ; ino1=$! ; ino2=$(ps --ppid $! | grep inotifywait | awk '{print $1}') ; }
inotify_()  { inotifywait --exclude 'index.lock|(.*\.sw.?)' -e create -e delete -e move "$PWD/" 2>&- | { read a b f ; [[ "$f" ]] && tmux send -t "$my_pane" ${C[refresh]} 2>&- ; } ; }
inotify_k() { [[ $ino1 ]] && { kill $ino1 $ino2 2>&- ; ino1= ; ino2= ; } ; }
kbdf()      { [[ $REPLY != $'\e' && $REPLY != "[" && $leader_command != 1 ]] && while read -t 0.01 ; do : ; done ; }
cdfl()      { true 2>&- >&3 && { [[ $REPLY == ${C[quit]} ]] && ((! in_Q)) && echo "${files[file]}" >&3 || echo >&3 ; } ; }
mime_get()  { [[ "${mime[$n]}" ]] || { mime_cache ; mime[$n]="$(mimemagic "$n")" ; } ;  mtype="${mime[$n]}" ; false ; }
mime_cache(){ while IFS=$': ' read fm mm ; do mime[$PWD/$fm]="$mm" ; done < <(mimemagic "${files[@]:$file:((file + 20))}" 2>&1) ; }
mkapipe()   { for arg in "$@" ; do PIPE=$(mktemp -u) && mkfifo $PIPE && eval "exec $arg<>$PIPE" && rm $PIPE ; done ; }
move()      { ((nf = file + $1, nf = nf < 0 ? 0 : nf >= nfiles ? nfiles - 1 : nf)) ; ((nf != file)) && dir_file[${tab}_$PWD]=$nf ; }
mplayer_k() { ((mplayer)) && { kill $mplayer &>/dev/null ; mplayer= ; } ; }
pane_extra(){ pane_ftl "'$n' $pfs" "$1" "$2" ; sleep 0.05 ; rdir ; tmux selectp -t $new_pane ; }
pane_ftl()  { pane_read ; tcpreview ; tsplit "prev_all=0 ftl $1" 30% "$2" $3 ; panes+=($pane_id) ; new_pane=$pane_id ; pane_id= ; printf "%s\n" "${panes[@]}" >$pfs/panes ; }
pane_close(){ pane_read ; ((main && ${#panes[@]})) && { tail -n +2 $pfs/panes | sponge $pfs/panes ; tmux send -t ${panes[0]} ${C[quit]} 2>&- ; sleep 0.03 ; } ; }
pane_next() { pane_read ; pf=0 ; tp=("${panes[@]}" $main_pane "${panes[@]}") ; for p in  "${tp[@]}" ; do [[ $p == $my_pane ]] && pf=1 || { ((pf)) && echo $p && break ; } ; done ; }
pane_read() { <$pfs/pane read main_pane ; [[ -s $pfs/panes ]] && mapfile -t panes < <(grep -w -f <(tmux lsp -F "#{pane_id}") $pfs/panes) ; printf "%s\n" "${panes[@]}" >$pfs/panes ; }
pane_send() { pane_read && for p in "${panes[@]}" ; do tmux send -t $p "$1" &>/dev/null ; done ; }
path()      { n="$1" ; [[ "$n" =~ / ]] && p="${n%/*}" || p= ; [[ ${p:0:1} != "/" ]] && p="$PWD/$p" ; f="${n##*/}" ; b="${f%.*}" ; [[ "$f" =~ '.' ]] && e="${f##*.}" || e= ; }
path_none() { n= ; p= ; f= ; b= ; e= ; }
pdh()       { [[ -f $pfs/pdh ]] && { read pdh <$pfs/pdh ; [[ $pdh ]] && tmux send -t $pdh "ftl: $my_pane: ${1//\\n/$'\n'}" ; } ; true ; }
pid_2_pane(){ while read -s pi pp ; do [[ $1 == $pp ]] || [[ $(ps -o pid --no-headers --ppid $pp | rg $$) ]] && echo $pi && break ; done < <(tmux lsp -F '#{pane_id} #{pane_pid}') ; }
prev_synch(){ read ofs <$fsp/fs ; . "$ofs/tags" ; . "$ofs/ftl" ; ftl_imode "${imode[tab]}" ; [[ $1 ]] && { path "$n" ; preview ; } || cdir "$sdir" '' "$sindex" ; ofs= ; }
prompt()    { stty echo ; echo -ne '\e[H\e[K\e[33m\e[?25h' ; read -e -rp "$@" ; echo -ne '\e[m' ; stty -echo ; tput civis ; }
quit()      { tcpreview ; quit2 ; quit_shell ; tmux kill-session -t ftl$$ &>/dev/null ; ((!main)) && { pane_read ; tmux send -t $main_pane ${C[SIG_PANE]} ; } ; rm -rf $fs ; exit 0 ; }
quit2()     { inotify_k ; stty echo ; [[ $pfs == $fs ]] && tbcolor 236 52 ; mplayer_k ; kill $w3iproc &>/dev/null ; refresh "\e[?25h\e[?1049l" ; cdfl ; }
quit_shell(){ [[ $REPLY != ${A[q]} ]] && [[ $shell_id ]] && tmux killp -t $shell_id &> /dev/null ; }
rdir()      { get_dir "$1" ; ((lines = nfiles > LINES - 1 ? LINES - 1 : nfiles, center = lines / 2)) ; qd=1 ; list ; qd=0 ; }
refresh()   { echo -ne "\e[?25l\e[2J\e[H\e[m$1" ; }
run_maxed() { run_maxed=1 ; ((run_maxed)) && { aw=$(xdotool getwindowfocus -f) ; xdotool windowminimize $aw ; } ; "$@" 2>/dev/null ; ((run_maxed)) && { wmctrl -ia $aw ; } ; true ; }
selection() { selection=() ; ((${#tags[@]})) && selection+=("${!tags[@]}") || { ((nfiles)) && selection=("${files[file]}") ; } ; }
shell_eval(){ s="${selection[@]}" ; for n in "${selection[@]}" ; do eval "echo -e '\e[2;33m[$(date -R)] $PWD > $REPLY\e[m' ; $REPLY" ; echo '$?': $? ; done ; }
shell_hist(){ [[ -f $ftl_cmds ]] && awk '!seen[$0]++' $ftl_cmds | fzf-tmux $fzf_opt --cycle --tac ; }
shell_pane(){ tcpreview ; op=$pane_id ; tsplit bash 30% -v -U ; shell_id=$pane_id ; pane_id=$op ; cdir ; tmux selectp -t $shell_id ; sleep 0.25 ; tmux send -t $shell_id " '$f'" C-b ; }
shell_run() { tcpreview ; echo -en '\e[?1049l' ; ${1:-:} ; read -sn 1 ; echo -en '\e[?1049h' ; }
sort_by()   { sort $s_reversed ${sort_filters[s_type]} | tee >(cut -f 1 >&6) | cut -f 3- ; }
sort_glyph(){ echo ${sglyph[s_type]} ; }
save_state(){ declare -p tags >$fs/tags ; ((!nfiles)) && { : >${1:-$fs}/ftl ; return ; } ; >${1:-$fs}/ftl echo "\
		sdir=\"${files[file]}\"	; sindex=${dir_file[${tab}_${files[file]}]}	; n=\"$n\"
		imode[tab]=${imode[tab]}; xxx=0						; sort_type[tab]=${sort_type[tab]}
		ftag=$ftag		; filters[tab]=\"${filters[tab]}\"		; filters2[tab]=\"${filters2[tab]}\" 
		etag=$etag		; show_size=$show_size				; show_dir_size=$show_dir_size" ; }
tab_close() { (($ntabs > 1)) && { tabs[$tab]= ; ((ntabs--)) ; tab_next ; cdir ${tabs[tab]} ; } ; }
tab_new()   { dir="$1" ; [[ "$dir" == '.' ]] && dir= ; [[ "$dir" =~ ^/ ]] || dir="$PWD/$dir" ; tabs+=("$dir") && ((tab=${#tabs[@]} - 1, ntabs++)) ; }
tab_next()  { ((tab++)) ; for i in "${tabs[@]:$tab}" TAB_RESET "${tabs[@]}" ; do [[ "$i" == TAB_RESET ]] && tab=0 && continue ; [[ -n "$i" ]] && break ; ((tab++)) ; done ; true ; }
tag_check() { for tag in "${!tags[@]}" ; do [[ -e "$tag" ]] || unset -v "tags[$tag]" ; done ; ((${#tags[@]} != 0)) ; }
tag_class() { tag_ntags ; ((${#ntags[@]}>1)) && { echo "$(printf "%s\n" "${!ntags[@]}" | sort | fzf-tmux .p 80% --cycle --reverse --info=inline )" ; } || echo "${tags[$t]}" ; }
tag_ntags() { ntags=() ; for t in "${!tags[@]}" ; do ntags[${tags[$t]}]=1 ; done ; }
tag_clear() { for t in "${!tags[@]}" ; do [[ "$1" == "${tags[$t]}" ]] && unset -v "tags[$t]" ; done ; }
tag_flip()  { [[ ${tags[$1]} ]] && unset -v "tags[$1]" || tags[$1]=${2:-▪} ; }
tag_get()   { ((${#tags[@]})) && { declare -n rtags="$1" rclass="$2" ; rclass=$(tag_class) ; list ; for t in "${!tags[@]}" ; do [[ $rclass == ${tags[$t]} ]] && rtags[$t]=1 ; done ; } ; }
tbcolor()   { tmux set pane-border-style "fg=color$1" ; tmux set pane-active-border-style "fg=color$2" ; sleep 0.01 ; }
tpop()      { read -r PLEFT PTOP< <(tmux display -p -t $1 '#{pane_left} #{pane_top}') && tmux popup -E -h 3 -w 3 -x $PLEFT -y $(($PTOP + 3)) "sleep 0.07 ; true" ; }
tscommand() { tmux new -A -d -s ftl$$ ; tmux neww -t ftl$$ -d "date ; echo -e \"\nftl\> $1\n\n\" ; $1 ; echo \$\?: $? ; read -sn5 -t 1800" ; }
tsplit()    { tmux sp $(ftl_env) $5 -t $my_pane ${3:--h} -l ${2:-${zooms[zoom]}%} -c "$PWD" "$1" && { sleep 0.03 ; pane_id=$(tmux display -p '#{pane_id}') && tselectp $4 ; } ; }
tselectp()  { tmux selectp -t $pane_id ${1:--L} ; }
winch()     { return ; geometry ; { ((!in_ftli)) && [[ "$WCOLS" != "$COLS" ]] || [[ "$WLINES" != "$LINES" ]] ; } && ((winch)) && R="R=${C[refresh]}$R" && pdh "WINCH" ; }
zoom()      { geometry ; [[ $pane_id ]] && read -r COLS_P < <(tmux display -p -t $pane_id '#{pane_width}') || COLS_P=0 ; ((x = ( ($COLS + $COLS_P) * ${zooms[$zoom]} ) / 100)) ; }

def_sub 'ftl_sort:sort_by' 'ftl_filter:cat' etag_dir etag_tag 'ext_bindings:false' externals previewers ; . ~/.config/ftl/ftl.eb ; [[ $TMUX ]] && ftl "$@" || echo 'ftl: run in tmux'
