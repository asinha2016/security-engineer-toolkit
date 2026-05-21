# instance-provision

Provisions and tears down live instances via a provider's REST API. The current implementation targets Shamu Splunk; the skill is structured so additional providers can be added without renaming the skill.

Used inside the **bb-triage** plugin so a security engineer can spin up a real instance to reproduce the steps reported by an external researcher before submitting a Jira ticket to engineering.

## Prerequisites

### 1. AD credentials in `~/.claude/settings.json`

```json
{
  "env": {
    "SHAMU_AD_USER": "your-ad-username",
    "SHAMU_AD_PASSWORD": "your-ad-password"
  }
}
```

### 2. SSH private key on disk

The Shamu SSH private key must be present at the path set by `ssh_key_path` in `config/config.yaml` (default: `~/.ssh/SHAMU_PRIVATE_KEY`). This is provisioned separately — the skill does not fetch or generate it.

### 3. Required CLI tools

- `curl` — API calls
- `jq` — JSON parsing
- `python3` — token parsing (handles unescaped newlines in API response)

---

## Usage

```
/instance-provision --version <semver>                    # provision by Splunk version
/instance-provision --version <semver> --cloud <provider> # override cloud (default: kubernetes)
/instance-provision --build <git-hash>                    # provision by build hash
/instance-provision --teardown <deployment-id>            # tear down a running instance
```

**Supported `--cloud` values:** `kubernetes` (default), `aws-ec2`

### Examples

```
/instance-provision --version 9.2.1
/instance-provision --version 10.2.2 --cloud aws-ec2
/instance-provision --build 92ca7157c40c
/instance-provision --teardown asinha260519153645fwkzq
```

---

## What happens

### Provision

1. Validates AD credentials
2. Authenticates with the Shamu API (`GET /v1/token`)
3. Submits a create job (`POST /v1/jobs`)
4. Polls until ready (max 10 minutes)
5. Writes a YAML artifact to `reports/instance-provision/<version>_<job_prefix>.yaml`
6. Prints connection details

### Teardown

1. Validates AD credentials
2. Authenticates with the Shamu API
3. Reads the local artifact to determine the cloud provider
4. Submits a destroy job (`POST /v1/jobs`)
5. Polls until complete (max 5 minutes)
6. Updates artifact state to `torn_down`

---

## Configuration

All parameters are in `config/config.yaml`:

```yaml
# Shamu API base URL — change for staging/dev environments
api_base_url: https://shamu.splunkeng.com/v1

# Shamu API docs — consulted by the agent on unexpected API errors
api_docs: https://shamu.splunkeng.com/api/doc

# Default cloud when --cloud is not passed: kubernetes, aws-ec2
default_cloud: kubernetes

# Path to the Shamu SSH private key on disk
ssh_key_path: ~/.ssh/SHAMU_PRIVATE_KEY

# Instance TTL in hours — sets expires_at in the artifact
instance_ttl_hours: 4

# Output directory for provisioning artifacts (relative to project root)
artifact_dir: reports/instance-provision

# Model used by the provisioning sub-agent: opus, sonnet, haiku
model: sonnet
```

---

## Output artifact

Each provisioned instance writes a YAML file at `<artifact_dir>/<version>_<job_prefix>.yaml`.

The artifact contains the deployment ID, host, all port mappings, SSH command, and connection URLs. Use it to tear down the instance later:
```
/instance-provision --teardown <deployment_id>
```

> **Security:** Artifact files contain instance credentials. The default `reports/` directory is gitignored. If you change `artifact_dir`, make sure to add the new path to `.gitignore` before committing. The `artifact_dir` is created automatically if it does not exist.

### Artifact states

| State | Meaning |
|---|---|
| `provisioning` | Job submitted, waiting for instance to be ready |
| `ready` | Instance is up and reachable |
| `failure` | Provision job returned a failure status — check the error output |
| `timeout` | Provision job did not complete within 10 minutes — instance may still be coming up; check Shamu UI |
| `torn_down` | Teardown completed successfully |
| `teardown_failure` | Teardown job returned a failure status — check the error output |
| `teardown_timeout` | Teardown job did not complete within 5 minutes — check Shamu UI |

On teardown completion, a `torn_down_at` timestamp field is appended to the artifact.

---

## Error handling reference

The agent handles each of these conditions inline. This table is for human reference when debugging.

| Condition | Action taken by agent |
|---|---|
| Pre-flight: missing AD creds | Abort immediately with clear message |
| Auth: TOKEN empty/null | Abort: check AD credentials |
| `POST /jobs`: 400 | Print full response, abort |
| `POST /jobs`: 401 | Prompt user to check `SHAMU_AD_USER` / `SHAMU_AD_PASSWORD` |
| `POST /jobs`: jobStatus != accepted | Print full response, abort |
| Polling: jobStatus == failure (provision) | Update artifact to `state: failure`, print full response, abort |
| Polling timeout (provision) | Update artifact to `state: timeout`, print job ID, abort |
| Polling: jobStatus == failure (teardown) | Update artifact to `state: teardown_failure` if found, print full response, abort |
| Polling timeout (teardown) | Update artifact to `state: teardown_timeout` if found, print job ID, tell user to check Shamu UI |
| Artifact not found (teardown) | Warn user, skip artifact update, complete teardown summary |

---

## Layout

```
skills/instance-provision/
├── SKILL.md                          # skill manifest (invokes the agent)
├── README.md                         # this file
├── config/config.yaml                # API URLs, defaults, model choice
├── scripts/
│   ├── get-token.sh                  # auth helper
│   ├── extract-artifact.sh           # parses Shamu API response into shell vars
│   └── update-artifact-state.py      # mutates state/torn_down_at fields in YAML artifact
└── templates/
    ├── artifact-partial.yaml.tmpl    # written immediately after job accept
    └── artifact-final.yaml.tmpl      # written when instance is ready
```

The agent file lives at `agents/shamu-provisioner.md` (separate from the skill because it's the implementation worker, not the user-facing interface).

---

## References

- Shamu UI: https://shamu.splunkeng.com
- Shamu API docs: https://shamu.splunkeng.com/api/doc

## Installation

This skill is part of the `bb-triage` plugin. To install:

```
/plugin install bb-triage@greyshell
```

Then:
1. Set `SHAMU_AD_USER` and `SHAMU_AD_PASSWORD` in your `~/.claude/settings.json`
2. Place your Shamu SSH private key on disk and set `ssh_key_path` in `config/config.yaml` to its location
3. Review `config/config.yaml` before the first run — it controls the default cloud, TTL, artifact directory, and model
