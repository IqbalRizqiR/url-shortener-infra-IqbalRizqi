#!/usr/bin/env bash
set -euo pipefail

REQUIRED_SECRETS=(
  "AWS_ACCESS_KEY_ID"
  "AWS_SECRET_ACCESS_KEY"
  "AWS_SESSION_TOKEN"
  "AWS_REGION"
  "DB_PASSWORD"
  "AWS_ACCOUNT_ID"
)

WORKFLOW_FILES=(
  ".github/workflows/deploy.yml"
)

PASS=true

echo "=== Part A: Checking secret references in workflow files ==="

for wf in "${WORKFLOW_FILES[@]}"; do
  if [[ ! -f "${wf}" ]]; then
    echo "FAIL [Part A]: File not found: ${wf}"
    PASS=false
    continue
  fi

  echo "  Checking ${wf}..."
  for secret in "${REQUIRED_SECRETS[@]}"; do
    if grep -q "${secret}" "${wf}"; then
      echo "    PASS: ${secret} referenced"
    else
      echo "    FAIL: ${secret} NOT referenced in ${wf}"
      PASS=false
    fi
  done
done

echo ""
echo "=== Part B: Checking secrets exist in repo via GitHub API (diagnostic only) ==="

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "  NOTE [Part B]: GITHUB_TOKEN is not set — skipping API check (not graded)"
else
  REPO="${GITHUB_REPOSITORY}"
  API_BASE="https://api.github.com"
  AUTH_HEADER="Authorization: Bearer ${GITHUB_TOKEN}"
  ACCEPT_HEADER="Accept: application/vnd.github+json"
  VERSION_HEADER="X-GitHub-Api-Version: 2022-11-28"

  echo "  Fetching repo-level secrets for ${REPO}..."
  REPO_SECRETS_JSON=$(curl -sf --retry 3 --retry-delay 2 \
    -H "${AUTH_HEADER}" \
    -H "${ACCEPT_HEADER}" \
    -H "${VERSION_HEADER}" \
    "${API_BASE}/repos/${REPO}/actions/secrets?per_page=100" 2>&1) || {
    echo "  NOTE [Part B]: API call for repo secrets returned an error (not graded)"
    echo "  Response: ${REPO_SECRETS_JSON}"
    REPO_SECRETS_JSON='{"secrets":[]}'
  }

  echo "  Fetching organization secrets visible to ${REPO}..."
  ORG_SECRETS_JSON=$(curl -sf --retry 3 --retry-delay 2 \
    -H "${AUTH_HEADER}" \
    -H "${ACCEPT_HEADER}" \
    -H "${VERSION_HEADER}" \
    "${API_BASE}/repos/${REPO}/actions/organization-secrets?per_page=100" 2>&1) || {
    echo "  NOTE: Could not fetch org secrets (may not be org repo). Continuing with repo secrets only."
    ORG_SECRETS_JSON='{"secrets":[]}'
  }

  ALL_SECRET_NAMES=$(
    python3 - "${REPO_SECRETS_JSON}" "${ORG_SECRETS_JSON}" <<'PYEOF'
import sys
import json

repo_data = json.loads(sys.argv[1])
org_data  = json.loads(sys.argv[2])

names = set()
for s in repo_data.get("secrets", []):
    names.add(s["name"])
for s in org_data.get("secrets", []):
    names.add(s["name"])

print("\n".join(sorted(names)))
PYEOF
  )

  echo "  Secrets found in repo/org: $(echo "${ALL_SECRET_NAMES}" | tr '\n' ' ')"

  for secret in "${REQUIRED_SECRETS[@]}"; do
    if echo "${ALL_SECRET_NAMES}" | grep -qx "${secret}"; then
      echo "  INFO: ${secret} is set (confirmed via API)"
    else
      echo "  WARN: ${secret} not found via API (may be a token permission limitation — not graded)"
    fi
  done
fi

echo ""
if [[ "${PASS}" == "true" ]]; then
  echo "ALL SECRETS CHECKS PASSED (graded on Part A only)"
  exit 0
else
  echo "SECRETS CHECK FAILED — Part A (secret references in deploy.yml) must fully pass"
  exit 1
fi
