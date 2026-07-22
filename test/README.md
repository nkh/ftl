# ftl test suite

A comprehensive test framework for unit-testing and integration-testing ftl's Bash modules.

## Running tests

```bash
# Run all tests (unit + integration)
./test/harness.sh

# Run only unit tests
./test/harness.sh test/unit/

# Run only integration tests
./test/harness.sh test/integration/

# Run a specific test file
./test/harness.sh test/unit/test_keyboard.sh

# Verbose mode (show each assertion)
./test/harness.sh -v
```

## Test counts

| Category | Files | Test functions | Assertions |
|----------|-------|---------------|------------|
| Unit tests (core) | 16 | ~140 | ~272 |
| Unit tests (extra) | 6 | ~130 | ~189 |
| Integration tests | 2 | ~148 | ~148 |
| Tmux tests (if available) | 1 | 15 | 15 |
| **Total** | **25** | **~433** | **~624** |

## Unit test files

### Core unit tests (one per module)

| File | Module tested |
|------|---------------|
| `test_util.sh` | `util.sh` — path parsing, size formatting, dedup |
| `test_log.sh` | `log.sh` — init, set_level, debug/info/trace |
| `test_debug.sh` | `debug.sh` — stacktrace, format_size |
| `test_state.sh` | `state.sh` — save, load, serialize_info |
| `test_keyboard.sh` | `keyboard.sh` — bind, normalize_key, trie |
| `test_selection.sh` | `selection.sh` — flip/set/unset/clear |
| `test_tab.sh` | `tab.sh` — create, advance, retreat |
| `test_pane.sh` | `pane.sh` — pid_to_id, geometry |
| `test_filter.sh` | `filter.sh` — pipeline add/remove/clear |
| `test_list.sh` | `list.sh` — move_cursor, quote_* |
| `test_preview.sh` | `preview.sh` — clear, dispatch |
| `test_etag.sh` | `etag.sh` — default no-op |
| `test_virtual.sh` | `virtual.sh` — enable, reset, inject |
| `test_mark.sh` | `mark.sh` — save_to_history |
| `test_time.sh` | `time.sh` — tick, handlers |
| `test_commands.sh` | `commands.sh` — dispatch_command |

### Extra unit tests (more depth per module)

| File | Focus |
|------|-------|
| `test_util_extra.sh` | Edge cases for path parsing, sizes, binary detection |
| `test_keyboard_extra.sh` | All key types (arrows, F-keys, control, alt), AltGr tables |
| `test_selection_extra.sh` | Tag cycles, classes, validation, size tracking |
| `test_state_extra.sh` | Serialization roundtrips, child env, cleanup |
| `test_filter_extra.sh` | Pipeline manipulation, sort glyphs, user colors |
| `test_log_extra.sh` | Log levels, file output, trace suppression |
| `test_virtual_extra.sh` | Full virtual entry lifecycle, callbacks |
| `test_tab_extra.sh` | Tab creation, switching, init_defaults |

## Integration test files

| File | Categories | Tests |
|------|-----------|-------|
| `test_integration.sh` | 13 categories | 48 |
| `test_integration_extra.sh` | 8 categories | 100 |
| `test_tmux_integration.sh` | tmux operations | 15 (skipped if no tmux) |

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

## Notes

- Tests run outside tmux; tmux commands are mocked (except tmux integration tests).
- Each test file runs in a subshell for isolation.
- `ftl::test::setup()` is called before each test function.
- Tmux integration tests are auto-skipped when tmux is not installed.
