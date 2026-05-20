# bb-triage

Bug bounty triage plugin for Claude Code. Helps a security engineer eliminate duplicates, reproduce researcher-reported steps on a live instance, validate the bug, and submit a Jira ticket to engineering.

## Skills

- **`instance-provision`** — provision a live instance to reproduce a bug, or tear one down. Currently dispatches to the Shamu Splunk provisioner. See [skills/instance-provision/README.md](skills/instance-provision/README.md).

## Agents

- **`shamu-provisioner`** — implementation worker for `instance-provision` (Shamu REST API).
