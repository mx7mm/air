#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/release-current-to-github.sh [options]

Options:
  --repo <owner/repo>       GitHub repo (default: mx7mm/air)
  --version <vX.Y.Z>        Explicit update version
  --next-patch              Bump patch from board version (vA.B.C -> vA.B.(C+1))
  --payload-dir <dir>       Payload directory (default: board/air/rootfs-overlay/etc/air)
  --work-dir <dir>          Temp/output work dir (default: /tmp/air-release-current)
  --dry-run                 Do not upload, print actions only
  -h, --help                Show help

Examples:
  scripts/release-current-to-github.sh
  scripts/release-current-to-github.sh --next-patch
  scripts/release-current-to-github.sh --repo mx7mm/air --version v0.2.0
EOF
}

REPO="mx7mm/air"
VERSION=""
NEXT_PATCH=0
PAYLOAD_DIR="board/air/rootfs-overlay/etc/air"
WORK_DIR="/tmp/air-release-current"
DRY_RUN=0
VERSION_FILE="board/air/rootfs-overlay/etc/air/VERSION"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --next-patch)
      NEXT_PATCH=1
      shift 1
      ;;
    --payload-dir)
      PAYLOAD_DIR="${2:-}"
      shift 2
      ;;
    --work-dir)
      WORK_DIR="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift 1
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

[[ -n "$REPO" ]] || { echo "missing --repo" >&2; exit 1; }
[[ -d "$PAYLOAD_DIR" ]] || { echo "payload dir not found: $PAYLOAD_DIR" >&2; exit 1; }
[[ -f "$VERSION_FILE" ]] || { echo "version file not found: $VERSION_FILE" >&2; exit 1; }

base_version="$(head -n 1 "$VERSION_FILE" | tr -d '\r\n')"

if [[ -n "$VERSION" && "$NEXT_PATCH" -eq 1 ]]; then
  echo "Use either --version or --next-patch, not both." >&2
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  if [[ "$NEXT_PATCH" -eq 1 ]]; then
    sem="${base_version#v}"
    major="${sem%%.*}"
    rest="${sem#*.}"
    minor="${rest%%.*}"
    patch="${rest#*.}"
    [[ "$major$minor$patch" =~ ^[0-9]+$ ]] || {
      echo "cannot bump non-semver version: $base_version" >&2
      exit 1
    }
    VERSION="v${major}.${minor}.$((patch + 1))"
  else
    VERSION="$base_version"
  fi
fi

mkdir -p "$WORK_DIR"
package_path="$WORK_DIR/air-update-${VERSION}.tar"

echo "Preparing release:"
echo "  repo=$REPO"
echo "  version=$VERSION"
echo "  payload_dir=$PAYLOAD_DIR"
echo "  package=$package_path"

scripts/make-update-package.sh \
  --version "$VERSION" \
  --payload-dir "$PAYLOAD_DIR" \
  --output "$package_path"

publish_args=(
  --repo "$REPO"
  --package "$package_path"
  --version-tag "$VERSION"
  --channel-tag "air-channel"
  --channel-asset "latest.json"
)

if [[ "$DRY_RUN" -eq 1 ]]; then
  publish_args+=(--dry-run)
fi

scripts/publish-update-github.sh "${publish_args[@]}"

echo "Done."
echo "Set devices to:"
echo "  AIR_UPDATE_MANIFEST_URL=https://github.com/${REPO}/releases/download/air-channel/latest.json"
