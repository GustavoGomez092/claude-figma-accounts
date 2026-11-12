#!/usr/bin/env bash
# Exercises figma-account against a throwaway HOME, a fake `claude` CLI and a temp
# account list, so the real Claude Code config is never touched. Run: tests/test.sh
set -u
F="$(cd "$(dirname "$0")/.." && pwd)/figma-account"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/home"
cat > "$T/bin/claude" <<'PY'
#!/usr/bin/env python3
import json, os, sys
p = os.path.expanduser("~/.claude.json")
d = json.load(open(p)) if os.path.exists(p) else {}
a, s = sys.argv[1:], d.setdefault("mcpServers", {})
if a[:2] == ["mcp", "add"]: s[a[-2]] = {"type": "http", "url": a[-1]}
elif a[:2] == ["mcp", "remove"]: s.pop(a[-1])
json.dump(d, open(p, "w"))
PY
chmod +x "$T/bin/claude"
# Fake keychain: like a real Mac with a stale item, only the per-user item (-a $USER)
# holds the logins; a lookup without -a gets the stale one.
cat > "$T/bin/security" <<'SH'
#!/bin/sh
case "$*" in
  *"-a $USER"*) echo '{"mcpOAuth":{"figma-personal|abc":{"accessToken":"x"},"figma-work-acme|abc":{}}}' ;;
  *) echo '{"mcpOAuth":{}}' ;;
esac
SH
chmod +x "$T/bin/security"
echo '{"mcpServers":{"Figma":{"type":"http","url":"http://127.0.0.1:3845/mcp"}}}' > "$T/home/.claude.json"
run() { HOME="$T/home" PATH="$T/bin:$PATH" FIGMA_ACCOUNTS_FILE="$T/accounts.json" "$F" "$@"; }
fail() { echo "FAIL: $*"; exit 1; }

run list | grep -q "No Figma accounts" || fail "empty list"
run add personal >/dev/null || fail "add"
run add figma-work-acme >/dev/null || fail "add with figma- prefix"
run add personal | grep -q "already registered" || fail "add is idempotent"
run add "Bad Name" 2>/dev/null && fail "bad name accepted"
python3 -c "
import json; s = json.load(open('$T/home/.claude.json'))['mcpServers']
assert set(s) == {'Figma', 'figma-personal', 'figma-work-acme'}, s
assert s['figma-personal']['url'] == 'https://mcp.figma.com/mcp'" || fail "config"
U="https://www.figma.com/design/AbC123xyz/Landing?node-id=1-2&t=zz"
run which "$U" 2>/dev/null && fail "unknown file resolved"
run remember personal "$U" | grep -q "AbC123xyz → figma-personal" || fail "remember"
[ "$(run which "https://figma.com/design/AbC123xyz/branch/BrX/Landing")" = figma-personal ] || fail "branch link"
run remember work-acme "$U" >/dev/null
[ "$(run which "$U")" = figma-work-acme ] || fail "reassign to another account"
grep -q "t=zz" "$T/accounts.json" && fail "query string stored"
run whois personal me@example.com >/dev/null
run list | grep -q "figma-personal: .*who: me@example.com" || fail "list shows who"
run list | grep -q "figma-personal: signed in" || fail "signed-in account shown as signed in"
run list | grep -q "figma-work-acme: needs sign-in" || fail "account without token shown as needing sign-in"
run remove work-acme >/dev/null
run list | grep -q work-acme && fail "remove"
run which "https://example.com/x" 2>/dev/null; [ $? = 2 ] || fail "non-Figma link exit code"
echo "ALL PASS"
