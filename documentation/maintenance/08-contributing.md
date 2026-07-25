# 08 — Contributing

> **Audience:** Maintainers preparing changes for commit and review.
> **Goal:** Understand the contribution workflow, code style, and
> commit conventions.
> **Time:** 20 minutes.

---

## 1. Branch Strategy

ftl uses a simple branch strategy:

- `main` — the stable branch. Do not push directly; open a PR.
- `reformat` — the refactored branch (module split, namespacing). This
  is the current development branch.
- `missing_functionalities` — the branch for the 42 missing-feature
  implementations and subsequent work. This is the active development
  branch as of July 2026.

For new work, branch from `missing_functionalities` (or `reformat` if
`missing_functionalities` has been merged):

```bash
git checkout missing_functionalities
git pull
git checkout -b my-feature
```

### Branch naming

- `feature/<short-description>` — new features
- `fix/<short-description>` — bug fixes
- `docs/<short-description>` — documentation-only changes
- `refactor/<short-description>` — code refactoring
- `test/<short-description>` — test-only changes

## 2. Code Style

### 2.1 Indentation: Tabs

The project uses **tabs** (not spaces) for indentation in Bash files.
Configure your editor to insert tab characters. The `ftl::kbd::bind`
call uses tabs to separate fields; the bindings table display relies
on tab-delimited fields.

**Exception:** The man page (`config/ftl/man/ftl.md`) and the mdBook
documentation use spaces (Markdown convention).

### 2.2 No One-Liners

The `reformat` branch eliminated all one-liners. Every function body
is multi-line with one statement per line. For example:

```bash
# Bad (one-liner)
ftl::my::func() { local x ; x=$(echo hi) ; echo "$x" ; }

# Good (multi-line)
ftl::my::func() {
	local x
	x=$(echo hi)
	echo "$x"
}
```

This is enforced by code review. Maintain the style.

### 2.3 Namespacing

All functions and variables are namespaced:

- **Functions:** `ftl::<module>::<function>` (e.g.
  `ftl::kbd::bind`)
- **Module variables:** `ftl_<module>_<name>` (e.g.
  `ftl_kbd_trie`)
- **Config variables:** `ftl_cfg_*`
- **State variables:** `ftl_state_*`
- **Plugin functions:** `ftl::plugin::<name>::<function>`
- **Plugin variables:** `ftl_plugin_<name>_*`
- **Private helpers:** leading underscore (`_ftl::list::scan_directory`)

### 2.4 `set -u` Discipline

ftl runs under `set -u`. Always provide defaults for potentially-unset
variables:

```bash
# Bad: crashes if ftl_selection_tags is unset
for p in "${!ftl_selection_tags[@]}" ; do ...

# Good: defaults to empty
for p in "${!ftl_selection_tags[@]:-}" ; do ...
```

When in doubt, use `${var:-}` (default to empty) or `${var:+...}`
(expand to `...` if set).

### 2.5 Quoting

Quote all variable expansions unless you specifically want word
splitting:

```bash
# Bad
cp $file $dest

# Good
cp "$file" "$dest"
```

Use `${var@Q}` (Bash 4.4+) for safe shell quoting when interpolating
paths into commands:

```bash
ftl::pane::split "cat '${ftl_state_current_path@Q}'"
```

### 2.6 Comments

Every module begins with a header comment block listing:

```bash
# module.sh — <one-line purpose>
#
# <longer description>
#
# Public functions:
#   ftl::module::function   — <one-line description>
#
# Private functions:
#   _ftl::module::helper    — <one-line description>
#
# Globals:
#   ftl_module_var          — <one-line description>
```

Maintain this header when adding functions or globals.

Inline comments should explain *why*, not *what*. The code shows what;
the comment explains the reasoning.

### 2.7 File Endings

All Bash files end with:

```bash
# vim: set filetype=bash :
```

This is a modeline for vim. Maintain it.

## 3. Commit Conventions

### 3.1 Commit message format

```
<type>: <short description in imperative mood>

<optional body explaining the why and what>

<optional footer>
```

**Types:**

- `ADD` — new feature
- `FIX` — bug fix
- `REFORMAT` — code formatting/refactoring
- `DOCS` — documentation only
- `TEST` — test only
- `CHORE` — build, CI, tooling

**Examples:**

```
ADD: inline rename mode (LEADER r i) — modal single/sequential/regexp/image-label rename

Implements the design proposed in documentation/ftl-inline-rename-proposal.md.
...
```

```
FIX: test harness — default FTL_CFG to project config dir, not $HOME/.config/ftl

The harness was setting FTL_CFG=$HOME/.config/ftl if not already set.
...
```

### 3.2 Commit size

Prefer small, focused commits. One logical change per commit. If a
change spans multiple files, that's fine, but the commit should have a
single purpose.

If a commit adds a feature, it should include:

- The implementation
- Tests
- Documentation updates

### 3.3 Commit frequency

Commit early and often. Use `git commit --amend` or `git rebase -i` to
clean up before pushing. Do not push broken commits.

## 4. Pull Request Process

1. **Branch.** Create a feature branch from `missing_functionalities`
   (or the appropriate base).

2. **Implement.** Make the changes following the code style above.

3. **Test.** Run the full test suite:
   ```bash
   bash test/harness.sh
   ```
   All tests must pass (skips are acceptable for missing optional
   tools).

4. **Document.** Update the man page, mdBook, and analysis docs as
   needed. See [06-documentation.md](./06-documentation.md).

5. **Commit.** Write clear commit messages. Squash WIP commits before
   pushing.

6. **Push.** `git push origin my-feature`.

7. **Open a PR.** Target `missing_functionalities` (or `reformat`).
   Describe the change, the rationale, and the testing performed.

8. **Review.** Address feedback. Force-push to the same branch to
   update the PR.

9. **Merge.** After approval, squash-merge or rebase-merge.

## 5. Code Review Checklist

Before opening a PR, verify:

- [ ] Tests pass (`bash test/harness.sh`)
- [ ] New code has tests
- [ ] No one-liners
- [ ] Tabs for indentation (not spaces) in Bash files
- [ ] `set -u` safe (all variables have defaults)
- [ ] Functions and variables are namespaced
- [ ] Module header comments are updated
- [ ] Man page is updated (if user-facing)
- [ ] mdBook docs are updated (if user-facing)
- [ ] Analysis docs are updated (if architectural)
- [ ] Commit messages follow the convention
- [ ] No debug `set -x` or `echo` left in the code
- [ ] No commented-out code

## 6. Testing Requirements

Every PR must:

1. **Not break existing tests.** `bash test/harness.sh` must show 0
   failures.

2. **Include tests for new features.** If you add a function, add a
   test for it. If you add a binding, add a test that verifies the
   binding is registered and the function works.

3. **Skip gracefully for optional dependencies.** If your feature
   requires an optional tool (e.g. `7z`, `convert`, `fzf-tmux`),
   skip the test if the tool is missing:
   ```bash
   command -v 7z >/dev/null 2>&1 || { ftl::test::skip "7z not installed" ; return ; }
   ```

## 7. Handling Reports

When a bug is reported:

1. **Reproduce.** Create a minimal reproduction.

2. **Isolate.** Determine which module/function is responsible. Use
   `FTL_DEBUG=1` or `FTL_TRACE=1` to enable logging.

3. **Fix.** Make the minimal change that fixes the bug. Do not refactor
   unrelated code in the same commit.

4. **Test.** Add a test that reproduces the bug and verifies the fix.
   The test should fail before the fix and pass after.

5. **Document.** If the bug was in user-facing behavior, update the
   docs.

6. **Commit.** Use the `FIX:` prefix.

## 8. Release Process

ftl does not have a formal release schedule. The `main` branch is
considered stable. To cut a release:

1. Merge `missing_functionalities` (or `reformat`) into `main`.
2. Update the version in `README.md` and the man page date.
3. Tag: `git tag v1.2.3 && git push --tags`.
4. Announce.

## 9. Communication

- **Issues.** Use GitHub issues for bug reports and feature requests.
- **PRs.** Use GitHub PRs for code review.
- **Discussion.** For design discussions, open an issue with the
  `design` label.

## 10. Licensing

ftl is dual-licensed under the Artistic License 2.0 and the GPL 3.0.
Contributions are accepted under the same terms. Do not include code
under incompatible licenses.
