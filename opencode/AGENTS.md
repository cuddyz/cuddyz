# OpenCode Global Rules — cuddyz

This is the global `AGENTS.md` for all opencode sessions on this machine.
It lives at `~/.config/opencode/AGENTS.md` (symlinked from this repo).

---

## SSH & GitHub Identity

This machine has **two GitHub accounts** configured via separate SSH keys and
`~/.ssh/config` host aliases. Always use the correct remote alias when cloning,
setting remotes, or pushing.

| Account | SSH Host Alias | Key File | Use For |
|---|---|---|---|
| cuddyz | `git@github.com-cuddyz` | `~/.ssh/id_rsa` | Personal repos (github.com/cuddyz) |
| ChromeDomeWebDesigns | `git@github.com-cdwd` | `~/.ssh/cdwd_id_rsa` | CDWD client/business repos |

### Rules

- When cloning a **cuddyz** repo, always use:
  `git clone git@github.com-cuddyz:cuddyz/<repo>.git`
- When cloning a **ChromeDomeWebDesigns** repo, always use:
  `git clone git@github.com-cdwd:ChromeDomeWebDesigns/<repo>.git`
- Never use the bare `git@github.com:` host directly — it will use the wrong key.
- After cloning, verify the remote with `git remote -v` and update if the wrong
  host alias was used.
- When setting up a new repo for cuddyz:
  `git remote set-url origin git@github.com-cuddyz:cuddyz/<repo>.git`
- When setting up a new repo for ChromeDomeWebDesigns:
  `git remote set-url origin git@github.com-cdwd:ChromeDomeWebDesigns/<repo>.git`

### SSH Config (reference)

```
# Personal
Host github.com-cuddyz
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa

# CDWD
Host github.com-cdwd
    HostName github.com
    User git
    IdentityFile ~/.ssh/cdwd_id_rsa
```

---

## Sounds

Peon-ping is installed with the **zelda-mix** pack (OOT + A Link to the Past).
Config lives at `~/.config/opencode/peon-ping/config.json`.

---

## General Conventions

- Platform: macOS (darwin)
- Shell: bash/zsh
- Package manager preference: Homebrew where available, then npm/bun
- Prefer editing existing files over creating new ones
- Commit only when explicitly asked
- No force pushes to main/master without explicit confirmation

---

## Nuxt 2 Development Style

See `local-agents/NUXT2_AGENTS.md` in this repo.

<!-- tombstone — full content moved to local-agents/ for project-level use -->

**Reference files:**
- `nuxt.config.js` — plugin registration order, module list, `generate.routes()`
- `plugins/firebase.js` — canonical Firebase init pattern
- `plugins/facets.js` — parallel prefetch on app boot with `Promise.all`
- `plugins/cookies.js` — store hydration from cookie on page load

---

## Roblox Game Development (Luau)

See `local-agents/ROBLOX_AGENTS.md` in this repo.

<!-- tombstone — full content moved to local-agents/ for project-level use -->
