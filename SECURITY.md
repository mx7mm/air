# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in Air, please **do not** open a public GitHub issue.

Instead, please email: **security@example.com**

**Include:**
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if available)

We will acknowledge receipt within 48 hours and provide status updates every 5 days.

## Security Considerations for Phase 1

Air is in **early development** with a minimal security posture. Phase 1 focuses on bootability, not security hardening.

**Known limitations:**
- No secure boot (EFI signatures not verified)
- Root password empty
- No firewall/SELinux/AppArmor
- SSH not enabled (network access deferred to Phase 2)

Security hardening will be prioritized in later phases.

## Dependencies

Air uses:
- Linux kernel (regular security updates available)
- musl libc (actively maintained)
- Busybox (monitor security advisories)

See [CHANGELOG.md](CHANGELOG.md) for version tracking.
