# NAME

ftl - a bash file manager

# SYNOPSIS

ftl

ftl [-t file] [directory[/file]]

# DESCRIPTION

ftl is Written in Bash, the language that packs a real punch (and sometimes punches you).

## Display

The display consists of a header and a listing of the files in a directory, possibly filtered, and an optional preview

### tabs

Only show images in the listing and directory preview; with multiple tabs, makes sorting images easy.

### hyperorthodox panes

### header components

<directory> [tilde(filter on)] <current_file/total_files> <current_tab> <selected_files> [file_stat]

### listing

The directory entries are colored with lscolors, if preview is on, a preview pane is displayed

## display modes

all files and directories / files only / directories only


# CONFIGURATION

# ENVIRONMENT

$FTL_CFG

# INSTALL

see **INSTALL** file

# COMMANDS

## leader key [SPACE_KEY]

## file

creat new directory [I]

move selection [P]

rename/bulk rename [R]

chmod a-x selection [X]

copy selection to [c]

delete selection [d]

creat new file [i]

copy selection [p]

chmod a+x selection [x]

symlink create [⇈l]

move to predefine location [⇈p]

creat in bulk [⇑i]

symlink follow [⇑l]

## filter

show/hide extension preview [#]

hide extension [%]

enable all extensions [&]

show/hide dot-files [.]

set filter 2 [F]

set filter 1 [f]

select etags [⇈.]

set reverse filter [⇈f]

show/hide etags [⇑.]

clear filters [⇑d]

select filter [⇑f]

##find

find [/]

find previous [N]

fzf find current directory file [b]

find next [n]

fzf to file with preview [{]

rg to file [}]

fzf find from current directory [⇈b]

fzf find current directory file or subdirs [⇑b]

## ftl

detach editor preview [$]

maximum listing depth [\*]

show help [?]

cd [G]

quit forced [Q]

quit [q]

refresh [r]

pdh pane [¿]

keep shell zoomed [⇈q]

show command mapping [⇑c]

quit keep shell [⇑q]

to clipboard [⇑t]

## history

fzf history current session [H]

fzf history all sessions [¨]

delete current session history [⇈d]

fzf edit all sessions history [⇈h]

fzf history all sessions [⇑h]

##extra:

pdf2txt [˽fP]

compress/decompress [˽fc]

reduce image size [˽fi]

mail [˽fm]

reduce pdf size [˽fp]

stat file [˽fs]

terminal popup [˽ft]

reduce video size [˽fv]

PGP encrypt/decrypt [˽fx]

password encrypt/decrypt [˽fz]

## marks

go to mark [']

add persistent mark [,]

fzf to persistent mark [;]

mark directory/file [m]

fzf to mark [⇑']

clear persistent marks [⇑k]

## media

external viewer detached [E]

fzf viewer [W]

kill sound preview [a]

external viewer [e]

terminal media player in background [w]

## move

cd or open file ['']

next pane or viewer [-]

page down [5]

page up [6]

previous entry [A]

next entry [B]

cd or open file [C]

parent directory [D]

scroll preview down [J]

scroll preview up [K]

go to top/file/bottom [g]

parent directory [h]

next entry [j]

previous entry [k]

cd or open file [l]

next entry of different extension [Ö]

goto entry by index [ä]

next entry of same extension [ö]

## pane

extra pane right [<]

extra pane left [>]

extra pane below [\_]

extra pane: left [|]

extra pane: right [¦]

## shell

view shell [!]

shell + commands: q, etags, load_tags, ... [:]

shell pane with selected files [S]

shell pane [s]

## tabs

next tab [TAB]

new tab [⇈s]

## tags

class tag [1-4]

fzf tag files and subdirs [T]

untag all [U]

tag up [Y]

fzf tag files [t]

untag fzf [u]

tag down [y]

fzf merge from panes [⇈O]

tag all files and subdirs [⇈y]

fzf goto [⇑g]

merge from panes [⇑o]

tag all files [⇑y]

## view

show/hide image preview ["]

file/dir view mode [)]

change preview size [+]

preview directory only [=]

view mode: file/directory/image [M]

sort reversed [O]

preview once [V]

show/hide stat [^]

sort type [o]

preview show/hide [v]

fzfi, using ueberzurg [⇈i]

refresh montage [⇈m]

file preview at end [⇈t]

alternative preview for : dir, media, pdf, tar, ... [⇈v]

montage mode [⇑m]

show/hide size [⇑s]

alternative preview for : dir, media, pdf, tar, ... [⇑v]

# USER DEFINED COMMANDS

# BUGS

# AUTHOR

© Nadim Khemir 2020-2022

mailto:nadim.khemir@gmail.com

CPAN/Github ID: NKH

# LICENSE

Artistic licence 2.0

# SEE ALSO

ranger, fff, clifm, lfm, nnn, vifm, broot, ...
