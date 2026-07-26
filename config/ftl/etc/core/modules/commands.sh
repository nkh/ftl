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
