# Commit Message Conventions

Format: `<type>(<scope>): <description>`

---

## Types

| Type | Semver effect | Use when |
|---|---|---|
| `feat` | minor bump (`0.1.0 → 0.2.0`) | new skill, new agent, new capability |
| `fix` | patch bump (`0.1.0 → 0.1.1`) | bug fix in a skill or hook |
| `feat!` | major bump (`0.1.0 → 1.0.0`) | breaking change — rename a skill, remove a parameter, change output shape |
| `chore` | no bump | housekeeping, config tweaks, dependency updates |
| `docs` | no bump | README, CLAUDE.md, plan doc, reference doc edits |
| `refactor` | no bump | restructuring without behaviour change |
| `ci` | no bump | GitHub Actions workflows, git hook scripts |
| `test` | no bump | fixture files, sandbox changes |

---

## Scope

The scope must match the **directory name** under `packages/`. Omit it for repo-level changes.

| Scope | When to use |
|---|---|
| `bb-triage` | any change inside `packages/bb-triage/` |
| `owasp-audit` | any change inside `packages/owasp-audit/` (Phase 1.5) |
| `secret-scanner` | any change inside `packages/secret-scanner/` (Phase 1.5) |
| _(omit)_ | repo-level change not tied to one plugin |

---

## Examples

```
# New capability → minor bump
feat(bb-triage): add CVSS scoring to instance-provision

# Bug fix → patch bump
fix(bb-triage): correct Shamu API endpoint in get-token.sh

# Breaking change → major bump
feat(bb-triage)!: rename skill instance-provision to provision-instance

# Housekeeping — no bump
chore(bb-triage): update config.yaml default TTL to 8 hours

# Repo-level docs — no bump, no scope
docs: update IMPLEMENTATION-PLAN.md Phase 3 steps

# CI change — no bump, no scope
ci: add pre-push hook install script

# Sandbox / test change — no bump
test(bb-triage): add sample-high fixture for CVSS triage scenario
```

---

## Rules of thumb

- If the commit touches anything inside `packages/<plugin>/` that a customer would notice → use `feat` or `fix` with the plugin scope.
- If it only affects dev tooling, docs, or CI → use `chore`, `docs`, or `ci` with no scope.
- release-please ignores commits whose scope does not match a registered package path, so typos in the scope silently skip the version bump.
- A single commit should only carry one scope. If you touched two plugins, split into two commits.
