#!/usr/bin/env python3
"""Update the `state:` field of a YAML artifact and append `torn_down_at:`.

Usage: update-artifact-state.py <artifact_file> <new_state> <iso_timestamp>

Rewrites <artifact_file> in place. Idempotent for the timestamp field — if
`torn_down_at:` already exists, it's replaced; otherwise it's appended.
"""
import re
import sys


def main() -> int:
    if len(sys.argv) != 4:
        print(f"usage: {sys.argv[0]} <artifact_file> <new_state> <iso_timestamp>", file=sys.stderr)
        return 2

    path, new_state, ts = sys.argv[1], sys.argv[2], sys.argv[3]

    with open(path) as f:
        content = f.read()

    content = re.sub(r'^state:.*$', f'state: "{new_state}"', content, flags=re.MULTILINE)
    if 'torn_down_at:' in content:
        content = re.sub(r'^torn_down_at:.*$', f'torn_down_at: "{ts}"', content, flags=re.MULTILINE)
    else:
        content = content.rstrip('\n') + f'\ntorn_down_at: "{ts}"\n'

    with open(path, 'w') as f:
        f.write(content)
    print(path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
