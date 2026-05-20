---
name: instance-provision
description: Provision a live instance to reproduce a researcher or customer reported bug, or tear one down. First skill of the bb-triage plugin — gives you a running target to validate the steps to reproduce. Currently dispatches to the Shamu Splunk provisioner.
---

# instance-provision

Provision a live instance to reproduce a researcher-reported bug, or tear one down.

## Usage

```
/instance-provision --version <semver>                    # e.g. 9.2.1
/instance-provision --version <semver> --cloud <provider> # override cloud (default: kubernetes)
/instance-provision --build <git-hash>                    # e.g. 92ca7157c40c
/instance-provision --teardown <deployment-id>
```

Supported `--cloud` values: `kubernetes` (default), `aws-ec2`

## Instructions

Parse the arguments provided by the user:

- If `--version <value>` is given: mode = provision, versionField = `splunkVersion`, versionValue = `<value>`
- If `--build <value>` is given: mode = provision, versionField = `splunkBuild`, versionValue = `<value>`
- If `--teardown <value>` is given: mode = teardown, deploymentId = `<value>`
- If none of the above match, or both `--version` and `--build` are given: print a clear usage error and stop.
- If `--cloud <value>` is given alongside provision: cloudValue = `<value>`. Otherwise cloudValue = `default_cloud` from config.
- For teardown: cloudValue = `default_cloud` from config (used only as fallback if the artifact has no `cloud` field).

Read `.claude/skills/instance-provision/config/config.yaml` and extract:
- `api_base_url` — default to `https://shamu.splunkeng.com/v1` if missing
- `api_docs` — default to `https://shamu.splunkeng.com/api/doc` if missing
- `default_cloud` — default to `kubernetes` if missing; used as cloudValue when `--cloud` is not passed
- `ssh_key_path` — default to `~/.ssh/SHAMU_PRIVATE_KEY` if missing
- `instance_ttl_hours` — default to `4` if missing
- `artifact_dir` — default to `reports/instance-provision` if missing
- `model` — default to `sonnet` if missing

Then call the Agent tool with:
- `subagent_type`: `general-purpose` (will switch to `shamu-provisioner` once subagent registration is wired up — see plan Step 1.6)
- `model`: the value read from config
- `prompt`: the full agent instructions from `.claude/agents/shamu-provisioner.md` followed by the invocation details — mode, versionField, versionValue, cloudValue, deploymentId (teardown only), apiBaseUrl, apiDocs, sshKeyPath, instanceTtlHours, artifactDir, skillDir (path to this skill's directory so the agent can locate `scripts/` and `templates/`)
