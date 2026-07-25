# ftl Maintenance Documentation

This directory contains the maintenance documentation for ftl. It is
written for engineers who have never seen the ftl codebase before and
need to progress from zero understanding to confident modification of
any part of the project.

## Audience

The intended reader is a software engineer with:

- Working knowledge of Bash 5+ (associative arrays, namerefs, `declare
  -g`, `local`, subshells, traps)
- Familiarity with tmux (panes, windows, sessions, `tmux split-window`,
  `tmux send-keys`, `tmux popup`)
- General Unix file-management instincts (inotify, FUSE, MIME types,
  `LS_COLORS`)
- Some experience with at least one other terminal file manager
  (ranger, vifm, lf, nnn, yazi, broot) — useful but not required

No prior knowledge of ftl is assumed.

## Reading Order

The documents are numbered and intended to be read in order. Each
builds on the previous.

| # | Document | Purpose | Time |
|---|----------|---------|------|
| 1 | [01-onboarding.md](./01-onboarding.md) | First reading: what ftl is, how to run it, how to read the source, the mental model | 30 min |
| 2 | [02-architecture.md](./02-architecture.md) | Deep architectural walkthrough: process model, state flow, the listing pipeline, the keyboard engine, pane IPC | 60 min |
| 3 | [03-modules.md](./03-modules.md) | Module-by-module reference: every module's responsibility, public API, private helpers, interactions with other modules | 90 min |
| 4 | [04-api-reference.md](./04-api-reference.md) | Complete API listing grouped by module, with signatures, side effects, and usage notes | reference |
| 5 | [05-testing.md](./05-testing.md) | The testing system: harness design, test categories, how to write and run tests, the stubbing pattern | 45 min |
| 6 | [06-documentation.md](./06-documentation.md) | The documentation system: mdBook structure, man page, analysis docs, how to modify each | 30 min |
| 7 | [07-modification-guide.md](./07-modification-guide.md) | Step-by-step recipes for common modifications: add a binding, add a command, add a filter, add a viewer, modify the listing, modify the keyboard engine, modify the preview pipeline | 90 min |
| 8 | [08-contributing.md](./08-contributing.md) | Contribution workflow: branch naming, commit conventions, code style, tab indentation, `set -u` discipline, PR process | 20 min |

Total reading time: approximately 6 hours. After completing the
sequence, the maintainer should be competent to modify any part of ftl.

## Proposed Structure (Rationale)

The documentation is split into eight documents rather than one large
file for the following reasons:

1. **Cognitive load.** A single 6000-line document is intimidating and
   difficult to navigate. Eight focused documents of 500–1500 lines
   each are tractable.

2. **Selective reading.** A maintainer who only needs to add a binding
   can read documents 1, 3 (relevant module), and 7, skipping the
   architecture deep-dive and the testing system. The structure
   supports this.

3. **Reference vs. tutorial separation.** Document 4 (API reference)
   is a reference: alphabetical, complete, no narrative. Documents 1–3
   and 7 are tutorials: narrative, progressive, with examples. Keeping
   them separate serves both use cases.

4. **Maintenance of the documentation itself.** When a module's API
   changes, only document 4 needs updating. When the architecture
   changes, only document 2. The split localizes documentation churn.

5. **Discoverability.** The numbered prefix makes the reading order
   obvious in any file browser or `ls` output. The maintainer does not
   need to consult an index to know what to read next.

## Quick Start

If the maintainer has limited time and wants the minimum viable
understanding to make a small change:

1. Read [01-onboarding.md](./01-onboarding.md) (30 min).
2. Read the relevant section of [03-modules.md](./03-modules.md) for
   the module being modified (10 min).
3. Read the relevant recipe in
   [07-modification-guide.md](./07-modification-guide.md) (15 min).
4. Read [05-testing.md](./05-testing.md) sections 1–3 (15 min) to
   understand how to verify the change.

Total: ~70 minutes to a first contribution.

## Companion Documents

The following documents in the parent `documentation/` directory
provide additional context:

- `ftl-analysis.md` — a deep functional, code, and architecture
  analysis of the original (pre-reformat) ftl codebase
- `ftl2-architecture-analysis.md` — the post-reformat architecture
  analysis (the current state)
- `ftl2-rewrite-report.md` — the report on the reformat effort (module
  split, namespacing, tab indentation)
- `ftl2-variable-migration-table.md` — old → new variable name mapping
- `ftl2-function-migration-table.md` — old → new function name mapping
- `ftl-variables.md` — complete variable reference
- `ftl-bindings-analysis.md` — analysis of the binding set
- `ftl-ftlrc-reference.md` — configuration reference
- `ftl-missing-functionality.md` — 42 implemented feature proposals
- `ftl-missing-functionality-v2.md` — 60 new feature proposals
- `ftl-inline-rename-proposal.md` — design document for the inline
  rename mode
- `ftl-terminal-file-manager-comparison.md` — comparison of 10
  terminal file managers
- `ftl-plugin-ideas.md` — 25 new plugin ideas + 25 improvements to
  existing plugins

The mdBook user documentation in `docs/src/` is the user-facing
counterpart to this maintainer-facing documentation.

## Conventions Used in This Documentation

- **Function names** are written in `monospace` and include the full
  namespace: `ftl::kbd::bind`, `ftl::list::render`.
- **Variable names** are written in `monospace` with the full prefix:
  `ftl_kbd_trie`, `ftl_state_cursor_index`.
- **File paths** are relative to the project root unless prefixed with
  `/`: `config/ftl/etc/core/modules/keyboard.sh`.
- **Code blocks** are Bash unless otherwise noted.
- **Cross-references** to other documents use the format
  `[document-name, §section]`.

## Status

This documentation suite was written in July 2026 against the
`missing_functionalities` branch (commit history through `93a6ce0`).
The codebase at that point comprises:

- 17 core modules totaling ~5,500 lines of Bash
- 1 viewer dispatcher (`viewers/core`, ~500 lines)
- 1 entry point (`bin/ftl`, ~300 lines)
- 1 setup orchestrator (`etc/core/ftl_setup`, ~120 lines)
- 1 config file (`etc/ftlrc`, ~600 lines)
- 19 binding plugins, 10 commands, 7 etags, 19 filters, 18 generators,
  5 viewers
- 925 tests (797 unit + 128 behavioral + 17 tmux integration) in 32
  test files
- mdBook documentation in `docs/src/` (31 pages, ~5,200 lines)
- Analysis documents in `documentation/` (12 files, ~15,400 lines)

The documentation is a living document. When the codebase changes,
update the relevant section and bump the date in the document header.
