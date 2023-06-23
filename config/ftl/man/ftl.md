% FTL(1) | General Commands Manual
# NAME
ftl - terminal file manager, with live previews, hyperorthodox

# SYNOPSIS

ftl

ftl [ [-s file] [-t file] ] [directory[/file]]

# OPTIONS

-s file         file contains paths to files to select

                eg: ftl -s <(find -name 'ftl*') 

-t file         file contains paths to files to show in own tab, must come
                after _-s_ if any

                eg: ftl -t <(find -name 'ftl*') 

# DESCRIPTION

ftl is hyperothodox file manager with live previews that leverages tmux and
many other programs.

The display consists of panes containing files listings and optional preview.

# CONCEPTS

## Unix Spirit

*ftl* strives to follow the spirit of Unix by reusing what's available and
is designed to integrate other Unix applications and tools. *ftl* can be used
to change directory, to pick files/directories in scripts or as a _vim_ file
picker (see # EXAMPLES)

*ftl* is written in Bash, the language that packs a real punch ... and sometimes
punches you; it will not work in other shells but it may be a cool exercise to
make it portable. Most of the code is one liners, albeit long, and it's
structured to be "easy" to expand.

## File Listing

The listing consists of a header and directory listing.

The header displays information depending on the current state:

        - current directory, possibly truncated
        - listing mode, directory/file
        - image mode, all files/non images/images
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
        - colored entries according to LS_COLORS
            - override color (See ftlrc)

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
                                              
## Preview Pane And Live Previews

The preview pane can be switched on and off during the session and its size can
be changed. 

Some entry types have multiple types of preview (IE: directories) that can be
accessed with a keyboard shortcut («z1» and «z2» by default)

The preview pane is not, generally, a static view of the file but, thanks to
_tmux_, a running program. If you are positioned on a text file, _vim_ will be
run to display it. If you change the position in the listing pane, the preview
program is killed and a new program is started.

The idea is to use within *ftl* what you normally use on the command line.

Supported files:

        - images

        - videos

        - ASCII text with escape sequences

        - cbr/cbz

        - directories

        - html

        - json

        - manpage

        - markdown

        - mp3s

        - pdf

        - rar

        - sc-im

        - shellscript

        - svg

        - text files

See "Creating you own viewer" in "## External Viewer"

## Extended And Detached Viewers

For some file types, often media types, *ftl* can show an extended preview and 
even start a detached viewer. 

See "## External Viewer" below and config in _'$FTL_CFG/etc/ftlrc'_. 

## Vim And Vim-like Bindings
*ftl* uses the awesome _vim_ for text preview, if it's not your favorite editor
you can install it just for previewing (and maybe find it awesome). Patches for
other editors are welcome.

*ftl* bindings are vim-like, vim-bindings take time to get used to, and often
take multiple key presses but they are more logical as families of commands are
accessed with shortcuts that start with the same letter. You can find the file
_ftl_not_so_vim_like_ in the distributions for much less vim-like bindings. Mix
and match to your liking and let me know what better bindings you use, vim-like
or otherwise.

See section "# KEY BINDINGS" below.

## Hyperorthodoxy

*ftl* is hyperothodox, it starts as a file-list manager with a preview. You can
choose to remove the preview as well as adding more panes showing the same or
different directories. The outstanding _tmux_ makes this possible.

Panes are independent instances of ftl that work in synch, each pane has its
own tabs, filters, ... 

## Filtering 

*ftl* can filter the entries in many ways, even using external filters you
define, to list only the entries you want to see.

See "## Filtering" in commands.

## Tabs

Tabs are views, to same or different directories, in the same pane. Filters
are per tab so you can have two tabs with different filters.

## Bookmarks

You can bookmark locations and jump back to them. Bookmarks can be set in the
configuration file, added in the current session and made persistent.

## Selection

You can select multiple entries, the selection is synchronized between panes
when option _auto_selection is set (set by default). 

## Etags

Etags is extra information that is optionally prepended to the entries.

Available etags are:

        /home/nadim/nadim/devel/repositories/ftl 2/14 ⍺
        1  08/11/2022-12:00 ftl

           ⮤              ⮥ date 

        /home/nadim/nadim/devel/repositories/ftl 2/14 ⍺
        1  M ftl
        1 ?? doc

          ⮤⮥ git-status

        /home/nadim/nadim/devel/repositories/ftl 2/14 ⍺
        11 1598x2100 image.jpg
        12  720x 507 image.png
        
           ⮤       ⮥ image-size

        /home/nadim/nadim/devel/repositories/ftl 2/14 ⍺
        1   ftl
        1 ᵀ doc

          ⮤ tmsu tag

        /home/nadim/nadim/devel/repositories/ftl 2/14 ⍺
        1   ftl
        1 ᵛ a virtual file

          ⮤ virtual entry

## Tags
*ftl* has support for tags via TMSU

## Type 

Text files are opened in _vim_.

_7z|bz2|cab|gz|iso|rar|tar|tar.bz2|tar.gz|zip_ archives are automounted.

You can add handlers in _'$FTL_CFG/bindings/type_handlers'_

## Virtual Entry Injection

*ftl* has a very simple mechanism that allows you to inject _virtual entries_
in the listing. You can control their colors, preview, and keyboard actions.

See "# Virtual file injection" in '#EXAMPLES'.

# KEY BINDINGS

The bindings can be changed in the default ftlrc file but it's better to create
your own rcfile. See example in "# EXAMPLES" below.

Reserved for *ftl*: [ÅåÄ]

## Default Bindings

«c» will open a window listing all the current binding, in _fzf_,
wich allows you to search per key or name.

        map    section  keys     command                
        -------------------------------------------------------------------
        ftl    file     w        copy          copy file to, prompts inline
        ...

## Leader Key

The “Leader key” is a prefix key used to extend *ftl* shortcuts by using
sequences of keys to perform a command. The default is '\\'

        leader_key=SPACE # set LEADER to SPACE

## User Defined Bindings

        bind function arguments, all mendatory:

                map                        map name (hint)
                section                    section name (hint)
                keys                       key combination
                command                    name of the internal command that is called
                short_ help                help displayed in command listing
              

        eg: bind ftl        file  w            copy     "copy file to, prompts inline"

        eg: bind leader_ftl extra "LEADER f h" ftl_help "display help"

You can also override _ftl_event_quit_ which is called when *ftl* is closing,
you can see it in use in _'$FTL_CFG/bindings/type_handlers'_

In the default _ftlrc_ file, associative arrays A for alt-gr and SA for
shift+Alt-gr are defined, they allow you to define bindings this way: 

        eg: bin ftl filter fc clear_filters "clear filters"


AltGr and Shift+AltGr keys are also available. When bindings are shown _alt-gr_
is replaced by _⇑_ and "_shift+alt-gr_ is replaced by  _⇈_; as well as the key
the combination would generate that makes it easier to search by name or by
binding. 

Available symbolic names (depending on your OS bindings and terminal) :

        LEADER COUNT

        AT, BACKSPACE, DEL, ENTER, ESCAPE, INS

        BACKSLASH, QUOTE and DQUOTE, SPACE, STAR, TAB, QUESTION_MARK

        UP, DOWN, RIGHT, LEFT, PGUP, PGDN, HOME, END 

        F1 to F12

        CTL-A to CTL-Z

See example in "# EXAMPLES" below.

## Binding Commands That Take A Count
If you prepend symbol "COUNT" in your binding definition, *ftl* will gather the
count in $COUNT variable before calling your command. If you specify "COUNT" in
your binding then the user has to type a, non zero, count; if you want "COUNT"
to be optional you must specify two bindings; one with "COUNT" and one without.

	bind test count		"COUNT t"	count_test		""

	count_test() { tmux popup -h90% -w90% -E "echo count = $COUNT | less " ; }

# COMMANDS

- General *ftl* Commands
- Viewing modes
- Panes
- Tabs
- Moving Around
- Preview
- Sorting
- Filtering
- Searching
- Selection
- Etags
- Tags
- Bookmarks
- History
- File And Directory Operations
- External Commands
- External Viewer
- Shell Pane
- Command Mode
- Time Events

## General *ftl* Commands

        «?»             Show this man page 

                        The man page shows the default bindings. You can configure *ftl*
                        to show a different help if you prefer to cook your own.

        «c»             Show keyboard bindings 

                        The bindings listing is generated at runtime, if you add
                        or modify bindings they will show in the listing. The listing
                        is displayed in fzf which allows you to search by name but
                        also by binding.

        «q»             Quit, closes the current tab, it there are tabs, then closes the
                        last created pane, then closes *ftl*.

        «Q» «ZZ»        Quit all, closes all tabs and panes at once.

        «ZS»            Quit, quit all but doesn't close the shell pane if one exists.

        «ZP»            Quit, doesn't close the preview pane if one exists and zooms it.

        «$»             Detach the preview from ftl, open a new preview pane.

        «¿»             Pdh, pane used for debugging.


## Viewing Mode

        «zs»               Show size (circular)
                                  - no size
                                  - only files
                                  - file size and directory entries
                                  - file size and directory sizes (computed once)

        «z.»               Show/hide dot-files.
        
        «zg»               Show/hide stat, entry stat is added to the header.

        «zt»               Show/hide etags, see "Select etag type" below.

        «zp»               Montage mode, directory preview is a montage of the images.

        «zP»               Refresh preview or montage.

        «zep»              Show/hide current extension preview.

        «zmd»              file/directory mode

        «zmv»              File/dir view mode (circular)
                                  - only files
                                  - only directories
                                  - files and directories

        «zmm»              View mode (circular)
                                  - filter out non-images
                                  - filter out images
                                  - show all files

        «zma»              Show all files

        «zmi»              filter out non-images              

        «zmn»              filter out images

        «zmp»              Show pdf preview as text or image.

        «zmI»              Show/hide image preview.

        «zmD»              Preview directory only/all. 

        «zeh»              Hide files having the same extention as the current file, per tab

        «zeH»              Hide files having the same extention as the current file, global 
                        
        «zec»              Show all hidden extensions 

        «z*»               Set maximum listing depth

                               Set the maximum depth of listing, 1 shows the entries in the
                               current directory. It's sometimes practical but using multiple
                               tabs or panes is more ergonomic.

        not assigned       Preview lock
        not assigned       Preview lock clear

## Panes
        «CTL-W j»                New ftl pane below 

        «CTL-W h»                New ftl pane left 

        «CTL-W H»                New ftl pane left, keep focus 

        «CTL-W l»                New ftl pane right 

        «CTL-W L»                New ftl pane right, keep focus 

        «gp»                     Set focus on the next pane

## Tabs

        Each tab has its own index-name, indexes are not reused;
        tabs have their own filters; each pane has its own tabs.

        Tabs are close with «q», when the last tab is closed the pane
        is closed.

        «⇈s/§»             New tab 

        «gt»               Next tab 

        «TAB»              Next tab 

        «COUNT gt»         Goto tab

        «gT»               Previous tab

## Moving around
        Also see "cd" in *General Commands*, *Bookmarks* and *History* below

        *ftl* will automatically put you on a README if you haven't visited
        the directory before; afterward *ftl* will remembers which entry you
        were on.

        «ENTER»            cd into directory or edit file if not binary

        «h»                Cd to parent directory            
        «LEFT»             Cd to parent directory            

        «j»                Down to next entry                
        «DOWN»             Down to next entry                

        «k»                Up to previous entry              
        «UP»               Up to previous entry              

        «l»                cd into entry                     
        «RIGHT»            cd into entry                     

        «PGDN» «CTL-F»     Page down                         
        «PGUP» «CTL-B»     Page up                           

        «gd»               Move to first directory

        «gg»               Move to first file

        «G»                Move to las file

        «g LEADER»         cycle between top/file/bottom

        «gh»               position cursor on the first file in the window

        «gl»               position cursor on the last file in the window

        «gD»               *ftl* prompts you for a path, with path completions, and cd.
                           You can also change directory with bookmarks or by searching for it

        «COUNT %»          position cursor iat COUNT percent in the entries

        «(» «ö»            Next entry of same extension      

        «{» «Ö»            Next entry of different extension 

        «#»                Goto entry by index               

        yn                 Goto next selected entry

        yN                 Goto previous selected entry

        «K»                Scroll preview up                 

        «J»                Scroll preview down               

## Preview

        «zv»               Preview show/hide      

        «z+» «+»           Change preview size, see rc file predefined sizes

        Some entry have multiple preview types, these bindings let you
        to see the other type of preview.

        entry types with multiple preview types:
                - directories
                - music, will show information and play the music
                - pdf
                - tar files 
                - markdown
                ...

        «z1»                  Alternative preview #1 

        «z2»                  Alternative preview #2 

        not assigned          Preview file's end (text files in vim)

## Sorting 

        «zo»               Set sort order :
                                - alphanumeric
                                - size
                                - date

        «zO»               Reverse sort order 

        «fE»               Choose sort order from external sorts 

## Filtering

        External filters are applied first (to directories and files).

        Filter #d is applied to directories.

        Filter #1, filter #2, and reverse-filter are applied to files.

        Filters are arguments passed to rg.

                examples: 
                        .                # select everything
                        -i inst          # select entries containing "inst", case insensitive
                        INST             # select entries containing "INST", case sensitive
                        
                regular expressions:
                        
                        If you want to filter entries with a regular expression things get a
                        bit more complicated. What you give as a filter is passed directly to
                        rg, including options such as '-i', but the data passed to rg is not 
                        just the entry name.
                        
                        *ftl* passes a string which contains the size, the date, and the name
                        to rg, separated with a '\t'; here's an example:
                        
                                62[\t]1663067416.1648839110[\t].gitignore
                        
                        To find an entry that starts with digits you'll need this filter which
                        handless the first two fields:
                        
                                \t.+\t[[:digit:]]
                        
                        It's also possible to define a filter in a function, instead for using
                        filter #1/#2/reverse. The filters directory contains extra filters. 
                        
        «fE»               Choose filter from external filters 
                        
        «fd»               Set filter #d
                        
        «ff»               Set filter #1 

        «fF»               Set filter #2 
                        
        «fr»               Set reverse-filter 
                        
                           Filters out what you don't want to see. Applied after other
                           filters are applied. It can be set in your ftlrc file.
                        
                           eg: keep files containing 'f' and not containing 'i'
                                «ff»  -> f
                                «fr» -> i
                        
                           eg: always hide vim swap files, set by default in _ftlrc_
                                rfilter0='\.sw.$'
                        
        «fy»               filter out non selection
 
        «fx»               Select files to keep via bash commands
                             
                           Put the files you want selected in "ftl_to_keep_XXXXXXX"

        «fX»               Select files to hide via bash command

                           Put the files you want selected in "ftl_to_hide_XXXXXXX"

        «fc»               Clear all filters 


## Searching

        Incremental search:
               
        «/»                Start the incremental search.

                You can move around in drectories while in incremental search.
                The search is reset when you change directory. The last part
                of the search can be delete with the BACKSPACE key. To end the
                incremental search press the ESCAPE key.
 
        «n»                Find next                      

        «N»                Find previous                  

        «gfi»              go to image using sxiv

        «gfI»              go to image using sxiv, including sub directories

        «gfu»              Fzfi, use fzf and ueberzurg to find and display images

        Fzf searches:

        «gff» «b»          Fzf find in current directory  

        «gfF» «B»          Fzf find                       

        «gfd»              Fzf find only directories      

        «gfa»              Fzf find regexp/fuzzy          

        «gfA»              Fzf find, filrs and subdirs, regexp/fuzzy          

        «gfr»              Ripgreg with preview           

        «gfp»              ftl pane preview, files in the directory

        «gfP»              ftl pane preview, directory and sub directories

        «gy»               Opens fzf to choose an entry in the selection, then
                           changes directory to where the selection is.

                           This is handy when selections are read from a file with option
                           -t on the command line or via the 'load_sel'

        «gm»               Fzf go to bookmark, open multiple tabs with «ctrl-t»

        «gM»               Fzf to persistent bookmark, open multiple tabs with «ctrl-t»

                           You can inject marks dynamically, for example add
                           fzf-marks to my persistent marks which let's me jump
                           to marks in the command line or in *ftl*.

                               gmark_fzf_user() { perl -ape '$_ = "$F[2]/\$\n"' ~/.fzf-marks ; }

        Opening search results in tabs:
                If you use one of the above you can pick multiple entries.
                Entries can be opened in a new tab with 'ctrl+t'.

        not_assigned       Merge selection from all panes, see option auto_select

## Selection

        *ftl* will display a glyph next to selected files. Option auto_select
        controls if the selection is automatically merged to other panes.

        Multiple selection classes are available, *ftl* will ask which class
        to use. The number of entries is displayed in the header.

        «[COUNT] yy»       Select current entry in "normal" class and move down

        «[COUNT] Y»        Select current entry in "normal" class and move down

        «[COUNT] yu»       Select current entry in "normal" class and move up

        «[COUNT] y1/2/3/4» Select current entry in given class and move down, the
                           glyph used for each class is defined in _ftlrc_ tglyph. 

                
        «yf»               Select all the files in the current directory

        «yd»               Select all directories

        «ya»               Select all files and subdirs in the current directory

        «ye»               Select files with same extension

        «yie»              Fzf select files with same extension

        «yE»               Select files ext, with subdirs

        «yiE»              Fzf select files ext, with subdirs

        «yii»              Select image via sxiv

        «yiI»              Select image via sxiv, including sub directories

        «yif»              Open fzf to select files, multiple selection is possible.

        «yiF»              Open fzf to select files and sub directories.

        «yc»               Deselect all files and directories, including those in other
                           directories.

        «yC»               Opens fzf to let you choose which entries to deselect.

        «ytc»              Copy selection to clipboard, full path, separated by a space.

        «gy»               Opens fzf to choose an entry in the selection, then
                           changes directory to where the selection is.

        «yn»               Go to next selected entry.

        «yN»               Go to previous selected entry.

        «yx»               Select files via bash commands
                             
                           Put the files you want selected in "ftl_to_select_XXXXXXX", if you
                           do it often write a script.

        «yX»               Select files via up (the ultimate plumber) TUI

        not_assigned       Merge selection from all panes, see option auto_select

        not_assigned       Fzf merge selection from panes 

## Etags
        «zt»               Show/hide etags

        «zT»               Select etag type from list

## Tags

        «LEADER t LEADER»  show tmsu tags in preview

        «LEADER t g»       goto tmsu tagged file via fzf

        «LEADER t f»       tmsu tag selection via fzf

        «LEADER t m»       tmsu mount

        «LEADER t q»       filter based on tmsu tags or query

        «LEADER t r»       filter based on tmsu tags via fzf

        «LEADER t s»       sc-im interface to tmsu tags

        «LEADER t t»       tag selection

## Bookmarks

        «m» + char         Bookmark directory/file 

        «'» + char         Go to bookmark 

        «'» + "'"          Go to previous directory

        «gm»               Fzf go to bookmark, open multiple tabs with «ctrl-t»

        «MM»               Add persistent bookmark    

        «gM»               Fzf to persistent bookmark, open multiple tabs with «ctrl-t»

        «Mc»               Clear persistent bookmarks 

## History

        *ftl* keeps two location histories, one for the current session and one
        global.

        «HH» «¨»           Fzf history all sessions, open multiple tabs with «ctrl-t»

        «Hh»               Fzf history current session, open multiple tabs with «ctrl-t»

        «He»               Uses fzf to mark entries that will be removed from the history

        «Hc»               Clear all sessions history 

## File and directory operations

        «if»               Create new file        

        «id»               Create new directory   

        «ib»               Create entries in bulk, in _vim_, end lines with / for directories

        «d»                Delete selection, uses configuration *RM* variable, see ftlrc.

        «w»                Copy entry        

        «pp»               Copy selection    

        «pm»               Move selection    

        «P»                Move selection to, Uses _fzf_mv_.

        «R»                Rename selection

        «xl»               Symlink selection 

        «gL»               Goto symlinked file     

        «xmr»              Flip selection read bit 

        «xmw»              Flip selection write bit 

        «xmx»              Flip selection execute bit 

        «xmm»              Set permissions for one entry interactively 

        «xmM»              Set permissions interactively 

        «xh»               Hexadecimal preview    

        «xv»               open in vim    

## External Commands

        Example of command integration, see 'etc/bindings/leader_ftl'.

        «LEADER f c»       Compress/decompress            

        «LEADER f t»       vim diff two selected files                 

        «LEADER f P»       Convert pdf to text file       

        «CTL-G»            Display stat in preview pane   

        «LEADER f z»       Encrypt/decrypt using password 

        «LEADER f x»       Encrypt/decrypt using _gpg_    

        «LEADER s »        Shred selection using _shred_  

        «LEADER f i»       Reduce jpg image size          

        «LEADER f i»       Reduce png to jpg              

        «LEADER f p»       Reduce pdf size                

        «LEADER f v»       Reduce video size              

        «LEADER f l»       Lint current directory         

        «LEADER f m»       Send mail                      

        «LEADER f t»       Terminal popup                 

        «:url URL»        open URL in qutebrowser

## External Viewer

        Sometime Previews in ftl are not enough, eg. you really want to see
        that pdf with the images in it not just a text rendering. The external
        key bindings set the _emode_ variable and an external viewer decide how
        to display an entry, that may be in a text based application or not.

        *ftl* had a some viewers for images, videos, comics, ...

        «ee»               External viewer, mode #1 

        «er»               External viewer, mode #2, detached 

        «ew»               External viewer, mode #3 

        «aA»               Fzf choose viewer 

        Media types

        «aa»               Background sound preview, stops when *ftl* closes.

        «ak»               Kill sound preview 

        «aq»               Queue entries in music player. default to cmus.

                           You can binding cmus in *tmux* for easy access.

        Creating you own viewer:

                viewers are in '$FTL_CFG/viewers'
                
                default viewers are in file '$FTL_CFG/viewers/core'

## Shell Pane
        «CTL-W ss» «s»     Shell pane

        «CTL-W sv» «Sv»    Vertical shell pane, closes the preview

        «CTL-W sS» «SS»    Shell pane with selected files 

        «CTL-W sz» «Sz»    Shell pane, zoomed out 

        «CTL-W sg» «gS»    Cd shell pane to ftl directory

        «CTL-W sf» «Sp»    Send selection to shell pane 

        «CTL-W !»  «S!»    Switch to session-shell pane 

        «CTL-W sp» «Sp»    Run shell command in pane

        «CTL-W sq» «Sq»    Close shell pane

# Command Mode

You can run commands in different ways

        - Within a shell pane, see *Shell Panes* above
        - user defined ftl command

If you run the same command often you can create a command that you can call
directly from *ftl*.

Create a shortcut, maybe using a function keys, and put your code
in $FTL_CFG/bindings/, it will be loaded automatically by *ftlrc*. See 
"# EXAMPLES" below.

You can also add commands without bindings, in $FTL_CFG/commands/, *ftl*
will lets you choose a command to run with the invaluable _fzf_ or at the
command prompt.

        «:»                Command prompt   

        «LEADER u»         Run user command 

        the scripts are either
                - bash scripts that are sourced (can change *ftl* state)
                - executables written in any language

        Look in $FTL_CFG/etc/commands/XX_example for documentation.

From the command prompt

        «:»                Command prompt 

        You are prompted, with edit/history/completion, for a command:

                - «empty answer»         Cancel

                - ^[1-9][0-9]*$          Goto entry

                - ^etags                 Chose tagging method

                - "load_sel"       Load selection from a file

                - ^tree                  display a tree in a popup pane

                - ftl shortcut           run the *ftl* command

                - ftl function           run the *ftl* command

                - user_command [args]    run the user command

                - external command       See 'External command' below

## External Commands

*ftl* has one _session-shell_, a pane running bash, where your external commands
are run by default.

        «:»                Command  prompt, command [args]

        «tmux-prefix+L»    Switch back from tmux pane 

        Selection an shells:
        
        *finfo* can list the following data:

                - selection (selected files)

                - FTL_PID (ftl's pid)

                - FTL_FS (ftl's data directory)

                - FTL_PWD (ftl's current directory)

                - n (current file)

                without arguments *finfo* lists ftl's selection, null separated
                        
                        «:» finfo | xargs -0 ls --color=always

                        «:» finfo | xargs -0 -n 1 ls --color=always

                first argument is the separator used to display data, remaining
                arguments are the name of the data to list:

                        finfo \\n selection # list selection separated by '\n'

                *finfo* can also be used in the default shell  
        
        "${selection[@]}" and "$n" (the current entry) can also be used in commands.

Running commands in a separate shell pane in the *ftl* session

        *fsh* command [command args]
        
        Can be used when commands that take a long time to complete.
                
        The shell pane is closed if the command exit code is 0. 

Running commands in the current window

        You can split windows with tmux commands or you can use _full_ and _split_ which
        give you access to _finfo_.

                *full*  command [command args]

                *split* command [command args]

Command aliases
        
        *ftl* checks for aliases in the _cmd_aliases_ array defined
        in _ftlrc_.

                declare -A cmd_aliases=([csx]="split finfo | xargs -0" [cfx]="full finfo | xargs -0")

Examples
                                                       run command in:
        
        «:» command                                    default shell

        «:» fsh command                                own shell

        «:» finfo | xargs -0 command                   default shell, one command for all selection

        «:» finfo | xargs -0 -n1 command               default shell, one command per selection

        «:» fsh finfo | xargs -0 command               own shell, one command for all selection

        «:» fsh finfo | xargs -0 -n1 command           own shell, one command per selection

        «:» finfo | xargs -0 -n1 fsh command           one shell per selection

        «:» split finfo | xargs -0 echo ; read -sn1    split window

        «:» csx ls -l ; read -sn1                      split window and use an alias, read necessary to
                                                           keep window open

        «:» full finfo | xargs -0 ls -l ; read -sn1    full screen


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

You can override configuration in your own ~/.ftlrc after sourcing the 
default configuration.

# ENVIRONMENT

$FTL_CFG (set by default to $HOME/.config/ftl) is the directory that contains
*ftl* code and data.

# CONFIGURATION

See _"$FTL_CFG/etc/ftlrc"_, ftl's default config file, for details. 

# EXAMPLES

## Helpful Tmux Bindings

        # start ftl in a new window
        tmux bind C-F run-shell 'tmux new-window -n ftl ftl "#{pane_current_path}"'

        # start ftl on a specific directory in a new window
        tmux bind C-D new-window -n download "ftl $HOME/downloads"

## Example User RCfile

        # source default config
        source $FTL_CFG/etc/ftlrc

        # change leader-key to SPACE key
        leader_key=SPACE

        # don't show swap files
        rfilter0='\.sw.$'

        # set to auto mount archives, fuse-archive must be installed
        mount_archive=1

        # display options for fzf
        fzf_opt="-p 90% --cycle --reverse --info=inline --color=hl+:214,hl:214"

        # columns when displaying command mapping in popup
        CMD_COLS=150

        # how to delete files
        RM="rip --graveyard $HOME/graveyard" ; mkdir -p $HOME/graveyard

        # alternative directory preview
        NCDU=gdu

        # define your bookmarks
        declare -A marks=(
                [0]=/
                [1]=$HOME/$
                [3]=$HOME/downloads/$
                [$"'"]="$(tail -n1 $ghist)" # last visited directory
                )

        # User colors
        declare -A user_colors=([special_entry]="30;42")

        # load git etag support 
        . ~/.config/ftl/etags/git

## User Command With Binding

This example can be found in $FTL_CONFIG/user_bindings/01_shred

        shred_command() 
        {
        # prompt user
        ((${#selection[@]} > 1)) && plural='ies' || plural='y'
        prompt "shred: ${#selection[@]} entr${plural} [yes|N]? "

        [[ $REPLY == yes ]] && # reply must be "yes"
                {
                # use shred utility and clear the selection
                shred -n 2 -z -u "${selection[@]}" && selection_clear

                cdir # reload directory
                } ||
                # redisplay list to override prompt
                list
        }

        # bind shortcut «LEADER s» 
        bind leader file "LEADER s" shred_command "overrides selection, bypasses \$RM"

## user defined preview

Code for generating a preview is in '$FTL_CFG/viewers/core', you can also
define code for preview in your *ftlrc*. Below is an example from my config.

I have files with extensions "pbs_log" and "pbs_log_failed", those files
contain ANSI escape code. Files with ANSI escpe code have three different
previews, one of them uses vim plus the AnsiEsc plugin; I also handle the
above files in my vimrc. The problem is that both vim and ftl try to set
AnsiEsc resulting in AnsiEsc not being set at all! 

I check the file extension, if they match I bypass ftl's default viewer.

        user_pviewers() 
        {
        [[ $e == pbs_log || $e == pbs_log_fail ]] && ((extmode==1)) && { ptext ; return 0 ; }
        
        # you can define multiple hanlers in this function
        # return false for the default ftl handlers to run
        }

## Using Bash to select and filter

        During an ftl session you decide that you want to select:

            - all the files under the current directory
            - not in the backup directory 
            - with size under 5 MB
            - accessed this week
            - belonging to group nadim
            - which is a mp4 video
            - that's not rotated
            - that's does have matching sha256 signature file

        Supporting this kind of query is easier done by a set of commands in a bash
        pipeline.

            find -size +5M -mtime -7 -not -path "*/video_backup/*" -group nadim

        The file needs to be an mp4

            mimemagic | grep mp4

        Not rotated

            exiftool | grep -i rotation | grep 0

        With a sha256 signature file

            perl -ne 'chomp ; -e "$_.sha256" && print "$_\n"'

        Put together: 

            find -size +5M -mtime -700 -not -path "*/video_backup/*" -group nadim | \
            perl 'chomp ; -e "$_.sha256" && print "$_\n"' | \
            while read -r f ; do mimemagic "$f" | grep -q mp4 && echo "$f" ; done | \
            while read -r f ; do exiftool "$f" | grep -i rotation | grep -q 0 && echo "$f" ; done

        «yx», «fx», and «fX», open a shell after creating a temporary file where you
        can put the results of your selection/search.

        You couls also open a shell with «s» and run the following command: 

            find -name '*.png' | filter-on-file-size -5000 | xargs realpath >$ftl_fs/load_sel

        Close the shell then runf this commnd in *ftl*: load_sel.

        You can move from selection to selection with «yn» or via fzf with «gy».


## Virtual Entry Injection

To inject entries in the listing you need to define functions to:

        - get directory entries
        - get file entries
        - color virtual entries
        - handle the preview of virtual entries
        - handle keyboard input for virtual entries

The names of the functions are up to you, but try something unique to
what you are implementing. 
 
        Call vfiles_set() with the above function in that order.

        Call vfiles_go() to turn injection on, "get directory entries" and "get file entries"
        will be call every time the listing need to be updated, "$PWD" is set before the calls.  

        Call vfiles_rst() to reset everything.
        
        See '$FTL_CFG/etags/virtual' and '$FTL_CFG/bindings/virtual_files'

## Time Events
You can register functions in *ftl* to be run at when a 'Time Event' occurs.

Set "time_event" in _ftlrc_ to a positive integer n, a 'Time Event' will
occurs every n seconds.

Register your function:

        print_seconds(){ pdhn $SECONDS ; }
        time_event_handlers[print_seconds]=print_seconds

If you want your function to be run every 'x' seconds, you'll need to handle it
yourself, *ftl* will call your function every 'n' seconds.

## Directory Changer

        Add the following code to your bashrc:
                source $path_to_ftl/cdf

        This adds a _cdf_ function which will open an *ftl* instance you can
        use to navigate your directories, jump to bookmarks, ...

        Press «q» to quit and jump to the directory you're currently in.

        Press «Q» to cancel.

## Files/Directories Picker

        Add the following code to your bashrc:
                source $path_to_ftl/ftll

        This adds a _ftll_ function which will open an *ftl* instance in a new
        tmux window, select the entries you want, without selection the current
        entry is selected.

        Press «q» to quit to return the selection.

        Press «Q» to cancel.

        You can also create a "virtual" file and select it, thus you can use ftl as
        a save-as dialog.

## Vim Files Picker

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

## Vim As Man Pager
        To use vim as a man page viewer add this to your bashrc:

                MANPAGER="vim -c 'set nospell' +MANPAGER -"

        I also added this to my vimrc:

                au FileType man setlocal nospell

## Sxiv background colors and font

        Add the folloing lines in your ~/.Xresources:
            Sxiv.background: #000000
            Sxiv.foreground: #00C0FF
            Sxiv.font: Mono-12

       If you display svg files you may need a grey background, here's
       and example is you decide to use nsxiv instead for sxiv.

            Nsxiv.*.background: #808080
            Nsxiv.*.foreground: #F0F0F0

# BUGS AND CONTRIBUTIONS

Please report bug to <https://https://github.com/nkh/ftl/issues>

Contributions are best done via pull requests on github. Keep code to a bare minimum.

#AUTHOR

© Nadim Khemir 2020-2023

mailto:nadim.khemir@gmail.com

CPAN/Github ID: NKH

# LICENSE

*ftl* is under Artistic licence 2.0 or GNU General Public License 3, at your option.

*ftl* logo is base on tmux logo; tmux license is at https://github.com/tmux/tmux/blob/master/logo/LICENSE

# SEE ALSO

ranger, fff, clifm, lfm, nnn, vifm, broot, gitfm, ...

