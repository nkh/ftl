# NAME

ftl - terminal file manager, tmux based

## Commands shortcuts
```
q|Q ) close tab, close and write to &3           ?   ) show this file
j|B ) next entry                                 ''  ) cd to selected entry or open file
k|A ) previous entry                             :   ) go to entry
h|D ) parent directory                           *   ) set maximum listing depth
l|C ) cd to selected entry or open file          ŋ   ) cd
g|G ) first entry, last entry                    /   ) fzf to file
5|6 ) page down/up                               \   ) fzf to directory        
a   ) kill mplayer                               {   ) fzf to file with preview
b   ) find entry in directory                    ;   ) fzf persistent mark
c   ) copy selection                             §   ) clear persistent marks
d   ) delete                                     ,   ) add persistent mark
e   ) cd in global directory history             «   ) password encrypt/decrypt to file
E   ) cd in directory history                    »   ) public key encrypt/decrypt to screen
f   ) filter1, filter is per tab                 .   ) show/hide hidden files
F   ) clear filter                               €   ) 2nd filter, per tab
H   ) clear global directory history             ¥   ) reverse filter, per tab
i   ) image/no image mode                        \(  ) fzfi, find images using ueberzurg 
I   ) create empty file                          }   ) rg to file
J|K ) scroll preview                             %   ) disable extension from listing
L   ) symlink selection                          &   ) re-enable all extensions
m   ) mark directory                             '   ) go to mark
M   ) mkdir                                      +   ) show only directory preview
n|N ) find next/previous                         ½   ) open new ftl in pane 
O|o ) next/previous pane                         >|<|_ ) extra pane
p|P ) p: copy selection, P: move selection       |   ) close extra panes
r   ) rename or bulk rename                      ^   ) show/hide entry stat in header
R   ) reverse sort                               =   ) sort by name, size, or date
s   ) show/hide dir size                         )   ) show/hide directories and files
S   ) separate editor preview                    ©   ) compress/decompress
t   ) create new tab                             tab ) switch tab
T   ) fzf tag                                    1-4 ) switch to given tab
u|U ) tag all files, untag all files             þ   ) show/hide external file tags
v|V ) preview on/off, v: preview current file    #   ) flip-flop preview for extension
w|W ) w: ext. viewer, W: ext. detached viewer    -   ) change preview size
x|X ) chmod a+x, a-x                             "   ) flip-flop image preview
y|Y ) tag/untag current file                     !   ) run shell command
Z   ) close all tabs                             $   ) shell pane
z   ) make preview the active pane and quit      ←   ) copy selection to clipboard
                                                 ' ' ) leader key
                                                 0|8|9 ) internal usage

```

![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/ftl.png)
![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/image_preview.png)
![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/tiled.png)

# DOCUMENTATION

There are many promising file managers for the terminal, from fff to nnn, clifm, ranger, vimfm, etc ... 

ftl is Written in Bash, the language that packs a real punch and sometimes punches you.

I wanted a file manager that would use tmux and give me "live" preview and works well with a tiling manager,

This is definitely not production quality, it's for the fun of it, but it's good enough so I stopped using other programs

# DEPENDENCIES

- tmux     - ftl is a tmux based file manager
- terminal $EDITOR - $EDITOR is extensively used to provide live previews
- lscolors <https://github.com/sharkdp/lscolors> - colors files according to LS_COLORS
- rg       - to locate files containing a specific text
- fzf      - to locate file and to present a picker
- awk, sed, numfmt, sponge, ...
- fzf-tmux, fim, zathura, qutebrowse, rw3m, w3mimgdisplay, pdftotext, ffmpegthumbnailer, mplayer, exiftool, mimemagic, rip, ...
- xdotool, wmctrl, expect, inotifywait
- divers fzf scripts (perl, bat) - fzf file location with preview, fzfi (uberzug), available here: ... soon

## Installation

ftl is a single script, put it in the PATH, install the dependencies *TODO: package dependencies* and run.

README.md: this file, is also the inline help

Some optional files:

ftl.eb: example of how to add extra binding. It contains an incremental search example.
ftl.et: example of how to tag files with their git status

## Display

The display consists of a header and a listing of the files in a directory, possibly filtered, and an optional preview

### header components

directory tilde(filter on) current_file/total_files current_tab/total_tabs selected_files file_stat

### listing

The directory entries are colored with lscolors, if preview is on, a preview pane is displayed

## Image mode

Only show images in the listing and directory preview; with multiple tabs, makes sorting images easy.

# TODO

- Handle SIGWINCH
- keyboard buffer flushing
- fzf scripts preview via vim not bat
- vim file opener using ftl
- use inotify
 
# PATCHING ftl (with gratitude to Larry wall, and not just for patch)

There's no documentation, the code is *dense* with long lines but there's hope as
the call stack is seldom more than 2 deep.

The description of the main variables and functions should get you going, watch the
videos and if you need help send me a mail.

## Variables

- dir_file    selected file in a directory, ftl remembers where you were
- filters     each tab has its filter
- epanes      extra panes 
- pane_id     id of preview pane
- my_pane     own pane id
- tfilter     used in image mode
- marks       bookmarks, marks=([0]=dir [1]=dir ...), preset bookmarks
- tags        list of tagged files
- show_dirs   directory toggle
- preview_all preview toggle
- ifilter     extension of files considered images
- zooms       preview pane sizes in percent
- fs          directory where ftl saves the current selection and temporary files

## Functions

- ftl       variable setup and switch for the commands
- cdir      get list of files in directory and colorize them
- list      list directory files
- ftl_pmode setup directory preview
- ftl_imode setup image mode
- c*        close previews
- e*        external viewers
- p*        "internal" viewers
- t*        tmux function
- vipreview text preview in $EDITOR
...

# BUGS AND LIMITATIONS

- SIGWINCH is not handled 

# LICENSE AND COPYRIGHT

Artistic License 2.0

© Nadim Khemir
mailto:nadim.khemir@gmail.com
CPAN/Github ID: NKH

# SEE ALSO

ranger
fff
lfm
nnn
vifm

