# ftl — 50 Adventurous Ideas & The File Manager as Terminal Hub

> **Subject:** A second round of plugin and feature ideas, more
> adventurous than the previous proposals, plus an essay on
> positioning ftl as the central hub of terminal activity.
> **Purpose:** Expand the horizon of what ftl can be, beyond a
> traditional file manager.
> **Companion documents:** `ftl-missing-functionality.md` (v1, 42
> implemented), `ftl-missing-functionality-v2.md` (60 proposals),
> `ftl-plugin-ideas.md` (25 + 25), `ftl-terminal-file-manager-comparison.md`.
> **Status:** Proposals — not yet implemented. Several are ambitious
> and would require significant effort or architectural changes.

---

## Table of Contents

**Part I — The File Manager as Terminal Hub**
1. [The Hub Thesis](#part-i--the-file-manager-as-terminal-hub)
2. [Why the Terminal Needs a Hub](#why-the-terminal-needs-a-hub)
3. [The Hub Workflow](#the-hub-workflow)
4. [What Makes ftl Suited to Be the Hub](#what-makes-ftl-suited-to-be-the-hub)

**Part II — 50 Adventurous Ideas**
5. [Adventurous Ideas](#part-ii--50-adventurous-ideas)

---

# Part I — The File Manager as Terminal Hub

## The Hub Thesis

Most terminal users treat their file manager as a utility: they open
it, navigate to a directory, do something, and close it. The shell
(`bash`, `zsh`, `fish`) is the actual hub — the place where work
happens, where commands are composed, where state lives.

This document proposes a different model: **the file manager as the
hub**, with the shell as one of several satellites. In this model, the
file manager is always running (in a tmux pane), maintains context
(current directory, selection, marks, history, open tabs), and
dispatches work to specialized tools (shell, editor, git, browser,
build system) as needed.

This is not a new idea — Emacs users will recognize it as the Emacs
model (the editor as hub), and tmux power users already run tmux as a
session manager with multiple windows. What is new is proposing that a
**file manager** can fill this role, and that ftl's architecture
(hyperorthodox panes, real-program previews, Bash extensibility) makes
it particularly well-suited.

## Why the Terminal Needs a Hub

The modern terminal user's workflow is fragmented:

1. **The shell** knows the current directory and command history, but
   nothing about file relationships, tags, or visual context.
2. **The editor** (vim, neovim, helix) knows the open buffers and
   cursor positions, but nothing about the directory structure outside
   the working set.
3. **Git** knows version history, but lives in the shell and requires
   explicit invocation.
4. **The build system** (make, ninja, cargo) knows what to build, but
   not what changed since the last build (without being told).
5. **The browser** (w3m, lynx) knows the current page, but has no
   connection to local files.
6. **The terminal multiplexer** (tmux) knows the window layout, but
   nothing about the content of each pane.

Each tool maintains its own slice of context, and the user is the
integration layer — switching panes, copying paths, re-typing
commands, re-establishing context after each context switch.

A hub collapses this: one process maintains the shared context
(directory, selection, history, marks, git state), and dispatches to
specialized tools with that context pre-loaded. The user switches
between tools, not between contexts.

## The Hub Workflow

In the hub model, ftl is always running in a tmux pane. A typical
session:

1. **Start.** `ftl` opens in a tmux pane. The other pane has a shell.
2. **Navigate.** Use ftl to move to the project directory. ftl's
   frecency jump (`z` or `LEADER f`) makes this one keystroke.
3. **Inspect.** Move the cursor over a file; the preview pane shows
   its contents. Move over a git-modified file; the preview shows the
   diff. Move over an image; the preview shows it.
4. **Act.** Press a key to dispatch:
   - `Enter` opens the file in the editor (in a new tmux pane).
   - `LEADER g a` stages it in git.
   - `LEADER g c` commits.
   - `;` opens a shell pane synchronized to the current directory.
   - `LEADER b` runs the build system.
   - `LEADER t` runs the test suite.
   - `LEADER d` opens a Docker shell for the project.
5. **Return.** After the dispatched tool exits, control returns to
   ftl, which re-renders with the updated directory state.
6. **Continue.** The user never leaves the ftl context; they dispatch
   and return.

The key insight is that ftl **maintains context across dispatches**.
The shell pane remembers the directory. The editor opens at the
cursor's file. Git operations target the selection. The build system
runs in the project root. The user does not re-establish context after
each tool switch — ftl does it for them.

## What Makes ftl Suited to Be the Hub

ftl's architecture is unusually well-suited to the hub role:

1. **Hyperorthodox panes.** Each pane is a separate process. This
   means ftl can dispatch to a shell, an editor, a build, a test run,
   a Docker shell — all as sibling processes, each with its own state,
   all synchronized to ftl's directory and selection. A crash in one
   pane does not take down the hub.

2. **Real-program previews.** ftl's preview pane can show a file's
   contents, a git diff, a man page, a markdown render, an image, a
   PDF. This means the user can inspect context without leaving ftl.
   The preview pane is the "info" satellite.

3. **Bash extensibility.** Dispatching to a new tool is a 5-line
   binding plugin. There is no build step, no compilation. A user can
   add a "dispatch to my build system" binding in under a minute.

4. **State serialization.** ftl's state (directory, selection, marks,
   history) is serialized to the filesystem. External tools can read
   this state (via `$ftl_state_info_file_path`) and integrate. The
   `finfo` and `fsh` commands already do this.

5. **Tmux integration.** ftl is built on tmux. tmux is the de facto
   terminal multiplexer. ftl leverages tmux's pane management,
   popups, and windows for its dispatch model. A user who already
   uses tmux gains the hub model for free.

6. **Selection classes.** ftl's 4 selection classes (`¹²³D`) allow
   the user to maintain multiple parallel selections — e.g. class 1
   for "files to commit", class 2 for "files to delete", class 3 for
   "files to diff". The hub can dispatch to different tools based on
   the class.

The ideas in Part II explore how to realize this hub vision. Some are
modest (a binding to run a build system); some are ambitious (a
plugin system for non-file entities like processes or Docker
containers); some are speculative (integration with LSP servers for
code intelligence).

---

# Part II — 50 Adventurous Ideas

These ideas are more ambitious than those in `ftl-plugin-ideas.md`
and `ftl-missing-functionality-v2.md`. Several would require
architectural changes or significant new subsystems. They are
organized into 8 themes:

1. [Hub & Dispatch (1–8)](#1-hub--dispatch-18)
2. [Code Intelligence (9–16)](#2-code-intelligence-916)
3. [Non-File Entities (17–24)](#3-non-file-entities-1724)
4. [Collaboration & Sharing (25–30)](#4-collaboration--sharing-2530)
5. [Automation & Scripting (31–37)](#5-automation--scripting-3137)
6. [Sensory & Visualization (38–43)](#6-sensory--visualization-3843)
7. [Meta & Self-Modification (44–47)](#7-meta--self-modification-4447)
8. [Speculative (48–50)](#8-speculative-4850)

---

## 1. Hub & Dispatch (1–8)

### 1.1 Build system dispatcher

**Idea:** A binding that runs the project's build system (`make`,
`ninja`, `cargo`, `npm`, `go build`) in a split pane, with the output
piped to a log file ftl can preview.

**Why it matters:** The build is the most common dispatch target. A
dedicated binding removes the need to switch to the shell and type the
command.

**Sketch:**
```bash
ftl::plugin::build::run() {
    local cmd
    cmd=$(ftl::plugin::build::detect)  # detect Makefile, Cargo.toml, etc.
    ftl::pane::split "$cmd 2>&1 | tee $ftl_state_session_dir/build.log"
}
ftl::kbd::bind	ftl	ftl	"LEADER b"	ftl::plugin::build::run	"run build"
```

**Effort:** Medium. Requires a build-system detector (check for
`Makefile`, `Cargo.toml`, `package.json`, `go.mod`, `CMakeLists.txt`).

---

### 1.2 Test runner dispatcher

**Idea:** A binding that runs the project's test suite, scoped to the
current file if it's a source file.

**Why it matters:** Running tests for the current file is a common
loop. ftl knows the current file; it can pass it to the test runner.

**Sketch:**
```bash
ftl::plugin::test::run() {
    local cmd
    case "$ftl_state_current_extension" in
        py)  cmd="pytest ${ftl_state_current_basename}" ;;
        rs)  cmd="cargo test ${ftl_state_current_stem}" ;;
        go)  cmd="go test -run ${ftl_state_current_stem}" ;;
        js)  cmd="jest ${ftl_state_current_basename}" ;;
        *)   cmd="make test" ;;
    esac
    ftl::pane::split "$cmd 2>&1 | tee $ftl_state_session_dir/test.log"
}
ftl::kbd::bind	ftl	ftl	"LEADER t"	ftl::plugin::test::run	"run tests for current file"
```

**Effort:** Medium.

---

### 1.3 Linter / formatter dispatcher

**Idea:** A binding that runs the appropriate linter or formatter on
the current file (or selection).

**Why it matters:** Code quality tools are per-language; ftl can
dispatch based on extension.

**Sketch:**
```bash
ftl::plugin::lint::run() {
    local cmd
    case "$ftl_state_current_extension" in
        py)  cmd="ruff check --fix" ;;
        rs)  cmd="cargo clippy" ;;
        go)  cmd="gofmt -w" ;;
        js)  cmd="prettier --write" ;;
        sh)  cmd="shellcheck" ;;
        *)   ftl::log::warn "no linter for .$ftl_state_current_extension" ; return ;;
    esac
    $cmd "${ftl_selection_current[@]:-$ftl_state_current_path}"
    ftl::list::change_dir
}
ftl::kbd::bind	ftl	entry	"LEADER l"	ftl::plugin::lint::run	"lint/format current file"
```

**Effort:** Low.

---

### 1.4 Docker / container shell

**Idea:** A binding that opens a shell in a Docker container for the
current project (detected via `Dockerfile` or `docker-compose.yml`).

**Why it matters:** Containerized development is common; a one-key
dispatch into the container saves typing `docker exec -it ... bash`.

**Sketch:**
```bash
ftl::plugin::docker::shell() {
    [[ -f Dockerfile || -f docker-compose.yml ]] || { ftl::log::warn "no Dockerfile" ; return ; }
    local container
    container=$(docker compose ps -q 2>/dev/null | head -1)
    [[ -n "$container" ]] || container=$(docker ps -q --filter "label=com.docker.compose.project=$(basename $PWD)" | head -1)
    [[ -n "$container" ]] || { ftl::log::warn "no running container" ; return ; }
    ftl::pane::split "docker exec -it $container bash"
}
ftl::kbd::bind	ftl	ftl	"LEADER d"	ftl::plugin::docker::shell	"docker shell"
```

**Effort:** Medium.

---

### 1.5 Project switcher (git-aware)

**Idea:** A binding that lists all git repositories under a configured
root (e.g. `~/projects`), fzf-selects one, and opens it in a new tab.

**Why it matters:** Project switching is a frequent operation. A
git-aware switcher shows branch names and dirty status.

**Sketch:**
```bash
ftl::plugin::project::switch() {
    local root="${ftl_cfg_project_root:-$HOME/projects}"
    local proj
    proj=$(fd -t d -H '\.git$' "$root" 2>/dev/null \
        | sed 's|/.git$||' \
        | fzf-tmux -p 60% --preview 'cd {} && git log --oneline -5 2>/dev/null')
    [[ -n "$proj" ]] && ftl::cmd::tab_new && ftl::list::change_dir "$proj"
}
ftl::kbd::bind	ftl	move	"LEADER p"	ftl::plugin::project::switch	"switch project"
```

**Effort:** Low–medium.

---

### 1.6 Dispatch context menu

**Idea:** A popup menu (like a right-click menu) showing all available
dispatch actions for the current file type.

**Why it matters:** Discoverability. New users do not know all the
bindings; a context menu surfaces them.

**Sketch:**
```bash
ftl::plugin::dispatch_menu::show() {
    local actions=()
    actions+=("edit:Edit in \$EDITOR")
    actions+=("git-diff:Show git diff")
    actions+=("git-stage:Stage in git")
    [[ -f Makefile ]] && actions+=("make:Run make")
    [[ -f Cargo.toml ]] && actions+=("cargo:Run cargo build")
    # ...
    local choice
    choice=$(printf '%s\n' "${actions[@]}" | fzf-tmux -p 40% | cut -d: -f1)
    case "$choice" in
        edit)      ftl::cmd::edit_in_vim ;;
        git-diff)  ftl::plugin::missing::git_file_log ;;
        # ...
    esac
}
ftl::kbd::bind	ftl	entry	"LEADER SPC"	ftl::plugin::dispatch_menu::show	"dispatch context menu"
```

**Effort:** Medium. The menu is dynamic based on file type and
project.

---

### 1.7 Background job manager

**Idea:** A pane showing all background jobs (builds, tests, downloads)
spawned by ftl, with their status and output. Allows canceling,
re-running, or viewing output.

**Why it matters:** Long-running dispatches need management. tmux's
window list is not sufficient; ftl can track jobs it spawned.

**Sketch:**
```bash
declare -gA ftl_plugin_jobs=()  # job_id → "cmd|pane|start_time|status"

ftl::plugin::jobs::spawn() {
    local cmd="$1"
    local id="job_$(date +%s)"
    local pane=$(tmux split-window -P -d "$cmd 2>&1 | tee $ftl_state_session_dir/$id.log")
    ftl_plugin_jobs[$id]="$cmd|$pane|$(date +%s)|running"
}

ftl::plugin::jobs::show() {
    local list=""
    for id in "${!ftl_plugin_jobs[@]}" ; do
        list+="$id: ${ftl_plugin_jobs[$id]}\n"
    done
    # Display in a popup, allow selecting to view output or cancel
    echo -e "$list" | fzf-tmux -p 50% --preview "cat $ftl_state_session_dir/{}.log"
}
ftl::kbd::bind	ftl	ftl	"LEADER j"	ftl::plugin::jobs::show	"job manager"
```

**Effort:** Medium–high. Requires tracking pane PIDs and polling
status.

---

### 1.8 Cross-tool selection sharing

**Idea:** ftl's selection is serialized to the filesystem. External
tools (a shell script, a vim plugin) can read it and act on the same
set of files.

**Why it matters:** Enables workflows like "tag files in ftl, then
run a custom script on the tagged files from the shell".

**Sketch:** The infrastructure already exists (`$ftl_state_info_file_path`
contains `ftl_selection_current`). Add a shell helper:

```bash
# In ~/.bashrc:
ftl-sel() {
    source "$FTL_STATE_DIR/$(cat $FTL_STATE_DIR/last_pid)/ftl_main_info_*/ftl_info_*"
    for f in "${ftl_selection_current[@]}" ; do
        "$@" "$f"
    done
}
```

**Effort:** Low (the infrastructure exists; just needs a convenience
wrapper and documentation).

---

## 2. Code Intelligence (9–16)

### 2.1 LSP integration

**Idea:** Integrate with Language Server Protocol servers to show
symbol info, go-to-definition, find-references, and hover docs in the
preview pane.

**Why it matters:** Code intelligence is the killer feature of IDEs.
Bringing it to the terminal file manager blurs the line between editor
and file browser.

**Sketch:** This is ambitious. Would require:
- An LSP client in Bash (or a companion tool in Python/Node).
- A way to communicate with a running LSP server (via stdio).
- Preview pane rendering of LSP responses.

A minimal version: on cursor move over a source file, run `ctags` or
`global` and show the symbol list in the preview.

**Effort:** High.

---

### 2.2 Symbol navigator (ctags/global)

**Idea:** For source files, show a list of symbols (functions,
classes, variables) in the preview pane. Selecting a symbol jumps to
it in the editor.

**Why it matters:** Faster code navigation than grep.

**Sketch:**
```bash
ftl::plugin::symbols::show() {
    [[ $ftl_state_current_extension =~ py|rs|go|c|js ]] || return
    ftl::prev::clear
    ftl::pane::split_for_preview \
        "ctags -x --format=2 '${ftl_state_current_path@Q}' | fzf --preview 'grep -n {1} \"${ftl_state_current_path@Q}\" | head -5' | awk '{print \$3}' > $ftl_state_session_dir/symbol_line"
    # Then the editor can read $ftl_state_session_dir/symbol_line to jump
}
```

**Effort:** Medium.

---

### 2.3 Inline documentation (man pages / pydoc / perldoc)

**Idea:** When the cursor is over a file that has documentation (a
man page, a Python module with `pydoc`, a Perl module with `perldoc`),
show the docs in the preview pane.

**Why it matters:** Reduces context switches to a browser or separate
man page lookup.

**Sketch:**
```bash
ftl::plugin::docs::show() {
    case "$ftl_state_current_extension" in
        1)  ftl::pane::split_for_preview "man ${ftl_state_current_stem} ; read -sn 100" ;;
        py) ftl::pane::split_for_preview "pydoc ${ftl_state_current_stem} ; read -sn 100" ;;
        pl) ftl::pane::split_for_preview "perldoc ${ftl_state_current_stem} ; read -sn 100" ;;
        pm) ftl::pane::split_for_preview "perldoc ${ftl_state_current_stem} ; read -sn 100" ;;
    esac
}
```

**Effort:** Low.

---

### 2.4 Dependency graph viewer

**Idea:** For projects with a dependency manifest (`Cargo.toml`,
`package.json`, `go.mod`, `requirements.txt`), show a dependency
graph in the preview pane.

**Why it matters:** Understanding dependencies is critical for
debugging and security.

**Sketch:** Use `cargo tree` (Rust), `npm ls` (Node), `go mod graph`
(Go), or `pipdeptree` (Python). Pipe through `dot -Tsvg` for a
visual graph.

**Effort:** Medium.

---

### 2.5 Code search with semantic context

**Idea:** Use `ast-grep` or `tree-sitter` to search for code patterns
semantically (e.g. "all function definitions that call `foo`").

**Why it matters:** Plain regex search misses context. Semantic search
understands code structure.

**Sketch:**
```bash
ftl::plugin::semantic_search::run() {
    ftl::cmd::prompt "pattern (ast-grep): "
    local pat="$REPLY"
    ftl::pane::split_for_preview "ast-grep run '$pat' | $ftl_cfg_markdown_pager"
}
ftl::kbd::bind	ftl	find	"LEADER s s"	ftl::plugin::semantic_search::run	"semantic code search"
```

**Effort:** Low (if `ast-grep` is installed). High (if implementing
from scratch).

---

### 2.6 Refactoring dispatcher

**Idea:** Dispatch to a refactoring tool (`sed` for simple cases,
`ast-grep` for structural) with a preview of the changes before
applying.

**Why it matters:** Refactoring is error-prone; a preview-and-confirm
workflow is safer.

**Sketch:**
```bash
ftl::plugin::refactor::run() {
    ftl::cmd::prompt "refactor pattern: "
    local pat="$REPLY"
    # Dry run: show diff
    ftl::pane::split_for_preview "ast-grep run --update-all '$pat' --diff ; read -sn 1"
    ftl::cmd::prompt "apply? [y|N]" -sn1
    [[ "$REPLY" == y ]] && ast-grep run --update-all "$pat"
    ftl::list::change_dir
}
```

**Effort:** Medium.

---

### 2.7 Code statistics dashboard

**Idea:** For a project, show a dashboard: lines of code, file count,
language breakdown, complexity metrics, git activity over time.

**Why it matters:** Useful for project assessment and onboarding.

**Sketch:** Use `tokei` or `cloc` for line counts, `git log --since`
for activity. Render as a text dashboard in the preview pane.

**Effort:** Medium.

---

### 2.8 Inline REPL for scripts

**Idea:** When the cursor is on a Python, Ruby, or Bash script, open
an REPL in a split pane with the script's directory as the working
directory and the script's module loaded.

**Why it matters:** Exploratory programming without leaving the file
manager.

**Sketch:**
```bash
ftl::plugin::repl::open() {
    case "$ftl_state_current_extension" in
        py) ftl::pane::split "cd '$PWD' && python3 -i '${ftl_state_current_path@Q}'" ;;
        rb) ftl::pane::split "cd '$PWD' && irb -r '${ftl_state_current_path@Q}'" ;;
        sh) ftl::pane::split "cd '$PWD' && bash -i" ;;
    esac
}
ftl::kbd::bind	ftl	ftl	"LEADER r"	ftl::plugin::repl::open	"open REPL"
```

**Effort:** Low.

---

## 3. Non-File Entities (17–24)

### 3.1 Process viewer

**Idea:** A virtual list showing running processes (like `top` or
`htop`), with the ability to kill, signal, or inspect them from ftl.

**Why it matters:** Process management is a common terminal task.
Integrating it into ftl unifies file and process management.

**Sketch:** Use the virtual entries framework. Inject processes as
virtual files; `Enter` sends SIGTERM, `LEADER k` sends SIGKILL,
preview shows `ps` output.

**Effort:** Medium–high.

---

### 3.2 Docker container browser

**Idea:** Browse Docker containers (and their filesystems) as if they
were directories. `Enter` opens a shell; preview shows container
logs.

**Why it matters:** Container management is a key DevOps workflow.

**Sketch:** Virtual entries for `docker ps` output. `Enter` runs
`docker exec -it`. Preview runs `docker logs --tail 50`.

**Effort:** Medium.

---

### 3.3 systemd unit browser

**Idea:** Browse systemd units (services, timers, sockets). Start,
stop, restart, enable, disable. Preview shows journalctl output.

**Why it matters:** System administration from the file manager.

**Sketch:** Virtual entries for `systemctl list-units`. Bindings for
`start`, `stop`, `restart`, `enable`, `disable`. Preview runs
`journalctl -u <unit> --since "1 hour ago"`.

**Effort:** Medium.

---

### 3.4 Network connection browser

**Idea:** Browse active network connections (like `ss` or
`netstat`). Filter by state, kill connections.

**Why it matters:** Network debugging.

**Sketch:** Virtual entries for `ss -tunap`. Preview shows `lsof -i
:<port>`.

**Effort:** Medium.

---

### 3.5 Package manager browser

**Idea:** Browse installed packages (apt, pacman, dnf, brew). Show
package info, files, dependencies. Uninstall, update.

**Why it matters:** Package management is a frequent task.

**Sketch:** Virtual entries for `dpkg -l` (or equivalent). Preview
shows `apt show <package>`. Bindings for `apt remove`, `apt update`.

**Effort:** Medium. Package-manager-specific.

---

### 3.6 Cron job browser

**Idea:** Browse cron jobs (user and system). Edit, delete, create.

**Why it matters:** Scheduled task management.

**Sketch:** Virtual entries for `crontab -l` and `/etc/cron.*`.
`Enter` opens `crontab -e`.

**Effort:** Low–medium.

---

### 3.7 Environment variable browser

**Idea:** Browse environment variables. Edit, unset, export new ones.
Filter by name or value.

**Why it matters:** Environment debugging.

**Sketch:** Virtual entries for `env`. `Enter` edits in `$EDITOR`.
Preview shows variable value and source.

**Effort:** Low.

---

### 3.8 SSH key / config browser

**Idea:** Browse SSH keys, known hosts, and config entries. Connect,
edit, remove.

**Why it matters:** SSH management is scattered across files;
centralizing it in ftl helps.

**Sketch:** Virtual entries for `~/.ssh/config` entries, `~/.ssh/*.pub`
keys, `~/.ssh/known_hosts` entries.

**Effort:** Medium.

---

## 4. Collaboration & Sharing (25–30)

### 4.1 File sharing via temporary HTTP server

**Idea:** A binding that starts a temporary HTTP server (Python
`http.server` or `miniserve`) serving the current directory, and
copies the URL to the clipboard.

**Why it matters:** Quick file sharing on a local network.

**Sketch:**
```bash
ftl::plugin::share::http() {
    local port=$((RANDOM % 1000 + 8000))
    ftl::pane::split "python3 -m http.server $port"
    sleep 1
    echo "http://$(hostname -I | awk '{print $1}'):$port" | xclip -selection clipboard
    ftl::log::info "serving on http://$(hostname -I | awk '{print $1}'):$port"
}
ftl::kbd::bind	ftl	entry	"LEADER s h"	ftl::plugin::share::http	"share via HTTP"
```

**Effort:** Low.

---

### 4.2 QR code generator for paths/URLs

**Idea:** Generate a QR code for the current file path or a URL, and
display it in the preview pane (using `qrencode -t ANSI`).

**Why it matters:** Quick transfer of paths/URLs to a phone.

**Sketch:**
```bash
ftl::plugin::qrcode::show() {
    ftl::prev::clear
    ftl::pane::split_for_preview "qrencode -t ANSI '${ftl_state_current_path@Q}' ; read -sn 100"
}
ftl::kbd::bind	ftl	view	"LEADER q"	ftl::plugin::qrcode::show	"show QR code"
```

**Effort:** Low.

---

### 4.3 Pastebin uploader

**Idea:** Upload the current file (or selection) to a pastebin
(`dpaste`, `paste.debian.net`, `ix.io`) and copy the URL.

**Why it matters:** Sharing code snippets for help/debugging.

**Sketch:**
```bash
ftl::plugin::pastebin::upload() {
    local url
    url=$(curl -s -F "file=@${ftl_state_current_path@Q}" http://0x0.st)
    echo "$url" | xclip -selection clipboard
    ftl::log::info "uploaded to $url"
}
```

**Effort:** Low.

---

### 4.4 Git patch exporter / importer

**Idea:** Export the current git diff (or a range of commits) as a
patch file. Import patches with review.

**Why it matters:** Patch-based collaboration (email, code review).

**Sketch:**
```bash
ftl::plugin::git_patch::export() {
    local out="$PWD/$(date +%Y%m%d).patch"
    git diff > "$out"
    ftl::log::info "wrote $out"
}
ftl::plugin::git_patch::import() {
    ftl::pane::split "git apply --check '${ftl_state_current_path@Q}' && git apply '${ftl_state_current_path@Q}' ; read -sn 1"
}
```

**Effort:** Low.

---

### 4.5 Collaborative editing (tmux + shared session)

**Idea:** Start a shared tmux session (via `tmate`) for collaborative
editing of the current file, with the ftl listing visible to all
participants.

**Why it matters:** Pair programming and live code review.

**Sketch:**
```bash
ftl::plugin::collab::start() {
    ftl::pane::split "tmate"
    # tmate prints an SSH URL; participants can join and see the session
}
```

**Effort:** Low (delegates to `tmate`).

---

### 4.6 File annotations / comments

**Idea:** Store per-file annotations (comments, notes) in a sidecar
`.ftl_notes` file. Display the annotation in the preview pane.

**Why it matters:** Collaborative context — "why does this file
exist?", "this file is deprecated", etc.

**Sketch:**
```bash
ftl::plugin::notes::edit() {
    local notesfile="$PWD/.ftl_notes"
    touch "$notesfile"
    $ftl_cfg_editor "$notesfile"
    ftl::list::render
}
```

**Effort:** Low. Preview integration requires an etag or viewer
enhancement.

---

## 5. Automation & Scripting (31–37)

### 5.1 Macro recorder

**Idea:** Record a sequence of ftl keystrokes, save as a named macro,
and replay with a key.

**Why it matters:** Repetitive workflows (e.g. "rename all .JPG to
.jpg, then sort by date") can be recorded once and replayed.

**Sketch:**
```bash
declare -g ftl_plugin_macro_recording=
declare -ga ftl_plugin_macro_keys=()

ftl::plugin::macro::start() {
    ftl_plugin_macro_recording=1
    ftl_plugin_macro_keys=()
}

ftl::plugin::macro::stop() {
    ftl_plugin_macro_recording=
    # Save to $FTL_STATE_DIR/macros/<name>
}

ftl::plugin::macro::play() {
    local name="$1"
    source "$FTL_STATE_DIR/macros/$name"
    for key in "${ftl_plugin_macro_keys[@]}" ; do
        ftl_kbd_current_key="$key"
        ftl::kbd::dispatch
    done
}
```

**Effort:** Medium. Requires hooking into the keyboard engine to
record.

---

### 5.2 Watched directory auto-actions

**Idea:** Configure rules: "when a file matching `*.log` appears in
this directory, gzip it", "when a `.torrent` file is downloaded, move
it to `~/torrents`".

**Why it matters:** Automation of common file-arrival workflows.

**Sketch:** Use inotify (already used by the file watcher). Extend
the watcher to match rules and execute actions.

**Effort:** Medium–high.

---

### 5.3 Batch operation queue

**Idea:** Queue up multiple operations (copy, move, rename) across
multiple directories, then execute them all at once with a review
step.

**Why it matters:** Complex file reorganizations are easier to plan
than to execute live.

**Sketch:** Maintain a queue in `$FTL_STATE_DIR/queue`. Each entry is
an operation (op, source, dest). `LEADER q` shows the queue;
`LEADER Q` executes it.

**Effort:** Medium.

---

### 5.4 Script generator from workflow

**Idea:** Record a ftl session (all keys pressed, all commands run),
and generate a Bash script that reproduces the workflow.

**Why it matters:** Turn ad-hoc file management into reusable
scripts.

**Sketch:** Extend the macro recorder (5.1) to emit a Bash script
instead of a key sequence.

**Effort:** Medium–high.

---

### 5.5 Cron-like scheduler for ftl commands

**Idea:** Schedule ftl commands to run at intervals (e.g. "every 5
minutes, sync the selection to the backup server").

**Why it matters:** Background automation without leaving ftl.

**Sketch:** Use the time-event handler system. Register a handler
with an interval; the handler runs the scheduled command.

**Effort:** Low (the infrastructure exists).

---

### 5.6 File arrival trigger

**Idea:** When a new file arrives in the current directory (via
inotify), execute a configured action.

**Why it matters:** React to downloads, build outputs, log rotations.

**Sketch:**
```bash
ftl::plugin::trigger::on_arrival() {
    local file="$1"
    case "$file" in
        *.jpg|*.png) ftl::plugin::image_optimize::run "$file" ;;
        *.log)       ftl::plugin::log_rotate::run "$file" ;;
        *.torrent)   mv "$file" ~/torrents/ ;;
    esac
}
```

**Effort:** Medium. Requires hooking into the file watcher.

---

### 5.7 Pipeline builder UI

**Idea:** A visual UI for building filter pipelines. Drag filters
together, configure each, see a live preview of the filtered listing.

**Why it matters:** The filter pipeline is powerful but textual. A
visual builder lowers the barrier.

**Sketch:** A tmux popup with fzf-selectable filters and a live
preview. Assemble the pipeline string and apply.

**Effort:** High.

---

## 6. Sensory & Visualization (38–43)

### 6.1 Disk usage treemap

**Idea:** Show disk usage as a treemap (nested rectangles sized by
directory size) in the preview pane.

**Why it matters:** Treemaps are the best visualization for disk
usage; `du` output is hard to parse visually.

**Sketch:** Use `duc` or generate an SVG with a Python script. Display
as an image in the preview pane.

**Effort:** Medium.

---

### 6.2 File timeline view

**Idea:** Show files on a timeline (by mtime), grouped by day/hour.
Useful for "what did I work on yesterday?".

**Why it matters:** Time-based navigation complements the
directory-based navigation.

**Sketch:** Virtual entries grouped by date. `find . -type f -printf
'%T+ %p\n' | sort -r`.

**Effort:** Medium.

---

### 6.3 Git contribution heatmap

**Idea:** Show a GitHub-style contribution heatmap for the current
git repo.

**Why it matters:** Visual overview of commit activity.

**Sketch:** `git log --date=short --format='%ad' | sort | uniq -c`,
render as ANSI-colored grid.

**Effort:** Low–medium.

---

### 6.4 Directory structure visualization

**Idea:** For the current directory, show a visual tree (with box-
drawing characters) in the preview pane, highlighting the cursor's
position.

**Why it matters:** Understanding directory structure at a glance.

**Sketch:** Use `tree` with custom formatting, or generate with awk.

**Effort:** Low.

---

### 6.5 Audio waveform preview

**Idea:** For audio files, show a waveform image in the preview pane.

**Why it matters:** Visual identification of audio files.

**Sketch:** Use `ffmpeg` to generate a waveform PNG, display with
`w3mimgdisplay`.

**Effort:** Medium.

---

### 6.6 PDF page grid

**Idea:** For PDFs, show a grid of all pages (as thumbnails) in the
preview pane, instead of just the first page.

**Why it matters:** Faster PDF navigation.

**Sketch:** `pdftoppm` all pages at low resolution, montage with
ImageMagick.

**Effort:** Medium. Slow for large PDFs; needs caching.

---

## 7. Meta & Self-Modification (44–47)

### 7.1 Live plugin editor

**Idea:** A binding that opens the user's `bindings/` directory in
ftl. Edit a plugin, `:source` it live, test, iterate.

**Why it matters:** Plugin development is currently edit-restart-test.
Live editing speeds development.

**Sketch:**
```bash
ftl::plugin::plugin_editor::open() {
    ftl::cmd::tab_new
    ftl::list::change_dir "$FTL_CFG/bindings"
}
ftl::kbd::bind	ftl	ftl	"LEADER P"	ftl::plugin::plugin_editor::open	"open plugin directory"
```

**Effort:** Low.

---

### 7.2 Binding conflict detector

**Idea:** On startup (or on demand), scan all bindings and report
conflicts (same key bound to different commands).

**Why it matters:** Binding conflicts are silent and confusing.

**Sketch:** Iterate `ftl_kbd_trie`, find entries where the value
changed during registration (the prefix counter).

**Effort:** Low.

---

### 7.3 Config profiler

**Idea:** Measure the time each section of `ftlrc` takes to source.
Report slow plugins or config sections.

**Why it matters:** ftl startup time is dominated by sourcing; this
helps optimize.

**Sketch:** Wrap each `source` in `ftl_setup` with timing. Report to
the log.

**Effort:** Low.

---

### 7.4 Self-documenting bindings

**Idea:** Each binding's help text is queryable from the `:` prompt.
`:help <key>` shows the help for that binding.

**Why it matters:** Discoverability without leaving ftl.

**Sketch:**
```bash
# In commands/help:
ftl::plugin::help::show() {
    local key="$1"
    for dscut in "${!ftl_kbd_bindings_display[@]}" ; do
        if [[ "$dscut" == *"$key"* ]] ; then
            echo "${ftl_kbd_bindings_display[$dscut]}"
        fi
    done
}
```

**Effort:** Low.

---

## 8. Speculative (48–50)

### 8.1 ftl as a window manager

**Idea:** ftl manages tmux windows and panes as first-class objects.
Each "tab" in ftl is a tmux window with a specific layout (file
manager + shell + editor). ftl dispatches to layouts, not just
commands.

**Why it matters:** Pushes the hub thesis to its conclusion — ftl
becomes the session manager, not just the file manager.

**Sketch:** This is a fundamental redesign. ftl would need a layout
system (defined in config), a window management API, and a way to
spawn pre-configured pane layouts.

**Effort:** Very high. Speculative.

---

### 8.2 ftl as a note-taking system

**Idea:** ftl manages a directory of markdown notes. Bindings for
creating, searching, linking, and rendering notes. Preview pane shows
rendered markdown.

**Why it matters:** Note-taking is a common terminal activity. ftl's
file management + markdown preview is a natural fit.

**Sketch:** A binding plugin (`bindings/notes`) with:
- `LEADER n n` — new note (prompts for title, creates
  `YYYY-MM-DD-title.md`)
- `LEADER n s` — search notes (fzf over note contents)
- `LEADER n l` — link to another note (inserts a markdown link)
- Preview pane renders markdown via `glow`

**Effort:** Medium. The infrastructure exists; this is a curated set
of bindings + a note directory convention.

---

### 8.3 ftl as a data pipeline editor

**Idea:** ftl manages data files (CSV, JSON, Parquet). Bindings for
inspecting, transforming, and piping data between tools (`jq`,
`csvkit`, `duckdb`). Preview pane shows data summaries.

**Why it matters:** Data analysis is a growing terminal use case.
ftl's preview pane is ideal for data summaries.

**Sketch:** Bindings for:
- `LEADER d h` — head (first 10 rows)
- `LEADER d s` — schema (column names and types)
- `LEADER d q` — query (prompt for a `jq`/`duckdb` query, show
  result)
- `LEADER d p` — plot (generate a quick chart with `gnuplot` or
  `matplotlib`)

**Effort:** Medium–high. Each binding is simple; the value is in the
curation.

---

## Quick-Reference: All 50 Ideas

| # | Idea | Theme | Effort |
|---|------|-------|--------|
| 1.1 | Build system dispatcher | Hub | Medium |
| 1.2 | Test runner dispatcher | Hub | Medium |
| 1.3 | Linter / formatter dispatcher | Hub | Low |
| 1.4 | Docker / container shell | Hub | Medium |
| 1.5 | Project switcher (git-aware) | Hub | Low–Med |
| 1.6 | Dispatch context menu | Hub | Medium |
| 1.7 | Background job manager | Hub | Med–High |
| 1.8 | Cross-tool selection sharing | Hub | Low |
| 2.1 | LSP integration | Code | High |
| 2.2 | Symbol navigator (ctags) | Code | Medium |
| 2.3 | Inline documentation | Code | Low |
| 2.4 | Dependency graph viewer | Code | Medium |
| 2.5 | Semantic code search | Code | Low–High |
| 2.6 | Refactoring dispatcher | Code | Medium |
| 2.7 | Code statistics dashboard | Code | Medium |
| 2.8 | Inline REPL | Code | Low |
| 3.1 | Process viewer | Non-File | Med–High |
| 3.2 | Docker container browser | Non-File | Medium |
| 3.3 | systemd unit browser | Non-File | Medium |
| 3.4 | Network connection browser | Non-File | Medium |
| 3.5 | Package manager browser | Non-File | Medium |
| 3.6 | Cron job browser | Non-File | Low–Med |
| 3.7 | Environment variable browser | Non-File | Low |
| 3.8 | SSH key / config browser | Non-File | Medium |
| 4.1 | File sharing via HTTP | Collab | Low |
| 4.2 | QR code generator | Collab | Low |
| 4.3 | Pastebin uploader | Collab | Low |
| 4.4 | Git patch exporter/importer | Collab | Low |
| 4.5 | Collaborative editing (tmate) | Collab | Low |
| 4.6 | File annotations / comments | Collab | Low |
| 5.1 | Macro recorder | Auto | Medium |
| 5.2 | Watched directory auto-actions | Auto | Med–High |
| 5.3 | Batch operation queue | Auto | Medium |
| 5.4 | Script generator from workflow | Auto | Med–High |
| 5.5 | Cron-like scheduler | Auto | Low |
| 5.6 | File arrival trigger | Auto | Medium |
| 5.7 | Pipeline builder UI | Auto | High |
| 6.1 | Disk usage treemap | Sensory | Medium |
| 6.2 | File timeline view | Sensory | Medium |
| 6.3 | Git contribution heatmap | Sensory | Low–Med |
| 6.4 | Directory structure visualization | Sensory | Low |
| 6.5 | Audio waveform preview | Sensory | Medium |
| 6.6 | PDF page grid | Sensory | Medium |
| 7.1 | Live plugin editor | Meta | Low |
| 7.2 | Binding conflict detector | Meta | Low |
| 7.3 | Config profiler | Meta | Low |
| 7.4 | Self-documenting bindings | Meta | Low |
| 8.1 | ftl as a window manager | Speculative | Very High |
| 8.2 | ftl as a note-taking system | Speculative | Medium |
| 8.3 | ftl as a data pipeline editor | Speculative | Med–High |

---

## Closing Note

The hub thesis is the through-line: ftl is not just a file browser,
it is a **context manager** that dispatches to specialized tools while
maintaining shared state. The 50 ideas above explore what that means
in practice — from modest dispatch bindings (run the build, run the
tests) to ambitious reimaginings (ftl as window manager, note system,
or data pipeline editor).

The common thread is that ftl's architecture — hyperorthodox panes,
real-program previews, Bash extensibility, serialized state — is
unusually well-suited to this role. Most file managers are sealed
boxes; ftl is an open platform. The question is not "can ftl do X?"
but "what is the most useful X to add next?"

The answer depends on the user. A developer wants build/test/lint
dispatchers. A sysadmin wants process/systemd/Docker browsers. A data
analyst wants data inspection and transformation. A writer wants note
management. ftl can be all of these, because the extension model is
uniform: a Bash function, a key binding, and access to ftl's state.

This is the adventurous proposition: that the terminal file manager,
long a utility, can become the hub.
