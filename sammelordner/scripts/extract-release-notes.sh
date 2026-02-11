#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/extract-release-notes.sh --version <vX.Y.Z> [--changelog <path>]

Extracts the matching section from CHANGELOG.md and prints Markdown notes.
EOF
}

VERSION=""
CHANGELOG="CHANGELOG.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --changelog)
      CHANGELOG="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 1
      ;;
  esac
done

[[ -n "$VERSION" ]] || { echo "missing --version" >&2; exit 1; }
[[ -f "$CHANGELOG" ]] || { echo "changelog not found: $CHANGELOG" >&2; exit 1; }

bare="${VERSION#v}"

awk -v version="$VERSION" -v bare="$bare" '
BEGIN {
  in_section = 0
  found = 0
}
{
  if ($0 ~ "^## \\[" bare "\\]" || $0 ~ "^## \\[" version "\\]") {
    in_section = 1
    found = 1
    next
  }
  if (in_section == 1 && $0 ~ "^## \\[") {
    exit
  }
  if (in_section == 1) {
    print $0
  }
}
END {
  if (found == 0) {
    exit 2
  }
}
' "$CHANGELOG" | sed '/^[[:space:]]*$/N;/^\n$/D'

status=${PIPESTATUS[0]}
if [[ "$status" -eq 2 ]]; then
  echo "version section not found in $CHANGELOG: $VERSION" >&2
  exit 1
fi

