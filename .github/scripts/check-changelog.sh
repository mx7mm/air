#!/usr/bin/env bash
set -euo pipefail

if [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
  base_sha="${BASE_SHA:-${GITHUB_BASE_SHA:-}}"
elif [[ "${GITHUB_EVENT_NAME:-}" == "push" ]]; then
  base_sha="${BASE_SHA:-${GITHUB_BEFORE_SHA:-}}"
else
  echo "Unsupported event: ${GITHUB_EVENT_NAME:-unknown}"
  exit 0
fi

if [[ -z "${base_sha:-}" ]]; then
  echo "No base SHA available, skipping changelog check."
  exit 0
fi

if [[ "$base_sha" == "0000000000000000000000000000000000000000" ]]; then
  echo "Initial push detected, skipping changelog check."
  exit 0
fi

changed_files="$(git diff --name-only "$base_sha"...HEAD)"
if [[ -z "$changed_files" ]]; then
  echo "No file changes detected."
  exit 0
fi

if echo "$changed_files" | rg -qx "CHANGELOG.md"; then
  echo "Only CHANGELOG.md changed."
  exit 0
fi

if echo "$changed_files" | rg -q "^CHANGELOG\.md$"; then
  echo "CHANGELOG.md updated."
  exit 0
fi

echo "Policy violation: CHANGELOG.md must be updated for every change."
echo "Changed files:"
echo "$changed_files"
exit 1
