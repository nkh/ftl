# Testing

ftl ships a minimal test harness for unit-testing its Bash modules.
Tests run **outside tmux** — tmux calls are mocked or avoided — so they
run fast and headless.

## The harness

`test/harness.sh` is the entry point. It sources each test file under
`test/unit/`, finds functions named `test_*`, and runs them.

```bash
./test/harness.sh                          # run all unit tests
./test/harness.sh test/unit/test_keyboard.sh   # run one file
./test/harness.sh -v                       # verbose: show each assertion
```

The harness sets up:

- `FTL_TEST_DIR` — the `test/` directory
- `FTL_ROOT_DIR` — the repo root
- `FTL_CFG` — defaults to `$HOME/.config/ftl`
- Color-coded pass/fail/skip counters

## Assertion functions

The harness exposes a small assertion library under the `ftl::test::`
namespace:

| Function | Purpose |
|----------|---------|
| `ftl::test::assert_eq <expected> <actual> [msg]` | equality |
| `ftl::test::assert_ne <expected> <actual> [msg]` | inequality |
| `ftl::test::assert_contains <haystack> <needle> [msg]` | substring |
| `ftl::test::assert_match <regex> <string> [msg]` | regex match |
| `ftl::test::fail [msg]` | explicit failure |
| `ftl::test::pass [msg]` | explicit pass |
| `ftl::test::skip [msg]` | skip the current test |

Each assertion increments `FTL_TEST_PASSES` or `FTL_TEST_FAILS`. The
harness prints a summary at the end and exits non-zero if any test
failed.

## Writing a test

Create a file in `test/unit/` named `test_<module>.sh`. Source the
module under test. Define functions named `test_*`:

```bash
#!/bin/env bash
# test/unit/test_util.sh
source "$FTL_CFG/etc/core/modules/util.sh"

test_parse_path_extracts_extension() {
    ftl::util::parse_path "/home/user/file.txt"
    ftl::test::assert_eq "file.txt" "$ftl_state_current_basename" \
        "basename should be file.txt"
    ftl::test::assert_eq "txt"      "$ftl_state_current_extension" \
        "extension should be txt"
}

test_parse_path_handles_no_extension() {
    ftl::util::parse_path "/home/user/Makefile"
    ftl::test::assert_eq "Makefile" "$ftl_state_current_basename"
    ftl::test::assert_eq ""         "$ftl_state_current_extension"
}
```

State is **not** automatically reset between tests. If you need a clean
slate, define a `setup` function (or use `ftl::test::setup`) and call
it at the top of each test, or reset the relevant globals manually.

## What's tested

| Test file | Module | Coverage |
|-----------|--------|----------|
| `test_util.sh` | `util.sh` | path parsing, size formatting, dedup |
| `test_keyboard.sh` | `keyboard.sh` | `bind`, `normalize_key`, trie lookup |
| `test_selection.sh` | `selection.sh` | tag `flip`/`set`/`unset`, `clear_all`, class index |
| `test_filter.sh` | `filter.sh` | pipeline `add`/`remove`/`clear`, sort glyph |
| `test_tab.sh` | `tab.sh` | `create`, `advance_index`, `retreat_index` |
| `test_mark.sh` | `mark.sh` | `save_to_history` (session + global, child-pane skip) |
| `test_list_format.sh` | `list.sh` | `_ftl::list::apply_filters_and_format` truncation (incl. b1234f0 clamp), filters |
| `test_filename_split_fix.sh` | `commands/search.sh` + `viewers/core` | b1234f0: `find_dirs_via_fzf` final render, `pcbr` debug-log removal |
| `test_project_marks.sh` | `bindings/project_marks` | `get_project_marks`, `pmark`, `pmarks_fzf`/`_subdir_fzf`, `pmarks_edit`, registered bindings |
| `test_dest_tags.sh` | `commands/dest_tags.sh` | 38a073a: 7 dest_tag commands, format_annotation, ftlrc/ftl_setup declarations |
| `test_dest_tags_render.sh` | `commands/dest_tags.sh` + `list.sh` | 38a073a: render emits ` [...dest]` annotation, trim long paths |
| `test_util_deep.sh` | `util.sh` | parse_path root/relative bugs, format_size_human PiB fallthrough, resolve_full_path, dedup_file, is_binary_file |
| `test_keyboard_deep.sh` | `keyboard.sh` | normalize_key (DOWN app-mode bug, F-keys, CTL chars), bind/unbind, redo exclusions |
| `test_tab_deep.sh` | `tab.sh` | retreat_index rev bug (11+ tabs), advance_index gaps, create "." trailing slash, load_from_file empty lines |
| `test_selection_deep.sh` | `selection.sh` | adjust_total_size crash on missing file, load_from_file flip-vs-set, build_class_index side effect |
| `test_dest_tags_deep.sh` | `commands/dest_tags.sh` | dtag_move=0 same-entry bug, copy/move clears tags on failure, format_annotation edge cases |
| `test_state_deep.sh` | `state.sh` | save round-trip var-name mismatch, sed `-A` corruption, cleanup guard, emit_selection_fd3 |
| `test_inline_rename_deep.sh` | `inline_rename.sh` | dotfile extension bug, commit mv-failure, abort doesn't clear active flag (bug) |
| `test_filter_deep.sh` | `filter.sh` | pipeline_remove empty array, get_sort_glyph quoting, init defaults, load_external |
| `test_pane_deep.sh` | `pane.sh` | count_bg_windows set -e, send_to_all_children empty, read_child_list missing file, select empty |
| `test_preview_deep.sh` | `preview.sh` | show_in_vim incomplete escaping, show_image unquoted vars, clear no-arg, thumb_path md5 newline |
| `test_dispatcher_deep.sh` | `commands/dispatcher.sh` | dispatch_command numeric sets path not index (bug), empty string crash, out-of-range crash |
| `test_commands_mark_deep.sh` | `commands/mark.sh` | set_mark/goto_mark use ftl_kbd_current_key not REPLY (bug), clear_persistent_marks same bug |
| `test_file_ops_deep.sh` | `commands/file_ops.sh` | create_file/copy_to_prompted/delete_selection use trigger key not REPLY (bug), do_copy/do_move |

## What's not tested

- Anything that requires a live tmux session (pane splitting, preview
  respawns, IPC signals). The harness runs outside tmux, so these are
  out of scope for unit tests. Future integration tests would live in
  `test/integration/`.
- End-to-end rendering (the listing scan/render pipeline depends on
  `tmux display`, terminal escape sequences, and a real filesystem
  layout).
- Plugin loading paths that depend on `$FTL_STATE_DIR` being writable
  in a particular shape.

## Tips

- Run `./test/harness.sh -v` while developing to see each assertion.
- Tests are sourced, so they share state with the harness — be careful
  not to define a `setup` function in one file that clobbers another's.
- The harness uses `set -u`; reference undefined variables and the test
  dies. This catches typos but means you sometimes need `${var:-}`
  defaults in test setup.
- Add new tests by dropping a `test_*.sh` file in `test/unit/` — the
  harness picks it up automatically.
