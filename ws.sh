# ws: create, open, list and delete temporary workspaces.
# Source this file from your shell rc: source /path/to/ws.sh
# Override the base directory with WS_BASE (default: ~/.workspaces).

ws() {
  local WS_BASE="${WS_BASE:-$HOME/.workspaces}"
  local id

  if [ $# -eq 0 ]; then
    echo "Usage: ws <id> [repo...] | ws ls | ws rm <id>" >&2
    return 1
  fi

  case "$1" in
    help|-h|--help)
      echo "Usage: ws <id> [repo...] | ws ls | ws rm <id>"
      return 0
      ;;
    ls)
      [ -d "$WS_BASE" ] || return 0
      local entry
      [ -n "${ZSH_VERSION:-}" ] && setopt local_options null_glob
      for entry in "$WS_BASE"/*; do
        [ -d "$entry" ] && printf '%s\n' "${entry##*/}"
      done
      return 0
      ;;
    rm)
      id=${2:-}
      case "$id" in ""|*/*|.|..) echo "invalid id" >&2; return 1;; esac
      [ -d "$WS_BASE/$id" ] || { echo "not found: $id" >&2; return 1; }
      case "$PWD" in "$WS_BASE/$id"|"$WS_BASE/$id"/*) cd "$HOME" ;; esac
      rm -rf "$WS_BASE/$id" && echo "deleted: $id"
      return
      ;;
  esac

  id=$1; shift
  case "$id" in ""|*/*|.|..) echo "invalid id" >&2; return 1;; esac
  local dir="$WS_BASE/$id"

  if [ ! -d "$dir" ]; then
    local orig=$PWD
    mkdir -p "$dir" && cd "$dir" || return
    local repo
    for repo in "$@"; do
      git clone "$repo" || {
        cd "$orig"
        rm -rf "$dir"
        echo "clone failed: $repo (removed workspace: $id)" >&2
        return 1
      }
    done
    echo "created: $id"
  else
    cd "$dir" || return
    echo "opened: $id"
  fi
}
