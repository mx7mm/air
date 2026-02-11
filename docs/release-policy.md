# Release Policy

Air uses a simple release rule:

- Every larger, user-visible change gets a new versioned release.
- Every release must be documented in `CHANGELOG.md`.
- Release notes must summarize what changed in clear, practical language.
- Every changed file must be version-bumped in `FILE_VERSIONS.tsv`.

Per-file bump rules:

- feature: `0.1.0 -> 0.2.0`
- patch: `0.1.0 -> 0.1.1`

## Definition: "larger change"

A change is considered larger when at least one applies:

- Boot behavior changes.
- Runtime flags or default behavior changes.
- Update path, install path, or compatibility changes.
- New user-visible features are added.
- Existing features are removed or replaced.

## Standard release flow

1. Update `CHANGELOG.md` with a new version section.
2. Update `board/air/rootfs-overlay/etc/air/VERSION`.
3. Run:

```bash
scripts/release-current-to-github.sh --repo mx7mm/air --version vX.Y.Z
```

This flow publishes:

- Versioned GitHub release/tag (`vX.Y.Z`)
- Update package asset (`air-update-vX.Y.Z.tar`)
- Channel manifest in `air-channel/latest.json`

## Automatic release on version change

GitHub Actions also publishes automatically when
`board/air/rootfs-overlay/etc/air/VERSION` changes.

Workflow:

- `.github/workflows/release-on-version-change.yml`

It will:

- read the current version from `VERSION`
- verify matching release notes exist in `CHANGELOG.md`
- build update package
- create/update version release
- update channel manifest (`air-channel/latest.json`)

## Notes quality

Release notes should include:

- What changed (added/changed/fixed)
- Why it matters for users/operators
- Any migration or compatibility notes
