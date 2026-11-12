---
name: figma-accounts
description: Use whenever a Figma link or Figma design is involved in Claude Code (design-to-code, screenshots, metadata, variables, FigJam) — the user has several Figma accounts connected at once as `figma-<name>` MCP servers, and this picks the right one. Also use when the user wants to add, remove, list or sign in a Figma account, or a Figma tool says the file is not found / no access.
---

# Several Figma accounts at once

Every Figma account is its own copy of Figma's official MCP server, registered at user scope
as `figma-<name>` (tools: `mcp__figma-<name>__get_design_context`, `…__get_screenshot`, …).
Each copy keeps its own login, so all accounts work side by side. The command
`figma-account` (this folder, also on PATH) manages them and remembers which account owns
which file in `accounts.json` (no secrets in it).

The claude.ai connector (`mcp__claude_ai_Figma__*`) and the desktop-app server (`Figma`,
127.0.0.1:3845) are separate single-account things. Don't use them for the user's linked
accounts unless the user asks.

## Picking the account for a link

1. `figma-account which "<url>"` → prints `figma-<name>`: use that server's tools.
2. Exit 1 (unknown file): `figma-account list`, then try the signed-in accounts one by one
   with a cheap call (`get_metadata` on the node, or the file's root) until one succeeds.
   "Not found", 403 or "no access" means wrong account: try the next one. Never conclude a
   file is missing until every signed-in account has been tried.
3. When one works: `figma-account remember <name> "<url>"`, then continue the task on it.
4. If none can open it: say which accounts were tried and ask which account owns the file
   (it may need sign-in, or the file isn't shared with any linked account).

Mention which account you used in one short line when it isn't obvious.

## Other Figma rules still apply

The Figma server's own instructions (create_session first, load /figma-design-to-code
before get_design_context, URL parsing of node-id `1-2` → `1:2`) apply to every
`figma-<name>` server the same way. A session id belongs to the server that created it;
don't pass one account's session to another account's tools.

## Managing accounts

- Add: `figma-account add <name>` (lowercase, digits, hyphens). Then the user signs in:
  restart Claude Code first (a running session never sees servers added after it started,
  and /reload-skills doesn't help; `claude --continue` keeps the conversation), then
  `/mcp` → `figma-<name>` → Authenticate, with the browser on the right Figma account.
  Several to add? Add them all, then one restart.
  Signing in opens a browser and needs the user: tell them, don't attempt it yourself.
- Who is it: call that server's `whoami`, then `figma-account whois <name> "<email / handle>"`.
- List: `figma-account list` (registered, signed in or needs sign-in, who, files remembered).
- Remove: `figma-account remove <name>` (config + account list; its keychain login is left
  behind harmlessly; `/mcp` can clear it).
- Wrong account signed in to a server: `/mcp` → `figma-<name>` → Clear authentication, then
  Authenticate again with the browser on the right account.
