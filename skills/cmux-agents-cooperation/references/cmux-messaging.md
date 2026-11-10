# cmux agent messaging: mechanics and pitfalls

Verified with the cmux CLI in November 2026. Run `cmux agent message --help` and `cmux agent inbox --help` to check your version.

## Contents

1. Commands
2. How delivery works
3. Checking whether a session can receive
4. Message states
5. Addressing: refs, names and senders
6. Replies and follow-ups
7. Idle sessions
8. Why not type into the other agent's prompt
9. Message template

## 1. Commands

```bash
cmux tree                                   # human-readable layout: workspaces > panes > surfaces (tabs)
cmux --json tree --all                      # same, as JSON (used by scripts/cmux-ref.sh)
cmux identify --json                        # who am I (caller surface/workspace)

cmux agent message <target> [--from <name>] [--thread <id>] [--json] -- "<text>"
cmux agent message --reply-to <message-id> [--from <name>] "<text>"
echo "long text" | cmux agent message <target> -          # read the body from stdin

cmux agent inbox [--surface <target>] [--state queued|delivered|read|failed] [--limit <n>] [--mark-read] [--json]
cmux agent messages status [<target>]       # are messages to a surface on or off?
cmux read-screen --surface <ref> --lines 20 # look at a tab without touching it (observation only)
```

`<target>` is a surface ref (`surface:12`), a workspace ref, or a workspace title (exact match, then unique prefix). Workspace targets are ambiguous when several agents share one workspace, so prefer surface refs resolved by tab title.

## 2. How delivery works

cmux never types messages into the terminal. It queues them and hands them to the receiving agent through that agent's **hooks** (for example a Claude Code Stop, SessionStart or UserPromptSubmit hook). The receiving agent then sees the message as hook feedback, with its id, the sender and the exact `--reply-to` command.

The hooks are injected when the agent is launched **through cmux's wrapper**:

- **Claude Code:** inside a cmux terminal, `claude` on `PATH` resolves to a per-surface shim that calls `cmux-claude-wrapper`, which adds `--settings` with the hook configuration. Launching by absolute path (`/Users/me/.local/bin/claude ...`), or from a script that does, **bypasses the shim**, so there are no hooks and messages never deliver.
- **Codex:** sessions launched or restored through cmux (`cmux restore codex <session-id>`, or `codex` inside a cmux terminal) received messages in our setup. Per cmux's documentation at the time, installing persistent hooks with `cmux hooks codex install` was not, on its own, enough to receive messages; wrapper-launched sessions were.

## 3. Checking whether a session can receive

- `cmux agent inbox --json`: a message that stays `queued` while the recipient is busy and active suggests the recipient has no hooks.
- For Claude Code, inspect the process: `ps -o command -p <pid>`. A wrapper-launched session has a `--settings` argument containing cmux hook settings. A bare `claude --name ... --session-id ...` started by path does not.
- The sender's command output says `No agent activity seen on that surface yet` when cmux has never seen hook activity from the recipient.
- A tree or surface inventory field such as `agent: null` was **not** a reliable indicator in our tests; delivery still worked.

**Fix:** exit the session and relaunch it through the wrapper, keeping its history (`claude --resume <session-id>`, `cmux restore codex <session-id>`). Claude Code's `/restart` may be unavailable while Remote Control is connected; exit and relaunch instead.

## 4. Message states

`queued` → `delivered` (handed to the recipient's hook) → `read` (marked read) → *completed* (the requested action was done, which only the recipient's reply or log entry can tell you).

Report the state you can verify. "Sent, still queued" and "delivered and acknowledged" are different claims. `scripts/msg-state.sh <id-prefix>` prints the state, sender and recipient of one message.

## 5. Addressing: refs, names and senders

- **Refs change when cmux restarts** (`surface:1000030004` became `surface:1000040000` after a restart). Store chat *names* in the roster, never refs, and resolve them just before sending (`scripts/cmux-ref.sh "<tab title>"`).
- Tab titles can carry suffixes such as `Overall · cmux`. `cmux-ref.sh` matches an exact title first, then a unique prefix, and fails loudly on zero or several matches.
- **Default sender name = workspace title.** If five chats share the workspace "Project", every message says it's from "Project". Always pass `--from "<chat name>"`.

## 6. Replies and follow-ups

`--reply-to <id>` addresses the **original sender of message `<id>`**. That's right for answering someone, but a follow-up to a message *you* sent, made with `--reply-to <your-own-id>`, comes back to you. For follow-ups, resolve the recipient again and send a fresh message. When it matters, verify with `cmux agent inbox --json` that `recipient_surface_id` is the intended chat.

Acknowledge an actionable handoff once. Don't acknowledge acknowledgements; two polite agents can loop indefinitely.

## 7. Idle sessions

- An idle **Claude Code** session is woken by an incoming message.
- An idle **Codex** session didn't wake in our setup; it received the message at its next prompt or stop. If something is urgent, ask the user to type "check your cmux inbox" in that tab, and write the item into `PROJECT_STATUS.md` §7 as well, so it isn't lost if the session is never resumed.

## 8. Why not type into the other agent's prompt

`cmux send` and `cmux send-key` can type text and press Enter in another tab. It's tempting when hooks are missing, but:

- the text can merge with something the user is half-way through typing, or land in a dialog;
- pasted text may sit unsubmitted (in our case the first Enter was swallowed by bracketed paste and a second Enter was needed);
- the receiving agent can't tell your text from the user's own instructions, which blurs who asked for what.

Use it at most once, with the user's go-ahead, to bootstrap messaging. Then fix the hooks and stop.

## 9. Message template

```
From: <chat name>   To: <chat name>
Source: <who said it / where / when>   (e.g. "the user, 10 Nov, in the outreach chat")
Fact or task: <one or two sentences, self-contained>
Next action for you: <what the recipient should do, or "FYI, no action">
Durable copy: <where it's recorded, e.g. PROJECT_STATUS §7 / §8>
```
