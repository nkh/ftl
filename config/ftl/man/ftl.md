% FTL(1) | General Commands Manual
# NAME
ftl - terminal file manager, hyperorthodox, with live previews

![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/ftl.png)

![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/image_preview.png)

# SYNOPSIS

ftl

ftl [ [-t file] [-T file] ][directory[/file]]

# OPTIONS

-t file		file contains paths to files to tag

		eg: ftl -t <(find -name 'ftl*') 

-T file		file contains paths to files to show in own tab, must come
		after optionial _-t_ 

		eg: ftl -T <(find -name 'ftl*') 

# DESCRIPTION

ftl is hyperothodox file manager with live previews that leverages tmux and
many other programs.

The display consists of panes containing files listings and optional preview.

*ftl* can be used as a directory picker (see cdf in the source) and as a 
file picker in _vim_
 
# CONCEPTS

## Hyperorthodoxy

ftl is hyperothodox, or not at all depending on your preferences, it starts
with two panes but can start with just one pane or have more than two panes.
The default is two panes, one showing you a directory listing and the other
a preview of the current entry. The outstanding _tmux_ makes this possible.

You can choose to remove the preview as well as having multiple panes showing
the same or different directories.

Panes are independent instances of ftl that work in synch, each pane has its
own tabs, filters, ... 

## Preview Pane And Live Previews

If preview is on (on by default), a preview pane is displayed. It can
be switched on and off during the session; it's size can be changed. Some
entry types have multiple previews (IE: directories) that can be accessed
with a keyboard shortcut (Alt-gr+v by default)

The preview pane is not, generally, a static view of the file but, thanks to
_tmux_, a running program. If you are positioned on a text file, _vim_ will be
run to display it. If you change the position in the listing pane, the preview
program is killed and a new program is started.

The idea is to use within *ftl* what you normally use on the command line.

## Extended And Detached Viewers

For some file types, often media types, *ftl* can show an extended view and 
even start a detached viewer. See "## External Viewer" below and config in 
'$FTL_CFG/etc/ftlrc'. 

## Vim

*ftl* uses the awesome _vim_, if it's not your favorite editor you can install it
just for previewing (and maybe find it awesome). Patches for other editors are
welcome.

## Tabs

Tabs are views, to same or different directories, in the same pane. Filters
are per tab so you can have two tabs with different filters.

## File Listing

The listing consists of a header and directory listing.

The header consists of multiple elements, some depending on the current state:

	- current directory, possibly truncated
	- listing mode, directory/file
	- image mode, all files/non image/image
	- preview dir only (D)
	- montage mode (⠶)
	- filtered (~)
	- entry index/number of entries
	- size of directory, if sizes are displayed
	- file stat, optional
	- tab id
	- sort glyph, ⍺: alphanumeric, 🡕: size, entry date
	- reverse sort order (r)
	- background shell sessions

The directory listing consists of:

	- entry index
	- optional etag
	- entries colored by _lscolors_

Example:

	[ path ]  [      information       ]  [                   preview                    ] 

	ries/ftl  7/8 09/03/22-09:54 ᵗ2      │
	 1     .git                          │NAME                                            
	 2     config                        │                                                
	 3     screenshots                   │    ftl - file manager using tmux panes and live
	 4     test                          │                                                
	 5     .gitignore                    │    Screenshot [Image: https://raw.github.com/nk
	 6  A  INSTALL                       │    Screenshot [Image: https://raw.github.com/nk
	 7  M  README.md                     │                                                
	 8     Todo.txt                      │DOCUMENTATION                                   
	 ^  ^  [entries]                     │                                                
	 |  |                                │    There are many promising file managers for t
	 |  `- [etags]                       │    nnn, clifm, ranger, vimfm, broot, etc …     
	 |                                   │
	 `- [index]                          │...
                                              
## Marks

You can bookmak locations and jump back to them. Marks can be set in the
configuration file, added for the current session or made persistent.

## Tags/Etags

You can tag (select) entries, tags are synched between panes when option
_auto_tag_ is set (set by default). 

Etags is extra information that is optionally prepended to the entries.

Available etags are:

	/home/nadim/nadim/devel/repositories/ftl 2/14 ⍺
	1  08/11/2022-12:00 ftl
	   ⮤     etag     ⮥ date 

	/home/nadim/nadim/devel/repositories/ftl 2/14 ⍺
	1  M ftl
	1 ?? tags
	  ⮤⮥ git-status

	/home/nadim/nadim/devel/repositories/ftl 2/14 ⍺
	11 1598x2100 image.jpg
	12  720x 507 image.png
	   ⮤ etag  ⮥ image-size

## Type handlers

Text files are opened in _vim_.

_7z|bz2|cab|gz|iso|rar|tar|tar.bz2|tar.gz|zip_ archives are automounted.

You can add handlers in _'$FTL_CFG/bindings/type_handlers'_

## Filtering 

*ftl* can filter the files in the directory to present only those you want
to see.

See "## Filtering" in commands.

## Bash

*ftl* is written in Bash, the language that packs a real punch ... and
sometimes punches you. It also strives to follow the spirit of unix by
reusing what's available. IT will probably not work in other shells but
may be a cool exercise in making things portable.

Most of the code is one liners, albeit long, and it's structured to be
_easy_ to expand.

# KEY BINDINGS

*ftl* uses vim-like key bindings by default, the bindings are defined in the
default ftlrc file.

*ftl* has many commands and thus many bindings. The control key is not used
but the Alt-gr key, in combination with the shift key, is used extensively

## Default bindings

'Alt-gr'+c will open a window listing all the current binding, in _fzf_,
wich allows you to search per key or name.

	map    section  key      command                
	-------------------------------------------------------------------
	ftl    file     c        copy          copy file to, prompts inline
	...

## User defined bindings

You can override all the keys by creating your own rcfile and using the *bind*
function. See "## Examples".

	bind function arguments, all mendatory:

		map		map where the binding is saves 
		section		logical group the binding belongs to (hint)
		key		the keyboard key
		command		name of the internal command that is called
		short_ help	help displayed 
              

	eg: bind ftl file k copy "copy file to, prompts inline"

You can also override _ftl_event_quit_ which is called when *ftl* is closing,
you can see it in use in _'$FTL_CFG/bindings/type_handlers'_

In the default _ftlrc_ file, associative arrays A for alt-gr and SA for
shift+Alt-gr are defined, they allow you to define bindings this way: 

	eg: bin ftl filter "${A[d]}" clear_filters "clear filters"

When bindings are shown _alt-gr_ is replaced by _⇑_ and "_shift+alt-gr_
is replaced by  _⇈_; as well as the key the combination would generate
that makes it easier to search by name or by binding. 

## Leader key

The “Leader key” is a prefix key used to extend *ftl* shortcuts by using
sequences of keys to perform a command. The default is '\\'

	# set leader to "space"
	bind ftl bind BACKSPACE_KEY leader_key 'leader key SPACE_KEY

# COMMANDS TOC

- General *ftl* Commands
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
- File And Directory Operations
- External Commands
- External Viewer
- Shell Pane
- Command Mode

## General *ftl* Commands

	Show keyboard bindings «⇑c/©» 

		The bindings listing is generated at runtime, if you add
		or modify bindings it will show in the listing. The listing
		is displayed in fzf which allows you to search by name but
		also by binding.

	Show this man page «?»

		The man page is generated and shows the default bindings. You
		can configure *ftl* to show a different help if you prefer to
		cook your own.

	Quit «q»

		Closes the current tab, it there are tabs, then closes the
		last created pane.

	Quit all «Q»
		
		Closes all tabs and panes at once

	Quit, keep shell «@»

		Quit all but doesn't close the shell pane if one exists

	Quit, keep preview zoomed «⇈q/Ω»

		Quit *ftl* but doesn't close the preview pane if one exists and
		zooms it.

	Detach the preview «$»
		
		Open a new preview pane, the old preview pane is not under *ftl*
		control any more.

	Cd «G»
		
		*ftl* prompts you for a path, the promt has path completions.
		You can also change directory with marks or by finding it, this
		is the most simplistic way. 

	Set maximum listing depth «*»

		Set the maximum depth of listing, 1 shows the entries in the
		current directory. It's sometime practicall but using multiple
		tabs or panes is more ergonomic.

	Copy selection to clipboard «⇑t/þ»
		
		The selected entries are copied to the clipboard with full
		path, separated with by a space.

	Pdh, pane used for debugging «¿»

	Bindings used internaly by *ftl*

		Refresh curent pane «r»
		Handle pane event   «7»
		Preview pane signal «8»
		Handle pane preview «9»
		Cd to shell pane    «0»

## Viewing Mode

	Show size «⇑s/ß»
		Changes the state of size display option (circular) :
			- no size
			- only files
			- file size and directory entries
			- file size and directory sizes (scans the sub directories)

	Show/hide dot-files «.»
		Default config shows dot files
	
	Show/hide stat «^»
		Entry stat is added to the header 

	Show/hide etags «⇑./·»
		See "Select etag type" below.

	File/dir view mode «)»
		Set the file/dir to (circular):
			- only files
			- only directories
			- files and directories

	View mode «M»
		Set image mode (circular):
			- filter out images
			- filter out non images
			- show all files

	Montage mode «⇑m/µ»
		Directory preview will be a montage of the images in the directory.

	Refresh montage «⇈m/º»
		The montage is generated once, a manual refresh is needed if new
		images are added to the directory

	Preview directory only/all «=»
		No file preview is generated

	Show/hide image preview «DQUOTE»
		Preview everything but not images

	Show/hide extension preview «#»
		No preview for the current entry extension will be shown

	Fzfi, using ueberzurg «⇈i/ı»
		Use fzf and ueberzurg to find and display images

	Preview lock «⍰»
	Preview lock clear «⍰»
		tbd

## Panes

	New ftl pane below «_»
	New ftl pane left «|»
	New ftl pane left, keep focus «>»
	New ftl pane right «¦»
	New ftl pane right, keep focus «<»

	Next pane or viewer «'-'»
		Set focus on the next pane

## Tabs

	Each tab has its own index, indexes are not reused; each pane has
	its own tabs. Tabs are close with «q», when the last tab is closed
	the pane is closed.

	New tab «⇈s/§»
	Next tab «TAB»

## Moving around

	Also see "cd" in *General Commands* above and *Marks* and
	*History* below

	*ftl* will automatically put you on a README if you haven't visited
	the directory before; afterward *ftl* will remembers which entry you
	were on.

	
	cd into directory or edit file «ENTER»
		edit file if not binary, for binary files try hexedit command

	Cd to parent directory «h»
	Down to next entry     «j»
	Up to previous entry   «k»
	cd into entry   «l»

	Using arrow:

	Cd to parent directory   «arrow_left/D»
	Down to next entry       «arrow_down/B»
	Up to previous entry     «arrow_up/A»
	cd into directory «arrow_right/C»

	Page down «page_down/5»
	Page up   «page_up/6»

	Move to «g»
		goes to, depending of where in the listing you are:

		- top
		- first file
		- last file

	Next entry of same extension «ö»
	Next entry of different extension «Ö»
	Goto entry by index «ä»

	Scroll preview up   «K»
	Scroll preview down «J»

	or this alternative, see rc file
		Move up multiple lines   «K»
		Move down multiple lines «J»

## Preview

	Preview show/hide «v»

	Change preview size «+»
		choose a size in a predefined, see rc file, set of sizes

	Preview once «V»
		Preview current entry (if preview pane is close), close the
		preview at the next command.

	Alternative preview #1 «⇑v/“»
	Alternative preview #2 «⇈v/‘»
		Some entry have multiple preview types, these bindings let you
		to see the other type of preview.

		entry types with multiple preview types:
			- directories
			- music
				will show information and play the music
			- pdf
			- tar files 

	File preview at end «⇈t/Þ»
		show the bottom of the entry (text files in vim)

	Hexadecimal preview «⇑x/»»

## Sorting 

	Select sort order «o» from:
		- alphanumeric
		- size
		- date

	Reverse sort order «O»

	Select a sort order from a list of external sorts «⇑f/đ»
		IE: by extension

## Filtering

	Set filter #1 «f»
	Set filter #2 «F»

	Clear all filters «⇑d/ð»

	Select a filter from a list of external filters «⇑f/đ» ;

	by_extension			# keep files matching extensions
	by_file				# keep selected files, additive
	by_file_reset_dir		# keep selected files, exclusive
	by_file_global			# keep selected files, all tabs, additive
	by_file_global_reset_dir	# keep selected files, all tabs, exclusive
	by_no_extension			# keep files not matching extensions
	by_only_tagged			# keep tagged files
	by_size				# keep files over minimum size

	Set reverse-filter «⇑a/ª»
		Filters out what you don't want to see. Applied after other
		filters are applied. It can be set in your ftlrc file.

		eg: keep files containing 'f' and not containing 'i'
			«f»  -> f
			«⇑a» -> i

		eg: always hide vim swap files, set in rcfile
			rfilter0='\.sw.$'

	Hide extension «¤», per tab
	Hide extension «%», globally
		Hide files having the same extention as the current file.
		You can hide multiple extensions.

	Show hidden extensions «⇈k/&»

## Searchings

	Incremental search «/»
		Press 'enter' to end.

	Find next «n»
	Find previous «N»

	Searching with _fzf_ and _rg_:
		*ftl* runs fzf to let you pick one or multiple entries.

		If you select only one entry, *ftl* positons you on the entry,
		you can also open the entry in a new tab with 'ctrl+t'.

		If you select multiple entries, end with 'ctrl+t'.

	Fzf find current directory file «b»
	Fzf find files and directories  «⇑b/”»
	Fzf find only directories       «⇈b/’»

	Rg to file with preview «}»

## Tags/Etags

	A tag is a selected file, *ftl* will display a glyph next to tagged
	files. Option auto_tags controls if tags are automatically merged to
	other panes.

	When using tags and multiple class tags are present, *ftl* will ask
	which class to use.

	The number of tagged entries is displayed in the header

	Tag down «y»
		Tag current entry in "normal" tag class and move one entry down

	Tag up «Y»
		Tag current entry in "normal" tag class and move one entry up

	Class tag «1» «2» «3»
		Tag current entry in given class and move one entry down. The
		entry is addorned with the class name

	Class tag D «4»
		Tag current entry in D class and move one entry down. The entry
		is addorned with the class name "D".
		
	Tag all files «⇑y/←»
		Tag all the files, no sub directories, in the current directory

	Tag all files and subdirs «⇈y/¥»
		Tag all the files and sub directories in the current directory

	Fzf tag files «t»
		Open fzf to tag files, no sub directories, select with «TAB>,
		multiple selection is possible.

	Fzf tag files and subdirs «T»
		Open fzf to tag files and sub directories, select with «TAB>,
		multiple selection is possible.

	Untag all «u»
		Untag all files and directories, including those in other
		directories.

	Untag fzf «U»
		Opens fzf to let you choose which entries to untag

	Fzf goto «⇑g/ŋ»
		Opens fzf to let you choose an entry among the tags, then
		change directory to where the tag is.

		This is can be handy when tags are read from a file with option
		-t on the command line or via the 'load_tags' shell command

	Merge tags from all panes «⇑o/œ»
		if option auto_tags=0,  merge tags from all panes

	Fzf merge tags from panes «⇈0/°»
		if option auto_tags=0, choose the pane to merge tags from

	Select etag type from list «⇈./˙»
		See "Show/hide etags" above.

## Marks

	Mark directory/file «m» + character

	Go to mark «QUOTE» + character
		QUOTE+QUOTE will take you to the last directory

	Fzf go to mark «⇈'/×»
		You can open multiple marks in tabs with «ctrl-t»

	Add persistent mark «,»
	Fzf to persistent mark «;»
		You can open multiple marks in tabs with «ctrl-t»

	Clear persistent marks «⇑k/ĸ»

## History

	*ftl* keeps two location histories, one in the currentsession and one
	global (sum of all sessions)

	Fzf history all sessions «¨»
	Fzf history all sessions «⇑h/ħ»
		You can open multiple marks in tabs with «ctrl-t»

	Fzf history current session «H»
		You can open multiple marks in tabs with «ctrl-t»

	Fzf delete from all sessions history «⇈h/Ħ»
		Uses fzf to mark entries that will be removed from the history

	Delete all session history «⇈d/Ð»

## File and directory operations

	Create new file        «i»
	Create new directory   «I»
	Create entries in bulk «⇑i/→»
		Opens _vim_, lines ending with / will create directories

	Delete selection «d»
		uses configuration *RM*, see ftlrc.

	Copy entry «c»
	Copy selection «p»

	Move selection «P»
	Move selection «⇈p/þ»
		Uses _fzf_mv_.

	Rename «R»
		Uses _vidir_.

	Symlink selection «⇑l/ł»
	Symlink follow    «⇈l/Ł»

	Flip selection executable bit «x»

## External Commands

	Example of command integration, see 'etc/bindings/leader_ftl'.

	Compress/decompress            «˽fc»

	Convert pdf to text file       «˽fP»

	Display stat in preview pane   «˽fs»

	Encrypt/decrypt using password «˽fz»

	Encrypt/decrypt using _gpg_    «˽fx»

	Shred selection using _shred_  «˽s»

	Reduce jpg image size          «˽fi»

	Reduce png to jpg              «˽fi»

	Reduce pdf size                «˽fp»

	Reduce video size              «˽fv»

	Lint current directory         «˽fl»

	Send mail                      «˽fm»

	Terminal popup                 «˽ft»

## External Viewer

	Sometime Previews in ftl are not enough, eg. you really want to see
	that pdf with the images in it not just a text rendering. The external
	key bindings set the _emode_ variable and external viewer decide how
	to display an entry, that may be in a text based application or not.

	*ftl* had a some viewers for images, videos, comics, directories
	containing media, mp3, ...

	External viewer, mode #1 «e»
	External viewer, mode #2, detached «E»
	External viewer, mode #3 «⇑e/€»
	External viewer, mode #4 «⇈e/¢»

	Music has a sound preview mode #1, it lets you play a file in the 
	background. you can stop it when you want or it stops when you
	leave *ftl*. Modes #2-#4 open _G_PLAYER_ which is _vlc_ by default.

	Kill sound preview «a»

	run viewer        «w»
	Fzf choose viewer «W»

	The viewer for music queues the files in cmus. I recommend adding
	a binding for cmus in *tmux* to access the application easilly.

	Creating and using a viewer:
		core viewers are in '$FTL_CFG/etc/core/viewers/ftl'

		extra viewers are in'$FTL_CFG/viewers'
		
## Shell Pane
	Shell pane «s»

		moving from shell pane to ftl and from ftl to shell pane

	Shell pane with selected files «S»
	Shell pane, zoomed out «not asssigned»

	Cd to shell pane «⇈0/°»
		synch shell pane directory to ftl

	Send selection to shell pane «X»

# Command Mode

You can run commands in different ways

- Within a shell pane, see *Shell Panes* above

- user defined ftl command

if you run the same command often you can create a command that you can call
directly from *ftl*.

Create a shortcut, maybe using «leader + u + char», and put your code
in $FTL_CFG/bindings/, it will be loaded automatically in *ftlrc*. See 
"# EXAMPLES" below.

You can also add commands without bindings, in $FTL_CFG/commands/, *ftl*
will lets you choose a command to run with the invaluable _fzf_ or at the
command prompt.

	Run user command «˽u»
	command propmpt «:»

	the scripts are either
		- bash scripts that are sourced (can change *ftl* state)
		- executables written in any language

	Look in $FTL_CFG/etc/commands/XX_example for documentation.

- from the command prompt

	Run commands «:»

	You are prompted, with edit/history/completion, for a command:

		- «empty answer» 	Cancel

		- ^[1-9][0-9]*$ 	Goto entry

		- ^etags		Chose tagging method

		- "load_tags"		Load tags from a file

		- ^tree			display a tree in a popup pane

		- shortcut		run the *ftl* command

		- bound function	run the *ftl* command

		- user_command [args]   run the user command

		- external command	See 'External command' below

## External Commands

*ftl* has one _session-shell_, a pane running bash, where your external commands
are run by default.

	Run command  «:»
		command [args]

		*ftlsel* list ftl selection, null separated
			
			«:» ftlsel | xargs -0 ls --color=always
			«:» ftlsel | xargs -0 -n 1 ls --color=always

		*ftl_session* command [command args]

			run you commands in a separate shell pane in the *ftl*
			session, eg: when commands that take time to complete.
			
			the shell pane is closed if the command exit code is 0. 

	Switch to session-shell pane «!»

	Switch back from tmux pane «tmux-prefix+L»

# FILES

## Directory structure

	<ftl repo>
	├── INSTALL
	├── README.md 
	└── config
	    └── ftl
		├── ftlrc
		├── bindings
		├── commands -> etc/commands
		├── etags -> etc/etags
		├── etc
		│   ├── bin
		│   │   ├── ftl
		│   │   ├── ftli
		│   │   └── ...
		│   ├── bindings
		│   │   └── lib
		│   ├── commands
		│   ├── core
		│   │   └── lib
		│   │       ├── lock_preview
		│   │       └── merge
		│   ├── etags
		│   ├── filters
		│   ├── generators
		│   └── viewers
		├── filters -> etc/filters
		├── generators -> etc/generators
		├── man
		├── var
		│   └── thumbs
		│       ├── flv
		│       └── ...
		└── viewers -> etc/viewers

## ftlrc

_ftl_ reads it's configuration from ~/.config/ftl/etc/ftlrc

you can override configuration in your own ~/.ftlrc after sourcing the 
default configuration

# ENVIRONMENT

$FTL_CFG (set by default to $HOME/.config/ftl) is the directory that contains
*ftl* code and data.

# CONFIGURATION

See "$FTL_CFG/etc/ftlrc", ftl's default config file, for details. 

# INSTALL

Install ftl in $FTL_CFG and symlink _ftl_ somewhere in your $PATH

Also read the **INSTALL** file

# EXAMPLES

## Helpful Bindings

	# start ftl in a new window
	tmux bind C-F run-shell 'tmux new-window -n ftl ftl "#{pane_current_path}"'

	# start ftl on a specific directory in a new window
	tmux bind C-D new-window -n download "ftl $HOME/downloads"

## RCfile

	# source default config
	source $FTL_CFG/etc/ftlrc

	# change leader-key to SPACE_KEY
	bind ftl bind SPACE_KEY leader_key 'leader key "˽"'

	# don't show swap files
	rfilter0='\.sw.$'

	# display options for fzf
	fzf_opt="-p 90% --cycle --reverse --info=inline --color=hl+:214,hl:214"

	# columns when displaying command mapping in popup
	CMD_COLS=150

	# how to delete files
	RM="rip --graveyard $HOME/graveyard" ; mkdir -p $HOME/graveyard

	# alternative directory preview
	NCDU=gdu

	# define your marks
	declare -A marks=(
		[0]=/
		[1]=$HOME/$
		[3]=$HOME/downloads/$
		[$"'"]="$(tail -n1 $ghist)" # last visited directory
		)

	# load git support 
	. ~/.config/ftl/etags/git

	# vim: set filetype=bash :

## User Command With Binding

This example can be found in $FTL_CONFIG/user_bindings/01_shred

	shred_command() 
	{
	# prompt user
	((${#selection[@]} > 1)) && plural='ies' || plural='y'
	prompt "shred: ${#selection[@]} entr${plural} [yes|N]? "

	[[ $REPLY == yes ]] && # reply must be "yes"
		{
		# use shred utility and clear the selection tags
		shred -n 2 -z -u "${selection[@]}" && tags_clear

		cdir # reload directory
		} ||
		# redisplay list to override prompt
		list

	false # reset key_map to default
	}

	# bind shortcut «s» in the leader map
	bind leader file s shred_command "*** bypasses RM *** ..."

	# vim: set filetype=bash :

## Directory Picker

	Add the following code to your bashrc:
		source $path_to_ftl/cdf

	This adds a _cdf_ function which will open an *ftl* instance you can
	use to navigate your directories, jump to marks, ...

	Press «q» to quit and jump to the directory you're currently in.
	Press «Q» to cancel.

## Vim File Picker

	Add the following code to your vimrc:

	function! Ftl(preview)
	    let temp = tempname()
	    let id=localtime()

	    if ! has("gui_running")
		"exec "silent !echo waiting for signal: ftl_" . id
		exec "silent !tmux new-window ftlvim " . shellescape(temp) . " ftl_" . id . " " . a:preview . " ; tmux wait ftl_" . id
	    endif

	    if !filereadable(temp)
		redraw!
		return
	    endif

	    let names = readfile(temp)
	    if empty(names)
		redraw!
		return
	    endif

	    for name in names
		exec 'tabedit ' . fnameescape(name)
	    endfor

	    redraw!
	endfunction

	map <silent> <leader>f :call Ftl(1)<cr>

# BUGS AND CONTRIBUTIONS

Please report bug to <https://https://github.com/nkh/ftl/issues>

Contributions are best done via pull requests on github. Keep code to a minimum.

# AUTHOR

© Nadim Khemir 2020-2022

mailto:nadim.khemir@gmail.com

CPAN/Github ID: NKH

# LICENSE

Artistic licence 2.0 or GNU General Public License 3, at your option.

# SEE ALSO

ranger, fff, clifm, lfm, nnn, vifm, broot, gitfm, ...
