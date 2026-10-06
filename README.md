# ws

A small shell function for temporary workspaces. Each workspace is a folder under `~/.workspaces`, optionally pre-filled with cloned repos.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/ssupawat/ws/main/install.sh | sh
```

Or from a clone:

```sh
git clone https://github.com/ssupawat/ws && sh ws/install.sh
```

This copies `ws.sh` to `~/.local/share/ws` and adds one `source` line to `~/.zshrc` or `~/.bashrc`. Running it again does not duplicate the line. Set `WS_INSTALL_DIR` to change the install location.

## Usage

```sh
ws <id> [repo...]   # create (and clone repos) or open a workspace, then cd into it
ws ls               # list workspaces
ws rm <id>          # delete a workspace
ws help             # show usage
ws version          # show version
```

## Behavior

- If a clone fails during creation, the whole workspace is removed and you are returned to the directory you started in.
- `ws rm` moves you to `$HOME` first if you are inside the workspace being deleted (or one of its subdirectories) — not when you are in a workspace whose name merely shares a prefix.
- The empty id, ids containing `/`, and the ids `.` and `..` are rejected (a dot inside an id like `foo.bar` is allowed).
- The words `ls`, `rm`, `help` and `version` are reserved and cannot be workspace ids.
- Errors and usage go to stderr; failures exit non-zero.
- `ws ls` and `ws rm` never create the base directory; only `ws <id>` does.
- Set `WS_BASE` to change the base directory.

Works in bash and zsh.

## Development

Run the test suite (uses a local git remote, no network):

```sh
bash test-ws.sh
zsh test-ws.sh
```

A pre-push hook runs both suites automatically; enable it once with:

```sh
git config core.hooksPath hooks
```
