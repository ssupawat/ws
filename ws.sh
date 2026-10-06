# ws: create, open, list and delete temporary workspaces.
# Source this file from your shell rc: source /path/to/ws.sh
# Override the base directory with WS_BASE (default: ~/.workspaces).

ws() {
  local WS_BASE="${WS_BASE:-$HOME/.workspaces}"
  local WS_VERSION="0.4.0"
  local id

  # colours only on a terminal; NO_COLOR (any value) disables them
  local GREEN="" CYAN="" RED="" DIM="" OFF=""
  if [ -z "${NO_COLOR:-}" ]; then
    [ -t 1 ] && { GREEN=$'\033[32m'; CYAN=$'\033[36m'; DIM=$'\033[2m'; OFF=$'\033[0m'; }
    [ -t 2 ] && { RED=$'\033[31m'; OFF=$'\033[0m'; }
  fi

  if [ $# -eq 0 ]; then
    echo "Usage: ws <id> [repo...] | ws ls | ws rm <id>" >&2
    return 1
  fi

  case "$1" in
    version|-v|--version)
      echo "ws $WS_VERSION"
      return 0
      ;;
    help|-h|--help)
      echo "Usage: ws <id> [repo...] | ws ls | ws rm <id>"
      return 0
      ;;
    ls)
      [ -d "$WS_BASE" ] || { echo "${DIM}no workspaces${OFF}"; return 0; }
      local entry found=""
      [ -n "${ZSH_VERSION:-}" ] && setopt local_options null_glob
      for entry in "$WS_BASE"/*; do
        [ -d "$entry" ] || continue
        printf '%s\n' "${entry##*/}"
        found=1
      done
      [ -n "$found" ] || echo "${DIM}no workspaces${OFF}"
      return 0
      ;;
    rm)
      id=${2:-}
      case "$id" in ""|*/*|.|..) echo "${RED}✗ invalid id${OFF}" >&2; return 1;; esac
      [ -d "$WS_BASE/$id" ] || { echo "${RED}✗ not found: $id${OFF}" >&2; return 1; }
      case "$PWD" in "$WS_BASE/$id"|"$WS_BASE/$id"/*) cd "$HOME" ;; esac
      rm -rf "$WS_BASE/$id" && echo "${GREEN}✓ deleted: $id${OFF}"
      return
      ;;
  esac

  id=$1; shift
  case "$id" in ""|*/*|.|..) echo "${RED}✗ invalid id${OFF}" >&2; return 1;; esac
  local dir="$WS_BASE/$id"

  if [ ! -d "$dir" ]; then
    local orig=$PWD
    mkdir -p "$dir" && cd "$dir" || return
    local repo
    for repo in "$@"; do
      git clone "$repo" || {
        cd "$orig"
        rm -rf "$dir"
        echo "${RED}✗ clone failed: $repo (removed workspace: $id)${OFF}" >&2
        return 1
      }
    done
    echo "${GREEN}✓ created: $id${OFF}"
  else
    cd "$dir" || return
    echo "${CYAN}→ opened: $id${OFF}"
  fi
}
