# A Reference Architecture for File Managers
### Ideas, research findings, and advanced capabilities for a state-of-the-art file management system

> Scope: file managers as a class of software — terminal and graphical, single-pane and
> multi-pane, local and networked. This document is organized around *ideas worth having*,
> grounded in human-computer-interaction research on how people actually organize and find
> files, in the systems-research lineage that treats "directory" as a special case of "query,"
> and in the architectural choices of real implementations old and new. It is deliberately
> language- and platform-agnostic; no implementation is prescribed.

---

## Table of contents

1. [Why this is a research problem, not just UI chrome](#1-why-this-is-a-research-problem-not-just-ui-chrome)
2. [Lineages worth learning from](#2-lineages-worth-learning-from)
3. [Design principles grounded in evidence](#3-design-principles-grounded-in-evidence)
4. [The core abstraction: everything is a queryable collection](#4-the-core-abstraction-everything-is-a-queryable-collection)
5. [The property system: files as bundles of attributes, not just bytes](#5-the-property-system-files-as-bundles-of-attributes-not-just-bytes)
6. [The provider layer: unifying local, remote, archived, and generated storage](#6-the-provider-layer-unifying-local-remote-archived-and-generated-storage)
7. [The async task engine](#7-the-async-task-engine)
8. [Rendering at scale: focus, context, and progressive disclosure](#8-rendering-at-scale-focus-context-and-progressive-disclosure)
9. [Unifying search, selection, and filtering](#9-unifying-search-selection-and-filtering)
10. [The command and macro layer](#10-the-command-and-macro-layer)
11. [Cross-instance and cross-pane state](#11-cross-instance-and-cross-pane-state)
12. [The extension model](#12-the-extension-model)
13. [Advanced capabilities worth building](#13-advanced-capabilities-worth-building)
14. [Lessons from a mature backlog: errors the architecture should design out](#14-lessons-from-a-mature-backlog-errors-the-architecture-should-design-out)
15. [References](#15-references)

---

## 1. Why this is a research problem, not just UI chrome

File management looks like a solved problem — copy, move, delete, rename, a tree, a list — and most file managers are built as if it were. It isn't. There is thirty-plus years of human-computer-interaction research specifically on how people organize and retrieve personal files, and its findings are not what most file-manager UIs assume:

- People do not primarily *search* for files — they **navigate** to them, using remembered location as the retrieval cue, and this is measurably true even when search is faster: in a controlled study, participants recalled significantly more items from a concurrent memory task when retrieving a file by navigation than by search, showing that navigation costs less cognitive attention even though search took nearly three times longer in wall-clock terms (Bergman, Tene-Rubinstein, & Shalom, 2013). A file manager optimized around a search box is optimizing for the mode people use less naturally.
- The dominant early study of how people organize desks — physical and, by extension, digital — found that a file's *location* often exists to remind the owner of something to do, not only to make the file findable later; disorganized "piles" are not a failure state but a legitimate, load-bearing strategy that automatic classification and rigid filing schemes actively work against (Malone, 1983).
- A pair of independent studies of DOS/Windows and Macintosh users converged on the same conclusions: people prefer location-based finding precisely because of its reminding function, they avoid elaborate filing schemes, they archive comparatively little, and the files they work with fall naturally into three states — ephemeral, working, and archived — that call for different treatment (Barreau & Nardi, 1995).
- A large-scale, more recent literature review of file-management research confirms this pattern still holds and catalogues how little mainstream file-manager design has absorbed it (Dinneen & Julien, 2019).

The implication for architecture is direct: **a file manager's information model should not be "one tree, browsed alphabetically, with a search box bolted on."** It should treat *recency, pinning, working sets, and location-as-memory* as first-class surfaces, not afterthoughts — and it should make "temporary, ungoverned collections of files that don't live in one directory" (Malone's "piles") a structurally supported concept, not a workaround.

---

## 2. Lineages worth learning from

Four distinct architectural lineages have each solved a piece of this problem well. None solved all of it; the best next design borrows the right idea from each rather than cloning any one of them.

### 2.1 The Orthodox Commander lineage

Norton Commander (1986) established the two-pane, keyboard-driven paradigm later called "orthodox file managers" (OFMs) — Midnight Commander, Far Manager, Total Commander, and, more recently, vi-influenced descendants like `ranger`, `vifm`, `lf`, and `nnn` (Bezroukov, ongoing). The lineage's durable architectural contributions:

- **A virtual file system (VFS) that makes non-directory things browsable as directories.** Midnight Commander's VFS lets a user `cd` into a `.tar.gz`, an FTP/SFTP host, or an archive and see its contents exactly like a real directory, with the same operations (view, copy, edit) applying uniformly. This is the single most important idea in the lineage: **the browsing surface and the storage backend are decoupled**, and the decoupling is total enough that the user cannot tell, from the navigation experience alone, whether they are inside a real directory, a compressed archive, or a remote host.
- **A distinct command-language layer.** Most OFMs conflate "keyboard shortcuts" with "the extensibility surface." A minority — Midnight Commander's user-menu macro system, and more fully `ranger`'s console (a typed command language with `map`/`cmap`/`chain`/`eval` and direct access to the running program's internals) — expose a real, typed command layer distinct from key bindings, which key bindings then merely invoke. This separation is what makes the system scriptable rather than merely configurable.
- **Context macro-variables exported to the shell.** Midnight Commander's user-menu macros (`%f` current file, `%d` current directory, `%t` tagged files, the equivalent pair for the *other* panel, `%D`/`%T`/`%F`) let any user-menu entry or any spawned shell command receive structured context about "what is selected, where, in which of the two panels" without the plugin author having to parse anything. This is a durable pattern: **export the browsing context as named variables to anything you spawn**, rather than requiring external tools to re-derive it.
- **Panelizing arbitrary command output.** Midnight Commander's "panelize" takes the output of any external command (as a list of paths) and displays it as if it were a directory listing — search results, `find` output, a custom script's output all become first-class, operable panels. This is the OFM lineage's version of "collections," discussed generally in §4.
- **A proposed but rarely fully realized "cutting edge" standard** for the lineage (Bezroukov, 2012) explicitly calls for unifying three historically separate mechanisms — file search, file selection, and file filtering — into a single mechanism with different output targets, and for the ability to *save* a search and reopen it later as a live, re-runnable panel. Both ideas are still, individually, rare in shipping tools; combined, they are the seed of §9 below.

### 2.2 The GUI desktop-metaphor lineage

Apple's Finder, Windows Explorer, and the GNOME/KDE desktop file managers took a different path: the filesystem is presented through a **shell namespace** that is not restricted to real files at all. Windows Explorer's namespace includes virtual locations (Control Panel, "This PC," network neighborhoods) alongside real directories, using the same navigation and property-sheet UI for both. GNOME's Nautilus is built on **GVFS**, and KDE's Dolphin on **KIO**, both of which implement the same idea as Midnight Commander's VFS — archives, remote protocols (SFTP, SMB, WebDAV), and even non-filesystem sources (a camera, a phone via MTP) are exposed through one mount/provider abstraction and browsed identically to local disk. The architectural lesson from this lineage is the same as from §2.1, arrived at independently: **provider abstraction is not optional at scale** — every mature file manager, TUI or GUI, ends up building one.

### 2.3 The semantic/attribute-driven lineage

This is the systems-research lineage, and it is the most architecturally radical of the four, because it attacks the tree itself.

- **Semantic File Systems** (Gifford, Jouvelot, Sheldon, & O'Toole, 1991) proposed that a filesystem provide flexible associative access by automatically extracting key/value attributes from files using file-type-specific **transducers**, and — critically — introduced the **virtual directory**: a directory name is interpreted as a *query*, and what it "contains" is whatever currently matches that query, computed live, compatible with existing tree-structured filesystem protocols (they demonstrated it as an NFS-compatible layer). "Show me every file where `author=nadim` and `type=invoice` and `year=2025`" becomes a directory you can `cd` into, not a search you run and then discard.
- **Presto** (Dourish, Edwards, LaMarca, & Salisbury, 1999) generalized this into a full document system built around **uniform, attribute-based interaction**: every document (and every collection of documents) is manipulated through the same property-based interface regardless of its type or application, and applications can contribute **active properties** — computed, live attributes (e.g., an auto-generated summary) that behave exactly like stored ones from the interaction layer's point of view. Presto's authors explicitly found, from field studies underlying the related Placeless Documents work, that most users do not build deep, elaborate directory hierarchies — they prefer simple structures and rely on other cues (location, recency) to compensate — which is the systems-research echo of the Barreau & Nardi finding in §1.
- **Lifestreams** (Freeman & Gelernter, and Fertig, Freeman, & Gelernter, 1996) proposed replacing hierarchical location with a single chronological stream as the primary organizing axis, directly operationalizing the "reminding" function Malone identified — a file's position in time, not in a tree, is what makes it findable and keeps it visible.

The lesson for a modern architecture is not "throw away the tree" — Barreau & Nardi and Presto's own field data both show users still want and use simple hierarchies — but that **the tree should be one view over an attribute-indexed store, not the store itself.** A "virtual directory" backed by a live query, and a chronological/recency view backed by the same store, should be able to coexist with, and be built from, the same underlying data, and moving between them should be as cheap as changing a view, not migrating data.

### 2.4 The modern async-native TUI generation

The newest generation of terminal file managers — `yazi`, `broot`, `joshuto`, `xplr` — grew up assuming multi-core hardware and non-blocking I/O as a baseline, which older tools (including most of the OFM lineage) did not. `yazi`'s published account of its own performance design (sxyazi, 2023) is a useful concrete reference: it treats **every I/O and CPU-bound operation as an async task**, scheduled with real-time progress reporting and cancellation; it renders large directories via **chunked loading** rather than requiring the full listing before the first entry appears (something plain `ls`-style tools structurally cannot do, since they must emit a complete, sorted list); it computes MIME types in batched pages rather than per-file to cut syscall overhead; and it uses a **two-pass image pipeline** — a cheap downscaled cache generated once, redisplayed at whatever size is needed at view time — to make preview switching fast without repeatedly re-decoding source media. Architecturally, `yazi` also folds cross-instance and cross-pane communication into a **client-server model with no separate server process to manage** plus a **publish/subscribe data-distribution layer**, which is the same problem the Orthodox Commander lineage historically solved with much weaker primitives (single-character terminal-multiplexer signals, polled shared files) — the modern generation simply built a proper message bus instead.

---

## 3. Design principles grounded in evidence

Distilled from §1–§2, five principles that should shape every subsequent architectural decision in this document:

1. **Navigation is the primary retrieval mode; search is secondary and should feed navigation, not replace it.** Every search result, every filter, every query should be capable of becoming a *browsable place* (a virtual directory, a saved collection) rather than a one-shot answer the user has to re-derive next time (Bergman et al., 2013; Bezroukov's "store searches and invoke a panel with their results," 2012).
2. **Support piling as a first-class alternative to filing.** Working sets, ad-hoc groupings, and "everything I touched recently" views are not lesser versions of a proper directory structure — they are how most people actually work, and the architecture should make constructing and dissolving them cheap (Malone, 1983; Barreau & Nardi, 1995).
3. **Location is memory; keep it stable and meaningful.** Cursor position, scroll offset, and "where things are" should persist per-directory and be restored precisely — moving a frequently-visited item to a different visual position between sessions has a real cognitive cost (Jones & Dumais, 1986, on the spatial metaphor for interface reference).
4. **Overview first, then zoom/filter, then details on demand** (Shneiderman, 1996) — the interaction pattern that underlies almost every good large-data browsing tool applies directly to a directory of 200,000 files: show a fast, low-detail overview immediately, let filtering narrow it, and defer expensive per-item detail (thumbnails, full metadata) until the user's attention actually lands on an item.
5. **When a structure is too large to show in full, degrade gracefully by importance, not by truncation.** Furnas's **generalized fisheye view** (1986) formalizes this as a Degree-of-Interest function trading off a priori importance against distance from the current focus — directly applicable to tree views, to very large flat directories, and to "how much of the directory hierarchy above/below the cursor should be visible" (the technique `broot` uses, in practice, for its pruned tree view).

---

## 4. The core abstraction: everything is a queryable collection

The single highest-leverage architectural decision available to a new file manager is to **generalize "directory" into "collection"** and build the entire listing/filter/select/render pipeline against that one abstraction, rather than against "the current directory's contents."

A **collection** is any named, orderable, filterable set of entries, regardless of source:

- a real directory's contents (the default, trivial collection)
- the result of a recursive search or a content grep
- the files changed by a version-control commit, a range of commits, or the current working tree
- a saved or ad-hoc selection ("everything I tagged in the last ten minutes")
- the result of a semantic query over indexed attributes (§5) — Gifford's virtual directory, generalized
- a diff between two directories or two points in time
- the output of an arbitrary external command, in the spirit of Midnight Commander's panelize
- a chronological stream — "everything touched in the last 24 hours," directly implementing the Lifestreams/Malone reminding function as a standing view rather than a one-off query

Every collection supports the same operations — list, filter, sort, group, watch-for-changes, select-within — because they are implemented once, against the abstraction, not once per source type. This single change absorbs an enormous amount of otherwise-duplicated logic: a "search results" view, a "git-changed-files" view, and a "saved selection" view stop being three separate features built three separate times and become three ways of *constructing* the same kind of object.

Two properties every collection needs, learned directly from where ad-hoc implementations of this idea go wrong:

- **Provenance per entry.** When a collection blends heterogeneous sources — a virtual directory containing files from three different real directories, a commit's changed files mixed with the working tree's current version of them — each entry must carry *where it actually came from* and be able to display it, and sorting/grouping must offer "by original location" as an explicit option, not silently default to one behavior. A collection that hides provenance is unusable the moment it stops being homogeneous.
- **Liveness is a property of the collection, not a special case.** A directory listing is a live collection (it should react to filesystem change events); a search result may or may not be (does the user want it to re-run automatically, or to be a frozen snapshot they can return to?); a saved selection is deliberately not live once saved. Liveness should be a declared, per-collection flag the construction step sets, not something the rendering layer has to guess from the collection's type.

---

## 5. The property system: files as bundles of attributes, not just bytes

Directly generalizing Gifford et al.'s transducers and Presto's active properties: every entry in every collection should be a bundle of typed attributes, not a filename plus a formatted display string.

- **Intrinsic attributes** come for free from the storage provider (size, modification time, permissions, owner).
- **Extracted attributes** are computed by pluggable "transducer"-equivalents keyed by type: an image's dimensions, a document's page count, an audio file's tags, a source file's line count, a video's duration and codec. These should be cached and invalidated by content hash or mtime, never recomputed unconditionally.
- **Active/computed attributes** are live, not cached at all: a version-control status glyph, a "days since last modified," a "matches current search" boolean. These are recomputed on render, cheaply, by design — if computing one is expensive, it belongs in the previous category with a cache.
- **User attributes** are the free-form layer: tags, ratings, notes — the same kind of data tagging tools like TMSU or Tagsistant provide as a bolt-on, but here treated as just another attribute source feeding the same query engine that content-derived attributes feed.

The payoff for treating all four uniformly: **filtering, sorting, grouping, and column display are all just "operate on an attribute," regardless of which of the four categories the attribute came from.** A user should be able to sort by "git status" exactly the way they sort by "size," and group by "tag" exactly the way they group by "file extension," because from the query engine's point of view those are the same operation over different attribute keys. This is also what makes §4's semantic-query collections possible: a virtual directory defined by `type:image AND tag:vacation AND modified:<30d` is simply a saved predicate over this attribute space.

**Rendering must be a separate, swappable layer over this structured attribute set** — never a pre-formatted string baked in at scan time. The moment display formatting and data are fused, per-column sorting, per-column visibility toggling, and heterogeneous-source display (provenance, §4) all become expensive retrofits instead of features that fall out of the design for free.

---

## 6. The provider layer: unifying local, remote, archived, and generated storage

Every mature implementation across every lineage in §2 converges on the same answer here, arrived at independently at least three times (Midnight Commander's VFS, GVFS, KIO): **one provider interface, implemented per backend, consumed uniformly everywhere else.**

A provider implements a small, uniform contract — list entries, read, write, stat, watch-for-changes, and (where the backend permits) move/delete/create — for one kind of backend:

- local filesystem
- an archive format (tar, zip, 7z, rar, cpio, iso), presented exactly like a directory once "entered"
- a network protocol (SFTP, FTP, SMB, WebDAV, S3-compatible object storage)
- a version-control snapshot (browse a repository at an arbitrary commit as a read-only directory tree, without checking it out)
- a generated/synthetic source (the output of a running process, a database query result rendered as rows-as-files)

Everything above the provider layer — the collection abstraction, the property system, selection, rendering, plugins — talks only to this interface and never needs to know which backend it's actually looking at. The user experience this buys is the thing every OFM and every GUI file manager considers a headline feature once they have it: *you can `cd` into a zip file, or an SFTP host, or a specific git commit, and every operation (copy, search, tag, preview) just works, because from the rest of the system's point of view it's a directory.*

Two design details that determine whether this abstraction holds up under real use:

- **Watch-for-changes must degrade gracefully per backend**, not fail silently. A local filesystem can usually offer real change notifications (inotify/FSEvents/ReadDirectoryChangesW-equivalent); most remote and archive providers cannot, and should fall back to a declared polling interval rather than simply never refreshing — the failure mode of "the watcher is broken and nobody told the UI" is a recurring, user-visible bug class across real implementations and should be designed against from the start by making "how does this provider report changes" an explicit, required part of the provider contract (poll interval, event-based, or none-and-the-UI-shows-that).
- **Write operations across providers need an explicit conflict/capability model.** Not every provider supports every operation (you can't `chmod` inside a read-only archive view of a remote git commit); the UI needs to know this before the user tries, not after a cryptic failure.

---

## 7. The async task engine

Every long-running operation — a directory scan, a copy, a checksum, a search, a thumbnail generation — is a **task**: cancellable, priority-ranked, progress-reporting, and running off the interaction thread entirely. This is the specific lesson the modern async-native generation (§2.4) has already validated at scale: `yazi`'s explicit design goal of spreading CPU-bound work across threads and reporting real-time progress and supporting cancellation is precisely what makes a TUI file manager feel instantaneous on very large directories where an older, synchronous design would freeze.

Concretely, the engine needs:

- **A priority scheme**, so that "render what's on screen right now" always preempts "generate a thumbnail for something scrolled off screen" and "finish a background bulk copy."
- **Chunked/streaming delivery for scans**, so the first N entries of a 200,000-file directory render before the scan of the remaining entries completes — never "wait for the whole listing, then show it."
- **A uniform progress/cancellation contract** every task type implements, so the UI's "task manager" surface (a first-class feature, not a debug tool — see §13) works identically for a copy, a checksum run, or a plugin-defined long operation.
- **Two-pass generation for expensive previews** (a cheap, cached low-fidelity pass; a full-fidelity pass only on actual view), directly following the pattern that gives `yazi` fast preview switching without re-decoding source media on every cursor movement.

---

## 8. Rendering at scale: focus, context, and progressive disclosure

Apply Shneiderman's mantra (§3, principle 4) and Furnas's fisheye formalism (§3, principle 5) directly to directory/tree rendering, not just to data visualization:

- **Overview first**: the initial render of any collection should be cheap and immediate — names and the one or two attributes needed to orient the user — never blocked on computing every attribute for every entry.
- **Zoom and filter**: narrowing a collection (via the unified filter/search/select mechanism, §9) should re-render from already-fetched data wherever possible, not re-scan the source.
- **Details on demand**: expensive per-entry detail (a full preview, an extracted thumbnail, a computed checksum) is fetched only for the entry currently in focus (or imminently likely to be, via read-ahead one or two entries around the cursor) — never for the whole visible window eagerly, and never for the whole collection eagerly.
- **Degree-of-interest culling for large trees**: when rendering a tree (not just a flat list) that cannot fit on screen, assign each node a Furnas-style degree-of-interest score — combining "how important is this a priori" (e.g., directories over files, or a user-pinned path) with "how far is this from the current cursor" — and render the highest-scoring N nodes rather than truncating naively by depth or alphabetically. This is exactly the mechanism that lets a pruned, always-legible tree view stay useful on a codebase with tens of thousands of files, instead of either showing an unusable full tree or an arbitrarily truncated one.

---

## 9. Unifying search, selection, and filtering

The OFM lineage's own "cutting edge" proposal (§2.1) names this directly: file search, selection, and filtering have historically been three separate mechanisms with three separate UIs, when they are the same underlying operation — *evaluate a predicate against a collection* — with three different things done with the result:

| target | what happens to matches |
|---|---|
| **filter** | the current view narrows to just the matches, non-destructively (the full collection is still there, just hidden) |
| **select** | matches are added to the active selection, for a subsequent operation (copy, tag, delete) |
| **search / navigate** | the view jumps to the first (or next) match, without narrowing anything |

Building one query engine that can be invoked with any of these three targets — and, critically, that can be *saved and re-invoked later, as a named, re-runnable collection* (§4, and directly implementing Bezroukov's "store searches, invoke a temp panel with their results" proposal) — collapses what is usually three parallel, half-duplicated subsystems into one. The predicate language itself should operate over the property system (§5) uniformly: `size > 10MB`, `tag:invoice`, `git-status:modified`, `mtime < 7d`, and free-text content search are all just different attribute predicates to the same engine, composable with boolean operators.

---

## 10. The command and macro layer

Distinct from key bindings (which merely invoke commands), a real file manager needs a typed **command language** — the OFM lineage's most under-copied good idea (§2.1). Concretely:

- Every user-facing action is a **named command** with a documented signature, invocable three ways: via a bound key, via a typed command prompt, and programmatically (by a plugin, or by an external script). Key bindings are never the primary interface to functionality — they are one thin invocation path among several onto the same command.
- **Context variables are exported uniformly** wherever a command runs or a process is spawned: current entry, current directory, the full selection, the *other* pane's equivalents in a multi-pane layout, the active collection's query if any. This is Midnight Commander's `%f`/`%F`/`%d`/`%D`/`%t`/`%T` pattern, generalized: any spawned external tool, any plugin, any macro should receive this context as structured data (typed variables, not string interpolation into a shell command) rather than having to reconstruct it.
- **The command language should be a real, if small, scripting language** — expressions, conditionals, the ability to chain commands — rather than an ad-hoc micro-syntax invented for the file manager alone. Reusing an existing, well-specified embeddable language (rather than inventing a bespoke one) pays off specifically in the visibility-condition use case Midnight Commander pioneered and never fully generalized: a menu item or a binding should be able to declare *when it's even relevant* ("only when exactly one file is selected and it's a directory") as a real expression evaluated against context, hiding irrelevant actions from the user instead of presenting them and failing.

---

## 11. Cross-instance and cross-pane state

Any file manager with more than one simultaneous view of the world (multiple panes, multiple windows, multiple terminal instances sharing a selection) needs a way for those views to stay in sync. The right shape of this mechanism, validated by the modern generation (§2.4) after decades of weaker ad-hoc solutions in the older lineage:

- **A message bus with a publish/subscribe model**, not polling and not raw unstructured signals. State changes (selection changed, a collection's contents changed, a task completed) are published as typed, timestamped events; interested panes/instances subscribe to the events relevant to them.
- **No separate long-running server process to manage**, where avoidable — the first instance launched can transparently take on a coordinating role, and later instances discover and attach to it, rather than requiring the user to start and maintain infrastructure.
- **State that must survive a restart (not just cross a pane boundary) is persisted separately from the live bus** — a crash or restart should be able to recover the last-known session (open tabs, panes, active collections) from durable storage, not lose it because the bus itself doesn't persist.

---

## 12. The extension model

Generalizing across every lineage in §2 to the categories that recur regardless of implementation language or platform:

| category | responsibility | examples from real systems |
|---|---|---|
| **provider** | expose a backend as a collection source (§6) | archive formats, remote protocols, VCS snapshots |
| **property extractor** | compute attributes for a type of entry (§5) | image dimensions, audio tags, VCS status |
| **previewer** | render a rich view of one entry | image/video/PDF/markdown rendering |
| **action / command** | a named, invocable operation (§10) | bulk rename, checksum, archive extraction |
| **filter predicate** | a reusable term in the query language (§9) | "is duplicate of," "matches regex," custom tag queries |
| **UI surface** | a pluggable panel, status element, or view mode | a task manager panel, a git-blame side panel |

Two structural requirements, learned from where extension models across the surveyed lineages tend to fail in practice:

- **A declared manifest per extension** (what it provides, what category it's in, what it needs access to) checked at load time, so a broken or malicious extension fails loudly and specifically rather than silently corrupting shared state.
- **Capability scoping**: a property extractor should not need, and should not be granted, the ability to spawn arbitrary processes or mutate the selection; an action legitimately might need both. Declaring and enforcing this per category (not per individual extension, which is too fine-grained to be practical for most authors) gets most of the safety benefit of a full sandbox at a fraction of the implementation cost — and, as a secondary benefit, a well-typed manifest is exactly the metadata a **package manager for extensions** (which the modern generation, §2.4, now treats as a baseline expectation rather than a luxury) needs to install, update, and pin versions of third-party extensions safely.

---

## 13. Advanced capabilities worth building

Capabilities that follow naturally from the architecture in §4–§12, listed because most shipping file managers — TUI or GUI — still lack most of them, despite the underlying research and prior art being decades old in some cases:

1. **Saved semantic collections** — a named, re-openable "virtual directory" defined by a predicate over the property system (§5, §9), directly realizing Gifford et al.'s 1991 proposal as a standing feature rather than a one-off search.
2. **A standing "reminding" surface** — a recency/frequency/pinned view, always one keystroke away, implementing Malone's and Barreau & Nardi's core finding that *where you last saw something* is how you actually find it again.
3. **A chronological/timeline view** across one or more directories — the Lifestreams idea, as an alternate axis of organization coexisting with the tree rather than replacing it.
4. **Provenance-tracked heterogeneous collections** (§4) — browse "everything this commit touched," "everything matching this search," or "everything I tagged this week" with per-entry source display, sortable by original location or by the collection's own logic.
5. **A first-class task manager surface** (§7) — every background operation visible, individually cancellable, with real progress, not a spinner or a frozen UI.
6. **Transactional, verified file operations** — a copy that verifies the destination before removing the source on a move, and a delete path that defaults to a recoverable trash rather than unrecoverable removal, addressing a correctness expectation users bring from everyday computing that command-line-descended tools frequently ignore.
7. **Faceted browsing** — narrow a large collection by successively selecting attribute values (by type, then by tag, then by modified-date bucket), the query-engine (§9) exposed as an interactive facet UI rather than only a typed predicate.
8. **Undo across file operations**, not only within a text editor — logged, reversible where the underlying operation permits it (a move can be undone; a `shred` cannot, and the UI should say so up front rather than after the fact).
9. **Live version-control awareness as a native attribute source** (§5) — status, blame, and per-file history available as ordinary, sortable/filterable columns rather than a bolted-on separate mode.
10. **An explicit, formally-modeled interaction-mode stack** — browsing, an inline rename, a popup dialog, an embedded terminal, a nested preview are all "modes," pushed and popped from one stack with one restoration mechanism, so that returning from any nested mode to any other always leaves the terminal/window state exactly as it was — the general form of a class of bugs (a modal operation failing to correctly restore the screen it interrupted) that recurs across implementations whenever screen/mode state is tracked ad hoc rather than as a single explicit stack.
11. **Agent/automation-callable interface** — expose the command layer (§10) as a well-typed, introspectable API a scripted client or an AI agent can call directly (list a collection, run a query, invoke an action, read the current selection) rather than only a human at a keyboard; several current-generation file managers are already treating this as a first-class design target rather than an afterthought, which is the direction this document recommends any new design assume from the start rather than retrofit.
12. **Collaborative/shared session state**, opt-in — a session's active collection, selection, or task list visible to (and, where sensible, actionable by) a second connected instance, built on the same pub/sub bus described in §11, useful for pairing/remote assistance scenarios without requiring a purpose-built screen-sharing tool.

---

## 14. Lessons from a mature backlog: errors the architecture should design out

Reviewing a long-running, real-world file manager's own unresolved-issues backlog is instructive precisely because it shows which problems *don't* get fixed incrementally — they recur because the underlying architecture makes them structurally likely, and only a different architectural choice, decided up front, avoids them. Generalized (not tool-specific):

- **Screen/mode-state tracked as an ad hoc flag instead of an explicit stack** produces exactly the bug class in §13 item 10 — a nested mode that doesn't know what it interrupted, and therefore restores the wrong thing (or nothing) on exit. Design the mode stack in from the start (§13.10); do not bolt it on after the first report of "exiting X leaves the screen wrong."
- **"General virtual directory / arbitrary collection" left as a late, ambitious, never-quite-shipped feature** is a recurring pattern precisely because it is usually attempted as an addition to a listing pipeline that was hardwired to "the current directory's contents" from day one. If the collection abstraction (§4) is the foundation rather than a retrofit, this class of feature (git-commit-driven views, search-result views, saved-selection views) is a small amount of glue code, not a rewrite.
- **A single global, ungeneralized filtering mechanism** — one active filter, applied only to live directory scans — blocks exactly the reuse that a unified filter/select/search engine (§9) is meant to provide. When filtering is bound tightly to one data source, every new source (search results, VCS output, a saved list) ends up needing its own bespoke, weaker filtering logic instead of inheriting the general one.
- **File-attribute display baked into one formatted string per entry at scan time** blocks per-column sort, per-column visibility toggling, and multi-source provenance display, and is expensive to unwind once other features depend on the string format. Model entries as structured records from the start (§5); treat formatting as a render-time concern only.
- **Background file-watching (inotify/FSEvents-equivalent) treated as always-available and unconditionally relied upon**, with no fallback, produces exactly the "silently stopped refreshing, user has no idea why" failure class. Every provider must declare how (or whether) it reports changes (§6), and the UI must be able to show "this view is not live" explicitly rather than presenting a stale view as if it were current.
- **Large architectural questions (how should pane splitting behave? where does focus go on a split?) left unresolved as open questions embedded directly in a running product's backlog for years** is a sign that these decisions were never made explicit as UX policy — they were left to be decided ad hoc, differently, each time a related feature touched them. Decide and document window/pane-management policy (split direction, focus transfer, keep-vs-move-on-split) once, explicitly, as part of the architecture, not per feature request.
- **Multi-column, per-column-sortable attribute display and asynchronous, incrementally-populated columns** are treated as a future "someday" architectural item rather than a foundational one in more than one real backlog surveyed for this document — exactly the gap §5 and §7 close if designed in from the start (structured attributes; async tasks that can update a specific column in place as they complete, e.g., a checksum column filling in progressively without blocking the rest of the listing).

The general principle underlying all of the above: **every one of these is cheap if it's a foundational abstraction, and expensive if it's a retrofit.** The purpose of §4–§12 is to make sure the foundational abstractions are the right ones the first time.

---

## 15. References

- Barreau, D., & Nardi, B. A. (1995). Finding and reminding: File organization from the desktop. *ACM SIGCHI Bulletin*, 27(3), 39–43.
- Bergman, O., Tene-Rubinstein, M., & Shalom, J. (2013). The use of attention resources in navigation versus search. *Personal and Ubiquitous Computing*, 17(3), 583–590.
- Bezroukov, N. (1998–2012). *Less Is More: The Orthodox File Manager (OFM) Paradigm* (ongoing work; includes the *OFM2012 — Cutting Edge Features of Orthodox File Managers* draft standard). Softpanorama.
- Dinneen, J. D., & Julien, C. (2019). The ubiquitous digital file: A review of file management research. *Journal of the Association for Information Science and Technology*, 71(1).
- Dourish, P., Edwards, W. K., LaMarca, A., & Salisbury, M. (1999). Presto: An experimental architecture for fluid interactive document spaces. *ACM Transactions on Computer-Human Interaction*, 6(2), 133–161.
- Fertig, S., Freeman, E., & Gelernter, D. (1996). "Finding and reminding" reconsidered. *ACM SIGCHI Bulletin*, 28(1).
- Freeman, E., & Gelernter, D. Lifestreams: Organizing your electronic life. *AAAI Fall Symposium on AI Applications in Knowledge Navigation and Retrieval*.
- Furnas, G. W. (1986). Generalized fisheye views. In *Proceedings of the ACM CHI '86 Conference on Human Factors in Computing Systems* (pp. 16–23).
- Gifford, D. K., Jouvelot, P., Sheldon, M. A., & O'Toole, J. W. (1991). Semantic file systems. In *Proceedings of the 13th ACM Symposium on Operating Systems Principles* (pp. 16–25). *ACM Operating Systems Review*, 25(5).
- Jones, W. P., & Dumais, S. T. (1986). The spatial metaphor for user interfaces: Experimental tests of reference by location versus name. *ACM Transactions on Office Information Systems*, 4(1), 42–63.
- Malone, T. W. (1983). How do people organize their desks? Implications for the design of office information systems. *ACM Transactions on Office Information Systems*, 1(1), 99–112.
- Shneiderman, B. (1996). The eyes have it: A task by data type taxonomy for information visualizations. In *Proceedings of the IEEE Symposium on Visual Languages* (pp. 336–343).
- sxyazi (2023). *Why is Yazi fast?* Yazi project blog/documentation — cited for its concrete, published account of chunked directory loading, batched MIME-type computation, two-pass image preview generation, and the client-server/publish-subscribe data-distribution design of the `yazi` terminal file manager.
- GNU Midnight Commander documentation and ArchWiki entry — cited for the Virtual File System (VFS) design (archive and remote-protocol browsing as ordinary directories).
- `ranger` documentation — cited for its console command language and context-aware command set as an example of a distinct command layer in a terminal file manager.
- General background on GVFS (GNOME) and KIO (KDE) as the GUI-lineage equivalents of the same provider/VFS abstraction, and on Windows Explorer's shell namespace as the earliest mainstream mixed real/virtual browsing surface.
