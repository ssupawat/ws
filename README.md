# ws

A small shell function for temporary workspaces. Each workspace is a folder under `~/.workspaces`, optionally pre-filled with cloned repos.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/OWNER/ws/main/install.sh | sh
```

Or from a clone:

```sh
git clone https://github.com/OWNER/ws && sh ws/install.sh
```

This copies `ws.sh` to `~/.local/share/ws` and adds one `source` line to `~/.zshrc` or `~/.bashrc`. Running it again does not duplicate the line. Set `WS_INSTALL_DIR` to change the install location.

## Usage

```sh
ws <id> [repo...]   # create (and clone repos) or open a workspace, then cd into it
ws ls               # list workspaces
ws rm <id>          # delete a workspace
```

## Behavior

- If a clone fails during creation, the whole workspace is removed.
- `ws rm` moves you to `$HOME` first if you are inside the workspace being deleted.
- Ids containing `/`, `.` or `..` are rejected.
- Set `WS_BASE` to change the base directory.

Works in bash and zsh.
