#!/usr/bin/env bash
set -e

# Point git at the tracked .githooks/ directory.
# Idempotent: re-running is a no-op once configured.
git config core.hooksPath .githooks
echo "core.hooksPath set to .githooks"

# Clean up any stale copies left behind by the old install pattern.
# Safe — only touches the three names this repo manages.
rm -f .git/hooks/commit-msg .git/hooks/pre-push .git/hooks/post-merge
echo "Removed any stale copies from .git/hooks/"
