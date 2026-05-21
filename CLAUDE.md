# Dev guide

## Adding a new plugin

1. Copy `packages/bb-triage/` to `packages/<your-plugin-name>/`.
2. Edit `.claude-plugin/plugin.json` — update `name`, `version`, `description`, `author`.
3. Update or replace `skills/`, `agents/`, `hooks/`, `.mcp.json` as needed.
4. Run `bash scripts/validate.sh` — fix any errors before committing.
5. Run `bash scripts/build.sh` — rebuilds `dist/` with the new plugin included.

## Validate

```bash
bash scripts/validate.sh
```

Walks every plugin under `packages/` and checks required files, JSON validity, and frontmatter fields. Exits 0 on success, 1 with a descriptive error on failure.

## Build

```bash
bash scripts/build.sh
```

Reads `packages/`, writes `dist/`. Produces `dist/plugins/<name>/` for each plugin and `dist/.claude-plugin/marketplace.json`. Output is deterministic — same source produces byte-identical output.

`dist/` is gitignored. Always rebuild before local testing — customers install from `dist/`, not from `packages/`.

## Commit message convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

| Type | Example |
|---|---|
| New feature | `feat(bb-triage): add CVSS scoring to instance-provision` |
| Bug fix | `fix(bb-triage): correct hook event name` |
| Breaking change | `feat(bb-triage)!: rename skill to provision-instance` |
| Repo tooling | `chore: update validate.sh to check .mcp.json` |

The `(<plugin>)` scope should match the directory name under `packages/`.

## Manual release (fallback)

If the release workflow fails, publish manually from your laptop:

    # 1. Guard: must be on main with a clean working tree
    git diff --quiet && git diff --cached --quiet \
      || { echo "Working tree dirty — commit or stash first"; exit 1; }
    git checkout main && git pull origin main

    # 2. Bump the affected plugin's version in plugin.json, then commit
    #    (e.g. edit packages/bb-triage/.claude-plugin/plugin.json)
    #    Also update .release-please-manifest.json to match.
    #    Commit: git add ... && git commit -m "chore(bb-triage): bump version to X.Y.Z"

    # 3. Build and stage output outside the repo
    bash scripts/validate.sh
    bash scripts/build.sh
    STAGING=$(mktemp -d)
    cp -R dist/* "$STAGING/"

    # 4. Publish to release branch
    git checkout release
    git rm -rf .
    cp -R "$STAGING"/. .
    git add -A
    git commit -m "chore(release): manual publish $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    git push origin release
    git checkout main

## Local git hooks

Run once after cloning:

    bash scripts/install-hooks.sh

Points git at the tracked `.githooks/` directory (one-time per clone, idempotent). The tracked files are the live hooks — no copy step, no drift.

- `commit-msg` — rejects commits that don't follow Conventional Commits; blocks silent release-please no-ops
- `pre-push` — runs `validate.sh` before any push to `main`; blocks on failure
- `post-merge` — rebuilds `dist/` after every merge so your local sandbox stays current
