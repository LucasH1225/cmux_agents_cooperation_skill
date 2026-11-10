#!/usr/bin/env bash
# Show the delivery state of cmux agent messages, so you report "queued" vs "delivered" honestly.
#
# Usage: msg-state.sh [<message-id-prefix>]     # no argument: the 10 most recent messages
set -euo pipefail
command -v cmux >/dev/null 2>&1 || { echo "cmux not found on PATH" >&2; exit 3; }

json=$(cmux agent inbox --json 2>/dev/null) || { echo "cmux agent inbox failed (is cmux running?)" >&2; exit 3; }

CMUX_INBOX_JSON="$json" python3 -I - "${1:-}" <<'PY'
import json, os, sys, datetime

prefix = sys.argv[1]
msgs = json.loads(os.environ["CMUX_INBOX_JSON"]).get("messages", [])
if prefix:
    msgs = [m for m in msgs if m.get("id", "").startswith(prefix)]
    if not msgs:
        print(f"no message with id starting {prefix!r}", file=sys.stderr)
        sys.exit(1)
else:
    msgs = msgs[:10]

def ts(t):
    return datetime.datetime.fromtimestamp(t).strftime("%Y-%m-%d %H:%M") if t else "-"

for m in msgs:
    print(f"{m['id'][:8]}  {m.get('state','?'):9}  from {m.get('sender_name','?')!r}"
          f"  to surface {str(m.get('recipient_surface_id','?'))[:8]}"
          f"  created {ts(m.get('created_at'))}  delivered {ts(m.get('delivered_at'))}")
    if m.get("failure_reason"):
        print(f"          failure: {m['failure_reason']}")
PY
