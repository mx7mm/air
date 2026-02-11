# Contributing to Air

Thank you for your interest in contributing to Air!

## How to Contribute

### 1. Report Bugs
Use [GitHub Issues](../../issues) with the bug template. Include:
- What you were doing
- What happened
- What you expected to happen
- Build logs (if applicable)

### 2. Suggest Features
Open an issue with the feature template:
- What problem does it solve?
- How would it work?
- Any design thoughts?

### 3. Submit Code

**Before starting:**
1. Read the [Architecture](docs/architecture.md) to understand the system
2. Check [open issues](../../issues) - someone might be working on it
3. Open a discussion issue first for major changes

**Process:**
1. Fork the repo
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make small, atomic commits with clear messages
4. Write a clear pull request description
5. Link relevant issues
6. Wait for code review

**Code Standards:**
- Follow existing code style
- Update documentation as you go
- Test your changes (build succeeds)
- Keep commits clean and meaningful
- Update `CHANGELOG.md` in every change set

### Release/Milestone Policy

- Every change must include a `CHANGELOG.md` update (enforced in CI).
- Every larger, user-visible change must be released with a new version tag and GitHub Release.
- Use `scripts/release-current-to-github.sh --repo mx7mm/air --version vX.Y.Z` after updating version + changelog.
- Every changed file must have a matching per-file version bump in `FILE_VERSIONS.tsv`.
- Bump rules: feature `0.1.0 -> 0.2.0`, patch `0.1.0 -> 0.1.1`.
- When a milestone is closed, create/update a matching wiki page and keep it maintained.
- Use `docs/milestones/WIKI_TEMPLATE.md` as the canonical structure.

### 4. Improve Documentation
- Fix typos, clarify explanations
- Add examples to [docs/](docs/)
- Update [CHANGELOG.md](CHANGELOG.md)

## Development Setup

```bash
git clone https://github.com/mx7mm/air.git
cd air
git checkout root
./scripts/build.sh
```

## Project Structure

See [docs/architecture.md](docs/architecture.md) for system design.

Key directories:
- `docs/` – Documentation
- `configs/` – Build configuration
- `board/` – Board-specific files (bootloader, kernel, overlay)
- `scripts/` – Build scripts
- `src/` – (Future) Custom components

## Commit Messages

Use clear, descriptive messages:

```
Short summary (50 chars)

Longer explanation if needed (72 chars per line).
- Bullet points OK
- Reference issues: #123

Closes #123
```

## Code of Conduct

Be respectful, inclusive, and professional. Harassment or discrimination will not be tolerated.

## Questions?

Open an issue or check [SECURITY.md](SECURITY.md) for security concerns.

---

*We appreciate your help! Every contribution makes Air better.*
