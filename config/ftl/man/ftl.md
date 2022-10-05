% FTL(1) | General Commands Manual
# NAME
ftl - terminal file manager, hyperorthodox, with live previews

# SYNOPSIS

ftl

ftl [ [-t file] [-T file] ][directory[/file]]

# OPTIONS

-t file         file contains paths to files to tag

                eg: ftl -t <(find -name 'ftl*') 

-T file         file contains paths to files to show in own tab, must come
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
be switched on and off during the session; its size can be changed. Some
entry types have multiple previews (IE: directories) that can be accessed
with a keyboard shortcut (Alt-gr+v and Alt-gr+V by default)

The preview pane is not, generally, a static view of the file but, thanks to
_tmux_, a running program. If you are positioned on a text file, _vim_ will be
run to display it. If you change the position in the listing pane, the preview
program is killed and a new program is started.

The idea is to use within *ftl* what you normally use on the command line.

## Extended And Detached Viewers

For some file types, often media types, *ftl* can show an extended view and 
even start a detached viewer. 

See "## External Viewer" below and config in '$FTL_CFG/etc/ftlrc'. 

## Vim

*ftl* uses the awesome _vim_, if it's not your favorite editor you can install it
just for previewing (and maybe find it awesome). Patches for other editors are
welcome.

## Tabs

Tabs are views, to same or different directories, in the same pane. Filters
are per tab so you can have two tabs with different filters.

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
reusing what's available. *ftl* is designed to integrate other Unix
tools and applications.

*ftl*  will probably not work in other shells but it may be a cool exercise
making things portable.

Most of the code is one liners, albeit long, and it's structured to be "easy"
to expand.

# KEY BINDINGS

*ftl* uses vim-like key bindings, the bindings can be changed in the default
ftlrc file but it better to create your own rcfile.

## Default bindings

'Alt-gr'+c will open a window listing all the current binding, in _fzf_,
wich allows you to search per key or name.

        map    section  key      command                
        -------------------------------------------------------------------
        ftl    file     c        copy          copy file to, prompts inline
        ...

## User defined bindings

        bind function arguments, all mendatory:

                map                        map where the binding is saved
                section                    logical group the binding belongs to (hint)
                key                        the keyboard key
                command                    name of the internal command that is called
                short_ help                help displayed in command listing
              

        eg: bind ftl file k copy "copy file to, prompts inline"

You can also override _ftl_event_quit_ which is called when *ftl* is closing,
you can see it in use in _'$FTL_CFG/bindings/type_handlers'_

In the default _ftlrc_ file, associative arrays A for alt-gr and SA for
shift+Alt-gr are defined, they allow you to define bindings this way: 

        eg: bin ftl filter "${A[d]}" clear_filters "clear filters"

When bindings are shown _alt-gr_ is replaced by _⇑_ and "_shift+alt-gr_
is replaced by  _⇈_; as well as the key the combination would generate
that makes it easier to search by name or by binding. 

Available symbolic key name (depending on your OS bindings and terminal) :

        AT, BACKSPACE, DEL, ENTER, ESCAPE, INS

        BACKSLASH, QUOTE and DQUOTE, SPACE, STAR, TAB

        UP, DOWN, RIGHT, LEFT, PGUP, PGDN, HOME, END 

        F1 to F12

        CTL-A to CTL-Z

See example in "# EXAMPLES" below.

## Leader key

The “Leader key” is a prefix key used to extend *ftl* shortcuts by using
sequences of keys to perform a command. The default is '\\'

        # set leader to "space"
        bind ftl bind BACKSPACE leader_key 'leader key SPACE'

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
- Tags/Selection
- Marks
- History
- File And Directory Operations
- External Commands
- External Viewer
- Shell Pane
- Command Mode

## General *ftl* Commands

        «?»             Show this man page 

                        The man page shows the default bindings. You can configure *ftl*
                        to show a different help if you prefer to cook your own.

        «⇑c/©»          Show keyboard bindings 

                        The bindings listing is generated at runtime, if you add
                        or modify bindings it will show in the listing. The listing
                        is displayed in fzf which allows you to search by name but
                        also by binding.

        «q»             Quit, closes the current tab, it there are tabs, then closes the
                        last created pane, then closes *ftl*.

        «Q»             Quit all, closes all tabs and panes at once.

        «@»             Quit, quit all but doesn't close the shell pane if one exists.

        «⇈q/Ω»          Quit, doesn't close the preview pane if one exists and zooms it.

        «$»             Detach the preview from ftl, open a new preview pane.

        «*»             Set maximum listing depth

                        Set the maximum depth of listing, 1 shows the entries in the
                        current directory. It's sometimes practical but using multiple
                        tabs or panes is more ergonomic.

        «⇑t/þ»          Copy selection to clipboard, full path, separated with by a space.

        «¿»             Pdh, pane used for debugging.

        Bindings used internaly by *ftl*

                        Refresh curent pane «r»
                        Handle pane event   «7»
                        Preview pane signal «8»
                        Handle pane preview «9»
                        Cd to shell pane    «0»

## Viewing Mode

        «⇑s/ß»             Show size (circular)
                                  - no size
                                  - only files
                                  - file size and directory entries
                                  - file size and directory sizes

        «.»                Show/hide dot-files.
        
        «^»                Show/hide stat, entry stat is added to the header.

        «⇑./·»             Show/hide etags, see "Select etag type" below.

        «)»                File/dir view mode (circular)
                                  - only files
                                  - only directories
                                  - files and directories

        «M»                View mode (circular)
                                  - filter out images
                                  - filter out non images
                                  - show all files

        «⇑m/µ»             Montage mode, directory preview is a montage of the images.

        «⇈m/º»             Refresh preview or montage.

        «=»                Preview directory only/all. 

        «"»                Show/hide image preview.

        «#»                Show/hide current extension preview.

        «⇈i/ı»             Fzfi, use fzf and ueberzurg to find and display images

        not assigned       Preview lock
        not assigned       Preview lock clear

## Panes

        «_»                New ftl pane below 

        «|»                New ftl pane left 

        «>»                New ftl pane left, keep focus 

        «¦»                New ftl pane right 

        «<»                New ftl pane right, keep focus 

        «-»                Set focus on the next pane

## Tabs

        Each tab has its own index, indexes are not reused; each pane has
        its own tabs. Tabs are close with «q», when the last tab is closed
        the pane is closed.

        «⇈s/§»             New tab 

        «TAB»              Next tab 

## Moving around

        Also see "cd" in *General Commands* above and *Marks* and
        *History* below

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
        «RIGHT»                cd into entry                     

        «PGDN»             Page down                         
        «PGUP»             Page up                           

        «g»                Move to:                           
                                  - top
                                  - first file
                                  - last file

        «G»                CD, *ftl* prompts you for a path, the promt has path completions.
                           You can also change directory with marks or by searching for it

        «ö»                Next entry of same extension      

        «Ö»                Next entry of different extension 

        «ä»                Goto entry by index               

        not assigned       Goto previous tag
        not assigned       Goto next tag

        «K»                Scroll preview up                 

        «J»                Scroll preview down               

## Preview

        «v»                Preview show/hide      

        «+»                Change preview size, see rc file predefined sizes

        «V»                Preview current entry once (if preview pane is close)

        Some entry have multiple preview types, these bindings let you
        to see the other type of preview.

        entry types with multiple preview types:
                - directories
                - music, will show information and play the music
                - pdf
                - tar files 

        «⇑v/“»                Alternative preview #1 

        «⇈v/‘»                Alternative preview #2 


        «⇈t/Þ»                File preview at end (text files in vim)

        «⇑x/»»                Hexadecimal preview    

## Sorting 

        «o»                Set sort order :
                                - alphanumeric
                                - size
                                - date

        «O»                Reverse sort order 

        «⇑f/đ»             Choose  sort order from external sorts 

## Filtering

        filter #1, filter #2, and reverse-filter are arguments passed to rg

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
                        filter #1/#2/reverse. The filters directory contains ten external
                        filters you can load with shortcut «⇑f/đ». 
                        
        «f»                Set filter #1 

        «F»                Set filter #2 
                        
        «⇑d/ð»             Clear all filters 
                        
        «⇑f/đ»             Choose filter from external filters 
                        
        «⇑a/ª»             Set reverse-filter 
                        
                           Filters out what you don't want to see. Applied after other
                           filters are applied. It can be set in your ftlrc file.
                        
                           eg: keep files containing 'f' and not containing 'i'
                                «f»  -> f
                                «⇑a» -> i
                        
                           eg: always hide vim swap files, set by default in _ftlrc_
                                rfilter0='\.sw.$'
                        
        «¤»                Hide files having the same extention as the current file, per tab

        «%»                Hide files having the same extention as the current file, global 
                        
        «&»                Show all hidden extensions 

## Searching

        «b»                Fzf find in current directory  

        «⇑b/”»             Fzf find                       

        «⇈b/’»             Fzf find regexp/fuzzy          

        «⇈'/’/÷»           Fzf find only directories      

        «}»                Ripgreg with preview           

        Opening search results in tabs:
                If you use one of the above you can pick multiple entries.
                Entries can be opened in a new tab with 'ctrl+t'.

        «/»                Incremental search, «ENTER» or «ESCAPE» to end.

        «n»                Find next                      

        «N»                Find previous                  

## Tags/Etags

        A tag is a selected file, *ftl* will display a glyph next to tagged
        files. Option auto_tags controls if tags are automatically merged to
        other panes.

        When using tags and multiple class tags are present, *ftl* will ask
        which class to use. The number of entries is displayed in the header.

        «y»                Tag current entry in "normal" tag class and move down

        «Y»                Tag current entry in "normal" tag class and move up

        «1» «2» «3»        Tag current entry in given class and move down.

        «4»                Tag current entry in D class and move down.
                
        «⇑y/←»             Tag all the files in the current directory

        «⇈y/¥»             Tag all files and subdirs in the current directory

        «t»                Open fzf to tag files, multiple selection is possible.

        «T»                Open fzf to tag files and sub directories.

        «u»                Untag all files and directories, including those in other
                           directories.

        «U»                Opens fzf to let you choose which entries to untag

        «⇑g/ŋ»             Opens fzf to choose an entry among the tags, then
                           changes directory to where the tag is.

                           This is  handy when tags are read from a file with option
                           -t on the command line or via the 'load_tags'

        «⇑o/œ»             Merge tags from all panes, see option auto_tags

        «⇈0/°»             Fzf merge tags from panes 

        «⇈./˙»             Select etag type from list

## Marks

        «m» + char         Mark directory/file 

        «'» + char         Go to mark 

        «'» + "'"          Go to last directory

        «⇈'/×»             Fzf go to mark, open multiple tabs with «ctrl-t»

        «,»                Add persistent mark    

        «;»                Fzf to persistent mark, open multiple tabs with «ctrl-t»

        «⇑k/ĸ»             Clear persistent marks 

## History

        *ftl* keeps two location histories, one for the current session and one
        global.

        «⇑h/ħ» «¨»         Fzf history all sessions, open multiple tabs with «ctrl-t»

        «H»                Fzf history current session, open multiple tabs with «ctrl-t»

        «⇈h/Ħ»             Uses fzf to mark entries that will be removed from the history

        «⇈d/Ð»             Delete all session history 

## File and directory operations

        «i»                Create new file        

        «I»                Create new directory   

        «⇑i/→»             Create entries in bulk, in _vim_, end lines with / for directories

        «d»                Delete selection, uses configuration *RM* variable, see ftlrc.

        «c»                Copy entry        

        «p»                Copy selection    

        «P»                Move selection    

        «⇈p/þ»             Move selection to, Uses _fzf_mv_.

        «R»                Rename, Uses _vidir_.

        «⇑l/ł»             Symlink selection 

        «⇈l/Ł»             Symlink follow    

        «x»                Flip selection executable bit 

## External Commands

        Example of command integration, see 'etc/bindings/leader_ftl'.

        «˽fc»              Compress/decompress            

        «˽fP»              Convert pdf to text file       

        «˽fs»              Display stat in preview pane   

        «˽fz»              Encrypt/decrypt using password 

        «˽fx»              Encrypt/decrypt using _gpg_    

        «˽s»               Shred selection using _shred_  

        «˽fi»              Reduce jpg image size          

        «˽fi»              Reduce png to jpg              

        «˽fp»              Reduce pdf size                

        «˽fv»              Reduce video size              

        «˽fl»              Lint current directory         

        «˽fm»              Send mail                      

        «˽ft»              Terminal popup                 

## External Viewer

        Sometime Previews in ftl are not enough, eg. you really want to see
        that pdf with the images in it not just a text rendering. The external
        key bindings set the _emode_ variable and an external viewer decide how
        to display an entry, that may be in a text based application or not.

        *ftl* had a some viewers for images, videos, comics, directories
        containing media, mp3, ...

        «e»                External viewer, mode #1 

        «E»                External viewer, mode #2, detached 

        «⇑e/€»             External viewer, mode #3 

        «⇈e/¢»             External viewer, mode #4 

        Music has a sound preview mode #1, it lets you play a file in the 
        background. you can stop it when you want or it stops when you
        leave *ftl*. Modes #2-#4 open _G_PLAYER_ which is _vlc_ by default.

        «a»                Kill sound preview 

        «w»                run viewer        

        «W»                Fzf choose viewer 

        The viewer for music queues the files in cmus. I recommend adding
        a binding for cmus in *tmux* to access the application easilly.

        Creating and using a viewer:

                core viewers are in '$FTL_CFG/etc/core/viewers/ftl'

                extra viewers are in'$FTL_CFG/viewers'
                
## Shell Pane
        «s»                Shell pane

        «S»                Shell pane with selected files 

        not assigned       Shell pane, zoomed out 

        «⇈0/°»             Cd shell pane to ftl directory

        «X»                Send selection to shell pane 

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

        «˽u»               Run user command 

        the scripts are either
                - bash scripts that are sourced (can change *ftl* state)
                - executables written in any language

        Look in $FTL_CFG/etc/commands/XX_example for documentation.

- from the command prompt

        «:»                Command prompt 

        You are prompted, with edit/history/completion, for a command:

                - «empty answer»         Cancel

                - ^[1-9][0-9]*$          Goto entry

                - ^etags                 Chose tagging method

                - "load_tags"            Load tags from a file

                - ^tree                  display a tree in a popup pane

                - ftl shortcut           run the *ftl* command

                - ftl functioni          run the *ftl* command

                - user_command [args]    run the user command

                - external command       See 'External command' below

## External Commands

*ftl* has one _session-shell_, a pane running bash, where your external commands
are run by default.

        «:»                    Command  prompt, command [args]

        «!»                    Switch to session-shell pane 

        «tmux-prefix+L»        Switch back from tmux pane 

        Selection an shells:
        
        *fsel* list ftl selection, null separated
                
                «:» fsel | xargs -0 ls --color=always

                «:» fsel | xargs -0 -n 1 ls --color=always
        
        *fsh* command [command args]
        
        Run you commands in a separate shell pane in the *ftl*
        session, eg: when commands that take time to complete.
                
        The shell pane is closed if the command exit code is 0. 
        
                                                   run command in:
        
        «:» command                                default shell

        «:» fsh command                            own shell

        «:» fsel | xargs -0 command                default shell, one command for all selection

        «:» fsel | xargs -0 -n1 command            default shell, one command per selection

        «:» fsh fsel | xargs -0 command            own shell, one command for all selection

        «:» fsh fsel | xargs -0 -n1 command        own shell, one command per selection

        «:» fsel | xargs -0 -n1 fsh command        one shell per selection

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

See "$FTL_CFG/etc/ftlrc", ftl's default config file, for details. 

# EXAMPLES

## Helpful Tmux Bindings

        # start ftl in a new window
        tmux bind C-F run-shell 'tmux new-window -n ftl ftl "#{pane_current_path}"'

        # start ftl on a specific directory in a new window
        tmux bind C-D new-window -n download "ftl $HOME/downloads"

## RCfile

        # source default config
        source $FTL_CFG/etc/ftlrc

        # change leader-key to SPACE key
        bind ftl bind SPACE leader_key 'leader key "˽"'

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

        # define your marks
        declare -A marks=(
                [0]=/
                [1]=$HOME/$
                [3]=$HOME/downloads/$
                [$"'"]="$(tail -n1 $ghist)" # last visited directory
                )

        # load git support 
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

## Vim As Man Pager
        To use vim as a man page viewer add this to your bashrc:

                MANPAGER="vim -c 'set nospell' +MANPAGER -"

        I also added this to my vimrc:

                au FileType man setlocal nospell

# BUGS AND CONTRIBUTIONS

Please report bug to <https://https://github.com/nkh/ftl/issues>

Contributions are best done via pull requests on github. Keep code to a bare minimum.

# AUTHOR

© Nadim Khemir 2020-2022

mailto:nadim.khemir@gmail.com

CPAN/Github ID: NKH

# LICENSE

Artistic licence 2.0 or GNU General Public License 3, at your option.

# SEE ALSO

ranger, fff, clifm, lfm, nnn, vifm, broot, gitfm, ...
