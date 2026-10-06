#!/bin/sh
# Install ws: copy ws.sh to ~/.local/share/ws and source it from your shell rc.
# Remote: curl -fsSL https://raw.githubusercontent.com/ssupawat/ws/main/install.sh | sh
set -eu

REPO="${WS_REPO:-ssupawat/ws}"
DEST="${WS_INSTALL_DIR:-$HOME/.local/share/ws}"
LINE="[ -f \"$DEST/ws.sh\" ] && . \"$DEST/ws.sh\""

case "${SHELL:-}" in
  */zsh)  RC="$HOME/.zshrc" ;;
  */bash) RC="$HOME/.bashrc" ;;
  *) echo "unsupported shell: ${SHELL:-unknown} (bash and zsh only)" >&2; exit 1 ;;
esac

mkdir -p "$DEST"
SRC_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)
if [ -n "$SRC_DIR" ] && [ -f "$SRC_DIR/ws.sh" ]; then
  cp "$SRC_DIR/ws.sh" "$DEST/ws.sh"
else
  curl -fsSL "https://raw.githubusercontent.com/$REPO/main/ws.sh" -o "$DEST/ws.sh"
fi

touch "$RC"
grep -qF "$DEST/ws.sh" "$RC" || printf '\n# ws\n%s\n' "$LINE" >> "$RC"

echo "installed: $DEST/ws.sh"
echo "restart your shell or run: . $RC"
