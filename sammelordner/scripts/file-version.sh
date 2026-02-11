#!/usr/bin/env bash
set -euo pipefail

MANIFEST="${FILE_VERSIONS_MANIFEST:-FILE_VERSIONS.tsv}"
DEFAULT_VERSION="${FILE_VERSIONS_DEFAULT:-0.1.0}"

usage() {
  cat <<'EOF'
Usage:
  scripts/file-version.sh init [--default <x.y.z>]
  scripts/file-version.sh bump --type <feature|patch> <file> [file...]
  scripts/file-version.sh show <file>

Rules:
  - feature bump: x.y.z -> x.(y+1).0
  - patch bump:   x.y.z -> x.y.(z+1)
  - new files start at 0.1.0
EOF
}

is_semver() {
  [[ "${1:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

get_version() {
  local path="$1"
  awk -F '\t' -v path="$path" '$1==path { print $2 }' "$MANIFEST"
}

set_version() {
  local path="$1"
  local version="$2"
  local tmp
  tmp="$(mktemp)"
  awk -F '\t' -v OFS='\t' -v path="$path" -v ver="$version" '
    BEGIN { found=0 }
    $1==path { print $1, ver; found=1; next }
    { print $0 }
    END { if (!found) print path, ver }
  ' "$MANIFEST" | sort > "$tmp"
  mv "$tmp" "$MANIFEST"
}

bump_feature() {
  local version="$1"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"
  echo "${major}.$((minor + 1)).0"
}

bump_patch() {
  local version="$1"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"
  echo "${major}.${minor}.$((patch + 1))"
}

cmd_init() {
  local default="$DEFAULT_VERSION"
  if [[ "${1:-}" == "--default" ]]; then
    default="${2:-}"
    shift 2
  fi
  [[ $# -eq 0 ]] || { usage; exit 1; }
  is_semver "$default" || { echo "invalid default version: $default" >&2; exit 1; }

  git ls-files | sort | awk -v OFS='\t' -v ver="$default" '{ print $0, ver }' > "$MANIFEST"
  echo "initialized: $MANIFEST (default=$default)"
}

cmd_bump() {
  local type=""
  if [[ "${1:-}" == "--type" ]]; then
    type="${2:-}"
    shift 2
  fi
  [[ "$type" == "feature" || "$type" == "patch" ]] || {
    echo "missing or invalid --type <feature|patch>" >&2
    exit 1
  }
  [[ $# -gt 0 ]] || { echo "no files provided" >&2; exit 1; }
  [[ -f "$MANIFEST" ]] || { echo "manifest not found: $MANIFEST" >&2; exit 1; }

  local path current next
  for path in "$@"; do
    current="$(get_version "$path" || true)"
    if [[ -z "$current" ]]; then
      set_version "$path" "$DEFAULT_VERSION"
      echo "$path: $DEFAULT_VERSION (new)"
      continue
    fi
    is_semver "$current" || { echo "invalid semver for $path: $current" >&2; exit 1; }
    if [[ "$type" == "feature" ]]; then
      next="$(bump_feature "$current")"
    else
      next="$(bump_patch "$current")"
    fi
    set_version "$path" "$next"
    echo "$path: $current -> $next"
  done
}

cmd_show() {
  local path="${1:-}"
  [[ -n "$path" ]] || { echo "missing file path" >&2; exit 1; }
  [[ -f "$MANIFEST" ]] || { echo "manifest not found: $MANIFEST" >&2; exit 1; }
  local version
  version="$(get_version "$path" || true)"
  if [[ -z "$version" ]]; then
    echo "$path: not tracked"
    exit 1
  fi
  echo "$path: $version"
}

case "${1:-}" in
  init)
    shift
    cmd_init "$@"
    ;;
  bump)
    shift
    cmd_bump "$@"
    ;;
  show)
    shift
    cmd_show "$@"
    ;;
  *)
    usage
    exit 1
    ;;
esac
