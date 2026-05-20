# Claude Code Plugin Development — Pattern B + Build Step + Single Repo

> **Purpose of this document:** Complete handoff specification for an Approach 3 plugin development workflow using Pattern B branch layout with a build step, all in a single GitHub repository. This document captures the full mental model, structure, customer experience, and CI/release flow agreed upon. Use it as the starting context for continuing implementation discussions.

---

## 1. Scope and intent

You are building a Claude Code plugin marketplace as a single GitHub repository that hosts multiple related security plugins (e.g., `bb-triage`, `owasp-audit`, `secret-scanner`). The repo serves two completely separate audiences:

- **Customers** — install plugins via `/plugin marketplace add` and `/plugin install`. They never look at source, tests, or CI.
- **You (and future contributors)** — author, validate, test, and release plugins.

The goal is a setup where the customer sees a clean, install-ready repo on GitHub and runs one command, while you retain a full dev environment with validation, semver releases, and CI gates — all in the same repo.

---

## 2. The two-axis decision

There were two independent decisions to make. They are now resolved:

| Question | Choice | Rationale |
|---|---|---|
| **Build step or ship source directly?** | **Build step (yes)** | Pattern B's release branch is auto-generated. Without a build step, the release branch would have to be hand-maintained, which causes drift. Build step keeps source on `main` and ship surface on `release` in lockstep. |
| **Branch layout?** | **Pattern B** | Customer sees only the clean install surface on the GitHub landing page. Default branch = `release`. Dev work happens on `main`, accessible via branch switcher for the curious. |

---

## 3. Mental model

> **`main` is editable. `release` is generated. The two never touch by hand.**

```
You edit packages/ on main      →  validate  →  build dist/  →  publish to release branch  →  customer installs
   (humans)                        (CI gate)    (deterministic)    (auto-pushed)              (/plugin install)
```

Three rules that anchor everything:

1. **You will never hand-edit `marketplace.json`.** It is generated from `packages/` on every build.
2. **`packages/` is the only authoring surface.** Tests, fixtures, scripts, CI, and CLAUDE.md exist to support it. Nothing under `packages/` references them.
3. **A release is just `git tag` + automated build/publish.** Once setup is done, you do not think about release mechanics — you write commit messages in a convention and the system handles the rest.

---

## 4. What the customer sees

### 4.1 GitHub landing page (default branch = `release`)

```
claude-security-tools/        (branch: release — DEFAULT)
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── bb-triage/
│   ├── owasp-audit/
│   └── secret-scanner/
├── README.md
└── LICENSE
```

No `packages/`. No `tests/`. No `scripts/`. No `.github/`. No `CLAUDE.md`. No `.gitignore`. Clean.

### 4.2 Customer-facing README (on `release` branch)

```markdown
# claude-security-tools

Claude Code plugins for security workflows.

## Install

​```
/plugin marketplace add abhijit/claude-security-tools
/plugin install bb-triage@abhijit-security
/plugin install owasp-audit@abhijit-security
/plugin install secret-scanner@abhijit-security
​```

## Update

​```
/plugin marketplace update abhijit-security
/plugin update bb-triage
​```

## Plugins

| Plugin | Description | Requires |
|---|---|---|
| bb-triage | Bug bounty triage with five-dimension scoring | Jira MCP, JIRA_* env vars |
| owasp-audit | OWASP-aligned code review | — |
| secret-scanner | Blocks writes containing secrets | — |

## Source

Development happens on the `main` branch. This branch (`release`) contains only the published, validated artifact.
```

### 4.3 Customer commands

**First install:**

```bash
/plugin marketplace add abhijit/claude-security-tools
/plugin install bb-triage@abhijit-security
```

No `@branch` suffix needed — `release` is the default branch, so `/plugin marketplace add` reads `marketplace.json` from it automatically. **This is the key benefit of Pattern B.**

**Update to latest version (after you publish a new release):**

```bash
/plugin marketplace update abhijit-security
/plugin update bb-triage
```

`marketplace update` re-fetches the release branch. `plugin update` upgrades to the version now listed in `marketplace.json`.

**Reload after local edits (dev-only, customers rarely use this):**

```bash
/plugin reload bb-triage
```

---

## 5. What you see on the `main` branch

```
claude-security-tools/        (branch: main)
├── packages/                 ← source you edit (the only authoring surface)
│   ├── bb-triage/
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   │   └── triage-workflow/
│   │   │       └── SKILL.md
│   │   ├── agents/
│   │   │   └── triage-analyst.md
│   │   ├── hooks/
│   │   │   └── hooks.json
│   │   ├── .mcp.json
│   │   └── README.md          ← plugin-specific docs (ships to customer)
│   ├── owasp-audit/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/owasp-checks/SKILL.md
│   │   └── agents/audit-reviewer.md
│   └── secret-scanner/
│       ├── .claude-plugin/plugin.json
│       └── hooks/hooks.json
│
├── tests/                    ← inner-loop dev environment
│   ├── fixtures/
│   │   ├── jira-tickets/
│   │   │   ├── high-confidence.json
│   │   │   └── low-confidence.json
│   │   └── vulnerable-code-samples/
│   └── sandboxes/
│       ├── bb-triage/
│       │   └── CLAUDE.md      ← user-perspective harness
│       ├── owasp-audit/
│       │   └── CLAUDE.md
│       └── secret-scanner/
│           └── CLAUDE.md
│
├── scripts/
│   ├── validate.sh           ← runs all validators
│   └── build.sh              ← packages/ → dist/
│
├── .github/workflows/
│   ├── validate.yml          ← runs on PR to main
│   └── release.yml           ← builds and pushes to release branch on tag
│
├── release-please-config.json
├── .release-please-manifest.json
├── CLAUDE.md                 ← dev guide for editing the repo
├── README.md                 ← dev-facing README (different from release README)
├── LICENSE
└── .gitignore                ← ignores dist/, .claude/, etc.
```

### 5.1 Two READMEs — why this matters

Pattern B requires two distinct README files:

| File location | Audience | Content |
|---|---|---|
| `main` branch `README.md` | Contributors, you | "How to set up dev, how to add a plugin, how the build works" |
| `release` branch `README.md` | Customers | "How to install, update, what each plugin does" |

The build script generates the release README. You maintain the source as either:
- A separate file `README.release.md` on `main`, which build copies as `README.md` into `dist/`, **or**
- A template `templates/README.md.tmpl` that the build script populates with current plugin metadata.

Generating it is cleaner — single source of truth for plugin list.

---

## 6. The five workflows of Approach 3

Approach 3 is just five repeatable workflows wired together. Once you can do these in sequence, you have a working system.

### 6.1 Author — write or change a plugin

You work inside `packages/<plugin-name>/`. This directory contains exactly what would ship as a plugin (skills, agents, hooks, manifest). You do **not** worry about marketplace.json here — that gets generated later.

### 6.2 Validate — prove the plugin is well-formed

Before code is allowed to merge, every plugin under `packages/` is checked:

- `plugin.json` has required fields and a valid version.
- Every `SKILL.md` has the required frontmatter (`name`, `description`).
- Every agent file has `name` and `description`.
- Hook JSON parses.
- `.mcp.json` parses.
- Optional: lint markdown, check for hardcoded secrets, check for forbidden patterns.

Runs locally (pre-commit hook) and in CI (PR check). A broken plugin **never** reaches users because the gate fails first.

### 6.3 Test — exercise the plugin end-to-end

`tests/` contains fixtures (sample Jira tickets, vulnerable code samples) and per-plugin sandboxes. Each sandbox is a directory you `cd` into to install plugins from `packages/` locally and run them against the fixtures. This is your inner-loop dev environment.

### 6.4 Build — generate the install surface

`scripts/build.sh` reads everything in `packages/`, generates `marketplace.json` listing every plugin with the right metadata, copies plugin directories into `dist/`, and produces a clean artifact that has only what customers need. No dev files, no fixtures, no CLAUDE.md, no scripts.

Deterministic — running build twice on the same source produces identical output.

### 6.5 Release — publish a version customers can install

Triggered by `release-please` based on conventional commits. On release PR merge:
- CI re-runs validation.
- CI runs build.
- CI publishes `dist/` to the `release` branch.
- Customers running `/plugin marketplace update` get the new version.

Versions are semver. Breaking changes bump major. New plugins or new features bump minor. Bug fixes bump patch. You write `feat(bb-triage): add severity dimension`; `release-please` figures out the version bump.

---

## 7. End-to-end flow

```
You edit packages/bb-triage/skills/triage-workflow/SKILL.md
        │
        ▼
git commit -m "feat(bb-triage): improve scoring rubric"
git push origin main (via PR)
        │
        ▼
.github/workflows/validate.yml runs
   ├─ scripts/validate.sh checks all plugins
   └─ ✅ pass → merge to main
        │
        ▼
release-please opens a release PR on main
   (bumps versions based on commit messages)
        │
        ▼
You merge the release PR
        │
        ▼
.github/workflows/release.yml runs
   ├─ scripts/build.sh
   │    ├─ Read packages/
   │    ├─ Generate marketplace.json
   │    ├─ Generate customer-facing README
   │    └─ Write everything to dist/
   ├─ git checkout release
   ├─ Replace contents with dist/
   ├─ git commit + push to release branch
   └─ Create GitHub release with changelog
        │
        ▼
Customer runs /plugin marketplace update abhijit-security
   → Claude Code pulls latest from release branch
   → Customer gets the new version
```

---

## 8. What lives where — the mental map

| Concern | Where it lives | Who edits it |
|---|---|---|
| Plugin source code | `packages/<plugin>/` on `main` | You, by hand |
| Marketplace manifest | Generated into `dist/.claude-plugin/marketplace.json` | Build script |
| Validation logic | `scripts/validate.sh` and `.github/workflows/validate.yml` | You, rarely |
| Test fixtures | `tests/fixtures/` | You, when adding test cases |
| Test sandboxes | `tests/sandboxes/<plugin>/` | You, when adding test cases |
| CI workflows | `.github/workflows/` | You, once at setup |
| Release config | `release-please-config.json` | You, once at setup |
| Dev guide | `CLAUDE.md` on `main` | You, evolves over time |
| Dev README | `README.md` on `main` | You, evolves over time |
| Customer README | Generated → `dist/README.md` → pushed to `release` branch | Build script (from template) |
| What customers install | `release` branch contents | CI only (never hand-edited) |

---

## 9. Inner-loop dev cycle

Your day-to-day post-setup looks like:

```
1. cd packages/bb-triage/
2. Edit SKILL.md, agent, or hook
3. cd ../../tests/sandboxes/bb-triage/
4. /plugin reload bb-triage in Claude Code
5. Run a triage against a fixture, observe behavior
6. Repeat 2–5 until done
7. git commit -m "feat(bb-triage): add severity-weighted scoring"
8. git push
9. Open PR → CI validates → merge
10. release-please opens a release PR with version bump
11. Merge release PR → tagged release → dist published → customers get update
```

Steps 1–6 are seconds. Steps 7–11 are minutes total, mostly automated.

### 9.1 Two-window VS Code workflow

- **Window 1:** Open `claude-security-tools/` on `main` — edit `packages/`.
- **Window 2:** Open `claude-security-tools/tests/sandboxes/bb-triage/` — install plugins locally and exercise them.

First-time setup in Window 2:

```bash
/plugin marketplace add ../../../
/plugin install bb-triage@abhijit-security
```

After edits in Window 1:

```bash
/plugin reload bb-triage   # in Window 2
```

---

## 10. The CI pipeline shape

```
Push to main / open PR
        │
        ▼
   Validate workflow (.github/workflows/validate.yml)
   ├─ Lint plugin.json files
   ├─ Lint SKILL.md frontmatter
   ├─ Lint agent frontmatter
   ├─ Validate hooks.json parses
   ├─ Validate .mcp.json parses
   └─ Run `claude plugin validate` on each
        │
        ▼
  ❌ fail → block merge / show error
  ✅ pass → merge allowed

Push to main (after merge)
        │
        ▼
   Release-please workflow
   ├─ Read commit messages since last release
   ├─ Compute next version per plugin (independent versioning)
   ├─ Open / update a release PR
   └─ On release PR merge: tag + trigger publish

Release PR merged + tag created
        │
        ▼
   Build + publish workflow (.github/workflows/release.yml)
   ├─ Run validate again (belt and suspenders)
   ├─ Run scripts/build.sh → produce dist/
   ├─ Push dist/ to release branch (force-push or commit-on-top)
   └─ Create GitHub release with changelog
```

---

## 11. One-time setup pieces

These are set up once, then forgotten:

1. `scripts/validate.sh` — runs all validators.
2. `scripts/build.sh` — generates `marketplace.json`, copies plugins to `dist/`, generates customer README.
3. `.github/workflows/validate.yml` — runs validate on PR.
4. `.github/workflows/release.yml` — runs release-please, then build+publish on tag.
5. `release-please-config.json` — declares which plugins are versioned independently.
6. `.release-please-manifest.json` — tracks current version per plugin.
7. `.pre-commit-config.yaml` (optional) — runs validate locally before commit.
8. `CLAUDE.md` — dev guide for you and future contributors.
9. `tests/sandboxes/<plugin>/CLAUDE.md` — per-plugin test harness.
10. Initial `release` branch creation (orphan branch, see §12).

---

## 12. Initial `release` branch setup (one-time, manual)

The first time you set up Pattern B, do this once:

```bash
git checkout --orphan release
git rm -rf .
# Add an initial placeholder marketplace.json and README so the branch is valid
cat > README.md <<'EOF'
# claude-security-tools

Initial release branch — content will be populated on first CI release.
EOF
mkdir -p .claude-plugin
cat > .claude-plugin/marketplace.json <<'EOF'
{
  "name": "abhijit-security",
  "owner": { "name": "Abhijit" },
  "plugins": []
}
EOF
git add .
git commit -m "Initial release branch"
git push origin release
```

Then in GitHub: **Settings → Branches → Default branch → change from `main` to `release`.**

After that, CI maintains the `release` branch automatically. You never check it out again from your dev machine.

---

## 13. Commit message convention (Conventional Commits)

`release-please` reads commit messages to compute version bumps. Use this format:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

Examples:

```
feat(bb-triage): add severity dimension to scoring rubric
fix(secret-scanner): handle AWS session tokens
feat(owasp-audit)!: rewrite agent prompt for OWASP 2025
chore(repo): update CI node version
docs(bb-triage): clarify JIRA env var requirements
```

| Type | Version bump |
|---|---|
| `feat` | minor |
| `fix` | patch |
| `feat!` or `BREAKING CHANGE:` in body | major |
| `chore`, `docs`, `style`, `refactor`, `test` | no version bump |

The `scope` should match the plugin name for plugin-specific changes, or `repo` for cross-cutting changes.

---

## 14. Independent versioning per plugin

Each plugin in `packages/<name>/.claude-plugin/plugin.json` has its own version. `release-please-config.json` declares them as independent:

```json
{
  "packages": {
    "packages/bb-triage": {
      "release-type": "simple",
      "package-name": "bb-triage"
    },
    "packages/owasp-audit": {
      "release-type": "simple",
      "package-name": "owasp-audit"
    },
    "packages/secret-scanner": {
      "release-type": "simple",
      "package-name": "secret-scanner"
    }
  }
}
```

`bb-triage` can be at v1.4.2 while `secret-scanner` is at v0.3.0. A commit scoped to one plugin only bumps that plugin's version.

---

## 15. What you give up vs. simpler approaches

- **Speed of first commit:** Approach 2 you're shipping in an hour. Approach 3 takes a day to set up the pipeline.
- **Conceptual overhead:** You need to understand the build/release distinction.

## 16. What you gain

- **Safety:** Bad changes can't reach customers — CI gates block them.
- **History:** Every release is tagged, changelogged, diff-able.
- **Multi-author readiness:** When a contributor opens a PR, CI gates it.
- **Independence per plugin:** Plugins version independently.
- **Trust:** Anyone auditing your published surface sees only the install artifact, no dev noise.
- **Clean customer experience:** Default branch is install-ready; install command has no branch suffix.

---

## 17. Open items for next discussion

Things still to decide / implement when you continue:

1. **Concrete contents of `scripts/build.sh`** — exact bash/node script that reads `packages/`, emits `dist/`.
2. **Concrete contents of `scripts/validate.sh`** — validator implementation (likely a mix of `jq`, `yq`, and `claude plugin validate`).
3. **Concrete `.github/workflows/validate.yml` and `release.yml`** — full YAML.
4. **`release-please-config.json` and `.release-please-manifest.json`** — initial state.
5. **Customer README template** — what fields are auto-populated vs. hand-written.
6. **`CLAUDE.md` for the `main` branch** — dev guide.
7. **Per-plugin sandbox `CLAUDE.md`** under `tests/sandboxes/<plugin>/` — test harness context.
8. **Pre-commit hook config** (optional but recommended).
9. **Naming finalization** — marketplace name (`abhijit-security`?), GitHub repo name (`claude-security-tools`?).
10. **Initial plugin content** for `bb-triage` (skill + agent + hooks + MCP), `owasp-audit`, `secret-scanner`.

---

## 18. Glossary — terms used in this doc

| Term | Meaning |
|---|---|
| **Marketplace** | A directory containing `marketplace.json` listing one or more plugins. Customers add it via `/plugin marketplace add`. |
| **Plugin** | A directory with `.claude-plugin/plugin.json` and any combination of skills, agents, commands, hooks, MCP servers. |
| **Skill** | A `SKILL.md` file with YAML frontmatter; auto-invoked by description matching or via `/<skill-name>`. Has replaced commands going forward. |
| **Agent (subagent)** | A markdown file in `agents/` with frontmatter declaring name, description, tools, model. Invoked via the Task tool. |
| **Hook** | A JSON-configured deterministic event handler (`PreToolUse`, `PostToolUse`, `SessionStart`, etc.). Cannot be bypassed by the model. |
| **Command** | Deprecated. Custom slash commands merged into skills. Existing `commands/` files still work but new plugins should use skills only. |
| **MCP server** | External tool server registered via `.mcp.json` in plugin root. |
| **Pattern A** | Default branch = `main` (dev visible), customers install from `@release`. |
| **Pattern B** | Default branch = `release` (clean), dev hidden on `main`. **This is our choice.** |
| **`packages/`** | Authoring directory on `main`. Source of truth. |
| **`dist/`** | Build output. Gitignored on `main`, pushed to `release` branch by CI. |
| **release-please** | Google's tool that automates semver versioning and changelog generation from conventional commits. |

---

*End of handoff doc. Continue from §17 — open items — when picking this up in another system.*
