---
name: zorron-elysia-commands
description: "Project-local command guide for the Zorron ElysiaJS workspace. Use when Codex needs to start, stop, inspect, test, build, lint, or operate this repository's ElysiaJS/Vite multi-service app, including API Gateway, Leader Worker, OpenCode workers, Vue Dashboard, CLI smoke checks, and service ports. DO NOT invoke for other unrelated tasks."
allowed-tools: Bash
version: 1.0.0
---

# Zorron ElysiaJS Commands


## When to invoke
- When the task requires: Project-local command guide for the Zorron ElysiaJS workspace.
- When executing workflows related to zorron-elysia-commands.
- **DO NOT invoke when**: The request is unrelated to zorron-elysia-commands.

## Project Layout

Treat `zorron-nest/` as the package root. Run package commands from:

```bash
cd ~/Documents/zorronAgents/zorron-agents/zorron-nest
```

The outer `zorron-agents/` directory is the workspace container. The useful app files live under `zorron-nest/apps`, `zorron-nest/libs`, `zorron-nest/scripts`, and `zorron-nest/docs`.

## Architecture

The project has been migrated from NestJS to **ElysiaJS** (Bun-first TypeScript framework). Key changes:

- **Controllers** → ElysiaJS route plugins (`new Elysia({ prefix }).get().post()`)
- **Modules** → ElysiaJS plugin composition (`.use(plugin)`)
- **Guards** → ElysiaJS `onBeforeHandle` lifecycle hooks
- **Middleware** → ElysiaJS `onRequest`/`onAfterHandle` lifecycle hooks
- **WebSocket Gateway** → ElysiaJS native `.ws()` (Bun WebSocket)
- **DI (Dependency Injection)** → Direct service instantiation with `getDataSource()`
- **Validation** → ElysiaJS TypeBox schemas (`t.Object()`, `t.String()`, etc.)

## Package Manager

Use `bun` for all project operations. If dependencies are missing, run:

```bash
bun install
```

The UI app under `apps/zorron-ui` also uses `bun`, but normal full-stack startup should be run from the package root.

## Development Startup

Use the orchestrator first:

```bash
bun dev
bun dev:start
```

Both commands run `scripts/dev.ts start`. The orchestrator reads `startup.config.json`, starts enabled services, records PIDs in `.pids/`, and performs port health checks.

Default enabled services:

| Service ID | Service | Type | Port | Notes |
| --- | --- | --- | --- | --- |
| `api-gateway` | API Gateway (ElysiaJS) | `bun --watch` | `3000` | Main API entry; includes dispatcher routes internally |
| `dispatcher` | Dispatcher | `internal` | `3000` | Not a separate process in current config |
| `leader` | Leader Worker (ElysiaJS) | `bun --watch` | `8090` | Built-in worker |
| `master` | Master Worker | `opencode serve` | `8091` | Requires `opencode` available |
| `zorron-ui` | Vue Dashboard | Vite | `5173` | `VITE_API_URL=http://localhost:3000` |

If `bun dev` fails because `opencode` is unavailable, start only the core system group:

```bash
bun dev:start system
```

Useful service control commands:

```bash
bun dev:status
bun dev:stop
bun dev:restart
bun dev:start system
bun dev:start builtin-worker
bun dev:start api-gateway leader zorron-ui
```

When a dev session is no longer needed, prefer:

```bash
bun dev:stop
```

## Single-Service Startup

Use these when isolating a service:

```bash
bun start:dev:api-gateway
bun start:dev:leader
bun start:dev:zorron-nest
bun start:dev:ui
bun start:dev:mock-workers
```

`start:dev:dispatcher` exists in `package.json`, but `startup.config.json` says Dispatcher is currently merged into API Gateway. Prefer API Gateway and `/dispatcher/*` routes unless changing legacy dispatcher code.

## Verification

After startup, check health:

```bash
bun cli:health
bun cli:dashboard
bun smoke
```

Equivalent CLI entrypoint:

```bash
bun cli health
bun cli dashboard
bun cli smoke
```

The CLI reads `ZORRON_GATEWAY_URL` and `ZORRON_API_KEY`; by default it targets `http://127.0.0.1:3000`.

Public quick checks:

```bash
curl http://127.0.0.1:3000/health
curl http://127.0.0.1:3000/conversations/health
curl http://127.0.0.1:3000/system/health
```

The Vue dashboard is at:

```text
http://localhost:5173
```

## Build, Test, Lint, Format

Common validation commands:

```bash
bun test
bun test:watch
bun test:cov
bun test:e2e
bun lint
bun format
```

TypeScript type checking:

```bash
bun run tsc --noEmit
bun run tsgo --noEmit
```

## Environment

Use `.env.example` as the template for `.env`. Important runtime variables:

```text
NODE_ENV=development
API_KEY=
CORS_ORIGINS=http://localhost:5173
DISPATCHER_URL=http://127.0.0.1:3000/dispatcher
ZORRON_GATEWAY_URL=http://127.0.0.1:3000
ZORRON_API_KEY=
PORT=3000
LEADER_PORT=8090
```

In development, an empty `API_KEY` generally allows requests unless `NODE_ENV=production`.

## Operational Notes

Prefer commands from `package.json` over ad hoc process management. `scripts/dev.ts` can release occupied ports, maintain `.pids/`, and print grouped service status.

The project uses **ElysiaJS** (not NestJS). All HTTP routes are defined in `apps/*/src/routes/*.routes.ts` and composed via `apps/*/src/app.ts`. Services in `libs/` are plain TypeScript classes without framework decorators.

For project-specific API and CLI usage, consult `docs/OPERATION_MANUAL.md` and `docs/PROJECT_USAGE_GUIDE.md`.