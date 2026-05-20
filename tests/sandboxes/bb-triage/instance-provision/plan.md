# instance-provision skill — development plan

> Working notes for building out this skill. Not shipped to customers (build.sh copies everything, but this file is dev-only context).

## Goal

Provision a live Shamu Splunk instance to reproduce a researcher-reported bug bounty finding, or tear one down when done.

## Open questions

- [ ] What Shamu REST API endpoints are used for provision / teardown?
- [ ] What auth mechanism does the API require (token, OAuth, mTLS)?
- [ ] What is the expected artifact format written to `run_artifacts/`?
- [ ] What does the skill return to the user on success vs. failure?

## Design decisions (record here as they are made)

| Decision | Choice | Reason |
|---|---|---|
| Artifact location | `run_artifacts/` in sandbox cwd | Keeps outputs local, easy to inspect |

## Iteration log

### v0.1 (stub)
- Created SKILL.md with frontmatter only — no real logic yet.
