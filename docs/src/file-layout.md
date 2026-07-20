# File Layout

ftl installs into `~/.config/ftl/` (referred to as `$FTL_CFG`). This
page is a complete walk through the directory tree.

```
$FTL_CFG/                               # ~/.config/ftl
├── etc/                                # ftl's "binary" tree
│   ├── ftlrc                           # main config (sourced at startup)
│   ├── ftlrc_not_so_vim_like           # alt config with less vim-like bindings
│   ├── ftl_setup                       # bootstrap (sourced by the launcher)
│   ├── core/
│   │   ├── ftl                         # backwards-compat module loader
│   │   ├── dir_file_filter             # dir/file filter helper
│   │   ├── commands                    # core commands dispatcher
│   │   ├── modules/                    # the 16 core modules
│   │   │   ├── util.sh
│   │   │   ├── log.sh
│   │   │   ├── debug.sh
│   │   │   ├── state.sh
│   │   │   ├── keyboard.sh
│   │   │   ├── selection.sh
│   │   │   ├── tab.sh
│   │   │   ├── pane.sh
│   │   │   ├── filter.sh
│   │   │   ├── list.sh
│   │   │   ├── preview.sh
│   │   │   ├── etag.sh
│   │   │   ├── virtual.sh
│   │   │   ├── mark.sh
│   │   │   ├── time.sh
│   │   │   └── commands.sh
│   │   └── lib/
│   │       ├── shell                   # shell pane helpers
│   │       ├── merge/                  # selection merge helpers
│   │       │   ├── pick
│   │       │   ├── synch
│   │       │   └── all
│   │       └── lock_preview/
│   │           └── stat_and_text
│   ├── bin/                            # executables on $PATH
│   │   ├── ftl                         # the launcher
│   │   ├── ftll                        # file-picker (writes to fd 3)
│   │   ├── cdf                         # cd-from-ftl helper
│   │   ├── fsh                         # shell-with-ftl-env wrapper
│   │   ├── finfo                       # emit ftl info for external cmds
│   │   ├── ftlvim                      # vim with ftl file-picker
│   │   ├── ftli                        # w3mimgdisplay image daemon
│   │   ├── ftl_synch_with_shell        # shell cwd sync
│   │   ├── ftl_shell_back              # return from shell
│   │   ├── fzfr / frf / frl / frg      # fzf/ripgrep wrappers
│   │   ├── fzf_mv / fzf_mv_add / _rm / _sd  # move via fzf
│   │   ├── ansi_show / color_size / piper / piper_md  # preview helpers
│   │   ├── parse_parts                 # command-prompt tokenizer
│   │   ├── scim_permission / scim_tmsu # sc-im integrations
│   │   ├── filter-on-file-size        # size filter helper
│   │   ├── fpdh                        # debug pane helper
│   │   └── third_party/                # vendored tools
│   │       ├── fzf_vvip
│   │       ├── vimkat
│   │       ├── piper
│   │       ├── mimemagic
│   │       ├── git-tree-status / git-fullstatus / git-color-status
│   │       ├── tdiff
│   │       ├── tw
│   │       ├── plc / pchild
│   │       └── .vimkatrc               # copied to ~ during install
│   ├── commands/  → ../commands        # symlink to plugin dir
│   ├── etags/     → ../etags
│   ├── filters/   → ../filters
│   ├── generators/ → ../generators
│   ├── viewers/   → ../viewers
│   ├── bindings/                      # binding plugins (auto-sourced)
│   │   ├── leader / leader_ftl / leader_git
│   │   ├── incremental_search / fzf_search / fzf_pane_preview
│   │   ├── change_mode / file_diff / virtual_entries
│   │   ├── type_handlers / via_bash / tmsu
│   │   ├── add_to_a_log / shred / user_command
│   │   └── lib/                       # binding helper libraries
│   │       ├── compress / optimize / extra
│   │       └── merge/pick / synch / all
│   └── viewers/  → ../viewers
├── commands/                           # user command plugins
│   ├── 01_example / 02_example         # templates (sourced)
│   ├── open_with                       # fzf-pick a program
│   ├── fma / fmr                       # file-management actions
│   ├── tree                            # tree view
│   ├── etags                           # manage etag sources
│   ├── url                             # open URLs
│   ├── show_cmd_log
│   └── ftlrc_dir/reverse_date          # dir-scoped command
├── etags/                              # etag plugins
│   ├── none / git / lines / date
│   ├── image_size / tmsu / virtual
├── filters/                            # filter plugins
│   ├── no_filter / no_sort
│   ├── by_extension / by_no_extension / sort_by_extension
│   ├── by_size / by_tag / by_tag_query
│   ├── by_file / by_file_reset_dir
│   ├── by_file_global / by_file_global_reset_dir
│   ├── by_all_files / by_all_files_reset
│   ├── by_only_tagged / by_visible_entries
│   ├── by_regexp / by_bash_hide / by_bash_keep
│   └── README.md
├── generators/                         # thumbnail generators (executable)
│   ├── generator / generator_one       # drivers
│   ├── pdf / svg / svg_to_pdf / html
│   ├── gif / apng / montage
│   ├── mp3 / mp4 / mkv / flv / webm
│   ├── epub / cbz / cbr / stl
├── viewers/                            # viewer plugins
│   ├── core                            # the dispatch chain (pviewers/ext_viewers)
│   ├── vlc / cmus
│   ├── mplayer_background / mplayer_local
├── man/                                # man page generation
│   ├── ftl.md                          # the source
│   └── gen_man_pages                   # builds ftl.1
├── var/                                # runtime state ($FTL_STATE_DIR)
│   ├── <pid>/                          # per-session dir (one per pane)
│   │   ├── prev/                       # shared sync dir (=$fsp)
│   │   ├── lock_preview/
│   │   ├── mnt/
│   │   ├── tmp/
│   │   ├── ftl                         # serialized state
│   │   ├── tags                        # serialized selection
│   │   ├── history                     # session history
│   │   └── log                         # stderr capture
│   ├── shared/                         # cross-session state
│   │   └── history                     # global history
│   └── cache/thumbs/                   # thumbnail cache
└── image_bg.png                        # terminal bg image (for image previews)
```

## Conventions

- **`etc/`** is ftl's "binary" — code that ships with ftl. Symlinks
  (`commands/`, `etags/`, etc.) point into it from the top-level so
  user-drop-in plugins share the same namespace.
- **`var/`** is runtime state. Each pane gets its own `var/<pid>/`
  directory; cross-session state lives in `var/shared/`.
- **Plugins** are auto-discovered: bindings by `fd` at startup, the
  others lazily when selected.
- **Top-level plugin directories** (`commands/`, `etags/`, `filters/`,
  `generators/`, `viewers/`) are where users drop their own plugins;
  `etc/` versions ship the defaults.
