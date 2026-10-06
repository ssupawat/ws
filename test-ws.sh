#!/bin/bash
# Functional tests for ws.sh. Run: bash test-ws.sh  or:  zsh test-ws.sh
set -u
WS_SRC=$(cd "$(dirname "$0")" && pwd)/ws.sh
TMP=$(mktemp -d)
export HOME="$TMP/home"
mkdir -p "$HOME"
BASE="$HOME/.workspaces"

# local git remote to avoid network
git init -q --bare "$TMP/remote.git"
git init -q "$TMP/seed"
cd "$TMP/seed" && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init && git push -q "$TMP/remote.git" main 2>/dev/null || git push -q "$TMP/remote.git" master

source "$WS_SRC"

pass=0; fail=0
check() { # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL: $1
  expected: [$2]
  actual:   [$3]"; fi
}

# 1. no args: usage on stderr, rc 1
out=$(ws 2>/dev/null); rc=$?
check "no-args rc" "1" "$rc"
check "no-args stdout empty" "" "$out"
err=$(ws 2>&1 1>/dev/null)
check "no-args usage on stderr" "Usage: ws <id> [repo...] | ws ls | ws rm <id>" "$err"

# 2. help: usage on stdout, rc 0
out=$(ws help); rc=$?
check "help rc" "0" "$rc"
check "-h rc" "0" "$(ws -h >/dev/null; echo $?)"
check "--help rc" "0" "$(ws --help >/dev/null; echo $?)"
check "help stdout" "Usage: ws <id> [repo...] | ws ls | ws rm <id>" "$out"

# 3. create workspace, cd into it (verify pwd inside the subshell)
out=$(cd "$HOME" && ws proj && pwd)
check "create msg+pwd" "$(printf 'created: proj\n%s' "$BASE/proj")" "$out"

# 4. open existing
out=$(cd "$HOME" && ws proj 2>&1)
check "open msg" "opened: proj" "$out"

# 5. create with repo clone (stderr discarded: git prints its own progress)
out=$(cd "$HOME" && ws cl "$TMP/remote.git" 2>/dev/null)
check "clone msg" "created: cl" "$out"
[ -n "$(ls "$BASE/cl" 2>/dev/null)" ] && cloned=yes || cloned=no
check "clone content" "yes" "$cloned"

# 6. ls lists only directories, sorted
mkdir -p "$BASE/.hidden" "$BASE/notdir" 2>/dev/null
touch "$BASE/afile"
out=$(cd "$HOME" && ws ls)
check "ls dirs only" "$(printf 'cl\nnotdir\nproj')" "$out"
rmdir "$BASE/.hidden"; rmdir "$BASE/notdir"; rm -f "$BASE/afile"

# 7. no side effects: ls/rm/invalid id must not create WS_BASE
NB="$TMP/nobase"
WS_BASE="$NB" ws ls >/dev/null 2>&1
check "ls no mkdir" "" "$([ -d "$NB" ] && echo created || true)"
WS_BASE="$NB" ws rm x >/dev/null 2>&1
check "rm no mkdir" "" "$([ -d "$NB" ] && echo created || true)"
WS_BASE="$NB" ws "a/b" >/dev/null 2>&1
check "invalid-id no mkdir" "" "$([ -d "$NB" ] && echo created || true)"

# 8. invalid ids (errors on stderr, rc 1)
for bad in "a/b" "." ".."; do
  out=$(ws "$bad" 2>/dev/null); rc=$?
  check "invalid id '$bad' rc" "1" "$rc"
  check "invalid id '$bad' stderr" "invalid id" "$(ws "$bad" 2>&1 1>/dev/null)"
done

# 9. dot inside an id is allowed (README corrected to match)
out=$(ws "foo.bar" 2>/dev/null); rc=$?
check "dot-in-id allowed rc" "0" "$rc"
check "dot-in-id dir" "1" "$([ -d "$BASE/foo.bar" ] && echo 1)"
cd "$HOME" && ws rm foo.bar >/dev/null

# 10. rm: not found, missing id under set -u, success message
out=$(cd "$HOME" && ws rm nope 2>/dev/null)
check "rm missing stdout empty" "" "$out"
check "rm missing stderr" "not found: nope" "$(cd "$HOME" && ws rm nope 2>&1 1>/dev/null)"
check "rm missing rc" "1" "$(cd "$HOME" && ws rm nope >/dev/null 2>&1; echo $?)"
out=$(cd "$HOME" && ws rm 2>&1)
check "rm no id under set -u" "invalid id" "$out"

# 11. rm from inside moves you to $HOME; message confirms deletion
# (direct call: cd must move the real shell, not a subshell)
cd "$BASE/proj" && ws rm proj > "$TMP/msg" 2>/dev/null
check "rm msg" "deleted: proj" "$(cat "$TMP/msg")"
check "rm from inside pwd" "$HOME" "$PWD"
check "rm removed" "" "$(ls "$BASE" | grep proj || true)"

# 12. clone failure: workspace removed, back where you started, message on stderr
out=$(cd "$TMP/seed" && ws bad "$TMP/remote.git" "$TMP/does-not-exist" 2>/dev/null; pwd)
check "clone-fail pwd" "$TMP/seed" "$out"
check "clone-fail cleanup" "" "$(ls "$BASE" | grep bad || true)"
err=$(cd "$HOME" && ws bad2 "$TMP/does-not-exist" 2>&1 1>/dev/null | grep -F 'clone failed:')
check "clone-fail stderr" "clone failed: $TMP/does-not-exist (removed workspace: bad2)" "$err"

# 13. empty ls: silent, rc 0, even when base does not exist
out=$(WS_BASE="$TMP/emptybase" ws ls 2>/dev/null); rc=$?
check "empty ls rc" "0" "$rc"
check "empty ls output" "" "$out"

echo "---"
[ -n "${ZSH_VERSION:-}" ] && mode=zsh || mode=bash
echo "shell=$mode pass=$pass fail=$fail"
rm -rf "$TMP"
[ "$fail" -eq 0 ]
