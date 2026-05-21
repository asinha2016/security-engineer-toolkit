# Phase 1 — What We Built and Why

This document explains what was done in Phase 1 in plain language, so anyone picking this up can get oriented quickly.

---

## The goal

Build one plugin — `bb-triage` — all the way through: author it, validate it, and produce a clean build output. Prove the toolchain works before adding more plugins.

---

## What we created

### 1. The plugin itself — `packages/bb-triage/`

This is the source of truth for the plugin. It contains everything Claude Code needs to install and run it.

| File / Folder | What it is |
|---|---|
| `.claude-plugin/plugin.json` | The plugin's identity card — name, version, description, author |
| `skills/instance-provision/SKILL.md` | A skill that provisions (or tears down) a live Splunk instance to reproduce a reported bug |
| `agents/shamu-provisioner.md` | A sub-agent that does the actual API calls to Shamu (Splunk's internal provisioning system) |
| `hooks/hooks.json` | Hook configuration — currently empty, placeholder for future use |
| `.mcp.json` | MCP server configuration — currently empty |
| `README.md` | Short description of the plugin |

**What the `instance-provision` skill does in plain English:**
A security researcher submits a bug report. To validate it, you need a running Splunk instance at the exact version they found the bug on. This skill lets you say `/instance-provision --version 9.2.1` and it spins one up for you automatically, or `/instance-provision --teardown <id>` to destroy it when you're done.

**What the `shamu-provisioner` agent does:**
It's the worker that actually talks to the Shamu REST API — authenticates, submits a provisioning job, polls until the instance is ready, and writes a YAML artifact with the connection details. The skill calls this agent behind the scenes.

---

### 2. Two scripts — `scripts/`

#### `validate.sh`
Checks every plugin under `packages/` before a build. It verifies:
- `plugin.json` exists and has all required fields
- Every skill and agent file has the required frontmatter (`name:` and `description:`)
- `hooks.json` and `.mcp.json` are valid JSON

Run it with: `bash scripts/validate.sh`

#### `build.sh`
Reads `packages/` and produces a clean `dist/` output. It:
- Copies each plugin to `dist/plugins/<name>/`
- Generates `dist/.claude-plugin/marketplace.json` — the file Claude Code reads to list available plugins
- Generates a customer-facing `dist/README.md`

Run it with: `bash scripts/build.sh`

The output in `dist/` is what a customer installs — not the source in `packages/`.

---

### 3. Housekeeping

- **`.gitignore`** — `dist/` (build output) and `.claude/` (local Claude state) are excluded from git. Also excludes `.DS_Store` files.
- **`CLAUDE.md`** — A "Dev guide" section was added explaining how to add a new plugin, run validate, run build, and write commit messages.

---

## The key design decision

We build to `dist/` and customers install from `dist/`. We never have customers install directly from `packages/`. This means:
- What gets tested is exactly what gets shipped.
- A rebuild (`bash scripts/build.sh`) is required after any edit before testing locally.

---

## How to verify everything is working

```bash
bash scripts/validate.sh   # should print: Validation passed.
bash scripts/build.sh      # should print: Build complete: .../dist
jq .plugins dist/.claude-plugin/marketplace.json   # should show bb-triage
```

---

## What is NOT done yet (deliberately deferred)

- `owasp-audit` and `secret-scanner` plugins — skipped, adding them later once the pipeline is proven
- Local install test in Claude Code — that's Phase 2
- CI/CD pipeline and GitHub release automation — that's Phase 3
