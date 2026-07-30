# docker-rmlint

Minimal Docker image for running `rmlint` with low I/O priority by default.

## What this image does

- Installs `rmlint` on `debian:bookworm-slim`
- Runs `rmlint` through `ionice`
- Defaults to idle I/O class (`IONICE_CLASS=3`) to reduce disk churn

## Build

```bash
docker build -t rmlint .
```

## Run

### PowerShell (Windows)

```powershell
docker run --rm -v ${PWD}:/work rmlint /work --xattr
```

### Bash / Zsh (Linux, macOS)

```bash
docker run --rm -v "$PWD":/work rmlint /work --xattr
```

## Background scan with report output

Use built-in `scan` mode to write timestamped duplicate reports into a specific folder.

Generated files:

- `*.json` machine-readable duplicate report
- `*.txt` summary report
- `*.sh` removal script (review before use)

### PowerShell (detached)

```powershell
docker run -d --name rmlint-scan `
	-v ${PWD}\target:/work `
	-v ${PWD}\reports:/reports `
	-e REPORT_DIR=/reports `
	-e REPORT_NAME=duplicates `
	rmlint scan /work --xattr
```

### Bash / Zsh (detached)

```bash
docker run -d --name rmlint-scan \
	-v "$PWD/target":/work \
	-v "$PWD/reports":/reports \
	-e REPORT_DIR=/reports \
	-e REPORT_NAME=duplicates \
	rmlint scan /work --xattr
```

Check progress and collect logs:

```bash
docker logs -f rmlint-scan
docker wait rmlint-scan
docker rm rmlint-scan
```

Optional report settings:

- `REPORT_DIR` default `/reports`
- `REPORT_NAME` default `duplicates-report`
- `REPORT_TIMESTAMP` default `1` (set `0` to overwrite stable filenames)

## ionice tuning

The container entrypoint reads two optional environment variables:

- `IONICE_CLASS` (default: `3`)
- `IONICE_LEVEL` (default: `7`, used by class `1` and `2`)

Examples:

```bash
# Best-effort, lowest priority in class
docker run --rm -e IONICE_CLASS=2 -e IONICE_LEVEL=7 -v "$PWD":/work rmlint /work --xattr

# Best-effort, slightly more aggressive
docker run --rm -e IONICE_CLASS=2 -e IONICE_LEVEL=4 -v "$PWD":/work rmlint /work --xattr
```

## Safe first scan for large datasets

Start with reporting-only output and no deletion script:

```bash
docker run --rm -v "$PWD":/work rmlint /work --xattr -o summary -o pretty
```

After reviewing results, generate a removal script (still review before running):

```bash
docker run --rm -v "$PWD":/work rmlint /work --xattr -o sh:stdout > cleanup.sh
```

## Notes for ZFS xattrs

- Ensure the target dataset allows extended attributes.
- Ensure permissions allow writing xattrs on target files.
- If needed, run the container with your host UID/GID.
