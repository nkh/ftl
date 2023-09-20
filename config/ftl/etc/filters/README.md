
# EXTERNAL FILTERS

Filters can be found in *$HOME/.config/ftl/filters*

| name                     | functionality                                           |
| ------------------------ | ------------------------------------------------------- |
| by_all_files             | select files to show, accumulative                      |
| by_all_files_reset       | reset accumulation                                      |
| by_file                  | select files in current directories to show, cumulative |
| by_file_reset_dir        | reset accumulation and chose new entries                |
| by_bash_hide             | accept a complex bash command to select entries to hide |
| by_bash_keep             | accept a complex bash command to select entries to show |
| by_extension             | pick which extentions you want to be displayed          |
| by_no_extension          | pick extension you don't want to see                    |
| by_file_global           | pick entry names that will be shown in all directories  |
| by_file_global_reset_dir | reset for by_global_dir                                 |
| by_only_tagged           | only show selected files                                |
| by_regexp                | pick files, you can use a regexp to help chose them     |
| by_size                  | show files over specific size                           |
| by_tag                   | show files with tmsu tags, see *Tags* in documentation  |
| by_tag_query             | show files with tmsu tagw, query can be complex         |
| by_visible_entries       | filter away files that are not present in a filter file |
| no_filter                | stop external filter                                    |
| no_sort                  | stop external sorting filter                            |
| sort_by_extension        | sort on entries extension                               |
