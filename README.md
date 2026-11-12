# figma-accounts — several Figma accounts in Claude Code at once

Claude Code's Figma connection signs in to one Figma account. If your designs live in a
personal account and a work account or two, you end up disconnecting and reconnecting to
switch. This skill connects all of them at the same time, and lets Claude pick the right
one for each Figma link.

## How it works

- Every account is its own copy of **Figma's official MCP server**
  (`https://mcp.figma.com/mcp`), registered at user scope as `figma-<name>`.
  Claude Code keeps one OAuth login per server name, so each copy stays signed in to its
  own account. Nothing about Figma's server is modified; you get all its tools
  (`get_design_context`, `get_screenshot`, `use_figma`, …) on every account.
- The `figma-account` command adds, lists and removes accounts, and remembers which
  account owns which file in `accounts.json` (local only, git-ignored, no secrets).
- The skill (`SKILL.md`) tells Claude how to route: a known file goes straight to its
  account; an unknown one is tried on each signed-in account until one can open it, and
  the match is remembered.
- Tokens stay in Claude Code's own credential store; this tool never reads them out.

## Install

Needs Claude Code and Python 3 (macOS: the sign-in check uses the login keychain).

```bash
git clone https://github.com/GustavoGomez092/claude-figma-accounts ~/.claude/skills/figma-accounts
ln -s ~/.claude/skills/figma-accounts/figma-account ~/.local/bin/figma-account   # any dir on PATH
```

## Add accounts

```bash
figma-account add personal
figma-account add work-acme      # lowercase letters, digits, hyphens
```

Then **restart Claude Code** (a running session only sees servers that existed when it
started; `claude --continue` resumes your conversation). In Claude Code run `/mcp`, pick
`figma-personal` → **Authenticate**, with your browser signed in to that Figma account.
Repeat for each account, switching the browser's Figma account before each sign-in.

## Use

Paste any Figma link and ask for what you want ("build this section", "screenshot this
frame"). Claude picks the account and says which one it used when it isn't obvious.

```bash
figma-account list                       # accounts, signed in or not, files remembered
figma-account which <figma-url>          # which account owns this file
figma-account remember <name> <url>      # tell it yourself
figma-account whois <name> "me@work.com" # label an account
figma-account remove <name>
```

Signed in to the wrong account? `/mcp` → `figma-<name>` → Clear authentication, then
Authenticate again.

## Test

```bash
tests/test.sh    # uses a throwaway HOME and a fake `claude`; never touches your config
```

## License

MIT
