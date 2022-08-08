% FTL(1) | ftl manual
# NAME

ftl - a bash file manager

# SYNOPSIS

ftl

ftl [-t file] [directory[/file]]

# OPTIONS

	-t file		file contains paths to files to tag
			eg: ftl -t <(find -name ftl)

# DESCRIPTION

ftl is file manager written in Bash (the language that packs a real punch and sometimes punches you).

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

## Key bindings

*ftl* uses vim-like key bindings by default, the bindings are defined in the default ftlrc file.

## Default bindings

'Alt-gr'+c will open a window with all the current binding

A list of all bindings is displayed in _fzf_ wich allows you to search per key, name or in the help.

	map           section  key      command                
	-----------------------------------------------------------------------------------
	ftl           file     c        copy                   copy file to, prompts inline

## User defined bindings

You can override all the keys by creating your own rcfile and using the *bind* function.
See <USER DEFINED BINDINGS, COMMANDS, ...> for some examples.

	bind arguments, all mendatory:

		map		map where the binding is saves, ftl is the default map, 
		section		logical group the binding belongs to (hint)
		key		the keyboard key
		command		name of the internal command that is called
		short_ help	help displayed 
              

	eg: bind ftl file k copy "copy file to, prompts inline"

In the default ftlrc file, associative arrays A (for alt-gr) and SA (for shift+Alr-gr) are defined,
they allow you ti define bindings this way: 

	eg: bin ftl filter "${A[d]}" clear_filters "clear filters"

When bindings are shown with 'alt-gr'+c, "${A[d]}" is replaced with "⇑d/ð" wich makes it easier to
search for bindings.

## Leader key

The “Leader key” is a prefix key used to extend ftl shortcuts by using sequences of
keys to perform a command. The default is '\'

	ie: bind ftl bind BACKSPACE_KEY leader_key 'leader key "\"'


## Ftl
ftl           ftl      $              editor_detach          detach editor preview
ftl           ftl      AT_KEY         quit_keep_shell        quit keep shell
ftl           ftl      ⇑c/©           k_bindings             show keyboard bindings
ftl           ftl      ?              ftl_help               show help
ftl           ftl      G              change_dir             cd
ftl           ftl      ¿              pdh_pane               pdh pane
ftl           ftl      Q              quit_all               quit forced
ftl           ftl      q              quit_ftl               quit
ftl           ftl      ⇈q/Ω           quit_keep_zoom         keep shell zoomed
ftl           ftl      r              refresh_pane           refresh
ftl           ftl      STAR_KEY       depth                  maximum listing depth
ftl           ftl      ⇑t/þ           copy_clipboard         copy selection to clipboard
ftl           SIG      7              SIG_PANE               handle pane event
ftl           SIG      7              SIG_REFRESH            preview pane signal
ftl           SIG      8              SIG_REMOTE             handle pane preview
ftl           SIG      9              SIG_SYNCH_SHELL        cd to shell pane
leader_space  test     ˽˽?            leader_space_test      test leader + space + key
leader        test     ˽˽t            leader_test            test leader key

## Panes
ftl           pane     _              pane_down              extra pane below
ftl           pane     -              pane_go_next           next pane or viewer
ftl           pane     |              pane_L                 extra pane: left
ftl           pane     ¦              pane_R                 extra pane: right
ftl           pane     ⇈x/>           pane_right             extra pane left
ftl           pane     ⇈z/<           pane_left              extra pane right

## View
### sorting methods
ftl           view     DQUOTE_KEY     preview_image          show/hide image preview
ftl           view     )              file_dir_mode          file/dir view mode
ftl           view     ⇈i/ı           image_fzf              fzfi, using ueberzurg
ftl           view     M              image_mode             view mode: file/directory/image
ftl           view     ⇈m/º           montage_clear          refresh montage
ftl           view     ⇑m/µ           montage_preview        montage mode
ftl           view     O              sort_entries_reversed  sort reversed
ftl           view     o              sort_entries           sort type
ftl           view     =              preview_dir_only       preview directory only
ftl           view     ⍰              preview_lock           preview lock clear
ftl           view     +              preview_size           change preview size
ftl           view     ^              show_stat              show/hide stat
ftl           view     ⇑s/ß           show_size              show/hide size
ftl           view     ⇈t/Þ           preview_tail           file preview at end
ftl           view     ⇑v/“           preview_m1             alternative preview for : dir, media, pdf, tar, ...
ftl           view     ⇈v/‘           preview_m2             alternative preview for : dir, media, pdf, tar, ...
ftl           view     V              preview_once           preview once
ftl           view     v              preview_pane           preview show/hide
ftl           view     ⇑x/»           hexedit                hexedit

## Moving the cursor
ftl           move     5              move_page_up           page down
ftl           move     6              move_page-down         page up
ftl           move     ä              goto_entry             goto entry by index
ftl           move     A              move_up_arrow          up to previous entry
ftl           move     B              move_down_arrow        down to next entry
ftl           move     C              move_right_arrow       right; cd into directory
ftl           move     D              move_left_arrow        cd to parent directory
ftl           move     ENTER_KEY      enter                  enter; cd or open file
ftl           move     g              top_file_bottom        go to top/file/bottom
ftl           move     h              move_left              cd to parent directory
ftl           move     j              move_down              down to next entry
ftl           move     J              preview_down           scroll preview down
ftl           move     k              move_up                up to previous entry
ftl           move     K              preview_up             scroll preview up
ftl           move     l              move_right             right; cd into entry
ftl           move     ö              goto_alt1              next entry of same extension
ftl           move     Ö              goto_alt2              next entry of different extension

## Selecting files

### Filters: selecting files matching patterns
ftl           filter   ⇑a/ª           filter_reverse         set reverse filter
ftl           filter   ⇑d/ð           clear_filters          clear filters
ftl           filter   ⇑f/đ           filter_ext             select filter
ftl           filter   F              set_filter2            set filter 2
ftl           filter   f              set_filter             set filter 1
ftl           filter   ⇈k/&           preview_hide_clr       enable all extensions
ftl           filter   #              preview_ext_ign        show/hide extension preview
ftl           filter   %              preview_hide_ext       hide extension
ftl           filter   ⇑./·           show_etag              show/hide etags
ftl           filter   .              show_hidden            show/hide dot-files

## Incremental search
override      find     /              incremental_search     start incremental search, press 'enter' to end

## Tags
ftl           tabs     ⇈s/§           tab_new                new tab
ftl           tabs     TAB_KEY        tab_next               next tab
ftl           tags     ⇈0/°           tag_external           fzf merge from panes
ftl           tags     1              tag_1                  class 1 tag
ftl           tags     2              tag_2                  class 2 tag
ftl           tags     3              tag_3                  class 3 tag
ftl           tags     4              tag_4                  class 4 tag
ftl           tags     ⇑g/ŋ           tag_goto               fzf goto
ftl           tags     ⇑o/œ           tag_merge_all          merge from panes
ftl           tags     T              tag_fzf_all            fzf tag files and subdirs
ftl           tags     t              tag_fzf                fzf tag files
ftl           tags     u              tag_untag_all          untag all
ftl           tags     U              tag_untag_fzf          untag fzf
ftl           tags     ⇈y/¥           tag_all                tag all files and subdirs
ftl           tags     ⇑y/←           tag_all_files          tag all files
ftl           tags     y              tag_flip_down          tag down
ftl           tags     Y              tag_flip_up            tag up

## History
ftl           history  ⇈d/Ð           ghistory_clear         delete current session history
ftl           history  ¨              ghistory2              fzf history all sessions
ftl           history  ⇈h/Ħ           ghistory_edit          fzf edit all sessions history
ftl           history  ⇑h/ħ           ghistory               fzf history all sessions
ftl           history  H              history_go             fzf history current session

## Marks
ftl           marks    ALT_QUOTE_KEY  mark_fzf               fzf to mark
ftl           marks    ,              gmark                  add persistent mark
ftl           marks    ;              gmark_fzf              fzf to persistent mark
ftl           marks    ⇑k/ĸ           gmarks_clear           clear persistent marks
ftl           marks    ⇈'/×           mark_go                go to mark, new tab
ftl           marks    m              mark                   mark directory/file

## File operations
ftl           file     c              copy                   copy file to, prompts inline
ftl           file     d              delete_selection       delete selection using config rm -rf
ftl           file     ⇑i/→           create_bulk            creat in files and directories in bulk, uses vim, lines ending with / will create directories
ftl           file     I              create_dir             creat new directory, prompts inline
ftl           file     i              create_file            creat new file, prompts inline
ftl           file     ⇈l/Ł           follow_link            symlink follow
ftl           file     ⇑l/ł           link                   symlink selection in current directory
ftl           file     p              tag_copy               copy selection to current directory
ftl           file     P              tag_move               move selection to current directory
ftl           file     R              rename                 rename/bulk rename selection using vidir
ftl           file     ⇈t/Þ           tag_move_to            move to selection to predefine location using fzf_mv
ftl           file     x              chmod_x                chmod a+x selection, flips selection executable bit

### Copying Files

### Moving Files

### Creating Files

### Deleting Files

### Linking Files

### Renaming Files

### Changing a file's mode, owner and group

### Viewing and Editing Files

### Searching Files
ftl           find     ⇑b/”           find_fzf_all           fzf find
ftl           find     ⇈b/’           find_fzf_dirs          fzf find directories
ftl           find     b              find_fzf               fzf find current directory file
ftl           find     /              find_entry             find
ftl           find     {              go_fzf                 fzf to file with preview
ftl           find     }              go_rg                  rg to file
ftl           find     n              find_next              find next
ftl           find     N              find_previous          find previous

### Wiping Files
leader        file     ˽s             shred                  override selection multiple times and deletes it, bypasses config rm -rf, asks for confirmation

### Compressing Files
leader_ftl    extra    ˽fc            compress               compress/decompress

leader_ftl    extra    ˽fi            optimize_image         reduce jpg image size, converts png to jpg
leader_ftl    extra    ˽fm            mutt                   send selection in mail
leader_ftl    extra    ˽fp            optimize_pdf           reduce pdf size
leader_ftl    extra    ˽fP            pdf2txt                convert current pdf to text file
leader_ftl    extra    ˽fs            stat_file              display stat information for file in preview pane
leader_ftl    extra    ˽ft            shell_pop              terminal popup
leader_ftl    extra    ˽fv            optimize_video         reduce video size

### Encrypting Files
leader_ftl    extra    ˽fx            gpg_encrypt            GPG encrypt/decrypt
leader_ftl    extra    ˽fz            password_encrypt       password encrypt/decrypt

### Spell Checking Files

### Printing Files

## Directory operations

### Creating directories

### Copying directories

### Deleting directories

### Moving directories

### Renaming directories

### Summarize directory usage

### Changing directories


## Media
ftl           media    a              player_kill            kill sound preview
ftl           media    ⇈e/¢           external_mode4         external viewer, m4
ftl           media    ⇑e/€           external_mode3         external viewer, m3
ftl           media    e              external_mode1         external viewer, m1
ftl           media    E              external_mode2         external viewer m2, detached
ftl           media    W              preview_show_fzf       fzf viewer
ftl           media    w              preview_show           terminal media player in background

## Command line

## Starting a shell pane
ftl           shell    ⇈0/°           shell_synch            cd to shell pane
ftl           shell    :              command_promt          run commands: q, etags, load_tags, ...
ftl           shell    ⍰              shell_zoomed           shell pane, zoomed out
ftl           shell    !              shel_view              view shell
ftl           shell    S              shell_files            shell pane with selected files
ftl           shell    s              shell                  shell pane
ftl           shell    X              shell_file             send selection to shell pane

### insert files in the shell pane

### Comparing Files


### synch shell pane directory to ftl, and ftl directory to shell pane

### from shell pane to ftl and from ftl to shell pane

### multiple shell panes

# FILES AND DIRECTORIES

## RCfiles

### File Types

# ENVIRONMENT

$FTL_CFG

# INSTALL

see **INSTALL** file

# USER DEFINED BINDINGS, COMMANDS, ...

# BUGS

# AUTHOR

© Nadim Khemir 2020-2022

mailto:nadim.khemir@gmail.com

CPAN/Github ID: NKH

# LICENSE

Artistic licence 2.0

# SEE ALSO

ranger, fff, clifm, lfm, nnn, vifm, broot, gitfm, ...
