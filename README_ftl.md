#NAME

ftl - terminal file manager, tmux based

##Commands

	q|Q|Z  ) close tab, Q: save current file in &3, Q, Z: close all tabs
	z      ) make preview the active pane and quit
	g|G    ) go to first line, go to last lines in directory 
	B|j    ) next line
	A|k    ) previous line
	D|h    ) parent directory
	C|l|'' ) change to selected directory or open file in $EDITOR
	5      ) page down
	6      ) page up
	J|K    ) scroll preview 
	
	a      ) kill mplayer
	b|n|N  ) find entry in directory
	c      ) copy
	d      ) delete
	e      ) fzf current session directory history
	E      ) fzf global directory history
	f      ) filter1, filter is per tab
	F      ) clear filter
	i      ) enter/exit image mode
	I      ) fzfi, find images using ueberzurg
	K      ) clear global directory history
	L      ) symlink selection
	m      ) mark directory
	M      ) mkdir
	O      ) show/hide directories
	o      ) show/hide files
	p|P    ) p: copy selection, P: move selection
	r      ) rename or bulk rename
	R      ) reverse sort
	S      ) show/hide dir size
	s      ) show/hide file size
	t      ) create new tab
	T      ) fzf tag
	u|U    ) tag all files, untag all files
	v|V    ) +: switch preview on/off for all files, v:preview current file 
	w|W    ) w: open in external viewer, W: open and detach in external viewer
	x|X    ) chmod a+x, a-x
	' '|y|Y) tag/untag current file, tgs are shared among the tabs
	-      ) change preview size
	\=     ) sort by name, size, or date
	\'     ) go to mark, \'\' takes you to the previous directory
	\}     ) fzf persistent mark
	\,     ) add persistent mark
	\;     ) clear persistent marks
	\>|\<  ) extra pane
	\|     ) close extra panes
	\@     ) cd
	$'\t'  ) switch tab
	[1-4]  ) switch to given tab
	7      ) filter2, filter is per tab
	\!     ) run shell command
	\*     ) set maximum listing depth
	\^     ) show/hide entry stat in header
	.      ) show/hide hidden files
	\\     ) show only directory preview
	\?     ) show this file
	+      ) next extra pane
	/      ) fzf to file
	\{     ) fzf to file with preview
	\~     ) rg to file

#DOCUMENTATION

There are many promising file managers for the terminal from fff to nnn, ranger, etc ... 

ftl is Written in Bash, Bash packs a punch (sometimes it punches you).

I wanted a file manager that would use tmux and give "live" preview. it matches well with a tiling manager,

#DEPENDENCIES

tmux     - ftl is a tmux based file manager
terminal $EDITOR - $EDITOR is extensively used to provide live previews
lscolors <https://github.com/sharkdp/lscolors> - colors files according to LS_COLORS
rg       - to locate files containing a specific text
fzf      - to locate file and to present a picker
awk, sed, numfmt, sponge, ...
fzf-tmux, fim, zathura, qutebrowse, rw3m, w3mimgdisplay, pdftotext, ffmpegthumbnailer, mplayer, exiftool ...
xdotool, wmctrl
divers fzf scripts (perl, bat) - fzf file location with preview, fzfi (uberzug), available here: ...

##installation

ftl is a single script, put it in the PATH, install the dependencies *TODO package dependencies* and run.

##Display

The display consists of a header and a listing of the files in a directory, possibly filtered,
and an optional preview

###header components

directory tilde(filter on) current_file/total_files current_tab/total_tabs selected_files file_stat

###listing

The directory entries are colored with lscolors, if preview is on, a preview pane is displayed

##Image mode

Only show images in the listing and directory preview; with multiple tabs, makes sorting images easy.

#TODO

- Handle SIGWINCH
- keyboard buffer flushing
- fzf scripts preview via vim not bat
- vim file opener using ftl
- use inotify
 
#PATCHING ftl (with gratitude to Larry wall, and not just for patch)

There's no documentation, the code is *dense* with long lines but there's hope as
the call stack is seldom more than 2 deep.

The description of the main variables and functions should get you going, watch the
videos and if you need help send me a mail.

##Variables

dir_file    selected file in a directory, ftl remembers where you were
filters     each tab has its filter
epanes      extra panes 
pane_id     id of preview pane
my_pane     own pane
tfilter     used in image mode
marks       bookmarks, marks=([0]=dir [1]=dir ...), preset bookmarks
tags        list of tagged files
show_dirs   directory toggle
preview_all preview toggle
ifilter     extension of files considered images
zooms       preview pane sizes in percent
fs          directory where ftl saves the current selection and temporary files

##Functions

ftl       variable setup and switch for the commands
cdir      get list of files in directory and colorize them
list      list directory files
ftl_pmode setup directory preview
ftl_imode setup image mode
c*        close previews
e*        external viewers
p*        "internal" viewers
t*        tmux function
vipreview text preview in $EDITOR
...

#BUGS AND LIMITATIONS

SIGWINCH is not handled yet

=LICENSE AND COPYRIGHT

Artistic License 2.0

© Nadim Khemir
mailto:nadim.khemir@gmail.com
CPAN/Github ID: NKH

#=SEE ALSO

ranger
fff
lfm
nnn
vifm
