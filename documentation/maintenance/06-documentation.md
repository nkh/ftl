# 06 — Documentation

> **Audience:** Maintainers modifying the documentation.
> **Goal:** Understand the documentation structure, build process, and
> how to update each part.
> **Time:** 30 minutes.

---

## 1. Documentation Structure

ftl's documentation is split into three trees:

```
ftl-work/
├── docs/                       ← mdBook user documentation
│   ├── book.toml               ← mdBook configuration
│   └── src/
│       ├── SUMMARY.md          ← table of contents (mdBook entry point)
│       ├── *.md                ← top-level pages
│       ├── getting-started/    ← getting started guide
│       ├── user-guide/         ← user guide pages
│       └── assets/             ← images
├── documentation/              ← analysis and design documents
│   ├── maintenance/            ← maintainer documentation (this directory)
│   ├── ftl-analysis.md
│   ├── ftl2-architecture-analysis.md
│   ├── ftl-variables.md
│   ├── ftl-bindings-analysis.md
│   ├── ftl-ftlrc-reference.md
│   ├── ftl-missing-functionality.md
│   ├── ftl-missing-functionality-v2.md
│   ├── ftl-inline-rename-proposal.md
│   ├── ftl-terminal-file-manager-comparison.md
│   └── ftl-plugin-ideas.md
└── config/ftl/man/ftl.md       ← the man page (Markdown source for mandoc)
```

### 1.1 `docs/` — mdBook user documentation

This is the user-facing documentation. It is built with
[mdBook](https://rust-lang.github.io/mdBook/) and published as an
HTML book.

**`SUMMARY.md`** is the entry point. It defines the table of
contents. mdBook requires this file. To add a page, create the
`.md` file and add a line to `SUMMARY.md`.

**`book.toml`** configures the build. The default output is
`docs/book/` (HTML).

### 1.2 `documentation/` — analysis and design documents

These are maintainer-facing documents. They are not part of the mdBook
build. They include:

- Architecture analyses (pre- and post-reformat)
- Variable and function migration tables (from the reformat)
- Feature proposal documents (missing functionalities v1 and v2)
- Design documents (inline rename proposal)
- Comparative analyses (terminal file manager comparison)
- Plugin ideas
- **`maintenance/`** — this directory (maintainer onboarding)

### 1.3 `config/ftl/man/ftl.md` — the man page

The man page is written in Markdown (specifically, the dialect
understood by `mandoc -Tmd` or `pandoc -f markdown -t man`). It is the
canonical reference for ftl's keybindings and configuration.

## 2. Building the mdBook

To build the mdBook locally:

```bash
# Install mdBook (if not already installed)
cargo install mdbook
# or: download a prebuilt binary from
# https://github.com/rust-lang/mdBook/releases

# Build the book
cd docs
mdbook build

# The HTML output is in docs/book/
# Open docs/book/index.html in a browser

# Serve locally with live reload
mdbook serve --open
```

`mdbook serve` starts a local web server (default
`http://localhost:3000`) and rebuilds on every file change. This is
the recommended workflow for documentation development.

## 3. Modifying the mdBook

### 3.1 Adding a new page

1. Create the `.md` file in the appropriate directory under
   `docs/src/`. For example, `docs/src/user-guide/my-feature.md`.

2. Add a line to `docs/src/SUMMARY.md` in the appropriate section:

   ```markdown
   # User Guide

   - [Navigation](./user-guide/navigation.md)
   - [Selection & Tags](./user-guide/selection.md)
   - [My Feature](./user-guide/my-feature.md)  ← new line
   ```

3. Write the page content. Use Markdown (CommonMark + GitHub-flavored
   tables and code blocks).

4. Rebuild (or let `mdbook serve` rebuild automatically).

### 3.2 Modifying an existing page

Edit the `.md` file directly. mdBook rebuilds on save.

### 3.3 Adding images

Place images in `docs/src/assets/`. Reference them in Markdown:

```markdown
![ftl main view](assets/ftl.png)
```

### 3.4 Cross-references

Use relative links:

```markdown
See [Inline Rename Mode](./user-guide/inline-rename.md) for details.
```

mdBook validates links at build time. Broken links produce warnings.

### 3.5 Page structure conventions

Each page should have:

- A `# Title` H1 heading
- An introductory paragraph (1–3 sentences) stating the page's purpose
- A table of contents for long pages (use `##` headings; mdBook
  generates the TOC automatically if `output.html.fold.enable = true`
  in `book.toml`)
- Section headings (`##`, `###`) in logical order
- Code blocks with language specifiers (` ```bash `)
- Cross-references to related pages

### 3.6 Tone

The documentation targets a mixed audience of casual computer users
and hardcore Linux command-line power users. The tone is technical
but relaxed:

- Use second person ("you") for instructions.
- Avoid contractions in formal sections ("do not" instead of "don't").
- Explain non-obvious terms on first use.
- Provide examples for every feature.
- Cross-reference related features.

## 4. Modifying the Man Page

The man page is `config/ftl/man/ftl.md`. It uses a Markdown dialect
that `mandoc` or `pandoc` can convert to the man page format.

### 4.1 Structure

The man page is organized as:

```markdown
# FTL 1 "July 2026" "ftl" "File Manager Manual"

## Name
ftl — terminal file manager

## Synopsis
ftl [-f filter] [-s file] [-t file] [directory/file]

## Description
...

## Options
...

## Concepts
...

## Key Bindings
... (the bulk of the man page)

## Configuration
...

## Files
...

## See Also
...

## Bugs
...

## Author
...
```

### 4.2 Adding a new binding to the man page

1. Find the appropriate table in the "Key Bindings" section (e.g.
   "File Operations", "Navigation", "Preview Control").

2. Add a row to the table:

   ```markdown
   | **LEADER r i** | Enter inline rename mode (see below) |
   ```

3. If the binding needs a detailed subsection (like inline rename
   mode), add an `###` subsection after the relevant table.

### 4.3 Tab indentation in the man page

The man page uses **spaces** (not tabs) for indentation in code blocks
and tables. This is different from the Bash source files (which use
tabs). Be consistent within the man page.

### 4.4 Building the man page

To preview the man page:

```bash
# Convert to man format and view
pandoc -f markdown -t man config/ftl/man/ftl.md | man -l -

# Or install as a man page
pandoc -f markdown -t man config/ftl/man/ftl.md > /usr/local/share/man/man1/ftl.1
mandb
man ftl
```

The `ftl_cfg_help_command` variable (set in `ftlrc`) controls what
runs when the user presses `?`. The default is `man ftl.1`.

## 5. Modifying the Analysis Documents

The analysis documents in `documentation/` are standalone Markdown
files. Edit them directly. No build step is required.

### 5.1 Document conventions

- Each document starts with a blockquote header:
  ```markdown
  > **Subject:** ...
  > **Purpose:** ...
  > **Companion documents:** ...
  > **Approach:** ...
  ```

- Use `##` for top-level sections, `###` for subsections.

- Code blocks use ` ```bash ` for Bash, ` ``` ` for generic output.

- Cross-reference other documents by filename:
  ```markdown
  See `ftl-missing-functionality.md` §1.6 for the batch rename proposal.
  ```

### 5.2 When to update which document

| Document | Update when... |
|----------|----------------|
| `ftl-analysis.md` | Never (historical; describes the pre-reformat codebase) |
| `ftl2-architecture-analysis.md` | The architecture changes |
| `ftl2-rewrite-report.md` | Never (historical; describes the reformat) |
| `ftl2-variable-migration-table.md` | Never (historical) |
| `ftl2-function-migration-table.md` | Never (historical) |
| `ftl-variables.md` | A variable is added, removed, or renamed |
| `ftl-bindings-analysis.md` | The binding set changes significantly |
| `ftl-ftlrc-reference.md` | A `ftl_cfg_*` variable is added or changed |
| `ftl-missing-functionality.md` | A v1 proposal is implemented (mark its status) |
| `ftl-missing-functionality-v2.md` | A v2 proposal is implemented (mark its status) |
| `ftl-inline-rename-proposal.md` | The inline rename design changes |
| `ftl-terminal-file-manager-comparison.md` | A competitor releases a major version |
| `ftl-plugin-ideas.md` | New ideas or when an idea is implemented |
| `maintenance/*.md` | The codebase, build, or conventions change |

## 6. Modifying the Maintenance Documentation

This directory (`documentation/maintenance/`) is the maintainer
onboarding suite. To modify it:

1. Edit the relevant `.md` file.
2. Update the `README.md` index if the change affects the reading
   order or the file list.
3. Update the "Status" section in `README.md` if the codebase
   statistics (line counts, test counts, etc.) have changed.

### Conventions for maintenance docs

- Numbered prefix (`01-`, `02-`, etc.) for reading order.
- Each document starts with a blockquote stating audience, goal, and
  time.
- Cross-references use the format `[NN-document.md, §section]`.
- Code blocks use ` ```bash ` for Bash.
- The tone is formal and technical (not casual).

## 7. Documentation and Code Synchronization

The documentation should reflect the current state of the code. To
keep them in sync:

1. **When adding a feature:** Update the man page (binding table +
   subsection if needed), the relevant mdBook page, and (if
   applicable) the analysis documents. Add a test.

2. **When changing an existing feature:** Update all documentation
   that mentions the feature. Search for the feature name across
   `docs/`, `documentation/`, and `config/ftl/man/`.

3. **When removing a feature:** Remove all documentation references.
   Search for the feature name.

4. **When renaming a function or variable:** Update the API reference
   (`04-api-reference.md`), the variable reference
   (`ftl-variables.md`), and any cross-references.

### Search commands

```bash
# Search all documentation for a term
rg "term" docs/ documentation/ config/ftl/man/

# Search all Bash source for a function name
rg "ftl::my::function" config/ftl/

# Search test files for a test name
rg "test_my_feature" test/
```

## 8. Publishing

The mdBook is published by building `docs/book/` and hosting it. The
GitHub repository may have GitHub Pages configured to serve
`docs/book/` from the `gh-pages` branch (or similar).

To publish manually:

```bash
cd docs
mdbook build
# Deploy docs/book/ to your hosting provider
```

The man page is installed as part of `make install` (if an
install target exists) or manually:

```bash
pandoc -f markdown -t man config/ftl/man/ftl.md > /usr/local/share/man/man1/ftl.1
mandb
```
