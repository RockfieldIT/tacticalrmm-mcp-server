# Rockfield IT Services fork

Internal fork of [NightSquawk/tacticalrmm-mcp-server](https://github.com/NightSquawk/tacticalrmm-mcp-server), used unmodified (AGPL-3.0) by Rockfield technicians.

## Why a fork

- **Pinned, reviewed code.** Upstream commit `da48034` was security-reviewed on 2026-10-27: read-only (GET plus three query-only PATCH endpoints), no shell execution, no telemetry, and it talks only to the configured TacticalRMM URL.
- **Patched dependencies.** `package-lock.json` has the non-breaking `npm audit fix` applied (MCP SDK, axios/follow-redirects and others). Remaining: zod (high), which is only reachable by oversized input from the local MCP client over stdio. Accepted.
- **Reproducible installs.** Releases ship with the dependencies bundled inside (`bundleDependencies`), so every install runs the same reviewed code.

## Team install (Windows, Claude Code)

1. Ask Colm for your personal API key on `claude-readonly`.
2. In PowerShell 7, run:
   ```powershell
   irm https://raw.githubusercontent.com/RockfieldIT/tacticalrmm-mcp-server/v0.1.0-rf.1/scripts/install-rockfield.ps1 -OutFile $env:TEMP\trmm-mcp.ps1; pwsh -File $env:TEMP\trmm-mcp.ps1
   ```
3. Fully quit and reopen the Claude app.

Claude Desktop (Chat) users can instead double-click the `.mcpb` from the release and paste their key when asked.

## Updating from upstream

1. Diff upstream against the last reviewed commit and review every change.
2. Run `npm ci --ignore-scripts`, then `npm audit fix --ignore-scripts`, then `npx tsc`.
3. Cut a new `vX.Y.Z-rf.N` release with the bundled `.tgz` and the `.mcpb`.

Never point team installs at the public npm package or at `@latest`.

## Credentials

Each tech gets their own API key on the TRMM user `claude-readonly`, which has a read-only role. Keys live in the Windows user environment variable `TACTICALRMM_API_KEY`, never in a config file.
