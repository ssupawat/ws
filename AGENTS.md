# AGENTS.md

## Test

- A pre-push hook runs `bash test-ws.sh` and `zsh test-ws.sh`; enable once with `git config core.hooksPath hooks`
- Tests follow AAA (Arrange / Act / Assert), one `ws` invocation per Act; each test builds its own fixtures — no order coupling

## Code

- One file, `ws.sh`, a sourced shell function — must work in bash and zsh

## Docs

- README must match verified behavior — update it in the same change

## Release

- Bump `WS_VERSION` in `ws.sh`, commit, tag `vX.Y.Z` on that commit, push the tag — the embedded version must equal the tag
- `gh release create vX.Y.Z --title "vX.Y.Z" --notes "<one bullet per user-visible change>"`
- Versioning: 0.x — patch for fixes, minor for features
- Never force-push tags
