# NAME

ftl - file manager using tmux panes and live previews

![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/ftl.png)
![Screenshot](https://raw.github.com/nkh/ftl/master/screenshots/image_preview.png)

# DOCUMENTATION

There are many promising file managers for the terminal, from fff to nnn, clifm, ranger, vimfm, broot, etc ... 

ftl is Written in Bash, the language that packs a real punch (and sometimes punches you).

I wanted a file manager that would use tmux and give me "live" preview and works well with my tiling manager,

This is definitely not production quality, it's for the fun of it, but it's good enough so I stopped using other programs

# MAN PAGE

*ftl* has a complete man page, this is just a very short overview. 
![Manpage](https://github.com/nkh/ftl/blob/main/config/ftl/etc/man/ftl.md)

## Installation
see *INSTALL* file

## Display

The display consists of a header and a listing of the files in a directory, possibly filtered, and an optional preview

### tabs, hyperorthodox panes

### header components

directory tilde(filter on) current_file/total_files current_tab/total_tabs selected_files file_stat

### listing

The directory entries are colored with lscolors, if preview is on, a preview pane is displayed

## Image mode

Only show images in the listing and directory preview; with multiple tabs, makes sorting images easy.

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
gitfm
...
