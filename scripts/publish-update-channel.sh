#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/publish-update-channel.sh \
    --package <air-update-<version>.tar> \
    --channel-dir <dir> \
    [--base-url <http(s)://... or file:///...>]
EOF
}

PACKAGE_PATH=""
CHANNEL_DIR=""
BASE_URL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package)
      PACKAGE_PATH="${2:-}"
      shift 2
      ;;
    --channel-dir)
      CHANNEL_DIR="${2:-}"
      shift 2
      ;;
    --base-url)
      BASE_URL="${2:-}"
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

[[ -n "$PACKAGE_PATH" ]] || { echo "missing --package" >&2; exit 1; }
[[ -n "$CHANNEL_DIR" ]] || { echo "missing --channel-dir" >&2; exit 1; }
[[ -f "$PACKAGE_PATH" ]] || { echo "package not found: $PACKAGE_PATH" >&2; exit 1; }

command -v tar >/dev/null 2>&1 || { echo "tar not found" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum not found" >&2; exit 1; }

workdir="$(mktemp -d /tmp/air-channel.XXXXXX)"
trap 'rm -rf "$workdir"' EXIT INT TERM

tar -xf "$PACKAGE_PATH" -C "$workdir"
manifest_json="$workdir/manifest.json"
[[ -f "$manifest_json" ]] || { echo "manifest.json not found in package" >&2; exit 1; }

package_version="$(sed -n 's/.*"package_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest_json" | head -n 1)"
[[ -n "$package_version" ]] || { echo "package_version missing in manifest" >&2; exit 1; }

mkdir -p "$CHANNEL_DIR/packages"
target_pkg="$CHANNEL_DIR/packages/air-update-${package_version}.tar"
cp "$PACKAGE_PATH" "$target_pkg"
package_sha="$(sha256sum "$target_pkg" | awk '{print $1}')"

if [[ -n "$BASE_URL" ]]; then
  package_url="${BASE_URL%/}/packages/air-update-${package_version}.tar"
else
  package_url="file://$target_pkg"
fi

cat > "$CHANNEL_DIR/latest.json" <<EOF
{
  "format_version": "air-channel-1",
  "package_version": "$package_version",
  "package_url": "$package_url",
  "package_sha256": "$package_sha"
}
EOF

echo "OK: channel published"
echo "channel_latest=$CHANNEL_DIR/latest.json"
echo "package=$target_pkg"
echo "package_version=$package_version"
