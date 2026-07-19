# Writing Commands

A **command** is a user-invoked script that runs against the current
ftl session. Commands are invoked from the `:` prompt
(`ftl::cmd::open_command_prompt`) or bound to keys. They live in
`$FTL_CFG/commands/`.

## Two flavors

A command file can be either:

- **Sourced** (not executable) — runs in ftl's own shell, so it has
  direct access to all of ftl's globals: `ftl_state_current_path`,
  `ftl_selection_current`, `$PWD`, `$ftl_state_session_dir`, etc.
- **Executable** (has the executable bit) — runs as a separate process.
  Use this when you want isolation or a non-Bash language.

The dispatcher in `ftl::cmd::dispatch_command` decides which:

```bash
local user_cmd="$FTL_CFG/commands/$cmd"
if [[ -f "$user_cmd" ]] ; then
    if [[ ! -x "$user_cmd" ]] ; then
        source "$user_cmd" "${cmd_parts[@]:1}"
    else
        "$user_cmd" "${cmd_parts[@]:1}"
    fi
    return
fi
```

## Arguments

Command-line arguments (everything after the command name in the `:`
prompt) are split by `etc/bin/parse_parts` and passed to the script as
`$@`. For sourced scripts, `$1`, `$2`, … are the parsed parts.

## Accessing ftl state from a sourced command

Sourced commands run in ftl's shell, so they can read and mutate any
`ftl_*` global. The example in `commands/01_example` shows the pattern:

```bash
{
    echo "CWD: $PWD"
    echo "current entry: $ftl_state_current_path"
    echo "Selection:" ; printf "\t%s\n" "${ftl_selection_current[@]}"
    echo "Arguments:" ; printf "\t%s\n" "$@"
} >"$ftl_state_session_dir/01_example_info"

tmux popup cat "$ftl_state_session_dir/01_example_info"
```

## External command integration: `ftl::state::serialize_info`

Executable commands can't see ftl's globals directly. To bridge the gap,
the dispatcher calls `ftl::state::serialize_info` before running an
external command. This writes an info file containing
`FTL_PID`, `FTL_SESSION_DIR`, `FTL_CWD`, the current path, and the
selection, then exports `ftl_state_info_file_path` so the child process
can find it:

```bash
ftl::state::serialize_info() {
    ftl_state_info_file_path="$(mktemp -p "$ftl_state_session_dir" ftl_info_XXXXXXX)"
    export ftl_state_info_file_path
    ftl_state_child_env+=([ftl_info_file]=$ftl_state_info_file_path)
    {
        echo "FTL_PID=$$"
        echo "FTL_SESSION_DIR=$ftl_state_session_dir"
        echo "FTL_CWD=${PWD@Q}"
        declare -p FTL_PID FTL_SESSION_DIR FTL_CWD \
            ftl_state_current_path ftl_selection_current
    } >"$ftl_state_info_file_path"
}
```

The child receives `ftl_info_file` via tmux's `-e` mechanism
(`ftl::state::render_child_env`). Source it to get back the variables:

```bash
#!/bin/bash
source "$ftl_info_file"
echo "ftl is in $FTL_CWD, on $ftl_state_current_path"
echo "Selection: ${ftl_selection_current[@]}"
```

The `finfo` wrapper (`etc/bin/finfo`) does this for you; the `csx` and
`cfx` aliases pipe `finfo`'s output into `xargs`:

```bash
declare -Ag ftl_cfg_command_aliases=(
    [csx]="split finfo | xargs -0"
    [cfx]="full finfo | xargs -0"
)
```

## Talking back to ftl

To send a key to ftl from a child process:

```bash
tmux send -t "$FTL_SESSION_DIR" "<key>"
```

To run a command in ftl's session shell:

```bash
tmux send -t "ftl$$:ftl$$_bash" "command" Enter
```

## Built-in commands

`$FTL_CFG/commands/` ships `fma` (file management actions), `fmr`
(file management recursive), `tree`, `etags` (manage etag sources),
`url` (open URLs from the selection), `show_cmd_log`, `open_with`, and
two examples (`01_example`, `02_example`). Study them as templates.
