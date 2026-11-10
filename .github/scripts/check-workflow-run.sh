#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_FILE="${1:?Usage: $0 <workflow-filename>}"
DEADLINE="2028-04-01T09:00:00Z"

echo "=== Checking workflow run success: ${WORKFLOW_FILE} ==="
echo "    Deadline: ${DEADLINE}"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "FAIL: GITHUB_TOKEN is not set — cannot call GitHub API"
  exit 1
fi

REPO="${GITHUB_REPOSITORY}"
API_BASE="https://api.github.com"
AUTH_HEADER="Authorization: Bearer ${GITHUB_TOKEN}"
ACCEPT_HEADER="Accept: application/vnd.github+json"
VERSION_HEADER="X-GitHub-Api-Version: 2022-11-28"

RUNS_URL="${API_BASE}/repos/${REPO}/actions/workflows/${WORKFLOW_FILE}/runs"
RUNS_URL="${RUNS_URL}?status=success&per_page=100&branch=main"

echo "  Querying: ${RUNS_URL}"

HTTP_RESPONSE=$(curl -s --retry 3 --retry-delay 2 \
  -w "\n__HTTP_STATUS__%{http_code}" \
  -H "${AUTH_HEADER}" \
  -H "${ACCEPT_HEADER}" \
  -H "${VERSION_HEADER}" \
  "${RUNS_URL}")

HTTP_BODY=$(echo "${HTTP_RESPONSE}" | sed '$d')
HTTP_CODE=$(echo "${HTTP_RESPONSE}" | tail -1 | sed 's/__HTTP_STATUS__//')

if [[ "${HTTP_CODE}" == "404" ]]; then
  echo "FAIL: Workflow file '${WORKFLOW_FILE}' not found in GitHub Actions"
  echo "      (404 from API — workflow may not exist or has never been run)"
  exit 1
fi

if [[ "${HTTP_CODE}" != "200" ]]; then
  echo "FAIL: GitHub API returned HTTP ${HTTP_CODE}"
  echo "      Response body: ${HTTP_BODY}"
  exit 1
fi

python3 - "${HTTP_BODY}" "${WORKFLOW_FILE}" "${DEADLINE}" <<'PYEOF'
import sys
import json
from datetime import datetime, timezone

raw_body      = sys.argv[1]
workflow_file = sys.argv[2]
deadline_str  = sys.argv[3]

try:
    data = json.loads(raw_body)
except json.JSONDecodeError as e:
    print(f"FAIL: Could not parse API response as JSON: {e}")
    print(f"  Raw response (first 500 chars): {raw_body[:500]}")
    sys.exit(1)

deadline = datetime.fromisoformat(deadline_str.replace("Z", "+00:00"))

runs = data.get("workflow_runs", [])
total = data.get("total_count", len(runs))
print(f"  Total runs returned by API: {total} (showing up to {len(runs)})")

qualifying = []
for run in runs:
    status     = run.get("status", "")
    conclusion = run.get("conclusion", "")
    created_at = run.get("created_at", "")

    try:
        created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
    except Exception:
        continue

    if status == "completed" and conclusion == "success" and created < deadline:
        qualifying.append({
            "id":         run.get("id"),
            "created_at": created_at,
            "html_url":   run.get("html_url", ""),
        })

if qualifying:
    best = qualifying[0]
    print(f"PASS: Found {len(qualifying)} qualifying run(s)")
    print(f"  Best run: id={best['id']} created_at={best['created_at']}")
    print(f"  URL: {best['html_url']}")
    sys.exit(0)
else:
    print("FAIL: No completed+success run found before the deadline")
    if runs:
        print(f"  Runs seen (up to 5):")
        for r in runs[:5]:
            print(f"    id={r.get('id')} status={r.get('status')} "
                  f"conclusion={r.get('conclusion')} created={r.get('created_at')}")
    else:
        print("  No runs found at all for this workflow")
    sys.exit(1)
PYEOF
