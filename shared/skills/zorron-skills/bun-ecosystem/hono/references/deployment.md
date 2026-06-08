# Hono Deployment Guide

## Cloudflare Workers

```bash
pnpm create hono@latest my-app --template cloudflare-workers
cd my-app
pnpm install
pnpm dev      # Local dev with wrangler
pnpm deploy   # Deploy to Cloudflare
```

**wrangler.toml:**
```toml
name = "my-app"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[vars]
API_HOST = "api.example.com"

[[kv_namespaces]]
binding = "MY_KV"
id = "xxxx"

[[d1_databases]]
binding = "DB"
database_name = "my-db"
database_id = "xxxx"
```

**Type-safe bindings:**
```typescript
// src/types/env.ts
type Bindings = {
  API_HOST: string
  MY_KV: KVNamespace
  DB: D1Database
}

export type Env = { Bindings: Bindings }
```

## Bun

```bash
bun create hono@latest my-app --template bun
cd my-app
bun install
bun run dev    # Start dev server
```

**Entry point:**
```typescript
// src/index.ts
import { Hono } from 'hono'

const app = new Hono()
app.get('/', (c) => c.text('Hello Bun!'))

export default {
  port: 3000,
  fetch: app.fetch,
}
```

**Run:** `bun run --hot src/index.ts`

## Node.js

```bash
pnpm create hono@latest my-app --template nodejs
cd my-app
pnpm install
pnpm dev
```

Uses `@hono/node-server`:
```typescript
import { serve } from '@hono/node-server'
import { Hono } from 'hono'

const app = new Hono()
app.get('/', (c) => c.text('Hello Node!'))

serve({ fetch: app.fetch, port: 3000 })
```

## Deno

```bash
deno init --npm hono@latest my-app
cd my-app
deno task dev
```

**deno.json:**
```json
{
  "tasks": {
    "dev": "deno run --watch --allow-net src/index.ts",
    "start": "deno run --allow-net src/index.ts"
  }
}
```

## Vercel

```bash
pnpm create hono@latest my-app --template vercel
```

Structure for Vercel:
```text
api/
└── [[route]].ts    # Catch-all route handler
```

```typescript
// api/[[route]].ts
import { Hono } from 'hono'
import { handle } from 'hono/vercel'

const app = new Hono().basePath('/api')
app.get('/hello', (c) => c.json({ message: 'Hello Vercel!' }))

export const GET = handle(app)
export const POST = handle(app)
```

## AWS Lambda

```bash
pnpm create hono@latest my-app --template aws-lambda
```

```typescript
import { Hono } from 'hono'
import { handle } from 'hono/aws-lambda'

const app = new Hono()
app.get('/', (c) => c.text('Hello Lambda!'))

export const handler = handle(app)
```

## Netlify

```bash
pnpm create hono@latest my-app --template netlify
```

```typescript
import { Hono } from 'hono'
import { handle } from 'hono/netlify'

const app = new Hono().basePath('/api')
app.get('/hello', (c) => c.json({ message: 'Hello Netlify!' }))

export default handle(app)
```

## Fastly Compute

```bash
pnpm create hono@latest my-app --template fastly
```

## Multi-runtime Pattern

Write once, deploy anywhere. The same Hono code works across all runtimes:

```typescript
// src/index.ts - works on ALL runtimes
import { Hono } from 'hono'

const app = new Hono()
app.get('/', (c) => c.text('Hello World!'))
app.get('/health', (c) => c.json({ status: 'ok' }))

export default app
```

Only the entry point / adapter differs per runtime.
