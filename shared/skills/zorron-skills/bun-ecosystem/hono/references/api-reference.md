# Hono API Reference

## Hono Instance Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `app.get` | `(path, ...handlers)` | Register GET handler |
| `app.post` | `(path, ...handlers)` | Register POST handler |
| `app.put` | `(path, ...handlers)` | Register PUT handler |
| `app.delete` | `(path, ...handlers)` | Register DELETE handler |
| `app.patch` | `(path, ...handlers)` | Register PATCH handler |
| `app.all` | `(path, ...handlers)` | Match any HTTP method |
| `app.on` | `(method, path, ...handlers)` | Custom/multiple methods |
| `app.use` | `(path?, middleware)` | Register middleware |
| `app.route` | `(path, app)` | Mount sub-app at path |
| `app.basePath` | `(path)` | Set base path |
| `app.notFound` | `(handler)` | Custom 404 handler |
| `app.onError` | `(handler)` | Global error handler |
| `app.mount` | `(path, handler)` | Mount non-Hono app |
| `app.fetch` | `(request, env?, ctx?)` | Entry point for runtimes |
| `app.request` | `(path, options?, env?)` | Test helper |

## Context (c) Methods

### Request Access

| Method/Property | Returns | Description |
|----------------|---------|-------------|
| `c.req` | `HonoRequest` | Request object |
| `c.req.method` | `string` | HTTP method |
| `c.req.url` | `string` | Full URL |
| `c.req.path` | `string` | Path only |
| `c.req.header(name)` | `string \| undefined` | Get request header |
| `c.req.param(name?)` | `string \| Record` | Path params |
| `c.req.query(key?)` | `string \| Record` | Query params |
| `c.req.queries(key?)` | `string[]` | Multi-value query |
| `c.req.parseBody()` | `Promise<Record>` | Parse form body |
| `c.req.json()` | `Promise<any>` | Parse JSON body |
| `c.req.arrayBuffer()` | `Promise<ArrayBuffer>` | Raw body |
| `c.req.blob()` | `Promise<Blob>` | Body as Blob |
| `c.req.text()` | `Promise<string>` | Body as text |
| `c.req.valid(target)` | `T` | Get validated data |

### Response Helpers

| Method | Signature | Description |
|--------|-----------|-------------|
| `c.text` | `(body, status?, headers?)` | text/plain response |
| `c.json` | `(body, status?, headers?)` | application/json response |
| `c.html` | `(body, status?, headers?)` | text/html response |
| `c.redirect` | `(url, status?)` | Redirect (default 302) |
| `c.notFound` | `()` | 404 response |
| `c.body` | `(body, status?, headers?)` | Raw response |
| `c.status` | `(code)` | Set status code |
| `c.header` | `(name, value)` | Set response header |

### State & Environment

| Method/Property | Description |
|----------------|-------------|
| `c.set(key, value)` | Set per-request variable |
| `c.get(key)` | Get per-request variable |
| `c.var` | Access variables as properties |
| `c.env` | Environment bindings (Cloudflare) |
| `c.executionCtx` | ExecutionContext (Cloudflare) |
| `c.error` | Access thrown error |
| `c.res` | Response object (mutable after next) |

## Routing Patterns

| Pattern | Example | Matches |
|---------|---------|---------|
| Static | `/hello` | Exact match |
| Named param | `/user/:name` | `/user/alice` |
| Optional | `/api/:type?` | `/api` and `/api/cat` |
| Regexp | `/post/:id{[0-9]+}` | `/post/123` |
| Wildcard | `/files/*` | `/files/a/b/c` |
| Including slashes | `/files/:name{.+\\.png}` | `/files/a/b/img.png` |

## HTTPException

```typescript
import { HTTPException } from 'hono/http-exception'

// Basic
throw new HTTPException(401, { message: 'Unauthorized' })

// Custom response
throw new HTTPException(401, {
  res: new Response('Unauthorized', { status: 401, headers: { 'WWW-Authenticate': 'error="invalid_token"' } })
})

// With cause
throw new HTTPException(401, { message: 'Auth failed', cause: originalError })

// In error handler
app.onError((err, c) => {
  if (err instanceof HTTPException) return err.getResponse()
  return c.text('Internal Server Error', 500)
})
```

## HonoRequest (c.req) Full API

```typescript
// Headers
c.req.header()                    // All headers as Record
c.req.header('content-type')      // Specific header

// Params
c.req.param()                     // All params as Record
c.req.param('id')                 // Specific param

// Query
c.req.query()                     // All query as Record
c.req.query('page')               // Specific query param
c.req.queries('tag')              // Multi-value: ?tag=a&tag=b -> ['a', 'b']

// Body parsing
await c.req.parseBody()           // FormData / URL-encoded
await c.req.json()                // JSON body
await c.req.text()                // Raw text
await c.req.arrayBuffer()         // ArrayBuffer
await c.req.blob()                // Blob
await c.req.formData()            // FormData object

// Validated data
c.req.valid('json')               // Zod-validated JSON
c.req.valid('form')               // Zod-validated form
c.req.valid('query')              // Zod-validated query
c.req.valid('param')              // Zod-validated params
c.req.valid('header')             // Zod-validated headers
```

## Validator Targets

| Target | Source | Content-Type required |
|--------|--------|----------------------|
| `json` | Request body | `application/json` |
| `form` | Request body | `application/x-www-form-urlencoded` or `multipart/form-data` |
| `query` | URL query string | N/A |
| `param` | Path parameters | N/A |
| `header` | Request headers | N/A |
| `cookie` | Cookie header | N/A |

## RPC Client (hc)

```typescript
import { hc } from 'hono/client'
import type { AppType } from '../server'

const client = hc<AppType>('http://localhost:8787/')

// GET request
const res = await client.posts.$get()

// POST with JSON
const res = await client.posts.$post({
  json: { title: 'Hello', body: 'World' }
})

// With path params
const res = await client.posts[':id'].$get({
  param: { id: '123' }
})

// With query params
const res = await client.search.$get({
  query: { q: 'hono', page: '1' }
})

// With custom headers
const res = await client.posts.$get({}, {
  headers: { 'Authorization': 'Bearer token' }
})

// Get URL
const url = client.posts.$url()

// Type inference
import type { InferRequestType, InferResponseType } from 'hono/client'
type ReqType = InferRequestType<typeof client.posts.$post>
type ResType = InferResponseType<typeof client.posts.$post>
```
