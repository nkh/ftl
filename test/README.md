# ftl test suite

A comprehensive test framework for unit-testing and integration-testing ftl's Bash modules.

## Running tests

```bash
# Run all tests (unit + integration)
./test/harness.sh

# Run only unit tests
./test/harness.sh test/unit/

# Run only integration tests
./test/harness.sh test/integration/test_integration.sh

# Run a specific test file
./test/harness.sh test/unit/test_keyboard.sh

# Verbose mode (show each assertion)
./test/harness.sh -v
```

## Test counts

| Category | Files | Test functions | Assertions |
|----------|-------|---------------|------------|
| Unit tests | 16 | ~140 | ~272 |
| Integration tests | 1 | 48 | 48 |
| **Total** | **17** | **~188** | **~320** |

## Unit test files

| File | Module tested | Tests |
|------|---------------|-------|
| `test_util.sh` | `util.sh` — path parsing, size formatting, dedup, fifos | 12 |
| `test_log.sh` | `log.sh` — init, set_level, debug/info/trace, wrap | 13 |
| `test_debug.sh` | `debug.sh` — stacktrace, log_caller, format_size | 10 |
| `test_state.sh` | `state.sh` — save, load, serialize_info, child_env | 14 |
| `test_keyboard.sh` | `keyboard.sh` — bind, normalize_key, trie, AltGr | 13 |
| `test_selection.sh` | `selection.sh` — flip/set/unset/clear/validate | 13 |
| `test_tab.sh` | `tab.sh` — create, advance, retreat, wrap | 9 |
| `test_pane.sh` | `pane.sh` — pid_to_id, geometry, border colors | 14 |
| `test_filter.sh` | `filter.sh` — pipeline add/remove/clear, user colors | 11 |
| `test_list.sh` | `list.sh` — move_cursor, quote_*, mime_type | 15 |
| `test_preview.sh` | `preview.sh` — clear, show_in_vim, dispatch | 12 |
| `test_etag.sh` | `etag.sh` — default no-op scan/tag | 8 |
| `test_virtual.sh` | `virtual.sh` — enable/reset/inject/callbacks | 11 |
| `test_mark.sh` | `mark.sh` — save_to_history | 9 |
| `test_time.sh` | `time.sh` — tick, handlers, timer reset | 8 |
| `test_commands.sh` | `commands.sh` — dispatch_command, quote_selection | 10 |

## Integration test file

| File | Categories | Tests |
|------|-----------|-------|
| `test_integration.sh` | 13 categories | 48 |

Integration test categories:
1. Module loading (6 tests)
2. Path parsing + selection workflow (6 tests)
3. Tab + cursor memory (6 tests)
4. Filter pipeline + listing (6 tests)
5. Keyboard binding + dispatch (6 tests)
6. State serialization roundtrip (6 tests)
7. Virtual entries lifecycle (6 tests)
8. Etag system (5 tests)
9. Time events (4 tests)
10. Logging system (5 tests)
11. Command dispatch (5 tests)
12. Preview state management (4 tests)
13. Pane geometry (3 tests)

## Writing tests

Create a file in `test/unit/` or `test/integration/` named `test_*.sh`. Define functions named `test_*`. Use the assertion helpers:

```bash
ftl::test::assert_eq <expected> <actual> [msg]
ftl::test::assert_ne <expected> <actual> [msg]
ftl::test::assert_contains <haystack> <needle> [msg]
ftl::test::assert_match <regex> <string> [msg]
ftl::test::fail [msg]
ftl::test::pass [msg]
ftl::test::skip [msg]
```

### Example

```bash
#!/bin/env bash
source "$FTL_CFG/etc/core/modules/util.sh"

test_parse_path() {
    ftl::util::parse_path "/home/user/file.txt"
    ftl::test::assert_eq "file.txt" "$ftl_state_current_basename"
    ftl::test::assert_eq "txt" "$ftl_state_current_extension"
}
```

## Notes

- Tests run outside tmux; tmux commands are mocked.
- Each test file runs in a subshell for isolation.
- `ftl::test::setup()` is called before each test function.
- `ftl::test::teardown()` is called after each test function.
- The harness supports `--source-only` flag for sourcing without running.
