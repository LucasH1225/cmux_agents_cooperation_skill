#!/usr/bin/env bash
# Atomic lock for a shared resource (tracker spreadsheet, deploy, config...) used by several agents.
# mkdir is atomic: exactly one agent can create the lock directory. Writing a claim into a file and
# reading it back is NOT a lock: two agents can both write, read and believe they won.
#
# Usage (run from the project root, or set COORD_ROOT):
#   coord-lock.sh acquire <resource> "<owner chat>" "<scope>"   # exit 0 acquired, 1 held by someone else
#   coord-lock.sh release <resource> "<owner chat>"             # exit 0 released, 1 not yours / not held
#   coord-lock.sh status  <resource>                            # exit 0 held (prints owner), 1 free
#
# The lock lives at $COORD_ROOT/.<resource>-edit.lock/ with owner.txt inside.
# Also record the claim in PROJECT_STATUS.md §2, and never remove another agent's lock: a lock with no
# owner.txt yet may belong to an agent that is still writing its metadata. Ask the owner, or the user.
set -euo pipefail

usage() { sed -n '2,15p' "$0" >&2; exit 3; }
[[ $# -ge 2 ]] || usage

action=$1 resource=$2
[[ "$resource" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "resource must be [A-Za-z0-9_-]+" >&2; exit 3; }
root=${COORD_ROOT:-$PWD}
lock="$root/.${resource}-edit.lock"

case "$action" in
  acquire)
    [[ $# -ge 4 ]] || usage
    owner=$3 scope=$4
    if mkdir "$lock" 2>/dev/null; then
      {
        printf 'owner: %s\n' "$owner"
        printf 'scope: %s\n' "$scope"
        printf 'started: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
        printf 'host: %s\n' "$(hostname -s 2>/dev/null || echo unknown)"
      } > "$lock/owner.txt"
      echo "acquired $lock"
      echo "Next: record owner, scope and start time in PROJECT_STATUS.md §2."
    else
      echo "HELD: $lock already exists; do not write." >&2
      if [[ -f "$lock/owner.txt" ]]; then cat "$lock/owner.txt" >&2
      else echo "(no owner.txt yet: its owner may still be writing it)" >&2; fi
      exit 1
    fi
    ;;
  release)
    [[ $# -ge 3 ]] || usage
    owner=$3
    [[ -d "$lock" ]] || { echo "not held: $lock does not exist" >&2; exit 1; }
    holder=$(sed -n 's/^owner: //p' "$lock/owner.txt" 2>/dev/null || true)
    if [[ "$holder" != "$owner" ]]; then
      echo "refusing: lock is held by '${holder:-unknown}', not '$owner'. Never remove another agent's lock." >&2
      exit 1
    fi
    rm -f "$lock/owner.txt"
    rmdir "$lock"
    echo "released $lock"
    echo "Next: set PROJECT_STATUS.md §2 back to Free and add a §8 change-log line."
    ;;
  status)
    if [[ -d "$lock" ]]; then
      echo "held: $lock"
      if [[ -f "$lock/owner.txt" ]]; then cat "$lock/owner.txt"; else echo "(no owner.txt yet)"; fi
    else
      echo "free: $lock"
      exit 1
    fi
    ;;
  *) usage ;;
esac
