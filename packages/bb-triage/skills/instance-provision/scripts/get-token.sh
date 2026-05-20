#!/usr/bin/env bash
# Fetches a Shamu API bearer token. Reads SHAMU_AD_USER, SHAMU_AD_PASSWORD, and
# the API base URL (passed as $1) from the environment. Prints the token on
# stdout. Exits 1 if auth fails or the token is empty.
#
# The Shamu /token response contains a `sshPrivateKey` field with literal
# unescaped newlines, which breaks `jq`. We use Python instead.

set -euo pipefail

API_BASE_URL="${1:-}"
if [[ -z "$API_BASE_URL" ]]; then
  echo "ERROR: usage: get-token.sh <api_base_url>" >&2
  exit 2
fi
if [[ -z "${SHAMU_AD_USER:-}" || -z "${SHAMU_AD_PASSWORD:-}" ]]; then
  echo "ERROR: SHAMU_AD_USER or SHAMU_AD_PASSWORD not set" >&2
  exit 2
fi

AUTH=$(printf '%s:%s' "$SHAMU_AD_USER" "$SHAMU_AD_PASSWORD" | base64 | tr -d '\n')

TOKEN=$(curl -sS -X GET "$API_BASE_URL/token" -H "Authorization: Basic $AUTH" \
  | python3 -c "import json,sys,os; d=json.loads(sys.stdin.read(), strict=False); u=os.environ.get('SHAMU_AD_USER',''); print(d.get(u,{}).get('token','') or d.get('token',''))")

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "ERROR: auth failed (empty token) — check SHAMU_AD_USER and SHAMU_AD_PASSWORD" >&2
  exit 1
fi

printf '%s' "$TOKEN"
