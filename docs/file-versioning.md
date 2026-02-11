# File Versioning Rule

Every file in the repository gets its own version tag in:

`FILE_VERSIONS.tsv`

Format:

`<path>\t<major.minor.patch>`

## Bump Rules

- Feature added:
  - increase minor, reset patch
  - example: `0.1.0 -> 0.2.0`
- Patch/fix:
  - increase patch only
  - example: `0.1.0 -> 0.1.1`

New files start with:

- `0.1.0`

## Commands

Initialize manifest:

```bash
scripts/file-version.sh init
```

Bump files for a feature change:

```bash
scripts/file-version.sh bump --type feature path/to/file1 path/to/file2
```

Bump files for a patch:

```bash
scripts/file-version.sh bump --type patch path/to/file1 path/to/file2
```

Show a file version:

```bash
scripts/file-version.sh show path/to/file
```

## CI Enforcement

Policy workflow enforces:

- all tracked files (except `FILE_VERSIONS.tsv`) must have an entry
- modified files must be bumped correctly
- new files must start at `0.1.0`
- deleted files must be removed from the manifest

Mode selection in CI:

- if commits include `feat(...)` / `feat: ...` -> feature bump expected
- otherwise patch bump expected
