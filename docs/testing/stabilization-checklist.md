# Stabilization Checklist (v0.2.1)

Use this list before cutting a stabilization tag/image.

## Build
- [ ] ARM64 image build succeeds
- [ ] `disk.img` is generated

## Boot
- [ ] Boot regression matrix passes (`scripts/boot-regression-matrix.sh`)

## Runtime Mounts
- [ ] Run `air-verify-mounts` inside runtime shell
- [ ] Output ends with `RESULT: PASS`

## Healthcheck
- [ ] Run `air-healthcheck --mode=runtime` inside runtime shell
- [ ] Output ends with `RESULT: PASS`

## Persistence
- [ ] Run `scripts/test-data-persistence.sh`
- [ ] Output contains `PASS: /data persistence verified across reboot`

## Session
- [ ] Kiosk launches automatically
- [ ] Debug shell only appears when explicitly enabled
