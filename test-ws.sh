#!/bin/bash
# Functional tests for ws.sh (AAA pattern). Run: bash test-ws.sh  or:  zsh test-ws.sh
set -u
WS_SRC=$(cd "$(dirname "$0")" && pwd)/ws.sh
TMP=$(mktemp -d)
export HOME="$TMP/home"
mkdir -p "$HOME"
BASE="$HOME/.workspaces"
ERR="$TMP/stderr"

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
# Arrange: none
# Act
out=$(ws 2>"$ERR"); rc=$?
# Assert
check "no-args rc" "1" "$rc"
check "no-args stdout empty" "" "$out"
check "no-args usage on stderr" "Usage: ws <id> [repo...] | ws ls | ws rm <id>" "$(cat "$ERR")"

# 2. help variants: usage on stdout, rc 0
# Arrange: none
# Act
out=$(ws help 2>"$ERR"); rc=$?
# Assert
check "help rc" "0" "$rc"
check "help stdout" "Usage: ws <id> [repo...] | ws ls | ws rm <id>" "$out"
check "help stderr empty" "" "$(cat "$ERR")"
# Act (aliases)
rc_h=$(ws -h >/dev/null 2>&1; echo $?)
rc_help=$(ws --help >/dev/null 2>&1; echo $?)
# Assert
check "-h rc" "0" "$rc_h"
check "--help rc" "0" "$rc_help"

# 3. create: makes the workspace and cds into it
# Arrange
rm -rf "$BASE/proj"
# Act
out=$(cd "$HOME" && ws proj 2>"$ERR" && pwd)
# Assert
check "create msg+pwd" "$(printf 'created: proj\n%s' "$BASE/proj")" "$out"
check "create stderr empty" "" "$(cat "$ERR")"

# 4. open existing: cds into it
# Arrange
mkdir -p "$BASE/proj"
# Act
out=$(cd "$HOME" && ws proj 2>"$ERR" && pwd)
# Assert
check "open msg+pwd" "$(printf 'opened: proj\n%s' "$BASE/proj")" "$out"

# 5. create with repos: clones each into the workspace
# Arrange
rm -rf "$BASE/cl"
# Act
out=$(cd "$HOME" && ws cl "$TMP/remote.git" 2>/dev/null)
# Assert
check "clone msg" "created: cl" "$out"
check "clone dir" "yes" "$([ -d "$BASE/cl/remote" ] && echo yes || echo no)"

# 6. ls: directories only, sorted, no dot-dirs, no files
# Arrange
mkdir -p "$BASE/proj" "$BASE/cl" "$BASE/.hidden" "$BASE/notdir"
touch "$BASE/afile"
# Act
out=$(cd "$HOME" && ws ls)
# Assert
check "ls dirs only" "$(printf 'cl\nnotdir\nproj')" "$out"
# Teardown
rmdir "$BASE/.hidden" "$BASE/notdir"; rm -f "$BASE/afile"

# 7. no side effects: ls / rm / invalid id never create WS_BASE
# Arrange
NB="$TMP/nobase"
# Act + Assert (three invocations, each must leave NB absent)
WS_BASE="$NB" ws ls >/dev/null 2>&1
check "ls no mkdir" "" "$([ -d "$NB" ] && echo created || true)"
WS_BASE="$NB" ws rm x >/dev/null 2>&1
check "rm no mkdir" "" "$([ -d "$NB" ] && echo created || true)"
WS_BASE="$NB" ws "a/b" >/dev/null 2>&1
check "invalid-id no mkdir" "" "$([ -d "$NB" ] && echo created || true)"

# 8. invalid ids: "invalid id" on stderr, rc 1
# Arrange: none
for bad in "a/b" "." ".."; do
  # Act
  out=$(ws "$bad" 2>"$ERR"); rc=$?
  # Assert
  check "invalid id '$bad' rc" "1" "$rc"
  check "invalid id '$bad' stdout empty" "" "$out"
  check "invalid id '$bad' stderr" "invalid id" "$(cat "$ERR")"
done

# 9. dot inside an id is allowed
# Arrange
rm -rf "$BASE/foo.bar"
# Act
out=$(ws "foo.bar" 2>"$ERR"); rc=$?
# Assert
check "dot-in-id rc" "0" "$rc"
check "dot-in-id dir" "yes" "$([ -d "$BASE/foo.bar" ] && echo yes || echo no)"
# Teardown
rm -rf "$BASE/foo.bar"

# 10. rm missing id and workspace: "not found" on stderr, rc 1
# Arrange: none (nope never exists)
# Act
out=$(cd "$HOME" && ws rm nope 2>"$ERR"); rc=$?
# Assert
check "rm missing rc" "1" "$rc"
check "rm missing stdout empty" "" "$out"
check "rm missing stderr" "not found: nope" "$(cat "$ERR")"
# Act
out=$(cd "$HOME" && ws rm 2>"$ERR"); rc=$?
# Assert (would crash under set -u before the ${2:-} fix)
check "rm no id rc" "1" "$rc"
check "rm no id stderr" "invalid id" "$(cat "$ERR")"

# 11. rm from inside the workspace: deletes, moves the real shell to $HOME
# Arrange
mkdir -p "$BASE/proj"
cd "$BASE/proj"
# Act (direct call: cd must move the real shell, not a subshell)
ws rm proj > "$TMP/msg" 2>"$ERR"; rc=$?
# Assert
check "rm rc" "0" "$rc"
check "rm msg" "deleted: proj" "$(cat "$TMP/msg")"
check "rm from inside pwd" "$HOME" "$PWD"
check "rm removed" "" "$(ls "$BASE" | grep proj || true)"

# 12. clone failure: workspace removed, back where you started
# Arrange
rm -rf "$BASE/bad"
# Act
out=$(cd "$TMP/seed" && ws bad "$TMP/remote.git" "$TMP/does-not-exist" 2>/dev/null; pwd)
# Assert
check "clone-fail pwd" "$TMP/seed" "$out"
check "clone-fail cleanup" "" "$(ls "$BASE" | grep bad || true)"

# 13. clone failure: names the repo and the removed workspace on stderr
# Arrange
rm -rf "$BASE/bad2"
# Act
err=$(cd "$HOME" && ws bad2 "$TMP/does-not-exist" 2>&1 1>/dev/null | grep -F 'clone failed:')
# Assert
check "clone-fail stderr" "clone failed: $TMP/does-not-exist (removed workspace: bad2)" "$err"

# 14. empty ls: silent, rc 0, even when the base does not exist
# Arrange
NB="$TMP/emptybase"
# Act
out=$(WS_BASE="$NB" ws ls 2>"$ERR"); rc=$?
# Assert
check "empty ls rc" "0" "$rc"
check "empty ls output" "" "$out"
check "empty ls stderr empty" "" "$(cat "$ERR")"

# 15. empty id rejected on the create path, base dir untouched
# Arrange
NB="$TMP/nobase2"
# Act
out=$(cd "$HOME" && ws "" 2>"$ERR"); rc=$?
# Assert
check "empty id rc" "1" "$rc"
check "empty id stderr" "invalid id" "$(cat "$ERR")"
check "empty id stdout empty" "" "$out"

# 16. rm only moves you to $HOME when inside the deleted workspace, not a prefix sibling
# Arrange
mkdir -p "$BASE/foo" "$BASE/foo2"
cd "$BASE/foo2"
# Act
ws rm foo >/dev/null 2>&1
# Assert
check "rm prefix sibling pwd" "$BASE/foo2" "$PWD"
# Teardown
rm -rf "$BASE/foo2"

# 17. rm propagates failure from rm -rf
# Arrange
mkdir -p "$BASE/locked"
rm() { return 1; }
# Act
ws rm locked >/dev/null 2>&1; rc=$?
# Assert
check "rm failure rc" "1" "$rc"
# Teardown
unset -f rm
command rm -rf "$BASE/locked"

# 18. rm must not fall through to the create path
# Arrange
mkdir -p "$BASE/proj"
cd "$HOME"
# Act
out=$(ws rm proj >"$TMP/msg" 2>"$ERR"); rc=$?
# Assert
check "rm rc 0" "0" "$rc"
check "rm stderr empty" "" "$(cat "$ERR")"
check "rm stdout" "deleted: proj" "$(cat "$TMP/msg")"
check "rm no 'rm' workspace created" "" "$([ -d "$BASE/rm" ] && echo leaked || true)"
check "rm pwd untouched" "$HOME" "$PWD"

# 19. rm with extra args still deletes, never creates a workspace named 'rm'
# Arrange
mkdir -p "$BASE/px"
# Act
out=$(cd "$HOME" && ws rm px "$TMP/remote.git" 2>"$ERR"); rc=$?
# Assert
check "rm extra-args rc" "0" "$rc"
check "rm extra-args msg" "deleted: px" "$out"
check "rm extra-args stderr empty" "" "$(cat "$ERR")"
check "rm extra-args no 'rm' dir" "" "$([ -d "$BASE/rm" ] && echo leaked || true)"

# 20. ls on an existing but empty base is silent, rc 0 (zsh nomatch regression)
# Arrange
mkdir -p "$TMP/emptydir"
# Act
out=$(WS_BASE="$TMP/emptydir" ws ls 2>&1); rc=$?
# Assert
check "empty dir ls rc" "0" "$rc"
check "empty dir ls output" "" "$out"

echo "---"
[ -n "${ZSH_VERSION:-}" ] && mode=zsh || mode=bash
echo "shell=$mode pass=$pass fail=$fail"
rm -rf "$TMP"
[ "$fail" -eq 0 ]
