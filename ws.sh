# ws: create, open, list and delete temporary workspaces.
# Source this file from your shell rc: source /path/to/ws.sh
# Override the base directory with WS_BASE (default: ~/.workspaces).

ws() {
  local WS_BASE="${WS_BASE:-$HOME/.workspaces}"
  mkdir -p "$WS_BASE"

  case "$1" in
    "")
      echo "Usage: ws <id> [repo...] | ws rm <id> | ws ls"
      return 1
      ;;
    ls)
      ls -1 "$WS_BASE" 2>/dev/null
      return 0
      ;;
    rm)
      local id=$2
      case "$id" in ""|*/*|.|..) echo "invalid id"; return 1;; esac
      [ -d "$WS_BASE/$id" ] || { echo "not found: $id"; return 1; }
      case "$PWD" in "$WS_BASE/$id"*) cd "$HOME" ;; esac
      rm -rf "$WS_BASE/$id" && echo "deleted: $id"
      return 0
      ;;
  esac

  local id=$1; shift
  case "$id" in */*|.|..) echo "invalid id"; return 1;; esac
  local dir="$WS_BASE/$id"

  if [ ! -d "$dir" ]; then
    mkdir -p "$dir" && cd "$dir" || return
    local repo
    for repo in "$@"; do
      git clone "$repo" || { cd "$HOME"; rm -rf "$dir"; return 1; }
    done
    echo "created: $id"
  else
    cd "$dir" || return
    echo "opened: $id"
  fi
}
