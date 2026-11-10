#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_FILE="${1:?Usage: $0 <workflow-filename>}"
WORKFLOW_PATH=".github/workflows/${WORKFLOW_FILE}"

echo "=== Checking trigger config for: ${WORKFLOW_PATH} ==="

if [[ ! -f "${WORKFLOW_PATH}" ]]; then
  echo "FAIL: File not found: ${WORKFLOW_PATH}"
  exit 1
fi
echo "PASS: File exists"

python3 - "${WORKFLOW_PATH}" <<'PYEOF'
import sys
import re

workflow_path = sys.argv[1]

with open(workflow_path, "r") as f:
    content = f.read()

def extract_sequence_values(text, key):
    """
    Extract a list of string values from a YAML mapping key whose value is
    either a flow sequence  key: [a, b]  or a block sequence:
        key:
          - a
          - b
    Returns a list of stripped strings (quotes removed).
    """
    # Flow form: key: [val1, val2, ...]
    flow_re = re.compile(
        r'^\s*' + re.escape(key) + r'\s*:\s*\[([^\]]*)\]',
        re.MULTILINE
    )
    m = flow_re.search(text)
    if m:
        raw = m.group(1)
        items = [v.strip().strip('"').strip("'") for v in raw.split(',') if v.strip()]
        return items

    block_key_re = re.compile(
        r'^\s*' + re.escape(key) + r'\s*:\s*$',
        re.MULTILINE
    )
    mk = block_key_re.search(text)
    if not mk:
        return []

    line_start = text.rfind('\n', 0, mk.start()) + 1
    key_line   = text[line_start:mk.end()]
    key_indent = len(key_line) - len(key_line.lstrip())

    rest    = text[mk.end():]
    items   = []
    item_re = re.compile(r'^(\s*)-\s+(.+)$')
    for line in rest.split('\n'):
        if not line.strip():
            continue
        im = item_re.match(line)
        if im:
            item_indent = len(im.group(1))
            if item_indent > key_indent:
                items.append(im.group(2).strip().strip('"').strip("'"))
                continue
        stripped = line.lstrip()
        cur_indent = len(line) - len(stripped)
        if cur_indent <= key_indent and stripped and not stripped.startswith('#'):
            break

    return items

on_push_re = re.compile(
    r'^on\s*:.*?(?=\n\S|\Z)',
    re.MULTILINE | re.DOTALL
)
m_on = on_push_re.search(content)
if not m_on:
    print("FAIL: No 'on:' section found in workflow")
    sys.exit(1)

on_block = m_on.group(0)

if 'push' not in on_block:
    print("FAIL: 'push' event not found in on: trigger")
    sys.exit(1)

push_re = re.compile(
    r'push\s*:(.+?)(?=\n\s{0,3}\S|\Z)',
    re.DOTALL
)
mp = push_re.search(on_block)
push_block = mp.group(0) if mp else on_block  # fallback: search whole on block

branches = extract_sequence_values(push_block, 'branches')
if not branches:
    branches = extract_sequence_values(content, 'branches')

if 'main' not in branches:
    print(f"FAIL: on.push.branches does not include 'main'. Found: {branches}")
    sys.exit(1)
print(f"PASS: on.push.branches includes 'main' (found: {branches})")

print("ALL TRIGGER CHECKS PASSED")
sys.exit(0)
PYEOF
