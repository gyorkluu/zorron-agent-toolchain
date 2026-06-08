# Tencent Cloud EdgeOne Pages Configuration & Deployment Specification

This reference document outlines the complete configuration options for `edgeone.json`, deployment methods, framework integration rules, Pages Functions (Edge & Cloud), storage options (KV & Blob), observability, domain management, and AI integrations on Tencent Cloud EdgeOne Pages.

---

## 1. `edgeone.json` Configuration Specification

Create an `edgeone.json` file in the root directory of your frontend project to define and override the default project behaviors.

### Configuration Fields

| Field | Type | Description | Example |
| --- | --- | --- | --- |
| `buildCommand` | `string` | Overrides the build command defined in the console. | `"npm run build"` |
| `installCommand` | `string` | Overrides the package installation command. Configures the package manager used in build. | `"pnpm install"` |
| `outputDirectory` | `string` | Overrides the static asset output directory. | `"dist"` or `"./build"` |
| `nodeVersion` | `string` | Specifies the Node.js version. Recommended pre-installed versions: `14.21.3`, `16.20.2`, `18.20.4`, `20.18.0`, `22.11.0`. | `"22.11.0"` |
| `redirects` | `array` | Configure HTTP redirects (up to 100 rules). | See below |
| `rewrites` | `array` | Configure URL rewrites (up to 100 rules). Does not support SPA frontend routing rewrites. | See below |
| `headers` | `array` | Configure custom HTTP headers (security, cache control). | See below |
| `cloudFunctions` | `object` | Settings for Serverless Cloud Functions (timeout, deployment regions). | See below |
| `schedules` | `array` | Set cron-based timers to trigger Pages Functions. | See below |

---

### Field Details & Examples

#### `redirects` (HTTP Redirects)
Used to redirect requests from one URL path to another with status code `301` (permanent) or `302` (temporary).
```json
{
  "redirects": [
    {
      "source": "/articles/:id",
      "destination": "/news-articles/:id",
      "statusCode": 301
    },
    {
      "source": "/old-path",
      "destination": "/new-path",
      "statusCode": 302
    },
    {
      "source": "$host",
      "destination": "$wwwhost",
      "statusCode": 301
    }
  ]
}
```

#### `rewrites` (URL Rewrites)
Rewrites paths internally without modifying the address bar URL. Typically used for static assets mapping.
> [!IMPORTANT]
> The `rewrites` configuration applies only to static resources. It does **not** support SPA (Single Page Application) frontend routing rewrites. For SPA routing, configure it in your frontend router.
```json
{
  "rewrites": [
    {
      "source": "/assets/*",
      "destination": "/assets-new/:splat"
    },
    {
      "source": "/assets/*.png",
      "destination": "/assets-new/:splat.png"
    }
  ]
}
```

#### `headers` (HTTP Headers)
Inject custom headers to manage website security, caching, and CORS.
```json
{
  "headers": [
    {
      "source": "/*",
      "headers": [
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "Cache-Control",
          "value": "max-age=7200"
        }
      ]
    }
  ]
}
```

#### `cloudFunctions` (Cloud Functions)
Configure runtime parameters for EdgeOne Pages Serverless Functions.
- **Regions**: Configure mainland regions via `main mainlandRegions` (default: `ap-guangzhou`) and overseas regions via `overseasRegions` (default: `ap-singapore`).
- **Timeout**: `maxDuration` can be set up to `120` seconds (default: 30) for handling long-lived API requests (e.g., AI streaming/SSE).
```json
{
  "cloudFunctions": {
    "mainlandRegions": ["ap-beijing"],
    "overseasRegions": ["ap-tokyo"],
    "maxDuration": 120,
    "includeFiles": ["config/*.json"]
  }
}
```

#### `schedules` (Cron Timers)
Define background cron jobs to periodically trigger specific functions.
```json
{
  "schedules": [
    {
      "cron": "0 * * * *",
      "path": "/api/hourly-sync"
    }
  ]
}
```

---

### Complete `edgeone.json` Example

```json
{
  "installCommand": "pnpm install",
  "buildCommand": "pnpm run build",
  "outputDirectory": "dist",
  "nodeVersion": "22.11.0",
  "headers": [
    {
      "source": "/*",
      "headers": [
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "Cache-Control",
          "value": "max-age=7200"
        }
      ]
    }
  ],
  "redirects": [
    {
      "source": "/old-blog/:slug",
      "destination": "/blog/:slug",
      "statusCode": 301
    }
  ],
  "cloudFunctions": {
    "maxDuration": 60
  },
  "schedules": [
    {
      "cron": "*/15 * * * *",
      "path": "/api/cron-check"
    }
  ]
}
```

---

## 2. Pages Functions (Edge vs Cloud)

EdgeOne Pages supports Serverless Functions inside the `cloud-functions/` or `edge-functions/` folders.

| Feature | Edge Functions (边缘函数) | Cloud Functions (云函数) |
| --- | --- | --- |
| **Execution Location** | Edge nodes worldwide (close to user) | Central Cloud data centers |
| **Response Latency** | **Extremely Low** (millisecond cold start) | Higher (due to routing to data center) |
| **Computation Power** | Lightweight (best for header adjustments, redirect logic) | Powerful (suited for heavy compute, DB queries) |
| **Timeout Limit** | Short | Up to 120 seconds (configurable in `edgeone.json`) |
| **Supported Runtimes** | JavaScript (standard Web Worker API) | Node.js, Python, Go |
| **Storage Binding** | KV, Blob | Blob |

- **Edge Functions**: Used for URL rewrites, A/B testing, custom security headers, image manipulation, and instant API responses.
- **Cloud Functions**: Used for complex business logic, database queries, long-lived API connections (like AI streaming), and background data aggregation.

### Folder Structure & Directory Placement

In your project repository, these folders must be placed at the **project root directory** (adjacent to `edgeone.json` and `package.json`):

```text
my-pages-project/
├── edge-functions/         # Edge Functions source code
│   └── api/
│       └── hello.js        # Accessible via https://<your-domain>/api/hello
├── cloud-functions/        # Cloud Functions source code
│   └── index.js            # Accessible via https://<your-domain>/
├── edgeone.json            # Configuration file
└── package.json            # Node project configuration
```

#### Important Deployment Rules for Functions:
1. **Git / Automatic Cloud Build**: When deploying via Git integration, the Pages builder will automatically locate `edge-functions/` and `cloud-functions/` at the root of your repository and compile them.
2. **Local / Manual CLI Deployment (`edgeone pages deploy <dir>`)**:
   - If you use `edgeone pages deploy` (which builds the project automatically via CLI), the CLI handles copying these folders.
   - If you run your own build command (e.g. `npm run build` which outputs to `dist/`) and manually deploy the folder via `edgeone pages deploy ./dist`, you **MUST** copy the `edge-functions/` and/or `cloud-functions/` folders, along with `package.json`, into your output directory (`./dist`) before running the deploy command.

---

## 3. Integrated Storage Options

EdgeOne Pages provides built-in distributed storage that can be bound directly to your functions.

### A. KV Storage (Key-Value Store)
- **Architecture**: Centralized storage with edge node caching.
- **Consistency**: Eventually consistent (edge cache duration up to 60 seconds).
- **Data Limit**: Single value up to 25 MB.
- **Availability**: Currently supported inside Edge Functions.
- **Use Case**: Clicking counters, feature toggles, session states, configuration variables.

### B. Blob Storage (Object Store)
- **Architecture**: Distributed object store with folder/directory path support.
- **Consistency**: Supports both "Eventually Consistent" (reads edge caches) and "Strongly Consistent" (direct fetch) modes.
- **Availability**: Supported in both Edge Functions and Cloud Functions.
- **Use Case**: Image uploads, document hosting, AI generated content management, JSON structured database storage.

---

## 4. Observability & Domain Management

### A. Observability
EdgeOne Pages Console provides out-of-the-box charts for monitoring:
- **Metrics Analysis**: Request count, error rates (4xx, 5xx), transfer sizes, and execution latency.
- **Log Analysis**: Real-time console logs and error stack traces to debug function failures.

### B. Domain Management
- **Custom Domains**: Bind domains in Console -> Project Settings -> Domains.
- **DNS Records**: Point the domain CNAME to the allocated EdgeOne Page domain (e.g. `your-project.edgeone.app`).
- **HTTPS & SSL**: Automatic provisioning and renewal of free Let's Encrypt certificates, or upload your own SSL custom certificates.

---

## 5. AI Tool Integrations

EdgeOne Pages provides advanced options to deploy and maintain pages using AI Agent ecosystems:

1.  **MCP Server**: Enables AI clients (like Cursor or VS Code) to deploy folders, HTML pages, or full frameworks to EdgeOne Pages via simple text prompts in the chat panel.
2.  **EdgeOne Pages Skills**: A curated set of agent procedures and scripts to automate workspace diagnostics, dependency installations, and deployment commands directly from your local agent environment.
