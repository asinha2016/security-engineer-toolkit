#!/usr/bin/env bash
# Renders an artifact YAML from a template by substituting __PLACEHOLDER__ tokens
# with the corresponding shell variables. Caller exports the variables, then:
#
#   bash render-artifact.sh partial > "$ARTIFACT_FILE"
#   bash render-artifact.sh final   > "$ARTIFACT_FILE"
#
# Required env vars (both modes):
#   SKILL_DIR, JOB_ID, CLOUD, TIMESTAMP, EXPIRES,
#   SPLUNK_VERSION_OR_NULL, SPLUNK_BUILD_OR_NULL
#
# Required env vars (final mode only):
#   DEPLOYMENT_ID, HOST, ROLE, CLUSTER, NAMESPACE, PLATFORM,
#   PORT_WEB, PORT_SPLUNKD, PORT_HEC, PORT_SSH, PORT_SYSLOG, PORT_S2S,
#   SSH_KEY_PATH, CONTAINER_ID, RUN_ID
#
# For partial mode, DEPLOYMENT_ID may be unset (rendered as `null`).

set -euo pipefail

MODE="${1:?usage: render-artifact.sh partial|final}"
TEMPLATE="$SKILL_DIR/templates/artifact-${MODE}.yaml.tmpl"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: template not found: $TEMPLATE" >&2
  exit 2
fi

if [[ "$MODE" == "partial" ]]; then
  DEPLOYMENT_ID="${DEPLOYMENT_ID:-TBD}"
  DEPLOYMENT_ID_OR_NULL="null"
else
  DEPLOYMENT_ID_OR_NULL="\"$DEPLOYMENT_ID\""
fi

sed \
  -e "s|__JOB_ID__|${JOB_ID}|g" \
  -e "s|__DEPLOYMENT_ID__|${DEPLOYMENT_ID}|g" \
  -e "s|__DEPLOYMENT_ID_OR_NULL__|${DEPLOYMENT_ID_OR_NULL}|g" \
  -e "s|__SPLUNK_VERSION_OR_NULL__|${SPLUNK_VERSION_OR_NULL}|g" \
  -e "s|__SPLUNK_BUILD_OR_NULL__|${SPLUNK_BUILD_OR_NULL}|g" \
  -e "s|__CLOUD__|${CLOUD}|g" \
  -e "s|__TIMESTAMP__|${TIMESTAMP}|g" \
  -e "s|__EXPIRES__|${EXPIRES}|g" \
  -e "s|__HOST__|${HOST:-}|g" \
  -e "s|__ROLE__|${ROLE:-}|g" \
  -e "s|__CLUSTER__|${CLUSTER:-}|g" \
  -e "s|__NAMESPACE__|${NAMESPACE:-}|g" \
  -e "s|__PLATFORM__|${PLATFORM:-}|g" \
  -e "s|__PORT_WEB__|${PORT_WEB:-}|g" \
  -e "s|__PORT_SPLUNKD__|${PORT_SPLUNKD:-}|g" \
  -e "s|__PORT_HEC__|${PORT_HEC:-}|g" \
  -e "s|__PORT_SSH__|${PORT_SSH:-}|g" \
  -e "s|__PORT_SYSLOG__|${PORT_SYSLOG:-}|g" \
  -e "s|__PORT_S2S__|${PORT_S2S:-}|g" \
  -e "s|__SSH_KEY_PATH__|${SSH_KEY_PATH:-}|g" \
  -e "s|__CONTAINER_ID__|${CONTAINER_ID:-}|g" \
  -e "s|__RUN_ID__|${RUN_ID:-}|g" \
  "$TEMPLATE"
