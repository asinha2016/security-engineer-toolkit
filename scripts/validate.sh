#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$REPO_ROOT/packages"
ERRORS=0

error() {
  echo "ERROR: $*" >&2
  ERRORS=$((ERRORS + 1))
}

# Check a JSON file parses cleanly
check_json() {
  local file="$1"
  if ! jq empty "$file" 2>/dev/null; then
    error "$file is not valid JSON"
    return 1
  fi
}

# Check YAML frontmatter has a required key
check_frontmatter_key() {
  local file="$1" key="$2"
  local value
  value=$(awk '/^---$/{f=!f;next}f' "$file" | grep -E "^${key}:" || true)
  if [ -z "$value" ]; then
    error "$file: frontmatter missing '$key:'"
  fi
}

# Verify every sandbox has a matching plugin source
for sandbox_dir in "$REPO_ROOT/tests/sandboxes"/*/; do
  [ -d "$sandbox_dir" ] || continue
  plugin_name=$(basename "$sandbox_dir")
  [ "$plugin_name" = ".DS_Store" ] && continue
  if [ ! -d "$REPO_ROOT/packages/$plugin_name" ]; then
    error "sandbox '$plugin_name' references a plugin source that does not exist at packages/$plugin_name"
  fi
done

# Warn if a plugin has no sandbox (dev-only check, does not fail validation)
for plugin_dir in "$PACKAGES_DIR"/*/; do
  [ -d "$plugin_dir" ] || continue
  plugin_name=$(basename "$plugin_dir")
  [ "$plugin_name" = ".DS_Store" ] && continue
  if [ ! -d "$REPO_ROOT/tests/sandboxes/$plugin_name" ]; then
    echo "WARNING: plugin '$plugin_name' has no sandbox under tests/sandboxes/" >&2
  fi
done

for plugin_dir in "$PACKAGES_DIR"/*/; do
  [ -d "$plugin_dir" ] || continue
  plugin_name=$(basename "$plugin_dir")
  [ "$plugin_name" = ".DS_Store" ] && continue

  # 1. plugin.json — exists, valid JSON, required fields present
  plugin_json="$plugin_dir/.claude-plugin/plugin.json"
  if [ ! -f "$plugin_json" ]; then
    error "$plugin_name: missing .claude-plugin/plugin.json"
  else
    if check_json "$plugin_json"; then
      for field in name version description; do
        val=$(jq -r ".${field} // empty" "$plugin_json")
        [ -n "$val" ] || error "$plugin_name: plugin.json missing '$field'"
      done
      # author must be an object with a non-empty name
      author_name=$(jq -r '.author.name // empty' "$plugin_json")
      [ -n "$author_name" ] || error "$plugin_name: plugin.json 'author' must be an object with a 'name' field"
    fi
  fi

  # 2. SKILL.md files — each must have name: and description: in frontmatter
  if [ -d "$plugin_dir/skills" ]; then
    while IFS= read -r -d '' skill_md; do
      check_frontmatter_key "$skill_md" "name"
      check_frontmatter_key "$skill_md" "description"
    done < <(find "$plugin_dir/skills" -name "SKILL.md" -print0)
  fi

  # 3. Agent .md files — each must have name: and description: in frontmatter
  if [ -d "$plugin_dir/agents" ]; then
    while IFS= read -r -d '' agent_md; do
      check_frontmatter_key "$agent_md" "name"
      check_frontmatter_key "$agent_md" "description"
    done < <(find "$plugin_dir/agents" -name "*.md" -print0)
  fi

  # 4. hooks.json — valid JSON if present
  hooks_json="$plugin_dir/hooks/hooks.json"
  if [ -f "$hooks_json" ]; then
    check_json "$hooks_json"
  fi

  # 5. .mcp.json — valid JSON if present
  mcp_json="$plugin_dir/.mcp.json"
  if [ -f "$mcp_json" ]; then
    check_json "$mcp_json"
  fi
done

if [ "$ERRORS" -gt 0 ]; then
  echo "Validation failed with $ERRORS error(s)." >&2
  exit 1
fi

echo "Validation passed."
