# Agent rules — {{PROJECT_NAME}}

These rules apply to every assistant working in this folder (Codex, Claude Code and any other agent). {{USER_NAME}} is the user; their instructions override this file.

## 1. Every session, and before every new task

1. Run `cmux agent inbox` and handle messages addressed to you.
2. Read [PROJECT_STATUS.md](PROJECT_STATUS.md): §0 At a glance, §2 Claims and In progress, your heading in §7 Notes, and the newest §8 Change log entries.
3. Act on anything that affects your task before starting it. Handle notes addressed to you, then delete only those notes.
4. Older handoff files are archived history. Where they conflict with PROJECT_STATUS.md or a later statement from {{USER_NAME}}, the later source wins.

## 2. Sources of truth

- **{{CANONICAL_TRACKER}}** is authoritative for {{TRACKER_SCOPE}}. Copies elsewhere are backups.
- **PROJECT_STATUS.md** is the coordination and current-facts index. It holds dated snapshots and links; it doesn't duplicate the tracker.
- **{{USER_NAME}}'s direct statements override agent inferences.** Record each important fact's source, the date it was confirmed and its certainty (Confirmed / Reported / Unconfirmed). Keep unresolved contradictions listed; don't silently pick one side.
- Official requirements and deadlines need their own source and the date checked. An earlier finding isn't a live check.

## 3. Editing PROJECT_STATUS.md

- Re-read the file **immediately before** editing; another agent may have changed it.
- Make narrow edits. Don't rewrite or reorder sections you aren't changing.
- After each task that changes a fact, a work item or a user-facing file, add **one dated batch** to §8, tagged with your chat name. Temporary or test files don't need logging.
- Never edit or delete another chat's notes or log entries. Update "Last edited" at the top.
- **Keep it readable:** about five lines per thread summary in §6, with detail in a linked per-thread file. Shorten your own entries, not other chats'.
- **Archiving:** completed change-log entries older than 14 days may be moved, unchanged and dated, to `PROJECT_STATUS_ARCHIVE.md`. Never archive open facts, notes, claims or pending messages.

## 4. Shared resources and locks

Shared resources: {{SHARED_RESOURCES}}.

1. **Claim before writing:** acquire the atomic lock (`mkdir .<resource>-edit.lock`, never `-p`, or `scripts/coord-lock.sh acquire <resource> "<chat>" "<scope>"`). If it exists, don't write. Then record owner, scope and start time in §2 and re-read to confirm.
2. **Release when done:** set §2 back to Free, log in §8, then remove only your own lock.
3. **Stale claims:** about two hours without an update is a prompt to inspect and ask the owner via cmux. It is never an automatic expiry. If ownership can't be established, ask {{USER_NAME}}.
4. {{RESOURCE_SPECIFIC_RULES}}

## 5. Conduct

- Don't send emails or messages, submit, publish, or contact third parties without {{USER_NAME}}'s explicit approval of that specific action.
- Don't treat a finished draft as sent or submitted.
- Don't close, restart or retire another chat; mark it in the roster and let {{USER_NAME}} close it.
- Back up a file before overwriting it, and preserve {{USER_NAME}}'s own edits.

## 6. Messaging between agents (cmux)

- Send: `cmux agent message <ref> --from "<your chat name>" "<text>"`. Reply: `cmux agent message --reply-to <id> --from "<your chat name>" "<text>"`.
- **Resolve refs by tab name just before sending** (`cmux tree` or `scripts/cmux-ref.sh "<name>"`). Refs change whenever cmux restarts.
- Delivery needs the recipient to have been launched through cmux's wrapper (plain `claude`, or `cmux restore codex <id>`). Check `cmux agent inbox` as a fallback.
- **Don't type into another agent's live prompt.**
- **Routing:** owner clear in §1 → message that chat directly; owner unclear or several chats affected → {{COORDINATOR_CHAT}}; shared-resource changes → its current maintainer or claim holder.
- **Content:** the concrete task or fact, the recipient, the source, and the next action required. Durable items also go in §7 under the recipient's heading.
- **States:** distinguish queued, delivered, read and completed. Don't claim a queued message was read. An idle Codex chat receives at its next prompt; ask {{USER_NAME}} to nudge it if urgent.
- `--reply-to` goes to the **original sender**; send follow-ups to your own messages fresh. Acknowledge actionable handoffs once; never acknowledge acknowledgements.

## 7. Shared lists in PROJECT_STATUS.md

- **§0 Waiting on {{USER_NAME}}:** genuine blockers only, at most about five, each with owner chat, reason and link. Remove when resolved.
- **§0 Next 14 days:** derived from {{CANONICAL_TRACKER}} with the date checked. Don't hand-maintain a competing list.
- **§2 In progress:** a row before starting work that could overlap another chat's (same files, person or resource). Delete it when done.
- **§4 External actions log:** emails, messages and submissions, with stage (draft → ready → sent → confirmed), date and evidence. Never infer "sent" from a finished draft.
