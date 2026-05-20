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
