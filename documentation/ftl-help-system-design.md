# ftl Help System (`-h`) — Design Document

> **Subject:** Detailed design for a `-h` / `--help` option in ftl,
> with three help levels (short, complete, detailed), argument-
> specific help (`-h <topic>`), and a unified documentation
> architecture that reuses the existing mdBook and man page content
> rather than maintaining a separate help system.
> **Status:** Design document — **not yet implemented**. Pending
> review.
> **Companion documents:** `maintenance/06-documentation.md` (current
> documentation system), `config/ftl/man/ftl.md` (existing man page),
> `docs/src/SUMMARY.md` (existing mdBook structure).

---

## Table of Contents

1. [Goals](#1-goals)
2. [Non-Goals](#2-non-goals)
3. [User-Facing Interface](#3-user-facing-interface)
4. [The Three Help Levels](#4-the-three-help-levels)
5. [Argument-Specific Help](#5-argument-specific-help)
6. [Why Reuse Existing Documentation](#6-why-reuse-existing-documentation)
7. [Architecture](#7-architecture)
8. [Content Extraction Strategy](#8-content-extraction-strategy)
9. [Build Pipeline](#9-build-pipeline)
10. [File Layout](#10-file-layout)
11. [The Help Renderer](#11-the-help-renderer)
12. [Topic Index](#12-topic-index)
13. [Runtime Behavior](#13-runtime-behavior)
14. [Integration with ftl's `:` Prompt](#14-integration-with-ftls--prompt)
15. [Caching Strategy](#15-caching-strategy)
16. [Internationalization Considerations](#16-internationalization-considerations)
17. [Testing Strategy](#17-testing-strategy)
18. [Migration Path](#18-migration-path)
19. [Open Questions](#19-open-questions)
20. [Implementation Phases](#20-implementation-phases)

---

## 1. Goals

1. **Three help levels from the command line:**
   - `ftl -h` — short, concise help (fits on one screen)
   - `ftl -h full` — complete help (the equivalent of the current man page)
   - `ftl -h detailed` — detailed help (the full mdBook content, navigable)

2. **Argument-specific help:**
   - `ftl -h <topic>` — shows help for a specific topic (binding, command,
     config variable, module)
   - Examples: `ftl -h LEADER-r-i`, `ftl -h rename`, `ftl -h ftl_cfg_leader_key`,
     `ftl -h keyboard`

3. **Unified documentation source:** The help content is extracted from
   the existing documentation (man page + mdBook), not authored
   separately. A single source of truth.

4. **No mandatory build step for help:** The help system works from a
   pre-built index that ships with ftl. Users do not need to install
   mdBook or run a build to use `-h`.

5. **Works outside tmux:** `ftl -h` must work without tmux (unlike
   `ftl` itself). This is critical — users often check `--help` before
   deciding whether to use a tool.

6. **Fast:** Help should appear in under 100ms. No sourcing of ftl's
   core modules.

---

## 2. Non-Goals

1. **Not a replacement for the man page or mdBook.** The man page
   remains the canonical reference; the mdBook remains the canonical
   user guide. The help system is a **view** over these sources.

2. **Not interactive.** `ftl -h detailed` does not open an interactive
   pager (that would require tmux). It dumps the content to stdout;
   the user pipes to `less` if desired. (The `:help` command inside
   ftl *can* be interactive — see §14.)

3. **No search engine.** `ftl -h <topic>` does exact or prefix
   matching only. Full-text search is the mdBook's job (via the
   browser).

4. **No HTML rendering from the CLI.** The CLI help is plain text
   (with ANSI color if the terminal supports it). HTML is the
   mdBook's domain.

5. **No re-authoring of content.** If the help content is wrong, fix
   the source (man page or mdBook), not the help system.

---

## 3. User-Facing Interface

### 3.1 The `-h` flag

```
ftl -h                    # short help (concise)
ftl -h full               # complete help (man page equivalent)
ftl -h detailed           # detailed help (full mdBook dump)
ftl -h <topic>            # help for a specific topic
ftl --help                # alias for -h
ftl --help=<topic>        # alias for -h <topic>
```

### 3.2 Behavior

- `-h` is handled **before** the tmux check. This means `ftl -h` works
  outside tmux.
- `-h` is handled **before** sourcing `ftl_setup`. This makes help
  fast (no module loading).
- After printing help, ftl exits with code 0. Help is not an error.
- If `-h` is combined with other flags (e.g. `ftl -h -s file`), help
  wins and the other flags are ignored.

### 3.3 Topic syntax

Topics are normalized for matching:

- `LEADER-r-i` → looks up the binding `LEADER r i`
- `leader-r-i` → same (case-insensitive)
- `LEADER_r_i` → same (underscores = hyphens = spaces)
- `rename` → looks up the command `ftl::cmd::rename_selection` and
  any binding whose command contains "rename"
- `ftl_cfg_leader_key` → looks up the config variable
- `keyboard` → looks up the module `keyboard.sh` and the mdBook page
  on the keyboard engine

The normalization rules:

1. Convert to lowercase.
2. Replace `_` and spaces with `-`.
3. Strip leading/trailing hyphens.
4. Collapse multiple hyphens.

### 3.4 Exit codes

- `0` — help displayed successfully
- `0` — help displayed, but topic not found (with a "topic not found"
  message and a suggestion list)
- `1` — help system error (missing index file, corrupt data)

---

## 4. The Three Help Levels

### 4.1 Short help (`ftl -h`)

**Purpose:** Get the user started in 30 seconds. Fits on one screen
(~20 lines).

**Content:**

```
ftl — terminal file manager, with live previews, hyperorthodox

Usage: ftl [-f filter] [-s file] [-t file] [directory[/file]]

Options:
  -f <filter>    Load an external filter plugin at startup
  -s <file>      Pre-select paths from file (one per line)
  -t <file>      Open paths in separate tabs (one per line)
  -h [topic]     Show help (short, full, detailed, or topic-specific)
  directory      Initial directory (or file to select)

Quick start:
  ftl                  # open in current directory
  ftl ~/projects       # open in a directory
  ftl ~/file.txt       # open in file's parent, select the file

Inside ftl:
  j/k         move down/up       h/l  parent/child
  SPACE/t     tag entry          q    quit
  :           command prompt     ?    show help (man page)
  c           show bindings      LEADER  leader key (\)

Learn more:
  ftl -h full       # complete help (man page equivalent)
  ftl -h detailed   # full documentation
  ftl -h <topic>    # help for a specific topic

Documentation: https://github.com/nkh/ftl (docs/ directory)
```

**Source:** Authored as a standalone file
(`config/ftl/etc/help/short.md`). Not extracted from the man page —
the short help is a curated summary, and curating it separately is
simpler than extracting a subset.

### 4.2 Complete help (`ftl -h full`)

**Purpose:** The equivalent of `man ftl`. Everything a regular user
needs.

**Content:** The existing man page (`config/ftl/man/ftl.md`), rendered
as plain text with ANSI bold for `**bold**` spans.

**Source:** `config/ftl/man/ftl.md` (the existing man page, unchanged).

**Rendering:** A Markdown-to-text renderer converts the man page to
plain text. Bold (`**text**`) becomes ANSI bold. Tables are rendered
as text tables. Code blocks are indented.

### 4.3 Detailed help (`ftl -h detailed`)

**Purpose:** The full documentation, for users who want deep context.
Equivalent to reading the mdBook.

**Content:** All mdBook pages concatenated in reading order (as
defined by `SUMMARY.md`), with page separators and a table of
contents at the top.

**Source:** `docs/src/**/*.md` (the existing mdBook source).

**Rendering:** Same Markdown-to-text renderer as `full`. Page
boundaries are marked with `\n=== <page title> ===\n`. The output is
long (the mdBook is ~5000 lines); users will pipe to `less` or
`grep`.

**Note:** This is the "dump everything" option. It is not meant to
be read end-to-end from the terminal; it is meant to be grepped or
piped to a pager for offline reference.

---

## 5. Argument-Specific Help

### 5.1 Topic categories

`ftl -h <topic>` resolves the topic to one of:

| Category | Example topic | Source |
|----------|---------------|--------|
| Binding | `LEADER-r-i`, `j`, `xd` | Extracted from man page binding tables + `ftl_kbd_bindings_display` |
| Command | `rename`, `delete` | Extracted from `commands.sh` function headers + man page |
| Config variable | `ftl_cfg_leader_key` | Extracted from `ftlrc` comments + `ftl-ftlrc-reference.md` |
| Module | `keyboard`, `list` | Extracted from module header comments + `maintenance/03-modules.md` |
| Concept | `preview`, `selection` | Extracted from mdBook page titles + first paragraph |
| Plugin | `incremental_search`, `missing_functionalities` | Extracted from plugin file headers |

### 5.2 Topic resolution

The resolver tries each category in order:

1. **Binding match.** Normalize the topic. If it matches a binding's
   key sequence (e.g. `LEADER-r-i` → `LEADER r i`), show the binding's
   help: key, command function, description, and a link to the
   relevant man page section.

2. **Command match.** If the topic matches a command name (e.g.
   `rename` → `ftl::cmd::rename_selection`), show the command's
   signature, description (from the function header comment), and
   related bindings.

3. **Config variable match.** If the topic starts with `ftl_cfg_`,
   look it up in the config reference. Show the variable name,
   default value, and description.

4. **Module match.** If the topic matches a module name (e.g.
   `keyboard`), show the module's purpose (from the header comment),
   public API count, and a link to the maintenance doc.

5. **Concept match.** If the topic matches an mdBook page title (e.g.
   `preview` → `user-guide/preview.md`), show the page's title and
   first paragraph, with a note pointing to the full page.

6. **Plugin match.** If the topic matches a plugin file name, show
   the plugin's header comment and registered bindings.

7. **Not found.** If no match, print "topic not found" and a list of
   similar topics (prefix match + Levenshtein distance for typo
   correction).

### 5.3 Topic output format

```
ftl -h LEADER-r-i

Binding: LEADER r i
Command: ftl::plugin::inline_rename::enter
Description: enter inline rename mode

Inline rename mode is a modal, two-level workflow for renaming files.
... (first 2 paragraphs from docs/src/user-guide/inline-rename.md) ...

See also:
  man ftl  (section: Inline Rename Mode)
  ftl -h detailed  (full documentation)
  docs/src/user-guide/inline-rename.md
```

---

## 6. Why Reuse Existing Documentation

The core design principle is **single source of truth**. The help
system does not author content; it extracts and renders content from
the existing documentation.

### 6.1 The alternative (and why it's bad)

The alternative is to author help content separately — e.g. a
`help/bindings.txt`, `help/commands.txt`, etc. This approach has
three problems:

1. **Drift.** When a binding changes, the developer must update the
   man page, the mdBook, the help text, and the source code. In
   practice, one or more of these is forgotten. The documentation
   drifts from reality.

2. **Effort.** Authoring the same content in three formats (man page
   Markdown, mdBook Markdown, plain-text help) is triple the work for
   no benefit.

3. **Inconsistency.** The three formats will diverge in tone,
   detail, and examples. Users get different answers depending on
   where they look.

### 6.2 The reuse approach

ftl already has two well-maintained documentation sources:

- **The man page** (`config/ftl/man/ftl.md`) — the canonical
  reference for bindings, options, and configuration. ~750 lines.
- **The mdBook** (`docs/src/`) — the canonical user guide and deep
  dives. ~5000 lines across 31 pages.

The help system extracts from these:

- Short help is curated (standalone) because it is a summary, not a
  subset.
- Full help is the man page, rendered as text.
- Detailed help is the mdBook, concatenated and rendered as text.
- Topic-specific help is extracted from the relevant section of the
  man page or mdBook, identified by an index.

### 6.3 What changes in the existing docs

To make extraction reliable, the existing documentation needs minor
structural changes:

1. **Man page:** Add HTML comment markers to sections so the
   extractor can locate them:
   ```markdown
   <!-- HELP:binding:LEADER-r-i -->
   ### Inline Rename Mode
   ...
   <!-- /HELP:binding:LEADER-r-i -->
   ```

2. **mdBook pages:** Add a YAML-style frontmatter block with the
   topic identifier:
   ```markdown
   ---
   help_topics: [preview, preview-system, preview-pane]
   ---
   # Preview System
   ...
   ```

3. **Config reference (`ftlrc`):** The config file already has
   comments; the extractor parses them. No changes needed, but a
   convention helps:
   ```bash
   # ftl_cfg_leader_key: the leader key (default: BACKSLASH)
   ftl_cfg_leader_key='BACKSLASH'
   ```

4. **Module headers:** Already structured (see `keyboard.sh:1-35`).
   The extractor parses them.

These changes are additive and do not affect the rendered output of
the man page or mdBook.

---

## 7. Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Source Documentation                     │
│                                                              │
│  config/ftl/man/ftl.md          docs/src/**/*.md             │
│  (man page, with HELP markers)  (mdBook, with frontmatter)   │
│  config/ftl/etc/ftlrc           config/ftl/etc/core/modules/ │
│  (config, with comments)        (module headers)             │
└──────────────┬──────────────────────────────────┬───────────┘
               │                                  │
               ▼                                  │
    ┌─────────────────────┐                      │
    │  Build Script        │                      │
    │  (scripts/build-     │                      │
    │   help-index.sh)     │                      │
    └──────────┬──────────┘                      │
               │                                  │
               ▼                                  │
    ┌─────────────────────┐                      │
    │  Help Index          │                      │
    │  (config/ftl/etc/    │                      │
    │   help/index.tsv)    │                      │
    │  + help cache        │                      │
    │  (config/ftl/etc/    │                      │
    │   help/cache/)       │                      │
    └──────────┬──────────┘                      │
               │                                  │
               ▼                                  │
    ┌─────────────────────┐                      │
    │  Help Renderer       │     ◄────────────────┘
    │  (config/ftl/etc/    │
    │   bin/ftl-help)      │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  ftl -h [topic]      │
    │  (user invocation)   │
    └─────────────────────┘
```

### Components

1. **Source documentation** (existing) — man page, mdBook, ftlrc,
   module headers. With minor structural additions (markers,
   frontmatter).

2. **Build script** (`scripts/build-help-index.sh`) — a Bash script
   run at build time (or manually) that scans the source docs and
   produces the help index and cache. This script does **not** run at
   ftl startup; its output is checked into the repository.

3. **Help index** (`config/ftl/etc/help/index.tsv`) — a tab-separated
   file mapping topics to their location in the source docs. Example:
   ```
   binding:LEADER-r-i\tman:ftl.md:296:50
   binding:j\tman:ftl.md:139:5
   command:rename\tman:ftl.md:277:1\tcommands.sh:858:1
   config:ftl_cfg_leader_key\tftlrc:267:1
   module:keyboard\tmaintenance/03-modules.md:keyboard-section
   concept:preview\tdocs/src/user-guide/preview.md:1:10
   ```

4. **Help cache** (`config/ftl/etc/help/cache/`) — pre-extracted text
   snippets for each topic, rendered as plain text with ANSI escapes.
   One file per topic. This avoids re-parsing Markdown at runtime.

5. **Help renderer** (`config/ftl/etc/bin/ftl-help`) — a standalone
   Bash script (not sourced into ftl's main shell) that:
   - Parses the `-h` arguments
   - Looks up the topic in the index
   - Outputs the cached snippet (or the full man page / mdBook dump)
   - Exits

6. **ftl entry point** (`config/ftl/etc/bin/ftl`) — modified to
   intercept `-h` before the tmux check and delegate to `ftl-help`.

---

## 8. Content Extraction Strategy

The build script extracts content from the source docs using these
strategies:

### 8.1 From the man page

The man page is Markdown. The build script uses `awk` and `sed` to
extract sections delimited by `<!-- HELP:... -->` markers.

**Man page structure (with markers):**
```markdown
<!-- HELP:section:file-operations -->
## File Operations

| Key | Action |
|-----|--------|
| **R** | Rename selection (via **edir**(1)) |
| **LEADER r i** | Enter inline rename mode (see below) |
...
<!-- /HELP:section:file-operations -->

<!-- HELP:binding:LEADER-r-i -->
### Inline Rename Mode

Press **LEADER r i** to enter inline rename mode...
<!-- /HELP:binding:LEADER-r-i -->
```

**Extraction:**
```bash
extract_marker() {
    local file="$1" marker="$2"
    awk -v m="$marker" '
        $0 == "<!-- HELP:" m " -->" { in=1; next }
        $0 == "<!-- /HELP:" m " -->" { in=0 }
        in { print }
    ' "$file"
}
```

### 8.2 From the mdBook

Each mdBook page has a YAML frontmatter block listing its help topics:

```markdown
---
help_topics: [preview, preview-system, preview-pane]
---
# Preview System

The preview pane shows the contents of the current entry...
```

**Extraction:**
```bash
extract_mdbook_page() {
    local file="$1"
    # Strip frontmatter, return the body
    awk 'BEGIN{in_fm=0} /^---$/{if(NR==1){in_fm=1;next}; if(in_fm){in_fm=0;next}} !in_fm' "$file"
}
```

The first paragraph (after the `#` title) is used as the topic's
short description.

### 8.3 From the config file (ftlrc)

The config file has inline comments. The build script parses
`# var: description` patterns:

```bash
# ftl_cfg_leader_key: the leader key (default: BACKSLASH)
ftl_cfg_leader_key='BACKSLASH'
```

**Extraction:**
```bash
awk '/^# (ftl_cfg_[a-z_]+): / {
    var=$2; sub(/:$/, "", var)
    desc=$0; sub(/^# [a-z_]+: /, "", desc)
    print var "\t" desc
}' "$FTL_CFG/etc/ftlrc"
```

### 8.4 From module headers

Module headers have a structured format (see `keyboard.sh:1-35`):

```bash
# keyboard.sh — keyboard input engine
#
# Handles key reading, normalization, trie-based dispatch, and binding
# management.
#
# Public functions:
#   ftl::kbd::bind                — register a key binding
#   ftl::kbd::unbind              — remove a key binding
# ...
```

**Extraction:** Parse the header comment block (lines starting with
`#` at the top of the file). Extract the module name, purpose, and
public API list.

### 8.5 From binding registrations

The build script scans `etc/bindings/*` and `bindings/*` for
`ftl::kbd::bind` calls and extracts the key, command, and help text:

```bash
awk '/ftl::kbd::bind/ {
    # Parse the tab-separated fields
    # ... (the call uses tabs as separators)
}' "$file"
```

This produces a list of all bindings with their help text, which
feeds the `binding:<key>` topics.

---

## 9. Build Pipeline

The build pipeline runs offline (at release time, or manually by
developers). Its output is checked into the repository.

### 9.1 Build script: `scripts/build-help-index.sh`

```bash
#!/usr/bin/env bash
# scripts/build-help-index.sh — build the help index and cache
#
# Run this after modifying the man page, mdBook, ftlrc, or module
# headers. Commit the resulting index.tsv and cache/ directory.

set -euo pipefail

FTL_CFG="${FTL_CFG:-config/ftl}"
HELP_DIR="$FTL_CFG/etc/help"
INDEX="$HELP_DIR/index.tsv"
CACHE="$HELP_DIR/cache"

mkdir -p "$CACHE"
: > "$INDEX"

# 1. Extract bindings from the man page and binding files
# ... (calls to extract_marker, awk on binding files)

# 2. Extract config variables from ftlrc
# ...

# 3. Extract module info from module headers
# ...

# 4. Extract concept pages from mdBook
# ...

# 5. For each topic, render the snippet to plain text and cache it
while IFS=$'\t' read -r topic source location; do
    render_topic "$topic" "$source" "$location" > "$CACHE/$topic.txt"
    echo -e "$topic\t$source\t$location" >> "$INDEX"
done < <(collect_all_topics)

echo "Built help index: $INDEX ($(wc -l < "$INDEX") topics)"
```

### 9.2 When to run the build

- **Before every release.** The release process includes running
  `scripts/build-help-index.sh` and committing the result.
- **After documentation changes.** Developers run it manually after
  editing the man page or mdBook, and commit the updated index.
- **Never at ftl startup.** The index is static; ftl reads it, it
  does not build it.

### 9.3 CI check

A CI step verifies that the checked-in index is up to date:

```bash
scripts/build-help-index.sh --dry-run
git diff --exit-code config/ftl/etc/help/
```

If the diff is non-empty, the CI fails with "help index is stale;
run scripts/build-help-index.sh and commit."

---

## 10. File Layout

```
config/ftl/etc/
├── bin/
│   ├── ftl                  ← entry point (modified: -h interception)
│   └── ftl-help             ← NEW: the help renderer
├── help/                    ← NEW: the help system
│   ├── short.md             ← curated short help (standalone)
│   ├── index.tsv            ← topic → source location mapping
│   └── cache/               ← pre-rendered topic snippets
│       ├── binding:LEADER-r-i.txt
│       ├── binding:j.txt
│       ├── command:rename.txt
│       ├── config:ftl_cfg_leader_key.txt
│       ├── module:keyboard.txt
│       ├── concept:preview.txt
│       └── ... (one per topic)
├── man/
│   └── ftl.md               ← man page (modified: HELP markers added)
├── core/modules/
│   └── *.sh                 ← module headers (unchanged structure)
└── ftlrc                    ← config (modified: comment convention)

scripts/
└── build-help-index.sh      ← NEW: the build script

docs/src/
├── SUMMARY.md               ← mdBook (unchanged)
└── **/*.md                  ← mdBook pages (modified: frontmatter added)
```

---

## 11. The Help Renderer

`config/ftl/etc/bin/ftl-help` is a standalone Bash script. It does
**not** source `ftl_setup` or any core modules. This ensures it is
fast and works outside tmux.

### 11.1 Structure

```bash
#!/usr/bin/env bash
# ftl-help — the help renderer for ftl
#
# Invoked by ftl when -h is passed. Can also be called directly.
# Does not require tmux. Does not source ftl's core modules.

FTL_CFG="${FTL_CFG:-$HOME/.config/ftl}"
HELP_DIR="$FTL_CFG/etc/help"

# Color detection
if [[ -t 1 ]]; then
    BOLD=$'\e[1m'; RESET=$'\e[0m'
else
    BOLD=''; RESET=''
fi

# Parse arguments
mode="short"
topic=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) mode="short" ; shift ;;
        full)      mode="full" ; shift ;;
        detailed)  mode="detailed" ; shift ;;
        *)         mode="topic"; topic="$1"; shift ;;
    esac
done

case "$mode" in
    short)
        cat "$HELP_DIR/short.md"
        ;;
    full)
        # Render the man page as text
        render_markdown_to_text "$FTL_CFG/man/ftl.md"
        ;;
    detailed)
        # Concatenate all mdBook pages in reading order
        render_mdbook_to_text "$FTL_CFG/../../docs/src/SUMMARY.md"
        ;;
    topic)
        render_topic "$topic"
        ;;
esac
```

### 11.2 Markdown-to-text rendering

The renderer converts Markdown to plain text with minimal formatting:

- `**bold**` → ANSI bold (if terminal)
- `*italic*` → ANSI underline
- `` `code` `` → kept as-is (or ANSI dim)
- `## Heading` → uppercase + underline
- `### Subheading` → bold
- Tables → text tables (columns aligned with spaces)
- Code blocks → indented 4 spaces
- Links `[text](url)` → `text (url)`
- Images `![alt](src)` → `[image: alt]`
- HTML comments (`<!-- ... -->`) → stripped

This is a ~100-line Bash function using `sed` and `awk`. It does not
need to be a perfect Markdown renderer; it needs to be readable.

### 11.3 Topic rendering

```bash
render_topic() {
    local topic="$1"
    local normalized
    normalized=$(normalize_topic "$topic")

    # Look up in the index
    local entry
    entry=$(grep -m1 "^$normalized	" "$HELP_DIR/index.tsv" 2>/dev/null)

    if [[ -z "$entry" ]]; then
        echo "ftl: help topic '$topic' not found"
        echo ""
        echo "Similar topics:"
        suggest_similar_topics "$normalized" | head -10
        return 0
    fi

    local t source location
    IFS=$'\t' read -r t source location <<< "$entry"

    # Output the cached snippet
    cat "$HELP_DIR/cache/$t.txt"
}
```

### 11.4 Topic normalization

```bash
normalize_topic() {
    local t="$1"
    # Lowercase
    t="${t,,}"
    # Replace _ and space with -
    t="${t//_/-}"
    t="${t// /-}"
    # Strip leading/trailing hyphens
    t="${t#-}"; t="${t%-}"
    # Collapse multiple hyphens
    while [[ "$t" == *--* ]]; do t="${t//--/-}"; done
    # Prefix with category if not present
    if [[ "$t" == LEADER-* || "$t" =~ ^[a-z]$ ]]; then
        t="binding:$t"
    elif [[ "$t" == ftl_cfg_* ]]; then
        t="config:${t//_/-}"  # ftl-cfg-leader-key
        t="config:${t#config:ftl-cfg-}"
        t="config:ftl_cfg_${t#config:}"
    fi
    echo "$t"
}
```

---

## 12. Topic Index

The index (`config/ftl/etc/help/index.tsv`) is a tab-separated file
with one topic per line:

```
<topic_id>\t<source>\t<location>\t<cache_file>
```

### 12.1 Topic IDs

Topic IDs are namespaced:

- `binding:<key>` — e.g. `binding:LEADER-r-i`, `binding:j`, `binding:xd`
- `command:<name>` — e.g. `command:rename`, `command:cursor-down`
- `config:<var>` — e.g. `config:ftl_cfg_leader_key`
- `module:<name>` — e.g. `module:keyboard`, `module:list`
- `concept:<name>` — e.g. `concept:preview`, `concept:selection`
- `plugin:<name>` — e.g. `plugin:incremental-search`, `plugin:missing-functionalities`
- `section:<name>` — e.g. `section:file-operations` (man page sections)

### 12.2 Example index entries

```
binding:LEADER-r-i	man:ftl.md:296:50	cache/binding:LEADER-r-i.txt
binding:j	man:ftl.md:139:2	cache/binding:j.txt
binding:xd	man:ftl.md:358:1	cache/binding:xd.txt
command:rename	commands.sh:858:1	cache/command:rename.txt
command:cursor-down	commands.sh:143:5	cache/command:cursor-down.txt
config:ftl_cfg_leader_key	ftlrc:267:1	cache/config:ftl_cfg_leader_key.txt
module:keyboard	maintenance/03-modules.md:keyboard	cache/module:keyboard.txt
concept:preview	docs/src/user-guide/preview.md:1:10	cache/concept:preview.txt
plugin:incremental-search	etc/bindings/incremental_search:1:30	cache/plugin:incremental-search.txt
section:file-operations	man:ftl.md:263:35	cache/section:file-operations.txt
```

### 12.3 Index size estimate

- ~150 bindings (from the binding tables + binding files)
- ~390 commands (from `commands.sh`)
- ~50 config variables (from `ftlrc`)
- 17 modules
- ~30 concepts (mdBook pages)
- ~20 plugins
- ~20 man page sections

Total: ~680 topics. The index file is ~680 lines, ~50KB. The cache
directory has ~680 files, totaling ~500KB. This is small enough to
ship with ftl.

---

## 13. Runtime Behavior

### 13.1 ftl entry point modification

The `ftl` entry point (`config/ftl/etc/bin/ftl`) is modified to
intercept `-h` before the tmux check:

```bash
#!/bin/env bash
# ftl — terminal file manager, with live previews, hyperorthodox

# Handle -h / --help BEFORE the tmux check
case "${1:-}" in
    -h|--help)
        shift
        exec "$FTL_CFG/etc/bin/ftl-help" "$@"
        ;;
esac

# Run only inside tmux (existing check)
if [[ -z "$TMUX" ]] ; then
    echo 'ftl: run me in tmux'
    exit 1
fi

# ... rest of ftl unchanged ...
```

### 13.2 Performance

- `ftl -h` (short): reads `short.md` and prints it. ~5ms.
- `ftl -h full`: reads `ftl.md`, renders to text, prints. ~50ms (the
  man page is ~750 lines; the renderer is fast).
- `ftl -h detailed`: reads all mdBook pages, renders, concatenates,
  prints. ~200ms (5000 lines). Acceptable; users will pipe to `less`.
- `ftl -h <topic>`: reads the index, looks up the topic, reads one
  cache file, prints. ~10ms.

All times are well under the 100ms target.

### 13.3 No tmux dependency

`ftl-help` does not source `ftl_setup`, does not call any `ftl::*`
function, and does not require tmux. It is a standalone script that
reads files and prints text. This means:

- `ftl -h` works in a plain terminal (no tmux).
- `ftl -h` works in a CI environment.
- `ftl -h` works even if ftl's core modules are broken (useful for
  debugging).

---

## 14. Integration with ftl's `:` Prompt

Inside ftl, the `:` command prompt can also dispatch to the help
system:

```
:help              # same as ftl -h full (opens in a tmux popup)
:help <topic>      # same as ftl -h <topic> (opens in a tmux popup)
:help detailed     # opens the full mdBook in a tmux popup with less
```

This is implemented as a command (`config/ftl/etc/commands/help`):

```bash
# config/ftl/etc/commands/help
# Invoke the help renderer in a tmux popup

topic="${1:-full}"
tmux popup -h 80% -w 80% "$FTL_CFG/etc/bin/ftl-help '$topic' | less -R"
```

This gives users interactive help (with scrolling and search via
`less`) without leaving ftl.

---

## 15. Caching Strategy

### 15.1 Build-time cache

The cache directory (`config/ftl/etc/help/cache/`) is populated at
build time by `scripts/build-help-index.sh`. Each topic has a
pre-rendered text file. This is the primary cache.

### 15.2 Runtime cache

No runtime cache is needed. The build-time cache is sufficient
because:

- The index is static (does not change between releases).
- Reading a file is fast (~1ms per file).
- The user's `~/.config/ftl/etc/help/` may differ from the system
  install (if they customized), but that's fine — the index reflects
  their install.

### 15.3 Cache invalidation

The cache is invalidated by re-running the build script. The CI check
(§9.3) ensures the cache is always up to date in the repository.

For users who install ftl from source and modify the docs, they can
run `scripts/build-help-index.sh` to rebuild the cache. For users who
install from a package, the cache ships with the package.

---

## 16. Internationalization Considerations

The help system is English-only for now. Future i18n would require:

- Translated man page and mdBook (a large effort).
- Per-language index and cache.
- A `--lang` flag on `ftl-help`.

This is out of scope for the initial implementation.

---

## 17. Testing Strategy

### 17.1 Build script tests

Test that `build-help-index.sh` produces a valid index:

```bash
test_help_index_has_entries() {
    scripts/build-help-index.sh
    [[ -s config/ftl/etc/help/index.tsv ]]
    local count=$(wc -l < config/ftl/etc/help/index.tsv)
    (( count > 100 ))  # at least 100 topics
}

test_help_index_is_sorted() {
    scripts/build-help-index.sh
    local sorted=$(sort config/ftl/etc/help/index.tsv)
    [[ "$sorted" == "$(cat config/ftl/etc/help/index.tsv)" ]]
}
```

### 17.2 Renderer tests

Test that `ftl-help` produces correct output:

```bash
test_help_short() {
    local out=$("$FTL_CFG/etc/bin/ftl-help")
    [[ "$out" == *"ftl — terminal file manager"* ]]
    [[ "$out" == *"Usage:"* ]]
}

test_help_topic_binding() {
    local out=$("$FTL_CFG/etc/bin/ftl-help" LEADER-r-i)
    [[ "$out" == *"LEADER r i"* ]]
    [[ "$out" == *"inline rename"* ]]
}

test_help_topic_not_found() {
    local out=$("$FTL_CFG/etc/bin/ftl-help" nonexistent-topic 2>&1)
    [[ "$out" == *"not found"* ]]
    [[ "$out" == *"Similar topics"* ]]
}

test_help_works_without_tmux() {
    unset TMUX
    "$FTL_CFG/etc/bin/ftl-help" -h >/dev/null 2>&1
    # Should not fail
}
```

### 17.3 Integration tests

Test that `ftl -h` works end to end:

```bash
test_ftl_h_short() {
    local out=$(ftl -h 2>&1)
    [[ "$out" == *"Usage:"* ]]
}

test_ftl_h_full() {
    local out=$(ftl -h full 2>&1)
    [[ "$out" == *"Key Bindings"* ]]
}

test_ftl_h_topic() {
    local out=$(ftl -h j 2>&1)
    [[ "$out" == *"cursor"* ]]
}
```

### 17.4 CI staleness check

```bash
test_help_index_not_stale() {
    cp config/ftl/etc/help/index.tsv /tmp/index-before.tsv
    scripts/build-help-index.sh
    diff /tmp/index-before.tsv config/ftl/etc/help/index.tsv
    # No diff = pass
}
```

---

## 18. Migration Path

### 18.1 Phase 1: Minimal viable help

- Add `-h` interception to `bin/ftl`.
- Create `ftl-help` with short help only.
- No index, no cache, no extraction.

**Result:** `ftl -h` prints the short help. `ftl -h full` and
`ftl -h <topic>` are not yet supported (print "not implemented").

### 18.2 Phase 2: Full help

- Add Markdown-to-text rendering.
- `ftl -h full` renders the man page.

**Result:** Short and full help work.

### 18.3 Phase 3: Topic help

- Add HELP markers to the man page.
- Write `build-help-index.sh`.
- Build the index and cache.
- Implement topic lookup in `ftl-help`.

**Result:** `ftl -h <topic>` works for bindings, commands, and
sections.

### 18.4 Phase 4: Detailed help + mdBook integration

- Add frontmatter to mdBook pages.
- Extend the build script to extract concept topics.
- Implement `ftl -h detailed` (concatenate mdBook).

**Result:** All three levels and topic help work.

### 18.5 Phase 5: `:help` command

- Add the `:help` command to ftl.
- Opens help in a tmux popup.

**Result:** Help is accessible from inside ftl.

---

## 19. Open Questions

These are design decisions that should be confirmed before
implementation.

### 19.1 Should `ftl -h detailed` dump everything, or open a pager?

**Current proposal:** Dump to stdout. The user pipes to `less`.

**Alternative:** Auto-pipe to `less` if stdout is a terminal.

**Recommendation:** Dump to stdout. Consistent with Unix conventions.
Users who want a pager pipe to `less`. The `:help detailed` command
(inside ftl) opens a pager automatically.

### 19.2 Should the topic index include partial matches?

**Current proposal:** Exact match (after normalization) only. If not
found, suggest similar topics.

**Alternative:** Prefix match. `ftl -h rename` matches
`command:rename`, `command:rename-selection`, `binding:R`,
`section:inline-rename-mode`.

**Recommendation:** Prefix match with disambiguation. If multiple
topics match, list them and ask the user to be more specific.

### 19.3 Should the help system support fuzzy matching?

**Current proposal:** No. Exact or prefix match only.

**Alternative:** Fuzzy match (like fzf).

**Recommendation:** No. Fuzzy matching is for interactive use; the
help system is a quick lookup. Users who want fuzzy search should use
`:help` (inside ftl) which can open fzf.

### 19.4 Should the cache be human-readable?

**Current proposal:** Yes. The cache files are plain text with ANSI
escapes.

**Alternative:** Binary format (smaller, faster).

**Recommendation:** Plain text. Easier to debug, easier to diff, and
the size difference is negligible (~500KB total).

### 19.5 Should `ftl -h` work without `FTL_CFG` set?

**Current proposal:** No. `ftl-help` uses `FTL_CFG` to find the help
files.

**Alternative:** Fall back to a compiled-in default path.

**Recommendation:** Fall back. `ftl-help` should have a compiled-in
default (`/usr/share/ftl/help/` or similar) for system installs.
`FTL_CFG` overrides for development.

### 19.6 Should the build script be Bash or a "real" language?

**Current proposal:** Bash. Consistent with the rest of ftl.

**Alternative:** Python or Node.js (better Markdown parsing).

**Recommendation:** Bash with `awk`/`sed`. The Markdown subset ftl
uses is simple enough. A Python dependency for the build step is
acceptable but adds a dependency. Bash keeps the build self-contained.

### 19.7 Should the man page markers be HTML comments or a different syntax?

**Current proposal:** HTML comments (`<!-- HELP:... -->`). They are
invisible in the rendered man page and mdBook.

**Alternative:** A custom syntax (e.g. `!!! HELP:binding:LEADER-r-i`).

**Recommendation:** HTML comments. They are standard in Markdown for
metadata, invisible in rendering, and do not require parser changes.

---

## 20. Implementation Phases

(Summary of §18, with estimated effort.)

| Phase | Scope | Effort | Result |
|-------|-------|--------|--------|
| 1 | `-h` interception, short help | 1 day | `ftl -h` works |
| 2 | Markdown-to-text renderer, `full` | 2 days | `ftl -h full` works |
| 3 | HELP markers, build script, topic index, `topic` | 4 days | `ftl -h <topic>` works |
| 4 | mdBook frontmatter, `detailed` | 2 days | `ftl -h detailed` works |
| 5 | `:help` command | 1 day | In-ftl help works |
| **Total** | | **~10 days** | **Complete help system** |

Each phase is independently shippable. Phase 1 alone is useful;
phases 2–5 add depth.

---

## Appendix A: Sample Help Output

### `ftl -h` (short)

```
ftl — terminal file manager, with live previews, hyperorthodox

Usage: ftl [-f filter] [-s file] [-t file] [directory[/file]]

Options:
  -f <filter>    Load an external filter plugin at startup
  -s <file>      Pre-select paths from file (one per line)
  -t <file>      Open paths in separate tabs (one per line)
  -h [topic]     Show help (short, full, detailed, or topic-specific)
  directory      Initial directory (or file to select)

Quick start:
  ftl                  # open in current directory
  ftl ~/projects       # open in a directory

Inside ftl:
  j/k  move down/up    h/l  parent/child
  SPACE tag entry      q    quit
  :    command prompt  ?    show help (man page)

Learn more:
  ftl -h full       # complete help
  ftl -h detailed   # full documentation
  ftl -h <topic>    # help for a specific topic
```

### `ftl -h LEADER-r-i` (topic)

```
Binding: LEADER r i
Command: ftl::plugin::inline_rename::enter
Description: enter inline rename mode

Inline rename mode is a modal, two-level workflow for renaming files.
It is entered with LEADER r i and exited with Escape or q.

Outer mode (navigation + dispatch):
  j/k       move cursor
  Return    edit current entry's name (pre-filled)
  r         sequential rename
  R         regexp rename
  l         edit EXIF label (images)
  Escape    exit mode

Inner mode (per-entry text editing):
  printable append to draft
  Backspace delete last char
  Return    commit (mv)
  Escape    abort
  TAB       commit and advance to next entry

See also:
  ftl -h detailed  (full documentation)
  docs/src/user-guide/inline-rename.md
```

### `ftl -h j` (topic)

```
Binding: j
Command: ftl::cmd::cursor_down
Description: move cursor down one entry

Moves the cursor down by one entry. If the cursor is at the bottom of
the visible window, the window scrolls. At the last entry, the cursor
stays.

Count prefix: 3j moves down 3 entries.

See also:
  ftl -h k          (move up)
  ftl -h cursor-down (command details)
```

---

## Appendix B: Relationship to Existing Documentation

| Existing doc | Help system use |
|--------------|-----------------|
| `config/ftl/man/ftl.md` | Source for `ftl -h full` and binding/section topics |
| `docs/src/**/*.md` | Source for `ftl -h detailed` and concept topics |
| `config/ftl/etc/ftlrc` | Source for config variable topics |
| `config/ftl/etc/core/modules/*.sh` | Source for module topics (header comments) |
| `config/ftl/etc/bindings/*`, `config/ftl/bindings/*` | Source for plugin topics |
| `documentation/maintenance/03-modules.md` | Cross-referenced from module topics |
| `documentation/ftl-ftlrc-reference.md` | Cross-referenced from config topics |

The help system does not duplicate this content; it extracts and
renders it. When the source changes, the build script regenerates the
index and cache.

---

*This document is a design proposal. Implementation should not begin
until the design is reviewed and approved. The open questions in §19
should be resolved first.*
