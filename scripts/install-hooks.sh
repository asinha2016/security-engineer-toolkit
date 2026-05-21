#!/usr/bin/env bash
set -e
HOOKS_DIR=".git/hooks"

install_hook() {
  local name="$1"
  local src="scripts/hooks/$name"
  local dst="$HOOKS_DIR/$name"
  cp "$src" "$dst"
  chmod +x "$dst"
  echo "Installed $dst"
}

install_hook commit-msg
install_hook pre-push
install_hook post-merge
echo "All hooks installed."
