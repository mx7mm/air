#!/usr/bin/env bash
set -euo pipefail

manifest="FILE_VERSIONS.tsv"
base_sha="${BASE_SHA:-}"

if [[ -z "$base_sha" ]]; then
  echo "No BASE_SHA provided, skipping file-version check."
  exit 0
fi

if [[ "$base_sha" == "0000000000000000000000000000000000000000" ]]; then
  echo "Initial push detected, skipping file-version check."
  exit 0
fi

if [[ ! -f "$manifest" ]]; then
  echo "Policy violation: missing $manifest"
  exit 1
fi

tmp_old="$(mktemp)"
trap 'rm -f "$tmp_old"' EXIT INT TERM

if ! git show "$base_sha:$manifest" > "$tmp_old" 2>/dev/null; then
  echo "No previous $manifest found at base; skipping bump validation."
  exit 0
fi

is_semver() {
  [[ "${1:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

lookup_version() {
  local file="$1"
  local src="$2"
  awk -F '\t' -v file="$file" '$1==file { print $2 }' "$src"
}

check_patch_bump() {
  local old="$1" new="$2"
  local o_major o_minor o_patch n_major n_minor n_patch
  IFS='.' read -r o_major o_minor o_patch <<< "$old"
  IFS='.' read -r n_major n_minor n_patch <<< "$new"
  [[ "$o_major" == "$n_major" ]] || return 1
  [[ "$o_minor" == "$n_minor" ]] || return 1
  [[ "$n_patch" -eq $((o_patch + 1)) ]] || return 1
}

check_feature_bump() {
  local old="$1" new="$2"
  local o_major o_minor o_patch n_major n_minor n_patch
  IFS='.' read -r o_major o_minor o_patch <<< "$old"
  IFS='.' read -r n_major n_minor n_patch <<< "$new"
  [[ "$o_major" == "$n_major" ]] || return 1
  [[ "$n_minor" -eq $((o_minor + 1)) ]] || return 1
  [[ "$n_patch" -eq 0 ]] || return 1
}

mode="patch"
if git log --format=%s "$base_sha..HEAD" | rg -q '^feat(\(|:|!)'; then
  mode="feature"
fi
echo "File version check mode: $mode"

errors=0

# Enforce every tracked file has a version entry (except manifest itself).
while IFS= read -r tracked; do
  [[ "$tracked" == "$manifest" ]] && continue
  current="$(lookup_version "$tracked" "$manifest")"
  if [[ -z "$current" ]]; then
    echo "Policy violation: missing version entry for tracked file: $tracked"
    errors=1
  fi
done < <(git ls-files)

while IFS=$'\t' read -r status p1 p2; do
  case "$status" in
    M|A|D)
      path="$p1"
      ;;
    R*|C*)
      # Handle rename/copy as delete+add semantics.
      old_path="$p1"
      new_path="$p2"

      [[ "$old_path" == "$manifest" ]] || {
        if [[ -n "$(lookup_version "$old_path" "$manifest")" ]]; then
          echo "Policy violation: renamed source still tracked in $manifest: $old_path"
          errors=1
        fi
      }
      path="$new_path"
      status="A"
      ;;
    *)
      continue
      ;;
  esac

  [[ "$path" == "$manifest" ]] && continue

  old_ver="$(lookup_version "$path" "$tmp_old")"
  new_ver="$(lookup_version "$path" "$manifest")"

  if [[ "$status" == "D" ]]; then
    if [[ -n "$new_ver" ]]; then
      echo "Policy violation: deleted file still tracked in $manifest: $path"
      errors=1
    fi
    continue
  fi

  if [[ "$status" == "A" ]]; then
    if [[ -z "$new_ver" ]]; then
      echo "Policy violation: new file missing version entry: $path"
      errors=1
      continue
    fi
    if [[ "$new_ver" != "0.1.0" ]]; then
      echo "Policy violation: new file must start at 0.1.0: $path ($new_ver)"
      errors=1
    fi
    continue
  fi

  if [[ -z "$old_ver" || -z "$new_ver" ]]; then
    echo "Policy violation: missing version bump entry for modified file: $path"
    errors=1
    continue
  fi

  if ! is_semver "$old_ver" || ! is_semver "$new_ver"; then
    echo "Policy violation: invalid semver for $path (old=$old_ver new=$new_ver)"
    errors=1
    continue
  fi

  if [[ "$mode" == "feature" ]]; then
    if ! check_feature_bump "$old_ver" "$new_ver"; then
      echo "Policy violation: feature bump expected for $path ($old_ver -> $new_ver)"
      errors=1
    fi
  else
    if ! check_patch_bump "$old_ver" "$new_ver"; then
      echo "Policy violation: patch bump expected for $path ($old_ver -> $new_ver)"
      errors=1
    fi
  fi
done < <(git diff --name-status "$base_sha...HEAD")

if [[ "$errors" -ne 0 ]]; then
  exit 1
fi

echo "File version policy check passed."
