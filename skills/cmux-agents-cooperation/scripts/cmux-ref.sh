#!/usr/bin/env bash
# Resolve a cmux tab (surface) title to its current ref, e.g. "Overall" -> surface:1000040000.
# Refs change whenever cmux restarts, so resolve them just before sending a message.
#
# Usage: cmux-ref.sh "<tab title or unique prefix>" [--all-workspaces]
# Matching: exact title first, then unique prefix (case-sensitive). Searches the caller's
# workspace first, then all workspaces (or all of them straight away with --all-workspaces).
# Exit codes: 0 found (ref printed on stdout), 1 no match, 2 ambiguous, 3 usage/cmux error.
set -euo pipefail

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "usage: $(basename "$0") \"<tab title or prefix>\" [--all-workspaces]" >&2
  exit 3
fi
command -v cmux >/dev/null 2>&1 || { echo "cmux not found on PATH" >&2; exit 3; }

json=$(cmux --json tree --all 2>/dev/null) || { echo "cmux --json tree failed (is cmux running?)" >&2; exit 3; }

CMUX_TREE_JSON="$json" python3 -I - "$1" "${2:-}" <<'PY'
import json, os, sys

query, flag = sys.argv[1], sys.argv[2]
tree = json.loads(os.environ["CMUX_TREE_JSON"])
caller_ws = (tree.get("caller") or {}).get("workspace_ref")

def surfaces():
    for win in tree.get("windows", []):
        for ws in win.get("workspaces", []):
            for pane in ws.get("panes", []):
                for s in pane.get("surfaces", []):
                    yield ws.get("ref"), ws.get("title"), s

def pick(candidates):
    exact = [c for c in candidates if c[2].get("title") == query]
    if exact:
        return exact
    return [c for c in candidates if (c[2].get("title") or "").startswith(query)]

everything = list(surfaces())
scopes = [everything] if flag == "--all-workspaces" or not caller_ws else \
         [[c for c in everything if c[0] == caller_ws], everything]

for scope in scopes:
    hits = pick(scope)
    if len(hits) == 1:
        print(hits[0][2]["ref"])
        sys.exit(0)
    if len(hits) > 1:
        print(f"ambiguous: {len(hits)} tabs match {query!r}:", file=sys.stderr)
        for ws_ref, ws_title, s in hits:
            print(f"  {s['ref']}  {s.get('title')!r}  (workspace {ws_title!r})", file=sys.stderr)
        sys.exit(2)

print(f"no tab matches {query!r}", file=sys.stderr)
sys.exit(1)
PY
