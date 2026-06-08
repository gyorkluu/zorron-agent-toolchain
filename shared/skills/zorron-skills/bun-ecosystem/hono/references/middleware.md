# Hono Middleware Catalog

## Built-in Middleware

### Authentication

| Middleware | Import | Description |
|-----------|--------|-------------|
| Basic Auth | `hono/basic-auth` | HTTP Basic Authentication |
| Bearer Auth | `hono/bearer-auth` | Bearer token authentication |
| JWT | `hono/jwt` | JWT token verification |

```typescript
import { basicAuth } from 'hono/basic-auth'
app.use('/admin/*', basicAuth({ username: 'admin', password: 'secret' }))

import { bearerAuth } from 'hono/bearer-auth'
app.use('/api/*', bearerAuth({ token: 'your-token' }))

import { jwt } from 'hono/jwt'
app.use('/auth/*', jwt({ secret: 'your-secret' }))
```

### Security

| Middleware | Import | Description |
|-----------|--------|-------------|
| CORS | `hono/cors` | Cross-Origin Resource Sharing |
| Secure Headers | `hono/secure-headers` | Security headers (XSS, CSRF, etc.) |
| Body Limit | `hono/body-limit` | Limit request body size |

```typescript
import { cors } from 'hono/cors'
app.use('/api/*', cors({
  origin: 'https://example.com',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowHeaders: ['Content-Type', 'Authorization'],
  exposeHeaders: ['X-Total-Count'],
  maxAge: 86400,
  credentials: true,
}))

import { secureHeaders } from 'hono/secure-headers'
app.use(secureHeaders())

import { bodyLimit } from 'hono/body-limit'
app.use(bodyLimit({ maxSize: 10 * 1024 })) // 10KB
```

### Caching & Performance

| Middleware | Import | Description |
|-----------|--------|-------------|
| Cache | `hono/cache` | HTTP caching |
| Compress | `hono/compress` | Gzip compression |
| ETag | `hono/etag` | ETag support |

```typescript
import { cache } from 'hono/cache'
app.get('/api/*', cache({ cacheName: 'api', cacheControl: 'max-age=3600' }))

import { compress } from 'hono/compress'
app.use(compress())

import { etag } from 'hono/etag'
app.use(etag())
```

### Logging & Debug

| Middleware | Import | Description |
|-----------|--------|-------------|
| Logger | `hono/logger` | Request logging |
| Powered By | `hono/powered-by` | X-Powered-By header |
| Pretty JSON | `hono/pretty-json` | Pretty-printed JSON |

```typescript
import { logger } from 'hono/logger'
app.use(logger())

import { poweredBy } from 'hono/powered-by'
app.use(poweredBy())

import { prettyJSON } from 'hono/pretty-json'
app.use(prettyJSON())
```

### Other Built-in

| Middleware | Import | Description |
|-----------|--------|-------------|
| Context Storage | `hono/context-storage` | AsyncLocalStorage for context |
| Language | `hono/language` | Accept-Language parsing |
| Timing | `hono/timing` | Server-Timing header |

## Third-party Middleware

| Middleware | Package | Description |
|-----------|---------|-------------|
| Zod Validator | `@hono/zod-validator` | Zod schema validation |
| Standard Validator | `@hono/standard-validator` | Standard Schema validation |
| GraphQL Server | `@hono/graphql-server` | GraphQL endpoint |
| Sentry | `@hono/sentry` | Error tracking |
| Firebase Auth | `@hono/firebase-auth` | Firebase authentication |
| OAuth | `@hono/oauth-providers` | OAuth2 providers |
| OIDC | `@hono/oidc` | OpenID Connect |
| Trpc | `@hono/trpc-server` | tRPC integration |
| Clerk | `@hono/clerk-auth` | Clerk authentication |
| Prometheus | `@hono/prometheus` | Metrics collection |
| OpenTelemetry | `@hono/opentelemetry` | Distributed tracing |

```typescript
// Zod Validator
import { zValidator } from '@hono/zod-validator'
app.post('/users', zValidator('json', userSchema), handler)

// GraphQL Server
import { graphqlServer } from '@hono/graphql-server'
app.use('/graphql', graphqlServer({ schema }))

// Sentry
import { sentry } from '@hono/sentry'
app.use('*', sentry({ dsn: 'your-dsn' }))
```

## Custom Middleware Patterns

### Auth Middleware with Type Safety

```typescript
import { createMiddleware } from 'hono/factory'
import { HTTPException } from 'hono/http-exception'

type Env = {
  Variables: {
    user: { id: string; email: string }
  }
}

export const authMiddleware = createMiddleware<Env>(async (c, next) => {
  const token = c.req.header('Authorization')?.replace('Bearer ', '')
  if (!token) {
    throw new HTTPException(401, { message: 'Missing authorization token' })
  }
  try {
    const user = await verifyToken(token)
    c.set('user', user)
    await next()
  } catch {
    throw new HTTPException(401, { message: 'Invalid token' })
  }
})
```

### Request ID Middleware

```typescript
import { createMiddleware } from 'hono/factory'

export const requestId = createMiddleware(async (c, next) => {
  const id = crypto.randomUUID()
  c.set('requestId', id)
  c.header('X-Request-Id', id)
  await next()
})
```

### Response Time Middleware

```typescript
export const responseTime = createMiddleware(async (c, next) => {
  const start = Date.now()
  await next()
  const ms = Date.now() - start
  c.header('X-Response-Time', `${ms}ms`)
})
```
