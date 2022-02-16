# NAME

ftl - terminal file manager, tmux based

## Commands shortcuts (⇑:alt-gr)
```
q|Q|@) close, write to &3, keep shell             ?   ) show this file
a    ) kill mplayer                               j|B  ) next entry
b    ) find entry in directory                    k|A  ) previous entry
c    ) copy selection                             h|D  ) parent directory
⇑c   ) compress/decompress                        l|C  ) cd to selected entry or open file
d    ) delete                                     ''  ) cd to selected entry or open file
e    ) cd in global directory history             5|6  ) page down/up
⇑e   ) 2nd filter, per tab                        .   ) show/hide hidden files
E    ) cd in directory history                    {   ) fzf to file with preview
f    ) filter1, filter is per tab                 ;   ) fzf persistent mark
F    ) clear filter                               :   ) go to entry
⇑f   ) select external filter                     *   ) set maximum listing depth
g|G  ) first entry, last entry                    /   ) fzf to file
⇑g   ) cd                                         \   ) fzf to directory
H    ) clear global directory history
i    ) image/no image mode                        (   ) fzfi, find images using ueberzurg
I    ) create empty file                          }   ) rg to file
J|K  ) scroll preview                             %   ) disable extension from listing
⇑k   ) clear persistent marks                     ,   ) add persistent mark
L    ) symlink selection                          &   ) re-enable all extensions
m    ) mark directory                             '   ) go to mark
M    ) mkdir                                      +   ) show only directory preview
⇑m   ) mail
n|N  ) find next/previous                         ½   ) open new ftl in pane
O|o  ) next/previous pane                         >|<|_ ) extra pane
p|P  ) p: copy selection, P: move selection       |   ) close extra panes
r    ) reverse sort                               ^   ) show/hide entry stat in header
R    ) rename or bulk rename                      =   ) sort by name, size, or date
s    ) show/hide dir size                         )   ) show/hide directories and files
S    ) separate editor preview                    
$|⇑s ) shell pane, zoomed                         §   ) create new tab
t|T  ) fzf tag directory/with subdirectories      1-4 ) switch to given tab
⇑t   ) show/hide external file tags               tab ) switch tab
u|U  ) tag all files, untag all files             ⇑6  ) reverse filter, per tab
v|V  ) preview on/off, v: preview current file    #   ) flip-flop preview for extension
w|W  ) w: ext. viewer, W: ext. detached viewer    -   ) change preview size
x|X  ) chmod a+x, a-x                             "   ) flip-flop image preview
⇑x   ) public key encrypt/decrypt to screen
y|Y  ) tag/untag current file                     !   ) run shell command
⇑y   ) copy selection to clipboard
Z    ) close all tabs                             ' ' ) leader key
z    ) make preview the active pane and quit      8   ) refresh
⇑z   ) password encrypt/decrypt to file           0|9 ) internal usage
                                                  
```


![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/ftl.png)
![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/image_preview.png)
![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/tiled.png)

# DOCUMENTATION

There are many promising file managers for the terminal, from fff to nnn, clifm, ranger, vimfm, etc ... 

ftl is Written in Bash, the language that packs a real punch and sometimes punches you.

I wanted a file manager that would use tmux and give me "live" preview and works well with my tiling manager,

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

clone ftl, put it in the PATH, install the dependencies *TODO: package dependencies* and run.

README.md: this file, is also the inline help

Some optional files:

ftl.eb: example of how to add extra binding. It contains an incremental search example.
ftl.et: example of how to tag files with their git status

see resources/ for your ftlrc setup and some filter examples

## Display

The display consists of a header and a listing of the files in a directory, possibly filtered, and an optional preview

### header components

directory tilde(filter on) current_file/total_files current_tab/total_tabs selected_files file_stat

### listing

The directory entries are colored with lscolors, if preview is on, a preview pane is displayed

## Image mode

Only show images in the listing and directory preview; with multiple tabs, makes sorting images easy.

# TODO

- keyboard buffer flushing
- fzf scripts preview via vim not bat
- vim file opener using ftl
 
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

no installer

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

