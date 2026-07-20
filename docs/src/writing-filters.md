# Writing Filters

An **external filter** is a plugin that takes over the listing pipeline.
When the user selects it via `fe`, ftl sources the plugin script, which
overrides `ftl::filter::apply_external` to read raw entry lines from
stdin and emit only the lines that should be shown.

## The contract

A filter plugin must:

1. Define a filter function under the `ftl::plugin::<name>::*` namespace.
2. Override the placeholder so the pipeline dispatches to it:

   ```bash
   ftl::filter::apply_external() { ftl::plugin::my_filter::filter ; }
   ```

3. Handle three lifecycle arguments: **load**, **reset**, and the default
   (interactive setup). The plugin is invoked as:

   ```bash
   source "$FTL_CFG/filters/<name>"            # interactive setup
   source "$FTL_CFG/filters/<name>" load       # re-hydrate in a child pane
   source "$FTL_CFG/filters/<name>" reset      # clean up
   ```

## The entry data format

The pipeline streams lines of `size<TAB>date<TAB>name` to your filter.
To extract the filename from a line:

```bash
fn="${file_data#$'*\t'*$'\t'}"     # strip size<TAB>date<TAB>
```

This is the canonical pattern used by every built-in filter.

## Lifecycle

- **Interactive setup** — runs in the primary pane. Typically opens an
  fzf picker, lets the user choose what to keep, then writes the choice
  to `$ftl_state_parent_dir/<name>` via `declare -p`. Sets
  `ftl_filt_active_glyph` (e.g. `"~"`) so the header shows a filter is
  active.
- **load** — runs in a child pane. Re-sources the saved state from
  `$ftl_state_parent_dir/<name>`. This is how a child pane inherits the
  parent's filter without re-prompting.
- **reset** — unsets the plugin's state arrays.

A canonical skeleton (modeled on `by_regexp`):

```bash
declare -g -A keep PWDS

[[ "$1" == reset ]] && { unset -v keep PWDS ; } ||
{
    [[ "$1" == load ]] && [[ -e "$ftl_state_parent_dir/by_regexp" ]] \
        && source "$ftl_state_parent_dir/by_regexp" ||
    {
        # interactive setup — pick files to keep
        for file in $(frf 1 "-tmux -p 80%" ctrl-t) ; do
            keep["$ftl_state_current_tab_index-$PWD/$file"]=1
            PWDS[$ftl_state_current_tab_index-$PWD]=1
            ftl_filt_active_glyph="~"
        done
        declare -p keep PWDS >"$ftl_state_parent_dir/by_regexp"
    }
}

ftl::plugin::by_regexp::filter() {
    local file_data fn
    [[ "${PWDS["$ftl_state_current_tab_index-$PWD"]}" == 1 ]] && {
        while read -r file_data ; do
            fn="${file_data#$'*\t'*$'\t'}"
            [[ "${keep["$ftl_state_current_tab_index-$PWD/$fn"]}" == 1 ]] \
                && echo "$file_data"
        done
    } || cat
}

ftl::filter::apply_external() { ftl::plugin::by_regexp::filter ; }
```

## Caching

Filter state is keyed by `"$ftl_state_current_tab_index-$PWD"` so the
same filter can carry different keep-lists per tab and per directory.
The state is serialized with `declare -p` to a file in
`$ftl_state_parent_dir/` (the parent pane's session dir), which child
panes re-source on `load`. This is your cache.

## Built-in filters

See `$FTL_CFG/filters/` and `$FTL_CFG/etc/filters/README.md` for the
full list: `by_all_files`, `by_file`, `by_bash_hide`, `by_bash_keep`,
`by_extension`, `by_no_extension`, `by_file_global`, `by_only_tagged`,
`by_regexp`, `by_size`, `by_tag`, `by_tag_query`, `by_visible_entries`,
`no_filter`, `no_sort`, `sort_by_extension`.
