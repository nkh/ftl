#!/usr/bin/env bash
# scripts/split-commands.sh — split commands.sh into per-section module files
#
# commands.sh is 2732 lines with 381 functions across 15 sections.
# This script extracts each section into its own file under
# config/ftl/etc/core/modules/commands/. The original commands.sh is
# replaced with a barrel file that sources all the new files (so
# existing code that sources commands.sh continues to work).
#
# Usage: bash scripts/split-commands.sh

set -euo pipefail

cd "$(dirname "$0")/.."

SRC="config/ftl/etc/core/modules/commands.sh"
DEST_DIR="config/ftl/etc/core/modules/commands"

mkdir -p "$DEST_DIR"

# Section definitions: name | start_line | end_line | description
# end_line is the line BEFORE the next section's header (or EOF)
sections=(
	"dispatcher|25|129|Shell-command dispatcher"
	"movement|130|369|Movement commands"
	"selection|370|639|Selection commands"
	"file_ops|640|1102|File operation commands"
	"filter|1103|1186|Filter commands"
	"search|1187|1455|Search commands"
	"tab|1456|1524|Tab commands"
	"pane|1525|1607|Pane commands"
	"preview|1608|1985|Preview commands"
	"shell|1986|2142|Shell commands"
	"view|2143|2341|View mode commands"
	"mark|2342|2501|Mark/history commands"
	"quit|2502|2590|Quit commands"
	"signals|2591|2640|Signal handlers"
	"prompt|2641|2732|Command prompt"
)

for entry in "${sections[@]}" ; do
	IFS='|' read -r name start end desc <<< "$entry"

	outfile="$DEST_DIR/${name}.sh"

	# Write header
	cat > "$outfile" <<EOF
# commands/${name}.sh — ${desc}
#
# Split from commands.sh. Each command is a function that takes no
# arguments (it reads state from globals) and performs its action,
# usually ending with ftl::list::render or ftl::list::change_dir.
#
# vim: set filetype=bash :

EOF

	# Extract the section (lines start through end, inclusive)
	sed -n "${start},${end}p" "$SRC" >> "$outfile"

	echo "  wrote $outfile ($(wc -l < "$outfile") lines)"
done

# Replace commands.sh with a barrel file
cat > "$SRC" <<'EOF'
# commands.sh — user-facing command functions (barrel)
#
# This file sources all command modules from the commands/ subdirectory.
# The commands were split into per-section files for maintainability.
# Each module is self-contained and can be sourced independently.
#
# Modules (sourced in dependency order):
#   commands/dispatcher.sh  — shell-command dispatcher (must be first)
#   commands/movement.sh    — cursor and view movement
#   commands/selection.sh   — tagging and selection
#   commands/file_ops.sh    — file operations (cp, mv, rm, chmod, etc.)
#   commands/filter.sh      — filter pipeline commands
#   commands/search.sh      — incremental search and ripgrep
#   commands/tab.sh         — tab management
#   commands/pane.sh        — pane splitting and management
#   commands/preview.sh     — preview pane commands
#   commands/shell.sh       — shell pane integration
#   commands/view.sh        — view mode, sorting, size display
#   commands/mark.sh        — marks and history
#   commands/quit.sh        — quit and cancel
#   commands/signals.sh     — signal handlers
#   commands/prompt.sh      — command prompt (: prompt)

source "$FTL_CFG/etc/core/modules/commands/dispatcher.sh"
source "$FTL_CFG/etc/core/modules/commands/movement.sh"
source "$FTL_CFG/etc/core/modules/commands/selection.sh"
source "$FTL_CFG/etc/core/modules/commands/file_ops.sh"
source "$FTL_CFG/etc/core/modules/commands/filter.sh"
source "$FTL_CFG/etc/core/modules/commands/search.sh"
source "$FTL_CFG/etc/core/modules/commands/tab.sh"
source "$FTL_CFG/etc/core/modules/commands/pane.sh"
source "$FTL_CFG/etc/core/modules/commands/preview.sh"
source "$FTL_CFG/etc/core/modules/commands/shell.sh"
source "$FTL_CFG/etc/core/modules/commands/view.sh"
source "$FTL_CFG/etc/core/modules/commands/mark.sh"
source "$FTL_CFG/etc/core/modules/commands/quit.sh"
source "$FTL_CFG/etc/core/modules/commands/signals.sh"
source "$FTL_CFG/etc/core/modules/commands/prompt.sh"

# vim: set filetype=bash :
EOF

echo ""
echo "Split complete. commands.sh is now a barrel file sourcing 15 modules."
