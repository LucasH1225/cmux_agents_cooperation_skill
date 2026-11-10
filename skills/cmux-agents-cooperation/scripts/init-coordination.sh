#!/usr/bin/env bash
# Copy the coordination templates (AGENTS.md, PROJECT_STATUS.md, CLAUDE.md) into a project folder.
# Never overwrites an existing file. Afterwards, fill in every {{PLACEHOLDER}} it lists.
#
# Usage: init-coordination.sh <project-dir>
set -euo pipefail

[[ $# -eq 1 ]] || { echo "usage: $(basename "$0") <project-dir>" >&2; exit 3; }
dest=$1
[[ -d "$dest" ]] || { echo "not a directory: $dest" >&2; exit 3; }

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
templates="$here/../templates"

for f in AGENTS.md PROJECT_STATUS.md CLAUDE.md; do
  if [[ -e "$dest/$f" ]]; then
    echo "skip   $f (already exists; merge by hand rather than replacing it)"
  else
    cp "$templates/$f" "$dest/$f"
    echo "create $f"
  fi
done

echo
echo "Placeholders still to fill in:"
(cd "$dest" && grep -o '{{[A-Z_]*}}' AGENTS.md PROJECT_STATUS.md 2>/dev/null | sort | uniq -c) || echo "  (none)"
echo
echo "Next: fill the placeholders, add every chat to the roster (PROJECT_STATUS.md §1) with a"
echo "§7 heading each, get the user's approval, then ask the other agents to review with narrow edits."
