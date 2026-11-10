# Case study: seven agent chats, one project folder

How the rules in this skill came about, from a real project in November 2026. Personal details have been removed.

## Contents

1. Setting
2. Timeline of problems and fixes
3. What worked
4. What we'd do differently from day one
5. Open limitations

## 1. Setting

A student ran a summer-internship application project from one folder. Over about four days, work spread across **seven chats in one cmux workspace**:

| Chat | Tool | Job |
|---|---|---|
| Overall | Codex | Coordinator; maintained the application tracker (a Google Sheet with an on-edit script) |
| finding | Codex | Internship research and eligibility checks |
| Research | Codex | Programme research and a learning plan |
| Technical | Codex | Interview preparation and a portfolio project plan |
| cover letters | Claude Code | Letters, CVs, and (as it turned out) coordination setup |
| outreach | Claude Code | Drafting emails and messages to people |
| a seventh chat | Claude Code | Started for something else; drifted into drafting emails |

The user switched between tabs, often relaying information by hand.

## 2. Timeline of problems and fixes

### 2.1 Two handoff files, three versions of the truth

Each tool had written its own handoff document. Within a day they disagreed: the availability end date existed in three versions (end of August, 30 September, "July–September" on the CV); one file said an email was "not confirmed sent" after the user had already said it was sent; one letter was labelled "almost final" above a fully corrected text.

**Fix:** one shared `PROJECT_STATUS.md` with provenance on every fact (source, date, certainty), contradictions listed as open questions, and the rule that **later explicit statements by the user win**. The handoffs became archived history. The date conflict was settled by asking the user once, then recording the answer with its source.

### 2.2 "Can you talk to Codex?" No, at first

The Claude session's own agent-messaging tool only reached other Claude sessions. The two tools had no shared channel except the filesystem.

**Fix:** the files became the channel. Codex reads `AGENTS.md` automatically; Claude reads `CLAUDE.md`, which imports it with `@AGENTS.md`. Both load the same rules with no copy-and-paste.

### 2.3 cmux messages stuck in "queued"

The first `cmux agent message` from Claude to Codex queued with "No agent activity seen on that surface yet". Codex's reply also queued and never arrived. Diagnosis: the Claude session had been launched by **absolute path** from another chat's script, which bypassed cmux's `claude` shim, so it had no hooks. The Codex sessions likewise hadn't been launched through cmux.

**Fix:** relaunch through the wrapper (`claude --resume <id>`; `cmux restore codex <id>`). After the relaunch, the backlog was delivered immediately as hook feedback. **Lesson:** check delivery capability before relying on it, and never claim a message was received when it's only queued.

### 2.4 The tempting workaround: typing into the other prompt

While hooks were missing, Claude typed its message into Codex's idle prompt with `cmux send`. It worked, but the first Enter was swallowed by the paste and the text sat unsubmitted until a second Enter. Codex then asked Claude to stop: injected text is indistinguishable from the user's own words and can collide with what the user is typing.

**Rule:** no typing into live prompts; messaging and inbox only.

### 2.5 Surface refs changed after a restart

cmux restarted, every `surface:` number changed, and messages that quoted the old refs now pointed nowhere. A reply addressed by the old ref failed with "No workspace or surface matches".

**Rule:** the roster stores chat *names*; resolve the ref at send time (`scripts/cmux-ref.sh`).

### 2.6 A claim that wasn't a lock

The first tracker rule was "write your name in the claim table, then read it back". Codex pointed out the race: two agents can both write, both read their own write, and both proceed.

**Fix:** an atomic `mkdir .tracker-edit.lock` (never `mkdir -p`), with owner metadata inside it, *then* the visible claim row. Release only your own lock. A stale claim is a prompt to ask the owner, never an automatic expiry.

### 2.7 `--reply-to` looping back to the sender

Codex followed up on its own message using `--reply-to <its own message id>`. The follow-up went to Codex itself, because `--reply-to` targets the original sender.

**Rule:** follow-ups are sent fresh to the resolved recipient; verify `recipient_surface_id` when it matters.

### 2.8 Everyone was called "Intern"

The default `--from` is the workspace title, so every chat's messages appeared to come from the workspace name.

**Rule:** always pass `--from "<chat name>"`.

### 2.9 Overlapping chats

A seventh chat, started for another purpose, began drafting the same emails the outreach chat owned. Nothing in the files said who owned outreach, so nothing stopped it.

**Fix:** a roster ("Chats and responsibilities") with one owner per area, an **In progress** table for work that could overlap, routing rules (direct to owner; unclear or cross-cutting work to the coordinator), and a retirement procedure: mark the chat "Retiring", hand off drafts, log outcomes, and let the user close the tab.

### 2.10 "Draft finished" isn't "sent"

Several times an agent was one step from recording an email as sent because the draft was final. In one case the only evidence was the user's own unsubmitted text in another chat's prompt.

**Fix:** an External actions log with stages (draft → ready → sent → confirmed) and an evidence column. Unsubmitted or second-hand evidence is logged as "reported; confirm", and the confirmation request goes on the "Waiting on the user" list.

### 2.11 The status file started to sprawl

One thread's summary grew past 200 words of interleaved updates, and the change log grew by several long entries a day.

**Fix (soft):** about five lines per thread summary with detail in a linked per-thread file; archive completed change-log entries older than two weeks; a short "At a glance" section at the top with at most about five genuine blockers for the user and the next 14 days of deadlines.

### 2.12 Idle Codex chats didn't hear the doorbell

Briefings to two idle Codex chats stayed queued for a day; they arrived only when the user next typed in those tabs.

**Rule:** durable items also go into the per-chat mailbox in `PROJECT_STATUS.md` §7; tell the user which tab needs a nudge.

### 2.13 Exported documents mangle text

A handoff that had round-tripped through an online document editor came back with escaped characters (`\+`, `\|`), emails turned into Markdown links, and header lines merged.

**Rule:** don't copy final text (letters, emails) out of exported or converted files; use the original.

## 3. What worked

- **Propose, refine, approve, write once, review.** One agent proposed; the other replied with numbered refinements; the user approved; one agent wrote the files; the other reviewed with narrow edits and a change-log line. No competing files were ever created.
- **Tagged, dated change-log batches.** Every chat could see what changed since it last looked, and by whom.
- **Provenance columns.** "Confirmed / Reported / Unconfirmed", with source and date, stopped agents re-deriving or overwriting each other's facts.
- **User statements override inferences,** and contradictions stay visible until the user resolves them.
- **A coordinator that triages but doesn't own everything.** Direct messages to clear owners kept the coordinator's context free.

## 4. What we'd do differently from day one

1. Launch every chat through the cmux wrapper, and test one round-trip message before starting work.
2. Create the roster, the files and the lock script before the second chat opens.
3. Pass `--from` on every message.
4. Start the External actions log with the first draft, not after the first confusion.
5. Use one handoff format from the start, so a fresh chat can bootstrap from `PROJECT_STATUS.md` alone.

## 5. Open limitations

- Idle Codex sessions need a human nudge; there is no automatic wake-up.
- The lock is local to one machine's filesystem. Agents on different machines need a shared lock (e.g. a lock row in the shared spreadsheet, or a remote service).
- Nothing enforces the rules; they rely on every agent reading `AGENTS.md`. Short, explained rules are followed far more reliably than long lists of MUSTs.
