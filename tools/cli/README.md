# `kya` — command-line driver

Tiny CLI for **KeepingYouAwake (Amphetamine)** — drive activate / deactivate / status from the terminal, shell scripts, cron jobs, or any other place a one-shot command is more natural than clicking the menu bar icon.

## Examples

```bash
$ kya activate 30m
$ kya activate 2h
$ kya activate                # indefinite
$ kya activate --until-end-of-day
$ kya deactivate
$ kya toggle
$ kya status
active (source=user) remaining=0:29:54
$ kya status --json
{"active": true, "source": "user", "startedAt": "...", "requestedDuration": 1800, "fireDate": "...", "remainingSeconds": 1794.7}
```

`kya status` exits **0** when active, **1** when inactive — handy for shell `if` checks.

## Install

Recommended: [`uv`](https://docs.astral.sh/uv/):

```bash
uv tool install \
  "git+https://github.com/ryouka0731/KeepingYouAwake-Amphetamine.git#subdirectory=tools/cli"
```

Or with stock `pip` from a clone:

```bash
git clone https://github.com/ryouka0731/KeepingYouAwake-Amphetamine.git
cd KeepingYouAwake-Amphetamine/tools/cli
pip install .
```

Either gets you a `kya` executable on PATH. No external Python deps; just the standard library.

## How it talks to KYA

Same playbook as `kya-mcp-server`:

- Activate / deactivate / toggle via the running app's URL scheme (`open keepingyouawake:///…`).
- Status reads `~/Library/Application Support/KeepingYouAwake/activity.jsonl` (the activity log).

KYA must be installed; the URL scheme launches it on demand if it isn't running.

## Duration grammar

| Input | Seconds |
|-------|---------|
| `30s` | 30 |
| `30m` | 1800 |
| `2h` | 7200 |
| `1h30m` | 5400 |
| `90` | 90 (bare integers are seconds) |
| (omitted) | indefinite (no fireDate) |
| `--until-end-of-day` | seconds until next local midnight |

## License

MIT (matches the parent repo).
