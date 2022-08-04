# NAME

ftl - terminal file manager, tmux based

## Commands shortcuts (⇑: alt-gr, ⇈: shift+alt-gr)
```
q Q @  ) close, > &3, keep shell         ?       ) show help
a      ) kill sound preview              j B     ) next entry
b ⇑b   ) find/fzf entry in directory     k A     ) previous entry
c      ) copy selection                  h D     ) parent directory
⇑c     ) compress/decompress             l C ''  ) cd or open file
d      ) delete                          5 6     ) page down/up
... 

for a complete list press '?' in ftl


```

![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/ftl.png)
![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/image_preview.png)

# DOCUMENTATION

There are many promising file managers for the terminal, from fff to nnn, clifm, ranger, vimfm, broot, etc ... 

ftl is Written in Bash, the language that packs a real punch (and sometimes punches you).

I wanted a file manager that would use tmux and give me "live" preview and works well with my tiling manager,

This is definitely not production quality, it's for the fun of it, but it's good enough so I stopped using other programs

# DEPENDENCIES

- tmux     - ftl is a tmux based file manager
- terminal $EDITOR - $EDITOR is extensively used to provide live previews
- lscolors <https://github.com/sharkdp/lscolors> - colors files according to LS_COLORS
- rg       - to locate files containing a specific text
- fzf      - to locate file and to present a picker
- awk, sed, numfmt, sponge, ...
- fzf-tmux, fim, zathura, qutebrowse, mutool, rw3m, w3mimgdisplay, cbconvert, pdftotext, ffmpegthumbnailer, mplayer, exiftool, mimemagic, rip, ...
- xdotool, wmctrl, expect, inotifywait
- divers fzf scripts (perl, bat) - fzf file location with preview, fzfi (uberzug), available here: ... soon

## Installation

clone ftl, put it in the PATH, link resource/.config/ftl in ~/.config, install the dependencies *TODO: package dependencies*.

Some optional files:

ftl.eb: example of how to add extra binding. It contains, among other, an incremental search example.
ftl.et: example of how to tag files with their git status

see resources/ for your ftlrc setup and some filter examples

## Display

The display consists of a header and a listing of the files in a directory, possibly filtered, and an optional preview

### tabs, hyperorthodox panes

### header components

directory tilde(filter on) current_file/total_files current_tab/total_tabs selected_files file_stat

### listing

The directory entries are colored with lscolors, if preview is on, a preview pane is displayed

## Image mode

Only show images in the listing and directory preview; with multiple tabs, makes sorting images easy.

# PATCHING ftl (with gratitude to Larry wall, and not just for patch)

There's no documentation, yet, the code is *dense* with long lines but there's hope as
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

© Nadim Khemir 2020-2022
mailto:nadim.khemir@gmail.com
CPAN/Github ID: NKH

# SEE ALSO

ranger
fff
clifm
lfm
nnn
vifm
...
