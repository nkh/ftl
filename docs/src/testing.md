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
