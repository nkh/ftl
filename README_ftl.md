#NAME

ftl - terminal file manager, tmux based

![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/ftl.png)
![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/image_preview.png)
![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/tiled.png)

##Commands

?   ) show this file
q   ) quit
''  ) cd to selected entry or open file

j|B ) next entry                                 0|9 ) internal usage
k|A ) previous entry                             @   ) cd
h|D ) parent directory                           .   ) show/hide hidden files
l|C ) cd to selected entry or open file          #   ) copy selection to clipboard
g|G ) first entry, last entry                    ' ' ) tag/untag current file
5|6 ) page down/up                               #   ) flip-flop preview for extension
a   ) kill mplayer                               :   ) go to entry
b   ) find entry in directory                    =   ) sort by name, size, or date
n|N ) find next/previous                         /   ) fzf to file
c   ) copy selection                             \   ) fzf to directory
d   ) delete                                     {   ) fzf to file with preview
e   ) cd in directory history                    }   ) rg to file
E   ) cd in global directory history             tab ) switch tab
f   ) filter1, filter is per tab                 1-4 ) switch to given tab
F   ) clear filter                               7   ) 2nd filter, per tab
H   ) clear global directory history             8   ) reverse filter, per tab
i   ) enter/exit image mode                      >|< ) extra pane
I   ) fzfi, find images using ueberzurg          |   ) close extra panes
J|K ) scroll preview                             %   ) disable extension from listing
L   ) symlink selection                          &   ) re-enable all extensions
m   ) mark directory                             "   ) flip-flop image preview
M   ) mkdir                                      +   ) show only directory preview
O|o ) next/previous pane                         !   ) run shell command
p|P ) p: copy selection, P: move selection       *   ) set maximum listing depth
r   ) rename or bulk rename                      ^   ) show/hide entry stat in header
R   ) reverse sort                               $   ) shell pane
S   ) show/hide dir size                         #   ) show/hide directories
s   ) show/hide file size                        #   ) show/hide files
t   ) create new tab                             -   ) change preview size
T   ) fzf tag                                    ,   ) add persistent mark
u|U ) tag all files, untag all files             ;   ) fzf persistent mark
v|V ) preview on/off, v: preview current file    §   ) clear persistent marks
w|W ) w: ext. viewer, W: ext. detached viewer    '   ) go to mark
x|X ) chmod a+x, a-x                             
y|Y ) tag/untag current file
Z   ) close all tabs
z   ) make preview the active pane and quit
q|Q ) close tab, close and write to &3

#DOCUMENTATION

There are many promising file managers for the terminal, fff to nnn, clifm, ranger, vimfm, etc ... 

ftl is Written in Bash (packs a punch, sometimes it punches you).

I wanted a file manager that would use tmux and give "live" preview. It matches well with a tiling manager,

#DEPENDENCIES

tmux     - ftl is a tmux based file manager
terminal $EDITOR - $EDITOR is extensively used to provide live previews
lscolors <https://github.com/sharkdp/lscolors> - colors files according to LS_COLORS
rg       - to locate files containing a specific text
fzf      - to locate file and to present a picker
awk, sed, numfmt, sponge, ...
fzf-tmux, fim, zathura, qutebrowse, rw3m, w3mimgdisplay, pdftotext, ffmpegthumbnailer, mplayer, exiftool, mimemagic, rip, ...
xdotool, wmctrl
divers fzf scripts (perl, bat) - fzf file location with preview, fzfi (uberzug), available here: ...

##installation

ftl is a single script, put it in the PATH, install the dependencies *TODO package dependencies* and run.

README_ftl.md, this file, should also be where you put ftl if you want "inline help"

ftl.eb implements external binding, put it where you put ftl if you want to use it. It contains an incremental
search example.

You can also symlink the files.

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

