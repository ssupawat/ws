## v0.2.1

- Fix `ws rm` with no id crashing under `set -u` shells (unbound variable error)
- Add `ws help` / `ws -h`; usage and errors now go to stderr
- `ws ls`, `ws rm` and invalid ids no longer create `WS_BASE` as a side effect
- `ws ls` lists only directories
- Failed-clone cleanup returns you to the directory you started in and names the repo that failed
- README: id rule corrected — only `/`, `.` and `..` exactly are rejected

## v0.2.0

- Add `install.sh`: copies `ws.sh` to `~/.local/share/ws` and sources it from `~/.zshrc` or `~/.bashrc` (idempotent)
- Works via `curl | sh` or from a local clone
- `WS_INSTALL_DIR` overrides the install location

## v0.1.0

First release.

- `ws <id> [repo...]` creates or opens a workspace under `~/.workspaces` and clones the given repos
- `ws ls` lists workspaces
- `ws rm <id>` deletes a workspace
- Rejects ids containing `/`, `.` or `..`
- Removes the whole workspace if any clone fails
- `WS_BASE` env var overrides the base directory
