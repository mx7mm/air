#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/make-update-package.sh \
    --version <semver> \
    --payload-dir <dir> \
    --output <air-update-<version>.tar>
EOF
}

VERSION=""
PAYLOAD_DIR=""
OUTPUT_PATH=""
FORMAT_VERSION="air-update-1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --payload-dir)
      PAYLOAD_DIR="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="${2:-}"
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
[[ -n "$PAYLOAD_DIR" ]] || { echo "missing --payload-dir" >&2; exit 1; }
[[ -n "$OUTPUT_PATH" ]] || { echo "missing --output" >&2; exit 1; }
[[ -d "$PAYLOAD_DIR" ]] || { echo "payload dir not found: $PAYLOAD_DIR" >&2; exit 1; }

command -v tar >/dev/null 2>&1 || { echo "tar not found" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum not found" >&2; exit 1; }

workdir="$(mktemp -d /tmp/air-update-build.XXXXXX)"
trap 'rm -rf "$workdir"' EXIT INT TERM

payload_tar="$workdir/payload.tar"
manifest_json="$workdir/manifest.json"
manifest_sha="$workdir/manifest.sha256"
payload_sha_file="$workdir/payload.sha256"
built_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

tar -cf "$payload_tar" -C "$PAYLOAD_DIR" .
payload_sha="$(sha256sum "$payload_tar" | awk '{print $1}')"

cat > "$manifest_json" <<EOF
{
  "format_version": "$FORMAT_VERSION",
  "package_version": "$VERSION",
  "built_at": "$built_at",
  "payload_file": "payload.tar",
  "payload_sha256": "$payload_sha",
  "notes": "Local Air update package"
}
EOF

sha256sum "$manifest_json" > "$manifest_sha"
sha256sum "$payload_tar" > "$payload_sha_file"

mkdir -p "$(dirname "$OUTPUT_PATH")"
tar -cf "$OUTPUT_PATH" \
  -C "$workdir" \
  manifest.json \
  manifest.sha256 \
  payload.tar \
  payload.sha256

echo "OK: update package generated"
echo "output=$OUTPUT_PATH"
echo "version=$VERSION"
echo "payload_sha256=$payload_sha"
