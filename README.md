# NAME

ftl - terminal file manager, tmux based

## Commands shortcuts (⇑:alt-gr)
```
q|Q|@ ) close, write to &3, keep shell             ?       ) show this file
a     ) kill sound preview                         j|B     ) next entry
b     ) find entry in directory                    k|A     ) previous entry
c     ) copy selection                             h|D     ) parent directory
⇑c    ) compress/decompress                        l|C|''  ) cd to selected entry or open file
d     ) delete                                     5|6     ) page down/up
e     ) cd in global directory history             §|\t|1-4) create tab, switch to tab
E     ) cd in directory history                    :       ) go to entry
⇑e    ) clear global directory history             .|·     ) show/hide hidden files/tags               
f|⇑f  ) filter1, filter2, filter is per tab        ⇑6      ) reverse filter, per tab
F     ) clear filters                              ⇑d      ) select external filter
g|G   ) first entry, last entry                    /       ) fzf to file
⇑g    ) cd                                         \       ) fzf to directory
i     ) image/no image mode                        {       ) fzf to file with preview
I     ) create empty file                          }       ) rg to file
J|K   ) scroll preview                             
⇑k    ) clear persistent marks                     ,|;     ) add persistent mark, fzf persistent mark
L     ) symlink selection                          
m     ) mark directory                             '       ) go to mark
M     ) mkdir                                      
⇑m    ) mail
n|N   ) find next/previous                         ½       ) open new ftl in pane
O|o   ) sort by name, size, or date                >|<|_   ) extra pane
p|P   ) p: copy selection, P: move selection       =       ) next pane
r     ) reverse sort                               |       ) close extra panes
R     ) rename or bulk rename                      ^       ) show/hide entry stat in header
s     ) show/hide dir size                         )       ) show/hide directories and files
S     ) separate editor preview                    (       ) fzfi, find images using ueberzurg 
$|⇑s  ) shell pane, zoomed                         !       ) run shell command
t|⇑t|T) fzf tag, +subdir, clear                    
u|U   ) tag all files, untag all files             ]       ) untag files 
v|V   ) preview on/off, v: preview current file    #       ) flip-flop preview for extension
w|W   ) w: ext. viewer, W: ext. detached viewer    -       ) change preview size
x|X   ) chmod a+x, a-x                             +       ) show only directory preview
⇑x    ) public key encrypt/decrypt to screen       %|&     ) disable extension, re-enable extensions
y|Y   ) tag/untag current file                     "       ) flip-flop image preview
⇑y    ) copy selection to clipboard                *       ) set maximum listing depth
Z     ) close all tabs                             ' '     ) leader key
z     ) make preview the active pane and quit      8       ) refresh
⇑z    ) password encrypt/decrypt to file           0|9     ) internal usage
                                                  
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

