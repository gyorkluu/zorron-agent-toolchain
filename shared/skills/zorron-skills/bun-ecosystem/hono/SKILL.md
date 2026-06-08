---
name: hono
description: "Build web APIs and edge applications with Hono, an ultrafast lightweight framework on Web Standards. Triggers on "hono", "honojs", "create API with hono", "hono middleware", "hono RPC". DO NOT invoke for Express, Fastify, Koa, or non-Hono frameworks. This skill covers detailed instructions, workflows, prerequisites, and safety guidelines for the task."
allowed-tools: Bash
version: 1.0.0
---

# Hono Skill

Hono (火焰🔥) is a small, simple, and ultrafast web framework built on Web Standards. It works on any JavaScript runtime: Cloudflare Workers, Bun, Deno, Node.js, AWS Lambda, Vercel, and more.

## When to invoke

- User wants to build a web API or edge application with Hono
- User asks about Hono routing, middleware, validation, or RPC
- User wants to scaffold a new Hono project
- User needs help with Hono deployment on any runtime
- User asks about type-safe API patterns with Hono
- DO NOT invoke for Express, Fastify, Koa, ElysiaJS, or other frameworks

---

## Quick Start

```bash
# Scaffold a new project (interactive)
pnpm create hono@latest

# Or with bun
bun create hono@latest
```

Minimal app:

```typescript
import { Hono } from 'hono'
const app = new Hono()

app.get('/', (c) => c.text('Hello Hono!'))

export default app
```

---

## Core Concepts

### 1. App Instance

```typescript
import { Hono } from 'hono'

// Basic
const app = new Hono()

// With type-safe Bindings and Variables
type Bindings = { TOKEN: string; DB: D1Database }
type Variables = { user: User }
const app = new Hono<{ Bindings: Bindings; Variables: Variables }>()

// Strict mode (default true, distinguishes /hello vs /hello/)
const app = new Hono({ strict: false })

// Custom router
import { RegExpRouter } from 'hono/router/reg-exp-router'
const app = new Hono({ router: new RegExpRouter() })
```

### 2. Routing

```typescript
// HTTP methods
app.get('/', (c) => c.text('GET'))
app.post('/', (c) => c.text('POST'))
app.put('/', (c) => c.text('PUT'))
app.delete('/', (c) => c.text('DELETE'))

// Wildcard
app.get('/wild/*/card', (c) => c.text('Wild'))

// Any method
app.all('/hello', (c) => c.text('Any'))

// Custom method
app.on('PURGE', '/cache', (c) => c.text('PURGE'))

// Multiple methods
app.on(['PUT', 'DELETE'], '/post', (c) => c.text('PUT or DELETE'))

// Path parameters
app.get('/user/:name', (c) => {
  const name = c.req.param('name')
  return c.json({ name })
})

// Optional parameters
app.get('/api/animal/:type?', (c) => c.text('Animal'))

// Regexp constraints
app.get('/post/:date{[0-9]+}/:title{[a-z]+}', (c) => {
  const { date, title } = c.req.param()
  return c.json({ date, title })
})

// Chained routes
app
  .get('/endpoint', (c) => c.text('GET'))
  .post((c) => c.text('POST'))
  .delete((c) => c.text('DELETE'))

// Route grouping
const book = new Hono()
book.get('/', (c) => c.text('List Books'))
book.get('/:id', (c) => c.text('Book: ' + c.req.param('id')))

const app = new Hono()
app.route('/book', book) // mounts at /book

// Base path
const api = new Hono().basePath('/api')
api.get('/users', (c) => c.text('Users')) // GET /api/users
```

### 3. Context (c)

The Context object is created per request. Key methods:

```typescript
// Request access
c.req.header('User-Agent')
c.req.param('id')
c.req.query('page')
c.req.parseBody()
c.req.json()

// Response helpers
c.text('Hello')                        // text/plain
c.json({ message: 'Hi' })             // application/json
c.html('<h1>Hello</h1>')              // text/html
c.redirect('/')                        // 302 redirect
c.redirect('/', 301)                   // 301 redirect
c.notFound()                           // 404
c.body('raw body', 200, { 'X-Custom': 'yes' }) // raw response

// Status and headers
c.status(201)
c.header('X-Message', 'Hello')

// State (per-request key-value)
c.set('user', userObj)
const user = c.get('user')
const user = c.var.user

// Environment (Cloudflare Bindings etc.)
c.env.TOKEN
c.env.DB

// Error handling
c.error // access thrown error in middleware
```

### 4. Middleware

```typescript
// Built-in middleware
import { logger } from 'hono/logger'
import { basicAuth } from 'hono/basic-auth'
import { bearerAuth } from 'hono/bearer-auth'
import { cors } from 'hono/cors'
import { etag } from 'hono/etag'
import { prettyJSON } from 'hono/pretty-json'
import { secureHeaders } from 'hono/secure-headers'
import { compress } from 'hono/compress'
import { cache } from 'hono/cache'
import { poweredBy } from 'hono/powered-by'

app.use(logger())
app.use('/api/*', cors())
app.use('/auth/*', basicAuth({ username: 'admin', password: 'secret' }))

// Custom middleware
app.use(async (c, next) => {
  console.log(`${c.req.method} ${c.req.url}`)
  await next()
  c.header('X-Response-Time', Date.now().toString())
})

// Reusable middleware with createMiddleware
import { createMiddleware } from 'hono/factory'

const authMiddleware = createMiddleware<{
  Variables: { user: User }
}>(async (c, next) => {
  const token = c.req.header('Authorization')
  if (!token) throw new HTTPException(401, { message: 'Unauthorized' })
  c.set('user', verifyToken(token))
  await next()
})
```

> Execution order: middleware runs top-down before `next()`, then bottom-up after `next()`.

### 5. Validation (with Zod)

```typescript
import * as z from 'zod'
import { zValidator } from '@hono/zod-validator'

// Validate JSON body
app.post(
  '/posts',
  zValidator('json', z.object({
    title: z.string(),
    body: z.string(),
  })),
  (c) => {
    const { title, body } = c.req.valid('json')
    return c.json({ created: true }, 201)
  }
)

// Validate query params
app.get(
  '/search',
  zValidator('query', z.object({
    q: z.string(),
    page: z.coerce.number().optional(),
  })),
  (c) => {
    const { q, page } = c.req.valid('query')
    return c.json({ results: [] })
  }
)

// Validate path params
app.get(
  '/users/:id',
  zValidator('param', z.object({ id: z.string().uuid() })),
  (c) => {
    const { id } = c.req.valid('param')
    return c.json({ id })
  }
)

// Validation targets: json, form, query, param, header, cookie
```

### 6. Error Handling

```typescript
import { HTTPException } from 'hono/http-exception'

// Throw typed errors
app.post('/login', async (c) => {
  const user = await authenticate(c)
  if (!user) {
    throw new HTTPException(401, { message: 'Invalid credentials' })
  }
  return c.json({ user })
})

// Global error handler
app.onError((err, c) => {
  if (err instanceof HTTPException) {
    return err.getResponse()
  }
  console.error(err)
  return c.text('Internal Server Error', 500)
})

// Custom 404
app.notFound((c) => c.text('Not Found', 404))
```

### 7. RPC (Type-safe Client)

```typescript
// Server: export the route type
const route = app.post(
  '/posts',
  zValidator('json', z.object({ title: z.string(), body: z.string() })),
  (c) => {
    const { title, body } = c.req.valid('json')
    return c.json({ ok: true, id: '1' }, 201)
  }
)
export type AppType = typeof route

// Client: use hc for type-safe calls
import { hc } from 'hono/client'
import type { AppType } from './server'

const client = hc<AppType>('http://localhost:8787/')

const res = await client.posts.$post({
  json: { title: 'Hello', body: 'World' },
})

if (res.ok) {
  const data = await res.json() // fully typed!
}
```

### 8. Testing

```typescript
import { describe, test, expect } from 'vitest'

describe('API', () => {
  test('GET /posts', async () => {
    const res = await app.request('/posts')
    expect(res.status).toBe(200)
  })

  test('POST /posts', async () => {
    const res = await app.request('/posts', {
      method: 'POST',
      headers: new Headers({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({ title: 'Test', body: 'Hello' }),
    })
    expect(res.status).toBe(201)
  })

  // With mock env (Cloudflare Bindings)
  test('GET /data', async () => {
    const res = await app.request('/data', {}, { DB: mockDB })
    expect(res.status).toBe(200)
  })
})
```

---

## Project Scaffolding

When creating a new Hono project, choose the runtime template:

```bash
pnpm create hono@latest my-app
# Select: cloudflare-workers | bun | deno | nodejs | vercel | aws-lambda | netlify
```

### Typical project structure

```text
my-app/
├── src/
│   ├── index.ts          # App entry point
│   ├── routes/
│   │   ├── users.ts      # Route group
│   │   └── posts.ts
│   ├── middleware/
│   │   ├── auth.ts
│   │   └── logger.ts
│   └── types/
│       └── env.ts        # Bindings & Variables types
├── test/
│   └── index.test.ts
├── package.json
├── tsconfig.json
└── wrangler.toml         # Cloudflare Workers config (if applicable)
```

### Entry point pattern

```typescript
// src/index.ts
import { Hono } from 'hono'
import { logger } from 'hono/logger'
import { cors } from 'hono/cors'
import users from './routes/users'
import posts from './routes/posts'
import type { Env } from './types/env'

const app = new Hono<Env>()

app.use(logger())
app.use('/api/*', cors())

app.route('/api/users', users)
app.route('/api/posts', posts)

app.get('/health', (c) => c.json({ status: 'ok' }))

app.notFound((c) => c.json({ error: 'Not Found' }, 404))
app.onError((err, c) => {
  console.error(err)
  return c.json({ error: 'Internal Server Error' }, 500)
})

export default app
export type AppType = typeof app
```

---

## Deployment Quick Reference

| Runtime | Command | Export |
|---------|---------|--------|
| **Cloudflare Workers** | `pnpm create hono@latest --template cloudflare-workers` | `export default app` |
| **Bun** | `bun create hono@latest --template bun` | `export default { port: 3000, fetch: app.fetch }` |
| **Node.js** | `pnpm create hono@latest --template nodejs` | Uses `@hono/node-server` |
| **Deno** | `deno init --npm hono@latest` | `export default app` |
| **Vercel** | `pnpm create hono@latest --template vercel` | `export default app` |
| **AWS Lambda** | `pnpm create hono@latest --template aws-lambda` | Uses `@hono/aws-lambda` |

> For detailed deployment configs, read: `references/deployment.md`

---

## Rules & Guardrails

- **MUST**: Use `c.json()` with explicit status codes for RPC type inference
- **MUST**: Validate all inputs with Zod + `zValidator` for type safety
- **MUST**: Export `AppType` when using RPC pattern
- **MUST**: Use `HTTPException` for error responses, not raw `new Response`
- **MUST NOT**: Use `c.notFound()` in RPC routes (breaks type inference)
- **MUST NOT**: Mix Hono version with middleware versions in Deno
- **SHOULD**: Use `createMiddleware` from `hono/factory` for reusable middleware
- **SHOULD**: Chain route handlers for proper type inference in large apps
- **SHOULD**: Keep route files focused; use `app.route()` to compose

---

## Output Specification

When building with Hono, always produce:
1. Type-safe route definitions with Zod validation
2. Proper error handling with `HTTPException` and `app.onError`
3. Health endpoint at `/health` returning `{ status: 'ok' }`
4. Exported `AppType` for RPC client consumption
5. Test files using `app.request()` pattern

---

## Examples & Edge Cases

- **Typical**: "Create a REST API with Hono for user management"
- **RPC**: "Build a type-safe API with Hono RPC and Zod"
- **Edge**: "Deploy Hono to Cloudflare Workers with D1 and KV bindings"
- **Middleware chain**: Order matters — middleware registered first runs first before `next()`
- **Wildcard routes**: `app.get('*', ...)` catches all — register after specific routes
- **Header validation**: Use lowercase keys when validating headers (`idempotency-key` not `Idempotency-Key`)

> For complete API reference, read: `references/api-reference.md`
> For middleware catalog, read: `references/middleware.md`