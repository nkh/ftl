# Shell Integration

ftl can spawn a real `bash -i` in a sibling tmux pane and keep it in sync
with the listing. The shell pane has its own tmux pane id
(`ftl_pane_shell_id`) and an optional persistent "session shell" running
in a separate tmux window (`ftl_pane_session_shell_active`).

## Opening the shell pane

| Key | Command | Description |
|-----|---------|-------------|
| `Ss` / `CTL-W ss` | `ftl::cmd::open_shell` | open a horizontal shell pane |
| `Sv` / `CTL-W sv` | `ftl::cmd::open_vertical_shell` | open a vertical shell pane |
| `Sz` / `CTL-W sz` | `ftl::cmd::open_zoomed_shell` | open a zoomed-out shell pane |
| `S!` / `CTL-W !` | `ftl::cmd::view_session_shell` | view the persistent session shell |
| `Sq` / `CTL-W sq` | `ftl::cmd::close_shell_pane` | close the shell pane |

The shell pane dimensions are configurable:

```bash
ftl_cfg_shell_pane_height=40%
ftl_cfg_shell_pane_width=60%
```

## Sending files to the shell

| Key | Command | Description |
|-----|---------|-------------|-----------|
| `Sf` / `CTL-W sf` | `ftl::cmd::send_files_to_shell` | send the selection to the shell |
| `SS` / `CTL-W sS` | `ftl::cmd::open_shell_with_files` | open a shell pane pre-loaded with the selection |

The selected files are quoted and inserted into the shell's input buffer
via `tmux send-keys`.

## Synchronizing cwd

| Key | Command | Description |
|-----|---------|-------------|
| `gS` / `CTL-W sg` | `ftl::cmd::synch_shell_cwd` | cd ftl to the shell pane's cwd |

The reverse direction (push ftl's cwd to the shell) happens implicitly
when you open the shell: it inherits ftl's `$PWD` via `tmux split-window
-c "$PWD"`.

## Session shell

A "session shell" is a long-lived bash running in a background tmux
window named `ftl$$:ftl$$_bash`. It survives ftl quitting (with `ZS`).
Send commands to it with:

```bash
tmux send -t ftl$$:ftl$$_bash "command" Enter
```

## Command prompt

The `:` key opens ftl's command prompt (`ftl::cmd::open_command_prompt`).
The dispatcher (`ftl::cmd::dispatch_command`) accepts:

- a number → go to entry by index
- `qa` → quit all
- `load_sel` → load a selection from a file
- a binding name → invoke that binding's command
- `split <cmd>` / `full <cmd>` → run a user command in a split pane or
  full screen

Aliases live in `ftl_cfg_command_aliases`:

```bash
declare -Ag ftl_cfg_command_aliases=(
    [csx]="split finfo | xargs -0"
    [cfx]="full finfo | xargs -0"
)
```

## fsh and ftll/cdf

`fsh` (in `etc/bin/fsh`) is a wrapper that runs a shell command with
ftl's environment variables set — useful from inside the shell pane to
get back at ftl state. `ftll` and `cdf` are file-picker wrappers: they
start ftl, let you select files, and write the selection to fd 3 so the
calling shell can capture it (`ftl::state::emit_selection_fd3`). This
makes ftl usable as a `vim` file picker or a `cd`-helper.
