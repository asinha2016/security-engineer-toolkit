# Implementation Plan — Security Engineer Toolkit Plugin Marketplace

> Status tracking for building the full Approach 3 / Pattern B plugin marketplace.
> Work through phases in order. Do not start Phase N+1 until Phase N is verified.
>
> **Strategy:** Build a complete vertical slice with **one plugin** (`bb-triage`) all
> the way to a customer install, then replicate for the other two. This way, if the
> build/release loop is broken, you debug it once on one plugin — not three.

---

## Phase 0 — Prerequisites (verify tooling is installed)

Before any step below, confirm these exist on your machine. If any are missing, install them first.

### Step 0.1 — Verify required CLI tools

Run each of these and confirm they print a version (not "command not found"):

```bash
jq --version          # JSON parsing in shell scripts
python3 --version     # JSON validation fallback
git --version         # Branch and commit operations
claude --version      # Claude Code CLI for /plugin commands
gh --version          # GitHub CLI for repo settings (optional but recommended)
```

Decision recorded: **shell scripts will use `jq`** as the primary JSON tool, with `python3 -m json.tool` as a parse-validity fallback.

Verification: All five commands print a version string.

---

### Step 0.2 — Decide and record the local-install model

When testing locally, the sandbox needs to point its `/plugin marketplace add` at *something* on disk. There are two options:

| Model | Sandbox command | Pro | Con |
|---|---|---|---|
| **A. Install from `dist/`** | `/plugin marketplace add ../../../dist` | Tests the exact artifact customers get | Must rerun `build.sh` after every edit |
| **B. Install from `packages/`** (with a dev marketplace.json checked in alongside) | `/plugin marketplace add ../../../` | Edit-and-reload, no rebuild | Tests a different artifact than ships |

**Decision: use Model A (install from `dist/`).** Reason: the whole point of the build step is to make `dist/` the truth. If we test against `packages/` we lose the safety the build provides. The rebuild cost is one command.

Every step below assumes Model A.

---

## Phase 1 — Vertical Slice with One Plugin (`bb-triage`)

Goal: Author one plugin, validate it, build it, and prove the build output is well-formed. Other plugins come later in Phase 1.5.

### Step 1.1 — Scaffold `packages/bb-triage/` only

Create just the one plugin's directory tree. Defer `owasp-audit` and `secret-scanner`.

```
packages/
  bb-triage/
    .claude-plugin/
      plugin.json
    skills/
      instance-provision/
        SKILL.md
    agents/
      shamu-provisioner.md
    hooks/
      hooks.json
    .mcp.json
    README.md
```

Verification: `ls packages/bb-triage/` shows `.claude-plugin/`, `skills/`, `agents/`, `hooks/`, `.mcp.json`, `README.md`.

---

### Step 1.2 — Write `plugin.json` for `bb-triage`

```json
{
  "name": "bb-triage",
  "version": "0.1.0",
  "description": "Bug bounty triage with five-dimension scoring",
  "author": "Abhijit Sinha"
}
```

Verification: `jq . packages/bb-triage/.claude-plugin/plugin.json` exits 0 and prints the four fields.

---

### Step 1.3 — Write stub `SKILL.md` with required frontmatter

```markdown
---
name: instance-provision
description: Provision a live instance to reproduce a researcher-reported bug, or tear one down.
---

(skill body placeholder — real content in a later iteration)
```

Verification: `head -5 packages/bb-triage/skills/instance-provision/SKILL.md` shows the frontmatter block with `name:` and `description:`.

---

### Step 1.4 — Write stub agent file with required frontmatter

```markdown
---
name: shamu-provisioner
description: Shamu-specific worker agent. Provisions or tears down a Shamu Splunk instance via the Shamu REST API.
---

(agent body placeholder)
```

Verification: `head -5 packages/bb-triage/agents/shamu-provisioner.md` shows the frontmatter block.

---

### Step 1.5 — Write stub `hooks.json`, `.mcp.json`, and plugin `README.md`

`hooks.json`:
```json
{ "hooks": [] }
```

`.mcp.json`:
```json
{ "mcpServers": {} }
```

`README.md` (plugin-specific docs that ship to the customer):
```markdown
# bb-triage

Bug bounty triage plugin for Claude Code.
```

Verification: `jq . packages/bb-triage/hooks/hooks.json` and `jq . packages/bb-triage/.mcp.json` both exit 0.

---

### Step 1.6 — Verify the marketplace.json schema before writing build.sh

**This step is a research checkpoint, not a code-writing step.** Before writing `build.sh`, confirm the actual format Claude Code expects for `marketplace.json` — specifically:

- Where does the file live? (`dist/.claude-plugin/marketplace.json` vs `dist/marketplace.json`)
- How is the `path` field interpreted? (Relative to the marketplace.json file? Relative to the marketplace root?)
- What fields are required per plugin entry?

Source the answer from one of:
1. The Claude Code plugin documentation.
2. An existing public marketplace's `marketplace.json` on GitHub.
3. The `claude` CLI itself (e.g., `claude plugin --help`).

Record the decision in this file (overwrite the placeholder below) before continuing:

> **Marketplace schema decision** (sourced from `claude plugin validate` output and the live official marketplace at `~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json`):
>
> **File location:** `.claude-plugin/marketplace.json` at the repo root (same folder customers see when they add your marketplace).
>
> **How the `source` path works:** It is relative to the **repo root**, not to `marketplace.json` itself (confirmed from the official marketplace — `commit-commands` uses `"source": "./plugins/commit-commands"` even though `marketplace.json` is inside `.claude-plugin/`). So the path in each entry is `./plugins/bb-triage`.
>
> **Required marketplace-level fields:**
> ```json
> {
>   "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
>   "name": "greyshell",
>   "description": "...",
>   "owner": { "name": "Abhijit Sinha" },
>   "plugins": [ ... ]
> }
> ```
>
> **Required per-plugin fields inside `plugins[]`:**
> ```json
> {
>   "name": "bb-triage",
>   "description": "...",
>   "author": { "name": "Abhijit Sinha" },
>   "source": "./plugins/bb-triage"
> }
> ```
>
> **Two schema rules that bit us (already fixed):**
> - `author` must be an object `{ "name": "..." }`, not a plain string.
> - `hooks` inside `hooks.json` must be an object `{}` (keyed by event name), not an array `[]`.

Verification: The decision block above is filled in with a citation to the source.

---

### Step 1.7 — Write `scripts/validate.sh`

Walks every directory under `packages/` and checks:

1. `plugin.json` exists; parses as valid JSON; has `name`, `version`, `description`, `author`.
2. Every `SKILL.md` under `skills/*/` has frontmatter containing `name:` and `description:`.
3. Every `.md` under `agents/` has frontmatter containing `name:` and `description:`.
4. Any `hooks.json` parses as valid JSON.
5. Any `.mcp.json` parses as valid JSON.

Implementation: Bash + `jq`. For frontmatter extraction, use `awk '/^---$/{f=!f;next}f'` to grab the frontmatter block, then `grep -E '^name:'` and `grep -E '^description:'`.

Exits 0 if all pass; exits 1 with a descriptive `echo "ERROR: ..."` to stderr if any fail.

Verification: `bash scripts/validate.sh` exits 0 against the `bb-triage` stubs. Then deliberately break `plugin.json` (delete the `version` field), rerun, confirm it exits 1 with a clear error message, then restore.

---

### Step 1.8 — Write `scripts/build.sh` (using the schema decision from Step 1.6)

Reads `packages/`, writes `dist/`. Behavior:

1. Delete and recreate `dist/`.
2. For each directory under `packages/`, copy it to `dist/plugins/<name>/`.
3. Generate `marketplace.json` at the location decided in Step 1.6, containing one entry per plugin with the fields decided in Step 1.6.
4. Generate `dist/README.md` (customer-facing) listing the plugins with their descriptions, pulling from each `plugin.json`.
5. Make all output deterministic: same `packages/` produces byte-identical `dist/`.

Use `jq` to construct `marketplace.json` rather than string concatenation.

Verification: `bash scripts/build.sh` exits 0. `jq . dist/.claude-plugin/marketplace.json` (or wherever Step 1.6 decided) parses cleanly and the plugins array contains exactly one entry: `bb-triage`. `dist/README.md` mentions `bb-triage`.

---

### Step 1.9 — Update `.gitignore`

Add:
```
dist/
.claude/
```

Verification: After `bash scripts/build.sh`, `git status` shows no untracked files under `dist/`.

---

### Step 1.10 — Update `CLAUDE.md` (dev guide)

Add a "Dev guide" section to the existing `CLAUDE.md`:

- How to add a new plugin (copy `packages/bb-triage/` as a template, edit `plugin.json`)
- How to run validate: `bash scripts/validate.sh`
- How to run build: `bash scripts/build.sh`
- Commit message convention (Conventional Commits — `feat(<plugin>):`, `fix(<plugin>):`, `feat(<plugin>)!:` for breaking)

Keep the existing Ghost MCP block unchanged.

Verification: `CLAUDE.md` on `main` has a top-level "Dev guide" section.

---

**Phase 1 done when:** `bash scripts/validate.sh && bash scripts/build.sh` runs clean end-to-end and `dist/` contains a well-formed marketplace with the one `bb-triage` plugin.

---

## Phase 1.5 — Replicate to Other Plugins

Goal: Add `owasp-audit` and `secret-scanner` to `packages/`. The build/validate scripts already handle them; this step exercises that.

### Step 1.5.1 — Scaffold `packages/owasp-audit/` and `packages/secret-scanner/`

Mirror the `bb-triage` structure where applicable. `secret-scanner` is hooks-only (no skills or agents per the spec); `owasp-audit` has a skill and an agent but no hooks.

```
packages/owasp-audit/
  .claude-plugin/plugin.json
  skills/owasp-checks/SKILL.md
  agents/audit-reviewer.md
  README.md

packages/secret-scanner/
  .claude-plugin/plugin.json
  hooks/hooks.json
  README.md
```

### Step 1.5.2 — Fill in plugin.json, SKILL.md, agent, and hooks stubs

Same shape as `bb-triage`, with names and descriptions adjusted.

### Step 1.5.3 — Re-run validate and build

```bash
bash scripts/validate.sh
bash scripts/build.sh
```

Verification: Both exit 0. `dist/.claude-plugin/marketplace.json` lists all three plugins. `dist/plugins/` contains all three plugin directories.

---

**Phase 1.5 done when:** All three plugins build into `dist/` cleanly and the generated marketplace.json lists all three.

---

## Phase 2 — Test Environment (inner-loop local testing)

Goal: Install the locally-built plugin from `dist/` into a sandbox and exercise it inside Claude Code, with no GitHub or CI involved.

### Step 2.1 — Scaffold `tests/` directory structure

```
tests/
  fixtures/
    jira-tickets/
      sample-high.json
      sample-low.json
    vulnerable-code-samples/
      xss-example.js
  sandboxes/
    bb-triage/
      CLAUDE.md
    owasp-audit/
      CLAUDE.md
    secret-scanner/
      CLAUDE.md
```

Verification: `ls tests/sandboxes/` shows all three sandbox directories.

---

### Step 2.2 — Write sandbox `CLAUDE.md` files (Model A)

Each sandbox `CLAUDE.md` documents the loop: build → install/reload → run.

Example for `bb-triage`:
```markdown
# bb-triage test sandbox

## First-time setup
From the repo root, run a build:

    bash scripts/build.sh

Then in this sandbox directory in Claude Code:

    /plugin marketplace add ../../../dist
    /plugin install bb-triage@greyshell

## After editing the plugin source on main
1. Repo root: `bash scripts/build.sh`
2. This sandbox: `/plugin reload bb-triage`

## Test scenario
Use fixture: tests/fixtures/jira-tickets/sample-high.json
Skill: instance-provision
Expected: instance provisioned successfully, artifact written to run_artifacts/
```

Verification: Each sandbox `CLAUDE.md` has Setup, Reload, and Test scenario sections, all using Model A (install from `../../../dist`).

---

### Step 2.3 — Write stub fixture files

`tests/fixtures/jira-tickets/sample-high.json` — a Jira-like JSON payload with `summary`, `description`, `priority: High`, and a couple of labels.

`tests/fixtures/jira-tickets/sample-low.json` — same shape, `priority: Low`.

`tests/fixtures/vulnerable-code-samples/xss-example.js` — a few-line JS file with `element.innerHTML = userInput`.

Verification: All three files exist; the JSONs parse with `jq .`.

---

### Step 2.4 — Run build, then install locally from sandbox

From repo root:
```bash
bash scripts/build.sh
```

Open `tests/sandboxes/bb-triage/` in Claude Code and run:
```
/plugin marketplace add ../../../dist
/plugin install bb-triage@greyshell
```

Verification: Claude Code confirms the plugin installed. `/plugin list` shows `bb-triage` as installed.

---

### Step 2.5 — Test the reload cycle

Edit `packages/bb-triage/skills/instance-provision/SKILL.md` — change one word in the description.

Rebuild:
```bash
bash scripts/build.sh
```

In the sandbox:
```
/plugin reload bb-triage
```

Verification: The skill description visible inside Claude Code reflects the edit, without a reinstall.

---

**Phase 2 done when:** You can edit a plugin, rebuild, reload, and see the change reflected — entirely locally.

---

## Phase 3 — CI Pipeline (automated validation and release)

Goal: Pushes to GitHub trigger validation; merging a release-please PR auto-publishes to the `release` branch.

### Step 3.1 — Create the `release` branch (orphan, one-time, with concrete placeholder content)

Run from a clean working tree:

```bash
git checkout --orphan release
git rm -rf .

mkdir -p .claude-plugin

cat > .claude-plugin/marketplace.json <<'EOF'
{
  "name": "greyshell",
  "owner": { "name": "Abhijit Sinha" },
  "plugins": []
}
EOF

cat > README.md <<'EOF'
# security-engineer-toolkit

Initial release branch — content will be populated on first CI release.

## Source

Development happens on the `main` branch.
EOF

git add .claude-plugin/marketplace.json README.md
git commit -m "chore(release): initial release branch placeholder"
git push origin release
git checkout main
```

Verification: `git ls-remote origin release` returns a SHA. GitHub web UI shows the `release` branch with the placeholder README and an empty plugins array in `marketplace.json`.

---

### Step 3.2 — Change the default branch on GitHub to `release`

GitHub → Settings → Branches → Default branch → switch from `main` to `release`.

Note: This is reversible (you can switch back any time). It only affects what visitors see by default and what `/plugin marketplace add <user>/<repo>` (no `@branch` suffix) resolves to.

Verification: Visiting `github.com/<you>/security-engineer-toolkit` shows the `release` branch's README by default.

---

### Step 3.3 — Write `.github/workflows/validate.yml`

Triggered on: `push` to `main`, `pull_request` targeting `main`.

Steps:
1. `actions/checkout@v4`.
2. Install `jq` (usually preinstalled on `ubuntu-latest` but pin it).
3. `bash scripts/validate.sh`.
4. Workflow fails if exit code != 0.

Verification: Open a PR that breaks `plugin.json` (delete a required field). The validate workflow fails, the PR's "Checks" tab shows the error, and merge is blocked. Restore the field; the next push passes.

---

### Step 3.4 — Write `release-please-config.json` and `.release-please-manifest.json`

`release-please-config.json`:
```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    "packages/bb-triage":      { "release-type": "simple", "package-name": "bb-triage" },
    "packages/owasp-audit":    { "release-type": "simple", "package-name": "owasp-audit" },
    "packages/secret-scanner": { "release-type": "simple", "package-name": "secret-scanner" }
  }
}
```

`.release-please-manifest.json`:
```json
{
  "packages/bb-triage": "0.1.0",
  "packages/owasp-audit": "0.1.0",
  "packages/secret-scanner": "0.1.0"
}
```

Verification: Both files exist and `jq .` parses them cleanly.

---

### Step 3.5 — Write `.github/workflows/release.yml` (build outside the worktree)

Triggered on: push to `main` (release-please opens its PR), and on merge of a release-please PR (release-please tags + creates a GitHub release, which our workflow watches for).

Two jobs:

**Job A: `release-please`**
- Runs `googleapis/release-please-action@v4` against `release-please-config.json`.
- Outputs whether a release was created.

**Job B: `publish-to-release-branch`** (depends on Job A, runs only if Job A created a release)

Critical: build into a temp directory *outside* the working tree so a subsequent `git checkout release` does not wipe it.

Steps:
1. `actions/checkout@v4` with `fetch-depth: 0` (full history, both branches).
2. `bash scripts/validate.sh` (belt and suspenders).
3. `STAGING=$(mktemp -d) && bash scripts/build.sh && cp -R dist/* "$STAGING/"` — copy build output to a path outside the repo so the next checkout cannot delete it.
4. `git checkout release`.
5. `git rm -rf .` then `cp -R "$STAGING"/. .`.
6. `git config user.name "release-bot" && git config user.email "release-bot@users.noreply.github.com"`.
7. `git add -A && git commit -m "chore(release): publish $GITHUB_SHA"`.
8. `git push origin release`.

Permissions block at the top of the workflow:
```yaml
permissions:
  contents: write
  pull-requests: write
```

Verification: Push a `feat(bb-triage):` commit to `main`. release-please opens a PR. Merge it. The workflow runs Job B, publishes to `release`, and `marketplace.json` on `release` reflects the new version.

---

### Step 3.6 — Document the manual release fallback

If release-please fails (config error, transient API failure, GitHub Actions outage), you need a way to publish manually. Add a section to `CLAUDE.md`:

```markdown
## Manual release (fallback)

If the release workflow fails, publish manually from your laptop:

    bash scripts/validate.sh
    bash scripts/build.sh

    STAGING=$(mktemp -d)
    cp -R dist/* "$STAGING/"

    git checkout release
    git rm -rf .
    cp -R "$STAGING"/. .
    git add -A
    git commit -m "chore(release): manual publish $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    git push origin release
    git checkout main

Bump the affected plugin's version in its plugin.json before running this, and update .release-please-manifest.json so the next automated release picks the right next version.
```

Verification: The manual release section exists in `CLAUDE.md`.

---

**Phase 3 done when:** Merging a feature commit to `main` opens a release PR; merging the release PR publishes to `release`; the manual fallback is documented.

---

## Phase 4 — Customer Install Test (end-to-end from terminal)

Goal: Simulate a fresh customer with no knowledge of the repo internals installing a plugin via three terminal commands.

### Step 4.1 — Verify `release` branch is the default on GitHub

Open `github.com/<your-handle>/security-engineer-toolkit`. Confirm:
- The branch selector shows `release` by default.
- `marketplace.json` is visible at `.claude-plugin/marketplace.json` and lists `bb-triage` (and the other two if Phase 1.5 was done).
- The README shown is the customer-facing one, not the dev README.

---

### Step 4.2 — Open a fresh Claude Code session (no prior plugin state)

Either open a brand-new working directory, or run `/plugin marketplace list` first and remove any prior `greyshell` registration with `/plugin marketplace remove greyshell`.

Verification: `/plugin marketplace list` does not show `greyshell`.

---

### Step 4.3 — Add the marketplace

```
/plugin marketplace add abhijit/security-engineer-toolkit
```

No `@branch` suffix needed — the GitHub default branch (`release`) is used.

Verification: Claude Code confirms the `greyshell` marketplace was added and lists the plugins it found.

---

### Step 4.4 — Install a plugin

```
/plugin install bb-triage@greyshell
```

Verification: Claude Code confirms `bb-triage` installed; the skill `instance-provision` and agent `shamu-provisioner` show up in the appropriate lists.

---

### Step 4.5 — Exercise the installed plugin

Invoke the skill against a fixture. Stub-level output is acceptable here — the goal is to confirm the plugin is wired up, not that the content is mature.

Verification: The skill runs without error.

---

### Step 4.6 — Test the update flow end-to-end

1. On `main`: edit `packages/bb-triage/skills/instance-provision/SKILL.md`.
2. Commit with `feat(bb-triage): <change description>` and push.
3. Wait for release-please to open a release PR.
4. Merge the release PR.
5. Wait for the release workflow to publish.

In the customer terminal:
```
/plugin marketplace update greyshell
/plugin update bb-triage
```

Verification: `/plugin list` shows `bb-triage` at the new version. The change is visible (e.g., updated description text).

---

**Phase 4 done when:** A fresh session can install and use the plugin with three commands, and the update flow works end-to-end from a `feat(...)` commit to a published version.

---

## Summary checklist

| Phase | Step | Done? |
|---|---|---|
| 0 | 0.1 Verify CLI tools (jq, python3, git, claude, gh) | ✅ |
| 0 | 0.2 Record local-install model decision (Model A: install from `dist/`) | ✅ |
| 1 | 1.1 Scaffold `packages/bb-triage/` | ✅ |
| 1 | 1.2 Write `bb-triage` plugin.json | ✅ |
| 1 | 1.3 Write SKILL.md stub | ✅ (full skill: instance-provision) |
| 1 | 1.4 Write agent stub | ✅ (full agent: shamu-provisioner) |
| 1 | 1.5 Write hooks.json, .mcp.json, README.md stubs | ✅ |
| 1 | 1.6 Research and record marketplace.json schema | ✅ |
| 1 | 1.7 Write scripts/validate.sh | ✅ |
| 1 | 1.8 Write scripts/build.sh | ✅ |
| 1 | 1.9 Update .gitignore | |
| 1 | 1.10 Update CLAUDE.md dev guide | |
| 1.5 | 1.5.1 Scaffold owasp-audit and secret-scanner | |
| 1.5 | 1.5.2 Fill in their stubs | |
| 1.5 | 1.5.3 Re-run validate + build | |
| 2 | 2.1 Scaffold tests/ directory | |
| 2 | 2.2 Write sandbox CLAUDE.md files (Model A) | |
| 2 | 2.3 Write stub fixtures | |
| 2 | 2.4 Build and install locally from sandbox | |
| 2 | 2.5 Test the reload cycle | |
| 3 | 3.1 Create release branch with concrete placeholder | |
| 3 | 3.2 Set release as GitHub default branch | |
| 3 | 3.3 Write validate.yml | |
| 3 | 3.4 Write release-please config files | |
| 3 | 3.5 Write release.yml (build into temp dir) | |
| 3 | 3.6 Document manual release fallback | |
| 4 | 4.1 Verify release is default on GitHub | |
| 4 | 4.2 Open fresh session | |
| 4 | 4.3 Add marketplace from terminal | |
| 4 | 4.4 Install plugin from terminal | |
| 4 | 4.5 Exercise the installed plugin | |
| 4 | 4.6 Test update flow end-to-end | |

---

*Work through this in order. Each step has a concrete verification condition — do not mark it done until that condition is met.*
