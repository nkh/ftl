#!/usr/bin/env bash
# scripts/convert-to-tabs.sh — convert space indentation to tabs in Bash files
#
# The project convention is hard tabs for indentation. Several files were
# accidentally converted to spaces by editor tools. This script converts
# leading spaces (groups of 8) to tabs.
#
# Usage: bash scripts/convert-to-tabs.sh

set -euo pipefail
cd "$(dirname "$0")/.."

files=(
	config/ftl/etc/core/modules/filter.sh
	config/ftl/etc/core/modules/inline_rename.sh
	config/ftl/etc/core/modules/keyboard.sh
	config/ftl/etc/core/modules/log.sh
	config/ftl/etc/core/modules/state.sh
	config/ftl/etc/core/modules/util.sh
	config/ftl/etc/core/modules/commands/quit.sh
	config/ftl/etc/core/modules/commands/view.sh
	config/ftl/etc/viewers/core
	config/ftl/etc/ftlrc
	config/ftl/etc/bin/ftl
)

for f in "${files[@]}" ; do
	[[ -f "$f" ]] || continue
	# Convert leading spaces to tabs (8 spaces = 1 tab, matching the
	# original code's tab width). Use unexpand which handles partial
	# tab widths correctly.
	unexpand -t 8 --first-only "$f" > "${f}.tmp" && mv "${f}.tmp" "$f"
	echo "  converted: $f"
done

echo "Done."
