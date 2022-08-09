% FTL(1) | General Commands Manual
# NAME

ftl - file manager using tmux panes and live previews

# SYNOPSIS

ftl

ftl [-t file] [directory[/file]]

# OPTIONS

-t file		file contains paths to files to tag
	eg: ftl -t <(find -name 'ftl*') 

# DESCRIPTION

ftl is hyperothodox file manager that leverages tmux, vim and many other
utilities. It's  written in Bash,the language that packs a real punch and
sometimes punches you.

The display consists of pane containing a header and a listing of the files
in a directory and an optional preview

## Hyperorthodox file manager
ftl is hyperothodox, or not at all depending on your preferences, it starts
with two panes, one showing you a directory listing and the other a preview
of the directory entries.

You can chose to remove the preview as well as having multiple panes showing
the same or different directories

Panes are independent instances of ftl that work in synch, each pane can
have its own tabs. 

## Tabs

Tabs are views, to same or different directories, in the same pane. Filters
are per tab so you can have two tabs with different filters.

## File Listing

The directory entries are colored with lscolors

## Header
The header contains these fields:

	<directory> [tilde(filter)] <current/total> <tab> <selected_files> [file_stat]

## preview
if preview is on (on by default), a preview pane is displayed. It can
be switched on and off during the session; it's size can be changed. Some
entry types have multiple previews (IE: directories) that can be accessed
with a keyboard shortcut (Alt-gr+v by default)

## Filtering 
*ftl* can filter the files in the directory to present only those you want to see.

See *Filtering* commands.

## Key bindings

*ftl* uses vim-like key bindings by default, the bindings are defined in the
default ftlrc file.

*ftl* has many commands and thus many bindings. The control key is not used
but the Alt-gr key, in combination with the shift key, is used extensively

### Default bindings

'Alt-gr'+c will open a window with all the current binding

A list of all bindings, in _fzf_, wich allows you to search per key or name.

	map           section  key      command                
	--------------------------------------------------------------------------
	ftl           file     c        copy          copy file to, prompts inline

### User defined bindings

You can override all the keys by creating your own rcfile and using the *bind*
function. See <USER RCFILE, BINDINGS, COMMANDS, ...> for some examples.

	bind function arguments, all mendatory:

		map		map where the binding is saves 
		section		logical group the binding belongs to (hint)
		key		the keyboard key
		command		name of the internal command that is called
		short_ help	help displayed 
              

	eg: bind ftl file k copy "copy file to, prompts inline"

In the default _ftlrc_ file, associative arrays A for alt-gr and SA for
shift+Alt-gr are defined, they allow you to define bindings this way: 

	eg: bin ftl filter "${A[d]}" clear_filters "clear filters"

When bindings are shown _alt-gr_ is replaced by _⇑_ and "_shift+alt-gr_
is replaced by  _⇈_; as well as the key the combination would generate
that makes it easier to search for bindings by typing them. 

## Leader key

The “Leader key” is a prefix key used to extend *ftl* shortcuts by using
sequences of keys to perform a command. The default is '\\'

	# set leader to "space"
	bind ftl bind BACKSPACE_KEY leader_key 'leader key SPACE_KEY

# TOC

- General Ftl Commands
- Command Mode
- Viewing modes
- Panes
- Tabs
- Moving Around
- Preview
- Sorting
- Filtering
- Searching
- Tags/Selection
- Marks
- History
- File and directory operations
- Extra operations
	- Wiping Files
	- Compressing Files
	- Optimizing Files
	- Rmlint
	- Mail
	- Conversion
	- Encrypting Files
- Media
- Shell panes
	- insert files in the shell pane
	- Comparing Files
	- synch shell pane directory to ftl, and ftl directory to shell pane
	- from shell pane to ftl and from ftl to shell pane
	- multiple shell panes

## General Ftl Commands
	⇑c/©	k_bindings		show keyboard bindings

	?	ftl_help		show this help

	q	quit_ftl		quit
	Q	quit_all		quit all panes and tabs at once
	AT	quit_keep_shell		quit but keep shell
	⇈q/Ω	quit_keep_zoom		quit but keep shell zoomed

	$	editor_detach		detach the preview

	G	change_dir		cd

	STAR	depth			maximum listing depth

	⇑t/þ	copy_clipboard		copy selection to clipboard

	¿	pdh_pane		pdh, pane used for debugging

	r	refresh_pane		refresh curent pane

	7	SIG_PANE		handle pane event, reserved for ftl
	8	SIG_REFRESH		preview pane signal, reserved for ftl
	9	SIG_REMOTE		handle pane preview, reserved for ftl
	0	SIG_SYNCH_SHELL		cd to shell pane, reserved for ftl

## Command Mode 
	:	command_promt		run commands: q, etags, load_tags, ...
	!	shel_view	view shell

## Viewing Mode

	⇑s/ß	show_size		show/hide size

	.	show_hidden		show/hide dot-files

	^	show_stat		show/hide stat

	⇑./·	show_etag		show/hide etags

	)	file_dir_mode		file/dir view mode
	M	image_mode		view mode: file/directory/image

	⇑m/µ	montage_preview		montage mode
	⇈m/º	montage_clear		refresh montage

	=	preview_dir_only	preview directory only
	#	preview_ext_ign		show/hide extension preview
	DQUOTE	preview_image		show/hide image preview

	⇈i/ı	image_fzf		fzfi, using ueberzurg

	⍰	preview_lock		preview lock clear

## Panes
	_	pane_down		new pane below

	|	pane_L			new pane left

	¦	pane_R			new pane right

	⇈x/>	pane_right		new pane left

	⇈z/<	pane_left		new pane right

	'-'	pane_go_next		next pane or viewer

	⇈0/°	tag_external	fzf merge from panes
	⇑o/œ	tag_merge_all	merge from panes

## Tabs
	⇈s/§	tab_new			new tab
	TAB	tab_next		next tab

## Moving around
	See *Marks* and *History* below

	*ftl* remembers which entry you were on in a directory

	*ftl* will automatically put you on a README if you haven't visited
	the directory before.
	
	Bindings:

	ENTER	enter			enter; cd or edit file
		edit file if not binary, for binary files try hexedit command

	h	move_left		cd to parent directory
	D	move_left_arrow		cd to parent directory

	j	move_down		down to next entry
	B	move_down_arrow		down to next entry

	k	move_up			up to previous entry
	A	move_up_arrow		up to previous entry

	l	move_right		right; cd into entry
	C	move_right_arrow	right; cd into directory

	5	move_page_up		page down
	6	move_page-down		page up

	g	top_file_bottom		go to top/file/bottom

	K	preview_up		scroll preview up
	J	preview_down		scroll preview down

	ö	goto_alt1		next entry of same extension
	Ö	goto_alt2		next entry of different extension
	ä	goto_entry		goto entry by index

## Preview

	v	preview_pane		preview show/hide
	+	preview_size		change preview size
	V	preview_once		preview once

	⇑v/“	preview_m1		alternative preview for dir, media, pdf, tar, ...
	⇈v/‘	preview_m2		alternative preview for dir, media, pdf, tar, ...

	⇈t/Þ	preview_tail		file preview at end

	⇑x/»	hexedit			hex preview + live editor

## Sorting 

	o	sort_entries		set sort order
	O	sort_entries_reversed	reverse sort order

	⇑f/đ	filter_ext		select a sort order from a list of external sorts

## Filtering
	f	set_filter		set filter #1
	F	set_filter2		set filter #2
	⇑d/ð	clear_filters		clear filters

	⇑f/đ	filter_ext		select a filter from a list of external filters

	⇑a/ª	filter_reverse		set reverse filter

	%	preview_hide_ext	hide extension
	⇈k/&	preview_hide_clr	enable all extensions

## Searchings
	b	find_fzf		fzf find current directory file
	⇑b/”	find_fzf_all		fzf find
	⇈b/’	find_fzf_dirs		fzf find directories

	n	find_next	find next
	N	find_previous	find previous

	/	find_entry		find
	/	incremental_search	start incremental search, 'enter' to end

	{	go_fzf			fzf to file with preview
	}	go_rg			rg to file

## Tags/Selection
	y	tag_flip_down	tag down
	Y	tag_flip_up	tag up

	1	tag_1		class 1 tag
	2	tag_2		class 2 tag
	3	tag_3		class 3 tag
	4	tag_4		class 4 tag

	⇈y/¥	tag_all		tag all files and subdirs
	⇑y/←	tag_all_files	tag all files

	T	tag_fzf_all	fzf tag files and subdirs
	t	tag_fzf		fzf tag files

	u	tag_untag_all	untag all
	U	tag_untag_fzf	untag fzf

	⇑g/ŋ	tag_goto	fzf goto

## Marks

	m	mark		mark directory/file
	QUOTE	mark_fzf	fzf to mark
		QUOTE+QUOTE will take you to the last directory

	⇈'/×	mark_go		go to mark, optionally in new tab

	,	gmark		add persistent mark
	;	gmark_fzf	fzf to persistent mark
	⇑k/ĸ	gmarks_clear	clear persistent marks

## History
	⇑h/ħ	ghistory	fzf history all sessions
	¨	ghistory2	fzf history all sessions
	H	history_go	fzf history current session

	⇈h/Ħ	ghistory_edit	fzf edit all sessions history
	⇈d/Ð	ghistory_clear	delete current session history

## File and directory operations
	i	create_file		creat new file, prompts inline
	I	create_dir		creat new directory, prompts inline
	⇑i/→	create_bulk		creat in files and directories in bulk, uses vim, lines ending with / will create directories

	c	copy			copy file to, prompts inline

	d	delete_selection	delete selection using config $RM

	⇑l/ł	link			symlink selection in current directory
	⇈l/Ł	follow_link		symlink follow

	p	tag_copy		copy selection to current directory
	P	tag_move		move selection to current directory
	⇈p/þ	tag_move_to		move to selection to predefine location using fzf_mv

	R	rename			rename/bulk rename selection using vidir

	x	chmod_x			flip selection executable bit

## Extra commands 
	˽fc	compress		compress/decompress

	˽fi	optimize_image		reduce jpg image size, converts png to jpg

	˽fl	rmlint			run rmlint in current directory

	˽fm	mutt			send selection in mail

	˽fp	optimize_pdf		reduce pdf size

	˽fP	pdf2txt			convert current pdf to text file

	˽fs	stat_file		display stat information for file in preview pane

	˽s	shred			override selection multiple times and deletes it, bypasses config rm -rf, asks for confirmation

	˽ft	shell_pop		terminal popup

	˽fv	optimize_video		reduce video size

	˽fx	gpg_encrypt		GPG encrypt/decrypt

	˽fz	password_encrypt	password encrypt/decrypt

## Media
	e	external_mode1		external viewer, m1
	E	external_mode2		external viewer, m2, detached
	⇑e/€	external_mode3		external viewer, m3
	⇈e/¢	external_mode4		external viewer, m4

	w	preview_show		terminal media player in background
	W	preview_show_fzf	fzf viewer

	a	player_kill		kill sound preview

## Shell panes
	synch shell pane directory to ftl, and ftl directory to shell pane

	moving from shell pane to ftl and from ftl to shell pane

	multiple shell panes

	bindings:
	s	shell		shell pane
	S	shell_files	shell pane with selected files
	⍰	shell_zoomed	shell pane, zoomed out

	⇈0/°	shell_synch	cd to shell pane
	X	shell_file	send selection to shell pane
		Comparing Files

# FILES AND DIRECTORIES

## ftlrc

_ftl_ reads it's configuration from ~/.config/ftl/etc/ftlrc

you can override configuration in your own ~/.ftlrc after sourcing the 
default configuration

# ENVIRONMENT

$FTL_CFG

# CONFIGURATION
See *config/ftl/etc/ftlrc*, ftl's default config file, for a complete documentation 

# INSTALL

see **INSTALL** file

# EXAMPLE RCFILE, BINDINGS, COMMANDS, ...

tbd: examples here

# BUGS AND CONTRIBUTIONS

Report bug to <https://https://github.com/nkh/ftl/issues>

Contributions are best done via pull requests on github. Keep code to minimum.

# AUTHOR

© Nadim Khemir 2020-2022

mailto:nadim.khemir@gmail.com

CPAN/Github ID: NKH

# LICENSE

Artistic licence 2.0

# SEE ALSO

ranger, fff, clifm, lfm, nnn, vifm, broot, gitfm, ...
