# Remote Port Registry Setup Guide

This guide explains how to set up, fetch, and update the centralized port registry file from a remote HTTP source.

## Why Remote?

A remote port registry ensures:
- All agents and tools share the same port allocation state
- Multiple developers on the same network avoid conflicts
- Port assignments persist across machine restarts
- No local file sync issues — single source of truth

## Option 1: GitHub Gist (Recommended)

### Setup

1. Create a new GitHub Gist at https://gist.github.com/
2. Name the file `ports-registry.json`
3. Paste the contents from `templates/ports-registry.json`
4. Create the gist (public or secret)

### Get the Raw URL

After creating the gist, the raw URL format is:
```
https://gist.githubusercontent.com/<username>/<gist-id>/raw/ports-registry.json
```

### Fetch the Registry

```bash
# Simple fetch
curl -sL "https://gist.githubusercontent.com/<username>/<gist-id>/raw/ports-registry.json"

# Save to local cache
curl -sL "https://gist.githubusercontent.com/<username>/<gist-id>/raw/ports-registry.json" \
  -o /tmp/ports-registry.json
```

### Update the Registry

Using **GitHub CLI (gh)**:
```bash
# Install gh if not already installed
# macOS: brew install gh

# Authenticate
gh auth login

# Edit the gist with updated file
gh gist edit <gist-id> /tmp/ports-registry-updated.json
```

Using **curl with GitHub API**:
```bash
# Requires a GitHub Personal Access Token with "gist" scope
GITHUB_TOKEN="ghp_your_token_here"
GIST_ID="your_gist_id_here"

# Get current gist SHA (optional, for conflict detection)
curl -sH "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/gists/$GIST_ID" | jq '.history[0].version'

# Update the gist
curl -X PATCH \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "files": {
      "ports-registry.json": {
        "content": '"$(cat /tmp/ports-registry-updated.json | jq -c .)"'
      }
    }
  }' \
  "https://api.github.com/gists/$GIST_ID"
```

## Option 2: GitHub Repository

### Setup

1. Create a repository (private or public) to store the registry
2. Add `ports-registry.json` to the root or a subdirectory

### Fetch the Registry

```bash
# Public repo
curl -sL "https://raw.githubusercontent.com/<owner>/<repo>/main/ports-registry.json"

# Private repo (requires token)
curl -sL -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3.raw" \
  "https://api.github.com/repos/<owner>/<repo>/contents/ports-registry.json"
```

### Update the Registry

```bash
# Using GitHub CLI
gh api repos/<owner>/<repo>/contents/ports-registry.json \
  -X PUT \
  -f message="chore: update port registry" \
  -f content="$(base64 < /tmp/ports-registry-updated.json)" \
  -f sha="$(gh api repos/<owner>/<repo>/contents/ports-registry.json --jq '.sha')"
```

## Option 3: Cloudflare R2 / S3

### Setup

1. Create a bucket (e.g., `dev-configs`)
2. Upload `ports-registry.json`
3. Set appropriate access permissions (public read, authenticated write)

### Fetch the Registry

```bash
# Public URL
curl -sL "https://<bucket>.s3.<region>.amazonaws.com/ports-registry.json"

# Cloudflare R2
curl -sL "https://<account>.r2.dev/ports-registry.json"
```

### Update the Registry

```bash
# AWS S3
aws s3 cp /tmp/ports-registry-updated.json s3://dev-configs/ports-registry.json

# Cloudflare R2 (using wrangler)
wrangler r2 object put dev-configs/ports-registry.json \
  --file /tmp/ports-registry-updated.json
```

## Option 4: Self-Hosted HTTP Server

### Setup

Any HTTP server that can serve and accept JSON files:

```typescript
// Minimal ElysiaJS server for port registry
import { Elysia, t } from "elysia"

const REGISTRY_PATH = "./ports-registry.json"

new Elysia()
  .get("/ports-registry.json", () => Bun.file(REGISTRY_PATH))
  .put("/ports-registry.json", async ({ body }) => {
    await Bun.write(REGISTRY_PATH, JSON.stringify(body, null, 2))
    return { ok: true }
  }, {
    body: t.Object({}, { additionalProperties: true })
  })
  .listen(9900)
```

### Fetch

```bash
curl -sL "http://your-server:9900/ports-registry.json"
```

### Update

```bash
curl -X PUT \
  -H "Content-Type: application/json" \
  -d @/tmp/ports-registry-updated.json \
  "http://your-server:9900/ports-registry.json"
```

## Environment Variable Configuration

Set the remote URL as an environment variable so all tools and agents can find it:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PORTS_REGISTRY_URL="https://gist.githubusercontent.com/<user>/<gist-id>/raw/ports-registry.json"

# Optional: GitHub token for write access
export GITHUB_TOKEN="ghp_your_token_here"

# Optional: Local cache path
export PORTS_REGISTRY_LOCAL_PATH="/tmp/ports-registry.json"
```

## Concurrency & Conflict Resolution

When multiple agents might update the registry simultaneously:

1. **Fetch before write**: Always re-fetch the latest version before pushing updates
2. **Use ETag / If-Match headers**: For GitHub API, use the `If-None-Match` header to detect stale reads
3. **Retry on conflict**: If the update fails (409 Conflict), re-fetch and retry
4. **Atomic updates**: Use `jq` to modify the file in a single pipeline

```bash
# Safe update pattern
curl -sL "$PORTS_REGISTRY_URL" -o /tmp/ports-registry.json
# ... modify /tmp/ports-registry.json ...
gh gist edit <gist-id> /tmp/ports-registry-updated.json
# If edit fails, re-fetch and retry
```

## Security Considerations

- **Never commit secrets** — use environment variables for tokens
- **Use private gists/repos** if the registry contains internal project names or paths
- **Restrict write access** — only authorized agents should update the registry
- **Audit trail** — GitHub gists and repos maintain version history automatically
- **Validate JSON** — always validate the registry structure after modification:
  ```bash
  jq empty /tmp/ports-registry-updated.json && echo "Valid JSON" || echo "INVALID"
  ```
