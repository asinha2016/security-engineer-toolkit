# Phase 2 — What We Built and Why

This document explains what was done in Phase 2 in plain language, so anyone picking this up can get oriented quickly.

---

## The goal

Set up a local test environment so you can build, install, and exercise the plugin entirely on your laptop — no GitHub, no CI, no customers involved. Prove the inner dev loop works before wiring up automation.

---

## What we created

### 1. Test directory structure — `tests/`

```
tests/
  fixtures/
    jira-tickets/           ← placeholder for future test payloads
    vulnerable-code-samples/ ← placeholder for future test payloads
  sandboxes/
    bb-triage/
      CLAUDE.md             ← install and reload instructions for this sandbox
      instance-provision/
        plan.md             ← skill design doc (written before implementing)
```

**Fixtures** — directories are scaffolded but empty for now. Fixture files (sample Jira tickets, vulnerable code snippets) will be added when needed for automated testing.

**Sandboxes** — each plugin gets its own sandbox directory. Opening a sandbox in Claude Code gives you an isolated workspace to install and test that plugin without affecting other projects.

---

### 2. Sandbox `CLAUDE.md` — `tests/sandboxes/bb-triage/CLAUDE.md`

Documents the complete inner loop for testing `bb-triage`. Two approaches are documented:

| Approach | When to use |
|---|---|
| **A — `--plugin-dir` flag** | While actively building or editing skills. Session-scoped, no install needed, fastest iteration. |
| **B — Marketplace install** | To verify the full customer install flow end-to-end. Persists across sessions. |

Both approaches use `/reload-plugins` (not `/plugin reload`, which does not exist) to pick up changes after a rebuild.

The file also covers:
- How to reset to a clean slate (`/plugin uninstall` + `/plugin marketplace remove`)
- A skills table that links each skill to its `plan.md` and shows its invocation command
- How to add a new skill (create `plan.md` first, then implement)

---

### 3. Skill plan convention — `tests/sandboxes/bb-triage/instance-provision/plan.md`

**The pattern:** Before implementing any skill, create a `plan.md` in `tests/sandboxes/<plugin>/<skill-name>/`. Write the design there first — what the skill should do, open questions, decisions. Then point Claude at that document to implement.

This file lives under `tests/` (never shipped to customers) and stays co-located with the sandbox where you test the skill. Each skill gets its own subfolder so plans don't collide as more skills are added.

---

### 4. Artifact directory renamed — `run_artifacts/` → `reports/`

The skill writes a YAML file with instance credentials after provisioning. The output directory was renamed from `run_artifacts/` to `reports/` for clarity. Updated in three places:

- `packages/bb-triage/skills/instance-provision/config/config.yaml` — `artifact_dir` default value
- `packages/bb-triage/skills/instance-provision/SKILL.md` — config extraction instructions
- `packages/bb-triage/skills/instance-provision/README.md` — documentation

`reports/` is gitignored to prevent credential leakage.

---

## Key decisions made in Phase 2

### `/reload-plugins` not `/plugin reload`

The correct command to reload plugins after a rebuild is `/reload-plugins`. There is no `/plugin reload <name>` command — attempting it opens the Discover UI instead.

### Two install approaches, not one

The original plan only documented the marketplace install flow. Phase 2 surfaced a better approach for development: `claude --plugin-dir ./dist/plugins/bb-triage` loads the plugin for a session without installing it, making the edit → rebuild → test loop faster. Both approaches are valid and documented.

### plan.md lives in tests/, not packages/

Skill design docs are dev-only artifacts. Keeping them under `tests/sandboxes/` ensures they never ship to customers (everything under `packages/` does) and keeps them co-located with the sandbox where you test the skill.

---

## How to verify everything is working

```bash
bash scripts/build.sh
claude --plugin-dir ./dist/plugins/bb-triage
# inside Claude Code:
/bb-triage:instance-provision --version 9.2.1
```

A successful run provisions a Splunk instance and writes a YAML artifact to `reports/instance-provision/`.

---

## What is NOT done yet (deliberately deferred)

- Fixture files (`tests/fixtures/`) — directories exist, files will be added when needed
- `owasp-audit` and `secret-scanner` sandboxes — skipped, bb-triage focus only
- CI/CD pipeline and GitHub release automation — that is Phase 3
- Skill refinement (`feat/bb-triage-instance-provision` branch) — in progress, merge to `main` before starting Phase 3
