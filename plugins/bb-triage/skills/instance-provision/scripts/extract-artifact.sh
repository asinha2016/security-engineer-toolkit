#!/usr/bin/env bash
# Reads the Shamu /jobs/<id> success response from stdin (JSON) and emits
# shell-sourceable variable assignments on stdout. Caller does:
#
#   eval "$(echo "$RESULT" | bash extract-artifact.sh)"
#
# Then has DEPLOYMENT_ID, CONTAINER_ID, HOST, ROLE, CLUSTER, NAMESPACE, PLATFORM,
# RUN_ID, PORT_WEB, PORT_SPLUNKD, PORT_HEC, PORT_SSH, PORT_SYSLOG, PORT_S2S
# in scope.
#
# Requires SHAMU_AD_USER set in the environment (used as the top-level key in
# jobResult). Requires `jq`.

set -euo pipefail

if [[ -z "${SHAMU_AD_USER:-}" ]]; then
  echo "echo 'ERROR: SHAMU_AD_USER not set' >&2; exit 1"
  exit 1
fi

RESULT=$(cat)

DEPLOYMENT_ID=$(jq --arg user "$SHAMU_AD_USER" -r '.jobResult[$user] | keys[0]' <<<"$RESULT")
CONTAINER_ID=$(jq --arg user "$SHAMU_AD_USER" --arg did "$DEPLOYMENT_ID" -r '.jobResult[$user][$did].containers | keys[0]' <<<"$RESULT")
PAYLOAD=$(jq --arg user "$SHAMU_AD_USER" --arg did "$DEPLOYMENT_ID" --arg cid "$CONTAINER_ID" -r '.jobResult[$user][$did].containers[$cid]' <<<"$RESULT")

read_field() { jq -r "$1 // empty" <<<"$PAYLOAD"; }
read_port()  { jq -r "$1 // empty" <<<"$PAYLOAD" | cut -d: -f2; }

cat <<EOF
DEPLOYMENT_ID='$DEPLOYMENT_ID'
CONTAINER_ID='$CONTAINER_ID'
HOST='$(read_field .host)'
ROLE='$(read_field .role)'
CLUSTER='$(read_field .cluster)'
NAMESPACE='$(read_field .namespace)'
PLATFORM='$(read_field .platform)'
RUN_ID='$(read_field '.runID // .run_id')'
PORT_WEB='$(read_port .ports.splunk_web)'
PORT_SPLUNKD='$(read_port .ports.splunkd)'
PORT_HEC='$(read_port .ports.hec)'
PORT_SSH='$(read_port .ports.ssh)'
PORT_SYSLOG='$(read_port .ports.syslog_tcp)'
PORT_S2S='$(read_port .ports.s2s)'
EOF
