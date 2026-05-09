# `kya-mcp-server`

[Model Context Protocol](https://modelcontextprotocol.io) server for **KeepingYouAwake (Amphetamine)**. Lets MCP-aware clients (Claude Code, Claude Desktop, Cursor, Zed, …) drive KYA over stdio without leaving the chat.

## Tools

| Tool | What it does |
|------|--------------|
| `kya_activate(duration)` | Start a keep-awake session. `duration` is an integer (seconds), `"indefinite"`, or `"until_end_of_day"`. |
| `kya_deactivate()` | Stop the current session, if any. |
| `kya_toggle()` | Toggle. Equivalent to clicking the menu bar icon. |
| `kya_status()` | Returns `{active, source, fireDate, remainingSeconds}` from the activity log. |
| `kya_list_recent_sessions(limit)` | Up to N recent activate/deactivate entries (`limit` default 20). |
| `kya_set_default(key, value)` | Flip one of KYA's known user-default keys via `defaults write`. Allow-listed; arbitrary keys are rejected. |

## Install

The server is a single Python file with one external dependency (`mcp`). The recommended install is via [`uv`](https://docs.astral.sh/uv/):

```bash
uv tool install \
  "git+https://github.com/ryouka0731/KeepingYouAwake-Amphetamine.git#subdirectory=tools/mcp-server"
```

Or with stock `pip` from a clone:

```bash
git clone https://github.com/ryouka0731/KeepingYouAwake-Amphetamine.git
cd KeepingYouAwake-Amphetamine/tools/mcp-server
pip install .
```

Either gets you a `kya-mcp-server` executable on PATH.

## Wire into Claude Code

Add to `~/.claude/mcp_settings.json` (create the file if needed):

```jsonc
{
  "mcpServers": {
    "kya": {
      "command": "kya-mcp-server"
    }
  }
}
```

Restart Claude Code. You should see the 6 tools listed under the new `kya` server.

## How it talks to KYA

The server doesn't poke into KYA's internals. It drives the **already-installed KYA app** through:

- `open keepingyouawake:///activate?seconds=N` (and `/deactivate`, `/toggle`) — the URL scheme entry points the app already exposes to App Intents and `osascript`.
- The activity log JSONL at `~/Library/Application Support/KeepingYouAwake/activity.jsonl` for state queries.
- `defaults write info.marcel-dierkes.KeepingYouAwake …` for the `kya_set_default` tool.

This means:

- The server runs on the same Mac as KYA.
- It works regardless of Mac App Store vs Direct build, as long as KYA is installed.
- It does not require Accessibility, Automation, or any other macOS permission.

## Tested clients

- Claude Code 2.x — ✅
- MCP Inspector (`npx @modelcontextprotocol/inspector kya-mcp-server`) — ✅

Other stdio MCP clients should work; report any glitches in the [issues tracker](https://github.com/ryouka0731/KeepingYouAwake-Amphetamine/issues).

## License

MIT (matches the parent repo).
