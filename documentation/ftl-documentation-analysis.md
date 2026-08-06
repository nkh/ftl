# ftl Documentation — Deep Analysis & 50 Improvement Suggestions

> **Subject:** Analysis of the current documentation set (60+ files, 33,786
> lines) and 50 concrete suggestions for improvement.
> **Date:** August 2026.

---

## Current Documentation State

### Inventory

| Location | Files | Lines | Purpose |
|----------|-------|-------|---------|
| `docs/src/` | 22 | ~5,200 | mdBook user documentation |
| `docs/src/getting-started/` | 3 | ~220 | Getting started guide |
| `docs/src/user-guide/` | 10 | ~800 | User guide pages |
| `documentation/` | 14 | ~15,400 | Analysis and design documents |
| `documentation/maintenance/` | 9 | ~4,200 | Maintainer documentation |
| `config/ftl/man/ftl.md` | 1 | ~845 | Man page |
| **Total** | **59** | **~33,800** | |

### Issues Found

1. **Old variable names** in 8 user-facing docs (`$fs`, `$pfs`, `sort_by`, etc.)
2. **Stale references** to functions that were renamed during the reformat
3. **Inconsistent terminology** between user docs and maintainer docs
4. **Missing cross-references** between related pages
5. **Outdated code examples** that use pre-reformat variable names
6. **No troubleshooting guide** for common problems
7. **No FAQ** page
8. **No quick reference card** for bindings
9. **Configuration reference** is incomplete (missing new `ftl_cfg_*` variables)
10. **No changelog** documenting the reformat changes

---

## 50 Suggestions

### Structure & Organization (1–10)

1. **Create a quick-reference card** — a single-page printable summary of all
   bindings, organized by category, with the most common 20 keys highlighted.
   Currently the binding table is spread across the man page and
   `key-bindings.md`.

2. **Add a FAQ page** to the mdBook — common questions like "why does ftl
   need tmux?", "how do I change the leader key?", "why doesn't my image
   preview work?", "how do I add a custom binding?".

3. **Add a troubleshooting guide** — "ftl shows a blank screen", "keys
   don't respond", "preview pane is empty", "sort doesn't work", each
   with step-by-step diagnosis using `FTL_DEBUG=1` and log file inspection.

4. **Consolidate the getting-started guide** — the three pages
   (installation, first-steps, bindings) are thin (70-80 lines each).
   Merge into a single "Getting Started" page with sections, or expand
   each to include more detail.

5. **Add a "Common Workflows" page** — step-by-step guides for common
   tasks: "rename a batch of photos", "find and delete large files",
   "compare two directories", "sync selection to remote server".

6. **Create a changelog** (`docs/src/changelog.md`) documenting all
   changes since the reformat, including the bug fixes, new features,
   and variable renames. This helps users upgrading from the old version.

7. **Reorganize the documentation/ directory** — it has 14 analysis
   documents, many of which are historical (pre-reformat analysis,
   migration tables). Move historical docs to a `documentation/archive/`
   subdirectory and keep only current docs at the top level.

8. **Add a glossary** — terms like "hyperorthodox", "etag", "frecency",
   "sub-mode handler", "trie", "FIFO pipeline" are used without
   definition. A glossary page would help new users.

9. **Add a "For Users Coming From..." comparison page** — "Coming from
   ranger? Here's what's different", "Coming from vifm?", "Coming from
   lf?". This helps users transfer their muscle memory.

10. **Add a table of contents to long pages** — pages like
    `missing-functionalities.md` (922 lines) and `extending-ftl.md`
    (730 lines) need a TOC at the top for navigation.

### Content Quality (11–20)

11. **Update all code examples** to use namespaced variable names —
    several examples in `extending-ftl.md` use `$f`, `$n`, `$fs` which
    are old names. Replace with `$ftl_state_current_basename`,
    `$ftl_state_current_path`, `$ftl_state_session_dir`.

12. **Add real-world binding examples** — the current examples are
    minimal (compress selection, count lines). Add 5-10 real-world
    examples: "auto-tag files by extension", "batch convert images",
    "git workflow (stage, commit, push)", "Docker container management".

13. **Expand the configuration reference** — `configuration.md` is only
    203 lines. Document every `ftl_cfg_*` variable with type, default,
    and effect. Currently many variables are only documented in the
    man page or not at all.

14. **Add screenshots/ASCII art** — the user guide pages are
    text-only. Add ASCII art or screenshots showing what the listing,
    preview pane, and shell pane look like. The `assets/` directory
    has 3 images but they're only used in the introduction.

15. **Document the filter pipeline** more thoroughly — the current
    `filtering.md` user guide page is 73 lines. Explain the 5-layer
    pipeline, how filters interact, and how to write a custom filter
    plugin with a worked example.

16. **Document the etag system** — there's no dedicated user guide page
    for etags. Explain what they are, how to activate them (`zT`), and
    how to write a custom etag plugin.

17. **Document the virtual entries system** — the `virtual_entries`
    binding is mentioned in `extra-features.md` but not explained.
    Add a page explaining how virtual entries work and how to write
    a plugin that injects them.

18. **Expand the IPC documentation** — `ipc.md` is 111 lines. Document
    all tmux signal characters (`å`, `Å`, `ä`, `Ä`), the state file
    format, and how external commands interact with ftl.

19. **Add a "Plugin Development Guide"** — the current `writing-*.md`
    pages are separate. Create a unified guide that walks through
    developing a complete plugin (binding + filter + etag + viewer)
    step by step.

20. **Document the `ftl::cmd::prompt` behavior** — the prompt function
    is used by many bindings but its behavior (setting `$REPLY` vs
    `$ftl_kbd_current_key`) is confusing and has caused bugs. Document
    it clearly with examples.

### Accuracy & Consistency (21–30)

21. **Audit all function names in docs** against the actual source —
    the function-index, API reference, and module reference should
    match the actual function definitions. Several still reference
    old names (`sort_by`, `get_key` without namespace).

22. **Audit all variable names in docs** against the actual source —
    the variable-index should list every `ftl_*` variable. Many new
    variables added during bug fixes (e.g., `ftl_state_sync_dir`,
    `ftl_preview_media_pid`) are not documented.

23. **Ensure the man page and mdBook agree** — the man page and
    `key-bindings.md` should have the same binding table. Currently
    they differ in formatting and some entries.

24. **Standardize the term "sub-mode"** — the docs use "sub-mode",
    "submode", and "modal mode" interchangeably. Pick one and use it
    consistently.

25. **Standardize the term "leader key"** — some docs say "leader key",
    others say "LEADER key", others say "the `\` key". Standardize
    to "leader key (`\` by default)".

26. **Update the module reference** — `modules.md` and the maintenance
    `03-modules.md` should list all 17 modules + 15 command sub-modules.
    Currently they list 17 modules but don't mention the command split.

27. **Update the file layout** — `file-layout.md` should reflect the
    current directory structure including `commands/` subdirectory,
    `scripts/` directory, and all new documentation files.

28. **Fix the testing documentation** — `testing.md` and maintenance
    `05-testing.md` should mention the new test files
    (`test_all_bindings.sh`, `test_list_format.sh`) and the trace
    utility (`scripts/trace-all-bindings.sh`).

29. **Update the IPC documentation** to use the correct variable names
    (`$ftl_state_session_dir` instead of `$fs`, `$ftl_state_parent_dir`
    instead of `$pfs`).

30. **Ensure the man page's "Configuration" section** lists all
    `ftl_cfg_*` variables that are actually defined in `ftlrc`. Several
    new variables (`ftl_cfg_sort_options`, `ftl_cfg_image_extensions`)
    were added but not documented in the man page.

### Missing Content (31–40)

31. **Add a "Development Setup" page** — how to set up a development
    environment: clone, branch, install dependencies (tmux, fzf, rg,
    fd, etc.), run tests, iterate.

32. **Add a "Debugging ftl" page** — how to use `FTL_DEBUG=1`,
    `FTL_TRACE=1`, the debug log file, the `ftl::log::trace_call`
    DEBUG trap, and the `pdh` debug pane.

33. **Document the `bin/ftl` entry point** — the main loop, CLI
    argument parsing, session directory setup, and the relationship
    between parent and child panes.

34. **Document the `ftl_setup` initialization sequence** — the
    sourcing order, the `declare -Ag` declarations, and the runtime
    state initialization. This is critical for understanding startup.

35. **Add an "Architecture Decision Records" (ADR) section** —
    document why certain decisions were made: why Bash, why tmux,
    why hyperorthodox panes, why the trie-based keyboard engine.

36. **Document the `viewers/core` dispatcher** — the full case
    statement, the dispatch order, and how to add a new viewer
    function for a new file type.

37. **Add a "Performance Guide"** — known bottlenecks (large
    directories, NFS, du computation), how to mitigate them
    (filters, listing depth, quick display), and benchmarking with
    `hyperfine`.

38. **Document the generator system** — how `generators/generator`
    works, the caching mechanism, how to add a new generator for a
    new file type.

39. **Add a "Migration Guide"** for users coming from the pre-reformat
    ftl — what changed, what bindings were renamed, what variables
    were renamed, how to update custom plugins.

40. **Document the `ftlrc_dir` per-directory override** — the
    `.ftlrc_dir` file is mentioned in `list.sh` but never documented
    for users.

### Presentation & Format (41–50)

41. **Add syntax highlighting** to all code blocks in the mdBook —
    ensure every code block has a language specifier (` ```bash `).

42. **Add "Note", "Warning", and "Tip" callout boxes** — use
    mdBook's admonition syntax to highlight important information,
    common pitfalls, and best practices.

43. **Add internal links** between related pages — e.g., when
    `extending-ftl.md` mentions bindings, link to
    `writing-bindings.md`; when `inline-rename.md` mentions the
    keyboard engine, link to `architecture.md`.

44. **Consistent heading hierarchy** — some pages use `##` for
    top-level sections, others use `#`. Standardize: `#` for page
    title, `##` for major sections, `###` for subsections.

45. **Add "Previous" and "Next" navigation** — the mdBook SUMMARY.md
    defines order, but pages don't have prev/next links at the bottom.
    mdBook generates these automatically, but verify they work.

46. **Use tables consistently** — the binding tables in the man page
    use `| Key | Action |` format, but the mdBook uses different
    formats. Standardize on one table format.

47. **Add a search index** — mdBook supports search. Enable it in
    `book.toml` and verify it indexes all pages.

48. **Shorten the man page** — the man page is 845 lines. Split into
    sections: "ftl.1" (core man page, ~200 lines), and move the
    detailed binding tables and configuration to the mdBook.

49. **Add badges to the README** — build status, test count, license,
    latest version. The README currently has no badges.

50. **Create a printable PDF** — generate a PDF from the mdBook for
    offline reading. mdBook supports PDF output via `mdbook-pdf`
    backend.
