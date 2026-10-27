# Rockfield IT Services fork

Internal fork of [NightSquawk/tacticalrmm-mcp-server](https://github.com/NightSquawk/tacticalrmm-mcp-server), used unmodified (AGPL-3.0) by Rockfield technicians.

## Why a fork

- **Pinned, reviewed code.** Upstream commit `da48034` was security-reviewed on 2026-10-27: read-only (GET plus three query-only PATCH endpoints), no shell execution, no telemetry, and it talks only to the configured TacticalRMM URL.
- **Patched dependencies.** `package-lock.json` has the non-breaking `npm audit fix` applied (MCP SDK, axios/follow-redirects and others). Remaining: zod (high), which is only reachable by oversized input from the local MCP client over stdio. Accepted.
- **Reproducible installs.** Releases ship with the dependencies bundled inside (`bundleDependencies`), so every install runs the same reviewed code.

## Updating from upstream

1. Diff upstream against the last reviewed commit and review every change.
2. Run `npm ci --ignore-scripts`, then `npm audit fix --ignore-scripts`, then `npx tsc`.
3. Cut a new `vX.Y.Z-rf.N` release with the bundled `.tgz` and the `.mcpb`.

Never point team installs at the public npm package or at `@latest`.

## Credentials

Each tech gets their own API key on the TRMM user `claude-readonly`, which has a read-only role. Keys live in the Windows user environment variable `TACTICALRMM_API_KEY`, never in a config file.
