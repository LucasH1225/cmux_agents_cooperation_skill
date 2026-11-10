# cmux agents cooperation skill

A skill for **several AI coding agents (Claude Code, Codex and others) working on one project folder from different [cmux](https://cmux.com) tabs ([GitHub](https://github.com/manaflow-ai/cmux))** without stepping on each other.

It gives the agents a shared memory and a doorbell:

- **`AGENTS.md`**: one rulebook. Codex loads it automatically; Claude Code loads it through a one-line `CLAUDE.md` (`@AGENTS.md`).
- **`PROJECT_STATUS.md`**: one source of truth, with a roster of chats and owners, claims and work in progress, provenance-tagged facts, an external-actions log, per-chat mailboxes and a tagged change log.
- **`cmux agent message`**: time-sensitive nudges between chats, with routing rules and a message protocol that survives restarts.
- **An atomic `mkdir` lock** for anything two agents could write at once (a tracker spreadsheet, a deploy, a config).

The rules were distilled from a real project in November 2026: seven chats (four Codex, three Claude Code) sharing one folder over several days. [The case study](skills/cmux-agents-cooperation/references/case-study.md) walks through every failure that shaped them.

## Why

Separate agent chats each keep their own picture of the project, and the pictures drift. In the source project, two handoff files disagreed within a day: three different availability dates, an email recorded as both "not sent" and "sent", a letter labelled draft above its final text. cmux messages sat in `queued` because sessions had been launched without cmux's hooks. A restart renumbered every tab. A "claim" written to a file turned out to be racy. A spare chat quietly started duplicating another chat's work.

## Install

The skill is a standard `SKILL.md` folder, so it works in both tools.

```bash
git clone https://github.com/LucasH1225/cmux_agents_cooperation_skill.git
cd cmux_agents_cooperation_skill

# Claude Code: per user, or per project (.claude/skills/)
cp -R skills/cmux-agents-cooperation ~/.claude/skills/

# Codex
cp -R skills/cmux-agents-cooperation ~/.codex/skills/
```

Then ask either agent something like *"set up coordination so you and Codex keep each other updated"*, or *"why are my cmux messages stuck in queued?"*.

## Quick start (by hand)

```bash
S=~/.claude/skills/cmux-agents-cooperation

bash $S/scripts/init-coordination.sh /path/to/project    # copies the templates; never overwrites
# fill in the {{PLACEHOLDERS}}, list your chats in PROJECT_STATUS.md §1

REF=$(bash $S/scripts/cmux-ref.sh "Overall")              # tab title -> current surface ref
cmux agent message "$REF" --from "Claude outreach" "Shared files are ready; please review."
bash $S/scripts/msg-state.sh                              # queued / delivered / read

cd /path/to/project
bash $S/scripts/coord-lock.sh acquire tracker "Codex Overall" "Update row 12"
bash $S/scripts/coord-lock.sh release tracker "Codex Overall"
```

**Before relying on messaging,** launch every agent through cmux's wrapper: type plain `claude` (or `claude --resume <id>`) in a cmux terminal, and use `cmux restore codex <id>` for Codex. A session started by absolute path has no hooks and never receives messages.

## What's inside

```
skills/cmux-agents-cooperation/
├── SKILL.md                     # the workflow: setup, per-task loop, routing, messaging, locks, lists, troubleshooting
├── references/
│   ├── cmux-messaging.md        # delivery mechanics, states, refs, --reply-to, idle sessions, message template
│   └── case-study.md            # what went wrong in a 7-chat project, and what fixed it
├── templates/
│   ├── AGENTS.md                # shared rulebook with {{PLACEHOLDERS}}
│   ├── PROJECT_STATUS.md        # §0 at a glance · §1 sources and roster · §2 claims · ... · §7 notes · §8 change log
│   └── CLAUDE.md                # "@AGENTS.md"
└── scripts/
    ├── init-coordination.sh     # copy templates into a project without overwriting
    ├── cmux-ref.sh              # resolve a tab title to its current surface ref (exact, then unique prefix)
    ├── msg-state.sh             # show queued/delivered/read state of messages
    └── coord-lock.sh            # atomic acquire/release/status lock for a shared resource
```

## Core rules at a glance

1. **Files are the memory; messages are the doorbell.** Anything durable goes in `PROJECT_STATUS.md`.
2. **Re-read before you write**, make narrow edits, and log one tagged, dated batch per task.
3. **Facts carry provenance** (source, date, certainty), and the user's own statements beat agent inferences.
4. **Route by owner** (roster); when unclear, go to the coordinator. Resolve refs by name at send time.
5. **Never type into another agent's prompt.** Use `cmux agent message` and the inbox.
6. **Lock shared resources atomically**; a stale claim is a reason to ask, not to take over.
7. **"Draft finished" isn't "sent".** Log external actions with evidence.
8. **Nothing goes out** (emails, messages, submissions) without the user's explicit approval.

## Requirements

- [cmux](https://cmux.com) with the `cmux agent message` / `cmux agent inbox` commands (tested with cmux 0.65.2, November 2026)
- bash and python3 (standard library only) for the scripts
- Claude Code and/or Codex; other agents can follow `AGENTS.md` if they read it

## License

MIT. See [LICENSE](LICENSE).
