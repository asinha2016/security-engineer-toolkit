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

## Editing the plugin source

If you identify a gap during a skill run, read only the file directly relevant to the gap — do not read the entire plugin directory. Do not suggest changes from memory — always read the file first.

Replace `<skill-name>` with the skill that has the gap (e.g. `instance-provision`):

| Gap type | File to read |
|---|---|
| Skill logic or argument parsing | `/Users/abhijis3/Documents/GitHub/security-engineer-toolkit/packages/bb-triage/skills/<skill-name>/SKILL.md` |
| Config values or defaults | `/Users/abhijis3/Documents/GitHub/security-engineer-toolkit/packages/bb-triage/skills/<skill-name>/config/config.yaml` |
| Helper script behavior | `/Users/abhijis3/Documents/GitHub/security-engineer-toolkit/packages/bb-triage/skills/<skill-name>/scripts/<script-name>.sh` |
| Artifact template output | `/Users/abhijis3/Documents/GitHub/security-engineer-toolkit/packages/bb-triage/skills/<skill-name>/templates/<template-name>.tmpl` |
| Agent steps or guardrails | First read the skill's SKILL.md to find which agent it dispatches to, then read `/Users/abhijis3/Documents/GitHub/security-engineer-toolkit/packages/bb-triage/agents/<agent-name>.md` |

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
