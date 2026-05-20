#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$REPO_ROOT/packages"
DIST_DIR="$REPO_ROOT/dist"

# 1. Delete and recreate dist/
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/plugins"
mkdir -p "$DIST_DIR/.claude-plugin"

# 2. Copy each package to dist/plugins/<name>/ and collect plugin metadata
MARKETPLACE_PLUGINS="[]"

for plugin_dir in "$PACKAGES_DIR"/*/; do
  [ -d "$plugin_dir" ] || continue
  plugin_name=$(basename "$plugin_dir")

  # Skip macOS metadata directories
  [ "$plugin_name" = ".DS_Store" ] && continue

  rsync -a --exclude='.DS_Store' "$plugin_dir" "$DIST_DIR/plugins/$plugin_name/"

  plugin_json="$plugin_dir/.claude-plugin/plugin.json"

  # 3. Accumulate one entry per plugin for marketplace.json
  entry=$(jq -n \
    --arg name        "$(jq -r .name        "$plugin_json")" \
    --arg description "$(jq -r .description "$plugin_json")" \
    --arg author_name "$(jq -r .author.name "$plugin_json")" \
    --arg source      "./plugins/$plugin_name" \
    '{name: $name, description: $description, author: {name: $author_name}, source: $source}')

  MARKETPLACE_PLUGINS=$(echo "$MARKETPLACE_PLUGINS" | jq --argjson entry "$entry" '. + [$entry]')
done

# 3 (cont). Write marketplace.json — sorted by name for deterministic output
jq -n \
  --arg schema      "https://anthropic.com/claude-code/marketplace.schema.json" \
  --arg name        "greyshell" \
  --arg description "Security engineer toolkit — plugins for security engineers" \
  --argjson plugins "$(echo "$MARKETPLACE_PLUGINS" | jq 'sort_by(.name)')" \
  '{
    "$schema": $schema,
    name: $name,
    description: $description,
    owner: {name: "Abhijit Sinha"},
    plugins: $plugins
  }' > "$DIST_DIR/.claude-plugin/marketplace.json"

# 4. Generate customer-facing dist/README.md
{
  echo "# security-engineer-toolkit"
  echo ""
  echo "Security engineer plugins for Claude Code."
  echo ""
  echo "## Plugins"
  echo ""

  for plugin_dir in "$PACKAGES_DIR"/*/; do
    [ -d "$plugin_dir" ] || continue
    plugin_name=$(basename "$plugin_dir")
    [ "$plugin_name" = ".DS_Store" ] && continue

    plugin_json="$plugin_dir/.claude-plugin/plugin.json"
    description=$(jq -r .description "$plugin_json")
    echo "- **\`$plugin_name\`** — $description"
  done

  echo ""
  echo "## Install"
  echo ""
  echo '```'
  echo "/plugin marketplace add asinha2016/security-engineer-toolkit"
  echo "/plugin install bb-triage@greyshell"
  echo '```'
} > "$DIST_DIR/README.md"

echo "Build complete: $DIST_DIR"
