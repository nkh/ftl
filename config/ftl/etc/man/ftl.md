% FTL(1) | ftl manual
# NAME

ftl - file manager using tmux panes and live previews

# SYNOPSIS

ftl

ftl [-t file] [directory[/file]]

# OPTIONS

	-t file		file contains paths to files to tag
			eg: ftl -t <(find -name ftl)

# DESCRIPTION

ftl is file manager written in Bash (the language that packs a real punch and sometimes punches you).

The display consists of a header and a listing of the files in a directory, possibly filtered, and an optional preview

## Tabs

Only show images in the listing and directory preview; with multiple tabs, makes sorting images easy.

## Hyperorthodox panes

## Header Components

<directory> [tilde(filter on)] <current_file/total_files> <current_tab> <selected_files> [file_stat]

## Listing

The directory entries are colored with lscolors, if preview is on, a preview pane is displayed

## Display Modes

all files and directories / files only / directories only

## Key bindings

*ftl* uses vim-like key bindings by default, the bindings are defined in the default ftlrc file.

### Default bindings

'Alt-gr'+c will open a window with all the current binding

A list of all bindings is displayed in _fzf_ wich allows you to search per key, name or in the help.

	map           section  key      command                
	-----------------------------------------------------------------------------------
	ftl           file     c        copy                   copy file to, prompts inline

### User defined bindings

You can override all the keys by creating your own rcfile and using the *bind* function.
See <USER DEFINED BINDINGS, COMMANDS, ...> for some examples.

	bind arguments, all mendatory:

		map		map where the binding is saves, ftl is the default map, 
		section		logical group the binding belongs to (hint)
		key		the keyboard key
		command		name of the internal command that is called
		short_ help	help displayed 
              

	eg: bind ftl file k copy "copy file to, prompts inline"

In the default ftlrc file, associative arrays A (for alt-gr) and SA (for shift+Alr-gr) are defined,
they allow you ti define bindings this way: 

	eg: bin ftl filter "${A[d]}" clear_filters "clear filters"

When bindings are shown with 'alt-gr'+c, "${A[d]}" is replaced with "⇑d/ð" wich makes it easier to
search for bindings.

## Leader key

The “Leader key” is a prefix key used to extend ftl shortcuts by using sequences of
keys to perform a command. The default is '\\'

	bind ftl bind BACKSPACE_KEY leader_key 'leader key SPACE_KEY # set leader to "space"

# COMMANDS

- Ftl
- Command Mode
- Panes
- View
- Moving Around
	- Selecting files
	- Sorting
	- Filtering
- Search
	Incremental search
- Tabs
- Tags
- History
- Marks
- File operations
	- Copying Files
	- Moving Files
	- Creating Files
	- Deleting Files
	- Linking Files
	- Renaming Files
	- Changing a file’s mode, owner and group
	- Viewing and Editing Files
	- Searching Files
	- Extra
		- Wiping Files
		- Compressing Files
		- Optimizing Files
		- Rmlint
		- Mail
		- Conversion
		- Encrypting Files
- Directory operations
	- Creating directories
	- Copying directories
	- Deleting directories
	- Moving directories
	- Renaming directories
	- Summarize directory usage
	- Changing directories
- Media
- Shell pane
	- insert files in the shell pane
	- Comparing Files
	- synch shell pane directory to ftl, and ftl directory to shell pane
	- from shell pane to ftl and from ftl to shell pane
	- multiple shell panes

## Ftl
	$ - editor_detach:		detach editor preview

		some very long text which spans mana man many lines, and even more text, in absurdum
		some very long text which spans mana man many lines, and even more text, in absurdum
		some very long text which spans mana man many lines, and even more text, in absurdum

	AT_KEY - quit_keep_shell:	quit keep shell

	⇑c/© - k_bindings:		show keyboard bindings

	? - ftl_help:			show help

	G - change_dir:			cd

	¿ - pdh_pane:			pdh pane

	Q - quit_all:			quit forced

	q - quit_ftl:			quit

	⇈q/Ω - quit_keep_zoom:		keep shell zoomed

	r - refresh_pane:		refresh

	STAR_KEY - depth:		maximum listing depth

	⇑t/þ - copy_clipboard:		copy selection to clipboard

	7 - SIG_PANE:			handle pane event

	7 - SIG_REFRESH:		preview pane signal

	8 - SIG_REMOTE:			handle pane preview

	9 - SIG_SYNCH_SHELL:		cd to shell pane

	˽˽? - leader_space_test:	test leader + space + key

	˽˽t - leader_test:		test leader key

## Panes
	_ - pane_down:		extra pane below

	- - pane_go_next:	next pane or viewer

	| - pane_L:		extra pane: left

	¦ - pane_R:		extra pane: right

	⇈x/> - pane_right:	extra pane left

	⇈z/< - pane_left:	extra pane right


## View

## Moving around
	5 - move_page_up:	page down

	6 - move_page-down:	page up

	ä - goto_entry:		goto entry by index

	A - move_up_arrow:	up to previous entry

	B - move_down_arrow:	down to next entry

	C - move_right_arrow:	right; cd into directory

	D - move_left_arrow:	cd to parent directory

	ENTER_KEY - enter:	enter; cd or open file

	g - top_file_bottom:	go to top/file/bottom

	h - move_left:		cd to parent directory

	j - move_down:		down to next entry

	J - preview_down:	scroll preview down

	k - move_up:		up to previous entry

	K - preview_up:		scroll preview up

	l - move_right:		right; cd into entry

	ö - goto_alt1:		next entry of same extension

	Ö - goto_alt2:		next entry of different extension


## Viewing and Editing Files

## Selecting files


## Sorting 

	O - sort_entries_reversed:	sort reversed

	o - sort_entries:		sort type

## View Mode

	DQUOTE_KEY - preview_image:	show/hide image preview

	) - file_dir_mode:		file/dir view mode

	⇈i/ı - image_fzf:		fzfi, using ueberzurg

	M - image_mode:			view mode: file/directory/image

	⇈m/º - montage_clear:		refresh montage

	⇑m/µ - montage_preview:		montage mode

	= - preview_dir_only:		preview directory only

	⍰ - preview_lock:		preview lock clear

	+ - preview_size:		change preview size

	^ - show_stat:			show/hide stat

	⇑s/ß - show_size:		show/hide size

## Preview

	⇈t/Þ - preview_tail:		file preview at end

	⇑v/“ - preview_m1:		alternative preview for : dir, media, pdf, tar, ...

	⇈v/‘ - preview_m2:		alternative preview for : dir, media, pdf, tar, ...

	V - preview_once:		preview once

	v - preview_pane:		preview show/hide

	⇑x/» - 				hexedit:	hexedit

### Filtering
	⇑a/ª - filter_reverse:	set reverse filter

	⇑d/ð - clear_filters:	clear filters

	⇑f/đ - filter_ext:	select filter

	F - set_filter2:	set filter 2

	f - set_filter:	set filter 1

	⇈k/& - preview_hide_clr:	enable all extensions

	# - preview_ext_ign:	show/hide extension preview

	% - preview_hide_ext:	hide extension

	⇑./· - show_etag:	show/hide etags

	. - show_hidden:	show/hide dot-files


##Search

### Incremental search

	find - /:	incremental_search     start incremental search, press 'enter' to end

## Tabs
	⇈s/§ - tab_new:	new tab

	TAB_KEY - tab_next:	next tab

## Tags
	⇈0/° - tag_external:	fzf merge from panes

	1 - tag_1:	class 1 tag

	2 - tag_2:	class 2 tag

	3 - tag_3:	class 3 tag

	4 - tag_4:	class 4 tag

	⇑g/ŋ - tag_goto:	fzf goto

	⇑o/œ - tag_merge_all:	merge from panes

	T - tag_fzf_all:	fzf tag files and subdirs

	t - tag_fzf:	fzf tag files

	u - tag_untag_all:	untag all

	U - tag_untag_fzf:	untag fzf

	⇈y/¥ - tag_all:	tag all files and subdirs

	⇑y/← - tag_all_files:	tag all files

	y - tag_flip_down:	tag down

	Y - tag_flip_up:	tag up


## History
	⇈d/Ð - ghistory_clear:	delete current session history

	¨ - ghistory2:	fzf history all sessions

	⇈h/Ħ - ghistory_edit:	fzf edit all sessions history

	⇑h/ħ - ghistory:	fzf history all sessions

	H - history_go:	fzf history current session


## Marks
	ALT_QUOTE_KEY - mark_fzf:	fzf to mark

	, - gmark:	add persistent mark

	; - gmark_fzf:	fzf to persistent mark

	⇑k/ĸ - gmarks_clear:	clear persistent marks

	⇈'/× - mark_go:	go to mark, new tab

	m - mark:	mark directory/file

## File operations
	c - copy:	copy file to, prompts inline

	d - delete_selection:	delete selection using config $RM

	⇑i/→ - create_bulk:	creat in files and directories in bulk, uses vim, lines ending with / will create directories

	I - create_dir:	creat new directory, prompts inline

	i - create_file:	creat new file, prompts inline

	⇈l/Ł - follow_link:	symlink follow

	⇑l/ł - link:	symlink selection in current directory

	p - tag_copy:	copy selection to current directory

	P - tag_move:	move selection to current directory

	R - rename:	rename/bulk rename selection using vidir

	⇈t/Þ - tag_move_to:	move to selection to predefine location using fzf_mv

	x - chmod_x:	chmod a+x selection, flips selection executable bit


### Copying Files

### Moving Files

### Creating Files

### Deleting Files

### Linking Files

### Renaming Files

### Changing a file's mode, owner and group

### Searching Files
	⇑b/” - find_fzf_all:	fzf find

	⇈b/’ - find_fzf_dirs:	fzf find directories

	b - find_fzf:	fzf find current directory file

	/ - find_entry:	find

	{ - go_fzf:	fzf to file with preview

	} - go_rg:	rg to file

	n - find_next:	find next

	N - find_previous:	find previous


## Extra commands 
	˽s - shred:	override selection multiple times and deletes it, bypasses config rm -rf, asks for confirmation

	˽fc - compress:	compress/decompress

	˽fi - optimize_image:	reduce jpg image size, converts png to jpg

	˽lm - rmlint:		run rmlint in current directory

	˽fm - mutt:	send selection in mail

	˽fp - optimize_pdf:	reduce pdf size

	˽fP - pdf2txt:	convert current pdf to text file

	˽fs - stat_file:	display stat information for file in preview pane

	˽ft - shell_pop:	terminal popup

	˽fv - optimize_video:	reduce video size

	˽fx - gpg_encrypt:	GPG encrypt/decrypt

	˽fz - password_encrypt:	password encrypt/decrypt

## Directory operations

### Creating directories

### Copying directories

### Deleting directories

### Moving directories

### Renaming directories

### Summarize directory usage

### Changing directories


## Media
	a - player_kill:	kill sound preview

	⇈e/¢ - external_mode4:	external viewer, m4

	⇑e/€ - external_mode3:	external viewer, m3

	e - external_mode1:	external viewer, m1

	E - external_mode2:	external viewer m2, detached

	W - preview_show_fzf:	fzf viewer

	w - preview_show:	terminal media player in background


## Command line

## Starting a shell pane
	⇈0/° - shell_synch:	cd to shell pane

	: - command_promt:	run commands: q, etags, load_tags, ...

	⍰ - shell_zoomed:	shell pane, zoomed out

	! - shel_view:		view shell

	S - shell_files:	shell pane with selected files

	s - shell:		shell pane

	X - shell_file:		send selection to shell pane


### insert files in the shell pane

### Comparing Files

### synch shell pane directory to ftl, and ftl directory to shell pane

### from shell pane to ftl and from ftl to shell pane

### multiple shell panes

# FILES AND DIRECTORIES

## ftlrc

_ftl_ reads it's configuration from ~/.confi/ftl/etc/ftlrc

you can override configuration in your own ~/.ftlrc

# ENVIRONMENT

$FTL_CFG

# INSTALL

see **INSTALL** file

# USER DEFINED BINDINGS, COMMANDS, ...

tbd: examples here

# BUGS

Report to <https://github.com/nkh/ftl>

# AUTHOR

© Nadim Khemir 2020-2022

mailto:nadim.khemir@gmail.com

CPAN/Github ID: NKH

# LICENSE

Artistic licence 2.0

# SEE ALSO

ranger, fff, clifm, lfm, nnn, vifm, broot, gitfm, ...
