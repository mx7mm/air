#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/publish-update-github.sh \
    --repo <owner/repo> \
    --package <air-update-<version>.tar> \
    [--version-tag <tag>] \
    [--channel-tag <tag>] \
    [--channel-asset <filename>] \
    [--dry-run]

Example:
  scripts/publish-update-github.sh \
    --repo mx7mm/air \
    --package ./air-update-v0.4.1.tar
EOF
}

REPO=""
PACKAGE_PATH=""
VERSION_TAG=""
CHANNEL_TAG="air-channel"
CHANNEL_ASSET="latest.json"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --package)
      PACKAGE_PATH="${2:-}"
      shift 2
      ;;
    --version-tag)
      VERSION_TAG="${2:-}"
      shift 2
      ;;
    --channel-tag)
      CHANNEL_TAG="${2:-}"
      shift 2
      ;;
    --channel-asset)
      CHANNEL_ASSET="${2:-}"
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
[[ -n "$PACKAGE_PATH" ]] || { echo "missing --package" >&2; exit 1; }
[[ -f "$PACKAGE_PATH" ]] || { echo "package not found: $PACKAGE_PATH" >&2; exit 1; }

command -v tar >/dev/null 2>&1 || { echo "tar not found" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum not found" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "gh not found" >&2; exit 1; }

workdir="$(mktemp -d /tmp/air-github-publish.XXXXXX)"
trap 'rm -rf "$workdir"' EXIT INT TERM

tar -xf "$PACKAGE_PATH" -C "$workdir"
manifest_json="$workdir/manifest.json"
[[ -f "$manifest_json" ]] || { echo "manifest.json not found in package" >&2; exit 1; }

package_version="$(sed -n 's/.*"package_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest_json" | head -n 1)"
[[ -n "$package_version" ]] || { echo "package_version missing in manifest" >&2; exit 1; }

if [[ -z "$VERSION_TAG" ]]; then
  VERSION_TAG="$package_version"
fi

asset_name="air-update-${package_version}.tar"
asset_path="$workdir/$asset_name"
cp "$PACKAGE_PATH" "$asset_path"
package_sha="$(sha256sum "$asset_path" | awk '{print $1}')"
package_url="https://github.com/${REPO}/releases/download/${VERSION_TAG}/${asset_name}"

latest_json="$workdir/$CHANNEL_ASSET"
cat > "$latest_json" <<EOF
{
  "format_version": "air-channel-1",
  "package_version": "$package_version",
  "package_url": "$package_url",
  "package_sha256": "$package_sha"
}
EOF

ensure_release() {
  local tag="$1"
  local title="$2"
  local notes="$3"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] ensure release tag=$tag"
    return 0
  fi
  if gh release view "$tag" --repo "$REPO" >/dev/null 2>&1; then
    return 0
  fi
  gh release create "$tag" --repo "$REPO" --title "$title" --notes "$notes"
}

upload_asset() {
  local tag="$1"
  local file="$2"
  local label="$3"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] upload asset to $tag: $file as $label"
    return 0
  fi
  gh release upload "$tag" --repo "$REPO" "$file#$label" --clobber
}

ensure_release "$VERSION_TAG" "Air ${package_version}" "Automated update package release."
upload_asset "$VERSION_TAG" "$asset_path" "$asset_name"

ensure_release "$CHANNEL_TAG" "Air Update Channel" "Mutable channel manifest used by devices."
upload_asset "$CHANNEL_TAG" "$latest_json" "$CHANNEL_ASSET"

channel_url="https://github.com/${REPO}/releases/download/${CHANNEL_TAG}/${CHANNEL_ASSET}"

echo "OK: GitHub update channel published"
echo "repo=$REPO"
echo "package_version=$package_version"
echo "version_tag=$VERSION_TAG"
echo "package_asset_url=$package_url"
echo "channel_tag=$CHANNEL_TAG"
echo "channel_manifest_url=$channel_url"
echo "package_sha256=$package_sha"
