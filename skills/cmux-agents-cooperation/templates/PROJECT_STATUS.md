# Project status — {{PROJECT_NAME}}

Shared coordination file for {{USER_NAME}} and every agent chat. Rules are in [AGENTS.md](AGENTS.md). Read this at the start of every task and again just before editing it.

_Last edited: {{DATE}} by {{CHAT_NAME}}._

## 0. At a glance

### Waiting on {{USER_NAME}}

Genuine blockers only, at most about five. Remove items once resolved.

| # | Item | Why it blocks | Owner chat | Link |
|---|---|---|---|---|
| 1 | | | | |

### Next 14 days

Derived from {{CANONICAL_TRACKER}}. _Last generated: {{DATE}} by {{CHAT_NAME}}._

- 

## 1. Canonical sources

| What | Where | Notes |
|---|---|---|
| {{TRACKER_SCOPE}} | {{CANONICAL_TRACKER}} | **Authoritative.** |
| Coordination, current facts, open questions | This file | Snapshots and links, not a second tracker. |
| Rules for agents | [AGENTS.md](AGENTS.md) | Codex loads it automatically; [CLAUDE.md](CLAUDE.md) imports it for Claude Code. |
| History (archived) | {{OLD_HANDOFFS}} | Dated records; later sources win. |

### Chats and responsibilities

Address chats **by name**; resolve refs with `cmux tree` at send time. Model labels describe the chat; they aren't routing requirements.

| Chat (cmux tab name) | Tool / model | Owns |
|---|---|---|
| **{{COORDINATOR_CHAT}}** | | Coordinator and default router; maintains {{CANONICAL_TRACKER}} under task-specific claims |
| | | |

## 2. Claims

### Shared-resource claim

| Resource | Owner | Scope | Started | Status |
|---|---|---|---|---|
| {{SHARED_RESOURCES}} | — | — | — | **Free** |

### In progress

Work that could overlap another chat's. Delete your row when done.

| Chat | Scope / files | Started | Last update | Next step |
|---|---|---|---|---|

## 3. Core facts

Certainty: **Confirmed** = the user stated it or it's verified in a saved file; **Reported** = from an earlier chat, not rechecked; **Unconfirmed** = still open.

| Fact | Value | Source / date | Certainty |
|---|---|---|---|
| | | | |

## 4. Work items snapshot

Snapshot from {{CANONICAL_TRACKER}}, dated. Check the tracker for the live version.

| Item | Status | Next step |
|---|---|---|
| | | |

### External actions log

Stages: **draft → ready → sent → confirmed**. Never infer "sent" from a finished draft.

| Date | Action | Stage | Evidence | Logged by |
|---|---|---|---|---|
| | | | | |

## 5. Open questions and contradictions

- [ ] 

## 6. Active threads

About five lines each; link to a per-thread file for detail.

- 

## 7. Notes

One heading per chat. Remove only notes addressed to you, after handling them.

### To any / unsure

- _(none)_

### To {{COORDINATOR_CHAT}}

- _(none)_

## 8. Change log

One dated batch per task, tagged with the chat name. Newest first.

- **{{DATE}} · {{CHAT_NAME}}** — Created the coordination files.
