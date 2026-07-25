# 05 — Testing

> **Audience:** Maintainers writing or modifying tests.
> **Goal:** Understand the test harness, test categories, the stubbing
> pattern, and how to run and debug tests.
> **Time:** 45 minutes.

---

## 1. Overview

ftl's test suite comprises 925 tests across 32 files:

| Category | Files | Tests | Purpose |
|----------|-------|-------|---------|
| Unit | 26 | 797 | Test individual modules in isolation |
| Behavioral | 1 | 128 | Test the 42 missing-functionalities features against real temp dirs |
| Integration | 4 | 17+ | Test end-to-end with real tmux |
| **Total** | **31** | **925** | |

All tests are Bash scripts run by `test/harness.sh`. The harness
auto-discovers `test_*.sh` files in `test/unit/` and `test/integration/`.

## 2. The Harness: `test/harness.sh`

The harness provides:

- **Assertion functions:** `ftl::test::assert_eq`, `assert_ne`,
  `assert_contains`, `assert_match`, `fail`, `pass`, `skip`.
- **Setup/teardown:** `ftl::test::setup` runs before each test;
  `ftl::test::teardown` runs after.
- **Subshell isolation:** Each test file runs in a subshell so
  function definitions and variable leaks don't cross files.
  Within a file, each test function runs in the same shell (setup
  re-initializes state between tests).
- **Counters:** Pass/fail/skip counts are accumulated and printed at
  the end.

### Running tests

```bash
# Run all tests
bash test/harness.sh

# Run one test file
bash test/harness.sh test/unit/test_keyboard.sh

# Verbose mode (prints PASS/SKIP lines, not just FAIL)
bash test/harness.sh -v

# Run with a specific FTL_CFG
FTL_CFG=/path/to/config bash test/harness.sh
```

### Harness internals

The harness sources each test file in a subshell:

```bash
(
    FTL_TEST_PASSES=0
    FTL_TEST_FAILS=0
    FTL_TEST_SKIPS=0

    trap 'printf "%s %s %s\n" "$FTL_TEST_PASSES" "$FTL_TEST_FAILS" "$FTL_TEST_SKIPS" >"$_ftl_counts_file"' EXIT

    source "$test_file"

    test_funcs=$(declare -F | awk '/^declare -f test_/ {print $3}')
    for tf in $test_funcs ; do
        ftl::test::setup
        "$tf" 2>&1
        ftl::test::teardown
    done
)

read -r p f s <"$_ftl_counts_file"
(( FTL_TEST_PASSES += p ))
(( FTL_TEST_FAILS += f ))
(( FTL_TEST_SKIPS += s ))
```

Key points:

- The `trap ... EXIT` ensures counts are written even if a test kills
  the subshell (e.g. via `set -u` on an unbound variable).
- `ftl::test::setup` and `ftl::test::teardown` are called around each
  test function. Tests define their own `setup`/`teardown` to
  override the defaults.
- `set -u` is active throughout. Tests must handle unset variables.

## 3. Test File Structure

A typical test file:

```bash
#!/bin/env bash
# test/unit/test_my_module.sh — tests for my_module

FTL_CFG="${FTL_CFG:-/home/z/my-project/ftl-work/config/ftl}"
export FTL_CFG

# Source the modules under test (in dependency order)
source "$FTL_CFG/etc/core/modules/util.sh"
source "$FTL_CFG/etc/core/modules/log.sh"
source "$FTL_CFG/etc/core/modules/state.sh"
source "$FTL_CFG/etc/core/modules/keyboard.sh"
# ... other modules as needed
source "$FTL_CFG/etc/core/modules/my_module.sh"

# Stub heavy I/O functions (redefined after sourcing, so they win)
ftl::list::render() { : ; }
ftl::pane::split_for_preview() { : ; }
tmux() { : ; }
stty() { : ; }
tput() { : ; }

# Stub ftl::cmd::prompt to return a fake value
FTL_TEST_FAKE_REPLY=
ftl::cmd::prompt() { REPLY="$FTL_TEST_FAKE_REPLY" ; }

# Setup: called before each test
ftl::test::setup() {
    ftl_state_session_dir=$(mktemp -d)
    mkdir -p "$ftl_state_session_dir/prev"
    # ... initialize state
}

ftl::test::teardown() {
    rm -rf "$ftl_state_session_dir" 2>/dev/null
}

# Helper: set up a fake listing
setup_listing() {
    local f
    for f in "$@" ; do
        touch "$ftl_state_session_dir/$f"
        ftl_list_entries+=( "$ftl_state_session_dir/$f" )
    done
    ftl_list_entry_count=${#ftl_list_entries[@]}
    ftl_state_cursor_index=0
    ftl_state_current_path="${ftl_list_entries[0]}"
    ftl_state_current_basename="${ftl_state_current_path##*/}"
}

# Tests
test_my_function_does_x() {
    setup_listing "a.txt"
    ftl::my_module::my_function
    ftl::test::assert_eq "expected" "$actual" "my_function does X"
}

test_my_function_handles_edge_case() {
    # ...
}

# vim: set filetype=bash :
```

### Key conventions

1. **`FTL_CFG` default.** Each test file sets
   `FTL_CFG="${FTL_CFG:-/path/to/config/ftl}"`. The harness sets
   `FTL_CFG` to the project's config dir if not already set, so the
   `:-` default is a fallback for running tests in isolation.

2. **Source modules in dependency order.** The test file must source
   the modules it tests, plus their dependencies. The order matches
   `ftl_setup`.

3. **Stub after sourcing.** Stub functions are defined *after* the
   modules are sourced, so the stubs override the real functions.

4. **`ftl::test::setup` per file.** Each test file defines its own
   `setup` function. The harness calls it before every test function
   in the file.

5. **Test functions start with `test_`.** The harness discovers them
   via `declare -F | awk '/^declare -f test_/ {print $3}'`.

6. **Tab indentation.** Test files use tabs, matching the project
   convention.

## 4. The Stubbing Pattern

ftl's modules interact heavily with the terminal (tmux, stty, tput)
and with each other. Tests stub these to make them deterministic.

### Common stubs

```bash
# No-op stubs (the function does nothing)
ftl::list::render() { : ; }
ftl::prev::dispatch() { : ; }
ftl::prev::clear() { : ; }
ftl::pane::stop_file_watcher() { : ; }
ftl::pane::start_file_watcher() { : ; }
ftl::pane::query_geometry() { : ; }
ftl::pane::snapshot_geometry() { : ; }
tmux() { : ; }
stty() { : ; }
tput() { : ; }

# Stateful stubs (mutate state to simulate the real function)
ftl::list::change_dir() {
    if (( ftl_list_entry_count )) ; then
        local idx=${ftl_state_cursor_index:-0}
        (( idx >= ftl_list_entry_count )) && idx=$(( ftl_list_entry_count - 1 ))
        (( idx < 0 )) && idx=0
        ftl_state_current_path="${ftl_list_entries[$idx]}"
        ftl_state_current_basename="${ftl_state_current_path##*/}"
    fi
}

# Capturing stubs (record what the function was called with)
local captured=
ftl::pane::split() { captured="$*" ; }

# Counter stubs (track how many times the function was called)
local call_count=0
ftl::pane::split() { ((call_count++)) ; }
```

### The `ftl::cmd::prompt` stub

`ftl::cmd::prompt` reads user input via `read -e -rp`. In tests, stub
it to set `$REPLY` (and `$ftl_kbd_current_key`, which some code paths
use instead — this is a known inconsistency):

```bash
FTL_TEST_FAKE_REPLY=
ftl::cmd::prompt() {
    REPLY="$FTL_TEST_FAKE_REPLY"
    ftl_kbd_current_key="$FTL_TEST_FAKE_REPLY"
}
```

For tests that need multiple prompts (e.g. `rg_replace` prompts 3
times), use a queue:

```bash
_FTL_TEST_REPLIES=( "hello" "HI" "s" )
_FTL_TEST_REPLY_IDX=0
ftl::cmd::prompt() {
    ftl_kbd_current_key="${_FTL_TEST_REPLIES[$_FTL_TEST_REPLY_IDX]:-}"
    ((_FTL_TEST_REPLY_IDX++)) || true
}
```

Always restore the original stub at the end of the test:

```bash
local _saved_prompt="$(declare -f ftl::cmd::prompt)"
ftl::cmd::prompt() { ... }
# ... test code ...
eval "$_saved_prompt"  # restore
```

## 5. Test Categories

### 5.1 Unit tests (`test/unit/`)

Test individual modules in isolation. The module is sourced; its
dependencies are sourced or stubbed. Tests call the module's functions
directly and assert on the resulting state.

Examples:

- `test_keyboard.sh` — tests `ftl::kbd::bind`, `unbind`,
  `normalize_key`, the trie, dispatch.
- `test_selection.sh` — tests `ftl::sel::flip`, `set`, `unset`,
  `validate_existence`, etc.
- `test_list.sh` — tests `ftl::list::move_cursor`, window computation.
- `test_state.sh` — tests `ftl::state::save`, `load`, `serialize_info`.

### 5.2 Behavioral tests (`test/unit/test_missing_functionalities_behavior.sh`)

Test the 42 missing-functionalities features against real temp
directories. Each test:

1. Creates a temp directory with known files.
2. Sets up ftl state (listing, selection, current path).
3. Calls the feature function.
4. Asserts on the resulting filesystem or state.

These tests use real Unix commands (`cp`, `ln`, `mv`, `touch`,
`sha256sum`, `zip`, `7z`, `git`, etc.) but stub ftl's I/O functions
(`ftl::list::render`, `ftl::pane::split_for_preview`, `tmux`).

Features with optional dependencies skip gracefully:

```bash
test_compress_7z_creates_archive() {
    command -v 7z >/dev/null 2>&1 || { ftl::test::skip "7z not installed" ; return ; }
    # ... test ...
}
```

### 5.3 Integration tests (`test/integration/`)

Test end-to-end with real tmux. The test file checks for tmux and
skips the entire file if not available:

```bash
command -v tmux >/dev/null 2>&1 || {
    echo "  (skipped: tmux not installed)"
    exit 0
}
```

Integration tests spawn real tmux sessions, send keys, and capture
pane output:

```bash
test_tmux_creates_session() {
    tmux new-session -d -s test_session
    # ... assertions ...
    tmux kill-session -t test_session
}
```

## 6. Writing a New Test

To add a test for a new feature:

1. **Pick the right file.** If testing a core module, add to the
   existing `test_<module>.sh` or create `test_<module>_extra.sh`. If
   testing a plugin, create a new file.

2. **Source the module.** Add the source line in dependency order.

3. **Add stubs.** Stub any I/O functions the module calls.

4. **Write the test function.** Start with `test_`. Use the assert
   functions.

5. **Run the test.** `bash test/harness.sh test/unit/test_my_module.sh -v`

6. **Verify.** The test should pass. If it fails, debug by adding
   `set -x` at the top of the test function.

### Example: testing a new binding

```bash
test_my_binding_works() {
    setup_listing "a.txt" "b.txt"
    ftl::plugin::my_plugin::enter
    ftl::test::assert_eq "1" "$ftl_my_plugin_active" "plugin entered"
    ftl_kbd_current_key="ESCAPE"
    ftl::plugin::my_plugin::dispatch
    ftl::test::assert_eq "0" "$ftl_my_plugin_active" "plugin exited on ESCAPE"
}
```

## 7. Debugging Tests

### Common failures

1. **`unbound variable` under `set -u`.** The test accessed an unset
   variable. Add `:-` defaults: `${var:-}`.

2. **`cannot convert indexed to associative array`.** The test
   declared the array as indexed, then the module declares it as
   associative. Ensure the test's `setup` uses `declare -Ag` for assoc
   arrays.

3. **`command not found`.** The test forgot to source a module. Add
   the source line.

4. **`No such file or directory` on source.** `FTL_CFG` is wrong.
   Check the path.

5. **Test passes in isolation, fails in the full suite.** State leaks
   between tests. Ensure `setup` resets all relevant variables. Use
   `unset -f` to clear stub functions defined inside test functions.

### Debugging techniques

1. **Run with `-v`.** `bash test/harness.sh -v test/unit/test_x.sh`
   prints PASS/SKIP lines for every test, not just FAILs.

2. **Add `set -x` to a test function.** This traces every command in
   the test.

3. **Run the test file directly.** `bash test/unit/test_x.sh` (without
   the harness) runs the file's code but doesn't accumulate counts.
   Useful for seeing raw error output.

4. **Check the subshell counts.** If a test kills the subshell, the
   counts may be 0/0/0. The trap on EXIT should still write them; if
   not, the test is killing the subshell before the trap fires.

5. **Use `ftl::test::pass`/`ftl::test::fail` explicitly.** For complex
   assertions, break them into multiple `pass`/`fail` calls with
   descriptive messages.

## 8. Test Coverage

To check test coverage (which functions are tested):

```bash
# List all test functions
grep -h '^test_' test/unit/*.sh test/integration/*.sh | wc -l

# List all public API functions
grep -h '^ftl::' config/ftl/etc/core/modules/*.sh | wc -l
```

The behavioral tests in `test_missing_functionalities_behavior.sh`
cover all 42 missing-functionalities features. The unit tests cover
the core modules' public APIs. The integration tests cover tmux
interaction.

Gaps to be aware of:

- `commands.sh` has ~390 functions; not all are tested. The most
  commonly used ones (movement, selection, file operations) are
  covered.
- The viewer functions in `viewers/core` are not unit-tested (they
  spawn external programs). Integration tests cover the dispatch
  logic.
- The filter plugins in `filters/` are not tested. The filter
  pipeline (`ftl::filt::*`) is tested in `test_filter.sh` and
  `test_filter_extra.sh`.

## 9. CI Considerations

For CI, ensure:

1. **`FTL_CFG` is set.** The harness defaults to
   `$FTL_ROOT_DIR/config/ftl`, which is the project's config dir. CI
   should not override this.

2. **Optional tools are installed.** For full coverage (no skips),
   install: `tmux`, `fzf`, `ripgrep`, `fd`, `moreutils` (for `sponge`),
   `p7zip-full`, `imagemagick`, `git`, `zip`, `unzip`, `tar`, `wget`,
   `exiftool`.

3. **The test sandbox has a TTY.** tmux integration tests require a
   TTY. In CI, use `tmux new -d` or a virtual framebuffer.

4. **`set -u` is respected.** CI should not disable `set -u`. Tests
   that fail under `set -u` have a bug and should be fixed.
