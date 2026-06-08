# Tencent Cloud EdgeOne Pages Configuration & Deployment Specification

This reference document outlines the complete configuration options for `edgeone.json`, deployment methods, framework integration rules, and API token management on Tencent Cloud EdgeOne Pages.

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

## 2. Pages Deployment Methods

Tencent Cloud EdgeOne Pages supports three major deployment workflows:

1.  **Git Integration (Recommended)**: Connect to GitHub, GitLab, or Gitee repository. On push to the specified branch, the cloud environment automatically builds and deploys the assets.
2.  **EdgeOne CLI Direct Upload**: Deploy directly from local dev environments or CI/CD pipelines (e.g., Jenkins, GitHub Actions) using the `edgeone` CLI:
    ```bash
    edgeone pages deploy ./dist -n <projectName> -t <api_token>
    ```
3.  **Template Scaffolding**: Initiate projects directly from curated presets (Astro, Next.js, etc.) via the EdgeOne Console.

---

## 3. API Token Authentication

In non-interactive deployment scenarios (like CI/CD pipelines or headless servers), you **must** use an API Token for authorization instead of `edgeone login`.

- **Generation**: Go to the **EdgeOne Pages Console** -> **Project Settings** -> **API Token** -> Click **Generate Token**.
- **Security**: Store the token securely. For GitHub Actions, add it to your repository secrets (`EDGEONE_API_TOKEN`).
- **Usage**:
  ```bash
  edgeone pages deploy ./dist -n <projectName> -t "${EDGEONE_API_TOKEN}"
  ```
