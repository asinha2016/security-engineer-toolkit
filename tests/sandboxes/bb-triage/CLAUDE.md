# bb-triage test sandbox

## Approach A — Development (fast iteration)

Use this while actively building or editing skills. No install required — plugin is session-scoped.

From the repo root, build and launch:

    bash scripts/build.sh
    claude --plugin-dir ./dist/plugins/bb-triage

After any edit, rebuild and reload without restarting:

    # separate terminal
    bash scripts/build.sh

    # back in Claude Code session
    /reload-plugins

## Approach B — Marketplace install (test the customer flow)

Use this to verify the full install flow works end-to-end, the same way a customer would.

From the repo root, build first:

    bash scripts/build.sh

Then in a Claude Code session opened in this sandbox directory:

    /plugin marketplace add ../../../dist
    /plugin install bb-triage@greyshell

After any edit:

    # separate terminal
    bash scripts/build.sh

    # back in Claude Code session
    /reload-plugins

### Reset (clean slate)

    /plugin uninstall bb-triage
    /plugin marketplace remove greyshell

Then repeat Approach B setup.

---

## Test scenarios

Each skill has its own subfolder here with a `plan.md` that describes what the skill should do and what a passing run looks like.

| Skill | Plan | Invoke (Approach A) | Invoke (Approach B) |
|---|---|---|---|
| instance-provision | [instance-provision/plan.md](instance-provision/plan.md) | `/bb-triage:instance-provision` | `/bb-triage:instance-provision` |

## Adding a new skill

1. Create `tests/sandboxes/bb-triage/<skill-name>/plan.md` and write the design before implementing.
2. Add a row to the table above once the skill is added to `packages/bb-triage/skills/`.
3. Rebuild and reload: `bash scripts/build.sh` → `/reload-plugins`.
