---
name: cmux-agents-cooperation
description: Coordinate several AI agents (Claude Code, Codex or others) that work on the same project folder from different cmux tabs. Sets up a shared AGENTS.md rulebook and a PROJECT_STATUS.md source of truth (roster, mailbox, task claims, change log), an atomic lock for shared resources, routing rules, and cmux agent messaging that actually gets delivered. Use this whenever more than one agent or chat works in the same folder, when the user asks agents to "keep each other updated", "talk to Codex" or "tell Claude", wants a shared status or handoff file, adds or retires a chat, or when `cmux agent message` messages sit in "queued", even if cmux isn't mentioned by name.
---

# cmux agents cooperation

Several agents in one folder behave like colleagues without a shared memory: each chat keeps its own picture of the project, and the pictures drift apart. Handoff notes written by different chats start contradicting each other within a day. This skill gives them **one written source of truth plus a doorbell**:

- **Files are the memory.** `AGENTS.md` holds the rules; `PROJECT_STATUS.md` holds the current facts, who owns what, who is working on what, notes for each chat, and a change log. Anything that matters later goes here.
- **cmux messages are the doorbell.** They tell a specific chat that something changed or needs doing *now*. A message alone is not a record.

Codex reads `AGENTS.md` automatically. Claude Code reads `CLAUDE.md`, which contains just `@AGENTS.md`, so every agent follows the same rulebook.

## 1. Set up a project (once)

1. **Check nothing exists yet.** Look for `AGENTS.md`, `CLAUDE.md` and a status file. If they exist, adapt them rather than replacing them.
2. **Propose before writing.** Describe the plan to the user and, if another agent is already active, message it and ask for refinements (see §4). Agreement first avoids two agents creating competing files.
3. **Get the user's approval**, then let **one** agent create the files:
   ```bash
   bash <skill-dir>/scripts/init-coordination.sh /path/to/project
   ```
   This copies `templates/AGENTS.md`, `PROJECT_STATUS.md` and `CLAUDE.md` without overwriting anything. Fill in the placeholders (`{{...}}`): the user's name, the canonical tracker, the chats.
4. **Seed PROJECT_STATUS.md from existing handoffs**, listing contradictions as open questions rather than resolving them silently. Keep old handoffs as dated, archived history.
5. **Ask the other agents to review** with narrow edits plus a change-log line, then brief any remaining chats.

## 2. Every session, and before every new task

1. Run `cmux agent inbox` and read new messages addressed to you.
2. Read `PROJECT_STATUS.md`: at least §0 (waiting on the user, next deadlines), §2 (claims and work in progress), your heading in §7 (notes), and the newest §8 change-log entries.
3. Act on anything that affects your task before starting it. Handle notes addressed to you, then delete only those.

Why every task and not just every session: other chats keep working while you're idle, and a session can last days.

## 3. Writing to the shared files

- **Re-read immediately before editing.** Another agent may have changed the file a minute ago.
- **Make narrow edits.** Don't rewrite or reorder sections you aren't changing; never edit or delete another chat's notes or log entries.
- **Log one dated batch per task** in the change log, tagged with your chat name (`2026-11-10 · Claude outreach — ...`). Skip temporary or test files.
- **Record provenance for facts:** value, source (who said it, where, when), and certainty (Confirmed / Reported / Unconfirmed). The user's own statements override agent inferences. Keep unresolved contradictions listed; don't pick a side quietly.
- **Keep it readable.** Aim for about five lines per thread summary and link to a per-thread file for detail. Move completed change-log entries older than about two weeks to an archive file, unchanged; never archive open items.

## 4. Routing: who to message

The roster in `PROJECT_STATUS.md` §1 lists each chat (by its cmux tab name), its tool and what it owns.

1. **Owner is clear** → message that chat directly. Routing everything through one hub makes it a bottleneck and burns its context.
2. **Owner unclear, or several chats affected** → message the coordinator chat, which triages and forwards.
3. **Changes to a shared resource** (a tracker spreadsheet, a deploy, a shared config) → the resource's current maintainer or claim holder.
4. **Resolve the surface ref by name at send time.** Refs change whenever cmux restarts:
   ```bash
   REF=$(bash <skill-dir>/scripts/cmux-ref.sh "Overall")   # exact title or unique prefix
   cmux agent message "$REF" --from "Claude outreach" "..."
   ```

## 5. Messaging with cmux

Full mechanics and pitfalls: [references/cmux-messaging.md](references/cmux-messaging.md). The essentials:

- **Delivery needs hooks.** cmux delivers through the receiving agent's hooks, which are added when the agent is launched through cmux's wrapper: plain `claude` typed in a cmux terminal, or `cmux restore codex <id>`. A Claude started by absolute path (e.g. `~/.local/bin/claude`) has no hooks, so its messages stay `queued` forever. Fix: exit and relaunch with plain `claude --resume <session-id>`.
- **Never type into another agent's live prompt** (`cmux send`) as a workaround. Text can merge with what the user is typing or sit unsubmitted. Use messaging and the inbox only.
- **Write self-contained messages:** the concrete task or fact, the intended recipient, the source, and the next action. Pass `--from "<your chat name>"`, because the default sender is the *workspace* title, which several chats share.
- **Track states honestly:** queued → delivered → read → completed. `cmux agent inbox --json` shows the delivery state; `scripts/msg-state.sh <id-prefix>` prints it. Don't tell the user a chat "knows" something that is only queued.
- **Idle chats:** an idle Claude Code session is woken by a message. An idle Codex session picks it up at its next prompt, so ask the user to nudge it ("check your cmux inbox").
- **`--reply-to` goes to the original sender.** Replying to your *own* outgoing message loops back to you. Send follow-ups fresh to the resolved recipient, and check `recipient_surface_id` when it matters.
- **Acknowledge actionable handoffs once.** Never acknowledge an acknowledgement.

## 6. Shared resources and locks

For anything two agents could write at once (a tracker spreadsheet and its scripts, a deployment, a database), use an atomic lock plus a visible claim:

```bash
bash <skill-dir>/scripts/coord-lock.sh acquire tracker "Codex Overall" "Update row 12 status"
# ... edit, verify, log ...
bash <skill-dir>/scripts/coord-lock.sh release tracker "Codex Overall"
```

`mkdir` is atomic, so only one agent can create `.tracker-edit.lock/`. Writing a claim into the status file and reading it back is *not* enough: two agents can both write, read and believe they won. After acquiring the lock, record owner, scope and start time in the status file's claim table as well.

- Release only your own lock. Never delete another agent's.
- About **two hours** without an update is a prompt to inspect and ask the owner, never an automatic expiry. A quiet log doesn't prove a task was abandoned. If ownership can't be established, ask the user.
- If an edit path bypasses the resource's own automation (e.g. API writes don't fire a spreadsheet's on-edit script), document what must be maintained by hand in `AGENTS.md`.

## 7. Shared lists in PROJECT_STATUS.md

| List | Purpose | Discipline |
|---|---|---|
| **§0 Waiting on the user** | Decisions, facts or actions only the user can give | At most about five genuine blockers, each with the owner chat, why it blocks and a link. Remove when resolved. |
| **§0 Next 14 days** | Upcoming deadlines | Derive from the canonical tracker with a checked date. Don't hand-maintain a competing list. |
| **§2 In progress** | Task claims for work that could overlap (same files, same person, same resource) | Scope, start, last update, next step. Delete your row when done. Independent research needs no row. |
| **§4 External actions log** | Emails, messages, submissions | Stages draft → ready → sent → confirmed, with date and evidence. **Never infer "sent" from a finished draft.** |
| **§7 Notes** | Durable mailbox, one heading per chat plus "To any / unsure" | Remove only notes addressed to you, after handling them. |

## 8. Conduct

- Don't send emails or messages, submit applications, publish, or contact third parties without the user's explicit approval of that specific action and final text.
- Don't close, restart or retire another chat yourself. Mark it in the roster and let the user close the tab.
- Back up a file before overwriting it, and preserve the user's own edits.

## 9. Adding or retiring a chat

- **Add:** launch through the wrapper so it has hooks, e.g. `cmux new-surface --pane <pane> --working-directory <dir> --focus false --command "claude --name '<Tab name>' '<first-turn brief>'"`. Give it a first-turn brief that says to read the shared files and wait. Add a roster row and a §7 heading.
- **Retire:** mark the roster row "Retiring" and leave a §7 note: take no new work, log any outcomes with evidence, hand unfinished drafts to the new owner, then tell the user the tab can be closed. Message it too, so it sees the note at its next step.

## 10. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Messages stay `queued` | Recipient launched without cmux hooks | Relaunch via plain `claude --resume <id>` or `cmux restore codex <id>` |
| "No workspace or surface matches" | Refs changed after a cmux restart | Re-resolve with `scripts/cmux-ref.sh` |
| Reply arrives back at yourself | `--reply-to` on your own message | Send fresh to the resolved recipient |
| Two chats did the same task | No claim or roster owner | Add a roster owner and an §2 In progress row |
| Status file contradicts a handoff | Handoffs are snapshots | Later explicit user statements win; log the contradiction |
| Text copied from an exported doc is mangled | Doc export added escapes and links and merged lines | Copy from the original source, not the export |

For the full story behind these rules, see [references/case-study.md](references/case-study.md).
