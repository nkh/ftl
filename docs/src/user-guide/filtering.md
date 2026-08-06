# Filtering

ftl's directory listing passes through a **5-layer filter pipeline** before
being rendered. Each layer is a function in a Bash pipe; the listing
scanner feeds raw entries (as `size<TAB>date<TAB>name` lines) through the
chain.

## The five layers

From outermost to innermost:

1. **External filter** (`ftl::filter::apply_external`) — a plugin that
   takes over the whole pipeline. Selected via `fe`. Includes
   `by_bash_keep`, `by_bash_hide`, `by_regexp`, `by_size`, `by_tag`,
   `by_tag_query`, `by_visible_entries`, etc.
2. **Directory filter** (`ftl_tab_filter_dirs[tab]`) — a regex applied to
   directory entries only. Set with `fd`.
3. **File filter 1** (`ftl_tab_filter_1[tab]`) — a regex applied to file
   entries. Set with `ff`. Implemented as `rg <regex>`.
4. **File filter 2** (`ftl_tab_filter_2[tab]`) — a second file regex. Set
   with `fF`.
5. **Reverse filter** (`ftl_tab_filter_reverse[tab]`) — a regex; matching
   entries are *removed*. Set with `fr`. Defaults to
   `ftl_cfg_default_reverse_filter`.

The pipeline string itself is stored in `ftl_filt_pipeline_string`, and
the list of filter functions in `ftl_filt_pipeline_list`.

## Regex syntax

File/dir/reverse filters use **ripgrep** regex syntax — they're literally
passed to `rg`. So `ff` then `\.py$` keeps only Python files; `fd` then
`^src` keeps only directories starting with `src`; `fr` then `\.o$`
hides object files.

## Extension hide / only

Two extension lists live alongside the pipeline:

- `ftl_filt_listing_hide_exts` — extensions to hide from the listing
- `ftl_filt_listing_keep_exts` — extensions to keep (everything else hidden)

| Key | Command | Description |
|-----|---------|-------------|
| `zeh` | `ftl::cmd::extension_hide_tab` | hide this extension, per-tab |
| `zeH` | `ftl::cmd::extension_hide` | hide this extension |
| `zeo` | `ftl::cmd::extension_only_tab` | keep only this extension, per-tab |
| `zeO` | `ftl::cmd::extension_only` | keep only this extension |
| `zec` | `ftl::cmd::extension_clear` | re-enable all extensions |
| `zes` | `ftl::cmd::extension_sort` | sort by extension |

## Filter bindings

| Key | Command | Description |
|-----|---------|-------------|
| `fe` | `ftl::cmd::select_external_filter` | pick an external filter plugin |
| `fd` | `ftl::cmd::set_dir_filter` | set directory filter regex |
| `ff` | `ftl::cmd::set_filter_1` | set file filter 1 regex |
| `fF` | `ftl::cmd::set_filter_2` | set file filter 2 regex |
| `fr` | `ftl::cmd::set_reverse_filter` | set reverse filter regex |
| `fy` | `ftl::cmd::filter_to_tagged` | show only tagged files |
| `fc` | `ftl::cmd::clear_all_filters` | clear all filters |

## External filter plugins

External filters live in `$FTL_CFG/filters/`. Each is a sourced Bash
script that overrides `ftl::filter::apply_external` (a placeholder that
just `cat`s its input). The plugin also receives `load` and `reset`
arguments so it can re-hydrate state in a child pane and clean up. See
[Writing Filters](../writing-filters.md) for the full contract.

When any filter is active, the header shows a `~` glyph
(`ftl_filt_active_glyph`).

## See Also

- [Searching](./searching.md) — incremental search
- [Writing Filters](../writing-filters.md) — how to write a custom filter plugin
- [Navigation](./navigation.md) — moving through the listing
