# Terminal File Managers: A Comparative Analysis

> **Subject:** A feature-by-feature comparison of the 10 most popular
> terminal file managers for Linux, with ftl as the reference point.
> **Purpose:** Inform users evaluating ftl against alternatives, and
> identify feature gaps for the ftl roadmap.
> **Methodology:** Each file manager was evaluated against its official
> documentation, GitHub README, and ArchWiki page. Feature presence is
> marked as **Yes** (built-in or first-party plugin), **Plugin**
> (available via a community plugin requiring installation), **Partial**
> (limited or workaround), or **No** (not available).
> **Date:** July 2026.

---

## Table of Contents

1. [File Managers Surveyed](#1-file-managers-surveyed)
2. [Feature Matrix](#2-feature-matrix)
3. [Detailed Comparisons](#3-detailed-comparisons)
4. [Architectural Summary](#4-architectural-summary)
5. [Recommendations](#5-recommendations)

---

## 1. File Managers Surveyed

| # | Name | Language | First Released | License |
|---|------|----------|----------------|---------|
| 1 | **ftl** | Bash 5+ | 2020 | Artistic 2.0 / GPL 3.0 |
| 2 | **ranger** | Python | 2010 | GPL 3.0 |
| 3 | **vifm** | C | 2001 | GPL 2.0 |
| 4 | **lf** | Go | 2016 | MIT |
| 5 | **nnn** (n³) | C | 2017 | BSD 2-Clause |
| 6 | **yazi** | Rust | 2023 | MIT |
| 7 | **broot** | Rust | 2019 | MIT |
| 8 | **Midnight Commander** (mc) | C | 1994 | GPL 3.0 |
| 9 | **clifm** | C | 2020 | GPL 2.0 |
| 10 | **superfile** (spf) | Go | 2024 | MIT |

---

## 2. Feature Matrix

The following matrix compares the 10 file managers across 40 features
organized into 8 categories. Entries: **Yes** (built-in), **Plugin**
(community plugin required), **Partial** (limited), **No** (not
available).

### 2.1 Core Architecture

| Feature | ftl | ranger | vifm | lf | nnn | yazi | broot | mc | clifm | spf |
|---------|-----|--------|------|----|-----|------|-------|----|-------|-----|
| Implementation language | Bash | Python | C | Go | C | Rust | Rust | C | C | Go |
| Pane model | Process-per-pane (tmux) | Internal (curses) | Internal (curses) | Internal | Internal | Internal | Internal (single) | Internal (curses) | None (CLI) | Internal |
| Multi-pane | Yes (tmux split) | Yes | Yes | Yes | Yes (via tmux) | Yes | No | Yes | No | Yes |
| Tabs | Yes | Yes | Yes | Yes | Yes (contexts) | Yes | No | Yes | Yes (workspaces) | Yes |
| Mouse support | No | Yes | Yes | Yes | Partial | Yes | Yes | Yes | Partial | Yes |
| Async I/O | No (Bash) | No | Yes | Yes | Yes | Yes | Yes | No | Yes | Yes |

### 2.2 Preview System

| Feature | ftl | ranger | vifm | lf | nnn | yazi | broot | mc | clifm | spf |
|---------|-----|--------|------|----|-----|------|-------|----|-------|-----|
| Image preview | Yes (w3mimgdisplay) | Yes (w3mimgdisplay) | Yes (w3mimgdisplay) | Yes (überzug/w3m) | Yes (überzug) | Yes (built-in) | No | No | Yes | Yes |
| Video preview (first frame) | Yes (ffmpeg) | Plugin | No | Plugin | Plugin | Yes | No | No | No | Yes |
| PDF preview | Yes (mupdf) | Plugin | Plugin | Plugin | Plugin | Yes | No | No | No | Yes |
| Audio preview (metadata) | Yes (exiftool) | Plugin | No | No | No | Yes | No | No | No | Yes |
| Markdown rendered | Yes (glow) | Plugin | Plugin | Plugin | Plugin | Yes | No | No | No | Yes |
| Archive contents | Yes (tar/unzip) | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes |
| Code syntax highlight | Partial (via $PAGER) | Yes (highlight) | Plugin | Plugin | Plugin | Yes (bat) | Yes | No | Yes | Yes |
| Scrollable preview | Partial | Yes | Yes | Yes | Yes | Yes | Yes | No | No | Yes |
| Preview caching | Yes (generator cache) | No | No | No | No | Yes (pre-caching) | No | No | No | No |

### 2.3 Navigation

| Feature | ftl | ranger | vifm | lf | nnn | yazi | broot | mc | clifm | spf |
|---------|-----|--------|------|----|-----|------|-------|----|-------|-----|
| Vim-like keys | Yes | Yes | Yes | Yes | Partial | Yes | Yes | No | Partial | Yes |
| Leader key | Yes | No | No | No | No | No | No | No | No | No |
| Count prefix | Yes | Yes | Yes | Yes | No | No | No | No | No | No |
| Multi-key sequences | Yes | Yes | Yes | Yes | No | No | No | No | No | No |
| Sub-modes (incremental search, etc.) | Yes | Yes | Yes | No | No | No | No | No | No | No |
| Redo key | Yes | No | No | No | No | No | No | No | No | No |
| zoxide / autojump | No | Plugin | No | Plugin | Yes (plugin) | Plugin | No | No | Yes (built-in) | No |
| Frecency (built-in) | No | No | No | No | No | No | No | No | Yes | No |
| Directory tree view | No | Yes | Yes | No | No | No | Yes (core) | Yes | No | No |
| Two-pane (dual dir) | Yes (tmux) | Yes | Yes | Yes | Yes | Yes | No | Yes | No | Yes |
| Bookmark sidebar | No | No | Yes | No | Yes | No | Yes | Yes | Yes | No |

### 2.4 File Operations

| Feature | ftl | ranger | vifm | lf | nnn | yazi | broot | mc | clifm | spf |
|---------|-----|--------|------|----|-----|------|-------|----|-------|-----|
| Bulk rename | Yes (edir + inline) | Yes (bulkrename) | Yes (bulkrename) | Yes (bulkrename) | Yes (numrev) | Yes | Yes | No | Yes | No |
| Inline rename (modal) | Yes | No | No | No | No | No | No | No | No | No |
| Sequential numbered rename | Yes (inline mode) | No | No | No | Yes | No | No | No | No | No |
| Regexp rename | Yes (inline mode) | Plugin | Yes | Plugin | No | No | No | No | Yes | No |
| Trash / restore | Partial (via $ftl_cfg_delete_command) | Yes | Yes | Yes | Yes | Yes | No | Yes | Yes | Yes |
| Undo / redo | No | No | Yes | No | No | No | No | Yes | No | No |
| Secure delete (shred) | Yes | No | No | No | No | No | No | No | Yes | No |
| Duplicate / clone | Yes | No | No | No | No | No | No | No | No | No |
| Hard link | Yes | Yes | Yes | Yes | No | No | No | Yes | Yes | No |
| Checksums (SHA256) | Yes | No | No | No | No | No | No | No | Yes | No |
| Numeric chmod | Yes | No | Yes | No | No | No | No | Yes | Yes | No |

### 2.5 Selection

| Feature | ftl | ranger | vifm | lf | nnn | yazi | broot | mc | clifm | spf |
|---------|-----|--------|------|----|-----|------|-------|----|-------|-----|
| Selection classes (multiple) | Yes (4 classes) | No | Yes (registers) | No | No | No | No | No | Yes (tags) | No |
| Visual selection mode | Yes | Yes | Yes (visual) | Yes | No | Yes | Yes | Yes | Yes | Yes |
| Invert selection | Yes | Yes | Yes | Yes | No | Yes | No | Yes | Yes | Yes |
| Select by pattern | Yes | Yes | Yes | No | No | No | No | No | Yes | No |
| Select by size | Yes | No | No | No | No | No | No | No | No | No |
| Select by age | No (proposed) | No | No | No | No | No | No | No | No | No |
| Select by content (ripgrep) | No (proposed) | No | No | No | No | No | No | No | No | No |
| Persistent selection (save/load) | Yes | No | Yes (registers) | No | No | No | No | No | Yes | No |
| Set operations (union/intersect/subtract) | Yes | No | Yes (registers) | No | No | No | No | No | No | No |

### 2.6 Search

| Feature | ftl | ranger | vifm | lf | nnn | yazi | broot | mc | clifm | spf |
|---------|-----|--------|------|----|-----|------|-------|----|-------|-----|
| Incremental filename search | Yes | Yes | Yes | Yes | Yes | Yes | Yes (fuzzy) | No | Yes | Yes |
| Fuzzy file finder (fzf) | Yes | Plugin | Plugin | Plugin | Plugin | Plugin | Yes (core) | No | Yes | Yes |
| Content search (ripgrep) | Yes | Yes (grep) | Yes (grep) | Plugin | Plugin | Plugin | Yes | Yes (grep) | Yes | No |
| Search & replace across files | Yes | No | No | No | No | No | No | No | No | No |
| Search history | Yes | No | Yes | No | No | No | Yes | No | Yes | No |
| Duplicate file finder | No (proposed) | No | No | No | Plugin | No | No | No | No | No |

### 2.7 Extension / Plugin System

| Feature | ftl | ranger | vifm | lf | nnn | yazi | broot | mc | clifm | spf |
|---------|-----|--------|------|----|-----|------|-------|----|-------|-----|
| Plugin system | Yes (6 categories) | Yes (Python) | Yes (Lua + commands) | Yes (shell) | Yes (shell scripts) | Yes (Lua) | No | No | Yes (plugins) | Yes (Lua) |
| Extension language | Bash | Python | Lua / VimL | Shell | Any (shell) | Lua | N/A | N/A | Any (shell) | Lua |
| Live reload (no restart) | Yes | No | Yes | Yes | Yes | Yes | N/A | No | Yes | No |
| Package manager | No | Yes (ranger-plug) | No | No | Yes (nnn plugins repo) | Yes (ya pkg) | No | No | No | No |
| File type icons (devicons) | No (proposed) | Plugin | Plugin | Plugin | Plugin | Yes | Yes | No | Yes | Yes |

### 2.8 Integration

| Feature | ftl | ranger | vifm | lf | nnn | yazi | broot | mc | clifm | spf |
|---------|-----|--------|------|----|-----|------|-------|----|-------|-----|
| Git status display | Yes (etag) | Plugin | Plugin | Plugin | Plugin | Plugin | Yes | No | Yes | Yes |
| Git blame/log/diff | Yes | No | No | No | No | No | No | No | No | Partial |
| Shell pane (real bash) | Yes | No | Yes (terminal) | No | Yes (via shell) | No | No | Yes | Yes (it is the shell) | No |
| Vim/nvim integration | Yes (ftll/cdf) | Yes (ranger.nvim) | Yes (vifm.nvim) | Yes (lf.nvim) | Yes (nnn.nvim) | Yes (yazi.nvim) | Yes (broot.nvim) | No | No | No |
| TMSU tagging | Yes | No | No | No | No | No | No | No | No | No |
| Cloud storage (rclone) | No (proposed) | No | No | No | No | No | No | No | No | No |
| Remote (SFTP/SSHFS) | No (proposed) | No | No | No | No | No | No | Yes (SFTP/FISH) | No | No |

---

## 3. Detailed Comparisons

### 3.1 ftl vs. ranger

**ranger** is the most established terminal file manager (Python, 2010).
ftl and ranger share the vim-like keybinding philosophy and the
three-pane model (listing + preview).

| Dimension | ftl | ranger |
|-----------|-----|--------|
| Implementation | Bash 5+ | Python |
| Extension language | Bash | Python |
| Preview rendering | Real programs in tmux panes | Internal preview pipeline |
| Pane model | Independent processes (tmux) | Internal (curses) |
| Selection classes | 4 | 1 (registers serve a similar role) |
| Inline rename mode | Yes (modal) | No |
| Plugin count | ~20 shipped | ~50 community (ranger-awesome) |
| Mouse support | No | Yes |
| Async I/O | No | No |
| Startup speed | Fast (Bash) | Slow (Python import overhead) |

**ftl advantages:** real-program previews (no reimplementation), inline
rename mode, selection classes, TMSU integration, leader key + count
prefix + multi-key sequences, shell pane as a real bash.

**ranger advantages:** larger plugin ecosystem, mouse support, async
preview (Python threads), wider community documentation.

### 3.2 ftl vs. vifm

**vifm** is a C-based, vim-like file manager with a long history
(since 2001). It is the most vim-faithful file manager.

| Dimension | ftl | vifm |
|-----------|-----|------|
| Implementation | Bash 5+ | C |
| Vim fidelity | High (leader, count, sequences) | Very high (modes, registers, commands, vimL config) |
| Configuration | Bash (ftlrc) | VimL (vifmrc) |
| Extension language | Bash | Lua / VimL |
| Two-pane | Via tmux split | Built-in (native) |
| Undo/redo | No (proposed) | Yes |
| Directory tree comparison | No | Yes |
| FUSE support | No | Yes |

**ftl advantages:** real-program previews, leader key, TMSU, shell pane,
simpler config (Bash vs. VimL).

**vifm advantages:** native two-pane (no tmux dependency), undo/redo,
FUSE support, directory tree comparison, vim register system, faster
(C vs. Bash).

### 3.3 ftl vs. lf

**lf** is a Go-based file manager inspired by ranger. It is known for
its simplicity and server/client architecture (cut in one terminal,
paste in another).

| Dimension | ftl | lf |
|-----------|-----|----|
| Implementation | Bash 5+ | Go |
| Extension language | Bash | Shell |
| Server/client | No (panes sync via filesystem) | Yes (cut/paste across terminals) |
| Sixel image preview | No | Yes (via Überzug) |
| Configuration | Bash | Shell (lfrc) |
| Mouse support | No | Yes |

**ftl advantages:** real-program previews, leader key, selection
classes, TMSU, shell pane, inline rename mode, more extensive plugin
categories.

**lf advantages:** server/client (cross-terminal cut/paste), mouse
support, async I/O (Go), simpler config, faster on large directories.

### 3.4 ftl vs. nnn

**nnn** (n³) is a C-based, minimal file manager with a plugin system
that delegates to external scripts.

| Dimension | ftl | nnn |
|-----------|-----|-----|
| Implementation | Bash 5+ | C |
| Philosophy | Reuse (tmux, real programs) | Minimal core + plugin scripts |
| Plugin language | Bash | Any (shell scripts) |
| Plugin count | ~20 shipped | ~50 community |
| Startup speed | Fast | Very fast (C, minimal) |
| Memory footprint | Low (Bash) | Very low (C) |
| du analyzer | Yes (size_analysis) | Yes (built-in) |
| Batch rename | Yes (edir + inline) | Yes (numrev) |
| File picker mode | Yes (ftll/cdf) | Yes (-p flag) |

**ftl advantages:** real-program previews, leader key + count +
sequences, selection classes, TMSU, shell pane, inline rename mode.

**nnn advantages:** faster (C vs. Bash), larger plugin ecosystem,
lower memory footprint, file picker mode, broader platform support
(includes macOS, BSD, Windows/WSL).

### 3.5 ftl vs. yazi

**yazi** is a Rust-based file manager (2023) that has rapidly become
the most popular modern choice. It features async I/O, pre-caching,
and a Lua plugin system.

| Dimension | ftl | yazi |
|-----------|-----|------|
| Implementation | Bash 5+ | Rust |
| Async I/O | No | Yes (tokio) |
| Preview caching | Yes (generator cache) | Yes (pre-caching, async) |
| Plugin language | Bash | Lua |
| Package manager | No | Yes (ya pkg) |
| Sixel / Kitty image | No | Yes (multiple backends) |
| Configuration | Bash (ftlrc) | TOML (yazi.toml) |
| Mouse support | No | Yes |
| Tab naming | No (proposed) | Yes |
| Scrollable video preview | No | Yes |

**ftl advantages:** real-program previews (yazi reimplements preview
rendering), leader key + count + sequences, selection classes, TMSU,
shell pane as real bash, inline rename mode, simpler extension model
(Bash vs. Lua + package manager).

**yazi advantages:** async I/O (much faster on large directories),
pre-caching (instant preview), modern image protocols (Sixel, Kitty,
iTerm2), mouse support, tab naming, larger plugin ecosystem, package
manager, TOML config (more structured than Bash).

### 3.6 ftl vs. broot

**broot** is a Rust-based "tree view + fuzzy search" file manager. It
is fundamentally different from ftl: it shows a collapsible tree
rather than a flat listing.

| Dimension | ftl | broot |
|-----------|-----|-------|
| Listing model | Flat (single column) | Tree (collapsible) |
| Fuzzy search | Via fzf | Core feature (built-in) |
| Preview pane | Yes (real programs) | Yes |
| File operations | Yes | Yes |
| Extension language | Bash | N/A (no plugin system) |
| Configuration | Bash (ftlrc) | TOML (conf.toml) |
| Mouse support | No | Yes |

**ftl advantages:** flat listing (faster scanning of large dirs), real-
program previews, leader key, selection classes, TMSU, shell pane,
plugin system, inline rename mode.

**broot advantages:** tree view (better for understanding structure),
built-in fuzzy search (no fzf dependency), faster startup, mouse
support, simpler config.

### 3.7 ftl vs. Midnight Commander (mc)

**mc** is the oldest file manager in this comparison (1994, C). It is
a dual-pane orthodox file manager with a menu-driven UI.

| Dimension | ftl | mc |
|-----------|-----|----|
| UI model | Vim-like, single-pane + preview | Dual-pane, menu-driven |
| Keybindings | Vim-like | Functional keys (F1-F10), custom |
| Vim familiarity | High | Low |
| Remote (SFTP/FISH) | No (proposed) | Yes (built-in) |
| Extension language | Bash | No (internal) |
| Mouse support | No | Yes |
| Community size | Small | Very large (decades) |

**ftl advantages:** vim-like keys, real-program previews, plugin
system, leader key, selection classes, TMSU, shell pane, inline
rename, modern filter pipeline.

**mc advantages:** remote filesystem support (SFTP, FISH, SMB),
maturity/stability, mouse support, dual-pane as a first-class citizen,
virtual filesystems (VFS), larger user base.

### 3.8 ftl vs. clifm

**clifm** is a C-based, shell-like file manager. It sits on the command
line rather than using a curses UI — the user types commands, clifm
interprets them.

| Dimension | ftl | clifm |
|-----------|-----|-------|
| UI model | Curses (listing + preview) | Shell-like (command line) |
| Bookmarks | Yes (session marks) | Yes |
| File tags | Yes (TMSU + selection classes) | Yes (built-in) |
| Directory jumper | No (proposed) | Yes (built-in frecency) |
| Bulk rename | Yes (edir + inline) | Yes |
| Trash | Partial | Yes |
| Plugins | Yes (6 categories) | Yes |
| Autosuggestions | No | Yes |

**ftl advantages:** curses UI (visual listing), real-program previews,
leader key, selection classes, TMSU, shell pane, inline rename mode,
more extensive plugin categories.

**clifm advantages:** built-in frecency (no zoxide dependency), built-in
trash, autosuggestions, faster (C vs. Bash), shell-like paradigm
familiar to power users.

### 3.9 ftl vs. superfile (spf)

**superfile** is a Go-based, modern file manager (2024) with a focus on
UI polish: multiple panels, theming, and a processes panel for active
operations.

| Dimension | ftl | spf |
|-----------|-----|-----|
| Implementation | Bash 5+ | Go |
| Multi-panel | Via tmux split | Built-in (native) |
| Theming | No (proposed) | Yes (extensive) |
| Processes panel | No | Yes (shows active operations) |
| Clipboard panel | No | Yes |
| Plugin language | Bash | Lua |
| Mouse support | No | Yes |
| Configuration | Bash (ftlrc) | TOML |

**ftl advantages:** real-program previews, leader key, selection
classes, TMSU, shell pane, inline rename mode, larger plugin
ecosystem, more mature.

**spf advantages:** native multi-panel (no tmux), theming, processes
panel (visibility into long operations), async I/O (Go), mouse
support, modern UI polish, TOML config.

---

## 4. Architectural Summary

### 4.1 Implementation Language Trade-offs

| Language | Pros | Cons | Used by |
|----------|------|------|---------|
| **Bash** | No compilation; trivial extension; full Unix tool access | Slow (no async, no threads); `set -u` gotchas | ftl |
| **Python** | Rich ecosystem; threads; readable | Import overhead; dependency management | ranger |
| **C** | Fast; low memory; portable | Hard to extend; manual memory management | vifm, nnn, mc, clifm |
| **Go** | Fast; async (goroutines); single binary | Larger binary; less ubiquitous than C | lf, superfile |
| **Rust** | Fast; safe; async (tokio) | Steep learning curve; compile times | yazi, broot |

ftl's choice of Bash is unusual but deliberate: it lowers the barrier
to contribution (any shell user can extend ftl) at the cost of
performance (no async I/O, slower on large directories). The
hyperorthodox architecture mitigates this: each pane is a separate
process, so a slow operation in one pane does not block others.

### 4.2 Preview Architecture

| Approach | Used by | Pros | Cons |
|----------|---------|------|------|
| **Real programs in tmux panes** | ftl | No reimplementation; full program features; interruptible | Requires tmux; program startup overhead |
| **Internal preview pipeline** | ranger, vifm, lf, nnn, yazi, broot | Fast; consistent; no external dependencies | Reimplements rendering; limited to supported types |
| **No preview** | clifm (CLI-based) | Simplicity | No visual feedback |

ftl is the only file manager in this comparison that uses real
programs in real tmux panes for preview. This is the defining
architectural decision: it means ftl supports any file type for which
a CLI preview tool exists, without code changes, but it requires tmux
and pays the program startup cost on each preview switch.

### 4.3 Extension Model

| Model | Used by | Barrier to Entry | Power |
|-------|---------|------------------|-------|
| **Bash scripts (sourced)** | ftl | Very low | High (full ftl API access) |
| **Python plugins** | ranger | Low (Python knowledge) | High |
| **Lua plugins** | vifm, yazi, spf | Medium (Lua knowledge) | High |
| **Shell scripts (external)** | lf, nnn | Low | Medium (no direct API access) |
| **No plugin system** | broot, mc | N/A | N/A |

ftl and ranger have the lowest barrier to extension: ftl requires Bash
(which any Linux power user knows), ranger requires Python (which most
engineers know). Lua-based systems (vifm, yazi, spf) require learning
Lua, which is less commonly known.

---

## 5. Recommendations

### 5.1 For Users

| Use case | Recommended |
|----------|-------------|
| **Vim power user, wants real-program previews** | ftl |
| **Vim power user, wants native two-pane + undo/redo** | vifm |
| **Vim power user, wants the largest plugin ecosystem** | ranger |
| **Modern, fast, async, mouse-friendly** | yazi |
| **Minimal, fast, C-based, plugin-driven** | nnn |
| **Simple, Go-based, server/client (cross-terminal cut/paste)** | lf |
| **Tree view + fuzzy search** | broot |
| **Legacy dual-pane, remote filesystems** | mc |
| **Shell-like, command-line, frecency built-in** | clifm |
| **Modern UI polish, multi-panel, theming** | superfile |

### 5.2 For ftl Roadmap

Based on the feature matrix, the highest-impact gaps in ftl relative to
its peers are:

1. **Mouse support** — every competitor has it; ftl does not (§1.5 in
   `ftl-missing-functionality-v2.md`).
2. **Async I/O** — yazi, lf, nnn, vifm, spf all have async; ftl (Bash)
   does not. This affects large-directory performance.
3. **Undo/redo** — vifm and mc have it; ftl does not (§12.1).
4. **Native two-pane** — vifm, mc, spf have native two-pane; ftl
   requires tmux splits (which is flexible but not as seamless).
5. **File type icons (devicons)** — yazi, broot, clifm, spf have
   built-in; ftl needs a plugin (§1.1).
6. **zoxide / frecency integration** — clifm has built-in frecency;
   yazi, ranger, lf have zoxide plugins; ftl has neither (§2.1, §2.2).
7. **Scrollable preview** — ranger, vifm, lf, nnn, yazi, broot, spf
   all support scrolling within the preview pane; ftl's preview is
   static (the backend program handles its own scrolling, but ftl
   does not expose it uniformly).
8. **Tab naming** — vifm, yazi, spf support named tabs; ftl does not
   (§10.4).
9. **Remote filesystems** — mc has built-in SFTP/FISH/SMB; ftl has
   none (§8.2, §8.4).
10. **Modern image protocols** — yazi supports Sixel, Kitty, iTerm2
    image protocols; ftl relies on `w3mimgdisplay` (X11-dependent).

These gaps are addressed in `ftl-missing-functionality-v2.md` with 60
proposed features, of which approximately 15 directly close gaps
identified in this comparison.

### 5.3 ftl's Unique Strengths

Despite the gaps above, ftl has several features no competitor offers:

1. **Real-program previews in real tmux panes** — the hyperorthodox
   architecture. No other file manager delegates preview rendering to
   external programs running in real panes.
2. **Inline rename mode** — a modal workflow combining single, sequential,
   regexp, and image-label rename. No competitor has an equivalent.
3. **Selection classes (4 disjoint classes)** — vifm's registers serve
   a similar purpose but are less ergonomic.
4. **Leader key + count prefix + multi-key sequences + sub-modes** —
   ftl's keyboard engine is more expressive than any competitor's.
5. **Shell pane as a real `bash -i`** — mc and clifm have shell-like
   interfaces, but ftl's shell pane is a full independent shell process
   in a sibling tmux pane.
6. **42+ extended features (missing functionalities)** — duplicate,
   hardlink, checksums, chmod-numeric, git blame/log/diff, zip/7z, scp,
   wget, workspace save/load, command palette, etc. No competitor
   ships this many file operations out of the box.

These strengths make ftl the preferred choice for power users who
value integration (real programs, real shell), keyboard expressiveness
(leader + count + sequences + sub-modes), and operational breadth
(42+ file operations).

---

*This comparison is based on publicly available documentation as of
July 2026. Feature sets evolve; verify current capabilities before
making a deployment decision.*
